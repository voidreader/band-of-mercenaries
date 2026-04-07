import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

void main() {
  group('Mercenary', () {
    test('effectiveAtk returns 80% when tired', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', atk: 10, def: 10, hp: 100, speed: 1.0, status: MercenaryStatus.tired);
      expect(merc.effectiveAtk, 8);
      expect(merc.effectiveDef, 8);
      expect(merc.effectiveHp, 80);
    });

    test('effectiveAtk returns full value when normal', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', atk: 10, def: 10, hp: 100, speed: 1.0);
      expect(merc.effectiveAtk, 10);
    });

    test('isAvailable returns false when dead', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', atk: 10, def: 10, hp: 100, speed: 1.0, status: MercenaryStatus.dead);
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns false when dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', atk: 10, def: 10, hp: 100, speed: 1.0, isDispatched: true);
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns true when normal and not dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', atk: 10, def: 10, hp: 100, speed: 1.0);
      expect(merc.isAvailable, true);
    });

    test('isAvailable returns true when tired and not dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', atk: 10, def: 10, hp: 100, speed: 1.0, status: MercenaryStatus.tired);
      expect(merc.isAvailable, true);
    });
  });
}
