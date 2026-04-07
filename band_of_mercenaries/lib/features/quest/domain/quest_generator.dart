import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

class QuestGenerator {
  static const _uuid = Uuid();

  static List<ActiveQuest> generateQuests({
    required int regionTier,
    required int regionId,
    required List<QuestPool> questPools,
    required List<QuestType> questTypes,
    required int count,
    required Random random,
  }) {
    final filtered = questPools
        .where((q) => q.minRegionDiff <= regionTier && q.maxRegionDiff >= regionTier)
        .toList();
    if (filtered.isEmpty) return [];
    filtered.shuffle(random);
    final selected = filtered.take(count).toList();

    return selected.map((pool) {
      final questType = questTypes[random.nextInt(questTypes.length)];
      return ActiveQuest(
        id: _uuid.v4(),
        questPoolId: pool.id,
        questTypeId: questType.id,
        difficulty: pool.difficulty.round(),
        region: regionId,
        questName: pool.name,
      );
    }).toList();
  }
}
