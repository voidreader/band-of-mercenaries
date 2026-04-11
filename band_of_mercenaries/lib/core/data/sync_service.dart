import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';

enum SyncStatus {
  fullDownload,  // 첫 실행: 전체 다운로드
  updated,       // 변경된 테이블 갱신됨
  noChanges,     // 변경 없음
  offline,       // 서버 연결 실패, 캐시 사용
}

class SyncService {
  final SupabaseClient _client;
  final DataLoader _dataLoader;

  static const String _versionsKey = 'dataVersions';

  static const List<String> allTables = [
    'jobs',
    'regions',
    'traits',
    'difficulties',
    'quest_types',
    'quest_pools',
    'person_names',
    'travel_events',
    'facilities',
    'ranks',
    'mercenary_wages',
  ];

  SyncService({
    required SupabaseClient client,
    required DataLoader dataLoader,
  })  : _client = client,
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
    final raw = _settingsBox.get(_versionsKey);
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  /// 로컬 버전 저장
  void _saveLocalVersions(Map<String, int> versions) {
    _settingsBox.put(_versionsKey, versions);
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
    await _downloadTables(allTables);
    final serverVersions = await _fetchServerVersions();
    _saveLocalVersions(serverVersions);
  }

  /// 지정된 테이블들 다운로드 + 캐시 저장
  Future<void> _downloadTables(List<String> tableNames) async {
    await Future.wait(
      tableNames.map((table) => _downloadTable(table)),
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
