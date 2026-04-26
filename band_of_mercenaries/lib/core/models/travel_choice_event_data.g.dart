// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_choice_event_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TravelChoiceEventDataImpl _$$TravelChoiceEventDataImplFromJson(
        Map<String, dynamic> json) =>
    _$TravelChoiceEventDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      situation: json['situation'] as String,
      minTier: (json['min_tier'] as num).toInt(),
      maxTier: (json['max_tier'] as num).toInt(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      preferredTraits: json['preferred_traits'] as String?,
    );

Map<String, dynamic> _$$TravelChoiceEventDataImplToJson(
        _$TravelChoiceEventDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'situation': instance.situation,
      'min_tier': instance.minTier,
      'max_tier': instance.maxTier,
      'weight': instance.weight,
      'preferred_traits': instance.preferredTraits,
    };
