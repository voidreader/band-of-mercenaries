import 'package:band_of_mercenaries/core/models/trait_data.dart';

class TraitEffectService {
  static double calculateSuccessRateBonus({
    required List<String> traitIds,
    required List<TraitData> allTraits,
    required String questTypeId,
    required int partySize,
  }) {
    double bonus = 0.0;
    for (final traitKey in traitIds) {
      final trait = allTraits.where((t) => t.key == traitKey).firstOrNull;
      if (trait?.effectJson == null) continue;
      final effects = trait!.effectJson!;
      bonus += (effects['success_rate'] as num?)?.toDouble() ?? 0.0;
      bonus += (effects['${questTypeId}_success_rate'] as num?)?.toDouble() ?? 0.0;
      if (partySize == 1) {
        bonus += (effects['solo_success_rate'] as num?)?.toDouble() ?? 0.0;
      } else {
        bonus += (effects['team_success_rate'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return bonus;
  }

  static double calculateDeathRateModifier({
    required List<String> traitIds,
    required List<TraitData> allTraits,
  }) {
    double modifier = 0.0;
    for (final traitKey in traitIds) {
      final trait = allTraits.where((t) => t.key == traitKey).firstOrNull;
      if (trait?.effectJson == null) continue;
      modifier += (trait!.effectJson!['death_rate'] as num?)?.toDouble() ?? 0.0;
    }
    return modifier;
  }

  static double calculateInjuryRateModifier({
    required List<String> traitIds,
    required List<TraitData> allTraits,
  }) {
    double modifier = 0.0;
    for (final traitKey in traitIds) {
      final trait = allTraits.where((t) => t.key == traitKey).firstOrNull;
      if (trait?.effectJson == null) continue;
      modifier += (trait!.effectJson!['injury_rate'] as num?)?.toDouble() ?? 0.0;
    }
    return modifier;
  }
}
