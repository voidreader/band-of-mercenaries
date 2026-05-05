import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
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
  /// 아이템 추가. 스택 가능 카테고리(소모품·재료)는 동일 itemId 기존 행 수량 가산, 장비는 항상 신규 행 (quantity=1).
  Future<InventoryItem> addItem({
    required String itemId,
    int quantity = 1,
    required List<ItemData> items,
  }) async {
    final itemData = items.firstWhere(
      (d) => d.id == itemId,
      orElse: () => throw ArgumentError('알 수 없는 itemId: $itemId'),
    );

    final stackMax = GameConstants.stackMaxByCategory[itemData.category] ?? 1;

    if (stackMax > 1) {
      // 스택 가능: 기존 행 탐색 → 수량 가산 (상한 클램프)
      InventoryItem? existing;
      for (final row in _box.values) {
        if (row.itemId == itemId) {
          existing = row;
          break;
        }
      }
      if (existing != null) {
        existing.quantity = (existing.quantity + quantity).clamp(0, stackMax);
        await existing.save();
        return existing;
      }
      final newItem = InventoryItem(
        id: _uuid.v4(),
        itemId: itemId,
        quantity: quantity.clamp(0, stackMax),
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

  /// itemId 기준 합산 보유 수량 동기 조회 (재료·소모품 수량 확인용).
  int getQuantityForItemId(String itemId) =>
      _box.values.where((r) => r.itemId == itemId).fold<int>(0, (sum, r) => sum + r.quantity);

  /// itemId 기준 재료를 quantity만큼 차감 — 보유 부족 시 StateError throw.
  Future<void> consumeMaterial(String itemId, int quantity) async {
    final rows = _box.values.where((r) => r.itemId == itemId).toList();
    final total = rows.fold<int>(0, (sum, r) => sum + r.quantity);
    if (total < quantity) throw StateError('재료 부족: $itemId');

    int remaining = quantity;
    for (final row in rows) {
      if (remaining == 0) break;
      final delta = remaining < row.quantity ? remaining : row.quantity;
      row.quantity -= delta;
      remaining -= delta;
      if (row.quantity == 0) {
        await row.delete();
      } else {
        await row.save();
      }
    }
  }
}
