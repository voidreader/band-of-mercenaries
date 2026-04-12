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
    );

Map<String, dynamic> _$$QuestPoolImplToJson(_$QuestPoolImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'difficulty': instance.difficulty,
      'min_region_diff': instance.minRegionDiff,
      'max_region_diff': instance.maxRegionDiff,
    };
