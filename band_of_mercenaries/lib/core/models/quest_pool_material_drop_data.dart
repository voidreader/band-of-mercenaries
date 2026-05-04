import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_pool_material_drop_data.freezed.dart';
part 'quest_pool_material_drop_data.g.dart';

/// 퀘스트 풀 재료 드롭 정적 데이터 모델 (Supabase quest_pool_material_drops 테이블과 1:1 대응).
@freezed
class QuestPoolMaterialDropData with _$QuestPoolMaterialDropData {
  const factory QuestPoolMaterialDropData({
    required int id,
    @JsonKey(name: 'pool_id') required String poolId,
    @JsonKey(name: 'item_id') required String itemId,
    @JsonKey(name: 'drop_rate') required double dropRate,
    @JsonKey(name: 'qty_min') @Default(1) int qtyMin,
    @JsonKey(name: 'qty_max') @Default(1) int qtyMax,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _QuestPoolMaterialDropData;

  factory QuestPoolMaterialDropData.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolMaterialDropDataFromJson(json);
}
