import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';

/// M8.5 페이즈 4 #1 생활권 완성도 대시보드 설정값 및 allowlist
class LivingsphereMetricsConfig {
  const LivingsphereMetricsConfig._();

  /// 6 지표 가중치 (합 = 1.0)
  static const Map<MetricKey, double> weights = {
    MetricKey.stability: 0.20,
    MetricKey.infrastructure: 0.20,
    MetricKey.eventCompletion: 0.20,
    MetricKey.resourceCraft: 0.15,
    MetricKey.influence: 0.10,
    MetricKey.achievement: 0.15,
  };

  /// FR-3: 사건 완료율 분모 (체인 6 + 발견 3 + M7 상태 의뢰 2 = 11)
  static const int eventCompletionDenominator = 11;

  /// FR-4: 자원·제작 분모 (특산품 5)
  static const int materialDenominator = 5;

  /// FR-4: 자원·제작 분모 (레시피 10)
  static const int recipeDenominator = 10;

  /// FR-6: 위업 달성률 분모 (region 3 위업 5종)
  static const int achievementDenominator = 5;

  /// FR-3: M7 상태 의뢰 region 3 allowlist 2종
  static const Set<String> region3StateQuestPoolIds = {
    'qp_m7_r3_cave_bats',
    'qp_m7_r3_safe_escort',
  };

  /// FR-3: 발견 region 3 allowlist 3종
  static const Set<String> region3DiscoveryIds = {
    'disc_dustvile_pyegwang_normal',
    'disc_dustvile_pyegwang_hidden',
    'disc_dustvile_pyegwang_deepest',
  };

  /// FR-4: 특산품 allowlist 5종
  static const Set<String> region3MaterialIds = {
    'mat_herb_dust_resin',
    'mat_relic_pyegwang_pickaxe_head',
    'mat_relic_pyegwang_shard',
    'mat_monster_giant_bat_fang',
    'mat_relic_ancient_seal_piece',
  };

  /// FR-4: 레시피 allowlist 10종 (recipe_dustvile_*)
  static const Set<String> region3RecipeIds = {
    'recipe_dustvile_banner_repair',
    'recipe_dustvile_hide_bundle',
    'recipe_dustvile_ore_polished',
    'recipe_dustvile_armor_solid',
    'recipe_dustvile_herbalist_seal',
    'recipe_dustvile_herb_pouch',
    'recipe_dustvile_miner_dagger',
    'recipe_dustvile_rusty_pickaxe',
    'recipe_dustvile_pyegwang_relic',
    'recipe_dustvile_miner_charm',
  };

  /// FR-6: 위업 allowlist 5종
  static const Set<String> region3AchievementTemplateIds = {
    'region_pacified:region_3',
    'infrastructure_tier:tier_4',
    'settlement_event_completed:settlement_3_pyegwang_reopen',
    'settlement_trust_belonging:region_3',
    'craft_first_rare:recipe_dustvile_pyegwang_relic',
  };

  /// FR-5: 영향력 세력 3종 고정
  static const Set<String> region3ActiveFactionIds = {
    'faction_adventurers_guild',
    'faction_merchants_alliance',
    'faction_warriors_guild',
  };

  /// FR-8: 30분 임박 신뢰도 임계 (nextThreshold - currentTrust <= 30)
  static const int imminentTrustGap = 30;

  /// FR-8: 30분 임박 명성 임계 (nextRankRep - currentRep <= 200)
  static const int imminentRankRepGap = 200;

  /// FR-9: 8시간 임박 신뢰도 임계 (nextThreshold - currentTrust <= 80)
  static const int longTermTrustGap = 80;

  /// FR-9: 8시간 임박 명성 임계 (nextRankRep - currentRep <= 8000)
  static const int longTermRankRepGap = 8000;

  /// FR-9: 8시간 활성 체인 임박 (remainingSteps <= 3)
  static const int longTermChainRemainingSteps = 3;

  /// FR-3: 거점 사건 체인 chainId
  static const String settlementChainId = 'settlement_3_pyegwang_reopen';
}
