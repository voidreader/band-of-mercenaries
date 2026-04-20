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

  /// 퀘스트 명성 획득량 계산.
  /// [reputationGainModifier]는 용병단 장비 등에서 가산 수집된 수정자(0.0~0.30 상한).
  /// 내부에서 clamp 후 `base × (1 + modifier)` 적용.
  static int calculateQuestReputation({
    required int difficulty,
    required bool isGreatSuccess,
    double reputationGainModifier = 0.0,
  }) {
    final base = difficulty * (isGreatSuccess ? 20 : 10);
    return (base * (1.0 + reputationGainModifier.clamp(0.0, 0.30))).round();
  }

  static Rank? getNextRank(int reputation, List<Rank> ranks) {
    final current = getCurrentRank(reputation, ranks);
    final idx = ranks.indexOf(current);
    if (idx >= ranks.length - 1) return null;
    return ranks[idx + 1];
  }

  /// F부터 현재 도달한 랭크까지의 리스트 반환 (requiredReputation 오름차순).
  /// PassiveBonusService 연동용.
  static List<Rank> getRankChain(int reputation, List<Rank> ranks) {
    final sorted = [...ranks]
      ..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
    final result = <Rank>[];
    for (final rank in sorted) {
      if (reputation >= rank.requiredReputation) {
        result.add(rank);
      } else {
        break;
      }
    }
    return result;
  }

  /// 현재 랭크의 인덱스(F=0, E=1, ...). 빈 체인 시 -1.
  static int getRankLevel(int reputation, List<Rank> ranks) {
    final chain = getRankChain(reputation, ranks);
    return chain.length - 1;
  }
}
