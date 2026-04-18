import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

Rank _rank(String grade, int req, {int unlockTier = 1}) {
  return Rank(
    grade: grade,
    name: grade,
    requiredReputation: req,
    unlockTier: unlockTier,
    bonusJson: const {},
  );
}

void main() {
  final ranks = [
    _rank('F', 0),
    _rank('E', 300),
    _rank('D', 1000),
    _rank('C', 2000),
    _rank('B', 3000),
    _rank('A', 5000),
  ];

  group('ReputationService.getRankChain', () {
    test('reputation 0 → F만 포함', () {
      final chain = ReputationService.getRankChain(0, ranks);
      expect(chain.length, 1);
      expect(chain[0].grade, 'F');
    });

    test('reputation 500 → F,E 포함', () {
      final chain = ReputationService.getRankChain(500, ranks);
      expect(chain.map((r) => r.grade).toList(), ['F', 'E']);
    });

    test('reputation 5000 → 전체 포함', () {
      final chain = ReputationService.getRankChain(5000, ranks);
      expect(chain.length, 6);
      expect(chain.last.grade, 'A');
    });

    test('ranks 비어있음 → 빈 리스트', () {
      final chain = ReputationService.getRankChain(1000, const <Rank>[]);
      expect(chain, isEmpty);
    });

    test('정렬 순서 무관 (내부 sort) — 역순 입력 시에도 F~A 순서', () {
      final reversed = ranks.reversed.toList();
      final chain = ReputationService.getRankChain(2000, reversed);
      expect(chain.map((r) => r.grade).toList(), ['F', 'E', 'D', 'C']);
    });

    test('reputation이 경계값과 정확히 일치 → 해당 랭크 포함', () {
      final chain = ReputationService.getRankChain(1000, ranks);
      expect(chain.map((r) => r.grade).toList(), ['F', 'E', 'D']);
    });
  });

  group('ReputationService.getRankLevel', () {
    test('F만 도달 → 0', () {
      expect(ReputationService.getRankLevel(0, ranks), 0);
    });

    test('D까지 도달 → 2', () {
      expect(ReputationService.getRankLevel(1500, ranks), 2);
    });

    test('A까지 도달 → 5', () {
      expect(ReputationService.getRankLevel(9999, ranks), 5);
    });

    test('빈 ranks → -1', () {
      expect(ReputationService.getRankLevel(1000, const <Rank>[]), -1);
    });
  });
}
