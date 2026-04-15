// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region_discovery_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RegionDiscoveryData _$RegionDiscoveryDataFromJson(Map<String, dynamic> json) {
  return _RegionDiscoveryData.fromJson(json);
}

/// @nodoc
mixin _$RegionDiscoveryData {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_id')
  int get regionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'knowledge_threshold')
  int get knowledgeThreshold => throw _privateConstructorUsedError;
  @JsonKey(name: 'discovery_type')
  String get discoveryType => throw _privateConstructorUsedError;
  @JsonKey(name: 'discovery_data')
  Map<String, dynamic>? get discoveryData => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RegionDiscoveryDataCopyWith<RegionDiscoveryData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionDiscoveryDataCopyWith<$Res> {
  factory $RegionDiscoveryDataCopyWith(
          RegionDiscoveryData value, $Res Function(RegionDiscoveryData) then) =
      _$RegionDiscoveryDataCopyWithImpl<$Res, RegionDiscoveryData>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'region_id') int regionId,
      @JsonKey(name: 'knowledge_threshold') int knowledgeThreshold,
      @JsonKey(name: 'discovery_type') String discoveryType,
      @JsonKey(name: 'discovery_data') Map<String, dynamic>? discoveryData,
      String description});
}

/// @nodoc
class _$RegionDiscoveryDataCopyWithImpl<$Res, $Val extends RegionDiscoveryData>
    implements $RegionDiscoveryDataCopyWith<$Res> {
  _$RegionDiscoveryDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? regionId = null,
    Object? knowledgeThreshold = null,
    Object? discoveryType = null,
    Object? discoveryData = freezed,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      knowledgeThreshold: null == knowledgeThreshold
          ? _value.knowledgeThreshold
          : knowledgeThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      discoveryType: null == discoveryType
          ? _value.discoveryType
          : discoveryType // ignore: cast_nullable_to_non_nullable
              as String,
      discoveryData: freezed == discoveryData
          ? _value.discoveryData
          : discoveryData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegionDiscoveryDataImplCopyWith<$Res>
    implements $RegionDiscoveryDataCopyWith<$Res> {
  factory _$$RegionDiscoveryDataImplCopyWith(_$RegionDiscoveryDataImpl value,
          $Res Function(_$RegionDiscoveryDataImpl) then) =
      __$$RegionDiscoveryDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'region_id') int regionId,
      @JsonKey(name: 'knowledge_threshold') int knowledgeThreshold,
      @JsonKey(name: 'discovery_type') String discoveryType,
      @JsonKey(name: 'discovery_data') Map<String, dynamic>? discoveryData,
      String description});
}

/// @nodoc
class __$$RegionDiscoveryDataImplCopyWithImpl<$Res>
    extends _$RegionDiscoveryDataCopyWithImpl<$Res, _$RegionDiscoveryDataImpl>
    implements _$$RegionDiscoveryDataImplCopyWith<$Res> {
  __$$RegionDiscoveryDataImplCopyWithImpl(_$RegionDiscoveryDataImpl _value,
      $Res Function(_$RegionDiscoveryDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? regionId = null,
    Object? knowledgeThreshold = null,
    Object? discoveryType = null,
    Object? discoveryData = freezed,
    Object? description = null,
  }) {
    return _then(_$RegionDiscoveryDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      knowledgeThreshold: null == knowledgeThreshold
          ? _value.knowledgeThreshold
          : knowledgeThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      discoveryType: null == discoveryType
          ? _value.discoveryType
          : discoveryType // ignore: cast_nullable_to_non_nullable
              as String,
      discoveryData: freezed == discoveryData
          ? _value._discoveryData
          : discoveryData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionDiscoveryDataImpl implements _RegionDiscoveryData {
  const _$RegionDiscoveryDataImpl(
      {required this.id,
      @JsonKey(name: 'region_id') required this.regionId,
      @JsonKey(name: 'knowledge_threshold') required this.knowledgeThreshold,
      @JsonKey(name: 'discovery_type') required this.discoveryType,
      @JsonKey(name: 'discovery_data')
      final Map<String, dynamic>? discoveryData,
      required this.description})
      : _discoveryData = discoveryData;

  factory _$RegionDiscoveryDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionDiscoveryDataImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'region_id')
  final int regionId;
  @override
  @JsonKey(name: 'knowledge_threshold')
  final int knowledgeThreshold;
  @override
  @JsonKey(name: 'discovery_type')
  final String discoveryType;
  final Map<String, dynamic>? _discoveryData;
  @override
  @JsonKey(name: 'discovery_data')
  Map<String, dynamic>? get discoveryData {
    final value = _discoveryData;
    if (value == null) return null;
    if (_discoveryData is EqualUnmodifiableMapView) return _discoveryData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String description;

  @override
  String toString() {
    return 'RegionDiscoveryData(id: $id, regionId: $regionId, knowledgeThreshold: $knowledgeThreshold, discoveryType: $discoveryType, discoveryData: $discoveryData, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionDiscoveryDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.knowledgeThreshold, knowledgeThreshold) ||
                other.knowledgeThreshold == knowledgeThreshold) &&
            (identical(other.discoveryType, discoveryType) ||
                other.discoveryType == discoveryType) &&
            const DeepCollectionEquality()
                .equals(other._discoveryData, _discoveryData) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      regionId,
      knowledgeThreshold,
      discoveryType,
      const DeepCollectionEquality().hash(_discoveryData),
      description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionDiscoveryDataImplCopyWith<_$RegionDiscoveryDataImpl> get copyWith =>
      __$$RegionDiscoveryDataImplCopyWithImpl<_$RegionDiscoveryDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionDiscoveryDataImplToJson(
      this,
    );
  }
}

abstract class _RegionDiscoveryData implements RegionDiscoveryData {
  const factory _RegionDiscoveryData(
      {required final String id,
      @JsonKey(name: 'region_id') required final int regionId,
      @JsonKey(name: 'knowledge_threshold')
      required final int knowledgeThreshold,
      @JsonKey(name: 'discovery_type') required final String discoveryType,
      @JsonKey(name: 'discovery_data')
      final Map<String, dynamic>? discoveryData,
      required final String description}) = _$RegionDiscoveryDataImpl;

  factory _RegionDiscoveryData.fromJson(Map<String, dynamic> json) =
      _$RegionDiscoveryDataImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'region_id')
  int get regionId;
  @override
  @JsonKey(name: 'knowledge_threshold')
  int get knowledgeThreshold;
  @override
  @JsonKey(name: 'discovery_type')
  String get discoveryType;
  @override
  @JsonKey(name: 'discovery_data')
  Map<String, dynamic>? get discoveryData;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$RegionDiscoveryDataImplCopyWith<_$RegionDiscoveryDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
