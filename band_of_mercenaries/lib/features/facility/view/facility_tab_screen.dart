import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/features/facility/view/construction_queue_bar.dart';
import 'package:band_of_mercenaries/features/facility/view/facility_card.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';

class FacilityTabScreen extends ConsumerWidget {
  const FacilityTabScreen({super.key});

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0초';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h시간 $m분';
    if (m > 0) return '$m분 $s초';
    return '$s초';
  }

  Future<void> _startUpgrade(
    BuildContext context,
    WidgetRef ref,
    Facility facility,
    int level,
    double speedMultiplier,
  ) async {
    final nextLevel = level + 1;
    final cost = ConstructionService.calculateCost(facility, nextLevel);
    final duration = ConstructionService.calculateBuildDuration(facility, nextLevel, speedMultiplier);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${facility.name} 업그레이드'),
        content: Text(
          '${facility.name} Lv.$nextLevel 업그레이드?\n비용: ${cost}G\n소요시간: ${_formatDuration(duration)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userDataProvider.notifier).startConstruction(
        facility.id,
        cost,
        duration,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);
    ref.watch(gameTickProvider);
    final speedMultiplier = ref.watch(speedMultiplierProvider);

    return staticDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (staticData) {
        final userData = ref.watch(userDataProvider);
        if (userData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final facilities = staticData.facilities;

        return Column(
          children: [
            const ConstructionQueueBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: facilities.length,
                itemBuilder: (context, index) {
                  final facility = facilities[index];
                  final currentLevel = userData.facilities[facility.id] ?? 0;
                  final canUpgrade = ConstructionService.canStartConstruction(
                    facility,
                    currentLevel,
                    userData.gold,
                    userData.constructionFacilityId,
                  );

                  return FacilityCard(
                    facility: facility,
                    currentLevel: currentLevel,
                    isConstructing: userData.constructionFacilityId != null,
                    canUpgrade: canUpgrade,
                    onUpgrade: () => _startUpgrade(
                      context,
                      ref,
                      facility,
                      currentLevel,
                      speedMultiplier,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
