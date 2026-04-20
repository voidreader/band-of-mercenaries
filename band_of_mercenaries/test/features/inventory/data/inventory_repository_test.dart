import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';

ItemData makeEquipment(String id) => ItemData(
      id: id,
      name: id,
      category: 'personal_equipment',
      slot: 'weapon',
      tier: 3,
    );

ItemData makeConsumable(String id) => ItemData(
      id: id,
      name: id,
      category: 'consumable',
      slot: 'essence_str',
      tier: 3,
    );

void main() {
  late Directory tempDir;
  late InventoryRepository repo;
  late Box<InventoryItem> box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('inv_repo_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(InventoryItemAdapter());
    }
    box = await Hive.openBox<InventoryItem>(HiveInitializer.inventoryBoxName);
    repo = InventoryRepository();
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(HiveInitializer.inventoryBoxName);
    tempDir.deleteSync(recursive: true);
  });

  group('InventoryRepository CRUD', () {
    test('getAll() 초기에는 빈 리스트', () {
      expect(repo.getAll(), isEmpty);
    });

    test('addItem() 장비는 항상 신규 행 생성', () async {
      final items = [makeEquipment('eq1')];
      await repo.addItem(itemId: 'eq1', items: items);
      await repo.addItem(itemId: 'eq1', items: items);
      expect(repo.getAll().length, 2);
      expect(repo.getAll().every((i) => i.quantity == 1), isTrue);
    });

    test('addItem() 소모품은 기존 행 수량 가산', () async {
      final items = [makeConsumable('es1')];
      await repo.addItem(itemId: 'es1', items: items);
      await repo.addItem(itemId: 'es1', items: items);
      expect(repo.getAll().length, 1);
      expect(repo.getAll().first.quantity, 2);
    });

    test('addItem() 알 수 없는 itemId는 ArgumentError', () async {
      await expectLater(
        () => repo.addItem(itemId: 'unknown', items: <ItemData>[]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('removeItem() 단일 행 삭제', () async {
      final items = [makeEquipment('eq2')];
      final added = await repo.addItem(itemId: 'eq2', items: items);
      await repo.removeItem(added.id);
      expect(repo.getById(added.id), isNull);
    });

    test('decrementQuantity() 수량 차감', () async {
      final items = [makeConsumable('es2')];
      await repo.addItem(itemId: 'es2', items: items);
      await repo.addItem(itemId: 'es2', items: items);
      await repo.addItem(itemId: 'es2', items: items);
      final added = repo.getAll().first;
      expect(added.quantity, 3);
      await repo.decrementQuantity(added.id, delta: 1);
      expect(repo.getById(added.id)!.quantity, 2);
    });

    test('decrementQuantity() quantity<=0 자동 삭제', () async {
      final items = [makeConsumable('es3')];
      final added = await repo.addItem(itemId: 'es3', items: items);
      expect(added.quantity, 1);
      await repo.decrementQuantity(added.id, delta: 1);
      expect(repo.getAll(), isEmpty);
    });

    test('setEquippedTo() 장착/해제', () async {
      final items = [makeEquipment('eq3')];
      final added = await repo.addItem(itemId: 'eq3', items: items);
      await repo.setEquippedTo(added.id, 'merc_1');
      expect(repo.getEquippedBy('merc_1').length, 1);
      await repo.setEquippedTo(added.id, null);
      expect(repo.getUnequipped().length, 1);
      expect(repo.getEquippedBy('merc_1'), isEmpty);
    });
  });
}
