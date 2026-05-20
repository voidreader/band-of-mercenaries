// M8b 페이즈 4 #5 FR-1 — CombatSimulator 시드 결정성 검증.
//
// 검증 범위:
//   동일 입력 + 동일 시드로 simulate를 2회 호출했을 때
//   questResult / turns / injuredMercIds / deceasedMercIds /
//   objectiveProgress / exitCondition / statusEffectHistory 7 필드가 동일해야 한다.
//
// 시드 표본: {1, 7, 13, 42, 100, 200, 500, 999} (8 시드)
// 시나리오: 일반 엘리트 / 유니크 엘리트 / 체인 핵심 단계+엘리트 동반 (3 시나리오)
// = 24 케이스.

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
import 'package:band_of_mercenaries/features/quest/domain/combat_action.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulator.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';
import 'package:flutter_test/flutter_test.dart';

const _seeds = [1, 7, 13, 42, 100, 200, 500, 999];

void main() {
  group('CombatSimulator FR-1 시드 결정성', () {
    for (final seed in _seeds) {
      test('일반 엘리트 — seed=$seed 동일 입력 2회 호출 결과 일치', () {
        final quest = _quest(eliteId: 'elite_a');
        final pool = _pool();
        final party = [_merc(id: 'merc_a'), _merc(id: 'merc_b', str: 25)];
        final staticData = _staticData(
          enemies: [
            _enemy(id: 'elite_a', enemyKind: EnemyKind.elite, hp: 80),
            _enemy(id: 'enemy_normal_a'),
            _enemy(id: 'enemy_normal_b'),
          ],
        );

        final first = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );
        final second = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );

        _expectDeterministic(first, second, scenario: '일반 엘리트', seed: seed);
      });

      test('유니크 엘리트 — seed=$seed 동일 입력 2회 호출 결과 일치', () {
        final quest = _quest(eliteId: 'elite_unique');
        final pool = _pool();
        final party = [_merc(id: 'merc_a'), _merc(id: 'merc_b')];
        final staticData = _staticData(
          enemies: [
            _enemy(
              id: 'elite_unique',
              enemyKind: EnemyKind.unique,
              hp: 200,
              attack: 12,
            ),
            _enemy(id: 'enemy_normal_a'),
          ],
        );

        final first = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );
        final second = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );

        _expectDeterministic(first, second, scenario: '유니크 엘리트', seed: seed);
      });

      test('체인 핵심 단계 + 엘리트 동반 — seed=$seed 동일 입력 2회 호출 결과 일치', () {
        final quest = _quest(
          eliteId: 'elite_chain',
          chainId: 'chain_test',
          chainStep: 1,
          isChainStep: true,
          specialFlags: const {
            'chain_protagonist_id': 'merc_a',
          },
        );
        final pool = _pool(specialFlags: const {
          'chain_core_step': true,
        });
        final party = [
          _merc(id: 'merc_a', vit: 50),
          _merc(id: 'merc_b'),
        ];
        final staticData = _staticData(
          enemies: [
            _enemy(id: 'elite_chain', enemyKind: EnemyKind.elite),
            _enemy(id: 'enemy_normal_a'),
            _enemy(id: 'enemy_normal_b'),
          ],
        );

        final first = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );
        final second = CombatSimulator.simulate(
          quest: quest,
          partyMercs: party,
          pool: pool,
          staticData: staticData,
          userData: _userData(),
          factionStates: const [],
          seed: seed,
        );

        _expectDeterministic(
          first,
          second,
          scenario: '체인 핵심 + 엘리트 동반',
          seed: seed,
        );
      });
    }
  });
}

void _expectDeterministic(
  dynamic first,
  dynamic second, {
  required String scenario,
  required int seed,
}) {
  final reason = 'scenario=$scenario seed=$seed';
  expect(first, isNotNull, reason: '$reason 시뮬레이션 1회차 null');
  expect(second, isNotNull, reason: '$reason 시뮬레이션 2회차 null');

  expect(first.questResult, equals(second.questResult), reason: '$reason questResult');
  expect(first.exitCondition, equals(second.exitCondition), reason: '$reason exitCondition');
  expect(
    first.objectiveProgress,
    equals(second.objectiveProgress),
    reason: '$reason objectiveProgress',
  );
  expect(
    first.injuredMercIds,
    orderedEquals(second.injuredMercIds),
    reason: '$reason injuredMercIds',
  );
  expect(
    first.deceasedMercIds,
    orderedEquals(second.deceasedMercIds),
    reason: '$reason deceasedMercIds',
  );

  // turns 비교: 라운드별 액션 시그니처(actorId/actionKind/damage/isKill/isCrit/isShielded/isEvaded)
  // 가 동일한지 확인. 전체 객체 deep equality는 Hive 객체 특성상 어렵다.
  expect(first.turns.length, equals(second.turns.length), reason: '$reason turns 길이');
  for (var i = 0; i < first.turns.length; i++) {
    final CombatTurn t1 = first.turns[i];
    final CombatTurn t2 = second.turns[i];
    expect(t1.roundIndex, equals(t2.roundIndex), reason: '$reason turn $i roundIndex');
    expect(t1.phase, equals(t2.phase), reason: '$reason turn $i phase');
    expect(
      t1.actions.length,
      equals(t2.actions.length),
      reason: '$reason turn $i actions 길이',
    );
    for (var j = 0; j < t1.actions.length; j++) {
      final CombatAction a1 = t1.actions[j];
      final CombatAction a2 = t2.actions[j];
      expect(a1.actorId, equals(a2.actorId), reason: '$reason turn $i action $j actorId');
      expect(
        a1.actionKind,
        equals(a2.actionKind),
        reason: '$reason turn $i action $j actionKind',
      );
      expect(a1.damage, equals(a2.damage), reason: '$reason turn $i action $j damage');
      expect(a1.isKill, equals(a2.isKill), reason: '$reason turn $i action $j isKill');
      expect(a1.isCrit, equals(a2.isCrit), reason: '$reason turn $i action $j isCrit');
      expect(a1.isShielded, equals(a2.isShielded), reason: '$reason turn $i action $j isShielded');
      expect(a1.isEvaded, equals(a2.isEvaded), reason: '$reason turn $i action $j isEvaded');
    }
  }

  // statusEffectHistory 비교: 길이 + 각 이벤트의 핵심 필드.
  expect(
    first.statusEffectHistory.length,
    equals(second.statusEffectHistory.length),
    reason: '$reason statusEffectHistory 길이',
  );
  for (var i = 0; i < first.statusEffectHistory.length; i++) {
    final StatusEffectEvent e1 = first.statusEffectHistory[i];
    final StatusEffectEvent e2 = second.statusEffectHistory[i];
    expect(e1.effectId, equals(e2.effectId), reason: '$reason event $i effectId');
    expect(e1.targetId, equals(e2.targetId), reason: '$reason event $i targetId');
    expect(e1.roundIndex, equals(e2.roundIndex), reason: '$reason event $i roundIndex');
  }
}

// ============================================================================
// 헬퍼 (combat_simulator_test.dart 패턴 재사용)
// ============================================================================

ActiveQuest _quest({
  String questTypeId = 'raid',
  String? eliteId,
  String? chainId,
  int? chainStep,
  bool? isChainStep,
  Map<String, dynamic> specialFlags = const {},
}) {
  return ActiveQuest(
    id: 'quest_determinism_test',
    questPoolId: 'pool_determinism_test',
    questTypeId: questTypeId,
    difficulty: 1,
    region: 1,
    questName: '결정성 테스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.utc(2026, 5, 20, 1),
    endTime: DateTime.utc(2026, 5, 20, 1, 5),
    eliteId: eliteId,
    chainId: chainId,
    chainStep: chainStep,
    isChainStep: isChainStep,
    specialFlags: specialFlags,
  );
}

QuestPool _pool({Map<String, dynamic> specialFlags = const {}}) {
  return QuestPool(
    id: 'pool_determinism_test',
    name: '결정성 테스트 풀',
    type: 1,
    difficulty: 1,
    minRegionDiff: 0,
    maxRegionDiff: 0,
    typeId: 'raid',
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
  EnemyKind enemyKind = EnemyKind.normal,
  int hp = 40,
  int attack = 8,
  int defense = 4,
}) {
  return EnemyArchetype(
    id: id,
    name: id,
    enemyKind: enemyKind,
    role: role,
    tier: 1,
    baseStr: 8,
    baseInt: 2,
    baseVit: 8,
    baseAgi: 4,
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
    ],
    enemyArchetypes: enemies,
  );
}
