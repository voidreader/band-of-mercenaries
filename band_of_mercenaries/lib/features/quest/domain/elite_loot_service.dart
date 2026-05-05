import 'dart:math';

import 'package:band_of_mercenaries/core/models/elite_loot_entry.dart';

class EliteLootResult {
  final int bonusGold;
  final List<String> itemDrops;

  const EliteLootResult({required this.bonusGold, required this.itemDrops});

  static const EliteLootResult empty =
      EliteLootResult(bonusGold: 0, itemDrops: []);
}

class EliteLootService {
  EliteLootService._();

  static EliteLootResult rollDrops({
    required String eliteId,
    required List<EliteLootEntry> lootEntries,
    required Random random,
  }) {
    final entries = lootEntries.where((e) => e.eliteId == eliteId).toList();
    if (entries.isEmpty) return EliteLootResult.empty;

    int bonusGold = 0;
    final itemDrops = <String>[];

    for (final entry in entries) {
      if (random.nextDouble() >= entry.dropRate) continue;

      switch (entry.dropType) {
        case 'gold':
          final min = entry.goldMin ?? 0;
          final max = entry.goldMax ?? min;
          bonusGold += (max > min)
              ? min + random.nextInt(max - min + 1)
              : min;
        case 'essence':
        case 'equipment':
        case 'guild_item':
        case 'material':
          if (entry.itemId != null) {
            for (var i = 0; i < entry.quantity; i++) {
              itemDrops.add(entry.itemId!);
            }
          }
        default:
          break;
      }
    }

    return EliteLootResult(bonusGold: bonusGold, itemDrops: itemDrops);
  }
}
