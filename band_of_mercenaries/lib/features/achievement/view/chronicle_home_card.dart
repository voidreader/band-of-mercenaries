import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';

class ChronicleHomeCard extends ConsumerWidget {
  final VoidCallback? onTap;
  const ChronicleHomeCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(bandAchievementsProvider);
    final latest = achievements.isEmpty ? null : achievements.first;
    final hasNew = latest != null &&
        latest.achievedAt.isAfter(
          DateTime.now().subtract(const Duration(hours: 24)),
        );

    final staticData = ref.watch(staticDataProvider).valueOrNull;
    String? latestName;
    if (latest != null) {
      if (latest.type == BandAchievementType.memorial) {
        latestName = latest.mercSnapshot != null
            ? '${latest.mercSnapshot!.name}의 기록'
            : '추모';
      } else {
        final template = staticData?.bandAchievementTemplates
            .where((t) => t.id == latest.templateId)
            .firstOrNull;
        latestName = template?.name ?? '알 수 없는 위업';
      }
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.chainGold),
                  const SizedBox(width: 8),
                  Text('연대기', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (hasNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.chainGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEW',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (latestName != null)
                Text(
                  latestName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  '용병단의 첫 위업을 기다립니다',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '전체 연대기 보기 →',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
