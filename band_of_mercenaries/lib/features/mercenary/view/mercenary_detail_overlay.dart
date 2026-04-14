import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_deletion_service.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_slot_grid.dart';
import 'package:band_of_mercenaries/features/mercenary/view/behavior_stats_section.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_history_section.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_detail_dialog.dart';
import 'package:band_of_mercenaries/shared/widgets/status_badge.dart';

class MercenaryDetailOverlay extends ConsumerWidget {
  final String mercenaryId;

  const MercenaryDetailOverlay({super.key, required this.mercenaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercs = ref.watch(mercenaryListProvider);
    final staticDataAsync = ref.watch(staticDataProvider);

    final merc = mercs.where((m) => m.id == mercenaryId).firstOrNull;

    if (merc == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedMercenaryIdProvider.notifier).state = null;
      });
      return const SizedBox.shrink();
    }

    return Material(
      color: AppTheme.background,
      child: staticDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            '데이터 로드 실패: $err',
            style: const TextStyle(color: AppTheme.textHint),
          ),
        ),
        data: (staticData) {
          final allTraits = staticData.traits;
          final job = staticData.jobs.where((j) => j.id == merc.jobId).firstOrNull;

          final resolvedTraits = merc.allTraitIds
              .map((id) => allTraits.where((t) => t.key == id).firstOrNull)
              .whereType<TraitData>()
              .toList();

          final innateTraits = resolvedTraits.where((t) => t.type == 'innate').toList();
          final acquiredTraits = resolvedTraits.where((t) => t.type != 'innate').toList();

          final singleCandidates = TraitEvolutionService.checkSingleEvolutions(
            stats: merc.stats,
            currentTraitIds: merc.allTraitIds,
            transitions: staticData.traitTransitions,
            allTraits: allTraits,
          );
          final comboCandidates = TraitEvolutionService.checkComboEvolutions(
            currentTraitIds: merc.allTraitIds,
            comboEvolutions: staticData.traitComboEvolutions,
            allTraits: allTraits,
          );

          final evolvableKeys = <String>{
            ...singleCandidates.map((c) => c.fromKey),
            ...comboCandidates.expand((c) => [c.trait1Key, c.trait2Key]),
          };

          void onTraitTap(TraitData trait) {
            final userData = ref.read(userDataProvider);
            final infirmaryLevel = userData?.facilities['infirmary'] ?? 0;
            final currentGold = userData?.gold ?? 0;

            showDialog<void>(
              context: context,
              builder: (_) => TraitDetailDialog(
                trait: trait,
                mercenary: merc,
                allTraits: staticData.traits,
                transitions: staticData.traitTransitions,
                comboEvolutions: staticData.traitComboEvolutions,
                conflicts: staticData.traitConflicts,
                synergies: staticData.traitSynergies,
                infirmaryLevel: infirmaryLevel,
                currentGold: currentGold,
                isDispatched: merc.isDispatched,
                onDelete: () {
                  final cost = TraitDeletionService.deletionCost(trait);
                  ref.read(userDataProvider.notifier).spendGold(cost);
                  ref.read(mercenaryRepositoryProvider).deleteTrait(merc.id, trait.key);
                  ref.read(activityLogProvider.notifier).addLog(
                    '${merc.name}의 [${trait.name}] 트레잇이 제거되었다',
                    ActivityLogType.traitDeleted,
                  );
                  ref.read(mercenaryListProvider.notifier).refresh();
                },
              ),
            );
          }

          return Column(
            children: [
              _buildHeaderBar(context, ref),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(merc, job),
                      const SizedBox(height: 16),
                      TraitSlotGrid(
                        innateTraits: innateTraits,
                        acquiredTraits: acquiredTraits,
                        evolvableTraitKeys: evolvableKeys,
                        onTraitTap: onTraitTap,
                      ),
                      const SizedBox(height: 16),
                      BehaviorStatsSection(stats: merc.stats),
                      const SizedBox(height: 16),
                      TraitHistorySection(
                        traitHistory: merc.traitHistory,
                        deletedTraitIds: merc.deletedTraitIds,
                        allTraits: allTraits,
                        transitions: staticData.traitTransitions,
                        comboEvolutions: staticData.traitComboEvolutions,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () {
              ref.read(selectedMercenaryIdProvider.notifier).state = null;
            },
            color: AppTheme.textPrimary,
          ),
          const Text(
            '용병 상세',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Mercenary merc, dynamic job) {
    final tierColor = job != null ? AppTheme.tierColor(job.tier) : AppTheme.textHint;
    final tierBgColor = job != null ? AppTheme.tierBgColor(job.tier) : AppTheme.tier1Bg;
    final jobName = job?.name ?? merc.jobId;
    final jobTier = job?.tier ?? 1;

    final currentLevel = merc.level;
    final currentXp = merc.xp;
    final isMaxLevel = currentLevel >= ExperienceService.maxLevel;

    double xpProgress = 0.0;
    int xpForNext = 0;
    int xpBase = 0;

    if (!isMaxLevel) {
      xpBase = ExperienceService.levelThresholds[currentLevel - 1];
      xpForNext = ExperienceService.levelThresholds[currentLevel];
      final xpRange = xpForNext - xpBase;
      if (xpRange > 0) {
        xpProgress = ((currentXp - xpBase) / xpRange).clamp(0.0, 1.0);
      }
    } else {
      xpProgress = 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tierBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    '⚔',
                    style: TextStyle(fontSize: 24, color: tierColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            merc.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Lv.$currentLevel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierBgColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'T$jobTier $jobName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tierColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(status: merc.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow(merc),
          const SizedBox(height: 10),
          _buildXpBar(currentLevel, currentXp, xpProgress, isMaxLevel, xpForNext),
        ],
      ),
    );
  }

  Widget _buildStatRow(Mercenary merc) {
    return Row(
      children: [
        _buildStatChip('STR', '${merc.effectiveStr}', const Color(0xFFC62828)),
        const SizedBox(width: 8),
        _buildStatChip('INT', '${merc.effectiveIntelligence}', const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        _buildStatChip('VIT', '${merc.effectiveVit}', const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        _buildStatChip('AGI', merc.effectiveAgi.toString(), const Color(0xFF6A1B9A)),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpBar(int level, int xp, double progress, bool isMax, int xpForNext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXP',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              isMax ? 'MAX' : '$xp / $xpForNext',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              isMax ? AppTheme.tier5 : AppTheme.tier3,
            ),
          ),
        ),
      ],
    );
  }

}
