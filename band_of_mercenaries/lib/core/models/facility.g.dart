// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FacilityImpl _$$FacilityImplFromJson(Map<String, dynamic> json) =>
    _$FacilityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      effectType: json['effect_type'] as String,
      maxLevel: (json['max_level'] as num).toInt(),
      costs: (json['costs'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      values: (json['values'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      description: json['description'] as String?,
      category: json['category'] as String?,
      baseCost: (json['base_cost'] as num?)?.toInt(),
      costMultiplier: (json['cost_multiplier'] as num?)?.toDouble(),
      lv1Cost: (json['lv1_cost'] as num?)?.toInt(),
      lv2Cost: (json['lv2_cost'] as num?)?.toInt(),
      baseTime: (json['base_time'] as num?)?.toInt(),
      timeMultiplier: (json['time_multiplier'] as num?)?.toDouble(),
      lv1Time: (json['lv1_time'] as num?)?.toInt(),
      lv2Time: (json['lv2_time'] as num?)?.toInt(),
      maxEffect: (json['max_effect'] as num?)?.toDouble(),
      alpha: (json['alpha'] as num?)?.toDouble(),
      milestones: (json['milestones'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$$FacilityImplToJson(_$FacilityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'effect_type': instance.effectType,
      'max_level': instance.maxLevel,
      'costs': instance.costs,
      'values': instance.values,
      'description': instance.description,
      'category': instance.category,
      'base_cost': instance.baseCost,
      'cost_multiplier': instance.costMultiplier,
      'lv1_cost': instance.lv1Cost,
      'lv2_cost': instance.lv2Cost,
      'base_time': instance.baseTime,
      'time_multiplier': instance.timeMultiplier,
      'lv1_time': instance.lv1Time,
      'lv2_time': instance.lv2Time,
      'max_effect': instance.maxEffect,
      'alpha': instance.alpha,
      'milestones': instance.milestones,
    };
