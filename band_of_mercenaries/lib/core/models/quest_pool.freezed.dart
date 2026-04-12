// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_pool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestPool _$QuestPoolFromJson(Map<String, dynamic> json) {
  return _QuestPool.fromJson(json);
}

/// @nodoc
mixin _$QuestPool {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get type => throw _privateConstructorUsedError;
  double get difficulty => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_region_diff')
  double get minRegionDiff => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_region_diff')
  double get maxRegionDiff => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestPoolCopyWith<QuestPool> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestPoolCopyWith<$Res> {
  factory $QuestPoolCopyWith(QuestPool value, $Res Function(QuestPool) then) =
      _$QuestPoolCopyWithImpl<$Res, QuestPool>;
  @useResult
  $Res call(
      {String id,
      String name,
      double type,
      double difficulty,
      @JsonKey(name: 'min_region_diff') double minRegionDiff,
      @JsonKey(name: 'max_region_diff') double maxRegionDiff});
}

/// @nodoc
class _$QuestPoolCopyWithImpl<$Res, $Val extends QuestPool>
    implements $QuestPoolCopyWith<$Res> {
  _$QuestPoolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? difficulty = null,
    Object? minRegionDiff = null,
    Object? maxRegionDiff = null,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as double,
      minRegionDiff: null == minRegionDiff
          ? _value.minRegionDiff
          : minRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      maxRegionDiff: null == maxRegionDiff
          ? _value.maxRegionDiff
          : maxRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestPoolImplCopyWith<$Res>
    implements $QuestPoolCopyWith<$Res> {
  factory _$$QuestPoolImplCopyWith(
          _$QuestPoolImpl value, $Res Function(_$QuestPoolImpl) then) =
      __$$QuestPoolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double type,
      double difficulty,
      @JsonKey(name: 'min_region_diff') double minRegionDiff,
      @JsonKey(name: 'max_region_diff') double maxRegionDiff});
}

/// @nodoc
class __$$QuestPoolImplCopyWithImpl<$Res>
    extends _$QuestPoolCopyWithImpl<$Res, _$QuestPoolImpl>
    implements _$$QuestPoolImplCopyWith<$Res> {
  __$$QuestPoolImplCopyWithImpl(
      _$QuestPoolImpl _value, $Res Function(_$QuestPoolImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? difficulty = null,
    Object? minRegionDiff = null,
    Object? maxRegionDiff = null,
  }) {
    return _then(_$QuestPoolImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as double,
      minRegionDiff: null == minRegionDiff
          ? _value.minRegionDiff
          : minRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      maxRegionDiff: null == maxRegionDiff
          ? _value.maxRegionDiff
          : maxRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestPoolImpl implements _QuestPool {
  const _$QuestPoolImpl(
      {required this.id,
      required this.name,
      required this.type,
      required this.difficulty,
      @JsonKey(name: 'min_region_diff') required this.minRegionDiff,
      @JsonKey(name: 'max_region_diff') required this.maxRegionDiff});

  factory _$QuestPoolImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestPoolImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double type;
  @override
  final double difficulty;
  @override
  @JsonKey(name: 'min_region_diff')
  final double minRegionDiff;
  @override
  @JsonKey(name: 'max_region_diff')
  final double maxRegionDiff;

  @override
  String toString() {
    return 'QuestPool(id: $id, name: $name, type: $type, difficulty: $difficulty, minRegionDiff: $minRegionDiff, maxRegionDiff: $maxRegionDiff)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestPoolImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.minRegionDiff, minRegionDiff) ||
                other.minRegionDiff == minRegionDiff) &&
            (identical(other.maxRegionDiff, maxRegionDiff) ||
                other.maxRegionDiff == maxRegionDiff));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, type, difficulty, minRegionDiff, maxRegionDiff);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestPoolImplCopyWith<_$QuestPoolImpl> get copyWith =>
      __$$QuestPoolImplCopyWithImpl<_$QuestPoolImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestPoolImplToJson(
      this,
    );
  }
}

abstract class _QuestPool implements QuestPool {
  const factory _QuestPool(
      {required final String id,
      required final String name,
      required final double type,
      required final double difficulty,
      @JsonKey(name: 'min_region_diff') required final double minRegionDiff,
      @JsonKey(name: 'max_region_diff')
      required final double maxRegionDiff}) = _$QuestPoolImpl;

  factory _QuestPool.fromJson(Map<String, dynamic> json) =
      _$QuestPoolImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get type;
  @override
  double get difficulty;
  @override
  @JsonKey(name: 'min_region_diff')
  double get minRegionDiff;
  @override
  @JsonKey(name: 'max_region_diff')
  double get maxRegionDiff;
  @override
  @JsonKey(ignore: true)
  _$$QuestPoolImplCopyWith<_$QuestPoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
