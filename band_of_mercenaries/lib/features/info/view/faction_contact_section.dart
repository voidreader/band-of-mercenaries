import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_contact_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_contact_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_reaction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_reaction_picker.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_relation_stage.dart';

/// M8a 세력 생활권 접촉점 섹션 (FR-G1)
class FactionContactSection extends ConsumerWidget {
  final String factionId;
  const FactionContactSection({super.key, required this.factionId});

  // 매 build에서 Random()을 새로 만들지 않도록 정적 인스턴스 1개 공유.
  static final Random _random = Random();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).value;
    if (staticData == null) return const SizedBox.shrink();

    final contacts = staticData.factionContacts
        .where((c) => c.factionId == factionId)
        .where((c) => FactionContactService.isActive(c.id, ref))
        .toList();

    if (contacts.isEmpty) return const SizedBox.shrink();

    final stage = FactionRelationStage.resolve(factionId, ref);
    final stageLabel = _stageLabel(stage);
    final random = _random;

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('생활권 접촉점', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final contact in contacts)
              _ContactCard(
                npcName: contact.npcName,
                stageLabel: stageLabel,
                reactionText: _pickReaction(
                  contact,
                  staticData.factionReactions,
                  stage,
                  random,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _pickReaction(
    FactionContact contact,
    List<FactionReaction> reactions,
    FactionRelationStage stage,
    Random random,
  ) {
    final filtered = reactions
        .where((r) => r.factionId == factionId && r.contactId == contact.id)
        .toList();
    final picked = FactionReactionPicker.pickFor(
      factionId: factionId,
      relationStage: stage,
      reactions: filtered,
      random: random,
    );
    return picked?.text ?? contact.firstReactionText;
  }

  String _stageLabel(FactionRelationStage stage) {
    switch (stage) {
      case FactionRelationStage.untouched:
        return '미접촉';
      case FactionRelationStage.noticed:
        return '주목';
      case FactionRelationStage.patronage:
        return '후원';
      case FactionRelationStage.joined:
        return '가입';
      case FactionRelationStage.trusted:
        return '신뢰';
      case FactionRelationStage.core:
        return '핵심';
      case FactionRelationStage.hostile:
        return '적대';
    }
  }
}

class _ContactCard extends StatelessWidget {
  final String npcName;
  final String stageLabel;
  final String? reactionText;

  const _ContactCard({
    required this.npcName,
    required this.stageLabel,
    required this.reactionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 6),
              Text(npcName, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              Chip(
                label: Text(stageLabel),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (reactionText != null && reactionText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(reactionText!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
