// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestTypeImpl _$$QuestTypeImplFromJson(Map<String, dynamic> json) =>
    _$QuestTypeImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      baseReward: (json['base_reward'] as num).toInt(),
      baseDuration: (json['base_duration'] as num).toInt(),
      riskFactor: (json['risk_factor'] as num).toDouble(),
    );

Map<String, dynamic> _$$QuestTypeImplToJson(_$QuestTypeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'base_reward': instance.baseReward,
      'base_duration': instance.baseDuration,
      'risk_factor': instance.riskFactor,
    };

_$QuestTypeListImpl _$$QuestTypeListImplFromJson(Map<String, dynamic> json) =>
    _$QuestTypeListImpl(
      items: (json['QuestTypes'] as List<dynamic>)
          .map((e) => QuestType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$QuestTypeListImplToJson(_$QuestTypeListImpl instance) =>
    <String, dynamic>{
      'QuestTypes': instance.items,
    };
