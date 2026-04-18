import 'package:band_of_mercenaries/core/models/rank.dart';

/// 현재 평판에 기반한 Rank 조회 유틸 (UI 표시용).
class RankHelper {
  /// 현재 평판에 해당하는 최상위 랭크의 `grade` 반환. 없으면 'F'.
  static String getCurrentRankGrade(int reputation, List<Rank> ranks) {
    final rank = getCurrentRank(reputation, ranks);
    return rank?.grade ?? 'F';
  }

  /// 현재 평판에 해당하는 최상위 Rank 객체 반환. 리스트 비어있으면 null.
  static Rank? getCurrentRank(int reputation, List<Rank> ranks) {
    if (ranks.isEmpty) return null;
    final sorted = [...ranks]..sort(
      (a, b) => a.requiredReputation.compareTo(b.requiredReputation),
    );
    Rank? current;
    for (final rank in sorted) {
      if (reputation >= rank.requiredReputation) {
        current = rank;
      } else {
        break;
      }
    }
    return current ?? sorted.first;
  }
}
