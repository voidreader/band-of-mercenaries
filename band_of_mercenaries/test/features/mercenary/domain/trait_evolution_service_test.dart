import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';

void main() {
  final allTraits = [
    const TraitData(key: 'strong_build', name: '강인한 체격', categoryKey: 'Physical', type: 'innate'),
    const TraitData(key: 'berserker_talent', name: '광전사의 피', categoryKey: 'Talent', type: 'innate'),
    const TraitData(key: 'duelist', name: '결투가', categoryKey: 'CombatStyle', type: 'acquired'),
    const TraitData(key: 'charger', name: '돌격대장', categoryKey: 'CombatStyle', type: 'acquired'),
    const TraitData(key: 'confident', name: '자신감', categoryKey: 'Mental', type: 'acquired'),
    const TraitData(key: 'survivor', name: '생존 전문가', categoryKey: 'Survival', type: 'acquired'),
    const TraitData(key: 'lucky', name: '행운아', categoryKey: 'Experience', type: 'acquired'),
    const TraitData(key: 'blade_master', name: '검의 달인', categoryKey: 'CombatStyle', type: 'evolved'),
    const TraitData(key: 'slayer', name: '학살자', categoryKey: 'CombatStyle', type: 'evolved'),
    const TraitData(key: 'phoenix', name: '불사조', categoryKey: 'Survival', type: 'evolved'),
    const TraitData(key: 'legend', name: '전설', categoryKey: 'Experience', type: 'evolved'),
  ];

  final transitions = [
    const TraitTransition(id: 1, fromTraitKey: 'duelist', toTraitKey: 'blade_master',
        conditionJson: {'solo_dispatch_count': 30, 'high_difficulty_count': 10}),
  ];

  final comboEvolutions = [
    const TraitComboEvolution(id: 1, requiredTrait1: 'charger', requiredTrait2: 'confident', resultTraitKey: 'slayer'),
    const TraitComboEvolution(id: 2, requiredTrait1: 'survivor', requiredTrait2: 'lucky', resultTraitKey: 'phoenix'),
  ];

  group('TraitEvolutionService — single evolution', () {
    test('returns candidate when condition met', () {
      final candidates = TraitEvolutionService.checkSingleEvolutions(
        stats: {'solo_dispatch_count': 35, 'high_difficulty_count': 12},
        currentTraitIds: ['strong_build', 'duelist'],
        transitions: transitions,
        allTraits: allTraits,
      );
      expect(candidates.length, 1);
      expect(candidates.first.fromKey, 'duelist');
      expect(candidates.first.toKey, 'blade_master');
    });

    test('returns empty when condition not met', () {
      final candidates = TraitEvolutionService.checkSingleEvolutions(
        stats: {'solo_dispatch_count': 10, 'high_difficulty_count': 5},
        currentTraitIds: ['strong_build', 'duelist'],
        transitions: transitions,
        allTraits: allTraits,
      );
      expect(candidates, isEmpty);
    });

    test('ignores innate traits', () {
      final fakeTransitions = [
        const TraitTransition(id: 99, fromTraitKey: 'strong_build', toTraitKey: 'blade_master',
            conditionJson: {'solo_dispatch_count': 1}),
      ];
      final candidates = TraitEvolutionService.checkSingleEvolutions(
        stats: {'solo_dispatch_count': 100},
        currentTraitIds: ['strong_build'],
        transitions: fakeTransitions,
        allTraits: allTraits,
      );
      expect(candidates, isEmpty);
    });

    test('ignores transition when trait not owned', () {
      final candidates = TraitEvolutionService.checkSingleEvolutions(
        stats: {'solo_dispatch_count': 100, 'high_difficulty_count': 100},
        currentTraitIds: ['strong_build', 'charger'],
        transitions: transitions,
        allTraits: allTraits,
      );
      expect(candidates, isEmpty);
    });
  });

  group('TraitEvolutionService — combo evolution', () {
    test('returns candidate when both traits owned', () {
      final candidates = TraitEvolutionService.checkComboEvolutions(
        currentTraitIds: ['strong_build', 'charger', 'confident'],
        comboEvolutions: comboEvolutions,
        allTraits: allTraits,
      );
      expect(candidates.length, 1);
      expect(candidates.first.trait1Key, 'charger');
      expect(candidates.first.trait2Key, 'confident');
      expect(candidates.first.resultKey, 'slayer');
    });

    test('returns empty when only one trait owned', () {
      final candidates = TraitEvolutionService.checkComboEvolutions(
        currentTraitIds: ['strong_build', 'charger'],
        comboEvolutions: comboEvolutions,
        allTraits: allTraits,
      );
      expect(candidates, isEmpty);
    });

    test('skips when result category occupied and not freed by source', () {
      // legend(Experience) requires veteran(Exp) + confident(Mental)
      // If Experience slot is already occupied by lucky, and lucky is NOT a source,
      // then result can't fit
      final comboWithThirdCategory = [
        const TraitComboEvolution(id: 3, requiredTrait1: 'charger', requiredTrait2: 'confident', resultTraitKey: 'legend'),
      ];
      // charger=CombatStyle, confident=Mental → freed: {CombatStyle, Mental}
      // legend=Experience → not in freed set → check if Experience occupied
      // lucky occupies Experience → skip
      final candidates = TraitEvolutionService.checkComboEvolutions(
        currentTraitIds: ['charger', 'confident', 'lucky'],
        comboEvolutions: comboWithThirdCategory,
        allTraits: allTraits,
      );
      expect(candidates, isEmpty);
    });

    test('allows when result category freed by source consumption', () {
      // charger(CombatStyle) + confident(Mental) → slayer(CombatStyle)
      // CombatStyle freed by charger consumption → slayer fits
      final candidates = TraitEvolutionService.checkComboEvolutions(
        currentTraitIds: ['charger', 'confident', 'survivor'],
        comboEvolutions: comboEvolutions,
        allTraits: allTraits,
      );
      expect(candidates.length, 1);
      expect(candidates.first.resultKey, 'slayer');
    });

    test('allows when result category not occupied at all', () {
      // survivor(Survival) + lucky(Experience) → phoenix(Survival)
      // Survival freed by survivor → phoenix fits
      final candidates = TraitEvolutionService.checkComboEvolutions(
        currentTraitIds: ['strong_build', 'survivor', 'lucky'],
        comboEvolutions: comboEvolutions,
        allTraits: allTraits,
      );
      expect(candidates.length, 1);
      expect(candidates.first.resultKey, 'phoenix');
    });
  });
}
