// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enemy_archetype.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EnemyArchetype _$EnemyArchetypeFromJson(Map<String, dynamic> json) {
  return _EnemyArchetype.fromJson(json);
}

/// @nodoc
mixin _$EnemyArchetype {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'enemy_kind')
  EnemyKind get enemyKind => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  int get tier => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_str')
  int get baseStr => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_int')
  int get baseInt => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_vit')
  int get baseVit => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_agi')
  int get baseAgi => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_hp')
  int get baseHp => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_attack')
  int get baseAttack => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_defense')
  int get baseDefense => throw _privateConstructorUsedError;
  @JsonKey(name: 'behavior_pattern')
  BehaviorPattern get behaviorPattern => throw _privateConstructorUsedError;
  @JsonKey(name: 'skill_ids')
  List<String> get skillIds => throw _privateConstructorUsedError;
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_tags')
  List<String> get factionTags => throw _privateConstructorUsedError;
  @JsonKey(name: 'ambush_compatible')
  bool get ambushCompatible => throw _privateConstructorUsedError;
  @JsonKey(name: 'enemy_keyword_key')
  String? get enemyKeywordKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'elite_monster_id')
  String? get eliteMonsterId => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EnemyArchetypeCopyWith<EnemyArchetype> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnemyArchetypeCopyWith<$Res> {
  factory $EnemyArchetypeCopyWith(
          EnemyArchetype value, $Res Function(EnemyArchetype) then) =
      _$EnemyArchetypeCopyWithImpl<$Res, EnemyArchetype>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'enemy_kind') EnemyKind enemyKind,
      String role,
      int tier,
      @JsonKey(name: 'base_str') int baseStr,
      @JsonKey(name: 'base_int') int baseInt,
      @JsonKey(name: 'base_vit') int baseVit,
      @JsonKey(name: 'base_agi') int baseAgi,
      @JsonKey(name: 'base_hp') int baseHp,
      @JsonKey(name: 'base_attack') int baseAttack,
      @JsonKey(name: 'base_defense') int baseDefense,
      @JsonKey(name: 'behavior_pattern') BehaviorPattern behaviorPattern,
      @JsonKey(name: 'skill_ids') List<String> skillIds,
      @JsonKey(name: 'environment_tags') List<String> environmentTags,
      @JsonKey(name: 'faction_tags') List<String> factionTags,
      @JsonKey(name: 'ambush_compatible') bool ambushCompatible,
      @JsonKey(name: 'enemy_keyword_key') String? enemyKeywordKey,
      @JsonKey(name: 'elite_monster_id') String? eliteMonsterId,
      String description});
}

/// @nodoc
class _$EnemyArchetypeCopyWithImpl<$Res, $Val extends EnemyArchetype>
    implements $EnemyArchetypeCopyWith<$Res> {
  _$EnemyArchetypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? enemyKind = null,
    Object? role = null,
    Object? tier = null,
    Object? baseStr = null,
    Object? baseInt = null,
    Object? baseVit = null,
    Object? baseAgi = null,
    Object? baseHp = null,
    Object? baseAttack = null,
    Object? baseDefense = null,
    Object? behaviorPattern = null,
    Object? skillIds = null,
    Object? environmentTags = null,
    Object? factionTags = null,
    Object? ambushCompatible = null,
    Object? enemyKeywordKey = freezed,
    Object? eliteMonsterId = freezed,
    Object? description = null,
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
      enemyKind: null == enemyKind
          ? _value.enemyKind
          : enemyKind // ignore: cast_nullable_to_non_nullable
              as EnemyKind,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      baseStr: null == baseStr
          ? _value.baseStr
          : baseStr // ignore: cast_nullable_to_non_nullable
              as int,
      baseInt: null == baseInt
          ? _value.baseInt
          : baseInt // ignore: cast_nullable_to_non_nullable
              as int,
      baseVit: null == baseVit
          ? _value.baseVit
          : baseVit // ignore: cast_nullable_to_non_nullable
              as int,
      baseAgi: null == baseAgi
          ? _value.baseAgi
          : baseAgi // ignore: cast_nullable_to_non_nullable
              as int,
      baseHp: null == baseHp
          ? _value.baseHp
          : baseHp // ignore: cast_nullable_to_non_nullable
              as int,
      baseAttack: null == baseAttack
          ? _value.baseAttack
          : baseAttack // ignore: cast_nullable_to_non_nullable
              as int,
      baseDefense: null == baseDefense
          ? _value.baseDefense
          : baseDefense // ignore: cast_nullable_to_non_nullable
              as int,
      behaviorPattern: null == behaviorPattern
          ? _value.behaviorPattern
          : behaviorPattern // ignore: cast_nullable_to_non_nullable
              as BehaviorPattern,
      skillIds: null == skillIds
          ? _value.skillIds
          : skillIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      environmentTags: null == environmentTags
          ? _value.environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      factionTags: null == factionTags
          ? _value.factionTags
          : factionTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ambushCompatible: null == ambushCompatible
          ? _value.ambushCompatible
          : ambushCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      enemyKeywordKey: freezed == enemyKeywordKey
          ? _value.enemyKeywordKey
          : enemyKeywordKey // ignore: cast_nullable_to_non_nullable
              as String?,
      eliteMonsterId: freezed == eliteMonsterId
          ? _value.eliteMonsterId
          : eliteMonsterId // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnemyArchetypeImplCopyWith<$Res>
    implements $EnemyArchetypeCopyWith<$Res> {
  factory _$$EnemyArchetypeImplCopyWith(_$EnemyArchetypeImpl value,
          $Res Function(_$EnemyArchetypeImpl) then) =
      __$$EnemyArchetypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'enemy_kind') EnemyKind enemyKind,
      String role,
      int tier,
      @JsonKey(name: 'base_str') int baseStr,
      @JsonKey(name: 'base_int') int baseInt,
      @JsonKey(name: 'base_vit') int baseVit,
      @JsonKey(name: 'base_agi') int baseAgi,
      @JsonKey(name: 'base_hp') int baseHp,
      @JsonKey(name: 'base_attack') int baseAttack,
      @JsonKey(name: 'base_defense') int baseDefense,
      @JsonKey(name: 'behavior_pattern') BehaviorPattern behaviorPattern,
      @JsonKey(name: 'skill_ids') List<String> skillIds,
      @JsonKey(name: 'environment_tags') List<String> environmentTags,
      @JsonKey(name: 'faction_tags') List<String> factionTags,
      @JsonKey(name: 'ambush_compatible') bool ambushCompatible,
      @JsonKey(name: 'enemy_keyword_key') String? enemyKeywordKey,
      @JsonKey(name: 'elite_monster_id') String? eliteMonsterId,
      String description});
}

/// @nodoc
class __$$EnemyArchetypeImplCopyWithImpl<$Res>
    extends _$EnemyArchetypeCopyWithImpl<$Res, _$EnemyArchetypeImpl>
    implements _$$EnemyArchetypeImplCopyWith<$Res> {
  __$$EnemyArchetypeImplCopyWithImpl(
      _$EnemyArchetypeImpl _value, $Res Function(_$EnemyArchetypeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? enemyKind = null,
    Object? role = null,
    Object? tier = null,
    Object? baseStr = null,
    Object? baseInt = null,
    Object? baseVit = null,
    Object? baseAgi = null,
    Object? baseHp = null,
    Object? baseAttack = null,
    Object? baseDefense = null,
    Object? behaviorPattern = null,
    Object? skillIds = null,
    Object? environmentTags = null,
    Object? factionTags = null,
    Object? ambushCompatible = null,
    Object? enemyKeywordKey = freezed,
    Object? eliteMonsterId = freezed,
    Object? description = null,
  }) {
    return _then(_$EnemyArchetypeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      enemyKind: null == enemyKind
          ? _value.enemyKind
          : enemyKind // ignore: cast_nullable_to_non_nullable
              as EnemyKind,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      baseStr: null == baseStr
          ? _value.baseStr
          : baseStr // ignore: cast_nullable_to_non_nullable
              as int,
      baseInt: null == baseInt
          ? _value.baseInt
          : baseInt // ignore: cast_nullable_to_non_nullable
              as int,
      baseVit: null == baseVit
          ? _value.baseVit
          : baseVit // ignore: cast_nullable_to_non_nullable
              as int,
      baseAgi: null == baseAgi
          ? _value.baseAgi
          : baseAgi // ignore: cast_nullable_to_non_nullable
              as int,
      baseHp: null == baseHp
          ? _value.baseHp
          : baseHp // ignore: cast_nullable_to_non_nullable
              as int,
      baseAttack: null == baseAttack
          ? _value.baseAttack
          : baseAttack // ignore: cast_nullable_to_non_nullable
              as int,
      baseDefense: null == baseDefense
          ? _value.baseDefense
          : baseDefense // ignore: cast_nullable_to_non_nullable
              as int,
      behaviorPattern: null == behaviorPattern
          ? _value.behaviorPattern
          : behaviorPattern // ignore: cast_nullable_to_non_nullable
              as BehaviorPattern,
      skillIds: null == skillIds
          ? _value._skillIds
          : skillIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      environmentTags: null == environmentTags
          ? _value._environmentTags
          : environmentTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      factionTags: null == factionTags
          ? _value._factionTags
          : factionTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ambushCompatible: null == ambushCompatible
          ? _value.ambushCompatible
          : ambushCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      enemyKeywordKey: freezed == enemyKeywordKey
          ? _value.enemyKeywordKey
          : enemyKeywordKey // ignore: cast_nullable_to_non_nullable
              as String?,
      eliteMonsterId: freezed == eliteMonsterId
          ? _value.eliteMonsterId
          : eliteMonsterId // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnemyArchetypeImpl implements _EnemyArchetype {
  const _$EnemyArchetypeImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'enemy_kind') required this.enemyKind,
      required this.role,
      required this.tier,
      @JsonKey(name: 'base_str') required this.baseStr,
      @JsonKey(name: 'base_int') required this.baseInt,
      @JsonKey(name: 'base_vit') required this.baseVit,
      @JsonKey(name: 'base_agi') required this.baseAgi,
      @JsonKey(name: 'base_hp') required this.baseHp,
      @JsonKey(name: 'base_attack') required this.baseAttack,
      @JsonKey(name: 'base_defense') required this.baseDefense,
      @JsonKey(name: 'behavior_pattern') required this.behaviorPattern,
      @JsonKey(name: 'skill_ids') final List<String> skillIds = const [],
      @JsonKey(name: 'environment_tags')
      final List<String> environmentTags = const [],
      @JsonKey(name: 'faction_tags') final List<String> factionTags = const [],
      @JsonKey(name: 'ambush_compatible') this.ambushCompatible = false,
      @JsonKey(name: 'enemy_keyword_key') this.enemyKeywordKey,
      @JsonKey(name: 'elite_monster_id') this.eliteMonsterId,
      required this.description})
      : _skillIds = skillIds,
        _environmentTags = environmentTags,
        _factionTags = factionTags;

  factory _$EnemyArchetypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnemyArchetypeImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'enemy_kind')
  final EnemyKind enemyKind;
  @override
  final String role;
  @override
  final int tier;
  @override
  @JsonKey(name: 'base_str')
  final int baseStr;
  @override
  @JsonKey(name: 'base_int')
  final int baseInt;
  @override
  @JsonKey(name: 'base_vit')
  final int baseVit;
  @override
  @JsonKey(name: 'base_agi')
  final int baseAgi;
  @override
  @JsonKey(name: 'base_hp')
  final int baseHp;
  @override
  @JsonKey(name: 'base_attack')
  final int baseAttack;
  @override
  @JsonKey(name: 'base_defense')
  final int baseDefense;
  @override
  @JsonKey(name: 'behavior_pattern')
  final BehaviorPattern behaviorPattern;
  final List<String> _skillIds;
  @override
  @JsonKey(name: 'skill_ids')
  List<String> get skillIds {
    if (_skillIds is EqualUnmodifiableListView) return _skillIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skillIds);
  }

  final List<String> _environmentTags;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags {
    if (_environmentTags is EqualUnmodifiableListView) return _environmentTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_environmentTags);
  }

  final List<String> _factionTags;
  @override
  @JsonKey(name: 'faction_tags')
  List<String> get factionTags {
    if (_factionTags is EqualUnmodifiableListView) return _factionTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_factionTags);
  }

  @override
  @JsonKey(name: 'ambush_compatible')
  final bool ambushCompatible;
  @override
  @JsonKey(name: 'enemy_keyword_key')
  final String? enemyKeywordKey;
  @override
  @JsonKey(name: 'elite_monster_id')
  final String? eliteMonsterId;
  @override
  final String description;

  @override
  String toString() {
    return 'EnemyArchetype(id: $id, name: $name, enemyKind: $enemyKind, role: $role, tier: $tier, baseStr: $baseStr, baseInt: $baseInt, baseVit: $baseVit, baseAgi: $baseAgi, baseHp: $baseHp, baseAttack: $baseAttack, baseDefense: $baseDefense, behaviorPattern: $behaviorPattern, skillIds: $skillIds, environmentTags: $environmentTags, factionTags: $factionTags, ambushCompatible: $ambushCompatible, enemyKeywordKey: $enemyKeywordKey, eliteMonsterId: $eliteMonsterId, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnemyArchetypeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.enemyKind, enemyKind) ||
                other.enemyKind == enemyKind) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.baseStr, baseStr) || other.baseStr == baseStr) &&
            (identical(other.baseInt, baseInt) || other.baseInt == baseInt) &&
            (identical(other.baseVit, baseVit) || other.baseVit == baseVit) &&
            (identical(other.baseAgi, baseAgi) || other.baseAgi == baseAgi) &&
            (identical(other.baseHp, baseHp) || other.baseHp == baseHp) &&
            (identical(other.baseAttack, baseAttack) ||
                other.baseAttack == baseAttack) &&
            (identical(other.baseDefense, baseDefense) ||
                other.baseDefense == baseDefense) &&
            (identical(other.behaviorPattern, behaviorPattern) ||
                other.behaviorPattern == behaviorPattern) &&
            const DeepCollectionEquality().equals(other._skillIds, _skillIds) &&
            const DeepCollectionEquality()
                .equals(other._environmentTags, _environmentTags) &&
            const DeepCollectionEquality()
                .equals(other._factionTags, _factionTags) &&
            (identical(other.ambushCompatible, ambushCompatible) ||
                other.ambushCompatible == ambushCompatible) &&
            (identical(other.enemyKeywordKey, enemyKeywordKey) ||
                other.enemyKeywordKey == enemyKeywordKey) &&
            (identical(other.eliteMonsterId, eliteMonsterId) ||
                other.eliteMonsterId == eliteMonsterId) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        enemyKind,
        role,
        tier,
        baseStr,
        baseInt,
        baseVit,
        baseAgi,
        baseHp,
        baseAttack,
        baseDefense,
        behaviorPattern,
        const DeepCollectionEquality().hash(_skillIds),
        const DeepCollectionEquality().hash(_environmentTags),
        const DeepCollectionEquality().hash(_factionTags),
        ambushCompatible,
        enemyKeywordKey,
        eliteMonsterId,
        description
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EnemyArchetypeImplCopyWith<_$EnemyArchetypeImpl> get copyWith =>
      __$$EnemyArchetypeImplCopyWithImpl<_$EnemyArchetypeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnemyArchetypeImplToJson(
      this,
    );
  }
}

abstract class _EnemyArchetype implements EnemyArchetype {
  const factory _EnemyArchetype(
      {required final String id,
      required final String name,
      @JsonKey(name: 'enemy_kind') required final EnemyKind enemyKind,
      required final String role,
      required final int tier,
      @JsonKey(name: 'base_str') required final int baseStr,
      @JsonKey(name: 'base_int') required final int baseInt,
      @JsonKey(name: 'base_vit') required final int baseVit,
      @JsonKey(name: 'base_agi') required final int baseAgi,
      @JsonKey(name: 'base_hp') required final int baseHp,
      @JsonKey(name: 'base_attack') required final int baseAttack,
      @JsonKey(name: 'base_defense') required final int baseDefense,
      @JsonKey(name: 'behavior_pattern')
      required final BehaviorPattern behaviorPattern,
      @JsonKey(name: 'skill_ids') final List<String> skillIds,
      @JsonKey(name: 'environment_tags') final List<String> environmentTags,
      @JsonKey(name: 'faction_tags') final List<String> factionTags,
      @JsonKey(name: 'ambush_compatible') final bool ambushCompatible,
      @JsonKey(name: 'enemy_keyword_key') final String? enemyKeywordKey,
      @JsonKey(name: 'elite_monster_id') final String? eliteMonsterId,
      required final String description}) = _$EnemyArchetypeImpl;

  factory _EnemyArchetype.fromJson(Map<String, dynamic> json) =
      _$EnemyArchetypeImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'enemy_kind')
  EnemyKind get enemyKind;
  @override
  String get role;
  @override
  int get tier;
  @override
  @JsonKey(name: 'base_str')
  int get baseStr;
  @override
  @JsonKey(name: 'base_int')
  int get baseInt;
  @override
  @JsonKey(name: 'base_vit')
  int get baseVit;
  @override
  @JsonKey(name: 'base_agi')
  int get baseAgi;
  @override
  @JsonKey(name: 'base_hp')
  int get baseHp;
  @override
  @JsonKey(name: 'base_attack')
  int get baseAttack;
  @override
  @JsonKey(name: 'base_defense')
  int get baseDefense;
  @override
  @JsonKey(name: 'behavior_pattern')
  BehaviorPattern get behaviorPattern;
  @override
  @JsonKey(name: 'skill_ids')
  List<String> get skillIds;
  @override
  @JsonKey(name: 'environment_tags')
  List<String> get environmentTags;
  @override
  @JsonKey(name: 'faction_tags')
  List<String> get factionTags;
  @override
  @JsonKey(name: 'ambush_compatible')
  bool get ambushCompatible;
  @override
  @JsonKey(name: 'enemy_keyword_key')
  String? get enemyKeywordKey;
  @override
  @JsonKey(name: 'elite_monster_id')
  String? get eliteMonsterId;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$EnemyArchetypeImplCopyWith<_$EnemyArchetypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
