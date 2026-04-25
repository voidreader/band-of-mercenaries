// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chain_quest_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChainQuestData _$ChainQuestDataFromJson(Map<String, dynamic> json) {
  return _ChainQuestData.fromJson(json);
}

/// @nodoc
mixin _$ChainQuestData {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'chain_id')
  String get chainId => throw _privateConstructorUsedError;
  @JsonKey(name: 'chain_name')
  String get chainName => throw _privateConstructorUsedError;
  int get step => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_steps')
  int get totalSteps => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_id')
  int? get regionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_region_id')
  int? get targetRegionId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'quest_type_id')
  String get questTypeId => throw _privateConstructorUsedError;
  int get difficulty => throw _privateConstructorUsedError;
  @JsonKey(name: 'combat_power')
  int get combatPower => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_gold')
  int get rewardGold => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_xp')
  int get rewardXp => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_items')
  Map<String, int> get rewardItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'final_reward')
  bool get finalReward => throw _privateConstructorUsedError;
  @JsonKey(name: 'final_reputation_bonus')
  int? get finalReputationBonus => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_seconds')
  int get durationSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_step_delay_seconds')
  int get nextStepDelaySeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_tag_id')
  String? get factionTagId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChainQuestDataCopyWith<ChainQuestData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChainQuestDataCopyWith<$Res> {
  factory $ChainQuestDataCopyWith(
          ChainQuestData value, $Res Function(ChainQuestData) then) =
      _$ChainQuestDataCopyWithImpl<$Res, ChainQuestData>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'chain_id') String chainId,
      @JsonKey(name: 'chain_name') String chainName,
      int step,
      @JsonKey(name: 'total_steps') int totalSteps,
      @JsonKey(name: 'region_id') int? regionId,
      @JsonKey(name: 'target_region_id') int? targetRegionId,
      String name,
      String description,
      @JsonKey(name: 'quest_type_id') String questTypeId,
      int difficulty,
      @JsonKey(name: 'combat_power') int combatPower,
      @JsonKey(name: 'reward_gold') int rewardGold,
      @JsonKey(name: 'reward_xp') int rewardXp,
      @JsonKey(name: 'reward_items') Map<String, int> rewardItems,
      @JsonKey(name: 'final_reward') bool finalReward,
      @JsonKey(name: 'final_reputation_bonus') int? finalReputationBonus,
      @JsonKey(name: 'duration_seconds') int durationSeconds,
      @JsonKey(name: 'next_step_delay_seconds') int nextStepDelaySeconds,
      @JsonKey(name: 'faction_tag_id') String? factionTagId});
}

/// @nodoc
class _$ChainQuestDataCopyWithImpl<$Res, $Val extends ChainQuestData>
    implements $ChainQuestDataCopyWith<$Res> {
  _$ChainQuestDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chainId = null,
    Object? chainName = null,
    Object? step = null,
    Object? totalSteps = null,
    Object? regionId = freezed,
    Object? targetRegionId = freezed,
    Object? name = null,
    Object? description = null,
    Object? questTypeId = null,
    Object? difficulty = null,
    Object? combatPower = null,
    Object? rewardGold = null,
    Object? rewardXp = null,
    Object? rewardItems = null,
    Object? finalReward = null,
    Object? finalReputationBonus = freezed,
    Object? durationSeconds = null,
    Object? nextStepDelaySeconds = null,
    Object? factionTagId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      chainName: null == chainName
          ? _value.chainName
          : chainName // ignore: cast_nullable_to_non_nullable
              as String,
      step: null == step
          ? _value.step
          : step // ignore: cast_nullable_to_non_nullable
              as int,
      totalSteps: null == totalSteps
          ? _value.totalSteps
          : totalSteps // ignore: cast_nullable_to_non_nullable
              as int,
      regionId: freezed == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int?,
      targetRegionId: freezed == targetRegionId
          ? _value.targetRegionId
          : targetRegionId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      questTypeId: null == questTypeId
          ? _value.questTypeId
          : questTypeId // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
      combatPower: null == combatPower
          ? _value.combatPower
          : combatPower // ignore: cast_nullable_to_non_nullable
              as int,
      rewardGold: null == rewardGold
          ? _value.rewardGold
          : rewardGold // ignore: cast_nullable_to_non_nullable
              as int,
      rewardXp: null == rewardXp
          ? _value.rewardXp
          : rewardXp // ignore: cast_nullable_to_non_nullable
              as int,
      rewardItems: null == rewardItems
          ? _value.rewardItems
          : rewardItems // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      finalReward: null == finalReward
          ? _value.finalReward
          : finalReward // ignore: cast_nullable_to_non_nullable
              as bool,
      finalReputationBonus: freezed == finalReputationBonus
          ? _value.finalReputationBonus
          : finalReputationBonus // ignore: cast_nullable_to_non_nullable
              as int?,
      durationSeconds: null == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      nextStepDelaySeconds: null == nextStepDelaySeconds
          ? _value.nextStepDelaySeconds
          : nextStepDelaySeconds // ignore: cast_nullable_to_non_nullable
              as int,
      factionTagId: freezed == factionTagId
          ? _value.factionTagId
          : factionTagId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChainQuestDataImplCopyWith<$Res>
    implements $ChainQuestDataCopyWith<$Res> {
  factory _$$ChainQuestDataImplCopyWith(_$ChainQuestDataImpl value,
          $Res Function(_$ChainQuestDataImpl) then) =
      __$$ChainQuestDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'chain_id') String chainId,
      @JsonKey(name: 'chain_name') String chainName,
      int step,
      @JsonKey(name: 'total_steps') int totalSteps,
      @JsonKey(name: 'region_id') int? regionId,
      @JsonKey(name: 'target_region_id') int? targetRegionId,
      String name,
      String description,
      @JsonKey(name: 'quest_type_id') String questTypeId,
      int difficulty,
      @JsonKey(name: 'combat_power') int combatPower,
      @JsonKey(name: 'reward_gold') int rewardGold,
      @JsonKey(name: 'reward_xp') int rewardXp,
      @JsonKey(name: 'reward_items') Map<String, int> rewardItems,
      @JsonKey(name: 'final_reward') bool finalReward,
      @JsonKey(name: 'final_reputation_bonus') int? finalReputationBonus,
      @JsonKey(name: 'duration_seconds') int durationSeconds,
      @JsonKey(name: 'next_step_delay_seconds') int nextStepDelaySeconds,
      @JsonKey(name: 'faction_tag_id') String? factionTagId});
}

/// @nodoc
class __$$ChainQuestDataImplCopyWithImpl<$Res>
    extends _$ChainQuestDataCopyWithImpl<$Res, _$ChainQuestDataImpl>
    implements _$$ChainQuestDataImplCopyWith<$Res> {
  __$$ChainQuestDataImplCopyWithImpl(
      _$ChainQuestDataImpl _value, $Res Function(_$ChainQuestDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chainId = null,
    Object? chainName = null,
    Object? step = null,
    Object? totalSteps = null,
    Object? regionId = freezed,
    Object? targetRegionId = freezed,
    Object? name = null,
    Object? description = null,
    Object? questTypeId = null,
    Object? difficulty = null,
    Object? combatPower = null,
    Object? rewardGold = null,
    Object? rewardXp = null,
    Object? rewardItems = null,
    Object? finalReward = null,
    Object? finalReputationBonus = freezed,
    Object? durationSeconds = null,
    Object? nextStepDelaySeconds = null,
    Object? factionTagId = freezed,
  }) {
    return _then(_$ChainQuestDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      chainName: null == chainName
          ? _value.chainName
          : chainName // ignore: cast_nullable_to_non_nullable
              as String,
      step: null == step
          ? _value.step
          : step // ignore: cast_nullable_to_non_nullable
              as int,
      totalSteps: null == totalSteps
          ? _value.totalSteps
          : totalSteps // ignore: cast_nullable_to_non_nullable
              as int,
      regionId: freezed == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int?,
      targetRegionId: freezed == targetRegionId
          ? _value.targetRegionId
          : targetRegionId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      questTypeId: null == questTypeId
          ? _value.questTypeId
          : questTypeId // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
      combatPower: null == combatPower
          ? _value.combatPower
          : combatPower // ignore: cast_nullable_to_non_nullable
              as int,
      rewardGold: null == rewardGold
          ? _value.rewardGold
          : rewardGold // ignore: cast_nullable_to_non_nullable
              as int,
      rewardXp: null == rewardXp
          ? _value.rewardXp
          : rewardXp // ignore: cast_nullable_to_non_nullable
              as int,
      rewardItems: null == rewardItems
          ? _value._rewardItems
          : rewardItems // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      finalReward: null == finalReward
          ? _value.finalReward
          : finalReward // ignore: cast_nullable_to_non_nullable
              as bool,
      finalReputationBonus: freezed == finalReputationBonus
          ? _value.finalReputationBonus
          : finalReputationBonus // ignore: cast_nullable_to_non_nullable
              as int?,
      durationSeconds: null == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      nextStepDelaySeconds: null == nextStepDelaySeconds
          ? _value.nextStepDelaySeconds
          : nextStepDelaySeconds // ignore: cast_nullable_to_non_nullable
              as int,
      factionTagId: freezed == factionTagId
          ? _value.factionTagId
          : factionTagId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChainQuestDataImpl implements _ChainQuestData {
  const _$ChainQuestDataImpl(
      {required this.id,
      @JsonKey(name: 'chain_id') required this.chainId,
      @JsonKey(name: 'chain_name') required this.chainName,
      required this.step,
      @JsonKey(name: 'total_steps') required this.totalSteps,
      @JsonKey(name: 'region_id') this.regionId,
      @JsonKey(name: 'target_region_id') this.targetRegionId,
      required this.name,
      required this.description,
      @JsonKey(name: 'quest_type_id') required this.questTypeId,
      required this.difficulty,
      @JsonKey(name: 'combat_power') required this.combatPower,
      @JsonKey(name: 'reward_gold') required this.rewardGold,
      @JsonKey(name: 'reward_xp') this.rewardXp = 0,
      @JsonKey(name: 'reward_items')
      final Map<String, int> rewardItems = const {},
      @JsonKey(name: 'final_reward') this.finalReward = false,
      @JsonKey(name: 'final_reputation_bonus') this.finalReputationBonus,
      @JsonKey(name: 'duration_seconds') required this.durationSeconds,
      @JsonKey(name: 'next_step_delay_seconds') this.nextStepDelaySeconds = 0,
      @JsonKey(name: 'faction_tag_id') this.factionTagId})
      : _rewardItems = rewardItems;

  factory _$ChainQuestDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChainQuestDataImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'chain_id')
  final String chainId;
  @override
  @JsonKey(name: 'chain_name')
  final String chainName;
  @override
  final int step;
  @override
  @JsonKey(name: 'total_steps')
  final int totalSteps;
  @override
  @JsonKey(name: 'region_id')
  final int? regionId;
  @override
  @JsonKey(name: 'target_region_id')
  final int? targetRegionId;
  @override
  final String name;
  @override
  final String description;
  @override
  @JsonKey(name: 'quest_type_id')
  final String questTypeId;
  @override
  final int difficulty;
  @override
  @JsonKey(name: 'combat_power')
  final int combatPower;
  @override
  @JsonKey(name: 'reward_gold')
  final int rewardGold;
  @override
  @JsonKey(name: 'reward_xp')
  final int rewardXp;
  final Map<String, int> _rewardItems;
  @override
  @JsonKey(name: 'reward_items')
  Map<String, int> get rewardItems {
    if (_rewardItems is EqualUnmodifiableMapView) return _rewardItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_rewardItems);
  }

  @override
  @JsonKey(name: 'final_reward')
  final bool finalReward;
  @override
  @JsonKey(name: 'final_reputation_bonus')
  final int? finalReputationBonus;
  @override
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @override
  @JsonKey(name: 'next_step_delay_seconds')
  final int nextStepDelaySeconds;
  @override
  @JsonKey(name: 'faction_tag_id')
  final String? factionTagId;

  @override
  String toString() {
    return 'ChainQuestData(id: $id, chainId: $chainId, chainName: $chainName, step: $step, totalSteps: $totalSteps, regionId: $regionId, targetRegionId: $targetRegionId, name: $name, description: $description, questTypeId: $questTypeId, difficulty: $difficulty, combatPower: $combatPower, rewardGold: $rewardGold, rewardXp: $rewardXp, rewardItems: $rewardItems, finalReward: $finalReward, finalReputationBonus: $finalReputationBonus, durationSeconds: $durationSeconds, nextStepDelaySeconds: $nextStepDelaySeconds, factionTagId: $factionTagId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChainQuestDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chainId, chainId) || other.chainId == chainId) &&
            (identical(other.chainName, chainName) ||
                other.chainName == chainName) &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.targetRegionId, targetRegionId) ||
                other.targetRegionId == targetRegionId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.questTypeId, questTypeId) ||
                other.questTypeId == questTypeId) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.combatPower, combatPower) ||
                other.combatPower == combatPower) &&
            (identical(other.rewardGold, rewardGold) ||
                other.rewardGold == rewardGold) &&
            (identical(other.rewardXp, rewardXp) ||
                other.rewardXp == rewardXp) &&
            const DeepCollectionEquality()
                .equals(other._rewardItems, _rewardItems) &&
            (identical(other.finalReward, finalReward) ||
                other.finalReward == finalReward) &&
            (identical(other.finalReputationBonus, finalReputationBonus) ||
                other.finalReputationBonus == finalReputationBonus) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.nextStepDelaySeconds, nextStepDelaySeconds) ||
                other.nextStepDelaySeconds == nextStepDelaySeconds) &&
            (identical(other.factionTagId, factionTagId) ||
                other.factionTagId == factionTagId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        chainId,
        chainName,
        step,
        totalSteps,
        regionId,
        targetRegionId,
        name,
        description,
        questTypeId,
        difficulty,
        combatPower,
        rewardGold,
        rewardXp,
        const DeepCollectionEquality().hash(_rewardItems),
        finalReward,
        finalReputationBonus,
        durationSeconds,
        nextStepDelaySeconds,
        factionTagId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChainQuestDataImplCopyWith<_$ChainQuestDataImpl> get copyWith =>
      __$$ChainQuestDataImplCopyWithImpl<_$ChainQuestDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChainQuestDataImplToJson(
      this,
    );
  }
}

abstract class _ChainQuestData implements ChainQuestData {
  const factory _ChainQuestData(
      {required final String id,
      @JsonKey(name: 'chain_id') required final String chainId,
      @JsonKey(name: 'chain_name') required final String chainName,
      required final int step,
      @JsonKey(name: 'total_steps') required final int totalSteps,
      @JsonKey(name: 'region_id') final int? regionId,
      @JsonKey(name: 'target_region_id') final int? targetRegionId,
      required final String name,
      required final String description,
      @JsonKey(name: 'quest_type_id') required final String questTypeId,
      required final int difficulty,
      @JsonKey(name: 'combat_power') required final int combatPower,
      @JsonKey(name: 'reward_gold') required final int rewardGold,
      @JsonKey(name: 'reward_xp') final int rewardXp,
      @JsonKey(name: 'reward_items') final Map<String, int> rewardItems,
      @JsonKey(name: 'final_reward') final bool finalReward,
      @JsonKey(name: 'final_reputation_bonus') final int? finalReputationBonus,
      @JsonKey(name: 'duration_seconds') required final int durationSeconds,
      @JsonKey(name: 'next_step_delay_seconds') final int nextStepDelaySeconds,
      @JsonKey(name: 'faction_tag_id')
      final String? factionTagId}) = _$ChainQuestDataImpl;

  factory _ChainQuestData.fromJson(Map<String, dynamic> json) =
      _$ChainQuestDataImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'chain_id')
  String get chainId;
  @override
  @JsonKey(name: 'chain_name')
  String get chainName;
  @override
  int get step;
  @override
  @JsonKey(name: 'total_steps')
  int get totalSteps;
  @override
  @JsonKey(name: 'region_id')
  int? get regionId;
  @override
  @JsonKey(name: 'target_region_id')
  int? get targetRegionId;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'quest_type_id')
  String get questTypeId;
  @override
  int get difficulty;
  @override
  @JsonKey(name: 'combat_power')
  int get combatPower;
  @override
  @JsonKey(name: 'reward_gold')
  int get rewardGold;
  @override
  @JsonKey(name: 'reward_xp')
  int get rewardXp;
  @override
  @JsonKey(name: 'reward_items')
  Map<String, int> get rewardItems;
  @override
  @JsonKey(name: 'final_reward')
  bool get finalReward;
  @override
  @JsonKey(name: 'final_reputation_bonus')
  int? get finalReputationBonus;
  @override
  @JsonKey(name: 'duration_seconds')
  int get durationSeconds;
  @override
  @JsonKey(name: 'next_step_delay_seconds')
  int get nextStepDelaySeconds;
  @override
  @JsonKey(name: 'faction_tag_id')
  String? get factionTagId;
  @override
  @JsonKey(ignore: true)
  _$$ChainQuestDataImplCopyWith<_$ChainQuestDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
