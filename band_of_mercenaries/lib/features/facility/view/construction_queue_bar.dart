import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';

class ConstructionQueueBar extends ConsumerWidget {
  const ConstructionQueueBar({super.key});

  String _formatDuration(Duration d) {
    if (d.isNegative) return '완료';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h시간 $m분';
    if (m > 0) return '$m분 $s초';
    return '$s초';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    if (userData == null || userData.constructionFacilityId == null) {
      return const SizedBox.shrink();
    }

    ref.watch(gameTickProvider);

    final staticDataAsync = ref.watch(staticDataProvider);
    final facilityId = userData.constructionFacilityId!;
    final endTime = userData.constructionEndTime;
    final startTime = userData.constructionStartTime;

    final now = DateTime.now();
    final remaining = endTime != null ? endTime.difference(now) : Duration.zero;
    final total = (endTime != null && startTime != null)
        ? endTime.difference(startTime)
        : Duration.zero;
    final progress = (total.inSeconds > 0)
        ? (1.0 - remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 1.0;

    return staticDataAsync.maybeWhen(
      data: (staticData) {
        final facility = staticData.facilities
            .where((f) => f.id == facilityId)
            .firstOrNull;
        if (facility == null) return const SizedBox.shrink();

        final currentLevel = userData.facilities[facilityId] ?? 0;
        final nextLevel = currentLevel + 1;
        final refundGold = ConstructionService.calculateCost(facility, nextLevel);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.tier3Bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.tier3.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${facility.name} Lv.$currentLevel → Lv.$nextLevel',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.tier3,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(remaining),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.tier3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('건설 취소'),
                            content: Text(
                              '건설을 취소하시겠습니까?\n비용 ${refundGold}G가 환불됩니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('아니오'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('취소'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(userDataProvider.notifier)
                              .cancelConstruction(refundGold);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 12, color: AppTheme.tier5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tier3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
