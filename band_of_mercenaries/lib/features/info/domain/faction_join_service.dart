// band_of_mercenaries/lib/features/info/domain/faction_join_service.dart

class FactionJoinService {
  static const int maxReputationBeforeJoin = 10;
  static const int minReputation = -100;
  static const int maxReputation = 100;

  static const List<String> _rankOrder = ['F', 'E', 'D', 'C', 'B', 'A'];

  /// 가입 가능 여부 판별
  static bool canJoin({
    required String factionId,
    required int reputation,
    required bool joinNeedsClue,
    required int maxClueLevel,
    required String? joinRankMin,
    required String currentRank,
    required List<String> conflictFactionIds,
    required List<String> currentlyJoinedFactionIds,
  }) {
    if (reputation <= 0) return false;
    if (joinNeedsClue && maxClueLevel < 3) return false;
    if (joinRankMin != null && !isRankSufficient(currentRank, joinRankMin)) {
      return false;
    }
    // 충돌 세력은 가입 시 자동 탈퇴되므로 유효 가입 수 계산에서 제외
    final conflictSet = conflictFactionIds.toSet();
    final effectiveJoined = currentlyJoinedFactionIds
        .where((id) => !conflictSet.contains(id))
        .length;
    if (effectiveJoined >= 3) return false;
    return true;
  }

  /// 평판 클램핑 (미가입 시 최대 10, 가입 후 최대 100)
  static int clampReputation(int rep, {required bool joined}) {
    final cap = joined ? maxReputation : maxReputationBeforeJoin;
    return rep.clamp(minReputation, cap);
  }

  /// 랭크 충분 여부 (currentRank >= requiredRank)
  static bool isRankSufficient(String currentRank, String requiredRank) {
    final currentIdx = _rankOrder.indexOf(currentRank);
    final requiredIdx = _rankOrder.indexOf(requiredRank);
    if (currentIdx < 0 || requiredIdx < 0) return false;
    return currentIdx >= requiredIdx;
  }
}
