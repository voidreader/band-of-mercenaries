import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_acquisition_service.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';

void main() {
  final categories = [
    const TraitCategory(key: 'Physical', name: '육체적 특성', slotType: 'innate'),
    const TraitCategory(key: 'CombatStyle', name: '전투 성향', slotType: 'acquired'),
    const TraitCategory(key: 'Survival', name: '생존 성향', slotType: 'acquired'),
    const TraitCategory(key: 'Behavior', name: '행동 스타일', slotType: 'acquired'),
    const TraitCategory(key: 'Mental', name: '정신 상태', slotType: 'acquired'),
    const TraitCategory(key: 'Experience', name: '경험', slotType: 'acquired'),
  ];

  final allTraits = [
    const TraitData(key: 'strong_build', name: '강인한 체격', categoryKey: 'Physical', type: 'innate'),
    const TraitData(key: 'berserker_talent', name: '광전사의 피', categoryKey: 'Talent', type: 'innate'),
    TraitData(key: 'tactician', name: '전술가', categoryKey: 'CombatStyle', type: 'acquired',
      acquisitionCondition: {'team_dispatch_count': 15, 'success_count': 10}),
    TraitData(key: 'survivor', name: '생존 전문가', categoryKey: 'Survival', type: 'acquired',
      acquisitionCondition: {'near_death_count': 3, 'success_count': 5}),
    TraitData(key: 'lone_wolf', name: '고독한 늑대', categoryKey: 'Behavior', type: 'acquired',
      acquisitionCondition: {'solo_dispatch_count': 15}),
    TraitData(key: 'cautious', name: '신중함', categoryKey: 'Survival', type: 'acquired',
      acquisitionCondition: {'consecutive_success': 8}),
    TraitData(key: 'charger', name: '돌격대장', categoryKey: 'CombatStyle', type: 'acquired',
      acquisitionCondition: {'raid_count': 10, 'great_success_count': 3}),
  ];

  group('TraitAcquisitionService', () {
    test('returns candidate when condition met', () {
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'solo_dispatch_count': 20},
        currentTraitIds: ['strong_build'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: [],
      );
      expect(candidates, contains('lone_wolf'));
    });

    test('returns empty when condition not met', () {
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'solo_dispatch_count': 5},
        currentTraitIds: ['strong_build'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: [],
      );
      expect(candidates, isEmpty);
    });

    test('skips already owned trait', () {
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'solo_dispatch_count': 20},
        currentTraitIds: ['strong_build', 'lone_wolf'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: [],
      );
      expect(candidates, isNot(contains('lone_wolf')));
    });

    test('skips category already occupied', () {
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'near_death_count': 5, 'success_count': 10, 'consecutive_success': 10},
        currentTraitIds: ['strong_build', 'survivor'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: [],
      );
      // cautious is also Survival, so it should be skipped since survivor occupies Survival
      expect(candidates, isNot(contains('cautious')));
    });

    test('skips conflicting trait', () {
      final conflicts = [
        const TraitConflict(traitKey: 'berserker_talent', conflictTraitKey: 'cautious'),
        const TraitConflict(traitKey: 'cautious', conflictTraitKey: 'berserker_talent'),
      ];
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'consecutive_success': 10},
        currentTraitIds: ['berserker_talent'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: conflicts,
        synergies: [],
      );
      expect(candidates, isNot(contains('cautious')));
    });

    test('skips trait in history (no re-acquisition)', () {
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'solo_dispatch_count': 20},
        currentTraitIds: ['strong_build'],
        traitHistory: ['lone_wolf'],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: [],
      );
      expect(candidates, isNot(contains('lone_wolf')));
    });

    test('synergy reduces acquisition threshold', () {
      final synergies = [
        const TraitSynergy(id: 1, innateTraitKey: 'berserker_talent', targetTraitKey: 'charger', reductionPercent: 30),
      ];
      // Without synergy: raid_count >= 10 AND great_success_count >= 3
      // With 30% reduction: raid_count >= 7 AND great_success_count >= 3 (ceil)
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'raid_count': 7, 'great_success_count': 3},
        currentTraitIds: ['berserker_talent'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: synergies,
      );
      expect(candidates, contains('charger'));
    });

    test('without synergy same stats do not meet condition', () {
      final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
        stats: {'raid_count': 7, 'great_success_count': 3},
        currentTraitIds: ['strong_build'],
        traitHistory: [],
        allTraits: allTraits,
        categories: categories,
        conflicts: [],
        synergies: [],
      );
      expect(candidates, isNot(contains('charger')));
    });
  });
}
