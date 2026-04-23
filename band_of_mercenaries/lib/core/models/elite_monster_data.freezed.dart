// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'elite_monster_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EliteMonsterData _$EliteMonsterDataFromJson(Map<String, dynamic> json) {
  return _EliteMonsterData.fromJson(json);
}

/// @nodoc
mixin _$EliteMonsterData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_unique')
  bool get isUnique => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_family')
  String get typeFamily => throw _privateConstructorUsedError;
  int get tier => throw _privateConstructorUsedError;
  int get power => throw _privateConstructorUsedError;
  @JsonKey(name: 'spawn_rate')
  double get spawnRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_multiplier')
  double get durationMultiplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags => throw _privateConstructorUsedError;
  @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
  Map<String, double> get statWeight => throw _privateConstructorUsedError;
  @JsonKey(name: 'fixed_region_environments')
  List<String>? get fixedRegionEnvironments =>
      throw _privateConstructorUsedError;
  String? get lore => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EliteMonsterDataCopyWith<EliteMonsterData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EliteMonsterDataCopyWith<$Res> {
  factory $EliteMonsterDataCopyWith(
          EliteMonsterData value, $Res Function(EliteMonsterData) then) =
      _$EliteMonsterDataCopyWithImpl<$Res, EliteMonsterData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'is_unique') bool isUnique,
      @JsonKey(name: 'type_family') String typeFamily,
      int tier,
      int power,
      @JsonKey(name: 'spawn_rate') double spawnRate,
      @JsonKey(name: 'duration_multiplier') double durationMultiplier,
      @JsonKey(name: 'environment_tags') List<String> environmentTags,
      @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
      Map<String, double> statWeight,
      @JsonKey(name: 'fixed_region_environments')
      List<String>? fixedRegionEnvironments,
      String? lore,
      String? title});
}

/// @nodoc
class _$EliteMonsterDataCopyWithImpl<$Res, $Val extends EliteMonsterData>
    implements $EliteMonsterDataCopyWith<$Res> {
  _$EliteMonsterDataCopyWithImpl(this._value, this._then);

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
    Object? isUnique = null,
    Object? typeFamily = null,
    Object? tier = null,
    Object? power = null,
    Object? spawnRate = null,
    Object? durationMultiplier = null,
    Object? environmentTags = null,
    Object? statWeight = null,
    Object? fixedRegionEnvironments = freezed,
    Object? lore = freezed,
    Object? title = freezed,
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
      isUnique: null == isUnique
          ? _value.isUnique
          : isUnique // ignore: cast_nullable_to_non_nullable
              as bool,
      typeFamily: null == typeFamily
          ? _value.typeFamily
          : typeFamily // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      power: null == power
          ? _value.power
          : power // ignore: cast_nullable_to_non_nullable
              as int,
      spawnRate: null == spawnRate
          ? _value.spawnRate
          : spawnRate // ignore: cast_nullable_to_non_nullable
              as double,
      durationMultiplier: null == durationMultiplier
          ? _value.durationMultiplier
          : durationMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      environmentTags: null == environmentTags
          ? _value.environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      statWeight: null == statWeight
          ? _value.statWeight
          : statWeight // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      fixedRegionEnvironments: freezed == fixedRegionEnvironments
          ? _value.fixedRegionEnvironments
          : fixedRegionEnvironments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      lore: freezed == lore
          ? _value.lore
          : lore // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EliteMonsterDataImplCopyWith<$Res>
    implements $EliteMonsterDataCopyWith<$Res> {
  factory _$$EliteMonsterDataImplCopyWith(_$EliteMonsterDataImpl value,
          $Res Function(_$EliteMonsterDataImpl) then) =
      __$$EliteMonsterDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'is_unique') bool isUnique,
      @JsonKey(name: 'type_family') String typeFamily,
      int tier,
      int power,
      @JsonKey(name: 'spawn_rate') double spawnRate,
      @JsonKey(name: 'duration_multiplier') double durationMultiplier,
      @JsonKey(name: 'environment_tags') List<String> environmentTags,
      @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
      Map<String, double> statWeight,
      @JsonKey(name: 'fixed_region_environments')
      List<String>? fixedRegionEnvironments,
      String? lore,
      String? title});
}

/// @nodoc
class __$$EliteMonsterDataImplCopyWithImpl<$Res>
    extends _$EliteMonsterDataCopyWithImpl<$Res, _$EliteMonsterDataImpl>
    implements _$$EliteMonsterDataImplCopyWith<$Res> {
  __$$EliteMonsterDataImplCopyWithImpl(_$EliteMonsterDataImpl _value,
      $Res Function(_$EliteMonsterDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? isUnique = null,
    Object? typeFamily = null,
    Object? tier = null,
    Object? power = null,
    Object? spawnRate = null,
    Object? durationMultiplier = null,
    Object? environmentTags = null,
    Object? statWeight = null,
    Object? fixedRegionEnvironments = freezed,
    Object? lore = freezed,
    Object? title = freezed,
  }) {
    return _then(_$EliteMonsterDataImpl(
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
      isUnique: null == isUnique
          ? _value.isUnique
          : isUnique // ignore: cast_nullable_to_non_nullable
              as bool,
      typeFamily: null == typeFamily
          ? _value.typeFamily
          : typeFamily // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      power: null == power
          ? _value.power
          : power // ignore: cast_nullable_to_non_nullable
              as int,
      spawnRate: null == spawnRate
          ? _value.spawnRate
          : spawnRate // ignore: cast_nullable_to_non_nullable
              as double,
      durationMultiplier: null == durationMultiplier
          ? _value.durationMultiplier
          : durationMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      environmentTags: null == environmentTags
          ? _value._environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      statWeight: null == statWeight
          ? _value._statWeight
          : statWeight // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      fixedRegionEnvironments: freezed == fixedRegionEnvironments
          ? _value._fixedRegionEnvironments
          : fixedRegionEnvironments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      lore: freezed == lore
          ? _value.lore
          : lore // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EliteMonsterDataImpl implements _EliteMonsterData {
  const _$EliteMonsterDataImpl(
      {required this.id,
      required this.name,
      required this.description,
      @JsonKey(name: 'is_unique') required this.isUnique,
      @JsonKey(name: 'type_family') required this.typeFamily,
      required this.tier,
      required this.power,
      @JsonKey(name: 'spawn_rate') required this.spawnRate,
      @JsonKey(name: 'duration_multiplier') required this.durationMultiplier,
      @JsonKey(name: 'environment_tags')
      final List<String> environmentTags = const <String>[],
      @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
      final Map<String, double> statWeight = const <String, double>{},
      @JsonKey(name: 'fixed_region_environments')
      final List<String>? fixedRegionEnvironments,
      this.lore,
      this.title})
      : _environmentTags = environmentTags,
        _statWeight = statWeight,
        _fixedRegionEnvironments = fixedRegionEnvironments;

  factory _$EliteMonsterDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$EliteMonsterDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  @JsonKey(name: 'is_unique')
  final bool isUnique;
  @override
  @JsonKey(name: 'type_family')
  final String typeFamily;
  @override
  final int tier;
  @override
  final int power;
  @override
  @JsonKey(name: 'spawn_rate')
  final double spawnRate;
  @override
  @JsonKey(name: 'duration_multiplier')
  final double durationMultiplier;
  final List<String> _environmentTags;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags {
    if (_environmentTags is EqualUnmodifiableListView) return _environmentTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_environmentTags);
  }

  final Map<String, double> _statWeight;
  @override
  @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
  Map<String, double> get statWeight {
    if (_statWeight is EqualUnmodifiableMapView) return _statWeight;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_statWeight);
  }

  final List<String>? _fixedRegionEnvironments;
  @override
  @JsonKey(name: 'fixed_region_environments')
  List<String>? get fixedRegionEnvironments {
    final value = _fixedRegionEnvironments;
    if (value == null) return null;
    if (_fixedRegionEnvironments is EqualUnmodifiableListView)
      return _fixedRegionEnvironments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? lore;
  @override
  final String? title;

  @override
  String toString() {
    return 'EliteMonsterData(id: $id, name: $name, description: $description, isUnique: $isUnique, typeFamily: $typeFamily, tier: $tier, power: $power, spawnRate: $spawnRate, durationMultiplier: $durationMultiplier, environmentTags: $environmentTags, statWeight: $statWeight, fixedRegionEnvironments: $fixedRegionEnvironments, lore: $lore, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EliteMonsterDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isUnique, isUnique) ||
                other.isUnique == isUnique) &&
            (identical(other.typeFamily, typeFamily) ||
                other.typeFamily == typeFamily) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.power, power) || other.power == power) &&
            (identical(other.spawnRate, spawnRate) ||
                other.spawnRate == spawnRate) &&
            (identical(other.durationMultiplier, durationMultiplier) ||
                other.durationMultiplier == durationMultiplier) &&
            const DeepCollectionEquality()
                .equals(other._environmentTags, _environmentTags) &&
            const DeepCollectionEquality()
                .equals(other._statWeight, _statWeight) &&
            const DeepCollectionEquality().equals(
                other._fixedRegionEnvironments, _fixedRegionEnvironments) &&
            (identical(other.lore, lore) || other.lore == lore) &&
            (identical(other.title, title) || other.title == title));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      isUnique,
      typeFamily,
      tier,
      power,
      spawnRate,
      durationMultiplier,
      const DeepCollectionEquality().hash(_environmentTags),
      const DeepCollectionEquality().hash(_statWeight),
      const DeepCollectionEquality().hash(_fixedRegionEnvironments),
      lore,
      title);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EliteMonsterDataImplCopyWith<_$EliteMonsterDataImpl> get copyWith =>
      __$$EliteMonsterDataImplCopyWithImpl<_$EliteMonsterDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EliteMonsterDataImplToJson(
      this,
    );
  }
}

abstract class _EliteMonsterData implements EliteMonsterData {
  const factory _EliteMonsterData(
      {required final String id,
      required final String name,
      required final String description,
      @JsonKey(name: 'is_unique') required final bool isUnique,
      @JsonKey(name: 'type_family') required final String typeFamily,
      required final int tier,
      required final int power,
      @JsonKey(name: 'spawn_rate') required final double spawnRate,
      @JsonKey(name: 'duration_multiplier')
      required final double durationMultiplier,
      @JsonKey(name: 'environment_tags') final List<String> environmentTags,
      @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
      final Map<String, double> statWeight,
      @JsonKey(name: 'fixed_region_environments')
      final List<String>? fixedRegionEnvironments,
      final String? lore,
      final String? title}) = _$EliteMonsterDataImpl;

  factory _EliteMonsterData.fromJson(Map<String, dynamic> json) =
      _$EliteMonsterDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'is_unique')
  bool get isUnique;
  @override
  @JsonKey(name: 'type_family')
  String get typeFamily;
  @override
  int get tier;
  @override
  int get power;
  @override
  @JsonKey(name: 'spawn_rate')
  double get spawnRate;
  @override
  @JsonKey(name: 'duration_multiplier')
  double get durationMultiplier;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags;
  @override
  @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
  Map<String, double> get statWeight;
  @override
  @JsonKey(name: 'fixed_region_environments')
  List<String>? get fixedRegionEnvironments;
  @override
  String? get lore;
  @override
  String? get title;
  @override
  @JsonKey(ignore: true)
  _$$EliteMonsterDataImplCopyWith<_$EliteMonsterDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
