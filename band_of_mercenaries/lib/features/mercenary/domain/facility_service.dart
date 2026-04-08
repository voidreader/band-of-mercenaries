import 'package:band_of_mercenaries/core/models/facility.dart';

class FacilityService {
  static const int baseMercenaryMax = 10;
  static const int baseQuestCount = 5;

  static int? getUpgradeCost(Facility facility, int currentLevel) {
    if (currentLevel >= facility.maxLevel) return null;
    return facility.costs[currentLevel];
  }

  static bool canUpgrade(Facility facility, int currentLevel, int gold) {
    final cost = getUpgradeCost(facility, currentLevel);
    if (cost == null) return false;
    return gold >= cost;
  }

  static double getEffectValue(Facility facility, int level) {
    if (level <= 0) return 0.0;
    return facility.values[level - 1];
  }

  static int getMaxMercenaries(Facility barracks, int level) {
    return baseMercenaryMax + getEffectValue(barracks, level).round();
  }

  static int getExtraQuestCount(Facility intelligence, int level) {
    return getEffectValue(intelligence, level).round();
  }
}
