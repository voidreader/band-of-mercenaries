// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TravelEventImpl _$$TravelEventImplFromJson(Map<String, dynamic> json) =>
    _$TravelEventImpl(
      id: json['ID'] as String,
      name: json['Name'] as String,
      type: json['Type'] as String,
      effectType: json['EffectType'] as String,
      magnitude: (json['Magnitude'] as num).toDouble(),
      minTier: (json['MinTier'] as num).toInt(),
      maxTier: (json['MaxTier'] as num).toInt(),
      description: json['Description'] as String,
    );

Map<String, dynamic> _$$TravelEventImplToJson(_$TravelEventImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'Type': instance.type,
      'EffectType': instance.effectType,
      'Magnitude': instance.magnitude,
      'MinTier': instance.minTier,
      'MaxTier': instance.maxTier,
      'Description': instance.description,
    };

_$TravelEventListImpl _$$TravelEventListImplFromJson(
        Map<String, dynamic> json) =>
    _$TravelEventListImpl(
      items: (json['TravelEvents'] as List<dynamic>)
          .map((e) => TravelEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TravelEventListImplToJson(
        _$TravelEventListImpl instance) =>
    <String, dynamic>{
      'TravelEvents': instance.items,
    };
