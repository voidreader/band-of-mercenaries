import 'package:hive/hive.dart';

part 'faction_state_model.g.dart';

@HiveType(typeId: 10)
class FactionClueRecord extends HiveObject {
  @HiveField(0)
  late String factionId;

  @HiveField(1)
  late int regionId;

  @HiveField(2)
  late String discoveryId;

  @HiveField(3)
  late DateTime foundAt;

  FactionClueRecord({
    required this.factionId,
    required this.regionId,
    required this.discoveryId,
    required this.foundAt,
  });
}

@HiveType(typeId: 9)
class FactionState extends HiveObject {
  @HiveField(0)
  late String factionId;

  @HiveField(1)
  late List<FactionClueRecord> clueRecords;

  // 신규 필드 (기존 Hive 데이터는 null로 읽히므로 생성자에서 0/false/{} 기본값 처리)
  @HiveField(2)
  late int reputation;

  @HiveField(3)
  late bool joined;

  @HiveField(4)
  DateTime? joinedAt;

  @HiveField(5)
  late Map<String, int> facilityLevels;

  FactionState({
    required this.factionId,
    List<FactionClueRecord>? clueRecords,
    this.reputation = 0,
    this.joined = false,
    this.joinedAt,
    Map<String, int>? facilityLevels,
  })  : clueRecords = clueRecords ?? [],
        facilityLevels = facilityLevels ?? {};

  List<int> get discoveredInRegions =>
      clueRecords.map((r) => r.regionId).toSet().toList();

  int get maxClueLevel {
    final uniqueCount = clueRecords.map((r) => r.discoveryId).toSet().length;
    return uniqueCount.clamp(0, 3);
  }
}
