// M8b 페이즈 4 #2 — CombatSkill 정적 카탈로그 모델
import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_enums.dart';

part 'combat_skill.freezed.dart';
part 'combat_skill.g.dart';

@freezed
class CombatSkill with _$CombatSkill {
  const factory CombatSkill({
    required String id,
    required String role,
    @Default(false) @JsonKey(name: 'party_only') bool partyOnly,
    @JsonKey(name: 'trigger_kind') required TriggerKind triggerKind,
    @JsonKey(name: 'trigger_condition') String? triggerCondition,
    @JsonKey(name: 'action_cost') required ActionCost actionCost,
    @Default(0) @JsonKey(name: 'cooldown_rounds') int cooldownRounds,
    @JsonKey(name: 'max_uses_per_combat') int? maxUsesPerCombat,
    @JsonKey(name: 'targeting_kind') required TargetingKind targetingKind,
    @JsonKey(name: 'targeting_max_count') int? targetingMaxCount,
    @JsonKey(name: 'targeting_priority') String? targetingPriority,
    @JsonKey(name: 'multi_hit_count') int? multiHitCount,
    @JsonKey(name: 'skill_damage_multiplier') double? skillDamageMultiplier,
    @JsonKey(name: 'shield_block_bonus') double? shieldBlockBonus,
    @JsonKey(name: 'crit_rate_bonus') double? critRateBonus,
    @JsonKey(name: 'status_effect_id') String? statusEffectId,
    @JsonKey(name: 'status_effect_apply_chance') double? statusEffectApplyChance,
    @JsonKey(name: 'status_effect_intensity') double? statusEffectIntensity,
    @JsonKey(name: 'status_effect_duration_turns') int? statusEffectDurationTurns,
    @JsonKey(name: 'dispel_kind') DispelKind? dispelKind,
    @JsonKey(name: 'dispel_max_count') int? dispelMaxCount,
    @JsonKey(name: 'display_label') required String displayLabel,
    required String description,
  }) = _CombatSkill;

  factory CombatSkill.fromJson(Map<String, dynamic> json) =>
      _$CombatSkillFromJson(json);
}
