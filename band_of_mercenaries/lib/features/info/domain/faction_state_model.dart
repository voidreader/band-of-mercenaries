import 'package:hive/hive.dart';

import 'faction_shop_daily_entry.dart';

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

  // 신규 필드 (기존 Hive 데이터는 null로 읽히므로 nullable 타입으로 선언)
  @HiveField(2)
  int? reputation;

  @HiveField(3)
  bool? joined;

  @HiveField(4)
  DateTime? joinedAt;

  @HiveField(5)
  Map<String, int>? facilityLevels;

  /// FR-D4: 세력 상점 누적 구매 이력 (itemId → 구매 여부)
  @HiveField(6)
  Map<String, bool>? shopPurchaseHistory;

  /// FR-D4: 세력 상점 daily 재고 카운터 (itemId → FactionShopDailyEntry)
  @HiveField(7)
  Map<String, FactionShopDailyEntry>? shopDailyPurchases;

  /// FR-E5: 이미 지급된 세력 보상 id 목록
  @HiveField(8)
  List<String>? grantedRewardIds;

  /// FR-A6: 해금된 세력 연락처 id 목록
  @HiveField(9)
  List<String>? contactUnlockedIds;

  FactionState({
    required this.factionId,
    List<FactionClueRecord>? clueRecords,
    int? reputation,
    bool? joined,
    this.joinedAt,
    Map<String, int>? facilityLevels,
    this.shopPurchaseHistory,
    this.shopDailyPurchases,
    this.grantedRewardIds,
    this.contactUnlockedIds,
  })  : clueRecords = clueRecords ?? [],
        reputation = reputation ?? 0,
        joined = joined ?? false,
        facilityLevels = facilityLevels ?? {};

  bool get isJoined => joined ?? false;
  int get currentReputation => reputation ?? 0;

  List<int> get discoveredInRegions =>
      clueRecords.map((r) => r.regionId).toSet().toList();

  int get maxClueLevel {
    final uniqueCount = clueRecords.map((r) => r.discoveryId).toSet().length;
    return uniqueCount.clamp(0, 3);
  }

  Map<String, bool> get effectiveShopPurchaseHistory =>
      shopPurchaseHistory ?? <String, bool>{};

  Map<String, FactionShopDailyEntry> get effectiveShopDailyPurchases =>
      shopDailyPurchases ?? <String, FactionShopDailyEntry>{};

  List<String> get effectiveGrantedRewardIds =>
      grantedRewardIds ?? const <String>[];

  List<String> get effectiveContactUnlockedIds =>
      contactUnlockedIds ?? const <String>[];
}
