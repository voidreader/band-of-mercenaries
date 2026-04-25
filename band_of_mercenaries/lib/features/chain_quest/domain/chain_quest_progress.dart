import 'package:hive/hive.dart';

part 'chain_quest_progress.g.dart';

@HiveType(typeId: 14)
enum ChainQuestStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  dormant,
}

@HiveType(typeId: 13)
class ChainQuestProgress extends HiveObject {
  @HiveField(0)
  String chainId;

  @HiveField(1)
  int currentStep;

  @HiveField(2)
  ChainQuestStatus status;

  @HiveField(3)
  DateTime startedAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  String? protagonistMercId;

  @HiveField(6)
  DateTime? currentStepAvailableAt;

  @HiveField(7)
  int stepFailureCount;

  @HiveField(8)
  DateTime? lastActivityAt;

  ChainQuestProgress({
    required this.chainId,
    this.currentStep = 1,
    this.status = ChainQuestStatus.active,
    required this.startedAt,
    this.completedAt,
    this.protagonistMercId,
    this.currentStepAvailableAt,
    this.stepFailureCount = 0,
    this.lastActivityAt,
  });
}
