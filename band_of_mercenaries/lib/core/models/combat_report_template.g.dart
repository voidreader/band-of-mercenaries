// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_report_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CombatReportTemplateImpl _$$CombatReportTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$CombatReportTemplateImpl(
      id: json['id'] as String,
      group: json['group'] as String,
      scope: json['scope'] as String,
      factionId: json['faction_id'] as String?,
      questType: json['quest_type'] as String?,
      resultType: json['result_type'] as String?,
      lineType: json['line_type'] as String,
      importance: json['importance'] as String,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      template: json['template'] as String,
      tagsJson: json['tags_json'],
    );

Map<String, dynamic> _$$CombatReportTemplateImplToJson(
        _$CombatReportTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group': instance.group,
      'scope': instance.scope,
      'faction_id': instance.factionId,
      'quest_type': instance.questType,
      'result_type': instance.resultType,
      'line_type': instance.lineType,
      'importance': instance.importance,
      'weight': instance.weight,
      'template': instance.template,
      'tags_json': instance.tagsJson,
    };
