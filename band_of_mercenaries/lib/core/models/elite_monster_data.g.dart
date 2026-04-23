// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'elite_monster_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EliteMonsterDataImpl _$$EliteMonsterDataImplFromJson(
        Map<String, dynamic> json) =>
    _$EliteMonsterDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isUnique: json['is_unique'] as bool,
      typeFamily: json['type_family'] as String,
      tier: (json['tier'] as num).toInt(),
      power: (json['power'] as num).toInt(),
      spawnRate: (json['spawn_rate'] as num).toDouble(),
      durationMultiplier: (json['duration_multiplier'] as num).toDouble(),
      environmentTags: (json['environment_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      statWeight: json['stat_weight'] == null
          ? const <String, double>{}
          : _statWeightFromJson(json['stat_weight']),
      fixedRegionEnvironments:
          (json['fixed_region_environments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      lore: json['lore'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$$EliteMonsterDataImplToJson(
        _$EliteMonsterDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_unique': instance.isUnique,
      'type_family': instance.typeFamily,
      'tier': instance.tier,
      'power': instance.power,
      'spawn_rate': instance.spawnRate,
      'duration_multiplier': instance.durationMultiplier,
      'environment_tags': instance.environmentTags,
      'stat_weight': instance.statWeight,
      'fixed_region_environments': instance.fixedRegionEnvironments,
      'lore': instance.lore,
      'title': instance.title,
    };
