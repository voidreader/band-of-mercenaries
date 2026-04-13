import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';

class TraitSlotGrid extends StatelessWidget {
  final List<TraitData> innateTraits;
  final List<TraitData> acquiredTraits;
  final Set<String> evolvableTraitKeys;
  final void Function(TraitData trait)? onTraitTap;

  static const List<String> _innateCategories = ['Physical', 'Background', 'Talent'];
  static const List<String> acquiredCategoriesOrder = [
    'CombatStyle',
    'Survival',
    'Behavior',
    'Mental',
    'Experience',
  ];

  const TraitSlotGrid({
    super.key,
    required this.innateTraits,
    required this.acquiredTraits,
    this.evolvableTraitKeys = const {},
    this.onTraitTap,
  });

  /// Returns a list of [maxAcquired] category keys: owned categories first,
  /// then filled with categories from [acquiredCategoriesOrder] not already
  /// in [ownedCategoryKeys] until [maxAcquired] is reached.
  static List<String> buildAcquiredSlotCategories({
    required List<String> ownedCategoryKeys,
    required int maxAcquired,
  }) {
    final result = List<String>.from(ownedCategoryKeys);
    if (result.length >= maxAcquired) {
      return result.take(maxAcquired).toList();
    }
    for (final cat in acquiredCategoriesOrder) {
      if (result.length >= maxAcquired) break;
      if (!result.contains(cat)) {
        result.add(cat);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('선천 트레잇'),
        const SizedBox(height: 6),
        _buildInnateRow(),
        const SizedBox(height: 12),
        _buildSectionHeader('후천 트레잇 (${acquiredTraits.length}/4)'),
        const SizedBox(height: 6),
        _buildAcquiredWrap(),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildInnateRow() {
    // Map category -> owned trait
    final Map<String, TraitData?> categoryToTrait = {};
    for (final cat in _innateCategories) {
      categoryToTrait[cat] = null;
    }
    for (final trait in innateTraits) {
      if (_innateCategories.contains(trait.categoryKey)) {
        categoryToTrait[trait.categoryKey] = trait;
      }
    }

    return Row(
      children: _innateCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final cat = entry.value;
        final trait = categoryToTrait[cat];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < _innateCategories.length - 1 ? 6 : 0),
            child: trait != null
                ? _buildFilledSlot(trait)
                : _buildEmptySlot(cat),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcquiredWrap() {
    final ownedCategoryKeys = acquiredTraits.map((t) => t.categoryKey).toList();
    final slots = buildAcquiredSlotCategories(
      ownedCategoryKeys: ownedCategoryKeys,
      maxAcquired: 4,
    );

    // Map category -> owned acquired trait
    final Map<String, TraitData?> categoryToTrait = {};
    for (final trait in acquiredTraits) {
      categoryToTrait[trait.categoryKey] = trait;
    }

    final slotWidgets = slots.map((cat) {
      final trait = categoryToTrait[cat];
      return SizedBox(
        width: double.infinity,
        child: trait != null
            ? _buildFilledSlot(trait)
            : _buildEmptySlot(cat),
      );
    }).toList();

    // 2-per-row using Wrap
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: slotWidgets.map((child) {
        return FractionallySizedBox(
          widthFactor: 0.5,
          child: Padding(
            padding: const EdgeInsets.only(right: 0),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilledSlot(TraitData trait) {
    final color = AppTheme.traitCategoryColors[trait.categoryKey] ?? AppTheme.textHint;
    final isEvolvable = evolvableTraitKeys.contains(trait.key);

    final slot = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isEvolvable
            ? const Color(0xFFFFF9C4).withValues(alpha: 0.6)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trait.categoryKey,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trait.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (isEvolvable) ...[
            const SizedBox(height: 2),
            const Text(
              '진화 가능',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF57F17),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTraitTap != null) {
      return GestureDetector(
        onTap: () => onTraitTap!(trait),
        child: slot,
      );
    }
    return slot;
  }

  Widget _buildEmptySlot(String categoryKey) {
    final borderColor = AppTheme.textHint.withValues(alpha: 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            categoryKey,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '—',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
