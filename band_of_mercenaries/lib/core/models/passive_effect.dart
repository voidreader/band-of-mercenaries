import 'package:freezed_annotation/freezed_annotation.dart';

part 'passive_effect.freezed.dart';

/// 세력/명성 랭크에서 파생되는 패시브 효과를 표현하는 sealed class.
/// JSON 역직렬화는 type discriminator 기반 수동 switch.
/// toJson은 제공하지 않음 — 앱이 PassiveEffect를 DB에 직렬화하지 않으므로 불필요.
@freezed
sealed class PassiveEffect with _$PassiveEffect {
  const factory PassiveEffect.questRewardMultiplier({
    required String questType,
    required double value,
  }) = QuestRewardMultiplierEffect;

  const factory PassiveEffect.questSuccessRateBonus({
    required String questType,
    required double value,
  }) = QuestSuccessRateBonusEffect;

  const factory PassiveEffect.questSuccessRateBonusPartySize({
    required int minPartySize,
    required double value,
  }) = QuestSuccessRateBonusPartySizeEffect;

  const factory PassiveEffect.recoveryTimeReduction({
    required String status,
    required double value,
  }) = RecoveryTimeReductionEffect;

  const factory PassiveEffect.travelEventMitigation({
    required String eventType,
    required double value,
  }) = TravelEventMitigationEffect;

  const factory PassiveEffect.investigationSuccessRateBonus({
    required double value,
  }) = InvestigationSuccessRateBonusEffect;

  const factory PassiveEffect.traitAcquisitionConditionRelief({
    required double value,
  }) = TraitAcquisitionConditionReliefEffect;

  const factory PassiveEffect.traitEvolutionConditionRelief({
    required double value,
  }) = TraitEvolutionConditionReliefEffect;

  /// stub — 현재 미사용, 향후 카테고리 트레잇 해금 기능용
  const factory PassiveEffect.traitUnlockCategory({
    required String categoryKey,
  }) = TraitUnlockCategoryEffect;

  const factory PassiveEffect.facilityCostReduction({
    required String costType,
    required double value,
  }) = FacilityCostReductionEffect;

  const factory PassiveEffect.facilityEffectBonus({
    String? facilityId,
    required double value,
  }) = FacilityEffectBonusEffect;

  const factory PassiveEffect.recruitmentCostReduction({
    required double value,
  }) = RecruitmentCostReductionEffect;

  const factory PassiveEffect.recruitmentTierBoost({
    required int tierMin,
    required int tierMax,
    required double value,
  }) = RecruitmentTierBoostEffect;

  const factory PassiveEffect.idleRewardBonus({
    required String bonusType,
    required double value,
  }) = IdleRewardBonusEffect;

  const factory PassiveEffect.mercenaryXpBonus({
    required double value,
  }) = MercenaryXpBonusEffect;

  const factory PassiveEffect.dispatchSlotBonus({
    required int value,
  }) = DispatchSlotBonusEffect;

  /// 미지원 type에 대한 fallback — 앱 다운그레이드 호환 보장
  const factory PassiveEffect.unknown({
    required String rawType,
  }) = UnknownPassiveEffect;

  /// JSON 원소(`{"type": "...", ...}`)를 variant로 파싱.
  /// 미지원 type 또는 파싱 실패 시 [PassiveEffect.unknown]을 반환.
  static PassiveEffect fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return const PassiveEffect.unknown(rawType: '');

    double dbl(String key) => (json[key] as num?)?.toDouble() ?? 0.0;
    int integer(String key) => (json[key] as num?)?.toInt() ?? 0;
    String str(String key) => json[key] as String? ?? '';

    switch (type) {
      case 'quest_reward_multiplier':
        return PassiveEffect.questRewardMultiplier(
          questType: str('quest_type'),
          value: dbl('value'),
        );
      case 'quest_success_rate_bonus':
        return PassiveEffect.questSuccessRateBonus(
          questType: str('quest_type'),
          value: dbl('value'),
        );
      case 'quest_success_rate_bonus_party_size':
        return PassiveEffect.questSuccessRateBonusPartySize(
          minPartySize: integer('min_party_size'),
          value: dbl('value'),
        );
      case 'recovery_time_reduction':
        return PassiveEffect.recoveryTimeReduction(
          status: str('status'),
          value: dbl('value'),
        );
      case 'travel_event_mitigation':
        return PassiveEffect.travelEventMitigation(
          eventType: str('event_type'),
          value: dbl('value'),
        );
      case 'investigation_success_rate_bonus':
        return PassiveEffect.investigationSuccessRateBonus(
          value: dbl('value'),
        );
      case 'trait_acquisition_condition_relief':
        return PassiveEffect.traitAcquisitionConditionRelief(
          value: dbl('value'),
        );
      case 'trait_evolution_condition_relief':
        return PassiveEffect.traitEvolutionConditionRelief(
          value: dbl('value'),
        );
      case 'trait_unlock_category':
        return PassiveEffect.traitUnlockCategory(
          categoryKey: str('category_key'),
        );
      case 'facility_cost_reduction':
        return PassiveEffect.facilityCostReduction(
          costType: str('cost_type'),
          value: dbl('value'),
        );
      case 'facility_effect_bonus':
        return PassiveEffect.facilityEffectBonus(
          facilityId: json['facility_id'] as String?,
          value: dbl('value'),
        );
      case 'recruitment_cost_reduction':
        return PassiveEffect.recruitmentCostReduction(value: dbl('value'));
      case 'recruitment_tier_boost':
        return PassiveEffect.recruitmentTierBoost(
          tierMin: integer('tier_min'),
          tierMax: integer('tier_max'),
          value: dbl('value'),
        );
      case 'idle_reward_bonus':
        return PassiveEffect.idleRewardBonus(
          bonusType: str('bonus_type'),
          value: dbl('value'),
        );
      case 'mercenary_xp_bonus':
        return PassiveEffect.mercenaryXpBonus(value: dbl('value'));
      case 'dispatch_slot_bonus':
        return PassiveEffect.dispatchSlotBonus(value: integer('value'));
      default:
        return PassiveEffect.unknown(rawType: type);
    }
  }

  /// `{"effects": [...]}` 컨테이너에서 [List<PassiveEffect>] 파싱.
  /// bonusJson이 null이거나 effects 키가 없으면 빈 리스트 반환.
  static List<PassiveEffect> parseEffects(Map<String, dynamic> bonusJson) {
    final rawList = bonusJson['effects'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PassiveEffect.fromJson)
        .toList(growable: false);
  }
}
