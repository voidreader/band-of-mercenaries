import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_item_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_unlock_result.dart';

/// M8a 세력 상점 섹션 (FR-G1)
///
/// staticData.factionShopItems에서 factionId 일치 상품을 evaluateUnlock 결과별 그룹으로 표시한다.
class FactionShopSection extends ConsumerWidget {
  final String factionId;
  const FactionShopSection({super.key, required this.factionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).value;
    if (staticData == null) return const SizedBox.shrink();

    final items = staticData.factionShopItems
        .where((i) => i.factionId == factionId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (items.isEmpty) return const SizedBox.shrink();

    final ready = <FactionShopItem>[];
    final locked = <FactionShopItem>[];
    final soldOut = <FactionShopItem>[];

    for (final item in items) {
      final result = FactionShopService.evaluateUnlock(item, ref);
      if (result is FactionShopUnlockReady) {
        ready.add(item);
      } else if (result is FactionShopUnlockSoldOut) {
        soldOut.add(item);
      } else {
        locked.add(item);
      }
    }

    // staticData.items에서 itemId → 표시명 조회 헬퍼
    String resolveItemName(String itemId) {
      final found = staticData.items.where((i) => i.id == itemId).firstOrNull;
      return found?.name ?? itemId;
    }

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('세력 상점', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (ready.isNotEmpty) ...[
              Text('구매 가능', style: theme.textTheme.labelMedium),
              for (final item in ready)
                _ShopItemRow(
                  item: item,
                  displayName: resolveItemName(item.itemId),
                  status: 'ready',
                ),
            ],
            if (locked.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('조건 미충족', style: theme.textTheme.labelMedium),
              for (final item in locked)
                _ShopItemRow(
                  item: item,
                  displayName: resolveItemName(item.itemId),
                  status: 'locked',
                ),
            ],
            if (soldOut.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('재고 소진', style: theme.textTheme.labelMedium),
              for (final item in soldOut)
                _ShopItemRow(
                  item: item,
                  displayName: resolveItemName(item.itemId),
                  status: 'sold_out',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopItemRow extends ConsumerWidget {
  final FactionShopItem item;
  final String displayName;
  final String status;

  const _ShopItemRow({
    required this.item,
    required this.displayName,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(displayName, style: theme.textTheme.bodySmall),
          ),
          Text('${item.priceGold}G', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          if (status == 'ready')
            TextButton(
              onPressed: () async {
                try {
                  await FactionShopService.purchase(item, ref);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매 완료')),
                    );
                  }
                } on StateError catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('구매 실패: ${e.message}')),
                    );
                  }
                }
              },
              child: const Text('구매'),
            )
          else
            const Text('—'),
        ],
      ),
    );
  }
}
