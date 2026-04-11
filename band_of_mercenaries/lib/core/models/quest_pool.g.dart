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

_$QuestPoolListImpl _$$QuestPoolListImplFromJson(Map<String, dynamic> json) =>
    _$QuestPoolListImpl(
      items: (json['QuestPools'] as List<dynamic>)
          .map((e) => QuestPool.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$QuestPoolListImplToJson(_$QuestPoolListImpl instance) =>
    <String, dynamic>{
      'QuestPools': instance.items,
    };
