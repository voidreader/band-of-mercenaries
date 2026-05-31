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

  // ==========================================================================
  // M8.5 페이즈 4 #3 TASK-25b — 투지 +0.20 / 불굴 lv 보너스 clamp 순서 + 솔로 cap
  // ==========================================================================
  group('CombatSimulator 투지·불굴 사망 저항 cap', () {
    test('불굴 lv 보너스는 clamp 이전에 더해져 사망률을 낮춘다', () {
      // 동일 구성(솔로 의뢰 + cap 0.95)에서 불굴 lv만 다르게 둔다.
      //  - fortitude lv5 → death_resistance hook +0.10 (clamp 이전 가산).
      //  - fortitude lv0 → 보너스 없음.
      // base(T5 0.65)+warrior(0.10)+fortitude(0.10)=0.85 vs 0.75 차이가
      // clamp(min 0.20 / cap 0.95) 이전에 반영되어야 사망률이 낮아진다.
      final withFortitude = _measureSoloDeterminationDeath(
        deathCap: 0.95,
        fortitudeLevel: 5,
      );
      final withoutFortitude = _measureSoloDeterminationDeath(
        deathCap: 0.95,
        fortitudeLevel: 0,
      );

      expect(withFortitude.sampled, greaterThan(0));
      expect(withoutFortitude.sampled, greaterThan(0));
      expect(
        withFortitude.deathRate,
        lessThan(withoutFortitude.deathRate),
        reason: '불굴 lv5 보너스(+0.10)가 사망 저항에 반영되지 않음',
      );
    });

    test('투지 발동 + 솔로 cap 0.95에서도 사망 저항이 1.0을 넘지 않는다(cap 상한 유지)', () {
      // 솔로 의뢰(partySizeMax==1)에서 단독 용병은 투지 eligible이며,
      // HP<30% 도달 시 emotional_determination(+0.20)이 발동한다.
      // base(0.65)+warrior(0.10)+fortitude(0.10)+투지(0.20)=1.05 이지만
      // effectiveMax = max(0.95, 0.80) = 0.95로 clamp되어 사망 저항 ≤ 0.95이다.
      // 즉 cap 통과 후 별도 가산이 없으므로(무적 금지) 사망률 > 0이 유지되어야 한다.
      final result = _measureSoloDeterminationDeath(
        deathCap: 0.95,
        fortitudeLevel: 5,
      );

      expect(result.sampled, greaterThan(0));
      // 투지가 실제로 발동해야 cap 검증이 유효하다.
      expect(
        result.determinationApplied,
        isTrue,
        reason: '투지(emotional_determination) 미발동 — cap 검증 무의미',
      );
      // cap 0.95 → 저항 ≤ 0.95 → 사망률 > 0 (저항이 1.0이 되면 무적이므로 cap 위배).
      expect(
        result.deathRate,
        greaterThan(0.0),
        reason: '사망 저항이 cap 0.95를 넘어 1.0이 되었다(무적 — cap 위배)',
      );
      // 솔로 cap이 정상 작동하면 사망률은 합리적 범위(≤ 0.40) 내에 있다.
      expect(
        result.deathRate,
        lessThanOrEqualTo(0.40),
        reason: '솔로 cap 0.95 사망률이 비정상적으로 높음',
      );
    });
  });
}

/// 솔로 의뢰 + 투지 발동 구성에서 사망률·투지 발동 여부를 측정.
/// fortitudeLevel로 불굴 히든 스탯 lv를 주입한다.
({double deathRate, int sampled, bool determinationApplied})
    _measureSoloDeterminationDeath({
  required double? deathCap,
  required int fortitudeLevel,
}) {
  const mercId = 'merc_solo';
  var deathCount = 0;
  var sampled = 0;
  var determinationApplied = false;
  for (var seed = 1; seed <= _sampleSize; seed++) {
    final result = CombatSimulator.simulate(
      quest: _soloQuest(),
      partyMercs: [
        // T5 전사 + 불굴 lv + 약한 스탯(즉시 위기 → 투지 트리거).
        _soloMerc(
          id: mercId,
          str: 1,
          vit: 1,
          agi: 1,
          fortitudeLevel: fortitudeLevel,
        ),
      ],
      pool: _soloPool(),
      staticData: _soloStaticData(
        enemies: [_enemy(id: 'enemy_strong', attack: 80, hp: 400, agi: 50)],
        partyTier: 5,
      ),
      userData: _userData(),
      factionStates: const [],
      seed: seed,
      deathResistanceCaps: deathCap == null ? const {} : {mercId: deathCap},
    );
    if (result == null) continue;
    sampled++;
    if (result.deceasedMercIds.contains(mercId)) deathCount++;
    if (result.statusEffectHistory.any(
      (e) => e.effectId == 'emotional_determination' && e.eventType == 'apply',
    )) {
      determinationApplied = true;
    }
  }
  return (
    deathRate: sampled == 0 ? 0.0 : deathCount / sampled,
    sampled: sampled,
    determinationApplied: determinationApplied,
  );
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
    hiddenStats: const [],
    battleMemoryTemplates: const [],
  );
}

// ============================================================================
// 투지·불굴 cap 전용 헬퍼 (TASK-25b)
// ============================================================================

/// 솔로 의뢰 quest. 솔로 cap 검증은 pool.partySizeMax==1로 투지 eligible을 만든다.
ActiveQuest _soloQuest() {
  return ActiveQuest(
    id: 'quest_solo_determination_test',
    questPoolId: 'pool_solo_determination_test',
    questTypeId: 'raid',
    difficulty: 1,
    region: 1,
    questName: '솔로 투지 테스트',
    status: QuestStatus.inProgress,
    startTime: DateTime.utc(2026, 5, 21, 1),
    endTime: DateTime.utc(2026, 5, 21, 1, 5),
    specialFlags: const {},
  );
}

/// partySizeMax == 1 → 단독 용병이 투지(determination) eligible.
QuestPool _soloPool() {
  return QuestPool(
    id: 'pool_solo_determination_test',
    name: '솔로 투지 테스트 풀',
    type: 1,
    difficulty: 1,
    minRegionDiff: 0,
    maxRegionDiff: 0,
    typeId: 'raid',
    partySizeMin: 1,
    partySizeMax: 1,
    specialFlags: const {},
  );
}

/// 불굴 히든 스탯 lv(fortitude)를 주입한 mercenary.
Mercenary _soloMerc({
  String id = 'merc_solo',
  int str = 30,
  int intelligence = 10,
  int vit = 30,
  int agi = 20,
  int fortitudeLevel = 5,
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
    hiddenStats: {'fortitude': fortitudeLevel},
    recruitedAt: DateTime.utc(2026, 1, 1),
  );
}

/// emotional 4행(투지 포함)을 combatStatusEffects에 추가한 staticData.
StaticGameData _soloStaticData({
  required List<EnemyArchetype> enemies,
  int partyTier = 1,
}) {
  final base = _staticData(enemies: enemies, partyTier: partyTier);
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
    combatSkills: base.combatSkills,
    combatStatusEffects: [...base.combatStatusEffects, ..._soloEmotionalEffects],
    enemyArchetypes: enemies,
    hiddenStats: base.hiddenStats,
    battleMemoryTemplates: base.battleMemoryTemplates,
  );
}

const List<CombatStatusEffect> _soloEmotionalEffects = [
  CombatStatusEffect(
    id: 'emotional_rage',
    kind: 'emotional',
    displayLabel: '분노',
    defaultDurationTurns: 3,
    defaultIntensity: 0.30,
    stackPolicy: StackPolicy.ignore,
    hookTarget: ['attack'],
    applyMethod: ApplyMethod.none,
    description: '분노',
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
    description: '슬픔',
  ),
  CombatStatusEffect(
    id: 'emotional_despair',
    kind: 'emotional',
    displayLabel: '절망',
    defaultDurationTurns: 3,
    defaultIntensity: 0.20,
    stackPolicy: StackPolicy.ignore,
    hookTarget: ['hit'],
    applyMethod: ApplyMethod.none,
    description: '절망',
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
    description: '투지',
  ),
];
