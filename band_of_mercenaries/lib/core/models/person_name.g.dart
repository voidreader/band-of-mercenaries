// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_name.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonNameImpl _$$PersonNameImplFromJson(Map<String, dynamic> json) =>
    _$PersonNameImpl(
      id: (json['id'] as num).toInt(),
      korean: json['korean'] as String,
    );

Map<String, dynamic> _$$PersonNameImplToJson(_$PersonNameImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'korean': instance.korean,
    };

_$PersonNameListImpl _$$PersonNameListImplFromJson(Map<String, dynamic> json) =>
    _$PersonNameListImpl(
      items: (json['PersonNames'] as List<dynamic>)
          .map((e) => PersonName.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PersonNameListImplToJson(
        _$PersonNameListImpl instance) =>
    <String, dynamic>{
      'PersonNames': instance.items,
    };
