// 세력 상점 아이템 — 세력별 구매 가능 아이템 및 조건 정의 (M8a 페이즈 4 #1)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_shop_item_data.freezed.dart';
part 'faction_shop_item_data.g.dart';

@freezed
class FactionShopItem with _$FactionShopItem {
  const factory FactionShopItem({
    required String id,
    @JsonKey(name: 'faction_id') required String factionId,
    @JsonKey(name: 'item_id') required String itemId,
    @JsonKey(name: 'shop_category') required String shopCategory,
    @JsonKey(name: 'price_gold') required int priceGold,
    @JsonKey(name: 'min_reputation') required int minReputation,
    @JsonKey(name: 'requires_joined') @Default(false) bool requiresJoined,
    @JsonKey(name: 'unlock_type') String? unlockType,
    @JsonKey(name: 'unlock_value') String? unlockValue,
    @JsonKey(name: 'stock_policy') @Default('once') String stockPolicy,
    @JsonKey(name: 'stock_limit') @Default(1) int stockLimit,
    @JsonKey(name: 'restock_hours') int? restockHours,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'grant_type') @Default('item') String grantType,
    @Default('') String notes,
  }) = _FactionShopItem;

  factory FactionShopItem.fromJson(Map<String, dynamic> json) =>
      _$FactionShopItemFromJson(json);
}
