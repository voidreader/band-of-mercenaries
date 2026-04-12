import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';

void main() {
  group('RecruitmentService.canFreeRecruit', () {
    test('returns true when cooldown has passed', () {
      final lastRecruit = DateTime.now().subtract(const Duration(hours: 3));
      expect(RecruitmentService.canFreeRecruit(lastRecruit, 1.0), isTrue);
    });

    test('returns false during cooldown', () {
      final lastRecruit = DateTime.now().subtract(const Duration(minutes: 30));
      expect(RecruitmentService.canFreeRecruit(lastRecruit, 1.0), isFalse);
    });

    test('speed multiplier reduces cooldown', () {
      // At 10x speed, 2h cooldown = 12 min real time
      final lastRecruit = DateTime.now().subtract(const Duration(minutes: 15));
      expect(RecruitmentService.canFreeRecruit(lastRecruit, 10.0), isTrue);
    });

    test('speed multiplier still blocks within reduced cooldown', () {
      final lastRecruit = DateTime.now().subtract(const Duration(minutes: 5));
      expect(RecruitmentService.canFreeRecruit(lastRecruit, 10.0), isFalse);
    });
  });

  group('RecruitmentService.freeRecruitRemaining', () {
    test('returns zero when cooldown has passed', () {
      final lastRecruit = DateTime.now().subtract(const Duration(hours: 3));
      expect(RecruitmentService.freeRecruitRemaining(lastRecruit, 1.0), Duration.zero);
    });

    test('returns positive duration during cooldown', () {
      final lastRecruit = DateTime.now();
      final remaining = RecruitmentService.freeRecruitRemaining(lastRecruit, 1.0);
      expect(remaining.inSeconds, greaterThan(0));
      expect(remaining.inSeconds, lessThanOrEqualTo(GameConstants.freeRecruitCooldown.inSeconds));
    });
  });
}
