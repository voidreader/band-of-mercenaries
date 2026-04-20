// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItemData _$ItemDataFromJson(Map<String, dynamic> json) {
  return _ItemData.fromJson(json);
}

/// @nodoc
mixin _$ItemData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'flavor_text')
  String get flavorText => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get slot => throw _privateConstructorUsedError;
  int get tier => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_json')
  Map<String, dynamic> get effectJson => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemDataCopyWith<ItemData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemDataCopyWith<$Res> {
  factory $ItemDataCopyWith(ItemData value, $Res Function(ItemData) then) =
      _$ItemDataCopyWithImpl<$Res, ItemData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'flavor_text') String flavorText,
      String category,
      String slot,
      int tier,
      @JsonKey(name: 'effect_json') Map<String, dynamic> effectJson,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$ItemDataCopyWithImpl<$Res, $Val extends ItemData>
    implements $ItemDataCopyWith<$Res> {
  _$ItemDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? flavorText = null,
    Object? category = null,
    Object? slot = null,
    Object? tier = null,
    Object? effectJson = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      flavorText: null == flavorText
          ? _value.flavorText
          : flavorText // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      effectJson: null == effectJson
          ? _value.effectJson
          : effectJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemDataImplCopyWith<$Res>
    implements $ItemDataCopyWith<$Res> {
  factory _$$ItemDataImplCopyWith(
          _$ItemDataImpl value, $Res Function(_$ItemDataImpl) then) =
      __$$ItemDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'flavor_text') String flavorText,
      String category,
      String slot,
      int tier,
      @JsonKey(name: 'effect_json') Map<String, dynamic> effectJson,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$ItemDataImplCopyWithImpl<$Res>
    extends _$ItemDataCopyWithImpl<$Res, _$ItemDataImpl>
    implements _$$ItemDataImplCopyWith<$Res> {
  __$$ItemDataImplCopyWithImpl(
      _$ItemDataImpl _value, $Res Function(_$ItemDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? flavorText = null,
    Object? category = null,
    Object? slot = null,
    Object? tier = null,
    Object? effectJson = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$ItemDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      flavorText: null == flavorText
          ? _value.flavorText
          : flavorText // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      effectJson: null == effectJson
          ? _value._effectJson
          : effectJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemDataImpl implements _ItemData {
  const _$ItemDataImpl(
      {required this.id,
      required this.name,
      this.description = '',
      @JsonKey(name: 'flavor_text') this.flavorText = '',
      required this.category,
      required this.slot,
      required this.tier,
      @JsonKey(name: 'effect_json')
      final Map<String, dynamic> effectJson = const <String, dynamic>{},
      @JsonKey(name: 'created_at') this.createdAt})
      : _effectJson = effectJson;

  factory _$ItemDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'flavor_text')
  final String flavorText;
  @override
  final String category;
  @override
  final String slot;
  @override
  final int tier;
  final Map<String, dynamic> _effectJson;
  @override
  @JsonKey(name: 'effect_json')
  Map<String, dynamic> get effectJson {
    if (_effectJson is EqualUnmodifiableMapView) return _effectJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_effectJson);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ItemData(id: $id, name: $name, description: $description, flavorText: $flavorText, category: $category, slot: $slot, tier: $tier, effectJson: $effectJson, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.flavorText, flavorText) ||
                other.flavorText == flavorText) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            const DeepCollectionEquality()
                .equals(other._effectJson, _effectJson) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      flavorText,
      category,
      slot,
      tier,
      const DeepCollectionEquality().hash(_effectJson),
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemDataImplCopyWith<_$ItemDataImpl> get copyWith =>
      __$$ItemDataImplCopyWithImpl<_$ItemDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemDataImplToJson(
      this,
    );
  }
}

abstract class _ItemData implements ItemData {
  const factory _ItemData(
      {required final String id,
      required final String name,
      final String description,
      @JsonKey(name: 'flavor_text') final String flavorText,
      required final String category,
      required final String slot,
      required final int tier,
      @JsonKey(name: 'effect_json') final Map<String, dynamic> effectJson,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$ItemDataImpl;

  factory _ItemData.fromJson(Map<String, dynamic> json) =
      _$ItemDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'flavor_text')
  String get flavorText;
  @override
  String get category;
  @override
  String get slot;
  @override
  int get tier;
  @override
  @JsonKey(name: 'effect_json')
  Map<String, dynamic> get effectJson;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ItemDataImplCopyWith<_$ItemDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
