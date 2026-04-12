import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';

void main() {
  group('QuestCalculator.calculateSuccessRatePreview', () {
    test('returns ~50% when power ratio is 1.0 with no modifiers', () {
      final rate = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 0,
      );
      expect(rate, 50.0);
    });

    test('higher power increases rate', () {
      final rate = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 20, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 0,
      );
      expect(rate, 95.0); // 50 + 50 = 100, clamped to 95
    });

    // Phase 3에서 데이터 드리븐 트레잇 보너스 구현 후 테스트 재작성 예정
    test('trait bonus is 0 pending Phase 3 data-driven implementation', () {
      final withTrait = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: ['veteran'],
        questTypeId: 'loot', distancePenalty: 0,
      );
      final without = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 0,
      );
      expect(withTrait - without, 0.0);
    });

    test('includes quest type modifier', () {
      final explore = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: [],
        questTypeId: 'explore', distancePenalty: 0,
      );
      final hunt = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: [],
        questTypeId: 'hunt', distancePenalty: 0,
      );
      expect(explore - hunt, 10.0); // +5 - (-5)
    });

    test('distance penalty reduces rate', () {
      final near = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 0,
      );
      final far = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 10,
      );
      expect(near - far, 10.0);
    });

    test('returns 95.0 when enemyPower is 0', () {
      final rate = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 10, enemyPower: 0, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 0,
      );
      expect(rate, 95.0);
    });

    test('clamps to 5-95 range', () {
      final low = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 1, enemyPower: 100, traitBonuses: [],
        questTypeId: 'hunt', distancePenalty: 50,
      );
      expect(low, 5.0);

      final high = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 1000, enemyPower: 1, traitBonuses: ['veteran'],
        questTypeId: 'explore', distancePenalty: 0,
      );
      expect(high, 95.0);
    });

    test('is deterministic (no random variance)', () {
      final rate1 = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 15, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 3,
      );
      final rate2 = QuestCalculator.calculateSuccessRatePreview(
        partyPower: 15, enemyPower: 10, traitBonuses: [],
        questTypeId: 'loot', distancePenalty: 3,
      );
      expect(rate1, rate2);
    });
  });
}
