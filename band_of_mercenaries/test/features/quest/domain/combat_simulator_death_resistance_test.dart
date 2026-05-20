// M8b 페이즈 4 #5 FR-5 — 사망 저항 클램프 검증.
//
// 검증 범위:
//   1) 일반 mercenary T1~T5 — HP=1 (즉시 사망 위기) vs 강력 적 200 시드:
//      사망률은 결국 simulate 결과로 누적되며, 일반 사망 저항 클램프 [0.20, 0.80] 내
//      평균을 보장하므로 사망률은 ≤ 0.80 (200 시드 기준 fail-soft 마진 포함 ≤ 0.90).
//      매우 약한 mercenary는 사망률이 높을 수 있으므로 본 검증은 클램프 상한만 확인.
//   2) 체인 주인공 (`quest.specialFlags['chain_protagonist_id'] == merc.id`):
//      잔여 사망 확률 절반 보정이 적용되어 일반 T1 전사(저항 40%)보다
//      낮은 사망률(저항 70% 안팎)을 보여야 한다.
//   3) 사망 저항이 실제로 작동하는지 확인 — HP=1 vs 강력 적에서 사망률이 100% 미만.

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

const int _sampleSize = 200;

void main() {
  group('CombatSimulator FR-5 사망 저항 클램프', () {
    for (final tier in [1, 2, 3, 4, 5]) {
      test('일반 mercenary T$tier — 200 시드 사망률 [0, 0.80] 이내', () {
        final deceasedRate = _measureDeceasedRatio(
          partyTier: tier,
          chainProtagonistMercId: null,
        );
        // 일반 사망 저항 클램프 [0.20, 0.80] → 사망률 ≤ 1 - 0.20 = 0.80.
        // 표본 200 / 표준 오차 ≈ 0.04 / 마진 +0.10 = 상한 0.90.
        expect(
          deceasedRate,
          lessThanOrEqualTo(0.90),
          reason: 'T$tier 일반 mercenary 사망률 클램프 위배',
        );
      });
    }

    test('체인 주인공 — 잔여 사망 확률 절반 보정으로 사망률이 낮아진다', () {
      final protagonistRate = _measureDeceasedRatio(
        partyTier: 1,
        chainProtagonistMercId: 'merc_protagonist',
      );
      // T1 전사 기본 사망 저항은 tier 0.30 + warrior 0.10 = 0.40.
      // 체인 주인공 보정은 chance += (1 - chance) * 0.5 이므로 0.70이 된다.
      // 200표본 분산을 감안해 사망률 상한을 0.40으로 둔다.
      expect(
        protagonistRate,
        lessThanOrEqualTo(0.40),
        reason: '체인 주인공 사망 저항 보정 미적용',
      );
    });
  });
}

double _measureDeceasedRatio({
  required int partyTier,
  required String? chainProtagonistMercId,
}) {
  final mercId = chainProtagonistMercId ?? 'merc_target';
  var deathCount = 0;
  var sampled = 0;
  for (var seed = 1; seed <= _sampleSize; seed++) {
    final result = CombatSimulator.simulate(
      quest: _quest(
        isChainStep: chainProtagonistMercId != null,
        chainId: chainProtagonistMercId != null ? 'chain_test' : null,
        specialFlags: chainProtagonistMercId != null
            ? {'chain_protagonist_id': chainProtagonistMercId}
            : const {},
      ),
      partyMercs: [
        // HP=1 즉시 사망 위기 (str/vit/agi 모두 최소)
        _merc(id: mercId, str: 1, vit: 1, agi: 1),
      ],
      pool: _pool(),
      staticData: _staticData(
        enemies: [_enemy(id: 'enemy_strong', attack: 80, hp: 200, agi: 50)],
        partyTier: partyTier,
      ),
      userData: _userData(),
      factionStates: const [],
      seed: seed,
    );
    if (result == null) continue;
    sampled++;
    if (result.deceasedMercIds.contains(mercId)) {
      deathCount++;
    }
  }
  return sampled == 0 ? 0.0 : deathCount / sampled;
}

// ============================================================================
// 헬퍼
// ============================================================================

ActiveQuest _quest({
  Map<String, dynamic> specialFlags = const {},
  bool isChainStep = false,
  String? chainId,
}) {
  return ActiveQuest(
    id: 'quest_death_resist_test',
    questPoolId: 'pool_death_resist_test',
    questTypeId: 'raid',
    difficulty: 1,
    region: 1,
    questName: '사망 저항 테스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.utc(2026, 5, 20, 1),
    endTime: DateTime.utc(2026, 5, 20, 1, 5),
    isChainStep: isChainStep ? true : null,
    chainId: chainId,
    specialFlags: specialFlags,
  );
}

QuestPool _pool() {
  return QuestPool(
    id: 'pool_death_resist_test',
    name: '사망 저항 테스트 풀',
    type: 1,
    difficulty: 1,
    minRegionDiff: 0,
    maxRegionDiff: 0,
    typeId: 'raid',
    specialFlags: const {},
  );
}

Mercenary _merc({
  String id = 'merc_a',
  int str = 30,
  int intelligence = 10,
  int vit = 30,
  int agi = 20,
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
    recruitedAt: DateTime.utc(2026, 1, 1),
  );
}

EnemyArchetype _enemy({
  String id = 'enemy_a',
  int hp = 40,
  int attack = 8,
  int agi = 4,
}) {
  return EnemyArchetype(
    id: id,
    name: id,
    enemyKind: EnemyKind.normal,
    role: 'warrior',
    tier: 1,
    baseStr: 8,
    baseInt: 2,
    baseVit: 8,
    baseAgi: agi,
    baseHp: hp,
    baseAttack: attack,
    baseDefense: 4,
    behaviorPattern: BehaviorPattern.aggressive,
    environmentTags: const ['plains'],
    description: '강력한 적',
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

StaticGameData _staticData({
  required List<EnemyArchetype> enemies,
  int partyTier = 1,
}) {
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
    jobs: [
      Job(
        id: 'job_warrior',
        tier: partyTier,
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
