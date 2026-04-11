import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

class QuestResultDialog extends ConsumerWidget {
  final ActiveQuest quest;

  const QuestResultDialog({super.key, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);
    final mercs = ref.watch(mercenaryListProvider);

    return staticData.when(
      data: (data) {
        final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
        final (label, color, bgColor) = switch (quest.result) {
          QuestResult.greatSuccess => ('대성공!', AppTheme.greatSuccess, AppTheme.greatSuccessBg),
          QuestResult.success => ('성공!', AppTheme.success, AppTheme.successBg),
          QuestResult.failure => ('실패...', AppTheme.failure, AppTheme.failureBg),
          QuestResult.criticalFailure => ('대실패...', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
          null => ('완료', AppTheme.textSecondary, AppTheme.tier1Bg),
        };

        final isSuccess = quest.result == QuestResult.greatSuccess || quest.result == QuestResult.success;
        final rewardGold = quest.rewardGold ?? 0;
        final totalWage = quest.totalWage ?? 0;
        final dispatchCost = quest.dispatchCost ?? 0;
        final netProfit = rewardGold - totalWage - dispatchCost;
        final earnedXp = quest.earnedXp ?? 0;
        final earnedReputation = quest.earnedReputation ?? 0;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('퀘스트 완료', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(quest.questName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text('${questType.name} · 난이도 ${quest.difficulty}',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                const SizedBox(height: 16),

                // Result banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
                const SizedBox(height: 16),

                // Mercenary status
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('용병 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                for (final mercId in quest.dispatchedMercIds)
                  _buildMercStatus(mercId, mercs, data),

                const SizedBox(height: 16),

                // Reward details section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('보상 내역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildRewardRow('기본 보상', '${rewardGold}G', AppTheme.textSecondary),
                      const SizedBox(height: 4),
                      _buildRewardRow('파견 비용', '-${dispatchCost}G', AppTheme.textTertiary),
                      const SizedBox(height: 4),
                      _buildRewardRow('인건비', '-${totalWage}G', AppTheme.textTertiary),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, color: AppTheme.borderLight),
                      ),
                      _buildRewardRow(
                        '순수익',
                        '${netProfit >= 0 ? '+' : ''}${netProfit}G',
                        netProfit >= 0 ? Colors.green : Colors.red,
                        isBold: true,
                      ),
                      const SizedBox(height: 4),
                      _buildRewardRow('획득 경험치', '+$earnedXp XP', AppTheme.timerBlue),
                      const SizedBox(height: 4),
                      _buildRewardRow('획득 명성', '+$earnedReputation', AppTheme.tier4),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isSuccess ? '🪙 ${netProfit}G 보상 수령' : '확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildRewardRow(String label, String value, Color valueColor, {bool isBold = false}) {
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

  Widget _buildMercStatus(String mercId, List<Mercenary> mercs, StaticGameData data) {
    final Mercenary? merc = mercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('알 수 없는 용병', style: TextStyle(fontSize: 14)),
            Text('사망', style: TextStyle(fontSize: 14, color: AppTheme.criticalFailure, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
    final statusText = switch (merc.status) {
      MercenaryStatus.normal || MercenaryStatus.tired => '무사 귀환',
      MercenaryStatus.injured => '부상',
      MercenaryStatus.dead => '사망',
    };
    final statusColor = switch (merc.status) {
      MercenaryStatus.normal || MercenaryStatus.tired => AppTheme.textSecondary,
      MercenaryStatus.injured => AppTheme.failure,
      MercenaryStatus.dead => AppTheme.criticalFailure,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${merc.name} (${job.name})', style: const TextStyle(fontSize: 14)),
          Text(statusText, style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
