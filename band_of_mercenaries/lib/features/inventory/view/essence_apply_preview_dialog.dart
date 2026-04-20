import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/essence_service.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

/// 정수 사용 프리뷰 팝업을 표시하고 사용 여부(true/false/null)를 반환한다.
///
/// [preview.appliedGain] == 0이면 상한 도달 안내 AlertDialog를 표시하고 false를 반환한다.
Future<bool?> showEssenceApplyPreviewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Mercenary mercenary,
  required int mercenaryTier,
  required InventoryItem inventoryRow,
  required ItemData essence,
  required EssencePreview preview,
  required String jobName,
}) {
  // 잔량 0 이미 도달: 별도 안내 후 차단
  if (preview.appliedGain == 0) {
    final statName =
        EssenceService.statKoreanNames[preview.statKey] ?? preview.statKey;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('상한 도달'),
        content: Text('$statName 상한에 이미 도달했습니다. 사용할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PreviewDialog(
      mercenary: mercenary,
      mercenaryTier: mercenaryTier,
      inventoryRow: inventoryRow,
      essence: essence,
      preview: preview,
      jobName: jobName,
      parentRef: ref,
    ),
  );
}

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({
    required this.mercenary,
    required this.mercenaryTier,
    required this.inventoryRow,
    required this.essence,
    required this.preview,
    required this.jobName,
    required this.parentRef,
  });

  final Mercenary mercenary;
  final int mercenaryTier;
  final InventoryItem inventoryRow;
  final ItemData essence;
  final EssencePreview preview;
  final String jobName;
  final WidgetRef parentRef;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    final isOverflow = p.warningLevel == EssencePreviewLevel.overflow;
    final isApproaching = p.warningLevel == EssencePreviewLevel.approaching;
    final statShort = _statShort(p.statKey);
    final base = _getBase(widget.mercenary, p.statKey);
    final newPermanent = p.currentPermanent + p.appliedGain;
    final jailBefore = p.cap - p.currentPermanent;
    final jailAfter = p.cap - newPermanent;
    final levelBonusPct =
        (widget.mercenary.level - 1) * GameConstants.levelBonusPerLevel * 100;

    return AlertDialog(
      title: Text(
        isOverflow ? '⚠ 상한 초과 경고' : '정수 사용 확인',
        style: TextStyle(color: isOverflow ? Colors.red : null),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '대상 용병: ${widget.mercenary.name} '
              '(T${widget.mercenaryTier} ${widget.jobName}, Lv${widget.mercenary.level})',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '사용 아이템: ${widget.essence.name} — T${widget.essence.tier} 정수 (+${p.gain})',
              style: const TextStyle(fontSize: 13),
            ),
            const Divider(height: 16),
            _row(
              '현재 $statShort',
              '${base + p.currentPermanent} (base $base + permanent +${p.currentPermanent})',
            ),
            _row(
              '사용 후 $statShort',
              '${base + newPermanent} (base $base + permanent +$newPermanent)',
            ),
            _row('상한 잔량', '+$jailBefore → +$jailAfter'),
            _row(
              'effective $statShort',
              '${p.effectiveBefore} → ${p.effectiveAfter}  '
              '(레벨 보너스 ${levelBonusPct.toStringAsFixed(0)}%)',
            ),
            if (isOverflow) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '상한 초과: ${p.lossAmount} 포인트가 손실됩니다',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isApproaching) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '다음 사용 시 상한 초과 가능',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _applying ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _applying ? null : _apply,
          style: isOverflow
              ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
              : null,
          child: Text(isOverflow ? '손실 감수하고 사용' : '사용'),
        ),
      ],
    );
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final mercRepo = widget.parentRef.read(mercenaryRepositoryProvider);
    final inventoryRepo = widget.parentRef.read(inventoryRepositoryProvider);
    final logNotifier =
        widget.parentRef.read(activityLogProvider.notifier);

    final result = await EssenceService.apply(
      mercenary: widget.mercenary,
      mercenaryTier: widget.mercenaryTier,
      inventoryRow: widget.inventoryRow,
      essence: widget.essence,
      mercRepo: mercRepo,
      inventoryRepo: inventoryRepo,
      logNotifier: logNotifier,
    );
    // 용병 리스트 갱신
    widget.parentRef.read(mercenaryListProvider.notifier).refresh();
    if (!mounted) return;

    switch (result) {
      case EssenceApplySuccess():
        Navigator.pop(context, true);
      case EssenceApplyFailure(:final reason):
        Navigator.pop(context, false);
        final msg = switch (reason) {
          'full_cap' => '이미 상한에 도달했습니다',
          'schema' => '정수 데이터 오류',
          'not_found' => '아이템을 찾을 수 없습니다',
          _ => '정수 사용 실패',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  int _getBase(Mercenary m, String statKey) {
    switch (statKey) {
      case 'str':
        return m.str;
      case 'intelligence':
        return m.intelligence;
      case 'vit':
        return m.vit;
      case 'agi':
        return m.agi;
      default:
        return 0;
    }
  }

  String _statShort(String statKey) {
    switch (statKey) {
      case 'str':
        return 'STR';
      case 'intelligence':
        return 'INT';
      case 'vit':
        return 'VIT';
      case 'agi':
        return 'AGI';
      default:
        return statKey;
    }
  }
}
