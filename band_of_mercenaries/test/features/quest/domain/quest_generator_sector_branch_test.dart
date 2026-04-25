import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';

// 공통 quest_type 목록 (quest_generator_test 패턴 참조)
const _questTypes = [
  QuestType(id: 'raid', name: '약탈', baseReward: 100, baseDuration: 60, riskFactor: 1.0),
];

// sectorType별 풀: null 풀, village 풀, ruins 풀, hidden 풀
const _poolNull = QuestPool(
  id: 'pool_null',
  name: 'null 섹터 퀘스트',
  type: 0,
  difficulty: 1,
  minRegionDiff: 0,
  maxRegionDiff: 5,
  typeId: 'raid',
  sectorType: null,
);
const _poolVillage = QuestPool(
  id: 'pool_village',
  name: 'village 섹터 퀘스트',
  type: 0,
  difficulty: 1,
  minRegionDiff: 0,
  maxRegionDiff: 5,
  typeId: 'raid',
  sectorType: 'village',
);
const _poolRuins = QuestPool(
  id: 'pool_ruins',
  name: 'ruins 섹터 퀘스트',
  type: 0,
  difficulty: 1,
  minRegionDiff: 0,
  maxRegionDiff: 5,
  typeId: 'raid',
  sectorType: 'ruins',
);
const _poolHidden = QuestPool(
  id: 'pool_hidden',
  name: 'hidden 섹터 퀘스트',
  type: 0,
  difficulty: 1,
  minRegionDiff: 0,
  maxRegionDiff: 5,
  typeId: 'raid',
  sectorType: 'hidden',
);

// 모든 sectorType 풀 포함 목록
const _allPools = [_poolNull, _poolVillage, _poolRuins, _poolHidden];

List<String> _poolIdsFrom(List<dynamic> quests) =>
    quests.map((q) => (q as dynamic).questPoolId as String).toList();

void main() {
  group('QuestGenerator sector 분기', () {
    test('sectorChanges가 null이면 sectorType==null 풀만 사용한다', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: _allPools,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: 3,
        sectorChanges: null, // sectorChanges null → null 풀만
      );
      final poolIds = _poolIdsFrom(quests);
      expect(poolIds, everyElement(equals('pool_null')));
    });

    test('currentSectorIndex가 null이면 sectorType==null 풀만 사용한다', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: _allPools,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: null, // sectorIndex null → sectorChanges 조회 불가
        sectorChanges: {'3': 'village'},
      );
      final poolIds = _poolIdsFrom(quests);
      expect(poolIds, everyElement(equals('pool_null')));
    });

    test('sectorChanges["3"]="village"이고 currentSectorIndex=3이면 village 풀만 사용한다', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: _allPools,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: 3,
        sectorChanges: {'3': 'village'},
      );
      final poolIds = _poolIdsFrom(quests);
      expect(poolIds, everyElement(equals('pool_village')));
    });

    test('sectorChanges["7"]="ruins"이고 currentSectorIndex=7이면 ruins 풀만 사용한다', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: _allPools,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: 7,
        sectorChanges: {'7': 'ruins'},
      );
      final poolIds = _poolIdsFrom(quests);
      expect(poolIds, everyElement(equals('pool_ruins')));
    });

    test('sectorChanges["0"]="hidden"이고 currentSectorIndex=0이면 hidden 풀만 사용한다', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: _allPools,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: 0,
        sectorChanges: {'0': 'hidden'},
      );
      final poolIds = _poolIdsFrom(quests);
      expect(poolIds, everyElement(equals('pool_hidden')));
    });

    test('currentSectorIndex와 sectorChanges key가 다른 섹터를 가리키면 null 풀로 폴백한다', () {
      // sectorChanges에는 섹터 5가 village이지만 현재 섹터는 3 → 변형 없음 → null 풀 사용
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: _allPools,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: 3,
        sectorChanges: {'5': 'village'}, // 섹터 3 변형 없음
      );
      final poolIds = _poolIdsFrom(quests);
      expect(poolIds, everyElement(equals('pool_null')));
    });

    test('해당 sectorType 풀이 없으면 퀘스트가 생성되지 않는다', () {
      // village 풀만 없는 상태에서 village 섹터 진입 시 빈 목록 반환
      final poolsWithoutVillage = [_poolNull, _poolRuins, _poolHidden];
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: poolsWithoutVillage,
        questTypes: _questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 5,
        currentSectorIndex: 3,
        sectorChanges: {'3': 'village'},
      );
      expect(quests, isEmpty);
    });
  });
}
