// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_skill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CombatSkill _$CombatSkillFromJson(Map<String, dynamic> json) {
  return _CombatSkill.fromJson(json);
}

/// @nodoc
mixin _$CombatSkill {
  String get id => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'party_only')
  bool get partyOnly => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_kind')
  TriggerKind get triggerKind => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_condition')
  String? get triggerCondition => throw _privateConstructorUsedError;
  @JsonKey(name: 'action_cost')
  ActionCost get actionCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'cooldown_rounds')
  int get cooldownRounds => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_uses_per_combat')
  int? get maxUsesPerCombat => throw _privateConstructorUsedError;
  @JsonKey(name: 'targeting_kind')
  TargetingKind get targetingKind => throw _privateConstructorUsedError;
  @JsonKey(name: 'targeting_max_count')
  int? get targetingMaxCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'targeting_priority')
  String? get targetingPriority => throw _privateConstructorUsedError;
  @JsonKey(name: 'multi_hit_count')
  int? get multiHitCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'skill_damage_multiplier')
  double? get skillDamageMultiplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'shield_block_bonus')
  double? get shieldBlockBonus => throw _privateConstructorUsedError;
  @JsonKey(name: 'crit_rate_bonus')
  double? get critRateBonus => throw _privateConstructorUsedError;
  @JsonKey(name: 'status_effect_id')
  String? get statusEffectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'status_effect_apply_chance')
  double? get statusEffectApplyChance => throw _privateConstructorUsedError;
  @JsonKey(name: 'status_effect_intensity')
  double? get statusEffectIntensity => throw _privateConstructorUsedError;
  @JsonKey(name: 'status_effect_duration_turns')
  int? get statusEffectDurationTurns => throw _privateConstructorUsedError;
  @JsonKey(name: 'dispel_kind')
  DispelKind? get dispelKind => throw _privateConstructorUsedError;
  @JsonKey(name: 'dispel_max_count')
  int? get dispelMaxCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_label')
  String get displayLabel => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CombatSkillCopyWith<CombatSkill> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CombatSkillCopyWith<$Res> {
  factory $CombatSkillCopyWith(
          CombatSkill value, $Res Function(CombatSkill) then) =
      _$CombatSkillCopyWithImpl<$Res, CombatSkill>;
  @useResult
  $Res call(
      {String id,
      String role,
      @JsonKey(name: 'party_only') bool partyOnly,
      @JsonKey(name: 'trigger_kind') TriggerKind triggerKind,
      @JsonKey(name: 'trigger_condition') String? triggerCondition,
      @JsonKey(name: 'action_cost') ActionCost actionCost,
      @JsonKey(name: 'cooldown_rounds') int cooldownRounds,
      @JsonKey(name: 'max_uses_per_combat') int? maxUsesPerCombat,
      @JsonKey(name: 'targeting_kind') TargetingKind targetingKind,
      @JsonKey(name: 'targeting_max_count') int? targetingMaxCount,
      @JsonKey(name: 'targeting_priority') String? targetingPriority,
      @JsonKey(name: 'multi_hit_count') int? multiHitCount,
      @JsonKey(name: 'skill_damage_multiplier') double? skillDamageMultiplier,
      @JsonKey(name: 'shield_block_bonus') double? shieldBlockBonus,
      @JsonKey(name: 'crit_rate_bonus') double? critRateBonus,
      @JsonKey(name: 'status_effect_id') String? statusEffectId,
      @JsonKey(name: 'status_effect_apply_chance')
      double? statusEffectApplyChance,
      @JsonKey(name: 'status_effect_intensity') double? statusEffectIntensity,
      @JsonKey(name: 'status_effect_duration_turns')
      int? statusEffectDurationTurns,
      @JsonKey(name: 'dispel_kind') DispelKind? dispelKind,
      @JsonKey(name: 'dispel_max_count') int? dispelMaxCount,
      @JsonKey(name: 'display_label') String displayLabel,
      String description});
}

/// @nodoc
class _$CombatSkillCopyWithImpl<$Res, $Val extends CombatSkill>
    implements $CombatSkillCopyWith<$Res> {
  _$CombatSkillCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? partyOnly = null,
    Object? triggerKind = null,
    Object? triggerCondition = freezed,
    Object? actionCost = null,
    Object? cooldownRounds = null,
    Object? maxUsesPerCombat = freezed,
    Object? targetingKind = null,
    Object? targetingMaxCount = freezed,
    Object? targetingPriority = freezed,
    Object? multiHitCount = freezed,
    Object? skillDamageMultiplier = freezed,
    Object? shieldBlockBonus = freezed,
    Object? critRateBonus = freezed,
    Object? statusEffectId = freezed,
    Object? statusEffectApplyChance = freezed,
    Object? statusEffectIntensity = freezed,
    Object? statusEffectDurationTurns = freezed,
    Object? dispelKind = freezed,
    Object? dispelMaxCount = freezed,
    Object? displayLabel = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      partyOnly: null == partyOnly
          ? _value.partyOnly
          : partyOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      triggerKind: null == triggerKind
          ? _value.triggerKind
          : triggerKind // ignore: cast_nullable_to_non_nullable
              as TriggerKind,
      triggerCondition: freezed == triggerCondition
          ? _value.triggerCondition
          : triggerCondition // ignore: cast_nullable_to_non_nullable
              as String?,
      actionCost: null == actionCost
          ? _value.actionCost
          : actionCost // ignore: cast_nullable_to_non_nullable
              as ActionCost,
      cooldownRounds: null == cooldownRounds
          ? _value.cooldownRounds
          : cooldownRounds // ignore: cast_nullable_to_non_nullable
              as int,
      maxUsesPerCombat: freezed == maxUsesPerCombat
          ? _value.maxUsesPerCombat
          : maxUsesPerCombat // ignore: cast_nullable_to_non_nullable
              as int?,
      targetingKind: null == targetingKind
          ? _value.targetingKind
          : targetingKind // ignore: cast_nullable_to_non_nullable
              as TargetingKind,
      targetingMaxCount: freezed == targetingMaxCount
          ? _value.targetingMaxCount
          : targetingMaxCount // ignore: cast_nullable_to_non_nullable
              as int?,
      targetingPriority: freezed == targetingPriority
          ? _value.targetingPriority
          : targetingPriority // ignore: cast_nullable_to_non_nullable
              as String?,
      multiHitCount: freezed == multiHitCount
          ? _value.multiHitCount
          : multiHitCount // ignore: cast_nullable_to_non_nullable
              as int?,
      skillDamageMultiplier: freezed == skillDamageMultiplier
          ? _value.skillDamageMultiplier
          : skillDamageMultiplier // ignore: cast_nullable_to_non_nullable
              as double?,
      shieldBlockBonus: freezed == shieldBlockBonus
          ? _value.shieldBlockBonus
          : shieldBlockBonus // ignore: cast_nullable_to_non_nullable
              as double?,
      critRateBonus: freezed == critRateBonus
          ? _value.critRateBonus
          : critRateBonus // ignore: cast_nullable_to_non_nullable
              as double?,
      statusEffectId: freezed == statusEffectId
          ? _value.statusEffectId
          : statusEffectId // ignore: cast_nullable_to_non_nullable
              as String?,
      statusEffectApplyChance: freezed == statusEffectApplyChance
          ? _value.statusEffectApplyChance
          : statusEffectApplyChance // ignore: cast_nullable_to_non_nullable
              as double?,
      statusEffectIntensity: freezed == statusEffectIntensity
          ? _value.statusEffectIntensity
          : statusEffectIntensity // ignore: cast_nullable_to_non_nullable
              as double?,
      statusEffectDurationTurns: freezed == statusEffectDurationTurns
          ? _value.statusEffectDurationTurns
          : statusEffectDurationTurns // ignore: cast_nullable_to_non_nullable
              as int?,
      dispelKind: freezed == dispelKind
          ? _value.dispelKind
          : dispelKind // ignore: cast_nullable_to_non_nullable
              as DispelKind?,
      dispelMaxCount: freezed == dispelMaxCount
          ? _value.dispelMaxCount
          : dispelMaxCount // ignore: cast_nullable_to_non_nullable
              as int?,
      displayLabel: null == displayLabel
          ? _value.displayLabel
          : displayLabel // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CombatSkillImplCopyWith<$Res>
    implements $CombatSkillCopyWith<$Res> {
  factory _$$CombatSkillImplCopyWith(
          _$CombatSkillImpl value, $Res Function(_$CombatSkillImpl) then) =
      __$$CombatSkillImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String role,
      @JsonKey(name: 'party_only') bool partyOnly,
      @JsonKey(name: 'trigger_kind') TriggerKind triggerKind,
      @JsonKey(name: 'trigger_condition') String? triggerCondition,
      @JsonKey(name: 'action_cost') ActionCost actionCost,
      @JsonKey(name: 'cooldown_rounds') int cooldownRounds,
      @JsonKey(name: 'max_uses_per_combat') int? maxUsesPerCombat,
      @JsonKey(name: 'targeting_kind') TargetingKind targetingKind,
      @JsonKey(name: 'targeting_max_count') int? targetingMaxCount,
      @JsonKey(name: 'targeting_priority') String? targetingPriority,
      @JsonKey(name: 'multi_hit_count') int? multiHitCount,
      @JsonKey(name: 'skill_damage_multiplier') double? skillDamageMultiplier,
      @JsonKey(name: 'shield_block_bonus') double? shieldBlockBonus,
      @JsonKey(name: 'crit_rate_bonus') double? critRateBonus,
      @JsonKey(name: 'status_effect_id') String? statusEffectId,
      @JsonKey(name: 'status_effect_apply_chance')
      double? statusEffectApplyChance,
      @JsonKey(name: 'status_effect_intensity') double? statusEffectIntensity,
      @JsonKey(name: 'status_effect_duration_turns')
      int? statusEffectDurationTurns,
      @JsonKey(name: 'dispel_kind') DispelKind? dispelKind,
      @JsonKey(name: 'dispel_max_count') int? dispelMaxCount,
      @JsonKey(name: 'display_label') String displayLabel,
      String description});
}

/// @nodoc
class __$$CombatSkillImplCopyWithImpl<$Res>
    extends _$CombatSkillCopyWithImpl<$Res, _$CombatSkillImpl>
    implements _$$CombatSkillImplCopyWith<$Res> {
  __$$CombatSkillImplCopyWithImpl(
      _$CombatSkillImpl _value, $Res Function(_$CombatSkillImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? partyOnly = null,
    Object? triggerKind = null,
    Object? triggerCondition = freezed,
    Object? actionCost = null,
    Object? cooldownRounds = null,
    Object? maxUsesPerCombat = freezed,
    Object? targetingKind = null,
    Object? targetingMaxCount = freezed,
    Object? targetingPriority = freezed,
    Object? multiHitCount = freezed,
    Object? skillDamageMultiplier = freezed,
    Object? shieldBlockBonus = freezed,
    Object? critRateBonus = freezed,
    Object? statusEffectId = freezed,
    Object? statusEffectApplyChance = freezed,
    Object? statusEffectIntensity = freezed,
    Object? statusEffectDurationTurns = freezed,
    Object? dispelKind = freezed,
    Object? dispelMaxCount = freezed,
    Object? displayLabel = null,
    Object? description = null,
  }) {
    return _then(_$CombatSkillImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      partyOnly: null == partyOnly
          ? _value.partyOnly
          : partyOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      triggerKind: null == triggerKind
          ? _value.triggerKind
          : triggerKind // ignore: cast_nullable_to_non_nullable
              as TriggerKind,
      triggerCondition: freezed == triggerCondition
          ? _value.triggerCondition
          : triggerCondition // ignore: cast_nullable_to_non_nullable
              as String?,
      actionCost: null == actionCost
          ? _value.actionCost
          : actionCost // ignore: cast_nullable_to_non_nullable
              as ActionCost,
      cooldownRounds: null == cooldownRounds
          ? _value.cooldownRounds
          : cooldownRounds // ignore: cast_nullable_to_non_nullable
              as int,
      maxUsesPerCombat: freezed == maxUsesPerCombat
          ? _value.maxUsesPerCombat
          : maxUsesPerCombat // ignore: cast_nullable_to_non_nullable
              as int?,
      targetingKind: null == targetingKind
          ? _value.targetingKind
          : targetingKind // ignore: cast_nullable_to_non_nullable
              as TargetingKind,
      targetingMaxCount: freezed == targetingMaxCount
          ? _value.targetingMaxCount
          : targetingMaxCount // ignore: cast_nullable_to_non_nullable
              as int?,
      targetingPriority: freezed == targetingPriority
          ? _value.targetingPriority
          : targetingPriority // ignore: cast_nullable_to_non_nullable
              as String?,
      multiHitCount: freezed == multiHitCount
          ? _value.multiHitCount
          : multiHitCount // ignore: cast_nullable_to_non_nullable
              as int?,
      skillDamageMultiplier: freezed == skillDamageMultiplier
          ? _value.skillDamageMultiplier
          : skillDamageMultiplier // ignore: cast_nullable_to_non_nullable
              as double?,
      shieldBlockBonus: freezed == shieldBlockBonus
          ? _value.shieldBlockBonus
          : shieldBlockBonus // ignore: cast_nullable_to_non_nullable
              as double?,
      critRateBonus: freezed == critRateBonus
          ? _value.critRateBonus
          : critRateBonus // ignore: cast_nullable_to_non_nullable
              as double?,
      statusEffectId: freezed == statusEffectId
          ? _value.statusEffectId
          : statusEffectId // ignore: cast_nullable_to_non_nullable
              as String?,
      statusEffectApplyChance: freezed == statusEffectApplyChance
          ? _value.statusEffectApplyChance
          : statusEffectApplyChance // ignore: cast_nullable_to_non_nullable
              as double?,
      statusEffectIntensity: freezed == statusEffectIntensity
          ? _value.statusEffectIntensity
          : statusEffectIntensity // ignore: cast_nullable_to_non_nullable
              as double?,
      statusEffectDurationTurns: freezed == statusEffectDurationTurns
          ? _value.statusEffectDurationTurns
          : statusEffectDurationTurns // ignore: cast_nullable_to_non_nullable
              as int?,
      dispelKind: freezed == dispelKind
          ? _value.dispelKind
          : dispelKind // ignore: cast_nullable_to_non_nullable
              as DispelKind?,
      dispelMaxCount: freezed == dispelMaxCount
          ? _value.dispelMaxCount
          : dispelMaxCount // ignore: cast_nullable_to_non_nullable
              as int?,
      displayLabel: null == displayLabel
          ? _value.displayLabel
          : displayLabel // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CombatSkillImpl implements _CombatSkill {
  const _$CombatSkillImpl(
      {required this.id,
      required this.role,
      @JsonKey(name: 'party_only') this.partyOnly = false,
      @JsonKey(name: 'trigger_kind') required this.triggerKind,
      @JsonKey(name: 'trigger_condition') this.triggerCondition,
      @JsonKey(name: 'action_cost') required this.actionCost,
      @JsonKey(name: 'cooldown_rounds') this.cooldownRounds = 0,
      @JsonKey(name: 'max_uses_per_combat') this.maxUsesPerCombat,
      @JsonKey(name: 'targeting_kind') required this.targetingKind,
      @JsonKey(name: 'targeting_max_count') this.targetingMaxCount,
      @JsonKey(name: 'targeting_priority') this.targetingPriority,
      @JsonKey(name: 'multi_hit_count') this.multiHitCount,
      @JsonKey(name: 'skill_damage_multiplier') this.skillDamageMultiplier,
      @JsonKey(name: 'shield_block_bonus') this.shieldBlockBonus,
      @JsonKey(name: 'crit_rate_bonus') this.critRateBonus,
      @JsonKey(name: 'status_effect_id') this.statusEffectId,
      @JsonKey(name: 'status_effect_apply_chance') this.statusEffectApplyChance,
      @JsonKey(name: 'status_effect_intensity') this.statusEffectIntensity,
      @JsonKey(name: 'status_effect_duration_turns')
      this.statusEffectDurationTurns,
      @JsonKey(name: 'dispel_kind') this.dispelKind,
      @JsonKey(name: 'dispel_max_count') this.dispelMaxCount,
      @JsonKey(name: 'display_label') required this.displayLabel,
      required this.description});

  factory _$CombatSkillImpl.fromJson(Map<String, dynamic> json) =>
      _$$CombatSkillImplFromJson(json);

  @override
  final String id;
  @override
  final String role;
  @override
  @JsonKey(name: 'party_only')
  final bool partyOnly;
  @override
  @JsonKey(name: 'trigger_kind')
  final TriggerKind triggerKind;
  @override
  @JsonKey(name: 'trigger_condition')
  final String? triggerCondition;
  @override
  @JsonKey(name: 'action_cost')
  final ActionCost actionCost;
  @override
  @JsonKey(name: 'cooldown_rounds')
  final int cooldownRounds;
  @override
  @JsonKey(name: 'max_uses_per_combat')
  final int? maxUsesPerCombat;
  @override
  @JsonKey(name: 'targeting_kind')
  final TargetingKind targetingKind;
  @override
  @JsonKey(name: 'targeting_max_count')
  final int? targetingMaxCount;
  @override
  @JsonKey(name: 'targeting_priority')
  final String? targetingPriority;
  @override
  @JsonKey(name: 'multi_hit_count')
  final int? multiHitCount;
  @override
  @JsonKey(name: 'skill_damage_multiplier')
  final double? skillDamageMultiplier;
  @override
  @JsonKey(name: 'shield_block_bonus')
  final double? shieldBlockBonus;
  @override
  @JsonKey(name: 'crit_rate_bonus')
  final double? critRateBonus;
  @override
  @JsonKey(name: 'status_effect_id')
  final String? statusEffectId;
  @override
  @JsonKey(name: 'status_effect_apply_chance')
  final double? statusEffectApplyChance;
  @override
  @JsonKey(name: 'status_effect_intensity')
  final double? statusEffectIntensity;
  @override
  @JsonKey(name: 'status_effect_duration_turns')
  final int? statusEffectDurationTurns;
  @override
  @JsonKey(name: 'dispel_kind')
  final DispelKind? dispelKind;
  @override
  @JsonKey(name: 'dispel_max_count')
  final int? dispelMaxCount;
  @override
  @JsonKey(name: 'display_label')
  final String displayLabel;
  @override
  final String description;

  @override
  String toString() {
    return 'CombatSkill(id: $id, role: $role, partyOnly: $partyOnly, triggerKind: $triggerKind, triggerCondition: $triggerCondition, actionCost: $actionCost, cooldownRounds: $cooldownRounds, maxUsesPerCombat: $maxUsesPerCombat, targetingKind: $targetingKind, targetingMaxCount: $targetingMaxCount, targetingPriority: $targetingPriority, multiHitCount: $multiHitCount, skillDamageMultiplier: $skillDamageMultiplier, shieldBlockBonus: $shieldBlockBonus, critRateBonus: $critRateBonus, statusEffectId: $statusEffectId, statusEffectApplyChance: $statusEffectApplyChance, statusEffectIntensity: $statusEffectIntensity, statusEffectDurationTurns: $statusEffectDurationTurns, dispelKind: $dispelKind, dispelMaxCount: $dispelMaxCount, displayLabel: $displayLabel, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CombatSkillImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.partyOnly, partyOnly) ||
                other.partyOnly == partyOnly) &&
            (identical(other.triggerKind, triggerKind) ||
                other.triggerKind == triggerKind) &&
            (identical(other.triggerCondition, triggerCondition) ||
                other.triggerCondition == triggerCondition) &&
            (identical(other.actionCost, actionCost) ||
                other.actionCost == actionCost) &&
            (identical(other.cooldownRounds, cooldownRounds) ||
                other.cooldownRounds == cooldownRounds) &&
            (identical(other.maxUsesPerCombat, maxUsesPerCombat) ||
                other.maxUsesPerCombat == maxUsesPerCombat) &&
            (identical(other.targetingKind, targetingKind) ||
                other.targetingKind == targetingKind) &&
            (identical(other.targetingMaxCount, targetingMaxCount) ||
                other.targetingMaxCount == targetingMaxCount) &&
            (identical(other.targetingPriority, targetingPriority) ||
                other.targetingPriority == targetingPriority) &&
            (identical(other.multiHitCount, multiHitCount) ||
                other.multiHitCount == multiHitCount) &&
            (identical(other.skillDamageMultiplier, skillDamageMultiplier) ||
                other.skillDamageMultiplier == skillDamageMultiplier) &&
            (identical(other.shieldBlockBonus, shieldBlockBonus) ||
                other.shieldBlockBonus == shieldBlockBonus) &&
            (identical(other.critRateBonus, critRateBonus) ||
                other.critRateBonus == critRateBonus) &&
            (identical(other.statusEffectId, statusEffectId) ||
                other.statusEffectId == statusEffectId) &&
            (identical(
                    other.statusEffectApplyChance, statusEffectApplyChance) ||
                other.statusEffectApplyChance == statusEffectApplyChance) &&
            (identical(other.statusEffectIntensity, statusEffectIntensity) ||
                other.statusEffectIntensity == statusEffectIntensity) &&
            (identical(other.statusEffectDurationTurns,
                    statusEffectDurationTurns) ||
                other.statusEffectDurationTurns == statusEffectDurationTurns) &&
            (identical(other.dispelKind, dispelKind) ||
                other.dispelKind == dispelKind) &&
            (identical(other.dispelMaxCount, dispelMaxCount) ||
                other.dispelMaxCount == dispelMaxCount) &&
            (identical(other.displayLabel, displayLabel) ||
                other.displayLabel == displayLabel) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        role,
        partyOnly,
        triggerKind,
        triggerCondition,
        actionCost,
        cooldownRounds,
        maxUsesPerCombat,
        targetingKind,
        targetingMaxCount,
        targetingPriority,
        multiHitCount,
        skillDamageMultiplier,
        shieldBlockBonus,
        critRateBonus,
        statusEffectId,
        statusEffectApplyChance,
        statusEffectIntensity,
        statusEffectDurationTurns,
        dispelKind,
        dispelMaxCount,
        displayLabel,
        description
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CombatSkillImplCopyWith<_$CombatSkillImpl> get copyWith =>
      __$$CombatSkillImplCopyWithImpl<_$CombatSkillImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CombatSkillImplToJson(
      this,
    );
  }
}

abstract class _CombatSkill implements CombatSkill {
  const factory _CombatSkill(
      {required final String id,
      required final String role,
      @JsonKey(name: 'party_only') final bool partyOnly,
      @JsonKey(name: 'trigger_kind') required final TriggerKind triggerKind,
      @JsonKey(name: 'trigger_condition') final String? triggerCondition,
      @JsonKey(name: 'action_cost') required final ActionCost actionCost,
      @JsonKey(name: 'cooldown_rounds') final int cooldownRounds,
      @JsonKey(name: 'max_uses_per_combat') final int? maxUsesPerCombat,
      @JsonKey(name: 'targeting_kind')
      required final TargetingKind targetingKind,
      @JsonKey(name: 'targeting_max_count') final int? targetingMaxCount,
      @JsonKey(name: 'targeting_priority') final String? targetingPriority,
      @JsonKey(name: 'multi_hit_count') final int? multiHitCount,
      @JsonKey(name: 'skill_damage_multiplier')
      final double? skillDamageMultiplier,
      @JsonKey(name: 'shield_block_bonus') final double? shieldBlockBonus,
      @JsonKey(name: 'crit_rate_bonus') final double? critRateBonus,
      @JsonKey(name: 'status_effect_id') final String? statusEffectId,
      @JsonKey(name: 'status_effect_apply_chance')
      final double? statusEffectApplyChance,
      @JsonKey(name: 'status_effect_intensity')
      final double? statusEffectIntensity,
      @JsonKey(name: 'status_effect_duration_turns')
      final int? statusEffectDurationTurns,
      @JsonKey(name: 'dispel_kind') final DispelKind? dispelKind,
      @JsonKey(name: 'dispel_max_count') final int? dispelMaxCount,
      @JsonKey(name: 'display_label') required final String displayLabel,
      required final String description}) = _$CombatSkillImpl;

  factory _CombatSkill.fromJson(Map<String, dynamic> json) =
      _$CombatSkillImpl.fromJson;

  @override
  String get id;
  @override
  String get role;
  @override
  @JsonKey(name: 'party_only')
  bool get partyOnly;
  @override
  @JsonKey(name: 'trigger_kind')
  TriggerKind get triggerKind;
  @override
  @JsonKey(name: 'trigger_condition')
  String? get triggerCondition;
  @override
  @JsonKey(name: 'action_cost')
  ActionCost get actionCost;
  @override
  @JsonKey(name: 'cooldown_rounds')
  int get cooldownRounds;
  @override
  @JsonKey(name: 'max_uses_per_combat')
  int? get maxUsesPerCombat;
  @override
  @JsonKey(name: 'targeting_kind')
  TargetingKind get targetingKind;
  @override
  @JsonKey(name: 'targeting_max_count')
  int? get targetingMaxCount;
  @override
  @JsonKey(name: 'targeting_priority')
  String? get targetingPriority;
  @override
  @JsonKey(name: 'multi_hit_count')
  int? get multiHitCount;
  @override
  @JsonKey(name: 'skill_damage_multiplier')
  double? get skillDamageMultiplier;
  @override
  @JsonKey(name: 'shield_block_bonus')
  double? get shieldBlockBonus;
  @override
  @JsonKey(name: 'crit_rate_bonus')
  double? get critRateBonus;
  @override
  @JsonKey(name: 'status_effect_id')
  String? get statusEffectId;
  @override
  @JsonKey(name: 'status_effect_apply_chance')
  double? get statusEffectApplyChance;
  @override
  @JsonKey(name: 'status_effect_intensity')
  double? get statusEffectIntensity;
  @override
  @JsonKey(name: 'status_effect_duration_turns')
  int? get statusEffectDurationTurns;
  @override
  @JsonKey(name: 'dispel_kind')
  DispelKind? get dispelKind;
  @override
  @JsonKey(name: 'dispel_max_count')
  int? get dispelMaxCount;
  @override
  @JsonKey(name: 'display_label')
  String get displayLabel;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$CombatSkillImplCopyWith<_$CombatSkillImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
