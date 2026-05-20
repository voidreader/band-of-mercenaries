import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/util/stable_seed.dart';

void main() {
  group('stableSeed32', () {
    test('returns same hash for same input', () {
      final input = 'test_seed';
      final hash1 = stableSeed32(input);
      final hash2 = stableSeed32(input);
      expect(hash1, equals(hash2));
    });

    test('returns different hash for different inputs', () {
      final hash1 = stableSeed32('seed1');
      final hash2 = stableSeed32('seed2');
      expect(hash1, isNot(equals(hash2)));
    });

    test('returns 32-bit unsigned integer', () {
      final hash = stableSeed32('any input');
      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThanOrEqualTo(0xFFFFFFFF));
    });

    test('handles empty string', () {
      final hash = stableSeed32('');
      expect(hash, equals(0x811C9DC5)); // offsetBasis
    });

    test('handles special characters', () {
      final hash = stableSeed32('special|chars!@#');
      expect(hash, isNotNull);
      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThanOrEqualTo(0xFFFFFFFF));
    });

    test('handles unicode characters', () {
      final hash = stableSeed32('한글테스트');
      expect(hash, isNotNull);
      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThanOrEqualTo(0xFFFFFFFF));
    });

    test('consistent across multiple calls with timestamp format', () {
      final domainKey = 'order|0|mercenary_123';
      final hashes = [
        stableSeed32(domainKey),
        stableSeed32(domainKey),
        stableSeed32(domainKey),
      ];
      expect(hashes[0], equals(hashes[1]));
      expect(hashes[1], equals(hashes[2]));
    });

    test('produces different seeds for PRNG domain keys', () {
      const seed = 12345;
      final dmgKey = 'dmg|0|pair_1';
      final hitKey = 'hit|0|pair_1';

      final dmgSeed = seed ^ stableSeed32(dmgKey);
      final hitSeed = seed ^ stableSeed32(hitKey);

      expect(dmgSeed, isNot(equals(hitSeed)));
    });

    // M8b 페이즈 4 #5 FR-2 — 표본 5종 + 1000회 반복 결정성 + 충돌 0/5.
    test('FR-2: 5 input samples produce deterministic hashes (1000 repeats)', () {
      const samples = [
        '',
        'a',
        'merc_1|quest_a',
        'dmg|0|123456',
        'death|merc_a',
      ];
      for (final input in samples) {
        final baseline = stableSeed32(input);
        for (var i = 0; i < 1000; i++) {
          expect(
            stableSeed32(input),
            equals(baseline),
            reason: 'input="$input" iter=$i 변동 발견',
          );
        }
      }
    });

    test('FR-2: 5 sample pair collisions are zero', () {
      const samples = [
        '',
        'a',
        'merc_1|quest_a',
        'dmg|0|123456',
        'death|merc_a',
      ];
      final hashes = samples.map(stableSeed32).toList();
      for (var i = 0; i < hashes.length; i++) {
        for (var j = i + 1; j < hashes.length; j++) {
          expect(
            hashes[i],
            isNot(equals(hashes[j])),
            reason: '"${samples[i]}" / "${samples[j]}" 충돌',
          );
        }
      }
    });
  });
}
