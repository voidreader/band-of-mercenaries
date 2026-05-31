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

  // ==========================================================================
  // M8.5 페이즈 4 #3 TASK-25b — 감정 반응(emotional) 1명 1감정 + DoT 사망/중상
  // ==========================================================================
  group('CombatSimulator 감정 반응', () {
    test('한 용병은 같은 라운드에 분노/슬픔/절망/투지 중 1감정만 적용된다', () {
      // 동료 사망(분노 후보 전원) + 동료 중상(슬픔 후보) + 파티 HP<25%(절망 후보 전원)
      // + 체인 주인공 저HP(투지 후보)를 동시에 유발한다. priority flush가 1명 1감정만
      // 적용하므로 어떤 생존 용병도 emotional kind 상태를 2개 이상 보유하지 않아야 한다.
      final quest = _emotionalQuest(
        chainId: 'chain_test',
        protagonistMercId: 'merc_protagonist',
      );
      final pool = _pool();
      final party = [
        _emotionalMerc(
          id: 'merc_protagonist',
          str: 6,
          vit: 1,
          agi: 1,
          hiddenStats: const {'fortitude': 3},
        ),
        _emotionalMerc(id: 'merc_ally_a', str: 4, vit: 1, agi: 1),
        _emotionalMerc(id: 'merc_ally_b', str: 2, vit: 1, agi: 1),
      ];
      final staticData = _emotionalStaticData(
        enemies: [
          _enemy(id: 'enemy_brutal', hp: 50, attack: 9999),
          _enemy(id: 'enemy_brutal_2', hp: 50, attack: 9999),
        ],
      );

      var checkedAnyEmotion = false;
      for (var seed = 1; seed <= 60; seed++) {
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

        // mercId → 현재 보유 중인 emotional effectId 누적 추적.
        // apply 이벤트는 +1, end 이벤트는 -1(end_cause death 포함)으로 동시 보유 수를 계산.
        final active = <String, Set<String>>{};
        var sawApply = false;
        for (final e in result.statusEffectHistory) {
          if (!e.effectId.startsWith('emotional_')) continue;
          final tid = e.targetId;
          final set = active.putIfAbsent(tid, () => <String>{});
          if (e.eventType == 'apply') {
            sawApply = true;
            set.add(e.effectId);
            // 같은 시점에 동시 보유 emotional은 1개를 넘으면 안 된다.
            expect(
              set.length,
              lessThanOrEqualTo(1),
              reason: 'seed=$seed merc=$tid 동시 emotional ${set.toList()}',
            );
          } else if (e.eventType == 'end') {
            set.remove(e.effectId);
          }
        }
        if (sawApply) checkedAnyEmotion = true;
      }

      expect(checkedAnyEmotion, isTrue, reason: '어떤 seed에서도 emotional 미발동');
    });

    test('DoT 사망/중상도 _resolveDeath 결과로 감정 후보와 fortitude 카운터를 생성한다', () {
      // 적은 약한 일반 공격(2)만 하지만 매 라운드 강한 독(dot_poisoned)을 부여한다.
      // DoT tick 누적으로 파티원 HP가 0 이하가 되면 _resolveDeath를 거쳐
      // 사망(분노 후보) 또는 사망 저항 생존=중상(슬픔 후보 + fortitude_event_count +1)이
      // 발생한다. dot tick이 실제로 일어났고, 감정 발동과 fortitude 카운터가
      // 함께 생성되는지 검증한다.
      final quest = _emotionalQuest(
        chainId: 'chain_test',
        protagonistMercId: 'merc_protagonist',
      );
      final pool = _pool();
      final party = [
        _emotionalMerc(
          id: 'merc_protagonist',
          str: 3,
          vit: 1,
          agi: 1,
          hiddenStats: const {'fortitude': 3},
        ),
        _emotionalMerc(id: 'merc_ally_a', str: 2, vit: 1, agi: 1),
      ];
      // 약공격(2) + 매 라운드 dot_poisoned 부여 → DoT tick으로 점진 사망/중상.
      final staticData = _emotionalStaticData(
        enemies: [
          _enemy(
            id: 'enemy_venom',
            hp: 400,
            attack: 2,
            agi: 2,
          ).copyWith(skillIds: const ['skill_enemy_poison_bite']),
        ],
        withDot: true,
      );

      var sawDotTick = false;
      var sawFortitude = false;
      var sawEmotion = false;
      for (var seed = 1; seed <= 80; seed++) {
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

        final dotTicks = result.turns
            .expand((t) => t.actions)
            .where((a) => a.actionKind == 'dot_tick')
            .toList();
        if (dotTicks.isNotEmpty) sawDotTick = true;

        for (final counters in result.hiddenStatEvents.values) {
          if ((counters['fortitude_event_count'] ?? 0) > 0) {
            sawFortitude = true;
          }
        }
        final emotionApplied = result.statusEffectHistory.any(
          (e) =>
              e.effectId.startsWith('emotional_') && e.eventType == 'apply',
        );
        if (emotionApplied) sawEmotion = true;
        if (sawDotTick && sawFortitude && sawEmotion) break;
      }

      expect(sawDotTick, isTrue, reason: 'DoT tick 미발생');
      expect(
        sawFortitude,
        isTrue,
        reason: '사망 저항 생존(중상) → fortitude_event_count 미생성',
      );
      expect(sawEmotion, isTrue, reason: '사망/중상 → 감정 후보 미발동');
    });
  });
}

// ============================================================================
// 감정 반응(emotional) 전용 헬퍼 (TASK-25b)
// ============================================================================

ActiveQuest _emotionalQuest({
  required String chainId,
  required String protagonistMercId,
}) {
  return ActiveQuest(
    id: 'quest_emotional_test',
    questPoolId: 'pool_combat_test',
    questTypeId: 'raid',
    difficulty: 1,
    region: 1,
    questName: '감정 테스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.utc(2026, 5, 21, 1),
    endTime: DateTime.utc(2026, 5, 21, 1, 5),
    chainId: chainId,
    isChainStep: true,
    specialFlags: {'chain_protagonist_id': protagonistMercId},
  );
}

Mercenary _emotionalMerc({
  String id = 'merc_a',
  int str = 30,
  int intelligence = 10,
  int vit = 30,
  int agi = 20,
  List<String> traitIds = const [],
  Map<String, int> hiddenStats = const {},
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
    hiddenStats: hiddenStats,
    recruitedAt: DateTime.utc(2026, 1, 1),
  );
}

/// emotional 4행(분노/슬픔/절망/투지)을 포함하는 staticData.
/// withDot=true이면 독(dot) 상태 효과 + 적 DoT 스킬을 추가한다.
StaticGameData _emotionalStaticData({
  required List<EnemyArchetype> enemies,
  bool withDot = false,
}) {
  final base = _staticData(enemies: enemies);
  return StaticGameData(
    difficulties: base.difficulties,
    jobs: base.jobs,
    traits: base.traits,
    traitCategories: base.traitCategories,
    traitConflicts: base.traitConflicts,
    traitTransitions: base.traitTransitions,
    traitComboEvolutions: base.traitComboEvolutions,
    traitSynergies: base.traitSynergies,
    regions: base.regions,
    regionAdjacencies: base.regionAdjacencies,
    regionSectors: base.regionSectors,
    questTypes: base.questTypes,
    questPools: base.questPools,
    personNames: base.personNames,
    travelEvents: base.travelEvents,
    facilities: base.facilities,
    ranks: base.ranks,
    mercenaryWages: base.mercenaryWages,
    regionDiscoveries: base.regionDiscoveries,
    factions: base.factions,
    items: base.items,
    eliteMonsters: base.eliteMonsters,
    eliteLootEntries: base.eliteLootEntries,
    chainQuests: base.chainQuests,
    questNarratives: base.questNarratives,
    travelChoiceEvents: base.travelChoiceEvents,
    travelChoiceOptions: base.travelChoiceOptions,
    travelChoiceResults: base.travelChoiceResults,
    craftingRecipes: base.craftingRecipes,
    questPoolMaterialDrops: base.questPoolMaterialDrops,
    bandAchievementTemplates: base.bandAchievementTemplates,
    titles: base.titles,
    factionContacts: base.factionContacts,
    factionReactions: base.factionReactions,
    factionShopItems: base.factionShopItems,
    combatReportTemplates: base.combatReportTemplates,
    combatReportKeywords: base.combatReportKeywords,
    combatSkills: [
      ...base.combatSkills,
      if (withDot) _enemyPoisonSkill,
    ],
    combatStatusEffects: [
      ...base.combatStatusEffects,
      ..._emotionalEffects,
      if (withDot) _dotEffect,
    ],
    enemyArchetypes: enemies,
    hiddenStats: base.hiddenStats,
    battleMemoryTemplates: base.battleMemoryTemplates,
  );
}

// simulator는 effectId 'dot_poisoned'만 라운드 시작 tick으로 처리한다.
const CombatStatusEffect _dotEffect = CombatStatusEffect(
  id: 'dot_poisoned',
  kind: 'dot',
  displayLabel: '맹독',
  defaultDurationTurns: 6,
  defaultIntensity: 8.0,
  stackPolicy: StackPolicy.stack,
  hookTarget: ['hp'],
  applyMethod: ApplyMethod.absolute,
  description: '매 라운드 피해를 입힌다',
);

// 적이 매 라운드 dot_poisoned를 부여하는 스킬(_resolveEnemyAction이 인식하는 id).
const CombatSkill _enemyPoisonSkill = CombatSkill(
  id: 'skill_enemy_poison_bite',
  role: 'warrior',
  triggerKind: TriggerKind.active,
  actionCost: ActionCost.action,
  targetingKind: TargetingKind.singleEnemy,
  statusEffectId: 'dot_poisoned',
  statusEffectApplyChance: 1.0,
  statusEffectIntensity: 8.0,
  statusEffectDurationTurns: 6,
  cooldownRounds: 0,
  displayLabel: '독니',
  description: '독을 부여한다',
);

const List<CombatStatusEffect> _emotionalEffects = [
  CombatStatusEffect(
    id: 'emotional_rage',
    kind: 'emotional',
    displayLabel: '분노',
    defaultDurationTurns: 3,
    defaultIntensity: 0.30,
    stackPolicy: StackPolicy.ignore,
    hookTarget: ['attack', 'defense'],
    applyMethod: ApplyMethod.none,
    description: '동료의 죽음에 분노한다',
  ),
  CombatStatusEffect(
    id: 'emotional_sorrow',
    kind: 'emotional',
    displayLabel: '슬픔',
    defaultDurationTurns: 2,
    defaultIntensity: 0.50,
    stackPolicy: StackPolicy.ignore,
    hookTarget: ['action'],
    applyMethod: ApplyMethod.none,
    description: '동료의 부상에 위축된다',
  ),
  CombatStatusEffect(
    id: 'emotional_despair',
    kind: 'emotional',
    displayLabel: '절망',
    defaultDurationTurns: 3,
    defaultIntensity: 0.20,
    stackPolicy: StackPolicy.ignore,
    hookTarget: ['hit', 'evasion'],
    applyMethod: ApplyMethod.none,
    description: '전멸의 공포에 휩싸인다',
  ),
  CombatStatusEffect(
    id: 'emotional_determination',
    kind: 'emotional',
    displayLabel: '투지',
    defaultDurationTurns: 3,
    defaultIntensity: 0.20,
    stackPolicy: StackPolicy.ignore,
    hookTarget: ['death_resistance', 'evasion'],
    applyMethod: ApplyMethod.none,
    description: '위기 속에서 투지를 불태운다',
  ),
];

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
    hiddenStats: const [],
    battleMemoryTemplates: const [],
  );
}
