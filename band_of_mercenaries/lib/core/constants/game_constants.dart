class GameConstants {
  static const int startingGold = 500;
  static const int sectorCount = 10;
  static const int baseQuestCount = 5;
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

  // Trait deletion
  static const int traitDeletionCostAcquired = 200;
  static const int traitDeletionCostEvolved = 500;
  static const int traitDeletionMinInfirmaryLevelAcquired = 2;
  static const int traitDeletionMinInfirmaryLevelEvolved = 4;
}
