import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';

/// 수집된 PassiveEffect 리스트 래퍼.
class CollectedEffects {
  final List<PassiveEffect> effects;
  const CollectedEffects(this.effects);
  const CollectedEffects.empty() : effects = const [];
}

/// 세력 패시브 + 명성 랭크 누적 보너스를 통합 처리하는 서비스.
///
/// 스태킹 규약:
///   - 곱셈 계열 반환값: `(1 - Σ).clamp(0.10, 1.0)` 형태의 "남는 비율".
///     호출측은 `baseValue × multiplier`로 적용 (회복시간·시설비용·모집비용).
///   - 가산 계열 반환값: %p 또는 비율 합산. 호출측이 `+ bonus` 또는 `× (1 + bonus)`로 적용.
///   - 완화 비율 계열: 0.0~0.95 클램프. 호출측이 `threshold × (1 - relief)` 형태로 적용.
class PassiveBonusService {
  /// 가입 세력 effects + F부터 현재 reputation 도달 랭크까지의 effects를 누적하여 반환.
  ///
  /// allRanks는 requiredReputation 오름차순 정렬 후, 첫 미도달 랭크에서 break.
  static CollectedEffects collect({
    required int reputation,
    required List<Rank> allRanks,
    required List<FactionData> joinedFactions,
  }) {
    final buffer = <PassiveEffect>[];

    // 세력 패시브 수집
    for (final faction in joinedFactions) {
      buffer.addAll(PassiveEffect.parseEffects(faction.passiveBonusJson));
    }

    // 랭크 보너스 수집: 오름차순 정렬 후 도달한 랭크까지 누적
    final sorted = [...allRanks]
      ..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
    for (final rank in sorted) {
      if (reputation >= rank.requiredReputation) {
        buffer.addAll(PassiveEffect.parseEffects(rank.bonusJson));
      } else {
        break;
      }
    }

    return CollectedEffects(buffer);
  }

  // ─────────── 가산 스태킹 계열 ────────────

  /// 퀘스트 보상 배수. `all` + 해당 questType 가산 후 `1.0 + sum` 반환.
  static double getQuestRewardMultiplier(CollectedEffects ce, String questType) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is QuestRewardMultiplierEffect) {
        if (e.questType == 'all' || e.questType == questType) {
          sum += e.value;
        }
      }
    }
    return 1.0 + sum;
  }

  /// 퀘스트 성공률 보너스 (%p). 공유 상한 +20%p 클램프.
  /// DB 저장 기준이 비율(0.05)이므로 × 100 적용 후 반환.
  static double getQuestSuccessRateBonus(
    CollectedEffects ce, {
    required String questType,
    required int partySize,
  }) {
    return getQuestSuccessRateBonusWithDetail(
      ce,
      questType: questType,
      partySize: partySize,
    ).applied;
  }

  /// 퀘스트 성공률 보너스 상세 반환 (rawSum은 %p 단위, applied는 clamp(0,20) 적용값, lossAmount는 초과분).
  static ({double rawSum, double applied, double lossAmount})
      getQuestSuccessRateBonusWithDetail(
    CollectedEffects ce, {
    required String questType,
    required int partySize,
  }) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is QuestSuccessRateBonusEffect) {
        if (e.questType == 'all' || e.questType == questType) {
          sum += e.value;
        }
      } else if (e is QuestSuccessRateBonusPartySizeEffect) {
        if (partySize >= e.minPartySize) {
          sum += e.value;
        }
      }
    }
    final rawPp = sum * 100.0;
    final applied = rawPp.clamp(0.0, 20.0);
    final lossAmount = (rawPp - applied).clamp(0.0, double.infinity);
    return (rawSum: rawPp, applied: applied, lossAmount: lossAmount);
  }

  /// 지역 조사 성공률 보너스 (%p). 자체 상한 +20%p (퀘스트 성공률과 별도 풀).
  static double getInvestigationSuccessRateBonus(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is InvestigationSuccessRateBonusEffect) {
        sum += e.value;
      }
    }
    return (sum * 100.0).clamp(0.0, 20.0);
  }

  /// 용병 XP 보너스 비율 합산. 호출측은 `baseXp × (1 + return)` 형태로 적용.
  static double getMercenaryXpBonus(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is MercenaryXpBonusEffect) {
        sum += e.value;
      }
    }
    return sum;
  }

  // ─────────── 곱셈 스태킹 계열 (하한 0.10) ────────────

  /// 회복 시간 배수. `(1 - Σ).clamp(0.10, 1.0)` 반환.
  /// 호출측: `baseSeconds × multiplier`
  static double getRecoveryTimeMultiplier(CollectedEffects ce, String status) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is RecoveryTimeReductionEffect) {
        if (e.status == 'all' || e.status == status) {
          sum += e.value;
        }
      }
    }
    return (1.0 - sum).clamp(0.10, 1.0);
  }

  /// 시설 비용 배수 (gold 또는 time). `(1 - Σ).clamp(0.10, 1.0)` 반환.
  static double getFacilityCostMultiplier(CollectedEffects ce, String costType) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is FacilityCostReductionEffect && e.costType == costType) {
        sum += e.value;
      }
    }
    return (1.0 - sum).clamp(0.10, 1.0);
  }

  /// 모집 비용 배수. `(1 - Σ).clamp(0.10, 1.0)` 반환.
  static double getRecruitmentCostMultiplier(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is RecruitmentCostReductionEffect) {
        sum += e.value;
      }
    }
    return (1.0 - sum).clamp(0.10, 1.0);
  }

  // ─────────── 완화 비율 계열 (0.0~0.95) ────────────

  /// 트레잇 획득 조건 완화 비율. 0.0~0.95 클램프.
  /// 호출측: `threshold × (1 - relief)`
  static double getTraitAcquisitionRelief(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is TraitAcquisitionConditionReliefEffect) {
        sum += e.value;
      }
    }
    return sum.clamp(0.0, 0.95);
  }

  /// 트레잇 진화 조건 완화 비율. 0.0~0.95 클램프.
  static double getTraitEvolutionRelief(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is TraitEvolutionConditionReliefEffect) {
        sum += e.value;
      }
    }
    return sum.clamp(0.0, 0.95);
  }

  // ─────────── 기타 ────────────

  /// 이동 이벤트 완화 비율. 0.0~0.95 클램프.
  /// 호출측: `magnitude × (1 - return)`
  static double getTravelEventMitigation(CollectedEffects ce, String eventType) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is TravelEventMitigationEffect) {
        if (e.eventType == 'all' || e.eventType == eventType) {
          sum += e.value;
        }
      }
    }
    return sum.clamp(0.0, 0.95);
  }

  /// 시설 효과 보너스. facilityId 일치 또는 전체(facilityId == null) effect의 value 합산.
  /// 0.0~1.0 클램프.
  static double getFacilityEffectBonus(CollectedEffects ce, String facilityId) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is FacilityEffectBonusEffect) {
        if (e.facilityId == null || e.facilityId == facilityId) {
          sum += e.value;
        }
      }
    }
    return sum.clamp(0.0, 1.0);
  }

  /// 모집 티어 부스트 (T4~T5 범위와 겹치는 effect의 value 합산). 0.0~0.5 클램프.
  static double getRecruitmentTierBoost(
    CollectedEffects ce, {
    int targetTierMin = 4,
    int targetTierMax = 5,
  }) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is RecruitmentTierBoostEffect) {
        final overlaps = e.tierMin <= targetTierMax && e.tierMax >= targetTierMin;
        if (overlaps) sum += e.value;
      }
    }
    return sum.clamp(0.0, 0.5);
  }

  /// 방치 보상 보너스. rate는 비율(+0.15 = +15%), cap은 추가 상한 골드.
  static ({double rate, double cap}) getIdleRewardBonus(CollectedEffects ce) {
    double rate = 0.0;
    double cap = 0.0;
    for (final e in ce.effects) {
      if (e is IdleRewardBonusEffect) {
        if (e.bonusType == 'rate') rate += e.value;
        if (e.bonusType == 'cap') cap += e.value;
      }
    }
    return (rate: rate, cap: cap);
  }

  /// 파견 슬롯 보너스. 정수 합산. 하한 0, 상한 +10 클램프.
  static int getDispatchSlotBonus(CollectedEffects ce) {
    int sum = 0;
    for (final e in ce.effects) {
      if (e is DispatchSlotBonusEffect) {
        sum += e.value;
      }
    }
    return sum.clamp(0, 10);
  }
}
