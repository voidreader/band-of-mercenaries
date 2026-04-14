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
