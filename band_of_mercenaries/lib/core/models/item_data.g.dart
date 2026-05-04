// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemDataImpl _$$ItemDataImplFromJson(Map<String, dynamic> json) =>
    _$ItemDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      flavorText: json['flavor_text'] as String? ?? '',
      category: json['category'] as String,
      slot: json['slot'] as String,
      tier: (json['tier'] as num).toInt(),
      regionExclusive: (json['region_exclusive'] as num?)?.toInt(),
      effectJson: json['effect_json'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ItemDataImplToJson(_$ItemDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'flavor_text': instance.flavorText,
      'category': instance.category,
      'slot': instance.slot,
      'tier': instance.tier,
      'region_exclusive': instance.regionExclusive,
      'effect_json': instance.effectJson,
      'created_at': instance.createdAt?.toIso8601String(),
    };
