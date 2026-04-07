import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/home/view/campsite_painter.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final quests = ref.watch(questListProvider);
    ref.watch(movementProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
    final aliveMercs = mercs.where((m) => m.status != MercenaryStatus.dead).length;

    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('대륙 ${userData.continent} : 지역 ${userData.region} : 섹터 ${userData.sector}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
            ],
          ),
        ),

        // Campsite
        Expanded(
          child: Container(
            color: AppTheme.surfaceAlt,
            child: Center(
              child: CustomPaint(
                size: const Size(300, 200),
                painter: CampsitePainter(mercenaryCount: aliveMercs),
              ),
            ),
          ),
        ),

        // Progress panel
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('진행 상황', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (userData.isMoving && userData.moveEndTime != null)
                TimerDisplay(
                  label: '🗺 이동 → 지역 ${userData.moveTargetRegion}',
                  remaining: userData.moveEndTime!.difference(DateTime.now()),
                ),
              for (final quest in inProgressQuests)
                if (quest.endTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TimerDisplay(
                      label: '⚔ ${quest.questName}',
                      remaining: quest.endTime!.difference(DateTime.now()),
                    ),
                  ),
              if (!userData.isMoving && inProgressQuests.isEmpty)
                const Text('진행 중인 활동이 없습니다',
                    style: TextStyle(fontSize: 14, color: AppTheme.textHint)),
            ],
          ),
        ),
      ],
    );
  }
}
