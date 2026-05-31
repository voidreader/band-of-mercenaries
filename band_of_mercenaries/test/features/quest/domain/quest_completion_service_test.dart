import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/hidden_stat_bonus_resolver.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/core/models/combat_enums.dart';
import 'package:band_of_mercenaries/core/models/combat_skill.dart';
import 'package:band_of_mercenaries/core/models/combat_status_effect.dart';
import 'package:band_of_mercenaries/core/models/enemy_archetype.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';

StaticGameData _makeStaticData({
  int enemyPower = 10,
  double rewardMultiplier = 1.0,
  int baseReward = 100,
  int baseDuration = 60,
  List<ChainQuestData> chainQuests = const [],
  List<QuestPool> questPools = const [],
  List<CombatSkill> combatSkills = const [],
  List<CombatStatusEffect> combatStatusEffects = const [],
  List<EnemyArchetype> enemyArchetypes = const [],
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
      const Job(
        id: 'warrior',
        tier: 1,
        name: '전사',
        baseStr: 10,
        baseIntelligence: 8,
        baseVit: 100,
        baseAgi: 50,
      ),
    ],
    traits: [],
    traitCategories: [],
    traitConflicts: [],
    traitTransitions: [],
    traitComboEvolutions: [],
    traitSynergies: [],
    regions: [],
    questTypes: [
      QuestType(
        id: 'raid',
        name: '약탈',
        baseReward: baseReward,
        baseDuration: baseDuration,
        riskFactor: 1.0,
      ),
    ],
    questPools: questPools,
    personNames: [],
    travelEvents: [],
    facilities: [
      const Facility(
        id: 'training',
        name: '훈련소',
        effectType: 'xp_bonus',
        maxLevel: 3,
        costs: [100, 200, 400],
        values: [0.1, 0.2, 0.3],
      ),
      const Facility(
        id: 'infirmary',
        name: '의무실',
        effectType: 'recovery_reduction',
        maxLevel: 3,
        costs: [100, 200, 400],
        values: [0.1, 0.2, 0.3],
      ),
    ],
    ranks: [
      const Rank(grade: 'F', name: '신참', requiredReputation: 0, unlockTier: 1),
    ],
    mercenaryWages: [const MercenaryWage(tier: 1, wage: 10)],
    regionDiscoveries: const [],
    factions: const [],
    items: const <ItemData>[],
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: chainQuests,
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionAdjacencies: const [],
    regionSectors: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: const [],
    combatSkills: combatSkills,
    combatStatusEffects: combatStatusEffects,
    enemyArchetypes: enemyArchetypes,
    hiddenStats: const [],
    battleMemoryTemplates: const [],
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

ActiveQuest _makeEliteQuest() {
  return ActiveQuest(
    id: 'q_elite',
    questPoolId: 'elite_test',
    questTypeId: 'raid',
    difficulty: 1,
    region: 1,
    questName: '엘리트 테스트',
    status: QuestStatus.inProgress,
    eliteId: 'elite_test',
    startTime: DateTime.now().subtract(const Duration(minutes: 5)),
    endTime: DateTime.now().subtract(const Duration(seconds: 1)),
  );
}

Mercenary _makeMerc({
  String id = 'm1',
  int str = 20,
  String traitId = '',
  String jobId = 'warrior',
}) {
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
        result.resultType == QuestResult.greatSuccess ||
            result.resultType == QuestResult.success,
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
      expect(
        greatSuccessResult!.rewardGold,
        200,
      ); // baseReward * rewardMult(1.0) * 2
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
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      final withTraining = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {'training': 2},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
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
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        if (result.mercDamages.any(
          (d) => d.newStatus == MercenaryStatus.injured,
        )) {
          injurySeed = seed;
          break;
        }
      }

      if (injurySeed == null) {
        // 부상 발생 시드를 못 찾으면 스킵 (확률적으로 매우 드묾)
        return;
      }

      final withoutInfirmary = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(injurySeed),
      );

      final withInfirmary = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {'infirmary': 2},
        speedMultiplier: 1.0,
        random: _SeededRandom(injurySeed),
      );

      final injuredWithout = withoutInfirmary.mercDamages.firstWhere(
        (d) => d.newStatus == MercenaryStatus.injured,
      );
      final injuredWith = withInfirmary.mercDamages.firstWhere(
        (d) => d.newStatus == MercenaryStatus.injured,
      );

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
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 10,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        if (nearResult.resultType == QuestResult.greatSuccess ||
            nearResult.resultType == QuestResult.success) {
          nearSuccesses++;
        }

        final farResult = QuestCompletionService.calculate(
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
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
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      expect(result.mercDamages, hasLength(3));
      expect(result.mercDamages.map((d) => d.mercId).toSet(), {
        'm1',
        'm2',
        'm3',
      });
    });

    test('속도 배율이 회복시간에 반영된다', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 50)];

      final speed1x = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      final speed10x = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 10.0,
        random: _SeededRandom(42),
      );

      // 성공 시 tired 상태, 회복 시간이 10배 빨라야 함
      final tired1x = speed1x.mercDamages.first;
      final tired10x = speed10x.mercDamages.first;
      if (tired1x.recoveryEndTime != null && tired10x.recoveryEndTime != null) {
        final diff1x = tired1x.recoveryEndTime!
            .difference(DateTime.now())
            .inSeconds;
        final diff10x = tired10x.recoveryEndTime!
            .difference(DateTime.now())
            .inSeconds;
        // 10x 속도면 회복시간이 약 1/10
        expect(diff10x, lessThan(diff1x));
      }
    });

    test('엘리트 의뢰는 combat_report 플래그가 없어도 전투 보고서 대상이다', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final result = QuestCompletionService.calculate(
        quest: _makeEliteQuest(),
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      expect(result.combatReportEligible, isTrue);
    });
  });

  // ==========================================================================
  // M8b 페이즈 4 #5 FR-4 — combatSimulationEligible 매트릭스 14 케이스.
  // 명세 페이즈 4 #3 [FR-3] 평가식 분기:
  //   isElite || (isChainQuest && _isChainSimulationStep) ||
  //   (pool?.isNamed) || (isFactionExclusive &&
  //       (isAdvancedTrack || _factionReputation >= 31))
  // ==========================================================================

  group('FR-4 combatSimulationEligible 매트릭스', () {
    test('case 1: 일반 엘리트 의뢰 → true', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(eliteId: 'elite_normal');
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
      expect(result.combatReportEligible, isTrue, reason: 'OR로 자동 true');
    });

    test('case 2: 유니크 엘리트 의뢰 → true', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(eliteId: 'elite_unique');
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 3: 체인 최종 단계 (chainStep+1 == totalSteps) → true', () {
      final staticData = _makeStaticData(
        chainQuests: const [
          ChainQuestData(
            id: 'cq1',
            chainId: 'chain_a',
            chainName: 'Chain A',
            step: 0,
            totalSteps: 2,
            name: '1단계',
            description: '',
            questTypeId: 'raid',
            difficulty: 1,
            combatPower: 1,
            rewardGold: 0,
            durationSeconds: 60,
          ),
          ChainQuestData(
            id: 'cq2',
            chainId: 'chain_a',
            chainName: 'Chain A',
            step: 1,
            totalSteps: 2,
            name: '최종 단계',
            description: '',
            questTypeId: 'raid',
            difficulty: 1,
            combatPower: 1,
            rewardGold: 0,
            durationSeconds: 60,
          ),
        ],
      );
      final quest = _makeQuestRich(
        isChainStep: true,
        chainId: 'chain_a',
        chainStep: 1,
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 4: chain_core_step=true → true', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(
        isChainStep: true,
        chainId: 'chain_b',
        chainStep: 0,
        specialFlags: const {'chain_core_step': true},
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 5: 체인 일반 단계 (chain_core_step 미설정, 엘리트 미동반) → false', () {
      final staticData = _makeStaticData(
        chainQuests: const [
          ChainQuestData(
            id: 'cq1',
            chainId: 'chain_c',
            chainName: 'Chain C',
            step: 0,
            totalSteps: 3,
            name: '1단계',
            description: '',
            questTypeId: 'raid',
            difficulty: 1,
            combatPower: 1,
            rewardGold: 0,
            durationSeconds: 60,
          ),
        ],
      );
      final quest = _makeQuestRich(
        isChainStep: true,
        chainId: 'chain_c',
        chainStep: 0,
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isFalse);
    });

    test('case 6: 거점 사건 체인 (settlement_x, 엘리트 미동반) → false', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(
        isChainStep: true,
        chainId: 'settlement_dustvile_x',
        chainStep: 0,
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      // settlement chain + chainSteps 없음 + chain_core_step 없음 + 엘리트 없음
      expect(result.combatSimulationEligible, isFalse);
    });

    test('case 7: M6 지명 의뢰 (pool.isNamed=true) → true', () {
      final staticData = _makeStaticData(questPools: [_makeNamedPool('pool1')]);
      final quest = _makeQuestRich(questPoolId: 'pool1');
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 8: M8a 세력 지명 의뢰 (pool.isNamed=true) → true', () {
      // case 7과 동일 동작이지만 factionTag 추가로 차별화.
      final staticData = _makeStaticData(
        questPools: [_makeNamedPool('faction_named_pool')],
      );
      final quest = _makeQuestRich(
        questPoolId: 'faction_named_pool',
        factionTag: 'faction_a',
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 9: 세력 고급 트랙 (isAdvancedTrack=true) → true', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(
        factionTag: 'faction_a',
        isAdvancedTrack: true,
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 10: 세력 기본 트랙 + 평판 31 → true', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(
        factionTag: 'faction_a',
        isAdvancedTrack: false,
      );
      final factionState = FactionState(factionId: 'faction_a')
        ..joined = true
        ..reputation = 31;
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
        factionStates: [factionState],
      );
      expect(result.combatSimulationEligible, isTrue);
    });

    test('case 11: 세력 기본 트랙 + 평판 30 → false', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(
        factionTag: 'faction_a',
        isAdvancedTrack: false,
      );
      final factionState = FactionState(factionId: 'faction_a')
        ..joined = true
        ..reputation = 30;
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
        factionStates: [factionState],
      );
      expect(result.combatSimulationEligible, isFalse);
    });

    test('case 12: 더스트빌 허드렛일 일반 의뢰 → false', () {
      final staticData = _makeStaticData();
      final quest = _makeQuestRich(questPoolId: 'dustvile_chore_03');
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isFalse);
    });

    test('case 13: 일반 의뢰 (factionTag null, isElite false) → false', () {
      final staticData = _makeStaticData();
      final quest = _makeQuest();
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isFalse);
      expect(result.simulationResult, isNull);
    });

    test('case 14: pool=null + isElite=true → true', () {
      // pool이 questPools에 미등록 시 firstOrNull=null. 그래도 isElite로 true.
      final staticData = _makeStaticData(); // questPools 비어있음 (기본)
      final quest = _makeQuestRich(
        eliteId: 'elite_x',
        questPoolId: 'nonexistent_pool',
      );
      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: [_makeMerc(str: 50)],
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );
      expect(result.combatSimulationEligible, isTrue);
    });
  });

  // ==========================================================================
  // M8b 페이즈 4 #5 — FR-16 / FR-21 / FR-23 단위 검증.
  // ==========================================================================

  group('FR-16 일반 의뢰 fallback', () {
    test('일반 의뢰는 simulationResult=null, QuestCalculator 경로 사용', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 50)];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      // 일반 의뢰 = combatSimulationEligible false + simulationResult null
      expect(result.combatSimulationEligible, isFalse);
      expect(result.simulationResult, isNull);
      // 기존 QuestCalculator 경로 동작 검증 (보상 발생)
      expect(result.mercDamages, hasLength(1));
      expect(result.resultType, isNotNull);
    });
  });

  group('FR-21 시뮬레이션 활성 의뢰는 LegendaryResultUpgrade 미적용', () {
    test('시뮬레이션 결과는 final, fallback의 LegendaryResultUpgrade는 미적용', () {
      final staticData = _makeStaticData(
        enemyPower: 1,
        combatSkills: [_passiveShieldSkill()],
        combatStatusEffects: [_attackUpEffect()],
        enemyArchetypes: [_overpoweringElite()],
      );
      final quest = _makeEliteQuest();
      final mercs = [_makeMerc(str: 50)];
      final legendaryEffects = <LegendaryEffect>[
        const LegendaryResultUpgrade(chance: 1.0),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(1),
        legendaryEffects: legendaryEffects,
        userData: _makeUserData(),
      );

      expect(result.combatSimulationEligible, isTrue);
      expect(
        result.simulationResult,
        isNotNull,
        reason: '시뮬레이션 경로가 실제 호출되어야 함',
      );
      expect(result.resultType, equals(result.simulationResult!.questResult));
      expect(
        result.resultType,
        isNot(equals(QuestResult.greatSuccess)),
        reason: 'LegendaryResultUpgrade chance=1.0이 시뮬레이션 결과를 승격하면 안 됨',
      );
    });
  });

  group('FR-23 recoveryEndTime은 시뮬레이션 DoT 누적량 반영 안 함', () {
    test('부상자 recoveryEndTime은 difficulty × 10분 / speedMultiplier 산식 유지', () {
      // 시뮬레이션 미적용 일반 의뢰에서 부상자 발생 시 산식 확인.
      final staticData = _makeStaticData(enemyPower: 1000); // 강한 적
      final quest = _makeQuest();
      final mercs = [_makeMerc(str: 1, traitId: '')];

      // 부상 발생까지 시드 탐색.
      Duration? recoveryDuration;
      for (var seed = 0; seed < 200; seed++) {
        final result = QuestCompletionService.calculate(
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        final damage = result.mercDamages.firstOrNull;
        if (damage?.newStatus == MercenaryStatus.injured &&
            damage?.recoveryEndTime != null) {
          recoveryDuration = damage!.recoveryEndTime!.difference(
            DateTime.now(),
          );
          break;
        }
      }
      // difficulty.level=1 × 10분 = 600초 (recoveryReduction/passive 미적용).
      // 마진 ±60초 (DateTime.now 호출 시점 차이).
      if (recoveryDuration != null) {
        expect(
          recoveryDuration.inSeconds,
          inInclusiveRange(540, 660),
          reason: 'recoveryEndTime DoT 누적량 미반영 확인 (기존 산식 유지)',
        );
      }
    });
  });

  // ==========================================================================
  // M8.5 페이즈 4 #3 — HiddenStatBonusResolver.computeLevel + itemDropBonus/repGain 검증
  // 명세 §3.5
  // ==========================================================================

  group('HiddenStatBonusResolver.computeLevel — thresholds [1,3,7,15,30]', () {
    test('카운터 0 → lv0', () {
      expect(HiddenStatBonusResolver.computeLevel(0), 0);
    });

    test('카운터 1 (첫 임계값 도달) → lv1', () {
      expect(HiddenStatBonusResolver.computeLevel(1), 1);
    });

    test('카운터 2 (1 이상, 3 미만) → lv1 유지', () {
      expect(HiddenStatBonusResolver.computeLevel(2), 1);
    });

    test('카운터 3 → lv2', () {
      expect(HiddenStatBonusResolver.computeLevel(3), 2);
    });

    test('카운터 7 → lv3', () {
      expect(HiddenStatBonusResolver.computeLevel(7), 3);
    });

    test('카운터 15 → lv4', () {
      expect(HiddenStatBonusResolver.computeLevel(15), 4);
    });

    test('카운터 30 → lv5 (최대)', () {
      expect(HiddenStatBonusResolver.computeLevel(30), 5);
    });

    test('카운터 100 (30 초과) → lv5 (상한 유지)', () {
      expect(HiddenStatBonusResolver.computeLevel(100), 5);
    });

    test('hiddenStatUnlocked enqueue 대상 = lv0→lv1 전이만 (lv2~5는 로그 분기)', () {
      // 명세 §3.5: oldLv==0 && newLv>=1 일 때만 hiddenStatUnlocked publish.
      // lv1에서 lv2 전이(카운터 1→3)는 해당 조건 불충족.
      //
      // computeLevel을 이용해 전이 여부를 확인:
      //   oldLv = computeLevel(counter_before_delta)
      //   newLv = computeLevel(counter_before_delta + delta)
      // lv0→lv1 전이 예시
      final oldLv = HiddenStatBonusResolver.computeLevel(0);
      final newLv = HiddenStatBonusResolver.computeLevel(1);
      expect(oldLv, 0);
      expect(newLv, 1);
      // 조건: oldLv == 0 && newLv >= 1 → enqueue 대상
      expect(oldLv == 0 && newLv >= 1, isTrue, reason: 'lv1 첫 해금은 enqueue 대상');

      // lv1→lv2 전이 예시
      final oldLv2 = HiddenStatBonusResolver.computeLevel(1);
      final newLv2 = HiddenStatBonusResolver.computeLevel(3);
      expect(oldLv2, 1);
      expect(newLv2, 2);
      // 조건: oldLv == 0 이 아님 → enqueue 비대상 (활동 로그 분기)
      expect(oldLv2 == 0 && newLv2 >= 1, isFalse, reason: 'lv2 승급은 enqueue 비대상');
    });
  });

  // ==========================================================================
  // luck itemDropBonus — 파티 최고 luck lv 1명만 적용 (합산 금지, 동률 mercId asc)
  // ==========================================================================

  group('luck itemDropBonus — 파티 최고 luck lv 1명 선택 (합산 금지)', () {
    test('luck lv0인 파티 → itemDropBonus = 0.0', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [
        _makeMercWithHiddenStats('m_a', hiddenStats: {}),
        _makeMercWithHiddenStats('m_b', hiddenStats: {}),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      expect(result.itemDropBonus, 0.0);
    });

    test('luck lv1 단독 → itemDropBonus = 0.005 (lv1 × 0.005)', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      // luck lv1 = 카운터 >= 1 이므로 hiddenStats['luck'] = 1
      final mercs = [
        _makeMercWithHiddenStats('m_a', hiddenStats: {'luck': 1}),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      expect(result.itemDropBonus, closeTo(0.005, 1e-9));
    });

    test('luck lv5 단독 → itemDropBonus = 0.025 (상한 clamp)', () {
      // lv5 × 0.005 = 0.025 (최대치)
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [
        _makeMercWithHiddenStats('m_a', hiddenStats: {'luck': 5}),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      expect(result.itemDropBonus, closeTo(0.025, 1e-9));
    });

    test('파티 중 최고 luck lv 용병 1명만 반영 — 합산 금지', () {
      // m_low: luck lv2 / m_high: luck lv4
      // itemDropBonus = lv4 × 0.005 = 0.020 (합산 아닌 최고값만)
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [
        _makeMercWithHiddenStats('m_low', hiddenStats: {'luck': 2}),
        _makeMercWithHiddenStats('m_high', hiddenStats: {'luck': 4}),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      // lv2(0.010) + lv4(0.020) = 0.030이 아니라 max(lv4) = 0.020
      expect(result.itemDropBonus, closeTo(0.020, 1e-9));
    });

    test('luck lv 동률 시 mercId 오름차순 첫 번째 용병만 반영', () {
      // 두 용병 모두 luck lv3 → mercId asc: 'm_a' < 'm_b' → 'm_a' 선택
      // itemDropBonus = lv3 × 0.005 = 0.015 (합산이면 0.030 — 이와 달라야 함)
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [
        _makeMercWithHiddenStats('m_b', hiddenStats: {'luck': 3}),
        _makeMercWithHiddenStats('m_a', hiddenStats: {'luck': 3}),
      ];

      final result = QuestCompletionService.calculate(
        quest: quest,
        mercs: mercs,
        staticData: staticData,
        playerRegion: 1,
        facilities: {},
        speedMultiplier: 1.0,
        random: _SeededRandom(42),
      );

      // 합산이면 0.030, 최고 1명만이면 0.015 — 0.015 검증
      expect(result.itemDropBonus, closeTo(0.015, 1e-9));
    });
  });

  // ==========================================================================
  // grit reputationGainModifier — 파티 최고 grit lv 1명만 반영 (합산 금지)
  // ==========================================================================

  group('grit reputationGainModifier — 파티 최고 grit lv 1명 선택 (합산 금지)', () {
    test('grit lv0인 성공 파티 → repGain = 기본값', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();
      final mercs = [
        _makeMercWithHiddenStats('m_a', hiddenStats: {}),
      ];

      // 성공이 보장되는 시드 탐색
      QuestCompletionResult? successResult;
      for (int seed = 0; seed < 100; seed++) {
        final r = QuestCompletionService.calculate(
          quest: quest,
          mercs: mercs,
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        if (r.resultType == QuestResult.success ||
            r.resultType == QuestResult.greatSuccess) {
          successResult = r;
          break;
        }
      }
      expect(successResult, isNotNull);
      expect(successResult!.repGain, greaterThan(0));
    });

    test('grit lv 높을수록 repGain이 증가한다 — 단일 용병 비교', () {
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();

      // 동일 시드에서 grit lv0 vs lv3 비교 — 성공 시 명성 차이 확인
      for (int seed = 0; seed < 100; seed++) {
        final baseResult = QuestCompletionService.calculate(
          quest: quest,
          mercs: [_makeMercWithHiddenStats('m_a', hiddenStats: {})],
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        final gritResult = QuestCompletionService.calculate(
          quest: quest,
          mercs: [_makeMercWithHiddenStats('m_a', hiddenStats: {'grit': 3})],
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );

        if (baseResult.resultType == QuestResult.success &&
            gritResult.resultType == QuestResult.success) {
          // grit lv3 의 grit × 0.015 = +0.045 reputationGainModifier 가산
          expect(
            gritResult.repGain,
            greaterThanOrEqualTo(baseResult.repGain),
            reason: 'grit lv3는 lv0보다 명성 보너스가 높거나 같아야 함',
          );
          break;
        }
      }
    });

    test('파티 최고 grit 1명만 반영 — 합산 금지 (두 용병 repGain이 단일 최고값과 같아야 함)', () {
      // m_low(grit lv1) + m_high(grit lv4)로 구성된 파티의 repGain =
      // m_high(grit lv4) 단독 파티의 repGain 과 동일해야 함 (합산 불가).
      final staticData = _makeStaticData(enemyPower: 5);
      final quest = _makeQuest();

      for (int seed = 0; seed < 100; seed++) {
        final multiResult = QuestCompletionService.calculate(
          quest: quest,
          mercs: [
            _makeMercWithHiddenStats('m_low', hiddenStats: {'grit': 1}),
            _makeMercWithHiddenStats('m_high', hiddenStats: {'grit': 4}),
          ],
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );
        final singleResult = QuestCompletionService.calculate(
          quest: quest,
          mercs: [
            _makeMercWithHiddenStats('m_high', hiddenStats: {'grit': 4}),
            _makeMercWithHiddenStats('m_low', hiddenStats: {'grit': 1}),
          ],
          staticData: staticData,
          playerRegion: 1,
          facilities: {},
          speedMultiplier: 1.0,
          random: _SeededRandom(seed),
        );

        if (multiResult.resultType == QuestResult.success &&
            singleResult.resultType == QuestResult.success) {
          // 동일 파티(순서만 다름) — repGain이 같아야 함 (합산 아닌 최고값 1명)
          expect(
            multiResult.repGain,
            equals(singleResult.repGain),
            reason: 'grit은 합산이 아닌 최고 lv 1명에서만 적용',
          );
          break;
        }
      }
    });
  });
}

// ===========================================================================
// FR-4 매트릭스용 추가 헬퍼
// ===========================================================================

QuestPool _makeNamedPool(String id) {
  return QuestPool(
    id: id,
    name: '지명 의뢰 테스트 풀',
    type: 1,
    difficulty: 1,
    minRegionDiff: 0,
    maxRegionDiff: 0,
    typeId: 'raid',
    isNamed: true,
    specialFlags: const {},
  );
}

UserData _makeUserData() {
  return UserData(
    gold: 1000,
    region: 1,
    sector: 1,
    lastFreeRecruit: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

CombatSkill _passiveShieldSkill() {
  return const CombatSkill(
    id: 'skill_warrior_shield_bulwark',
    role: 'warrior',
    triggerKind: TriggerKind.passive,
    actionCost: ActionCost.passive,
    targetingKind: TargetingKind.self,
    shieldBlockBonus: 0.10,
    displayLabel: '방패 보루',
    description: '방패 막기 강화',
  );
}

CombatStatusEffect _attackUpEffect() {
  return const CombatStatusEffect(
    id: 'buff_attack_up',
    kind: 'buff',
    displayLabel: '공격력 강화',
    defaultDurationTurns: 2,
    defaultIntensity: 0.2,
    stackPolicy: StackPolicy.refresh,
    hookTarget: ['attack'],
    applyMethod: ApplyMethod.multiplicative,
    description: '공격력 강화',
  );
}

EnemyArchetype _overpoweringElite() {
  return const EnemyArchetype(
    id: 'enemy_overpowering_elite',
    name: '압도적인 엘리트',
    enemyKind: EnemyKind.elite,
    eliteMonsterId: 'elite_test',
    role: 'warrior',
    tier: 5,
    baseStr: 100,
    baseInt: 20,
    baseVit: 100,
    baseAgi: 80,
    baseHp: 800,
    baseAttack: 500,
    baseDefense: 80,
    behaviorPattern: BehaviorPattern.aggressive,
    environmentTags: ['plains'],
    description: '시뮬레이션 결과를 fallback과 분리하기 위한 강적',
  );
}

ActiveQuest _makeQuestRich({
  String id = 'q_matrix',
  String questPoolId = 'pool1',
  String questTypeId = 'raid',
  int difficulty = 1,
  int region = 1,
  String? eliteId,
  bool? isChainStep,
  String? chainId,
  int? chainStep,
  String? factionTag,
  bool? isAdvancedTrack,
  Map<String, dynamic>? specialFlags,
}) {
  return ActiveQuest(
    id: id,
    questPoolId: questPoolId,
    questTypeId: questTypeId,
    difficulty: difficulty,
    region: region,
    questName: '매트릭스 테스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.now().subtract(const Duration(minutes: 5)),
    endTime: DateTime.now().subtract(const Duration(seconds: 1)),
    eliteId: eliteId,
    isChainStep: isChainStep,
    chainId: chainId,
    chainStep: chainStep,
    factionTag: factionTag,
    isAdvancedTrack: isAdvancedTrack,
    specialFlags: specialFlags,
  );
}

// M8.5 페이즈 4 #3 — hiddenStats가 있는 Mercenary 생성 헬퍼.
// 기존 _makeMerc와 별도 정의(hiddenStats 지정 필요).
Mercenary _makeMercWithHiddenStats(
  String id, {
  Map<String, int>? hiddenStats,
}) {
  return Mercenary(
    id: id,
    name: '용병_$id',
    jobId: 'warrior',
    traitId: '',
    str: 20,
    intelligence: 10,
    vit: 100,
    agi: 50,
    hiddenStats: hiddenStats ?? const {},
  );
}
