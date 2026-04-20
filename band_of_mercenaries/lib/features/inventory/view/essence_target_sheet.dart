import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/inventory/domain/essence_service.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/view/essence_apply_preview_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

/// 경로 B — 인벤토리에서 아이템 선택 후 대상 용병을 고르는 바텀 시트.
Future<void> showEssenceTargetSheet({
  required BuildContext context,
  required WidgetRef ref,
  required InventoryItem inventoryRow,
  required ItemData essence,
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
          return _EssenceTargetContent(
            inventoryRow: inventoryRow,
            essence: essence,
            scrollCtl: scrollCtl,
            parentRef: ref,
          );
        },
      );
    },
  );
}

class _EssenceTargetContent extends ConsumerWidget {
  const _EssenceTargetContent({
    required this.inventoryRow,
    required this.essence,
    required this.scrollCtl,
    required this.parentRef,
  });

  final InventoryItem inventoryRow;
  final ItemData essence;
  final ScrollController scrollCtl;
  final WidgetRef parentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = EssenceService.resolve(essence);
    if (descriptor == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('정수 데이터 오류'),
        ),
      );
    }

    final mercs = ref
        .watch(mercenaryListProvider)
        .where((m) => m.status != MercenaryStatus.dead)
        .toList();

    final staticData = ref.watch(staticDataProvider).valueOrNull;
    if (staticData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final jobMap = {for (final j in staticData.jobs) j.id: j};

    // 용병별 프리뷰 계산
    final infoList = mercs.map((m) {
      final job = jobMap[m.jobId];
      final tier = job?.tier ?? 1;
      final preview = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: tier,
      );
      return _TargetInfo(
        merc: m,
        jobName: job?.name ?? '?',
        tier: tier,
        preview: preview,
      );
    }).toList();

    final allBlocked =
        infoList.isNotEmpty && infoList.every((i) => i.preview.appliedGain == 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${essence.name} — 대상 용병 선택',
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
          const SizedBox(height: 8),
          Text(
            '효과: ${EssenceService.statKoreanNames[descriptor.statKey]} 영구 +${descriptor.gain}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (allBlocked)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                '⚠ 모든 용병이 해당 스탯 상한에 도달했습니다.',
                style: TextStyle(fontSize: 13, color: Colors.orange),
              ),
            ),
          Expanded(
            child: infoList.isEmpty
                ? const Center(
                    child: Text(
                      '사용할 수 있는 용병이 없습니다',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtl,
                    itemCount: infoList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) =>
                        _buildTargetCard(context, infoList[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, _TargetInfo info) {
    final disabled = info.preview.appliedGain == 0;
    final warn = !disabled && info.preview.lossAmount > 0;
    final statName =
        EssenceService.statKoreanNames[info.preview.statKey] ??
        info.preview.statKey;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: disabled
            ? null
            : () async {
                final confirmed = await showEssenceApplyPreviewDialog(
                  context: context,
                  ref: parentRef,
                  mercenary: info.merc,
                  mercenaryTier: info.tier,
                  inventoryRow: inventoryRow,
                  essence: essence,
                  preview: info.preview,
                  jobName: info.jobName,
                );
                if (confirmed == true && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1500),
                      content: Text(
                        '${info.merc.name}이(가) ${essence.name}을(를) 각인했다. '
                        '$statName +${info.preview.appliedGain}',
                      ),
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(6),
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
                  Expanded(
                    child: Text(
                      '${info.merc.name} '
                      '(T${info.tier} ${info.jobName}, Lv${info.merc.level})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (disabled)
                    const Text(
                      '상한 도달',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    )
                  else if (warn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '일부 손실 (-${info.preview.lossAmount})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '현재 $statName ${info.preview.effectiveBefore} '
                '(permanent +${info.preview.currentPermanent}/${info.preview.cap}) '
                '· 잔량 +${info.preview.cap - info.preview.currentPermanent}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetInfo {
  _TargetInfo({
    required this.merc,
    required this.jobName,
    required this.tier,
    required this.preview,
  });

  final Mercenary merc;
  final String jobName;
  final int tier;
  final EssencePreview preview;
}
