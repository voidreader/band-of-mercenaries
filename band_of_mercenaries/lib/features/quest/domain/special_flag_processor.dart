import 'dart:math';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/special_flag_result.dart';

/// 퀘스트 완료 시 특수 플래그(specialFlags) 처리 순수 정적 서비스.
///
/// 6종 플래그를 처리하여 [SpecialFlagResult]를 반환한다.
/// 실제 Hive 저장·Provider 갱신은 호출자가 담당한다.
class SpecialFlagProcessor {
  SpecialFlagProcessor._();

  static SpecialFlagResult apply({
    required ActiveQuest quest,
    required QuestResult resultType,
    required List<Mercenary> partyMercs,
    required StaticGameData staticData,
    required Random random,
  }) {
    final flags = quest.specialFlags;
    if (flags == null || flags.isEmpty) {
      return SpecialFlagResult.empty();
    }

    final extraItemIds = <String>[];
    var extraReputation = 0;
    final boostedMercIds = <String>[];
    var reputationPenaltyApplied = false;

    final isSuccess =
        resultType == QuestResult.success ||
        resultType == QuestResult.greatSuccess;

    // 성공·대성공에만 적용되는 플래그
    if (isSuccess) {
      // 1. trait_learning_boost: 파티 전원 트레잇 학습 부스트
      if (flags.containsKey('trait_learning_boost') &&
          flags['trait_learning_boost'] is Map<String, dynamic>) {
        boostedMercIds.addAll(partyMercs.map((m) => m.id));
      }

      // 2. guild_drop_rare: 고급 길드 아이템 드랍
      _tryGuildDrop(flags, 'guild_drop_rare', extraItemIds, random);

      // 3. guild_drop_ultra_rare: 초고급 길드 아이템 드랍
      _tryGuildDrop(flags, 'guild_drop_ultra_rare', extraItemIds, random);

      // 4. essence_drop_bonus: 정수 아이템 랜덤 드랍
      if (flags.containsKey('essence_drop_bonus') &&
          flags['essence_drop_bonus'] is Map<String, dynamic>) {
        final flagData = flags['essence_drop_bonus'] as Map<String, dynamic>;
        if (flagData.containsKey('drop_rate') &&
            flagData.containsKey('quantity')) {
          final dropRate = (flagData['drop_rate'] as num).toDouble();
          final quantity = (flagData['quantity'] as num).toInt();
          if (random.nextDouble() < dropRate) {
            final essenceItems = staticData.items
                .where(
                  (i) =>
                      i.id.startsWith('essence_') &&
                      i.category == 'consumable',
                )
                .toList();
            if (essenceItems.isNotEmpty) {
              final randomEssence =
                  essenceItems[random.nextInt(essenceItems.length)];
              extraItemIds.addAll(List.filled(quantity, randomEssence.id));
            }
          }
        }
      }

      // 5. equipment_drop_bonus: 장비 아이템 랜덤 드랍
      if (flags.containsKey('equipment_drop_bonus') &&
          flags['equipment_drop_bonus'] is Map<String, dynamic>) {
        final flagData = flags['equipment_drop_bonus'] as Map<String, dynamic>;
        if (flagData.containsKey('drop_rate')) {
          final dropRate = (flagData['drop_rate'] as num).toDouble();
          final tierRangeRaw = flagData['tier_range'];
          final tierRange = tierRangeRaw is List && tierRangeRaw.length == 2
              ? [tierRangeRaw[0] as int, tierRangeRaw[1] as int]
              : null;
          if (random.nextDouble() < dropRate) {
            final equipmentItems = staticData.items
                .where(
                  (i) =>
                      i.category == 'personal_equipment' &&
                      (tierRange == null ||
                          (i.tier >= tierRange[0] && i.tier <= tierRange[1])),
                )
                .toList();
            if (equipmentItems.isNotEmpty) {
              final randomEquipment =
                  equipmentItems[random.nextInt(equipmentItems.length)];
              extraItemIds.add(randomEquipment.id);
            }
          }
        }
      }
    }

    // 6. reputation_penalty: 결과 무관 항상 적용
    if (flags.containsKey('reputation_penalty') &&
        flags['reputation_penalty'] is Map<String, dynamic>) {
      final flagData = flags['reputation_penalty'] as Map<String, dynamic>;
      if (flagData.containsKey('amount')) {
        final amount = (flagData['amount'] as num).toInt();
        extraReputation += amount;
        reputationPenaltyApplied = true;
      }
    }

    return SpecialFlagResult(
      extraItemIds: extraItemIds,
      extraReputation: extraReputation,
      boostedMercIds: boostedMercIds,
      reputationPenaltyApplied: reputationPenaltyApplied,
    );
  }

  /// guild_drop_rare / guild_drop_ultra_rare 공통 드랍 처리.
  /// flagKey에 해당하는 플래그가 있고 drop_rate 확률을 통과하면 item_id를 [result]에 추가한다.
  static void _tryGuildDrop(
    Map<String, dynamic> flags,
    String flagKey,
    List<String> result,
    Random random,
  ) {
    if (!flags.containsKey(flagKey)) return;
    if (flags[flagKey] is! Map<String, dynamic>) return;
    final flagData = flags[flagKey] as Map<String, dynamic>;
    if (!flagData.containsKey('drop_rate') || !flagData.containsKey('item_id')) return;
    final dropRate = (flagData['drop_rate'] as num).toDouble();
    final itemId = flagData['item_id'] as String;
    if (random.nextDouble() < dropRate) {
      result.add(itemId);
    }
  }
}
