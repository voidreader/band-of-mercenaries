import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class DispatchScreen extends ConsumerStatefulWidget {
  const DispatchScreen({super.key});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  String? _selectedQuestId;
  final Set<String> _selectedMercIds = {};
  bool _isShowingResult = false;
  final Set<String> _shownResultIds = {};

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final quests = ref.watch(questListProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    if (userData.isMoving) {
      return const Center(
        child: Text('이동 중에는 파견할 수 없습니다', style: TextStyle(fontSize: 16, color: AppTheme.textHint)),
      );
    }

    ref.listen<List<ActiveQuest>>(questListProvider, (previous, next) {
      if (_isShowingResult) return;
      final completed = next.where(
        (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
      ).toList();
      if (completed.isNotEmpty) {
        _isShowingResult = true;
        _shownResultIds.add(completed.first.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showResult(context, completed.first, ref);
          }
        });
      }
    });

    final pendingQuests = quests.where((q) => q.status == QuestStatus.pending).toList();
    final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();

    return staticData.when(
      data: (data) {
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
                  Text('${data.regions.firstWhere((r) => r.region == userData.region).regionName} (지역 ${userData.region})',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // In-progress quests
                    for (final quest in inProgressQuests)
                      if (quest.endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.tier3Bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TimerDisplay(
                              label: '⚔ ${quest.questName}',
                              remaining: quest.endTime!.difference(DateTime.now()),
                            ),
                          ),
                        ),

                    // Quest list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('가능한 퀘스트 (${pendingQuests.length}개)',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
                        if (pendingQuests.isEmpty)
                          TextButton(
                            onPressed: () => ref.read(questListProvider.notifier).generateQuests(),
                            child: const Text('퀘스트 생성'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    for (final quest in pendingQuests)
                      _buildQuestCard(quest, data),

                    // Fill quests button
                    Builder(builder: (context) {
                      final maxCount = ref.read(questListProvider.notifier).getMaxQuestCount();
                      final activeCount = quests.where(
                        (q) => q.status == QuestStatus.pending || q.status == QuestStatus.inProgress,
                      ).length;
                      if (activeCount >= maxCount) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => ref.read(questListProvider.notifier).fillQuests(),
                            child: Text('퀘스트 채우기 ($activeCount/$maxCount)'),
                          ),
                        ),
                      );
                    }),

                    // Dispatch panel
                    if (_selectedQuestId != null) ...[
                      const SizedBox(height: 12),
                      _buildDispatchPanel(mercs, data),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildQuestCard(ActiveQuest quest, StaticGameData data) {
    final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final isSelected = _selectedQuestId == quest.id;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedQuestId = isSelected ? null : quest.id;
        _selectedMercIds.clear();
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(quest.questName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(questType.name, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('난이도 ${quest.difficulty} · 보상 ${questType.baseReward}G · 소요 ${questType.baseDuration}초',
                style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
            if (quest.status == QuestStatus.pending && quest.createdAt != null)
              Builder(builder: (_) {
                final speedMult = ref.read(speedMultiplierProvider);
                final realElapsed = DateTime.now().difference(quest.createdAt!);
                final gameElapsedMs = (realElapsed.inMilliseconds * speedMult).round();
                final gameElapsed = Duration(milliseconds: gameElapsedMs);
                final remaining = const Duration(hours: 1) - gameElapsed;
                if (remaining.isNegative) return const SizedBox.shrink();
                final mins = remaining.inMinutes;
                final secs = remaining.inSeconds % 60;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '갱신까지 ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchPanel(List<Mercenary> mercs, StaticGameData data) {
    final userData = ref.read(userDataProvider);
    final quest = ref.read(questListProvider).firstWhere((q) => q.id == _selectedQuestId);
    final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final difficulty = data.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => data.difficulties.first,
    );
    final selectedMercs = mercs.where((m) => _selectedMercIds.contains(m.id)).toList();
    final partyPower = selectedMercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);

    // Cost/profit calculations
    final grossReward = QuestCalculator.calculateReward(
      baseReward: questType.baseReward,
      rewardMultiplier: difficulty.rewardMultiplier,
    );
    final mercTiers = selectedMercs.map((merc) {
      final job = data.jobs.firstWhere(
        (j) => j.id == merc.jobId,
        orElse: () => data.jobs.first,
      );
      return job.tier;
    }).toList();
    final totalWage = QuestCalculator.calculateTotalWage(mercTiers, data.mercenaryWages);
    final dispatchCost = QuestCalculator.calculateDispatchCost(
      baseDuration: questType.baseDuration,
      difficulty: quest.difficulty,
      minCost: difficulty.minDispatchCost,
      maxCost: difficulty.maxDispatchCost,
    );
    final netProfit = QuestCalculator.calculateNetProfit(
      totalReward: grossReward,
      totalWage: totalWage,
      dispatchCost: dispatchCost,
    );

    final hasEnoughGold = userData != null && userData.gold >= dispatchCost;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('파견 인원 선택', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: mercs.map((merc) {
              final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
              final isSelected = _selectedMercIds.contains(merc.id);
              final canSelect = merc.isAvailable;

              return GestureDetector(
                onTap: canSelect
                    ? () => setState(() {
                          if (isSelected) {
                            _selectedMercIds.remove(merc.id);
                          } else {
                            _selectedMercIds.add(merc.id);
                          }
                        })
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: canSelect ? AppTheme.border : AppTheme.borderLight),
                  ),
                  child: Text(
                    '${isSelected ? '✓ ' : ''}${merc.name} (${job.name})',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : (canSelect ? AppTheme.textSecondary : const Color(0xFF999999)),
                      decoration: canSelect ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            '예상 성공률: ${_selectedMercIds.isEmpty ? "-" : "${(partyPower / difficulty.enemyPower * 50 + 50).clamp(5, 95).round()}%"} · 전투력: $partyPower/${difficulty.enemyPower}',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (_selectedMercIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCostBreakdown(
              grossReward: grossReward,
              totalWage: totalWage,
              dispatchCost: dispatchCost,
              netProfit: netProfit,
            ),
          ],
          const SizedBox(height: 10),
          if (!hasEnoughGold)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '골드가 부족합니다 (파견비용: ${dispatchCost}G)',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedMercIds.isEmpty || !hasEnoughGold)
                  ? null
                  : () {
                      ref.read(questListProvider.notifier)
                          .dispatch(_selectedQuestId!, _selectedMercIds.toList());
                      setState(() {
                        _selectedQuestId = null;
                        _selectedMercIds.clear();
                      });
                    },
              child: const Text('파견 출발'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown({
    required int grossReward,
    required int totalWage,
    required int dispatchCost,
    required int netProfit,
  }) {
    final netColor = netProfit >= 0 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          _buildBreakdownRow('예상 보상', '${grossReward}G', AppTheme.textSecondary),
          const SizedBox(height: 4),
          _buildBreakdownRow('인건비', '-${totalWage}G', AppTheme.textTertiary),
          const SizedBox(height: 4),
          _buildBreakdownRow('파견비용', '-${dispatchCost}G', AppTheme.textTertiary),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          _buildBreakdownRow(
            '예상 순수익',
            '${netProfit}G',
            netColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _showResult(BuildContext context, ActiveQuest quest, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestResultDialog(quest: quest),
    );
    // 다이얼로그 닫힘 후 퀘스트 정리
    ref.read(questListProvider.notifier).clearCompleted(quest.id);
    _isShowingResult = false;
    // 다음 완료된 퀘스트가 있으면 표시
    if (mounted) {
      final quests = ref.read(questListProvider);
      final nextCompleted = quests.where(
        (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
      ).toList();
      if (nextCompleted.isNotEmpty) {
        _isShowingResult = true;
        _shownResultIds.add(nextCompleted.first.id);
        _showResult(context, nextCompleted.first, ref);
      }
    }
  }
}
