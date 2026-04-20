import 'package:freezed_annotation/freezed_annotation.dart';

part 'legendary_effect.freezed.dart';

/// 전설 유니크 아이템의 특수 효과를 표현하는 sealed class.
/// `effect_json.legendary_effect.category` discriminator 기반으로 5 variant를 분기한다.
@freezed
sealed class LegendaryEffect with _$LegendaryEffect {
  /// ① 특정 퀘스트 유형 성공률 보정.
  const factory LegendaryEffect.successRateBonus({
    required String questType,
    required double value,
  }) = LegendarySuccessRateBonus;

  /// ② 성공 → 대성공 승격 확률.
  const factory LegendaryEffect.resultUpgrade({
    required double chance,
  }) = LegendaryResultUpgrade;

  /// ③ 부상률·사망률 수정 (가산).
  const factory LegendaryEffect.damageResistance({
    required double injuryMod,
    required double deathMod,
  }) = LegendaryDamageResistance;

  /// ④ 골드 보상 배율 가산.
  const factory LegendaryEffect.rewardBonus({
    required double multiplier,
  }) = LegendaryRewardBonus;

  /// ⑤ 사망 방지 (쿨다운 포함).
  const factory LegendaryEffect.special({
    required int deathPreventionCount,
    required int cooldownHours,
  }) = LegendarySpecial;

  /// [json]의 `category` 필드를 기준으로 variant를 생성한다.
  /// 지원하지 않는 category 또는 파싱 실패 시 null을 반환한다 (fail-soft).
  static LegendaryEffect? fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    if (category == null) return null;

    switch (category) {
      case 'success_rate_bonus':
        // 4개 퀘스트 유형 키 중 존재하는 1개를 탐색한다.
        const successRateKeys = [
          'raid_success_rate',
          'hunt_success_rate',
          'escort_success_rate',
          'explore_success_rate',
        ];
        for (final key in successRateKeys) {
          if (json.containsKey(key)) {
            final questType = key.replaceAll('_success_rate', '');
            final value = (json[key] as num?)?.toDouble() ?? 0.0;
            return LegendaryEffect.successRateBonus(
              questType: questType,
              value: value,
            );
          }
        }
        return null;

      case 'result_upgrade':
        return LegendaryEffect.resultUpgrade(
          chance:
              (json['success_to_great_chance'] as num?)?.toDouble() ?? 0.0,
        );

      case 'damage_resistance':
        return LegendaryEffect.damageResistance(
          injuryMod:
              (json['injury_rate_modifier'] as num?)?.toDouble() ?? 0.0,
          deathMod:
              (json['death_rate_modifier'] as num?)?.toDouble() ?? 0.0,
        );

      case 'reward_bonus':
        return LegendaryEffect.rewardBonus(
          multiplier:
              (json['gold_reward_multiplier'] as num?)?.toDouble() ?? 0.0,
        );

      case 'special':
        return LegendaryEffect.special(
          deathPreventionCount:
              (json['death_prevention_count'] as num?)?.toInt() ?? 0,
          cooldownHours:
              (json['cooldown_hours'] as num?)?.toInt() ?? 24,
        );

      default:
        return null;
    }
  }
}
