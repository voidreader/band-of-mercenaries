// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_memory_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BattleMemoryTemplateImpl _$$BattleMemoryTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$BattleMemoryTemplateImpl(
      id: json['id'] as String,
      entryType: json['entry_type'] as String,
      sourceEventMatch: json['source_event_match'] as String?,
      template: json['template'] as String,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$BattleMemoryTemplateImplToJson(
        _$BattleMemoryTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entry_type': instance.entryType,
      'source_event_match': instance.sourceEventMatch,
      'template': instance.template,
      'weight': instance.weight,
    };
