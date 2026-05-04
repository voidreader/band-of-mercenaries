import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/settlement/domain/herbalist_service.dart';

class HerbalistHealDialog extends ConsumerStatefulWidget {
  final int trustLevel;
  const HerbalistHealDialog({super.key, required this.trustLevel});

  @override
  ConsumerState<HerbalistHealDialog> createState() => _HerbalistHealDialogState();
}

class _HerbalistHealDialogState extends ConsumerState<HerbalistHealDialog> {
  String? _selectedMercId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final mercs = ref.watch(mercenaryListProvider);
    final healTargets = mercs.where((m) =>
        !m.isDispatched &&
        m.status != MercenaryStatus.dead &&
        (m.status == MercenaryStatus.injured ||
            m.status == MercenaryStatus.tired)).toList();

    final cost = HerbalistService.calculateCost(widget.trustLevel);
    final cooldown = HerbalistService.calculateCooldownMinutes(widget.trustLevel);

    final selectedMerc = _selectedMercId != null
        ? mercs.where((m) => m.id == _selectedMercId).firstOrNull
        : null;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        _selectedMercId == null ? '회복 대상 선택' : '회복 확인',
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      ),
      content: _selectedMercId == null
          ? _SelectionContent(
              healTargets: healTargets,
              onSelect: (id) => setState(() => _selectedMercId = id),
            )
          : _ConfirmContent(
              merc: selectedMerc,
              cost: cost,
              cooldownMinutes: cooldown,
            ),
      actions: _selectedMercId == null
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ]
          : [
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () => setState(() => _selectedMercId = null),
                child: const Text('뒤로'),
              ),
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _confirm(cost, cooldown),
                child: const Text('확인'),
              ),
            ],
    );
  }

  Future<void> _confirm(int cost, int cooldownMinutes) async {
    if (_selectedMercId == null) return;
    setState(() => _isProcessing = true);
    await ref.read(mercenaryListProvider.notifier).healInstant(
      mercId: _selectedMercId!,
      cost: cost,
      cooldownMinutes: cooldownMinutes,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('회복 완료 (-${cost}G)'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _SelectionContent extends StatelessWidget {
  final List<Mercenary> healTargets;
  final void Function(String) onSelect;

  const _SelectionContent({
    required this.healTargets,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (healTargets.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            '회복 대상 용병이 없습니다',
            style: TextStyle(fontSize: 14, color: AppTheme.textHint),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.maxFinite,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: healTargets.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderLight),
        itemBuilder: (context, index) {
          final merc = healTargets[index];
          return _MercListTile(
            merc: merc,
            onTap: () => onSelect(merc.id),
          );
        },
      ),
    );
  }
}

class _MercListTile extends StatelessWidget {
  final Mercenary merc;
  final VoidCallback onTap;

  const _MercListTile({required this.merc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusLabel = merc.status == MercenaryStatus.injured ? '부상' : '피로';
    final statusColor =
        merc.status == MercenaryStatus.injured ? AppTheme.tier5 : AppTheme.tier3;

    final endTime = merc.status == MercenaryStatus.injured
        ? merc.injuryEndTime
        : merc.tiredEndTime;
    final now = DateTime.now();
    final remainingMin = endTime != null && endTime.isAfter(now)
        ? endTime.difference(now).inMinutes + 1
        : null;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(
        merc.name,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary),
      ),
      subtitle: remainingMin != null
          ? Text(
              '회복까지 $remainingMin분 남음',
              style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
            )
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        ),
        child: Text(
          statusLabel,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor),
        ),
      ),
    );
  }
}

class _ConfirmContent extends StatelessWidget {
  final Mercenary? merc;
  final int cost;
  final int cooldownMinutes;

  const _ConfirmContent({
    required this.merc,
    required this.cost,
    required this.cooldownMinutes,
  });

  @override
  Widget build(BuildContext context) {
    if (merc == null) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '용병 정보를 찾을 수 없습니다',
            style: TextStyle(fontSize: 14, color: AppTheme.textHint),
          ),
        ),
      );
    }

    final statusLabel = merc!.status == MercenaryStatus.injured ? '부상' : '피로';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '대상',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
            const SizedBox(width: 12),
            Text(
              merc!.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              '($statusLabel)',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              '비용',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
            const SizedBox(width: 12),
            Text(
              '${cost}G',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text(
              '쿨다운',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
            const SizedBox(width: 12),
            Text(
              '$cooldownMinutes분',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '즉시 회복하시겠습니까?',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
