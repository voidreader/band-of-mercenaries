import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_flag_descriptions.dart';

class RegionStatusBadgeRow extends ConsumerWidget {
  final int regionId;
  const RegionStatusBadgeRow({super.key, required this.regionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(regionStateRepositoryProvider).getState(regionId);
    final dangerLevel = state?.currentDangerLevel ?? 2;
    final flags = state?.unlockedFlags ?? const <String>[];

    final dangerColor = AppTheme.dangerLevelColor(dangerLevel);
    final dangerLabel = AppTheme.dangerLevelLabel(dangerLevel);

    final knownFlags = flags
        .where((f) => regionStateFlagShortDescriptions.containsKey(f))
        .toList();
    final visibleFlags = knownFlags.take(2).toList();
    final overflow = knownFlags.length - visibleFlags.length;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: dangerColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: dangerColor, width: 1),
          ),
          child: Text('● $dangerLabel',
              style: TextStyle(fontSize: 11, color: dangerColor, fontWeight: FontWeight.w600)),
        ),
        for (final flag in visibleFlags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.chainGold, width: 1),
            ),
            child: Text('✓ ${regionStateFlagShortDescriptions[flag]}',
                style: const TextStyle(fontSize: 10, color: AppTheme.chainGold)),
          ),
        if (overflow > 0)
          Text('+$overflow', style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
      ],
    );
  }
}
