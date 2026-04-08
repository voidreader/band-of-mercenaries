// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FacilityImpl _$$FacilityImplFromJson(Map<String, dynamic> json) =>
    _$FacilityImpl(
      id: json['ID'] as String,
      name: json['Name'] as String,
      effectType: json['EffectType'] as String,
      maxLevel: (json['MaxLevel'] as num).toInt(),
      costs: (json['Costs'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      values: (json['Values'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$$FacilityImplToJson(_$FacilityImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'EffectType': instance.effectType,
      'MaxLevel': instance.maxLevel,
      'Costs': instance.costs,
      'Values': instance.values,
    };

_$FacilityListImpl _$$FacilityListImplFromJson(Map<String, dynamic> json) =>
    _$FacilityListImpl(
      items: (json['Facilities'] as List<dynamic>)
          .map((e) => Facility.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$FacilityListImplToJson(_$FacilityListImpl instance) =>
    <String, dynamic>{
      'Facilities': instance.items,
    };
