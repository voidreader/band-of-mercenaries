// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CombatSkillImpl _$$CombatSkillImplFromJson(Map<String, dynamic> json) =>
    _$CombatSkillImpl(
      id: json['id'] as String,
      role: json['role'] as String,
      partyOnly: json['party_only'] as bool? ?? false,
      triggerKind: $enumDecode(_$TriggerKindEnumMap, json['trigger_kind']),
      triggerCondition: json['trigger_condition'] as String?,
      actionCost: $enumDecode(_$ActionCostEnumMap, json['action_cost']),
      cooldownRounds: (json['cooldown_rounds'] as num?)?.toInt() ?? 0,
      maxUsesPerCombat: (json['max_uses_per_combat'] as num?)?.toInt(),
      targetingKind:
          $enumDecode(_$TargetingKindEnumMap, json['targeting_kind']),
      targetingMaxCount: (json['targeting_max_count'] as num?)?.toInt(),
      targetingPriority: json['targeting_priority'] as String?,
      multiHitCount: (json['multi_hit_count'] as num?)?.toInt(),
      skillDamageMultiplier:
          (json['skill_damage_multiplier'] as num?)?.toDouble(),
      shieldBlockBonus: (json['shield_block_bonus'] as num?)?.toDouble(),
      critRateBonus: (json['crit_rate_bonus'] as num?)?.toDouble(),
      statusEffectId: json['status_effect_id'] as String?,
      statusEffectApplyChance:
          (json['status_effect_apply_chance'] as num?)?.toDouble(),
      statusEffectIntensity:
          (json['status_effect_intensity'] as num?)?.toDouble(),
      statusEffectDurationTurns:
          (json['status_effect_duration_turns'] as num?)?.toInt(),
      dispelKind: $enumDecodeNullable(_$DispelKindEnumMap, json['dispel_kind']),
      dispelMaxCount: (json['dispel_max_count'] as num?)?.toInt(),
      displayLabel: json['display_label'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$CombatSkillImplToJson(_$CombatSkillImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'party_only': instance.partyOnly,
      'trigger_kind': _$TriggerKindEnumMap[instance.triggerKind]!,
      'trigger_condition': instance.triggerCondition,
      'action_cost': _$ActionCostEnumMap[instance.actionCost]!,
      'cooldown_rounds': instance.cooldownRounds,
      'max_uses_per_combat': instance.maxUsesPerCombat,
      'targeting_kind': _$TargetingKindEnumMap[instance.targetingKind]!,
      'targeting_max_count': instance.targetingMaxCount,
      'targeting_priority': instance.targetingPriority,
      'multi_hit_count': instance.multiHitCount,
      'skill_damage_multiplier': instance.skillDamageMultiplier,
      'shield_block_bonus': instance.shieldBlockBonus,
      'crit_rate_bonus': instance.critRateBonus,
      'status_effect_id': instance.statusEffectId,
      'status_effect_apply_chance': instance.statusEffectApplyChance,
      'status_effect_intensity': instance.statusEffectIntensity,
      'status_effect_duration_turns': instance.statusEffectDurationTurns,
      'dispel_kind': _$DispelKindEnumMap[instance.dispelKind],
      'dispel_max_count': instance.dispelMaxCount,
      'display_label': instance.displayLabel,
      'description': instance.description,
    };

const _$TriggerKindEnumMap = {
  TriggerKind.passive: 'passive',
  TriggerKind.active: 'active',
  TriggerKind.triggered: 'triggered',
  TriggerKind.onHit: 'on_hit',
  TriggerKind.onKill: 'on_kill',
};

const _$ActionCostEnumMap = {
  ActionCost.action: 'action',
  ActionCost.extraAction: 'extraAction',
  ActionCost.passive: 'passive',
};

const _$TargetingKindEnumMap = {
  TargetingKind.self: 'self',
  TargetingKind.singleEnemy: 'single_enemy',
  TargetingKind.singleAlly: 'single_ally',
  TargetingKind.aoeEnemy: 'aoe_enemy',
  TargetingKind.aoeAlly: 'aoe_ally',
  TargetingKind.party: 'party',
};

const _$DispelKindEnumMap = {
  DispelKind.debuff: 'debuff',
  DispelKind.buff: 'buff',
  DispelKind.dot: 'dot',
  DispelKind.debuffPlusDot: 'debuff+dot',
};
