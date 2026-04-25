import 'package:freezed_annotation/freezed_annotation.dart';

part 'chain_quest_data.freezed.dart';
part 'chain_quest_data.g.dart';

@freezed
class ChainQuestData with _$ChainQuestData {
  const factory ChainQuestData({
    required String id,
    @JsonKey(name: 'chain_id') required String chainId,
    @JsonKey(name: 'chain_name') required String chainName,
    required int step,
    @JsonKey(name: 'total_steps') required int totalSteps,
    @JsonKey(name: 'region_id') int? regionId,
    @JsonKey(name: 'target_region_id') int? targetRegionId,
    required String name,
    required String description,
    @JsonKey(name: 'quest_type_id') required String questTypeId,
    required int difficulty,
    @JsonKey(name: 'combat_power') required int combatPower,
    @JsonKey(name: 'reward_gold') required int rewardGold,
    @Default(0) @JsonKey(name: 'reward_xp') int rewardXp,
    @Default({}) @JsonKey(name: 'reward_items') Map<String, int> rewardItems,
    @Default(false) @JsonKey(name: 'final_reward') bool finalReward,
    @JsonKey(name: 'final_reputation_bonus') int? finalReputationBonus,
    @JsonKey(name: 'duration_seconds') required int durationSeconds,
    @Default(0)
    @JsonKey(name: 'next_step_delay_seconds')
    int nextStepDelaySeconds,
    @JsonKey(name: 'faction_tag_id') String? factionTagId,
  }) = _ChainQuestData;

  factory ChainQuestData.fromJson(Map<String, dynamic> json) =>
      _$ChainQuestDataFromJson(json);
}
