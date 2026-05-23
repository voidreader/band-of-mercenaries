import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart'
    show CraftingService, RecipeState;
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_metrics_config.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_infrastructure_config.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

/// M8.5 페이즈 4 #1 — 30분/8시간 목표 추천 서비스.
///
/// FR-8~11 — 14종 후보(30분 7 + 8시간 7) 점수화 + 핀 우선 + invalidatedPinId 반환.
/// 정적 메서드만 제공하며, 무효 pinId는 `GoalRecommendation.invalidatedPinId`로
/// 반환만 한다. `UserDataNotifier`를 직접 호출하지 않으며, UI/listener가
/// post-frame에서 `setShortGoalPin(null)` / `setLongGoalPin(null)`로 정리한다.
class GoalRecommendationService {
  const GoalRecommendationService._();

  /// MVP 대상 region (region 3 고정).
  static const int _regionId = 3;

  /// 30분 또는 8시간 슬롯의 목표 추천을 반환한다.
  ///
  /// `gameTickProvider` watch는 호출자(provider) 책임이다.
  static GoalRecommendation recommendGoal({
    required GoalSlot slot,
    required Ref<Object?> ref,
    required LivingsphereDashboardSnapshot snapshot,
  }) {
    final userData = ref.read(userDataProvider);
    if (userData == null) {
      return GoalRecommendation.fallback(slot);
    }

    final candidates = slot == GoalSlot.short30Min
        ? _collectShortTermCandidates(ref, userData)
        : _collectLongTermCandidates(ref, userData);

    // FR-10: score = baseWeight × clamp(progressFactor, 0~1) + clamp(valueFactor, 0~50)
    final scored = candidates.map((c) {
      final p = c.progressFactor.clamp(0.0, 1.0);
      final v = c.valueFactor.clamp(0.0, 50.0);
      final score = c.baseWeight * p + v;
      return c.copyWith(score: score);
    }).toList();

    // FR-10: 정렬 — score desc, baseWeight desc, id asc
    scored.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      final w = b.baseWeight.compareTo(a.baseWeight);
      if (w != 0) return w;
      return a.id.compareTo(b.id);
    });

    // FR-10: score > 0인 후보만 노출 (cap 4 = primary 1 + alternatives 3)
    final positive = scored.where((c) => c.score > 0).toList();

    // 핀 처리 (FR-10/11)
    final pinId = slot == GoalSlot.short30Min
        ? userData.shortGoalPinId
        : userData.longGoalPinId;

    GoalCandidate? primary;
    var pinned = false;
    String? invalidatedPinId;

    if (pinId != null) {
      // 후보 풀(positive만)에서 pinId + isValid 매칭.
      // positive 외 isValid=false 후보가 풀에 남아 있을 수도 있으므로
      // 전체 scored까지 확인하여 "후보는 있지만 무효"인 케이스도 invalidatedPinId로 보고한다.
      final matched =
          positive.where((c) => c.id == pinId && c.isValid).firstOrNull;
      if (matched != null) {
        primary = matched;
        pinned = true;
      } else {
        invalidatedPinId = pinId;
      }
    }

    primary ??= positive.firstOrNull;

    if (primary == null) {
      // 후보 0개 또는 모두 score≤0 → fallback. invalidatedPinId는 유지하여 반환.
      return GoalRecommendation.fallback(slot).copyWith(
        invalidatedPinId: invalidatedPinId,
      );
    }

    final primaryId = primary.id;
    final alternatives =
        positive.where((c) => c.id != primaryId).take(3).toList();

    return GoalRecommendation(
      slot: slot,
      primary: primary,
      pinned: pinned,
      alternatives: alternatives,
      isFallback: false,
      invalidatedPinId: invalidatedPinId,
    );
  }

  // ===========================================================================
  // 30분 슬롯 후보 수집 (FR-8) — 7종 후보
  // ===========================================================================
  static List<GoalCandidate> _collectShortTermCandidates(
    Ref<Object?> ref,
    UserData userData,
  ) {
    final candidates = <GoalCandidate>[];
    final now = DateTime.now();

    // 1. 진행 중 의뢰 (ActiveQuest.status == inProgress)
    final quests = ref.read(questListProvider);
    for (final q in quests) {
      if (q.status != QuestStatus.inProgress || q.endTime == null) continue;
      final remainingMin = q.endTime!.difference(now).inMinutes;
      if (remainingMin < 0) continue; // 이미 만료
      // baseWeight=100, progressFactor=1 - remaining/30, valueFactor=difficulty*5
      final progress = (1 - remainingMin / 30).clamp(0.0, 1.0).toDouble();
      candidates.add(GoalCandidate(
        id: 'quest:${q.id}',
        slot: GoalSlot.short30Min,
        label: '의뢰 완료까지 $remainingMin분',
        kind: GoalCandidateKind.inProgressQuest,
        baseWeight: 100,
        progressFactor: progress,
        valueFactor: (q.difficulty * 5).clamp(0, 50).toDouble(),
        score: 0,
        jumpTarget: const GoalJumpTarget.dispatch(),
        isValid: true,
      ));
    }

    // 2. 진행 중 이동 (UserData.moveEndTime != null && isMoving)
    if (userData.isMoving && userData.moveEndTime != null) {
      final remainingMin = userData.moveEndTime!.difference(now).inMinutes;
      if (remainingMin >= 0) {
        // moveStartTime이 없으므로 잔여 거리만 추정 (1칸=30초 정책).
        // 잔여 분 → 잔여 거리: minutes * 2 (≈ seconds/30).
        final remainingSecs =
            userData.moveEndTime!.difference(now).inSeconds.clamp(0, 1 << 30);
        final remainingDistance = (remainingSecs / 30).round().clamp(1, 25);
        candidates.add(GoalCandidate(
          id: 'movement:${userData.region}',
          slot: GoalSlot.short30Min,
          label: '이동 완료까지 $remainingMin분',
          kind: GoalCandidateKind.movement,
          baseWeight: 80,
          progressFactor: (1 - remainingMin / 30).clamp(0.0, 1.0).toDouble(),
          valueFactor: (remainingDistance * 2).clamp(0, 50).toDouble(),
          score: 0,
          jumpTarget: GoalJumpTarget.movement(regionId: userData.region),
          isValid: true,
        ));
      }
    }

    // 3. 진행 중 조사 (UserData.investigationEndTime)
    if (userData.investigationEndTime != null) {
      final remainingMin =
          userData.investigationEndTime!.difference(now).inMinutes;
      if (remainingMin >= 0) {
        // regionTier: staticData.regions에서 조회. 없으면 fallback 3.
        final staticData = ref.read(staticDataProvider).valueOrNull;
        var regionTier = 3;
        if (staticData != null) {
          final region = staticData.regions
              .where((r) => r.region == userData.region)
              .firstOrNull;
          regionTier = region?.regionTier ?? 3;
        }
        candidates.add(GoalCandidate(
          id: 'investigation:${userData.region}',
          slot: GoalSlot.short30Min,
          label: '지역 조사 완료까지 $remainingMin분',
          kind: GoalCandidateKind.investigation,
          baseWeight: 80,
          progressFactor: (1 - remainingMin / 30).clamp(0.0, 1.0).toDouble(),
          valueFactor: (regionTier * 3).clamp(0, 50).toDouble(),
          score: 0,
          jumpTarget: GoalJumpTarget.movement(regionId: userData.region),
          isValid: true,
        ));
      }
    }

    // 4. 진행 중 건설 (UserData.constructionEndTime + constructionFacilityId)
    if (userData.constructionEndTime != null &&
        userData.constructionFacilityId != null) {
      final remainingMin =
          userData.constructionEndTime!.difference(now).inMinutes;
      if (remainingMin >= 0) {
        final facilityId = userData.constructionFacilityId!;
        // 현재 시설 레벨 — 건설 중인 단계는 currentLevel + 1로 가정.
        final currentLevel = userData.facilities[facilityId] ?? 0;
        final nextLevel = currentLevel + 1;
        candidates.add(GoalCandidate(
          id: 'construction:$facilityId',
          slot: GoalSlot.short30Min,
          label: '시설 건설 완료까지 $remainingMin분',
          kind: GoalCandidateKind.construction,
          baseWeight: 80,
          progressFactor: (1 - remainingMin / 30).clamp(0.0, 1.0).toDouble(),
          valueFactor: (nextLevel * 4).clamp(0, 50).toDouble(),
          score: 0,
          // GoalJumpTarget에 시설 탭 전용 케이스가 없어 movement로 대체.
          jumpTarget: const GoalJumpTarget.movement(),
          isValid: true,
        ));
      }
    }

    // 5. 임박 신뢰도 임계 (region 3, nextTrustThreshold - currentTrust <= 30)
    final rs = ref.read(regionStateRepositoryProvider).getState(_regionId);
    final currentTrust = rs?.settlementTrust ?? 0;
    final currentTrustLevel = rs?.settlementTrustLevel ?? 1;
    final nextTrustLevel = currentTrustLevel + 1;
    if (nextTrustLevel <= 4) {
      final nextThreshold = _trustThreshold(nextTrustLevel);
      final gap = nextThreshold - currentTrust;
      if (gap > 0 && gap <= LivingsphereMetricsConfig.imminentTrustGap) {
        candidates.add(GoalCandidate(
          id: 'trust:$_regionId:$nextTrustLevel',
          slot: GoalSlot.short30Min,
          label: '신뢰도 $nextTrustLevel단계까지 $gap 점',
          kind: GoalCandidateKind.imminentTrust,
          baseWeight: 60,
          progressFactor:
              (1 - gap / LivingsphereMetricsConfig.imminentTrustGap)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          valueFactor: (nextTrustLevel * 8).clamp(0, 50).toDouble(),
          score: 0,
          jumpTarget: GoalJumpTarget.settlementFacility(
            facility: VillageFacility.chiefHouse,
            regionId: _regionId,
          ),
          isValid: true,
        ));
      }
    }

    // 6. 임박 인프라 flag (region 3, 다음 tier까지 flag 1개 부족 — FR-8)
    final currentTier = rs?.infrastructureTier ?? 1;
    final unlockedFlags = rs?.unlockedFlags ?? const <String>[];
    final nextTier = currentTier + 1;
    if (nextTier <= 4) {
      final requiredFlags =
          SettlementInfrastructureConfig.infraTierThresholds[nextTier] ?? 99;
      final flagGap = requiredFlags - unlockedFlags.length;
      // 30분 슬롯은 "1개 부족"만 임박 후보로. 명세 FR-8 라인 99 참조.
      if (flagGap == 1) {
        candidates.add(GoalCandidate(
          id: 'infra:$_regionId:$nextTier',
          slot: GoalSlot.short30Min,
          label: '거점 Tier $nextTier까지 flag $flagGap개',
          kind: GoalCandidateKind.imminentInfra,
          baseWeight: 60,
          // progressFactor 분모는 2로 유지 — flagGap=1 시 0.5.
          progressFactor: (1 - flagGap / 2).clamp(0.0, 1.0).toDouble(),
          valueFactor: 30,
          score: 0,
          jumpTarget: GoalJumpTarget.settlementFacility(
            facility: VillageFacility.chiefHouse,
            regionId: _regionId,
          ),
          isValid: true,
        ));
      }
    }

    // 7. 임박 명성 랭크 (nextRankRep - currentRep <= 200)
    final currentRep = userData.reputation;
    final nextRank = _findNextRankThreshold(currentRep, ref);
    if (nextRank != null) {
      final gap = nextRank.threshold - currentRep;
      if (gap > 0 && gap <= LivingsphereMetricsConfig.imminentRankRepGap) {
        candidates.add(GoalCandidate(
          id: 'rank:${nextRank.grade}',
          slot: GoalSlot.short30Min,
          label: '${nextRank.grade} 랭크까지 $gap G',
          kind: GoalCandidateKind.imminentRank,
          baseWeight: 50,
          progressFactor:
              (1 - gap / LivingsphereMetricsConfig.imminentRankRepGap)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          valueFactor: 40,
          score: 0,
          jumpTarget: const GoalJumpTarget.dispatch(),
          isValid: true,
        ));
      }
    }

    return candidates;
  }

  // ===========================================================================
  // 8시간 슬롯 후보 수집 (FR-9) — 7종 후보
  // ===========================================================================
  static List<GoalCandidate> _collectLongTermCandidates(
    Ref<Object?> ref,
    UserData userData,
  ) {
    final candidates = <GoalCandidate>[];
    final rs = ref.read(regionStateRepositoryProvider).getState(_regionId);

    // 1. 다음 신뢰도 단계 (nextThreshold - currentTrust <= 80)
    final currentTrust = rs?.settlementTrust ?? 0;
    final currentTrustLevel = rs?.settlementTrustLevel ?? 1;
    final nextTrustLevel = currentTrustLevel + 1;
    if (nextTrustLevel <= 4) {
      final nextThreshold = _trustThreshold(nextTrustLevel);
      final gap = nextThreshold - currentTrust;
      if (gap > 0 && gap <= LivingsphereMetricsConfig.longTermTrustGap) {
        candidates.add(GoalCandidate(
          id: 'trust:$_regionId:$nextTrustLevel',
          slot: GoalSlot.long8Hour,
          label: '신뢰도 $nextTrustLevel단계까지 $gap 점',
          kind: GoalCandidateKind.imminentTrust,
          baseWeight: 100,
          progressFactor:
              (1 - gap / LivingsphereMetricsConfig.longTermTrustGap)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          valueFactor: (nextTrustLevel * 10).clamp(0, 50).toDouble(),
          score: 0,
          jumpTarget: GoalJumpTarget.settlementFacility(
            facility: VillageFacility.chiefHouse,
            regionId: _regionId,
          ),
          isValid: true,
        ));
      }
    }

    // 2. 다음 인프라 Tier (requiredFlags - unlockedFlags <= 2)
    final currentTier = rs?.infrastructureTier ?? 1;
    final unlockedFlags = rs?.unlockedFlags ?? const <String>[];
    final nextTier = currentTier + 1;
    if (nextTier <= 4) {
      final requiredFlags =
          SettlementInfrastructureConfig.infraTierThresholds[nextTier] ?? 99;
      final flagGap = requiredFlags - unlockedFlags.length;
      if (flagGap > 0 && flagGap <= 2 && requiredFlags > 0) {
        candidates.add(GoalCandidate(
          id: 'infra:$_regionId:$nextTier',
          slot: GoalSlot.long8Hour,
          label: '거점 Tier $nextTier 진입 '
              '(flag ${unlockedFlags.length}/$requiredFlags)',
          kind: GoalCandidateKind.imminentInfra,
          baseWeight: 100,
          progressFactor:
              (unlockedFlags.length / requiredFlags).clamp(0.0, 1.0).toDouble(),
          valueFactor: (nextTier * 12).clamp(0, 50).toDouble(),
          score: 0,
          jumpTarget: GoalJumpTarget.settlementFacility(
            facility: VillageFacility.chiefHouse,
            regionId: _regionId,
          ),
          isValid: true,
        ));
      }
    }

    // 3. 다음 명성 랭크 (nextRankRep - currentRep <= 8000)
    final currentRep = userData.reputation;
    final nextRank = _findNextRankThreshold(currentRep, ref);
    if (nextRank != null) {
      final gap = nextRank.threshold - currentRep;
      if (gap > 0 && gap <= LivingsphereMetricsConfig.longTermRankRepGap) {
        candidates.add(GoalCandidate(
          id: 'rank:${nextRank.grade}',
          slot: GoalSlot.long8Hour,
          label: '${nextRank.grade} 랭크 진입 '
              '($currentRep/${nextRank.threshold})',
          kind: GoalCandidateKind.imminentRank,
          baseWeight: 90,
          progressFactor:
              (1 - gap / LivingsphereMetricsConfig.longTermRankRepGap)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          valueFactor: 40,
          score: 0,
          jumpTarget: const GoalJumpTarget.dispatch(),
          isValid: true,
        ));
      }
    }

    // 4. 활성 체인 완주 (remainingSteps <= 3)
    final chainProgressAsync = ref.read(chainQuestProgressProvider);
    final chainProgress = chainProgressAsync.valueOrNull ?? const [];
    final activeChain = chainProgress
        .where((p) => p.status == ChainQuestStatus.active)
        .firstOrNull;
    if (activeChain != null) {
      const totalSteps = 6;
      final remaining = (totalSteps - activeChain.currentStep).clamp(0, totalSteps);
      if (remaining > 0 &&
          remaining <= LivingsphereMetricsConfig.longTermChainRemainingSteps) {
        candidates.add(GoalCandidate(
          id: 'chain:${activeChain.chainId}',
          slot: GoalSlot.long8Hour,
          label: '${activeChain.chainId} 체인 완주까지 $remaining단계',
          kind: GoalCandidateKind.chainCompletion,
          baseWeight: 80,
          progressFactor:
              (1 - remaining / totalSteps).clamp(0.0, 1.0).toDouble(),
          valueFactor: 45,
          score: 0,
          jumpTarget: const GoalJumpTarget.dispatch(),
          isValid: activeChain.status == ChainQuestStatus.active,
        ));
      }
    }

    // 5. 핵심 제작 레시피 해금 (insufficient 상태 + 부족 재료 ≤ 2)
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData != null) {
      // CraftingService.evaluateState 호출 시 staticData가 requireValue로 필요하므로
      // staticData가 비어 있는 테스트 경로는 건너뛴다.
      CraftingService? crafting;
      try {
        crafting = ref.read(craftingServiceProvider);
      } catch (_) {
        crafting = null;
      }
      final inventory = ref.read(inventoryRepositoryProvider);
      if (crafting != null) {
        for (final recipeId
            in LivingsphereMetricsConfig.region3RecipeIds) {
          final recipe = staticData.craftingRecipes
              .where((r) => r.id == recipeId)
              .firstOrNull;
          if (recipe == null) continue;
          try {
            final state = crafting.evaluateState(recipe);
            if (state != RecipeState.insufficient) continue;
            // 부족한 재료 종류 수 카운트.
            var missing = 0;
            for (final input in recipe.inputs) {
              final have = _safeQuantity(inventory, input.itemId);
              if (have < input.quantity) missing++;
            }
            if (missing == 0 || missing > 2) continue;
            final output = staticData.items
                .where((i) => i.id == recipe.resultItemId)
                .firstOrNull;
            final recipeTier = output?.tier ?? 1;
            final outputName = output?.name ?? recipeId;
            candidates.add(GoalCandidate(
              id: 'craft:$recipeId',
              slot: GoalSlot.long8Hour,
              label: '$outputName 해금 (재료 $missing종 부족)',
              kind: GoalCandidateKind.craftUnlock,
              baseWeight: 60,
              progressFactor: (1 - missing / 3).clamp(0.0, 1.0).toDouble(),
              valueFactor: (recipeTier * 10).clamp(0, 50).toDouble(),
              score: 0,
              jumpTarget: const GoalJumpTarget.smithy(),
              isValid: true,
            ));
          } catch (_) {
            // fail-soft: 평가 실패 시 후보 스킵.
          }
        }
      }
    }

    // 6. 신규 세력 가입 조건 (currentRep > 0 && joined == false)
    final factionRepo = ref.read(factionStateRepositoryProvider);
    const requiredRep = 30; // M8a 가입 임계 단순화 (요건 충족 시 후속 정교화 위임)
    for (final factionId
        in LivingsphereMetricsConfig.region3ActiveFactionIds) {
      final fs = factionRepo.getState(factionId);
      if (fs == null) continue;
      if (fs.isJoined) continue;
      final rep = fs.currentReputation;
      if (rep <= 0) continue;
      candidates.add(GoalCandidate(
        id: 'faction_join:$factionId',
        slot: GoalSlot.long8Hour,
        label: '$factionId 가입 조건 (평판 $rep/$requiredRep)',
        kind: GoalCandidateKind.factionJoin,
        baseWeight: 50,
        progressFactor: (rep / requiredRep).clamp(0.0, 1.0).toDouble(),
        valueFactor: 30,
        score: 0,
        jumpTarget: GoalJumpTarget.faction(factionId: factionId),
        isValid: !fs.isJoined,
      ));
    }

    // 7. region_pacified 임박 (dangerScore <= -80)
    final danger = rs?.dangerScore ?? 0;
    if (danger <= -80) {
      // (dangerScore + 100).abs() / 100 — danger=-80일 때 0.20, danger=-99일 때 0.01.
      // dangerScore가 -100을 넘어가는 일이 이론상 없지만 clamp로 보호.
      final progress =
          (1 - ((danger + 100).abs() / 100)).clamp(0.0, 1.0).toDouble();
      candidates.add(GoalCandidate(
        id: 'pacify:$_regionId',
        slot: GoalSlot.long8Hour,
        label: '더스트플레인 평정 임박 (위협도 $danger)',
        kind: GoalCandidateKind.pacification,
        baseWeight: 100,
        progressFactor: progress,
        valueFactor: 50,
        score: 0,
        jumpTarget: const GoalJumpTarget.movement(regionId: _regionId),
        isValid: danger > -100,
      ));
    }

    return candidates;
  }

  // ===========================================================================
  // Helper: 신뢰도 임계값 (region 3 기준, RegionStateRepository와 동일)
  // ===========================================================================
  static int _trustThreshold(int level) {
    switch (level) {
      case 1:
        return 0;
      case 2:
        return 30;
      case 3:
        return 80;
      case 4:
        return 200;
      default:
        return 9999;
    }
  }

  // ===========================================================================
  // Helper: 다음 명성 랭크 (currentRep보다 큰 첫 grade를 ranks에서 검색)
  // ===========================================================================
  static ({String grade, int threshold})? _findNextRankThreshold(
      int currentRep, Ref<Object?> ref) {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) return null;
    final ranks = [...staticData.ranks]
      ..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
    for (final r in ranks) {
      if (r.requiredReputation > currentRep) {
        return (grade: r.grade, threshold: r.requiredReputation);
      }
    }
    return null;
  }

  // ===========================================================================
  // Helper: inventory 보유량 안전 조회 (Hive box 미초기화 환경에서 0 fallback)
  // ===========================================================================
  static int _safeQuantity(InventoryRepository repo, String itemId) {
    try {
      return repo.getQuantityForItemId(itemId);
    } catch (_) {
      return 0;
    }
  }
}
