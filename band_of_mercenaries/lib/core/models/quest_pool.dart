import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_pool.freezed.dart';
part 'quest_pool.g.dart';

@freezed
class QuestPool with _$QuestPool {
  const factory QuestPool({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') required double type,
    @JsonKey(name: 'Difficulty') required double difficulty,
    @JsonKey(name: 'MinRegionDiff') required double minRegionDiff,
    @JsonKey(name: 'MaxRegionDiff') required double maxRegionDiff,
  }) = _QuestPool;

  factory QuestPool.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolFromJson(json);
}

@freezed
class QuestPoolList with _$QuestPoolList {
  const factory QuestPoolList({
    @JsonKey(name: 'QuestPools') required List<QuestPool> items,
  }) = _QuestPoolList;

  factory QuestPoolList.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolListFromJson(json);
}
