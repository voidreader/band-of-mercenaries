import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';

void main() {
  final ranks = [
    const Rank(grade: 'F', name: '무명', requiredReputation: 0, unlockTier: 1),
    const Rank(grade: 'E', name: '신출내기', requiredReputation: 500, unlockTier: 2),
    const Rank(grade: 'D', name: '일반', requiredReputation: 2000, unlockTier: 3),
    const Rank(grade: 'C', name: '숙련', requiredReputation: 8000, unlockTier: 4),
    const Rank(grade: 'B', name: '정예', requiredReputation: 25000, unlockTier: 5),
    const Rank(grade: 'A', name: '전설', requiredReputation: 80000, unlockTier: 5),
  ];

  group('getCurrentRank', () {
    test('0 rep = F', () => expect(ReputationService.getCurrentRank(0, ranks).grade, 'F'));
    test('500 rep = E', () => expect(ReputationService.getCurrentRank(500, ranks).grade, 'E'));
    test('7999 rep = D', () => expect(ReputationService.getCurrentRank(7999, ranks).grade, 'D'));
    test('80000 rep = A', () => expect(ReputationService.getCurrentRank(80000, ranks).grade, 'A'));
  });

  group('getMaxUnlockedTier', () {
    test('rank F = tier 1', () => expect(ReputationService.getMaxUnlockedTier(0, ranks), 1));
    test('rank D = tier 3', () => expect(ReputationService.getMaxUnlockedTier(2000, ranks), 3));
    test('rank B = tier 5', () => expect(ReputationService.getMaxUnlockedTier(25000, ranks), 5));
  });

  group('isRegionAccessible', () {
    test('tier 1 at rank F', () => expect(ReputationService.isRegionAccessible(1, 0, ranks), true));
    test('tier 3 at rank E', () => expect(ReputationService.isRegionAccessible(3, 500, ranks), false));
    test('tier 3 at rank D', () => expect(ReputationService.isRegionAccessible(3, 2000, ranks), true));
  });

  group('calculateQuestReputation', () {
    test('success D3 = 30', () => expect(ReputationService.calculateQuestReputation(difficulty: 3, isGreatSuccess: false), 30));
    test('great success D3 = 60', () => expect(ReputationService.calculateQuestReputation(difficulty: 3, isGreatSuccess: true), 60));
  });

  group('getNextRank', () {
    test('next from F is E', () => expect(ReputationService.getNextRank(0, ranks)?.grade, 'E'));
    test('null at max rank', () => expect(ReputationService.getNextRank(80000, ranks), null));
  });
}
