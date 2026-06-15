import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

/// 이미지 에셋 카테고리 — fallback 이모지/색상 매핑 기준
enum ImageAssetCategory {
  regionThumbnail,
  factionEmblem,
  itemIcon,
  dashboardMetricIcon,
  livingsphereBackground,
}

/// 재사용 가능한 이미지 위젯. url이 null이거나 로드 실패 시 이모지+색상박스로 fallback.
/// M8.5 시점: 전 url NULL이므로 100% fallback 경로로 동작 (시각 회귀 없음).
class GameImage extends ConsumerWidget {
  const GameImage({
    super.key,
    required this.assetKey,
    required this.category,
    this.fallbackEmoji,
    this.fallbackBg,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// image_assets 조회 키. null이면 즉시 fallback.
  final String? assetKey;

  /// fallback 이모지/색상 기본값 결정용 카테고리.
  final ImageAssetCategory category;

  /// 호출부 오버라이드 fallback 이모지 (행 emoji > 이 값 > 카테고리 기본 순).
  final String? fallbackEmoji;

  /// fallback 색상 박스 배경색 (null이면 카테고리 기본색 사용).
  final Color? fallbackBg;

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final asset = (staticData != null && assetKey != null)
        ? staticData.findImageAsset(assetKey!)
        : null;

    final url = asset?.url;
    final resolvedEmoji = asset?.fallbackEmoji ?? fallbackEmoji ?? _defaultEmoji(category);
    final resolvedBg = fallbackBg ?? _defaultBg(category);
    final br = borderRadius ?? BorderRadius.circular(8);

    if (url != null) {
      return ClipRRect(
        borderRadius: br,
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return _FallbackBox(
              width: width,
              height: height,
              bg: resolvedBg,
              emoji: resolvedEmoji,
              br: br,
            );
          },
          errorBuilder: (ctx, error, stack) => _FallbackBox(
            width: width,
            height: height,
            bg: resolvedBg,
            emoji: resolvedEmoji,
            br: br,
          ),
        ),
      );
    }

    return _FallbackBox(
      width: width,
      height: height,
      bg: resolvedBg,
      emoji: resolvedEmoji,
      br: br,
    );
  }

  static String _defaultEmoji(ImageAssetCategory cat) => switch (cat) {
    ImageAssetCategory.regionThumbnail        => '🗺',
    ImageAssetCategory.factionEmblem          => '🔱',
    ImageAssetCategory.itemIcon               => '⚔',
    ImageAssetCategory.dashboardMetricIcon    => '★',
    ImageAssetCategory.livingsphereBackground => '🏕',
  };

  static Color _defaultBg(ImageAssetCategory cat) => switch (cat) {
    ImageAssetCategory.regionThumbnail        => AppTheme.borderLight,
    ImageAssetCategory.factionEmblem          => AppTheme.surfaceAlt,
    ImageAssetCategory.itemIcon               => AppTheme.surfaceAlt,
    ImageAssetCategory.dashboardMetricIcon    => AppTheme.surfaceAlt,
    ImageAssetCategory.livingsphereBackground => AppTheme.surfaceAlt,
  };
}

class _FallbackBox extends StatelessWidget {
  const _FallbackBox({
    required this.width,
    required this.height,
    required this.bg,
    required this.emoji,
    required this.br,
  });

  final double? width;
  final double? height;
  final Color bg;
  final String emoji;
  final BorderRadius br;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: bg, borderRadius: br),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
