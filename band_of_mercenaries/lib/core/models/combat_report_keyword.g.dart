// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_report_keyword.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CombatReportKeywordImpl _$$CombatReportKeywordImplFromJson(
        Map<String, dynamic> json) =>
    _$CombatReportKeywordImpl(
      id: json['id'] as String,
      category: json['category'] as String,
      key: json['key'] as String,
      displayText: json['display_text'] as String,
      tagsJson: json['tags_json'],
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$CombatReportKeywordImplToJson(
        _$CombatReportKeywordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'key': instance.key,
      'display_text': instance.displayText,
      'tags_json': instance.tagsJson,
      'weight': instance.weight,
    };
