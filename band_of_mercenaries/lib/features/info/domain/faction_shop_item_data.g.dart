// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_shop_item_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FactionShopItemImpl _$$FactionShopItemImplFromJson(
        Map<String, dynamic> json) =>
    _$FactionShopItemImpl(
      id: json['id'] as String,
      factionId: json['faction_id'] as String,
      itemId: json['item_id'] as String,
      shopCategory: json['shop_category'] as String,
      priceGold: (json['price_gold'] as num).toInt(),
      minReputation: (json['min_reputation'] as num).toInt(),
      requiresJoined: json['requires_joined'] as bool? ?? false,
      unlockType: json['unlock_type'] as String?,
      unlockValue: json['unlock_value'] as String?,
      stockPolicy: json['stock_policy'] as String? ?? 'once',
      stockLimit: (json['stock_limit'] as num?)?.toInt() ?? 1,
      restockHours: (json['restock_hours'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      grantType: json['grant_type'] as String? ?? 'item',
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$FactionShopItemImplToJson(
        _$FactionShopItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'faction_id': instance.factionId,
      'item_id': instance.itemId,
      'shop_category': instance.shopCategory,
      'price_gold': instance.priceGold,
      'min_reputation': instance.minReputation,
      'requires_joined': instance.requiresJoined,
      'unlock_type': instance.unlockType,
      'unlock_value': instance.unlockValue,
      'stock_policy': instance.stockPolicy,
      'stock_limit': instance.stockLimit,
      'restock_hours': instance.restockHours,
      'sort_order': instance.sortOrder,
      'grant_type': instance.grantType,
      'notes': instance.notes,
    };
