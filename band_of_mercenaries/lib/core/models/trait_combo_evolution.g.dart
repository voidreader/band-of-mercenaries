// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_combo_evolution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TraitComboEvolutionImpl _$$TraitComboEvolutionImplFromJson(
        Map<String, dynamic> json) =>
    _$TraitComboEvolutionImpl(
      id: (json['id'] as num).toInt(),
      requiredTrait1: json['required_trait_1'] as String,
      requiredTrait2: json['required_trait_2'] as String,
      resultTraitKey: json['result_trait_key'] as String,
    );

Map<String, dynamic> _$$TraitComboEvolutionImplToJson(
        _$TraitComboEvolutionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'required_trait_1': instance.requiredTrait1,
      'required_trait_2': instance.requiredTrait2,
      'result_trait_key': instance.resultTraitKey,
    };
