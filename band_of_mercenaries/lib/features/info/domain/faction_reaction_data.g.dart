// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_reaction_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FactionReactionImpl _$$FactionReactionImplFromJson(
        Map<String, dynamic> json) =>
    _$FactionReactionImpl(
      id: json['id'] as String,
      factionId: json['faction_id'] as String,
      contactId: json['contact_id'] as String,
      triggerType: json['trigger_type'] as String,
      triggerValue: json['trigger_value'] as String,
      relationStage: json['relation_stage'] as String,
      weight: (json['weight'] as num?)?.toInt() ?? 50,
      text: json['text'] as String,
      tagsJson: json['tags_json'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$FactionReactionImplToJson(
        _$FactionReactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
      'contact_id': instance.contactId,
      'trigger_type': instance.triggerType,
      'trigger_value': instance.triggerValue,
      'relation_stage': instance.relationStage,
      'weight': instance.weight,
      'text': instance.text,
      'tags_json': instance.tagsJson,
    };
