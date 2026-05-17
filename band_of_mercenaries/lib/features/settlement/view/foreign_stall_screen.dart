import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_infrastructure_config.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_infrastructure_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/card_container.dart';

class ForeignStallScreen extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const ForeignStallScreen({super.key, required this.onClose});

  @override
  ConsumerState<ForeignStallScreen> createState() => _ForeignStallScreenState();
}

class _ForeignStallScreenState extends ConsumerState<ForeignStallScreen> {
  @override
  void initState() {
    super.initState();
    // 방문 카운트 +1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userDataProvider.notifier).incrementForeignStallVisit();
    });
  }

  static const Map<int, String> _greeting = {
    3: '외지 손님, 이런 변방까지 오느라 수고했네. 내가 가진 물건들을 한 번 보겠나?',
    4: '어서 오시오, 변방의 영주여. 이제 자네를 위해 따로 마련한 물건들이 있다네.',
  };

  static const List<String> _gossipTier3 = [
    '바람결에 도적길 소문이 들렸지. 자네 덕에 길이 잠잠해졌다더군.',
    '근방의 약초가 동나면 다음 달에나 새 물건이 들어올 걸세.',
  ];
  static const List<String> _gossipTier4 = [
    '외래 상인이 어떤 거대한 세력의 깃발을 본 것 같다는 풍문이 들리네.',
    '북쪽 산맥 너머에서 누군가 변방을 노리고 있다는 소문도 있어.',
  ];

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(settlementInfrastructureTierProvider(GameConstants.startingRegionId));
    final userData = ref.watch(userDataProvider);
    final greeting = _greeting[tier] ?? _greeting[3]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardContainer(
          padding: const EdgeInsets.all(14),
          child: Text(
            '🛒 $greeting',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(label: '재료 거래', onTap: () => _showTradeDialog(context, tier)),
        const SizedBox(height: 8),
        _ActionButton(label: '외래 소식 듣기', onTap: () => _showGossipDialog(context, tier)),
        const SizedBox(height: 8),
        _ActionButton(
          label: '방문 횟수 보기',
          onTap: () => _showVisitDialog(context, userData?.foreignStallVisitCount ?? 0),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('닫기', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  void _showTradeDialog(BuildContext context, int tier) {
    final varietyCap = tier >= 4
        ? SettlementInfrastructureConfig.foreignStallTier4VarietyCap
        : SettlementInfrastructureConfig.foreignStallTier3VarietyCap;
    final discount = tier >= 4 ? SettlementInfrastructureConfig.foreignStallTier4Discount : 1.0;
    final prices = SettlementInfrastructureConfig.foreignStallBasePrices.entries
        .take(varietyCap)
        .toList();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final staticData = ref.read(staticDataProvider).valueOrNull;
        return AlertDialog(
          title: const Text('재료 거래'),
          content: SizedBox(
            width: 320,
            child: ListView(
              shrinkWrap: true,
              children: prices.map((entry) {
                final itemId = entry.key;
                final price = (entry.value * discount).round();
                final itemName = staticData?.items
                        .where((i) => i.id == itemId)
                        .map((i) => i.name)
                        .firstOrNull ??
                    itemId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$itemName · ${price}G',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _purchase(ctx, itemId, price, itemName),
                        child: const Text('구매'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('닫기')),
          ],
        );
      },
    );
  }

  Future<void> _purchase(BuildContext ctx, String itemId, int price, String itemName) async {
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('골드 부족')));
      }
      return;
    }
    final inv = ref.read(inventoryRepositoryProvider);
    if (inv.getQuantityForItemId(itemId) >= 999) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보유량 가득')));
      }
      return;
    }
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) return;
    await ref.read(userDataProvider.notifier).spendGold(price);
    await inv.addItem(itemId: itemId, quantity: 1, items: staticData.items);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$itemName 구매 (${price}G)')));
    }
  }

  void _showGossipDialog(BuildContext context, int tier) {
    final pool = tier >= 4 ? _gossipTier4 : _gossipTier3;
    final text = pool[Random().nextInt(pool.length)];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('외래 소식'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
        ],
      ),
    );
  }

  void _showVisitDialog(BuildContext context, int count) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('방문 횟수'),
        content: Text('외래 좌판 누적 방문: $count회'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
