// 세력 접촉점 — 특정 리전에서 세력과 상호작용하는 NPC 정보 (M8a 페이즈 4 #1)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_contact_data.freezed.dart';
part 'faction_contact_data.g.dart';

@freezed
class FactionContact with _$FactionContact {
  const factory FactionContact({
    required String id,
    @JsonKey(name: 'faction_id') required String factionId,
    @JsonKey(name: 'region_id') required int regionId,
    @JsonKey(name: 'npc_name') required String npcName,
    @JsonKey(name: 'trigger_type') required String triggerType,
    @JsonKey(name: 'trigger_value') required String triggerValue,
    @JsonKey(name: 'first_reaction_text') required String firstReactionText,
    @JsonKey(name: 'tags_json')
    @Default(<String, dynamic>{})
    Map<String, dynamic> tagsJson,
  }) = _FactionContact;

  factory FactionContact.fromJson(Map<String, dynamic> json) =>
      _$FactionContactFromJson(json);
}
