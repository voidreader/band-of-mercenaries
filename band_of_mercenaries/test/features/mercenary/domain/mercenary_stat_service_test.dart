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

    // ============================================================
    // M8b 페이즈 4 #5 FR-22 — damageRoll 1.0/0.5/0.0 매핑 호환
    // 페이즈 4 #3 [FR-8] case a/b/c 변환에서 시뮬레이션 결과는
    //   case a (deceased) damageRoll=1.0
    //   case b (injured)  damageRoll=0.5
    //   case c (tired)    damageRoll=0.0
    // 으로 고정 매핑된다. updateStatsAfterQuest의 단순 threshold 비교
    // (`damageRoll < deathRate * 2`)와 호환됨을 확인한다.
    // ============================================================

    test('FR-22 case a (damageRoll 1.0, dead) → near_death 미증가 (dead guard)', () {
      // 시뮬레이션 사망 케이스: damageStatus == dead.
      // updateStatsAfterQuest line 69 guard로 near_death_count 증가 안 함.
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.criticalFailure,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 1,
        damageStatus: MercenaryStatus.dead,
        damageRoll: 1.0,
        deathRate: 0.3,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['near_death_count'], isNull, reason: 'dead guard로 미증가');
      expect(stats['injury_count'], isNull, reason: 'dead는 injured 아님');
    });

    test('FR-22 case a + legendary canPrevent (damageRoll 1.0, injured) → injury_count 증가', () {
      // legendary ⑤로 dead→injured 다운그레이드된 케이스.
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.criticalFailure,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 1,
        damageStatus: MercenaryStatus.injured,
        damageRoll: 1.0,
        deathRate: 0.3,
        rewardGold: 0,
        mercLevel: 1,
      );
      // damageRoll(1.0) < deathRate*2(0.6) → false → near_death 미증가.
      // damageStatus == injured → injury_count 증가.
      expect(stats['injury_count'], equals(1), reason: 'injured → injury_count');
      expect(
        stats['near_death_count'],
        isNull,
        reason: 'damageRoll 1.0은 deathRate*2(0.6)보다 크므로 미증가',
      );
    });

    test('FR-22 case b (damageRoll 0.5, injured) → injury_count 증가, threshold 비교 정상', () {
      // 시뮬레이션 부상 케이스.
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.failure,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 1,
        damageStatus: MercenaryStatus.injured,
        damageRoll: 0.5,
        deathRate: 0.3,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['injury_count'], equals(1), reason: 'injured → injury_count');
      // damageRoll(0.5) < deathRate*2(0.6) → true → near_death 증가.
      expect(stats['near_death_count'], equals(1), reason: 'threshold 통과');
    });

    test('FR-22 case c (damageRoll 0.0, tired) → injury_count 미증가, threshold 통과', () {
      // 시뮬레이션 무사 케이스(생존 + 부상 없음).
      final stats = MercenaryStatService.updateStatsAfterQuest(
        {},
        resultType: QuestResult.failure,
        questTypeId: 'raid',
        difficulty: 3,
        partySize: 1,
        damageStatus: MercenaryStatus.tired,
        damageRoll: 0.0,
        deathRate: 0.3,
        rewardGold: 0,
        mercLevel: 1,
      );
      expect(stats['injury_count'], isNull, reason: 'tired는 injured 아님');
      // damageRoll(0.0) < deathRate*2(0.6) → true → near_death 증가.
      // isFailure인 무사 케이스(도주)에서 "죽음의 문턱" 카운트 자연 발생.
      expect(stats['near_death_count'], equals(1));
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
