// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestPoolImpl _$$QuestPoolImplFromJson(Map<String, dynamic> json) =>
    _$QuestPoolImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: (json['type'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      minRegionDiff: (json['min_region_diff'] as num).toDouble(),
      maxRegionDiff: (json['max_region_diff'] as num).toDouble(),
      typeId: json['type_id'] as String? ?? 'raid',
      factionTag: json['faction_tag'] as String?,
      isFactionExclusive: json['is_faction_exclusive'] as bool? ?? false,
      minReputation: (json['min_reputation'] as num?)?.toInt() ?? 0,
      sectorType: json['sector_type'] as String?,
      specialFlags: json['special_flags'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      enemyName: json['enemy_name'] as String?,
    );

Map<String, dynamic> _$$QuestPoolImplToJson(_$QuestPoolImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'difficulty': instance.difficulty,
      'min_region_diff': instance.minRegionDiff,
      'max_region_diff': instance.maxRegionDiff,
      'type_id': instance.typeId,
      'faction_tag': instance.factionTag,
      'is_faction_exclusive': instance.isFactionExclusive,
      'min_reputation': instance.minReputation,
      'sector_type': instance.sectorType,
      'special_flags': instance.specialFlags,
      'enemy_name': instance.enemyName,
    };
