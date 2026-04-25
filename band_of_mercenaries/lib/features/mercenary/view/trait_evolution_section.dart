import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class TraitEvolutionSection extends StatelessWidget {
  final TraitData trait;
  final Mercenary mercenary;
  final List<TraitData> allTraits;
  final List<TraitTransition> myTransitions;
  final List<TraitComboEvolution> myComboEvolutions;
  final Set<String> myTraitKeys;

  const TraitEvolutionSection({
    super.key,
    required this.trait,
    required this.mercenary,
    required this.allTraits,
    required this.myTransitions,
    required this.myComboEvolutions,
    required this.myTraitKeys,
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
          (t) => _buildSingleEvolutionCard(t),
        ),
        ...myComboEvolutions.map(
          (c) => _buildComboEvolutionCard(c),
        ),
      ],
    );
  }

  Widget _buildSingleEvolutionCard(TraitTransition transition) {
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

  Widget _buildComboEvolutionCard(TraitComboEvolution combo) {
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
