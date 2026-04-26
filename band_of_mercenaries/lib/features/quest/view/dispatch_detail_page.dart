import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_synergy_matrix.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';
import 'package:band_of_mercenaries/features/quest/domain/success_rate_breakdown.dart';
import 'package:band_of_mercenaries/features/quest/view/success_rate_breakdown_sheet.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_effect_context.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';

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

        final availableMercs = mercs.where((m) =>
          m.status != MercenaryStatus.dead &&
          !m.isDispatched &&
          m.id != userData.investigatingMercId
        ).toList();

        final selectedMercs = mercs.where((m) => _selectedMercIds.contains(m.id)).toList();
        final equipmentBonuses = EquipmentEffectContext.forPartySync(
          ref, selectedMercs.map((m) => m.id).toList(),
        );
        final partyPower = QuestCalculator.calculatePartyPower(
          selectedMercs,
          quest.questTypeId,
          equipmentBonuses: equipmentBonuses,
        );
        final partyRoles = RoleUtils.extractRoles(selectedMercs, data.jobs);
        final SuccessRateBreakdown breakdown = QuestCalculator.calculateSuccessRateBreakdown(
          partyPower: partyPower,
          enemyPower: difficulty.enemyPower,
          traitBonuses: selectedMercs.expand((m) => m.allTraitIds).toSet().toList(),
          questTypeId: quest.questTypeId,
          distancePenalty: (quest.region - userData.region).abs(),
          allTraits: data.traits,
          partySize: selectedMercs.length,
          factionPassiveBonus: 0.0,
          passiveSharedCapLoss: 0.0,
          partyRoles: partyRoles,
        );

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

        final factionForQuest = quest.factionTag != null
            ? data.factions.where((f) => f.id == quest.factionTag).firstOrNull
            : null;

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
                          IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back, size: 22),
                          ),
                          Expanded(
                            child: Text(quest.questName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (quest.isFactionExclusive && factionForQuest != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${factionForQuest.name} · ${quest.isAdvancedTrack == true ? '고급 트랙' : '기본 트랙'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: FactionData.parseColor(factionForQuest.color),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (quest.factionTag != null && factionForQuest != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: FactionData.parseColor(factionForQuest.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              factionForQuest.name,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${questType.name} · 난이도 ${quest.difficulty} · 보상 ${grossReward}G · 소요 ${questType.baseDuration}초',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),

                // Elite lore card
                if (quest.isElite)
                  Builder(builder: (_) {
                    final EliteMonsterData? eliteData =
                        data.eliteMonsters.where((m) => m.id == quest.eliteId).firstOrNull;
                    if (eliteData == null) return const SizedBox.shrink();
                    final isUnique = eliteData.isUnique;
                    final borderColor = isUnique ? AppTheme.eliteUniqueBorder : AppTheme.eliteBorder;
                    final gradientColors = isUnique
                        ? [AppTheme.eliteUniqueBg, const Color(0xFF2d0040)]
                        : [AppTheme.eliteBg, const Color(0xFF2d1500)];
                    final icon = isUnique ? '★' : '🔥';
                    final titleText = isUnique ? (eliteData.title ?? '유니크') : '엘리트 몬스터';
                    final bodyText = isUnique ? (eliteData.lore ?? '') : eliteData.description;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$icon $titleText',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: borderColor,
                            ),
                          ),
                          if (bodyText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bodyText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

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
                            final roleBonus = RoleSynergyMatrix.singleBonus(job.role, quest.questTypeId);
                            final isHighlighted = roleBonus >= 5.0;
                            final cardColor = isHighlighted
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                                : AppTheme.surface;
                            final showBadge = roleBonus.abs() >= 0.1;
                            final badgeText = '${roleBonus > 0 ? '+' : ''}${roleBonus.toStringAsFixed(1)}';

                            return Opacity(
                              opacity: canSelect ? 1.0 : 0.5,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: cardColor,
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
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${merc.name} (${job.name})',
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (showBadge) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          badgeText,
                                          style: TextStyle(
                                            color: roleBonus > 0
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    '전투력: ${merc.effectiveStr}',
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '성공률: ${_selectedMercIds.isEmpty ? "-" : "${QuestCalculator.calculateSuccessRatePreview(partyPower: partyPower, enemyPower: difficulty.enemyPower, traitBonuses: selectedMercs.expand((m) => m.allTraitIds).toSet().toList(), questTypeId: quest.questTypeId, distancePenalty: (quest.region - userData.region).abs(), allTraits: data.traits, partySize: selectedMercs.length, partyRoles: partyRoles).round()}%"}',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.help_outline, size: 18),
                                tooltip: '성공률 분해',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                                onPressed: selectedMercs.isEmpty
                                    ? null
                                    : () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: false,
                                          showDragHandle: false,
                                          builder: (ctx) => SuccessRateBreakdownSheet(breakdown: breakdown),
                                        );
                                      },
                              ),
                            ],
                          ),
                          Text(
                            '순수익: ${_selectedMercIds.isEmpty ? "-" : "${netProfit}G"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedMercIds.isEmpty
                                  ? AppTheme.textSecondary
                                  : (netProfit >= 0 ? AppTheme.success : AppTheme.criticalFailure),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (!hasEnoughGold && _selectedMercIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('골드가 부족합니다 (파견비용: ${dispatchCost}G)',
                            style: const TextStyle(fontSize: 12, color: AppTheme.criticalFailure)),
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
