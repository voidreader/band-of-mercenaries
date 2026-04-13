import 'dart:math';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';

class TraitAcquisitionService {
  static const _questTypeCountKeys = ['raid_count', 'hunt_count', 'escort_count', 'explore_count'];

  static List<String> checkAcquisitionCandidates({
    required Map<String, int> stats,
    required List<String> currentTraitIds,
    required List<String> traitHistory,
    required List<TraitData> allTraits,
    required List<TraitCategory> categories,
    required List<TraitConflict> conflicts,
    required List<TraitSynergy> synergies,
  }) {
    final currentCategories = <String>{};
    int acquiredCount = 0;
    for (final id in currentTraitIds) {
      final t = allTraits.where((t) => t.key == id).firstOrNull;
      if (t != null) {
        currentCategories.add(t.categoryKey);
        if (t.type != 'innate') acquiredCount++;
      }
    }

    final candidates = <String>[];
    for (final trait in allTraits.where((t) => t.type == 'acquired')) {
      if (currentTraitIds.contains(trait.key)) continue;
      if (traitHistory.contains(trait.key)) continue;
      if (currentCategories.contains(trait.categoryKey)) continue;
      if (acquiredCount >= GameConstants.maxAcquiredTraits) continue;
      if (hasConflict(trait.key, currentTraitIds, conflicts)) continue;
      if (trait.acquisitionCondition == null || trait.acquisitionCondition!.isEmpty) continue;
      if (_meetsCondition(stats, trait.acquisitionCondition!, trait.key, currentTraitIds, synergies, allTraits)) {
        candidates.add(trait.key);
      }
    }
    return candidates;
  }

  static bool hasConflict(
    String candidateKey,
    List<String> currentTraitIds,
    List<TraitConflict> conflicts,
  ) {
    for (final traitKey in currentTraitIds) {
      if (conflicts.any((c) =>
          (c.traitKey == candidateKey && c.conflictTraitKey == traitKey) ||
          (c.traitKey == traitKey && c.conflictTraitKey == candidateKey))) {
        return true;
      }
    }
    return false;
  }

  static bool _meetsCondition(
    Map<String, int> stats,
    Map<String, dynamic> condition,
    String targetTraitKey,
    List<String> currentTraitIds,
    List<TraitSynergy> synergies,
    List<TraitData> allTraits,
  ) {
    final reductionPercent = _calculateSynergyReduction(
      targetTraitKey, currentTraitIds, synergies, allTraits,
    );
    final reductionFactor = 1.0 - (reductionPercent / 100.0);

    for (final entry in condition.entries) {
      final key = entry.key;
      final requiredRaw = (entry.value as num).toDouble();
      final required = (requiredRaw * reductionFactor).ceil();

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

  static double _calculateSynergyReduction(
    String targetTraitKey,
    List<String> currentTraitIds,
    List<TraitSynergy> synergies,
    List<TraitData> allTraits,
  ) {
    double bestReduction = 0.0;
    for (final traitKey in currentTraitIds) {
      final trait = allTraits.where((t) => t.key == traitKey).firstOrNull;
      if (trait == null || trait.type != 'innate') continue;
      for (final syn in synergies) {
        if (syn.innateTraitKey == traitKey && syn.targetTraitKey == targetTraitKey) {
          if (syn.reductionPercent > bestReduction) {
            bestReduction = syn.reductionPercent;
          }
        }
      }
    }
    return bestReduction;
  }
}
