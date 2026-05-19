// 세력 반응 텍스트 — 접촉점 NPC의 상황별 대사 데이터 (M8a 페이즈 4 #1)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_reaction_data.freezed.dart';
part 'faction_reaction_data.g.dart';

@freezed
class FactionReaction with _$FactionReaction {
  const factory FactionReaction({
    required String id,
    @JsonKey(name: 'faction_id') required String factionId,
    @JsonKey(name: 'contact_id') required String contactId,
    @JsonKey(name: 'trigger_type') required String triggerType,
    @JsonKey(name: 'trigger_value') required String triggerValue,
    @JsonKey(name: 'relation_stage') required String relationStage,
    @Default(50) int weight,
    required String text,
    @JsonKey(name: 'tags_json')
    @Default(<String, dynamic>{})
    Map<String, dynamic> tagsJson,
  }) = _FactionReaction;

  factory FactionReaction.fromJson(Map<String, dynamic> json) =>
      _$FactionReactionFromJson(json);
}
