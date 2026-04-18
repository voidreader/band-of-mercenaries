import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/faction_tag_resolver.dart';

void main() {
  group('FactionTagResolver.resolve()', () {
    test('단서 없음 → null 반환', () {
      final result = FactionTagResolver.resolve(
        regionId: 1,
        joinedFactionIds: [],
        clueLevelsInRegion: {},
        hostileFactionIds: [],
        proximityTier: 3,
        random: Random(42),
      );
      expect(result, isNull);
    });

    test('가입 세력이 단서 보유 → 해당 세력 ID 항상 반환', () {
      // 여러 번 호출해도 항상 반환
      for (int seed = 0; seed < 10; seed++) {
        final result = FactionTagResolver.resolve(
          regionId: 1,
          joinedFactionIds: ['faction_a'],
          clueLevelsInRegion: {'faction_a': 2},
          hostileFactionIds: [],
          proximityTier: 3,
          random: Random(seed),
        );
        expect(result, 'faction_a');
      }
    });

    test('비가입 세력 단서 + proximityTier=3 → 확률 약 10%', () {
      // tagProbFar = 0.10
      const trials = 2000;
      int hitCount = 0;
      final random = Random(42);
      for (int i = 0; i < trials; i++) {
        final result = FactionTagResolver.resolve(
          regionId: 1,
          joinedFactionIds: [],
          clueLevelsInRegion: {'faction_a': 2},
          hostileFactionIds: [],
          proximityTier: 3,
          random: random,
        );
        if (result == 'faction_a') hitCount++;
      }
      final ratio = hitCount / trials;
      // 10% ± 5% 허용
      expect(ratio, greaterThan(0.05));
      expect(ratio, lessThan(0.15));
    });

    test('적대 세력은 후보에서 제외 → null 반환', () {
      final result = FactionTagResolver.resolve(
        regionId: 1,
        joinedFactionIds: [],
        clueLevelsInRegion: {'faction_a': 2},
        hostileFactionIds: ['faction_a'],
        proximityTier: 3,
        random: Random(42),
      );
      expect(result, isNull);
    });

    test('가입 세력 여러 개 중 단서 보유자만 반환', () {
      // faction_a는 단서 없음, faction_b만 단서 보유
      for (int seed = 0; seed < 10; seed++) {
        final result = FactionTagResolver.resolve(
          regionId: 1,
          joinedFactionIds: ['faction_a', 'faction_b'],
          clueLevelsInRegion: {'faction_b': 1},
          hostileFactionIds: [],
          proximityTier: 2,
          random: Random(seed),
        );
        expect(result, 'faction_b');
      }
    });

    test('가입 세력 + 적대 세력이 겹치면 적대 세력 제외 후 나머지 반환', () {
      // faction_a 단서 있고 가입했지만 적대 → 제외, faction_b만 반환
      for (int seed = 0; seed < 10; seed++) {
        final result = FactionTagResolver.resolve(
          regionId: 1,
          joinedFactionIds: ['faction_a', 'faction_b'],
          clueLevelsInRegion: {'faction_a': 2, 'faction_b': 1},
          hostileFactionIds: ['faction_a'],
          proximityTier: 1,
          random: Random(seed),
        );
        expect(result, 'faction_b');
      }
    });
  });

  group('FactionTagResolver.tagReputationGain()', () {
    test('proximityTier 1 → +2', () {
      expect(FactionTagResolver.tagReputationGain(1), 2);
    });

    test('proximityTier 2 → +2', () {
      expect(FactionTagResolver.tagReputationGain(2), 2);
    });

    test('proximityTier 3 → +1', () {
      expect(FactionTagResolver.tagReputationGain(3), 1);
    });

    test('proximityTier 4 → +1', () {
      expect(FactionTagResolver.tagReputationGain(4), 1);
    });
  });
}
