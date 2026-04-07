// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TraitDataImpl _$$TraitDataImplFromJson(Map<String, dynamic> json) =>
    _$TraitDataImpl(
      id: json['ID'] as String,
      name: json['Name'] as String,
      effectType: json['EffectType'] as String,
      value: (json['Value'] as num).toDouble(),
    );

Map<String, dynamic> _$$TraitDataImplToJson(_$TraitDataImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'EffectType': instance.effectType,
      'Value': instance.value,
    };

_$TraitDataListImpl _$$TraitDataListImplFromJson(Map<String, dynamic> json) =>
    _$TraitDataListImpl(
      items: (json['Traits'] as List<dynamic>)
          .map((e) => TraitData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TraitDataListImplToJson(_$TraitDataListImpl instance) =>
    <String, dynamic>{
      'Traits': instance.items,
    };
