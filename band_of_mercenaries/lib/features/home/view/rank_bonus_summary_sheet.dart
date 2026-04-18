import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';

/// 홈 등급 카드 탭 시 표시되는 bottom sheet.
///
/// 현재 활성 보너스(rankChain 누적) + 다음 등급 진행도 표시.
/// 최고 랭크(A) 도달 시 "최고 등급 도달" 안내.
class RankBonusSummarySheet extends ConsumerWidget {
  const RankBonusSummarySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataProvider);
    final staticData = ref.watch(staticDataProvider).valueOrNull;

    if (userData == null || staticData == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('데이터 로딩 중...'),
        ),
      );
    }

    final reputation = userData.reputation;
    final ranks = staticData.ranks;
    if (ranks.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('랭크 데이터 없음'),
        ),
      );
    }

    final currentRank = ReputationService.getCurrentRank(reputation, ranks);
    final nextRank = ReputationService.getNextRank(reputation, ranks);
    final rankChain = ReputationService.getRankChain(reputation, ranks);

    // rankChain 전체에서 effect와 출처 등급을 함께 수집
    final entries = <_SummaryEntry>[];
    for (final rank in rankChain) {
      final effects = PassiveEffect.parseEffects(rank.bonusJson);
      for (final effect in effects) {
        entries.add(_SummaryEntry(grade: rank.grade, effect: effect));
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '명성 ${currentRank.grade} — ${currentRank.name}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '현재 활성 보너스',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                '활성 보너스 없음',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${PassiveBonusFormatter.format(entry.effect)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '(${entry.grade})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            if (nextRank == null)
              Text(
                '최고 등급 도달',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            else ...[
              Text(
                '다음 등급: ${nextRank.grade} — ${nextRank.name}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _progress(reputation, currentRank, nextRank),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text(
                '명성 $reputation / ${nextRank.requiredReputation}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _progress(int reputation, Rank current, Rank next) {
    final span = next.requiredReputation - current.requiredReputation;
    if (span <= 0) return 1.0;
    final within = reputation - current.requiredReputation;
    return (within / span).clamp(0.0, 1.0);
  }
}

class _SummaryEntry {
  final String grade;
  final PassiveEffect effect;
  const _SummaryEntry({required this.grade, required this.effect});
}
