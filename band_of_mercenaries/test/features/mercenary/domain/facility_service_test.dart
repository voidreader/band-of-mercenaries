import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

void main() {
  final training = const Facility(id: 'training', name: '훈련소', effectType: 'xp_bonus', maxLevel: 5, costs: [500, 1000, 2000, 4000, 8000], values: [0.1, 0.2, 0.3, 0.4, 0.5]);

  group('getUpgradeCost', () {
    test('level 0→1 costs 500', () => expect(FacilityService.getUpgradeCost(training, 0), 500));
    test('level 2→3 costs 2000', () => expect(FacilityService.getUpgradeCost(training, 2), 2000));
    test('max level returns null', () => expect(FacilityService.getUpgradeCost(training, 5), null));
  });

  group('canUpgrade', () {
    test('can with enough gold', () => expect(FacilityService.canUpgrade(training, 0, 500), true));
    test('cannot with less gold', () => expect(FacilityService.canUpgrade(training, 0, 499), false));
    test('cannot at max', () => expect(FacilityService.canUpgrade(training, 5, 99999), false));
  });

  group('getEffectValue', () {
    test('level 0 returns 0', () => expect(FacilityService.getEffectValue(training, 0), 0.0));
    test('level 1 returns 0.1', () => expect(FacilityService.getEffectValue(training, 1), 0.1));
    test('level 3 returns 0.3', () => expect(FacilityService.getEffectValue(training, 3), 0.3));
  });

  group('getMaxMercenaries', () {
    final barracks = const Facility(id: 'barracks', name: '주둔지', effectType: 'max_mercenaries', maxLevel: 5, costs: [400, 800, 1600, 3200, 6400], values: [2.0, 4.0, 6.0, 8.0, 10.0]);
    test('level 0 base is 10', () => expect(FacilityService.getMaxMercenaries(barracks, 0), 10));
    test('level 3 gives 16', () => expect(FacilityService.getMaxMercenaries(barracks, 3), 16));
  });

  group('getExtraQuestCount', () {
    final intel = const Facility(id: 'intelligence', name: '정보망', effectType: 'quest_count', maxLevel: 3, costs: [1000, 3000, 9000], values: [1.0, 2.0, 3.0]);
    test('level 0 gives 0 extra', () => expect(FacilityService.getExtraQuestCount(intel, 0), 0));
    test('level 2 gives 2 extra', () => expect(FacilityService.getExtraQuestCount(intel, 2), 2));
  });
}
