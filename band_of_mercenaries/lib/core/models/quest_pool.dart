import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_pool.freezed.dart';
part 'quest_pool.g.dart';

@freezed
class QuestPool with _$QuestPool {
  const factory QuestPool({
    required String id,
    required String name,
    required double type,
    required double difficulty,
    @JsonKey(name: 'min_region_diff') required double minRegionDiff,
    @JsonKey(name: 'max_region_diff') required double maxRegionDiff,
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
