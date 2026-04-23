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

  @HiveField(12)
  int? rewardGold;

  @HiveField(13)
  int? totalWage;

  @HiveField(14)
  int? dispatchCost;

  @HiveField(15)
  int? earnedXp;

  @HiveField(16)
  int? earnedReputation;

  // 런타임 부여된 세력 태그 또는 전용 퀘스트 고정 세력
  @HiveField(17)
  String? factionTag;

  // 완료 시 지급될 세력 평판 (생성 시점에 미리 계산)
  @HiveField(18)
  int? reputationReward;

  // 전용 퀘스트 트랙 구분 (null=일반, false=기본, true=고급)
  @HiveField(19)
  bool? isAdvancedTrack;

  // 엘리트 몬스터 퀘스트 ID
  @HiveField(20)
  String? eliteId;

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
    this.rewardGold,
    this.totalWage,
    this.dispatchCost,
    this.earnedXp,
    this.earnedReputation,
    this.factionTag,
    this.reputationReward,
    this.isAdvancedTrack,
    this.eliteId,
  });

  // 전용 퀘스트 여부 (isAdvancedTrack이 설정된 경우)
  bool get isFactionExclusive => isAdvancedTrack != null;

  bool get isElite => eliteId != null;
}
