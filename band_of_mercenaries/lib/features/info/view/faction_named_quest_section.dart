import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart'
    show questListProvider;

/// M8a 세력 지명 의뢰 섹션 (FR-G1)
///
/// questListProvider에서 factionTag가 factionId와 일치하는 활성 의뢰를 표시한다.
class FactionNamedQuestSection extends ConsumerWidget {
  final String factionId;
  const FactionNamedQuestSection({super.key, required this.factionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allQuests = ref.watch(questListProvider);
    final staticData = ref.watch(staticDataProvider).value;
    final namedPoolIds =
        staticData?.questPools
            .where((p) => p.isNamed)
            .map((p) => p.id)
            .toSet() ??
        const <String>{};
    final factionQuests = allQuests
        .where((q) => q.factionTag == factionId)
        .where((q) => namedPoolIds.contains(q.questPoolId))
        .toList();

    if (factionQuests.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '세력 의뢰 ${factionQuests.length}건 활성',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final q in factionQuests)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${q.questName}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
