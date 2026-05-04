import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/investigation/domain/settlement_trust_provider.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_npc_data.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';
import 'package:band_of_mercenaries/shared/widgets/card_container.dart';

class ChiefHouseScreen extends ConsumerWidget {
  final VoidCallback onClose;
  const ChiefHouseScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trust = ref.watch(settlementTrustProvider(GameConstants.startingRegionId));
    final repo = ref.read(regionStateRepositoryProvider);
    final regionState = repo.getState(GameConstants.startingRegionId);
    final recentlyCompleted = regionState?.eventCompletedRecently ?? false;

    final level = trust.level;
    final greeting = SettlementNpcData.greetingFor(VillageFacility.chiefHouse, level);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NpcHeader(greeting: greeting, level: level),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (recentlyCompleted) ...[
                  _EventCompletedBanner(),
                  const SizedBox(height: 8),
                ],
                _TrustProgressCard(trust: trust.trust, level: level),
                const SizedBox(height: 16),
                _ActionButton(
                  label: '상황 듣기',
                  onTap: () => _showSituationDialog(context, ref),
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: '신뢰도 확인',
                  onTap: () => _showTrustDialog(context, trust.trust, level),
                ),
                const SizedBox(height: 8),
                _DisabledRewardButton(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('닫기', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSituationDialog(BuildContext context, WidgetRef ref) {
    const chainId = 'settlement_${GameConstants.startingRegionId}_pyegwang_reopen';
    final progresses = ref.read(chainQuestProgressProvider).valueOrNull ?? const [];
    final progress = progresses.where((p) => p.chainId == chainId).firstOrNull;
    final staticData = ref.read(staticDataProvider).valueOrNull;

    String title;
    String body;

    if (progress == null || progress.status == ChainQuestStatus.completed) {
      title = '파슨의 이야기';
      body = '마을은 평온하다.';
    } else if (progress.status == ChainQuestStatus.active) {
      final step = progress.currentStep;
      title = '현재 사건: 폐광길 재개방 ($step/6 단계)';

      final chainData = staticData?.chainQuests
          .where((c) =>
              c.chainId == 'settlement_${GameConstants.startingRegionId}_pyegwang_reopen' &&
              c.step == step)
          .firstOrNull;

      body = chainData?.description ?? '사건이 진행 중입니다.';
    } else {
      title = '파슨의 이야기';
      body = '마을은 평온하다.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        content: Text(
          body,
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showTrustDialog(BuildContext context, int currentTrust, int currentLevel) {
    const thresholds = {2: 30, 3: 80, 4: 200};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          '신뢰도 상세',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 단계: ${_levelName(currentLevel)} ($currentTrust점)',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              '단계별 임계값',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint),
            ),
            const SizedBox(height: 4),
            ...thresholds.entries.map((e) {
              final lv = e.key;
              final threshold = e.value;
              final reached = currentTrust >= threshold;
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      reached ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 14,
                      color: reached
                          ? AppTheme.tier2
                          : AppTheme.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_levelName(lv)} ($threshold점)',
                      style: TextStyle(
                          fontSize: 13,
                          color: reached
                              ? AppTheme.textPrimary
                              : AppTheme.textHint),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              '단계 진입 보상',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint),
            ),
            const SizedBox(height: 4),
            const Text(
              '2단계: +100G, +50XP\n3단계: +200G, +100XP\n4단계: +500G, +200XP, +100명성',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.6),
            ),
            const SizedBox(height: 8),
            const Text(
              '단계 진입 시 자동 지급됩니다.',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

// 단계명 매핑
String _levelName(int level) => switch (level) {
      1 => '의심',
      2 => '인지',
      3 => '친근',
      4 => '소속',
      _ => '의심',
    };

// 신뢰도 다음 단계 진행률 계산
double _calcProgress(int trust, int level) {
  const thresholds = {2: 30, 3: 80, 4: 200};
  if (level >= 4) return 1.0;
  final prevThreshold = thresholds[level] ?? 0;
  final nextThreshold = thresholds[level + 1];
  if (nextThreshold == null) return 1.0;
  return ((trust - prevThreshold) / (nextThreshold - prevThreshold))
      .clamp(0.0, 1.0);
}

class _NpcHeader extends StatelessWidget {
  final String greeting;
  final int level;

  const _NpcHeader({required this.greeting, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧓', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '파슨',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tier1Bg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        _levelName(level),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textHint,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"$greeting"',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCompletedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.settlementAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              SettlementNpcData.eventCompletedMessage,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustProgressCard extends StatelessWidget {
  final int trust;
  final int level;

  const _TrustProgressCard({required this.trust, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = _calcProgress(trust, level);
    final isMax = level >= 4;

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '마을 신뢰도',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHint),
              ),
              Text(
                isMax
                    ? '${_levelName(level)} (최고 단계)'
                    : '${_levelName(level)} → ${_levelName(level + 1)}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.settlementAccent),
            ),
          ),
          const SizedBox(height: 6),
          if (isMax)
            const Text(
              '최고 단계 도달',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.settlementAccent,
                  fontWeight: FontWeight.w600),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$trust점',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint),
                ),
                Text(
                  '다음 단계까지 ${_nextThreshold(level) - trust}점',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int _nextThreshold(int level) {
    const thresholds = {2: 30, 3: 80, 4: 200};
    return thresholds[level + 1] ?? 200;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class _DisabledRewardButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: AppTheme.borderLight,
              disabledForegroundColor: AppTheme.textHint,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: const Text('보상 받기'),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '단계 진입 시 자동 지급',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.textHint),
        ),
      ],
    );
  }
}

