import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/mercenary/view/equipment_equip_sheet.dart';

/// 장착 상태 새로고침용 카운터 Provider.
/// [EquipmentEquipSheet]에서 장착/해제 후 increment하여 [EquipmentSlotGrid]가 재빌드된다.
final equipmentRefreshProvider = StateProvider<int>((ref) => 0);

/// 용병 개인 장비 6슬롯 그리드 위젯.
///
/// - weapon / armor / helmet / boots / accessory 1 / accessory 2 순으로 2×3 배치.
/// - 각 슬롯 탭 시 [EquipmentEquipSheet] 모달 시트를 열어 아이템 선택·해제가 가능하다.
class EquipmentSlotGrid extends ConsumerWidget {
  final String mercenaryId;

  const EquipmentSlotGrid({super.key, required this.mercenaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 새로고침 트리거 구독 (값은 사용하지 않고 리빌드만 유도).
    ref.watch(equipmentRefreshProvider);

    final staticDataAsync = ref.watch(staticDataProvider);
    final staticData = staticDataAsync.valueOrNull;
    if (staticData == null) return const SizedBox.shrink();

    final inventoryRepo = ref.watch(inventoryRepositoryProvider);
    final equipped = inventoryRepo.getEquippedBy(mercenaryId);

    // itemId → ItemData 조회 맵 구성.
    final itemMap = {for (final item in staticData.items) item.id: item};

    // slot → 장착 아이템 분류.
    InventoryItem? weaponItem;
    InventoryItem? armorItem;
    InventoryItem? helmetItem;
    InventoryItem? bootsItem;
    final accessoryItems = <InventoryItem>[];

    for (final inv in equipped) {
      final itemData = itemMap[inv.itemId];
      if (itemData == null) continue;
      switch (itemData.slot) {
        case 'weapon':
          weaponItem = inv;
        case 'armor':
          armorItem = inv;
        case 'helmet':
          helmetItem = inv;
        case 'boots':
          bootsItem = inv;
        case 'accessory':
          accessoryItems.add(inv);
      }
    }

    // accessory는 id 오름차순으로 정렬하여 1번, 2번 슬롯에 배정.
    accessoryItems.sort((a, b) => a.id.compareTo(b.id));
    final accessory1 = accessoryItems.isNotEmpty ? accessoryItems[0] : null;
    final accessory2 = accessoryItems.length > 1 ? accessoryItems[1] : null;

    // 6개 슬롯 정의.
    final slots = [
      _SlotDef(
        label: '무기',
        slot: 'weapon',
        accessoryIndex: null,
        item: weaponItem,
        itemData: weaponItem != null ? itemMap[weaponItem.itemId] : null,
      ),
      _SlotDef(
        label: '갑옷',
        slot: 'armor',
        accessoryIndex: null,
        item: armorItem,
        itemData: armorItem != null ? itemMap[armorItem.itemId] : null,
      ),
      _SlotDef(
        label: '투구',
        slot: 'helmet',
        accessoryIndex: null,
        item: helmetItem,
        itemData: helmetItem != null ? itemMap[helmetItem.itemId] : null,
      ),
      _SlotDef(
        label: '부츠',
        slot: 'boots',
        accessoryIndex: null,
        item: bootsItem,
        itemData: bootsItem != null ? itemMap[bootsItem.itemId] : null,
      ),
      _SlotDef(
        label: '장신구 1',
        slot: 'accessory',
        accessoryIndex: 0,
        item: accessory1,
        itemData: accessory1 != null ? itemMap[accessory1.itemId] : null,
      ),
      _SlotDef(
        label: '장신구 2',
        slot: 'accessory',
        accessoryIndex: 1,
        item: accessory2,
        itemData: accessory2 != null ? itemMap[accessory2.itemId] : null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '장착 장비',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: slots.map((slotDef) {
            return FractionallySizedBox(
              widthFactor: 0.5,
              child: _EquipmentSlotCard(
                slotDef: slotDef,
                mercenaryId: mercenaryId,
                equippedAccessoryCount: accessoryItems.length,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 슬롯 정의 데이터 클래스.
class _SlotDef {
  final String label;
  final String slot;
  final int? accessoryIndex;
  final InventoryItem? item;
  final ItemData? itemData;

  const _SlotDef({
    required this.label,
    required this.slot,
    required this.accessoryIndex,
    required this.item,
    required this.itemData,
  });
}

/// 개인 장비 슬롯 카드 위젯.
class _EquipmentSlotCard extends ConsumerWidget {
  final _SlotDef slotDef;
  final String mercenaryId;
  final int equippedAccessoryCount;

  const _EquipmentSlotCard({
    required this.slotDef,
    required this.mercenaryId,
    required this.equippedAccessoryCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItem = slotDef.itemData != null;
    final tier = slotDef.itemData?.tier ?? 1;
    final tierColor = hasItem ? AppTheme.tierColor(tier) : AppTheme.textHint;
    final tierBgColor = hasItem ? AppTheme.tierBgColor(tier) : Colors.transparent;
    final borderColor = hasItem
        ? tierColor.withValues(alpha: 0.3)
        : AppTheme.textHint.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () => _openEquipSheet(context, ref),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(slotDef.item?.id ?? '${slotDef.slot}_empty'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: tierBgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slotDef.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasItem ? slotDef.itemData!.name : '비어있음',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasItem ? tierColor : AppTheme.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (hasItem) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'T$tier',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openEquipSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EquipmentEquipSheet(
        mercenaryId: mercenaryId,
        slot: slotDef.slot,
        accessorySlotIndex: slotDef.accessoryIndex,
        currentItem: slotDef.item,
        equippedAccessoryCount: equippedAccessoryCount,
      ),
    );
  }
}
