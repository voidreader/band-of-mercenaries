// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'elite_loot_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EliteLootEntryImpl _$$EliteLootEntryImplFromJson(Map<String, dynamic> json) =>
    _$EliteLootEntryImpl(
      id: json['id'] as String,
      eliteId: json['elite_id'] as String,
      dropType: json['drop_type'] as String,
      itemId: json['item_id'] as String?,
      goldMin: (json['gold_min'] as num?)?.toInt(),
      goldMax: (json['gold_max'] as num?)?.toInt(),
      dropRate: (json['drop_rate'] as num).toDouble(),
      rarityGrade: json['rarity_grade'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$EliteLootEntryImplToJson(
        _$EliteLootEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'elite_id': instance.eliteId,
      'drop_type': instance.dropType,
      'item_id': instance.itemId,
      'gold_min': instance.goldMin,
      'gold_max': instance.goldMax,
      'drop_rate': instance.dropRate,
      'rarity_grade': instance.rarityGrade,
      'quantity': instance.quantity,
    };
