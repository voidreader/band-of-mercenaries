// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region_adjacency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RegionAdjacency _$RegionAdjacencyFromJson(Map<String, dynamic> json) {
  return _RegionAdjacency.fromJson(json);
}

/// @nodoc
mixin _$RegionAdjacency {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_region')
  int get fromRegion => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_region')
  int get toRegion => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_units')
  int get distanceUnits => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RegionAdjacencyCopyWith<RegionAdjacency> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionAdjacencyCopyWith<$Res> {
  factory $RegionAdjacencyCopyWith(
          RegionAdjacency value, $Res Function(RegionAdjacency) then) =
      _$RegionAdjacencyCopyWithImpl<$Res, RegionAdjacency>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'from_region') int fromRegion,
      @JsonKey(name: 'to_region') int toRegion,
      @JsonKey(name: 'distance_units') int distanceUnits});
}

/// @nodoc
class _$RegionAdjacencyCopyWithImpl<$Res, $Val extends RegionAdjacency>
    implements $RegionAdjacencyCopyWith<$Res> {
  _$RegionAdjacencyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromRegion = null,
    Object? toRegion = null,
    Object? distanceUnits = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fromRegion: null == fromRegion
          ? _value.fromRegion
          : fromRegion // ignore: cast_nullable_to_non_nullable
              as int,
      toRegion: null == toRegion
          ? _value.toRegion
          : toRegion // ignore: cast_nullable_to_non_nullable
              as int,
      distanceUnits: null == distanceUnits
          ? _value.distanceUnits
          : distanceUnits // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegionAdjacencyImplCopyWith<$Res>
    implements $RegionAdjacencyCopyWith<$Res> {
  factory _$$RegionAdjacencyImplCopyWith(_$RegionAdjacencyImpl value,
          $Res Function(_$RegionAdjacencyImpl) then) =
      __$$RegionAdjacencyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'from_region') int fromRegion,
      @JsonKey(name: 'to_region') int toRegion,
      @JsonKey(name: 'distance_units') int distanceUnits});
}

/// @nodoc
class __$$RegionAdjacencyImplCopyWithImpl<$Res>
    extends _$RegionAdjacencyCopyWithImpl<$Res, _$RegionAdjacencyImpl>
    implements _$$RegionAdjacencyImplCopyWith<$Res> {
  __$$RegionAdjacencyImplCopyWithImpl(
      _$RegionAdjacencyImpl _value, $Res Function(_$RegionAdjacencyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromRegion = null,
    Object? toRegion = null,
    Object? distanceUnits = null,
  }) {
    return _then(_$RegionAdjacencyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fromRegion: null == fromRegion
          ? _value.fromRegion
          : fromRegion // ignore: cast_nullable_to_non_nullable
              as int,
      toRegion: null == toRegion
          ? _value.toRegion
          : toRegion // ignore: cast_nullable_to_non_nullable
              as int,
      distanceUnits: null == distanceUnits
          ? _value.distanceUnits
          : distanceUnits // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionAdjacencyImpl implements _RegionAdjacency {
  const _$RegionAdjacencyImpl(
      {required this.id,
      @JsonKey(name: 'from_region') required this.fromRegion,
      @JsonKey(name: 'to_region') required this.toRegion,
      @JsonKey(name: 'distance_units') required this.distanceUnits});

  factory _$RegionAdjacencyImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionAdjacencyImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'from_region')
  final int fromRegion;
  @override
  @JsonKey(name: 'to_region')
  final int toRegion;
  @override
  @JsonKey(name: 'distance_units')
  final int distanceUnits;

  @override
  String toString() {
    return 'RegionAdjacency(id: $id, fromRegion: $fromRegion, toRegion: $toRegion, distanceUnits: $distanceUnits)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionAdjacencyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromRegion, fromRegion) ||
                other.fromRegion == fromRegion) &&
            (identical(other.toRegion, toRegion) ||
                other.toRegion == toRegion) &&
            (identical(other.distanceUnits, distanceUnits) ||
                other.distanceUnits == distanceUnits));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, fromRegion, toRegion, distanceUnits);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionAdjacencyImplCopyWith<_$RegionAdjacencyImpl> get copyWith =>
      __$$RegionAdjacencyImplCopyWithImpl<_$RegionAdjacencyImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionAdjacencyImplToJson(
      this,
    );
  }
}

abstract class _RegionAdjacency implements RegionAdjacency {
  const factory _RegionAdjacency(
          {required final int id,
          @JsonKey(name: 'from_region') required final int fromRegion,
          @JsonKey(name: 'to_region') required final int toRegion,
          @JsonKey(name: 'distance_units') required final int distanceUnits}) =
      _$RegionAdjacencyImpl;

  factory _RegionAdjacency.fromJson(Map<String, dynamic> json) =
      _$RegionAdjacencyImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'from_region')
  int get fromRegion;
  @override
  @JsonKey(name: 'to_region')
  int get toRegion;
  @override
  @JsonKey(name: 'distance_units')
  int get distanceUnits;
  @override
  @JsonKey(ignore: true)
  _$$RegionAdjacencyImplCopyWith<_$RegionAdjacencyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
