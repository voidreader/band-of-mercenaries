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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
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
