import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/faction_tag_resolver.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';

class QuestGenerator {
  static const _uuid = Uuid();

  static List<ActiveQuest> generateQuests({
    required int regionTier,
    required int regionId,
    required List<QuestPool> questPools,
    required List<QuestType> questTypes,
    required int count,
    required Random random,
    required List<String> joinedFactionIds,
    required Map<String, int> factionReputations,
    required Map<String, int> clueLevelsInRegion,
    required Set<String> cooldownExclusiveQuestIds,
    required int activeSlotCount,
    int proximityTier = 3,
    List<String> hostileFactionIds = const [],
    List<EliteMonsterData> eliteMonsters = const [],
    List<String> regionEnvironmentTags = const [],
    Set<String> triggeredDiscoveries = const {},
    int? currentSectorIndex,
    Map<String, String>? sectorChanges,
    int currentTrustLevel = 0, // 신규 — 거점 신뢰도 단계 (페이즈 4 #5에서 RegionStateRepository.getSettlementTrust(regionId).level로 주입 예정)
    String? currentChainId, // M5 페이즈 4 #3 — 강제 spawn 분기용 현재 활성 체인 ID
    int? currentChainStep,  // M5 페이즈 4 #3 — 강제 spawn 분기용 현재 체인 단계
    NewbieGate gate = NewbieGate.normal, // 신규 유저 보호 게이트 (F/E/normal). 풀 weight 분기에 사용.
  }) {
    // 1. 기본 티어 필터
    final filtered = questPools
        .where((p) => p.minRegionDiff <= regionTier && p.maxRegionDiff >= regionTier)
        .toList();
    if (filtered.isEmpty) return [];

    // 2. 섹터 타입 결정
    final sectorType = (currentSectorIndex != null && sectorChanges != null)
        ? sectorChanges[currentSectorIndex.toString()]
        : null;

    // 3. 전용/일반 분리
    final exclusivePools = filtered.where((p) => p.isFactionExclusive).toList();
    final generalPools = filtered
        .where((p) => !p.isFactionExclusive)
        .where((p) => !p.isFixed)                           // REQ-03: 고정 의뢰 제외
        .where((p) => p.minTrustLevel <= currentTrustLevel) // REQ-04: 신뢰도 단계 필터
        .where((p) => sectorType != null
            ? p.sectorType == sectorType
            : p.sectorType == null)
        .toList();

    // 4. 전용 퀘스트 후보 필터링
    final eligibleExclusive = exclusivePools.where((p) =>
        p.factionTag != null &&
        joinedFactionIds.contains(p.factionTag) &&
        !hostileFactionIds.contains(p.factionTag) &&
        (factionReputations[p.factionTag] ?? 0) >= p.minReputation &&
        !cooldownExclusiveQuestIds.contains(p.id)).toList();
    eligibleExclusive.shuffle(random);

    // 5. 전용 노출 상한 계산
    int exclusiveCap = min(joinedFactionIds.length * 2, (activeSlotCount * 0.5).floor());
    exclusiveCap = min(exclusiveCap, count);
    final selectedExclusivePools = eligibleExclusive.take(exclusiveCap).toList();

    // 6. 일반 퀘스트 채우기 — 신규 유저 게이트(NewbieGate) weighted sampling
    final remainingCount = count - selectedExclusivePools.length;
    final selectedGeneralPools = _weightedSample(
      generalPools,
      remainingCount,
      gate,
      random,
    );

    // 7. ActiveQuest 생성
    final results = <ActiveQuest>[];

    // 전용 퀘스트
    for (final pool in selectedExclusivePools) {
      final isAdvanced = pool.minReputation >= 61;
      final repReward = isAdvanced ? (8 + random.nextInt(3)) : (5 + random.nextInt(3));
      final questType = questTypes.firstWhere(
        (t) => t.id == pool.typeId,
        orElse: () => questTypes.first,
      );
      results.add(ActiveQuest(
        id: _uuid.v4(),
        questPoolId: pool.id,
        questTypeId: questType.id,
        difficulty: pool.difficulty.round(),
        region: regionId,
        questName: pool.name,
        createdAt: DateTime.now(),
        factionTag: pool.factionTag,
        reputationReward: repReward,
        isAdvancedTrack: isAdvanced,
        specialFlags: pool.specialFlags.isEmpty ? null : Map<String, dynamic>.from(pool.specialFlags),
      ));
    }

    // 일반 퀘스트
    for (final pool in selectedGeneralPools) {
      final tag = FactionTagResolver.resolve(
        regionId: regionId,
        joinedFactionIds: joinedFactionIds,
        clueLevelsInRegion: clueLevelsInRegion,
        hostileFactionIds: hostileFactionIds,
        proximityTier: proximityTier,
        random: random,
      );
      final repReward = tag != null ? FactionTagResolver.tagReputationGain(proximityTier) : null;
      final questType = questTypes.firstWhere(
        (t) => t.id == pool.typeId,
        orElse: () => questTypes.first,
      );
      results.add(ActiveQuest(
        id: _uuid.v4(),
        questPoolId: pool.id,
        questTypeId: questType.id,
        difficulty: pool.difficulty.round(),
        region: regionId,
        questName: pool.name,
        createdAt: DateTime.now(),
        factionTag: tag,
        reputationReward: repReward,
        isAdvancedTrack: null,
        specialFlags: pool.specialFlags.isEmpty ? null : Map<String, dynamic>.from(pool.specialFlags),
      ));
    }

    // 8. 엘리트 퀘스트 생성
    const maxEliteCount = 2;
    final normalCandidates = eliteMonsters
        .where((m) => !m.isUnique && m.environmentTags.any(regionEnvironmentTags.contains))
        .toList();
    final uniqueCandidates = eliteMonsters
        .where((m) => m.isUnique && triggeredDiscoveries.any((d) => d.endsWith('_${m.id}')))
        .toList();
    final eliteCandidates = [...normalCandidates, ...uniqueCandidates];
    int eliteGenerated = 0;
    for (final monster in eliteCandidates) {
      if (eliteGenerated >= maxEliteCount) break;
      // M5 페이즈 4 #3 — settlement_3_pyegwang_reopen step 3에서 거대 박쥐 강제 spawn
      // TODO(M6+): elite_monsters에 fixed_chain_id/fixed_step 컬럼 또는 매핑 테이블 도입 시 하드코딩 제거
      final isSettlement3Step3 = currentChainId == 'settlement_3_pyegwang_reopen' && currentChainStep == 3;
      final shouldForceSpawn = isSettlement3Step3 && monster.id == 'elite_giant_bat';
      if (shouldForceSpawn || random.nextDouble() < monster.spawnRate) {
        final questName = monster.isUnique
            ? '[유니크] ${monster.name}'
            : '[엘리트] ${monster.name}';
        results.add(ActiveQuest(
          id: _uuid.v4(),
          questPoolId: 'elite_${monster.id}',
          questTypeId: 'raid',
          difficulty: monster.tier,
          region: regionId,
          questName: questName,
          createdAt: DateTime.now(),
          eliteId: monster.id,
          status: QuestStatus.pending,
        ));
        eliteGenerated++;
      }
    }

    return results;
  }

  /// 신규 유저 게이트별 difficulty weight.
  ///
  /// - newbieF: d1=1.0 / 그 외=0
  /// - newbieE: d1=1.0 / d2=0.25 / 그 외=0
  /// - normal: 모두 1.0 (균등 sampling과 통계적 동치)
  static double _weightFor(NewbieGate gate, double difficulty) {
    final d = difficulty.round();
    switch (gate) {
      case NewbieGate.newbieF:
        return d == 1 ? 1.0 : 0.0;
      case NewbieGate.newbieE:
        if (d == 1) return 1.0;
        if (d == 2) return 0.25;
        return 0.0;
      case NewbieGate.normal:
        return 1.0;
    }
  }

  /// weight 0인 풀을 사전 제외하고, 비복원 가중 샘플링으로 [count]개 선택.
  static List<QuestPool> _weightedSample(
    List<QuestPool> pools,
    int count,
    NewbieGate gate,
    Random random,
  ) {
    if (count <= 0) return const [];
    final weighted = <({QuestPool pool, double weight})>[];
    for (final p in pools) {
      final w = _weightFor(gate, p.difficulty);
      if (w > 0) weighted.add((pool: p, weight: w));
    }
    final selected = <QuestPool>[];
    for (var i = 0; i < count; i++) {
      var total = 0.0;
      for (final e in weighted) {
        total += e.weight;
      }
      if (total <= 0) break;
      var roll = random.nextDouble() * total;
      for (var j = 0; j < weighted.length; j++) {
        roll -= weighted[j].weight;
        if (roll <= 0) {
          selected.add(weighted[j].pool);
          weighted.removeAt(j);
          break;
        }
      }
    }
    return selected;
  }
}
