// GoalRecommendationService 단위 테스트.
//
// 검증 범위 (명세 §4.6 시나리오 8종):
//   1. 의뢰 12분 + difficulty 2 → score 70 primary
//   2. 명성 200G gap → score 40
//   3. 명성 20G gap → score 85
//   4. 인프라 Tier 4까지 flag 1개 → 5/6 + value 48 → score 131
//   5. dangerScore=-90 (8시간) → score 140 primary
//   6. 핀 우선 — pin 유효이면 선택, 무효이면 자동 + invalidatedPinId
//   7. 핀 무효화 — pinId만 반환, UserDataNotifier 미호출
//   8. fallback — 후보 0개
//
// 격리 전략:
//   - 임시 디렉토리에 Hive 셋업하여 UserData 박스 직접 주입 후 실제 UserDataNotifier 사용
//   - QuestRepository는 Quest 박스 의존이므로 questListProvider만 fake StateNotifier로 override
//   - regionStateRepositoryProvider / factionStateRepositoryProvider는 fake 인터페이스 구현체로 override
//   - chainQuestProgressProvider / staticDataProvider는 ProviderContainer override 후 pre-warm

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/info/domain/goal_recommendation_service.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';

// ============================================================================
// Hive 셋업 (임시 디렉토리)
// ============================================================================

late Directory _tempDir;

Future<void> _setUpHive() async {
  _tempDir =
      Directory.systemTemp.createTempSync('goal_recommendation_test_');
  Hive.init(_tempDir.path);

  void registerIfAbsent<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  // 본 테스트는 UserData(typeId 5), ActiveQuest(typeId 4),
  // ChainQuestProgress(typeId 13) 박스를 직접 사용한다.
  // QuestListNotifier 생성자가 _injectFixedSettlementQuest를 microtask로 호출하여
  // ChainQuestRepository box도 건드리므로 셋업 필수.
  registerIfAbsent(5, UserDataAdapter());
  registerIfAbsent(4, ActiveQuestAdapter());
  registerIfAbsent(2, QuestStatusAdapter());
  registerIfAbsent(3, QuestResultAdapter());
  registerIfAbsent(13, ChainQuestProgressAdapter());
  registerIfAbsent(14, ChainQuestStatusAdapter());
  await Hive.openBox<UserData>(HiveInitializer.userBoxName);
  await Hive.openBox<ActiveQuest>(HiveInitializer.questBoxName);
  await Hive.openBox<ChainQuestProgress>(
      HiveInitializer.chainQuestProgressBoxName);
}

Future<void> _tearDownHive() async {
  await Hive.close();
  _tempDir.deleteSync(recursive: true);
}

// ============================================================================
// Fake Repositories / Notifiers
// ============================================================================

class _FakeRegionStateRepository implements RegionStateRepository {
  _FakeRegionStateRepository(this._state);
  final RegionState? _state;

  @override
  RegionState? getState(int regionId) =>
      (_state != null && _state.regionId == regionId) ? _state : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFactionStateRepository implements FactionStateRepository {
  _FakeFactionStateRepository(this._states);
  final Map<String, FactionState> _states;

  @override
  FactionState? getState(String factionId) => _states[factionId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


// ============================================================================
// Fixture builders
// ============================================================================

StaticGameData _buildStaticData({
  List<Rank> ranks = const [],
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
    questTypes: const [],
    questPools: const [],
    personNames: const [],
    travelEvents: const [],
    facilities: const [],
    ranks: ranks,
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
    combatReportKeywords: const [],
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
    hiddenStats: const [],
    battleMemoryTemplates: const [],
  );
}

UserData _buildUserData({
  int gold = 1000,
  int reputation = 0,
  String? shortGoalPinId,
  String? longGoalPinId,
}) {
  return UserData(
    gold: gold,
    region: 3,
    sector: 1,
    lastFreeRecruit: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    reputation: reputation,
    shortGoalPinId: shortGoalPinId,
    longGoalPinId: longGoalPinId,
  );
}

ActiveQuest _buildQuest({
  required String id,
  required QuestStatus status,
  required DateTime endTime,
  int difficulty = 2,
}) {
  return ActiveQuest(
    id: id,
    questPoolId: 'qp_$id',
    questTypeId: 'qt_test',
    difficulty: difficulty,
    region: 3,
    questName: '테스트 의뢰 $id',
  )
    ..status = status
    ..endTime = endTime;
}

class _ContainerSetup {
  _ContainerSetup({
    required this.container,
    required this.snapshot,
  });
  final ProviderContainer container;
  final LivingsphereDashboardSnapshot snapshot;

  void dispose() => container.dispose();
}

/// fixture로 ProviderContainer 구성. Hive UserData 박스 초기화 + 주입 포함.
Future<_ContainerSetup> _buildContainer({
  UserData? userData,
  List<ActiveQuest> quests = const [],
  RegionState? regionState,
  Map<String, FactionState> factions = const {},
  List<ChainQuestProgress> chainProgress = const [],
  List<Rank> ranks = const [],
}) async {
  // 1) Hive 박스 초기화 + fixture 주입.
  final userBox = Hive.box<UserData>(HiveInitializer.userBoxName);
  final questBox = Hive.box<ActiveQuest>(HiveInitializer.questBoxName);
  await userBox.clear();
  await questBox.clear();
  if (userData != null) {
    await userBox.add(userData);
  }
  for (final q in quests) {
    await questBox.add(q);
  }
  // QuestListNotifier 생성자는 state.isEmpty일 때 generateQuests를 호출하는데,
  // 이는 staticData.regions/factionRepo 등 다수 의존성을 요구한다.
  // quest 박스에 sentinel(completed 상태) 의뢰 1개를 항상 추가하여 isEmpty 분기를 회피한다.
  // recommendGoal은 status==inProgress만 채택하므로 sentinel은 결과에 영향 없음.
  await questBox.add(
    ActiveQuest(
      id: '__sentinel__',
      questPoolId: 'qp_sentinel',
      questTypeId: 'qt_sentinel',
      difficulty: 1,
      region: 3,
      questName: 'sentinel',
    )..status = QuestStatus.completed,
  );

  final staticData = _buildStaticData(ranks: ranks);

  // 2) ProviderContainer 구성.
  // userDataProvider/questListProvider는 실제 Notifier가 box를 직접 읽으므로
  // box.add 후 read 시 정상 state 반영. repository 2종은 fake로 격리.
  final container = ProviderContainer(
    overrides: [
      regionStateRepositoryProvider
          .overrideWithValue(_FakeRegionStateRepository(regionState)),
      factionStateRepositoryProvider
          .overrideWithValue(_FakeFactionStateRepository(factions)),
      staticDataProvider.overrideWith((ref) async => staticData),
      chainQuestProgressProvider
          .overrideWith((ref) => Stream.value(chainProgress)),
    ],
  );

  // 3) FutureProvider / StreamProvider pre-warm.
  await container.read(staticDataProvider.future);
  await container.read(chainQuestProgressProvider.future);
  await container.read(chainQuestProgressProvider.future);

  // 4) userDataProvider / questListProvider read하여 첫 _load 트리거.
  container.read(userDataProvider);
  container.read(questListProvider);

  final snapshot = LivingsphereDashboardSnapshot(
    regionId: 3,
    metrics: const {},
    totalCompletionPct: 0,
  );

  return _ContainerSetup(container: container, snapshot: snapshot);
}

/// `Ref<Object?>`를 컨테이너에서 얻기 위한 proxy.
final _proxyRefProvider = Provider<Ref<Object?>>((ref) => ref);

// ============================================================================
// Tests
// ============================================================================

void main() {
  setUpAll(() async {
    await _setUpHive();
  });

  tearDownAll(() async {
    await _tearDownHive();
  });

  group('GoalRecommendationService - 30분 슬롯 단일 후보', () {
    test('#1 의뢰 12분 + difficulty 2 → score 70 primary', () async {
      // remaining = 12분 → progress = 1 - 12/30 = 0.60
      // value = 2 × 5 = 10
      // score = 100 × 0.60 + 10 = 70
      final now = DateTime.now();
      final setup = await _buildContainer(
        userData: _buildUserData(),
        quests: [
          _buildQuest(
            id: 'q1',
            status: QuestStatus.inProgress,
            endTime: now.add(const Duration(minutes: 12, seconds: 30)),
            difficulty: 2,
          ),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('quest:q1'));
      expect(rec.primary!.score, closeTo(70.0, 0.5));
      expect(rec.pinned, isFalse);
      expect(rec.isFallback, isFalse);
      expect(rec.invalidatedPinId, isNull);
    });

    test('#2 명성 200G gap → score 40', () async {
      // currentRep = 800, nextRank = 1000 → gap = 200 → progress = 0.00
      // score = 50 × 0.00 + 40 = 40
      final setup = await _buildContainer(
        userData: _buildUserData(reputation: 800),
        ranks: const [
          Rank(
            grade: 'B',
            name: 'B 랭크',
            requiredReputation: 1000,
            unlockTier: 3,
          ),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('rank:B'));
      expect(rec.primary!.score, closeTo(40.0, 0.5));
    });

    test('#3 명성 20G gap → score 85', () async {
      // currentRep = 980, nextRank = 1000 → gap = 20 → progress = 0.90
      // score = 50 × 0.90 + 40 = 85
      final setup = await _buildContainer(
        userData: _buildUserData(reputation: 980),
        ranks: const [
          Rank(
            grade: 'B',
            name: 'B 랭크',
            requiredReputation: 1000,
            unlockTier: 3,
          ),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('rank:B'));
      expect(rec.primary!.score, closeTo(85.0, 0.5));
    });
  });

  group('GoalRecommendationService - 8시간 슬롯', () {
    test('#4 인프라 Tier 4 진입 (5/6 flag) → score 약 131', () async {
      // unlockedFlags=5, requiredFlags=6 → gap=1, progress=5/6=0.833, value=48
      // score = 100 × 0.833 + 48 = 131.33
      final rs = RegionState(
        regionId: 3,
        infrastructureTier: 3,
        unlockedFlags: const [
          'flag_a',
          'flag_b',
          'flag_c',
          'flag_d',
          'flag_e',
        ],
      );
      final setup = await _buildContainer(
        userData: _buildUserData(),
        regionState: rs,
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.long8Hour,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('infra:3:4'));
      expect(rec.primary!.score, closeTo(131.33, 1.0));
    });

    test('#5 dangerScore=-90 (8시간) → score 140 primary', () async {
      // dangerScore = -90 → progress = 1 - 10/100 = 0.90, value = 50
      // score = 100 × 0.90 + 50 = 140
      final rs = RegionState(
        regionId: 3,
        dangerScore: -90,
      );
      final setup = await _buildContainer(
        userData: _buildUserData(),
        regionState: rs,
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.long8Hour,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('pacify:3'));
      expect(rec.primary!.score, closeTo(140.0, 0.5));
      expect(rec.isFallback, isFalse);
    });
  });

  group('GoalRecommendationService - 핀 정책', () {
    test('#6a 핀 유효 (단일 후보) — pinned=true', () async {
      final setup = await _buildContainer(
        userData: _buildUserData(reputation: 800, shortGoalPinId: 'rank:B'),
        ranks: const [
          Rank(
            grade: 'B',
            name: 'B 랭크',
            requiredReputation: 1000,
            unlockTier: 3,
          ),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('rank:B'));
      expect(rec.pinned, isTrue);
      expect(rec.invalidatedPinId, isNull);
    });

    test('#6b 핀 우선 — 핀(score 낮음)이 자동(score 높음)보다 우선', () async {
      // 후보: quest:q1 (score 70), rank:B (score 40). 핀=rank:B.
      // 핀 매칭 우선이므로 primary=rank:B, 자동(quest:q1)은 alternatives 진입.
      final now = DateTime.now();
      final setup = await _buildContainer(
        userData: _buildUserData(reputation: 800, shortGoalPinId: 'rank:B'),
        quests: [
          _buildQuest(
            id: 'q1',
            status: QuestStatus.inProgress,
            endTime: now.add(const Duration(minutes: 12, seconds: 30)),
            difficulty: 2,
          ),
        ],
        ranks: const [
          Rank(
            grade: 'B',
            name: 'B 랭크',
            requiredReputation: 1000,
            unlockTier: 3,
          ),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('rank:B'),
          reason: '핀 우선이므로 score 낮은 rank:B가 primary여야 한다');
      expect(rec.pinned, isTrue);
      expect(rec.invalidatedPinId, isNull);
      expect(rec.alternatives.any((a) => a.id == 'quest:q1'), isTrue);
    });

    test('#7 핀 무효화 — 의뢰 핀이 후보 풀에 없음 → invalidatedPinId 반환', () async {
      // 핀: quest:q1, quests 빈 리스트 → 후보 0개 + invalidatedPinId='quest:q1'
      // regionState를 trust 4단계로 설정해 다른 임박 후보 발생을 차단한다.
      final setup = await _buildContainer(
        userData: _buildUserData(shortGoalPinId: 'quest:q1'),
        regionState: RegionState(
          regionId: 3,
          settlementTrustLevel: 4,
          infrastructureTier: 4,
        ),
      );
      addTearDown(setup.dispose);

      // 사전 검증: userData.shortGoalPinId 직접 확인
      final preUser = setup.container.read(userDataProvider);
      expect(preUser?.shortGoalPinId, equals('quest:q1'),
          reason: '핀 호출 전 pinId는 유지되어 있어야 한다');

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.invalidatedPinId, equals('quest:q1'));
      expect(rec.pinned, isFalse);
      expect(rec.isFallback, isTrue);

      // 격리 정책 확인 — 서비스가 setShortGoalPin을 호출하지 않으므로
      // 호출 후에도 pinId는 그대로여야 한다.
      final postUser = setup.container.read(userDataProvider);
      expect(postUser?.shortGoalPinId, equals('quest:q1'),
          reason: '서비스는 UserDataNotifier를 호출하지 않아 pinId 그대로');
    });

    test('#7b 핀 무효화 + 자동 추천 공존 — invalidatedPinId 반환 + primary=자동', () async {
      // 핀: quest:ghost (없는 의뢰). 자동 후보로 quest:q1 존재.
      final now = DateTime.now();
      final setup = await _buildContainer(
        userData: _buildUserData(shortGoalPinId: 'quest:ghost'),
        quests: [
          _buildQuest(
            id: 'q1',
            status: QuestStatus.inProgress,
            endTime: now.add(const Duration(minutes: 12, seconds: 30)),
            difficulty: 2,
          ),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.invalidatedPinId, equals('quest:ghost'));
      expect(rec.pinned, isFalse);
      expect(rec.primary, isNotNull);
      expect(rec.primary!.id, equals('quest:q1'));
      expect(rec.isFallback, isFalse);
    });
  });

  group('GoalRecommendationService - fallback', () {
    test('#8 후보 0개 → GoalRecommendation.fallback', () async {
      // 모든 임계 진입 후보를 차단하기 위해 trust 4단계 + Tier 4 + dangerScore=0 설정.
      final setup = await _buildContainer(
        userData: _buildUserData(),
        regionState: RegionState(
          regionId: 3,
          settlementTrustLevel: 4,
          infrastructureTier: 4,
          dangerScore: 0,
        ),
      );
      addTearDown(setup.dispose);

      final shortRec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );
      final longRec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.long8Hour,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(shortRec.primary, isNull);
      expect(shortRec.alternatives, isEmpty);
      expect(shortRec.isFallback, isTrue);
      expect(shortRec.slot, equals(GoalSlot.short30Min));

      expect(longRec.primary, isNull);
      expect(longRec.alternatives, isEmpty);
      expect(longRec.isFallback, isTrue);
      expect(longRec.slot, equals(GoalSlot.long8Hour));
    });

    test('userData null → fallback', () async {
      final setup = await _buildContainer(userData: null);
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.isFallback, isTrue);
      expect(rec.primary, isNull);
    });
  });

  group('GoalRecommendationService - alternatives 정렬·cap', () {
    test('positive 후보 5개일 때 alternatives는 primary 제외 3개로 cap', () async {
      // - q1 12분 d=4 → 100×0.6+20 = 80
      // - q2 6분  d=2 → 100×0.8+10 = 90
      // - q3 24분 d=3 → 100×0.2+15 = 35
      // - q4 18분 d=5 → 100×0.4+25 = 65
      // - q5 3분  d=1 → 100×0.9+5  = 95
      // 정렬: q5(95) > q2(90) > q1(80) > q4(65) > q3(35)
      final now = DateTime.now();
      final setup = await _buildContainer(
        userData: _buildUserData(),
        quests: [
          _buildQuest(
              id: 'q1',
              status: QuestStatus.inProgress,
              endTime: now.add(const Duration(minutes: 12, seconds: 30)),
              difficulty: 4),
          _buildQuest(
              id: 'q2',
              status: QuestStatus.inProgress,
              endTime: now.add(const Duration(minutes: 6, seconds: 30)),
              difficulty: 2),
          _buildQuest(
              id: 'q3',
              status: QuestStatus.inProgress,
              endTime: now.add(const Duration(minutes: 24, seconds: 30)),
              difficulty: 3),
          _buildQuest(
              id: 'q4',
              status: QuestStatus.inProgress,
              endTime: now.add(const Duration(minutes: 18, seconds: 30)),
              difficulty: 5),
          _buildQuest(
              id: 'q5',
              status: QuestStatus.inProgress,
              endTime: now.add(const Duration(minutes: 3, seconds: 30)),
              difficulty: 1),
        ],
      );
      addTearDown(setup.dispose);

      final rec = GoalRecommendationService.recommendGoal(
        slot: GoalSlot.short30Min,
        ref: setup.container.read(_proxyRefProvider),
        snapshot: setup.snapshot,
      );

      expect(rec.primary!.id, equals('quest:q5'));
      expect(rec.alternatives.length, equals(3));
      expect(rec.alternatives[0].id, equals('quest:q2'));
      expect(rec.alternatives[1].id, equals('quest:q1'));
      expect(rec.alternatives[2].id, equals('quest:q4'));
    });
  });
}
