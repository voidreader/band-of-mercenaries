// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegionImpl _$$RegionImplFromJson(Map<String, dynamic> json) => _$RegionImpl(
      continent: (json['Continent'] as num).toInt(),
      region: (json['Region'] as num).toInt(),
      regionName: json['RegionName'] as String,
      regionTier: (json['RegionTier'] as num).toInt(),
      recommendPower: (json['RecommendPower'] as num).toInt(),
      desc: json['Desc'] as String,
    );

Map<String, dynamic> _$$RegionImplToJson(_$RegionImpl instance) =>
    <String, dynamic>{
      'Continent': instance.continent,
      'Region': instance.region,
      'RegionName': instance.regionName,
      'RegionTier': instance.regionTier,
      'RecommendPower': instance.recommendPower,
      'Desc': instance.desc,
    };

_$RegionListImpl _$$RegionListImplFromJson(Map<String, dynamic> json) =>
    _$RegionListImpl(
      items: (json['Regions'] as List<dynamic>)
          .map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RegionListImplToJson(_$RegionListImpl instance) =>
    <String, dynamic>{
      'Regions': instance.items,
    };
