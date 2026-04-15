// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FactionDataImpl _$$FactionDataImplFromJson(Map<String, dynamic> json) =>
    _$FactionDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      philosophy: json['philosophy'] as String,
      tierRange: (json['tier_range'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      color: json['color'] as String,
    );

Map<String, dynamic> _$$FactionDataImplToJson(_$FactionDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'philosophy': instance.philosophy,
      'tier_range': instance.tierRange,
      'color': instance.color,
    };
