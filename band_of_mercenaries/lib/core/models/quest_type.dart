import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_type.freezed.dart';
part 'quest_type.g.dart';

@freezed
class QuestType with _$QuestType {
  const factory QuestType({
    required String id,
    required String name,
    @JsonKey(name: 'base_reward') required int baseReward,
    @JsonKey(name: 'base_duration') required int baseDuration,
    @JsonKey(name: 'risk_factor') required double riskFactor,
  }) = _QuestType;

  factory QuestType.fromJson(Map<String, dynamic> json) =>
      _$QuestTypeFromJson(json);
}