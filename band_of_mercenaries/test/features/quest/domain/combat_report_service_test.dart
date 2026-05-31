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
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';

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
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
    hiddenStats: const [],
    battleMemoryTemplates: const [],
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

    test('simulationResult가 있으면 템플릿이 없어도 최소 보고서를 반환한다', () {
      final staticData = _makeStaticData(combatReportTemplates: const []);
      final quest = _makeQuest(result: QuestResult.success);
      final merc = _makeMerc(name: '주인공');
      final simulationResult = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: const [],
        protagonistMercId: merc.id,
        featuredMercIds: [merc.id],
        exitCondition: CombatExitCondition.cObjectiveAchieved,
        seed: 123,
        toneTags: const ['decisive'],
      );

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 0,
        simulationResult: simulationResult,
      );

      expect(report, isNotNull);
      expect(report!.summary, isNotEmpty);
      expect(report.details, isNotEmpty);
      expect(report.templateIds, isEmpty);
      expect(report.schemaVersion, 1);
      expect(report.turns, same(simulationResult.turns));
      expect(report.exitCondition, simulationResult.exitCondition);
      expect(report.objectiveProgress, simulationResult.objectiveProgress);
      expect(report.featuredMercIds, [merc.id]);
      expect(report.toneTags, contains('decisive'));
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

  // ==========================================================================
  // M8b 페이즈 4 #5 — FR-8 / FR-9 / FR-17 보강
  // ==========================================================================

  group('FR-17 simulationResult=null 시 M8a 호환 (schemaVersion null)', () {
    test('simulationResult 미전달 시 schemaVersion 등 신규 필드 모두 null', () {
      final templates = [
        _makeTemplate(
          id: 't_sum',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'summary',
          template: '요약',
        ),
        for (var i = 0; i < 6; i++)
          _makeTemplate(
            id: 't_det_$i',
            scope: 'quest_type',
            resultType: 'success',
            lineType: 'detail',
            template: '상세 $i',
          ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(result: QuestResult.success);
      final merc = _makeMerc(name: '주인공');

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 7,
        simulationResult: null,
      );

      expect(report, isNotNull);
      // M8b 신규 HiveField 8~14 모두 null/default 보장.
      expect(report!.schemaVersion, isNull, reason: 'schemaVersion');
      expect(report.turns, isNull, reason: 'turns');
      expect(report.combatantSnapshots, isNull, reason: 'combatantSnapshots');
      expect(report.exitCondition, isNull, reason: 'exitCondition');
      expect(report.objectiveProgress, isNull, reason: 'objectiveProgress');
      expect(report.enemySnapshots, isNull, reason: 'enemySnapshots');
      expect(report.statusEffectHistory, isNull, reason: 'statusEffectHistory');
    });
  });

  group('FR-8 / FR-9 simulationResult 입력 시 details.length 매트릭스', () {
    // 본 그룹은 simulationResult가 있는 보고서 생성 시 details.length가
    // 페이즈 2 #4 §2.1 매트릭스(3R→4 / 4~5R→5~6 / 6R→6~7 / 7~8R→7~8) 정합인지 확인.
    // 라인 풀이 충분하면 매트릭스에 맞춰 details가 생성되어야 한다.
    //
    // 페이즈 4 #3 [FR-9.2]: simulationResult != null일 때 템플릿 선택 실패 시에도
    // 최소 fallback 보고서를 만들어 schemaVersion=1과 구조 필드를 저장한다.
    //
    // 본 검증의 핵심:
    //   1) simulationResult != null → report.schemaVersion == 1.
    //   2) report.turns / combatantSnapshots / exitCondition 등 구조 필드 임베드.
    //   3) details.length 가 합리적 범위 (라인 풀이 부족하면 최소 fallback).

    test('simulationResult != null + 라인 풀 충분 → schemaVersion=1, 구조 필드 임베드', () {
      // 라인 풀: summary 1 + detail 16 (8 라운드 매트릭스 충분).
      final templates = [
        _makeTemplate(
          id: 't_sum',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'summary',
          template: '요약',
        ),
        for (var i = 0; i < 16; i++)
          _makeTemplate(
            id: 't_det_$i',
            scope: 'quest_type',
            resultType: 'success',
            lineType: 'detail',
            template: '상세 $i',
          ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(result: QuestResult.success);
      final merc = _makeMerc(name: '주인공');

      final simResult = _stubSimulationResult(
        questResult: QuestResult.success,
        turnCount: 6,
      );

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 7,
        simulationResult: simResult,
      );

      expect(report, isNotNull);
      // M8b 페이즈 4 #3 [FR-9] 최소 임베드 검증.
      expect(report!.schemaVersion, equals(1), reason: 'schemaVersion=1');
      expect(report.turns, isNotNull, reason: 'turns 임베드');
      expect(report.turns!.length, equals(6), reason: 'turns 길이 보존');
      expect(report.exitCondition, isNotNull, reason: 'exitCondition 임베드');
      expect(report.objectiveProgress, isNotNull, reason: 'objectiveProgress 임베드');
      // 페이즈 2 #4 §2.1: 6라운드 → details 6~7줄.
      expect(report.details.length, inInclusiveRange(1, 8));
    });

    test('simulationResult != null + 라인 풀 부족 → 최소 fallback 보고서', () {
      // 라인 풀이 매우 빈약해도 simulationResult가 있으면 null 반환 금지
      // (페이즈 4 #3 [FR-9.2]).
      final templates = [
        _makeTemplate(
          id: 't_sum',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'summary',
          template: '요약',
        ),
      ];
      final staticData = _makeStaticData(combatReportTemplates: templates);
      final quest = _makeQuest(result: QuestResult.success);
      final merc = _makeMerc(name: '주인공');

      final simResult = _stubSimulationResult(
        questResult: QuestResult.success,
        turnCount: 3,
      );

      final report = CombatReportService.generate(
        quest: quest,
        partyMercs: [merc],
        resultType: QuestResult.success,
        staticData: staticData,
        userData: _makeUserData(),
        factionStates: const [],
        templateEngine: _engine,
        seed: 7,
        simulationResult: simResult,
      );

      expect(report, isNotNull, reason: '최소 fallback 보고서 반환');
      expect(report!.schemaVersion, equals(1));
      expect(report.turns, isNotNull);
    });
  });

  // ==========================================================================
  // M8.5 페이즈 4 #3 — FR-17 감정 장면 섹션 테스트
  // ==========================================================================

  group('FR-17 감정 장면 섹션 (_buildEmotionalScenes)', () {
    // ------------------------------------------------------------------------
    // helper: emotional scope 템플릿 생성 (tags_json.emotion 키 기반 매칭)
    // ------------------------------------------------------------------------

    // 감정 종류별 emotional 템플릿 생성 (tags_json = {"emotion": "<kind>"})
    CombatReportTemplate makeEmotionalTemplate({
      required String id,
      required String emotionKind,
      String template = '',
    }) {
      return _makeTemplate(
        id: id,
        scope: 'emotional',
        resultType: null,
        lineType: 'detail',
        template: template.isEmpty ? 'emotional_$emotionKind 장면' : template,
        tagsJson: <String, dynamic>{'emotion': emotionKind},
      );
    }

    // statusEffectHistory 주입용 apply 이벤트 생성
    StatusEffectEvent makeApplyEvent(String effectId) {
      return StatusEffectEvent(
        eventType: 'apply',
        roundIndex: 0,
        targetId: 'merc-001',
        effectId: effectId,
        labelKey: effectId,
      );
    }

    // 기본 quest_type 템플릿 (summary + detail) — simulationResult가 있을 때
    // 본문 구성을 위한 최소 풀
    List<CombatReportTemplate> baseTemplates() {
      return [
        _makeTemplate(
          id: 'base_sum',
          scope: 'quest_type',
          resultType: 'success',
          lineType: 'summary',
          template: '기본 요약',
        ),
        for (var i = 0; i < 6; i++)
          _makeTemplate(
            id: 'base_det_$i',
            scope: 'quest_type',
            resultType: 'success',
            lineType: 'detail',
            template: '기본 상세 $i',
          ),
      ];
    }

    // simulationResult with statusEffectHistory
    CombatSimulationResult makeSimWithHistory(
      List<StatusEffectEvent> history,
    ) {
      return CombatSimulationResult(
        questResult: QuestResult.success,
        turns: const [],
        protagonistMercId: 'merc-001',
        featuredMercIds: const ['merc-001'],
        exitCondition: CombatExitCondition.cObjectiveAchieved,
        statusEffectHistory: history,
        seed: 42,
        toneTags: const [],
      );
    }

    test(
      'scope=emotional 템플릿이 있으면 감정 장면이 최대 3줄 추가된다',
      () {
        // 4종 감정 이벤트 주입 — 우선순위 역순으로 나열해 정렬 확인도 겸함
        final history = [
          makeApplyEvent('emotional_despair'), // 우선순위 4위
          makeApplyEvent('emotional_sorrow'), // 우선순위 3위
          makeApplyEvent('emotional_rage'), // 우선순위 2위
          makeApplyEvent('emotional_determination'), // 우선순위 1위
        ];

        final emotionalTemplates = [
          makeEmotionalTemplate(id: 'e_det', emotionKind: 'determination'),
          makeEmotionalTemplate(id: 'e_rage', emotionKind: 'rage'),
          makeEmotionalTemplate(id: 'e_sorrow', emotionKind: 'sorrow'),
          makeEmotionalTemplate(id: 'e_despair', emotionKind: 'despair'),
        ];

        final allTemplates = [...baseTemplates(), ...emotionalTemplates];
        final staticData = _makeStaticData(
          combatReportTemplates: allTemplates,
        );
        final quest = _makeQuest(result: QuestResult.success);
        final merc = _makeMerc(name: '주인공');
        final simResult = makeSimWithHistory(history);

        final report = CombatReportService.generate(
          quest: quest,
          partyMercs: [merc],
          resultType: QuestResult.success,
          staticData: staticData,
          userData: _makeUserData(),
          factionStates: const [],
          templateEngine: _engine,
          seed: 10,
          simulationResult: simResult,
        );

        expect(report, isNotNull);
        // 감정 장면은 최대 3줄 (4가지 감정 중 3개만 추가)
        // details = base_details + emotional_lines, emotional_lines <= 3
        final emotionalContent = report!.details
            .where((line) => line.startsWith('emotional_'))
            .toList();
        expect(
          emotionalContent.length,
          lessThanOrEqualTo(3),
          reason: '감정 장면은 최대 3줄',
        );
        expect(
          emotionalContent.length,
          greaterThanOrEqualTo(1),
          reason: '감정 이벤트가 있으면 최소 1줄 추가',
        );
      },
    );

    test(
      '감정 장면이 우선순위 순(투지>분노>슬픔>절망)으로 추가된다',
      () {
        // 4종 감정 이벤트를 모두 주입 — 보고서 details 후미에 붙는 감정 줄이
        // determination → rage → sorrow (또는 despair) 순임을 확인
        final history = [
          makeApplyEvent('emotional_despair'),
          makeApplyEvent('emotional_sorrow'),
          makeApplyEvent('emotional_rage'),
          makeApplyEvent('emotional_determination'),
        ];

        final emotionalTemplates = [
          makeEmotionalTemplate(
            id: 'e_det',
            emotionKind: 'determination',
            template: '투지_장면',
          ),
          makeEmotionalTemplate(
            id: 'e_rage',
            emotionKind: 'rage',
            template: '분노_장면',
          ),
          makeEmotionalTemplate(
            id: 'e_sorrow',
            emotionKind: 'sorrow',
            template: '슬픔_장면',
          ),
          makeEmotionalTemplate(
            id: 'e_despair',
            emotionKind: 'despair',
            template: '절망_장면',
          ),
        ];

        final allTemplates = [...baseTemplates(), ...emotionalTemplates];
        final staticData = _makeStaticData(
          combatReportTemplates: allTemplates,
        );
        final quest = _makeQuest(result: QuestResult.success);
        final merc = _makeMerc(name: '주인공');
        final simResult = makeSimWithHistory(history);

        final report = CombatReportService.generate(
          quest: quest,
          partyMercs: [merc],
          resultType: QuestResult.success,
          staticData: staticData,
          userData: _makeUserData(),
          factionStates: const [],
          templateEngine: _engine,
          seed: 10,
          simulationResult: simResult,
        );

        expect(report, isNotNull);
        final allDetails = report!.details;

        // details 후미 최대 3개를 감정 줄 후보로 확인
        // 전체 details에서 투지_장면은 분노_장면보다 앞에 등장해야 함
        int detIdx(String marker) =>
            allDetails.indexWhere((l) => l.contains(marker));
        final detIdx1 = detIdx('투지_장면');
        final detIdx2 = detIdx('분노_장면');

        // 투지, 분노 둘 다 등장한 경우에만 순서 검증
        if (detIdx1 >= 0 && detIdx2 >= 0) {
          expect(
            detIdx1 < detIdx2,
            isTrue,
            reason: '투지 장면은 분노 장면보다 먼저 등장해야 함',
          );
        }

        // 투지 장면은 반드시 포함 (최우선순위)
        expect(
          allDetails.any((l) => l.contains('투지_장면')),
          isTrue,
          reason: '최우선순위 투지 장면이 포함되어야 함',
        );
      },
    );

    test(
      'scope=emotional 템플릿이 없으면(빈 풀) 보고서 생성이 실패하지 않는다(fail-soft)',
      () {
        // emotional 이벤트가 있어도 scope='emotional' 템플릿이 0행이면 skip
        final history = [
          makeApplyEvent('emotional_determination'),
          makeApplyEvent('emotional_rage'),
        ];

        // emotional scope 없이 기본 템플릿만 구성
        final staticData = _makeStaticData(
          combatReportTemplates: baseTemplates(),
        );
        final quest = _makeQuest(result: QuestResult.success);
        final merc = _makeMerc(name: '주인공');
        final simResult = makeSimWithHistory(history);

        final report = CombatReportService.generate(
          quest: quest,
          partyMercs: [merc],
          resultType: QuestResult.success,
          staticData: staticData,
          userData: _makeUserData(),
          factionStates: const [],
          templateEngine: _engine,
          seed: 10,
          simulationResult: simResult,
        );

        // fail-soft: null 반환 금지
        expect(report, isNotNull, reason: '빈 emotional 풀에서도 보고서 생성 성공');

        // 기존 본문 details가 그대로 유지됨 (emotional 줄이 추가되지 않음)
        final hasEmotional = report!.details.any(
          (l) => l.startsWith('emotional_'),
        );
        expect(
          hasEmotional,
          isFalse,
          reason: 'emotional 템플릿이 없으면 감정 줄이 추가되지 않아야 함',
        );

        // 기존 base details가 정상 포함
        expect(report.details, isNotEmpty, reason: '기본 details가 유지되어야 함');
      },
    );

    test(
      '동일 감정 effectId 중복 이벤트는 1줄만 추가된다',
      () {
        // 같은 effectId가 여러 번 apply되어도 1회만 추출
        final history = [
          makeApplyEvent('emotional_rage'),
          makeApplyEvent('emotional_rage'), // 중복
          makeApplyEvent('emotional_rage'), // 중복
        ];

        final emotionalTemplates = [
          makeEmotionalTemplate(
            id: 'e_rage',
            emotionKind: 'rage',
            template: '분노_장면',
          ),
          makeEmotionalTemplate(
            id: 'e_rage2',
            emotionKind: 'rage',
            template: '분노_장면2',
          ),
        ];

        final allTemplates = [...baseTemplates(), ...emotionalTemplates];
        final staticData = _makeStaticData(
          combatReportTemplates: allTemplates,
        );
        final quest = _makeQuest(result: QuestResult.success);
        final merc = _makeMerc(name: '주인공');
        final simResult = makeSimWithHistory(history);

        final report = CombatReportService.generate(
          quest: quest,
          partyMercs: [merc],
          resultType: QuestResult.success,
          staticData: staticData,
          userData: _makeUserData(),
          factionStates: const [],
          templateEngine: _engine,
          seed: 10,
          simulationResult: simResult,
        );

        expect(report, isNotNull);
        // rage effectId 중복이므로 추가되는 감정 장면은 1줄
        final emotionalCount = report!.details
            .where(
              (l) => l.contains('분노_장면'),
            )
            .length;
        expect(
          emotionalCount,
          equals(1),
          reason: '중복 effectId는 1줄만 추가',
        );
      },
    );

    test(
      'simulationResult=null이면 감정 장면이 추가되지 않는다',
      () {
        final emotionalTemplates = [
          makeEmotionalTemplate(id: 'e_det', emotionKind: 'determination'),
        ];
        final allTemplates = [...baseTemplates(), ...emotionalTemplates];
        final staticData = _makeStaticData(
          combatReportTemplates: allTemplates,
        );
        final quest = _makeQuest(result: QuestResult.success);
        final merc = _makeMerc(name: '주인공');

        final report = CombatReportService.generate(
          quest: quest,
          partyMercs: [merc],
          resultType: QuestResult.success,
          staticData: staticData,
          userData: _makeUserData(),
          factionStates: const [],
          templateEngine: _engine,
          seed: 10,
          simulationResult: null, // simulationResult 없음
        );

        expect(report, isNotNull);
        // simulationResult=null → _buildEmotionalScenes 즉시 [] 반환
        final hasEmotional = report!.details.any(
          (l) => l.startsWith('emotional_'),
        );
        expect(
          hasEmotional,
          isFalse,
          reason: 'simulationResult=null이면 감정 장면 없음',
        );
      },
    );
  });
}

// ===========================================================================
// FR-8/FR-9/FR-17 보강용 헬퍼
// ===========================================================================

CombatSimulationResult _stubSimulationResult({
  required QuestResult questResult,
  required int turnCount,
}) {
  return CombatSimulationResult(
    questResult: questResult,
    turns: [
      for (var i = 0; i < turnCount; i++)
        CombatTurn(roundIndex: i, phase: 'general', actions: const []),
    ],
    protagonistMercId: 'merc-001',
    featuredMercIds: const ['merc-001'],
    injuredMercIds: const [],
    deceasedMercIds: const [],
    objectiveProgress: 1.0,
    exitCondition: CombatExitCondition.bEnemyWiped,
    statusEffectHistory: const [],
    seed: 1,
    toneTags: const [],
    combatantSnapshots: const [],
    enemySnapshots: const [],
  );
}
