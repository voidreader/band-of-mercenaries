// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'title_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TitleDataImpl _$$TitleDataImplFromJson(Map<String, dynamic> json) =>
    _$TitleDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      hookType: json['hook_type'] as String,
      hookCondition:
          json['hook_condition'] as Map<String, dynamic>? ?? const {},
      effectJson: json['effect_json'] as Map<String, dynamic>? ?? const {},
      iconKey: json['icon_key'] as String? ?? 'default',
      narrativeHint: json['narrative_hint'] as String?,
    );

Map<String, dynamic> _$$TitleDataImplToJson(_$TitleDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'hook_type': instance.hookType,
      'hook_condition': instance.hookCondition,
      'effect_json': instance.effectJson,
      'icon_key': instance.iconKey,
      'narrative_hint': instance.narrativeHint,
    };
