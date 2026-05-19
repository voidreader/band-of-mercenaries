import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'combat_report_template.freezed.dart';
part 'combat_report_template.g.dart';

@freezed
class CombatReportTemplate with _$CombatReportTemplate {
  const factory CombatReportTemplate({
    required String id,
    required String group,
    required String scope,
    @JsonKey(name: 'faction_id') String? factionId,
    @JsonKey(name: 'quest_type') String? questType,
    @JsonKey(name: 'result_type') String? resultType,
    @JsonKey(name: 'line_type') required String lineType,
    required String importance,
    @Default(1) int weight,
    required String template,
    @JsonKey(name: 'tags_json') Object? tagsJson,
  }) = _CombatReportTemplate;

  factory CombatReportTemplate.fromJson(Map<String, dynamic> json) =>
      _$CombatReportTemplateFromJson(json);
}

extension CombatReportTemplateX on CombatReportTemplate {
  Map<String, dynamic> get parsedTags {
    final raw = tagsJson;
    if (raw == null) return const <String, dynamic>{};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }
}
