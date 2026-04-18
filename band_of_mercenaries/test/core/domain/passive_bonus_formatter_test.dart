import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';

void main() {
  group('PassiveBonusFormatter.format', () {
    test('QuestRewardMultiplierEffect all 0.03 → "전" + "+3%"', () {
      const e = PassiveEffect.questRewardMultiplier(
        questType: 'all',
        value: 0.03,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('전'));
      expect(s, contains('보상'));
      expect(s, contains('+3%'));
    });

    test('QuestRewardMultiplierEffect raid 0.05 → "약탈" 포함', () {
      const e = PassiveEffect.questRewardMultiplier(
        questType: 'raid',
        value: 0.05,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('약탈'));
      expect(s, contains('+5%'));
    });

    test('QuestSuccessRateBonusEffect all 0.03 → "성공률" + "+3%p"', () {
      const e = PassiveEffect.questSuccessRateBonus(
        questType: 'all',
        value: 0.03,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('성공률'));
      expect(s, contains('+3%p'));
    });

    test('QuestSuccessRateBonusPartySizeEffect → "파티원 3명 이상"', () {
      const e = PassiveEffect.questSuccessRateBonusPartySize(
        minPartySize: 3,
        value: 0.05,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('파티원'));
      expect(s, contains('3'));
      expect(s, contains('+5%p'));
    });

    test('RecoveryTimeReductionEffect injured 0.10 → "부상" + "-10%"', () {
      const e = PassiveEffect.recoveryTimeReduction(
        status: 'injured',
        value: 0.10,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('부상'));
      expect(s, contains('-10%'));
    });

    test('TravelEventMitigationEffect bandit 0.20 → "습격" 포함', () {
      const e = PassiveEffect.travelEventMitigation(
        eventType: 'bandit',
        value: 0.20,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('습격'));
      expect(s, contains('-20%'));
    });

    test('InvestigationSuccessRateBonusEffect 0.05 → "조사" + "+5%p"', () {
      const e = PassiveEffect.investigationSuccessRateBonus(value: 0.05);
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('조사'));
      expect(s, contains('+5%p'));
    });

    test('DispatchSlotBonusEffect value 1 → "파견 슬롯" + "1"', () {
      const e = PassiveEffect.dispatchSlotBonus(value: 1);
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('파견 슬롯'));
      expect(s, contains('1'));
    });

    test('IdleRewardBonusEffect rate 0.15 → "방치" 포함', () {
      const e = PassiveEffect.idleRewardBonus(
        bonusType: 'rate',
        value: 0.15,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('방치'));
      expect(s, contains('+15%'));
    });

    test('IdleRewardBonusEffect cap 100 → "상한" + "G" 포함', () {
      const e = PassiveEffect.idleRewardBonus(
        bonusType: 'cap',
        value: 100,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('방치'));
      expect(s, contains('상한'));
      expect(s, contains('G'));
    });

    test('RecruitmentCostReductionEffect 0.10 → "모집 비용" + "-10%"', () {
      const e = PassiveEffect.recruitmentCostReduction(value: 0.10);
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('모집 비용'));
      expect(s, contains('-10%'));
    });

    test('RecruitmentTierBoostEffect T1~T2 0.05 → "T1~T2" + "+5%p"', () {
      const e = PassiveEffect.recruitmentTierBoost(
        tierMin: 1,
        tierMax: 2,
        value: 0.05,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('T1~T2'));
      expect(s, contains('+5%p'));
    });

    test('MercenaryXpBonusEffect 0.10 → "경험치" + "+10%"', () {
      const e = PassiveEffect.mercenaryXpBonus(value: 0.10);
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('경험치'));
      expect(s, contains('+10%'));
    });

    test('TraitAcquisitionConditionReliefEffect 0.10 → "트레잇 획득" + "-10%"', () {
      const e = PassiveEffect.traitAcquisitionConditionRelief(value: 0.10);
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('트레잇 획득'));
      expect(s, contains('-10%'));
    });

    test('TraitEvolutionConditionReliefEffect 0.10 → "트레잇 진화" + "-10%"', () {
      const e = PassiveEffect.traitEvolutionConditionRelief(value: 0.10);
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('트레잇 진화'));
      expect(s, contains('-10%'));
    });

    test('TraitUnlockCategoryEffect → "해금" + categoryKey 포함', () {
      const e = PassiveEffect.traitUnlockCategory(categoryKey: 'Talent');
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('해금'));
      expect(s, contains('Talent'));
    });

    test('FacilityCostReductionEffect gold 0.10 → "시설" + "골드" + "-10%"', () {
      const e = PassiveEffect.facilityCostReduction(
        costType: 'gold',
        value: 0.10,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('시설'));
      expect(s, contains('골드'));
      expect(s, contains('-10%'));
    });

    test('FacilityEffectBonusEffect facilityId null → "전 시설" 포함', () {
      const e = PassiveEffect.facilityEffectBonus(
        facilityId: null,
        value: 0.05,
      );
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('전 시설'));
      expect(s, contains('+5%'));
    });

    test('UnknownPassiveEffect rawType → "미지원" + rawType 포함', () {
      const e = PassiveEffect.unknown(rawType: 'custom_type');
      final s = PassiveBonusFormatter.format(e);
      expect(s, contains('미지원'));
      expect(s, contains('custom_type'));
    });
  });
}
