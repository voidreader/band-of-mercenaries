/// 전투 시뮬레이터 정적 상수 모음
///
/// 페이즈 1 #2 직업군 매트릭스, 페이즈 1 #3 산식, 페이즈 1 #2 트레잇 매핑,
/// 페이즈 2 #3 DoT, 페이즈 2 #4 보고서 길이 등 M8b 전투 시뮬레이터의 모든 매트릭스를 정의한다.
class CombatSimulatorConstants {
  CombatSimulatorConstants._();

  // ============================================================================
  // §FR-13: 트레잇 키워드 매트릭스 8종
  // ============================================================================

  /// 선제 점수 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #2 §5.2, 페이즈 2 #3 §7.1 정합
  static const Map<String, int> initiativeKeywords = {
    'scout': 2,
    'ambush': 3,
    'first_strike': 3,
    'vigilant': 2,
    'tracker': 1,
  };

  /// 행동 순서 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #2 §5.2
  static const Map<String, int> actionKeywords = {
    'swift': 2,
    'nimble': 1,
    'quick': 1,
    'agile': 1,
  };

  /// 회피율 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #3 §8.3
  static const Map<String, double> evasionKeywords = {
    'evasion': 0.04,
    'dodge': 0.04,
    'nimble': 0.03,
    'slippery': 0.04,
  };

  /// 반격율 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #3 §9.2
  static const Map<String, double> counterKeywords = {
    'riposte': 0.08,
    'counter': 0.08,
    'vengeance': 0.08,
    'vigilant': 0.05,
    'unyielding': 0.05,
  };

  /// 방패 막기 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #3 §4.3 hook 위치
  static const Map<String, double> shieldKeywords = {
    'shield': 0.10,
    'bulwark': 0.10,
    'guardian': 0.10,
  };

  /// 명중율 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #3 §6.4
  static const Map<String, double> hitKeywords = {
    'marksman': 0.05,
    'keen_eye': 0.05,
    'sniper': 0.05,
    'tracker': 0.03,
    'huntsman': 0.03,
    'veteran': 0.02,
  };

  /// 치명타율 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #3 §7.5
  static const Map<String, double> critKeywords = {
    'precise': 0.05,
    'deadly': 0.05,
    'assassin': 0.05,
    'keen_eye': 0.04,
    'sharpshooter': 0.04,
  };

  /// 사망 저항 관련 트레잇 키워드 (FR-13)
  /// 페이즈 1 #3 §10.3
  static const Map<String, double> deathResistKeywords = {
    'survivor': 0.05,
    'tough': 0.05,
    'resilient': 0.05,
    'iron_body': 0.05,
    'hardy': 0.05,
  };

  // ============================================================================
  // §FR-13 §2: 트레잇 상한 (per merc + team)
  // ============================================================================

  /// 1명당 선제 트레잇 상한 (FR-13 §2)
  static const int traitInitiativeCapPerMerc = 5;

  /// 1명당 행동 순서 트레잇 상한 (FR-13 §2)
  static const int traitActionCapPerMerc = 5;

  /// 1명당 회피 트레잇 상한 (FR-13 §2)
  static const double traitEvasionCapPerMerc = 0.12;

  /// 1명당 명중 트레잇 상한 (FR-13 §2)
  static const double traitHitCapPerMerc = 0.10;

  /// 1명당 치명타 트레잇 상한 (FR-13 §2)
  static const double traitCritCapPerMerc = 0.15;

  /// 1명당 사망 저항 트레잇 상한 (FR-13 §2)
  static const double traitDeathResistCapPerMerc = 0.15;

  /// 진영 합산 선제 점수 상한 (FR-13 §2)
  /// 선제 점수만 진영 합산 상한 적용. 행동·회피·명중·치명타·사망 저항·반격·방패는 1명당 상한만.
  static const int traitInitiativeCapTeam = 15;

  // ============================================================================
  // §FR-11 + 페이즈 1 #3: 직업군 매트릭스 (13종)
  // ============================================================================

  /// 선제 점수 직업군 가중치 (FR-13.5 + 페이즈 1 #2 §4.1)
  /// 진영 평균에 사용
  static const Map<String, int> roleInitiativeWeight = {
    'rogue': 6,
    'ranger': 5,
    'warrior': 2,
    'specialist': 1,
    'support': -2,
    'mage': -3,
  };

  /// 행동 순서 직업군 가중치 (페이즈 1 #2 §4.2)
  /// 개별 전투원 정렬에 사용
  static const Map<String, int> roleActionWeight = {
    'rogue': 6,
    'ranger': 4,
    'warrior': 1,
    'specialist': 0,
    'support': -1,
    'mage': -3,
  };

  /// 기본 명중률 (페이즈 1 #3 §6.1)
  static const Map<String, double> baseHitRate = {
    'warrior': 0.80,
    'specialist': 0.78,
    'ranger': 0.82,
    'rogue': 0.76,
    'mage': 0.75,
    'support': 0.75,
  };

  /// 기본 회피율 (페이즈 1 #3 §8.1)
  static const Map<String, double> baseEvasion = {
    'warrior': 0.05,
    'specialist': 0.08,
    'ranger': 0.15,
    'rogue': 0.18,
    'support': 0.10,
    'mage': 0.07,
  };

  /// 기본 치명타율 (페이즈 1 #3 §7.2)
  static const Map<String, double> baseCritRate = {
    'warrior': 0.05,
    'specialist': 0.05,
    'ranger': 0.10,
    'rogue': 0.15,
    'mage': 0.08,
    'support': 0.05,
  };

  /// 기본 반격율 (페이즈 1 #3 §9.1)
  static const Map<String, double> baseRiposte = {
    'warrior': 0.25,
    'specialist': 0.15,
    'rogue': 0.20,
    'ranger': 0.10,
    'mage': 0.00,
    'support': 0.00,
  };

  /// 치명타 피해 배수 (페이즈 1 #3 §7.6)
  static const Map<String, double> critMultiplier = {
    'rogue': 2.0,
    'ranger': 1.7,
    'mage': 1.7,
    'warrior': 1.5,
    'specialist': 1.5,
    'support': 1.5,
  };

  /// 직업군별 사망 저항 보너스 (FR-11.5 §10.2)
  /// roleDeathResist
  static const Map<String, double> roleDeathResistBonus = {
    'warrior': 0.10,
    'specialist': 0.05,
    'ranger': 0.00,
    'rogue': 0.00,
    'mage': 0.00,
    'support': 0.00,
  };

  /// 직업군별 VIT 계수 (FR-11 §7, 페이즈 1 #3 §2.2)
  static const Map<String, double> roleVitCoef = {
    'warrior': 5.5,
    'specialist': 4.5,
    'ranger': 4.0,
    'rogue': 3.5,
    'support': 4.0,
    'mage': 3.0,
  };

  /// 직업군별 HP 고정값 (페이즈 1 #3 §2.2)
  static const Map<String, int> roleHpFlat = {
    'warrior': 30,
    'specialist': 25,
    'ranger': 20,
    'rogue': 18,
    'support': 22,
    'mage': 15,
  };

  /// 직업군별 방어 계수 (페이즈 1 #3 §4.1)
  static const Map<String, double> roleDefCoef = {
    'warrior': 1.5,
    'specialist': 1.2,
    'ranger': 1.0,
    'rogue': 0.8,
    'support': 1.0,
    'mage': 0.7,
  };

  /// 직업군별 방어 고정값 (페이즈 1 #3 §4.1)
  static const Map<String, int> roleDefFlat = {
    'warrior': 8,
    'specialist': 6,
    'ranger': 4,
    'rogue': 3,
    'support': 5,
    'mage': 2,
  };

  // ============================================================================
  // §FR-11.5: 사망 저항 (Death Resistance)
  // ============================================================================

  /// 티어별 기본 사망 저항 (FR-11.5 §10.1)
  static const Map<int, double> baseDeathResistByTier = {
    1: 0.30,
    2: 0.35,
    3: 0.45,
    4: 0.55,
    5: 0.65,
  };

  /// 사망 저항 최소값 (FR-11.5 §10.1)
  static const double deathResistMin = 0.20;

  /// 사망 저항 최대값 (FR-11.5 §10.1)
  static const double deathResistMax = 0.80;

  /// 체인 퀘스트 주인공 사망 저항 최대값 (FR-11.5 §10.6)
  static const double deathResistChainProtagonistMax = 0.90;

  // ============================================================================
  // §FR-13.5: 환경 매트릭스 (8 태그 × 6 직업군)
  // 페이즈 1 #2 §6 + 페이즈 1 #3 §6.5, §8.4
  // ============================================================================

  /// 환경 태그 → 명중 보정 (페이즈 1 #3 §6.5)
  /// 모든 역할에 공통이거나, 역할별 분기. 접근형/원거리 구분 적용.
  static const Map<String, Map<String, double>> environmentHitMod = {
    'forest': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': -0.03,
      'mage': 0.0,
      'support': 0.0,
    },
    'dungeon': {
      'warrior': 0.05,
      'specialist': 0.05,
      'rogue': 0.05,
      'ranger': -0.03,
      'mage': -0.03,
      'support': -0.03,
    },
    'sea_coast': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': 0.0,
      'mage': 0.0,
      'support': 0.0,
    },
    'desert': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': -0.02,
      'mage': 0.0,
      'support': 0.0,
    },
    'mountain': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': 0.03,
      'mage': 0.0,
      'support': 0.0,
    },
    'mist_field': {
      'warrior': -0.10,
      'specialist': -0.10,
      'rogue': -0.10,
      'ranger': -0.10,
      'mage': -0.10,
      'support': -0.10,
    },
    'swamp': {
      'warrior': -0.02,
      'specialist': -0.02,
      'rogue': -0.02,
      'ranger': -0.02,
      'mage': -0.02,
      'support': -0.02,
    },
    'ruined_castle': {
      'warrior': 0.02,
      'specialist': 0.02,
      'rogue': 0.02,
      'ranger': 0.02,
      'mage': 0.02,
      'support': 0.02,
    },
  };

  /// 환경 태그 → 회피 보정 (페이즈 1 #3 §8.4)
  static const Map<String, Map<String, double>> environmentEvasionMod = {
    'forest': {
      'warrior': 0.03,
      'specialist': 0.03,
      'rogue': 0.03,
      'ranger': 0.03,
      'mage': 0.03,
      'support': 0.03,
    },
    'dungeon': {
      'warrior': -0.05,
      'specialist': -0.05,
      'rogue': -0.05,
      'ranger': -0.05,
      'mage': -0.05,
      'support': -0.05,
    },
    'sea_coast': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': 0.0,
      'mage': 0.0,
      'support': 0.0,
    },
    'desert': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': 0.0,
      'mage': 0.0,
      'support': 0.0,
    },
    'mountain': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': 0.0,
      'mage': 0.0,
      'support': 0.0,
    },
    'mist_field': {
      'warrior': 0.05,
      'specialist': 0.05,
      'rogue': 0.05,
      'ranger': 0.05,
      'mage': 0.05,
      'support': 0.05,
    },
    'swamp': {
      'warrior': -0.03,
      'specialist': -0.03,
      'rogue': -0.03,
      'ranger': -0.03,
      'mage': -0.03,
      'support': -0.03,
    },
    'ruined_castle': {
      'warrior': 0.0,
      'specialist': 0.0,
      'rogue': 0.0,
      'ranger': 0.0,
      'mage': 0.0,
      'support': 0.0,
    },
  };

  /// 환경 태그 → 행동 순서 보정 (페이즈 1 #2 §6)
  /// 페이즈 1 #2 MVP는 선제/행동 순서 동일 매트릭스 사용.
  /// 정확한 매트릭스는 페이즈 1 #2 §6 표 참고 (±5 범위).
  /// 본 명세 구현에서는 간단화: 0 또는 미사용으로 대체 (페이즈 4 #5 정밀화 위임).
  static const Map<String, Map<String, int>> environmentActionMod = {
    'forest': {
      'warrior': 0,
      'specialist': 0,
      'rogue': 0,
      'ranger': 5,
      'mage': -2,
      'support': 0,
    },
    'dungeon': {
      'warrior': 3,
      'specialist': 1,
      'rogue': 2,
      'ranger': -3,
      'mage': -1,
      'support': 0,
    },
    'sea_coast': {
      'warrior': -1,
      'specialist': 3,
      'rogue': 0,
      'ranger': 1,
      'mage': 0,
      'support': 1,
    },
    'desert': {
      'warrior': 1,
      'specialist': 1,
      'rogue': -1,
      'ranger': 0,
      'mage': -1,
      'support': 0,
    },
    'mountain': {
      'warrior': 2,
      'specialist': 1,
      'rogue': -1,
      'ranger': 2,
      'mage': -2,
      'support': -1,
    },
    'mist_field': {
      'warrior': -2,
      'specialist': 0,
      'rogue': 2,
      'ranger': -2,
      'mage': 1,
      'support': 0,
    },
    'swamp': {
      'warrior': -1,
      'specialist': 2,
      'rogue': 0,
      'ranger': 1,
      'mage': 1,
      'support': -1,
    },
    'ruined_castle': {
      'warrior': 2,
      'specialist': 1,
      'rogue': 2,
      'ranger': 0,
      'mage': 1,
      'support': 0,
    },
  };

  /// 환경 태그 → 선제 점수 보정 (FR-13.5)
  /// 페이즈 1 #2 §6 진입점은 battlefieldInitiativeModifier이나,
  /// MVP 구현에서는 간단화 (전부 0 또는 별도 매트릭스 미사용).
  static const Map<String, int> environmentInitiativeMod = {
    'forest': 0,
    'dungeon': 0,
    'sea_coast': 0,
    'desert': 0,
    'mountain': 0,
    'mist_field': 0,
    'swamp': 0,
    'ruined_castle': 0,
  };

  // ============================================================================
  // §FR-11 §6: Flank Bonus (후방 공격 보너스)
  // ============================================================================

  /// 후방 공격 치명타 보너스 (FR-11 §6, 페이즈 1 #3 §7.4)
  static const Map<String, double> flankBonus = {
    'rogue': 0.10,
    'ranger': 0.05,
    'warrior': 0.0,
    'specialist': 0.0,
    'mage': 0.0,
    'support': 0.0,
  };

  // ============================================================================
  // §FR-11: 명중/회피/치명타/반격/방패 상한 (clamp)
  // ============================================================================

  /// 명중률 최소값 (FR-11 §2)
  static const double hitChanceMin = 0.50;

  /// 명중률 최대값 (FR-11 §2)
  static const double hitChanceMax = 0.95;

  /// 회피 확률 최소값 (FR-11 §3)
  static const double evasionChanceMin = 0.0;

  /// 회피 확률 최대값 (FR-11 §3)
  static const double evasionChanceMax = 0.75;

  /// 치명타 확률 최소값 (FR-11 §6)
  static const double critChanceMin = 0.05;

  /// 치명타 확률 최대값 (FR-11 §6)
  static const double critChanceMax = 0.60;

  /// 반격 확률 최소값 (FR-11 §4)
  static const double riposteChanceMin = 0.0;

  /// 반격 확률 최대값 (FR-11 §4)
  static const double riposteChanceMax = 0.60;

  /// 방패 막기 감소율 최대값 (FR-11 §5)
  static const double shieldMitigationMax = 0.60;

  // ============================================================================
  // §FR-10: 결정적 장면 점수 (Decisive Action Scores)
  // ============================================================================

  /// 결정적 장면 액션별 점수 (FR-10 §2)
  /// 주인공 선정 시 기여도 점수 계산용.
  static const Map<String, int> decisiveActionScores = {
    'kill': 5,
    'criticalKill': 7,
    'crit': 3,
    'shieldBlock': 2,
    'riposte': 3,
    'aoeBigDamage': 2,
    'mezApply': 2,
    'dispel': 2,
    'dotApply': 1,
  };

  // ============================================================================
  // §FR-10: toneTags 개수 매트릭스 (FR-10 §4)
  // ============================================================================

  /// QuestResult enum 값별 toneTags 개수 결정 (FR-10 §4)
  /// 보고서 라인에 반영될 톤 키워드 개수.
  static const Map<String, int> toneTagCountByResult = {
    'greatSuccess': 3,
    'success': 2,
    'failure': 1,
    'criticalFailure': 1,
  };

  // ============================================================================
  // §FR-18: 보고서 길이 매트릭스 (라운드 수 → 보고서 라인 개수)
  // ============================================================================

  /// 라운드 수 → 최종 보고서 라인 개수 (FR-18 §1)
  /// 압축 후 최대 라인 수 결정.
  static const Map<int, int> reportLengthByRoundCount = {
    3: 4,
    4: 5,
    5: 6,
    6: 7,
    7: 8,
    8: 8,
  };

  /// 보고서 길이별 5 위치 라인 분배 (FR-18 §2)
  /// position: 'entry' / 'development' / 'crisis' / 'resolution' / 'aftermath'
  /// 예: 길이 4 → entry 1 + development 1 + crisis 1 + resolution 1 + aftermath 0 = 4줄
  static const Map<int, Map<String, int>> positionDistributionByLength = {
    4: {'entry': 1, 'development': 1, 'crisis': 1, 'resolution': 1, 'aftermath': 0},
    5: {'entry': 1, 'development': 2, 'crisis': 1, 'resolution': 1, 'aftermath': 0},
    6: {'entry': 1, 'development': 2, 'crisis': 1, 'resolution': 1, 'aftermath': 1},
    7: {'entry': 1, 'development': 2, 'crisis': 2, 'resolution': 1, 'aftermath': 1},
    8: {'entry': 1, 'development': 3, 'crisis': 2, 'resolution': 1, 'aftermath': 1},
  };

  // ============================================================================
  // §FR-18: 다중 결합 압축 우선순위 (FR-18 §4)
  // ============================================================================

  /// 다중 액션 결합 라인 우선순위 (FR-18 §4)
  /// 여러 액션을 한 라인으로 압축할 때 우선순위 결정.
  static const List<String> comboCompressionPriority = [
    'kill',
    'injure',
    'aoeBigDamage',
    'isDecisive',
    'appliesStatusEffect',
    'maxDamage',
  ];

  // ============================================================================
  // 산식 노이즈 + DoT 상수 (FR-11 §7 + FR-9 §1, §5)
  // ============================================================================

  /// 피해 노이즈 계수 (FR-11 §7, 페이즈 1 #3 §5.1)
  /// baseAttack × 0.10의 범위 내에서 랜덤 노이즈 적용.
  static const double damageNoiseFactor = 0.10;

  /// 피해 노이즈 최소값 (FR-11 §7)
  static const int damageNoiseMin = 1;

  /// 피해 노이즈 최대값 (FR-11 §7)
  static const int damageNoiseMax = 5;

  /// DoT bleeding (유혈) HP 배율 계수 (FR-9 §5, 페이즈 1 #3 에서 0.04)
  /// damage = max(1, floor(maxHp × 0.04 × stack))
  static const double dotBleedingHpFactor = 0.04;

  /// DoT poisoned (중독) 기본 배수 (FR-9 §1)
  /// damage = max(1, floor(intensity × 5 + level × 2))
  static const int dotPoisonedBaseMultiplier = 5;

  /// DoT poisoned 레벨 배수 (FR-9 §1)
  static const int dotPoisonedLevelMultiplier = 2;

  /// DoT poisoned stack → intensity 매핑 (FR-17.5 absolute)
  /// stack 누적 시 intensity 값 결정.
  static const Map<int, int> dotPoisonedIntensityByStack = {
    1: 3,
    2: 5,
    3: 8,
  };

  /// DoT 최대 stack 상한 (FR-17 §3)
  static const int dotMaxStack = 3;

  /// mez_stunned 최대 지속 턴 (FR-17 §3)
  static const int mezStunnedMaxDuration = 3;

  // ============================================================================
  // §FR-6: 사기(Morale) + 선제권(Initiative) 상수
  // ============================================================================

  /// 기본 사기값 (FR-6)
  static const int moraleBase = 100;

  /// 사기 최소값 (FR-6)
  static const int moraleMin = 0;

  /// 사기 최대값 (FR-6)
  static const int moraleMax = 200;

  /// 도주 확률 판정 임계값 (FR-9 §5 (e))
  /// 사기 ≤ (moraleBase × moraleFleeRatio) 시 도주 검토.
  static const double moraleFleeRatio = 0.25;

  /// 선제권 임계값 (FR-6)
  /// |deltaScore| >= 15일 때 선제 라운드 발동.
  static const int initiativeDeltaThreshold = 15;

  /// 매복 보너스 (FR-6 §10, 페이즈 1 #2 §2.2)
  /// pool.specialFlags['ambush_side']가 'party' 또는 'enemy'일 때 +20.
  static const int ambushBonus = 20;

  // ============================================================================
  // §FR-12: PRNG 도메인 키 prefix (Seed Key)
  // ============================================================================

  /// PRNG 도메인 키: 피해 노이즈 (FR-12)
  static const String seedKeyDmg = 'dmg';

  /// PRNG 도메인 키: 명중 판정 (FR-12)
  static const String seedKeyHit = 'hit';

  /// PRNG 도메인 키: 치명타 판정 (FR-12)
  static const String seedKeyCrit = 'crit';

  /// PRNG 도메인 키: 회피 판정 (FR-12)
  static const String seedKeyEva = 'eva';

  /// PRNG 도메인 키: 방패 막기 판정 (FR-12)
  static const String seedKeyShd = 'shd';

  /// PRNG 도메인 키: 반격 판정 (FR-12)
  static const String seedKeyRip = 'rip';

  /// PRNG 도메인 키: 사망 저항 롤 (FR-12)
  static const String seedKeyDeath = 'death';

  /// PRNG 도메인 키: 행동 순서 노이즈 (FR-12)
  static const String seedKeyOrder = 'order';

  /// PRNG 도메인 키: 상태 효과 부여 확률 (FR-12)
  static const String seedKeyApply = 'apply';

  /// PRNG 도메인 키: dispel 판정 (FR-12)
  static const String seedKeyDispel = 'dispel';

  /// PRNG 도메인 키: toneTags 선택 (FR-12)
  static const String seedKeyTone = 'tone';

  /// PRNG 도메인 키: 그룹 구성(적 archetype 선택) (FR-12)
  static const String seedKeyGroup = 'group';

  // ============================================================================
  // §FR-9: 행동 순서 동률 처리 (Tiebreak)
  // ============================================================================

  /// 행동 순서 동률 처리 직업군 우선순위 (FR-9 §3)
  static const List<String> rolePriorityForTiebreak = [
    'rogue',
    'ranger',
    'warrior',
    'specialist',
    'support',
    'mage',
  ];

  // ============================================================================
  // AGI 계수 (Agility Coefficients)
  // ============================================================================

  /// AGI 명중 계수 (FR-11 §2, 페이즈 1 #3 §6.2)
  /// 공격자 AGI - 방어자 AGI 차이 per 1 = 0.8% 명중 변화.
  static const double agiHitCoef = 0.008;

  /// AGI 치명타 계수 (FR-11 §6, 페이즈 1 #3 §7.3)
  /// 공격자 AGI per 1 = 0.3% 치명타 변화.
  static const double agiCritCoef = 0.003;

  /// AGI 회피 계수 (FR-11 §3, 페이즈 1 #3 §8.2)
  /// 방어자 AGI - 공격자 AGI 차이 per 1 = 0.8% 회피 변화.
  static const double agiEvasionCoef = 0.008;

  // ============================================================================
  // 직업군 분류 (Role Classification)
  // ============================================================================

  /// 근접형 직업군 집합 (FR-16)
  /// 전열 우선 표적 정책 적용.
  static const Set<String> meleeRoles = {'warrior', 'specialist', 'rogue'};

  /// 원거리 직업군 집합 (FR-16)
  /// 자유 표적 선택 정책 적용.
  static const Set<String> rangedRoles = {'ranger', 'mage', 'support'};
}
