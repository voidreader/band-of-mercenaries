import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_sort_service.dart';

// ─── 헬퍼: ActiveQuest 생성 ───────────────────────────────────────────────
ActiveQuest _makeQuest({
  required String id,
  required int difficulty,
  String questPoolId = 'pool_default',
  String questTypeId = 'type_default',
  bool isChainStep = false,
  String? chainId,
  bool? isAdvancedTrack, // null=일반, false/true=세력 전용
  String? factionTag,
  String? eliteId,
}) {
  return ActiveQuest(
    id: id,
    questPoolId: questPoolId,
    questTypeId: questTypeId,
    difficulty: difficulty,
    region: 1,
    questName: 'test_$id',
    isChainStep: isChainStep ? true : null,
    chainId: chainId,
    isAdvancedTrack: isAdvancedTrack,
    factionTag: factionTag,
    eliteId: eliteId,
  );
}

// ─── 헬퍼: QuestPool 생성 ─────────────────────────────────────────────────
QuestPool _makePool({
  required String id,
  String typeId = 'type_default',
  String? sectorType,
}) {
  return QuestPool(
    id: id,
    name: 'pool_$id',
    type: 1.0,
    difficulty: 1.0,
    minRegionDiff: 0.0,
    maxRegionDiff: 5.0,
    typeId: typeId,
    sectorType: sectorType,
  );
}

// ─── 헬퍼: QuestType 생성 ─────────────────────────────────────────────────
QuestType _makeType({
  required String id,
  required int baseReward,
}) {
  return QuestType(
    id: id,
    name: 'type_$id',
    baseReward: baseReward,
    baseDuration: 300,
    riskFactor: 1.0,
  );
}

// ─── 헬퍼: EliteMonsterData 생성 ──────────────────────────────────────────
EliteMonsterData _makeElite({
  required String id,
  required bool isUnique,
}) {
  return EliteMonsterData(
    id: id,
    name: 'elite_$id',
    description: '',
    isUnique: isUnique,
    typeFamily: 'beast',
    tier: 1,
    power: 100,
    spawnRate: 0.1,
    durationMultiplier: 1.0,
  );
}

// ─── 헬퍼: ChainQuestProgress 생성 ────────────────────────────────────────
ChainQuestProgress _makeChainProgress({
  required String chainId,
  ChainQuestStatus status = ChainQuestStatus.active,
}) {
  return ChainQuestProgress(
    chainId: chainId,
    startedAt: DateTime(2026, 1, 1),
    status: status,
  );
}

void main() {
  // 기본 공통 데이터
  final defaultPool = _makePool(id: 'pool_default', typeId: 'type_default');
  final defaultType = _makeType(id: 'type_default', baseReward: 100);

  group('QuestSortService', () {
    // ── 케이스 1: 빈 입력 ─────────────────────────────────────────────────
    test('빈 quests 입력 → chainTier0 빈, sortedRest 빈', () {
      final result = QuestSortService.sort(
        quests: [],
        chainProgress: [],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [defaultPool],
        questTypes: [defaultType],
        joinedFactionIds: {},
      );

      expect(result.chainTier0, isEmpty);
      expect(result.sortedRest, isEmpty);
    });

    // ── 케이스 2: Tier 0 분리 ─────────────────────────────────────────────
    test('체인 퀘스트 + active progress 일치 → chainTier0에만, sortedRest 제외', () {
      final chainQuest = _makeQuest(
        id: 'q_chain',
        difficulty: 3,
        isChainStep: true,
        chainId: 'chain_01',
      );
      final normalQuest = _makeQuest(id: 'q_normal', difficulty: 2);
      final progress = _makeChainProgress(
        chainId: 'chain_01',
        status: ChainQuestStatus.active,
      );

      final result = QuestSortService.sort(
        quests: [chainQuest, normalQuest],
        chainProgress: [progress],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [defaultPool],
        questTypes: [defaultType],
        joinedFactionIds: {},
      );

      expect(result.chainTier0, contains(chainQuest));
      expect(result.sortedRest, isNot(contains(chainQuest)));
      expect(result.sortedRest, contains(normalQuest));
    });

    // ── 케이스 3: Tier 1 (세력 전용) ─────────────────────────────────────
    test('isFactionExclusive + 가입 세력 일치 → sortedRest 첫 번째(Tier 1)', () {
      final exclusiveQuest = _makeQuest(
        id: 'q_exclusive',
        difficulty: 2,
        isAdvancedTrack: false, // 기본 트랙: isFactionExclusive == true
        factionTag: 'faction_alpha',
      );
      final normalQuest = _makeQuest(id: 'q_normal', difficulty: 3);

      final result = QuestSortService.sort(
        quests: [normalQuest, exclusiveQuest],
        chainProgress: [],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [defaultPool],
        questTypes: [defaultType],
        joinedFactionIds: {'faction_alpha'},
      );

      // Tier 1이 Tier 4보다 먼저 나와야 함
      expect(result.sortedRest.first.id, equals('q_exclusive'));
    });

    // ── 케이스 4: Tier 2 (엘리트) — 유니크 우선 정렬 ────────────────────
    test('엘리트 퀘스트 → Tier 2. 유니크가 보통 엘리트보다 앞서 정렬', () {
      final elitePool = _makePool(id: 'pool_elite', typeId: 'type_default');
      final normalElite = _makeQuest(
        id: 'q_elite_normal',
        difficulty: 3,
        questPoolId: 'pool_elite',
        eliteId: 'elite_01',
      );
      final uniqueElite = _makeQuest(
        id: 'q_elite_unique',
        difficulty: 3,
        questPoolId: 'pool_elite',
        eliteId: 'elite_02',
      );
      final regularQuest = _makeQuest(id: 'q_regular', difficulty: 5);

      final eliteNormal = _makeElite(id: 'elite_01', isUnique: false);
      final eliteUnique = _makeElite(id: 'elite_02', isUnique: true);

      final result = QuestSortService.sort(
        quests: [regularQuest, normalElite, uniqueElite],
        chainProgress: [],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [defaultPool, elitePool],
        questTypes: [defaultType],
        joinedFactionIds: {},
        eliteMonsters: [eliteNormal, eliteUnique],
      );

      // 엘리트 퀘스트 2개가 Tier 2로 일반 퀘스트 앞에 위치해야 함
      final ids = result.sortedRest.map((q) => q.id).toList();
      final uniqueIdx = ids.indexOf('q_elite_unique');
      final normalEliteIdx = ids.indexOf('q_elite_normal');
      final regularIdx = ids.indexOf('q_regular');

      expect(uniqueIdx, lessThan(normalEliteIdx)); // 유니크가 보통 엘리트보다 앞
      expect(normalEliteIdx, lessThan(regularIdx)); // 엘리트가 일반보다 앞
    });

    // ── 케이스 5: Tier 3 (변형 섹터) ─────────────────────────────────────
    test('변형 섹터 타입과 questPool.sectorType 일치 → Tier 3 (일반 Tier 4보다 앞)', () {
      final sectorPool = _makePool(
        id: 'pool_sector',
        typeId: 'type_default',
        sectorType: 'village',
      );
      final sectorQuest = _makeQuest(
        id: 'q_sector',
        difficulty: 2,
        questPoolId: 'pool_sector',
      );
      final normalQuest = _makeQuest(id: 'q_normal', difficulty: 5);

      // 섹터 3이 'village'로 변형된 상태
      final regionState = RegionState(
        regionId: 1,
        sectorChanges: {'3': 'village'},
      );

      final result = QuestSortService.sort(
        quests: [normalQuest, sectorQuest],
        chainProgress: [],
        currentRegion: 1,
        currentSector: 3, // 현재 섹터가 변형된 섹터와 일치
        regionState: regionState,
        questPools: [defaultPool, sectorPool],
        questTypes: [defaultType],
        joinedFactionIds: {},
      );

      final ids = result.sortedRest.map((q) => q.id).toList();
      expect(ids.indexOf('q_sector'), lessThan(ids.indexOf('q_normal')));
    });

    // ── 케이스 6: Tier 4 (일반) ───────────────────────────────────────────
    test('체인/세력/엘리트/변형 섹터 조건 미해당 → sortedRest에 Tier 4로 포함', () {
      final quest = _makeQuest(id: 'q_plain', difficulty: 2);

      final result = QuestSortService.sort(
        quests: [quest],
        chainProgress: [],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [defaultPool],
        questTypes: [defaultType],
        joinedFactionIds: {},
      );

      expect(result.chainTier0, isEmpty);
      expect(result.sortedRest, contains(quest));
    });

    // ── 케이스 7: 같은 tier 정렬 ─────────────────────────────────────────
    test('같은 Tier 내 정렬: estimatedReward 내림차순 → difficulty 오름차순 → id 사전순', () {
      final typeA = _makeType(id: 'type_a', baseReward: 200); // baseReward 높은 타입
      final typeB = _makeType(id: 'type_b', baseReward: 100); // baseReward 낮은 타입
      final poolA = _makePool(id: 'pool_a', typeId: 'type_a');
      final poolB = _makePool(id: 'pool_b', typeId: 'type_b');

      // q_high: reward=200×3=600
      final qHigh = _makeQuest(id: 'q_high', difficulty: 3, questPoolId: 'pool_a');
      // q_mid: reward=100×5=500
      final qMid = _makeQuest(id: 'q_mid', difficulty: 5, questPoolId: 'pool_b');
      // q_low_a: reward=100×2=200, difficulty=2, id=q_low_a
      final qLowA = _makeQuest(id: 'q_low_a', difficulty: 2, questPoolId: 'pool_b');
      // q_low_b: reward=100×2=200, difficulty=2, id=q_low_b (id 사전순으로 q_low_a 뒤)
      final qLowB = _makeQuest(id: 'q_low_b', difficulty: 2, questPoolId: 'pool_b');

      final result = QuestSortService.sort(
        quests: [qLowB, qMid, qLowA, qHigh],
        chainProgress: [],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [poolA, poolB],
        questTypes: [typeA, typeB],
        joinedFactionIds: {},
      );

      final ids = result.sortedRest.map((q) => q.id).toList();
      expect(ids, equals(['q_high', 'q_mid', 'q_low_a', 'q_low_b']));
    });

    // ── 케이스 8: 우선순위 fold — 체인+엘리트 동시 → Tier 0 우선 ────────
    test('체인 + 엘리트 동시 충족 퀘스트 → Tier 0으로만 처리, sortedRest 미포함', () {
      final chainEliteQuest = _makeQuest(
        id: 'q_chain_elite',
        difficulty: 4,
        isChainStep: true,
        chainId: 'chain_02',
        eliteId: 'elite_01',
      );
      final progress = _makeChainProgress(
        chainId: 'chain_02',
        status: ChainQuestStatus.active,
      );

      final result = QuestSortService.sort(
        quests: [chainEliteQuest],
        chainProgress: [progress],
        currentRegion: 1,
        currentSector: 0,
        regionState: null,
        questPools: [defaultPool],
        questTypes: [defaultType],
        joinedFactionIds: {},
        eliteMonsters: [_makeElite(id: 'elite_01', isUnique: false)],
      );

      expect(result.chainTier0, contains(chainEliteQuest));
      expect(result.sortedRest, isNot(contains(chainEliteQuest)));
    });
  });
}
