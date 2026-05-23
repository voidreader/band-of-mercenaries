/// M8.5 페이즈 4 #2 — 솔로/소수정예 의뢰 정적 설정.
///
/// 솔로(1인)·페어(2인)·삼인행(3인) 지명 의뢰의 사망 저항 cap, 가중치 α,
/// 쿨다운, 보장/확률 드랍 매핑, 후속 메시지를 단일 진실 공급원으로 보관한다.
///
/// DB(`quest_pools.special_flags`)와 코드 fallback 양쪽에 동일 값이 존재할 때
/// DB가 우선이며, 본 클래스의 상수는 fallback 또는 코드 전용 매트릭스로 활용한다.
class FlagshipSoloQuestConfig {
  FlagshipSoloQuestConfig._();

  /// 솔로(1인) 의뢰 사망 저항 cap. [0.20, 0.95] 상한.
  static const double soloDeathResistanceCap = 0.95;

  /// 소수정예(2~3인) 의뢰 사망 저항 cap. [0.20, 0.90] 상한.
  static const double smallPartyDeathResistanceCap = 0.90;

  /// 솔로 의뢰 가중치 α (M6 지명 +3.0 대신).
  static const double soloNamedWeightAlpha = 2.0;

  /// 소수정예 의뢰 가중치 α (M6 지명 +3.0 대신).
  static const double smallPartyNamedWeightAlpha = 2.0;

  /// 솔로 의뢰 발급 쿨다운 (시간).
  static const int soloCooldownHours = 48;

  /// 소수정예 의뢰 발급 쿨다운 (시간).
  static const int smallPartyCooldownHours = 36;

  /// pool.id → (partySizeMin, partySizeMax) 매트릭스.
  /// DB 시드와 동일한 값이지만, 코드 측 검증·UI 분기용 빠른 참조로 활용한다.
  static const partySizeMatrix = <String, ({int min, int max})>{
    'qp_solo_lone_wolf_letter': (min: 1, max: 1),
    'qp_solo_legend_continued': (min: 1, max: 1),
    'qp_solo_flagship_request': (min: 1, max: 1),
    'qp_pair_shadow_couple': (min: 2, max: 2),
    'qp_small_three_kings_march': (min: 3, max: 3),
  };

  /// pool.id → 보장 드랍 itemId (성공/대성공 시 항상 지급).
  /// [FR-19] 참조. 중복 보유 시 대체 골드 변환.
  static const guaranteedDropMatrix = <String, String>{
    'qp_solo_lone_wolf_letter': 'equip_accessory_red_spear_wristwrap',
    'qp_solo_legend_continued': 'guild_artifact_trade_seal',
    'qp_solo_flagship_request': 'guild_artifact_merchant_warrant',
  };

  /// pool.id → (itemId, 확률) 확률 드랍 (성공/대성공 시 확률 적용).
  /// [FR-20] 참조. 정확한 수치는 페이즈 3 #4 확정, 현재 0.05~0.10 임시 고정.
  static const probabilisticDropMatrix =
      <String, ({String itemId, double chance})>{
    'qp_solo_lone_wolf_letter':
        (itemId: 'guild_artifact_lone_wolf_compass', chance: 0.10),
    'qp_solo_legend_continued':
        (itemId: 'guild_artifact_lone_wolf_compass', chance: 0.05),
    'qp_solo_flagship_request':
        (itemId: 'guild_artifact_three_kings_seal', chance: 0.08),
  };

  /// pool.id → 결과 다이얼로그 또는 ActivityLog 후속 메시지.
  /// [FR-21] 참조. M9+ 확장 시 추가 entry 삽입.
  static const epilogueMessages = <String, String>{
    'qp_solo_lone_wolf_letter': '외로운 늑대의 이름이 또 한 번 입에 오르내렸다.',
  };
}
