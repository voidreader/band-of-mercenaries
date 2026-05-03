import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/special_flag_processor.dart';
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

// 최소 정적 데이터 구성 (quest_completion_service_test 패턴 참조)
StaticGameData _minimalStaticData({List<ItemData> items = const []}) {
  return StaticGameData(
    difficulties: [
      Difficulty(
        level: 1,
        enemyPower: 10,
        rewardMultiplier: 1.0,
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
      const QuestType(id: 'raid', name: '약탈', baseReward: 100, baseDuration: 60, riskFactor: 1.0),
    ],
    questPools: [],
    personNames: [],
    travelEvents: [],
    facilities: [
      const Facility(id: 'training', name: '훈련소', effectType: 'xp_bonus', maxLevel: 3, costs: [100, 200, 400], values: [0.1, 0.2, 0.3]),
    ],
    ranks: [
      const Rank(grade: 'F', name: '신참', requiredReputation: 0, unlockTier: 1),
    ],
    mercenaryWages: [
      const MercenaryWage(tier: 1, wage: 10),
    ],
    regionDiscoveries: const [],
    factions: const [],
    items: items,
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

ActiveQuest _makeQuest({Map<String, dynamic>? specialFlags}) {
  return ActiveQuest(
    id: 'q1',
    questPoolId: 'pool1',
    questTypeId: 'raid',
    difficulty: 1,
    region: 1,
    questName: '테스트 퀘스트',
    specialFlags: specialFlags,
  );
}

Mercenary _makeMerc(String id) {
  return Mercenary(
    id: id,
    name: '용병$id',
    jobId: 'warrior',
    traitId: '',
    str: 20,
    intelligence: 10,
    vit: 100,
    agi: 50,
  );
}

void main() {
  group('SpecialFlagProcessor', () {
    test('specialFlags가 null이면 empty를 반환한다', () {
      final quest = _makeQuest(specialFlags: null);
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.success,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.isEmpty, isTrue);
    });

    test('specialFlags가 빈 맵이면 empty를 반환한다', () {
      final quest = _makeQuest(specialFlags: {});
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.success,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.isEmpty, isTrue);
    });

    test('reputation_penalty는 실패 결과에도 적용된다', () {
      final quest = _makeQuest(
        specialFlags: {
          'reputation_penalty': {'amount': -5},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.failure,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraReputation, equals(-5));
      expect(result.reputationPenaltyApplied, isTrue);
    });

    test('reputation_penalty는 대실패 결과에도 적용된다', () {
      final quest = _makeQuest(
        specialFlags: {
          'reputation_penalty': {'amount': -10},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.criticalFailure,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraReputation, equals(-10));
      expect(result.reputationPenaltyApplied, isTrue);
    });

    test('reputation_penalty는 대성공 결과에도 적용된다', () {
      final quest = _makeQuest(
        specialFlags: {
          'reputation_penalty': {'amount': -3},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.greatSuccess,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraReputation, equals(-3));
      expect(result.reputationPenaltyApplied, isTrue);
    });

    test('trait_learning_boost는 성공 시 partyMercs ID를 boostedMercIds에 추가한다', () {
      final merc = _makeMerc('merc-1');
      final quest = _makeQuest(
        specialFlags: {'trait_learning_boost': <String, dynamic>{}},
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.success,
        partyMercs: [merc],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.boostedMercIds, contains('merc-1'));
    });

    test('trait_learning_boost는 대성공 시에도 partyMercs ID를 boostedMercIds에 추가한다', () {
      final merc1 = _makeMerc('merc-1');
      final merc2 = _makeMerc('merc-2');
      final quest = _makeQuest(
        specialFlags: {'trait_learning_boost': <String, dynamic>{}},
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.greatSuccess,
        partyMercs: [merc1, merc2],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.boostedMercIds, containsAll(['merc-1', 'merc-2']));
    });

    test('trait_learning_boost는 실패 시 boostedMercIds가 비어있다', () {
      final merc = _makeMerc('merc-1');
      final quest = _makeQuest(
        specialFlags: {'trait_learning_boost': <String, dynamic>{}},
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.failure,
        partyMercs: [merc],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.boostedMercIds, isEmpty);
    });

    test('trait_learning_boost는 대실패 시 boostedMercIds가 비어있다', () {
      final merc = _makeMerc('merc-1');
      final quest = _makeQuest(
        specialFlags: {'trait_learning_boost': <String, dynamic>{}},
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.criticalFailure,
        partyMercs: [merc],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.boostedMercIds, isEmpty);
    });

    test('guild_drop_rare는 성공 시 drop_rate 1.0이면 item_id를 extraItemIds에 추가한다', () {
      final quest = _makeQuest(
        specialFlags: {
          'guild_drop_rare': {'drop_rate': 1.0, 'item_id': 'rare_sword'},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.success,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraItemIds, contains('rare_sword'));
    });

    test('guild_drop_rare는 실패 시 item을 드랍하지 않는다', () {
      final quest = _makeQuest(
        specialFlags: {
          'guild_drop_rare': {'drop_rate': 1.0, 'item_id': 'rare_sword'},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.failure,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraItemIds, isEmpty);
    });

    test('guild_drop_rare는 drop_rate 0.0이면 item을 드랍하지 않는다', () {
      final quest = _makeQuest(
        specialFlags: {
          'guild_drop_rare': {'drop_rate': 0.0, 'item_id': 'rare_sword'},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.success,
        partyMercs: [],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraItemIds, isEmpty);
    });

    test('reputation_penalty와 trait_learning_boost를 동시에 처리한다', () {
      final merc = _makeMerc('merc-1');
      final quest = _makeQuest(
        specialFlags: {
          'reputation_penalty': {'amount': -5},
          'trait_learning_boost': <String, dynamic>{},
        },
      );
      final result = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: QuestResult.success,
        partyMercs: [merc],
        staticData: _minimalStaticData(),
        random: Random(42),
      );
      expect(result.extraReputation, equals(-5));
      expect(result.reputationPenaltyApplied, isTrue);
      expect(result.boostedMercIds, contains('merc-1'));
    });
  });
}
