import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';

class FactionReputationBar extends StatelessWidget {
  final int reputation;
  final bool joined;

  const FactionReputationBar({
    super.key,
    required this.reputation,
    required this.joined,
  });

  @override
  Widget build(BuildContext context) {
    // -100~+100 범위를 0.0~1.0으로 정규화
    final normalized = ((reputation + 100) / 200).clamp(0.0, 1.0);
    final color = reputation < 0
        ? Colors.red
        : reputation == 0
            ? AppTheme.textHint
            : Colors.green;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 8,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-100',
                style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            Text('0',
                style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            Text('+100',
                style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      ],
    );
  }
}

class FactionJoinConditions extends StatelessWidget {
  final FactionData faction;
  final int clueLevel;
  final String currentRank;
  final int reputation;

  const FactionJoinConditions({
    super.key,
    required this.faction,
    required this.clueLevel,
    required this.currentRank,
    required this.reputation,
  });

  @override
  Widget build(BuildContext context) {
    final conditions = <Widget>[];

    // 평판 > 0 조건 (실제 값 기반)
    conditions.add(FactionConditionRow(
      label: '세력 평판 > 0',
      met: reputation > 0,
    ));

    // clue 조건
    if (faction.joinNeedsClue) {
      conditions.add(FactionConditionRow(
        label: '거점 발견 (★★★)',
        met: clueLevel >= 3,
      ));
    }

    // 랭크 조건
    if (faction.joinRankMin != null) {
      final sufficient =
          FactionJoinService.isRankSufficient(currentRank, faction.joinRankMin!);
      conditions.add(FactionConditionRow(
        label: '랭크 ${faction.joinRankMin} 이상 (현재: $currentRank)',
        met: sufficient,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: conditions,
    );
  }
}

class FactionConditionRow extends StatelessWidget {
  final String label;
  final bool met;

  const FactionConditionRow({
    super.key,
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? Colors.green : AppTheme.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppTheme.textPrimary : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class FactionVisibilityBadge extends StatelessWidget {
  final String visibilityType;

  const FactionVisibilityBadge({
    super.key,
    required this.visibilityType,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (visibilityType) {
      'secret' => ('비밀', Colors.orange),
      'regional' => ('지역·종족', Colors.blue),
      _ => ('공개', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}
