import 'package:band_of_mercenaries/core/models/passive_effect.dart';

/// PassiveEffect 17 variant를 한국어 사용자 표시 문자열로 변환한다.
/// 랭크업 오버레이, 보너스 요약 시트 등 UI 컴포넌트에서 재사용.
class PassiveBonusFormatter {
  static const Map<String, String> _questTypeNames = {
    'raid': '약탈',
    'hunt': '사냥',
    'escort': '호위',
    'explore': '탐험',
    'all': '전',
  };

  static const Map<String, String> _statusNames = {
    'tired': '피로',
    'injured': '부상',
    'all': '전',
  };

  static const Map<String, String> _costTypeNames = {
    'gold': '골드',
    'time': '시간',
    'all': '전체',
  };

  static const Map<String, String> _travelEventNames = {
    'bandit': '습격',
    'weather': '기상',
    'encounter': '조우',
    'lucky': '행운',
    'all': '전',
  };

  static String _questTypeName(String key) => _questTypeNames[key] ?? key;
  static String _statusName(String key) => _statusNames[key] ?? key;
  static String _costTypeName(String key) => _costTypeNames[key] ?? key;
  static String _travelEventName(String key) => _travelEventNames[key] ?? key;
  static String _facilityName(String? id) =>
      id == null || id.isEmpty ? '전 시설' : id;

  /// 비율(0.03 → +3%) 포맷. 양수는 + 부호.
  static String _pct(double value) {
    final rounded = (value * 100).round();
    final sign = rounded > 0 ? '+' : '';
    return '$sign$rounded%';
  }

  /// %p 포맷 (동일하지만 표시 용도 구분).
  static String _pp(double value) {
    final rounded = (value * 100).round();
    final sign = rounded > 0 ? '+' : '';
    return '$sign$rounded%p';
  }

  /// 감소 비율(양수 값)을 "-X%"로 포맷. 음수 방어.
  static String _reductionPct(double value) {
    final rounded = (value.abs() * 100).round();
    return '-$rounded%';
  }

  static String format(PassiveEffect e) {
    return switch (e) {
      QuestRewardMultiplierEffect(:final questType, :final value) =>
        '${_questTypeName(questType)} 퀘스트 보상 ${_pct(value)}',
      QuestSuccessRateBonusEffect(:final questType, :final value) =>
        '${_questTypeName(questType)} 퀘스트 성공률 ${_pp(value)}',
      QuestSuccessRateBonusPartySizeEffect(
        :final minPartySize,
        :final value,
      ) =>
        '파티원 $minPartySize명 이상 시 성공률 ${_pp(value)}',
      RecoveryTimeReductionEffect(:final status, :final value) =>
        '${_statusName(status)} 회복 시간 ${_reductionPct(value)}',
      TravelEventMitigationEffect(:final eventType, :final value) =>
        '이동 이벤트(${_travelEventName(eventType)}) 피해 ${_reductionPct(value)}',
      InvestigationSuccessRateBonusEffect(:final value) =>
        '지역 조사 성공률 ${_pp(value)}',
      TraitAcquisitionConditionReliefEffect(:final value) =>
        '트레잇 획득 조건 ${_reductionPct(value)}',
      TraitEvolutionConditionReliefEffect(:final value) =>
        '트레잇 진화 조건 ${_reductionPct(value)}',
      TraitUnlockCategoryEffect(:final categoryKey) =>
        '트레잇 카테고리 해금: $categoryKey',
      FacilityCostReductionEffect(:final costType, :final value) =>
        '시설 ${_costTypeName(costType)} 비용 ${_reductionPct(value)}',
      FacilityEffectBonusEffect(:final facilityId, :final value) =>
        '${_facilityName(facilityId)} 효과 ${_pct(value)}',
      RecruitmentCostReductionEffect(:final value) =>
        '모집 비용 ${_reductionPct(value)}',
      RecruitmentTierBoostEffect(
        :final tierMin,
        :final tierMax,
        :final value,
      ) =>
        'T$tierMin~T$tierMax 모집 확률 ${_pp(value)}',
      IdleRewardBonusEffect(:final bonusType, :final value) =>
        _formatIdleRewardBonus(bonusType, value),
      MercenaryXpBonusEffect(:final value) => '용병 경험치 ${_pct(value)}',
      DispatchSlotBonusEffect(:final value) => '파견 슬롯 +$value',
      InjuryRateModifierEffect(:final value) => '부상률 ${_pct(value)}',
      ReputationGainModifierEffect(:final value) => '명성 획득 ${_pct(value)}',
      UnknownPassiveEffect() => '',
    };
  }

  /// features/info 버전과의 호환성 유지. [format]의 alias.
  static String describeEffect(PassiveEffect e) => format(e);

  /// bonus_json 컨테이너에서 effects를 파싱 후 각 줄을 한국어로 변환하여 "\n" join.
  /// 모든 effect가 unknown이거나 빈 배열이면 빈 문자열 반환.
  static String describe(Map<String, dynamic> bonusJson) {
    final effects = PassiveEffect.parseEffects(bonusJson);
    final lines =
        effects.map(format).where((s) => s.isNotEmpty).toList();
    return lines.join('\n');
  }

  static String _formatIdleRewardBonus(String bonusType, double value) {
    switch (bonusType) {
      case 'rate':
        return '방치 보상 rate ${_pct(value)}';
      case 'cap':
        final gold = value.round();
        final sign = gold > 0 ? '+' : '';
        return '방치 보상 상한 $sign${gold}G';
      default:
        return '방치 보상($bonusType) ${_pct(value)}';
    }
  }
}
