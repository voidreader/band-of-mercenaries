import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_stat_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

void main() {
  group('MercenaryStatService.updateStatsAfterQuest', () {
    test('success increments correct counters', () {
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.success,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 2,
        damageStatus: MercenaryStatus.tired,
        damageRoll: 0.5,
        deathRate: 0.05,
        rewardGold: 100,
        mercLevel: 2,
      );
      expect(stats['total_dispatch_count'], 1);
      expect(stats['success_count'], 1);
      expect(stats['failure_count'], isNull);
      expect(stats['team_dispatch_count'], 1);
      expect(stats['solo_dispatch_count'], isNull);
      expect(stats['raid_count'], 1);
      expect(stats['total_gold_earned'], 100);
      expect(stats['current_level'], 2);
      expect(stats['consecutive_success'], 1);
      expect(stats['consecutive_failure'], 0);
    });

    test('great success increments great_success_count', () {
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.greatSuccess,
        questTypeId: 'hunt',
        difficulty: 4,
        partySize: 1,
        damageStatus: MercenaryStatus.tired,
        damageRoll: 0.5,
        deathRate: 0.05,
        rewardGold: 200,
        mercLevel: 3,
      );
      expect(stats['great_success_count'], 1);
      expect(stats['success_count'], 1);
      expect(stats['solo_dispatch_count'], 1);
      expect(stats['high_difficulty_count'], 1);
      expect(stats['hunt_count'], 1);
    });

    test('failure resets consecutive_success', () {
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {'consecutive_success': 5, 'consecutive_failure': 0},
        resultType: QuestResult.failure,
        questTypeId: 'escort',
        difficulty: 2,
        partySize: 3,
        damageStatus: MercenaryStatus.injured,
        damageRoll: 0.08,
        deathRate: 0.05,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['consecutive_success'], 0);
      expect(stats['consecutive_failure'], 1);
      expect(stats['failure_count'], 1);
      expect(stats['injury_count'], 1);
      expect(stats['escort_count'], 1);
    });

    test('critical failure with survival tracks survived_great_failure', () {
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.criticalFailure,
        questTypeId: 'explore',
        difficulty: 5,
        partySize: 1,
        damageStatus: MercenaryStatus.injured,
        damageRoll: 0.08,
        deathRate: 0.05,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['great_failure_count'], 1);
      expect(stats['survived_great_failure'], 1);
      expect(stats['near_death_count'], 1); // 0.08 < 0.05*2=0.10
    });

    test('near_death detected when roll close to death rate', () {
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.failure,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 1,
        damageStatus: MercenaryStatus.normal,
        damageRoll: 0.09,
        deathRate: 0.05,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['near_death_count'], 1);
    });

    test('no near_death when roll is far from death rate', () {
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.failure,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 1,
        damageStatus: MercenaryStatus.normal,
        damageRoll: 0.5,
        deathRate: 0.05,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['near_death_count'], isNull);
    });
  });

  group('MercenaryStatService.updateStatsAfterTravel', () {
    test('increments travel distance and updates tier max', () {
      final stats = MercenaryStatService.updateStatsAfterTravel(
        {'total_travel_distance': 10, 'tier_max_visited': 2},
        distance: 5,
        regionTier: 3,
      );
      expect(stats['total_travel_distance'], 15);
      expect(stats['tier_max_visited'], 3);
    });

    test('tier_max_visited does not decrease', () {
      final stats = MercenaryStatService.updateStatsAfterTravel(
        {'tier_max_visited': 4},
        distance: 3,
        regionTier: 2,
      );
      expect(stats['tier_max_visited'], 4);
    });
  });
}
