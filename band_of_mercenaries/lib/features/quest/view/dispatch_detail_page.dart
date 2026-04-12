import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

class DispatchDetailPage extends ConsumerStatefulWidget {
  final String questId;
  final VoidCallback onBack;

  const DispatchDetailPage({super.key, required this.questId, required this.onBack});

  @override
  ConsumerState<DispatchDetailPage> createState() => _DispatchDetailPageState();
}

class _DispatchDetailPageState extends ConsumerState<DispatchDetailPage> {
  final Set<String> _selectedMercIds = {};

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questListProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);
    final userData = ref.watch(userDataProvider);

    final quest = quests.where((q) => q.id == widget.questId).firstOrNull;
    if (quest == null || userData == null) {
      return const Center(child: Text('퀘스트를 찾을 수 없습니다'));
    }

    return staticData.when(
      data: (data) {
        final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
        final difficulty = data.difficulties.firstWhere(
          (d) => d.level == quest.difficulty.clamp(1, 5),
          orElse: () => data.difficulties.first,
        );

        // Filter mercenaries: exclude dead and dispatched
        final availableMercs = mercs.where((m) =>
          m.status != MercenaryStatus.dead && !m.isDispatched
        ).toList();

        final selectedMercs = mercs.where((m) => _selectedMercIds.contains(m.id)).toList();
        final partyPower = selectedMercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);

        final grossReward = QuestCalculator.calculateReward(
          baseReward: questType.baseReward,
          rewardMultiplier: difficulty.rewardMultiplier,
        );
        final mercTiers = selectedMercs.map((merc) {
          final job = data.jobs.firstWhere((j) => j.id == merc.jobId, orElse: () => data.jobs.first);
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
          totalReward: grossReward, totalWage: totalWage, dispatchCost: dispatchCost,
        );
        final hasEnoughGold = userData.gold >= dispatchCost;

        return Column(
              children: [
                // Top fixed: Quest info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onBack,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_back, size: 22),
                            ),
                          ),
                          Expanded(
                            child: Text(quest.questName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${questType.name} · 난이도 ${quest.difficulty} · 보상 ${grossReward}G · 소요 ${questType.baseDuration}초',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),

                // Middle scroll: Mercenary list
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Text('파견 가능한 용병 (${availableMercs.length}명)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: availableMercs.length,
                          itemBuilder: (_, index) {
                            final merc = availableMercs[index];
                            final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
                            final isSelected = _selectedMercIds.contains(merc.id);
                            final canSelect = merc.status != MercenaryStatus.injured;

                            return Opacity(
                              opacity: canSelect ? 1.0 : 0.5,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  enabled: canSelect,
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: canSelect
                                        ? (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedMercIds.add(merc.id);
                                              } else {
                                                _selectedMercIds.remove(merc.id);
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                  title: Text(
                                    '${merc.name} (${job.name})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '전투력: ${merc.effectiveAtk}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                                  ),
                                  trailing: merc.status == MercenaryStatus.injured
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.failureBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('부상',
                                            style: TextStyle(fontSize: 11, color: AppTheme.failure, fontWeight: FontWeight.w600)),
                                        )
                                      : Text(
                                          merc.status == MercenaryStatus.tired ? '피곤함' : '정상',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom fixed: Cost summary + dispatch button
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '성공률: ${_selectedMercIds.isEmpty ? "-" : "${QuestCalculator.calculateSuccessRatePreview(partyPower: partyPower, enemyPower: difficulty.enemyPower, traitBonuses: selectedMercs.map((m) => m.traitId).toList(), questTypeId: quest.questTypeId, distancePenalty: (quest.region - userData.region).abs()).round()}%"}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          Text(
                            '순수익: ${_selectedMercIds.isEmpty ? "-" : "${netProfit}G"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedMercIds.isEmpty
                                  ? AppTheme.textSecondary
                                  : (netProfit >= 0 ? Colors.green : Colors.red),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (!hasEnoughGold && _selectedMercIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('골드가 부족합니다 (파견비용: ${dispatchCost}G)',
                            style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedMercIds.isEmpty || !hasEnoughGold)
                              ? null
                              : () async {
                                  final success = await ref.read(questListProvider.notifier)
                                      .dispatch(widget.questId, _selectedMercIds.toList());
                                  if (success && mounted) {
                                    widget.onBack();
                                  }
                                },
                          child: const Text('파견 출발'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
