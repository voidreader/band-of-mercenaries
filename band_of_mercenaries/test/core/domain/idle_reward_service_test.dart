import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/idle_reward_service.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';

void main() {
  group('IdleRewardService.calculateReward', () {
    test('returns 0 for less than 1 minute', () {
      final lastActive = DateTime.now().subtract(const Duration(seconds: 30));
      expect(IdleRewardService.calculateReward(lastActive), 0);
    });

    test('returns minutes * rate for normal absence', () {
      final lastActive = DateTime.now().subtract(const Duration(minutes: 60));
      final reward = IdleRewardService.calculateReward(lastActive);
      expect(reward, 60 * GameConstants.idleRewardPerMinute);
    });

    test('caps at maxIdleRewardMinutes', () {
      final lastActive = DateTime.now().subtract(const Duration(hours: 24));
      final reward = IdleRewardService.calculateReward(lastActive);
      expect(reward, GameConstants.maxIdleRewardMinutes * GameConstants.idleRewardPerMinute);
    });

    test('returns 0 for future time', () {
      final lastActive = DateTime.now().add(const Duration(minutes: 5));
      expect(IdleRewardService.calculateReward(lastActive), 0);
    });
  });
}
