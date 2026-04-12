// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trait_combo_evolution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TraitComboEvolution _$TraitComboEvolutionFromJson(Map<String, dynamic> json) {
  return _TraitComboEvolution.fromJson(json);
}

/// @nodoc
mixin _$TraitComboEvolution {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_trait_1')
  String get requiredTrait1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_trait_2')
  String get requiredTrait2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_trait_key')
  String get resultTraitKey => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitComboEvolutionCopyWith<TraitComboEvolution> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitComboEvolutionCopyWith<$Res> {
  factory $TraitComboEvolutionCopyWith(
          TraitComboEvolution value, $Res Function(TraitComboEvolution) then) =
      _$TraitComboEvolutionCopyWithImpl<$Res, TraitComboEvolution>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'required_trait_1') String requiredTrait1,
      @JsonKey(name: 'required_trait_2') String requiredTrait2,
      @JsonKey(name: 'result_trait_key') String resultTraitKey});
}

/// @nodoc
class _$TraitComboEvolutionCopyWithImpl<$Res, $Val extends TraitComboEvolution>
    implements $TraitComboEvolutionCopyWith<$Res> {
  _$TraitComboEvolutionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requiredTrait1 = null,
    Object? requiredTrait2 = null,
    Object? resultTraitKey = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      requiredTrait1: null == requiredTrait1
          ? _value.requiredTrait1
          : requiredTrait1 // ignore: cast_nullable_to_non_nullable
              as String,
      requiredTrait2: null == requiredTrait2
          ? _value.requiredTrait2
          : requiredTrait2 // ignore: cast_nullable_to_non_nullable
              as String,
      resultTraitKey: null == resultTraitKey
          ? _value.resultTraitKey
          : resultTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitComboEvolutionImplCopyWith<$Res>
    implements $TraitComboEvolutionCopyWith<$Res> {
  factory _$$TraitComboEvolutionImplCopyWith(_$TraitComboEvolutionImpl value,
          $Res Function(_$TraitComboEvolutionImpl) then) =
      __$$TraitComboEvolutionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'required_trait_1') String requiredTrait1,
      @JsonKey(name: 'required_trait_2') String requiredTrait2,
      @JsonKey(name: 'result_trait_key') String resultTraitKey});
}

/// @nodoc
class __$$TraitComboEvolutionImplCopyWithImpl<$Res>
    extends _$TraitComboEvolutionCopyWithImpl<$Res, _$TraitComboEvolutionImpl>
    implements _$$TraitComboEvolutionImplCopyWith<$Res> {
  __$$TraitComboEvolutionImplCopyWithImpl(_$TraitComboEvolutionImpl _value,
      $Res Function(_$TraitComboEvolutionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requiredTrait1 = null,
    Object? requiredTrait2 = null,
    Object? resultTraitKey = null,
  }) {
    return _then(_$TraitComboEvolutionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      requiredTrait1: null == requiredTrait1
          ? _value.requiredTrait1
          : requiredTrait1 // ignore: cast_nullable_to_non_nullable
              as String,
      requiredTrait2: null == requiredTrait2
          ? _value.requiredTrait2
          : requiredTrait2 // ignore: cast_nullable_to_non_nullable
              as String,
      resultTraitKey: null == resultTraitKey
          ? _value.resultTraitKey
          : resultTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitComboEvolutionImpl implements _TraitComboEvolution {
  const _$TraitComboEvolutionImpl(
      {required this.id,
      @JsonKey(name: 'required_trait_1') required this.requiredTrait1,
      @JsonKey(name: 'required_trait_2') required this.requiredTrait2,
      @JsonKey(name: 'result_trait_key') required this.resultTraitKey});

  factory _$TraitComboEvolutionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitComboEvolutionImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'required_trait_1')
  final String requiredTrait1;
  @override
  @JsonKey(name: 'required_trait_2')
  final String requiredTrait2;
  @override
  @JsonKey(name: 'result_trait_key')
  final String resultTraitKey;

  @override
  String toString() {
    return 'TraitComboEvolution(id: $id, requiredTrait1: $requiredTrait1, requiredTrait2: $requiredTrait2, resultTraitKey: $resultTraitKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitComboEvolutionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requiredTrait1, requiredTrait1) ||
                other.requiredTrait1 == requiredTrait1) &&
            (identical(other.requiredTrait2, requiredTrait2) ||
                other.requiredTrait2 == requiredTrait2) &&
            (identical(other.resultTraitKey, resultTraitKey) ||
                other.resultTraitKey == resultTraitKey));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, requiredTrait1, requiredTrait2, resultTraitKey);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitComboEvolutionImplCopyWith<_$TraitComboEvolutionImpl> get copyWith =>
      __$$TraitComboEvolutionImplCopyWithImpl<_$TraitComboEvolutionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitComboEvolutionImplToJson(
      this,
    );
  }
}

abstract class _TraitComboEvolution implements TraitComboEvolution {
  const factory _TraitComboEvolution(
      {required final int id,
      @JsonKey(name: 'required_trait_1') required final String requiredTrait1,
      @JsonKey(name: 'required_trait_2') required final String requiredTrait2,
      @JsonKey(name: 'result_trait_key')
      required final String resultTraitKey}) = _$TraitComboEvolutionImpl;

  factory _TraitComboEvolution.fromJson(Map<String, dynamic> json) =
      _$TraitComboEvolutionImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'required_trait_1')
  String get requiredTrait1;
  @override
  @JsonKey(name: 'required_trait_2')
  String get requiredTrait2;
  @override
  @JsonKey(name: 'result_trait_key')
  String get resultTraitKey;
  @override
  @JsonKey(ignore: true)
  _$$TraitComboEvolutionImplCopyWith<_$TraitComboEvolutionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
