import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class MilestoneTimeline extends StatelessWidget {
  final List<Map<String, dynamic>>? milestones;
  final int currentLevel;

  const MilestoneTimeline({
    super.key,
    required this.milestones,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones == null || milestones!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < milestones!.length; i++) ...[
          _buildMilestoneRow(milestones![i], i < milestones!.length - 1),
        ],
      ],
    );
  }

  Widget _buildMilestoneRow(Map<String, dynamic> milestone, bool hasNext) {
    final level = milestone['level'] as int? ?? 0;
    final label = milestone['label'] as String? ?? '';
    final achieved = level <= currentLevel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achieved ? AppTheme.tier3 : AppTheme.border,
                ),
                child: Icon(
                  achieved ? Icons.check : Icons.lock_outline,
                  size: 14,
                  color: achieved ? Colors.white : AppTheme.textHint,
                ),
              ),
              if (hasNext)
                Container(
                  width: 2,
                  height: 12,
                  color: AppTheme.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: achieved ? AppTheme.textPrimary : AppTheme.textHint,
                      fontWeight: achieved ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (!achieved)
                  Text(
                    'Lv.$level',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
