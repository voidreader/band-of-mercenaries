import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_type.freezed.dart';
part 'quest_type.g.dart';

@freezed
class QuestType with _$QuestType {
  const factory QuestType({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'BaseReward') required int baseReward,
    @JsonKey(name: 'BaseDuration') required int baseDuration,
    @JsonKey(name: 'RiskFactor') required double riskFactor,
  }) = _QuestType;

  factory QuestType.fromJson(Map<String, dynamic> json) =>
      _$QuestTypeFromJson(json);
}

@freezed
class QuestTypeList with _$QuestTypeList {
  const factory QuestTypeList({
    @JsonKey(name: 'QuestTypes') required List<QuestType> items,
  }) = _QuestTypeList;

  factory QuestTypeList.fromJson(Map<String, dynamic> json) =>
      _$QuestTypeListFromJson(json);
}
