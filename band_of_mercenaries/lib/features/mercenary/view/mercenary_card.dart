import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/shared/widgets/status_badge.dart';

class MercenaryCard extends StatelessWidget {
  final Mercenary mercenary;
  final Job job;
  final TraitData trait;

  const MercenaryCard({
    super.key,
    required this.mercenary,
    required this.job,
    required this.trait,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.tierColor(job.tier);
    final tierBg = AppTheme.tierBgColor(job.tier);
    final traitColor = AppTheme.traitColors[trait.id] ?? AppTheme.textHint;

    String? timerText;
    if (mercenary.status == MercenaryStatus.injured && mercenary.injuryEndTime != null) {
      final remaining = mercenary.injuryEndTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        timerText = null;
      } else {
        final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        timerText = '$m:$s';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(mercenary.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text(job.name, style: TextStyle(fontSize: 13, color: tierColor, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tierBg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('T${job.tier}',
                        style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (mercenary.isDispatched)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tier1Bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('파견중', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else
                StatusBadge(status: mercenary.status, timerText: timerText),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ATK ${mercenary.atk} · DEF ${mercenary.def} · HP ${mercenary.hp} · ',
            style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
          Text(trait.name, style: TextStyle(fontSize: 13, color: traitColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
