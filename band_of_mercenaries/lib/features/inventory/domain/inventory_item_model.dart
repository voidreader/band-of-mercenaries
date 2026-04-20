import 'package:hive/hive.dart';

part 'inventory_item_model.g.dart';

/// 인벤토리 아이템 영속 모델 — 획득한 아이템의 수량, 장착 상태, 획득 시각을 Hive에 저장한다.
@HiveType(typeId: 11)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemId;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  String? equippedTo;

  @HiveField(4)
  final DateTime acquiredAt;

  InventoryItem({
    required this.id,
    required this.itemId,
    this.quantity = 1,
    this.equippedTo,
    required this.acquiredAt,
  });
}
