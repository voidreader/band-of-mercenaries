// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_status_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CombatStatusEffect _$CombatStatusEffectFromJson(Map<String, dynamic> json) {
  return _CombatStatusEffect.fromJson(json);
}

/// @nodoc
mixin _$CombatStatusEffect {
  String get id => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_label')
  String get displayLabel => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_duration_turns')
  int get defaultDurationTurns => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_intensity')
  double get defaultIntensity => throw _privateConstructorUsedError;
  @JsonKey(name: 'stack_policy')
  StackPolicy get stackPolicy => throw _privateConstructorUsedError;
  @JsonKey(name: 'hook_target')
  List<String> get hookTarget => throw _privateConstructorUsedError;
  @JsonKey(name: 'apply_method')
  ApplyMethod get applyMethod => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CombatStatusEffectCopyWith<CombatStatusEffect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CombatStatusEffectCopyWith<$Res> {
  factory $CombatStatusEffectCopyWith(
          CombatStatusEffect value, $Res Function(CombatStatusEffect) then) =
      _$CombatStatusEffectCopyWithImpl<$Res, CombatStatusEffect>;
  @useResult
  $Res call(
      {String id,
      String kind,
      @JsonKey(name: 'display_label') String displayLabel,
      @JsonKey(name: 'default_duration_turns') int defaultDurationTurns,
      @JsonKey(name: 'default_intensity') double defaultIntensity,
      @JsonKey(name: 'stack_policy') StackPolicy stackPolicy,
      @JsonKey(name: 'hook_target') List<String> hookTarget,
      @JsonKey(name: 'apply_method') ApplyMethod applyMethod,
      String description});
}

/// @nodoc
class _$CombatStatusEffectCopyWithImpl<$Res, $Val extends CombatStatusEffect>
    implements $CombatStatusEffectCopyWith<$Res> {
  _$CombatStatusEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? displayLabel = null,
    Object? defaultDurationTurns = null,
    Object? defaultIntensity = null,
    Object? stackPolicy = null,
    Object? hookTarget = null,
    Object? applyMethod = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      displayLabel: null == displayLabel
          ? _value.displayLabel
          : displayLabel // ignore: cast_nullable_to_non_nullable
              as String,
      defaultDurationTurns: null == defaultDurationTurns
          ? _value.defaultDurationTurns
          : defaultDurationTurns // ignore: cast_nullable_to_non_nullable
              as int,
      defaultIntensity: null == defaultIntensity
          ? _value.defaultIntensity
          : defaultIntensity // ignore: cast_nullable_to_non_nullable
              as double,
      stackPolicy: null == stackPolicy
          ? _value.stackPolicy
          : stackPolicy // ignore: cast_nullable_to_non_nullable
              as StackPolicy,
      hookTarget: null == hookTarget
          ? _value.hookTarget
          : hookTarget // ignore: cast_nullable_to_non_nullable
              as List<String>,
      applyMethod: null == applyMethod
          ? _value.applyMethod
          : applyMethod // ignore: cast_nullable_to_non_nullable
              as ApplyMethod,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CombatStatusEffectImplCopyWith<$Res>
    implements $CombatStatusEffectCopyWith<$Res> {
  factory _$$CombatStatusEffectImplCopyWith(_$CombatStatusEffectImpl value,
          $Res Function(_$CombatStatusEffectImpl) then) =
      __$$CombatStatusEffectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String kind,
      @JsonKey(name: 'display_label') String displayLabel,
      @JsonKey(name: 'default_duration_turns') int defaultDurationTurns,
      @JsonKey(name: 'default_intensity') double defaultIntensity,
      @JsonKey(name: 'stack_policy') StackPolicy stackPolicy,
      @JsonKey(name: 'hook_target') List<String> hookTarget,
      @JsonKey(name: 'apply_method') ApplyMethod applyMethod,
      String description});
}

/// @nodoc
class __$$CombatStatusEffectImplCopyWithImpl<$Res>
    extends _$CombatStatusEffectCopyWithImpl<$Res, _$CombatStatusEffectImpl>
    implements _$$CombatStatusEffectImplCopyWith<$Res> {
  __$$CombatStatusEffectImplCopyWithImpl(_$CombatStatusEffectImpl _value,
      $Res Function(_$CombatStatusEffectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? displayLabel = null,
    Object? defaultDurationTurns = null,
    Object? defaultIntensity = null,
    Object? stackPolicy = null,
    Object? hookTarget = null,
    Object? applyMethod = null,
    Object? description = null,
  }) {
    return _then(_$CombatStatusEffectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      displayLabel: null == displayLabel
          ? _value.displayLabel
          : displayLabel // ignore: cast_nullable_to_non_nullable
              as String,
      defaultDurationTurns: null == defaultDurationTurns
          ? _value.defaultDurationTurns
          : defaultDurationTurns // ignore: cast_nullable_to_non_nullable
              as int,
      defaultIntensity: null == defaultIntensity
          ? _value.defaultIntensity
          : defaultIntensity // ignore: cast_nullable_to_non_nullable
              as double,
      stackPolicy: null == stackPolicy
          ? _value.stackPolicy
          : stackPolicy // ignore: cast_nullable_to_non_nullable
              as StackPolicy,
      hookTarget: null == hookTarget
          ? _value._hookTarget
          : hookTarget // ignore: cast_nullable_to_non_nullable
              as List<String>,
      applyMethod: null == applyMethod
          ? _value.applyMethod
          : applyMethod // ignore: cast_nullable_to_non_nullable
              as ApplyMethod,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CombatStatusEffectImpl implements _CombatStatusEffect {
  const _$CombatStatusEffectImpl(
      {required this.id,
      required this.kind,
      @JsonKey(name: 'display_label') required this.displayLabel,
      @JsonKey(name: 'default_duration_turns')
      required this.defaultDurationTurns,
      @JsonKey(name: 'default_intensity') required this.defaultIntensity,
      @JsonKey(name: 'stack_policy') required this.stackPolicy,
      @JsonKey(name: 'hook_target') required final List<String> hookTarget,
      @JsonKey(name: 'apply_method') required this.applyMethod,
      required this.description})
      : _hookTarget = hookTarget;

  factory _$CombatStatusEffectImpl.fromJson(Map<String, dynamic> json) =>
      _$$CombatStatusEffectImplFromJson(json);

  @override
  final String id;
  @override
  final String kind;
  @override
  @JsonKey(name: 'display_label')
  final String displayLabel;
  @override
  @JsonKey(name: 'default_duration_turns')
  final int defaultDurationTurns;
  @override
  @JsonKey(name: 'default_intensity')
  final double defaultIntensity;
  @override
  @JsonKey(name: 'stack_policy')
  final StackPolicy stackPolicy;
  final List<String> _hookTarget;
  @override
  @JsonKey(name: 'hook_target')
  List<String> get hookTarget {
    if (_hookTarget is EqualUnmodifiableListView) return _hookTarget;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hookTarget);
  }

  @override
  @JsonKey(name: 'apply_method')
  final ApplyMethod applyMethod;
  @override
  final String description;

  @override
  String toString() {
    return 'CombatStatusEffect(id: $id, kind: $kind, displayLabel: $displayLabel, defaultDurationTurns: $defaultDurationTurns, defaultIntensity: $defaultIntensity, stackPolicy: $stackPolicy, hookTarget: $hookTarget, applyMethod: $applyMethod, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CombatStatusEffectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.displayLabel, displayLabel) ||
                other.displayLabel == displayLabel) &&
            (identical(other.defaultDurationTurns, defaultDurationTurns) ||
                other.defaultDurationTurns == defaultDurationTurns) &&
            (identical(other.defaultIntensity, defaultIntensity) ||
                other.defaultIntensity == defaultIntensity) &&
            (identical(other.stackPolicy, stackPolicy) ||
                other.stackPolicy == stackPolicy) &&
            const DeepCollectionEquality()
                .equals(other._hookTarget, _hookTarget) &&
            (identical(other.applyMethod, applyMethod) ||
                other.applyMethod == applyMethod) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      kind,
      displayLabel,
      defaultDurationTurns,
      defaultIntensity,
      stackPolicy,
      const DeepCollectionEquality().hash(_hookTarget),
      applyMethod,
      description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CombatStatusEffectImplCopyWith<_$CombatStatusEffectImpl> get copyWith =>
      __$$CombatStatusEffectImplCopyWithImpl<_$CombatStatusEffectImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CombatStatusEffectImplToJson(
      this,
    );
  }
}

abstract class _CombatStatusEffect implements CombatStatusEffect {
  const factory _CombatStatusEffect(
      {required final String id,
      required final String kind,
      @JsonKey(name: 'display_label') required final String displayLabel,
      @JsonKey(name: 'default_duration_turns')
      required final int defaultDurationTurns,
      @JsonKey(name: 'default_intensity')
      required final double defaultIntensity,
      @JsonKey(name: 'stack_policy') required final StackPolicy stackPolicy,
      @JsonKey(name: 'hook_target') required final List<String> hookTarget,
      @JsonKey(name: 'apply_method') required final ApplyMethod applyMethod,
      required final String description}) = _$CombatStatusEffectImpl;

  factory _CombatStatusEffect.fromJson(Map<String, dynamic> json) =
      _$CombatStatusEffectImpl.fromJson;

  @override
  String get id;
  @override
  String get kind;
  @override
  @JsonKey(name: 'display_label')
  String get displayLabel;
  @override
  @JsonKey(name: 'default_duration_turns')
  int get defaultDurationTurns;
  @override
  @JsonKey(name: 'default_intensity')
  double get defaultIntensity;
  @override
  @JsonKey(name: 'stack_policy')
  StackPolicy get stackPolicy;
  @override
  @JsonKey(name: 'hook_target')
  List<String> get hookTarget;
  @override
  @JsonKey(name: 'apply_method')
  ApplyMethod get applyMethod;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$CombatStatusEffectImplCopyWith<_$CombatStatusEffectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
