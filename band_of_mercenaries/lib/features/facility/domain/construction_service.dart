import 'dart:math';
import 'package:band_of_mercenaries/core/models/facility.dart';

class ConstructionService {
  static int calculateCost(Facility facility, int nextLevel) {
    if (nextLevel == 1) {
      if (facility.lv1Cost != null) return facility.lv1Cost!;
      return facility.costs.isNotEmpty ? facility.costs[0] : 0;
    }
    if (nextLevel == 2) {
      if (facility.lv2Cost != null) return facility.lv2Cost!;
      return facility.costs.length > 1 ? facility.costs[1] : 0;
    }
    if (facility.baseCost != null && facility.costMultiplier != null) {
      return (facility.baseCost! * pow(facility.costMultiplier!, nextLevel - 3)).round();
    }
    final idx = nextLevel - 1;
    return idx < facility.costs.length ? facility.costs[idx] : 0;
  }

  static int calculateBuildTimeMinutes(Facility facility, int nextLevel) {
    if (nextLevel == 1) return facility.lv1Time ?? 0;
    if (nextLevel == 2) return facility.lv2Time ?? 0;
    if (facility.baseTime != null && facility.timeMultiplier != null) {
      return (facility.baseTime! * pow(facility.timeMultiplier!, nextLevel - 3)).round();
    }
    return 0;
  }

  static Duration calculateBuildDuration(Facility facility, int nextLevel, double speedMultiplier) {
    final effectiveSpeed = speedMultiplier <= 0 ? 1.0 : speedMultiplier;
    final minutes = calculateBuildTimeMinutes(facility, nextLevel);
    final seconds = (minutes * 60 / effectiveSpeed).round();
    return Duration(seconds: seconds);
  }

  static double getEffectValue(Facility facility, int level) {
    if (level <= 0) return 0.0;
    if (facility.maxEffect != null && facility.alpha != null) {
      final alpha = facility.alpha!;
      if (alpha == 0) {
        return facility.maxEffect! * level / 25;
      }
      return facility.maxEffect! * log(1 + level * alpha) / log(1 + 25 * alpha);
    }
    final idx = level - 1;
    return idx < facility.values.length ? facility.values[idx] : 0.0;
  }

  static int? getUpgradeCost(Facility facility, int currentLevel) {
    if (currentLevel >= facility.maxLevel) return null;
    return calculateCost(facility, currentLevel + 1);
  }

  static bool canStartConstruction(Facility facility, int currentLevel, int gold, String? currentConstructionId) {
    if (currentLevel >= facility.maxLevel) return false;
    if (currentConstructionId != null) return false;
    final cost = calculateCost(facility, currentLevel + 1);
    return gold >= cost;
  }
}
