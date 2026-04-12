import 'package:band_of_mercenaries/core/constants/game_constants.dart';

class IdleRewardService {
  static int calculateReward(DateTime lastActiveTime) {
    final absentMinutes = DateTime.now().difference(lastActiveTime).inMinutes;
    if (absentMinutes < 1) return 0;
    return absentMinutes.clamp(0, GameConstants.maxIdleRewardMinutes) * GameConstants.idleRewardPerMinute;
  }
}
