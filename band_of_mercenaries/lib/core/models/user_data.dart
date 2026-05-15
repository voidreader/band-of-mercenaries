import 'package:hive/hive.dart';

part 'user_data.g.dart';

@HiveType(typeId: 5)
class UserData extends HiveObject {
  @HiveField(0)
  int gold;

  @HiveField(1)
  final int continent;

  @HiveField(2)
  int region;

  @HiveField(3)
  int sector;

  @HiveField(4)
  bool isMoving;

  @HiveField(5)
  int? moveTargetRegion;

  @HiveField(6)
  int? moveTargetSector;

  @HiveField(7)
  DateTime? moveEndTime;

  @HiveField(8)
  DateTime lastFreeRecruit;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  int reputation;

  @HiveField(11)
  Map<String, int> facilities;

  @HiveField(12)
  String? constructionFacilityId;

  @HiveField(13)
  DateTime? constructionStartTime;

  @HiveField(14)
  DateTime? constructionEndTime;

  @HiveField(15)
  String? investigatingMercId;

  @HiveField(16)
  DateTime? investigationEndTime;

  @HiveField(17)
  int? investigationRegionId;

  // 용병단 깃발 슬롯
  @HiveField(18)
  String? bannerItemId;

  // 유물 슬롯 (최대 2개)
  @HiveField(19)
  List<String> artifactItemIds;

  // 완료된 체인 퀘스트 ID 목록
  @HiveField(20)
  List<String> completedChains;

  // 이동 중 선택지 이벤트 ID
  @HiveField(21)
  String? choiceEventId;

  @HiveField(22)
  DateTime? herbalistCooldownEndTime;

  @HiveField(23)
  DateTime? lastSmithyRepairAt;

  /// 용병단 기함 용병 ID (nullable)
  @HiveField(24)
  String? flagshipMercId;

  /// 마지막 파견 주인공 용병 ID (nullable)
  @HiveField(25)
  String? lastDispatchProtagonistMercId;

  UserData({
    required this.gold,
    this.continent = 1,
    required this.region,
    required this.sector,
    this.isMoving = false,
    this.moveTargetRegion,
    this.moveTargetSector,
    this.moveEndTime,
    required this.lastFreeRecruit,
    required this.createdAt,
    this.reputation = 0,
    Map<String, int>? facilities,
    this.constructionFacilityId,
    this.constructionStartTime,
    this.constructionEndTime,
    this.investigatingMercId,
    this.investigationEndTime,
    this.investigationRegionId,
    this.bannerItemId,
    List<String>? artifactItemIds,
    List<String>? completedChains,
    this.choiceEventId,
    this.herbalistCooldownEndTime,
    this.lastSmithyRepairAt,
    this.flagshipMercId,
    this.lastDispatchProtagonistMercId,
  })  : facilities = facilities ?? {},
        artifactItemIds = artifactItemIds ?? <String>[],
        completedChains = completedChains ?? <String>[];

  Set<String> get completedChainSet => completedChains.toSet();

  static int calculateDistance(
      int fromRegion, int fromSector, int toRegion, int toSector) {
    return (fromRegion - toRegion).abs() + (fromSector - toSector).abs();
  }

  static Duration calculateMoveTime(int distance, {double speedMultiplier = 1.0}) {
    final seconds = (distance * 30 / speedMultiplier).round();
    return Duration(seconds: seconds);
  }
}
