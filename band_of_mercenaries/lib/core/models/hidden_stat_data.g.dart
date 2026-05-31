// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hidden_stat_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HiddenStatDataImpl _$$HiddenStatDataImplFromJson(Map<String, dynamic> json) =>
    _$HiddenStatDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      counterKey: json['counter_key'] as String,
      levelThresholds: (json['level_thresholds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      combatEffectsJson: json['combat_effects_json'] as Map<String, dynamic>,
      passiveEffectsJson: json['passive_effects_json'] as Map<String, dynamic>?,
      postRewardEffectsJson:
          json['post_reward_effects_json'] as Map<String, dynamic>?,
      iconKey: json['icon_key'] as String? ?? 'default',
      narrativeHint: json['narrative_hint'] as String?,
    );

Map<String, dynamic> _$$HiddenStatDataImplToJson(
        _$HiddenStatDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'counter_key': instance.counterKey,
      'level_thresholds': instance.levelThresholds,
      'combat_effects_json': instance.combatEffectsJson,
      'passive_effects_json': instance.passiveEffectsJson,
      'post_reward_effects_json': instance.postRewardEffectsJson,
      'icon_key': instance.iconKey,
      'narrative_hint': instance.narrativeHint,
    };
