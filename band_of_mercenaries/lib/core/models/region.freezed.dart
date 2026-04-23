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
  int get continent => throw _privateConstructorUsedError;
  int get region => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_name')
  String get regionName => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_tier')
  int get regionTier => throw _privateConstructorUsedError;
  @JsonKey(name: 'recommend_power')
  int get recommendPower => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags => throw _privateConstructorUsedError;

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
      {int continent,
      int region,
      @JsonKey(name: 'region_name') String regionName,
      @JsonKey(name: 'region_tier') int regionTier,
      @JsonKey(name: 'recommend_power') int recommendPower,
      String description,
      @JsonKey(name: 'environment_tags') List<String> environmentTags});
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
    Object? description = null,
    Object? environmentTags = null,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      environmentTags: null == environmentTags
          ? _value.environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      {int continent,
      int region,
      @JsonKey(name: 'region_name') String regionName,
      @JsonKey(name: 'region_tier') int regionTier,
      @JsonKey(name: 'recommend_power') int recommendPower,
      String description,
      @JsonKey(name: 'environment_tags') List<String> environmentTags});
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
    Object? description = null,
    Object? environmentTags = null,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      environmentTags: null == environmentTags
          ? _value._environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionImpl implements _Region {
  const _$RegionImpl(
      {required this.continent,
      required this.region,
      @JsonKey(name: 'region_name') required this.regionName,
      @JsonKey(name: 'region_tier') required this.regionTier,
      @JsonKey(name: 'recommend_power') required this.recommendPower,
      required this.description,
      @JsonKey(name: 'environment_tags')
      final List<String> environmentTags = const <String>[]})
      : _environmentTags = environmentTags;

  factory _$RegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionImplFromJson(json);

  @override
  final int continent;
  @override
  final int region;
  @override
  @JsonKey(name: 'region_name')
  final String regionName;
  @override
  @JsonKey(name: 'region_tier')
  final int regionTier;
  @override
  @JsonKey(name: 'recommend_power')
  final int recommendPower;
  @override
  final String description;
  final List<String> _environmentTags;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags {
    if (_environmentTags is EqualUnmodifiableListView) return _environmentTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_environmentTags);
  }

  @override
  String toString() {
    return 'Region(continent: $continent, region: $region, regionName: $regionName, regionTier: $regionTier, recommendPower: $recommendPower, description: $description, environmentTags: $environmentTags)';
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
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._environmentTags, _environmentTags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      continent,
      region,
      regionName,
      regionTier,
      recommendPower,
      description,
      const DeepCollectionEquality().hash(_environmentTags));

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
      {required final int continent,
      required final int region,
      @JsonKey(name: 'region_name') required final String regionName,
      @JsonKey(name: 'region_tier') required final int regionTier,
      @JsonKey(name: 'recommend_power') required final int recommendPower,
      required final String description,
      @JsonKey(name: 'environment_tags')
      final List<String> environmentTags}) = _$RegionImpl;

  factory _Region.fromJson(Map<String, dynamic> json) = _$RegionImpl.fromJson;

  @override
  int get continent;
  @override
  int get region;
  @override
  @JsonKey(name: 'region_name')
  String get regionName;
  @override
  @JsonKey(name: 'region_tier')
  int get regionTier;
  @override
  @JsonKey(name: 'recommend_power')
  int get recommendPower;
  @override
  String get description;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags;
  @override
  @JsonKey(ignore: true)
  _$$RegionImplCopyWith<_$RegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
