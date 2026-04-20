// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'essence_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EssenceDescriptor {
  String get statKey =>
      throw _privateConstructorUsedError; // 'str' | 'intelligence' | 'vit' | 'agi'
  int get gain => throw _privateConstructorUsedError; // 티어별 증가량
  int get tier => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EssenceDescriptorCopyWith<EssenceDescriptor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EssenceDescriptorCopyWith<$Res> {
  factory $EssenceDescriptorCopyWith(
          EssenceDescriptor value, $Res Function(EssenceDescriptor) then) =
      _$EssenceDescriptorCopyWithImpl<$Res, EssenceDescriptor>;
  @useResult
  $Res call({String statKey, int gain, int tier});
}

/// @nodoc
class _$EssenceDescriptorCopyWithImpl<$Res, $Val extends EssenceDescriptor>
    implements $EssenceDescriptorCopyWith<$Res> {
  _$EssenceDescriptorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statKey = null,
    Object? gain = null,
    Object? tier = null,
  }) {
    return _then(_value.copyWith(
      statKey: null == statKey
          ? _value.statKey
          : statKey // ignore: cast_nullable_to_non_nullable
              as String,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as int,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EssenceDescriptorImplCopyWith<$Res>
    implements $EssenceDescriptorCopyWith<$Res> {
  factory _$$EssenceDescriptorImplCopyWith(_$EssenceDescriptorImpl value,
          $Res Function(_$EssenceDescriptorImpl) then) =
      __$$EssenceDescriptorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String statKey, int gain, int tier});
}

/// @nodoc
class __$$EssenceDescriptorImplCopyWithImpl<$Res>
    extends _$EssenceDescriptorCopyWithImpl<$Res, _$EssenceDescriptorImpl>
    implements _$$EssenceDescriptorImplCopyWith<$Res> {
  __$$EssenceDescriptorImplCopyWithImpl(_$EssenceDescriptorImpl _value,
      $Res Function(_$EssenceDescriptorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statKey = null,
    Object? gain = null,
    Object? tier = null,
  }) {
    return _then(_$EssenceDescriptorImpl(
      statKey: null == statKey
          ? _value.statKey
          : statKey // ignore: cast_nullable_to_non_nullable
              as String,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as int,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$EssenceDescriptorImpl
    with DiagnosticableTreeMixin
    implements _EssenceDescriptor {
  const _$EssenceDescriptorImpl(
      {required this.statKey, required this.gain, required this.tier});

  @override
  final String statKey;
// 'str' | 'intelligence' | 'vit' | 'agi'
  @override
  final int gain;
// 티어별 증가량
  @override
  final int tier;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'EssenceDescriptor(statKey: $statKey, gain: $gain, tier: $tier)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'EssenceDescriptor'))
      ..add(DiagnosticsProperty('statKey', statKey))
      ..add(DiagnosticsProperty('gain', gain))
      ..add(DiagnosticsProperty('tier', tier));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EssenceDescriptorImpl &&
            (identical(other.statKey, statKey) || other.statKey == statKey) &&
            (identical(other.gain, gain) || other.gain == gain) &&
            (identical(other.tier, tier) || other.tier == tier));
  }

  @override
  int get hashCode => Object.hash(runtimeType, statKey, gain, tier);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EssenceDescriptorImplCopyWith<_$EssenceDescriptorImpl> get copyWith =>
      __$$EssenceDescriptorImplCopyWithImpl<_$EssenceDescriptorImpl>(
          this, _$identity);
}

abstract class _EssenceDescriptor implements EssenceDescriptor {
  const factory _EssenceDescriptor(
      {required final String statKey,
      required final int gain,
      required final int tier}) = _$EssenceDescriptorImpl;

  @override
  String get statKey;
  @override // 'str' | 'intelligence' | 'vit' | 'agi'
  int get gain;
  @override // 티어별 증가량
  int get tier;
  @override
  @JsonKey(ignore: true)
  _$$EssenceDescriptorImplCopyWith<_$EssenceDescriptorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EssencePreview {
  String get statKey => throw _privateConstructorUsedError;
  int get currentPermanent => throw _privateConstructorUsedError;
  int get cap => throw _privateConstructorUsedError;
  int get gain => throw _privateConstructorUsedError;
  int get appliedGain => throw _privateConstructorUsedError;
  int get lossAmount => throw _privateConstructorUsedError;
  int get effectiveBefore => throw _privateConstructorUsedError;
  int get effectiveAfter => throw _privateConstructorUsedError;
  EssencePreviewLevel get warningLevel => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EssencePreviewCopyWith<EssencePreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EssencePreviewCopyWith<$Res> {
  factory $EssencePreviewCopyWith(
          EssencePreview value, $Res Function(EssencePreview) then) =
      _$EssencePreviewCopyWithImpl<$Res, EssencePreview>;
  @useResult
  $Res call(
      {String statKey,
      int currentPermanent,
      int cap,
      int gain,
      int appliedGain,
      int lossAmount,
      int effectiveBefore,
      int effectiveAfter,
      EssencePreviewLevel warningLevel});
}

/// @nodoc
class _$EssencePreviewCopyWithImpl<$Res, $Val extends EssencePreview>
    implements $EssencePreviewCopyWith<$Res> {
  _$EssencePreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statKey = null,
    Object? currentPermanent = null,
    Object? cap = null,
    Object? gain = null,
    Object? appliedGain = null,
    Object? lossAmount = null,
    Object? effectiveBefore = null,
    Object? effectiveAfter = null,
    Object? warningLevel = null,
  }) {
    return _then(_value.copyWith(
      statKey: null == statKey
          ? _value.statKey
          : statKey // ignore: cast_nullable_to_non_nullable
              as String,
      currentPermanent: null == currentPermanent
          ? _value.currentPermanent
          : currentPermanent // ignore: cast_nullable_to_non_nullable
              as int,
      cap: null == cap
          ? _value.cap
          : cap // ignore: cast_nullable_to_non_nullable
              as int,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as int,
      appliedGain: null == appliedGain
          ? _value.appliedGain
          : appliedGain // ignore: cast_nullable_to_non_nullable
              as int,
      lossAmount: null == lossAmount
          ? _value.lossAmount
          : lossAmount // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveBefore: null == effectiveBefore
          ? _value.effectiveBefore
          : effectiveBefore // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveAfter: null == effectiveAfter
          ? _value.effectiveAfter
          : effectiveAfter // ignore: cast_nullable_to_non_nullable
              as int,
      warningLevel: null == warningLevel
          ? _value.warningLevel
          : warningLevel // ignore: cast_nullable_to_non_nullable
              as EssencePreviewLevel,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EssencePreviewImplCopyWith<$Res>
    implements $EssencePreviewCopyWith<$Res> {
  factory _$$EssencePreviewImplCopyWith(_$EssencePreviewImpl value,
          $Res Function(_$EssencePreviewImpl) then) =
      __$$EssencePreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String statKey,
      int currentPermanent,
      int cap,
      int gain,
      int appliedGain,
      int lossAmount,
      int effectiveBefore,
      int effectiveAfter,
      EssencePreviewLevel warningLevel});
}

/// @nodoc
class __$$EssencePreviewImplCopyWithImpl<$Res>
    extends _$EssencePreviewCopyWithImpl<$Res, _$EssencePreviewImpl>
    implements _$$EssencePreviewImplCopyWith<$Res> {
  __$$EssencePreviewImplCopyWithImpl(
      _$EssencePreviewImpl _value, $Res Function(_$EssencePreviewImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statKey = null,
    Object? currentPermanent = null,
    Object? cap = null,
    Object? gain = null,
    Object? appliedGain = null,
    Object? lossAmount = null,
    Object? effectiveBefore = null,
    Object? effectiveAfter = null,
    Object? warningLevel = null,
  }) {
    return _then(_$EssencePreviewImpl(
      statKey: null == statKey
          ? _value.statKey
          : statKey // ignore: cast_nullable_to_non_nullable
              as String,
      currentPermanent: null == currentPermanent
          ? _value.currentPermanent
          : currentPermanent // ignore: cast_nullable_to_non_nullable
              as int,
      cap: null == cap
          ? _value.cap
          : cap // ignore: cast_nullable_to_non_nullable
              as int,
      gain: null == gain
          ? _value.gain
          : gain // ignore: cast_nullable_to_non_nullable
              as int,
      appliedGain: null == appliedGain
          ? _value.appliedGain
          : appliedGain // ignore: cast_nullable_to_non_nullable
              as int,
      lossAmount: null == lossAmount
          ? _value.lossAmount
          : lossAmount // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveBefore: null == effectiveBefore
          ? _value.effectiveBefore
          : effectiveBefore // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveAfter: null == effectiveAfter
          ? _value.effectiveAfter
          : effectiveAfter // ignore: cast_nullable_to_non_nullable
              as int,
      warningLevel: null == warningLevel
          ? _value.warningLevel
          : warningLevel // ignore: cast_nullable_to_non_nullable
              as EssencePreviewLevel,
    ));
  }
}

/// @nodoc

class _$EssencePreviewImpl
    with DiagnosticableTreeMixin
    implements _EssencePreview {
  const _$EssencePreviewImpl(
      {required this.statKey,
      required this.currentPermanent,
      required this.cap,
      required this.gain,
      required this.appliedGain,
      required this.lossAmount,
      required this.effectiveBefore,
      required this.effectiveAfter,
      required this.warningLevel});

  @override
  final String statKey;
  @override
  final int currentPermanent;
  @override
  final int cap;
  @override
  final int gain;
  @override
  final int appliedGain;
  @override
  final int lossAmount;
  @override
  final int effectiveBefore;
  @override
  final int effectiveAfter;
  @override
  final EssencePreviewLevel warningLevel;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'EssencePreview(statKey: $statKey, currentPermanent: $currentPermanent, cap: $cap, gain: $gain, appliedGain: $appliedGain, lossAmount: $lossAmount, effectiveBefore: $effectiveBefore, effectiveAfter: $effectiveAfter, warningLevel: $warningLevel)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'EssencePreview'))
      ..add(DiagnosticsProperty('statKey', statKey))
      ..add(DiagnosticsProperty('currentPermanent', currentPermanent))
      ..add(DiagnosticsProperty('cap', cap))
      ..add(DiagnosticsProperty('gain', gain))
      ..add(DiagnosticsProperty('appliedGain', appliedGain))
      ..add(DiagnosticsProperty('lossAmount', lossAmount))
      ..add(DiagnosticsProperty('effectiveBefore', effectiveBefore))
      ..add(DiagnosticsProperty('effectiveAfter', effectiveAfter))
      ..add(DiagnosticsProperty('warningLevel', warningLevel));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EssencePreviewImpl &&
            (identical(other.statKey, statKey) || other.statKey == statKey) &&
            (identical(other.currentPermanent, currentPermanent) ||
                other.currentPermanent == currentPermanent) &&
            (identical(other.cap, cap) || other.cap == cap) &&
            (identical(other.gain, gain) || other.gain == gain) &&
            (identical(other.appliedGain, appliedGain) ||
                other.appliedGain == appliedGain) &&
            (identical(other.lossAmount, lossAmount) ||
                other.lossAmount == lossAmount) &&
            (identical(other.effectiveBefore, effectiveBefore) ||
                other.effectiveBefore == effectiveBefore) &&
            (identical(other.effectiveAfter, effectiveAfter) ||
                other.effectiveAfter == effectiveAfter) &&
            (identical(other.warningLevel, warningLevel) ||
                other.warningLevel == warningLevel));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      statKey,
      currentPermanent,
      cap,
      gain,
      appliedGain,
      lossAmount,
      effectiveBefore,
      effectiveAfter,
      warningLevel);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EssencePreviewImplCopyWith<_$EssencePreviewImpl> get copyWith =>
      __$$EssencePreviewImplCopyWithImpl<_$EssencePreviewImpl>(
          this, _$identity);
}

abstract class _EssencePreview implements EssencePreview {
  const factory _EssencePreview(
      {required final String statKey,
      required final int currentPermanent,
      required final int cap,
      required final int gain,
      required final int appliedGain,
      required final int lossAmount,
      required final int effectiveBefore,
      required final int effectiveAfter,
      required final EssencePreviewLevel warningLevel}) = _$EssencePreviewImpl;

  @override
  String get statKey;
  @override
  int get currentPermanent;
  @override
  int get cap;
  @override
  int get gain;
  @override
  int get appliedGain;
  @override
  int get lossAmount;
  @override
  int get effectiveBefore;
  @override
  int get effectiveAfter;
  @override
  EssencePreviewLevel get warningLevel;
  @override
  @JsonKey(ignore: true)
  _$$EssencePreviewImplCopyWith<_$EssencePreviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EssenceApplyResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)
        success,
    required TResult Function(String reason) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)?
        success,
    TResult? Function(String reason)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)?
        success,
    TResult Function(String reason)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EssenceApplySuccess value) success,
    required TResult Function(EssenceApplyFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EssenceApplySuccess value)? success,
    TResult? Function(EssenceApplyFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EssenceApplySuccess value)? success,
    TResult Function(EssenceApplyFailure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EssenceApplyResultCopyWith<$Res> {
  factory $EssenceApplyResultCopyWith(
          EssenceApplyResult value, $Res Function(EssenceApplyResult) then) =
      _$EssenceApplyResultCopyWithImpl<$Res, EssenceApplyResult>;
}

/// @nodoc
class _$EssenceApplyResultCopyWithImpl<$Res, $Val extends EssenceApplyResult>
    implements $EssenceApplyResultCopyWith<$Res> {
  _$EssenceApplyResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$EssenceApplySuccessImplCopyWith<$Res> {
  factory _$$EssenceApplySuccessImplCopyWith(_$EssenceApplySuccessImpl value,
          $Res Function(_$EssenceApplySuccessImpl) then) =
      __$$EssenceApplySuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String statKey, int appliedGain, int lossAmount, int newPermanent});
}

/// @nodoc
class __$$EssenceApplySuccessImplCopyWithImpl<$Res>
    extends _$EssenceApplyResultCopyWithImpl<$Res, _$EssenceApplySuccessImpl>
    implements _$$EssenceApplySuccessImplCopyWith<$Res> {
  __$$EssenceApplySuccessImplCopyWithImpl(_$EssenceApplySuccessImpl _value,
      $Res Function(_$EssenceApplySuccessImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statKey = null,
    Object? appliedGain = null,
    Object? lossAmount = null,
    Object? newPermanent = null,
  }) {
    return _then(_$EssenceApplySuccessImpl(
      statKey: null == statKey
          ? _value.statKey
          : statKey // ignore: cast_nullable_to_non_nullable
              as String,
      appliedGain: null == appliedGain
          ? _value.appliedGain
          : appliedGain // ignore: cast_nullable_to_non_nullable
              as int,
      lossAmount: null == lossAmount
          ? _value.lossAmount
          : lossAmount // ignore: cast_nullable_to_non_nullable
              as int,
      newPermanent: null == newPermanent
          ? _value.newPermanent
          : newPermanent // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$EssenceApplySuccessImpl
    with DiagnosticableTreeMixin
    implements EssenceApplySuccess {
  const _$EssenceApplySuccessImpl(
      {required this.statKey,
      required this.appliedGain,
      required this.lossAmount,
      required this.newPermanent});

  @override
  final String statKey;
  @override
  final int appliedGain;
  @override
  final int lossAmount;
  @override
  final int newPermanent;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'EssenceApplyResult.success(statKey: $statKey, appliedGain: $appliedGain, lossAmount: $lossAmount, newPermanent: $newPermanent)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'EssenceApplyResult.success'))
      ..add(DiagnosticsProperty('statKey', statKey))
      ..add(DiagnosticsProperty('appliedGain', appliedGain))
      ..add(DiagnosticsProperty('lossAmount', lossAmount))
      ..add(DiagnosticsProperty('newPermanent', newPermanent));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EssenceApplySuccessImpl &&
            (identical(other.statKey, statKey) || other.statKey == statKey) &&
            (identical(other.appliedGain, appliedGain) ||
                other.appliedGain == appliedGain) &&
            (identical(other.lossAmount, lossAmount) ||
                other.lossAmount == lossAmount) &&
            (identical(other.newPermanent, newPermanent) ||
                other.newPermanent == newPermanent));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, statKey, appliedGain, lossAmount, newPermanent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EssenceApplySuccessImplCopyWith<_$EssenceApplySuccessImpl> get copyWith =>
      __$$EssenceApplySuccessImplCopyWithImpl<_$EssenceApplySuccessImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)
        success,
    required TResult Function(String reason) failure,
  }) {
    return success(statKey, appliedGain, lossAmount, newPermanent);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)?
        success,
    TResult? Function(String reason)? failure,
  }) {
    return success?.call(statKey, appliedGain, lossAmount, newPermanent);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)?
        success,
    TResult Function(String reason)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(statKey, appliedGain, lossAmount, newPermanent);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EssenceApplySuccess value) success,
    required TResult Function(EssenceApplyFailure value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EssenceApplySuccess value)? success,
    TResult? Function(EssenceApplyFailure value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EssenceApplySuccess value)? success,
    TResult Function(EssenceApplyFailure value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class EssenceApplySuccess implements EssenceApplyResult {
  const factory EssenceApplySuccess(
      {required final String statKey,
      required final int appliedGain,
      required final int lossAmount,
      required final int newPermanent}) = _$EssenceApplySuccessImpl;

  String get statKey;
  int get appliedGain;
  int get lossAmount;
  int get newPermanent;
  @JsonKey(ignore: true)
  _$$EssenceApplySuccessImplCopyWith<_$EssenceApplySuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EssenceApplyFailureImplCopyWith<$Res> {
  factory _$$EssenceApplyFailureImplCopyWith(_$EssenceApplyFailureImpl value,
          $Res Function(_$EssenceApplyFailureImpl) then) =
      __$$EssenceApplyFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class __$$EssenceApplyFailureImplCopyWithImpl<$Res>
    extends _$EssenceApplyResultCopyWithImpl<$Res, _$EssenceApplyFailureImpl>
    implements _$$EssenceApplyFailureImplCopyWith<$Res> {
  __$$EssenceApplyFailureImplCopyWithImpl(_$EssenceApplyFailureImpl _value,
      $Res Function(_$EssenceApplyFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
  }) {
    return _then(_$EssenceApplyFailureImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$EssenceApplyFailureImpl
    with DiagnosticableTreeMixin
    implements EssenceApplyFailure {
  const _$EssenceApplyFailureImpl({required this.reason});

  @override
  final String reason;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'EssenceApplyResult.failure(reason: $reason)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'EssenceApplyResult.failure'))
      ..add(DiagnosticsProperty('reason', reason));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EssenceApplyFailureImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EssenceApplyFailureImplCopyWith<_$EssenceApplyFailureImpl> get copyWith =>
      __$$EssenceApplyFailureImplCopyWithImpl<_$EssenceApplyFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)
        success,
    required TResult Function(String reason) failure,
  }) {
    return failure(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)?
        success,
    TResult? Function(String reason)? failure,
  }) {
    return failure?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String statKey, int appliedGain, int lossAmount, int newPermanent)?
        success,
    TResult Function(String reason)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(EssenceApplySuccess value) success,
    required TResult Function(EssenceApplyFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(EssenceApplySuccess value)? success,
    TResult? Function(EssenceApplyFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(EssenceApplySuccess value)? success,
    TResult Function(EssenceApplyFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class EssenceApplyFailure implements EssenceApplyResult {
  const factory EssenceApplyFailure({required final String reason}) =
      _$EssenceApplyFailureImpl;

  String get reason;
  @JsonKey(ignore: true)
  _$$EssenceApplyFailureImplCopyWith<_$EssenceApplyFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
