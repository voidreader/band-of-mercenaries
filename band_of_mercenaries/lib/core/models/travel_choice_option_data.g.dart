// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_choice_option_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TravelChoiceOptionDataImpl _$$TravelChoiceOptionDataImplFromJson(
        Map<String, dynamic> json) =>
    _$TravelChoiceOptionDataImpl(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      choiceIndex: (json['choice_index'] as num).toInt(),
      label: json['label'] as String,
      visibilityExpr: json['visibility_expr'] as String?,
      description: json['description'] as String,
      riskLevel: json['risk_level'] as String,
    );

Map<String, dynamic> _$$TravelChoiceOptionDataImplToJson(
        _$TravelChoiceOptionDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'choice_index': instance.choiceIndex,
      'label': instance.label,
      'visibility_expr': instance.visibilityExpr,
      'description': instance.description,
      'risk_level': instance.riskLevel,
    };
