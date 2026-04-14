import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';

class FacilityService {
  static const int baseMercenaryMax = 10;
  static const int baseQuestCount = 5;

  static int? getUpgradeCost(Facility facility, int currentLevel) {
    return ConstructionService.getUpgradeCost(facility, currentLevel);
  }

  static bool canUpgrade(Facility facility, int currentLevel, int gold, {String? currentConstructionId}) {
    return ConstructionService.canStartConstruction(facility, currentLevel, gold, currentConstructionId);
  }

  static double getEffectValue(Facility facility, int level) {
    return ConstructionService.getEffectValue(facility, level);
  }

  static int getMaxMercenaries(Facility barracks, int level) {
    return baseMercenaryMax + ConstructionService.getEffectValue(barracks, level).round();
  }

  static int getExtraQuestCount(Facility intelligence, int level) {
    return ConstructionService.getEffectValue(intelligence, level).round();
  }
}
