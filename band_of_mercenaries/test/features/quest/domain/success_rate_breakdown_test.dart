import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';

void main() {
  group('QuestCalculator.calculateSuccessRateBreakdown', () {
    test('기본 케이스 - warrior 1인 파티, 파티력==적파워', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
        partyRoles: const ['warrior'],
      );
      expect(b.base, 50.0);
      expect(b.powerRatioContribution, 0.0);
      expect(b.questMod, 0.0); // raid 보정 0
      expect(b.roleSynergy, 8.0); // warrior raid +8
      expect(b.traitBonus, 0.0);
      expect(b.factionPassiveBonus, 0.0);
      expect(b.sharedCapLoss, 0.0);
      expect(b.distancePenalty, 0.0);
      expect(b.total, 58.0);
      expect(b.finalRate, 58.0);
    });

    test('파티력 2배 - powerRatioContribution +50', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 200,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
      );
      expect(b.powerRatioContribution, 50.0); // (2.0 - 1.0) * 50
      expect(b.roleSynergy, 0.0); // 빈 파티
      expect(b.finalRate, 95.0); // clamp
    });

    test('enemyPower <= 0 guard', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 0,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
      );
      expect(b.finalRate, 95.0);
      expect(b.total, 95.0);
    });

    test('빈 partyRoles → roleSynergy 0', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'explore',
        distancePenalty: 0,
        partyRoles: const [],
      );
      expect(b.roleSynergy, 0.0);
      expect(b.questMod, 5.0); // explore +5
      expect(b.finalRate, 55.0);
    });

    test('factionPassiveBonus 반영', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
        factionPassiveBonus: 10.0,
      );
      expect(b.factionPassiveBonus, 10.0);
      expect(b.finalRate, 60.0);
    });

    test('passiveSharedCapLoss 필드 전달', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
        factionPassiveBonus: 20.0,
        passiveSharedCapLoss: 5.0,
      );
      expect(b.sharedCapLoss, 5.0);
      // sharedCapLoss는 합산에 영향 없음 (PassiveBonusService clamp 이미 적용됨)
      expect(b.finalRate, 70.0);
    });

    test('distancePenalty 음수 저장', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 20,
      );
      expect(b.distancePenalty, -20.0);
      expect(b.finalRate, 30.0);
    });

    test('rankBonus는 항상 0.0 stub', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
      );
      expect(b.rankBonus, 0.0);
    });

    test('합계 clamp(5, 95)', () {
      // 극단적으로 낮춰 5 미만이 될 상황: total = 50 + (0.1-1)*50 + 0 + 0 + 0 + 0 - 50 = -45
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 10,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 50,
      );
      expect(b.finalRate, 5.0);
      expect(b.total, lessThan(5.0));
    });

    test('warrior+mage 파티 raid → roleSynergy 평균 +3', () {
      final b = QuestCalculator.calculateSuccessRateBreakdown(
        partyPower: 100,
        enemyPower: 100,
        traitBonuses: const [],
        questTypeId: 'raid',
        distancePenalty: 0,
        partyRoles: const ['warrior', 'mage'],
      );
      expect(b.roleSynergy, 3.0);
      expect(b.finalRate, 53.0);
    });
  });
}
