import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_deletion_service.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_evolution_section.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_synergy_conflict_section.dart';

class TraitDetailDialog extends StatelessWidget {
  final TraitData trait;
  final Mercenary mercenary;
  final List<TraitData> allTraits;
  final List<TraitTransition> transitions;
  final List<TraitComboEvolution> comboEvolutions;
  final List<TraitConflict> conflicts;
  final List<TraitSynergy> synergies;
  final VoidCallback? onDelete;
  final int infirmaryLevel;
  final int currentGold;
  final bool isDispatched;

  const TraitDetailDialog({
    super.key,
    required this.trait,
    required this.mercenary,
    required this.allTraits,
    required this.transitions,
    required this.comboEvolutions,
    required this.conflicts,
    required this.synergies,
    this.onDelete,
    required this.infirmaryLevel,
    required this.currentGold,
    required this.isDispatched,
  });

  String _typeLabel(String type) {
    switch (type) {
      case 'innate':
        return '선천';
      case 'acquired':
        return '후천acquired';
      case 'evolved':
        return '후천evolved';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        AppTheme.traitCategoryColors[trait.categoryKey] ?? AppTheme.textHint;

    final myTraitKeys = Set<String>.from(mercenary.allTraitIds);

    // Gather data for sections
    final myTransitions = trait.type == 'acquired'
        ? transitions.where((t) => t.fromTraitKey == trait.key).toList()
        : <TraitTransition>[];

    final myComboEvolutions = trait.type == 'acquired'
        ? comboEvolutions
            .where((c) =>
                c.requiredTrait1 == trait.key || c.requiredTrait2 == trait.key)
            .toList()
        : <TraitComboEvolution>[];

    final mySynergies = trait.type == 'innate'
        ? synergies.where((s) => s.innateTraitKey == trait.key).toList()
        : <TraitSynergy>[];

    final myConflicts =
        conflicts.where((c) => c.traitKey == trait.key).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, accentColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (trait.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDescriptionBox(trait.description),
                    ],
                    if (trait.effectText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildEffectBox(trait.effectText),
                    ],
                    if (myTransitions.isNotEmpty || myComboEvolutions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TraitEvolutionSection(
                        trait: trait,
                        mercenary: mercenary,
                        allTraits: allTraits,
                        myTransitions: myTransitions,
                        myComboEvolutions: myComboEvolutions,
                        myTraitKeys: myTraitKeys,
                      ),
                    ],
                    if (trait.type == 'evolved') ...[
                      const SizedBox(height: 12),
                      _buildEvolvedBadge(),
                    ],
                    if (mySynergies.isNotEmpty || myConflicts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TraitSynergyConflictSection(
                        allTraits: allTraits,
                        mySynergies: mySynergies,
                        myConflicts: myConflicts,
                      ),
                    ],
                    _buildDeleteSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteSection(BuildContext context) {
    if (trait.type == 'innate') return const SizedBox.shrink();

    final result = TraitDeletionService.canDelete(
      trait: trait,
      mercenary: mercenary,
      infirmaryLevel: infirmaryLevel,
      currentGold: currentGold,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          const Divider(color: AppTheme.borderLight),
          const SizedBox(height: 8),
          if (result.canDelete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showDeleteConfirmDialog(context, result.cost),
                child: Text('삭제 — ${result.cost}G'),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.grey[500],
                    ),
                    onPressed: null,
                    child: Text('삭제 — ${result.cost}G'),
                  ),
                ),
                if (result.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      result.reason!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int cost) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('트레잇 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trait.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (trait.effectText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(trait.effectText, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 12),
            Text('비용: ${cost}G', style: const TextStyle(color: Color(0xFFC62828))),
            const SizedBox(height: 8),
            const Text(
              '삭제된 트레잇은 다시 획득할 수 없습니다.',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3, right: 8),
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trait.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trait.categoryKey} · ${_typeLabel(trait.type)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            color: AppTheme.textHint,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEffectBox(String effectText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '★ ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              effectText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1B5E20),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolvedBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF9A825)),
      ),
      child: const Text(
        '✨ 진화 완료 (최종 형태)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE65100),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

}
