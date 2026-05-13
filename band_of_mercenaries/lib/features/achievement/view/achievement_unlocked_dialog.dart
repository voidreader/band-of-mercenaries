import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';

class AchievementUnlockedDialog extends ConsumerWidget {
  final BandAchievement achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockedDialog({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final template = staticData?.bandAchievementTemplates
        .where((t) => t.id == achievement.templateId)
        .firstOrNull;

    // EC-5 폴백: template 미존재 시 이름은 "알 수 없는 위업"으로 표시
    final name = template?.name ?? '알 수 없는 위업';
    final renderedDescription = ref.watch(
      renderedAchievementProvider(achievement.id),
    );
    final mercSnapshot = achievement.mercSnapshot;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.chainGold),
          const SizedBox(width: 8),
          const Text('새로운 위업'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.chainGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (mercSnapshot != null) ...[
            Text(
              '주인공: ${mercSnapshot.name} (T${mercSnapshot.tier} ${mercSnapshot.jobName})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text(
            renderedDescription.isEmpty
                ? (template?.descriptionTemplate ?? achievement.templateId)
                : renderedDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
