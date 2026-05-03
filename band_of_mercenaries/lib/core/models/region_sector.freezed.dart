// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region_sector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RegionSector _$RegionSectorFromJson(Map<String, dynamic> json) {
  return _RegionSector.fromJson(json);
}

/// @nodoc
mixin _$RegionSector {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_id')
  int get regionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sector_index')
  int get sectorIndex => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'sector_type')
  String get sectorType => throw _privateConstructorUsedError;
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RegionSectorCopyWith<RegionSector> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionSectorCopyWith<$Res> {
  factory $RegionSectorCopyWith(
          RegionSector value, $Res Function(RegionSector) then) =
      _$RegionSectorCopyWithImpl<$Res, RegionSector>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'region_id') int regionId,
      @JsonKey(name: 'sector_index') int sectorIndex,
      String name,
      @JsonKey(name: 'sector_type') String sectorType,
      @JsonKey(name: 'environment_tags') List<String> environmentTags,
      String? description});
}

/// @nodoc
class _$RegionSectorCopyWithImpl<$Res, $Val extends RegionSector>
    implements $RegionSectorCopyWith<$Res> {
  _$RegionSectorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? regionId = null,
    Object? sectorIndex = null,
    Object? name = null,
    Object? sectorType = null,
    Object? environmentTags = null,
    Object? description = freezed,
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
      sectorIndex: null == sectorIndex
          ? _value.sectorIndex
          : sectorIndex // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sectorType: null == sectorType
          ? _value.sectorType
          : sectorType // ignore: cast_nullable_to_non_nullable
              as String,
      environmentTags: null == environmentTags
          ? _value.environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegionSectorImplCopyWith<$Res>
    implements $RegionSectorCopyWith<$Res> {
  factory _$$RegionSectorImplCopyWith(
          _$RegionSectorImpl value, $Res Function(_$RegionSectorImpl) then) =
      __$$RegionSectorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'region_id') int regionId,
      @JsonKey(name: 'sector_index') int sectorIndex,
      String name,
      @JsonKey(name: 'sector_type') String sectorType,
      @JsonKey(name: 'environment_tags') List<String> environmentTags,
      String? description});
}

/// @nodoc
class __$$RegionSectorImplCopyWithImpl<$Res>
    extends _$RegionSectorCopyWithImpl<$Res, _$RegionSectorImpl>
    implements _$$RegionSectorImplCopyWith<$Res> {
  __$$RegionSectorImplCopyWithImpl(
      _$RegionSectorImpl _value, $Res Function(_$RegionSectorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? regionId = null,
    Object? sectorIndex = null,
    Object? name = null,
    Object? sectorType = null,
    Object? environmentTags = null,
    Object? description = freezed,
  }) {
    return _then(_$RegionSectorImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      sectorIndex: null == sectorIndex
          ? _value.sectorIndex
          : sectorIndex // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sectorType: null == sectorType
          ? _value.sectorType
          : sectorType // ignore: cast_nullable_to_non_nullable
              as String,
      environmentTags: null == environmentTags
          ? _value._environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionSectorImpl implements _RegionSector {
  const _$RegionSectorImpl(
      {required this.id,
      @JsonKey(name: 'region_id') required this.regionId,
      @JsonKey(name: 'sector_index') required this.sectorIndex,
      required this.name,
      @JsonKey(name: 'sector_type') required this.sectorType,
      @JsonKey(name: 'environment_tags')
      final List<String> environmentTags = const <String>[],
      this.description})
      : _environmentTags = environmentTags;

  factory _$RegionSectorImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionSectorImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'region_id')
  final int regionId;
  @override
  @JsonKey(name: 'sector_index')
  final int sectorIndex;
  @override
  final String name;
  @override
  @JsonKey(name: 'sector_type')
  final String sectorType;
  final List<String> _environmentTags;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags {
    if (_environmentTags is EqualUnmodifiableListView) return _environmentTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_environmentTags);
  }

  @override
  final String? description;

  @override
  String toString() {
    return 'RegionSector(id: $id, regionId: $regionId, sectorIndex: $sectorIndex, name: $name, sectorType: $sectorType, environmentTags: $environmentTags, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionSectorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.sectorIndex, sectorIndex) ||
                other.sectorIndex == sectorIndex) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sectorType, sectorType) ||
                other.sectorType == sectorType) &&
            const DeepCollectionEquality()
                .equals(other._environmentTags, _environmentTags) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      regionId,
      sectorIndex,
      name,
      sectorType,
      const DeepCollectionEquality().hash(_environmentTags),
      description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionSectorImplCopyWith<_$RegionSectorImpl> get copyWith =>
      __$$RegionSectorImplCopyWithImpl<_$RegionSectorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionSectorImplToJson(
      this,
    );
  }
}

abstract class _RegionSector implements RegionSector {
  const factory _RegionSector(
      {required final String id,
      @JsonKey(name: 'region_id') required final int regionId,
      @JsonKey(name: 'sector_index') required final int sectorIndex,
      required final String name,
      @JsonKey(name: 'sector_type') required final String sectorType,
      @JsonKey(name: 'environment_tags') final List<String> environmentTags,
      final String? description}) = _$RegionSectorImpl;

  factory _RegionSector.fromJson(Map<String, dynamic> json) =
      _$RegionSectorImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'region_id')
  int get regionId;
  @override
  @JsonKey(name: 'sector_index')
  int get sectorIndex;
  @override
  String get name;
  @override
  @JsonKey(name: 'sector_type')
  String get sectorType;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags;
  @override
  String? get description;
  @override
  @JsonKey(ignore: true)
  _$$RegionSectorImplCopyWith<_$RegionSectorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
