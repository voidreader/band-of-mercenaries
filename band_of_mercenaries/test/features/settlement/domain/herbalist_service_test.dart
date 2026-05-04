import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/settlement/domain/herbalist_service.dart';

void main() {
  group('HerbalistService.calculateCost', () {
    test('단계 1 → 75G', () {
      expect(HerbalistService.calculateCost(1), 75);
    });
    test('단계 2 → 50G', () {
      expect(HerbalistService.calculateCost(2), 50);
    });
    test('단계 3 → 45G', () {
      expect(HerbalistService.calculateCost(3), 45);
    });
    test('단계 4 → 40G', () {
      expect(HerbalistService.calculateCost(4), 40);
    });
    test('범위 외 입력 → 50G fallback (multiplier 1.0)', () {
      expect(HerbalistService.calculateCost(5), 50);
      expect(HerbalistService.calculateCost(0), 50);
    });
  });

  group('HerbalistService.calculateCooldownMinutes', () {
    test('단계 1·2·3·4 → 45/30/15/10분', () {
      expect(HerbalistService.calculateCooldownMinutes(1), 45);
      expect(HerbalistService.calculateCooldownMinutes(2), 30);
      expect(HerbalistService.calculateCooldownMinutes(3), 15);
      expect(HerbalistService.calculateCooldownMinutes(4), 10);
    });
    test('범위 외 입력 → 30분 fallback', () {
      expect(HerbalistService.calculateCooldownMinutes(5), 30);
      expect(HerbalistService.calculateCooldownMinutes(0), 30);
    });
  });

  group('HerbalistService.gatheringMultiplier', () {
    test('단계 1·2 → 1.0 (단계 1은 미노출이지만 호출 시 안전값)', () {
      expect(HerbalistService.gatheringMultiplier(1), 1.0);
      expect(HerbalistService.gatheringMultiplier(2), 1.0);
    });
    test('단계 3 → 1.1, 단계 4 → 1.2', () {
      expect(HerbalistService.gatheringMultiplier(3), 1.1);
      expect(HerbalistService.gatheringMultiplier(4), 1.2);
    });
    test('범위 외 입력 → 1.0 fallback', () {
      expect(HerbalistService.gatheringMultiplier(5), 1.0);
      expect(HerbalistService.gatheringMultiplier(0), 1.0);
    });
  });
}
