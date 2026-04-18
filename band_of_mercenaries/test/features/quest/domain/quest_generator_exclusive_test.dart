import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';

QuestPool _pool({
  required String id,
  String typeId = 'raid',
  double difficulty = 1.0,
  double minRegionDiff = 0,
  double maxRegionDiff = 5,
  String? factionTag,
  bool isFactionExclusive = false,
  int minReputation = 0,
  String? sectorType,
}) =>
    QuestPool(
      id: id,
      name: id,
      type: 0,
      typeId: typeId,
      difficulty: difficulty,
      minRegionDiff: minRegionDiff,
      maxRegionDiff: maxRegionDiff,
      factionTag: factionTag,
      isFactionExclusive: isFactionExclusive,
      minReputation: minReputation,
      sectorType: sectorType,
    );

void main() {
  // 기본 퀘스트 타입
  const questTypes = [
    QuestType(id: 'raid', name: '토벌', baseReward: 100, baseDuration: 60, riskFactor: 0.3),
    QuestType(id: 'hunt', name: '사냥', baseReward: 120, baseDuration: 80, riskFactor: 0.5),
    QuestType(id: 'escort', name: '호위', baseReward: 90, baseDuration: 75, riskFactor: 0.25),
    QuestType(id: 'explore', name: '탐험', baseReward: 80, baseDuration: 70, riskFactor: 0.2),
  ];

  // 일반 풀 (전용 아닌 것)
  final generalPools = [
    _pool(id: 'g001', typeId: 'raid'),
    _pool(id: 'g002', typeId: 'hunt'),
    _pool(id: 'g003', typeId: 'escort'),
  ];

  // 전용 퀘스트 풀
  final exclusivePools = [
    _pool(id: 'fq001', typeId: 'raid', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 11),
    _pool(id: 'fq002', typeId: 'hunt', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 11),
    _pool(id: 'fq003', typeId: 'escort', factionTag: 'faction_b', isFactionExclusive: true, minReputation: 11),
  ];

  final allPools = [...generalPools, ...exclusivePools];

  group('QuestGenerator - 전용 퀘스트 필터링', () {
    test('가입 세력 없음 → 전용 퀘스트 미노출', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: allPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: [],
        factionReputations: {},
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {},
        activeSlotCount: 5,
      );
      final hasExclusive = quests.any((q) => q.isFactionExclusive);
      expect(hasExclusive, false);
    });

    test('가입 세력 있지만 평판 < minReputation → 전용 퀘스트 미노출', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: allPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: ['faction_a'],
        factionReputations: {'faction_a': 5}, // minReputation=11 미충족
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {},
        activeSlotCount: 5,
      );
      final exclusiveCount = quests.where((q) => q.isFactionExclusive).length;
      expect(exclusiveCount, 0);
    });

    test('가입 세력 + 평판 충족 → 전용 퀘스트 노출', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: allPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: ['faction_a'],
        factionReputations: {'faction_a': 20}, // minReputation=11 충족
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {},
        activeSlotCount: 5,
      );
      final exclusiveCount = quests.where((q) => q.isFactionExclusive).length;
      expect(exclusiveCount, greaterThan(0));
    });

    test('쿨다운 중인 전용 퀘스트 제외', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: allPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: ['faction_a'],
        factionReputations: {'faction_a': 20},
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {'fq001', 'fq002'}, // faction_a 전용 모두 쿨다운
        activeSlotCount: 5,
      );
      final questIds = quests.map((q) => q.questPoolId).toSet();
      expect(questIds.contains('fq001'), false);
      expect(questIds.contains('fq002'), false);
    });

    test('전용 노출 상한: joinedCount=1, activeSlotCount=2 → 최대 1개', () {
      // min(1*2, floor(2*0.5)) = min(2, 1) = 1
      final manyExclusivePools = [
        _pool(id: 'fq_e1', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 0),
        _pool(id: 'fq_e2', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 0),
        _pool(id: 'fq_e3', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 0),
        ...generalPools,
      ];
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: manyExclusivePools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: ['faction_a'],
        factionReputations: {'faction_a': 20},
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {},
        activeSlotCount: 2,
      );
      final exclusiveCount = quests.where((q) => q.isFactionExclusive).length;
      expect(exclusiveCount, lessThanOrEqualTo(1));
    });

    test('전용 노출 상한: joinedCount=2, activeSlotCount=10 → 최대 4개', () {
      // min(2*2, floor(10*0.5)) = min(4, 5) = 4
      final manyExclusivePools = [
        _pool(id: 'fq_m1', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 0),
        _pool(id: 'fq_m2', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 0),
        _pool(id: 'fq_m3', factionTag: 'faction_b', isFactionExclusive: true, minReputation: 0),
        _pool(id: 'fq_m4', factionTag: 'faction_b', isFactionExclusive: true, minReputation: 0),
        _pool(id: 'fq_m5', factionTag: 'faction_b', isFactionExclusive: true, minReputation: 0),
        ...generalPools,
      ];
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: manyExclusivePools,
        questTypes: questTypes,
        count: 10,
        random: Random(42),
        joinedFactionIds: ['faction_a', 'faction_b'],
        factionReputations: {'faction_a': 20, 'faction_b': 20},
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {},
        activeSlotCount: 10,
      );
      final exclusiveCount = quests.where((q) => q.isFactionExclusive).length;
      expect(exclusiveCount, lessThanOrEqualTo(4));
    });

    test('pool.typeId 기반 QuestType 결정 → questTypeId 일치', () {
      final huntExclusivePool = [
        _pool(id: 'fq_hunt', typeId: 'hunt', factionTag: 'faction_a', isFactionExclusive: true, minReputation: 0),
        ...generalPools,
      ];
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 1,
        questPools: huntExclusivePool,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
        joinedFactionIds: ['faction_a'],
        factionReputations: {'faction_a': 20},
        clueLevelsInRegion: {},
        cooldownExclusiveQuestIds: {},
        activeSlotCount: 5,
      );
      final exclusiveQuest = quests.firstWhere((q) => q.questPoolId == 'fq_hunt');
      expect(exclusiveQuest.questTypeId, 'hunt');
    });
  });
}
