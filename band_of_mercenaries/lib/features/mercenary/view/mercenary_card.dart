import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/shared/widgets/status_badge.dart';

class MercenaryCard extends StatelessWidget {
  final Mercenary mercenary;
  final Job job;
  final List<TraitData> traits;

  const MercenaryCard({
    super.key,
    required this.mercenary,
    required this.job,
    this.traits = const [],
  });

  double _xpProgress(int level, int xp) {
    if (level >= ExperienceService.maxLevel) return 1.0;
    final current = ExperienceService.levelThresholds[level - 1];
    final next = ExperienceService.levelThresholds[level];
    if (next <= current) return 1.0;
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.tierColor(job.tier);
    final tierBg = AppTheme.tierBgColor(job.tier);
    final isMaxLevel = mercenary.level >= ExperienceService.maxLevel;

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
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Lv.${mercenary.level}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
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
          // XP progress bar (hidden at max level)
          if (!isMaxLevel) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _xpProgress(mercenary.level, mercenary.xp),
                minHeight: 4,
                backgroundColor: Colors.amber.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'ATK ${mercenary.effectiveAtk} · DEF ${mercenary.effectiveDef} · HP ${mercenary.effectiveHp}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 4),
          if (traits.isEmpty)
            const Text('알 수 없는 특성', style: TextStyle(fontSize: 12, color: AppTheme.textHint))
          else
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: traits.map((t) {
                final color = AppTheme.traitCategoryColors[t.categoryKey] ?? AppTheme.textHint;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t.name, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
