import 'package:band_of_mercenaries/features/investigation/domain/danger_level.dart';

/// M7 페이즈 4 #2 — QuestGenerator 가중치 계산 정적 상수
///
/// 지역 상태(위험도, 플래그)에 따른 의뢰 유형별 가중치 계산.
/// 페이즈 2 #2 기획서의 4절(위험도 매트릭스) + 6절(플래그 효과) 참조.
class RegionStateWeightConfig {
  RegionStateWeightConfig._();

  /// 위험도 × quest_type 가중치 매트릭스 (페이즈 2 #2 4절)
  ///
  /// threat/tension 단계에서 raid/hunt 의뢰 확률 증대.
  /// stable/peaceful 단계에서 escort/explore 의뢰 확률 증대.
  static const Map<DangerLevel, Map<String, double>> dangerLevelMultiplier = {
    DangerLevel.threat: {
      'raid': 3.0,
      'hunt': 3.0,
      'escort': 1.5,
      'explore': 1.5,
    },
    DangerLevel.tension: {
      'raid': 2.0,
      'hunt': 2.0,
      'escort': 1.3,
      'explore': 1.3,
    },
    DangerLevel.peaceful: {
      'raid': 1.0,
      'hunt': 1.0,
      'escort': 1.2,
      'explore': 1.0,
    },
    DangerLevel.stable: {
      'raid': 0.3,
      'hunt': 0.5,
      'escort': 1.5,
      'explore': 1.3,
    },
  };

  /// 플래그별 quest_type 가중치 조정 (페이즈 2 #2 6절)
  ///
  /// 8개 플래그 × 1~2개 quest_type = 14쌍.
  /// 누적 상한 도달 후 이 값들은 0.2배 축소 적용.
  static const Map<String, Map<String, double>> flagMultipliers = {
    'region_3_pyegwang_reopen_completed': {'hunt': 0.7, 'escort': 1.2},
    'region_31_bandits_cleared': {'raid': 0.3, 'escort': 1.5},
    'region_31_shrine_quest_completed': {'explore': 1.3},
    'region_127_nomad_friendly': {'escort': 1.3, 'raid': 0.5},
    'region_9_giant_beast_killed': {'hunt': 0.5, 'escort': 1.2},
    'region_10_windrunner_chain_completed': {'explore': 1.3},
    'region_146_mist_cleared': {'explore': 1.3, 'hunt': 0.7},
    'region_38_ironbound_pact_completed': {'raid': 0.5, 'explore': 1.2},
  };

  /// cumulative cap 도달 후 노출 빈도 축소 계수
  ///
  /// 일정 횟수 이상 의뢰가 노출된 지역은 flagMultipliers 효과를
  /// 0.2배로 축소하여 다양성 증가.
  static const double cumulativeCapReachedMultiplier = 0.2;
}
