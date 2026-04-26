import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_narrative_data.freezed.dart';
part 'quest_narrative_data.g.dart';

@freezed
class QuestNarrativeData with _$QuestNarrativeData {
  const factory QuestNarrativeData({
    required String id,
    @JsonKey(name: 'quest_type') required String questType,
    @JsonKey(name: 'result_type') required String resultType,
    @Default(false) @JsonKey(name: 'is_elite') bool isElite,
    required String template,
    @Default(1) int weight,
    String? description,
  }) = _QuestNarrativeData;

  factory QuestNarrativeData.fromJson(Map<String, dynamic> json) =>
      _$QuestNarrativeDataFromJson(json);
}
