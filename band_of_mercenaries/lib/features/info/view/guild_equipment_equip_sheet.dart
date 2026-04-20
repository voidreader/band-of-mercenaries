import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/features/inventory/domain/item_effect_service.dart';

/// 용병단 장비 슬롯 장착 변경 모달 시트.
///
/// [slot]: 'banner' | 'artifact'
/// [artifactSlotIndex]: artifact 슬롯일 때 0 또는 1, banner이면 null.
class GuildEquipmentEquipSheet extends ConsumerWidget {
  final String slot;
  final int? artifactSlotIndex;

  const GuildEquipmentEquipSheet({
    super.key,
    required this.slot,
    this.artifactSlotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final staticDataAsync = ref.watch(staticDataProvider);
    final staticData = staticDataAsync.valueOrNull;

    if (userData == null || staticData == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = staticData.items;

    // slot 조건으로 필터링
    final candidates = items
        .where((item) => item.category == 'guild_equipment' && item.slot == slot)
        .toList()
      ..sort((a, b) => a.tier.compareTo(b.tier));

    // 현재 장착 ID 계산
    final String? equippedId = _currentEquippedId(userData);

    // 현재 장착 아이템
    final ItemData? equippedItem = equippedId != null
        ? candidates.where((i) => i.id == equippedId).firstOrNull
        : null;

    // 미장착 아이템 목록 (현재 장착 제외)
    final unequipped = candidates.where((i) => i.id != equippedId).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 시트 핸들
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 시트 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _sheetTitle(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),
            // 아이템 목록
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 현재 장착 아이템 (상단 하이라이트)
                  if (equippedItem != null) ...[
                    _SectionLabel(label: '장착 중'),
                    _ItemTile(
                      item: equippedItem,
                      isEquipped: true,
                      equippedSlotLabel: null,
                      onTap: () {
                        // 이미 장착 중 — 탭 무반응 (해제는 하단 버튼으로)
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                  // 미장착 아이템들
                  if (unequipped.isNotEmpty) ...[
                    _SectionLabel(label: '보유 장비'),
                    for (final item in unequipped)
                      _ItemTile(
                        item: item,
                        isEquipped: false,
                        equippedSlotLabel: _otherSlotLabel(item.id, userData),
                        onTap: () => _equipItem(context, ref, item.id),
                      ),
                  ] else if (equippedItem == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '장착 가능한 장비가 없습니다',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  // 해제 버튼 (현재 장착 중인 경우에만)
                  if (equippedId != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _unequipItem(context, ref),
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('장착 해제'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.border),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 현재 슬롯에 장착된 아이템 ID 반환.
  String? _currentEquippedId(dynamic userData) {
    if (slot == 'banner') {
      return userData.bannerItemId as String?;
    } else {
      // artifact
      final List<String> ids = userData.artifactItemIds as List<String>;
      final idx = artifactSlotIndex ?? 0;
      return idx < ids.length ? ids[idx] : null;
    }
  }

  /// artifact 슬롯의 경우, 해당 아이템이 다른 슬롯에 장착되어 있으면 레이블 반환.
  String? _otherSlotLabel(String itemId, dynamic userData) {
    if (slot != 'artifact') return null;
    final List<String> ids = userData.artifactItemIds as List<String>;
    for (int i = 0; i < ids.length && i < 2; i++) {
      if (ids[i] == itemId && i != artifactSlotIndex) {
        return '슬롯 ${i + 1}에 장착 중';
      }
    }
    return null;
  }

  String _sheetTitle() {
    if (slot == 'banner') return '깃발 슬롯 변경';
    final idx = (artifactSlotIndex ?? 0) + 1;
    return '유물 슬롯 $idx 변경';
  }

  Future<void> _equipItem(
      BuildContext context, WidgetRef ref, String itemId) async {
    if (slot == 'banner') {
      await ref.read(userDataProvider.notifier).setGuildBanner(itemId);
    } else {
      await ref
          .read(userDataProvider.notifier)
          .setGuildArtifact(artifactSlotIndex!, itemId);
    }
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _unequipItem(BuildContext context, WidgetRef ref) async {
    if (slot == 'banner') {
      await ref.read(userDataProvider.notifier).setGuildBanner(null);
    } else {
      await ref
          .read(userDataProvider.notifier)
          .setGuildArtifact(artifactSlotIndex!, null);
    }
    if (context.mounted) Navigator.pop(context);
  }
}

/// 섹션 라벨 (장착 중 / 보유 장비).
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textHint,
        ),
      ),
    );
  }
}

/// 아이템 목록 타일.
///
/// - 장착 중: 하이라이트 배경 + "장착 중" 배지.
/// - 다른 슬롯에 장착: [equippedSlotLabel] 표시.
class _ItemTile extends StatelessWidget {
  final ItemData item;
  final bool isEquipped;
  final String? equippedSlotLabel;
  final VoidCallback onTap;

  const _ItemTile({
    required this.item,
    required this.isEquipped,
    required this.equippedSlotLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = AppTheme.tierColor(item.tier);
    final tierBgColor = AppTheme.tierBgColor(item.tier);

    final effects = ItemEffectService.resolveGuildEquipment(item);
    final effectSummary = effects
        .map(PassiveBonusFormatter.format)
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return InkWell(
      onTap: isEquipped ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEquipped
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEquipped
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : AppTheme.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 티어 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tierBgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tierColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                'T${item.tier}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 이름 + 효과 요약
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (effectSummary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      effectSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 상태 배지
            if (isEquipped)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '장착 중',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else if (equippedSlotLabel != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  equippedSlotLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
