// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_synergy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TraitSynergyImpl _$$TraitSynergyImplFromJson(Map<String, dynamic> json) =>
    _$TraitSynergyImpl(
      id: (json['id'] as num).toInt(),
      innateTraitKey: json['innate_trait_key'] as String,
      targetTraitKey: json['target_trait_key'] as String,
      reductionPercent: (json['reduction_percent'] as num).toDouble(),
    );

Map<String, dynamic> _$$TraitSynergyImplToJson(_$TraitSynergyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'innate_trait_key': instance.innateTraitKey,
      'target_trait_key': instance.targetTraitKey,
      'reduction_percent': instance.reductionPercent,
    };
