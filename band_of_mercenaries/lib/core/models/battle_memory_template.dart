// M8.5 페이즈 4 #3 — BattleMemoryTemplate 정적 카탈로그 모델
import 'package:freezed_annotation/freezed_annotation.dart';

part 'battle_memory_template.freezed.dart';
part 'battle_memory_template.g.dart';

@freezed
class BattleMemoryTemplate with _$BattleMemoryTemplate {
  const factory BattleMemoryTemplate({
    required String id,
    @JsonKey(name: 'entry_type') required String entryType,
    @JsonKey(name: 'source_event_match') String? sourceEventMatch,
    required String template,
    @Default(1) int weight,
  }) = _BattleMemoryTemplate;

  factory BattleMemoryTemplate.fromJson(Map<String, dynamic> json) =>
      _$BattleMemoryTemplateFromJson(json);
}
