import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

void main() {
  // F부터 현재 랭크까지 bonusJson의 effects를 누적하는 collect() 로직 검증
  group('PassiveBonusService.collect', () {
    test('빈 입력 → 중립값 반환', () {
      const ce = CollectedEffects.empty();
      expect(PassiveBonusService.getQuestRewardMultiplier(ce, 'raid'), 1.0);
      expect(
        PassiveBonusService.getQuestSuccessRateBonus(
          ce,
          questType: 'raid',
          partySize: 3,
        ),
        0.0,
      );
      expect(PassiveBonusService.getRecoveryTimeMultiplier(ce, 'injured'), 1.0);
      expect(PassiveBonusService.getDispatchSlotBonus(ce), 0);
    });

    test('랭크 누적 — reputation=25000 (B 도달) → D+B 퀘스트 보상 누적', () {
      // D: +0.03, B: +0.07 → 합산 1.10
      final ranks = [
        _rank('F', 0, {'effects': []}),
        _rank('E', 300, {
          'effects': [
            {'type': 'recruitment_cost_reduction', 'value': 0.10},
          ],
        }),
        _rank('D', 2000, {
          'effects': [
            {
              'type': 'quest_reward_multiplier',
              'quest_type': 'all',
              'value': 0.03,
            },
          ],
        }),
        _rank('C', 8000, {
          'effects': [
            {
              'type': 'quest_success_rate_bonus',
              'quest_type': 'all',
              'value': 0.03,
            },
          ],
        }),
        _rank('B', 25000, {
          'effects': [
            {
              'type': 'quest_reward_multiplier',
              'quest_type': 'all',
              'value': 0.07,
            },
          ],
        }),
        _rank('A', 80000, {
          'effects': [
            {
              'type': 'quest_reward_multiplier',
              'quest_type': 'all',
              'value': 0.05,
            },
          ],
        }),
      ];
      final ce = PassiveBonusService.collect(
        reputation: 25000,
        allRanks: ranks,
        joinedFactions: [],
      );
      expect(
        PassiveBonusService.getQuestRewardMultiplier(ce, 'raid'),
        closeTo(1.10, 0.0001),
      );
    });

    test('랭크 누적 — A 도달 시 dispatch_slot_bonus C(1) + A(1) = 2', () {
      final ranks = [
        _rank('F', 0, {'effects': []}),
        _rank('C', 8000, {
          'effects': [
            {'type': 'dispatch_slot_bonus', 'value': 1},
          ],
        }),
        _rank('A', 80000, {
          'effects': [
            {'type': 'dispatch_slot_bonus', 'value': 1},
          ],
        }),
      ];
      final ce = PassiveBonusService.collect(
        reputation: 80000,
        allRanks: ranks,
        joinedFactions: [],
      );
      expect(PassiveBonusService.getDispatchSlotBonus(ce), 2);
    });

    test('reputation 미달 랭크는 수집 안 됨 — reputation=5000이면 C(8000) 미포함', () {
      final ranks = [
        _rank('F', 0, {'effects': []}),
        _rank('D', 2000, {
          'effects': [
            {
              'type': 'quest_reward_multiplier',
              'quest_type': 'all',
              'value': 0.03,
            },
          ],
        }),
        _rank('C', 8000, {
          'effects': [
            {
              'type': 'quest_reward_multiplier',
              'quest_type': 'all',
              'value': 0.07,
            },
          ],
        }),
      ];
      final ce = PassiveBonusService.collect(
        reputation: 5000,
        allRanks: ranks,
        joinedFactions: [],
      );
      // D만 포함 → 1.03
      expect(
        PassiveBonusService.getQuestRewardMultiplier(ce, 'raid'),
        closeTo(1.03, 0.0001),
      );
    });
  });

  // 곱셈 계열 감소 합산이 1.0을 초과하면 하한 0.10으로 클램프
  group('PassiveBonusService — 곱셈 하한 클램프', () {
    test('회복 시간 — 합산 감소 1.15 → 하한 0.10 적용', () {
      final effects = [
        PassiveEffect.recoveryTimeReduction(status: 'injured', value: 0.25),
        PassiveEffect.recoveryTimeReduction(status: 'injured', value: 0.25),
        PassiveEffect.recoveryTimeReduction(status: 'injured', value: 0.25),
        PassiveEffect.recoveryTimeReduction(status: 'injured', value: 0.25),
        PassiveEffect.recoveryTimeReduction(status: 'injured', value: 0.15),
      ];
      final ce = CollectedEffects(effects);
      expect(PassiveBonusService.getRecoveryTimeMultiplier(ce, 'injured'), 0.10);
    });

    test('시설 비용(time) — 단일 0.20 감소 → 0.80 반환', () {
      final effects = [
        PassiveEffect.facilityCostReduction(costType: 'time', value: 0.20),
      ];
      expect(
        PassiveBonusService.getFacilityCostMultiplier(
          CollectedEffects(effects),
          'time',
        ),
        closeTo(0.80, 0.0001),
      );
    });

    test('모집 비용 — 0.50 + 0.50 합산 → 하한 0.10 클램프', () {
      final effects = [
        PassiveEffect.recruitmentCostReduction(value: 0.50),
        PassiveEffect.recruitmentCostReduction(value: 0.50),
      ];
      expect(
        PassiveBonusService.getRecruitmentCostMultiplier(CollectedEffects(effects)),
        0.10,
      );
    });

    test('회복 시간 — status 불일치는 합산 제외', () {
      // 'tired' effect는 'injured' 조회에 영향 없음
      final effects = [
        PassiveEffect.recoveryTimeReduction(status: 'tired', value: 0.30),
        PassiveEffect.recoveryTimeReduction(status: 'injured', value: 0.10),
      ];
      expect(
        PassiveBonusService.getRecoveryTimeMultiplier(
          CollectedEffects(effects),
          'injured',
        ),
        closeTo(0.90, 0.0001),
      );
    });
  });

  // 퀘스트 성공률 보너스는 공유 상한 +20%p (비율 0.20)로 클램프
  group('PassiveBonusService — 공유 상한 +20%p', () {
    test('quest_success_rate_bonus — 30%p 합산 → 20%p 클램프', () {
      final effects = [
        PassiveEffect.questSuccessRateBonus(questType: 'all', value: 0.15),
        PassiveEffect.questSuccessRateBonus(questType: 'raid', value: 0.15),
      ];
      expect(
        PassiveBonusService.getQuestSuccessRateBonus(
          CollectedEffects(effects),
          questType: 'raid',
          partySize: 3,
        ),
        20.0,
      );
    });

    test('all + 특정 유형 가산 — raid 요청 시 0.05(all) + 0.08(raid) = 13%p', () {
      final effects = [
        PassiveEffect.questSuccessRateBonus(questType: 'all', value: 0.05),
        PassiveEffect.questSuccessRateBonus(questType: 'raid', value: 0.08),
      ];
      expect(
        PassiveBonusService.getQuestSuccessRateBonus(
          CollectedEffects(effects),
          questType: 'raid',
          partySize: 3,
        ),
        closeTo(13.0, 0.0001),
      );
    });

    test('quest_type 불일치 — escort 요청 시 raid 보너스 미적용', () {
      final effects = [
        PassiveEffect.questSuccessRateBonus(questType: 'raid', value: 0.10),
      ];
      expect(
        PassiveBonusService.getQuestSuccessRateBonus(
          CollectedEffects(effects),
          questType: 'escort',
          partySize: 3,
        ),
        0.0,
      );
    });

    test('party_size 조건부 — minPartySize=3, partySize=2면 미적용', () {
      final effects = [
        PassiveEffect.questSuccessRateBonusPartySize(
          minPartySize: 3,
          value: 0.08,
        ),
      ];
      expect(
        PassiveBonusService.getQuestSuccessRateBonus(
          CollectedEffects(effects),
          questType: 'raid',
          partySize: 2,
        ),
        0.0,
      );
      expect(
        PassiveBonusService.getQuestSuccessRateBonus(
          CollectedEffects(effects),
          questType: 'raid',
          partySize: 3,
        ),
        closeTo(8.0, 0.0001),
      );
    });
  });

  // dispatch_slot_bonus 합산 상한 +10
  group('PassiveBonusService — dispatch_slot_bonus 상한 +10', () {
    test('7 + 4 = 11 → 상한 10 클램프', () {
      final effects = [
        PassiveEffect.dispatchSlotBonus(value: 7),
        PassiveEffect.dispatchSlotBonus(value: 4),
      ];
      expect(
        PassiveBonusService.getDispatchSlotBonus(CollectedEffects(effects)),
        10,
      );
    });

    test('단일 3 → 그대로 3 반환', () {
      final effects = [PassiveEffect.dispatchSlotBonus(value: 3)];
      expect(
        PassiveBonusService.getDispatchSlotBonus(CollectedEffects(effects)),
        3,
      );
    });
  });

  group('PassiveBonusService — 기타', () {
    test('investigation_success_rate_bonus — 30%p 합산 → 20%p 상한 클램프', () {
      final effects = [
        PassiveEffect.investigationSuccessRateBonus(value: 0.30),
      ];
      expect(
        PassiveBonusService.getInvestigationSuccessRateBonus(
          CollectedEffects(effects),
        ),
        20.0,
      );
    });

    test('mercenary_xp_bonus 비율 합산 — 0.15 단일', () {
      final effects = [PassiveEffect.mercenaryXpBonus(value: 0.15)];
      expect(
        PassiveBonusService.getMercenaryXpBonus(CollectedEffects(effects)),
        closeTo(0.15, 0.0001),
      );
    });

    test('unknown type 무시 — parseEffects 통과 후 known effect만 반영', () {
      final parsed = PassiveEffect.parseEffects({
        'effects': [
          {'type': 'nonexistent_bonus', 'value': 99},
          {
            'type': 'quest_reward_multiplier',
            'quest_type': 'raid',
            'value': 0.05,
          },
        ],
      });
      // unknown variant 포함하여 총 2개
      expect(parsed.length, 2);
      final ce = CollectedEffects(parsed);
      // unknown은 무시, quest_reward_multiplier만 반영
      expect(
        PassiveBonusService.getQuestRewardMultiplier(ce, 'raid'),
        closeTo(1.05, 0.0001),
      );
    });

    test('parseEffects 빈 JSON 안전 처리', () {
      expect(PassiveEffect.parseEffects({}), isEmpty);
      expect(PassiveEffect.parseEffects({'effects': []}), isEmpty);
      expect(
        PassiveEffect.parseEffects({
          'effects': [
            {
              'type': 'quest_reward_multiplier',
              'quest_type': 'all',
              'value': 0.07,
            },
          ],
        }).length,
        1,
      );
    });
  });
}

Rank _rank(String grade, int req, Map<String, dynamic> bonusJson) {
  return Rank(
    grade: grade,
    name: grade,
    requiredReputation: req,
    unlockTier: 1,
    bonusJson: bonusJson,
  );
}
