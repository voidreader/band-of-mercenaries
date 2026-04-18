import 'dart:math';

import '../../../core/constants/game_constants.dart';

/// 일반 퀘스트에 런타임으로 세력 태그를 부여하는 선정 로직.
class FactionTagResolver {
  FactionTagResolver._();

  /// 일반 퀘스트에 부여할 세력 태그를 결정한다.
  /// 반환: 세력 ID (부여) 또는 null (미부여, 일반 퀘스트로 유지).
  static String? resolve({
    required int regionId,
    required List<String> joinedFactionIds,
    required Map<String, int> clueLevelsInRegion, // factionId -> clueLevel
    required List<String> hostileFactionIds,       // 평판 -100 세력
    required int proximityTier,                    // 1~4 (거점 거리, M1 범위는 3)
    required Random random,
  }) {
    // 1. 단서 보유 후보 수집 (clueLevel >= 1 && 적대 아님)
    final candidates = clueLevelsInRegion.entries
        .where((e) => e.value >= 1)
        .map((e) => e.key)
        .where((id) => !hostileFactionIds.contains(id))
        .toList();
    if (candidates.isEmpty) return null;

    // 2. 가입 세력 우선 경로 (확률 100%)
    final joinedCandidates =
        candidates.where((id) => joinedFactionIds.contains(id)).toList();
    if (joinedCandidates.isNotEmpty) {
      return joinedCandidates[random.nextInt(joinedCandidates.length)];
    }

    // 3. 비가입 세력: 거점 근접도 기반 확률
    final prob = _probabilityFor(proximityTier);
    if (random.nextDouble() > prob) return null;

    // 4. 균등 랜덤 (M1 단순화)
    return candidates[random.nextInt(candidates.length)];
  }

  /// 태그 퀘스트(가입 외) 평판 획득량.
  /// proximityTier 1~2 → +2, 3~4 → +1.
  static int tagReputationGain(int proximityTier) =>
      proximityTier <= 2 ? 2 : 1;

  static double _probabilityFor(int proximityTier) {
    switch (proximityTier) {
      case 1:
        return GameConstants.tagProbNear;
      case 2:
        return GameConstants.tagProbMid;
      case 3:
        return GameConstants.tagProbFar;
      case 4:
        return GameConstants.tagProbVeryFar;
      default:
        return GameConstants.tagProbFar;
    }
  }
}
