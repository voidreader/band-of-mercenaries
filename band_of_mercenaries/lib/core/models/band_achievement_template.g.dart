// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'band_achievement_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BandAchievementTemplateImpl _$$BandAchievementTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$BandAchievementTemplateImpl(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      descriptionTemplate: json['description_template'] as String,
      iconKey: json['icon_key'] as String? ?? 'default',
      chronicleVariants: (json['chronicle_variants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      defaultPriority: json['default_priority'] as String? ?? 'high',
      narrativeHint: json['narrative_hint'] as String?,
    );

Map<String, dynamic> _$$BandAchievementTemplateImplToJson(
        _$BandAchievementTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'name': instance.name,
      'description_template': instance.descriptionTemplate,
      'icon_key': instance.iconKey,
      'chronicle_variants': instance.chronicleVariants,
      'default_priority': instance.defaultPriority,
      'narrative_hint': instance.narrativeHint,
    };
