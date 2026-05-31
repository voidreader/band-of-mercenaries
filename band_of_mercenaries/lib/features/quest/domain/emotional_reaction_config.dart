/// 감정 반응 상태 발동 확률·효과·우선순위 정적 상수 (M8.5 페이즈 4 #3)
///
/// 밸런스 문서 [balance]20260521_m8.5_emotional_reaction_values.md §3~§4 기반.
/// 4 감정 반응(분노/절망/슬픔/투지)의 발동 확률, 효과 수치, 우선순위를 일관되게 관리한다.
class EmotionalReactionConfig {
  EmotionalReactionConfig._(); // 인스턴스화 방지

  // ===== 발동 확률 (§4.1 사건별 발동 확률 매트릭스) =====

  /// 분노 기본 발동 확률 (동료 사망 시)
  static const double rageBaseChance = 0.60;

  /// 분노 트레잇 가중 보너스 (vengeful/berserker_talent/madman/slayer 보유 시 +20%p)
  static const double rageTraitBonus = 0.20;

  /// 슬픔 기본 발동 확률 (동료 중상 시)
  static const double sorrowBaseChance = 0.50;

  /// 슬픔 트레잇 가중 보너스 (guardian/empathic/team_player/mentor 보유 시 +30%p)
  static const double sorrowTraitBonus = 0.30;

  /// 절망 기본 발동 확률 (파티 HP <25% 도달 시)
  /// 신규 면제 정책: iron_will/unyielding/hardened/fearless/composed 보유 시 0.0 (100% 면제)
  static const double despairBaseChance = 0.80;

  /// 투지 기본 발동 확률 (트리거 mercId HP <30% 도달 시) — 자동, 가중 없음
  static const double determinationBaseChance = 1.00;

  // ===== 트리거 임계값 (§4.1 트리거 조건) =====

  /// 절망 트리거 조건: 파티 HP 합계 / 파티 최대 HP < 25%
  static const double despairPartyHpThreshold = 0.25;

  /// 투지 트리거 조건: 트리거 대상 mercenary HP / 최대 HP < 30%
  /// (간판 용병 / 솔로 파견 용병 / 체인 주인공)
  static const double determinationCombatantHpThreshold = 0.30;

  // ===== 슬픔 특수 처리 (§3.3 슬픔 특수 처리) =====

  /// 슬픔 상태 효과 보유 시 행동 슬롯 스킵 확률 (50%)
  /// mez_stunned (100% 스킵 1턴)과 차별화하기 위해 apply_method='none'으로 simulator 분기
  static const double sorrowSkipChance = 0.50;

  // ===== 투지 사망 저항 cap 가산 정책 (§3.5 솔로 cap 0.95 + 투지 +0.20 가산 정책) =====

  /// 투지 발동 시 사망 저항 가산값 (+20%)
  /// 산식: clamp(base + traitBonus + factionBonus + emotional_determination, 0.20, capForQuest)
  /// 즉 cap 통과 전 base에 포함시켜 clamp를 재적용한다.
  /// cap 통과 후 별도 가산은 금지 (솔로 의뢰에서 cap 0.95 유지).
  static const double determinationDeathResistBonus = 0.20;

  /// 투지 발동 시 회피 가산값 (+15%)
  /// 별도 hook이므로 evasion clamp [0, 0.75]에 자유 가산 (cap 영향 없음)
  static const double determinationEvasionBonus = 0.15;

  // ===== 우선순위 (§8.1 우선순위 정책) =====

  /// 같은 라운드 다중 감정 트리거 시 평가 순서 (우선순위 desc)
  /// 한 combatant는 단일 emotional만 보유 (ignore stack_policy).
  /// 1. determination (최우선) — 영웅적 반응, 간판/솔로/체인 주인공 보호
  /// 2. rage — 동료 사망 직후 즉각 반응
  /// 3. sorrow — 동료 중상 일시적 위축
  /// 4. despair (최후순위) — 전멸 임박 가장 약한 자에게
  static const List<String> priority = [
    'determination',
    'rage',
    'sorrow',
    'despair',
  ];

  // ===== 분노 효과 수치 (§3.1 분노 default 수치 확정) =====

  /// 분노 공격 가산값 (multiplicative, +30%)
  static const double rageAtkBonus = 0.30;

  /// 분노 방어 감소값 (multiplicative, -20% = 방어 × 0.80)
  static const double rageDefPenalty = 0.20;

  // ===== 절망 효과 수치 (§3.2 절망 default 수치 확정) =====

  /// 절망 명중 감소값 (additive, -20%)
  /// M8b debuff_accuracy_down 0.10의 2배 강화 (전멸 임박의 무력감)
  static const double despairHitPenalty = 0.20;

  /// 절망 회피 감소값 (additive, -15%)
  static const double despairEvaPenalty = 0.15;
}

/// 감정 반응 트레잇 가중 키워드 정적 상수 (M8.5 페이즈 4 #3)
///
/// 밸런스 문서 [balance]20260521_m8.5_emotional_reaction_values.md §7.1 기반.
/// 실제 traits 테이블 key 매칭 (109행 중 13행).
/// 부분 문자열 매칭이 아니라 정확한 key 포함 여부로 판정한다.
class TraitEmotionalKeywords {
  TraitEmotionalKeywords._(); // 인스턴스화 방지

  // ===== 분노 가중 키워드 (rageBaseChance + rageTraitBonus) =====

  /// 분노 +20%p 보너스 트레잇 4종
  ///
  /// - vengeful: Mental acquired - 복수심
  /// - berserker_talent: Talent innate - 광전사의 피
  /// - madman: Mental - 광기
  /// - slayer: CombatStyle - 학살자
  static const Set<String> rageBoost = {
    'vengeful',
    'berserker_talent',
    'madman',
    'slayer',
  };

  // ===== 슬픔 가중 키워드 (sorrowBaseChance + sorrowTraitBonus) =====

  /// 슬픔 +30%p 보너스 트레잇 4종
  ///
  /// - guardian: CombatStyle acquired - 수호자
  /// - empathic: Mental - 공감
  /// - team_player: Behavior - 협동가
  /// - mentor: Behavior - 조언자
  static const Set<String> sorrowBoost = {
    'guardian',
    'empathic',
    'team_player',
    'mentor',
  };

  // ===== 절망 면제 키워드 (despairBaseChance → 0.0) =====

  /// 절망 100% 면제 트레잇 5종
  /// 이 키워드를 보유한 용병은 despairActivationChance = 0.0
  ///
  /// - iron_will: Talent innate - 철의 의지
  /// - unyielding: Survival evolved - 불굴
  /// - hardened: Mental - 무뎌진 마음
  /// - fearless: Mental - 두려움 없음
  /// - composed: Mental - 침착함
  static const Set<String> despairImmune = {
    'iron_will',
    'unyielding',
    'hardened',
    'fearless',
    'composed',
  };

  // 투지는 가중 없음 (자동 100%)
}
