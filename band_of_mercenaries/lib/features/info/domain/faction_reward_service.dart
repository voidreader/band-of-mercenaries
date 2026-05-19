// features/info/domain/faction_reward_service.dart
// FR-E5: 세력 아이템 보상 자동 1회 지급 헬퍼.
// MVP에서는 내부 정적 상수 Map 2 factionId × 1 entry 하드코딩 (planner Q-2 default).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';

/// M8a 세력 아이템 보상 자동 지급 헬퍼 (FR-E5).
///
/// 평판 임계값 + region flag(있을 경우) 충족 시 grantedRewardIds dedup 후 1회 지급.
/// MVP에서는 내부 정적 상수 Map으로 하드코딩 (Q-2 default).
class FactionRewardService {
  const FactionRewardService._();

  /// M8a 세력 아이템 보상 정의 (factionId → 보상 entry 목록)
  static const Map<String, List<_RewardEntry>> _rewardsByFaction = {
    'faction_merchants_alliance': [
      _RewardEntry(
        rewardId: 'reward_m8a_mer_item_warrant',
        itemId: 'guild_artifact_merchant_warrant',
        minReputation: 31,
        requiredRegionId: null,
        requiredFlag: null,
      ),
    ],
    'faction_warriors_guild': [
      _RewardEntry(
        rewardId: 'reward_m8a_war_item_wristwrap',
        itemId: 'equip_accessory_red_spear_wristwrap',
        minReputation: 61,
        requiredRegionId: 38,
        requiredFlag: 'region_38_ironbound_pact_completed',
      ),
    ],
  };

  /// 세력 평판 변경 후 trailing hook으로 호출되어 아이템 보상 자동 1회 지급 (FR-E5).
  ///
  /// 조건: 평판 임계 도달 AND (requiredFlag 미존재 OR 해당 region.unlockedFlags 포함) AND
  /// `FactionState.grantedRewardIds`에 미존재.
  /// 지급 시 addItem + markRewardGranted + ActivityLog (factionRewardGranted).
  /// 실패는 fail-soft (호출자 try/catch 책임).
  static Future<void> grantItemRewardIfEligible({
    required String factionId,
    required int newRep,
    required WidgetRef ref,
  }) async {
    await _grantInternal(factionId: factionId, newRep: newRep, ref: ref);
  }

  /// FR-E5 — Provider 계층(quest_provider 등)에서 [Ref]로 호출하기 위한 변형.
  ///
  /// 동작은 [grantItemRewardIfEligible]과 동일하며 ref 타입만 다르다.
  static Future<void> grantItemRewardIfEligibleFromProviderRef({
    required String factionId,
    required int newRep,
    required Ref<Object?> ref,
  }) async {
    await _grantInternal(factionId: factionId, newRep: newRep, ref: ref);
  }

  /// WidgetRef / Ref 양쪽에서 위임하는 내부 공용 로직.
  /// dynamic 사용은 두 ref 타입이 모두 `read` 메서드를 공유하기 위한 절충.
  static Future<void> _grantInternal({
    required String factionId,
    required int newRep,
    required dynamic ref,
  }) async {
    final entries = _rewardsByFaction[factionId];
    if (entries == null || entries.isEmpty) return;

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final regionRepo = ref.read(regionStateRepositoryProvider);
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    // 한국어 ActivityLog 일관성: factionId/itemId raw ID 대신 정적 데이터의 이름 사용
    final factionName = staticData.factions
            .where((f) => f.id == factionId)
            .map((f) => f.name)
            .firstOrNull ??
        factionId;

    for (final entry in entries) {
      if (newRep < entry.minReputation) continue;

      final regionId = entry.requiredRegionId;
      final flag = entry.requiredFlag;
      if (regionId != null && flag != null) {
        final regionState = regionRepo.getState(regionId);
        final flags = regionState?.unlockedFlags ?? const <String>[];
        if (!flags.contains(flag)) continue;
      }

      final alreadyGranted = factionRepo.hasGrantedReward(
        factionId: factionId,
        rewardId: entry.rewardId,
      );
      if (alreadyGranted) continue;

      await ref.read(inventoryRepositoryProvider).addItem(
            itemId: entry.itemId,
            quantity: 1,
            items: staticData.items,
          );
      await factionRepo.markRewardGranted(
        factionId: factionId,
        rewardId: entry.rewardId,
      );
      final itemName = staticData.items
              .where((it) => it.id == entry.itemId)
              .map((it) => it.name)
              .firstOrNull ??
          entry.itemId;
      ref.read(activityLogProvider.notifier).addLog(
            '$factionName 보상 $itemName 획득',
            ActivityLogType.factionRewardGranted,
          );
    }
  }
}

class _RewardEntry {
  final String rewardId;
  final String itemId;
  final int minReputation;
  final int? requiredRegionId;
  final String? requiredFlag;

  const _RewardEntry({
    required this.rewardId,
    required this.itemId,
    required this.minReputation,
    required this.requiredRegionId,
    required this.requiredFlag,
  });
}

/// FR-E5 trailing hook 호출용 Provider (constructor-less helper, optional).
final factionRewardServiceProvider = Provider<FactionRewardServiceHelper>((ref) {
  return const FactionRewardServiceHelper();
});

/// Provider에서 인스턴스화 가능하도록 wrap한 헬퍼. 내부는 static 호출 위임.
class FactionRewardServiceHelper {
  const FactionRewardServiceHelper();

  Future<void> grantItemRewardIfEligible({
    required String factionId,
    required int newRep,
    required WidgetRef ref,
  }) async {
    await FactionRewardService.grantItemRewardIfEligible(
      factionId: factionId,
      newRep: newRep,
      ref: ref,
    );
  }
}
