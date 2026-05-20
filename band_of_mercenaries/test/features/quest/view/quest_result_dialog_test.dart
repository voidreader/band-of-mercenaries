// QuestResultDialog M8b 라운드 로그 UI 위젯 테스트.
//
// 검증 범위:
//   [VT-1] M8a 호환 — schemaVersion==null 또는 turns==null 시 라운드 로그 미노출
//   [VT-2] M8b 분기 — schemaVersion==1 && turns!=null 시 라운드 로그 노출
//   [VT-3] lineBudget 상한 — turns 30개여도 4개만 노출
//   [VT-4] decisive 라벨 lookup — displayText 우선 / 미매칭 시 "결정적 장면"
//   [VT-5] 비노출 항목 — damageRoll/seed/actionScore/HP절대값 미노출
//   [VT-6] fallback 안정성 — null snapshots / 미등록 skill/effect 시 throw 없음
//
// 위젯 테스트 환경:
//   - Hive 어댑터는 테스트 격리를 위해 registerIfAbsent 패턴으로 등록
//   - staticDataProvider / mercenaryListProvider 를 ProviderScope overrides로 주입
//   - _pumpDialog 헬퍼가 다이얼로그 오픈 + "상세 보고서 보기" 탭까지 수행

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/combat_report_keyword.dart';
import 'package:band_of_mercenaries/core/models/combat_skill.dart';
import 'package:band_of_mercenaries/core/models/combat_status_effect.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/memorial_cause.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_daily_entry.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
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
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/core/models/persisted_dialog_entry.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';

// ─── Hive 초기화/정리 ──────────────────────────────────────────────────────────

late Directory _tempDir;

Future<void> _setUpHive() async {
  _tempDir = Directory.systemTemp.createTempSync('quest_result_dialog_test_');
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

  await Hive.openBox(HiveInitializer.settingsBoxName);
  await Hive.openBox<UserData>(HiveInitializer.userBoxName);
  await Hive.openBox<Mercenary>(HiveInitializer.mercenaryBoxName);
  await Hive.openBox<ActiveQuest>(HiveInitializer.questBoxName);
  await Hive.openBox<ActivityLog>('activityLogs');
  await Hive.openBox<String>(HiveInitializer.staticDataCacheBoxName);
  await Hive.openBox<RegionState>(HiveInitializer.regionStateBoxName);
  await Hive.openBox<FactionState>(HiveInitializer.factionStateBoxName);
  await Hive.openBox<InventoryItem>(HiveInitializer.inventoryBoxName);
}

Future<void> _tearDownHive() async {
  await Hive.close();
  _tempDir.deleteSync(recursive: true);
}

// ─── 픽스처 헬퍼 ──────────────────────────────────────────────────────────────

/// 가벼운 CombatAction 생성 헬퍼 (기본값: basic_attack, development 위치, damage=0)
CombatAction _action({
  String actorId = 'actor_1',
  List<String> targetIds = const ['target_1'],
  String actionKind = 'basic_attack',
  String position = 'development',
  int damage = 0,
  bool isCrit = false,
  bool isKill = false,
  bool isShielded = false,
  bool isEvaded = false,
  double shieldMitigation = 0.0,
  String? decisiveKeywordKey,
  String? skillId,
  String? statusEffectId,
  bool isComboCompression = false,
}) {
  return CombatAction(
    actorId: actorId,
    targetIds: targetIds,
    actionKind: actionKind,
    position: position,
    damage: damage,
    isCrit: isCrit,
    isKill: isKill,
    isShielded: isShielded,
    isEvaded: isEvaded,
    shieldMitigation: shieldMitigation,
    decisiveKeywordKey: decisiveKeywordKey,
    skillId: skillId,
    statusEffectId: statusEffectId,
    isComboCompression: isComboCompression,
  );
}

/// CombatTurn 생성 헬퍼
CombatTurn _turn(
  int idx,
  List<CombatAction> actions, {
  String phase = 'general',
}) {
  return CombatTurn(
    roundIndex: idx,
    phase: phase,
    actions: actions,
  );
}

/// M8a 보고서 (schemaVersion=null, turns=null)
CombatReport _buildM8aReport({
  String summary = '전투가 끝났다.',
  List<String> details = const ['상세 라인 1', '상세 라인 2', '상세 라인 3', '상세 라인 4'],
}) {
  return CombatReport(
    summary: summary,
    details: details,
    seed: 42,
    featuredMercIds: const [],
    toneTags: const [],
    createdAt: DateTime(2026, 5, 20),
    templateIds: const [],
  );
}

/// M8b 보고서 (schemaVersion=1, turns!=null)
CombatReport _buildM8bReport({
  required List<CombatTurn> turns,
  CombatExitCondition? exit,
  double? progress,
  List<CombatantSnapshot>? combatants,
  List<EnemySnapshot>? enemies,
  List<String>? details,
}) {
  return CombatReport(
    summary: '치열한 전투가 펼쳐졌다.',
    details: details ?? const ['상세 라인 1', '상세 라인 2', '상세 라인 3', '상세 라인 4'],
    seed: 99,
    featuredMercIds: const [],
    toneTags: const [],
    createdAt: DateTime(2026, 5, 20),
    templateIds: const [],
    schemaVersion: 1,
    turns: turns,
    exitCondition: exit,
    objectiveProgress: progress,
    combatantSnapshots: combatants,
    enemySnapshots: enemies,
  );
}

/// ActiveQuest 생성 헬퍼 (다이얼로그 텍스트 의존 필드 최소 채움)
ActiveQuest _quest({required CombatReport report}) {
  return ActiveQuest(
    id: 'quest-test-001',
    questPoolId: 'pool-test',
    questTypeId: 'raid',
    difficulty: 2,
    region: 3,
    questName: '테스트 퀘스트',
    result: QuestResult.success,
    combatReport: report,
    dispatchedMercIds: const [],
  );
}

/// StaticGameData stub 생성 — 모든 required 필드를 빈 리스트로 채움
StaticGameData _stubStaticData({
  List<CombatSkill> skills = const [],
  List<CombatStatusEffect> effects = const [],
  List<CombatReportKeyword> keywords = const [],
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
    regionAdjacencies: const [],
    regionSectors: const [],
    questTypes: const [
      // questType lookup이 _buildSummaryView에서 필요하므로 'raid' type 포함
      QuestType(
        id: 'raid',
        name: '전투',
        baseReward: 100,
        baseDuration: 300,
        riskFactor: 1.0,
      ),
    ],
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
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: keywords,
    combatSkills: skills,
    combatStatusEffects: effects,
    enemyArchetypes: const [],
  );
}

/// 다이얼로그를 펌프하고 "상세 보고서 보기" 버튼까지 탭하는 헬퍼
///
/// staticData: overrideWith에 사용할 StaticGameData
Future<void> _pumpDialog(
  WidgetTester tester,
  ActiveQuest quest,
  StaticGameData data,
) async {
  // MaterialApp 내부에 ProviderScope를 배치하여 Localizations 문제 방지.
  // showDialog 내부에서 ConsumerWidget이 상위 ProviderScope를 상속받도록
  // UncontrolledProviderScope를 사용한다.
  late ProviderContainer container;

  await tester.pumpWidget(
    MaterialApp(
      home: ProviderScope(
        overrides: [
          staticDataProvider.overrideWith((ref) async => data),
          // gameTickProvider를 빈 스트림으로 대체 — MercenaryListNotifier의
          // ref.listen(gameTickProvider)가 Stream.periodic을 구독하지 않도록
          gameTickProvider.overrideWith(
            (ref) => const Stream<DateTime>.empty(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => UncontrolledProviderScope(
                    container: container,
                    child: QuestResultDialog(quest: quest),
                  ),
                ),
                child: const Text('열기'),
              ),
            );
          },
        ),
      ),
    ),
  );

  // ProviderScope 초기화 완료 대기
  await tester.pumpAndSettle();

  // 다이얼로그 오픈
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();

  // "상세 보고서 보기" 탭 → detail 뷰 전환
  final detailBtn = find.text('상세 보고서 보기');
  if (detailBtn.evaluate().isNotEmpty) {
    await tester.tap(detailBtn);
    await tester.pumpAndSettle();
  }
}

// ─── 테스트 ──────────────────────────────────────────────────────────────────

void main() {
  group('QuestResultDialog — M8b 라운드 로그 UI', () {
    setUpAll(_setUpHive);
    tearDownAll(_tearDownHive);

    // ─── [VT-1] M8a 호환 ─────────────────────────────────────────────────────

    testWidgets('[VT-1] M8a 보고서: schemaVersion==null → 라운드 로그 미노출',
        (tester) async {
      final report = _buildM8aReport();
      final quest = _quest(report: report);
      final data = _stubStaticData();

      await _pumpDialog(tester, quest, data);

      // 라운드 로그 섹션 헤더 미노출 확인
      expect(find.text('전투 라운드 로그'), findsNothing);

      // details 라인은 정상 노출
      expect(find.textContaining('상세 라인 1'), findsOneWidget);
    });

    testWidgets('[VT-1] M8a 보고서: turns==null이지만 schemaVersion==1 → 라운드 로그 미노출',
        (tester) async {
      // schemaVersion=1 이지만 turns=null → M8a 경로
      final report = CombatReport(
        summary: '전투 요약',
        details: const ['상세 A', '상세 B', '상세 C', '상세 D'],
        seed: 1,
        featuredMercIds: const [],
        toneTags: const [],
        createdAt: DateTime(2026, 5, 20),
        templateIds: const [],
        schemaVersion: 1,
        turns: null, // turns가 null이면 M8a 경로
      );
      final quest = _quest(report: report);
      final data = _stubStaticData();

      await _pumpDialog(tester, quest, data);

      expect(find.text('전투 라운드 로그'), findsNothing);
      expect(find.textContaining('상세 A'), findsOneWidget);
    });

    // ─── [VT-2] M8b 분기 ─────────────────────────────────────────────────────

    testWidgets('[VT-2] M8b 보고서: 라운드 로그 헤더·종료 조건·R{i} 헤더·actor 이름 노출',
        (tester) async {
      final combatant = CombatantSnapshot(
        mercId: 'merc_1',
        name: '홍길동',
        jobId: 'warrior',
        tier: 2,
        level: 3,
        effectiveStr: 15,
        effectiveInt: 8,
        effectiveVit: 12,
        effectiveAgi: 10,
        role: 'warrior',
        positionRow: PositionRow.front,
        positionIndex: 0,
      );
      final enemy = EnemySnapshot(
        archetypeId: 'goblin',
        instanceId: 'goblin#0',
        name: '고블린',
        role: 'warrior',
        tier: 1,
        str: 8,
        int_: 5,
        vit: 8,
        agi: 8,
        hp: 0,
        attack: 10,
        defense: 5,
        behaviorPattern: BehaviorPattern.aggressive,
        positionRow: PositionRow.front,
        positionIndex: 0,
        formationGroupId: 'group_1',
      );

      final turns = [
        _turn(
          1,
          [
            _action(
              actorId: 'merc_1',
              targetIds: ['goblin#0'],
              damage: 25,
            ),
          ],
        ),
        _turn(
          2,
          [
            _action(
              actorId: 'goblin#0',
              targetIds: ['merc_1'],
              damage: 10,
            ),
          ],
        ),
      ];

      final report = _buildM8bReport(
        turns: turns,
        exit: CombatExitCondition.bEnemyWiped,
        combatants: [combatant],
        enemies: [enemy],
      );
      final quest = _quest(report: report);
      final data = _stubStaticData();

      await _pumpDialog(tester, quest, data);

      // 라운드 로그 헤더 노출
      expect(find.text('전투 라운드 로그'), findsOneWidget);

      // 종료 조건 배지
      expect(find.text('적 전멸'), findsOneWidget);

      // 라운드 헤더
      expect(find.text('R1'), findsOneWidget);
      expect(find.text('R2'), findsOneWidget);

      // actor 이름 (combatantSnapshots에서 lookup)
      expect(find.textContaining('홍길동'), findsAtLeastNWidgets(1));
    });

    // ─── [VT-3] lineBudget 상한 ──────────────────────────────────────────────

    testWidgets('[VT-3] turns 30개 × damage>=1 액션, details=[] → R헤더 4개만 노출',
        (tester) async {
      // details가 비어 있으면 lineBudget = 4
      final turns = List.generate(
        30,
        (i) => _turn(
          i + 1,
          [_action(actorId: 'actor_1', damage: 10)],
        ),
      );

      final report = _buildM8bReport(
        turns: turns,
        exit: CombatExitCondition.dRoundLimit,
        details: const [], // 빈 details → lineBudget = 4
      );
      final quest = _quest(report: report);
      final data = _stubStaticData();

      await _pumpDialog(tester, quest, data);

      // R1~R30 중 정확히 4개만 노출
      final shown = List.generate(
        30,
        (i) => find.text('R${i + 1}'),
      ).where((f) => f.evaluate().isNotEmpty).length;

      expect(shown, 4);
    });

    // ─── [VT-4] decisive 라벨 lookup ─────────────────────────────────────────

    testWidgets('[VT-4a] decisive key 매칭 → displayText 노출, raw key 미노출',
        (tester) async {
      const keyword = CombatReportKeyword(
        id: 'kw_1',
        category: 'decisive',
        key: 'shield_opens_path',
        displayText: '방패가 길을 열다',
        weight: 1,
      );

      final turns = [
        _turn(
          1,
          [
            _action(
              damage: 20,
              decisiveKeywordKey: 'shield_opens_path',
            ),
          ],
        ),
      ];

      final report = _buildM8bReport(turns: turns, exit: CombatExitCondition.bEnemyWiped);
      final quest = _quest(report: report);
      final data = _stubStaticData(keywords: [keyword]);

      await _pumpDialog(tester, quest, data);

      // displayText 노출
      expect(find.text('방패가 길을 열다'), findsOneWidget);

      // raw key 미노출
      expect(find.textContaining('shield_opens_path'), findsNothing);
    });

    testWidgets('[VT-4b] decisive key 미매칭 → "결정적 장면" fallback 노출',
        (tester) async {
      final turns = [
        _turn(
          1,
          [
            _action(
              damage: 15,
              decisiveKeywordKey: 'unknown_key',
            ),
          ],
        ),
      ];

      final report = _buildM8bReport(turns: turns, exit: CombatExitCondition.bEnemyWiped);
      final quest = _quest(report: report);
      // keywords 목록에 'unknown_key' 없음
      final data = _stubStaticData(keywords: const []);

      await _pumpDialog(tester, quest, data);

      // fallback 텍스트 노출
      expect(find.text('결정적 장면'), findsOneWidget);

      // raw key 미노출
      expect(find.textContaining('unknown_key'), findsNothing);
    });

    // ─── [VT-5] 비노출 항목 ──────────────────────────────────────────────────

    testWidgets('[VT-5] damageRoll/seed/actionScore/HP절대값 미노출', (tester) async {
      final turns = [
        _turn(
          1,
          [
            _action(
              damage: 42,
              isShielded: true,
              shieldMitigation: 0.3,
              isCrit: true,
            ),
          ],
        ),
      ];

      final report = _buildM8bReport(turns: turns, exit: CombatExitCondition.bEnemyWiped);
      final quest = _quest(report: report);
      final data = _stubStaticData();

      await _pumpDialog(tester, quest, data);

      // 비노출 항목 검증
      expect(find.textContaining('damageRoll'), findsNothing);
      expect(find.textContaining('actionScore'), findsNothing);
      // seed는 숫자(99)로만 존재하므로 문자열 'seed' 기준 검증
      expect(find.textContaining('seed'), findsNothing);
      // HP 절대값 패턴 (예: "HP: 100") 미노출
      expect(find.textContaining('HP: '), findsNothing);
      // 명중률/회피율/치명타율 % 미노출
      expect(find.textContaining('명중률'), findsNothing);
      expect(find.textContaining('회피율'), findsNothing);
      expect(find.textContaining('치명타율'), findsNothing);
    });

    // ─── [VT-6] fallback 안정성 ──────────────────────────────────────────────

    testWidgets('[VT-6] combatantSnapshots/enemySnapshots=null, skill/effect 미등록 → throw 없음',
        (tester) async {
      final turns = [
        _turn(
          1,
          [
            _action(
              actorId: 'test_actor_id',
              targetIds: ['test_target_id'],
              actionKind: 'skill',
              skillId: 'skill_unknown',
              statusEffectId: 'effect_unknown',
              damage: 10,
            ),
          ],
        ),
      ];

      // combatantSnapshots=null, enemySnapshots=null
      final report = _buildM8bReport(
        turns: turns,
        exit: CombatExitCondition.bEnemyWiped,
        combatants: null,
        enemies: null,
      );
      final quest = _quest(report: report);
      // combatSkills=[], combatStatusEffects=[] → skill/effect 모두 미등록
      final data = _stubStaticData(
        skills: const [],
        effects: const [],
      );

      await _pumpDialog(tester, quest, data);

      // throw 없이 렌더링 완료
      expect(tester.takeException(), isNull);

      // actorId raw가 fallback으로 노출되는지 확인
      // (combatantSnapshots, enemySnapshots, mercs 모두 null/empty → actorId 그대로)
      expect(find.textContaining('test_actor_id'), findsAtLeastNWidgets(1));
    });

    testWidgets('[VT-6b] dot_tick + statusEffectId 미등록 → "상태 효과" fallback, throw 없음',
        (tester) async {
      final turns = [
        _turn(
          1,
          [
            _action(
              actorId: 'actor_1',
              targetIds: ['target_1'],
              actionKind: 'dot_tick',
              statusEffectId: 'bleeding_unknown',
              damage: 5,
              position: 'crisis',
            ),
          ],
        ),
      ];

      final report = _buildM8bReport(
        turns: turns,
        exit: CombatExitCondition.bEnemyWiped,
      );
      final quest = _quest(report: report);
      final data = _stubStaticData(effects: const []);

      await _pumpDialog(tester, quest, data);

      expect(tester.takeException(), isNull);

      // 상태 효과 fallback 노출
      expect(find.textContaining('상태 효과'), findsAtLeastNWidgets(1));
    });

    // ─── [M8b 페이즈 4 #5 FR-10] lineBudget 매트릭스 4/5/6/7/8 ─────────────────

    testWidgets('[FR-10] details.length=4 + turns 30개 → 라운드 로그 4개', (tester) async {
      final report = _buildLineBudgetReport(detailLines: 4);
      final quest = _quest(report: report);
      final data = _stubStaticData();
      await _pumpDialog(tester, quest, data);
      // R{i} 헤더가 4개 노출되어야 한다 (lineBudget = clamp(4, 8) = 4).
      final headerCount = _countRoundHeaders(tester);
      expect(headerCount, equals(4));
    });

    testWidgets('[FR-10] details.length=7 + turns 30개 → 라운드 로그 7개', (tester) async {
      final report = _buildLineBudgetReport(detailLines: 7);
      final quest = _quest(report: report);
      final data = _stubStaticData();
      await _pumpDialog(tester, quest, data);
      final headerCount = _countRoundHeaders(tester);
      expect(headerCount, equals(7));
    });

    testWidgets('[FR-10] details.length=9 (overflow) → 라운드 로그 상한 8', (tester) async {
      final report = _buildLineBudgetReport(detailLines: 9);
      final quest = _quest(report: report);
      final data = _stubStaticData();
      await _pumpDialog(tester, quest, data);
      // clamp(4, 8) 상한 = 8.
      final headerCount = _countRoundHeaders(tester);
      expect(headerCount, equals(8));
    });

    // ─── [M8b 페이즈 4 #5 FR-11] decisive key 추가 케이스 ──────────────────────

    testWidgets('[FR-11] decisiveKeywordKey == null → 배지 미렌더링', (tester) async {
      final report = _buildM8bReport(
        turns: [
          _turn(1, [_action(decisiveKeywordKey: null, damage: 10)]),
        ],
        details: const ['요약 1'],
        exit: CombatExitCondition.bEnemyWiped,
      );
      final quest = _quest(report: report);
      final data = _stubStaticData();
      await _pumpDialog(tester, quest, data);
      // 결정적 장면 배지 텍스트 미존재.
      expect(find.text('결정적 장면'), findsNothing);
    });

    // ─── [M8b 페이즈 4 #5 FR-12] 비노출 14종 핵심 확장 ─────────────────────────

    testWidgets('[FR-12] damageRoll/intensity/명중률/HP 절대값/사망저항 등 미노출', (tester) async {
      // damage=42인 액션에서 damage 텍스트만 보이고 다른 수치는 가린다.
      final report = _buildM8bReport(
        turns: [
          _turn(1, [_action(damage: 42, isKill: true)]),
        ],
        details: const ['상세 1'],
        exit: CombatExitCondition.bEnemyWiped,
      );
      final quest = _quest(report: report);
      final data = _stubStaticData();
      await _pumpDialog(tester, quest, data);

      // 비노출 항목 매트릭스 14종 핵심 검증.
      // (1) damageRoll 1.0/0.5/0.0 텍스트 미노출.
      expect(find.textContaining('damageRoll'), findsNothing);
      // (2) seed 텍스트 미노출.
      expect(find.textContaining('seed'), findsNothing);
      // (3) actionScore 텍스트 미노출.
      expect(find.textContaining('actionScore'), findsNothing);
      // (4) HP 절대값 형식 미노출 (예: 'HP 120/200').
      expect(find.textContaining(RegExp(r'HP \d+/\d+')), findsNothing);
      // (5) intensity 텍스트 미노출.
      expect(find.textContaining('intensity'), findsNothing);
      // (6) 명중률·회피율·치명타율·사망 저항률 백분율 매트릭스 미노출 (예: '명중률 85%').
      expect(find.textContaining('명중률'), findsNothing);
      expect(find.textContaining('회피율'), findsNothing);
      expect(find.textContaining('치명타율'), findsNothing);
      expect(find.textContaining('사망 저항률'), findsNothing);
    });
  });
}

// ─── FR-10 lineBudget 매트릭스용 헬퍼 ────────────────────────────────────────

CombatReport _buildLineBudgetReport({required int detailLines}) {
  // turns 30개 (모두 damage>=1인 basic_attack 액션 1개씩)
  final turns = [
    for (var i = 1; i <= 30; i++)
      _turn(i, [_action(damage: 5, position: 'development')]),
  ];
  return _buildM8bReport(
    turns: turns,
    details: [for (var i = 0; i < detailLines; i++) '상세 $i'],
    exit: CombatExitCondition.bEnemyWiped,
  );
}

// R{i} 패턴 헤더 노출 수를 RegExp로 카운트.
int _countRoundHeaders(WidgetTester tester) {
  final pattern = RegExp(r'^R\d+$');
  var count = 0;
  for (final element in find.byType(Text).evaluate()) {
    final text = (element.widget as Text).data;
    if (text != null && pattern.hasMatch(text)) {
      count++;
    }
  }
  return count;
}
