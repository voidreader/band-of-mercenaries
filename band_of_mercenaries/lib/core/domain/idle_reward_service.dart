import 'package:band_of_mercenaries/core/constants/game_constants.dart';

class IdleRewardService {
  static int calculateReward(DateTime lastActiveTime, {double idleBonusAmount = 0.0}) {
    final absentMinutes = DateTime.now().difference(lastActiveTime).inMinutes;
    if (absentMinutes < 1) return 0;
    final maxGold = GameConstants.maxIdleRewardMinutes * GameConstants.idleRewardPerMinute + idleBonusAmount.round();
    final earned = absentMinutes * GameConstants.idleRewardPerMinute;
    return earned.clamp(0, maxGold);
  }
}
