// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestTypeImpl _$$QuestTypeImplFromJson(Map<String, dynamic> json) =>
    _$QuestTypeImpl(
      id: json['ID'] as String,
      name: json['Name'] as String,
      baseReward: (json['BaseReward'] as num).toInt(),
      baseDuration: (json['BaseDuration'] as num).toInt(),
      riskFactor: (json['RiskFactor'] as num).toDouble(),
    );

Map<String, dynamic> _$$QuestTypeImplToJson(_$QuestTypeImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'BaseReward': instance.baseReward,
      'BaseDuration': instance.baseDuration,
      'RiskFactor': instance.riskFactor,
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
