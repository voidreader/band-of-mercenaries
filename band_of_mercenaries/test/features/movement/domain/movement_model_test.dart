import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';

void main() {
  group('UserData', () {
    test('calculateDistance returns correct value for same region', () {
      expect(UserData.calculateDistance(42, 3, 42, 7), 4);
    });

    test('calculateDistance returns correct value for different regions', () {
      expect(UserData.calculateDistance(42, 3, 50, 5), 10);
    });

    test('calculateMoveTime returns 30s per distance unit', () {
      final duration = UserData.calculateMoveTime(5);
      expect(duration.inSeconds, 150);
    });

    test('calculateMoveTime applies speed multiplier', () {
      final duration = UserData.calculateMoveTime(10, speedMultiplier: 10.0);
      expect(duration.inSeconds, 30);
    });
  });
}
