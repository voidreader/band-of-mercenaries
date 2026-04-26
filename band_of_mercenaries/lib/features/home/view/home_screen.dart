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
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_state.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';
import 'package:band_of_mercenaries/features/investigation/view/investigation_widget.dart';
import 'package:band_of_mercenaries/features/settings/view/settings_screen.dart';
import 'package:band_of_mercenaries/features/home/view/rank_bonus_summary_sheet.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_choice_recall_provider.dart';
import 'package:band_of_mercenaries/features/movement/view/travel_choice_recall_dialog.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isShowingQuestResult = false;
  final Set<String> _shownQuestResultIds = {};
  bool _showSettings = false;

  Future<void> _showQuestResult(ActiveQuest quest) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestResultDialog(quest: quest),
    );
    if (!mounted) return;
    ref.read(questListProvider.notifier).clearCompleted(quest.id);
    _isShowingQuestResult = false;
    final quests = ref.read(questListProvider);
    final nextCompleted = quests.where(
      (q) => q.status == QuestStatus.completed && !_shownQuestResultIds.contains(q.id),
    ).toList();
    if (nextCompleted.isNotEmpty) {
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

    // 이동 선택지 회상 팝업: 큐에 enqueue (FIFO, medium 우선순위)
    ref.listen<TravelChoiceRecallData?>(
      pendingTravelChoiceProvider,
      (prev, next) {
        if (next == null) return;
        final data = next;
        ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
          id: 'travelChoiceRecall_${data.event.id}_${DateTime.now().microsecondsSinceEpoch}',
          priority: DialogPriority.medium,
          dialogType: DialogTypeRegistry.travelChoiceRecall,
          payload: {'eventId': data.event.id},
          builder: (ctx, dismiss) => TravelChoiceRecallDialog(
            data: data,
            onDismiss: dismiss,
          ),
        ));
        ref.read(pendingTravelChoiceProvider.notifier).state = null;
      },
    );

    // 자동 이동 이벤트: 이동 완료 순간 감지 후 큐에 enqueue (medium 우선순위)
    ref.listen<MovementState?>(movementProvider, (previous, next) {
      final wasMoving = previous?.isMoving ?? false;
      final isMovingNow = next?.isMoving ?? false;
      if (!wasMoving || isMovingNow) return; // 이동 완료 순간만 처리

      final event = ref.read(lastTravelEventProvider);
      if (event == null) return;

      final TravelEventTraitResult? traitResult;
      final Mercenary? targetMerc;
      final TraitData? traitData;

      if (event.effectType == 'trait_innate') {
        traitResult = ref.read(lastTravelEventTraitResultProvider);
        final staticData = ref.read(staticDataProvider).value;
        final mercList = ref.read(mercenaryListProvider);
        targetMerc = traitResult != null
            ? mercList.where((m) => m.id == traitResult!.mercenaryId).firstOrNull
            : null;
        traitData = traitResult != null
            ? staticData?.traits.where((t) => t.key == traitResult!.traitKey).firstOrNull
            : null;
      } else {
        traitResult = null;
        targetMerc = null;
        traitData = null;
      }

      ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
        id: 'autoTravelEvent_${event.id}',
        priority: DialogPriority.medium,
        dialogType: DialogTypeRegistry.autoTravelEvent,
        payload: const {},
        builder: (ctx, dismiss) => _TravelEventDialog(
          event: event,
          traitResult: traitResult,
          merc: targetMerc,
          trait: traitData,
        ),
      ));
      ref.read(lastTravelEventProvider.notifier).state = null;
      ref.read(lastTravelEventTraitResultProvider.notifier).state = null;
    });

    if (userData == null) return const Center(child: CircularProgressIndicator());

    if (_showSettings) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () => setState(() => _showSettings = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Text('설정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Expanded(child: SettingsScreen()),
        ],
      );
    }

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
              Row(
                children: [
                  Text('대륙 ${userData.continent} : 지역 ${userData.region} : 섹터 ${userData.sector}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 18),
                    onPressed: () => setState(() => _showSettings = true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
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

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  showDragHandle: false,
                  builder: (ctx) => const RankBonusSummarySheet(),
                );
              },
              child: Container(
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
            ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),

        // Construction mini widget
        if (userData.constructionFacilityId != null)
          staticDataAsync.maybeWhen(
            data: (staticData) {
              final facility = staticData.facilities
                  .where((f) => f.id == userData.constructionFacilityId)
                  .firstOrNull;
              if (facility == null) return const SizedBox.shrink();
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
              final remainStr = remaining.isNegative
                  ? '완료'
                  : remaining.inMinutes > 0
                      ? '${remaining.inMinutes}분 ${remaining.inSeconds.remainder(60)}초'
                      : '${remaining.inSeconds}초';
              final currentLevel = userData.facilities[facility.id] ?? 0;
              return GestureDetector(
                onTap: () => ref.read(currentTabProvider.notifier).state = 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.tier3Bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.tier3.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🏗 ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              '${facility.name} Lv.${currentLevel + 1} 건설 중',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tier3,
                              ),
                            ),
                          ),
                          Text(
                            remainStr,
                            style: const TextStyle(fontSize: 11, color: AppTheme.tier3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
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
          ),

        // Investigation mini widget
        const InvestigationWidget(),

        // Dashboard
        staticDataAsync.maybeWhen(
          data: (staticData) => _DashboardSection(
            mercs: mercs,
            staticData: staticData,
            userData: userData,
          ),
          orElse: () => const SizedBox.shrink(),
        ),

        // Campsite + 하단 정보 (스크롤 가능 영역)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Campsite: 최소 80px, 최대 200px, 오버플로우 클리핑
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 80, maxHeight: 200),
                  child: ClipRect(
                    child: Container(
                      color: AppTheme.surfaceAlt,
                      width: double.infinity,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(300, 200),
                          painter: CampsitePainter(mercenaryCount: aliveMercs),
                        ),
                      ),
                    ),
                  ),
                ),

                // Activity log
                const _ActivityLog(),

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
            ),
          ),
        ),
      ],
    );
  }

}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.mercs,
    required this.staticData,
    required this.userData,
  });

  final List<Mercenary> mercs;
  final StaticGameData staticData;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    final dispatchedCount = mercs.where((m) => m.isDispatched).length;
    final injuredCount = mercs.where((m) => m.status == MercenaryStatus.injured).length;
    final deadCount = mercs.where((m) => m.status == MercenaryStatus.dead).length;
    final totalPower = mercs.where((m) => m.isAvailable).fold<int>(0, (sum, m) => sum + m.effectiveStr);

    final barracksData = staticData.facilities.where((f) => f.id == 'barracks').firstOrNull;
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
              _DashItem(label: '보유', value: '$aliveCount/$maxMercs', color: AppTheme.textSecondary),
              _DashItem(label: '파견 중', value: '$dispatchedCount', color: AppTheme.primary),
              _DashItem(label: '부상', value: '$injuredCount', color: AppTheme.failure),
              _DashItem(label: '사망', value: '$deadCount', color: AppTheme.criticalFailure),
            ],
          ),
          const SizedBox(height: 4),
          Text('총 전투력: $totalPower', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
        ],
      ),
    );
  }
}

class _DashItem extends StatelessWidget {
  const _DashItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        ],
      ),
    );
  }
}

class _ActivityLog extends ConsumerWidget {
  const _ActivityLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                final iconInfo = _logIcon(log.type);
                final timeAgo = _formatTimeAgo(log.timestamp);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        iconInfo.icon,
                        style: TextStyle(
                          fontSize: 12,
                          color: iconInfo.color,
                          fontWeight: iconInfo.bold ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
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

  ({String icon, Color color, bool bold}) _logIcon(ActivityLogType type) {
    const d = AppTheme.textSecondary;
    switch (type) {
      case ActivityLogType.questResult:
        return (icon: '⚔', color: d, bold: false);
      case ActivityLogType.mercenaryStatus:
        return (icon: '💊', color: d, bold: false);
      case ActivityLogType.movementComplete:
        return (icon: '🏕', color: d, bold: false);
      case ActivityLogType.mercenaryRecruit:
        return (icon: '🛡', color: d, bold: false);
      case ActivityLogType.mercenaryDismiss:
        return (icon: '👋', color: d, bold: false);
      case ActivityLogType.levelUp:
        return (icon: '⬆', color: d, bold: false);
      case ActivityLogType.traitAcquired:
        return (icon: '✦', color: d, bold: false);
      case ActivityLogType.traitEvolved:
        return (icon: '⭐', color: d, bold: false);
      case ActivityLogType.traitDeleted:
        return (icon: '🗑', color: d, bold: false);
      case ActivityLogType.facilityUpgrade:
        return (icon: '🏗', color: d, bold: false);
      case ActivityLogType.investigationSuccess:
        return (icon: '🔍', color: d, bold: false);
      case ActivityLogType.investigationFailed:
        return (icon: '❌', color: d, bold: false);
      case ActivityLogType.discoveryFound:
        return (icon: '💎', color: d, bold: false);
      case ActivityLogType.reputationRankUp:
        return (icon: '🎖', color: d, bold: false);
      case ActivityLogType.reputationRankDown:
        return (icon: '📉', color: d, bold: false);
      case ActivityLogType.essenceApplied:
        return (icon: '✧', color: d, bold: false);
      case ActivityLogType.essenceLostOnDeath:
        return (icon: '💀', color: d, bold: false);
      case ActivityLogType.essenceLostOnRelease:
        return (icon: '👋', color: d, bold: false);
      case ActivityLogType.regionTransform:
        return (icon: '🗺️', color: AppTheme.transformHidden, bold: false);
      case ActivityLogType.chainProgressed:
        return (icon: '⛓️', color: AppTheme.primary, bold: false);
      case ActivityLogType.chainCompleted:
        return (icon: '⛓️', color: AppTheme.chainGold, bold: true);
      case ActivityLogType.travelChoiceCompleted:
        return (icon: '🛤️', color: AppTheme.textSecondary, bold: false);
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

class _TravelEventDialog extends StatelessWidget {
  const _TravelEventDialog({
    required this.event,
    this.traitResult,
    this.merc,
    this.trait,
  });

  final TravelEvent event;
  final TravelEventTraitResult? traitResult;
  final Mercenary? merc;
  final TraitData? trait;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('여행 중 사건 발생!'),
      content: _TravelEventDialogContent(
        event: event,
        traitResult: traitResult,
        merc: merc,
        trait: trait,
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _TravelEventDialogContent extends StatelessWidget {
  const _TravelEventDialogContent({
    required this.event,
    this.traitResult,
    this.merc,
    this.trait,
  });

  final TravelEvent event;
  final TravelEventTraitResult? traitResult;
  final Mercenary? merc;
  final TraitData? trait;

  @override
  Widget build(BuildContext context) {
    if (traitResult == null) {
      return Text(event.description);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event.description),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        if (merc != null)
          Text(
            '${merc!.name}가 새로운 선천 트레잇을 획득했습니다!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        if (trait != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trait!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  trait!.categoryKey,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
                if (trait!.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trait!.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
