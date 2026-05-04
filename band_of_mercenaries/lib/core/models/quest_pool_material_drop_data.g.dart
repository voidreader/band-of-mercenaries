// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_pool_material_drop_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestPoolMaterialDropDataImpl _$$QuestPoolMaterialDropDataImplFromJson(
        Map<String, dynamic> json) =>
    _$QuestPoolMaterialDropDataImpl(
      id: (json['id'] as num).toInt(),
      poolId: json['pool_id'] as String,
      itemId: json['item_id'] as String,
      dropRate: (json['drop_rate'] as num).toDouble(),
      qtyMin: (json['qty_min'] as num?)?.toInt() ?? 1,
      qtyMax: (json['qty_max'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$QuestPoolMaterialDropDataImplToJson(
        _$QuestPoolMaterialDropDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pool_id': instance.poolId,
      'item_id': instance.itemId,
      'drop_rate': instance.dropRate,
      'qty_min': instance.qtyMin,
      'qty_max': instance.qtyMax,
      'created_at': instance.createdAt?.toIso8601String(),
    };
