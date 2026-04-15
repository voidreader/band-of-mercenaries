// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_discovery_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegionDiscoveryDataImpl _$$RegionDiscoveryDataImplFromJson(
        Map<String, dynamic> json) =>
    _$RegionDiscoveryDataImpl(
      id: json['id'] as String,
      regionId: (json['region_id'] as num).toInt(),
      knowledgeThreshold: (json['knowledge_threshold'] as num).toInt(),
      discoveryType: json['discovery_type'] as String,
      discoveryData: json['discovery_data'] as Map<String, dynamic>?,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$RegionDiscoveryDataImplToJson(
        _$RegionDiscoveryDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'region_id': instance.regionId,
      'knowledge_threshold': instance.knowledgeThreshold,
      'discovery_type': instance.discoveryType,
      'discovery_data': instance.discoveryData,
      'description': instance.description,
    };
