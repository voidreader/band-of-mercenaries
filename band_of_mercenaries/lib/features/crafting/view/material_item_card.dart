import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_acquisition_hints.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_slot_labels.dart';
import 'package:band_of_mercenaries/features/crafting/domain/recipe_filter_provider.dart';

/// 인벤토리 재료 탭 — 재료 1종 카드 (tier 색 바 + 펼침 출처 힌트 + 대장간 점프 배지).
class MaterialItemCard extends ConsumerStatefulWidget {
  const MaterialItemCard({
    super.key,
    required this.itemData,
    required this.quantity,
    required this.onJumpToSmithy,
  });

  final ItemData itemData;
  final int quantity;
  final VoidCallback onJumpToSmithy;

  @override
  ConsumerState<MaterialItemCard> createState() => _MaterialItemCardState();
}

class _MaterialItemCardState extends ConsumerState<MaterialItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final usageCount =
        ref.watch(materialUsageCountProvider(widget.itemData.id));
    final tierColor = AppTheme.tierColor(widget.itemData.tier);
    final isRegionExclusive = widget.itemData.regionExclusive == 3;
    final acquisitionHint = materialAcquisitionHints[widget.itemData.id];
    final slotLabel = materialSlotLabelOf(widget.itemData.slot);

    return Card(
      shape: isRegionExclusive
          ? RoundedRectangleBorder(
              side: const BorderSide(color: AppTheme.settlementAccent, width: 1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 좌측 4px tier 색 바
                    Container(width: 4, color: tierColor),
                    const SizedBox(width: 8),
                    // 이름·슬롯·지역 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.itemData.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$slotLabel · T${widget.itemData.tier}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (isRegionExclusive) ...[
                            const SizedBox(height: 2),
                            Text(
                              '더스트빌',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.settlementAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 🔨 ×N 대장간 점프 배지
                    InkWell(
                      onTap: usageCount > 0
                          ? () {
                              ref
                                  .read(recipeFilterMaterialIdProvider.notifier)
                                  .state = widget.itemData.id;
                              widget.onJumpToSmithy();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: usageCount > 0
                              ? AppTheme.tier2Bg
                              : AppTheme.tier1Bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🔨 ×$usageCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: usageCount > 0
                                ? AppTheme.tier2
                                : AppTheme.textHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 보유 수량 (3자리 고정 우측)
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        '×${widget.quantity.toString().padLeft(3, ' ')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isExpanded && acquisitionHint != null) ...[
                const Divider(height: 16),
                Text(
                  acquisitionHint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
