import '../../../core/models/item_data.dart';
import '../../../core/models/passive_effect.dart';
import 'equipment_stat_bonus.dart';
import 'inventory_item_model.dart';
import 'legendary_effect.dart';
import 'personal_equipment_effect.dart';

/// 아이템의 `effect_json`을 카테고리·슬롯에 따라 구조화된 값 객체로 변환하는 순수 정적 서비스.
///
/// 파싱 실패 또는 카테고리 불일치 시 빈 값을 반환한다(fail-soft).
class ItemEffectService {
  ItemEffectService._();

  // ─── 개인 장비 ───────────────────────────────────────────────

  /// 개인 장비([ItemData]) 1개를 파싱하여 스탯 보정 + 전설 유니크 효과를 반환한다.
  ///
  /// - category != `'personal_equipment'`이거나 effectJson이 비어있으면 [PersonalEquipmentEffect.zero] 반환.
  /// - 스탯 키: `str`, `intelligence`, `vit`, `agi`.
  /// - 전설 필드: `legendary_effect.category` 기반으로 [LegendaryEffect.fromJson] 호출.
  static PersonalEquipmentEffect resolvePersonalEquipment(ItemData item) {
    if (item.category != 'personal_equipment') {
      return PersonalEquipmentEffect.zero;
    }
    final json = item.effectJson;
    if (json.isEmpty) return PersonalEquipmentEffect.zero;

    // 4개 스탯 키를 순회하여 보정값을 수집한다.
    final statBonus = EquipmentStatBonus(
      str: (json['str'] as num?)?.toInt() ?? 0,
      intelligence: (json['intelligence'] as num?)?.toInt() ?? 0,
      vit: (json['vit'] as num?)?.toInt() ?? 0,
      agi: (json['agi'] as num?)?.toInt() ?? 0,
    );

    // 전설 효과 파싱 — 필드가 없거나 파싱 실패 시 null.
    LegendaryEffect? legendary;
    final legendaryJson = json['legendary_effect'];
    if (legendaryJson is Map<String, dynamic>) {
      legendary = LegendaryEffect.fromJson(legendaryJson);
    }

    return PersonalEquipmentEffect(statBonus: statBonus, legendary: legendary);
  }

  // ─── 용병단 장비 ──────────────────────────────────────────────

  /// 용병단 장비([ItemData]) 1개를 파싱하여 거시 지표 [PassiveEffect] 리스트로 변환한다.
  ///
  /// - category != `'guild_equipment'`이거나 effectJson이 비어있으면 빈 리스트 반환.
  /// - 지원 키: `gold_reward_multiplier`, `recruit_high_tier_chance`,
  ///   `injury_rate_modifier`, `reputation_gain_modifier`.
  /// - 알 수 없는 키는 무시한다(fail-soft).
  /// - 복합 효과(여러 키 보유) 시 각 키마다 별도 [PassiveEffect]를 리스트에 추가한다.
  static List<PassiveEffect> resolveGuildEquipment(ItemData item) {
    if (item.category != 'guild_equipment') return const [];
    final json = item.effectJson;
    if (json.isEmpty) return const [];

    final effects = <PassiveEffect>[];

    for (final entry in json.entries) {
      final key = entry.key;
      final rawValue = entry.value;
      final value = (rawValue as num?)?.toDouble();
      if (value == null) continue;

      switch (key) {
        case 'gold_reward_multiplier':
          effects.add(PassiveEffect.questRewardMultiplier(
            questType: 'all',
            value: value,
          ));
        case 'recruit_high_tier_chance':
          effects.add(PassiveEffect.recruitmentTierBoost(
            tierMin: 4,
            tierMax: 5,
            value: value,
          ));
        case 'injury_rate_modifier':
          effects.add(PassiveEffect.injuryRateModifier(value: value));
        case 'reputation_gain_modifier':
          effects.add(PassiveEffect.reputationGainModifier(value: value));
        default:
          // 알 수 없는 키 — 무시(fail-soft).
          break;
      }
    }

    return effects;
  }

  // ─── 용병 장비 합산 ───────────────────────────────────────────

  /// 특정 용병([mercenaryId])에게 장착된 개인 장비 전체의 스탯 보정을 합산한다.
  ///
  /// 인벤토리에서 [mercenaryId]가 장착자로 등록된 아이템만 필터링한 후
  /// [resolvePersonalEquipment]로 개별 파싱하고 `+` 연산자로 누적한다.
  /// 매칭되는 [ItemData]가 없으면 해당 아이템을 skip한다.
  static EquipmentStatBonus aggregateMercenaryEquipment({
    required String mercenaryId,
    required List<InventoryItem> inventory,
    required List<ItemData> items,
  }) {
    var total = EquipmentStatBonus.zero;

    // itemId → ItemData 조회 맵 구성.
    final itemMap = {for (final item in items) item.id: item};

    for (final inv in inventory) {
      if (inv.equippedTo != mercenaryId) continue;
      final itemData = itemMap[inv.itemId];
      if (itemData == null) continue;
      total = total + resolvePersonalEquipment(itemData).statBonus;
    }

    return total;
  }

  /// 특정 용병([mercenaryId])에게 장착된 개인 장비 전체의 전설 유니크 효과 목록을 수집한다.
  ///
  /// legendary가 null인 아이템은 skip한다.
  static List<LegendaryEffect> collectLegendaryEffects({
    required String mercenaryId,
    required List<InventoryItem> inventory,
    required List<ItemData> items,
  }) {
    final result = <LegendaryEffect>[];
    final itemMap = {for (final item in items) item.id: item};

    for (final inv in inventory) {
      if (inv.equippedTo != mercenaryId) continue;
      final itemData = itemMap[inv.itemId];
      if (itemData == null) continue;
      final legendary = resolvePersonalEquipment(itemData).legendary;
      if (legendary != null) result.add(legendary);
    }

    return result;
  }

  // ─── 용병단 장비 수집 ─────────────────────────────────────────

  /// 용병단 장비(banner + artifacts)에서 [PassiveEffect] 리스트를 수집한다.
  ///
  /// - [bannerItemId]가 null이면 배너 효과는 skip한다.
  /// - [artifactItemIds]에서 존재하지 않는 id는 skip한다.
  /// - 내부적으로 [resolveGuildEquipment]를 호출하여 각 아이템의 효과를 수집한다.
  static List<PassiveEffect> collectGuildPassiveEffects({
    required String? bannerItemId,
    required List<String> artifactItemIds,
    required List<ItemData> items,
  }) {
    final result = <PassiveEffect>[];
    final itemMap = {for (final item in items) item.id: item};

    // 배너 효과 수집.
    if (bannerItemId != null) {
      final banner = itemMap[bannerItemId];
      if (banner != null) {
        result.addAll(resolveGuildEquipment(banner));
      }
    }

    // 아티팩트 효과 순차 수집.
    for (final artifactId in artifactItemIds) {
      final artifact = itemMap[artifactId];
      if (artifact == null) continue;
      result.addAll(resolveGuildEquipment(artifact));
    }

    return result;
  }
}
