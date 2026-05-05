import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_acquisition_hints.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_jump_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_slot_labels.dart';
import 'package:band_of_mercenaries/features/crafting/view/material_item_card.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';

/// 인벤토리 재료 탭 콘텐츠 — slot 필터 ChipBar + 카드 목록 + 빈 상태.
class MaterialTabContent extends ConsumerStatefulWidget {
  const MaterialTabContent({
    super.key,
    required this.materialRows,
    required this.allItems,
  });

  /// 보유 InventoryItem 목록 (이미 material 카테고리 필터링됨).
  final List<InventoryItem> materialRows;

  /// 전체 ItemData (재료 lookup용).
  final List<ItemData> allItems;

  @override
  ConsumerState<MaterialTabContent> createState() => _MaterialTabContentState();
}

class _MaterialTabContentState extends ConsumerState<MaterialTabContent> {
  String? _selectedSlot; // null = 전체
  final ScrollController _scrollController = ScrollController();
  bool _showSlotGuides = false; // 빈 상태에서 출처 가이드 펼침 여부

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// jump target 감지 시 slot 자동 전환 + 스크롤 상단 이동 + provider 즉시 리셋.
  void _handleJumpTarget(String? targetItemId) {
    if (targetItemId == null) return;
    final itemData = widget.allItems.where((i) => i.id == targetItemId).firstOrNull;
    if (itemData == null) return;

    setState(() {
      _selectedSlot = itemData.slot;
    });

    // 다음 프레임에서 필터가 적용된 뒤 상단으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 감지 후 즉시 리셋 (재진입 방지)
    ref.read(materialJumpTargetItemIdProvider.notifier).state = null;
  }

  List<InventoryItem> _filteredAndSorted(Map<String, ItemData> itemMap) {
    final filtered = widget.materialRows.where((row) {
      if (_selectedSlot == null) return true;
      return itemMap[row.itemId]?.slot == _selectedSlot;
    }).toList();

    // 정렬: tier 내림차순 → 보유량 내림차순 → id 오름차순
    filtered.sort((a, b) {
      final aTier = itemMap[a.itemId]?.tier ?? 0;
      final bTier = itemMap[b.itemId]?.tier ?? 0;
      final tierCmp = bTier.compareTo(aTier);
      if (tierCmp != 0) return tierCmp;
      final qtyCmp = b.quantity.compareTo(a.quantity);
      if (qtyCmp != 0) return qtyCmp;
      return a.itemId.compareTo(b.itemId);
    });

    return filtered;
  }

  void _onJumpToSmithy(String materialItemId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('낡은 대장간에서 확인할 수 있습니다'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build 메서드 내에서 listen 등록 (StatefulWidget 규칙)
    ref.listen<String?>(materialJumpTargetItemIdProvider, (prev, next) {
      _handleJumpTarget(next);
    });

    if (widget.materialRows.isEmpty) {
      return EmptyMaterialState(
        showGuides: _showSlotGuides,
        onToggleGuides: () => setState(() => _showSlotGuides = !_showSlotGuides),
      );
    }

    final itemMap = {for (final i in widget.allItems) i.id: i};
    final filteredRows = _filteredAndSorted(itemMap);

    return Column(
      children: [
        MaterialSlotChipBar(
          selectedSlot: _selectedSlot,
          onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
        ),
        Expanded(
          child: filteredRows.isEmpty
              ? const Center(
                  child: Text(
                    '해당 슬롯의 재료가 없습니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredRows.length,
                  separatorBuilder: (context2, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = filteredRows[index];
                    final itemData = itemMap[row.itemId];
                    if (itemData == null) return const SizedBox.shrink();
                    return MaterialItemCard(
                      key: ValueKey(row.itemId),
                      itemData: itemData,
                      quantity: row.quantity,
                      onJumpToSmithy: () => _onJumpToSmithy(row.itemId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// 재료 slot 5종 + 전체 가로 스크롤 칩 필터 바.
class MaterialSlotChipBar extends StatelessWidget {
  const MaterialSlotChipBar({
    super.key,
    required this.selectedSlot,
    required this.onSlotChanged,
  });

  /// 현재 선택된 slot 키 (null = 전체).
  final String? selectedSlot;

  /// slot 변경 콜백 (null = 전체 선택).
  final void Function(String? slot) onSlotChanged;

  @override
  Widget build(BuildContext context) {
    // 전체 + 5종 slot 순서 고정
    const slots = <String?>[
      null,
      'material_ore',
      'material_hide',
      'material_herb',
      'material_relic_fragment',
      'material_monster_part',
    ];

    String labelFor(String? slot) {
      if (slot == null) return '전체';
      return materialSlotLabels[slot] ?? slot;
    }

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: slots.map((slot) {
            final isSelected = selectedSlot == slot;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  labelFor(slot),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSlotChanged(slot),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: AppTheme.tier1Bg,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.border,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 재료 보유 없음 상태 — 안내 메시지 + slot 출처 가이드 토글.
class EmptyMaterialState extends StatelessWidget {
  const EmptyMaterialState({
    super.key,
    required this.showGuides,
    required this.onToggleGuides,
  });

  /// 출처 가이드 펼침 여부.
  final bool showGuides;

  /// 가이드 토글 콜백.
  final VoidCallback onToggleGuides;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            '아직 입수한 재료가 없습니다.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '의뢰 / 조사 / 사건 등을 통해 다양한 재료를 모아보세요.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // 출처 가이드 토글 버튼
          InkWell(
            onTap: onToggleGuides,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.tier1Bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showGuides ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    showGuides ? '출처 가이드 접기' : '출처 가이드 보기',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showGuides) ...[
            const SizedBox(height: 16),
            ...materialSlotGuides.entries.map((entry) {
              final label = materialSlotLabels[entry.key] ?? entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '▼ $label',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
