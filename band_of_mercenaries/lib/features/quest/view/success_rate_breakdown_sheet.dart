import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/features/quest/domain/success_rate_breakdown.dart';

/// 성공률 분해 레이어별 표시 시트.
/// [showModalBottomSheet]의 builder에서 반환하여 사용한다.
class SuccessRateBreakdownSheet extends StatelessWidget {
  final SuccessRateBreakdown breakdown;
  const SuccessRateBreakdownSheet({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <_BreakdownEntry>[
      _BreakdownEntry(label: '기본값', value: breakdown.base),
      _BreakdownEntry(label: '파티력 비율', value: breakdown.powerRatioContribution),
      _BreakdownEntry(label: '퀘스트 유형 보정', value: breakdown.questMod),
      _BreakdownEntry(label: '상성', value: breakdown.roleSynergy),
      _BreakdownEntry(label: '트레잇', value: breakdown.traitBonus),
      _BreakdownEntry(label: '세력 패시브', value: breakdown.factionPassiveBonus),
      if (breakdown.sharedCapLoss > 0)
        _BreakdownEntry(label: '공유 상한 도달', value: -breakdown.sharedCapLoss),
      _BreakdownEntry(label: '거리 패널티', value: breakdown.distancePenalty),
    ];

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
            const SizedBox(height: 12),
            Text('성공률 ${breakdown.finalRate.round()}%',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Divider(),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.label, style: theme.textTheme.bodyMedium),
                    ),
                    Text(
                      _formatValue(e.value),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _valueColor(e.value, theme),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('합계', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '${breakdown.finalRate.round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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

  String _formatValue(double v) {
    final rounded = v.toStringAsFixed(1);
    if (v > 0) return '+$rounded%p';
    return '$rounded%p';
  }

  Color _valueColor(double v, ThemeData theme) {
    if (v > 0) return theme.colorScheme.primary;
    if (v < 0) return theme.colorScheme.error;
    return theme.textTheme.bodyMedium?.color ?? Colors.black;
  }
}

class _BreakdownEntry {
  final String label;
  final double value;
  const _BreakdownEntry({required this.label, required this.value});
}
