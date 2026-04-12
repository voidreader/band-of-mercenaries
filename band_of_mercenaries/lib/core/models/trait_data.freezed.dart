// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trait_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TraitData _$TraitDataFromJson(Map<String, dynamic> json) {
  return _TraitData.fromJson(json);
}

/// @nodoc
mixin _$TraitData {
  String get key => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_key')
  String get categoryKey => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_text')
  String get effectText => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitDataCopyWith<TraitData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitDataCopyWith<$Res> {
  factory $TraitDataCopyWith(TraitData value, $Res Function(TraitData) then) =
      _$TraitDataCopyWithImpl<$Res, TraitData>;
  @useResult
  $Res call(
      {String key,
      String name,
      @JsonKey(name: 'category_key') String categoryKey,
      String type,
      String description,
      @JsonKey(name: 'effect_text') String effectText});
}

/// @nodoc
class _$TraitDataCopyWithImpl<$Res, $Val extends TraitData>
    implements $TraitDataCopyWith<$Res> {
  _$TraitDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? name = null,
    Object? categoryKey = null,
    Object? type = null,
    Object? description = null,
    Object? effectText = null,
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
      categoryKey: null == categoryKey
          ? _value.categoryKey
          : categoryKey // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      effectText: null == effectText
          ? _value.effectText
          : effectText // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitDataImplCopyWith<$Res>
    implements $TraitDataCopyWith<$Res> {
  factory _$$TraitDataImplCopyWith(
          _$TraitDataImpl value, $Res Function(_$TraitDataImpl) then) =
      __$$TraitDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String key,
      String name,
      @JsonKey(name: 'category_key') String categoryKey,
      String type,
      String description,
      @JsonKey(name: 'effect_text') String effectText});
}

/// @nodoc
class __$$TraitDataImplCopyWithImpl<$Res>
    extends _$TraitDataCopyWithImpl<$Res, _$TraitDataImpl>
    implements _$$TraitDataImplCopyWith<$Res> {
  __$$TraitDataImplCopyWithImpl(
      _$TraitDataImpl _value, $Res Function(_$TraitDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? name = null,
    Object? categoryKey = null,
    Object? type = null,
    Object? description = null,
    Object? effectText = null,
  }) {
    return _then(_$TraitDataImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categoryKey: null == categoryKey
          ? _value.categoryKey
          : categoryKey // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      effectText: null == effectText
          ? _value.effectText
          : effectText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitDataImpl implements _TraitData {
  const _$TraitDataImpl(
      {required this.key,
      required this.name,
      @JsonKey(name: 'category_key') required this.categoryKey,
      required this.type,
      this.description = '',
      @JsonKey(name: 'effect_text') this.effectText = ''});

  factory _$TraitDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitDataImplFromJson(json);

  @override
  final String key;
  @override
  final String name;
  @override
  @JsonKey(name: 'category_key')
  final String categoryKey;
  @override
  final String type;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'effect_text')
  final String effectText;

  @override
  String toString() {
    return 'TraitData(key: $key, name: $name, categoryKey: $categoryKey, type: $type, description: $description, effectText: $effectText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitDataImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryKey, categoryKey) ||
                other.categoryKey == categoryKey) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.effectText, effectText) ||
                other.effectText == effectText));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, key, name, categoryKey, type, description, effectText);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitDataImplCopyWith<_$TraitDataImpl> get copyWith =>
      __$$TraitDataImplCopyWithImpl<_$TraitDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitDataImplToJson(
      this,
    );
  }
}

abstract class _TraitData implements TraitData {
  const factory _TraitData(
      {required final String key,
      required final String name,
      @JsonKey(name: 'category_key') required final String categoryKey,
      required final String type,
      final String description,
      @JsonKey(name: 'effect_text') final String effectText}) = _$TraitDataImpl;

  factory _TraitData.fromJson(Map<String, dynamic> json) =
      _$TraitDataImpl.fromJson;

  @override
  String get key;
  @override
  String get name;
  @override
  @JsonKey(name: 'category_key')
  String get categoryKey;
  @override
  String get type;
  @override
  String get description;
  @override
  @JsonKey(name: 'effect_text')
  String get effectText;
  @override
  @JsonKey(ignore: true)
  _$$TraitDataImplCopyWith<_$TraitDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
