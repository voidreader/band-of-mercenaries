// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_narrative_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestNarrativeDataImpl _$$QuestNarrativeDataImplFromJson(
        Map<String, dynamic> json) =>
    _$QuestNarrativeDataImpl(
      id: json['id'] as String,
      questType: json['quest_type'] as String,
      resultType: json['result_type'] as String,
      isElite: json['is_elite'] as bool? ?? false,
      template: json['template'] as String,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$QuestNarrativeDataImplToJson(
        _$QuestNarrativeDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quest_type': instance.questType,
      'result_type': instance.resultType,
      'is_elite': instance.isElite,
      'template': instance.template,
      'weight': instance.weight,
      'description': instance.description,
    };
