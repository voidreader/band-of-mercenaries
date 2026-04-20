import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.inventoryRow,
    required this.itemData,
    this.mercenaryName,
    this.guildSlotLabel,
    required this.onTap,
  });

  final InventoryItem inventoryRow;
  final ItemData itemData;
  final String? mercenaryName; // 개인 장비 장착 시 용병 이름
  final String? guildSlotLabel; // 용병단 장비 장착 슬롯 라벨
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.tierColor(itemData.tier);
    final tierBgColor = AppTheme.tierBgColor(itemData.tier);
    final isConsumable = itemData.category == 'consumable';

    String? equipLabel;
    if (mercenaryName != null) {
      equipLabel = '장착 중: $mercenaryName';
    } else if (guildSlotLabel != null) {
      equipLabel = guildSlotLabel;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘 원형
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tierBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: tierColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  _categoryIcon(itemData.category),
                  style: TextStyle(fontSize: 16, color: tierColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 이름 + 상태
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemData.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierBgColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'T${itemData.tier}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (equipLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      equipLabel,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (isConsumable) ...[
              const SizedBox(width: 8),
              Text(
                '× ${inventoryRow.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryIcon(String category) {
    switch (category) {
      case 'personal_equipment':
        return '⚔';
      case 'guild_equipment':
        return '🏴';
      case 'consumable':
        return '✧';
      default:
        return '?';
    }
  }
}
