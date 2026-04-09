import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';

void main() {
  group('calculateDispatchCost', () {
    test('difficulty 1, shortest quest has low cost', () {
      final cost = QuestCalculator.calculateDispatchCost(
        baseDuration: 60, difficulty: 1, minCost: 5, maxCost: 30,
      );
      expect(cost, greaterThanOrEqualTo(5));
      expect(cost, lessThanOrEqualTo(30));
    });

    test('difficulty 5, longest quest hits max cost', () {
      final cost = QuestCalculator.calculateDispatchCost(
        baseDuration: 80, difficulty: 5, minCost: 50, maxCost: 200,
      );
      expect(cost, equals(200));
    });

    test('cost is always within min/max range', () {
      for (int diff = 1; diff <= 5; diff++) {
        for (int base in [60, 70, 75, 80]) {
          final cost = QuestCalculator.calculateDispatchCost(
            baseDuration: base, difficulty: diff, minCost: 5, maxCost: 200,
          );
          expect(cost, greaterThanOrEqualTo(5));
          expect(cost, lessThanOrEqualTo(200));
        }
      }
    });
  });
}
