import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart'
    show factionCodexScrollTargetProvider;
import 'package:band_of_mercenaries/features/info/domain/faction_contact_arrived_event.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';

/// M8a 세력 접촉점 도착 다이얼로그 (FR-G2)
class FactionContactArrivedDialog extends ConsumerWidget {
  final FactionContactArrivedEvent event;
  final VoidCallback onDismiss;

  const FactionContactArrivedDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        '${event.factionName} 접촉 가능',
        style: theme.textTheme.titleMedium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.npcName, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(event.firstReactionText, style: theme.textTheme.bodyMedium),
        ],
      ),
      actions: [
        TextButton(onPressed: onDismiss, child: const Text('닫기')),
        TextButton(
          onPressed: () {
            ref.read(factionCodexScrollTargetProvider.notifier).state =
                event.factionId;
            ref.read(currentTabProvider.notifier).state = 5;
            onDismiss();
          },
          child: const Text('정보 탭에서 확인'),
        ),
      ],
    );
  }
}
