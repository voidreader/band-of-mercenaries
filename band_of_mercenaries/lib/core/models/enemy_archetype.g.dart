// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enemy_archetype.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnemyArchetypeImpl _$$EnemyArchetypeImplFromJson(Map<String, dynamic> json) =>
    _$EnemyArchetypeImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      enemyKind: $enumDecode(_$EnemyKindEnumMap, json['enemy_kind']),
      role: json['role'] as String,
      tier: (json['tier'] as num).toInt(),
      baseStr: (json['base_str'] as num).toInt(),
      baseInt: (json['base_int'] as num).toInt(),
      baseVit: (json['base_vit'] as num).toInt(),
      baseAgi: (json['base_agi'] as num).toInt(),
      baseHp: (json['base_hp'] as num).toInt(),
      baseAttack: (json['base_attack'] as num).toInt(),
      baseDefense: (json['base_defense'] as num).toInt(),
      behaviorPattern:
          $enumDecode(_$BehaviorPatternEnumMap, json['behavior_pattern']),
      skillIds: (json['skill_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      environmentTags: (json['environment_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      factionTags: (json['faction_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ambushCompatible: json['ambush_compatible'] as bool? ?? false,
      enemyKeywordKey: json['enemy_keyword_key'] as String?,
      eliteMonsterId: json['elite_monster_id'] as String?,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$EnemyArchetypeImplToJson(
        _$EnemyArchetypeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'enemy_kind': _$EnemyKindEnumMap[instance.enemyKind]!,
      'role': instance.role,
      'tier': instance.tier,
      'base_str': instance.baseStr,
      'base_int': instance.baseInt,
      'base_vit': instance.baseVit,
      'base_agi': instance.baseAgi,
      'base_hp': instance.baseHp,
      'base_attack': instance.baseAttack,
      'base_defense': instance.baseDefense,
      'behavior_pattern': _$BehaviorPatternEnumMap[instance.behaviorPattern]!,
      'skill_ids': instance.skillIds,
      'environment_tags': instance.environmentTags,
      'faction_tags': instance.factionTags,
      'ambush_compatible': instance.ambushCompatible,
      'enemy_keyword_key': instance.enemyKeywordKey,
      'elite_monster_id': instance.eliteMonsterId,
      'description': instance.description,
    };

const _$EnemyKindEnumMap = {
  EnemyKind.normal: 'normal',
  EnemyKind.elite: 'elite',
  EnemyKind.unique: 'unique',
};

const _$BehaviorPatternEnumMap = {
  BehaviorPattern.aggressive: 'aggressive',
  BehaviorPattern.opportunist: 'opportunist',
  BehaviorPattern.caster: 'caster',
  BehaviorPattern.supporter: 'supporter',
  BehaviorPattern.defender: 'defender',
  BehaviorPattern.berserker: 'berserker',
};
