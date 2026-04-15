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
  }) : facilities = facilities ?? {};

  static int calculateDistance(
      int fromRegion, int fromSector, int toRegion, int toSector) {
    return (fromRegion - toRegion).abs() + (fromSector - toSector).abs();
  }

  static Duration calculateMoveTime(int distance, {double speedMultiplier = 1.0}) {
    final seconds = (distance * 30 / speedMultiplier).round();
    return Duration(seconds: seconds);
  }
}
