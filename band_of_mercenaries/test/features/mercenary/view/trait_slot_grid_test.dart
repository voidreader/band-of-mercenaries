import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_slot_grid.dart';

void main() {
  group('buildAcquiredSlotCategories', () {
    test('2개 보유 시 빈 슬롯 2개 추가', () {
      final ownedCategories = ['CombatStyle', 'Survival'];
      final slots = TraitSlotGrid.buildAcquiredSlotCategories(
        ownedCategoryKeys: ownedCategories,
        maxAcquired: 4,
      );
      expect(slots.length, 4);
      expect(slots[0], 'CombatStyle');
      expect(slots[1], 'Survival');
      expect(slots.where((s) => !ownedCategories.contains(s)).length, 2);
    });

    test('4개 보유 시 빈 슬롯 0개', () {
      final ownedCategories = ['CombatStyle', 'Survival', 'Behavior', 'Mental'];
      final slots = TraitSlotGrid.buildAcquiredSlotCategories(
        ownedCategoryKeys: ownedCategories,
        maxAcquired: 4,
      );
      expect(slots.length, 4);
    });

    test('0개 보유 시 빈 슬롯 4개', () {
      final slots = TraitSlotGrid.buildAcquiredSlotCategories(
        ownedCategoryKeys: [],
        maxAcquired: 4,
      );
      expect(slots.length, 4);
    });
  });
}
