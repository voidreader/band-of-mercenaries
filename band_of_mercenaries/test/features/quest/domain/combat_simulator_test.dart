import 'package:band_of_mercenaries/core/models/combat_enums.dart';
import 'package:band_of_mercenaries/core/models/combat_report_keyword.dart';
import 'package:band_of_mercenaries/core/models/combat_skill.dart';
import 'package:band_of_mercenaries/core/models/combat_status_effect.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/enemy_archetype.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatSimulator', () {
    test('탐험 의뢰는 요구 처치 수를 달성하면 objective 종료로 기록한다', () {
      final result = CombatSimulator.simulate(
        quest: _quest(questTypeId: 'explore'),
        partyMercs: [_merc(str: 80, vit: 30, agi: 40)],
        pool: _pool(
          typeId: 'explore',
          specialFlags: {'required_kill_count': 1},
        ),
        staticData: _staticData(
          enemies: [
            _enemy(id: 'enemy_front_1', hp: 8, role: 'warrior'),
            _enemy(id: 'enemy_front_2', hp: 80, role: 'warrior'),
          ],
        ),
        userData: _userData(),
        factionStates: const [],
        seed: 7,
      );

      expect(result, isNotNull);
      expect(result!.exitCondition, CombatExitCondition.cObjectiveAchieved);
      expect(result.objectiveProgress, 1.0);
    });

    test('시뮬레이션 결과는 보고서 영속화를 위한 시작 스냅샷을 함께 반환한다', () {
      final dynamic result = CombatSimulator.simulate(
        quest: _quest(),
        partyMercs: [_merc(id: 'merc_a')],
        pool: _pool(),
        staticData: _staticData(enemies: [_enemy()]),
        userData: _userData(),
        factionStates: const [],
        seed: 11,
      );

      expect(result, isNotNull);
      expect(
        result.combatantSnapshots.map((s) => s.mercId),
        contains('merc_a'),
      );
      expect(
        result.enemySnapshots.map((s) => s.archetypeId),
        contains('enemy_a'),
      );
    });

    test('사망 저항으로 부상 처리된 용병은 kill 액션으로 표시하지 않는다', () {
      final staticData = _staticData(
        enemies: [
          _enemy(
            id: 'enemy_executioner',
            hp: 400,
            attack: 120,
            defense: 40,
            str: 90,
            agi: 60,
          ),
        ],
      );
      final quest = _quest();
      final pool = _pool();
      final party = [_merc(id: 'merc_fragile', str: 1, vit: 1, agi: 1)];

      var foundInjurySeed = false;
      for (var seed = 1; seed <= 200; seed++) {
        final result = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );
        if (result == null || result.injuredMercIds.isEmpty) continue;

        foundInjurySeed = true;
        final injured = result.injuredMercIds.toSet();
        final killOnInjured = result.turns
            .expand((turn) => turn.actions)
            .where((action) => action.targetIds.any(injured.contains))
            .where((action) => action.isKill)
            .toList();
        expect(killOnInjured, isEmpty, reason: 'seed=$seed');
        break;
      }

      expect(foundInjurySeed, isTrue);
    });

    test('적 공격을 방패로 막은 파티 용병은 결정적 장면 기여자가 된다', () {
      final staticData = _staticData(
        enemies: [
          _enemy(
            id: 'enemy_attacker',
            hp: 300,
            attack: 18,
            defense: 80,
            agi: 40,
          ),
        ],
      );
      final quest = _quest();
      final pool = _pool();
      final party = [
        _merc(
          id: 'merc_guardian',
          str: 1,
          vit: 60,
          agi: 1,
          traitIds: const ['shield', 'bulwark', 'guardian'],
        ),
      ];

      var foundShieldSeed = false;
      for (var seed = 1; seed <= 200; seed++) {
        final result = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );
        if (result == null) continue;

        final shieldedByGuardian = result.turns
            .expand((turn) => turn.actions)
            .any(
              (action) =>
                  action.actorId.startsWith('enemy_') &&
                  action.targetIds.contains('merc_guardian') &&
                  action.isShielded,
            );
        if (!shieldedByGuardian) continue;

        foundShieldSeed = true;
        expect(result.protagonistMercId, 'merc_guardian', reason: 'seed=$seed');
        break;
      }

      expect(foundShieldSeed, isTrue);
    });
  });
}

ActiveQuest _quest({String questTypeId = 'raid'}) {
  return ActiveQuest(
    id: 'quest_combat_test',
    questPoolId: 'pool_combat_test',
    questTypeId: questTypeId,
    difficulty: 1,
    region: 1,
    questName: '전투 테스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.utc(2026, 5, 19, 1),
    endTime: DateTime.utc(2026, 5, 19, 1, 5),
  );
}

QuestPool _pool({
  String typeId = 'raid',
  Map<String, dynamic> specialFlags = const {},
}) {
  return QuestPool(
    id: 'pool_combat_test',
    name: '전투 테스트 풀',
    type: 1,
    difficulty: 1,
    minRegionDiff: 0,
    maxRegionDiff: 0,
    typeId: typeId,
    specialFlags: specialFlags,
  );
}

Mercenary _merc({
  String id = 'merc_a',
  int str = 30,
  int intelligence = 10,
  int vit = 30,
  int agi = 20,
  List<String> traitIds = const [],
}) {
  return Mercenary(
    id: id,
    name: id,
    jobId: 'job_warrior',
    traitId: '',
    str: str,
    intelligence: intelligence,
    vit: vit,
    agi: agi,
    traitIds: traitIds,
    recruitedAt: DateTime.utc(2026, 1, 1),
  );
}

EnemyArchetype _enemy({
  String id = 'enemy_a',
  String role = 'warrior',
  int hp = 40,
  int attack = 8,
  int defense = 4,
  int str = 8,
  int intelligence = 2,
  int vit = 8,
  int agi = 4,
}) {
  return EnemyArchetype(
    id: id,
    name: id,
    enemyKind: EnemyKind.normal,
    role: role,
    tier: 1,
    baseStr: str,
    baseInt: intelligence,
    baseVit: vit,
    baseAgi: agi,
    baseHp: hp,
    baseAttack: attack,
    baseDefense: defense,
    behaviorPattern: BehaviorPattern.aggressive,
    environmentTags: const ['plains'],
    description: '테스트 적',
  );
}

UserData _userData() {
  return UserData(
    gold: 1000,
    region: 1,
    sector: 1,
    lastFreeRecruit: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

StaticGameData _staticData({required List<EnemyArchetype> enemies}) {
  return StaticGameData(
    difficulties: const [
      Difficulty(
        level: 1,
        enemyPower: 10,
        rewardMultiplier: 1,
        successPenalty: 0,
        injuryRate: 0.1,
        deathRate: 0.05,
        minDispatchCost: 1,
        maxDispatchCost: 2,
      ),
    ],
    jobs: const [
      Job(
        id: 'job_warrior',
        tier: 1,
        name: '전사',
        baseStr: 10,
        baseIntelligence: 5,
        baseVit: 10,
        baseAgi: 8,
        role: 'warrior',
      ),
    ],
    traits: const [],
    traitCategories: const [],
    traitConflicts: const [],
    traitTransitions: const [],
    traitComboEvolutions: const [],
    traitSynergies: const [],
    regions: const [
      Region(
        continent: 1,
        region: 1,
        regionName: '테스트 평원',
        regionTier: 1,
        recommendPower: 1,
        description: '테스트',
        environmentTags: ['plains'],
      ),
    ],
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
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
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
    combatReportTemplates: const [],
    combatReportKeywords: const [
      CombatReportKeyword(
        id: 'kw_plains',
        category: 'battlefield',
        key: 'plains',
        displayText: '평원',
      ),
    ],
    combatSkills: const [
      CombatSkill(
        id: 'skill_warrior_shield_bulwark',
        role: 'warrior',
        triggerKind: TriggerKind.passive,
        actionCost: ActionCost.passive,
        targetingKind: TargetingKind.self,
        shieldBlockBonus: 0.10,
        displayLabel: '방패 보루',
        description: '방패 막기 강화',
      ),
    ],
    combatStatusEffects: const [
      CombatStatusEffect(
        id: 'buff_attack_up',
        kind: 'buff',
        displayLabel: '공격력 강화',
        defaultDurationTurns: 2,
        defaultIntensity: 0.2,
        stackPolicy: StackPolicy.refresh,
        hookTarget: ['attack'],
        applyMethod: ApplyMethod.multiplicative,
        description: '공격력 강화',
      ),
      CombatStatusEffect(
        id: 'debuff_accuracy_down',
        kind: 'debuff',
        displayLabel: '명중 약화',
        defaultDurationTurns: 2,
        defaultIntensity: 0.1,
        stackPolicy: StackPolicy.refresh,
        hookTarget: ['hit'],
        applyMethod: ApplyMethod.additive,
        description: '명중 약화',
      ),
    ],
    enemyArchetypes: enemies,
  );
}
