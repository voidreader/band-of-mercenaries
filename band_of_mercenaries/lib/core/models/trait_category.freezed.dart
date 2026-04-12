// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trait_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TraitCategory _$TraitCategoryFromJson(Map<String, dynamic> json) {
  return _TraitCategory.fromJson(json);
}

/// @nodoc
mixin _$TraitCategory {
  String get key => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'slot_type')
  String get slotType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitCategoryCopyWith<TraitCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitCategoryCopyWith<$Res> {
  factory $TraitCategoryCopyWith(
          TraitCategory value, $Res Function(TraitCategory) then) =
      _$TraitCategoryCopyWithImpl<$Res, TraitCategory>;
  @useResult
  $Res call(
      {String key, String name, @JsonKey(name: 'slot_type') String slotType});
}

/// @nodoc
class _$TraitCategoryCopyWithImpl<$Res, $Val extends TraitCategory>
    implements $TraitCategoryCopyWith<$Res> {
  _$TraitCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? name = null,
    Object? slotType = null,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slotType: null == slotType
          ? _value.slotType
          : slotType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitCategoryImplCopyWith<$Res>
    implements $TraitCategoryCopyWith<$Res> {
  factory _$$TraitCategoryImplCopyWith(
          _$TraitCategoryImpl value, $Res Function(_$TraitCategoryImpl) then) =
      __$$TraitCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String key, String name, @JsonKey(name: 'slot_type') String slotType});
}

/// @nodoc
class __$$TraitCategoryImplCopyWithImpl<$Res>
    extends _$TraitCategoryCopyWithImpl<$Res, _$TraitCategoryImpl>
    implements _$$TraitCategoryImplCopyWith<$Res> {
  __$$TraitCategoryImplCopyWithImpl(
      _$TraitCategoryImpl _value, $Res Function(_$TraitCategoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? name = null,
    Object? slotType = null,
  }) {
    return _then(_$TraitCategoryImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slotType: null == slotType
          ? _value.slotType
          : slotType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitCategoryImpl implements _TraitCategory {
  const _$TraitCategoryImpl(
      {required this.key,
      required this.name,
      @JsonKey(name: 'slot_type') required this.slotType});

  factory _$TraitCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitCategoryImplFromJson(json);

  @override
  final String key;
  @override
  final String name;
  @override
  @JsonKey(name: 'slot_type')
  final String slotType;

  @override
  String toString() {
    return 'TraitCategory(key: $key, name: $name, slotType: $slotType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitCategoryImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slotType, slotType) ||
                other.slotType == slotType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, name, slotType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitCategoryImplCopyWith<_$TraitCategoryImpl> get copyWith =>
      __$$TraitCategoryImplCopyWithImpl<_$TraitCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitCategoryImplToJson(
      this,
    );
  }
}

abstract class _TraitCategory implements TraitCategory {
  const factory _TraitCategory(
          {required final String key,
          required final String name,
          @JsonKey(name: 'slot_type') required final String slotType}) =
      _$TraitCategoryImpl;

  factory _TraitCategory.fromJson(Map<String, dynamic> json) =
      _$TraitCategoryImpl.fromJson;

  @override
  String get key;
  @override
  String get name;
  @override
  @JsonKey(name: 'slot_type')
  String get slotType;
  @override
  @JsonKey(ignore: true)
  _$$TraitCategoryImplCopyWith<_$TraitCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
