import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_action.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/combatant_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/enemy_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
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
    final isM8b = _isM8bReport(report);
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
                if (isM8b) ...[
                  const SizedBox(height: 16),
                  _CombatReportRoundLogSection(
                    report: report,
                    staticData: data,
                    mercs: mercs,
                    resultColor: resultColor,
                  ),
                ],
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
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isProtagonist ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      backgroundColor: AppTheme.surfaceAlt,
      side: BorderSide(
        color: isProtagonist ? AppTheme.chainGold : AppTheme.borderLight,
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

// ─── file-scope 헬퍼 ────────────────────────────────────────────────────────

typedef _SelectedRoundAction = ({CombatTurn turn, CombatAction action});

bool _isM8bReport(CombatReport r) =>
    r.schemaVersion == 1 && r.turns != null;

String _exitConditionLabel(CombatExitCondition? c) => switch (c) {
  CombatExitCondition.aPartyWiped => '파티 전멸',
  CombatExitCondition.bEnemyWiped => '적 전멸',
  CombatExitCondition.cObjectiveAchieved => '목표 달성',
  CombatExitCondition.dRoundLimit => '라운드 한계',
  CombatExitCondition.eFlee => '도주',
  CombatExitCondition.fEscortDead => '호위 대상 사망',
  null => '',
};

Color _positionBorderColor(String position) => switch (position) {
  'entry' || 'aftermath' => AppTheme.textTertiary,
  'development' => AppTheme.textSecondary,
  'crisis' => AppTheme.dangerTension,
  'resolution' => AppTheme.chainGold,
  _ => AppTheme.textTertiary,
};

bool _isKnownPosition(String position) => switch (position) {
  'entry' || 'development' || 'crisis' || 'resolution' || 'aftermath' => true,
  _ => false,
};

String _resolveActorName(
  String actorId,
  List<CombatantSnapshot> combatantSnapshots,
  List<EnemySnapshot> enemySnapshots,
  List<Mercenary> mercs,
) {
  final combatant =
      combatantSnapshots.where((s) => s.mercId == actorId).firstOrNull;
  if (combatant != null) return combatant.name;
  final enemy =
      enemySnapshots.where((s) => s.instanceId == actorId).firstOrNull;
  if (enemy != null) return enemy.name;
  final merc = mercs.where((m) => m.id == actorId).firstOrNull;
  if (merc != null) return merc.name;
  return actorId;
}

bool _isExposableAction(CombatAction a) {
  if (!_isKnownPosition(a.position)) return false;
  if (a.actionKind == 'dot_tick') {
    return a.statusEffectId != null && a.damage >= 1;
  }
  if (a.actionKind == 'skipped_stunned') return true;
  if (a.actionKind == 'riposte') return true;
  if (a.isKill || a.isCrit || a.isShielded) return true;
  if (a.isEvaded) return true;
  if (a.decisiveKeywordKey != null) return true;
  if (a.isComboCompression) return true;
  if (a.actionKind == 'skill' &&
      (a.skillId != null || a.statusEffectId != null)) {
    return true;
  }
  if (a.damage >= 1) return true;
  return false;
}

int _actionPriority(CombatAction a) {
  if (a.isKill) return 900;
  if (a.decisiveKeywordKey != null) return 800;
  if (a.isComboCompression) return 700;
  if (a.isCrit) return 600;
  if (a.isShielded || a.isEvaded || a.actionKind == 'riposte') return 500;
  if (a.actionKind == 'skill' && a.statusEffectId != null) return 400;
  if (a.actionKind == 'dot_tick') return 300;
  return 100 + a.damage.clamp(0, 99);
}

_SelectedRoundAction? _selectBestActionForTurn(CombatTurn turn) {
  final candidates = turn.actions.where(_isExposableAction).toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final priority = _actionPriority(b).compareTo(_actionPriority(a));
    if (priority != 0) return priority;
    return b.damage.compareTo(a.damage);
  });
  return (turn: turn, action: candidates.first);
}

List<_SelectedRoundAction> _selectRoundActions(CombatReport report) {
  final turns = report.turns ?? const <CombatTurn>[];
  final lineBudget = report.details.isEmpty
      ? 4
      : report.details.length.clamp(4, 8);
  return turns
      .map(_selectBestActionForTurn)
      .whereType<_SelectedRoundAction>()
      .take(lineBudget)
      .toList(growable: false);
}

// ─── 신규 private 위젯 ────────────────────────────────────────────────────────

class _CombatReportRoundLogSection extends StatelessWidget {
  final CombatReport report;
  final StaticGameData staticData;
  final List<Mercenary> mercs;
  final Color resultColor;

  const _CombatReportRoundLogSection({
    required this.report,
    required this.staticData,
    required this.mercs,
    required this.resultColor,
  });

  @override
  Widget build(BuildContext context) {
    final exitCondition = report.exitCondition;
    final progress = report.objectiveProgress;
    final roundActions = _selectRoundActions(report);
    final combatantSnapshots = report.combatantSnapshots ?? const [];
    final enemySnapshots = report.enemySnapshots ?? const [];

    return Container(
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '전투 라운드 로그',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              if (exitCondition != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: resultColor),
                  ),
                  child: Text(
                    _exitConditionLabel(exitCondition),
                    style: TextStyle(fontSize: 12, color: resultColor),
                  ),
                ),
              ],
            ],
          ),
          if (progress != null && progress > 0) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '목표 진행도: ${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(resultColor),
                minHeight: 6,
              ),
            ),
          ],
          for (final selected in roundActions) ...[
            const SizedBox(height: 8),
            _RoundCard(
              turn: selected.turn,
              action: selected.action,
              combatantSnapshots: combatantSnapshots,
              enemySnapshots: enemySnapshots,
              mercs: mercs,
              staticData: staticData,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final CombatTurn turn;
  final CombatAction action;
  final List<CombatantSnapshot> combatantSnapshots;
  final List<EnemySnapshot> enemySnapshots;
  final List<Mercenary> mercs;
  final StaticGameData staticData;

  const _RoundCard({
    required this.turn,
    required this.action,
    required this.combatantSnapshots,
    required this.enemySnapshots,
    required this.mercs,
    required this.staticData,
  });

  @override
  Widget build(BuildContext context) {
    final actorName = _resolveActorName(
      action.actorId,
      combatantSnapshots,
      enemySnapshots,
      mercs,
    );
    final targetName = action.targetIds.isNotEmpty
        ? _resolveActorName(
            action.targetIds.first,
            combatantSnapshots,
            enemySnapshots,
            mercs,
          )
        : null;

    final skillLabel = action.skillId != null
        ? staticData.combatSkills
              .where((s) => s.id == action.skillId)
              .firstOrNull
              ?.displayLabel
        : null;

    final statusEffectLabel = action.statusEffectId != null
        ? staticData.combatStatusEffects
              .where((e) => e.id == action.statusEffectId)
              .firstOrNull
              ?.displayLabel
        : null;

    final decisiveLabel = action.decisiveKeywordKey != null
        ? staticData.combatReportKeywords
              .where(
                (k) =>
                    k.category == 'decisive' &&
                    k.key == action.decisiveKeywordKey,
              )
              .firstOrNull
              ?.displayText
        : null;

    final isInitiative = turn.phase == 'initiative';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'R${turn.roundIndex}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
              ),
            ),
            if (isInitiative) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.chainGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppTheme.chainGold),
                ),
                child: const Text(
                  '선제',
                  style: TextStyle(fontSize: 11, color: AppTheme.chainGold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _ActionLine(
          action: action,
          actorName: actorName,
          targetName: targetName,
          skillLabel: skillLabel,
          statusEffectLabel: statusEffectLabel,
          decisiveLabel: decisiveLabel,
        ),
      ],
    );
  }
}

class _ActionLine extends StatelessWidget {
  final CombatAction action;
  final String actorName;
  final String? targetName;
  final String? skillLabel;
  final String? statusEffectLabel;
  final String? decisiveLabel;

  const _ActionLine({
    required this.action,
    required this.actorName,
    this.targetName,
    this.skillLabel,
    this.statusEffectLabel,
    this.decisiveLabel,
  });

  String _buildLineText() {
    final actor = actorName;
    final target = targetName ?? '';

    String base;
    switch (action.actionKind) {
      case 'basic_attack':
        if (action.isShielded) {
          final reduction =
              (action.shieldMitigation.clamp(0.0, 1.0) * 100).toInt();
          base = '$target이 $actor의 공격을 방패로 막아 $reduction% 감소';
        } else if (action.isEvaded) {
          base = '$target이 $actor의 공격을 회피했다';
        } else if (action.isCrit) {
          base = '$actor의 치명타! $target에게 ${action.damage}의 피해';
        } else {
          base = '$actor의 공격으로 $target에게 ${action.damage}의 피해';
        }
      case 'skill':
        final sLabel = skillLabel ?? '스킬';
        if (action.damage >= 1) {
          base = '$actor의 $sLabel — $target에게 ${action.damage}의 피해';
        } else if (action.statusEffectId != null) {
          final eLabel = statusEffectLabel ?? '상태 효과';
          base = '$actor의 $sLabel — $target에게 $eLabel';
        } else {
          base = '$actor의 $sLabel';
        }
      case 'dot_tick':
        final eLabel = statusEffectLabel ?? '상태 효과';
        base = '$target이 $eLabel로 ${action.damage}의 피해';
      case 'skipped_stunned':
        base = '$actor이 기절해 행동하지 못했다';
      case 'extra_action':
        base = '$actor의 추가 행동 (${action.damage}의 피해)';
      case 'riposte':
        base = '$actor의 반격으로 ${action.damage}의 피해';
      default:
        base = '$actor의 행동';
    }

    if (action.isKill) {
      base = '$base(처치)';
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _positionBorderColor(action.position);
    final lineText = _buildLineText();
    final hasDecisive = action.decisiveKeywordKey != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              lineText,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (hasDecisive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.chainGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.chainGold),
              ),
              child: Text(
                decisiveLabel ?? '결정적 장면',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.chainGold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 기존 private 위젯 ────────────────────────────────────────────────────────

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
