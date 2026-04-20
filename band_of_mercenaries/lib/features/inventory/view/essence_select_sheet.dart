import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/essence_service.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/view/essence_apply_preview_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

/// 정수 사용 완료 콜백 — statKey와 실제 적용된 gain을 전달한다.
typedef EssenceApplyCallback = void Function(String statKey, int appliedGain);

/// 경로 A — 용병 상세에서 해당 용병에게 사용할 정수를 선택하는 바텀 시트.
Future<void> showEssenceSelectSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String mercenaryId,
  EssenceApplyCallback? onApplySuccess,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtl) {
          return _EssenceSelectContent(
            mercenaryId: mercenaryId,
            scrollCtl: scrollCtl,
            parentRef: ref,
            onApplySuccess: onApplySuccess,
          );
        },
      );
    },
  );
}

class _EssenceSelectContent extends ConsumerWidget {
  const _EssenceSelectContent({
    required this.mercenaryId,
    required this.scrollCtl,
    required this.parentRef,
    required this.onApplySuccess,
  });

  final String mercenaryId;
  final ScrollController scrollCtl;
  final WidgetRef parentRef;
  final EssenceApplyCallback? onApplySuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercs = ref.watch(mercenaryListProvider);
    final merc = mercs.where((m) => m.id == mercenaryId).firstOrNull;
    if (merc == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('용병 정보를 찾을 수 없습니다'),
        ),
      );
    }

    final staticData = ref.watch(staticDataProvider).valueOrNull;
    if (staticData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final job = staticData.jobs.where((j) => j.id == merc.jobId).firstOrNull;
    final mercenaryTier = job?.tier ?? 1;
    final jobName = job?.name ?? merc.jobId;

    // 보유 consumable 아이템 중 essence 해석 가능한 것만 필터
    final inventoryRepo = ref.watch(inventoryRepositoryProvider);
    final allRows = inventoryRepo.getAll();
    final itemMap = {for (final i in staticData.items) i.id: i};

    final essenceEntries = <_EssenceEntry>[];
    for (final row in allRows) {
      final item = itemMap[row.itemId];
      if (item == null || item.category != 'consumable') continue;
      final descriptor = EssenceService.resolve(item);
      if (descriptor == null) continue;
      final preview = EssenceService.preview(
        mercenary: merc,
        essence: item,
        mercenaryTier: mercenaryTier,
      );
      essenceEntries.add(_EssenceEntry(
        row: row,
        item: item,
        descriptor: descriptor,
        preview: preview,
      ));
    }
    // 정렬: tier 내림차순, 이름 오름차순
    essenceEntries.sort((a, b) {
      if (a.item.tier != b.item.tier) return b.item.tier.compareTo(a.item.tier);
      return a.item.name.compareTo(b.item.name);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${merc.name}에게 사용할 정수 선택',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: essenceEntries.isEmpty
                ? const Center(
                    child: Text(
                      '보유한 정수가 없습니다',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtl,
                    itemCount: essenceEntries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _buildEssenceCard(
                      context,
                      merc,
                      mercenaryTier,
                      jobName,
                      essenceEntries[i],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssenceCard(
    BuildContext context,
    Mercenary merc,
    int mercenaryTier,
    String jobName,
    _EssenceEntry entry,
  ) {
    final statName =
        EssenceService.statKoreanNames[entry.descriptor.statKey] ??
        entry.descriptor.statKey;
    final tierColor = AppTheme.tierColor(entry.item.tier);
    final tierBgColor = AppTheme.tierBgColor(entry.item.tier);
    final jailBefore = entry.preview.cap - entry.preview.currentPermanent;
    final disabled = entry.preview.appliedGain == 0;
    final warn = !disabled && entry.preview.lossAmount > 0;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierBgColor,
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: tierColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'T${entry.item.tier}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '×${entry.row.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '현재 $statName ${entry.preview.effectiveBefore}'
              ' (permanent +${entry.preview.currentPermanent}/${entry.preview.cap})'
              ' · 잔량 +$jailBefore · 효과 +${entry.descriptor.gain}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (disabled)
                  const Text(
                    '상한 도달',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                  )
                else if (warn)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '일부 손실 (-${entry.preview.lossAmount})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: disabled
                      ? null
                      : () => _handleUse(
                          context, merc, mercenaryTier, jobName, entry),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(60, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('사용', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUse(
    BuildContext context,
    Mercenary merc,
    int mercenaryTier,
    String jobName,
    _EssenceEntry entry,
  ) async {
    final confirmed = await showEssenceApplyPreviewDialog(
      context: context,
      ref: parentRef,
      mercenary: merc,
      mercenaryTier: mercenaryTier,
      inventoryRow: entry.row,
      essence: entry.item,
      preview: entry.preview,
      jobName: jobName,
    );
    if (confirmed == true) {
      onApplySuccess?.call(entry.descriptor.statKey, entry.preview.appliedGain);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _EssenceEntry {
  _EssenceEntry({
    required this.row,
    required this.item,
    required this.descriptor,
    required this.preview,
  });

  final InventoryItem row;
  final ItemData item;
  final EssenceDescriptor descriptor;
  final EssencePreview preview;
}
