// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_choice_result_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TravelChoiceResultDataImpl _$$TravelChoiceResultDataImplFromJson(
        Map<String, dynamic> json) =>
    _$TravelChoiceResultDataImpl(
      id: json['id'] as String,
      optionId: json['option_id'] as String,
      resultIndex: (json['result_index'] as num).toInt(),
      probability: (json['probability'] as num).toDouble(),
      conditionalExpr: json['conditional_expr'] as String?,
      narrative: json['narrative'] as String,
      effectType: json['effect_type'] as String,
      effectMagnitude: (json['effect_magnitude'] as num?)?.toDouble() ?? 0.0,
      effectTarget: json['effect_target'] as String?,
    );

Map<String, dynamic> _$$TravelChoiceResultDataImplToJson(
        _$TravelChoiceResultDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'option_id': instance.optionId,
      'result_index': instance.resultIndex,
      'probability': instance.probability,
      'conditional_expr': instance.conditionalExpr,
      'narrative': instance.narrative,
      'effect_type': instance.effectType,
      'effect_magnitude': instance.effectMagnitude,
      'effect_target': instance.effectTarget,
    };
