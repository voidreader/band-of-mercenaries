/// M7 페이즈 4 #4 — 마을 인프라 시스템 정적 상수
class SettlementInfrastructureConfig {
  SettlementInfrastructureConfig._();

  /// 임계 flag 수 (Tier → 필요 flag 합) — 페이즈 2 #3 1절
  static const Map<int, int> infraTierThresholds = {1: 0, 2: 2, 3: 4, 4: 6};

  /// 단계 전이 일회성 보상 — 페이즈 2 #3 6절
  static const Map<int, ({int gold, int xp, int rep})> infraTierRewards = {
    2: (gold: 100, xp: 100, rep: 50),
    3: (gold: 200, xp: 200, rep: 100),
    4: (gold: 500, xp: 500, rep: 300),
  };

  /// 한국어 단계명 (페이즈 1 #3 1.1절)
  static const Map<int, String> infraTierNames = {
    1: '고립',
    2: '연결',
    3: '거점화',
    4: '변방의 중심',
  };

  /// M7 인프라 관련 8개 flag (페이즈 1 #2 1.3절)
  static const Set<String> infrastructureRelevantFlags = {
    'region_3_pyegwang_reopen_completed',
    'region_31_bandits_cleared',
    'region_31_shrine_quest_completed',
    'region_127_nomad_friendly',
    'region_9_giant_beast_killed',
    'region_10_windrunner_chain_completed',
    'region_146_mist_cleared',
    'region_38_ironbound_pact_completed',
  };

  /// 외래 좌판 거래 기본 가격 (Tier 3 기준)
  static const Map<String, int> foreignStallBasePrices = {
    'mat_herb_wildflower': 60,
    'mat_herb_seaweed': 60,
    'mat_hide_nomad_strap': 120,
    'mat_herb_wind': 150,
    'mat_herb_poison': 150,
    'mat_relic_swamp_seal': 200,
    'mat_relic_burnt_seal': 250,
    'mat_relic_ancient_seal_piece': 300,
  };

  /// Tier 4 할인율 (-20%)
  static const double foreignStallTier4Discount = 0.80;

  static const int foreignStallTier3VarietyCap = 3;
  static const int foreignStallTier4VarietyCap = 6;

  /// 광장 이정표 (페이즈 2 #3 3절)
  static const double signpostDistanceMultiplier = 0.90;
  static const int signpostMinTier = 2;

  /// flagCount → Tier 계산
  static int resolveTier(int flagCount) {
    if (flagCount >= (infraTierThresholds[4] ?? 6)) return 4;
    if (flagCount >= (infraTierThresholds[3] ?? 4)) return 3;
    if (flagCount >= (infraTierThresholds[2] ?? 2)) return 2;
    return 1;
  }
}
