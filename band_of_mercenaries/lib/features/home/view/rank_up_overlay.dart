import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/providers/reputation_rank_up_provider.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

/// 랭크업 축하 다이얼로그.
///
/// [app.dart]의 `ref.listen(reputationRankUpProvider)`가 감지 → `showDialog`로 렌더.
/// 확인 버튼 탭 시 [onDismiss]가 호출되며, 호출측에서
/// `Navigator.pop` + `reputationRankUpProvider.notifier.state = null` 수행.
class RankUpOverlay extends StatelessWidget {
  final RankUpEvent event;
  final VoidCallback onDismiss;

  const RankUpOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(
        Icons.military_tech,
        size: 56,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        '명성 상승!',
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '${event.from.grade} → ${event.to.grade}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              event.to.name,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          if (event.newEffects.isEmpty)
            Text(
              '신규 보너스 없음',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else ...[
            Text(
              '신규 보너스',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final effect in event.newEffects)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${PassiveBonusFormatter.format(effect)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            '✨ 이 순간은 연대기에 새겨졌다',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppTheme.chainGold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
