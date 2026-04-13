import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';

class TraitHistorySection extends StatelessWidget {
  final List<String> traitHistory;
  final List<TraitData> allTraits;
  final List<TraitTransition> transitions;
  final List<TraitComboEvolution> comboEvolutions;

  const TraitHistorySection({
    super.key,
    required this.traitHistory,
    required this.allTraits,
    required this.transitions,
    required this.comboEvolutions,
  });

  String _traitName(String key) {
    try {
      return allTraits.firstWhere((t) => t.key == key).name;
    } catch (_) {
      return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📜 트레잇 히스토리',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (traitHistory.isEmpty)
            const Text(
              '아직 진화 기록이 없습니다',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            )
          else
            ...traitHistory.map((key) => _buildHistoryEntry(key)),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(String key) {
    // Check single evolution
    TraitTransition? transition;
    try {
      transition = transitions.firstWhere((t) => t.fromTraitKey == key);
    } catch (_) {
      transition = null;
    }

    if (transition != null) {
      final originName = _traitName(key);
      final resultName = _traitName(transition.toTraitKey);
      final resultTrait = allTraits.where((t) => t.key == transition!.toTraitKey).isNotEmpty
          ? allTraits.firstWhere((t) => t.key == transition!.toTraitKey)
          : null;
      final resultColor = resultTrait != null
          ? (AppTheme.traitCategoryColors[resultTrait.categoryKey] ?? AppTheme.textSecondary)
          : AppTheme.textSecondary;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(
              originName,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppTheme.textHint,
              ),
            ),
            const Text(
              ' → ',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              resultName,
              style: TextStyle(
                fontSize: 12,
                color: resultColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              ' (진화)',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    // Check combo evolution
    TraitComboEvolution? combo;
    try {
      combo = comboEvolutions.firstWhere(
        (c) => c.requiredTrait1 == key || c.requiredTrait2 == key,
      );
    } catch (_) {
      combo = null;
    }

    if (combo != null) {
      final origin1Name = _traitName(combo.requiredTrait1);
      final origin2Name = _traitName(combo.requiredTrait2);
      final resultName = _traitName(combo.resultTraitKey);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              origin1Name,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppTheme.textHint,
              ),
            ),
            const Text(
              ' + ',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              origin2Name,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppTheme.textHint,
              ),
            ),
            const Text(
              ' → ',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              resultName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFFF176),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              ' (조합)',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    // Neither match — consumed/dissolved
    final originName = _traitName(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            originName,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppTheme.textHint,
            ),
          ),
          const Text(
            ' (소멸)',
            style: TextStyle(fontSize: 11, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}
