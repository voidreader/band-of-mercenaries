import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';

class ExperienceService {
  static const int baseXp = 20;
  static const int maxLevel = 5;
  static const List<int> levelThresholds = [0, 100, 350, 850, 1850];

  static int calculateXpGain({required int difficulty, required double resultMultiplier, required double facilityBonus}) {
    final base = difficulty * baseXp * resultMultiplier;
    return (base * (1.0 + facilityBonus)).round();
  }

  static int checkLevelUp({required int currentLevel, required int currentXp}) {
    if (currentLevel >= maxLevel) return maxLevel;
    int newLevel = currentLevel;
    for (int lvl = currentLevel; lvl < maxLevel; lvl++) {
      if (currentXp >= levelThresholds[lvl]) {
        newLevel = lvl + 1;
      } else {
        break;
      }
    }
    return newLevel;
  }

  static double resultMultiplier(QuestResultType resultType) {
    return switch (resultType) {
      QuestResultType.greatSuccess => 2.0,
      QuestResultType.success => 1.0,
      QuestResultType.failure => 0.5,
      QuestResultType.criticalFailure => 0.0,
    };
  }
}
