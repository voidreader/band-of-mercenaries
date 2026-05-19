// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_contact_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FactionContactImpl _$$FactionContactImplFromJson(Map<String, dynamic> json) =>
    _$FactionContactImpl(
      id: json['id'] as String,
      factionId: json['faction_id'] as String,
      regionId: (json['region_id'] as num).toInt(),
      npcName: json['npc_name'] as String,
      triggerType: json['trigger_type'] as String,
      triggerValue: json['trigger_value'] as String,
      firstReactionText: json['first_reaction_text'] as String,
      tagsJson: json['tags_json'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$FactionContactImplToJson(
        _$FactionContactImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
      'region_id': instance.regionId,
      'npc_name': instance.npcName,
      'trigger_type': instance.triggerType,
      'trigger_value': instance.triggerValue,
      'first_reaction_text': instance.firstReactionText,
      'tags_json': instance.tagsJson,
    };
