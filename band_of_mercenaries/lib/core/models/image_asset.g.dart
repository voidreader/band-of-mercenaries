// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImageAssetImpl _$$ImageAssetImplFromJson(Map<String, dynamic> json) =>
    _$ImageAssetImpl(
      assetKey: json['asset_key'] as String,
      category: json['category'] as String,
      entityId: json['entity_id'] as String?,
      url: json['url'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      fallbackEmoji: json['fallback_emoji'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$$ImageAssetImplToJson(_$ImageAssetImpl instance) =>
    <String, dynamic>{
      'asset_key': instance.assetKey,
      'category': instance.category,
      'entity_id': instance.entityId,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'fallback_emoji': instance.fallbackEmoji,
      'updated_at': instance.updatedAt,
    };
