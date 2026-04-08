import 'package:band_of_mercenaries/core/models/rank.dart';

class ReputationService {
  static Rank getCurrentRank(int reputation, List<Rank> ranks) {
    Rank current = ranks.first;
    for (final rank in ranks) {
      if (reputation >= rank.requiredReputation) current = rank;
    }
    return current;
  }

  static int getMaxUnlockedTier(int reputation, List<Rank> ranks) {
    return getCurrentRank(reputation, ranks).unlockTier;
  }

  static bool isRegionAccessible(int regionTier, int reputation, List<Rank> ranks) {
    return regionTier <= getMaxUnlockedTier(reputation, ranks);
  }

  static int calculateQuestReputation({required int difficulty, required bool isGreatSuccess}) {
    return difficulty * (isGreatSuccess ? 20 : 10);
  }

  static Rank? getNextRank(int reputation, List<Rank> ranks) {
    final current = getCurrentRank(reputation, ranks);
    final idx = ranks.indexOf(current);
    if (idx >= ranks.length - 1) return null;
    return ranks[idx + 1];
  }
}
