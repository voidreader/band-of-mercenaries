import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_effect_service.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';

void main() {
  group('TraitEffectService', () {
    test('returns 0 when no traits', () {
      expect(
        TraitEffectService.calculateSuccessRateBonus(
          traitIds: [], allTraits: [], questTypeId: 'raid', partySize: 1,
        ),
        0.0,
      );
    });

    test('returns 0 when effectJson is null', () {
      final traits = [
        const TraitData(key: 'veteran', name: '베테랑', categoryKey: 'Experience', type: 'acquired'),
      ];
      expect(
        TraitEffectService.calculateSuccessRateBonus(
          traitIds: ['veteran'], allTraits: traits, questTypeId: 'raid', partySize: 1,
        ),
        0.0,
      );
    });

    test('calculates success rate bonus from effectJson', () {
      final traits = [
        TraitData(key: 'veteran', name: '베테랑', categoryKey: 'Experience', type: 'acquired',
          effectJson: {'success_rate': 5.0}),
      ];
      expect(
        TraitEffectService.calculateSuccessRateBonus(
          traitIds: ['veteran'], allTraits: traits, questTypeId: 'raid', partySize: 1,
        ),
        5.0,
      );
    });

    test('stacks bonuses from multiple traits', () {
      final traits = [
        TraitData(key: 'veteran', name: '베테랑', categoryKey: 'Experience', type: 'acquired',
          effectJson: {'success_rate': 5.0}),
        TraitData(key: 'tactician', name: '전술가', categoryKey: 'CombatStyle', type: 'acquired',
          effectJson: {'success_rate': 3.0, 'team_success_rate': 4.0}),
      ];
      expect(
        TraitEffectService.calculateSuccessRateBonus(
          traitIds: ['veteran', 'tactician'], allTraits: traits, questTypeId: 'raid', partySize: 2,
        ),
        12.0, // 5 + 3 + 4
      );
    });

    test('applies quest-type-specific bonus', () {
      final traits = [
        TraitData(key: 'charger', name: '돌격대장', categoryKey: 'CombatStyle', type: 'acquired',
          effectJson: {'raid_success_rate': 5.0}),
      ];
      expect(
        TraitEffectService.calculateSuccessRateBonus(
          traitIds: ['charger'], allTraits: traits, questTypeId: 'raid', partySize: 1,
        ),
        5.0,
      );
      expect(
        TraitEffectService.calculateSuccessRateBonus(
          traitIds: ['charger'], allTraits: traits, questTypeId: 'hunt', partySize: 1,
        ),
        0.0,
      );
    });

    test('calculates death rate modifier', () {
      final traits = [
        TraitData(key: 'survivor', name: '생존 전문가', categoryKey: 'Survival', type: 'acquired',
          effectJson: {'death_rate': -0.02}),
      ];
      expect(
        TraitEffectService.calculateDeathRateModifier(traitIds: ['survivor'], allTraits: traits),
        -0.02,
      );
    });

    test('calculates injury rate modifier', () {
      final traits = [
        TraitData(key: 'tough', name: '억척스러움', categoryKey: 'Survival', type: 'acquired',
          effectJson: {'injury_rate': -0.05}),
      ];
      expect(
        TraitEffectService.calculateInjuryRateModifier(traitIds: ['tough'], allTraits: traits),
        -0.05,
      );
    });
  });
}
