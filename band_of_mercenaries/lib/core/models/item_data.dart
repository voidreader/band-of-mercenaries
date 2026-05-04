import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_data.freezed.dart';
part 'item_data.g.dart';

/// 아이템 정적 데이터 모델 (Supabase items 테이블과 1:1 대응).
@freezed
class ItemData with _$ItemData {
  const factory ItemData({
    required String id,
    required String name,
    @Default('') String description,
    @JsonKey(name: 'flavor_text') @Default('') String flavorText,
    required String category,
    required String slot,
    required int tier,
    @JsonKey(name: 'region_exclusive') int? regionExclusive,
    @JsonKey(name: 'effect_json')
    @Default(<String, dynamic>{})
    Map<String, dynamic> effectJson,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ItemData;

  factory ItemData.fromJson(Map<String, dynamic> json) =>
      _$ItemDataFromJson(json);
}
