import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/settings_keys.dart';

enum SyncStatus {
  fullDownload, // 첫 실행: 전체 다운로드
  updated, // 변경된 테이블 갱신됨
  noChanges, // 변경 없음
  offline, // 서버 연결 실패, 캐시 사용
}

class SyncService {
  final SupabaseClient _client;
  final DataLoader _dataLoader;

  static const List<String> allTables = [
    'jobs',
    'regions',
    'region_sectors', // 27. region_sectors (M4 페이즈 4 #2 추가)
    'trait_categories',
    'traits',
    'trait_conflicts',
    'trait_transitions',
    'trait_combo_evolutions',
    'trait_synergies',
    'difficulties',
    'quest_types',
    'quest_pools',
    'person_names',
    'travel_events',
    'facilities',
    'ranks',
    'mercenary_wages',
    'region_discoveries',
    'factions',
    'items', // 19. 아이템 (M2a 추가)
    'elite_monsters', // 20. 엘리트 몬스터 (M2b 추가)
    'elite_loot_tables', // 21. 엘리트 드랍 테이블 (M2b 추가)
    'chain_quests', // 22. 연쇄 퀘스트 (M3 추가)
    'quest_narratives', // 23. 퀘스트 서술 (M3 추가)
    'travel_choice_events', // 24. 이동 선택지 이벤트 (M3 추가)
    'travel_choice_options', // 25. 이동 선택지 옵션 (M3 추가)
    'travel_choice_results', // 26. 이동 선택지 결과 (M3 추가)
    'crafting_recipes', // 28. 제작 레시피 (M5 추가)
    'quest_pool_material_drops', // 29. 의뢰 풀 재료 드랍 (M5 추가)
    'band_achievement_templates', // 30. 위업 템플릿 (M6 페이즈 4 #1 추가)
    'titles', // 31. 칭호 (M6 페이즈 4 #2 추가)
    'region_adjacency', // 32. 지역 인접성 (M7 페이즈 4 #3 추가)
    'faction_contacts', // 33. 세력 접촉점 (M8a 페이즈 4 #1 추가)
    'faction_reactions', // 34. 세력 반응 텍스트 (M8a 페이즈 4 #1 추가)
    'faction_shop_items', // 35. 세력 상점 아이템 (M8a 페이즈 4 #1 추가)
    'combat_report_templates', // 36. 전투 보고서 템플릿 (M8a 페이즈 4 #2 추가)
    'combat_report_keywords', // 37. 전투 보고서 키워드 (M8a 페이즈 4 #2 추가)
  ];

  /// 비어 있어도 로컬 앱이 기동 가능해야 하는 보조 정적 데이터.
  ///
  /// region_sectors는 M4에서 더스트플레인 fallback을 코드로 보유하고, DB 시드는
  /// 후속 일괄 배포 전까지 0행을 허용한다. M8a 신규 테이블도 존재하면 동기화하고,
  /// 없거나 비어 있으면 빈 데이터로 동작한다.
  static const Set<String> optionalTables = {
    'region_sectors',
    'faction_contacts',
    'faction_reactions',
    'faction_shop_items',
    'combat_report_templates',
    'combat_report_keywords',
  };

  static List<String> get requiredTables =>
      allTables.where((table) => !optionalTables.contains(table)).toList();

  SyncService({required SupabaseClient client, required DataLoader dataLoader})
    : _client = client,
      _dataLoader = dataLoader;

  Box get _settingsBox => Hive.box(HiveInitializer.settingsBoxName);

  /// 메인 싱크 로직
  Future<SyncStatus> sync() async {
    final hasCache = _dataLoader.hasCache();

    if (!hasCache) {
      // 첫 실행: 전체 다운로드 필수 (실패 시 예외)
      await _fullDownload();
      return SyncStatus.fullDownload;
    }

    // 재실행: 서버 연결 시도
    try {
      final serverVersions = await _fetchServerVersions();
      final localVersions = _getLocalVersions();
      final changedTables = _findChangedTables(serverVersions, localVersions);

      // 자가치유: 빈 배열로 캐시된 테이블이 있으면 재다운로드 대상에 포함.
      // 과거에 sync 시점 supabase가 비어있어 '[]'로 저장된 케이스 복구용.
      for (final table in serverVersions.keys) {
        if (optionalTables.contains(table)) continue;
        if (_dataLoader.isCacheEmpty(table) && !changedTables.contains(table)) {
          changedTables.add(table);
        }
      }

      if (changedTables.isEmpty) {
        return SyncStatus.noChanges;
      }

      await _downloadTables(changedTables);
      _saveLocalVersions(serverVersions);
      return SyncStatus.updated;
    } catch (e) {
      // 서버 연결 실패 — 캐시 사용
      return SyncStatus.offline;
    }
  }

  /// 서버에서 data_versions 테이블 조회
  Future<Map<String, int>> _fetchServerVersions() async {
    final response = await _client
        .from('data_versions')
        .select('table_name, version');

    final versions = <String, int>{};
    for (final row in response as List) {
      versions[row['table_name'] as String] = row['version'] as int;
    }
    return versions;
  }

  /// 로컬 저장된 버전 정보
  Map<String, int> _getLocalVersions() {
    final raw = _settingsBox.get(SettingsKeys.dataVersions);
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  /// 로컬 버전 저장
  void _saveLocalVersions(Map<String, int> versions) {
    _settingsBox.put(SettingsKeys.dataVersions, versions);
  }

  /// 서버와 로컬 버전 비교 → 변경된 테이블 목록
  List<String> _findChangedTables(
    Map<String, int> serverVersions,
    Map<String, int> localVersions,
  ) {
    final changed = <String>[];
    for (final entry in serverVersions.entries) {
      final localVersion = localVersions[entry.key] ?? 0;
      if (entry.value != localVersion) {
        changed.add(entry.key);
      }
    }
    return changed;
  }

  /// 전체 테이블 다운로드 (첫 실행)
  Future<void> _fullDownload() async {
    try {
      await _downloadTables(requiredTables);
      await _downloadOptionalTables(optionalTables);
      final serverVersions = await _fetchServerVersions();
      _saveLocalVersions(serverVersions);
    } catch (e) {
      await _dataLoader.clearCache();
      rethrow;
    }
  }

  /// 지정된 테이블들 다운로드 + 캐시 저장
  Future<void> _downloadTables(List<String> tableNames) async {
    await Future.wait(tableNames.map((table) => _downloadTable(table)));
  }

  Future<void> _downloadOptionalTables(Iterable<String> tableNames) async {
    await Future.wait(
      tableNames.map((table) async {
        try {
          await _downloadTable(table);
        } catch (_) {
          // 후속 정적 데이터 스키마 적용 전 환경에서는 optional 테이블이 없을 수 있다.
        }
      }),
    );
  }

  /// 단일 테이블 다운로드 + 캐시 저장
  Future<void> _downloadTable(String tableName) async {
    final response = await _client.from(tableName).select();
    final data = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    await _dataLoader.saveToCache(tableName, data);
  }
}
