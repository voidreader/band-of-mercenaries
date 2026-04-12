import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/home/view/campsite_painter.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
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
  bool _isShowingQuestResult = false;
  final Set<String> _shownQuestResultIds = {};

  Future<void> _showQuestResult(ActiveQuest quest) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestResultDialog(quest: quest),
    );
    ref.read(questListProvider.notifier).clearCompleted(quest.id);
    _isShowingQuestResult = false;
    final quests = ref.read(questListProvider);
    final nextCompleted = quests.where(
      (q) => q.status == QuestStatus.completed && !_shownQuestResultIds.contains(q.id),
    ).toList();
    if (nextCompleted.isNotEmpty && mounted) {
      _isShowingQuestResult = true;
      _shownQuestResultIds.add(nextCompleted.first.id);
      _showQuestResult(nextCompleted.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final quests = ref.watch(questListProvider);
    final movementState = ref.watch(movementProvider);
    ref.watch(gameTickProvider);
    final staticDataAsync = ref.watch(staticDataProvider);

    // Quest completion detection
    ref.listen<List<ActiveQuest>>(questListProvider, (prev, next) {
      if (_isShowingQuestResult) return;
      final completed = next.where(
        (q) => q.status == QuestStatus.completed && !_shownQuestResultIds.contains(q.id),
      ).toList();
      if (completed.isNotEmpty) {
        _isShowingQuestResult = true;
        _shownQuestResultIds.add(completed.first.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showQuestResult(completed.first);
        });
      }
    });

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

        // Dashboard
        staticDataAsync.maybeWhen(
          data: (staticData) => _buildDashboard(mercs, staticData, userData),
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

        // Activity log
        _buildActivityLog(),

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

  Widget _buildDashboard(List<Mercenary> mercs, StaticGameData data, UserData userData) {
    final dispatchedCount = mercs.where((m) => m.isDispatched).length;
    final injuredCount = mercs.where((m) => m.status == MercenaryStatus.injured).length;
    final deadCount = mercs.where((m) => m.status == MercenaryStatus.dead).length;
    final totalPower = mercs.where((m) => m.isAvailable).fold<int>(0, (sum, m) => sum + m.effectiveAtk);

    final barracksData = data.facilities.where((f) => f.id == 'barracks').firstOrNull;
    final barracksLevel = userData.facilities['barracks'] ?? 0;
    final maxMercs = barracksData != null
        ? FacilityService.getMaxMercenaries(barracksData, barracksLevel)
        : 10;
    final aliveCount = mercs.where((m) => m.status != MercenaryStatus.dead).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('용병단 현황', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _dashItem('보유', '$aliveCount/$maxMercs', AppTheme.textSecondary),
              _dashItem('파견 중', '$dispatchedCount', AppTheme.primary),
              _dashItem('부상', '$injuredCount', Colors.orange),
              _dashItem('사망', '$deadCount', Colors.red),
            ],
          ),
          const SizedBox(height: 4),
          Text('총 전투력: $totalPower', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Widget _dashItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    final logs = ref.watch(activityLogProvider);

    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text('아직 활동 기록이 없습니다.', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
      );
    }

    final displayLogs = logs.take(100).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('최근 활동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView.builder(
              itemCount: displayLogs.length,
              itemBuilder: (_, index) {
                final log = displayLogs[index];
                final icon = _logIcon(log.type);
                final timeAgo = _formatTimeAgo(log.timestamp);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(log.message,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(timeAgo, style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _logIcon(ActivityLogType type) {
    switch (type) {
      case ActivityLogType.questResult: return '⚔';
      case ActivityLogType.mercenaryStatus: return '💊';
      case ActivityLogType.movementComplete: return '🏕';
      case ActivityLogType.mercenaryRecruit: return '🛡';
      case ActivityLogType.mercenaryDismiss: return '👋';
      case ActivityLogType.levelUp: return '⬆';
      case ActivityLogType.traitAcquired: return '✦';
      case ActivityLogType.traitEvolved: return '⭐';
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
