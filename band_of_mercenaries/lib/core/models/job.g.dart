// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImpl _$$JobImplFromJson(Map<String, dynamic> json) => _$JobImpl(
      id: json['id'] as String,
      tier: (json['tier'] as num).toInt(),
      name: json['name'] as String,
      baseStr: (json['base_str'] as num).toInt(),
      baseIntelligence: (json['base_intelligence'] as num).toInt(),
      baseVit: (json['base_vit'] as num).toInt(),
      baseAgi: (json['base_agi'] as num).toInt(),
    );

Map<String, dynamic> _$$JobImplToJson(_$JobImpl instance) => <String, dynamic>{
      'id': instance.id,
      'tier': instance.tier,
      'name': instance.name,
      'base_str': instance.baseStr,
      'base_intelligence': instance.baseIntelligence,
      'base_vit': instance.baseVit,
      'base_agi': instance.baseAgi,
    };
