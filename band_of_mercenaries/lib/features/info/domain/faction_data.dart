import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_data.freezed.dart';
part 'faction_data.g.dart';

@freezed
class FactionData with _$FactionData {
  const factory FactionData({
    required String id,
    required String name,
    required String description,
    required String philosophy,
    @JsonKey(name: 'tier_range') required List<int> tierRange,
    required String color,
    // 신규 필드 — Supabase 컬럼 추가 전까지 @Default로 호환
    @JsonKey(name: 'visibility_type') @Default('public') String visibilityType,
    @JsonKey(name: 'join_rank_min') String? joinRankMin,
    @JsonKey(name: 'join_needs_clue') @Default(false) bool joinNeedsClue,
    @JsonKey(name: 'passive_bonus_json')
    @Default(<String, dynamic>{})
    Map<String, dynamic> passiveBonusJson,
    @JsonKey(name: 'conflict_faction_ids')
    @Default(<String>[])
    List<String> conflictFactionIds,
  }) = _FactionData;

  factory FactionData.fromJson(Map<String, dynamic> json) =>
      _$FactionDataFromJson(json);
}
