import 'dart:math';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';

class SingleEvolutionCandidate {
  final String fromKey;
  final String toKey;
  const SingleEvolutionCandidate(this.fromKey, this.toKey);
}

class ComboEvolutionCandidate {
  final String trait1Key;
  final String trait2Key;
  final String resultKey;
  const ComboEvolutionCandidate(this.trait1Key, this.trait2Key, this.resultKey);
}

class TraitEvolutionService {
  static const _questTypeCountKeys = ['raid_count', 'hunt_count', 'escort_count', 'explore_count'];

  static List<SingleEvolutionCandidate> checkSingleEvolutions({
    required Map<String, int> stats,
    required List<String> currentTraitIds,
    required List<TraitTransition> transitions,
    required List<TraitData> allTraits,
  }) {
    final candidates = <SingleEvolutionCandidate>[];
    for (final transition in transitions) {
      if (!currentTraitIds.contains(transition.fromTraitKey)) continue;
      final fromTrait = allTraits.where((t) => t.key == transition.fromTraitKey).firstOrNull;
      if (fromTrait == null || fromTrait.type != 'acquired') continue;
      if (!_meetsCondition(stats, transition.conditionJson)) continue;
      candidates.add(SingleEvolutionCandidate(transition.fromTraitKey, transition.toTraitKey));
    }
    return candidates;
  }

  static List<ComboEvolutionCandidate> checkComboEvolutions({
    required List<String> currentTraitIds,
    required List<TraitComboEvolution> comboEvolutions,
    required List<TraitData> allTraits,
  }) {
    final candidates = <ComboEvolutionCandidate>[];
    for (final combo in comboEvolutions) {
      if (!currentTraitIds.contains(combo.requiredTrait1)) continue;
      if (!currentTraitIds.contains(combo.requiredTrait2)) continue;
      final resultTrait = allTraits.where((t) => t.key == combo.resultTraitKey).firstOrNull;
      if (resultTrait == null) continue;

      // Check if result category slot is available after consuming source traits
      final resultCategory = resultTrait.categoryKey;
      final t1 = allTraits.where((t) => t.key == combo.requiredTrait1).firstOrNull;
      final t2 = allTraits.where((t) => t.key == combo.requiredTrait2).firstOrNull;
      if (t1 == null || t2 == null) continue;

      final freedCategories = {t1.categoryKey, t2.categoryKey};
      if (!freedCategories.contains(resultCategory)) {
        // Result goes to a third category — check if it's already occupied
        final occupiedCategories = <String>{};
        for (final id in currentTraitIds) {
          if (id == combo.requiredTrait1 || id == combo.requiredTrait2) continue;
          final t = allTraits.where((t) => t.key == id).firstOrNull;
          if (t != null) occupiedCategories.add(t.categoryKey);
        }
        if (occupiedCategories.contains(resultCategory)) continue;
      }

      candidates.add(ComboEvolutionCandidate(combo.requiredTrait1, combo.requiredTrait2, combo.resultTraitKey));
    }
    return candidates;
  }

  static bool _meetsCondition(Map<String, int> stats, Map<String, dynamic> condition) {
    for (final entry in condition.entries) {
      final key = entry.key;
      final required = (entry.value as num).toInt();

      if (key == 'max_quest_type_count') {
        final maxCount = _questTypeCountKeys
            .map((k) => stats[k] ?? 0)
            .reduce(max);
        if (maxCount < required) return false;
      } else {
        final actual = stats[key] ?? 0;
        if (actual < required) return false;
      }
    }
    return true;
  }
}
