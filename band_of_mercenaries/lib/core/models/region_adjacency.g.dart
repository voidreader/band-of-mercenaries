// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_adjacency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegionAdjacencyImpl _$$RegionAdjacencyImplFromJson(
        Map<String, dynamic> json) =>
    _$RegionAdjacencyImpl(
      id: (json['id'] as num).toInt(),
      fromRegion: (json['from_region'] as num).toInt(),
      toRegion: (json['to_region'] as num).toInt(),
      distanceUnits: (json['distance_units'] as num).toInt(),
    );

Map<String, dynamic> _$$RegionAdjacencyImplToJson(
        _$RegionAdjacencyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from_region': instance.fromRegion,
      'to_region': instance.toRegion,
      'distance_units': instance.distanceUnits,
    };
