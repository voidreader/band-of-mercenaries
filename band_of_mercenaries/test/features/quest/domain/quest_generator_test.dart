import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';

void main() {
  final questPools = [
    const QuestPool(id: 'q001', name: '오크 사냥 Lv1', type: 0, difficulty: 1, minRegionDiff: 0, maxRegionDiff: 3),
    const QuestPool(id: 'q002', name: '늑대 토벌 Lv5', type: 0, difficulty: 5, minRegionDiff: 3, maxRegionDiff: 7),
    const QuestPool(id: 'q003', name: '동굴 조사 Lv10', type: 0, difficulty: 10, minRegionDiff: 8, maxRegionDiff: 12),
    const QuestPool(id: 'q004', name: '보물 침입 Lv2', type: 0, difficulty: 2, minRegionDiff: 0, maxRegionDiff: 4),
    const QuestPool(id: 'q005', name: '마법 유적 Lv3', type: 0, difficulty: 3, minRegionDiff: 1, maxRegionDiff: 5),
    const QuestPool(id: 'q006', name: '상단 호위 Lv4', type: 0, difficulty: 4, minRegionDiff: 2, maxRegionDiff: 6),
  ];
  final questTypes = [
    const QuestType(id: 'loot', name: '약탈', baseReward: 100, baseDuration: 60, riskFactor: 0.3),
    const QuestType(id: 'explore', name: '탐험', baseReward: 80, baseDuration: 70, riskFactor: 0.2),
    const QuestType(id: 'hunt', name: '토벌', baseReward: 120, baseDuration: 80, riskFactor: 0.5),
    const QuestType(id: 'escort', name: '호위', baseReward: 90, baseDuration: 75, riskFactor: 0.25),
  ];

  group('QuestGenerator', () {
    test('generates correct number of quests', () {
      final quests = QuestGenerator.generateQuests(regionTier: 1, regionId: 3, questPools: questPools, questTypes: questTypes, count: 5, random: Random(42), joinedFactionIds: const [], factionReputations: const {}, clueLevelsInRegion: const {}, cooldownExclusiveQuestIds: const {}, activeSlotCount: 5);
      expect(quests.length, lessThanOrEqualTo(5));
      expect(quests.length, greaterThan(0));
    });

    test('filters quests by region tier correctly', () {
      final quests = QuestGenerator.generateQuests(regionTier: 1, regionId: 3, questPools: questPools, questTypes: questTypes, count: 5, random: Random(42), joinedFactionIds: const [], factionReputations: const {}, clueLevelsInRegion: const {}, cooldownExclusiveQuestIds: const {}, activeSlotCount: 5);
      for (final quest in quests) {
        final pool = questPools.firstWhere((p) => p.id == quest.questPoolId);
        expect(pool.minRegionDiff, lessThanOrEqualTo(1));
        expect(pool.maxRegionDiff, greaterThanOrEqualTo(1));
      }
    });

    test('assigns quest types from available types', () {
      final quests = QuestGenerator.generateQuests(regionTier: 1, regionId: 3, questPools: questPools, questTypes: questTypes, count: 5, random: Random(42), joinedFactionIds: const [], factionReputations: const {}, clueLevelsInRegion: const {}, cooldownExclusiveQuestIds: const {}, activeSlotCount: 5);
      final validTypeIds = questTypes.map((t) => t.id).toSet();
      for (final quest in quests) { expect(validTypeIds.contains(quest.questTypeId), true); }
    });

    test('returns empty list when no quests match region tier', () {
      final quests = QuestGenerator.generateQuests(regionTier: 99, regionId: 1, questPools: questPools, questTypes: questTypes, count: 5, random: Random(42), joinedFactionIds: const [], factionReputations: const {}, clueLevelsInRegion: const {}, cooldownExclusiveQuestIds: const {}, activeSlotCount: 5);
      expect(quests, isEmpty);
    });
  });
}
