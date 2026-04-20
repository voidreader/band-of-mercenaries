import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/features/inventory/domain/item_effect_service.dart';

/// Ref/WidgetRef 진입점에서 장비 효과를 일괄 수집하는 헬퍼.
/// PassiveBonusContext와 동일 스타일로 여러 Provider를 조합한다.
class EquipmentEffectContext {
  EquipmentEffectContext._();

  /// 용병 1명의 장비 스탯 보정 (비동기 — staticDataProvider가 미로드 상태일 때 await).
  static Future<EquipmentStatBonus> forMercenary(Ref ref, String mercId) async {
    final staticData = await ref.read(staticDataProvider.future);
    final inventory = ref.read(inventoryRepositoryProvider).getAll();
    return ItemEffectService.aggregateMercenaryEquipment(
      mercenaryId: mercId,
      inventory: inventory,
      items: staticData.items,
    );
  }

  /// 용병 1명의 전설 유니크 효과 리스트 (비동기).
  static Future<List<LegendaryEffect>> legendariesFor(Ref ref, String mercId) async {
    final staticData = await ref.read(staticDataProvider.future);
    final inventory = ref.read(inventoryRepositoryProvider).getAll();
    return ItemEffectService.collectLegendaryEffects(
      mercenaryId: mercId,
      inventory: inventory,
      items: staticData.items,
    );
  }

  /// 용병단 장비(banner + artifactItemIds) PassiveEffect 리스트 (비동기).
  static Future<List<PassiveEffect>> guildEquipmentEffects(Ref ref) async {
    final staticData = await ref.read(staticDataProvider.future);
    final userData = ref.read(userDataProvider);
    if (userData == null) return const [];
    return ItemEffectService.collectGuildPassiveEffects(
      bannerItemId: userData.bannerItemId,
      artifactItemIds: userData.artifactItemIds,
      items: staticData.items,
    );
  }

  /// 파티 전체의 mercId → EquipmentStatBonus 맵 (비동기).
  static Future<Map<String, EquipmentStatBonus>> forParty(
    Ref ref,
    List<String> mercIds,
  ) async {
    final staticData = await ref.read(staticDataProvider.future);
    final inventory = ref.read(inventoryRepositoryProvider).getAll();
    return {
      for (final id in mercIds)
        id: ItemEffectService.aggregateMercenaryEquipment(
          mercenaryId: id,
          inventory: inventory,
          items: staticData.items,
        ),
    };
  }

  /// 동기 버전 — UI 프리뷰용. staticDataProvider가 이미 로드된 상태에서만 정확한 값 반환.
  /// AsyncLoading/Error 시 EquipmentStatBonus.zero 반환 (fail-soft).
  static EquipmentStatBonus forMercenarySync(WidgetRef ref, String mercId) {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) return EquipmentStatBonus.zero;
    final inventory = ref.read(inventoryRepositoryProvider).getAll();
    return ItemEffectService.aggregateMercenaryEquipment(
      mercenaryId: mercId,
      inventory: inventory,
      items: staticData.items,
    );
  }

  /// 동기 파티 맵 버전 — UI 프리뷰용.
  static Map<String, EquipmentStatBonus> forPartySync(
    WidgetRef ref,
    List<String> mercIds,
  ) {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) {
      return {for (final id in mercIds) id: EquipmentStatBonus.zero};
    }
    final inventory = ref.read(inventoryRepositoryProvider).getAll();
    return {
      for (final id in mercIds)
        id: ItemEffectService.aggregateMercenaryEquipment(
          mercenaryId: id,
          inventory: inventory,
          items: staticData.items,
        ),
    };
  }
}
