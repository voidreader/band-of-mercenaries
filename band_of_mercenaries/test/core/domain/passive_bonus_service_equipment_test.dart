import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';

void main() {
  group('PassiveBonusService — 장비 소스 통합', () {
    test('collect에 guildEquipments 전달 시 buffer에 append', () {
      final guildEffects = [
        const PassiveEffect.questRewardMultiplier(questType: 'all', value: 0.03),
      ];
      final ce = PassiveBonusService.collect(
        reputation: 0,
        allRanks: const [],
        joinedFactions: const [],
        guildEquipments: guildEffects,
      );
      expect(ce.effects.length, 1);
      expect(PassiveBonusService.getQuestRewardMultiplier(ce, 'raid'), closeTo(1.03, 0.001));
    });

    test('collect에 personalEquipmentLegendaries 전달 시 reward 경로 편입', () {
      final legendary = [
        const PassiveEffect.questRewardMultiplier(questType: 'all', value: 0.12),
      ];
      final ce = PassiveBonusService.collect(
        reputation: 0,
        allRanks: const [],
        joinedFactions: const [],
        personalEquipmentLegendaries: legendary,
      );
      expect(PassiveBonusService.getQuestRewardMultiplier(ce, 'explore'), closeTo(1.12, 0.001));
    });
  });

  group('getInjuryRateMultiplier — 곱셈 스태킹 + 하한 0.10', () {
    test('단일 -0.07 적용 시 0.93 배수', () {
      final ce = CollectedEffects([
        const PassiveEffect.injuryRateModifier(value: -0.07),
      ]);
      expect(PassiveBonusService.getInjuryRateMultiplier(ce), closeTo(0.93, 0.001));
    });

    test('복수 수정자 합산 하한 0.10 clamp', () {
      final ce = CollectedEffects([
        const PassiveEffect.injuryRateModifier(value: -0.50),
        const PassiveEffect.injuryRateModifier(value: -0.60),
      ]);
      expect(PassiveBonusService.getInjuryRateMultiplier(ce), 0.10);
    });

    test('수정자 없으면 1.0 반환', () {
      expect(PassiveBonusService.getInjuryRateMultiplier(const CollectedEffects.empty()), 1.0);
    });
  });

  group('getReputationGainModifier — 가산 + 상한 +0.30', () {
    test('단일 +0.05 반환', () {
      final ce = CollectedEffects([
        const PassiveEffect.reputationGainModifier(value: 0.05),
      ]);
      expect(PassiveBonusService.getReputationGainModifier(ce), closeTo(0.05, 0.001));
    });

    test('합산 +0.50 시 상한 +0.30 clamp', () {
      final ce = CollectedEffects([
        const PassiveEffect.reputationGainModifier(value: 0.20),
        const PassiveEffect.reputationGainModifier(value: 0.30),
      ]);
      expect(PassiveBonusService.getReputationGainModifier(ce), 0.30);
    });

    test('수정자 없으면 0.0 반환', () {
      expect(PassiveBonusService.getReputationGainModifier(const CollectedEffects.empty()), 0.0);
    });
  });
}
