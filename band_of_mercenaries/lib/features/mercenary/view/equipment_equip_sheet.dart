import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/item_effect_service.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/mercenary/view/equipment_slot_grid.dart';

/// 개인 장비 장착 시트.
///
/// 선택된 [slot]에 장착 가능한 미장착 아이템 목록을 표시하고,
/// 아이템 탭 시 [inventoryRepositoryProvider]를 통해 장착/해제를 처리한다.
class EquipmentEquipSheet extends ConsumerWidget {
  final String mercenaryId;

  /// 슬롯 식별자: `'weapon'` | `'armor'` | `'helmet'` | `'boots'` | `'accessory'`
  final String slot;

  /// accessory 슬롯일 때 0 또는 1. 비-accessory 슬롯은 null.
  final int? accessorySlotIndex;

  /// 현재 해당 슬롯(또는 accessory 슬롯 인덱스)에 장착된 아이템. 없으면 null.
  final InventoryItem? currentItem;

  /// 이 용병에게 현재 장착된 accessory 총 개수 (0~2).
  final int equippedAccessoryCount;

  const EquipmentEquipSheet({
    super.key,
    required this.mercenaryId,
    required this.slot,
    this.accessorySlotIndex,
    this.currentItem,
    this.equippedAccessoryCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);

    return staticDataAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '데이터 로드 실패: $err',
            style: const TextStyle(color: AppTheme.textHint),
          ),
        ),
      ),
      data: (staticData) {
        final inventoryRepo = ref.watch(inventoryRepositoryProvider);
        final allInventory = inventoryRepo.getAll();

        // itemId → ItemData 조회 맵.
        final itemMap = {for (final item in staticData.items) item.id: item};

        // 해당 slot의 personal_equipment 중 미장착 아이템 필터.
        // Q-7 결정: 다른 용병이 장착 중인 아이템은 숨김.
        final availableItems = allInventory.where((inv) {
          if (inv.equippedTo != null) return false;
          final itemData = itemMap[inv.itemId];
          if (itemData == null) return false;
          if (itemData.category != 'personal_equipment') return false;
          return itemData.slot == slot;
        }).toList();

        final slotLabel = _slotKoreanLabel(slot, accessorySlotIndex);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // 드래그 핸들.
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 헤더.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$slotLabel 장착',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          color: AppTheme.textHint,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 아이템 목록.
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // 현재 장착 아이템 표시 (있을 때만).
                        if (currentItem != null) ...[
                          _buildSectionLabel('현재 장착'),
                          _buildItemTile(
                            context: context,
                            ref: ref,
                            inv: currentItem!,
                            itemData: itemMap[currentItem!.itemId],
                            isCurrent: true,
                          ),
                          const SizedBox(height: 8),
                        ],
                        // 미장착 목록.
                        _buildSectionLabel('보유 아이템 (${availableItems.length}개)'),
                        if (availableItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              '장착 가능한 $slotLabel 아이템이 없습니다.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHint,
                              ),
                            ),
                          )
                        else
                          ...availableItems.map(
                            (inv) => _buildItemTile(
                              context: context,
                              ref: ref,
                              inv: inv,
                              itemData: itemMap[inv.itemId],
                              isCurrent: false,
                            ),
                          ),
                        // 해제 버튼 (현재 장착 아이템이 있을 때만).
                        if (currentItem != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.remove_circle_outline, size: 16),
                              label: Text('$slotLabel 해제'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textTertiary,
                                side: const BorderSide(color: AppTheme.border),
                              ),
                              onPressed: () => _unequip(context, ref),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 섹션 라벨 위젯.
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textHint,
        ),
      ),
    );
  }

  /// 아이템 타일 위젯.
  Widget _buildItemTile({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem inv,
    required ItemData? itemData,
    required bool isCurrent,
  }) {
    if (itemData == null) return const SizedBox.shrink();

    final tier = itemData.tier;
    final tierColor = AppTheme.tierColor(tier);
    final tierBgColor = AppTheme.tierBgColor(tier);

    // 효과 요약 텍스트 생성.
    final effect = ItemEffectService.resolvePersonalEquipment(itemData);
    final effectSummary = _buildEffectSummary(effect.statBonus, effect.legendary != null);

    return InkWell(
      onTap: isCurrent ? null : () => _equip(context, ref, inv),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent
              ? tierColor.withValues(alpha: 0.06)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? tierColor.withValues(alpha: 0.4)
                : AppTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            // 티어 배지.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: tierBgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'T$tier',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 이름 + 효과 요약.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemData.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isCurrent ? tierColor : AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '장착 중',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tierColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (effectSummary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      effectSummary,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 스탯 보정 + 전설 여부를 한 줄 요약 문자열로 변환한다.
  String _buildEffectSummary(EquipmentStatBonus bonus, bool hasLegendary) {
    final parts = <String>[];
    if (bonus.str != 0) parts.add('STR ${_sign(bonus.str)}${bonus.str}');
    if (bonus.intelligence != 0) {
      parts.add('INT ${_sign(bonus.intelligence)}${bonus.intelligence}');
    }
    if (bonus.vit != 0) parts.add('VIT ${_sign(bonus.vit)}${bonus.vit}');
    if (bonus.agi != 0) parts.add('AGI ${_sign(bonus.agi)}${bonus.agi}');

    final statText = parts.join(', ');
    if (hasLegendary) {
      return statText.isEmpty ? '★ 전설' : '$statText  ★ 전설';
    }
    return statText.isEmpty ? '효과 없음' : statText;
  }

  String _sign(int value) => value > 0 ? '+' : '';

  /// 슬롯 한글 라벨 반환.
  String _slotKoreanLabel(String slot, int? accessoryIndex) {
    switch (slot) {
      case 'weapon':
        return '무기';
      case 'armor':
        return '갑옷';
      case 'helmet':
        return '투구';
      case 'boots':
        return '부츠';
      case 'accessory':
        final idx = accessoryIndex ?? 0;
        return '장신구 ${idx + 1}';
      default:
        return slot;
    }
  }

  /// 아이템 장착 처리.
  ///
  /// 1. accessory 슬롯이면 기존 해당 슬롯 아이템을 먼저 해제.
  /// 2. 비-accessory 슬롯이면 현재 장착 아이템을 해제.
  /// 3. 새 아이템을 장착.
  /// 4. [equipmentRefreshProvider]를 increment하여 그리드를 갱신한다.
  Future<void> _equip(
    BuildContext context,
    WidgetRef ref,
    InventoryItem newItem,
  ) async {
    final repo = ref.read(inventoryRepositoryProvider);

    // 기존 장착 해제.
    if (currentItem != null) {
      await repo.setEquippedTo(currentItem!.id, null);
    }

    // 새 아이템 장착.
    await repo.setEquippedTo(newItem.id, mercenaryId);

    // 그리드 갱신 트리거.
    ref.read(equipmentRefreshProvider.notifier).state++;

    if (context.mounted) Navigator.pop(context);
  }

  /// 현재 장착 아이템 해제 처리.
  Future<void> _unequip(BuildContext context, WidgetRef ref) async {
    if (currentItem == null) return;
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.setEquippedTo(currentItem!.id, null);
    ref.read(equipmentRefreshProvider.notifier).state++;
    if (context.mounted) Navigator.pop(context);
  }
}
