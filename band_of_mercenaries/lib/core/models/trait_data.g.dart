// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TraitDataImpl _$$TraitDataImplFromJson(Map<String, dynamic> json) =>
    _$TraitDataImpl(
      key: json['key'] as String,
      name: json['name'] as String,
      categoryKey: json['category_key'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      effectText: json['effect_text'] as String? ?? '',
    );

Map<String, dynamic> _$$TraitDataImplToJson(_$TraitDataImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'category_key': instance.categoryKey,
      'type': instance.type,
      'description': instance.description,
      'effect_text': instance.effectText,
    };
