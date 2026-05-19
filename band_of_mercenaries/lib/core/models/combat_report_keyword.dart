import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'combat_report_keyword.freezed.dart';
part 'combat_report_keyword.g.dart';

@freezed
class CombatReportKeyword with _$CombatReportKeyword {
  const factory CombatReportKeyword({
    required String id,
    required String category,
    required String key,
    @JsonKey(name: 'display_text') required String displayText,
    @JsonKey(name: 'tags_json') Object? tagsJson,
    @Default(1) int weight,
  }) = _CombatReportKeyword;

  factory CombatReportKeyword.fromJson(Map<String, dynamic> json) =>
      _$CombatReportKeywordFromJson(json);
}

extension CombatReportKeywordX on CombatReportKeyword {
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
