import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

/// 파견 화면 퀘스트 정렬 결과
class QuestSortResult {
  final List<ActiveQuest> chainTier0; // ChainTopSection이 별도 렌더 (일반 목록에서 제거)
  final List<ActiveQuest> settlementTier; // 거점 사건 (settlement_ prefix, sortedRest 최상단 포함)
  final List<ActiveQuest> sortedRest; // settlementTier + Tier 1~4 정렬된 결과

  const QuestSortResult({
    required this.chainTier0,
    required this.settlementTier,
    required this.sortedRest,
  });
}

/// 파견 화면 퀘스트 5계층 정렬 순수 서비스
///
/// 계층 우선순위:
/// - Tier 0: 체인 다음 단계 (별도 섹션 렌더, 목록에서 제거)
/// - Tier 1: 세력 전용 퀘스트 (플레이어가 가입한 세력)
/// - Tier 2: 엘리트 퀘스트 (유니크 → 보통 순)
/// - Tier 3: 변형 섹터 전용 퀘스트 (현재 섹터 변형 타입 일치)
/// - Tier 4: 일반 퀘스트
class QuestSortService {
  static QuestSortResult sort({
    required List<ActiveQuest> quests,
    required List<ChainQuestProgress> chainProgress,
    required int currentRegion,
    required int currentSector,
    required RegionState? regionState,
    required List<QuestPool> questPools,
    required List<QuestType> questTypes,
    required Set<String> joinedFactionIds,
    List<EliteMonsterData> eliteMonsters = const [],
  }) {
    // 성능 최적화: 1회 인덱싱으로 O(1) 조회
    final poolMap = {for (final p in questPools) p.id: p};
    final typeMap = {for (final t in questTypes) t.id: t};
    // isUnique 판별을 위한 엘리트 인덱스 (ActiveQuest에 isUnique 필드 없음)
    final eliteMap = {for (final e in eliteMonsters) e.id: e};

    // active 상태 체인의 chainId 집합 — Tier 0 판별에 사용
    final activeChainIds = chainProgress
        .where((p) => p.status == ChainQuestStatus.active)
        .map((p) => p.chainId)
        .toSet();

    // 현재 섹터의 변형 타입 (없으면 null)
    final currentSectorTransform =
        regionState?.sectorChanges[currentSector.toString()];

    final chainTier0 = <ActiveQuest>[];
    final settlementTier = <ActiveQuest>[];
    final tier1 = <ActiveQuest>[];
    final tier2 = <ActiveQuest>[];
    final tier3 = <ActiveQuest>[];
    final tier4 = <ActiveQuest>[];

    for (final q in quests) {
      if (q.isChainQuest &&
          q.chainId != null &&
          activeChainIds.contains(q.chainId)) {
        if (q.isSettlementStep) {
          // 거점 사건(settlement_ prefix)은 일반 목록 최상단으로 분리
          settlementTier.add(q);
        } else {
          // Tier 0: 현재 active 단계의 체인 퀘스트 (ChainTopSection 렌더)
          chainTier0.add(q);
        }
      } else if (q.isFactionExclusive &&
          q.factionTag != null &&
          joinedFactionIds.contains(q.factionTag)) {
        // Tier 1: 플레이어가 가입한 세력의 전용 퀘스트
        tier1.add(q);
      } else if (q.isElite) {
        // Tier 2: 엘리트 퀘스트
        tier2.add(q);
      } else if (_isSectorTransformQuest(q, poolMap, currentSectorTransform)) {
        // Tier 3: 현재 변형 섹터와 일치하는 전용 퀘스트
        tier3.add(q);
      } else {
        // Tier 4: 일반 퀘스트
        tier4.add(q);
      }
    }

    // 각 Tier 내 정렬 적용
    _sortByEstimatedReward(settlementTier, poolMap, typeMap);
    _sortByEstimatedReward(tier1, poolMap, typeMap);
    _sortTier2(tier2, poolMap, typeMap, eliteMap);
    _sortByEstimatedReward(tier3, poolMap, typeMap);
    _sortByEstimatedReward(tier4, poolMap, typeMap);

    return QuestSortResult(
      chainTier0: chainTier0,
      settlementTier: settlementTier,
      sortedRest: [...settlementTier, ...tier1, ...tier2, ...tier3, ...tier4],
    );
  }

  /// 현재 변형 섹터 타입과 일치하는 퀘스트 풀인지 확인
  static bool _isSectorTransformQuest(
    ActiveQuest q,
    Map<String, QuestPool> poolMap,
    String? currentSectorTransform,
  ) {
    if (currentSectorTransform == null) return false;
    final pool = poolMap[q.questPoolId];
    if (pool == null || pool.sectorType == null) return false;
    return pool.sectorType == currentSectorTransform;
  }

  /// 추정 보상 기준 동일 Tier 내 정렬
  ///
  /// 정렬 키 (순서대로):
  /// 1. estimatedReward 내림차순 (높을수록 위)
  /// 2. difficulty 오름차순 (낮을수록 위 — 같은 보상이라면 쉬운 퀘스트 우선)
  /// 3. id 오름차순 (사전순 — 결정론적 안정 정렬 보장)
  static void _sortByEstimatedReward(
    List<ActiveQuest> quests,
    Map<String, QuestPool> poolMap,
    Map<String, QuestType> typeMap,
  ) {
    quests.sort((a, b) {
      final rewardA = _estimatedReward(a, poolMap, typeMap);
      final rewardB = _estimatedReward(b, poolMap, typeMap);

      final cmpReward = rewardB.compareTo(rewardA); // 내림차순
      if (cmpReward != 0) return cmpReward;

      final cmpDiff = a.difficulty.compareTo(b.difficulty); // 오름차순
      if (cmpDiff != 0) return cmpDiff;

      return a.id.compareTo(b.id); // 오름차순 (사전순)
    });
  }

  /// Tier 2 (엘리트) 전용 정렬: 유니크 먼저, 그 다음 보통 엘리트
  static void _sortTier2(
    List<ActiveQuest> quests,
    Map<String, QuestPool> poolMap,
    Map<String, QuestType> typeMap,
    Map<String, EliteMonsterData> eliteMap,
  ) {
    quests.sort((a, b) {
      // 유니크 여부: isUnique는 ActiveQuest에 없으므로 EliteMonsterData에서 lookup
      final aUnique = a.eliteId != null && (eliteMap[a.eliteId]?.isUnique ?? false);
      final bUnique = b.eliteId != null && (eliteMap[b.eliteId]?.isUnique ?? false);

      if (aUnique != bUnique) {
        // 유니크를 먼저 (true > false)
        return aUnique ? -1 : 1;
      }

      // 같은 유니크 여부이면 추정 보상 기준 정렬
      final rewardA = _estimatedReward(a, poolMap, typeMap);
      final rewardB = _estimatedReward(b, poolMap, typeMap);

      final cmpReward = rewardB.compareTo(rewardA); // 내림차순
      if (cmpReward != 0) return cmpReward;

      final cmpDiff = a.difficulty.compareTo(b.difficulty); // 오름차순
      if (cmpDiff != 0) return cmpDiff;

      return a.id.compareTo(b.id); // 오름차순 (사전순)
    });
  }

  /// 퀘스트 추정 보상 계산
  ///
  /// pending 상태에서 rewardGold가 null이므로 QuestType.baseReward × difficulty 추정값 사용.
  static int _estimatedReward(
    ActiveQuest q,
    Map<String, QuestPool> poolMap,
    Map<String, QuestType> typeMap,
  ) {
    final pool = poolMap[q.questPoolId];
    if (pool == null) return 0;

    final questType = typeMap[pool.typeId];
    if (questType == null) return 0;

    return questType.baseReward * q.difficulty;
  }
}
