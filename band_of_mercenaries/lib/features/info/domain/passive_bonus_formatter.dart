import 'package:band_of_mercenaries/core/models/passive_effect.dart';

/// PassiveEffect 리스트를 한국어 표시 문자열로 변환하는 포맷터.
class PassiveBonusFormatter {
  /// bonus_json 컨테이너에서 effects를 파싱 후 각 줄을 한국어로 변환하여 "\n" join.
  /// 모든 effect가 unknown이거나 빈 배열이면 빈 문자열 반환.
  static String describe(Map<String, dynamic> bonusJson) {
    final effects = PassiveEffect.parseEffects(bonusJson);
    final lines = effects
        .map(describeEffect)
        .where((s) => s.isNotEmpty)
        .toList();
    return lines.join('\n');
  }

  /// 단일 PassiveEffect → 한국어 문자열. unknown variant는 빈 문자열 반환.
  static String describeEffect(PassiveEffect effect) {
    return switch (effect) {
      QuestRewardMultiplierEffect(:final questType, :final value) =>
        '${_questTypeKo(questType)} 퀘스트 보상 ${_pctPlus(value)}',
      QuestSuccessRateBonusEffect(:final questType, :final value) =>
        '${_questTypeKo(questType)} 퀘스트 성공률 ${_ppPlus(value)}',
      QuestSuccessRateBonusPartySizeEffect(:final minPartySize, :final value) =>
        '$minPartySize명 이상 파견 시 성공률 ${_ppPlus(value)}',
      RecoveryTimeReductionEffect(:final status, :final value) =>
        '${_statusKo(status)} 회복 시간 ${_pctMinus(value)}',
      TravelEventMitigationEffect(:final eventType, :final value) =>
        '이동 ${_eventKo(eventType)} ${_pctMinus(value)}',
      InvestigationSuccessRateBonusEffect(:final value) =>
        '지역 조사 성공률 ${_ppPlus(value)}',
      TraitAcquisitionConditionReliefEffect(:final value) =>
        '트레잇 획득 조건 완화 ${_pctMinus(value)}',
      TraitEvolutionConditionReliefEffect(:final value) =>
        '트레잇 진화 조건 완화 ${_pctMinus(value)}',
      TraitUnlockCategoryEffect(:final categoryKey) =>
        '$categoryKey 카테고리 트레잇 해금',
      FacilityCostReductionEffect(:final costType, :final value) =>
        '시설 ${_costTypeKo(costType)} ${_pctMinus(value)}',
      FacilityEffectBonusEffect(:final facilityId, :final value) =>
        facilityId == null
            ? '모든 시설 효과 ${_pctPlus(value)}'
            : '$facilityId 시설 효과 ${_pctPlus(value)}',
      RecruitmentCostReductionEffect(:final value) =>
        '용병 모집 비용 ${_pctMinus(value)}',
      RecruitmentTierBoostEffect(:final tierMin, :final tierMax, :final value) =>
        'T$tierMin~T$tierMax 용병 모집 확률 ${_ppPlus(value)}',
      IdleRewardBonusEffect(:final bonusType, :final value) =>
        bonusType == 'rate'
            ? '방치 보상 ${_pctPlus(value)}'
            : '방치 보상 상한 +${value.toStringAsFixed(0)}G',
      MercenaryXpBonusEffect(:final value) =>
        '용병 경험치 ${_pctPlus(value)}',
      DispatchSlotBonusEffect(:final value) =>
        '파견 슬롯 +$value',
      UnknownPassiveEffect() => '',
    };
  }

  /// 비율(0.12) → "+12%"
  static String _pctPlus(double value) {
    final pct = (value * 100).toStringAsFixed(0);
    return value >= 0 ? '+$pct%' : '$pct%';
  }

  /// 비율(0.15) → "-15%" (감소 효과용)
  static String _pctMinus(double value) {
    final pct = (value * 100).toStringAsFixed(0);
    return '-$pct%';
  }

  /// 비율(0.05) → "+5%p" (성공률 가산)
  static String _ppPlus(double value) {
    final pp = (value * 100).toStringAsFixed(0);
    return value >= 0 ? '+$pp%p' : '$pp%p';
  }

  static String _questTypeKo(String type) {
    return const {
      'raid': '약탈',
      'hunt': '토벌',
      'escort': '호위',
      'explore': '탐험',
      'all': '모든',
    }[type] ?? type;
  }

  static String _statusKo(String status) {
    return const {
      'injured': '부상',
      'tired': '피로',
      'fatigued': '피곤',
      'all': '모든 상태',
    }[status] ?? status;
  }

  static String _eventKo(String type) {
    return const {
      'gold_loss': '골드 손실',
      'damage': '피해',
      'all': '이벤트',
    }[type] ?? type;
  }

  static String _costTypeKo(String type) {
    return const {
      'gold': '건설 비용',
      'time': '건설 시간',
    }[type] ?? type;
  }
}
