import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/features/inventory/domain/item_effect_service.dart';
import 'package:band_of_mercenaries/features/info/view/guild_equipment_equip_sheet.dart';
import 'package:band_of_mercenaries/shared/widgets/tier_badge.dart';

/// 정보 탭에서 진입하는 용병단 장비 전체화면.
///
/// 3개 슬롯(깃발 1 + 유물 2)을 카드로 표시.
/// 각 카드 탭 시 GuildEquipmentEquipSheet 모달 시트로 장착 변경.
class GuildEquipmentScreen extends ConsumerWidget {
  final VoidCallback onBack;
  const GuildEquipmentScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final staticDataAsync = ref.watch(staticDataProvider);
    final staticData = staticDataAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: onBack,
              ),
              const Text(
                '용병단 장비',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        // 본문
        Expanded(
          child: (userData == null || staticData == null)
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, ref, userData, staticData),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    dynamic userData,
    StaticGameData staticData,
  ) {
    final items = staticData.items;
    // id → ItemData 조회 맵
    final itemMap = {for (final item in items) item.id: item};

    // 현재 장착 ItemData 조회
    final bannerItem = userData.bannerItemId != null
        ? itemMap[userData.bannerItemId]
        : null;

    final List<String> artifactIds = userData.artifactItemIds;
    final artifact0 = artifactIds.isNotEmpty ? itemMap[artifactIds[0]] : null;
    final artifact1 = artifactIds.length > 1 ? itemMap[artifactIds[1]] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 깃발 슬롯
        _SlotCard(
          label: '깃발 슬롯',
          equippedItem: bannerItem,
          onTap: () => _openEquipSheet(
            context,
            slot: 'banner',
            artifactSlotIndex: null,
          ),
        ),
        const SizedBox(height: 12),
        // 유물 슬롯 1
        _SlotCard(
          label: '유물 슬롯 1',
          equippedItem: artifact0,
          onTap: () => _openEquipSheet(
            context,
            slot: 'artifact',
            artifactSlotIndex: 0,
          ),
        ),
        const SizedBox(height: 12),
        // 유물 슬롯 2
        _SlotCard(
          label: '유물 슬롯 2',
          equippedItem: artifact1,
          onTap: () => _openEquipSheet(
            context,
            slot: 'artifact',
            artifactSlotIndex: 1,
          ),
        ),
      ],
    );
  }

  void _openEquipSheet(
    BuildContext context, {
    required String slot,
    required int? artifactSlotIndex,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GuildEquipmentEquipSheet(
        slot: slot,
        artifactSlotIndex: artifactSlotIndex,
      ),
    );
  }
}

/// 슬롯 카드 위젯.
///
/// 장착 아이템이 있으면 이름+효과 요약, 없으면 "비어있음" + 점선 테두리.
class _SlotCard extends StatelessWidget {
  final String label;
  final ItemData? equippedItem;
  final VoidCallback onTap;

  const _SlotCard({
    required this.label,
    required this.equippedItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = equippedItem == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: isEmpty
              ? Border.all(
                  color: AppTheme.borderLight,
                  width: 1,
                  style: BorderStyle.solid,
                )
              : Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 슬롯 헤더 라벨
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (isEmpty)
              // 빈 슬롯
              Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      size: 18, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Text(
                    '비어있음',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else ...[
              // 장착 아이템 이름 + 티어 배지
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TierBadge(tier: equippedItem!.tier),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      equippedItem!.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textHint),
                ],
              ),
              // 효과 요약
              const SizedBox(height: 6),
              _EffectSummaryText(item: equippedItem!),
            ],
          ],
        ),
      ),
    );
  }
}

/// 아이템 효과 요약 텍스트.
///
/// ItemEffectService.resolveGuildEquipment + PassiveBonusFormatter.format으로 한 줄 생성.
class _EffectSummaryText extends StatelessWidget {
  final ItemData item;
  const _EffectSummaryText({required this.item});

  @override
  Widget build(BuildContext context) {
    final effects = ItemEffectService.resolveGuildEquipment(item);
    final summaryLines = effects
        .map(PassiveBonusFormatter.format)
        .where((s) => s.isNotEmpty)
        .join('\n');

    if (summaryLines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      summaryLines,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

