import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_transformed_provider.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';

class RegionTransformDialog extends ConsumerWidget {
  final RegionTransformedEvent event;
  final VoidCallback onDismiss;

  const RegionTransformDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeColor = _badgeColor(event.transformType);
    return AlertDialog(
      title: const Text('✨ 지역 변형'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유형 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor),
            ),
            child: Text(
              '[${_typeName(event.transformType)}] ${event.transformedName}',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(event.narrativeRendered),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(currentTabProvider.notifier).state = 0;
            onDismiss();
          },
          child: const Text('이동 화면으로'),
        ),
        TextButton(
          onPressed: onDismiss,
          child: const Text('확인'),
        ),
      ],
    );
  }

  Color _badgeColor(String type) {
    return switch (type) {
      'village' => AppTheme.transformVillage,
      'ruins' => AppTheme.transformRuins,
      'hidden' => AppTheme.transformHidden,
      _ => AppTheme.transformFallback,
    };
  }

  String _typeName(String type) {
    return switch (type) {
      'village' => '마을',
      'ruins' => '유적지',
      'hidden' => '숨겨진 섹터',
      _ => type,
    };
  }
}
