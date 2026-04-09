import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/data/json_loader.dart';

void main() {
  group('JsonLoader', () {
    test('parseDifficulties parses JSON correctly', () {
      const jsonString = '{"Difficultys": [{"Level": 1, "EnemyPower": 10, "RewardMultiplier": 1.0, "SuccessPenalty": 0.0, "InjuryRate": 0.1, "DeathRate": 0.05, "MinDispatchCost": 5, "MaxDispatchCost": 30}]}';
      final result = JsonLoader.parseDifficulties(jsonString);
      expect(result.length, 1);
      expect(result[0].level, 1);
      expect(result[0].enemyPower, 10);
      expect(result[0].deathRate, 0.05);
    });

    test('parseJobs parses JSON correctly', () {
      const jsonString = '{"Jobs": [{"ID": "farmer", "Tier": 1, "Name": "농부", "BaseAtk": 4, "BaseDef": 3, "BaseHp": 24, "Speed": 0.96}]}';
      final result = JsonLoader.parseJobs(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'farmer');
      expect(result[0].tier, 1);
      expect(result[0].name, '농부');
    });

    test('parseTraits parses JSON correctly', () {
      const jsonString = '{"Traits": [{"ID": "strong", "Name": "강인함", "EffectType": "hp_bonus", "Value": 0.2}]}';
      final result = JsonLoader.parseTraits(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'strong');
      expect(result[0].effectType, 'hp_bonus');
    });

    test('parseRegions parses JSON correctly', () {
      const jsonString = '{"Regions": [{"Continent": 1, "Region": 3, "RegionName": "초원", "RegionTier": 1, "RecommendPower": 10, "Desc": "초원 지역"}]}';
      final result = JsonLoader.parseRegions(jsonString);
      expect(result.length, 1);
      expect(result[0].region, 3);
      expect(result[0].regionTier, 1);
    });

    test('parseQuestTypes parses JSON correctly', () {
      const jsonString = '{"QuestTypes": [{"ID": "loot", "Name": "약탈", "BaseReward": 100, "BaseDuration": 60, "RiskFactor": 0.3}]}';
      final result = JsonLoader.parseQuestTypes(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'loot');
      expect(result[0].baseReward, 100);
    });

    test('parseQuestPools parses JSON correctly', () {
      const jsonString = '{"QuestPools": [{"ID": "q001", "Name": "귀족 마차 호위 Lv8", "Type": 0.0, "Difficulty": 8.0, "MinRegionDiff": 6.0, "MaxRegionDiff": 10.0}]}';
      final result = JsonLoader.parseQuestPools(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'q001');
      expect(result[0].difficulty, 8.0);
    });

    test('parsePersonNames parses JSON correctly', () {
      const jsonString = '{"PersonNames": [{"ID": 0, "Korean": "에이드리안"}, {"ID": 1, "Korean": "알라릭"}]}';
      final result = JsonLoader.parsePersonNames(jsonString);
      expect(result.length, 2);
      expect(result[0].korean, '에이드리안');
    });

    test('parseTravelEvents parses JSON correctly', () {
      const jsonString = '{"TravelEvents": [{"ID": "te_find_gold_s", "Name": "금화 주머니 발견", "Type": "discovery", "EffectType": "gold", "Magnitude": 20.0, "MinTier": 1, "MaxTier": 2, "Description": "길가에 금화 주머니를 발견했다."}]}';
      final result = JsonLoader.parseTravelEvents(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'te_find_gold_s');
      expect(result[0].effectType, 'gold');
      expect(result[0].magnitude, 20.0);
    });

    test('parseFacilities parses JSON correctly', () {
      const jsonString = '{"Facilities": [{"ID": "training", "Name": "훈련소", "EffectType": "xp_bonus", "MaxLevel": 5, "Costs": [500, 1000, 2000, 4000, 8000], "Values": [0.1, 0.2, 0.3, 0.4, 0.5]}]}';
      final result = JsonLoader.parseFacilities(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'training');
      expect(result[0].maxLevel, 5);
      expect(result[0].costs.length, 5);
    });

    test('parseRanks parses JSON correctly', () {
      const jsonString = '{"Ranks": [{"Grade": "F", "Name": "무명", "RequiredReputation": 0, "UnlockTier": 1}]}';
      final result = JsonLoader.parseRanks(jsonString);
      expect(result.length, 1);
      expect(result[0].grade, 'F');
      expect(result[0].requiredReputation, 0);
      expect(result[0].unlockTier, 1);
    });

    test('parseMercenaryWages parses JSON correctly', () {
      const jsonString = '{"MercenaryWages": [{"Tier": 1, "Wage": 10}, {"Tier": 2, "Wage": 25}]}';
      final result = JsonLoader.parseMercenaryWages(jsonString);
      expect(result.length, 2);
      expect(result[0].tier, 1);
      expect(result[0].wage, 10);
      expect(result[1].tier, 2);
    });
  });
}
