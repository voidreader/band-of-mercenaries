import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository());

class InventoryRepository {
  static const _uuid = Uuid();

  Box<InventoryItem> get _box =>
      Hive.box<InventoryItem>(HiveInitializer.inventoryBoxName);

  // ── 조회 ────────────────────────────────
  List<InventoryItem> getAll() => _box.values.toList();

  InventoryItem? getById(String id) {
    try {
      return _box.values.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  List<InventoryItem> getByCategory(String category, List<ItemData> items) {
    final idsInCategory = items
        .where((d) => d.category == category)
        .map((d) => d.id)
        .toSet();
    return _box.values.where((i) => idsInCategory.contains(i.itemId)).toList();
  }

  List<InventoryItem> getEquippedBy(String mercenaryId) =>
      _box.values.where((i) => i.equippedTo == mercenaryId).toList();

  List<InventoryItem> getUnequipped() =>
      _box.values.where((i) => i.equippedTo == null).toList();

  // ── 쓰기 ────────────────────────────────
  /// 아이템 추가. 소모품은 동일 itemId 기존 행 수량 가산, 장비는 항상 신규 행 (quantity=1).
  Future<InventoryItem> addItem({
    required String itemId,
    int quantity = 1,
    required List<ItemData> items,
  }) async {
    final itemData = items.firstWhere(
      (d) => d.id == itemId,
      orElse: () => throw ArgumentError('알 수 없는 itemId: $itemId'),
    );

    if (itemData.category == 'consumable') {
      // 소모품: 기존 행 탐색 → 수량 가산
      InventoryItem? existing;
      for (final row in _box.values) {
        if (row.itemId == itemId) {
          existing = row;
          break;
        }
      }
      if (existing != null) {
        existing.quantity += quantity;
        await existing.save();
        return existing;
      }
      final newItem = InventoryItem(
        id: _uuid.v4(),
        itemId: itemId,
        quantity: quantity,
        acquiredAt: DateTime.now(),
      );
      await _box.add(newItem);
      return newItem;
    }

    // 장비: 항상 신규 행, quantity 강제 1
    final newItem = InventoryItem(
      id: _uuid.v4(),
      itemId: itemId,
      quantity: 1,
      acquiredAt: DateTime.now(),
    );
    await _box.add(newItem);
    return newItem;
  }

  Future<void> removeItem(String id) async {
    final item = getById(id);
    if (item == null) return;
    await item.delete();
  }

  Future<void> decrementQuantity(String id, {int delta = 1}) async {
    final item = getById(id);
    if (item == null) return;
    item.quantity -= delta;
    if (item.quantity <= 0) {
      await item.delete();
      return;
    }
    await item.save();
  }

  Future<void> setEquippedTo(String id, String? mercenaryId) async {
    final item = getById(id);
    if (item == null) return;
    item.equippedTo = mercenaryId;
    await item.save();
  }
}
