// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trait_synergy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TraitSynergy _$TraitSynergyFromJson(Map<String, dynamic> json) {
  return _TraitSynergy.fromJson(json);
}

/// @nodoc
mixin _$TraitSynergy {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'innate_trait_key')
  String get innateTraitKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_trait_key')
  String get targetTraitKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'reduction_percent')
  double get reductionPercent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitSynergyCopyWith<TraitSynergy> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitSynergyCopyWith<$Res> {
  factory $TraitSynergyCopyWith(
          TraitSynergy value, $Res Function(TraitSynergy) then) =
      _$TraitSynergyCopyWithImpl<$Res, TraitSynergy>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'innate_trait_key') String innateTraitKey,
      @JsonKey(name: 'target_trait_key') String targetTraitKey,
      @JsonKey(name: 'reduction_percent') double reductionPercent});
}

/// @nodoc
class _$TraitSynergyCopyWithImpl<$Res, $Val extends TraitSynergy>
    implements $TraitSynergyCopyWith<$Res> {
  _$TraitSynergyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? innateTraitKey = null,
    Object? targetTraitKey = null,
    Object? reductionPercent = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      innateTraitKey: null == innateTraitKey
          ? _value.innateTraitKey
          : innateTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      targetTraitKey: null == targetTraitKey
          ? _value.targetTraitKey
          : targetTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      reductionPercent: null == reductionPercent
          ? _value.reductionPercent
          : reductionPercent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitSynergyImplCopyWith<$Res>
    implements $TraitSynergyCopyWith<$Res> {
  factory _$$TraitSynergyImplCopyWith(
          _$TraitSynergyImpl value, $Res Function(_$TraitSynergyImpl) then) =
      __$$TraitSynergyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'innate_trait_key') String innateTraitKey,
      @JsonKey(name: 'target_trait_key') String targetTraitKey,
      @JsonKey(name: 'reduction_percent') double reductionPercent});
}

/// @nodoc
class __$$TraitSynergyImplCopyWithImpl<$Res>
    extends _$TraitSynergyCopyWithImpl<$Res, _$TraitSynergyImpl>
    implements _$$TraitSynergyImplCopyWith<$Res> {
  __$$TraitSynergyImplCopyWithImpl(
      _$TraitSynergyImpl _value, $Res Function(_$TraitSynergyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? innateTraitKey = null,
    Object? targetTraitKey = null,
    Object? reductionPercent = null,
  }) {
    return _then(_$TraitSynergyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      innateTraitKey: null == innateTraitKey
          ? _value.innateTraitKey
          : innateTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      targetTraitKey: null == targetTraitKey
          ? _value.targetTraitKey
          : targetTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
      reductionPercent: null == reductionPercent
          ? _value.reductionPercent
          : reductionPercent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitSynergyImpl implements _TraitSynergy {
  const _$TraitSynergyImpl(
      {required this.id,
      @JsonKey(name: 'innate_trait_key') required this.innateTraitKey,
      @JsonKey(name: 'target_trait_key') required this.targetTraitKey,
      @JsonKey(name: 'reduction_percent') required this.reductionPercent});

  factory _$TraitSynergyImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitSynergyImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'innate_trait_key')
  final String innateTraitKey;
  @override
  @JsonKey(name: 'target_trait_key')
  final String targetTraitKey;
  @override
  @JsonKey(name: 'reduction_percent')
  final double reductionPercent;

  @override
  String toString() {
    return 'TraitSynergy(id: $id, innateTraitKey: $innateTraitKey, targetTraitKey: $targetTraitKey, reductionPercent: $reductionPercent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitSynergyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.innateTraitKey, innateTraitKey) ||
                other.innateTraitKey == innateTraitKey) &&
            (identical(other.targetTraitKey, targetTraitKey) ||
                other.targetTraitKey == targetTraitKey) &&
            (identical(other.reductionPercent, reductionPercent) ||
                other.reductionPercent == reductionPercent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, innateTraitKey, targetTraitKey, reductionPercent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitSynergyImplCopyWith<_$TraitSynergyImpl> get copyWith =>
      __$$TraitSynergyImplCopyWithImpl<_$TraitSynergyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitSynergyImplToJson(
      this,
    );
  }
}

abstract class _TraitSynergy implements TraitSynergy {
  const factory _TraitSynergy(
      {required final int id,
      @JsonKey(name: 'innate_trait_key') required final String innateTraitKey,
      @JsonKey(name: 'target_trait_key') required final String targetTraitKey,
      @JsonKey(name: 'reduction_percent')
      required final double reductionPercent}) = _$TraitSynergyImpl;

  factory _TraitSynergy.fromJson(Map<String, dynamic> json) =
      _$TraitSynergyImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'innate_trait_key')
  String get innateTraitKey;
  @override
  @JsonKey(name: 'target_trait_key')
  String get targetTraitKey;
  @override
  @JsonKey(name: 'reduction_percent')
  double get reductionPercent;
  @override
  @JsonKey(ignore: true)
  _$$TraitSynergyImplCopyWith<_$TraitSynergyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
