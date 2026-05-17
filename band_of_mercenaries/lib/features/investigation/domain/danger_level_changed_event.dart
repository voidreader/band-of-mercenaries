import 'danger_level.dart';

class DangerLevelChangedEvent {
  final int regionId;
  final String regionName;
  final DangerLevel from;
  final DangerLevel to;
  final List<String> grantedAchievements;
  final bool isBigTransition;

  const DangerLevelChangedEvent({
    required this.regionId,
    required this.regionName,
    required this.from,
    required this.to,
    this.grantedAchievements = const [],
    required this.isBigTransition,
  });

  static bool computeIsBigTransition(DangerLevel from, DangerLevel to) {
    final fromIdx = from.cacheInt;
    final toIdx = to.cacheInt;

    // 2단계 이상 차이나면 큰 전이
    if ((fromIdx - toIdx).abs() >= 2) return true;

    // stable 진입/이탈은 큰 전이
    final fromStable = from == DangerLevel.stable;
    final toStable = to == DangerLevel.stable;
    if (fromStable != toStable) return true;

    // threat 진입/이탈은 큰 전이
    final fromThreat = from == DangerLevel.threat;
    final toThreat = to == DangerLevel.threat;
    if (fromThreat != toThreat) return true;

    return false;
  }
}
