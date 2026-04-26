import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';

// Internal model representing one selectable evolution option card.
class _EvoCard {
  final bool isSingle;
  final String resultKey;
  final List<String> consumedKeys;
  final String? freedCategory; // null for single evolution
  final SingleEvolutionCandidate? single;
  final ComboEvolutionCandidate? combo;

  const _EvoCard({
    required this.isSingle,
    required this.resultKey,
    required this.consumedKeys,
    this.freedCategory,
    this.single,
    this.combo,
  });
}

class TraitEvolutionDialog extends StatefulWidget {
  final String mercenaryName;
  final List<TraitData> currentTraits;
  final List<SingleEvolutionCandidate> singleCandidates;
  final List<ComboEvolutionCandidate> comboCandidates;
  final List<TraitData> allTraits;

  const TraitEvolutionDialog({
    super.key,
    required this.mercenaryName,
    required this.currentTraits,
    required this.singleCandidates,
    required this.comboCandidates,
    required this.allTraits,
  });

  @override
  State<TraitEvolutionDialog> createState() => _TraitEvolutionDialogState();
}

class _TraitEvolutionDialogState extends State<TraitEvolutionDialog> {
  late final List<_EvoCard> _cards;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _cards = _buildCards();
    if (_cards.length == 1) {
      _selectedIndex = 0;
    }
  }

  TraitData? _findTrait(String key) {
    try {
      return widget.allTraits.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
    }
  }

  List<_EvoCard> _buildCards() {
    final cards = <_EvoCard>[];

    for (final s in widget.singleCandidates) {
      cards.add(_EvoCard(
        isSingle: true,
        resultKey: s.toKey,
        consumedKeys: [s.fromKey],
        freedCategory: null,
        single: s,
        combo: null,
      ));
    }

    for (final c in widget.comboCandidates) {
      final resultTrait = _findTrait(c.resultKey);
      final resultCat = resultTrait?.categoryKey;
      final t1Cat = _findTrait(c.trait1Key)?.categoryKey;
      final t2Cat = _findTrait(c.trait2Key)?.categoryKey;

      String? freed;
      if (resultCat != null) {
        if (t1Cat != resultCat) {
          freed = t1Cat;
        } else if (t2Cat != resultCat) {
          freed = t2Cat;
        }
      }

      cards.add(_EvoCard(
        isSingle: false,
        resultKey: c.resultKey,
        consumedKeys: [c.trait1Key, c.trait2Key],
        freedCategory: freed,
        single: null,
        combo: c,
      ));
    }

    return cards;
  }

  bool get _hasCombo => widget.comboCandidates.isNotEmpty;

  String get _headerLabel {
    if (_hasCombo) return '⚡ 조합 진화 가능!';
    return '⚡ 단일 진화 가능!';
  }

  String get _titleText {
    if (_cards.length == 1) return '진화하시겠습니까?';
    return '진화 경로를 선택하세요';
  }

  EvolutionChoice? _buildChoice(int index) {
    final card = _cards[index];
    if (card.isSingle && card.single != null) {
      return EvolutionChoice.fromSingle(card.single!);
    }
    if (!card.isSingle && card.combo != null) {
      return EvolutionChoice.fromCombo(card.combo!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard = _selectedIndex != null ? _cards[_selectedIndex!] : null;
    final consumedSet = selectedCard != null
        ? Set<String>.from(selectedCard.consumedKeys)
        : <String>{};

    final resultName = selectedCard != null
        ? (_findTrait(selectedCard.resultKey)?.name ?? selectedCard.resultKey)
        : '';

    final buttonLabel = selectedCard != null
        ? '$resultName(으)로 진화'
        : '진화 경로를 선택하세요';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildCurrentTraitsPill(consumedSet),
                    const SizedBox(height: 12),
                    ..._cards.asMap().entries.map((entry) {
                      return _buildEvoCard(entry.key, entry.value);
                    }),
                  ],
                ),
              ),
            ),
            _buildButtons(context, selectedCard, buttonLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headerLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFF176),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _titleText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.mercenaryName,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTraitsPill(Set<String> consumedSet) {
    if (widget.currentTraits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '현재 트레잇',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.currentTraits.map((trait) {
            final isConsumed = consumedSet.contains(trait.key);
            final catColor =
                AppTheme.traitCategoryColors[trait.categoryKey] ?? AppTheme.textHint;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConsumed
                    ? const Color(0xFFFFEBEE)
                    : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConsumed
                      ? const Color(0xFFEF9A9A)
                      : AppTheme.borderLight,
                ),
              ),
              child: Text(
                trait.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isConsumed
                      ? const Color(0xFFC62828)
                      : catColor,
                  fontWeight: FontWeight.w600,
                  decoration: isConsumed ? TextDecoration.lineThrough : null,
                  decorationColor:
                      isConsumed ? const Color(0xFFC62828) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEvoCard(int index, _EvoCard card) {
    final isSelected = _selectedIndex == index;
    final resultTrait = _findTrait(card.resultKey);
    final resultName = resultTrait?.name ?? card.resultKey;
    final resultCatKey = resultTrait?.categoryKey ?? '';
    final resultCatColor =
        AppTheme.traitCategoryColors[resultCatKey] ?? AppTheme.textHint;
    final effectText = resultTrait?.effectText ?? '';

    final borderColor = isSelected
        ? const Color(0xFFFFF176).withAlpha(204)
        : AppTheme.border;
    final bgColor = isSelected
        ? const Color(0xFFFFF176).withAlpha(30)
        : AppTheme.surfaceAlt;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: result name + checkmark
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: resultCatColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$resultCatKey · 후천(evolved)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF176),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF9A825)),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Color(0xFFE65100),
                    ),
                  ),
              ],
            ),
            // Effect text
            if (effectText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '★ ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        effectText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B5E20),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Consumed traits
            if (card.consumedKeys.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: card.consumedKeys.map((key) {
                  final t = _findTrait(key);
                  final tName = t?.name ?? key;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Text(
                      tName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC62828),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Color(0xFFC62828),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Freed category badge (combo only)
            if (card.freedCategory != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Text(
                  '${card.freedCategory} 슬롯 해방',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    _EvoCard? selectedCard,
    String buttonLabel,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('보류'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedIndex == null
                  ? null
                  : () {
                      final choice = _buildChoice(_selectedIndex!);
                      Navigator.of(context).pop(choice);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderLight,
                disabledForegroundColor: AppTheme.textHint,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: Text(
                _selectedIndex != null ? buttonLabel : '진화 경로를 선택하세요',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
