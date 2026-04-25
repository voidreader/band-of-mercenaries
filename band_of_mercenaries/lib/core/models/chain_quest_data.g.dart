// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chain_quest_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChainQuestDataImpl _$$ChainQuestDataImplFromJson(Map<String, dynamic> json) =>
    _$ChainQuestDataImpl(
      id: json['id'] as String,
      chainId: json['chain_id'] as String,
      chainName: json['chain_name'] as String,
      step: (json['step'] as num).toInt(),
      totalSteps: (json['total_steps'] as num).toInt(),
      regionId: (json['region_id'] as num?)?.toInt(),
      targetRegionId: (json['target_region_id'] as num?)?.toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      questTypeId: json['quest_type_id'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      combatPower: (json['combat_power'] as num).toInt(),
      rewardGold: (json['reward_gold'] as num).toInt(),
      rewardXp: (json['reward_xp'] as num?)?.toInt() ?? 0,
      rewardItems: (json['reward_items'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      finalReward: json['final_reward'] as bool? ?? false,
      finalReputationBonus: (json['final_reputation_bonus'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      nextStepDelaySeconds:
          (json['next_step_delay_seconds'] as num?)?.toInt() ?? 0,
      factionTagId: json['faction_tag_id'] as String?,
    );

Map<String, dynamic> _$$ChainQuestDataImplToJson(
        _$ChainQuestDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chain_id': instance.chainId,
      'chain_name': instance.chainName,
      'step': instance.step,
      'total_steps': instance.totalSteps,
      'region_id': instance.regionId,
      'target_region_id': instance.targetRegionId,
      'name': instance.name,
      'description': instance.description,
      'quest_type_id': instance.questTypeId,
      'difficulty': instance.difficulty,
      'combat_power': instance.combatPower,
      'reward_gold': instance.rewardGold,
      'reward_xp': instance.rewardXp,
      'reward_items': instance.rewardItems,
      'final_reward': instance.finalReward,
      'final_reputation_bonus': instance.finalReputationBonus,
      'duration_seconds': instance.durationSeconds,
      'next_step_delay_seconds': instance.nextStepDelaySeconds,
      'faction_tag_id': instance.factionTagId,
    };
