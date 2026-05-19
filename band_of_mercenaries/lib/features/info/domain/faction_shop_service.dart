import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';

import 'faction_contact_service.dart';
import 'faction_shop_daily_entry.dart';
import 'faction_shop_item_data.dart';
import 'faction_shop_unlock_result.dart';

/// M8a 세력 상점 평가/구매 헬퍼 (FR-D2 / FR-D3)
class FactionShopService {
  const FactionShopService._();

  /// 6단계 순차 해금 평가 (FR-D2). 어느 단계든 종결 결과를 반환하면 평가 즉시 종료.
  static FactionShopUnlockResult evaluateUnlock(
    FactionShopItem item,
    WidgetRef ref,
  ) {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) {
      return const FactionShopUnlockLocked('static_data_unavailable');
    }

    // 0. unknown_item 가드 — staticData.items에 itemId가 없으면 데이터 오류
    final hasItem = staticData.items.any((i) => i.id == item.itemId);
    if (!hasItem) {
      return const FactionShopUnlockLocked('unknown_item');
    }

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final state = factionRepo.getState(item.factionId);
    final reputation = state?.currentReputation ?? 0;
    final isJoined = state?.isJoined ?? false;

    // 1. 가입 요구 검사
    if (item.requiresJoined && !isJoined) {
      return const FactionShopUnlockLocked('not_joined');
    }

    // 2. 최소 평판 검사
    if (reputation < item.minReputation) {
      return FactionShopUnlockLocked('reputation:${item.minReputation}');
    }

    // 3. unlockType 분기 평가
    final type = item.unlockType;
    final value = item.unlockValue;
    if (type != null && value != null) {
      switch (type) {
        case 'faction_contact':
          if (!FactionContactService.isActive(value, ref)) {
            return FactionShopUnlockLocked('contact:$value');
          }
          break;
        case 'region_flag':
          final regionRepo = ref.read(regionStateRepositoryProvider);
          final regions = staticData.regions;
          var matched = false;
          for (final r in regions) {
            final regionState = regionRepo.getState(r.region);
            final flags = regionState?.unlockedFlags ?? const <String>[];
            if (flags.contains(value)) {
              matched = true;
              break;
            }
          }
          if (!matched) {
            return FactionShopUnlockLocked('region_flag:$value');
          }
          break;
        case 'faction_reputation':
          // 'faction_<id>>=<int>' 파싱
          final parsed = _parseFactionRepCondition(value);
          if (parsed != null) {
            final otherState = factionRepo.getState(parsed.factionId);
            final otherRep = otherState?.currentReputation ?? 0;
            if (otherRep < parsed.threshold) {
              return FactionShopUnlockLocked('reputation:${parsed.threshold}');
            }
          }
          break;
        default:
          // 기타/null/파싱 실패 — 다음 step으로 진행
          break;
      }
    }

    // 4. once 재고 검사
    if (item.stockPolicy == 'once') {
      final history =
          state?.effectiveShopPurchaseHistory ?? const <String, bool>{};
      if (history[item.itemId] == true) {
        return const FactionShopUnlockSoldOut(null);
      }
    }

    // 5. daily 재고 검사
    if (item.stockPolicy == 'daily') {
      final daily =
          state?.effectiveShopDailyPurchases ??
          const <String, FactionShopDailyEntry>{};
      final entry = daily[item.itemId];
      if (entry != null) {
        final now = DateTime.now();
        final restockAt = entry.restockAt;
        if (restockAt != null && restockAt.isAfter(now)) {
          if (entry.count >= item.stockLimit) {
            return FactionShopUnlockSoldOut(restockAt);
          }
        }
        // restockAt 지났거나 null이면 reset 의미 (영속 저장은 purchase 시점)
      }
    }

    // 6. 모두 통과
    return const FactionShopUnlockReady();
  }

  /// 5단계 구매 절차 (FR-D3). evaluateUnlock Ready 확인 → 골드 차감 → addItem → 영속 갱신 → ActivityLog.
  static Future<void> purchase(FactionShopItem item, WidgetRef ref) async {
    final result = evaluateUnlock(item, ref);
    if (result is! FactionShopUnlockReady) {
      throw StateError('not_ready');
    }

    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < item.priceGold) {
      throw StateError('insufficient_gold');
    }

    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) {
      throw StateError('static_data_unavailable');
    }

    await ref.read(userDataProvider.notifier).addGold(-item.priceGold);

    await ref
        .read(inventoryRepositoryProvider)
        .addItem(itemId: item.itemId, quantity: 1, items: staticData.items);

    final isDaily = item.stockPolicy == 'daily';
    final restockHours = item.restockHours;
    final restockAfter = (restockHours != null && restockHours > 0)
        ? Duration(hours: restockHours)
        : null;
    await ref
        .read(factionStateRepositoryProvider)
        .recordShopPurchase(
          factionId: item.factionId,
          itemId: item.itemId,
          isDaily: isDaily,
          restockAfter: restockAfter,
        );

    ref
        .read(activityLogProvider.notifier)
        .addLog(
          '${item.factionId} 상점에서 ${item.itemId} 구매 (${item.priceGold}G)',
          ActivityLogType.factionShopPurchased,
        );
  }

  static _FactionRepCondition? _parseFactionRepCondition(String value) {
    // 'faction_<id>>=<int>' 형식. 예: 'faction_merchants_alliance>=31'
    final regex = RegExp(r'^(faction_[a-z_]+)>=(\-?\d+)$');
    final m = regex.firstMatch(value);
    if (m == null) return null;
    final id = m.group(1);
    final group2 = m.group(2);
    if (id == null || group2 == null) return null;
    final n = int.tryParse(group2);
    if (n == null) return null;
    return _FactionRepCondition(id, n);
  }
}

class _FactionRepCondition {
  final String factionId;
  final int threshold;
  const _FactionRepCondition(this.factionId, this.threshold);
}
