import 'package:hive/hive.dart';

part 'activity_log_model.g.dart';

@HiveType(typeId: 6)
enum ActivityLogType {
  @HiveField(0)
  questResult,
  @HiveField(1)
  mercenaryStatus,
  @HiveField(2)
  movementComplete,
  @HiveField(3)
  mercenaryRecruit,
  @HiveField(4)
  mercenaryDismiss,
  @HiveField(5)
  levelUp,
  @HiveField(6)
  traitAcquired,
  @HiveField(7)
  traitEvolved,
  @HiveField(8)
  traitDeleted,
  @HiveField(9)
  facilityUpgrade,
  @HiveField(10)
  investigationSuccess,
  @HiveField(11)
  investigationFailed,
  @HiveField(12)
  discoveryFound,
  @HiveField(13)
  reputationRankUp,
  @HiveField(14)
  reputationRankDown,
  @HiveField(15)
  essenceApplied,
  @HiveField(16)
  essenceLostOnDeath,
  @HiveField(17)
  essenceLostOnRelease,
  @HiveField(18)
  regionTransform,
  @HiveField(19)
  chainProgressed,
  @HiveField(20)
  chainCompleted,
  @HiveField(21)
  travelChoiceCompleted,
  @HiveField(22)
  settlementTrustUp,
  @HiveField(23)
  settlementEventStep,
  @HiveField(24)
  settlementEventCompleted,
  @HiveField(25)
  herbalistHeal,
  @HiveField(26)
  smithyRepairCompleted,
  @HiveField(27)
  craftCompleted,
  @HiveField(28)
  inventoryStackCapped,
  @HiveField(29)
  achievementUnlocked,
  @HiveField(30)
  titleUnlocked,
  @HiveField(31)
  namedQuestTerminated,
  @HiveField(32)
  regionDangerLevelChanged,
  @HiveField(33)
  regionUnlockedFlagToggled,
  @HiveField(34)
  settlementInfrastructureUpgraded,
}

@HiveType(typeId: 7)
class ActivityLog extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final ActivityLogType type;

  ActivityLog({
    required this.timestamp,
    required this.message,
    required this.type,
  });
}
