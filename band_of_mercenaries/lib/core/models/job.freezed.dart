// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Job _$JobFromJson(Map<String, dynamic> json) {
  return _Job.fromJson(json);
}

/// @nodoc
mixin _$Job {
  String get id => throw _privateConstructorUsedError;
  int get tier => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_str')
  int get baseStr => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_intelligence')
  int get baseIntelligence => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_vit')
  int get baseVit => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_agi')
  int get baseAgi => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JobCopyWith<Job> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobCopyWith<$Res> {
  factory $JobCopyWith(Job value, $Res Function(Job) then) =
      _$JobCopyWithImpl<$Res, Job>;
  @useResult
  $Res call(
      {String id,
      int tier,
      String name,
      @JsonKey(name: 'base_str') int baseStr,
      @JsonKey(name: 'base_intelligence') int baseIntelligence,
      @JsonKey(name: 'base_vit') int baseVit,
      @JsonKey(name: 'base_agi') int baseAgi});
}

/// @nodoc
class _$JobCopyWithImpl<$Res, $Val extends Job> implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tier = null,
    Object? name = null,
    Object? baseStr = null,
    Object? baseIntelligence = null,
    Object? baseVit = null,
    Object? baseAgi = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      baseStr: null == baseStr
          ? _value.baseStr
          : baseStr // ignore: cast_nullable_to_non_nullable
              as int,
      baseIntelligence: null == baseIntelligence
          ? _value.baseIntelligence
          : baseIntelligence // ignore: cast_nullable_to_non_nullable
              as int,
      baseVit: null == baseVit
          ? _value.baseVit
          : baseVit // ignore: cast_nullable_to_non_nullable
              as int,
      baseAgi: null == baseAgi
          ? _value.baseAgi
          : baseAgi // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JobImplCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$$JobImplCopyWith(_$JobImpl value, $Res Function(_$JobImpl) then) =
      __$$JobImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int tier,
      String name,
      @JsonKey(name: 'base_str') int baseStr,
      @JsonKey(name: 'base_intelligence') int baseIntelligence,
      @JsonKey(name: 'base_vit') int baseVit,
      @JsonKey(name: 'base_agi') int baseAgi});
}

/// @nodoc
class __$$JobImplCopyWithImpl<$Res> extends _$JobCopyWithImpl<$Res, _$JobImpl>
    implements _$$JobImplCopyWith<$Res> {
  __$$JobImplCopyWithImpl(_$JobImpl _value, $Res Function(_$JobImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tier = null,
    Object? name = null,
    Object? baseStr = null,
    Object? baseIntelligence = null,
    Object? baseVit = null,
    Object? baseAgi = null,
  }) {
    return _then(_$JobImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      baseStr: null == baseStr
          ? _value.baseStr
          : baseStr // ignore: cast_nullable_to_non_nullable
              as int,
      baseIntelligence: null == baseIntelligence
          ? _value.baseIntelligence
          : baseIntelligence // ignore: cast_nullable_to_non_nullable
              as int,
      baseVit: null == baseVit
          ? _value.baseVit
          : baseVit // ignore: cast_nullable_to_non_nullable
              as int,
      baseAgi: null == baseAgi
          ? _value.baseAgi
          : baseAgi // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JobImpl implements _Job {
  const _$JobImpl(
      {required this.id,
      required this.tier,
      required this.name,
      @JsonKey(name: 'base_str') required this.baseStr,
      @JsonKey(name: 'base_intelligence') required this.baseIntelligence,
      @JsonKey(name: 'base_vit') required this.baseVit,
      @JsonKey(name: 'base_agi') required this.baseAgi});

  factory _$JobImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobImplFromJson(json);

  @override
  final String id;
  @override
  final int tier;
  @override
  final String name;
  @override
  @JsonKey(name: 'base_str')
  final int baseStr;
  @override
  @JsonKey(name: 'base_intelligence')
  final int baseIntelligence;
  @override
  @JsonKey(name: 'base_vit')
  final int baseVit;
  @override
  @JsonKey(name: 'base_agi')
  final int baseAgi;

  @override
  String toString() {
    return 'Job(id: $id, tier: $tier, name: $name, baseStr: $baseStr, baseIntelligence: $baseIntelligence, baseVit: $baseVit, baseAgi: $baseAgi)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.baseStr, baseStr) || other.baseStr == baseStr) &&
            (identical(other.baseIntelligence, baseIntelligence) ||
                other.baseIntelligence == baseIntelligence) &&
            (identical(other.baseVit, baseVit) || other.baseVit == baseVit) &&
            (identical(other.baseAgi, baseAgi) || other.baseAgi == baseAgi));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, tier, name, baseStr, baseIntelligence, baseVit, baseAgi);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JobImplCopyWith<_$JobImpl> get copyWith =>
      __$$JobImplCopyWithImpl<_$JobImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobImplToJson(
      this,
    );
  }
}

abstract class _Job implements Job {
  const factory _Job(
      {required final String id,
      required final int tier,
      required final String name,
      @JsonKey(name: 'base_str') required final int baseStr,
      @JsonKey(name: 'base_intelligence') required final int baseIntelligence,
      @JsonKey(name: 'base_vit') required final int baseVit,
      @JsonKey(name: 'base_agi') required final int baseAgi}) = _$JobImpl;

  factory _Job.fromJson(Map<String, dynamic> json) = _$JobImpl.fromJson;

  @override
  String get id;
  @override
  int get tier;
  @override
  String get name;
  @override
  @JsonKey(name: 'base_str')
  int get baseStr;
  @override
  @JsonKey(name: 'base_intelligence')
  int get baseIntelligence;
  @override
  @JsonKey(name: 'base_vit')
  int get baseVit;
  @override
  @JsonKey(name: 'base_agi')
  int get baseAgi;
  @override
  @JsonKey(ignore: true)
  _$$JobImplCopyWith<_$JobImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
