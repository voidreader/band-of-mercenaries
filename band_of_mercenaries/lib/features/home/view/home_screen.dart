import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/home/view/campsite_painter.dart';
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _wasMoving = false;

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final quests = ref.watch(questListProvider);
    final movementState = ref.watch(movementProvider);
    ref.watch(gameTickProvider);
    final staticDataAsync = ref.watch(staticDataProvider);

    // Travel event listener: detect when movement completes
    final isMovingNow = movementState?.isMoving ?? false;
    if (_wasMoving && !isMovingNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final event = ref.read(lastTravelEventProvider);
        if (event != null && mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('여행 중 사건 발생!'),
              content: Text(event.description),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          ref.read(lastTravelEventProvider.notifier).state = null;
        }
      });
    }
    _wasMoving = isMovingNow;

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

        // Rank display
        staticDataAsync.maybeWhen(
          data: (staticData) {
            final currentRank = ReputationService.getCurrentRank(userData.reputation, staticData.ranks);
            final nextRank = ReputationService.getNextRank(userData.reputation, staticData.ranks);
            final isTopRank = nextRank == null;
            final progressValue = isTopRank
                ? 1.0
                : ((userData.reputation - currentRank.requiredReputation) /
                        (nextRank.requiredReputation - currentRank.requiredReputation))
                    .clamp(0.0, 1.0);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceAlt,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.tier3Bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentRank.grade,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.tier3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentRank.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        isTopRank
                            ? '명성: ${userData.reputation} (최고 등급)'
                            : '명성: ${userData.reputation} / ${nextRank.requiredReputation}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                  if (!isTopRank) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 4,
                        backgroundColor: AppTheme.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tier3),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
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
