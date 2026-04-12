// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TraitDataImpl _$$TraitDataImplFromJson(Map<String, dynamic> json) =>
    _$TraitDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      effectType: json['effect_type'] as String,
      value: (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$$TraitDataImplToJson(_$TraitDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'effect_type': instance.effectType,
      'value': instance.value,
    };
