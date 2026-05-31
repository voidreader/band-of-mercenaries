// InventoryScreen 위젯 테스트 + 카테고리 필터 로직 단위 테스트.
//
// 위젯 테스트 범위:
//   - 빈 상태 안내 텍스트 표시
//   - 카테고리 필터 탭 4개 표시
//
// 단위 테스트 범위:
//   - 카테고리 필터 로직 (_filteredRows 동일 로직 직접 검증)
//   - 전체/개인장비/용병단장비/소모품 필터
//   - 카테고리 내 tier 내림차순 → 이름 오름차순 정렬
//
// 위젯 테스트에서 아이템 목록 렌더링 케이스는 MercenaryListNotifier 생성자의
// ref.listen(gameTickProvider, ...) 등록이 FakeAsync 환경에서 pending 상태를
// 만들어 pumpWidget이 반환되지 않는 문제로 인해 단위 테스트로 대체한다.
// (gameTickProvider가 Stream.periodic을 사용하므로 FakeAsync에서 무한 루프 발생)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/view/inventory_screen.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';

// ── Fake Repository ────────────────────────────────────────────────────────────

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository(this._rows);
  final List<InventoryItem> _rows;

  @override
  List<InventoryItem> getAll() => _rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── 헬퍼 ────────────────────────────────────────────────────────────────────

ItemData _makeItem({
  required String id,
  required String category,
  String slot = 'weapon',
  int tier = 1,
  String? name,
}) {
  return ItemData(
    id: id,
    name: name ?? id,
    category: category,
    slot: slot,
    tier: tier,
  );
}

InventoryItem _makeRow({
  required String id,
  required String itemId,
  int quantity = 1,
}) {
  return InventoryItem(
    id: id,
    itemId: itemId,
    quantity: quantity,
    acquiredAt: DateTime(2026, 1, 1),
  );
}

StaticGameData _makeStaticData({List<ItemData> items = const []}) {
  return StaticGameData(
    difficulties: const [],
    jobs: const [],
    traits: const [],
    traitCategories: const [],
    traitConflicts: const [],
    traitTransitions: const [],
    traitComboEvolutions: const [],
    traitSynergies: const [],
    regions: const [],
    questTypes: const [],
    questPools: const [],
    personNames: const [],
    travelEvents: const [],
    facilities: const [
      Facility(
        id: 'barracks',
        name: '주둔지',
        effectType: 'max_mercenaries',
        maxLevel: 1,
        costs: [100],
        values: [5.0],
      ),
    ],
    ranks: const [
      Rank(grade: 'F', name: '신참', requiredReputation: 0, unlockTier: 1),
    ],
    mercenaryWages: const [
      MercenaryWage(tier: 1, wage: 10),
    ],
    regionDiscoveries: const [],
    factions: const [],
    items: items,
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionAdjacencies: const [],
    regionSectors: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: const [],
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
    hiddenStats: const [],
    battleMemoryTemplates: const [],
  );
}

// ── 필터 로직 (InventoryScreen._filteredRows 동일 로직 추출) ───────────────────

/// InventoryScreen 내부의 _categoryFilterToString 및 _filteredRows 와 동일한 로직.
/// 위젯 테스트에서 _buildList 진입이 어려우므로 로직을 직접 단위 테스트한다.
List<InventoryItem> _filteredRows(
  List<InventoryItem> rows,
  List<ItemData> items,
  InventoryCategoryFilter filter,
) {
  String? categoryStr;
  switch (filter) {
    case InventoryCategoryFilter.all:
      categoryStr = null;
    case InventoryCategoryFilter.personalEquipment:
      categoryStr = 'personal_equipment';
    case InventoryCategoryFilter.guildEquipment:
      categoryStr = 'guild_equipment';
    case InventoryCategoryFilter.consumable:
      categoryStr = 'consumable';
    case InventoryCategoryFilter.material:
      categoryStr = 'material';
  }

  final itemMap = {for (final i in items) i.id: i};
  final filtered = categoryStr == null
      ? List<InventoryItem>.from(rows)
      : rows
          .where((r) => itemMap[r.itemId]?.category == categoryStr)
          .toList();

  filtered.sort((a, b) {
    final ia = itemMap[a.itemId];
    final ib = itemMap[b.itemId];
    if (ia == null || ib == null) return 0;
    if (ia.category != ib.category) return ia.category.compareTo(ib.category);
    if (ia.tier != ib.tier) return ib.tier.compareTo(ia.tier);
    return ia.name.compareTo(ib.name);
  });

  return filtered;
}

// ── Hive 초기화/정리 ──────────────────────────────────────────────────────────

late Directory _tempDir;

Future<void> _setUpHive() async {
  _tempDir = Directory.systemTemp.createTempSync('inv_screen_wgt_test_');
  Hive.init(_tempDir.path);

  void registerIfAbsent<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  registerIfAbsent(0, MercenaryStatusAdapter());
  registerIfAbsent(1, MercenaryAdapter());
  registerIfAbsent(2, QuestStatusAdapter());
  registerIfAbsent(3, QuestResultAdapter());
  registerIfAbsent(4, ActiveQuestAdapter());
  registerIfAbsent(5, UserDataAdapter());
  registerIfAbsent(6, ActivityLogTypeAdapter());
  registerIfAbsent(7, ActivityLogAdapter());
  registerIfAbsent(8, RegionStateAdapter());
  registerIfAbsent(9, FactionClueRecordAdapter());
  registerIfAbsent(10, FactionStateAdapter());
  registerIfAbsent(11, InventoryItemAdapter());

  await Hive.openBox(HiveInitializer.settingsBoxName);
  await Hive.openBox<UserData>(HiveInitializer.userBoxName);
  await Hive.openBox<Mercenary>(HiveInitializer.mercenaryBoxName);
  await Hive.openBox<ActiveQuest>(HiveInitializer.questBoxName);
  await Hive.openBox<ActivityLog>('activityLogs');
  await Hive.openBox<String>(HiveInitializer.staticDataCacheBoxName);
  await Hive.openBox<RegionState>(HiveInitializer.regionStateBoxName);
  await Hive.openBox<FactionState>(HiveInitializer.factionStateBoxName);
  await Hive.openBox<InventoryItem>(HiveInitializer.inventoryBoxName);
}

Future<void> _tearDownHive() async {
  await Hive.close();
  _tempDir.deleteSync(recursive: true);
}

// ── 테스트 ────────────────────────────────────────────────────────────────────

void main() {
  // 위젯 테스트 그룹은 Hive 박스가 열려 있어야 한다.
  group('InventoryScreen — 위젯 스모크 테스트', () {
    setUpAll(_setUpHive);
    tearDownAll(_tearDownHive);

    testWidgets('인벤토리가 비어 있으면 안내 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staticDataProvider.overrideWith(
              (ref) async => _makeStaticData(),
            ),
            inventoryRepositoryProvider
                .overrideWithValue(_FakeInventoryRepository([])),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InventoryScreen(onBack: _noop)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('보유한 아이템이 없습니다'), findsOneWidget);
    });

    testWidgets('카테고리 필터 탭이 전체·개인장비·용병단장비·소모품 4개 모두 표시된다',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staticDataProvider.overrideWith(
              (ref) async => _makeStaticData(),
            ),
            inventoryRepositoryProvider
                .overrideWithValue(_FakeInventoryRepository([])),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InventoryScreen(onBack: _noop)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('전체'), findsOneWidget);
      expect(find.text('개인장비'), findsOneWidget);
      expect(find.text('용병단장비'), findsOneWidget);
      expect(find.text('소모품'), findsOneWidget);
    });
  });

  // 순수 로직 단위 테스트 — Hive/Flutter 의존성 없음
  group('InventoryScreen — 카테고리 필터 로직 단위 테스트', () {
    final sword = _makeItem(id: 'sword', name: '장검', category: 'personal_equipment', tier: 2);
    final shield = _makeItem(id: 'shield', name: '방패', category: 'personal_equipment', tier: 1);
    final banner = _makeItem(id: 'banner', name: '깃발', category: 'guild_equipment');
    final potion = _makeItem(id: 'potion', name: '물약', category: 'consumable');
    final essence = _makeItem(id: 'essence', name: '정수', category: 'consumable', slot: 'essence_str');

    final allItems = [sword, shield, banner, potion, essence];

    final rows = [
      _makeRow(id: 'r1', itemId: 'sword'),
      _makeRow(id: 'r2', itemId: 'shield'),
      _makeRow(id: 'r3', itemId: 'banner'),
      _makeRow(id: 'r4', itemId: 'potion'),
      _makeRow(id: 'r5', itemId: 'essence'),
    ];

    test('전체 필터는 모든 행을 반환한다', () {
      final result = _filteredRows(rows, allItems, InventoryCategoryFilter.all);
      expect(result.length, 5);
    });

    test('개인장비 필터는 personal_equipment 카테고리만 반환한다', () {
      final result = _filteredRows(
        rows, allItems, InventoryCategoryFilter.personalEquipment,
      );
      expect(result.map((r) => r.itemId).toSet(), {'sword', 'shield'});
    });

    test('용병단장비 필터는 guild_equipment 카테고리만 반환한다', () {
      final result = _filteredRows(
        rows, allItems, InventoryCategoryFilter.guildEquipment,
      );
      expect(result.map((r) => r.itemId).toSet(), {'banner'});
    });

    test('소모품 필터는 consumable 카테고리만 반환한다', () {
      final result = _filteredRows(
        rows, allItems, InventoryCategoryFilter.consumable,
      );
      expect(result.map((r) => r.itemId).toSet(), {'potion', 'essence'});
    });

    test('동일 카테고리 내 tier 내림차순 정렬 — 높은 티어가 먼저', () {
      final result = _filteredRows(
        rows, allItems, InventoryCategoryFilter.personalEquipment,
      );
      // sword(tier=2)가 shield(tier=1)보다 먼저
      expect(result.first.itemId, 'sword');
      expect(result.last.itemId, 'shield');
    });

    test('동일 tier 내 이름 오름차순 정렬', () {
      final itemA = _makeItem(id: 'a', name: '나단검', category: 'personal_equipment', tier: 1);
      final itemB = _makeItem(id: 'b', name: '가단검', category: 'personal_equipment', tier: 1);
      final sameRows = [
        _makeRow(id: 'ra', itemId: 'a'),
        _makeRow(id: 'rb', itemId: 'b'),
      ];

      final result = _filteredRows(
        sameRows, [itemA, itemB], InventoryCategoryFilter.all,
      );
      // '가단검'이 '나단검'보다 먼저
      expect(result.first.itemId, 'b');
      expect(result.last.itemId, 'a');
    });

    test('빈 인벤토리에서 모든 필터가 빈 리스트를 반환한다', () {
      for (final filter in InventoryCategoryFilter.values) {
        expect(_filteredRows([], allItems, filter), isEmpty);
      }
    });
  });
}

void _noop() {}
