import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/models/combat_report_keyword.dart';
import 'package:band_of_mercenaries/core/models/combat_report_template.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

const _engine = TemplateEngine();

// ===========================================================================
// helper factory
// ===========================================================================

UserData _makeUserData() {
  final now = DateTime(2026, 5, 18);
  return UserData(
    gold: 1000,
    region: 1,
    sector: 0,
    lastFreeRecruit: now,
    createdAt: now,
  );
}

UserData _makeUserDataWithReputation(int reputation) {
  final user = _makeUserData();
  user.reputation = reputation;
  return user;
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
  QuestResult? result,
  String questTypeId = 'raid',
  String questPoolId = 'pool-001',
  String? eliteId,
  bool isChainStep = false,
  String? chainId,
  int? chainStep,
  String? factionTag,
  Map<String, dynamic>? specialFlags,
}) {
  return ActiveQuest(
    id: 'quest-001',
    questPoolId: questPoolId,
    questTypeId: questTypeId,
    difficulty: 1,
    region: 1,
    questName: '테스트 퀘스트',
    result: result,
    eliteId: eliteId,
    isChainStep: isChainStep ? true : null,
    chainId: chainId,
    chainStep: chainStep,
    factionTag: factionTag,
    specialFlags: specialFlags,
  );
}

CombatReportTemplate _makeTemplate({
  required String id,
  required String scope,
  String? factionId,
  String? questType,
  String? resultType,
  required String lineType,
  String importance = 'normal',
  int weight = 1,
  required String template,
  Object? tagsJson,
}) {
  return CombatReportTemplate(
    id: id,
    group: 'g1',
    scope: scope,
    factionId: factionId,
    questType: questType,
    resultType: resultType,
    lineType: lineType,
    importance: importance,
    weight: weight,
    template: template,
    tagsJson: tagsJson,
  );
}

EliteMonsterData _makeEliteMonster({
  required String id,
  bool isUnique = false,
}) {
  return EliteMonsterData(
    id: id,
    name: 'Test Elite',
    description: 'desc',
    isUnique: isUnique,
    typeFamily: 'beast',
    tier: 3,
    power: 100,
    spawnRate: 0.1,
    durationMultiplier: 1.0,
  );
}

StaticGameData _makeStaticData({
  List<CombatReportTemplate> combatReportTemplates = const [],
  List<CombatReportKeyword> combatReportKeywords = const [],
  List<EliteMonsterData> eliteMonsters = const [],
  List<ChainQuestData> chainQuests = const [],
}) {
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
    regionAdjacencies: const [],
    regionSectors: const [],
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
    eliteMonsters: eliteMonsters,
    eliteLootEntries: const [],
    chainQuests: chainQuests,
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: combatReportTemplates,
    combatReportKeywords: combatReportKeywords,
  );
}

// ===========================================================================
// 테스트
// ===========================================================================

void main() {
  group('CombatReportService.generate', () {
    test('동일 seed 입력 시 동일 보고서 반환', () {
      final templates = [
        _makeTemplate(
          id: 't1',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'summary',
          template: '요약 1',
        ),
        _makeTemplate(
          id: 't2',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'detail',
          template: '상세 1',
        ),
        _makeTemplate(
          id: 't3',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'detail',
          template: '상세 2',
        ),
        _makeTemplate(
          id: 't4',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'detail',
          template: '상세 3',
        ),
        _makeTemplate(
          id: 't5',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'detail',
          template: '상세 4',
        ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(result: QuestResult.success);
      final merc = _makeMerc(name: '홍길동');

      final r1 = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 42,
      );
      final r2 = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 42,
      );

      expect(r1, isNotNull);
      expect(r2, isNotNull);
      expect(r1!.summary, r2!.summary);
      expect(r1.details, r2.details);
      expect(r1.templateIds, r2.templateIds);
    });

    test('greatSuccess → great_success 템플릿만 매칭', () {
      final templates = [
        _makeTemplate(
          id: 'gs',
          scope: 'quest_type',
          resultType: 'great_success',
          lineType: 'summary',
          template: 'GS',
        ),
        _makeTemplate(
          id: 'gd',
          scope: 'quest_type',
          resultType: 'great_success',
          lineType: 'detail',
          template: 'GD',
        ),
        _makeTemplate(
          id: 's',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'summary',
          template: 'S',
        ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(result: QuestResult.greatSuccess);

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [_makeMerc(name: '주인공')],
        resultType: QuestResult.greatSuccess,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(report, isNotNull);
      expect(report!.summary, 'GS');
      expect(report.templateIds, containsAll(['gs', 'gd']));
    });

    test('유니크 엘리트 → unique_elite scope 우선 매칭', () {
      final elite = _makeEliteMonster(id: 'elite-u', isUnique: true);
      final templates = [
        _makeTemplate(
          id: 'us',
          scope: 'unique_elite',
          questType: 'raid',
          resultType: 'success',
          lineType: 'summary',
          template: 'US',
        ),
        _makeTemplate(
          id: 'qs',
          scope: 'quest_type',
          questType: 'raid',
          resultType: 'success',
          lineType: 'summary',
          template: 'QS',
        ),
        for (var i = 0; i < 10; i++)
          _makeTemplate(
            id: 'ud_$i',
            scope: 'unique_elite',
            questType: 'raid',
            resultType: 'success',
            lineType: 'detail',
            template: 'UD$i',
          ),
      ];
      final staticData = _makeStaticData(
        combatReportTemplates: templates,
        eliteMonsters: [elite],
      );
      final quest = _makeQuest(result: QuestResult.success, eliteId: 'elite-u');

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [_makeMerc(name: '주인공')],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(report, isNotNull);
      expect(report!.summary, 'US'); // unique_elite scope 우선 매칭
      expect(
        report.details.length,
        inInclusiveRange(6, 8),
      ); // veryHigh importance
    });

    test('scope fallback — chain_step 매칭 + scene 상세 보충', () {
      // chainStep: 0, totalSteps: 3 → (0+1) = 1 != 3 → chain_step (not final)
      final chain = ChainQuestData(
        id: 'cq1',
        chainId: 'chain-1',
        chainName: 'Test Chain',
        step: 1,
        totalSteps: 3,
        name: 'Step1',
        description: 'd',
        questTypeId: 'raid',
        difficulty: 1,
        combatPower: 10,
        rewardGold: 0,
        durationSeconds: 60,
      );
      final templates = [
        _makeTemplate(
          id: 'cs',
          scope: 'chain_step',
          questType: 'raid',
          resultType: 'success',
          lineType: 'summary',
          template: 'CS',
        ),
        _makeTemplate(
          id: 'cd',
          scope: 'chain_step',
          questType: 'raid',
          resultType: 'success',
          lineType: 'detail',
          template: 'CD',
        ),
        for (var i = 0; i < 8; i++)
          _makeTemplate(
            id: 'sc_$i',
            scope: 'scene',
            questType: 'raid',
            resultType: 'success',
            lineType: 'detail',
            template: 'SC$i',
          ),
      ];
      final staticData = _makeStaticData(
        combatReportTemplates: templates,
        chainQuests: [chain],
      );
      final quest = _makeQuest(
        result: QuestResult.success,
        isChainStep: true,
        chainId: 'chain-1',
        chainStep: 0, // (0+1) != 3 → chain_step (not final)
      );

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [_makeMerc(name: '주인공')],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(report, isNotNull);
      expect(report!.summary, 'CS');
      expect(report.details, isNotEmpty);
    });

    test('combatReportTemplates 빈 리스트 → null 반환', () {
      final staticData = _makeStaticData(combatReportTemplates: const []);
      final quest = _makeQuest(result: QuestResult.success);

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [_makeMerc(name: '주인공')],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(report, isNull);
    });

    test('partyMercs 빈 리스트 → null 반환 (protagonist null)', () {
      final templates = [
        _makeTemplate(
          id: 't1',
          scope: 'quest_type',
          questType: 'raid',
          resultType: 'success',
          lineType: 'summary',
          template: 'X',
        ),
        _makeTemplate(
          id: 't2',
          scope: 'quest_type',
          questType: 'raid',
          resultType: 'success',
          lineType: 'detail',
          template: 'Y',
        ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(result: QuestResult.success);

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: const [],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
      );

      expect(report, isNull);
    });

    test('세력 지명 보고서 중요도는 용병단 명성이 아니라 세력 평판을 기준으로 한다', () {
      final templates = [
        _makeTemplate(
          id: 'summary',
          scope: 'faction_named',
          factionId: 'faction_adventurers_guild',
          resultType: 'success',
          lineType: 'summary',
          template: '요약',
        ),
        _makeTemplate(
          id: 'faction_detail',
          scope: 'faction_named',
          factionId: 'faction_adventurers_guild',
          resultType: 'success',
          lineType: 'detail',
          template: '세력 상세',
        ),
        for (var i = 0; i < 8; i++)
          _makeTemplate(
            id: 'scene_$i',
            scope: 'scene',
            resultType: 'success',
            lineType: 'detail',
            template: '장면 $i',
          ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(
        result: QuestResult.success,
        factionTag: 'faction_adventurers_guild',
        specialFlags: const {'faction_named': true},
      );
      final merc = _makeMerc(name: '주인공');

      final lowFactionRep = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserDataWithReputation(100),
        factionStates: [
          FactionState(factionId: 'faction_adventurers_guild', reputation: 0),
        ],
        templateEngine: _engine,
        seed: 1,
      );
      final trustedFactionRep = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserDataWithReputation(0),
        factionStates: [
          FactionState(factionId: 'faction_adventurers_guild', reputation: 31),
        ],
        templateEngine: _engine,
        seed: 1,
      );

      expect(lowFactionRep, isNotNull);
      expect(trustedFactionRep, isNotNull);
      expect(lowFactionRep!.details.length, 4);
      expect(trustedFactionRep!.details.length, greaterThan(4));
    });
  });
}
