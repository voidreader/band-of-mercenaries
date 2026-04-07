import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final MercenaryStatus status;
  final String? timerText;

  const StatusBadge({super.key, required this.status, this.timerText});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      MercenaryStatus.normal => ('정상', AppTheme.textSecondary, AppTheme.tier1Bg),
      MercenaryStatus.tired => ('피곤', AppTheme.failure, AppTheme.failureBg),
      MercenaryStatus.injured => ('부상${timerText != null ? ' $timerText' : ''}', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
      MercenaryStatus.dead => ('사망', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
