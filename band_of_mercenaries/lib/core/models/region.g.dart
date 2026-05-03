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
      environmentTags: (json['environment_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      sectorCount: (json['sector_count'] as num?)?.toInt() ?? 4,
    );

Map<String, dynamic> _$$RegionImplToJson(_$RegionImpl instance) =>
    <String, dynamic>{
      'continent': instance.continent,
      'region': instance.region,
      'region_name': instance.regionName,
      'region_tier': instance.regionTier,
      'recommend_power': instance.recommendPower,
      'description': instance.description,
      'environment_tags': instance.environmentTags,
      'sector_count': instance.sectorCount,
    };
