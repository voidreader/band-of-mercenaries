// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImpl _$$JobImplFromJson(Map<String, dynamic> json) => _$JobImpl(
      id: json['ID'] as String,
      tier: (json['Tier'] as num).toInt(),
      name: json['Name'] as String,
      baseAtk: (json['BaseAtk'] as num).toInt(),
      baseDef: (json['BaseDef'] as num).toInt(),
      baseHp: (json['BaseHp'] as num).toInt(),
      speed: (json['Speed'] as num).toDouble(),
    );

Map<String, dynamic> _$$JobImplToJson(_$JobImpl instance) => <String, dynamic>{
      'ID': instance.id,
      'Tier': instance.tier,
      'Name': instance.name,
      'BaseAtk': instance.baseAtk,
      'BaseDef': instance.baseDef,
      'BaseHp': instance.baseHp,
      'Speed': instance.speed,
    };

_$JobListImpl _$$JobListImplFromJson(Map<String, dynamic> json) =>
    _$JobListImpl(
      items: (json['Jobs'] as List<dynamic>)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$JobListImplToJson(_$JobListImpl instance) =>
    <String, dynamic>{
      'Jobs': instance.items,
    };
