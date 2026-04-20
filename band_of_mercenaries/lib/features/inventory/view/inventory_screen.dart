import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/view/inventory_item_card.dart';
import 'package:band_of_mercenaries/features/inventory/view/item_detail_sheet.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';

enum InventoryCategoryFilter { all, personalEquipment, guildEquipment, consumable }

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  InventoryCategoryFilter _categoryFilter = InventoryCategoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final staticData = ref.watch(staticDataProvider);
    return staticData.when(
      data: (data) => _buildContent(data.items),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }

  Widget _buildContent(List<ItemData> allItems) {
    final repo = ref.watch(inventoryRepositoryProvider);
    final allRows = repo.getAll();
    final filtered = _filteredRows(allRows, allItems);

    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, color: AppTheme.border),
        _buildCategoryFilter(allRows, allItems),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : _buildList(filtered, allItems),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: widget.onBack,
            color: AppTheme.textPrimary,
          ),
          const Text(
            '인벤토리',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<InventoryItem> allRows, List<ItemData> items) {
    int countForFilter(InventoryCategoryFilter f) {
      if (f == InventoryCategoryFilter.all) return allRows.length;
      final categoryStr = _categoryFilterToString(f);
      final itemMap = {for (final i in items) i.id: i};
      return allRows
          .where((r) => itemMap[r.itemId]?.category == categoryStr)
          .length;
    }

    Widget filterTab(InventoryCategoryFilter f, String label) {
      final selected = _categoryFilter == f;
      final count = countForFilter(f);
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _categoryFilter = f),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.surface,
      child: Row(
        children: [
          filterTab(InventoryCategoryFilter.all, '전체'),
          filterTab(InventoryCategoryFilter.personalEquipment, '개인장비'),
          filterTab(InventoryCategoryFilter.guildEquipment, '용병단장비'),
          filterTab(InventoryCategoryFilter.consumable, '소모품'),
        ],
      ),
    );
  }

  String? _categoryFilterToString(InventoryCategoryFilter f) {
    switch (f) {
      case InventoryCategoryFilter.all:
        return null;
      case InventoryCategoryFilter.personalEquipment:
        return 'personal_equipment';
      case InventoryCategoryFilter.guildEquipment:
        return 'guild_equipment';
      case InventoryCategoryFilter.consumable:
        return 'consumable';
    }
  }

  List<InventoryItem> _filteredRows(
      List<InventoryItem> rows, List<ItemData> items) {
    final categoryStr = _categoryFilterToString(_categoryFilter);
    final itemMap = {for (final i in items) i.id: i};
    final filtered = categoryStr == null
        ? List<InventoryItem>.from(rows)
        : rows
            .where((r) => itemMap[r.itemId]?.category == categoryStr)
            .toList();
    // 정렬: 카테고리 → tier 내림차순 → 이름 오름차순
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '보유한 아이템이 없습니다',
        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildList(List<InventoryItem> rows, List<ItemData> items) {
    final itemMap = {for (final i in items) i.id: i};
    final mercs = ref.watch(mercenaryListProvider);
    final mercMap = {for (final m in mercs) m.id: m};
    final userData = ref.watch(userDataProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final row = rows[i];
        final itemData = itemMap[row.itemId];
        if (itemData == null) {
          return const SizedBox.shrink();
        }
        String? mercenaryName;
        if (row.equippedTo != null) {
          mercenaryName = mercMap[row.equippedTo]?.name;
        }
        String? guildSlotLabel;
        if (itemData.category == 'guild_equipment' && userData != null) {
          if (userData.bannerItemId == itemData.id) {
            guildSlotLabel = '장착 중 (깃발)';
          } else {
            final artifactIndex =
                userData.artifactItemIds.indexOf(itemData.id);
            if (artifactIndex >= 0) {
              guildSlotLabel = '장착 중 (유물 ${artifactIndex + 1})';
            }
          }
        }
        return InventoryItemCard(
          inventoryRow: row,
          itemData: itemData,
          mercenaryName: mercenaryName,
          guildSlotLabel: guildSlotLabel,
          onTap: () => showItemDetailSheet(
            context: context,
            ref: ref,
            inventoryRow: row,
            itemData: itemData,
          ),
        );
      },
    );
  }
}
