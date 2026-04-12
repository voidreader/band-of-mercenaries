// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trait_conflict.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TraitConflict _$TraitConflictFromJson(Map<String, dynamic> json) {
  return _TraitConflict.fromJson(json);
}

/// @nodoc
mixin _$TraitConflict {
  @JsonKey(name: 'trait_key')
  String get traitKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'conflict_trait_key')
  String get conflictTraitKey => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitConflictCopyWith<TraitConflict> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitConflictCopyWith<$Res> {
  factory $TraitConflictCopyWith(
          TraitConflict value, $Res Function(TraitConflict) then) =
      _$TraitConflictCopyWithImpl<$Res, TraitConflict>;
  @useResult
  $Res call(
      {@JsonKey(name: 'trait_key') String traitKey,
      @JsonKey(name: 'conflict_trait_key') String conflictTraitKey});
}

/// @nodoc
class _$TraitConflictCopyWithImpl<$Res, $Val extends TraitConflict>
    implements $TraitConflictCopyWith<$Res> {
  _$TraitConflictCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? traitKey = null,
    Object? conflictTraitKey = null,
  }) {
    return _then(_value.copyWith(
      traitKey: null == traitKey
          ? _value.traitKey
          : traitKey // ignore: cast_nullable_to_non_nullable
              as String,
      conflictTraitKey: null == conflictTraitKey
          ? _value.conflictTraitKey
          : conflictTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitConflictImplCopyWith<$Res>
    implements $TraitConflictCopyWith<$Res> {
  factory _$$TraitConflictImplCopyWith(
          _$TraitConflictImpl value, $Res Function(_$TraitConflictImpl) then) =
      __$$TraitConflictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'trait_key') String traitKey,
      @JsonKey(name: 'conflict_trait_key') String conflictTraitKey});
}

/// @nodoc
class __$$TraitConflictImplCopyWithImpl<$Res>
    extends _$TraitConflictCopyWithImpl<$Res, _$TraitConflictImpl>
    implements _$$TraitConflictImplCopyWith<$Res> {
  __$$TraitConflictImplCopyWithImpl(
      _$TraitConflictImpl _value, $Res Function(_$TraitConflictImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? traitKey = null,
    Object? conflictTraitKey = null,
  }) {
    return _then(_$TraitConflictImpl(
      traitKey: null == traitKey
          ? _value.traitKey
          : traitKey // ignore: cast_nullable_to_non_nullable
              as String,
      conflictTraitKey: null == conflictTraitKey
          ? _value.conflictTraitKey
          : conflictTraitKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitConflictImpl implements _TraitConflict {
  const _$TraitConflictImpl(
      {@JsonKey(name: 'trait_key') required this.traitKey,
      @JsonKey(name: 'conflict_trait_key') required this.conflictTraitKey});

  factory _$TraitConflictImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitConflictImplFromJson(json);

  @override
  @JsonKey(name: 'trait_key')
  final String traitKey;
  @override
  @JsonKey(name: 'conflict_trait_key')
  final String conflictTraitKey;

  @override
  String toString() {
    return 'TraitConflict(traitKey: $traitKey, conflictTraitKey: $conflictTraitKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitConflictImpl &&
            (identical(other.traitKey, traitKey) ||
                other.traitKey == traitKey) &&
            (identical(other.conflictTraitKey, conflictTraitKey) ||
                other.conflictTraitKey == conflictTraitKey));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, traitKey, conflictTraitKey);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitConflictImplCopyWith<_$TraitConflictImpl> get copyWith =>
      __$$TraitConflictImplCopyWithImpl<_$TraitConflictImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitConflictImplToJson(
      this,
    );
  }
}

abstract class _TraitConflict implements TraitConflict {
  const factory _TraitConflict(
      {@JsonKey(name: 'trait_key') required final String traitKey,
      @JsonKey(name: 'conflict_trait_key')
      required final String conflictTraitKey}) = _$TraitConflictImpl;

  factory _TraitConflict.fromJson(Map<String, dynamic> json) =
      _$TraitConflictImpl.fromJson;

  @override
  @JsonKey(name: 'trait_key')
  String get traitKey;
  @override
  @JsonKey(name: 'conflict_trait_key')
  String get conflictTraitKey;
  @override
  @JsonKey(ignore: true)
  _$$TraitConflictImplCopyWith<_$TraitConflictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
