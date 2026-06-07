// BattleMemorySection 위젯 테스트 (M8.5 페이즈 4 #4)
//
// 검증 범위:
//   [TS-1] battleMemories를 timestamp desc(최신 위)로 렌더한다.
//   [TS-2] 빈 List → 빈 상태 문구("아직 기억이 없습니다...") 표시.
//   [TS-3] achievement_granted lookup 실패 시 해당 카드 SizedBox.shrink(),
//          본 흐름 미실패(다른 카드 정상 렌더).
//   [TS-4] 빈 템플릿 캐시(battleMemoryTemplates=[])에서도 fallback 문구로 카드 유지.
//
// 구현 전략:
//   - BandAchievementsNotifier._loadAndWatch에서 box.watch()가 무한 Stream을 사용하면
//     pumpAndSettle이 완료되지 않는 문제를 방지하기 위해,
//     achievementServiceProvider를 mocktail Box mock으로 override한다.
//   - Box<BandAchievement> mock: watch()→Stream.empty(), values→지정된 achievements.
//   - 나머지 Provider는 최소한으로 override한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/battle_memory_template.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/memorial_cause.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_daily_entry.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/battle_memory_entry.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/view/battle_memory_section.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_action.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/combatant_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/enemy_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';
import 'package:band_of_mercenaries/core/models/persisted_dialog_entry.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

// Hive Box[BandAchievement] mock.
// - watch(): Stream.empty() (즉시 완료 — pumpAndSettle 무한 대기 방지)
// - values: 주입된 achievements 반환
class _MockBandAchievementBox extends Mock implements Box<BandAchievement> {}

// ── Hive 초기화/정리 ───────────────────────────────────────────────────────────

late Directory _tempDir;

Future<void> _setUpHive() async {
  _tempDir = Directory.systemTemp.createTempSync('battle_memory_section_test_');
  Hive.init(_tempDir.path);

  void registerIfAbsent<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  registerIfAbsent(0, MercenaryStatusAdapter());
  registerIfAbsent(1, MercenaryAdapter());
  registerIfAbsent(2, QuestStatusAdapter());
  registerIfAbsent(3, QuestResultAdapter());
  registerIfAbsent(4, ActiveQuestAdapter());
  registerIfAbsent(5, UserDataAdapter());
  registerIfAbsent(6, ActivityLogTypeAdapter());
  registerIfAbsent(7, ActivityLogAdapter());
  registerIfAbsent(8, RegionStateAdapter());
  registerIfAbsent(9, FactionClueRecordAdapter());
  registerIfAbsent(10, FactionStateAdapter());
  registerIfAbsent(11, InventoryItemAdapter());
  registerIfAbsent(13, ChainQuestProgressAdapter());
  registerIfAbsent(14, ChainQuestStatusAdapter());
  registerIfAbsent(15, PersistedDialogEntryAdapter());
  registerIfAbsent(16, BandAchievementAdapter());
  registerIfAbsent(17, BandAchievementTypeAdapter());
  registerIfAbsent(18, MercenarySnapshotAdapter());
  registerIfAbsent(19, MemorialCauseAdapter());
  registerIfAbsent(20, FactionShopDailyEntryAdapter());
  registerIfAbsent(21, CombatReportAdapter());
  registerIfAbsent(22, CombatSimulationResultAdapter());
  registerIfAbsent(23, CombatTurnAdapter());
  registerIfAbsent(24, CombatActionAdapter());
  registerIfAbsent(25, StatusEffectEventAdapter());
  registerIfAbsent(26, CombatantSnapshotAdapter());
  registerIfAbsent(27, EnemySnapshotAdapter());
  registerIfAbsent(28, CombatExitConditionAdapter());
  registerIfAbsent(29, BehaviorPatternAdapter());
  registerIfAbsent(30, PositionRowAdapter());
  registerIfAbsent(31, BattleMemoryEntryAdapter());

  await Hive.openBox(HiveInitializer.settingsBoxName);
  await Hive.openBox<UserData>(HiveInitializer.userBoxName);
  await Hive.openBox<Mercenary>(HiveInitializer.mercenaryBoxName);
  await Hive.openBox<ActiveQuest>(HiveInitializer.questBoxName);
  await Hive.openBox<ActivityLog>('activityLogs');
  await Hive.openBox<String>(HiveInitializer.staticDataCacheBoxName);
  await Hive.openBox<RegionState>(HiveInitializer.regionStateBoxName);
  await Hive.openBox<FactionState>(HiveInitializer.factionStateBoxName);
  await Hive.openBox<InventoryItem>(HiveInitializer.inventoryBoxName);
  // bandAchievements 박스는 mock으로 대체하므로 열지 않는다.
  // dialogQueue/chainQuestProgress 박스도 불필요.
}

Future<void> _tearDownHive() async {
  await Hive.close();
  _tempDir.deleteSync(recursive: true);
}

// ── 헬퍼 ─────────────────────────────────────────────────────────────────────

/// BattleMemoryEntry 생성 헬퍼.
BattleMemoryEntry _makeEntry({
  required String entryType,
  required DateTime timestamp,
  String sourceEventId = 'source_test',
  String? templateKey,
  Map<String, dynamic> templateData = const {},
}) {
  return BattleMemoryEntry(
    mercId: 'merc-1',
    entryType: entryType,
    sourceEventId: sourceEventId,
    timestamp: timestamp,
    templateKey: templateKey,
    templateData: templateData,
  );
}

/// Mercenary 생성 헬퍼.
Mercenary _makeMerc(List<BattleMemoryEntry> memories) {
  return Mercenary(
    id: 'merc-1',
    name: '테스트 용병',
    jobId: 'warrior',
    traitId: 'brave',
    str: 10,
    intelligence: 10,
    vit: 10,
    agi: 10,
    battleMemories: memories,
  );
}

/// StaticGameData 생성 헬퍼 (battleMemoryTemplates만 커스텀).
StaticGameData _makeStaticData({
  List<BattleMemoryTemplate> battleMemoryTemplates = const [],
}) {
  return StaticGameData(
    difficulties: const [],
    jobs: const [],
    traits: const [],
    traitCategories: const [],
    traitConflicts: const [],
    traitTransitions: const [],
    traitComboEvolutions: const [],
    traitSynergies: const [],
    regions: const [],
    questTypes: const [],
    questPools: const [],
    personNames: const [],
    travelEvents: const [],
    facilities: const [],
    ranks: const [],
    mercenaryWages: const [],
    regionDiscoveries: const [],
    factions: const [],
    items: const [],
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionAdjacencies: const [],
    regionSectors: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: const [],
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
    hiddenStats: const [],
    battleMemoryTemplates: battleMemoryTemplates,
  );
}

/// 지정된 achievements를 반환하는 mock box를 사용하는 AchievementService 생성.
/// box.watch()는 Stream.empty()를 반환해 pumpAndSettle 무한 대기를 방지한다.
AchievementService _makeFakeAchievementService(List<BandAchievement> achievements) {
  final mockBox = _MockBandAchievementBox();

  // watch() → 즉시 완료 Stream (Hive BoxEvent 타입 맞춤)
  when(() => mockBox.watch(key: any(named: 'key'))).thenAnswer(
    (_) => const Stream.empty(),
  );
  // values: achievements를 HiveObject Values로 반환
  when(() => mockBox.values).thenReturn(achievements);

  return AchievementService(
    box: mockBox,
    uuid: const Uuid(),
    addLog: (p1, p2) {},
    enqueueDialog: (_) {},
    templates: const [],
    buildAchievementDialog: (a, titles, onDismiss) => const SizedBox.shrink(),
  );
}

/// ProviderScope + overrides로 위젯 pump 헬퍼.
Future<void> _pump(
  WidgetTester tester,
  Mercenary merc, {
  List<BattleMemoryTemplate> templates = const [],
  List<BandAchievement> achievements = const [],
}) async {
  final fakeService = _makeFakeAchievementService(achievements);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        staticDataProvider.overrideWith(
          (ref) async => _makeStaticData(battleMemoryTemplates: templates),
        ),
        // achievementServiceProvider: mock box 사용 (box.watch() 무한 Stream 차단)
        achievementServiceProvider.overrideWithValue(fakeService),
        // gameTickProvider: Stream.periodic 무한 루프 방지
        gameTickProvider.overrideWith(
          (ref) => const Stream<DateTime>.empty(),
        ),
        titlesProvider.overrideWith(
          (ref) => const [],
        ),
        mercenaryTitlesProvider.overrideWith(
          (ref, _) => const [],
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BattleMemorySection(merc: merc),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── 테스트 ────────────────────────────────────────────────────────────────────

void main() {
  group('BattleMemorySection 위젯 테스트', () {
    setUpAll(_setUpHive);
    tearDownAll(_tearDownHive);

    // ── [TS-2] 빈 List → 빈 상태 문구 ───────────────────────────────────
    testWidgets('[TS-2] battleMemories 빈 List이면 빈 상태 문구를 표시한다', (tester) async {
      // given: 전투 기억이 없는 용병
      final merc = _makeMerc([]);

      // when
      await _pump(tester, merc);

      // then: 빈 상태 문구 포함
      expect(find.textContaining('아직 기억이 없습니다'), findsOneWidget);
    });

    // ── [TS-1] timestamp desc 정렬 ──────────────────────────────────────
    testWidgets('[TS-1] 전투 기억을 timestamp desc(최신 위)로 렌더한다', (tester) async {
      // given: 오래된 → 최신 순으로 추가된 2개 기억
      final old = _makeEntry(
        entryType: 'solo_great_success',
        timestamp: DateTime(2026, 1, 1, 10, 0),
        sourceEventId: 'quest_old',
      );
      final recent = _makeEntry(
        entryType: 'hidden_stat_unlock',
        timestamp: DateTime(2026, 1, 2, 10, 0),
        sourceEventId: 'quest_recent',
      );
      final merc = _makeMerc([old, recent]); // 원본은 old → recent 순서

      // when
      await _pump(tester, merc);

      // then: 빈 템플릿 캐시 → fallback 문구로 카드 표시됨
      final hiddenFallback = find.textContaining('새로운 잠재력이 깨어났다');
      final soloFallback = find.textContaining('단독 의뢰를 대성공으로 마쳤다');
      expect(hiddenFallback, findsOneWidget);
      expect(soloFallback, findsOneWidget);

      // 위치 비교: hidden_stat_unlock(recent) 카드가 solo_great_success(old) 카드보다 위에 위치
      final hiddenY = tester.getTopLeft(hiddenFallback).dy;
      final soloY = tester.getTopLeft(soloFallback).dy;
      expect(hiddenY, lessThan(soloY));
    });

    // ── [TS-3] achievement_granted lookup 실패 시 카드 SizedBox.shrink() ─
    testWidgets('[TS-3] achievement_granted lookup 실패 시 해당 카드 숨김, 다른 카드는 정상', (tester) async {
      // given: achievement_granted 카드(lookup 실패) + solo_great_success 카드
      final achievementEntry = _makeEntry(
        entryType: 'achievement_granted',
        timestamp: DateTime(2026, 1, 2),
        sourceEventId: 'achievement:nonexistent_template_id',
      );
      final soloEntry = _makeEntry(
        entryType: 'solo_great_success',
        timestamp: DateTime(2026, 1, 1),
        sourceEventId: 'quest_solo',
      );
      final merc = _makeMerc([achievementEntry, soloEntry]);

      // when: achievements 빈 리스트 (lookup 실패)
      await _pump(tester, merc, achievements: []);

      // then: solo 카드(fallback 문구)는 표시됨
      expect(find.textContaining('단독 의뢰를 대성공으로 마쳤다'), findsOneWidget);
      // 빈 상태 문구는 표시되지 않음(solo 카드가 있으므로)
      expect(find.textContaining('아직 기억이 없습니다'), findsNothing);
    });

    // ── [TS-3] achievement_granted lookup 실패 시 전체 흐름 미실패 ────────
    testWidgets('[TS-3] achievement_granted lookup 실패 시 예외 발생 없음', (tester) async {
      // given: achievement_granted만 있는 용병 (lookup 실패)
      final entry = _makeEntry(
        entryType: 'achievement_granted',
        timestamp: DateTime(2026, 1, 1),
        sourceEventId: 'achievement:does_not_exist',
      );
      final merc = _makeMerc([entry]);

      // when: 예외 없이 렌더 완료되어야 한다
      await _pump(tester, merc, achievements: []);

      // then: throw 없이 완료됨
      expect(tester.takeException(), isNull);
    });

    // ── [TS-4] 빈 템플릿 캐시 → fallback 문구 카드 유지 ──────────────────
    testWidgets('[TS-4] 빈 battleMemoryTemplates 캐시에서 fallback 문구로 카드 유지', (tester) async {
      // given: 4종 템플릿 렌더 entryType 각 1개
      final entries = [
        _makeEntry(
          entryType: 'emotional_apply',
          timestamp: DateTime(2026, 1, 4),
          sourceEventId: 'emotional_rage',
        ),
        _makeEntry(
          entryType: 'hidden_stat_unlock',
          timestamp: DateTime(2026, 1, 3),
          sourceEventId: 'hidden_grit',
        ),
        _makeEntry(
          entryType: 'solo_great_success',
          timestamp: DateTime(2026, 1, 2),
          sourceEventId: 'quest_solo',
        ),
        _makeEntry(
          entryType: 'unique_elite_first_kill',
          timestamp: DateTime(2026, 1, 1),
          sourceEventId: 'elite_dragon',
        ),
      ];
      final merc = _makeMerc(entries);

      // when: 빈 템플릿 캐시 (templates=[])
      await _pump(tester, merc);

      // then: 4종 모두 fallback 문구로 카드가 유지됨 (SizedBox.shrink() 아님)
      expect(find.textContaining('감정에 휩싸였다'), findsOneWidget);
      expect(find.textContaining('새로운 잠재력이 깨어났다'), findsOneWidget);
      expect(find.textContaining('단독 의뢰를 대성공으로 마쳤다'), findsOneWidget);
      expect(find.textContaining('강대한 적을 쓰러뜨렸다'), findsOneWidget);
    });

    // ── 헤더 카운터 포맷 확인 ─────────────────────────────────────────────
    testWidgets('헤더에 "전투 기억 N/30" 포맷으로 개수가 표시된다', (tester) async {
      // given: 기억 2개
      final entries = [
        _makeEntry(
          entryType: 'solo_great_success',
          timestamp: DateTime(2026, 1, 2),
        ),
        _makeEntry(
          entryType: 'hidden_stat_unlock',
          timestamp: DateTime(2026, 1, 1),
        ),
      ];
      final merc = _makeMerc(entries);

      // when
      await _pump(tester, merc);

      // then: 헤더에 "전투 기억 2/30" 표시
      expect(find.textContaining('전투 기억 2/30'), findsOneWidget);
    });
  });
}
