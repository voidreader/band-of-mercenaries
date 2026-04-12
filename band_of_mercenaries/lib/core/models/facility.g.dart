// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FacilityImpl _$$FacilityImplFromJson(Map<String, dynamic> json) =>
    _$FacilityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      effectType: json['effect_type'] as String,
      maxLevel: (json['max_level'] as num).toInt(),
      costs: (json['costs'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      values: (json['values'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$$FacilityImplToJson(_$FacilityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'effect_type': instance.effectType,
      'max_level': instance.maxLevel,
      'costs': instance.costs,
      'values': instance.values,
    };
