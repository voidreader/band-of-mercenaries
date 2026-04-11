// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegionImpl _$$RegionImplFromJson(Map<String, dynamic> json) => _$RegionImpl(
      continent: (json['continent'] as num).toInt(),
      region: (json['region'] as num).toInt(),
      regionName: json['region_name'] as String,
      regionTier: (json['region_tier'] as num).toInt(),
      recommendPower: (json['recommend_power'] as num).toInt(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$RegionImplToJson(_$RegionImpl instance) =>
    <String, dynamic>{
      'continent': instance.continent,
      'region': instance.region,
      'region_name': instance.regionName,
      'region_tier': instance.regionTier,
      'recommend_power': instance.recommendPower,
      'description': instance.description,
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
