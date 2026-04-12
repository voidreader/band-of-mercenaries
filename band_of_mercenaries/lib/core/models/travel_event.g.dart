// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TravelEventImpl _$$TravelEventImplFromJson(Map<String, dynamic> json) =>
    _$TravelEventImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      effectType: json['effect_type'] as String,
      magnitude: (json['magnitude'] as num).toDouble(),
      minTier: (json['min_tier'] as num).toInt(),
      maxTier: (json['max_tier'] as num).toInt(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$TravelEventImplToJson(_$TravelEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'effect_type': instance.effectType,
      'magnitude': instance.magnitude,
      'min_tier': instance.minTier,
      'max_tier': instance.maxTier,
      'description': instance.description,
    };
