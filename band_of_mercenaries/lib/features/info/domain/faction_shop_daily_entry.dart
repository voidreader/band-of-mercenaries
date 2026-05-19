import 'package:hive/hive.dart';

part 'faction_shop_daily_entry.g.dart';

/// M8a 세력 상점 daily 재고 카운터 + restockAt
@HiveType(typeId: 20)
class FactionShopDailyEntry extends HiveObject {
  @HiveField(0)
  late int count;

  @HiveField(1)
  late DateTime? restockAt;

  FactionShopDailyEntry({
    required this.count,
    this.restockAt,
  });
}
