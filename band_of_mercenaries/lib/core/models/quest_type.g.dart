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
