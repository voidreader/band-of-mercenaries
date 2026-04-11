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
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_type')
  String get effectType => throw _privateConstructorUsedError;
  double get value => throw _privateConstructorUsedError;

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
      {String id,
      String name,
      @JsonKey(name: 'effect_type') String effectType,
      double value});
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
    Object? id = null,
    Object? name = null,
    Object? effectType = null,
    Object? value = null,
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
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
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
      {String id,
      String name,
      @JsonKey(name: 'effect_type') String effectType,
      double value});
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
    Object? id = null,
    Object? name = null,
    Object? effectType = null,
    Object? value = null,
  }) {
    return _then(_$TraitDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitDataImpl implements _TraitData {
  const _$TraitDataImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'effect_type') required this.effectType,
      required this.value});

  factory _$TraitDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'effect_type')
  final String effectType;
  @override
  final double value;

  @override
  String toString() {
    return 'TraitData(id: $id, name: $name, effectType: $effectType, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.effectType, effectType) ||
                other.effectType == effectType) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, effectType, value);

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
      {required final String id,
      required final String name,
      @JsonKey(name: 'effect_type') required final String effectType,
      required final double value}) = _$TraitDataImpl;

  factory _TraitData.fromJson(Map<String, dynamic> json) =
      _$TraitDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'effect_type')
  String get effectType;
  @override
  double get value;
  @override
  @JsonKey(ignore: true)
  _$$TraitDataImplCopyWith<_$TraitDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TraitDataList _$TraitDataListFromJson(Map<String, dynamic> json) {
  return _TraitDataList.fromJson(json);
}

/// @nodoc
mixin _$TraitDataList {
  @JsonKey(name: 'Traits')
  List<TraitData> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TraitDataListCopyWith<TraitDataList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TraitDataListCopyWith<$Res> {
  factory $TraitDataListCopyWith(
          TraitDataList value, $Res Function(TraitDataList) then) =
      _$TraitDataListCopyWithImpl<$Res, TraitDataList>;
  @useResult
  $Res call({@JsonKey(name: 'Traits') List<TraitData> items});
}

/// @nodoc
class _$TraitDataListCopyWithImpl<$Res, $Val extends TraitDataList>
    implements $TraitDataListCopyWith<$Res> {
  _$TraitDataListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TraitData>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TraitDataListImplCopyWith<$Res>
    implements $TraitDataListCopyWith<$Res> {
  factory _$$TraitDataListImplCopyWith(
          _$TraitDataListImpl value, $Res Function(_$TraitDataListImpl) then) =
      __$$TraitDataListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Traits') List<TraitData> items});
}

/// @nodoc
class __$$TraitDataListImplCopyWithImpl<$Res>
    extends _$TraitDataListCopyWithImpl<$Res, _$TraitDataListImpl>
    implements _$$TraitDataListImplCopyWith<$Res> {
  __$$TraitDataListImplCopyWithImpl(
      _$TraitDataListImpl _value, $Res Function(_$TraitDataListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$TraitDataListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TraitData>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TraitDataListImpl implements _TraitDataList {
  const _$TraitDataListImpl(
      {@JsonKey(name: 'Traits') required final List<TraitData> items})
      : _items = items;

  factory _$TraitDataListImpl.fromJson(Map<String, dynamic> json) =>
      _$$TraitDataListImplFromJson(json);

  final List<TraitData> _items;
  @override
  @JsonKey(name: 'Traits')
  List<TraitData> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'TraitDataList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TraitDataListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TraitDataListImplCopyWith<_$TraitDataListImpl> get copyWith =>
      __$$TraitDataListImplCopyWithImpl<_$TraitDataListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TraitDataListImplToJson(
      this,
    );
  }
}

abstract class _TraitDataList implements TraitDataList {
  const factory _TraitDataList(
          {@JsonKey(name: 'Traits') required final List<TraitData> items}) =
      _$TraitDataListImpl;

  factory _TraitDataList.fromJson(Map<String, dynamic> json) =
      _$TraitDataListImpl.fromJson;

  @override
  @JsonKey(name: 'Traits')
  List<TraitData> get items;
  @override
  @JsonKey(ignore: true)
  _$$TraitDataListImplCopyWith<_$TraitDataListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
