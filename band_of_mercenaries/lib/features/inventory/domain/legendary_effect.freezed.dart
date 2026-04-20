// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legendary_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LegendaryEffect {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String questType, double value) successRateBonus,
    required TResult Function(double chance) resultUpgrade,
    required TResult Function(double injuryMod, double deathMod)
        damageResistance,
    required TResult Function(double multiplier) rewardBonus,
    required TResult Function(int deathPreventionCount, int cooldownHours)
        special,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String questType, double value)? successRateBonus,
    TResult? Function(double chance)? resultUpgrade,
    TResult? Function(double injuryMod, double deathMod)? damageResistance,
    TResult? Function(double multiplier)? rewardBonus,
    TResult? Function(int deathPreventionCount, int cooldownHours)? special,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String questType, double value)? successRateBonus,
    TResult Function(double chance)? resultUpgrade,
    TResult Function(double injuryMod, double deathMod)? damageResistance,
    TResult Function(double multiplier)? rewardBonus,
    TResult Function(int deathPreventionCount, int cooldownHours)? special,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LegendarySuccessRateBonus value) successRateBonus,
    required TResult Function(LegendaryResultUpgrade value) resultUpgrade,
    required TResult Function(LegendaryDamageResistance value) damageResistance,
    required TResult Function(LegendaryRewardBonus value) rewardBonus,
    required TResult Function(LegendarySpecial value) special,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult? Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult? Function(LegendaryDamageResistance value)? damageResistance,
    TResult? Function(LegendaryRewardBonus value)? rewardBonus,
    TResult? Function(LegendarySpecial value)? special,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult Function(LegendaryDamageResistance value)? damageResistance,
    TResult Function(LegendaryRewardBonus value)? rewardBonus,
    TResult Function(LegendarySpecial value)? special,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LegendaryEffectCopyWith<$Res> {
  factory $LegendaryEffectCopyWith(
          LegendaryEffect value, $Res Function(LegendaryEffect) then) =
      _$LegendaryEffectCopyWithImpl<$Res, LegendaryEffect>;
}

/// @nodoc
class _$LegendaryEffectCopyWithImpl<$Res, $Val extends LegendaryEffect>
    implements $LegendaryEffectCopyWith<$Res> {
  _$LegendaryEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LegendarySuccessRateBonusImplCopyWith<$Res> {
  factory _$$LegendarySuccessRateBonusImplCopyWith(
          _$LegendarySuccessRateBonusImpl value,
          $Res Function(_$LegendarySuccessRateBonusImpl) then) =
      __$$LegendarySuccessRateBonusImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String questType, double value});
}

/// @nodoc
class __$$LegendarySuccessRateBonusImplCopyWithImpl<$Res>
    extends _$LegendaryEffectCopyWithImpl<$Res, _$LegendarySuccessRateBonusImpl>
    implements _$$LegendarySuccessRateBonusImplCopyWith<$Res> {
  __$$LegendarySuccessRateBonusImplCopyWithImpl(
      _$LegendarySuccessRateBonusImpl _value,
      $Res Function(_$LegendarySuccessRateBonusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questType = null,
    Object? value = null,
  }) {
    return _then(_$LegendarySuccessRateBonusImpl(
      questType: null == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$LegendarySuccessRateBonusImpl implements LegendarySuccessRateBonus {
  const _$LegendarySuccessRateBonusImpl(
      {required this.questType, required this.value});

  @override
  final String questType;
  @override
  final double value;

  @override
  String toString() {
    return 'LegendaryEffect.successRateBonus(questType: $questType, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegendarySuccessRateBonusImpl &&
            (identical(other.questType, questType) ||
                other.questType == questType) &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, questType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LegendarySuccessRateBonusImplCopyWith<_$LegendarySuccessRateBonusImpl>
      get copyWith => __$$LegendarySuccessRateBonusImplCopyWithImpl<
          _$LegendarySuccessRateBonusImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String questType, double value) successRateBonus,
    required TResult Function(double chance) resultUpgrade,
    required TResult Function(double injuryMod, double deathMod)
        damageResistance,
    required TResult Function(double multiplier) rewardBonus,
    required TResult Function(int deathPreventionCount, int cooldownHours)
        special,
  }) {
    return successRateBonus(questType, value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String questType, double value)? successRateBonus,
    TResult? Function(double chance)? resultUpgrade,
    TResult? Function(double injuryMod, double deathMod)? damageResistance,
    TResult? Function(double multiplier)? rewardBonus,
    TResult? Function(int deathPreventionCount, int cooldownHours)? special,
  }) {
    return successRateBonus?.call(questType, value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String questType, double value)? successRateBonus,
    TResult Function(double chance)? resultUpgrade,
    TResult Function(double injuryMod, double deathMod)? damageResistance,
    TResult Function(double multiplier)? rewardBonus,
    TResult Function(int deathPreventionCount, int cooldownHours)? special,
    required TResult orElse(),
  }) {
    if (successRateBonus != null) {
      return successRateBonus(questType, value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LegendarySuccessRateBonus value) successRateBonus,
    required TResult Function(LegendaryResultUpgrade value) resultUpgrade,
    required TResult Function(LegendaryDamageResistance value) damageResistance,
    required TResult Function(LegendaryRewardBonus value) rewardBonus,
    required TResult Function(LegendarySpecial value) special,
  }) {
    return successRateBonus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult? Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult? Function(LegendaryDamageResistance value)? damageResistance,
    TResult? Function(LegendaryRewardBonus value)? rewardBonus,
    TResult? Function(LegendarySpecial value)? special,
  }) {
    return successRateBonus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult Function(LegendaryDamageResistance value)? damageResistance,
    TResult Function(LegendaryRewardBonus value)? rewardBonus,
    TResult Function(LegendarySpecial value)? special,
    required TResult orElse(),
  }) {
    if (successRateBonus != null) {
      return successRateBonus(this);
    }
    return orElse();
  }
}

abstract class LegendarySuccessRateBonus implements LegendaryEffect {
  const factory LegendarySuccessRateBonus(
      {required final String questType,
      required final double value}) = _$LegendarySuccessRateBonusImpl;

  String get questType;
  double get value;
  @JsonKey(ignore: true)
  _$$LegendarySuccessRateBonusImplCopyWith<_$LegendarySuccessRateBonusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LegendaryResultUpgradeImplCopyWith<$Res> {
  factory _$$LegendaryResultUpgradeImplCopyWith(
          _$LegendaryResultUpgradeImpl value,
          $Res Function(_$LegendaryResultUpgradeImpl) then) =
      __$$LegendaryResultUpgradeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double chance});
}

/// @nodoc
class __$$LegendaryResultUpgradeImplCopyWithImpl<$Res>
    extends _$LegendaryEffectCopyWithImpl<$Res, _$LegendaryResultUpgradeImpl>
    implements _$$LegendaryResultUpgradeImplCopyWith<$Res> {
  __$$LegendaryResultUpgradeImplCopyWithImpl(
      _$LegendaryResultUpgradeImpl _value,
      $Res Function(_$LegendaryResultUpgradeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chance = null,
  }) {
    return _then(_$LegendaryResultUpgradeImpl(
      chance: null == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$LegendaryResultUpgradeImpl implements LegendaryResultUpgrade {
  const _$LegendaryResultUpgradeImpl({required this.chance});

  @override
  final double chance;

  @override
  String toString() {
    return 'LegendaryEffect.resultUpgrade(chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegendaryResultUpgradeImpl &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chance);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LegendaryResultUpgradeImplCopyWith<_$LegendaryResultUpgradeImpl>
      get copyWith => __$$LegendaryResultUpgradeImplCopyWithImpl<
          _$LegendaryResultUpgradeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String questType, double value) successRateBonus,
    required TResult Function(double chance) resultUpgrade,
    required TResult Function(double injuryMod, double deathMod)
        damageResistance,
    required TResult Function(double multiplier) rewardBonus,
    required TResult Function(int deathPreventionCount, int cooldownHours)
        special,
  }) {
    return resultUpgrade(chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String questType, double value)? successRateBonus,
    TResult? Function(double chance)? resultUpgrade,
    TResult? Function(double injuryMod, double deathMod)? damageResistance,
    TResult? Function(double multiplier)? rewardBonus,
    TResult? Function(int deathPreventionCount, int cooldownHours)? special,
  }) {
    return resultUpgrade?.call(chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String questType, double value)? successRateBonus,
    TResult Function(double chance)? resultUpgrade,
    TResult Function(double injuryMod, double deathMod)? damageResistance,
    TResult Function(double multiplier)? rewardBonus,
    TResult Function(int deathPreventionCount, int cooldownHours)? special,
    required TResult orElse(),
  }) {
    if (resultUpgrade != null) {
      return resultUpgrade(chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LegendarySuccessRateBonus value) successRateBonus,
    required TResult Function(LegendaryResultUpgrade value) resultUpgrade,
    required TResult Function(LegendaryDamageResistance value) damageResistance,
    required TResult Function(LegendaryRewardBonus value) rewardBonus,
    required TResult Function(LegendarySpecial value) special,
  }) {
    return resultUpgrade(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult? Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult? Function(LegendaryDamageResistance value)? damageResistance,
    TResult? Function(LegendaryRewardBonus value)? rewardBonus,
    TResult? Function(LegendarySpecial value)? special,
  }) {
    return resultUpgrade?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult Function(LegendaryDamageResistance value)? damageResistance,
    TResult Function(LegendaryRewardBonus value)? rewardBonus,
    TResult Function(LegendarySpecial value)? special,
    required TResult orElse(),
  }) {
    if (resultUpgrade != null) {
      return resultUpgrade(this);
    }
    return orElse();
  }
}

abstract class LegendaryResultUpgrade implements LegendaryEffect {
  const factory LegendaryResultUpgrade({required final double chance}) =
      _$LegendaryResultUpgradeImpl;

  double get chance;
  @JsonKey(ignore: true)
  _$$LegendaryResultUpgradeImplCopyWith<_$LegendaryResultUpgradeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LegendaryDamageResistanceImplCopyWith<$Res> {
  factory _$$LegendaryDamageResistanceImplCopyWith(
          _$LegendaryDamageResistanceImpl value,
          $Res Function(_$LegendaryDamageResistanceImpl) then) =
      __$$LegendaryDamageResistanceImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double injuryMod, double deathMod});
}

/// @nodoc
class __$$LegendaryDamageResistanceImplCopyWithImpl<$Res>
    extends _$LegendaryEffectCopyWithImpl<$Res, _$LegendaryDamageResistanceImpl>
    implements _$$LegendaryDamageResistanceImplCopyWith<$Res> {
  __$$LegendaryDamageResistanceImplCopyWithImpl(
      _$LegendaryDamageResistanceImpl _value,
      $Res Function(_$LegendaryDamageResistanceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? injuryMod = null,
    Object? deathMod = null,
  }) {
    return _then(_$LegendaryDamageResistanceImpl(
      injuryMod: null == injuryMod
          ? _value.injuryMod
          : injuryMod // ignore: cast_nullable_to_non_nullable
              as double,
      deathMod: null == deathMod
          ? _value.deathMod
          : deathMod // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$LegendaryDamageResistanceImpl implements LegendaryDamageResistance {
  const _$LegendaryDamageResistanceImpl(
      {required this.injuryMod, required this.deathMod});

  @override
  final double injuryMod;
  @override
  final double deathMod;

  @override
  String toString() {
    return 'LegendaryEffect.damageResistance(injuryMod: $injuryMod, deathMod: $deathMod)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegendaryDamageResistanceImpl &&
            (identical(other.injuryMod, injuryMod) ||
                other.injuryMod == injuryMod) &&
            (identical(other.deathMod, deathMod) ||
                other.deathMod == deathMod));
  }

  @override
  int get hashCode => Object.hash(runtimeType, injuryMod, deathMod);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LegendaryDamageResistanceImplCopyWith<_$LegendaryDamageResistanceImpl>
      get copyWith => __$$LegendaryDamageResistanceImplCopyWithImpl<
          _$LegendaryDamageResistanceImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String questType, double value) successRateBonus,
    required TResult Function(double chance) resultUpgrade,
    required TResult Function(double injuryMod, double deathMod)
        damageResistance,
    required TResult Function(double multiplier) rewardBonus,
    required TResult Function(int deathPreventionCount, int cooldownHours)
        special,
  }) {
    return damageResistance(injuryMod, deathMod);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String questType, double value)? successRateBonus,
    TResult? Function(double chance)? resultUpgrade,
    TResult? Function(double injuryMod, double deathMod)? damageResistance,
    TResult? Function(double multiplier)? rewardBonus,
    TResult? Function(int deathPreventionCount, int cooldownHours)? special,
  }) {
    return damageResistance?.call(injuryMod, deathMod);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String questType, double value)? successRateBonus,
    TResult Function(double chance)? resultUpgrade,
    TResult Function(double injuryMod, double deathMod)? damageResistance,
    TResult Function(double multiplier)? rewardBonus,
    TResult Function(int deathPreventionCount, int cooldownHours)? special,
    required TResult orElse(),
  }) {
    if (damageResistance != null) {
      return damageResistance(injuryMod, deathMod);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LegendarySuccessRateBonus value) successRateBonus,
    required TResult Function(LegendaryResultUpgrade value) resultUpgrade,
    required TResult Function(LegendaryDamageResistance value) damageResistance,
    required TResult Function(LegendaryRewardBonus value) rewardBonus,
    required TResult Function(LegendarySpecial value) special,
  }) {
    return damageResistance(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult? Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult? Function(LegendaryDamageResistance value)? damageResistance,
    TResult? Function(LegendaryRewardBonus value)? rewardBonus,
    TResult? Function(LegendarySpecial value)? special,
  }) {
    return damageResistance?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult Function(LegendaryDamageResistance value)? damageResistance,
    TResult Function(LegendaryRewardBonus value)? rewardBonus,
    TResult Function(LegendarySpecial value)? special,
    required TResult orElse(),
  }) {
    if (damageResistance != null) {
      return damageResistance(this);
    }
    return orElse();
  }
}

abstract class LegendaryDamageResistance implements LegendaryEffect {
  const factory LegendaryDamageResistance(
      {required final double injuryMod,
      required final double deathMod}) = _$LegendaryDamageResistanceImpl;

  double get injuryMod;
  double get deathMod;
  @JsonKey(ignore: true)
  _$$LegendaryDamageResistanceImplCopyWith<_$LegendaryDamageResistanceImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LegendaryRewardBonusImplCopyWith<$Res> {
  factory _$$LegendaryRewardBonusImplCopyWith(_$LegendaryRewardBonusImpl value,
          $Res Function(_$LegendaryRewardBonusImpl) then) =
      __$$LegendaryRewardBonusImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double multiplier});
}

/// @nodoc
class __$$LegendaryRewardBonusImplCopyWithImpl<$Res>
    extends _$LegendaryEffectCopyWithImpl<$Res, _$LegendaryRewardBonusImpl>
    implements _$$LegendaryRewardBonusImplCopyWith<$Res> {
  __$$LegendaryRewardBonusImplCopyWithImpl(_$LegendaryRewardBonusImpl _value,
      $Res Function(_$LegendaryRewardBonusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? multiplier = null,
  }) {
    return _then(_$LegendaryRewardBonusImpl(
      multiplier: null == multiplier
          ? _value.multiplier
          : multiplier // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$LegendaryRewardBonusImpl implements LegendaryRewardBonus {
  const _$LegendaryRewardBonusImpl({required this.multiplier});

  @override
  final double multiplier;

  @override
  String toString() {
    return 'LegendaryEffect.rewardBonus(multiplier: $multiplier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegendaryRewardBonusImpl &&
            (identical(other.multiplier, multiplier) ||
                other.multiplier == multiplier));
  }

  @override
  int get hashCode => Object.hash(runtimeType, multiplier);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LegendaryRewardBonusImplCopyWith<_$LegendaryRewardBonusImpl>
      get copyWith =>
          __$$LegendaryRewardBonusImplCopyWithImpl<_$LegendaryRewardBonusImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String questType, double value) successRateBonus,
    required TResult Function(double chance) resultUpgrade,
    required TResult Function(double injuryMod, double deathMod)
        damageResistance,
    required TResult Function(double multiplier) rewardBonus,
    required TResult Function(int deathPreventionCount, int cooldownHours)
        special,
  }) {
    return rewardBonus(multiplier);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String questType, double value)? successRateBonus,
    TResult? Function(double chance)? resultUpgrade,
    TResult? Function(double injuryMod, double deathMod)? damageResistance,
    TResult? Function(double multiplier)? rewardBonus,
    TResult? Function(int deathPreventionCount, int cooldownHours)? special,
  }) {
    return rewardBonus?.call(multiplier);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String questType, double value)? successRateBonus,
    TResult Function(double chance)? resultUpgrade,
    TResult Function(double injuryMod, double deathMod)? damageResistance,
    TResult Function(double multiplier)? rewardBonus,
    TResult Function(int deathPreventionCount, int cooldownHours)? special,
    required TResult orElse(),
  }) {
    if (rewardBonus != null) {
      return rewardBonus(multiplier);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LegendarySuccessRateBonus value) successRateBonus,
    required TResult Function(LegendaryResultUpgrade value) resultUpgrade,
    required TResult Function(LegendaryDamageResistance value) damageResistance,
    required TResult Function(LegendaryRewardBonus value) rewardBonus,
    required TResult Function(LegendarySpecial value) special,
  }) {
    return rewardBonus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult? Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult? Function(LegendaryDamageResistance value)? damageResistance,
    TResult? Function(LegendaryRewardBonus value)? rewardBonus,
    TResult? Function(LegendarySpecial value)? special,
  }) {
    return rewardBonus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult Function(LegendaryDamageResistance value)? damageResistance,
    TResult Function(LegendaryRewardBonus value)? rewardBonus,
    TResult Function(LegendarySpecial value)? special,
    required TResult orElse(),
  }) {
    if (rewardBonus != null) {
      return rewardBonus(this);
    }
    return orElse();
  }
}

abstract class LegendaryRewardBonus implements LegendaryEffect {
  const factory LegendaryRewardBonus({required final double multiplier}) =
      _$LegendaryRewardBonusImpl;

  double get multiplier;
  @JsonKey(ignore: true)
  _$$LegendaryRewardBonusImplCopyWith<_$LegendaryRewardBonusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LegendarySpecialImplCopyWith<$Res> {
  factory _$$LegendarySpecialImplCopyWith(_$LegendarySpecialImpl value,
          $Res Function(_$LegendarySpecialImpl) then) =
      __$$LegendarySpecialImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int deathPreventionCount, int cooldownHours});
}

/// @nodoc
class __$$LegendarySpecialImplCopyWithImpl<$Res>
    extends _$LegendaryEffectCopyWithImpl<$Res, _$LegendarySpecialImpl>
    implements _$$LegendarySpecialImplCopyWith<$Res> {
  __$$LegendarySpecialImplCopyWithImpl(_$LegendarySpecialImpl _value,
      $Res Function(_$LegendarySpecialImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deathPreventionCount = null,
    Object? cooldownHours = null,
  }) {
    return _then(_$LegendarySpecialImpl(
      deathPreventionCount: null == deathPreventionCount
          ? _value.deathPreventionCount
          : deathPreventionCount // ignore: cast_nullable_to_non_nullable
              as int,
      cooldownHours: null == cooldownHours
          ? _value.cooldownHours
          : cooldownHours // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$LegendarySpecialImpl implements LegendarySpecial {
  const _$LegendarySpecialImpl(
      {required this.deathPreventionCount, required this.cooldownHours});

  @override
  final int deathPreventionCount;
  @override
  final int cooldownHours;

  @override
  String toString() {
    return 'LegendaryEffect.special(deathPreventionCount: $deathPreventionCount, cooldownHours: $cooldownHours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegendarySpecialImpl &&
            (identical(other.deathPreventionCount, deathPreventionCount) ||
                other.deathPreventionCount == deathPreventionCount) &&
            (identical(other.cooldownHours, cooldownHours) ||
                other.cooldownHours == cooldownHours));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, deathPreventionCount, cooldownHours);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LegendarySpecialImplCopyWith<_$LegendarySpecialImpl> get copyWith =>
      __$$LegendarySpecialImplCopyWithImpl<_$LegendarySpecialImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String questType, double value) successRateBonus,
    required TResult Function(double chance) resultUpgrade,
    required TResult Function(double injuryMod, double deathMod)
        damageResistance,
    required TResult Function(double multiplier) rewardBonus,
    required TResult Function(int deathPreventionCount, int cooldownHours)
        special,
  }) {
    return special(deathPreventionCount, cooldownHours);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String questType, double value)? successRateBonus,
    TResult? Function(double chance)? resultUpgrade,
    TResult? Function(double injuryMod, double deathMod)? damageResistance,
    TResult? Function(double multiplier)? rewardBonus,
    TResult? Function(int deathPreventionCount, int cooldownHours)? special,
  }) {
    return special?.call(deathPreventionCount, cooldownHours);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String questType, double value)? successRateBonus,
    TResult Function(double chance)? resultUpgrade,
    TResult Function(double injuryMod, double deathMod)? damageResistance,
    TResult Function(double multiplier)? rewardBonus,
    TResult Function(int deathPreventionCount, int cooldownHours)? special,
    required TResult orElse(),
  }) {
    if (special != null) {
      return special(deathPreventionCount, cooldownHours);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LegendarySuccessRateBonus value) successRateBonus,
    required TResult Function(LegendaryResultUpgrade value) resultUpgrade,
    required TResult Function(LegendaryDamageResistance value) damageResistance,
    required TResult Function(LegendaryRewardBonus value) rewardBonus,
    required TResult Function(LegendarySpecial value) special,
  }) {
    return special(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult? Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult? Function(LegendaryDamageResistance value)? damageResistance,
    TResult? Function(LegendaryRewardBonus value)? rewardBonus,
    TResult? Function(LegendarySpecial value)? special,
  }) {
    return special?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LegendarySuccessRateBonus value)? successRateBonus,
    TResult Function(LegendaryResultUpgrade value)? resultUpgrade,
    TResult Function(LegendaryDamageResistance value)? damageResistance,
    TResult Function(LegendaryRewardBonus value)? rewardBonus,
    TResult Function(LegendarySpecial value)? special,
    required TResult orElse(),
  }) {
    if (special != null) {
      return special(this);
    }
    return orElse();
  }
}

abstract class LegendarySpecial implements LegendaryEffect {
  const factory LegendarySpecial(
      {required final int deathPreventionCount,
      required final int cooldownHours}) = _$LegendarySpecialImpl;

  int get deathPreventionCount;
  int get cooldownHours;
  @JsonKey(ignore: true)
  _$$LegendarySpecialImplCopyWith<_$LegendarySpecialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
