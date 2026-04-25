import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/inventory/domain/essence_service.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/item_effect_service.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/features/inventory/view/essence_target_sheet.dart';
import 'package:band_of_mercenaries/shared/widgets/tier_badge.dart';

/// 인벤토리 아이템 상세 바텀 시트를 표시한다.
///
/// 카테고리별로 효과 요약을 다르게 렌더링한다:
/// - personal_equipment: 스탯 보정 + 전설 효과
/// - guild_equipment: PassiveEffect 리스트
/// - consumable: 정수 효과 (영구 스탯 증가)
Future<void> showItemDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required InventoryItem inventoryRow,
  required ItemData itemData,
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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtl) {
          return _ItemDetailContent(
            inventoryRow: inventoryRow,
            itemData: itemData,
            scrollCtl: scrollCtl,
            parentRef: ref,
          );
        },
      );
    },
  );
}

class _ItemDetailContent extends StatelessWidget {
  const _ItemDetailContent({
    required this.inventoryRow,
    required this.itemData,
    required this.scrollCtl,
    required this.parentRef,
  });

  final InventoryItem inventoryRow;
  final ItemData itemData;
  final ScrollController scrollCtl;
  final WidgetRef parentRef;

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.tierColor(itemData.tier);
    final tierBgColor = AppTheme.tierBgColor(itemData.tier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  itemData.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TierBadge(
                tier: itemData.tier,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: scrollCtl,
              children: [
                if (itemData.description.isNotEmpty) ...[
                  Text(
                    itemData.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (itemData.flavorText.isNotEmpty) ...[
                  Text(
                    itemData.flavorText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildEffectSummary(),
                const SizedBox(height: 16),
                _buildStatusInfo(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildEffectSummary() {
    final lines = <String>[];
    switch (itemData.category) {
      case 'personal_equipment':
        final eff = ItemEffectService.resolvePersonalEquipment(itemData);
        final b = eff.statBonus;
        if (b.str != 0) lines.add('STR ${b.str > 0 ? '+' : ''}${b.str}');
        if (b.intelligence != 0) {
          lines.add('INT ${b.intelligence > 0 ? '+' : ''}${b.intelligence}');
        }
        if (b.vit != 0) lines.add('VIT ${b.vit > 0 ? '+' : ''}${b.vit}');
        if (b.agi != 0) lines.add('AGI ${b.agi > 0 ? '+' : ''}${b.agi}');
        if (eff.legendary != null) {
          lines.add('전설: ${_describeLegendary(eff.legendary!)}');
        }
      case 'guild_equipment':
        final passives = ItemEffectService.resolveGuildEquipment(itemData);
        for (final p in passives) {
          lines.add(PassiveBonusFormatter.format(p));
        }
      case 'consumable':
        final desc = EssenceService.resolve(itemData);
        if (desc == null) {
          lines.add('효과 데이터 누락');
        } else {
          final name =
              EssenceService.statKoreanNames[desc.statKey] ?? desc.statKey;
          lines.add('$name 영구 +${desc.gain}');
        }
    }

    if (lines.isEmpty) {
      return const Text(
        '효과 없음',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '효과',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $l',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
      ],
    );
  }

  String _describeLegendary(LegendaryEffect eff) {
    return switch (eff) {
      LegendarySuccessRateBonus(:final questType, :final value) =>
        '$questType 성공률 ${value > 0 ? '+' : ''}${value.toStringAsFixed(0)}%p',
      LegendaryResultUpgrade(:final chance) =>
        '성공→대성공 승격 확률 ${(chance * 100).toStringAsFixed(0)}%',
      LegendaryDamageResistance(:final injuryMod, :final deathMod) =>
        '부상률 ${(injuryMod * 100).toStringAsFixed(0)}%p / 사망률 ${(deathMod * 100).toStringAsFixed(0)}%p',
      LegendaryRewardBonus(:final multiplier) =>
        '보상 +${(multiplier * 100).toStringAsFixed(0)}%',
      LegendarySpecial(:final deathPreventionCount, :final cooldownHours) =>
        '사망 방지 $deathPreventionCount회 (쿨다운 ${cooldownHours}h)',
    };
  }

  Widget _buildStatusInfo() {
    final isConsumable = itemData.category == 'consumable';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보유 정보',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '수량: ${inventoryRow.quantity}${isConsumable ? '' : ' (장비)'}',
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final isConsumable = itemData.category == 'consumable';
    if (isConsumable) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('사용'),
          onPressed: () async {
            Navigator.pop(context);
            await showEssenceTargetSheet(
              context: context,
              ref: parentRef,
              inventoryRow: inventoryRow,
              essence: itemData,
            );
          },
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '장착은 용병 상세 또는 용병단 장비 화면에서 진행하세요.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
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
