import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class TraitDetailDialog extends StatelessWidget {
  final TraitData trait;
  final Mercenary mercenary;
  final List<TraitData> allTraits;
  final List<TraitTransition> transitions;
  final List<TraitComboEvolution> comboEvolutions;
  final List<TraitConflict> conflicts;
  final List<TraitSynergy> synergies;

  const TraitDetailDialog({
    super.key,
    required this.trait,
    required this.mercenary,
    required this.allTraits,
    required this.transitions,
    required this.comboEvolutions,
    required this.conflicts,
    required this.synergies,
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

  TraitData? _findTrait(String key) {
    try {
      return allTraits.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
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
                      _buildEvolutionSection(
                        myTransitions,
                        myComboEvolutions,
                        myTraitKeys,
                        accentColor,
                      ),
                    ],
                    if (trait.type == 'evolved') ...[
                      const SizedBox(height: 12),
                      _buildEvolvedBadge(),
                    ],
                    if (mySynergies.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSynergySection(mySynergies),
                    ],
                    if (myConflicts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildConflictSection(myConflicts),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildEvolutionSection(
    List<TraitTransition> myTransitions,
    List<TraitComboEvolution> myComboEvolutions,
    Set<String> myTraitKeys,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '진화 경로',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ...myTransitions.map(
          (t) => _buildSingleEvolutionCard(t, myTraitKeys),
        ),
        ...myComboEvolutions.map(
          (c) => _buildComboEvolutionCard(c, myTraitKeys),
        ),
      ],
    );
  }

  Widget _buildSingleEvolutionCard(
    TraitTransition transition,
    Set<String> myTraitKeys,
  ) {
    final toTrait = _findTrait(transition.toTraitKey);
    final toName = toTrait?.name ?? transition.toTraitKey;

    final conditions = transition.conditionJson;
    final conditionEntries = conditions.entries.toList();

    bool allMet = true;
    for (final entry in conditionEntries) {
      final required = (entry.value is int)
          ? entry.value as int
          : int.tryParse(entry.value.toString()) ?? 0;
      final current = mercenary.stats[entry.key] ?? 0;
      if (current < required) {
        allMet = false;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trait.name} → $toName (단일)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (allMet)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF9A825)),
                  ),
                  child: const Text(
                    '⚡ 가능!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),
          if (conditionEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...conditionEntries.map(
              (entry) => _buildConditionProgress(entry.key, entry.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionProgress(String statKey, dynamic requiredValue) {
    final required = (requiredValue is int)
        ? requiredValue
        : int.tryParse(requiredValue.toString()) ?? 0;
    final current = mercenary.stats[statKey] ?? 0;
    final ratio = required > 0 ? (current / required).clamp(0.0, 1.0) : 1.0;

    Color barColor;
    if (ratio >= 0.75) {
      barColor = const Color(0xFF2E7D32);
    } else if (ratio >= 0.50) {
      barColor = const Color(0xFFE65100);
    } else {
      barColor = const Color(0xFFC62828);
    }

    final label = _statLabelKo(statKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
              Text(
                '$current / $required',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboEvolutionCard(
    TraitComboEvolution combo,
    Set<String> myTraitKeys,
  ) {
    final otherKey = combo.requiredTrait1 == trait.key
        ? combo.requiredTrait2
        : combo.requiredTrait1;
    final otherTrait = _findTrait(otherKey);
    final otherName = otherTrait?.name ?? otherKey;
    final resultTrait = _findTrait(combo.resultTraitKey);
    final resultName = resultTrait?.name ?? combo.resultTraitKey;

    final ownsOther = myTraitKeys.contains(otherKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${trait.name} + $otherName → $resultName (조합)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (ownsOther) ...[
            const SizedBox(height: 4),
            Text(
              '$otherName 보유 중',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

  Widget _buildSynergySection(List<TraitSynergy> mySynergies) {
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

  Widget _buildConflictSection(List<TraitConflict> myConflicts) {
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

  static String _statLabelKo(String key) {
    const labelMap = {
      'total_dispatch_count': '총 파견',
      'success_count': '성공',
      'failure_count': '실패',
      'great_success_count': '대성공',
      'great_failure_count': '대실패',
      'solo_dispatch_count': '솔로 파견',
      'team_dispatch_count': '팀 파견',
      'high_difficulty_count': '고난이도 성공',
      'low_difficulty_count': '저난이도 성공',
      'raid_count': '토벌',
      'hunt_count': '사냥',
      'escort_count': '호위',
      'explore_count': '탐색',
      'near_death_count': '아사 직전',
      'injury_count': '부상',
      'survived_great_failure': '대실패 생존',
      'tier_max_visited': '최고 티어 방문',
      'unique_region_count': '지역 탐험',
      'total_travel_distance': '총 이동거리',
      'total_gold_earned': '총 수입',
      'current_level': '현재 레벨',
      'consecutive_success': '연속 성공',
      'consecutive_failure': '연속 실패',
    };
    return labelMap[key] ?? key;
  }
}
