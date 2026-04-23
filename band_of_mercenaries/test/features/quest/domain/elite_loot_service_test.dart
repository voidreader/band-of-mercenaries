import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/elite_loot_entry.dart';
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart';

void main() {
  group('EliteLootService.rollDrops', () {
    const eliteId = 'elite_001';
    const otherId = 'elite_999';

    EliteLootEntry makeGoldEntry({
      required int goldMin,
      required int goldMax,
      double dropRate = 1.0,
    }) {
      return EliteLootEntry(
        id: 'entry_gold',
        eliteId: eliteId,
        dropType: 'gold',
        goldMin: goldMin,
        goldMax: goldMax,
        dropRate: dropRate,
        rarityGrade: 'common',
      );
    }

    EliteLootEntry makeItemEntry({
      required String dropType,
      required String itemId,
      double dropRate = 1.0,
      int quantity = 1,
    }) {
      return EliteLootEntry(
        id: 'entry_$dropType',
        eliteId: eliteId,
        dropType: dropType,
        itemId: itemId,
        dropRate: dropRate,
        rarityGrade: 'common',
        quantity: quantity,
      );
    }

    test('빈 lootEntries → EliteLootResult.empty 동일 결과', () {
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [],
        random: Random(42),
      );
      expect(result.bonusGold, 0);
      expect(result.itemDrops, isEmpty);
    });

    test('dropRate = 0.0 → 드랍 없음', () {
      final entry = makeGoldEntry(goldMin: 100, goldMax: 200, dropRate: 0.0);
      for (final seed in [0, 1, 7, 42, 99]) {
        final result = EliteLootService.rollDrops(
          eliteId: eliteId,
          lootEntries: [entry],
          random: Random(seed),
        );
        expect(result.bonusGold, 0, reason: 'seed=$seed 에서 드랍 없어야 함');
        expect(result.itemDrops, isEmpty, reason: 'seed=$seed 에서 아이템 없어야 함');
      }
    });

    test('dropRate = 1.0 (gold) → goldMin == goldMax 일 때 정확한 금액 반환', () {
      final entry = makeGoldEntry(goldMin: 150, goldMax: 150);
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [entry],
        random: Random(42),
      );
      expect(result.bonusGold, 150);
      expect(result.itemDrops, isEmpty);
    });

    test('dropRate = 1.0 (gold) → goldMin < goldMax 일 때 범위 내 값 반환', () {
      const min = 50;
      const max = 100;
      final entry = makeGoldEntry(goldMin: min, goldMax: max);
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [entry],
        random: Random(42),
      );
      expect(result.bonusGold, greaterThanOrEqualTo(min));
      expect(result.bonusGold, lessThanOrEqualTo(max));
    });

    test('dropRate = 1.0 (essence) → itemDrops에 해당 itemId 포함', () {
      final entry = makeItemEntry(dropType: 'essence', itemId: 'essence_fire');
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [entry],
        random: Random(42),
      );
      expect(result.itemDrops, contains('essence_fire'));
      expect(result.bonusGold, 0);
    });

    test('dropRate = 1.0 (equipment) → itemDrops에 해당 itemId 포함', () {
      final entry = makeItemEntry(dropType: 'equipment', itemId: 'sword_rare');
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [entry],
        random: Random(42),
      );
      expect(result.itemDrops, contains('sword_rare'));
      expect(result.bonusGold, 0);
    });

    test('dropRate = 1.0 (guild_item) → itemDrops에 해당 itemId 포함', () {
      final entry = makeItemEntry(dropType: 'guild_item', itemId: 'guild_banner');
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [entry],
        random: Random(42),
      );
      expect(result.itemDrops, contains('guild_banner'));
      expect(result.bonusGold, 0);
    });

    test('quantity = 3, dropRate = 1.0 → itemDrops에 동일 itemId 3개 포함', () {
      final entry = makeItemEntry(dropType: 'essence', itemId: 'essence_ice', quantity: 3);
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [entry],
        random: Random(42),
      );
      expect(result.itemDrops.where((id) => id == 'essence_ice').length, 3);
    });

    test('다른 elite_id의 엔트리는 결과에 포함되지 않음', () {
      final otherEntry = EliteLootEntry(
        id: 'entry_other',
        eliteId: otherId,
        dropType: 'gold',
        goldMin: 500,
        goldMax: 500,
        dropRate: 1.0,
        rarityGrade: 'rare',
      );
      final result = EliteLootService.rollDrops(
        eliteId: eliteId,
        lootEntries: [otherEntry],
        random: Random(42),
      );
      expect(result.bonusGold, 0);
      expect(result.itemDrops, isEmpty);
    });
  });
}
