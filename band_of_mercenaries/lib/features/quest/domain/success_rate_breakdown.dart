/// 성공률 레이어별 분해 값 객체.
///
/// 각 필드는 %p 단위. `total`은 clamp(5,95) 전 합계, `finalRate`는 clamp 적용 후.
/// `rankBonus`는 현재 `PassiveBonusService.CollectedEffects`에 랭크 효과가 이미 포함되므로
/// 중복 집계를 피하기 위해 **항상 0.0 stub**으로 유지된다 (P4-2 rankRewardBonus 제거 정책과 동일).
class SuccessRateBreakdown {
  final double base;                    // 50.0 고정
  final double powerRatioContribution;  // (powerRatio - 1) × 50
  final double questMod;                // 퀘스트 유형 보정 (raid 0, escort +3 등)
  final double roleSynergy;             // 파티 평균 role 상성 (±10 clamp 후)
  final double traitBonus;              // 트레잇 효과 합산 (±10 clamp 후)
  final double factionPassiveBonus;     // 세력 패시브 + 랭크 효과 (0~20 clamp 후)
  final double rankBonus;               // 항상 0.0 stub (주석 참조)
  final double sharedCapLoss;           // 공유 상한 초과 손실 (양수, UI는 음수 표시)
  final double distancePenalty;         // 음수 저장 (예: -20)
  final double total;                   // clamp 전 합계
  final double finalRate;               // clamp(5, 95) 적용 후 최종

  const SuccessRateBreakdown({
    required this.base,
    required this.powerRatioContribution,
    required this.questMod,
    required this.roleSynergy,
    required this.traitBonus,
    required this.factionPassiveBonus,
    this.rankBonus = 0.0,
    required this.sharedCapLoss,
    required this.distancePenalty,
    required this.total,
    required this.finalRate,
  });
}
