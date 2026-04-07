// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Region _$RegionFromJson(Map<String, dynamic> json) {
  return _Region.fromJson(json);
}

/// @nodoc
mixin _$Region {
  @JsonKey(name: 'Continent')
  int get continent => throw _privateConstructorUsedError;
  @JsonKey(name: 'Region')
  int get region => throw _privateConstructorUsedError;
  @JsonKey(name: 'RegionName')
  String get regionName => throw _privateConstructorUsedError;
  @JsonKey(name: 'RegionTier')
  int get regionTier => throw _privateConstructorUsedError;
  @JsonKey(name: 'RecommendPower')
  int get recommendPower => throw _privateConstructorUsedError;
  @JsonKey(name: 'Desc')
  String get desc => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RegionCopyWith<Region> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionCopyWith<$Res> {
  factory $RegionCopyWith(Region value, $Res Function(Region) then) =
      _$RegionCopyWithImpl<$Res, Region>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Continent') int continent,
      @JsonKey(name: 'Region') int region,
      @JsonKey(name: 'RegionName') String regionName,
      @JsonKey(name: 'RegionTier') int regionTier,
      @JsonKey(name: 'RecommendPower') int recommendPower,
      @JsonKey(name: 'Desc') String desc});
}

/// @nodoc
class _$RegionCopyWithImpl<$Res, $Val extends Region>
    implements $RegionCopyWith<$Res> {
  _$RegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? continent = null,
    Object? region = null,
    Object? regionName = null,
    Object? regionTier = null,
    Object? recommendPower = null,
    Object? desc = null,
  }) {
    return _then(_value.copyWith(
      continent: null == continent
          ? _value.continent
          : continent // ignore: cast_nullable_to_non_nullable
              as int,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as int,
      regionName: null == regionName
          ? _value.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String,
      regionTier: null == regionTier
          ? _value.regionTier
          : regionTier // ignore: cast_nullable_to_non_nullable
              as int,
      recommendPower: null == recommendPower
          ? _value.recommendPower
          : recommendPower // ignore: cast_nullable_to_non_nullable
              as int,
      desc: null == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegionImplCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$$RegionImplCopyWith(
          _$RegionImpl value, $Res Function(_$RegionImpl) then) =
      __$$RegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Continent') int continent,
      @JsonKey(name: 'Region') int region,
      @JsonKey(name: 'RegionName') String regionName,
      @JsonKey(name: 'RegionTier') int regionTier,
      @JsonKey(name: 'RecommendPower') int recommendPower,
      @JsonKey(name: 'Desc') String desc});
}

/// @nodoc
class __$$RegionImplCopyWithImpl<$Res>
    extends _$RegionCopyWithImpl<$Res, _$RegionImpl>
    implements _$$RegionImplCopyWith<$Res> {
  __$$RegionImplCopyWithImpl(
      _$RegionImpl _value, $Res Function(_$RegionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? continent = null,
    Object? region = null,
    Object? regionName = null,
    Object? regionTier = null,
    Object? recommendPower = null,
    Object? desc = null,
  }) {
    return _then(_$RegionImpl(
      continent: null == continent
          ? _value.continent
          : continent // ignore: cast_nullable_to_non_nullable
              as int,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as int,
      regionName: null == regionName
          ? _value.regionName
          : regionName // ignore: cast_nullable_to_non_nullable
              as String,
      regionTier: null == regionTier
          ? _value.regionTier
          : regionTier // ignore: cast_nullable_to_non_nullable
              as int,
      recommendPower: null == recommendPower
          ? _value.recommendPower
          : recommendPower // ignore: cast_nullable_to_non_nullable
              as int,
      desc: null == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionImpl implements _Region {
  const _$RegionImpl(
      {@JsonKey(name: 'Continent') required this.continent,
      @JsonKey(name: 'Region') required this.region,
      @JsonKey(name: 'RegionName') required this.regionName,
      @JsonKey(name: 'RegionTier') required this.regionTier,
      @JsonKey(name: 'RecommendPower') required this.recommendPower,
      @JsonKey(name: 'Desc') required this.desc});

  factory _$RegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionImplFromJson(json);

  @override
  @JsonKey(name: 'Continent')
  final int continent;
  @override
  @JsonKey(name: 'Region')
  final int region;
  @override
  @JsonKey(name: 'RegionName')
  final String regionName;
  @override
  @JsonKey(name: 'RegionTier')
  final int regionTier;
  @override
  @JsonKey(name: 'RecommendPower')
  final int recommendPower;
  @override
  @JsonKey(name: 'Desc')
  final String desc;

  @override
  String toString() {
    return 'Region(continent: $continent, region: $region, regionName: $regionName, regionTier: $regionTier, recommendPower: $recommendPower, desc: $desc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionImpl &&
            (identical(other.continent, continent) ||
                other.continent == continent) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.regionName, regionName) ||
                other.regionName == regionName) &&
            (identical(other.regionTier, regionTier) ||
                other.regionTier == regionTier) &&
            (identical(other.recommendPower, recommendPower) ||
                other.recommendPower == recommendPower) &&
            (identical(other.desc, desc) || other.desc == desc));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, continent, region, regionName,
      regionTier, recommendPower, desc);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionImplCopyWith<_$RegionImpl> get copyWith =>
      __$$RegionImplCopyWithImpl<_$RegionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionImplToJson(
      this,
    );
  }
}

abstract class _Region implements Region {
  const factory _Region(
      {@JsonKey(name: 'Continent') required final int continent,
      @JsonKey(name: 'Region') required final int region,
      @JsonKey(name: 'RegionName') required final String regionName,
      @JsonKey(name: 'RegionTier') required final int regionTier,
      @JsonKey(name: 'RecommendPower') required final int recommendPower,
      @JsonKey(name: 'Desc') required final String desc}) = _$RegionImpl;

  factory _Region.fromJson(Map<String, dynamic> json) = _$RegionImpl.fromJson;

  @override
  @JsonKey(name: 'Continent')
  int get continent;
  @override
  @JsonKey(name: 'Region')
  int get region;
  @override
  @JsonKey(name: 'RegionName')
  String get regionName;
  @override
  @JsonKey(name: 'RegionTier')
  int get regionTier;
  @override
  @JsonKey(name: 'RecommendPower')
  int get recommendPower;
  @override
  @JsonKey(name: 'Desc')
  String get desc;
  @override
  @JsonKey(ignore: true)
  _$$RegionImplCopyWith<_$RegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegionList _$RegionListFromJson(Map<String, dynamic> json) {
  return _RegionList.fromJson(json);
}

/// @nodoc
mixin _$RegionList {
  @JsonKey(name: 'Regions')
  List<Region> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RegionListCopyWith<RegionList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionListCopyWith<$Res> {
  factory $RegionListCopyWith(
          RegionList value, $Res Function(RegionList) then) =
      _$RegionListCopyWithImpl<$Res, RegionList>;
  @useResult
  $Res call({@JsonKey(name: 'Regions') List<Region> items});
}

/// @nodoc
class _$RegionListCopyWithImpl<$Res, $Val extends RegionList>
    implements $RegionListCopyWith<$Res> {
  _$RegionListCopyWithImpl(this._value, this._then);

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
              as List<Region>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegionListImplCopyWith<$Res>
    implements $RegionListCopyWith<$Res> {
  factory _$$RegionListImplCopyWith(
          _$RegionListImpl value, $Res Function(_$RegionListImpl) then) =
      __$$RegionListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Regions') List<Region> items});
}

/// @nodoc
class __$$RegionListImplCopyWithImpl<$Res>
    extends _$RegionListCopyWithImpl<$Res, _$RegionListImpl>
    implements _$$RegionListImplCopyWith<$Res> {
  __$$RegionListImplCopyWithImpl(
      _$RegionListImpl _value, $Res Function(_$RegionListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$RegionListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Region>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionListImpl implements _RegionList {
  const _$RegionListImpl(
      {@JsonKey(name: 'Regions') required final List<Region> items})
      : _items = items;

  factory _$RegionListImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionListImplFromJson(json);

  final List<Region> _items;
  @override
  @JsonKey(name: 'Regions')
  List<Region> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'RegionList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionListImplCopyWith<_$RegionListImpl> get copyWith =>
      __$$RegionListImplCopyWithImpl<_$RegionListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionListImplToJson(
      this,
    );
  }
}

abstract class _RegionList implements RegionList {
  const factory _RegionList(
          {@JsonKey(name: 'Regions') required final List<Region> items}) =
      _$RegionListImpl;

  factory _RegionList.fromJson(Map<String, dynamic> json) =
      _$RegionListImpl.fromJson;

  @override
  @JsonKey(name: 'Regions')
  List<Region> get items;
  @override
  @JsonKey(ignore: true)
  _$$RegionListImplCopyWith<_$RegionListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
