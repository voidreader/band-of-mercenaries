// ChronicleScreen._MemorialCard 위젯 테스트 (M8.5 페이즈 4 #4)
//
// 검증 범위:
//   [TS-1] _MemorialCard 탭 시 펼침(탭 전 숨겨진 내용이 탭 후 표시됨).
//   [TS-2] mercSnapshot.battleMemories 빈 List(구버전 호환) → 펼침 시 깨지지 않음.
//   [TS-3] hiddenStats lv1+만 표시(lv0 제외).
//
// 구현 전략:
//   - _MemorialCard는 private이므로 ChronicleScreen 전체를 pump한다.
//   - BandAchievementsNotifier.box.watch() 무한 Stream 차단을 위해
//     achievementServiceProvider를 mocktail Box mock으로 override한다.
//   - 필요한 Hive 박스를 최소한으로 열어 초기화 비용을 줄인다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/memorial_cause.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/achievement/view/chronicle_screen.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_daily_entry.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/battle_memory_entry.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
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
  _tempDir = Directory.systemTemp.createTempSync('chronicle_screen_test_');
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
  // (box.watch() 무한 Stream → pumpAndSettle 무한 대기 방지)
}

Future<void> _tearDownHive() async {
  await Hive.close();
  _tempDir.deleteSync(recursive: true);
}

// ── 헬퍼 ─────────────────────────────────────────────────────────────────────

/// StaticGameData 생성 헬퍼 (모두 빈 값).
StaticGameData _makeStaticData() {
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
    battleMemoryTemplates: const [],
  );
}

/// 지정된 achievements를 반환하는 mock box를 사용하는 AchievementService 생성.
AchievementService _makeFakeAchievementService(List<BandAchievement> achievements) {
  final mockBox = _MockBandAchievementBox();

  when(() => mockBox.watch(key: any(named: 'key'))).thenAnswer(
    (_) => const Stream.empty(),
  );
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

/// memorial 타입 BandAchievement 생성 헬퍼.
BandAchievement _makeMemorialAchievement({
  required String id,
  MercenarySnapshot? mercSnapshot,
  String cause = 'diedQuest',
}) {
  return BandAchievement(
    id: id,
    type: BandAchievementType.memorial,
    achievedAt: DateTime(2026, 1, 1),
    templateId: 'memorial:$id',
    mercSnapshot: mercSnapshot,
    payload: {'cause': cause},
  );
}

/// MercenarySnapshot 생성 헬퍼.
MercenarySnapshot _makeSnapshot({
  String id = 'snap-1',
  String name = '추모 용병',
  String jobName = '전사',
  int tier = 2,
  List<String> titleIds = const [],
  Map<String, int> hiddenStats = const {},
  List<BattleMemoryEntry> battleMemories = const [],
}) {
  return MercenarySnapshot(
    id: id,
    name: name,
    jobId: 'warrior',
    jobName: jobName,
    tier: tier,
    titleIds: titleIds,
    hiddenStats: hiddenStats,
    battleMemories: battleMemories,
  );
}

/// BattleMemoryEntry 생성 헬퍼.
BattleMemoryEntry _makeEntry(String entryType, DateTime timestamp) {
  return BattleMemoryEntry(
    mercId: 'snap-1',
    entryType: entryType,
    sourceEventId: 'source_$entryType',
    timestamp: timestamp,
  );
}

/// ProviderScope + overrides로 ChronicleScreen pump 헬퍼.
/// achievementServiceProvider를 mock으로 override해 box.watch() 무한 대기를 방지한다.
Future<void> _pumpChronicle(
  WidgetTester tester,
  List<BandAchievement> achievements,
) async {
  final fakeService = _makeFakeAchievementService(achievements);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        staticDataProvider.overrideWith(
          (ref) async => _makeStaticData(),
        ),
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
      child: const MaterialApp(
        home: ChronicleScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── 테스트 ────────────────────────────────────────────────────────────────────

void main() {
  group('ChronicleScreen._MemorialCard 위젯 테스트', () {
    setUpAll(_setUpHive);
    tearDownAll(_tearDownHive);

    // ── [TS-1] 탭 시 펼침 ────────────────────────────────────────────────
    testWidgets('[TS-1] _MemorialCard 탭 시 펼침 영역이 표시된다', (tester) async {
      // given: mercSnapshot이 있는 memorial 카드 (펼침 가능)
      final snapshot = _makeSnapshot(
        name: '추모 테스트',
        jobName: '궁수',
        tier: 3,
        hiddenStats: {'fortitude': 2}, // lv2 히든 스탯 — 펼침 시 표시됨
      );
      final achievement = _makeMemorialAchievement(
        id: 'memorial-1',
        mercSnapshot: snapshot,
        cause: 'diedQuest',
      );

      // when: ChronicleScreen 표시
      await _pumpChronicle(tester, [achievement]);

      // then: 접힘 상태 — 펼침 토글 아이콘 "▼" 표시
      expect(find.text('▼'), findsOneWidget);
      // 히든 스탯 요약은 아직 표시 안 됨
      expect(find.textContaining('fortitude lv'), findsNothing);

      // when: 카드 탭
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // then: 펼침 상태 — "▲" 토글 아이콘으로 전환
      expect(find.text('▲'), findsOneWidget);
    });

    // ── [TS-1] 펼침 후 다시 탭하면 접힘으로 돌아감 ──────────────────────
    testWidgets('[TS-1] 펼침 상태에서 다시 탭하면 접힘으로 돌아간다', (tester) async {
      // given
      final snapshot = _makeSnapshot(name: '추모 두번탭');
      final achievement = _makeMemorialAchievement(
        id: 'memorial-toggle',
        mercSnapshot: snapshot,
      );

      await _pumpChronicle(tester, [achievement]);

      // when: 첫 탭 → 펼침
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('▲'), findsOneWidget);

      // when: 두 번째 탭 → 접힘
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // then: 다시 접힘 상태
      expect(find.text('▼'), findsOneWidget);
    });

    // ── [TS-2] battleMemories 빈 List(구버전 호환) → 펼침 시 깨지지 않음 ─
    testWidgets('[TS-2] mercSnapshot.battleMemories 빈 List 상태에서 펼침 시 예외 없음', (tester) async {
      // given: battleMemories와 hiddenStats가 모두 빈 구버전 스냅샷
      final snapshot = _makeSnapshot(
        name: '구버전 용병',
        titleIds: const [],
        hiddenStats: const {},
        battleMemories: const [],
      );
      final achievement = _makeMemorialAchievement(
        id: 'memorial-legacy',
        mercSnapshot: snapshot,
        cause: 'released',
      );

      await _pumpChronicle(tester, [achievement]);

      // when: 카드 탭 (펼침)
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // then: 예외 없이 렌더됨
      expect(tester.takeException(), isNull);
      // "기록 없음" 문구 표시
      expect(find.textContaining('기록 없음'), findsOneWidget);
    });

    // ── [TS-2] mercSnapshot == null → 펼침 비활성 ──────────────────────
    testWidgets('[TS-2] mercSnapshot==null이면 펼침 기능 비활성, ▼ 아이콘 없음', (tester) async {
      // given: mercSnapshot이 null인 구버전 추모
      final achievement = _makeMemorialAchievement(
        id: 'memorial-null-snap',
        mercSnapshot: null,
        cause: 'diedEvent',
      );

      await _pumpChronicle(tester, [achievement]);

      // then: 펼침 토글 아이콘 없음
      expect(find.text('▼'), findsNothing);
      expect(find.text('▲'), findsNothing);
    });

    // ── [TS-3] hiddenStats lv1+만 표시(lv0 제외) ─────────────────────────
    testWidgets('[TS-3] hiddenStats lv1+만 히든 스탯 요약에 표시된다(lv0 제외)', (tester) async {
      // given: fortitude lv2(표시됨), grit lv0(제외됨)
      final snapshot = _makeSnapshot(
        name: '히든스탯 용병',
        hiddenStats: {
          'fortitude': 2,
          'grit': 0, // lv0은 표시 제외
        },
      );
      final achievement = _makeMemorialAchievement(
        id: 'memorial-hidden',
        mercSnapshot: snapshot,
      );

      await _pumpChronicle(tester, [achievement]);

      // when: 카드 탭 (펼침)
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // then: lv2(fortitude) 요약 표시, grit(lv0)은 없음
      // staticData.hiddenStats=[] 이므로 id를 key로 그대로 표기됨
      expect(find.textContaining('fortitude lv2'), findsOneWidget);
      // grit lv0은 숨겨짐
      expect(find.textContaining('grit'), findsNothing);
    });

    // ── 전투 기억이 있으면 펼침 시 헤더 표시 확인 ────────────────────────
    testWidgets('전투 기억이 있으면 펼침 시 "📖 전투 기억" 헤더가 표시된다', (tester) async {
      // given: 전투 기억 1개 포함 스냅샷
      final memory = _makeEntry(
        'solo_great_success',
        DateTime(2026, 1, 1, 10, 0),
      );
      final snapshot = _makeSnapshot(
        name: '기억 용병',
        battleMemories: [memory],
      );
      final achievement = _makeMemorialAchievement(
        id: 'memorial-memory',
        mercSnapshot: snapshot,
      );

      await _pumpChronicle(tester, [achievement]);

      // when: 카드 탭 (펼침)
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // then: 전투 기억 헤더 표시
      expect(find.textContaining('📖 전투 기억'), findsOneWidget);
    });
  });
}
