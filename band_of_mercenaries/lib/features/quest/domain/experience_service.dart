class ExperienceService {
  static const int baseXp = 20;
  static const int maxLevel = 5;
  static const List<int> _levelThresholds = [0, 100, 350, 850, 1850];

  static int calculateXpGain({required int difficulty, required double resultMultiplier, required double facilityBonus}) {
    final base = difficulty * baseXp * resultMultiplier;
    return (base * (1.0 + facilityBonus)).round();
  }

  static int checkLevelUp({required int currentLevel, required int currentXp}) {
    if (currentLevel >= maxLevel) return maxLevel;
    int newLevel = currentLevel;
    for (int lvl = currentLevel; lvl < maxLevel; lvl++) {
      if (currentXp >= _levelThresholds[lvl]) {
        newLevel = lvl + 1;
      } else {
        break;
      }
    }
    return newLevel;
  }

  static double resultMultiplier(String resultName) {
    return switch (resultName) {
      'greatSuccess' => 2.0,
      'success' => 1.0,
      'failure' => 0.5,
      'criticalFailure' => 0.0,
      _ => 0.0,
    };
  }
}
