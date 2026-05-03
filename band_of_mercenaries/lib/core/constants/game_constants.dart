class GameConstants {
  static const int startingGold = 200;
  static const int startingRegionId = 3;
  static const int startingSector = 1;
  @Deprecated('M4 페이즈 4 #2: region_sectors.sector_count로 대체')
  static const int sectorCount = 10;
  static const int baseQuestCount = 6;
  static const int maxIdleRewardMinutes = 480;
  static const int idleRewardPerMinute = 1;
  static const int paidRecruitCost = 100;
  static const Duration freeRecruitCooldown = Duration(hours: 2);
  static const int tiredDurationMinutes = 5;
  static const double levelBonusPerLevel = 0.1;
  static const double tiredDebuffMultiplier = 0.8;

  static const int maxInnateTraits = 3;
  static const int maxAcquiredTraits = 4;
  static const int maxTotalTraits = 7;
  static const Set<String> innateCategories = {'Physical', 'Background', 'Talent'};
  static const Set<String> acquiredCategories = {'CombatStyle', 'Survival', 'Behavior', 'Mental', 'Experience'};

  static const int maxFacilityLevel = 25;

  // 세력 태그/전용 퀘스트 파라미터 (balance report 2026-04-17)
  static const double tagProbNear = 0.30;
  static const double tagProbMid = 0.20;
  static const double tagProbFar = 0.10;
  static const double tagProbVeryFar = 0.05;
  static const double trackRewardBasic = 0.30;
  static const double trackRewardAdvanced = 0.40;
  static const double rewardBonusStackCap = 0.80;
  static const Duration factionQuestCooldown = Duration(hours: 6);

  // Trait deletion
  static const int traitDeletionCostAcquired = 200;
  static const int traitDeletionCostEvolved = 500;
  static const int traitDeletionMinInfirmaryLevelAcquired = 2;
  static const int traitDeletionMinInfirmaryLevelEvolved = 4;
}
