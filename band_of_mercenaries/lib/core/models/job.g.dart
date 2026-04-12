// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImpl _$$JobImplFromJson(Map<String, dynamic> json) => _$JobImpl(
      id: json['id'] as String,
      tier: (json['tier'] as num).toInt(),
      name: json['name'] as String,
      baseAtk: (json['base_atk'] as num).toInt(),
      baseDef: (json['base_def'] as num).toInt(),
      baseHp: (json['base_hp'] as num).toInt(),
      speed: (json['speed'] as num).toDouble(),
    );

Map<String, dynamic> _$$JobImplToJson(_$JobImpl instance) => <String, dynamic>{
      'id': instance.id,
      'tier': instance.tier,
      'name': instance.name,
      'base_atk': instance.baseAtk,
      'base_def': instance.baseDef,
      'base_hp': instance.baseHp,
      'speed': instance.speed,
    };
