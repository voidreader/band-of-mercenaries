// M8.5 페이즈 4 #5 — ImageAsset 정적 카탈로그 모델
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_asset.freezed.dart';
part 'image_asset.g.dart';

@freezed
class ImageAsset with _$ImageAsset {
  const factory ImageAsset({
    @JsonKey(name: 'asset_key') required String assetKey,
    required String category,
    @JsonKey(name: 'entity_id') String? entityId,
    String? url,
    int? width,
    int? height,
    @JsonKey(name: 'fallback_emoji') String? fallbackEmoji,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _ImageAsset;

  factory ImageAsset.fromJson(Map<String, dynamic> json) =>
      _$ImageAssetFromJson(json);
}
