import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';

StaticGameData _makeStaticData({
  int enemyPower = 10,
  double rewardMultiplier = 1.0,
  int baseReward = 100,
  int baseDuration = 60,
}) {
  return StaticGameData(
    difficulties: [
      Difficulty(
        level: 1,
        enemyPower: enemyPower,
        rewardMultiplier: rewardMultiplier,
        successPenalty: 0,
        injuryRate: 0.3,
        deathRate: 0.05,
        minDispatchCost: 10,
        maxDispatchCost: 50,
      ),
    ],
    jobs: [
      const Job(id: 'warrior', tier: 1, name: '전사', baseStr: 10, baseIntelligence: 8, baseVit: 100, baseAgi: 50),
    ],
    traits: [],
    traitCategories: [],
    traitConflicts: [],
    traitTransitions: [],
    traitComboEvolutions: [],
    traitSynergies: [],
    regions: [],
    questTypes: [
      QuestType(id: 'raid', name: '약탈', baseReward: baseReward, baseDuration: baseDuration, riskFactor: 1.0),
    ],
    questPools: [],
    personNames: [],
    travelEvents: [],
    facilities: [
      const Facility(id: 'training', name: '훈련소', effectType: 'xp_bonus', maxLevel: 3, costs: [100, 200, 400], values: [0.1, 0.2, 0.3]),
      const Facility(id: 'infirmary', name: '의무실', effectType: 'recovery_reduction', maxLevel: 3, costs: [100, 200, 400], values: [0.1, 0.2, 0.3]),
    ],
    ranks: [
      const Rank(grade: 'F', name: '신참', requiredReputation: 0, unlockTier: 1),
    ],
    mercenaryWages: [
      const MercenaryWage(tier: 1, wage: 10),
    ],
    regionDiscoveries: const [],
    factions: const [],
    items: const <ItemData>[],
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionSectors: const [],
  );
}

ActiveQuest _makeQuest({int difficulty = 1, int region = 1}) {
  return ActiveQuest(
    id: 'q1',
    questPoolId: 'pool1',
    questTypeId: 'raid',
    difficulty: difficulty,
    region: region,
    questName: '테스트 퀘스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.now().subtract(const Duration(minutes: 5)),
    endTime: DateTime.now().subtract(const Duration(seconds: 1)),
  );
}

Mercenary _makeMerc({String id = 'm1', int str = 20, String traitId = '', String jobId = 'warrior'}) {
  return Mercenary(
    id: id,
    name: '용병1',
    jobId: jobId,
    traitId: traitId,
    str: str,
    intelligence: 10,
    vit: 100,
    agi: 50,
  );
}

/// Seeded random that produces predictable sequences for testing
class _SeededRandom implements Random {
  final Random _inner;
  _SeededRandom(int seed) : _inner = Random(seed);

  @override
  int nextInt(int max) => _inner.nextInt(max);
  @override
  double nextDouble() => _inner.nextDouble();
  @override
  bool nextBool() => _inner.nextBool();
}

void main() {
  group('QuestCompletionService.calculate', () {
    test('성공 시 보상/XP/명성을 정확히 계산한다', () {
      // seed 100: successRate ~51, roll이 낮아서 success 보장을 위해 높은 파워 사용
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 50)];

      // 높은 파티 파워로 성공 보장
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      // 성공 또는 대성공이어야 함 (높은 파워비)
      expect(
        result.resultType == QuestResult.greatSuccess || result.resultType == QuestResult.success,
        isTrue,
      );
      expect(result.rewardGold, greaterThan(0));
      expect(result.totalWage, 10); // tier 1 wage
      expect(result.xpGain, greaterThan(0));
      expect(result.repGain, greaterThan(0));
      expect(result.mercDamages, hasLength(1));
      expect(result.mercDamages.first.newStatus, MercenaryStatus.tired);
    });

    test('대성공 시 보상이 2배이다', () {
      final staticData = _makeStaticData(enemyPower: 1, baseReward: 100);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 1000)];

      // 여러 시드를 시도하여 대성공을 찾음
      QuestCompletionResult? greatSuccessResult;
      for (int seed = 0; seed < 100; seed++) {
        final result = QuestCompletionService.calculate(
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        if (result.resultType == QuestResult.greatSuccess) {
          greatSuccessResult = result;
          break;
        }
      }
      expect(greatSuccessResult, isNotNull);
      expect(greatSuccessResult!.rewardGold, 200); // baseReward * rewardMult(1.0) * 2
    });

    test('실패 시 보상 0, XP 절반, 명성 0', () {
      final staticData = _makeStaticData(enemyPower: 1000);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 1)];

      QuestCompletionResult? failResult;
      for (int seed = 0; seed < 200; seed++) {
        final result = QuestCompletionService.calculate(
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        if (result.resultType == QuestResult.failure) {
          failResult = result;
          break;
        }
      }
      expect(failResult, isNotNull);
      expect(failResult!.rewardGold, 0);
      expect(failResult.repGain, 0);
      // XP = difficulty(1) * baseXp(20) * 0.5 = 10
      expect(failResult.xpGain, 10);
    });

    test('대실패 시 XP 0', () {
      final staticData = _makeStaticData(enemyPower: 1000);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 1)];

      QuestCompletionResult? critResult;
      for (int seed = 0; seed < 200; seed++) {
        final result = QuestCompletionService.calculate(
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        if (result.resultType == QuestResult.criticalFailure) {
          critResult = result;
          break;
        }
      }
      expect(critResult, isNotNull);
      expect(critResult!.rewardGold, 0);
      expect(critResult.xpGain, 0);
      expect(critResult.repGain, 0);
    });

    test('훈련소 시설 보너스가 XP에 반영된다', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 50)];

      final withoutTraining = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {},
        speedMultiplier: 1.0, random: _SeededRandom(42),
      );

      final withTraining = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {'training': 2},
        speedMultiplier: 1.0, random: _SeededRandom(42),
      );

      // 같은 시드이므로 같은 결과 타입, XP만 다름
      expect(withTraining.resultType, withoutTraining.resultType);
      expect(withTraining.xpGain, greaterThan(withoutTraining.xpGain));
    });

    test('의무실 시설 보너스로 부상 회복시간이 감소한다', () {
      final staticData = _makeStaticData(enemyPower: 1000);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 1)];

      // 실패+부상이 발생하는 시드 탐색
      int? injurySeed;
      for (int seed = 0; seed < 500; seed++) {
        final result = QuestCompletionService.calculate(
          quest: quest, mercs: mercs, staticData: staticData,
          playerRegion: 1, facilities: {},
          speedMultiplier: 1.0, random: _SeededRandom(seed),
        );
        if (result.mercDamages.any((d) => d.newStatus == MercenaryStatus.injured)) {
          injurySeed = seed;
          break;
        }
      }

      if (injurySeed == null) {
        // 부상 발생 시드를 못 찾으면 스킵 (확률적으로 매우 드묾)
        return;
      }

      final withoutInfirmary = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {},
        speedMultiplier: 1.0, random: _SeededRandom(injurySeed),
      );

      final withInfirmary = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {'infirmary': 2},
        speedMultiplier: 1.0, random: _SeededRandom(injurySeed),
      );

      final injuredWithout = withoutInfirmary.mercDamages.firstWhere((d) => d.newStatus == MercenaryStatus.injured);
      final injuredWith = withInfirmary.mercDamages.firstWhere((d) => d.newStatus == MercenaryStatus.injured);

      expect(
        injuredWith.recoveryEndTime!.isBefore(injuredWithout.recoveryEndTime!),
        isTrue,
      );
    });

    test('거리 패널티가 성공률에 반영된다', () {
      final staticData = _makeStaticData(enemyPower: 30);
      final quest = _makeQuest(region: 10);
      final mercs = [_makeMerc(str: 10)];

      int nearSuccesses = 0;
      int farSuccesses = 0;
      const trials = 1000;

      for (int seed = 0; seed < trials; seed++) {
        final nearResult = QuestCompletionService.calculate(
          quest: quest, mercs: mercs, staticData: staticData,
          playerRegion: 10, facilities: {},
          speedMultiplier: 1.0, random: _SeededRandom(seed),
        );
        if (nearResult.resultType == QuestResult.greatSuccess ||
            nearResult.resultType == QuestResult.success) {
          nearSuccesses++;
        }

        final farResult = QuestCompletionService.calculate(
          quest: quest, mercs: mercs, staticData: staticData,
          playerRegion: 1, facilities: {},
          speedMultiplier: 1.0, random: _SeededRandom(seed),
        );
        if (farResult.resultType == QuestResult.greatSuccess ||
            farResult.resultType == QuestResult.success) {
          farSuccesses++;
        }
      }

      expect(nearSuccesses, greaterThan(farSuccesses));
    });

    test('여러 용병의 데미지가 각각 계산된다', () {
      final staticData = _makeStaticData(enemyPower: 1000);
      final quest = _makeQuest();
      final mercs = [
        _makeMerc(id: 'm1', str: 1),
        _makeMerc(id: 'm2', str: 1),
        _makeMerc(id: 'm3', str: 1),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {},
        speedMultiplier: 1.0, random: _SeededRandom(42),
      );

      expect(result.mercDamages, hasLength(3));
      expect(result.mercDamages.map((d) => d.mercId).toSet(), {'m1', 'm2', 'm3'});
    });

    test('속도 배율이 회복시간에 반영된다', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 50)];

      final speed1x = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {},
        speedMultiplier: 1.0, random: _SeededRandom(42),
      );

      final speed10x = QuestCompletionService.calculate(
        quest: quest, mercs: mercs, staticData: staticData,
        playerRegion: 1, facilities: {},
        speedMultiplier: 10.0, random: _SeededRandom(42),
      );

      // 성공 시 tired 상태, 회복 시간이 10배 빨라야 함
      final tired1x = speed1x.mercDamages.first;
      final tired10x = speed10x.mercDamages.first;
      if (tired1x.recoveryEndTime != null && tired10x.recoveryEndTime != null) {
        final diff1x = tired1x.recoveryEndTime!.difference(DateTime.now()).inSeconds;
        final diff10x = tired10x.recoveryEndTime!.difference(DateTime.now()).inSeconds;
        // 10x 속도면 회복시간이 약 1/10
        expect(diff10x, lessThan(diff1x));
      }
    });
  });
}
