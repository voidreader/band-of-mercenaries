import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/region_state_effect.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/faction_tag_resolver.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/named_hook_evaluator.dart';
import 'package:band_of_mercenaries/features/quest/domain/region_state_weight_config.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';

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
    // M6 페이즈 4 #3 — 지명 의뢰 hook 평가 컨텍스트
    List<Mercenary> mercenaries = const [],
    List<BandAchievement> bandAchievements = const [],
    String? flagshipMercId,
    Map<String, DateTime> namedQuestCooldowns = const {},
    // M7 페이즈 4 #2 — region 상태(위험도/플래그/cumulative cap) 가중치 평가 컨텍스트
    RegionState? regionState,
    // FR-B2: M8a 세력 지명 의뢰 hook 평가 컨텍스트 — unlockedRegionFlags / activeContactIds
    Map<int, Set<String>> unlockedRegionFlags = const {},
    Set<String> activeContactIds = const {},
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
    final now = DateTime.now();
    // FR-B2: unlockedRegionFlags / activeContactIds / factionReputations 3 신규 필드 채움
    final hookContext = NamedHookContext(
      mercenaries: mercenaries,
      bandAchievements: bandAchievements,
      flagshipMercId: flagshipMercId,
      unlockedRegionFlags: unlockedRegionFlags,
      activeContactIds: activeContactIds,
      factionReputations: factionReputations,
    );
    final generalPools = filtered
        .where((p) => !p.isFactionExclusive)
        .where((p) => !p.isFixed)                           // REQ-03: 고정 의뢰 제외
        .where((p) => p.minTrustLevel <= currentTrustLevel) // REQ-04: 신뢰도 단계 필터
        .where((p) => sectorType != null
            ? p.sectorType == sectorType
            : p.sectorType == null)
        .where((p) {
          // M6 페이즈 4 #3 — 지명 의뢰 hook + 쿨다운 평가
          if (!p.isNamed) return true;
          if (!NamedHookEvaluator.evaluateNamedHook(p, hookContext)) return false;
          return NamedHookEvaluator.isCooldownPassed(
              namedQuestCooldowns[p.id], now);
        })
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
      regionState,
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
      // FR-B5: 세력 지명 의뢰는 pool.factionTag를 고정 사용, 그 외는 FactionTagResolver 결과 사용
      final String? tag;
      if (pool.isNamed && pool.factionTag != null) {
        tag = pool.factionTag;
      } else {
        tag = FactionTagResolver.resolve(
          regionId: regionId,
          joinedFactionIds: joinedFactionIds,
          clueLevelsInRegion: clueLevelsInRegion,
          hostileFactionIds: hostileFactionIds,
          proximityTier: proximityTier,
          random: random,
        );
      }
      final repReward = tag != null ? FactionTagResolver.tagReputationGain(proximityTier) : null;
      final questType = questTypes.firstWhere(
        (t) => t.id == pool.typeId,
        orElse: () => questTypes.first,
      );
      // M6 페이즈 4 #3 — flagship 의뢰는 발급 시점의 flagshipMercId 동결
      final namedTargetMercId =
          (pool.isNamed && pool.namedHookType == 'flagship')
              ? flagshipMercId
              : null;
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
        namedTargetMercId: namedTargetMercId,
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

  /// M7 페이즈 4 #2 — 의뢰 풀 최종 가중치 계산.
  ///
  /// 다음 순서로 가중치를 산출하며, 비노출 조건(required/excluded) 위반 또는
  /// NewbieGate 0 weight인 경우 0.0을 반환한다.
  ///
  /// 1. NewbieGate base weight (1) — 0이면 즉시 0 반환
  /// 2. region_state_required 비노출 검증 — 현재 단계와 불일치 시 0 반환
  /// 3. region_state_excluded 비노출 검증 — 현재 단계와 일치 시 0 반환
  /// 4. dangerLevel × quest_type 매트릭스 multiplier (곱)
  /// 5. unlockedFlags × quest_type multiplier (곱, 다중 합산)
  /// 6. cumulative cap 도달 후 노출 빈도 축소 (곱)
  /// 7. 지명 의뢰(`isNamed=true`)는 +α=3 가산 (M6 페이즈 4 #3)
  static double computeFinalWeight({
    required QuestPool pool,
    required RegionState? regionState,
    required NewbieGate gate,
  }) {
    // 1. NewbieGate base weight
    var weight = _weightFor(gate, pool.difficulty);
    if (weight <= 0) return 0.0;

    // 2. 비노출 검증 — region_state_required
    if (regionState != null && pool.regionStateRequired != null) {
      final required = DangerLevelResolver.fromLowercaseString(pool.regionStateRequired!);
      if (required != null) {
        final currentLevel = DangerLevelResolver.fromCacheInt(regionState.currentDangerLevel);
        if (currentLevel != required) return 0.0;
      }
    }

    // 3. 비노출 검증 — region_state_excluded
    if (regionState != null && pool.regionStateExcluded != null) {
      final excluded = DangerLevelResolver.fromLowercaseString(pool.regionStateExcluded!);
      if (excluded != null) {
        final currentLevel = DangerLevelResolver.fromCacheInt(regionState.currentDangerLevel);
        if (currentLevel == excluded) return 0.0;
      }
    }

    // 4. dangerLevel 가중치
    final level = regionState != null
        ? (DangerLevelResolver.fromCacheInt(regionState.currentDangerLevel) ?? DangerLevel.peaceful)
        : DangerLevel.peaceful;
    final dangerMulti = RegionStateWeightConfig.dangerLevelMultiplier[level]?[pool.typeId] ?? 1.0;
    weight *= dangerMulti;

    // 5. unlockedFlags 가중치 합산
    if (regionState != null) {
      for (final flag in regionState.unlockedFlags) {
        final flagMulti = RegionStateWeightConfig.flagMultipliers[flag]?[pool.typeId];
        if (flagMulti != null) weight *= flagMulti;
      }
    }

    // 6. cumulative cap 도달 후 노출 빈도 축소
    final effect = pool.regionStateEffect;
    if (effect is CumulativeEffect && regionState != null) {
      if (regionState.unlockedFlags.contains(effect.thresholdFlag)) {
        weight *= RegionStateWeightConfig.cumulativeCapReachedMultiplier;
      }
    }

    // 7. 지명 의뢰 +α=3 가중치 (M6 페이즈 4 #3, 가산)
    if (pool.isNamed) weight += 3.0;

    return weight;
  }

  /// weight 0인 풀을 사전 제외하고, 비복원 가중 샘플링으로 [count]개 선택.
  ///
  /// 가중치 계산은 [computeFinalWeight]에 일원화 (M7 페이즈 4 #2).
  /// M6 페이즈 4 #3 지명 의뢰 α=3 가중치도 동일 경로로 적용된다.
  static List<QuestPool> _weightedSample(
    List<QuestPool> pools,
    int count,
    NewbieGate gate,
    Random random,
    RegionState? regionState,
  ) {
    if (count <= 0) return const [];
    final weighted = <({QuestPool pool, double weight})>[];
    for (final p in pools) {
      final w = computeFinalWeight(pool: p, regionState: regionState, gate: gate);
      if (w <= 0) continue;
      weighted.add((pool: p, weight: w));
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
