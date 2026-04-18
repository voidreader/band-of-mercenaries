import 'package:band_of_mercenaries/core/constants/game_constants.dart';

class IdleRewardService {
  static int calculateReward(
    DateTime lastActiveTime, {
    double idleBonusAmount = 0.0,
    double rateBonus = 0.0,
    double capBonus = 0.0,
  }) {
    final absentMinutes = DateTime.now().difference(lastActiveTime).inMinutes;
    if (absentMinutes < 1) return 0;
    final perMinute = GameConstants.idleRewardPerMinute * (1.0 + rateBonus);
    final maxGold = (GameConstants.maxIdleRewardMinutes * GameConstants.idleRewardPerMinute + idleBonusAmount + capBonus).round();
    final earned = (absentMinutes * perMinute).round();
    return earned.clamp(0, maxGold);
  }
}
