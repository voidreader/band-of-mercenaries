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
    for (final conflictId in conflictFactionIds) {
      if (currentlyJoinedFactionIds.contains(conflictId)) return false;
    }
    if (currentlyJoinedFactionIds.length >= 3) return false;
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

  /// passiveBonusJson을 한국어 설명 문자열로 변환
  static String describePassiveBonus(Map<String, dynamic> json) {
    if (json.isEmpty) return '';
    final parts = <String>[];
    void add(String key, String desc) {
      final val = json[key];
      if (val != null) parts.add(desc.replaceAll('{v}', val.toString()));
    }
    add('explore_reward_pct', '탐험 퀘스트 보상 +{v}%');
    add('escort_reward_pct', '호위 퀘스트 보상 +{v}%');
    add('raid_hunt_success_pct', '약탈/토벌 퀘스트 성공률 +{v}%');
    add('idle_reward_pct', '방치 보상 +{v}%');
    add('investigation_success_pct', '지역 조사 성공률 +{v}%');
    add('travel_damage_pct', '이동 이벤트 피해 -{v}%');
    add('injury_recovery_pct', '부상 회복 속도 +{v}%');
    add('all_quest_success_pct', '모든 퀘스트 성공률 +{v}%');
    add('trait_evolution_ease_pct', '트레잇 진화 조건 완화 {v}%');
    add('trait_acquisition_ease_pct', '트레잇 획득 조건 완화 {v}%');
    add('construction_time_pct', '시설 건설 시간 -{v}%');
    add('construction_cost_pct', '시설 건설 비용 -{v}%');
    add('facility_effect_pct', '시설 효과 +{v}%');
    add('high_tier_recruit_pct', 'T4~T5 용병 모집 확률 +{v}%');
    add('group_success_pct', '3명 이상 파견 시 성공률 +{v}%');
    add('raid_reward_pct', '약탈 퀘스트 보상 +{v}%');
    add('escort_success_pct', '호위 퀘스트 성공률 +{v}%');
    add('injury_recovery_time_pct', '부상 회복 시간 -{v}%');
    return parts.join('\n');
  }
}
