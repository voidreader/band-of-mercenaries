import 'dart:math';
import 'package:band_of_mercenaries/core/models/facility.dart';

class ConstructionService {
  static int calculateCost(Facility facility, int nextLevel, {double costMultiplier = 1.0}) {
    int baseCost;
    if (nextLevel == 1) {
      if (facility.lv1Cost != null) {
        baseCost = facility.lv1Cost!;
      } else {
        baseCost = facility.costs.isNotEmpty ? facility.costs[0] : 0;
      }
    } else if (nextLevel == 2) {
      if (facility.lv2Cost != null) {
        baseCost = facility.lv2Cost!;
      } else {
        baseCost = facility.costs.length > 1 ? facility.costs[1] : 0;
      }
    } else if (facility.baseCost != null && facility.costMultiplier != null) {
      baseCost = (facility.baseCost! * pow(facility.costMultiplier!, nextLevel - 3)).round();
    } else {
      final idx = nextLevel - 1;
      baseCost = idx < facility.costs.length ? facility.costs[idx] : 0;
    }
    return (baseCost * costMultiplier).round();
  }

  static int calculateBuildTimeMinutes(Facility facility, int nextLevel) {
    if (nextLevel == 1) return facility.lv1Time ?? 0;
    if (nextLevel == 2) return facility.lv2Time ?? 0;
    if (facility.baseTime != null && facility.timeMultiplier != null) {
      return (facility.baseTime! * pow(facility.timeMultiplier!, nextLevel - 3)).round();
    }
    return 0;
  }

  static Duration calculateBuildDuration(Facility facility, int nextLevel, double speedMultiplier, {double timeMultiplier = 1.0}) {
    final effectiveSpeed = speedMultiplier <= 0 ? 1.0 : speedMultiplier;
    final minutes = calculateBuildTimeMinutes(facility, nextLevel);
    final baseSeconds = minutes * 60 * timeMultiplier;
    final seconds = (baseSeconds / effectiveSpeed).round();
    return Duration(seconds: seconds);
  }

  static double getEffectValue(Facility facility, int level, {double effectBonus = 0.0}) {
    if (level <= 0) return 0.0;
    double base;
    if (facility.maxEffect != null && facility.alpha != null) {
      final alpha = facility.alpha!;
      if (alpha == 0) {
        base = facility.maxEffect! * level / 25;
      } else {
        base = facility.maxEffect! * log(1 + level * alpha) / log(1 + 25 * alpha);
      }
    } else {
      final idx = level - 1;
      base = idx < facility.values.length ? facility.values[idx] : 0.0;
    }
    return base * (1.0 + effectBonus);
  }

  static int? getUpgradeCost(Facility facility, int currentLevel, {double costMultiplier = 1.0}) {
    if (currentLevel >= facility.maxLevel) return null;
    return calculateCost(facility, currentLevel + 1, costMultiplier: costMultiplier);
  }

  static bool canStartConstruction(Facility facility, int currentLevel, int gold, String? currentConstructionId, {double costMultiplier = 1.0}) {
    if (currentLevel >= facility.maxLevel) return false;
    if (currentConstructionId != null) return false;
    final cost = calculateCost(facility, currentLevel + 1, costMultiplier: costMultiplier);
    return gold >= cost;
  }
}
