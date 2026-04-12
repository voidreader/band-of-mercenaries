// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trait_transition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TraitTransition _$TraitTransitionFromJson(Map<String, dynamic> json) {
  return _TraitTransition.fromJson(json);
}

/// @nodoc
mixin _$TraitTransition {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_trait_key')
  String get fromTraitKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_trait_key')
  String get toTraitKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'condition_json')
  Map<String, dynamic> get conditionJson => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitTransitionCopyWith<TraitTransition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitTransitionCopyWith<$Res> {
  factory $TraitTransitionCopyWith(
          TraitTransition value, $Res Function(TraitTransition) then) =
      _$TraitTransitionCopyWithImpl<$Res, TraitTransition>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'from_trait_key') String fromTraitKey,
      @JsonKey(name: 'to_trait_key') String toTraitKey,
      @JsonKey(name: 'condition_json') Map<String, dynamic> conditionJson});
}

/// @nodoc
class _$TraitTransitionCopyWithImpl<$Res, $Val extends TraitTransition>
    implements $TraitTransitionCopyWith<$Res> {
  _$TraitTransitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromTraitKey = null,
    Object? toTraitKey = null,
    Object? conditionJson = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fromTraitKey: null == fromTraitKey
          ? _value.fromTraitKey
          : fromTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      toTraitKey: null == toTraitKey
          ? _value.toTraitKey
          : toTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      conditionJson: null == conditionJson
          ? _value.conditionJson
          : conditionJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitTransitionImplCopyWith<$Res>
    implements $TraitTransitionCopyWith<$Res> {
  factory _$$TraitTransitionImplCopyWith(_$TraitTransitionImpl value,
          $Res Function(_$TraitTransitionImpl) then) =
      __$$TraitTransitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'from_trait_key') String fromTraitKey,
      @JsonKey(name: 'to_trait_key') String toTraitKey,
      @JsonKey(name: 'condition_json') Map<String, dynamic> conditionJson});
}

/// @nodoc
class __$$TraitTransitionImplCopyWithImpl<$Res>
    extends _$TraitTransitionCopyWithImpl<$Res, _$TraitTransitionImpl>
    implements _$$TraitTransitionImplCopyWith<$Res> {
  __$$TraitTransitionImplCopyWithImpl(
      _$TraitTransitionImpl _value, $Res Function(_$TraitTransitionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromTraitKey = null,
    Object? toTraitKey = null,
    Object? conditionJson = null,
  }) {
    return _then(_$TraitTransitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fromTraitKey: null == fromTraitKey
          ? _value.fromTraitKey
          : fromTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      toTraitKey: null == toTraitKey
          ? _value.toTraitKey
          : toTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      conditionJson: null == conditionJson
          ? _value._conditionJson
          : conditionJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitTransitionImpl implements _TraitTransition {
  const _$TraitTransitionImpl(
      {required this.id,
      @JsonKey(name: 'from_trait_key') required this.fromTraitKey,
      @JsonKey(name: 'to_trait_key') required this.toTraitKey,
      @JsonKey(name: 'condition_json')
      required final Map<String, dynamic> conditionJson})
      : _conditionJson = conditionJson;

  factory _$TraitTransitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitTransitionImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'from_trait_key')
  final String fromTraitKey;
  @override
  @JsonKey(name: 'to_trait_key')
  final String toTraitKey;
  final Map<String, dynamic> _conditionJson;
  @override
  @JsonKey(name: 'condition_json')
  Map<String, dynamic> get conditionJson {
    if (_conditionJson is EqualUnmodifiableMapView) return _conditionJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_conditionJson);
  }

  @override
  String toString() {
    return 'TraitTransition(id: $id, fromTraitKey: $fromTraitKey, toTraitKey: $toTraitKey, conditionJson: $conditionJson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitTransitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromTraitKey, fromTraitKey) ||
                other.fromTraitKey == fromTraitKey) &&
            (identical(other.toTraitKey, toTraitKey) ||
                other.toTraitKey == toTraitKey) &&
            const DeepCollectionEquality()
                .equals(other._conditionJson, _conditionJson));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, fromTraitKey, toTraitKey,
      const DeepCollectionEquality().hash(_conditionJson));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitTransitionImplCopyWith<_$TraitTransitionImpl> get copyWith =>
      __$$TraitTransitionImplCopyWithImpl<_$TraitTransitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitTransitionImplToJson(
      this,
    );
  }
}

abstract class _TraitTransition implements TraitTransition {
  const factory _TraitTransition(
          {required final int id,
          @JsonKey(name: 'from_trait_key') required final String fromTraitKey,
          @JsonKey(name: 'to_trait_key') required final String toTraitKey,
          @JsonKey(name: 'condition_json')
          required final Map<String, dynamic> conditionJson}) =
      _$TraitTransitionImpl;

  factory _TraitTransition.fromJson(Map<String, dynamic> json) =
      _$TraitTransitionImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'from_trait_key')
  String get fromTraitKey;
  @override
  @JsonKey(name: 'to_trait_key')
  String get toTraitKey;
  @override
  @JsonKey(name: 'condition_json')
  Map<String, dynamic> get conditionJson;
  @override
  @JsonKey(ignore: true)
  _$$TraitTransitionImplCopyWith<_$TraitTransitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
