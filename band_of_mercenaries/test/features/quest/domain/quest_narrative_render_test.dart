import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/models/quest_narrative_data.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_narrative_service.dart';

const _engine = TemplateEngine();

UserData _makeUserData() {
  final now = DateTime(2026, 4, 26);
  return UserData(
    gold: 1000,
    region: 1,
    sector: 0,
    lastFreeRecruit: now,
    createdAt: now,
  );
}

Mercenary _makeMerc({required String name}) {
  return Mercenary(
    id: 'merc-001',
    name: name,
    jobId: 'warrior',
    traitId: '',
    str: 10,
    intelligence: 10,
    vit: 10,
    agi: 10,
  );
}

ActiveQuest _makeQuest({
  bool isChainStep = false,
  QuestResult? result,
  String questTypeId = 'raid',
  String questPoolId = 'pool-001',
}) {
  return ActiveQuest(
    id: 'quest-001',
    questPoolId: questPoolId,
    questTypeId: questTypeId,
    difficulty: 1,
    region: 1,
    questName: '테스트 퀘스트',
    isChainStep: isChainStep ? true : null,
    result: result,
  );
}

StaticGameData _makeStaticData({List<QuestNarrativeData> questNarratives = const []}) {
  return StaticGameData(
    difficulties: const [],
    jobs: const [],
    traits: const [],
    traitCategories: const [],
    traitConflicts: const [],
    traitTransitions: const [],
    traitComboEvolutions: const [],
    traitSynergies: const [],
    regions: const [],
    questTypes: const [],
    questPools: const [],
    personNames: const [],
    travelEvents: const [],
    facilities: const [],
    ranks: const [],
    mercenaryWages: const [],
    regionDiscoveries: const [],
    factions: const [],
    items: const [],
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
    questNarratives: questNarratives,
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionSectors: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
  );
}

void main() {
  group('renderNarrative', () {
    test('체인 퀘스트(isChainStep == true) → null 반환', () {
      final quest = _makeQuest(isChainStep: true, result: QuestResult.success);
      final staticData = _makeStaticData();

      final result = QuestNarrativeService.renderNarrative(
        quest: quest,
        partyMercs: [],
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
      );

      expect(result, isNull);
    });

    test('pickTemplate 매칭 0개 → null 반환', () {
      final quest = _makeQuest(result: QuestResult.success);
      final staticData = _makeStaticData(questNarratives: const []);

      final result = QuestNarrativeService.renderNarrative(
        quest: quest,
        partyMercs: [],
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
      );

      expect(result, isNull);
    });

    test('일반 퀘스트 + {merc.name} 치환 확인', () {
      final merc = _makeMerc(name: '홍길동');
      final quest = _makeQuest(result: QuestResult.success);
      final narrative = QuestNarrativeData(
        id: 'n1',
        questType: 'raid',
        resultType: 'success',
        isElite: false,
        template: '{merc.name}이(가) 임무를 완수했다.',
        weight: 1,
      );
      final staticData = _makeStaticData(questNarratives: [narrative]);

      final result = QuestNarrativeService.renderNarrative(
        quest: quest,
        partyMercs: [merc],
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(result, '홍길동이(가) 임무를 완수했다.');
    });

    test('일반 퀘스트 + {quest.enemy} null → "적" fallback 확인', () {
      final quest = _makeQuest(result: QuestResult.success);
      final narrative = QuestNarrativeData(
        id: 'n2',
        questType: 'raid',
        resultType: 'success',
        isElite: false,
        template: '{quest.enemy|적}을(를) 처치했다.',
        weight: 1,
      );
      final staticData = _makeStaticData(questNarratives: [narrative]);

      final result = QuestNarrativeService.renderNarrative(
        quest: quest,
        partyMercs: [],
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(result, '적을(를) 처치했다.');
    });
  });
}
