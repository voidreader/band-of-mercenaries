import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_service.dart';

class ChainCompletedDialog extends ConsumerWidget {
  final ChainCompletedEvent event;
  final VoidCallback? onDismiss;

  const ChainCompletedDialog({
    super.key,
    required this.event,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(templateEngineProvider);
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider).value;

    Mercenary? protagonist;
    if (event.protagonistMercId != null) {
      protagonist = mercs
          .where((m) => m.id == event.protagonistMercId)
          .firstOrNull;
    }

    final region = (userData != null && staticData != null)
        ? staticData.regions
            .where((r) => r.region == userData.region)
            .firstOrNull
        : null;

    final renderedDescription = userData != null
        ? engine.render(
            event.finalDescription,
            TemplateContext(
              user: userData,
              merc: protagonist,
              region: region,
              evaluationScope: EvaluationScope.mercenary,
            ),
          )
        : event.finalDescription;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '✅ 연계 퀘스트 완료: ${event.chainName}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // 서사 텍스트
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                renderedDescription,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),

            if (event.reputationBonus > 0 || event.rewardItems.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                    const Text('보상', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (event.reputationBonus > 0) ...[
                      _buildRewardRow('명성', '+${event.reputationBonus}', AppTheme.tier4),
                    ],
                    for (final entry in event.rewardItems.entries) ...[
                      const SizedBox(height: 4),
                      _buildRewardRow(entry.key, '×${entry.value}', AppTheme.textSecondary),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (onDismiss ?? () => Navigator.of(context).pop()),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
