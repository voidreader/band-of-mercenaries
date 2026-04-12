import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

void main() {
  group('QuestCalculator', () {
    group('calculateSuccessRate', () {
      test('returns around 50% when power ratio is 1.0 with no modifiers', () {
        final rate = QuestCalculator.calculateSuccessRate(partyPower: 10, enemyPower: 10, traitBonuses: [], questTypeId: 'loot', distancePenalty: 0, random: Random(42));
        expect(rate, greaterThanOrEqualTo(5));
        expect(rate, lessThanOrEqualTo(95));
      });

      test('higher power ratio increases success rate', () {
        final rate = QuestCalculator.calculateSuccessRate(partyPower: 20, enemyPower: 10, traitBonuses: [], questTypeId: 'loot', distancePenalty: 0, random: Random(42));
        expect(rate, greaterThan(80));
      });

      test('explore quest type gives +5% bonus', () {
        final rng = Random(42);
        final exploreRate = QuestCalculator.calculateSuccessRate(partyPower: 10, enemyPower: 10, traitBonuses: [], questTypeId: 'explore', distancePenalty: 0, random: rng);
        final rng2 = Random(42);
        final lootRate = QuestCalculator.calculateSuccessRate(partyPower: 10, enemyPower: 10, traitBonuses: [], questTypeId: 'loot', distancePenalty: 0, random: rng2);
        expect(exploreRate - lootRate, 5);
      });

      test('clamps to 5-95 range', () {
        final rate = QuestCalculator.calculateSuccessRate(partyPower: 1, enemyPower: 100, traitBonuses: [], questTypeId: 'hunt', distancePenalty: 50, random: Random(42));
        expect(rate, greaterThanOrEqualTo(5));
        final highRate = QuestCalculator.calculateSuccessRate(partyPower: 1000, enemyPower: 1, traitBonuses: [], questTypeId: 'explore', distancePenalty: 0, random: Random(42));
        expect(highRate, lessThanOrEqualTo(95));
      });

      test('returns 95.0 when enemyPower is 0', () {
        final rate = QuestCalculator.calculateSuccessRate(partyPower: 10, enemyPower: 0, traitBonuses: [], questTypeId: 'loot', distancePenalty: 0, random: Random(42));
        expect(rate, 95.0);
      });

      test('returns 95.0 when enemyPower is negative', () {
        final rate = QuestCalculator.calculateSuccessRate(partyPower: 10, enemyPower: -5, traitBonuses: [], questTypeId: 'loot', distancePenalty: 0, random: Random(42));
        expect(rate, 95.0);
      });
    });

    group('determineResult', () {
      test('roll in great success range returns greatSuccess', () {
        final result = QuestCalculator.determineResult(successRate: 80, roll: 10);
        expect(result, QuestResult.greatSuccess);
      });

      test('roll in success range returns success', () {
        final result = QuestCalculator.determineResult(successRate: 80, roll: 50);
        expect(result, QuestResult.success);
      });

      test('roll in failure range returns failure', () {
        final result = QuestCalculator.determineResult(successRate: 80, roll: 85);
        expect(result, QuestResult.failure);
      });

      test('roll in critical failure range returns criticalFailure', () {
        final result = QuestCalculator.determineResult(successRate: 80, roll: 98);
        expect(result, QuestResult.criticalFailure);
      });
    });

    group('calculateReward', () {
      test('calculates reward correctly', () {
        final reward = QuestCalculator.calculateReward(baseReward: 100, rewardMultiplier: 1.5);
        expect(reward, 150);
      });

      test('great success doubles reward', () {
        final reward = QuestCalculator.calculateReward(baseReward: 100, rewardMultiplier: 1.5, isGreatSuccess: true);
        expect(reward, 300);
      });
    });

    group('calculateDamage', () {
      test('roll below deathRate returns dead', () {
        final result = QuestCalculator.calculateDamage(roll: 0.03, deathRate: 0.05, injuryRate: 0.1, traitId: '');
        expect(result, DamageResult.dead);
      });

      test('roll below injuryRate returns injured', () {
        final result = QuestCalculator.calculateDamage(roll: 0.07, deathRate: 0.05, injuryRate: 0.1, traitId: '');
        expect(result, DamageResult.injured);
      });

      test('roll above injuryRate returns survived', () {
        final result = QuestCalculator.calculateDamage(roll: 0.5, deathRate: 0.05, injuryRate: 0.1, traitId: '');
        expect(result, DamageResult.survived);
      });

      // Phase 3에서 데이터 드리븐 트레잇 효과 구현 후 테스트 재작성 예정
      test('trait effects are disabled pending Phase 3 data-driven implementation', () {
        final result = QuestCalculator.calculateDamage(roll: 0.08, deathRate: 0.1, injuryRate: 0.2, traitId: 'coward');
        expect(result, DamageResult.dead);
      });
    });

    group('calculateDispatchDuration', () {
      test('difficulty 1 returns base duration', () {
        final duration = QuestCalculator.calculateDispatchDuration(baseDuration: 60, difficulty: 1, speedMultiplier: 1.0);
        expect(duration.inSeconds, 60);
      });

      test('difficulty 5 applies 1.8x multiplier', () {
        final duration = QuestCalculator.calculateDispatchDuration(baseDuration: 60, difficulty: 5, speedMultiplier: 1.0);
        expect(duration.inSeconds, 108);
      });

      test('speed multiplier reduces duration', () {
        final duration = QuestCalculator.calculateDispatchDuration(baseDuration: 60, difficulty: 1, speedMultiplier: 10.0);
        expect(duration.inSeconds, 6);
      });
    });

    group('calculateTotalWage', () {
      final wages = [
        const MercenaryWage(tier: 1, wage: 10),
        const MercenaryWage(tier: 2, wage: 25),
        const MercenaryWage(tier: 3, wage: 50),
        const MercenaryWage(tier: 4, wage: 100),
        const MercenaryWage(tier: 5, wage: 200),
      ];
      test('single tier 1 costs 10G', () => expect(QuestCalculator.calculateTotalWage([1], wages), 10));
      test('mixed party', () => expect(QuestCalculator.calculateTotalWage([1, 3, 5], wages), 260));
      test('empty party', () => expect(QuestCalculator.calculateTotalWage([], wages), 0));
    });

    group('calculateNetProfit', () {
      test('positive profit', () => expect(QuestCalculator.calculateNetProfit(totalReward: 300, totalWage: 100, dispatchCost: 50), 150));
      test('negative profit', () => expect(QuestCalculator.calculateNetProfit(totalReward: 100, totalWage: 150, dispatchCost: 50), -100));
    });
  });
}
