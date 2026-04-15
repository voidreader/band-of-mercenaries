import 'dart:math';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class MercenaryStatService {
  static const _questTypeMetricMap = <String, String>{
    'raid': 'raid_count',
    'hunt': 'hunt_count',
    'escort': 'escort_count',
    'explore': 'explore_count',
  };

  static Map<String, int> updateStatsAfterQuest(
    Map<String, int> current, {
    required QuestResult resultType,
    required String questTypeId,
    required int difficulty,
    required int partySize,
    required MercenaryStatus damageStatus,
    required double damageRoll,
    required double deathRate,
    required int rewardGold,
    required int mercLevel,
  }) {
    final stats = Map<String, int>.from(current);

    final isSuccess = resultType == QuestResult.greatSuccess || resultType == QuestResult.success;
    final isFailure = resultType == QuestResult.failure || resultType == QuestResult.criticalFailure;

    stats['total_dispatch_count'] = (stats['total_dispatch_count'] ?? 0) + 1;

    if (isSuccess) {
      stats['success_count'] = (stats['success_count'] ?? 0) + 1;
    }
    if (isFailure) {
      stats['failure_count'] = (stats['failure_count'] ?? 0) + 1;
    }
    if (resultType == QuestResult.greatSuccess) {
      stats['great_success_count'] = (stats['great_success_count'] ?? 0) + 1;
    }
    if (resultType == QuestResult.criticalFailure) {
      stats['great_failure_count'] = (stats['great_failure_count'] ?? 0) + 1;
    }

    if (partySize == 1) {
      stats['solo_dispatch_count'] = (stats['solo_dispatch_count'] ?? 0) + 1;
    } else {
      stats['team_dispatch_count'] = (stats['team_dispatch_count'] ?? 0) + 1;
    }

    if (difficulty >= 4 && isSuccess) {
      stats['high_difficulty_count'] = (stats['high_difficulty_count'] ?? 0) + 1;
    }
    if (difficulty <= 2 && isSuccess) {
      stats['low_difficulty_count'] = (stats['low_difficulty_count'] ?? 0) + 1;
    }

    final metricKey = _questTypeMetricMap[questTypeId];
    if (metricKey != null) {
      stats[metricKey] = (stats[metricKey] ?? 0) + 1;
    }

    // near_death: survived but roll was within 2x death threshold
    if (isFailure && damageStatus != MercenaryStatus.dead && deathRate > 0) {
      if (damageRoll < deathRate * 2) {
        stats['near_death_count'] = (stats['near_death_count'] ?? 0) + 1;
      }
    }

    if (damageStatus == MercenaryStatus.injured) {
      stats['injury_count'] = (stats['injury_count'] ?? 0) + 1;
    }

    if (resultType == QuestResult.criticalFailure && damageStatus != MercenaryStatus.dead) {
      stats['survived_great_failure'] = (stats['survived_great_failure'] ?? 0) + 1;
    }

    if (isSuccess && rewardGold > 0) {
      stats['total_gold_earned'] = (stats['total_gold_earned'] ?? 0) + rewardGold;
    }

    stats['current_level'] = mercLevel;

    if (isSuccess) {
      stats['consecutive_success'] = (stats['consecutive_success'] ?? 0) + 1;
      stats['consecutive_failure'] = 0;
    } else if (isFailure) {
      stats['consecutive_failure'] = (stats['consecutive_failure'] ?? 0) + 1;
      stats['consecutive_success'] = 0;
    }

    return stats;
  }

  static Map<String, int> updateStatsAfterTravel(
    Map<String, int> current, {
    required int distance,
    required int regionTier,
  }) {
    final stats = Map<String, int>.from(current);
    stats['total_travel_distance'] = (stats['total_travel_distance'] ?? 0) + distance;
    stats['tier_max_visited'] = max(stats['tier_max_visited'] ?? 0, regionTier);
    return stats;
  }

  static Map<String, int> updateStatsForFacilityBenefit(
    Map<String, int> current, {
    required Map<String, int> facilities,
    required bool isFailure,
    required MercenaryStatus damageStatus,
  }) {
    final stats = Map<String, int>.from(current);

    if ((facilities['training'] ?? 0) > 0) {
      stats['training_benefit_count'] = (stats['training_benefit_count'] ?? 0) + 1;
    }

    if ((facilities['infirmary'] ?? 0) > 0 && damageStatus == MercenaryStatus.injured) {
      stats['infirmary_recovery_count'] = (stats['infirmary_recovery_count'] ?? 0) + 1;
    }

    if ((facilities['field_hospital'] ?? 0) > 0 &&
        isFailure &&
        damageStatus != MercenaryStatus.dead &&
        damageStatus != MercenaryStatus.injured) {
      stats['field_hospital_benefit_count'] = (stats['field_hospital_benefit_count'] ?? 0) + 1;
    }

    return stats;
  }
}
