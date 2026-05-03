// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_sector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegionSectorImpl _$$RegionSectorImplFromJson(Map<String, dynamic> json) =>
    _$RegionSectorImpl(
      id: json['id'] as String,
      regionId: (json['region_id'] as num).toInt(),
      sectorIndex: (json['sector_index'] as num).toInt(),
      name: json['name'] as String,
      sectorType: json['sector_type'] as String,
      environmentTags: (json['environment_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$RegionSectorImplToJson(_$RegionSectorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'region_id': instance.regionId,
      'sector_index': instance.sectorIndex,
      'name': instance.name,
      'sector_type': instance.sectorType,
      'environment_tags': instance.environmentTags,
      'description': instance.description,
    };
