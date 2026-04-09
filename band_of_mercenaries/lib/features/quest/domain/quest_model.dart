import 'package:hive/hive.dart';

part 'quest_model.g.dart';

@HiveType(typeId: 2)
enum QuestStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 3)
enum QuestResult {
  @HiveField(0)
  greatSuccess,
  @HiveField(1)
  success,
  @HiveField(2)
  failure,
  @HiveField(3)
  criticalFailure,
}

@HiveType(typeId: 4)
class ActiveQuest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String questPoolId;

  @HiveField(2)
  final String questTypeId;

  @HiveField(3)
  final int difficulty;

  @HiveField(4)
  final int region;

  @HiveField(5)
  List<String> dispatchedMercIds;

  @HiveField(6)
  DateTime? startTime;

  @HiveField(7)
  DateTime? endTime;

  @HiveField(8)
  QuestStatus status;

  @HiveField(9)
  QuestResult? result;

  @HiveField(10)
  final String questName;

  @HiveField(11)
  DateTime? createdAt;

  ActiveQuest({
    required this.id,
    required this.questPoolId,
    required this.questTypeId,
    required this.difficulty,
    required this.region,
    required this.questName,
    this.dispatchedMercIds = const [],
    this.startTime,
    this.endTime,
    this.status = QuestStatus.pending,
    this.result,
    this.createdAt,
  });
}
