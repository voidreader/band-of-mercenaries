import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_relation_stage.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_metrics_config.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';

/// M8.5 페이즈 4 #1 — 생활권 완성도 대시보드 산식 서비스.
///
/// FR-1~7의 6 지표 + 통합 완성도(가중평균)를 계산한다.
/// 정적 메서드만 제공하며, `gameTickProvider` watch는 호출자(Provider) 책임.
/// MVP 대상은 region 3 고정.
class LivingsphereDashboardService {
  const LivingsphereDashboardService._();

  /// MVP 대상 region (region 3 고정 — 명세 §4.1 참조).
  static const int _regionId = 3;

  /// 6 지표 + 통합 완성도 계산.
  ///
  /// 모든 의존 Provider는 `ref.read`만 사용하므로 호출자가
  /// 적절한 watch 트리거를 별도 보장해야 한다.
  static LivingsphereDashboardSnapshot computeSnapshot(Ref<Object?> ref) {
    final regionState =
        ref.read(regionStateRepositoryProvider).getState(_regionId);

    final stability = _computeStability(regionState);
    final infrastructure = _computeInfrastructure(regionState);
    final eventCompletion = _computeEventCompletion(regionState, ref);
    final resourceCraft = _computeResourceCraft(regionState, ref);
    final influence = _computeInfluence(ref);
    final achievement = _computeAchievement(ref);

    final metrics = <MetricKey, MetricValue>{
      MetricKey.stability: stability,
      MetricKey.infrastructure: infrastructure,
      MetricKey.eventCompletion: eventCompletion,
      MetricKey.resourceCraft: resourceCraft,
      MetricKey.influence: influence,
      MetricKey.achievement: achievement,
    };

    final total = _computeTotal(metrics);

    return LivingsphereDashboardSnapshot(
      regionId: _regionId,
      metrics: metrics,
      totalCompletionPct: total,
    );
  }

  // ===========================================================================
  // FR-1: 안정도
  // ===========================================================================

  /// dangerScore -100~+100을 0~100% 안정도로 선형 매핑.
  /// `(100 - danger) / 200 * 100` → 위협 100 = 0%, 안정 -100 = 100%.
  static MetricValue _computeStability(RegionState? rs) {
    final danger = rs?.currentDangerScore ?? 0;
    final pct = (((100 - danger) / 200) * 100).clamp(0.0, 100.0).toDouble();
    final levelLabel = _dangerLevelLabel(danger);
    return MetricValue(
      percent: pct,
      displayMode: MetricDisplayMode.percent,
      label: levelLabel,
    );
  }

  /// DangerLevelResolver.resolveLevel과 동일 임계 — 라벨만 추출.
  static String _dangerLevelLabel(int dangerScore) {
    if (dangerScore <= -60) return '안정';
    if (dangerScore <= 20) return '평온';
    if (dangerScore <= 60) return '긴장';
    return '위협';
  }

  // ===========================================================================
  // FR-2: 거점 발전
  // ===========================================================================

  /// Tier 1~4를 0/33.3/66.7/100%로 매핑. null fallback 1, 범위 외 clamp.
  static MetricValue _computeInfrastructure(RegionState? rs) {
    final tier = (rs?.infrastructureTier ?? 1).clamp(1, 4);
    final pct = (((tier - 1) / 3) * 100).clamp(0.0, 100.0).toDouble();
    return MetricValue(
      percent: pct,
      displayMode: MetricDisplayMode.tierLevel,
      currentValue: tier,
      totalValue: 4,
      label: 'Tier $tier',
    );
  }

  // ===========================================================================
  // FR-3: 사건 완료율 (분모 11 = 체인 6 + 발견 3 + M7 상태 의뢰 2)
  // ===========================================================================

  static MetricValue _computeEventCompletion(
    RegionState? rs,
    Ref<Object?> ref,
  ) {
    // 체인: settlement_3_pyegwang_reopen 진행 단계 (완주 시 6 cap).
    final chainProgressAsync = ref.read(chainQuestProgressProvider);
    final chainProgress = chainProgressAsync.valueOrNull ?? const [];
    final settlementChain = chainProgress
        .where((p) => p.chainId == LivingsphereMetricsConfig.settlementChainId)
        .firstOrNull;
    final chainStep = (settlementChain?.currentStep ?? 0).clamp(0, 6);

    // 발견: triggeredDiscoveries와 region 3 allowlist 교집합.
    final triggeredDiscoveries = rs?.triggeredDiscoveries ?? const <String>[];
    final discoveryCount = triggeredDiscoveries
        .where((d) =>
            LivingsphereMetricsConfig.region3DiscoveryIds.contains(d))
        .length;

    // M7 상태 의뢰: questPoolCompletionCounts에서 allowlist 매칭 (각 1 cap).
    final completionCounts =
        rs?.questPoolCompletionCounts ?? const <String, int>{};
    var statePoolCompleted = 0;
    for (final poolId in LivingsphereMetricsConfig.region3StateQuestPoolIds) {
      if ((completionCounts[poolId] ?? 0) > 0) statePoolCompleted++;
    }

    final completed = chainStep + discoveryCount + statePoolCompleted;
    final denominator =
        LivingsphereMetricsConfig.eventCompletionDenominator;
    final pct =
        ((completed / denominator) * 100).clamp(0.0, 100.0).toDouble();

    return MetricValue(
      percent: pct,
      displayMode: MetricDisplayMode.countOverTotal,
      currentValue: completed,
      totalValue: denominator,
      expandedSummary:
          '체인 $chainStep/6 · 발견 $discoveryCount/3 · 상태 의뢰 $statePoolCompleted/2',
    );
  }

  // ===========================================================================
  // FR-4: 자원·제작 (특산품 50% + 레시피 50%)
  // ===========================================================================

  static MetricValue _computeResourceCraft(
    RegionState? rs,
    Ref<Object?> ref,
  ) {
    // 특산품: firstAcquiredMaterialIds와 allowlist 교집합.
    final firstAcquired =
        rs?.firstAcquiredMaterialIds ?? const <String>[];
    final acquiredCount = firstAcquired
        .where((id) =>
            LivingsphereMetricsConfig.region3MaterialIds.contains(id))
        .length;

    // 레시피: CraftingService.evaluateState 결과가 locked 외(unlocked = insufficient/ready) 카운트.
    final staticDataAsync = ref.read(staticDataProvider);
    final staticData = staticDataAsync.valueOrNull;
    var unlockedRecipes = 0;
    if (staticData != null) {
      final crafting = ref.read(craftingServiceProvider);
      for (final recipeId
          in LivingsphereMetricsConfig.region3RecipeIds) {
        final recipe = staticData.craftingRecipes
            .where((r) => r.id == recipeId)
            .firstOrNull;
        if (recipe == null) continue;
        try {
          final state = crafting.evaluateState(recipe);
          if (state != RecipeState.locked) unlockedRecipes++;
        } catch (_) {
          // fail-soft: 평가 실패 시 잠금으로 간주.
        }
      }
    }

    final acqDenom = LivingsphereMetricsConfig.materialDenominator;
    final recDenom = LivingsphereMetricsConfig.recipeDenominator;
    final pct = (((acquiredCount / acqDenom) * 50) +
            ((unlockedRecipes / recDenom) * 50))
        .clamp(0.0, 100.0)
        .toDouble();

    return MetricValue(
      percent: pct,
      displayMode: MetricDisplayMode.percent,
      expandedSummary:
          '특산품 $acquiredCount/$acqDenom · 레시피 $unlockedRecipes/$recDenom',
    );
  }

  // ===========================================================================
  // FR-5: 영향력 (활성 3 세력 평균)
  // ===========================================================================

  static MetricValue _computeInfluence(Ref<Object?> ref) {
    final repo = ref.read(factionStateRepositoryProvider);
    var totalScore = 0.0;
    var count = 0;
    final stageLabels = <String>[];

    for (final factionId
        in LivingsphereMetricsConfig.region3ActiveFactionIds) {
      final stage =
          FactionRelationStage.resolveFromProviderRef(factionId, ref);
      final fs = repo.getState(factionId);
      final reputation = fs?.currentReputation ?? 0;

      // 단계별 점수 매핑.
      // - untouched: 0
      // - noticed: 20
      // - patronage: 20 + (rep/10) × 20 (rep 1~10 보너스)
      // - joined: 50 + (rep/100) × 50 (rep 0~100)
      // - trusted/core: joined와 동일 곡선 (rep만 더 크다는 점에서 자연 증가)
      // - hostile: ((rep+100)/100) × 20 (rep -100 = 0, rep 0 = 20)
      final double score;
      switch (stage) {
        case FactionRelationStage.untouched:
          score = 0;
          break;
        case FactionRelationStage.noticed:
          score = 20;
          break;
        case FactionRelationStage.patronage:
          score = 20 + (reputation.clamp(0, 10) / 10) * 20;
          break;
        case FactionRelationStage.joined:
        case FactionRelationStage.trusted:
        case FactionRelationStage.core:
          score = (50 + (reputation.clamp(0, 100) / 100) * 50)
              .clamp(0.0, 100.0)
              .toDouble();
          break;
        case FactionRelationStage.hostile:
          score = ((reputation + 100) / 100 * 20).clamp(0.0, 20.0);
          break;
      }

      totalScore += score;
      count++;
      stageLabels
          .add('${factionId.replaceFirst('faction_', '')}:${stage.name}');
    }

    final pct = count > 0
        ? (totalScore / count).clamp(0.0, 100.0).toDouble()
        : 0.0;
    return MetricValue(
      percent: pct,
      displayMode: MetricDisplayMode.averageStage,
      expandedSummary: stageLabels.join(' · '),
    );
  }

  // ===========================================================================
  // FR-6: 위업 달성률 (region 3 위업 5종 allowlist)
  // ===========================================================================

  static MetricValue _computeAchievement(Ref<Object?> ref) {
    final achievements = ref.read(bandAchievementsProvider);
    final templateIds = achievements.map((a) => a.templateId).toSet();
    var matched = 0;
    for (final tid
        in LivingsphereMetricsConfig.region3AchievementTemplateIds) {
      if (templateIds.contains(tid)) matched++;
    }
    final denom = LivingsphereMetricsConfig.achievementDenominator;
    final pct = ((matched / denom) * 100).clamp(0.0, 100.0).toDouble();
    return MetricValue(
      percent: pct,
      displayMode: MetricDisplayMode.countOverTotal,
      currentValue: matched,
      totalValue: denom,
    );
  }

  // ===========================================================================
  // FR-7: 통합 완성도 (가중평균, weights 합 = 1.0)
  // ===========================================================================

  static double _computeTotal(Map<MetricKey, MetricValue> metrics) {
    var total = 0.0;
    LivingsphereMetricsConfig.weights.forEach((key, weight) {
      final v = metrics[key];
      if (v != null) total += v.percent * weight;
    });
    return total.clamp(0.0, 100.0);
  }
}
