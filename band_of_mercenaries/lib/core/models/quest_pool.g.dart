// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestPoolImpl _$$QuestPoolImplFromJson(Map<String, dynamic> json) =>
    _$QuestPoolImpl(
      id: json['ID'] as String,
      name: json['Name'] as String,
      type: (json['Type'] as num).toDouble(),
      difficulty: (json['Difficulty'] as num).toDouble(),
      minRegionDiff: (json['MinRegionDiff'] as num).toDouble(),
      maxRegionDiff: (json['MaxRegionDiff'] as num).toDouble(),
    );

Map<String, dynamic> _$$QuestPoolImplToJson(_$QuestPoolImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'Type': instance.type,
      'Difficulty': instance.difficulty,
      'MinRegionDiff': instance.minRegionDiff,
      'MaxRegionDiff': instance.maxRegionDiff,
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
