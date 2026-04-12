import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

void main() {
  group('recalculateEndTime', () {
    test('returns same endTime if already completed', () {
      final pastEnd = DateTime.now().subtract(const Duration(seconds: 10));
      final start = DateTime.now().subtract(const Duration(minutes: 5));
      final result = recalculateEndTime(pastEnd, start, 1.0, 2.0);
      expect(result, pastEnd);
    });

    test('returns null if endTime is null', () {
      final result = recalculateEndTime(null, DateTime.now(), 1.0, 2.0);
      expect(result, isNull);
    });

    test('returns endTime if startTime is null', () {
      final end = DateTime.now().add(const Duration(minutes: 5));
      final result = recalculateEndTime(end, null, 1.0, 2.0);
      expect(result, end);
    });

    test('doubling speed halves remaining time', () {
      final now = DateTime.now();
      final endTime = now.add(const Duration(seconds: 100));
      final startTime = now.subtract(const Duration(seconds: 50));

      final result = recalculateEndTime(endTime, startTime, 1.0, 2.0);

      // Remaining was 100s at 1x speed → base 100s → at 2x speed = 50s
      final remainingMs = result!.difference(now).inMilliseconds;
      expect(remainingMs, closeTo(50000, 100));
    });

    test('halving speed doubles remaining time', () {
      final now = DateTime.now();
      final endTime = now.add(const Duration(seconds: 100));
      final startTime = now.subtract(const Duration(seconds: 50));

      final result = recalculateEndTime(endTime, startTime, 2.0, 1.0);

      // Remaining was 100s at 2x speed → base 200s → at 1x speed = 200s
      final remainingMs = result!.difference(now).inMilliseconds;
      expect(remainingMs, closeTo(200000, 100));
    });
  });
}
