import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

void main() {
  group('Mercenary', () {
    test('effectiveStr returns 80% when tired', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, status: MercenaryStatus.tired);
      expect(merc.effectiveStr, 8);
      expect(merc.effectiveIntelligence, 8);
      expect(merc.effectiveVit, 80);
    });

    test('effectiveStr returns full value when normal', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50);
      expect(merc.effectiveStr, 10);
    });

    test('isAvailable returns false when dead', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, status: MercenaryStatus.dead);
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns false when dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, isDispatched: true);
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns true when normal and not dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50);
      expect(merc.isAvailable, true);
    });

    test('isAvailable returns true when tired and not dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, status: MercenaryStatus.tired);
      expect(merc.isAvailable, true);
    });
  });

  group('level stat bonuses', () {
    test('level 1 has no bonus (100 str stays 100)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 1);
      expect(merc.effectiveStr, 100);
    });

    test('level 3 gets +20% bonus (100 str becomes 120)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 3);
      expect(merc.effectiveStr, 120);
    });

    test('level 5 gets +40% bonus (100 str becomes 140)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 5);
      expect(merc.effectiveStr, 140);
    });

    test('tired + level 3 stacks multiplicatively (100 * 1.2 * 0.8 = 96)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 3, status: MercenaryStatus.tired);
      expect(merc.effectiveStr, 96);
    });
  });
}
