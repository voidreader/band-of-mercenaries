// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'facility.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Facility _$FacilityFromJson(Map<String, dynamic> json) {
  return _Facility.fromJson(json);
}

/// @nodoc
mixin _$Facility {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_type')
  String get effectType => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_level')
  int get maxLevel => throw _privateConstructorUsedError;
  List<int> get costs => throw _privateConstructorUsedError;
  List<double> get values => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FacilityCopyWith<Facility> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FacilityCopyWith<$Res> {
  factory $FacilityCopyWith(Facility value, $Res Function(Facility) then) =
      _$FacilityCopyWithImpl<$Res, Facility>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'effect_type') String effectType,
      @JsonKey(name: 'max_level') int maxLevel,
      List<int> costs,
      List<double> values});
}

/// @nodoc
class _$FacilityCopyWithImpl<$Res, $Val extends Facility>
    implements $FacilityCopyWith<$Res> {
  _$FacilityCopyWithImpl(this._value, this._then);

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
    Object? maxLevel = null,
    Object? costs = null,
    Object? values = null,
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
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      costs: null == costs
          ? _value.costs
          : costs // ignore: cast_nullable_to_non_nullable
              as List<int>,
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<double>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FacilityImplCopyWith<$Res>
    implements $FacilityCopyWith<$Res> {
  factory _$$FacilityImplCopyWith(
          _$FacilityImpl value, $Res Function(_$FacilityImpl) then) =
      __$$FacilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'effect_type') String effectType,
      @JsonKey(name: 'max_level') int maxLevel,
      List<int> costs,
      List<double> values});
}

/// @nodoc
class __$$FacilityImplCopyWithImpl<$Res>
    extends _$FacilityCopyWithImpl<$Res, _$FacilityImpl>
    implements _$$FacilityImplCopyWith<$Res> {
  __$$FacilityImplCopyWithImpl(
      _$FacilityImpl _value, $Res Function(_$FacilityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? effectType = null,
    Object? maxLevel = null,
    Object? costs = null,
    Object? values = null,
  }) {
    return _then(_$FacilityImpl(
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
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      costs: null == costs
          ? _value._costs
          : costs // ignore: cast_nullable_to_non_nullable
              as List<int>,
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<double>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FacilityImpl implements _Facility {
  const _$FacilityImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'effect_type') required this.effectType,
      @JsonKey(name: 'max_level') required this.maxLevel,
      required final List<int> costs,
      required final List<double> values})
      : _costs = costs,
        _values = values;

  factory _$FacilityImpl.fromJson(Map<String, dynamic> json) =>
      _$$FacilityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'effect_type')
  final String effectType;
  @override
  @JsonKey(name: 'max_level')
  final int maxLevel;
  final List<int> _costs;
  @override
  List<int> get costs {
    if (_costs is EqualUnmodifiableListView) return _costs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_costs);
  }

  final List<double> _values;
  @override
  List<double> get values {
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_values);
  }

  @override
  String toString() {
    return 'Facility(id: $id, name: $name, effectType: $effectType, maxLevel: $maxLevel, costs: $costs, values: $values)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FacilityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.effectType, effectType) ||
                other.effectType == effectType) &&
            (identical(other.maxLevel, maxLevel) ||
                other.maxLevel == maxLevel) &&
            const DeepCollectionEquality().equals(other._costs, _costs) &&
            const DeepCollectionEquality().equals(other._values, _values));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      effectType,
      maxLevel,
      const DeepCollectionEquality().hash(_costs),
      const DeepCollectionEquality().hash(_values));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FacilityImplCopyWith<_$FacilityImpl> get copyWith =>
      __$$FacilityImplCopyWithImpl<_$FacilityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FacilityImplToJson(
      this,
    );
  }
}

abstract class _Facility implements Facility {
  const factory _Facility(
      {required final String id,
      required final String name,
      @JsonKey(name: 'effect_type') required final String effectType,
      @JsonKey(name: 'max_level') required final int maxLevel,
      required final List<int> costs,
      required final List<double> values}) = _$FacilityImpl;

  factory _Facility.fromJson(Map<String, dynamic> json) =
      _$FacilityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'effect_type')
  String get effectType;
  @override
  @JsonKey(name: 'max_level')
  int get maxLevel;
  @override
  List<int> get costs;
  @override
  List<double> get values;
  @override
  @JsonKey(ignore: true)
  _$$FacilityImplCopyWith<_$FacilityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FacilityList _$FacilityListFromJson(Map<String, dynamic> json) {
  return _FacilityList.fromJson(json);
}

/// @nodoc
mixin _$FacilityList {
  @JsonKey(name: 'Facilities')
  List<Facility> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FacilityListCopyWith<FacilityList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FacilityListCopyWith<$Res> {
  factory $FacilityListCopyWith(
          FacilityList value, $Res Function(FacilityList) then) =
      _$FacilityListCopyWithImpl<$Res, FacilityList>;
  @useResult
  $Res call({@JsonKey(name: 'Facilities') List<Facility> items});
}

/// @nodoc
class _$FacilityListCopyWithImpl<$Res, $Val extends FacilityList>
    implements $FacilityListCopyWith<$Res> {
  _$FacilityListCopyWithImpl(this._value, this._then);

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
              as List<Facility>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FacilityListImplCopyWith<$Res>
    implements $FacilityListCopyWith<$Res> {
  factory _$$FacilityListImplCopyWith(
          _$FacilityListImpl value, $Res Function(_$FacilityListImpl) then) =
      __$$FacilityListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Facilities') List<Facility> items});
}

/// @nodoc
class __$$FacilityListImplCopyWithImpl<$Res>
    extends _$FacilityListCopyWithImpl<$Res, _$FacilityListImpl>
    implements _$$FacilityListImplCopyWith<$Res> {
  __$$FacilityListImplCopyWithImpl(
      _$FacilityListImpl _value, $Res Function(_$FacilityListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$FacilityListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Facility>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FacilityListImpl implements _FacilityList {
  const _$FacilityListImpl(
      {@JsonKey(name: 'Facilities') required final List<Facility> items})
      : _items = items;

  factory _$FacilityListImpl.fromJson(Map<String, dynamic> json) =>
      _$$FacilityListImplFromJson(json);

  final List<Facility> _items;
  @override
  @JsonKey(name: 'Facilities')
  List<Facility> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'FacilityList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FacilityListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FacilityListImplCopyWith<_$FacilityListImpl> get copyWith =>
      __$$FacilityListImplCopyWithImpl<_$FacilityListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FacilityListImplToJson(
      this,
    );
  }
}

abstract class _FacilityList implements FacilityList {
  const factory _FacilityList(
          {@JsonKey(name: 'Facilities') required final List<Facility> items}) =
      _$FacilityListImpl;

  factory _FacilityList.fromJson(Map<String, dynamic> json) =
      _$FacilityListImpl.fromJson;

  @override
  @JsonKey(name: 'Facilities')
  List<Facility> get items;
  @override
  @JsonKey(ignore: true)
  _$$FacilityListImplCopyWith<_$FacilityListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
