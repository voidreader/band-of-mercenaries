// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TraitTransitionImpl _$$TraitTransitionImplFromJson(
        Map<String, dynamic> json) =>
    _$TraitTransitionImpl(
      id: (json['id'] as num).toInt(),
      fromTraitKey: json['from_trait_key'] as String,
      toTraitKey: json['to_trait_key'] as String,
      conditionJson: json['condition_json'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$TraitTransitionImplToJson(
        _$TraitTransitionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from_trait_key': instance.fromTraitKey,
      'to_trait_key': instance.toTraitKey,
      'condition_json': instance.conditionJson,
    };
