// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region_state_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RegionStateEffect _$RegionStateEffectFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'cumulative':
      return CumulativeEffect.fromJson(json);
    case 'oneshot':
      return OneshotEffect.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'RegionStateEffect',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$RegionStateEffect {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)
        cumulative,
    required TResult Function(int delta, String flag) oneshot,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)?
        cumulative,
    TResult? Function(int delta, String flag)? oneshot,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)?
        cumulative,
    TResult Function(int delta, String flag)? oneshot,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CumulativeEffect value) cumulative,
    required TResult Function(OneshotEffect value) oneshot,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CumulativeEffect value)? cumulative,
    TResult? Function(OneshotEffect value)? oneshot,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CumulativeEffect value)? cumulative,
    TResult Function(OneshotEffect value)? oneshot,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionStateEffectCopyWith<$Res> {
  factory $RegionStateEffectCopyWith(
          RegionStateEffect value, $Res Function(RegionStateEffect) then) =
      _$RegionStateEffectCopyWithImpl<$Res, RegionStateEffect>;
}

/// @nodoc
class _$RegionStateEffectCopyWithImpl<$Res, $Val extends RegionStateEffect>
    implements $RegionStateEffectCopyWith<$Res> {
  _$RegionStateEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$CumulativeEffectImplCopyWith<$Res> {
  factory _$$CumulativeEffectImplCopyWith(_$CumulativeEffectImpl value,
          $Res Function(_$CumulativeEffectImpl) then) =
      __$$CumulativeEffectImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {@JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
      @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
      @JsonKey(name: 'threshold_flag') String thresholdFlag});
}

/// @nodoc
class __$$CumulativeEffectImplCopyWithImpl<$Res>
    extends _$RegionStateEffectCopyWithImpl<$Res, _$CumulativeEffectImpl>
    implements _$$CumulativeEffectImplCopyWith<$Res> {
  __$$CumulativeEffectImplCopyWithImpl(_$CumulativeEffectImpl _value,
      $Res Function(_$CumulativeEffectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deltaPerCompletion = null,
    Object? capPerThreshold = null,
    Object? thresholdFlag = null,
  }) {
    return _then(_$CumulativeEffectImpl(
      deltaPerCompletion: null == deltaPerCompletion
          ? _value.deltaPerCompletion
          : deltaPerCompletion // ignore: cast_nullable_to_non_nullable
              as int,
      capPerThreshold: null == capPerThreshold
          ? _value.capPerThreshold
          : capPerThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      thresholdFlag: null == thresholdFlag
          ? _value.thresholdFlag
          : thresholdFlag // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CumulativeEffectImpl implements CumulativeEffect {
  const _$CumulativeEffectImpl(
      {@JsonKey(name: 'delta_per_completion') required this.deltaPerCompletion,
      @JsonKey(name: 'cap_per_threshold') required this.capPerThreshold,
      @JsonKey(name: 'threshold_flag') required this.thresholdFlag,
      final String? $type})
      : $type = $type ?? 'cumulative';

  factory _$CumulativeEffectImpl.fromJson(Map<String, dynamic> json) =>
      _$$CumulativeEffectImplFromJson(json);

  @override
  @JsonKey(name: 'delta_per_completion')
  final int deltaPerCompletion;
  @override
  @JsonKey(name: 'cap_per_threshold')
  final int capPerThreshold;
  @override
  @JsonKey(name: 'threshold_flag')
  final String thresholdFlag;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RegionStateEffect.cumulative(deltaPerCompletion: $deltaPerCompletion, capPerThreshold: $capPerThreshold, thresholdFlag: $thresholdFlag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CumulativeEffectImpl &&
            (identical(other.deltaPerCompletion, deltaPerCompletion) ||
                other.deltaPerCompletion == deltaPerCompletion) &&
            (identical(other.capPerThreshold, capPerThreshold) ||
                other.capPerThreshold == capPerThreshold) &&
            (identical(other.thresholdFlag, thresholdFlag) ||
                other.thresholdFlag == thresholdFlag));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, deltaPerCompletion, capPerThreshold, thresholdFlag);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CumulativeEffectImplCopyWith<_$CumulativeEffectImpl> get copyWith =>
      __$$CumulativeEffectImplCopyWithImpl<_$CumulativeEffectImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)
        cumulative,
    required TResult Function(int delta, String flag) oneshot,
  }) {
    return cumulative(deltaPerCompletion, capPerThreshold, thresholdFlag);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)?
        cumulative,
    TResult? Function(int delta, String flag)? oneshot,
  }) {
    return cumulative?.call(deltaPerCompletion, capPerThreshold, thresholdFlag);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)?
        cumulative,
    TResult Function(int delta, String flag)? oneshot,
    required TResult orElse(),
  }) {
    if (cumulative != null) {
      return cumulative(deltaPerCompletion, capPerThreshold, thresholdFlag);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CumulativeEffect value) cumulative,
    required TResult Function(OneshotEffect value) oneshot,
  }) {
    return cumulative(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CumulativeEffect value)? cumulative,
    TResult? Function(OneshotEffect value)? oneshot,
  }) {
    return cumulative?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CumulativeEffect value)? cumulative,
    TResult Function(OneshotEffect value)? oneshot,
    required TResult orElse(),
  }) {
    if (cumulative != null) {
      return cumulative(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CumulativeEffectImplToJson(
      this,
    );
  }
}

abstract class CumulativeEffect implements RegionStateEffect {
  const factory CumulativeEffect(
      {@JsonKey(name: 'delta_per_completion')
      required final int deltaPerCompletion,
      @JsonKey(name: 'cap_per_threshold') required final int capPerThreshold,
      @JsonKey(name: 'threshold_flag')
      required final String thresholdFlag}) = _$CumulativeEffectImpl;

  factory CumulativeEffect.fromJson(Map<String, dynamic> json) =
      _$CumulativeEffectImpl.fromJson;

  @JsonKey(name: 'delta_per_completion')
  int get deltaPerCompletion;
  @JsonKey(name: 'cap_per_threshold')
  int get capPerThreshold;
  @JsonKey(name: 'threshold_flag')
  String get thresholdFlag;
  @JsonKey(ignore: true)
  _$$CumulativeEffectImplCopyWith<_$CumulativeEffectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OneshotEffectImplCopyWith<$Res> {
  factory _$$OneshotEffectImplCopyWith(
          _$OneshotEffectImpl value, $Res Function(_$OneshotEffectImpl) then) =
      __$$OneshotEffectImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int delta, String flag});
}

/// @nodoc
class __$$OneshotEffectImplCopyWithImpl<$Res>
    extends _$RegionStateEffectCopyWithImpl<$Res, _$OneshotEffectImpl>
    implements _$$OneshotEffectImplCopyWith<$Res> {
  __$$OneshotEffectImplCopyWithImpl(
      _$OneshotEffectImpl _value, $Res Function(_$OneshotEffectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? delta = null,
    Object? flag = null,
  }) {
    return _then(_$OneshotEffectImpl(
      delta: null == delta
          ? _value.delta
          : delta // ignore: cast_nullable_to_non_nullable
              as int,
      flag: null == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OneshotEffectImpl implements OneshotEffect {
  const _$OneshotEffectImpl(
      {required this.delta, required this.flag, final String? $type})
      : $type = $type ?? 'oneshot';

  factory _$OneshotEffectImpl.fromJson(Map<String, dynamic> json) =>
      _$$OneshotEffectImplFromJson(json);

  @override
  final int delta;
  @override
  final String flag;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'RegionStateEffect.oneshot(delta: $delta, flag: $flag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OneshotEffectImpl &&
            (identical(other.delta, delta) || other.delta == delta) &&
            (identical(other.flag, flag) || other.flag == flag));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, delta, flag);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OneshotEffectImplCopyWith<_$OneshotEffectImpl> get copyWith =>
      __$$OneshotEffectImplCopyWithImpl<_$OneshotEffectImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)
        cumulative,
    required TResult Function(int delta, String flag) oneshot,
  }) {
    return oneshot(delta, flag);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)?
        cumulative,
    TResult? Function(int delta, String flag)? oneshot,
  }) {
    return oneshot?.call(delta, flag);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @JsonKey(name: 'delta_per_completion') int deltaPerCompletion,
            @JsonKey(name: 'cap_per_threshold') int capPerThreshold,
            @JsonKey(name: 'threshold_flag') String thresholdFlag)?
        cumulative,
    TResult Function(int delta, String flag)? oneshot,
    required TResult orElse(),
  }) {
    if (oneshot != null) {
      return oneshot(delta, flag);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CumulativeEffect value) cumulative,
    required TResult Function(OneshotEffect value) oneshot,
  }) {
    return oneshot(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CumulativeEffect value)? cumulative,
    TResult? Function(OneshotEffect value)? oneshot,
  }) {
    return oneshot?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CumulativeEffect value)? cumulative,
    TResult Function(OneshotEffect value)? oneshot,
    required TResult orElse(),
  }) {
    if (oneshot != null) {
      return oneshot(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$OneshotEffectImplToJson(
      this,
    );
  }
}

abstract class OneshotEffect implements RegionStateEffect {
  const factory OneshotEffect(
      {required final int delta,
      required final String flag}) = _$OneshotEffectImpl;

  factory OneshotEffect.fromJson(Map<String, dynamic> json) =
      _$OneshotEffectImpl.fromJson;

  int get delta;
  String get flag;
  @JsonKey(ignore: true)
  _$$OneshotEffectImplCopyWith<_$OneshotEffectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
