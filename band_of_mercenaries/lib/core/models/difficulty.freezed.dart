// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'difficulty.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Difficulty _$DifficultyFromJson(Map<String, dynamic> json) {
  return _Difficulty.fromJson(json);
}

/// @nodoc
mixin _$Difficulty {
  int get level => throw _privateConstructorUsedError;
  @JsonKey(name: 'enemy_power')
  int get enemyPower => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_multiplier')
  double get rewardMultiplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'success_penalty')
  double get successPenalty => throw _privateConstructorUsedError;
  @JsonKey(name: 'injury_rate')
  double get injuryRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'death_rate')
  double get deathRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_dispatch_cost')
  int get minDispatchCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_dispatch_cost')
  int get maxDispatchCost => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DifficultyCopyWith<Difficulty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DifficultyCopyWith<$Res> {
  factory $DifficultyCopyWith(
          Difficulty value, $Res Function(Difficulty) then) =
      _$DifficultyCopyWithImpl<$Res, Difficulty>;
  @useResult
  $Res call(
      {int level,
      @JsonKey(name: 'enemy_power') int enemyPower,
      @JsonKey(name: 'reward_multiplier') double rewardMultiplier,
      @JsonKey(name: 'success_penalty') double successPenalty,
      @JsonKey(name: 'injury_rate') double injuryRate,
      @JsonKey(name: 'death_rate') double deathRate,
      @JsonKey(name: 'min_dispatch_cost') int minDispatchCost,
      @JsonKey(name: 'max_dispatch_cost') int maxDispatchCost});
}

/// @nodoc
class _$DifficultyCopyWithImpl<$Res, $Val extends Difficulty>
    implements $DifficultyCopyWith<$Res> {
  _$DifficultyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? enemyPower = null,
    Object? rewardMultiplier = null,
    Object? successPenalty = null,
    Object? injuryRate = null,
    Object? deathRate = null,
    Object? minDispatchCost = null,
    Object? maxDispatchCost = null,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      enemyPower: null == enemyPower
          ? _value.enemyPower
          : enemyPower // ignore: cast_nullable_to_non_nullable
              as int,
      rewardMultiplier: null == rewardMultiplier
          ? _value.rewardMultiplier
          : rewardMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      successPenalty: null == successPenalty
          ? _value.successPenalty
          : successPenalty // ignore: cast_nullable_to_non_nullable
              as double,
      injuryRate: null == injuryRate
          ? _value.injuryRate
          : injuryRate // ignore: cast_nullable_to_non_nullable
              as double,
      deathRate: null == deathRate
          ? _value.deathRate
          : deathRate // ignore: cast_nullable_to_non_nullable
              as double,
      minDispatchCost: null == minDispatchCost
          ? _value.minDispatchCost
          : minDispatchCost // ignore: cast_nullable_to_non_nullable
              as int,
      maxDispatchCost: null == maxDispatchCost
          ? _value.maxDispatchCost
          : maxDispatchCost // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DifficultyImplCopyWith<$Res>
    implements $DifficultyCopyWith<$Res> {
  factory _$$DifficultyImplCopyWith(
          _$DifficultyImpl value, $Res Function(_$DifficultyImpl) then) =
      __$$DifficultyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int level,
      @JsonKey(name: 'enemy_power') int enemyPower,
      @JsonKey(name: 'reward_multiplier') double rewardMultiplier,
      @JsonKey(name: 'success_penalty') double successPenalty,
      @JsonKey(name: 'injury_rate') double injuryRate,
      @JsonKey(name: 'death_rate') double deathRate,
      @JsonKey(name: 'min_dispatch_cost') int minDispatchCost,
      @JsonKey(name: 'max_dispatch_cost') int maxDispatchCost});
}

/// @nodoc
class __$$DifficultyImplCopyWithImpl<$Res>
    extends _$DifficultyCopyWithImpl<$Res, _$DifficultyImpl>
    implements _$$DifficultyImplCopyWith<$Res> {
  __$$DifficultyImplCopyWithImpl(
      _$DifficultyImpl _value, $Res Function(_$DifficultyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? enemyPower = null,
    Object? rewardMultiplier = null,
    Object? successPenalty = null,
    Object? injuryRate = null,
    Object? deathRate = null,
    Object? minDispatchCost = null,
    Object? maxDispatchCost = null,
  }) {
    return _then(_$DifficultyImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      enemyPower: null == enemyPower
          ? _value.enemyPower
          : enemyPower // ignore: cast_nullable_to_non_nullable
              as int,
      rewardMultiplier: null == rewardMultiplier
          ? _value.rewardMultiplier
          : rewardMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      successPenalty: null == successPenalty
          ? _value.successPenalty
          : successPenalty // ignore: cast_nullable_to_non_nullable
              as double,
      injuryRate: null == injuryRate
          ? _value.injuryRate
          : injuryRate // ignore: cast_nullable_to_non_nullable
              as double,
      deathRate: null == deathRate
          ? _value.deathRate
          : deathRate // ignore: cast_nullable_to_non_nullable
              as double,
      minDispatchCost: null == minDispatchCost
          ? _value.minDispatchCost
          : minDispatchCost // ignore: cast_nullable_to_non_nullable
              as int,
      maxDispatchCost: null == maxDispatchCost
          ? _value.maxDispatchCost
          : maxDispatchCost // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DifficultyImpl implements _Difficulty {
  const _$DifficultyImpl(
      {required this.level,
      @JsonKey(name: 'enemy_power') required this.enemyPower,
      @JsonKey(name: 'reward_multiplier') required this.rewardMultiplier,
      @JsonKey(name: 'success_penalty') required this.successPenalty,
      @JsonKey(name: 'injury_rate') required this.injuryRate,
      @JsonKey(name: 'death_rate') required this.deathRate,
      @JsonKey(name: 'min_dispatch_cost') required this.minDispatchCost,
      @JsonKey(name: 'max_dispatch_cost') required this.maxDispatchCost});

  factory _$DifficultyImpl.fromJson(Map<String, dynamic> json) =>
      _$$DifficultyImplFromJson(json);

  @override
  final int level;
  @override
  @JsonKey(name: 'enemy_power')
  final int enemyPower;
  @override
  @JsonKey(name: 'reward_multiplier')
  final double rewardMultiplier;
  @override
  @JsonKey(name: 'success_penalty')
  final double successPenalty;
  @override
  @JsonKey(name: 'injury_rate')
  final double injuryRate;
  @override
  @JsonKey(name: 'death_rate')
  final double deathRate;
  @override
  @JsonKey(name: 'min_dispatch_cost')
  final int minDispatchCost;
  @override
  @JsonKey(name: 'max_dispatch_cost')
  final int maxDispatchCost;

  @override
  String toString() {
    return 'Difficulty(level: $level, enemyPower: $enemyPower, rewardMultiplier: $rewardMultiplier, successPenalty: $successPenalty, injuryRate: $injuryRate, deathRate: $deathRate, minDispatchCost: $minDispatchCost, maxDispatchCost: $maxDispatchCost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DifficultyImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.enemyPower, enemyPower) ||
                other.enemyPower == enemyPower) &&
            (identical(other.rewardMultiplier, rewardMultiplier) ||
                other.rewardMultiplier == rewardMultiplier) &&
            (identical(other.successPenalty, successPenalty) ||
                other.successPenalty == successPenalty) &&
            (identical(other.injuryRate, injuryRate) ||
                other.injuryRate == injuryRate) &&
            (identical(other.deathRate, deathRate) ||
                other.deathRate == deathRate) &&
            (identical(other.minDispatchCost, minDispatchCost) ||
                other.minDispatchCost == minDispatchCost) &&
            (identical(other.maxDispatchCost, maxDispatchCost) ||
                other.maxDispatchCost == maxDispatchCost));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      level,
      enemyPower,
      rewardMultiplier,
      successPenalty,
      injuryRate,
      deathRate,
      minDispatchCost,
      maxDispatchCost);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DifficultyImplCopyWith<_$DifficultyImpl> get copyWith =>
      __$$DifficultyImplCopyWithImpl<_$DifficultyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DifficultyImplToJson(
      this,
    );
  }
}

abstract class _Difficulty implements Difficulty {
  const factory _Difficulty(
      {required final int level,
      @JsonKey(name: 'enemy_power') required final int enemyPower,
      @JsonKey(name: 'reward_multiplier')
      required final double rewardMultiplier,
      @JsonKey(name: 'success_penalty') required final double successPenalty,
      @JsonKey(name: 'injury_rate') required final double injuryRate,
      @JsonKey(name: 'death_rate') required final double deathRate,
      @JsonKey(name: 'min_dispatch_cost') required final int minDispatchCost,
      @JsonKey(name: 'max_dispatch_cost')
      required final int maxDispatchCost}) = _$DifficultyImpl;

  factory _Difficulty.fromJson(Map<String, dynamic> json) =
      _$DifficultyImpl.fromJson;

  @override
  int get level;
  @override
  @JsonKey(name: 'enemy_power')
  int get enemyPower;
  @override
  @JsonKey(name: 'reward_multiplier')
  double get rewardMultiplier;
  @override
  @JsonKey(name: 'success_penalty')
  double get successPenalty;
  @override
  @JsonKey(name: 'injury_rate')
  double get injuryRate;
  @override
  @JsonKey(name: 'death_rate')
  double get deathRate;
  @override
  @JsonKey(name: 'min_dispatch_cost')
  int get minDispatchCost;
  @override
  @JsonKey(name: 'max_dispatch_cost')
  int get maxDispatchCost;
  @override
  @JsonKey(ignore: true)
  _$$DifficultyImplCopyWith<_$DifficultyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
