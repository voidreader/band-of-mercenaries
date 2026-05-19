import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart'
    show EliteLootResult;
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

class QuestResultDialog extends ConsumerStatefulWidget {
  final ActiveQuest quest;
  final EliteLootResult? eliteLoot;

  const QuestResultDialog({super.key, required this.quest, this.eliteLoot});

  @override
  ConsumerState<QuestResultDialog> createState() => _QuestResultDialogState();
}

class _QuestResultDialogState extends ConsumerState<QuestResultDialog> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final staticData = ref.watch(staticDataProvider);
    final mercs = ref.watch(mercenaryListProvider);

    return staticData.when(
      data: (data) {
        final (label, color, bgColor) = _resolveResultStyle();
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _showDetail
                    ? _buildDetailView(context, data, mercs, color)
                    : _buildSummaryView(
                        context,
                        data,
                        mercs,
                        label,
                        color,
                        bgColor,
                      ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => Dialog(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ),
    );
  }

  (String, Color, Color) _resolveResultStyle() {
    return switch (widget.quest.result) {
      QuestResult.greatSuccess => (
        '대성공!',
        AppTheme.greatSuccess,
        AppTheme.greatSuccessBg,
      ),
      QuestResult.success => ('성공!', AppTheme.success, AppTheme.successBg),
      QuestResult.failure => ('실패...', AppTheme.failure, AppTheme.failureBg),
      QuestResult.criticalFailure => (
        '대실패...',
        AppTheme.criticalFailure,
        AppTheme.criticalFailureBg,
      ),
      null => ('완료', AppTheme.textSecondary, AppTheme.tier1Bg),
    };
  }

  Widget _buildSummaryView(
    BuildContext context,
    StaticGameData data,
    List<Mercenary> mercs,
    String label,
    Color color,
    Color bgColor,
  ) {
    final quest = widget.quest;
    final questType = data.questTypes.firstWhere(
      (t) => t.id == quest.questTypeId,
    );
    final isSuccess =
        quest.result == QuestResult.greatSuccess ||
        quest.result == QuestResult.success;
    final rewardGold = quest.rewardGold ?? 0;
    final totalWage = quest.totalWage ?? 0;
    final dispatchCost = quest.dispatchCost ?? 0;
    final netProfit = rewardGold - totalWage - dispatchCost;
    final earnedXp = quest.earnedXp ?? 0;
    final earnedReputation = quest.earnedReputation ?? 0;

    return SingleChildScrollView(
      key: const ValueKey('summary'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '퀘스트 완료',
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            quest.questName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            '${questType.name} · 난이도 ${quest.difficulty}',
            style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),

          if (quest.renderedNarrative != null &&
              quest.renderedNarrative!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.tier1Bg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                quest.renderedNarrative!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          if (quest.combatReport != null) ...[
            const SizedBox(height: 12),
            _CombatReportSummaryCard(
              report: quest.combatReport!,
              resultColor: color,
              onTapDetail: () => setState(() => _showDetail = true),
            ),
          ],
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '용병 상태',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          for (final mercId in quest.dispatchedMercIds)
            _MercStatusRow(mercId: mercId, mercs: mercs, staticData: data),

          const SizedBox(height: 16),

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
                const Text(
                  '보상 내역',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _RewardRow(
                  label: '기본 보상',
                  value: '${rewardGold}G',
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 4),
                _RewardRow(
                  label: '파견 비용',
                  value: '-${dispatchCost}G',
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 4),
                _RewardRow(
                  label: '인건비',
                  value: '-${totalWage}G',
                  color: AppTheme.textTertiary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: AppTheme.borderLight),
                ),
                _RewardRow(
                  label: '순수익',
                  value: '${netProfit >= 0 ? '+' : ''}${netProfit}G',
                  color: netProfit >= 0
                      ? AppTheme.success
                      : AppTheme.criticalFailure,
                  isBold: true,
                ),
                const SizedBox(height: 4),
                _RewardRow(
                  label: '획득 경험치',
                  value: '+$earnedXp XP',
                  color: AppTheme.timerBlue,
                ),
                const SizedBox(height: 4),
                _RewardRow(
                  label: '획득 명성',
                  value: '+$earnedReputation',
                  color: AppTheme.tier4,
                ),
              ],
            ),
          ),

          if (widget.eliteLoot != null &&
              (widget.eliteLoot!.bonusGold > 0 ||
                  widget.eliteLoot!.itemDrops.isNotEmpty)) ...[
            const SizedBox(height: 12),
            _EliteLootSection(
              loot: widget.eliteLoot!,
              staticData: data,
              eliteId: quest.eliteId,
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isSuccess
                    ? '🪙 ${netProfit + (widget.eliteLoot?.bonusGold ?? 0)}G 보상 수령'
                    : '확인',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(
    BuildContext context,
    StaticGameData data,
    List<Mercenary> mercs,
    Color resultColor,
  ) {
    final report = widget.quest.combatReport!;
    return Column(
      key: const ValueKey('detail'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => setState(() => _showDetail = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.quest.questName} — 전투 보고서',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in report.details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        border: Border(
                          left: BorderSide(color: resultColor, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final mercId in {
                      if (report.protagonistMercId != null)
                        report.protagonistMercId!,
                      ...report.featuredMercIds,
                    })
                      _buildMercChip(
                        mercId,
                        mercs,
                        isProtagonist: mercId == report.protagonistMercId,
                      ),
                  ].whereType<Widget>().toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }

  Widget? _buildMercChip(
    String mercId,
    List<Mercenary> mercs, {
    required bool isProtagonist,
  }) {
    final merc = mercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) return null;
    final label = isProtagonist ? '주인공: ${merc.name}' : merc.name;
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppTheme.surfaceAlt,
      side: BorderSide(
        color: isProtagonist ? AppTheme.tier4 : AppTheme.borderLight,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EliteLootSection extends StatelessWidget {
  final EliteLootResult loot;
  final StaticGameData staticData;
  final String? eliteId;

  const _EliteLootSection({
    required this.loot,
    required this.staticData,
    required this.eliteId,
  });

  @override
  Widget build(BuildContext context) {
    final eliteData = staticData.eliteMonsters
        .where((m) => m.id == eliteId)
        .firstOrNull;
    final isUnique = eliteData?.isUnique ?? false;
    final accentColor = isUnique
        ? AppTheme.eliteUniqueAccent
        : AppTheme.eliteAccent;
    final bgColor = isUnique ? AppTheme.eliteUniqueBg : AppTheme.eliteBg;
    final borderColor = isUnique
        ? AppTheme.eliteUniqueBorder
        : AppTheme.eliteBorder;
    final header = isUnique ? '★ 유니크 드랍' : '🔥 엘리트 드랍';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          if (loot.bonusGold > 0) ...[
            _RewardRow(
              label: '추가 골드',
              value: '+${loot.bonusGold}G',
              color: accentColor,
            ),
            const SizedBox(height: 4),
          ],
          for (final itemId in loot.itemDrops) ...[
            _RewardRow(
              label:
                  staticData.items
                      .where((i) => i.id == itemId)
                      .firstOrNull
                      ?.name ??
                  itemId,
              value: '획득',
              color: accentColor,
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _MercStatusRow extends StatelessWidget {
  final String mercId;
  final List<Mercenary> mercs;
  final StaticGameData staticData;

  const _MercStatusRow({
    required this.mercId,
    required this.mercs,
    required this.staticData,
  });

  @override
  Widget build(BuildContext context) {
    final Mercenary? merc = mercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('알 수 없는 용병', style: TextStyle(fontSize: 14)),
            Text(
              '사망',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.criticalFailure,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final job = staticData.jobs.firstWhere((j) => j.id == merc.jobId);
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
          Text(
            '${merc.name} (${job.name})',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _RewardRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _CombatReportSummaryCard extends StatelessWidget {
  final CombatReport report;
  final Color resultColor;
  final VoidCallback onTapDetail;

  const _CombatReportSummaryCard({
    required this.report,
    required this.resultColor,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📜', style: TextStyle(fontSize: 14, color: resultColor)),
              const SizedBox(width: 6),
              Text(
                '전투 보고서',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: resultColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.summary,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onTapDetail,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('상세 보고서 보기', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
