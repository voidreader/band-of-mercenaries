import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

class ExperienceService {
  static const int baseXp = 20;
  static const int maxLevel = 5;
  static const List<int> levelThresholds = [0, 100, 350, 850, 1850];

  static int calculateXpGain({required int difficulty, required double resultMultiplier, required double facilityBonus, double passiveXpBonus = 0.0, int? rewardXpBonusOverride}) {
    final base = difficulty * baseXp * resultMultiplier;
    final result = (base * (1.0 + facilityBonus + passiveXpBonus)).round();
    // 고정 의뢰 XP 보너스 override 가산 (quest_pools.reward_xp_bonus_override)
    if (rewardXpBonusOverride != null) {
      return result + rewardXpBonusOverride;
    }
    return result;
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

  static double resultMultiplier(QuestResult resultType) {
    return switch (resultType) {
      QuestResult.greatSuccess => 2.0,
      QuestResult.success => 1.0,
      QuestResult.failure => 0.5,
      QuestResult.criticalFailure => 0.0,
    };
  }
}
