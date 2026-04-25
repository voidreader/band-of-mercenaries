import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';

class TraitSynergyConflictSection extends StatelessWidget {
  final List<TraitData> allTraits;
  final List<TraitSynergy> mySynergies;
  final List<TraitConflict> myConflicts;

  const TraitSynergyConflictSection({
    super.key,
    required this.allTraits,
    required this.mySynergies,
    required this.myConflicts,
  });

  TraitData? _findTrait(String key) {
    try {
      return allTraits.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mySynergies.isNotEmpty) _buildSynergySection(),
        if (myConflicts.isNotEmpty) ...[
          if (mySynergies.isNotEmpty) const SizedBox(height: 12),
          _buildConflictSection(),
        ],
      ],
    );
  }

  Widget _buildSynergySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '시너지',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: mySynergies.map((s) {
              final targetTrait = _findTrait(s.targetTraitKey);
              final targetName = targetTrait?.name ?? s.targetTraitKey;
              final reduction = s.reductionPercent.toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '→ $targetName 획득 조건 $reduction% 감소',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0D47A1),
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConflictSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '충돌',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEF9A9A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: myConflicts.map((c) {
              final conflictTrait = _findTrait(c.conflictTraitKey);
              final conflictName = conflictTrait?.name ?? c.conflictTraitKey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '🚫 $conflictName — 동시 보유 불가',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC62828),
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
