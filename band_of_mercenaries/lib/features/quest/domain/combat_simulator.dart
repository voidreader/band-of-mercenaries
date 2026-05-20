// M8b 페이즈 4 #1 — CombatSimulator 순수 도메인 서비스.
//
// 4 페이즈(사전·선제·일반 라운드·마무리) 결정적 시뮬레이션을 1회 수행하여
// `QuestResult`·라운드 로그·결정적 장면 기여자를 산출한다.
// 순수 함수(ref/Hive/Provider 미접근). PRNG는 도메인 키별 매 액션 새 인스턴스.
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:band_of_mercenaries/core/models/combat_enums.dart';
import 'package:band_of_mercenaries/core/models/combat_report_keyword.dart';
import 'package:band_of_mercenaries/core/models/combat_skill.dart';
import 'package:band_of_mercenaries/core/models/combat_status_effect.dart';
import 'package:band_of_mercenaries/core/models/enemy_archetype.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/util/stable_seed.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_action.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulator_constants.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/combatant_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/enemy_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';

/// M8b 페이즈 4 #1: 전투 시뮬레이터.
///
/// `combatSimulationEligible` 의뢰 완료 시 1회 호출. 입력 스냅샷을 동결한 결정적
/// 시뮬레이션을 4 페이즈로 수행하여 `CombatSimulationResult`를 반환한다.
/// 예외/필수 데이터 부재 시 null. 호출 측은 null → `QuestCalculator` 폴백.
class CombatSimulator {
  CombatSimulator._();

  static const int _maxRounds = 8;

  static CombatSimulationResult? simulate({
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    QuestPool? pool,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    RegionState? regionState,
    Map<String, EquipmentStatBonus> partyEquipmentBonuses = const {},
    int? seed,
  }) {
    try {
      // FR-20 + §4.3: 엣지 케이스 가드.
      if (partyMercs.isEmpty) return null;
      if (quest.startTime == null) return null;
      if (staticData.combatSkills.isEmpty ||
          staticData.combatStatusEffects.isEmpty ||
          staticData.enemyArchetypes.isEmpty) {
        return null;
      }

      // FR-6 §1: 시드 결정.
      final effectiveSeed =
          seed ??
          stableSeed32(
            '${quest.startTime!.toUtc().microsecondsSinceEpoch}|${quest.id}',
          );

      final phase1 = _runPhase1(
        seed: effectiveSeed,
        quest: quest,
        partyMercs: partyMercs,
        pool: pool,
        staticData: staticData,
        userData: userData,
        factionStates: factionStates,
        regionState: regionState,
        partyEquipmentBonuses: partyEquipmentBonuses,
      );
      if (phase1 == null) return null;

      final phase2 = _runPhase2(phase1);
      final phase3 = _runPhase3(phase2);
      return _runPhase4(phase3);
    } catch (e, st) {
      debugPrint('[BOM][CombatSimulator] simulate failed: $e\n$st');
      return null;
    }
  }

  // ==========================================================================
  // Phase 1 (사전 단계) — FR-6, FR-7, FR-13, FR-13.5
  // ==========================================================================

  static _Phase1State? _runPhase1({
    required int seed,
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    QuestPool? pool,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    RegionState? regionState,
    required Map<String, EquipmentStatBonus> partyEquipmentBonuses,
  }) {
    // FR-6 §3 + §6: 파티 스냅샷 동결 + 진형 배치.
    final partySnapshots = <CombatantSnapshot>[];
    for (final merc in partyMercs) {
      final job = staticData.jobs.where((j) => j.id == merc.jobId).firstOrNull;
      final role = job?.role ?? 'specialist';
      final bonus = partyEquipmentBonuses[merc.id] ?? EquipmentStatBonus.zero;
      final tier = job?.tier ?? 1;
      partySnapshots.add(
        CombatantSnapshot(
          mercId: merc.id,
          name: merc.name,
          jobId: merc.jobId,
          tier: tier,
          level: merc.level,
          effectiveStr: merc.effectiveStrWith(bonus),
          effectiveInt: merc.effectiveIntelligenceWith(bonus),
          effectiveVit: merc.effectiveVitWith(bonus),
          effectiveAgi: merc.effectiveAgiWith(bonus),
          titleIds: List<String>.from(merc.titleIds),
          traitIds: List<String>.from(merc.allTraitIds),
          equippedItemIds: const [],
          role: role,
          positionRow: _resolvePositionRow(role),
          positionIndex: 0,
        ),
      );
    }
    _assignFormationIndicesParty(partySnapshots);

    // FR-6 §7: 환경 태그 산출.
    final region = staticData.regions
        .where((r) => r.region == quest.region)
        .firstOrNull;
    final envTags = region?.environmentTags ?? const <String>[];

    // FR-7: 적 그룹 구성.
    final enemies = _buildEnemyGroup(
      seed: seed,
      quest: quest,
      pool: pool,
      staticData: staticData,
      envTags: envTags,
    );
    if (enemies == null || enemies.isEmpty) return null;
    _assignFormationIndicesEnemy(enemies);

    final mercByMercId = {for (final m in partyMercs) m.id: m};

    final partyState = partySnapshots
        .map((s) => _Combatant.fromMerc(s, mercByMercId[s.mercId]))
        .toList(growable: false);
    final enemyState = enemies
        .map(_Combatant.fromEnemy)
        .toList(growable: false);

    // FR-6 §5: 사기 계산 — 기본 + 트레잇/직업군 패시브 ±20.
    final partyMorale = _computeMorale(partyState);
    final enemyMorale = _computeMorale(enemyState);

    // FR-13.5: 환경 자동 부여 — mist_field → 적군 전원 debuff_accuracy_down.
    final statusEffects = staticData.combatStatusEffects;
    final statusEffectById = {for (final e in statusEffects) e.id: e};
    final history = <StatusEffectEvent>[];

    if (envTags.contains('mist_field')) {
      final effect = statusEffectById['debuff_accuracy_down'];
      if (effect != null) {
        for (final enemy in enemyState) {
          _applyStatusEffect(
            target: enemy,
            caster: null,
            effect: effect,
            intensity: 0.10,
            duration: 2,
            roundIndex: 0,
            applyChance: 1.0,
            applyRng: null,
            history: history,
          );
        }
      }
    }

    // FR-13: 트레잇 자동 부여 — vigilant → buff_evasion_up, huntsman → buff_accuracy_up.
    for (final c in [...partyState, ...enemyState]) {
      final traits = c.traitIds;
      if (traits.any((t) => t.contains('vigilant'))) {
        final eff = statusEffectById['buff_evasion_up'];
        if (eff != null) {
          _applyStatusEffect(
            target: c,
            caster: c,
            effect: eff,
            intensity: 0.10,
            duration: 1,
            roundIndex: 0,
            applyChance: 1.0,
            applyRng: null,
            history: history,
          );
        }
      }
      if (traits.any((t) => t.contains('huntsman'))) {
        final eff = statusEffectById['buff_accuracy_up'];
        if (eff != null) {
          _applyStatusEffect(
            target: c,
            caster: c,
            effect: eff,
            intensity: 0.05,
            duration: 1,
            roundIndex: 0,
            applyChance: 1.0,
            applyRng: null,
            history: history,
          );
        }
      }
    }

    // FR-6 §9 + FR-6 §10: 선제 점수 산출 + 매복 보너스.
    final partyScore = _sideInitiativeScore(partyState, envTags);
    final enemyScoreBase = _sideInitiativeScore(enemyState, envTags);
    final ambushSide = pool?.specialFlags['ambush_side'];
    var partyScoreFinal = partyScore;
    var enemyScoreFinal = enemyScoreBase;
    if (ambushSide == 'enemy') {
      enemyScoreFinal += CombatSimulatorConstants.ambushBonus;
    } else if (ambushSide == 'party') {
      partyScoreFinal += CombatSimulatorConstants.ambushBonus;
    }

    // FR-6 §11: |delta| >= 15 → 우세 측이 Phase 2 진입.
    final delta = partyScoreFinal - enemyScoreFinal;
    final initiativeSide =
        delta.abs() >= CombatSimulatorConstants.initiativeDeltaThreshold
        ? (delta >= 0 ? _Side.party : _Side.enemy)
        : null;

    final staticById = _StaticIndex.build(staticData);

    return _Phase1State(
      seed: seed,
      quest: quest,
      pool: pool,
      partyState: partyState,
      enemyState: enemyState,
      envTags: envTags,
      partyMorale: partyMorale,
      enemyMorale: enemyMorale,
      initiativeSide: initiativeSide,
      history: history,
      staticIndex: staticById,
      turns: <CombatTurn>[],
      decisiveScores: {},
      damageDealt: {},
      killedEnemyCount: 0,
      combatantSnapshots: List<CombatantSnapshot>.from(partySnapshots),
      enemySnapshots: List<EnemySnapshot>.from(enemies),
    );
  }

  // ==========================================================================
  // Phase 2 (선제 라운드) — FR-8
  // ==========================================================================

  static _Phase1State _runPhase2(_Phase1State state) {
    if (state.initiativeSide == null) return state;
    final actors = state.initiativeSide == _Side.party
        ? state.partyState
        : state.enemyState;
    final defenders = state.initiativeSide == _Side.party
        ? state.enemyState
        : state.partyState;

    final actions = <CombatAction>[];
    for (final actor in actors) {
      if (!actor.alive) continue;
      _executeActorTurn(
        state: state,
        actor: actor,
        allies: actors,
        targets: defenders,
        roundIndex: 0,
        actions: actions,
        phase: 'initiative',
      );
      if (_partyWiped(state) || _enemyWiped(state)) break;
    }
    final turn = CombatTurn(
      roundIndex: 0,
      phase: 'initiative',
      actions: actions,
      exitConditionsTriggered: const [],
      hpRemainingByCombatant: _snapshotHp(state),
    );
    state.turns.add(turn);
    return state;
  }

  // ==========================================================================
  // Phase 3 (일반 라운드 반복, 최대 8) — FR-9
  // ==========================================================================

  static _Phase1State _runPhase3(_Phase1State state) {
    CombatExitCondition? exitCondition;
    var lastRoundIndex = 0;
    for (var r = 1; r <= _maxRounds; r++) {
      lastRoundIndex = r;
      final triggered = <String>[];
      final actions = <CombatAction>[];

      // FR-9 §1: 라운드 시작 DoT poisoned 일괄 적용.
      _applyDotRoundStart(state, r, actions);

      // FR-9 §2: 종료 조건 (a)/(b) 즉시 평가.
      exitCondition = _checkPostDotExit(state);
      if (exitCondition != null) {
        triggered.add(exitCondition.name);
        state.turns.add(
          CombatTurn(
            roundIndex: r,
            phase: 'general',
            actions: actions,
            exitConditionsTriggered: triggered,
            hpRemainingByCombatant: _snapshotHp(state),
          ),
        );
        break;
      }

      // FR-9 §3: actionScore 일괄 정렬.
      final order = _orderByActionScore(state, r);

      // FR-9 §4: 행동 실행.
      for (final actor in order) {
        if (!actor.alive) continue;

        // 트레잇 패시브 추가 행동(라운드 시작 큐) — 자기 행동 직전 1회.
        final extra = state.extraActionRoundStart[actor.id] ?? 0;
        if (extra > 0 && !actor.hasMezStunned) {
          state.extraActionRoundStart[actor.id] = 0;
          _executeActorTurn(
            state: state,
            actor: actor,
            allies: _alliesOf(state, actor),
            targets: _enemiesOf(state, actor),
            roundIndex: r,
            actions: actions,
            phase: 'general',
            isExtra: true,
            actionKindOverride: 'extra_action',
          );
          if (_partyWiped(state) || _enemyWiped(state)) break;
        }

        // 본 행동.
        _executeActorTurn(
          state: state,
          actor: actor,
          allies: _alliesOf(state, actor),
          targets: _enemiesOf(state, actor),
          roundIndex: r,
          actions: actions,
          phase: 'general',
        );
        if (_partyWiped(state) || _enemyWiped(state)) break;
      }

      // FR-9 §5: 라운드 종료 DoT bleeding + duration tick + 종료 조건.
      _applyDotRoundEnd(state, r, actions);
      _tickStatusEffects(state, r);

      exitCondition = _evaluateExitConditions(state, r);
      if (exitCondition != null) {
        triggered.add(exitCondition.name);
      }

      // 다음 라운드 추가 행동 큐 이관.
      _migrateNextRoundQueue(state);

      state.turns.add(
        CombatTurn(
          roundIndex: r,
          phase: 'general',
          actions: actions,
          exitConditionsTriggered: triggered,
          hpRemainingByCombatant: _snapshotHp(state),
        ),
      );
      if (exitCondition != null) break;
    }

    // 8 라운드 도달 + 양측 생존: (d) round_limit.
    state.exitCondition = exitCondition ?? CombatExitCondition.dRoundLimit;
    state.lastRoundIndex = lastRoundIndex;
    return state;
  }

  // ==========================================================================
  // Phase 4 (마무리 판정) — FR-10
  // ==========================================================================

  static CombatSimulationResult _runPhase4(_Phase1State state) {
    final enemyHpMax = state.enemyState.fold<int>(0, (s, e) => s + e.maxHp);
    final enemyHpRem = state.enemyState.fold<int>(
      0,
      (s, e) => s + (e.hp > 0 ? e.hp : 0),
    );
    final partyHpMax = state.partyState.fold<int>(0, (s, e) => s + e.maxHp);
    final partyHpRem = state.partyState.fold<int>(
      0,
      (s, e) => s + (e.hp > 0 ? e.hp : 0),
    );

    // FR-10.2: objectiveProgress 산출.
    final objectiveProgress = _computeObjectiveProgress(
      state: state,
      enemyHpMax: enemyHpMax,
      enemyHpRem: enemyHpRem,
    );

    // FR-10 §1: QuestResult 매핑.
    final questResult = _mapToQuestResult(
      exit: state.exitCondition,
      enemySurvivalRatio: enemyHpMax > 0 ? enemyHpRem / enemyHpMax : 0.0,
      partySurvivalRatio: partyHpMax > 0 ? partyHpRem / partyHpMax : 0.0,
      injuredCount: state.partyState.where((c) => c.injured).length,
      objectiveProgress: objectiveProgress,
    );

    // FR-10 §2: protagonist + featured.
    final partyByScoreDesc = state.partyState.toList()
      ..sort((a, b) {
        final sa = state.decisiveScores[a.id] ?? 0;
        final sb = state.decisiveScores[b.id] ?? 0;
        if (sb != sa) return sb.compareTo(sa);
        final da = state.damageDealt[a.id] ?? 0;
        final db = state.damageDealt[b.id] ?? 0;
        if (db != da) return db.compareTo(da);
        final ra = a.recruitedAt ?? DateTime(2000);
        final rb = b.recruitedAt ?? DateTime(2000);
        if (ra.compareTo(rb) != 0) return ra.compareTo(rb);
        return a.id.compareTo(b.id);
      });

    String? protagonistMercId;
    final featured = <String>[];
    for (final c in partyByScoreDesc) {
      final score = state.decisiveScores[c.id] ?? 0;
      if (score <= 0) continue;
      if (protagonistMercId == null) {
        protagonistMercId = c.id;
      } else if (featured.length < 2) {
        featured.add(c.id);
      } else {
        break;
      }
    }

    // FR-10 §3: 부상/사망 마킹 확정.
    final injured = state.partyState
        .where((c) => c.injured && !c.deceased)
        .map((c) => c.id)
        .toList();
    final deceased = state.partyState
        .where((c) => c.deceased)
        .map((c) => c.id)
        .toList();

    // FR-10 §4: toneTags 산출.
    final toneTags = _computeToneTags(state: state, questResult: questResult);

    return CombatSimulationResult(
      questResult: questResult,
      turns: state.turns,
      protagonistMercId: protagonistMercId,
      featuredMercIds: featured,
      injuredMercIds: injured,
      deceasedMercIds: deceased,
      objectiveProgress: objectiveProgress.clamp(0.0, 1.0),
      exitCondition: state.exitCondition,
      statusEffectHistory: state.history,
      seed: state.seed,
      toneTags: toneTags,
      combatantSnapshots: state.combatantSnapshots,
      enemySnapshots: state.enemySnapshots,
    );
  }

  // ==========================================================================
  // 행동 실행 — FR-11 시퀀스 + FR-14/FR-15 결정 트리 + FR-16 표적
  // ==========================================================================

  static void _executeActorTurn({
    required _Phase1State state,
    required _Combatant actor,
    required List<_Combatant> allies,
    required List<_Combatant> targets,
    required int roundIndex,
    required List<CombatAction> actions,
    required String phase,
    bool isExtra = false,
    String? actionKindOverride,
  }) {
    if (!actor.alive) return;

    if (actor.hasMezStunned) {
      actions.add(
        CombatAction(
          actorId: actor.id,
          targetIds: const [],
          actionKind: 'skipped_stunned',
          behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
          position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
        ),
      );
      return;
    }

    // FR-14 / FR-15: 스킬 자동 선택.
    final selectedSkillId = actor.isEnemy
        ? _selectEnemySkill(actor, state, roundIndex, allies, targets)
        : _selectPartySkill(actor, state, roundIndex, allies, targets);

    final skill = selectedSkillId == null
        ? null
        : state.staticIndex.skills[selectedSkillId];

    // FR-16: 표적 결정.
    final targetGroup = _selectTargets(
      actor: actor,
      skill: skill,
      allies: allies,
      enemies: targets,
      state: state,
    );

    final pairIdSuffix = targetGroup.isNotEmpty
        ? stableSeed32('${actor.id}|${targetGroup.first.id}')
        : 0;

    // 광역/연속 처리. extra_action 큐(반격)는 회피 통과 후 큐로 적재.
    final actionKind =
        actionKindOverride ?? (skill != null ? 'skill' : 'basic_attack');

    if (skill != null && skill.targetingKind == TargetingKind.self) {
      // self 버프/dispel 등.
      _applyNonAttackSkill(
        state: state,
        actor: actor,
        skill: skill,
        roundIndex: roundIndex,
        actions: actions,
        phase: phase,
      );
      _registerCooldown(state, actor, skill);
      return;
    }
    if (skill != null && skill.targetingKind == TargetingKind.singleAlly) {
      final ally = targetGroup.isNotEmpty ? targetGroup.first : actor;
      _applyAllySkill(
        state: state,
        actor: actor,
        target: ally,
        skill: skill,
        roundIndex: roundIndex,
        actions: actions,
        phase: phase,
      );
      _registerCooldown(state, actor, skill);
      return;
    }
    if (skill != null && skill.targetingKind == TargetingKind.aoeAlly) {
      for (final ally in allies.where((c) => c.alive)) {
        _applyAllySkill(
          state: state,
          actor: actor,
          target: ally,
          skill: skill,
          roundIndex: roundIndex,
          actions: actions,
          phase: phase,
        );
      }
      _registerCooldown(state, actor, skill);
      return;
    }
    if (skill != null && skill.dispelKind != null) {
      _applyDispelSkill(
        state: state,
        actor: actor,
        skill: skill,
        roundIndex: roundIndex,
        actions: actions,
        phase: phase,
        candidates:
            (skill.targetingKind == TargetingKind.aoeAlly ||
                skill.targetingKind == TargetingKind.party)
            ? allies
            : targets,
      );
      _registerCooldown(state, actor, skill);
      return;
    }

    // 공격 액션: 광역/단일.
    final attackTargets = targetGroup.isEmpty
        ? const <_Combatant>[]
        : targetGroup;
    if (attackTargets.isEmpty) {
      actions.add(
        CombatAction(
          actorId: actor.id,
          targetIds: const [],
          actionKind: actionKind,
          skillId: skill?.id,
          behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
          position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
        ),
      );
      return;
    }

    final multiHit = skill?.multiHitCount ?? 1;
    for (var hit = 0; hit < multiHit; hit++) {
      for (final defender in attackTargets) {
        if (!defender.alive) continue;
        final action = _resolveAction(
          state: state,
          actor: actor,
          defender: defender,
          skill: skill,
          actionKind: actionKind,
          roundIndex: roundIndex,
          pairIdSuffix: pairIdSuffix == 0
              ? stableSeed32('${actor.id}|${defender.id}')
              : stableSeed32('${actor.id}|${defender.id}|$hit'),
          phase: phase,
        );
        actions.add(action);
        // 반격(회피 성공 후) — 즉시 1회 추가 행동, 반격에서 반격 금지.
        if (action.isEvaded && !isExtra) {
          final ripChance = _evaluateRiposteChance(defender);
          final ripRng = Random(
            state.seed ^
                stableSeed32(
                  '${CombatSimulatorConstants.seedKeyRip}|$roundIndex|${stableSeed32('${actor.id}|${defender.id}')}',
                ),
          );
          if (ripRng.nextDouble() < ripChance) {
            final riposte = _resolveAction(
              state: state,
              actor: defender,
              defender: actor,
              skill: null,
              actionKind: 'riposte',
              roundIndex: roundIndex,
              pairIdSuffix: stableSeed32('${defender.id}|${actor.id}|rip'),
              phase: phase,
              isRiposte: true,
            );
            actions.add(riposte);
            _accumulateDecisive(state, defender, 'riposte');
          }
        }
      }
    }

    // 스킬 부가 상태 효과(공격 스킬).
    if (skill != null && skill.statusEffectId != null) {
      final effect = state.staticIndex.statusEffects[skill.statusEffectId];
      if (effect != null) {
        final applyRng = Random(
          state.seed ^
              stableSeed32(
                '${CombatSimulatorConstants.seedKeyApply}|$roundIndex|${actor.id}|${skill.id}|${skill.statusEffectId}',
              ),
        );
        for (final defender in attackTargets) {
          if (!defender.alive) continue;
          _applyStatusEffect(
            target: defender,
            caster: actor,
            effect: effect,
            intensity: skill.statusEffectIntensity ?? effect.defaultIntensity,
            duration:
                skill.statusEffectDurationTurns ?? effect.defaultDurationTurns,
            roundIndex: roundIndex,
            applyChance: skill.statusEffectApplyChance ?? 1.0,
            applyRng: applyRng,
            history: state.history,
          );
        }
      }
    }

    if (skill != null) {
      _registerCooldown(state, actor, skill);
    }
  }

  static CombatAction _resolveAction({
    required _Phase1State state,
    required _Combatant actor,
    required _Combatant defender,
    CombatSkill? skill,
    required String actionKind,
    required int roundIndex,
    required int pairIdSuffix,
    required String phase,
    bool isRiposte = false,
  }) {
    // FR-11 §2: 명중.
    final hitChance = _evaluateHitChance(actor, defender, state.envTags);
    final hitRng = Random(
      state.seed ^
          stableSeed32(
            '${CombatSimulatorConstants.seedKeyHit}|$roundIndex|$pairIdSuffix',
          ),
    );
    final isHit = hitRng.nextDouble() < hitChance;
    if (!isHit) {
      return CombatAction(
        actorId: actor.id,
        targetIds: [defender.id],
        actionKind: actionKind,
        skillId: skill?.id,
        statusEffectId: skill?.statusEffectId,
        behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
        position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
        damage: 0,
        isHit: false,
      );
    }

    // FR-11 §3: 회피.
    final evaChance = _evaluateEvasionChance(actor, defender, state.envTags);
    final evaRng = Random(
      state.seed ^
          stableSeed32(
            '${CombatSimulatorConstants.seedKeyEva}|$roundIndex|$pairIdSuffix',
          ),
    );
    final isEvaded = evaRng.nextDouble() < evaChance;
    if (isEvaded) {
      return CombatAction(
        actorId: actor.id,
        targetIds: [defender.id],
        actionKind: actionKind,
        skillId: skill?.id,
        statusEffectId: skill?.statusEffectId,
        behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
        position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
        damage: 0,
        isHit: true,
        isEvaded: true,
      );
    }

    // FR-11 §5: 방패 막기.
    final shieldChance = _evaluateShieldChance(defender, state);
    final shdRng = Random(
      state.seed ^
          stableSeed32(
            '${CombatSimulatorConstants.seedKeyShd}|$roundIndex|$pairIdSuffix',
          ),
    );
    final isShielded = shdRng.nextDouble() < shieldChance;
    final shieldMitigation = isShielded
        ? (_passiveShieldBonus(defender, state) + _traitShieldBonus(defender))
              .clamp(0.0, CombatSimulatorConstants.shieldMitigationMax)
        : 0.0;

    // FR-11 §6: 치명타.
    final critChance = _evaluateCritChance(actor, defender, skill, state);
    final critRng = Random(
      state.seed ^
          stableSeed32(
            '${CombatSimulatorConstants.seedKeyCrit}|$roundIndex|$pairIdSuffix',
          ),
    );
    final isCrit = critRng.nextDouble() < critChance;
    final critMul = isCrit
        ? (CombatSimulatorConstants.critMultiplier[actor.role] ?? 1.5)
        : 1.0;

    // FR-11 §7: 피해.
    final baseAttack = _computeBaseAttack(actor);
    final defense = _computeDefense(defender);
    final dmgRng = Random(
      state.seed ^
          stableSeed32(
            '${CombatSimulatorConstants.seedKeyDmg}|$roundIndex|$pairIdSuffix',
          ),
    );
    final noiseRange = (baseAttack * CombatSimulatorConstants.damageNoiseFactor)
        .floor()
        .clamp(
          CombatSimulatorConstants.damageNoiseMin,
          CombatSimulatorConstants.damageNoiseMax,
        );
    final noise = dmgRng.nextInt(noiseRange * 2 + 1) - noiseRange;
    final skillDmgMul = skill?.skillDamageMultiplier ?? 1.0;
    final raw =
        (baseAttack - defense).clamp(1, 999999).toDouble() *
            critMul *
            (1.0 - shieldMitigation) *
            skillDmgMul +
        noise;
    final damage = raw.round().clamp(1, 99999);

    final preHp = defender.hp;
    defender.hp -= damage;
    state.damageDealt[actor.id] = (state.damageDealt[actor.id] ?? 0) + damage;

    var isKill = false;
    if (defender.hp <= 0 && preHp > 0) {
      final died = _resolveDeath(
        state,
        defender,
        defender.isChainProtagonist(state),
      );
      isKill = died;
      if (defender.isEnemy && died) {
        state.killedEnemyCount += 1;
      }
    }

    if (!actor.isEnemy) {
      if (isKill) {
        _accumulateDecisive(state, actor, isCrit ? 'criticalKill' : 'kill');
      } else if (isCrit) {
        _accumulateDecisive(state, actor, 'crit');
      }
    }
    if (!defender.isEnemy && isShielded) {
      _accumulateDecisive(state, defender, 'shieldBlock');
    }

    return CombatAction(
      actorId: actor.id,
      targetIds: [defender.id],
      actionKind: actionKind,
      skillId: skill?.id,
      statusEffectId: skill?.statusEffectId,
      behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
      decisiveKeywordKey: isCrit ? 'crit' : (isKill ? 'kill' : null),
      position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
      damage: damage,
      isCrit: isCrit,
      isHit: true,
      isEvaded: false,
      isShielded: isShielded,
      isKill: isKill,
      shieldMitigation: shieldMitigation,
    );
  }

  static void _applyNonAttackSkill({
    required _Phase1State state,
    required _Combatant actor,
    required CombatSkill skill,
    required int roundIndex,
    required List<CombatAction> actions,
    required String phase,
  }) {
    if (skill.statusEffectId != null) {
      final effect = state.staticIndex.statusEffects[skill.statusEffectId];
      if (effect != null) {
        final applyRng = Random(
          state.seed ^
              stableSeed32(
                '${CombatSimulatorConstants.seedKeyApply}|$roundIndex|${actor.id}|${actor.id}|${skill.statusEffectId}',
              ),
        );
        _applyStatusEffect(
          target: actor,
          caster: actor,
          effect: effect,
          intensity: skill.statusEffectIntensity ?? effect.defaultIntensity,
          duration:
              skill.statusEffectDurationTurns ?? effect.defaultDurationTurns,
          roundIndex: roundIndex,
          applyChance: skill.statusEffectApplyChance ?? 1.0,
          applyRng: applyRng,
          history: state.history,
        );
      }
    }
    actions.add(
      CombatAction(
        actorId: actor.id,
        targetIds: [actor.id],
        actionKind: 'skill',
        skillId: skill.id,
        statusEffectId: skill.statusEffectId,
        behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
        position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
      ),
    );
  }

  static void _applyAllySkill({
    required _Phase1State state,
    required _Combatant actor,
    required _Combatant target,
    required CombatSkill skill,
    required int roundIndex,
    required List<CombatAction> actions,
    required String phase,
  }) {
    if (skill.statusEffectId != null) {
      final effect = state.staticIndex.statusEffects[skill.statusEffectId];
      if (effect != null) {
        final applyRng = Random(
          state.seed ^
              stableSeed32(
                '${CombatSimulatorConstants.seedKeyApply}|$roundIndex|${actor.id}|${target.id}|${skill.statusEffectId}',
              ),
        );
        _applyStatusEffect(
          target: target,
          caster: actor,
          effect: effect,
          intensity: skill.statusEffectIntensity ?? effect.defaultIntensity,
          duration:
              skill.statusEffectDurationTurns ?? effect.defaultDurationTurns,
          roundIndex: roundIndex,
          applyChance: skill.statusEffectApplyChance ?? 1.0,
          applyRng: applyRng,
          history: state.history,
        );
      }
    }
    actions.add(
      CombatAction(
        actorId: actor.id,
        targetIds: [target.id],
        actionKind: 'skill',
        skillId: skill.id,
        statusEffectId: skill.statusEffectId,
        behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
        position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
      ),
    );
  }

  static void _applyDispelSkill({
    required _Phase1State state,
    required _Combatant actor,
    required CombatSkill skill,
    required int roundIndex,
    required List<CombatAction> actions,
    required String phase,
    required List<_Combatant> candidates,
  }) {
    final dispelKind = skill.dispelKind!;
    final maxCount = skill.dispelMaxCount ?? 1;
    var totalDispelled = 0;
    for (final target in candidates.where((c) => c.alive)) {
      final dispelled = _executeDispel(
        state: state,
        target: target,
        dispelKind: dispelKind,
        maxCount: maxCount,
        roundIndex: roundIndex,
        casterId: actor.id,
      );
      if (dispelled > 0) totalDispelled += dispelled;
    }
    if (!actor.isEnemy && totalDispelled > 0) {
      _accumulateDecisive(state, actor, 'dispel');
    }
    actions.add(
      CombatAction(
        actorId: actor.id,
        targetIds: candidates.where((c) => c.alive).map((c) => c.id).toList(),
        actionKind: 'skill',
        skillId: skill.id,
        behaviorPattern: actor.isEnemy ? actor.behaviorPattern : null,
        position: _resolvePosition(roundIndex, state.lastRoundIndexEstimate),
      ),
    );
  }

  static int _executeDispel({
    required _Phase1State state,
    required _Combatant target,
    required DispelKind dispelKind,
    required int maxCount,
    required int roundIndex,
    required String casterId,
  }) {
    int dispelled = 0;
    bool matchesDot(_ActiveStatusEffect e) =>
        state.staticIndex.statusEffects[e.effectId]?.kind == 'dot';
    bool matchesDebuff(_ActiveStatusEffect e) =>
        state.staticIndex.statusEffects[e.effectId]?.kind == 'debuff';
    bool matchesBuff(_ActiveStatusEffect e) =>
        state.staticIndex.statusEffects[e.effectId]?.kind == 'buff';

    // FR-17.5: mez_stunned는 dispel 불가.
    Iterable<_ActiveStatusEffect> orderByAppliedDesc(
      Iterable<_ActiveStatusEffect> src,
    ) =>
        src.toList()
          ..sort((a, b) => b.appliedAtRound.compareTo(a.appliedAtRound));

    switch (dispelKind) {
      case DispelKind.debuff:
        final eligible = orderByAppliedDesc(
          target.statusEffects.where(
            (e) => matchesDebuff(e) && e.effectId != 'mez_stunned',
          ),
        ).take(maxCount);
        for (final e in eligible.toList()) {
          _removeEffect(state, target, e, roundIndex, 'dispel', casterId);
          dispelled++;
        }
        break;
      case DispelKind.buff:
        final eligible = orderByAppliedDesc(
          target.statusEffects.where(matchesBuff),
        ).take(maxCount);
        for (final e in eligible.toList()) {
          _removeEffect(state, target, e, roundIndex, 'dispel', casterId);
          dispelled++;
        }
        break;
      case DispelKind.dot:
        final list = target.statusEffects.where(matchesDot).toList()
          ..sort((a, b) {
            final c1 = b.stack.compareTo(a.stack);
            if (c1 != 0) return c1;
            final c2 = b.durationTurns.compareTo(a.durationTurns);
            if (c2 != 0) return c2;
            return b.appliedAtRound.compareTo(a.appliedAtRound);
          });
        for (final e in list.take(maxCount).toList()) {
          _removeEffect(state, target, e, roundIndex, 'dispel', casterId);
          dispelled++;
        }
        break;
      case DispelKind.debuffPlusDot:
        // FR-17.5: dot 1개 → debuff 1개 순서.
        final dot = target.statusEffects.where(matchesDot).toList()
          ..sort((a, b) {
            final c1 = b.stack.compareTo(a.stack);
            if (c1 != 0) return c1;
            return b.appliedAtRound.compareTo(a.appliedAtRound);
          });
        if (dot.isNotEmpty) {
          _removeEffect(
            state,
            target,
            dot.first,
            roundIndex,
            'dispel',
            casterId,
          );
          dispelled++;
        }
        final debuff = orderByAppliedDesc(
          target.statusEffects.where(
            (e) => matchesDebuff(e) && e.effectId != 'mez_stunned',
          ),
        ).toList();
        if (debuff.isNotEmpty) {
          _removeEffect(
            state,
            target,
            debuff.first,
            roundIndex,
            'dispel',
            casterId,
          );
          dispelled++;
        }
        break;
    }
    return dispelled;
  }

  static void _removeEffect(
    _Phase1State state,
    _Combatant target,
    _ActiveStatusEffect e,
    int roundIndex,
    String endCause,
    String? casterId,
  ) {
    target.statusEffects.remove(e);
    final eff = state.staticIndex.statusEffects[e.effectId];
    state.history.add(
      StatusEffectEvent(
        eventType: 'end',
        roundIndex: roundIndex,
        targetId: target.id,
        effectId: e.effectId,
        labelKey: eff?.displayLabel ?? e.effectId,
        endCause: endCause,
        casterId: casterId,
      ),
    );
  }

  // ==========================================================================
  // 스킬 자동 선택 — FR-14 (파티) / FR-15 (적)
  // ==========================================================================

  static String? _selectPartySkill(
    _Combatant actor,
    _Phase1State state,
    int roundIndex,
    List<_Combatant> allies,
    List<_Combatant> enemies,
  ) {
    bool ready(String skillId) {
      final skill = state.staticIndex.skills[skillId];
      if (skill == null) return false;
      final cd = actor.cooldowns[skillId] ?? 0;
      if (cd > 0) return false;
      final used = actor.usedCounts[skillId] ?? 0;
      if (skill.maxUsesPerCombat != null && used >= skill.maxUsesPerCombat!) {
        return false;
      }
      return true;
    }

    final role = actor.role;
    final allyAlive = allies.where((c) => c.alive).toList();
    final enemyAlive = enemies.where((c) => c.alive).toList();
    final hpRatio = actor.maxHp > 0 ? actor.hp / actor.maxHp : 0.0;

    if (role == 'warrior' &&
        hpRatio <= 0.5 &&
        !actor.flagBattleFuryUsed &&
        ready('skill_warrior_battle_fury')) {
      return 'skill_warrior_battle_fury';
    }
    if (role == 'support') {
      final anyNegative = allyAlive.any(
        (a) => a.statusEffects.any((e) {
          final k = state.staticIndex.statusEffects[e.effectId]?.kind;
          return k == 'debuff' || k == 'dot';
        }),
      );
      if (anyNegative && ready('skill_support_cleansing_word')) {
        return 'skill_support_cleansing_word';
      }
      final anyDefenseUp = allyAlive.any(
        (a) => a.statusEffects.any((e) => e.effectId == 'buff_defense_up'),
      );
      if (!anyDefenseUp && ready('skill_support_aegis_aura')) {
        return 'skill_support_aegis_aura';
      }
    }
    if (role == 'mage') {
      final maxHp = enemyAlive.fold<int>(0, (s, e) => s < e.hp ? e.hp : s);
      final hasTarget = enemyAlive.any(
        (e) =>
            e.enemyKind == 'unique' || e.enemyKind == 'elite' || e.hp >= maxHp,
      );
      if (hasTarget && ready('skill_mage_stun_bolt')) {
        return 'skill_mage_stun_bolt';
      }
      if (enemyAlive.length >= 2 && ready('skill_mage_arcane_blast')) {
        return 'skill_mage_arcane_blast';
      }
    }
    if (role == 'ranger') {
      if (actor.statusEffects.any((e) => e.effectId == 'buff_accuracy_up') &&
          ready('skill_ranger_volley_shot')) {
        return 'skill_ranger_volley_shot';
      }
      if (actor.isFirstInActionOrder && ready('skill_ranger_marksman_focus')) {
        return 'skill_ranger_marksman_focus';
      }
    }
    if (role == 'rogue') {
      final frontEnemies = enemyAlive
          .where((e) => e.positionRow == PositionRow.front)
          .length;
      if (frontEnemies >= 2 && ready('skill_rogue_mass_blind')) {
        return 'skill_rogue_mass_blind';
      }
    }
    if (role == 'specialist') {
      final hasEvasionUp = actor.statusEffects.any(
        (e) => e.effectId == 'buff_evasion_up',
      );
      if (!hasEvasionUp &&
          enemyAlive.length >= 2 &&
          (hpRatio <= 0.6 || roundIndex >= 2) &&
          ready('skill_specialist_adaptive_footwork')) {
        return 'skill_specialist_adaptive_footwork';
      }
    }
    return null;
  }

  static String? _selectEnemySkill(
    _Combatant actor,
    _Phase1State state,
    int roundIndex,
    List<_Combatant> allies,
    List<_Combatant> enemies,
  ) {
    bool ready(String skillId) {
      if (!actor.skillIds.contains(skillId)) return false;
      final skill = state.staticIndex.skills[skillId];
      if (skill == null) return false;
      final cd = actor.cooldowns[skillId] ?? 0;
      if (cd > 0) return false;
      final used = actor.usedCounts[skillId] ?? 0;
      if (skill.maxUsesPerCombat != null && used >= skill.maxUsesPerCombat!) {
        return false;
      }
      return true;
    }

    final pattern = actor.behaviorPattern;
    final hpRatio = actor.maxHp > 0 ? actor.hp / actor.maxHp : 0.0;
    final partyAlive = enemies.where((c) => c.alive).length;
    final enemyAllies = allies.where((c) => c.alive).toList();

    if (pattern == BehaviorPattern.berserker &&
        hpRatio <= 0.5 &&
        !actor.flagBattleFuryUsed &&
        ready('skill_warrior_battle_fury')) {
      return 'skill_warrior_battle_fury';
    }
    if (pattern == BehaviorPattern.defender) {
      if (roundIndex == 1 && ready('skill_enemy_taunt_roar')) {
        return 'skill_enemy_taunt_roar';
      }
      if (hpRatio <= 0.6 &&
          !actor.flagSummonUsed &&
          ready('skill_enemy_summon')) {
        return 'skill_enemy_summon';
      }
    }
    if (pattern == BehaviorPattern.caster) {
      if (partyAlive >= 2 && ready('skill_mage_arcane_blast')) {
        return 'skill_mage_arcane_blast';
      }
      if (partyAlive >= 1 && ready('skill_mage_stun_bolt')) {
        return 'skill_mage_stun_bolt';
      }
    }
    if (pattern == BehaviorPattern.supporter) {
      final anyDefenseUp = enemyAllies.any(
        (a) => a.statusEffects.any((e) => e.effectId == 'buff_defense_up'),
      );
      if (!anyDefenseUp && ready('skill_support_aegis_aura')) {
        return 'skill_support_aegis_aura';
      }
    }
    if (ready('skill_enemy_armor_break')) return 'skill_enemy_armor_break';
    if (ready('skill_enemy_bleeding_cut')) return 'skill_enemy_bleeding_cut';
    if (ready('skill_enemy_poison_bite')) return 'skill_enemy_poison_bite';
    if (ready('skill_enemy_self_dispel')) {
      final negCount = actor.statusEffects.where((e) {
        final k = state.staticIndex.statusEffects[e.effectId]?.kind;
        return k == 'debuff' || k == 'dot';
      }).length;
      if (negCount >= 2) return 'skill_enemy_self_dispel';
    }
    return null;
  }

  static void _registerCooldown(
    _Phase1State state,
    _Combatant actor,
    CombatSkill skill,
  ) {
    actor.usedCounts[skill.id] = (actor.usedCounts[skill.id] ?? 0) + 1;
    if (skill.cooldownRounds > 0) {
      actor.cooldowns[skill.id] = skill.cooldownRounds + 1;
    }
    if (skill.id == 'skill_warrior_battle_fury') {
      actor.flagBattleFuryUsed = true;
    }
    if (skill.id == 'skill_enemy_summon') {
      actor.flagSummonUsed = true;
    }
  }

  // ==========================================================================
  // 표적 결정 — FR-16
  // ==========================================================================

  static List<_Combatant> _selectTargets({
    required _Combatant actor,
    CombatSkill? skill,
    required List<_Combatant> allies,
    required List<_Combatant> enemies,
    required _Phase1State state,
  }) {
    if (skill != null) {
      switch (skill.targetingKind) {
        case TargetingKind.self:
          return [actor];
        case TargetingKind.singleAlly:
          final cands = allies
              .where((c) => c.alive && c.id != actor.id)
              .toList();
          cands.sort((a, b) {
            final ra = a.maxHp > 0 ? a.hp / a.maxHp : 1.0;
            final rb = b.maxHp > 0 ? b.hp / b.maxHp : 1.0;
            return ra.compareTo(rb);
          });
          return cands.isEmpty ? [actor] : [cands.first];
        case TargetingKind.aoeAlly:
        case TargetingKind.party:
          return allies.where((c) => c.alive).toList();
        case TargetingKind.aoeEnemy:
          return _frontProtectedEnemies(
            enemies,
          ).take(skill.targetingMaxCount ?? 99).toList();
        case TargetingKind.singleEnemy:
          return _selectSingleEnemyByRole(actor, enemies);
      }
    }
    return _selectSingleEnemyByRole(actor, enemies);
  }

  static List<_Combatant> _selectSingleEnemyByRole(
    _Combatant actor,
    List<_Combatant> enemies,
  ) {
    final survivors = _frontProtectedEnemies(enemies);
    if (survivors.isEmpty) return const [];

    final role = actor.role;
    final pattern = actor.behaviorPattern;
    if (pattern == BehaviorPattern.opportunist) {
      final sorted = survivors.toList()
        ..sort((a, b) {
          final ra = a.maxHp > 0 ? a.hp / a.maxHp : 1.0;
          final rb = b.maxHp > 0 ? b.hp / b.maxHp : 1.0;
          return ra.compareTo(rb);
        });
      return [sorted.first];
    }
    if (role == 'ranger') {
      final sorted = survivors.toList()..sort((a, b) => a.hp.compareTo(b.hp));
      return [sorted.first];
    }
    if (role == 'mage' || role == 'support') {
      final back = survivors
          .where((e) => e.positionRow == PositionRow.back)
          .toList();
      if (back.isNotEmpty) return [back.first];
      return [survivors.first];
    }
    return [survivors.first];
  }

  static List<_Combatant> _frontProtectedEnemies(List<_Combatant> enemies) {
    final alive = enemies.where((c) => c.alive).toList();
    final front = alive
        .where((e) => e.positionRow == PositionRow.front)
        .toList();
    if (front.isNotEmpty) {
      // 전열 보호: 후·중열 차단.
      return front;
    }
    final middle = alive
        .where((e) => e.positionRow == PositionRow.middle)
        .toList();
    if (middle.isNotEmpty) return middle;
    return alive;
  }

  // ==========================================================================
  // 산식 hook — FR-11 §2~7, FR-11.5
  // ==========================================================================

  static double _evaluateHitChance(
    _Combatant atk,
    _Combatant def,
    List<String> envTags,
  ) {
    final base = CombatSimulatorConstants.baseHitRate[atk.role] ?? 0.78;
    final agiDiff = (atk.agi - def.agi) * CombatSimulatorConstants.agiHitCoef;
    final traitBonus = _traitKeywordSumDouble(
      atk.traitIds,
      CombatSimulatorConstants.hitKeywords,
    ).clamp(0.0, CombatSimulatorConstants.traitHitCapPerMerc);
    final envMod = _envHitMod(atk.role, envTags);
    final buffSum = _sumStatusIntensities(atk, 'buff_accuracy_up');
    final debuffSum = _sumStatusIntensities(def, 'debuff_accuracy_down');
    final statusMod = buffSum - debuffSum;
    final raw = base + agiDiff + traitBonus + envMod + statusMod;
    return raw.clamp(
      CombatSimulatorConstants.hitChanceMin,
      CombatSimulatorConstants.hitChanceMax,
    );
  }

  static double _evaluateEvasionChance(
    _Combatant atk,
    _Combatant def,
    List<String> envTags,
  ) {
    final base = CombatSimulatorConstants.baseEvasion[def.role] ?? 0.10;
    final agiDiff =
        (def.agi - atk.agi) * CombatSimulatorConstants.agiEvasionCoef;
    final traitBonus = _traitKeywordSumDouble(
      def.traitIds,
      CombatSimulatorConstants.evasionKeywords,
    ).clamp(0.0, CombatSimulatorConstants.traitEvasionCapPerMerc);
    final envMod = _envEvasionMod(def.role, envTags);
    final statusMod = _sumStatusIntensities(def, 'buff_evasion_up');
    final raw = base + agiDiff + traitBonus + envMod + statusMod;
    return raw.clamp(
      CombatSimulatorConstants.evasionChanceMin,
      CombatSimulatorConstants.evasionChanceMax,
    );
  }

  static double _evaluateRiposteChance(_Combatant def) {
    final base = CombatSimulatorConstants.baseRiposte[def.role] ?? 0.10;
    final traitBonus = _traitKeywordSumDouble(
      def.traitIds,
      CombatSimulatorConstants.counterKeywords,
    );
    final raw = base + traitBonus;
    return raw.clamp(
      CombatSimulatorConstants.riposteChanceMin,
      CombatSimulatorConstants.riposteChanceMax,
    );
  }

  static double _evaluateCritChance(
    _Combatant atk,
    _Combatant def,
    CombatSkill? skill,
    _Phase1State state,
  ) {
    final base = CombatSimulatorConstants.baseCritRate[atk.role] ?? 0.05;
    final agiBonus = atk.agi * CombatSimulatorConstants.agiCritCoef;
    final traitBonus = _traitKeywordSumDouble(
      atk.traitIds,
      CombatSimulatorConstants.critKeywords,
    ).clamp(0.0, CombatSimulatorConstants.traitCritCapPerMerc);
    final flank =
        (def.positionRow == PositionRow.back && _enemyFrontAllDead(state, def))
        ? (CombatSimulatorConstants.flankBonus[atk.role] ?? 0.0)
        : 0.0;
    final skillBonus = skill?.critRateBonus ?? 0.0;
    final raw = base + agiBonus + traitBonus + flank + skillBonus;
    return raw.clamp(
      CombatSimulatorConstants.critChanceMin,
      CombatSimulatorConstants.critChanceMax,
    );
  }

  static double _evaluateShieldChance(_Combatant def, _Phase1State state) {
    final traitBonus = _traitKeywordSumDouble(
      def.traitIds,
      CombatSimulatorConstants.shieldKeywords,
    );
    final skillBonus = _passiveShieldBonus(def, state);
    return (traitBonus + skillBonus).clamp(0.0, 1.0);
  }

  static double _traitShieldBonus(_Combatant c) => _traitKeywordSumDouble(
    c.traitIds,
    CombatSimulatorConstants.shieldKeywords,
  );

  static double _passiveShieldBonus(_Combatant c, _Phase1State state) {
    var sum = 0.0;
    for (final skill in state.staticIndex.skills.values) {
      if (skill.role != c.role) continue;
      if (skill.actionCost != ActionCost.passive) continue;
      if (skill.shieldBlockBonus == null) continue;
      if (c.isEnemy && !c.skillIds.contains(skill.id)) continue;
      if (skill.partyOnly && c.isEnemy) continue;
      sum += skill.shieldBlockBonus!;
    }
    return sum;
  }

  static double _evaluateDeathResist(_Combatant c, bool isChainProtagonist) {
    final base = CombatSimulatorConstants.baseDeathResistByTier[c.tier] ?? 0.30;
    final roleBonus =
        CombatSimulatorConstants.roleDeathResistBonus[c.role] ?? 0.0;
    final traitBonus = _traitKeywordSumDouble(
      c.traitIds,
      CombatSimulatorConstants.deathResistKeywords,
    ).clamp(0.0, CombatSimulatorConstants.traitDeathResistCapPerMerc);
    var chance = (base + roleBonus + traitBonus).clamp(
      CombatSimulatorConstants.deathResistMin,
      CombatSimulatorConstants.deathResistMax,
    );
    if (isChainProtagonist) {
      chance += (1.0 - chance) * 0.5;
      chance = chance.clamp(
        0.0,
        CombatSimulatorConstants.deathResistChainProtagonistMax,
      );
    }
    return chance;
  }

  static int _computeBaseAttack(_Combatant c) {
    final role = c.role;
    final str = c.str;
    final intel = c.int_;
    int raw;
    switch (role) {
      case 'warrior':
      case 'specialist':
      case 'rogue':
        raw = (str * 1.4).round() + 4;
        break;
      case 'ranger':
        raw = (str * 1.1).round() + (c.agi * 0.4).round() + 3;
        break;
      case 'mage':
        raw = (intel * 1.5).round() + 2;
        break;
      case 'support':
        raw = (intel * 1.0).round() + (str * 0.5).round() + 2;
        break;
      default:
        raw = (str * 1.2).round() + 3;
    }
    final buffMul = _sumStatusIntensities(c, 'buff_attack_up');
    final debuffMul = _sumStatusIntensities(c, 'debuff_attack_down');
    final modded = (raw * (1.0 + buffMul) * (1.0 - debuffMul)).round();
    return modded < 1 ? 1 : modded;
  }

  static int _computeDefense(_Combatant c) {
    final coef = CombatSimulatorConstants.roleDefCoef[c.role] ?? 1.0;
    final flat = CombatSimulatorConstants.roleDefFlat[c.role] ?? 3;
    final raw = (c.vit * coef).round() + flat;
    final buffMul = _sumStatusIntensities(c, 'buff_defense_up');
    final debuffMul = _sumStatusIntensities(c, 'debuff_defense_down');
    final modded = (raw * (1.0 + buffMul) * (1.0 - debuffMul)).round();
    return modded < 1 ? 1 : modded;
  }

  // ==========================================================================
  // 상태 효과 — FR-17, FR-17.5
  // ==========================================================================

  static void _applyStatusEffect({
    required _Combatant target,
    _Combatant? caster,
    required CombatStatusEffect effect,
    required double intensity,
    required int duration,
    required int roundIndex,
    required double applyChance,
    Random? applyRng,
    required List<StatusEffectEvent> history,
  }) {
    if (applyRng != null && applyChance < 1.0) {
      if (applyRng.nextDouble() >= applyChance) return;
    }

    final existing = target.statusEffects
        .where((e) => e.effectId == effect.id)
        .toList();
    int finalStack = 1;
    int finalDuration = duration;
    double finalIntensity = intensity;
    String eventType = 'apply';

    if (existing.isNotEmpty) {
      final cur = existing.first;
      switch (effect.stackPolicy) {
        case StackPolicy.refresh:
          if (effect.id == 'mez_stunned') {
            finalDuration =
                (cur.durationTurns > duration ? cur.durationTurns : duration)
                    .clamp(0, CombatSimulatorConstants.mezStunnedMaxDuration);
          } else {
            finalDuration = cur.durationTurns > duration
                ? cur.durationTurns
                : duration;
          }
          finalIntensity = cur.intensity;
          finalStack = cur.stack;
          cur.durationTurns = finalDuration;
          break;
        case StackPolicy.stack:
          finalStack = (cur.stack + 1).clamp(
            1,
            CombatSimulatorConstants.dotMaxStack,
          );
          finalDuration = cur.durationTurns > duration
              ? cur.durationTurns
              : duration;
          if (effect.id == 'dot_poisoned') {
            final mapped = CombatSimulatorConstants
                .dotPoisonedIntensityByStack[finalStack];
            finalIntensity = (mapped ?? intensity).toDouble();
          } else {
            finalIntensity = intensity;
          }
          cur.stack = finalStack;
          cur.durationTurns = finalDuration;
          cur.intensity = finalIntensity;
          eventType = 'stack_increase';
          break;
        case StackPolicy.ignore:
          return;
      }
    } else {
      target.statusEffects.add(
        _ActiveStatusEffect(
          effectId: effect.id,
          intensity: finalIntensity,
          durationTurns: finalDuration,
          stack: finalStack,
          appliedAtRound: roundIndex,
        ),
      );
    }

    history.add(
      StatusEffectEvent(
        eventType: eventType,
        roundIndex: roundIndex,
        targetId: target.id,
        effectId: effect.id,
        labelKey: effect.displayLabel,
        casterId: caster?.id,
        intensity: finalIntensity,
        durationTurns: finalDuration,
        stackResult: eventType == 'stack_increase' ? finalStack : null,
      ),
    );

    // mezApply 결정적 장면 점수 가산은 _applyStatusEffect 외부에서 state 컨텍스트와 함께 처리.
    // (caster·state 동시 접근 가능한 호출점에서만 정확하므로 본 함수는 마킹만.)
  }

  static double _sumStatusIntensities(_Combatant c, String effectId) {
    var sum = 0.0;
    for (final e in c.statusEffects) {
      if (e.effectId == effectId) sum += e.intensity;
    }
    return sum;
  }

  static void _tickStatusEffects(_Phase1State state, int roundIndex) {
    for (final c in [...state.partyState, ...state.enemyState]) {
      final expired = <_ActiveStatusEffect>[];
      for (final e in c.statusEffects) {
        e.durationTurns -= 1;
        if (e.durationTurns <= 0) expired.add(e);
      }
      for (final e in expired) {
        c.statusEffects.remove(e);
        final effect = state.staticIndex.statusEffects[e.effectId];
        state.history.add(
          StatusEffectEvent(
            eventType: 'end',
            roundIndex: roundIndex,
            targetId: c.id,
            effectId: e.effectId,
            labelKey: effect?.displayLabel ?? e.effectId,
            endCause: 'natural',
          ),
        );
      }
    }
  }

  static void _applyDotRoundStart(
    _Phase1State state,
    int roundIndex,
    List<CombatAction> actions,
  ) {
    for (final c in [...state.partyState, ...state.enemyState]) {
      if (!c.alive) continue;
      final poisoned = c.statusEffects
          .where((e) => e.effectId == 'dot_poisoned')
          .toList();
      if (poisoned.isEmpty) continue;
      for (final p in poisoned) {
        final dmg =
            (p.intensity * CombatSimulatorConstants.dotPoisonedBaseMultiplier +
                    c.level *
                        CombatSimulatorConstants.dotPoisonedLevelMultiplier)
                .floor();
        final applied = dmg < 1 ? 1 : dmg;
        c.hp -= applied;
        actions.add(
          CombatAction(
            actorId: c.id,
            targetIds: [c.id],
            actionKind: 'dot_tick',
            statusEffectId: 'dot_poisoned',
            position: _resolvePosition(
              roundIndex,
              state.lastRoundIndexEstimate,
            ),
            damage: applied,
          ),
        );
        if (c.hp <= 0) {
          _resolveDeath(state, c, c.isChainProtagonist(state));
          break;
        }
      }
    }
  }

  static void _applyDotRoundEnd(
    _Phase1State state,
    int roundIndex,
    List<CombatAction> actions,
  ) {
    for (final c in [...state.partyState, ...state.enemyState]) {
      if (!c.alive) continue;
      final bleeding = c.statusEffects
          .where((e) => e.effectId == 'dot_bleeding')
          .toList();
      for (final b in bleeding) {
        final dmg =
            (c.maxHp * CombatSimulatorConstants.dotBleedingHpFactor * b.stack)
                .floor();
        final applied = dmg < 1 ? 1 : dmg;
        c.hp -= applied;
        actions.add(
          CombatAction(
            actorId: c.id,
            targetIds: [c.id],
            actionKind: 'dot_tick',
            statusEffectId: 'dot_bleeding',
            position: _resolvePosition(
              roundIndex,
              state.lastRoundIndexEstimate,
            ),
            damage: applied,
          ),
        );
        if (c.hp <= 0) {
          _resolveDeath(state, c, c.isChainProtagonist(state));
          break;
        }
      }
    }
  }

  // ==========================================================================
  // 사망 저항 / 종료 조건 — FR-11.5, FR-9 §5
  // ==========================================================================

  static bool _resolveDeath(
    _Phase1State state,
    _Combatant c,
    bool isChainProtagonist,
  ) {
    if (c.isEnemy) {
      c.deceased = true;
      c.hp = 0;
      _cleanupOnDeath(state, c, state.lastRoundIndexEstimate);
      return true;
    }
    final chance = _evaluateDeathResist(c, isChainProtagonist);
    final deathRng = Random(
      state.seed ^
          stableSeed32('${CombatSimulatorConstants.seedKeyDeath}|${c.id}'),
    );
    if (deathRng.nextDouble() < chance) {
      c.hp = 1;
      c.injured = true;
      return false;
    } else {
      c.deceased = true;
      c.hp = 0;
      _cleanupOnDeath(state, c, state.lastRoundIndexEstimate);
      return true;
    }
  }

  static void _cleanupOnDeath(
    _Phase1State state,
    _Combatant c,
    int roundIndex,
  ) {
    for (final e in [...c.statusEffects]) {
      c.statusEffects.remove(e);
      final eff = state.staticIndex.statusEffects[e.effectId];
      state.history.add(
        StatusEffectEvent(
          eventType: 'end',
          roundIndex: roundIndex,
          targetId: c.id,
          effectId: e.effectId,
          labelKey: eff?.displayLabel ?? e.effectId,
          endCause: 'death',
        ),
      );
    }
  }

  static bool _partyWiped(_Phase1State state) =>
      state.partyState.every((c) => !c.alive);

  static bool _enemyWiped(_Phase1State state) =>
      state.enemyState.every((c) => !c.alive);

  static CombatExitCondition? _checkPostDotExit(_Phase1State state) {
    if (_partyWiped(state)) return CombatExitCondition.aPartyWiped;
    if (_enemyWiped(state)) return CombatExitCondition.bEnemyWiped;
    return null;
  }

  static CombatExitCondition? _evaluateExitConditions(
    _Phase1State state,
    int roundIndex,
  ) {
    if (_partyWiped(state)) return CombatExitCondition.aPartyWiped;
    if (_objectiveAchieved(state)) {
      return CombatExitCondition.cObjectiveAchieved;
    }
    if (_enemyWiped(state)) return CombatExitCondition.bEnemyWiped;
    // (e) 사기 도주 eFlee: M8b 페이즈 4 #5 위임.
    final escortDead = state.quest.specialFlags?['escort_target_dead'] == true;
    if (escortDead) return CombatExitCondition.fEscortDead;
    return null;
  }

  static bool _objectiveAchieved(_Phase1State state) {
    final typeId = state.quest.questTypeId;
    final flags =
        state.pool?.specialFlags ?? state.quest.specialFlags ?? const {};

    if (typeId == 'escort') {
      final progress = flags['objective_progress'];
      return progress is num && progress >= 1.0;
    }
    if (typeId == 'explore' || typeId == 'investigation') {
      final required =
          (flags['required_kill_count'] as num?)?.toInt() ??
          state.enemyState.length;
      return required <= 0 || state.killedEnemyCount >= required;
    }
    return false;
  }

  // ==========================================================================
  // 행동 순서 — FR-9 §3
  // ==========================================================================

  static List<_Combatant> _orderByActionScore(
    _Phase1State state,
    int roundIndex,
  ) {
    final pool = [
      ...state.partyState.where((c) => c.alive),
      ...state.enemyState.where((c) => c.alive),
    ];
    final scored =
        pool.map((c) {
          final orderRng = Random(
            state.seed ^
                stableSeed32(
                  '${CombatSimulatorConstants.seedKeyOrder}|$roundIndex|${c.id}',
                ),
          );
          final noise = orderRng.nextInt(7) - 3;
          final traitBonus = _traitKeywordSumInt(
            c.traitIds,
            CombatSimulatorConstants.actionKeywords,
          ).clamp(0, CombatSimulatorConstants.traitActionCapPerMerc);
          final envMod = _envActionMod(c.role, state.envTags);
          final score =
              c.agi +
              (CombatSimulatorConstants.roleActionWeight[c.role] ?? 0) +
              traitBonus +
              envMod +
              noise;
          return _ScoredCombatant(c, score);
        }).toList()..sort((a, b) {
          if (b.score != a.score) return b.score.compareTo(a.score);
          final rpA = CombatSimulatorConstants.rolePriorityForTiebreak.indexOf(
            a.c.role,
          );
          final rpB = CombatSimulatorConstants.rolePriorityForTiebreak.indexOf(
            b.c.role,
          );
          final ra = rpA < 0 ? 99 : rpA;
          final rb = rpB < 0 ? 99 : rpB;
          if (ra != rb) return ra.compareTo(rb);
          if (b.c.tier != a.c.tier) return b.c.tier.compareTo(a.c.tier);
          final ha = stableSeed32(a.c.id);
          final hb = stableSeed32(b.c.id);
          if (ha != hb) return ha.compareTo(hb);
          return a.c.id.compareTo(b.c.id);
        });

    final result = scored.map((s) => s.c).toList();
    if (result.isNotEmpty) result.first.isFirstInActionOrder = true;
    for (int i = 1; i < result.length; i++) {
      result[i].isFirstInActionOrder = false;
    }
    // 쿨다운 1턴 감소.
    for (final c in pool) {
      final keys = c.cooldowns.keys.toList();
      for (final k in keys) {
        final v = (c.cooldowns[k] ?? 0) - 1;
        c.cooldowns[k] = v < 0 ? 0 : v;
      }
    }
    return result;
  }

  // ==========================================================================
  // 결과 매핑 — FR-10
  // ==========================================================================

  static QuestResult _mapToQuestResult({
    required CombatExitCondition exit,
    required double enemySurvivalRatio,
    required double partySurvivalRatio,
    required int injuredCount,
    required double objectiveProgress,
  }) {
    switch (exit) {
      case CombatExitCondition.bEnemyWiped:
        if (partySurvivalRatio >= 0.6 && injuredCount == 0) {
          return QuestResult.greatSuccess;
        }
        return QuestResult.success;
      case CombatExitCondition.cObjectiveAchieved:
        return objectiveProgress >= 0.9
            ? QuestResult.greatSuccess
            : QuestResult.success;
      case CombatExitCondition.dRoundLimit:
        if (objectiveProgress >= 0.7) return QuestResult.success;
        return QuestResult.failure;
      case CombatExitCondition.eFlee:
        return QuestResult.failure;
      case CombatExitCondition.aPartyWiped:
        return QuestResult.criticalFailure;
      case CombatExitCondition.fEscortDead:
        return QuestResult.criticalFailure;
    }
  }

  static double _computeObjectiveProgress({
    required _Phase1State state,
    required int enemyHpMax,
    required int enemyHpRem,
  }) {
    final pool = state.pool;
    final typeId = state.quest.questTypeId;
    final flags = pool?.specialFlags ?? state.quest.specialFlags ?? const {};

    if (typeId == 'escort' && flags['objective_progress'] is num) {
      return (flags['objective_progress'] as num).toDouble().clamp(0.0, 1.0);
    }
    if (typeId == 'explore' || typeId == 'investigation') {
      final required =
          (flags['required_kill_count'] as num?)?.toInt() ??
          state.enemyState.length;
      if (required <= 0) return 1.0;
      return (state.killedEnemyCount / required).clamp(0.0, 1.0);
    }
    if (enemyHpMax <= 0) return 1.0;
    return (1.0 - enemyHpRem / enemyHpMax).clamp(0.0, 1.0);
  }

  static List<String> _computeToneTags({
    required _Phase1State state,
    required QuestResult questResult,
  }) {
    final keywords = state.staticIndex.toneKeywords;
    if (keywords.isEmpty) return const [];
    final count =
        CombatSimulatorConstants.toneTagCountByResult[questResult.name] ?? 0;
    if (count <= 0) return const [];

    final toneRng = Random(
      state.seed ^
          stableSeed32(
            '${CombatSimulatorConstants.seedKeyTone}|${state.quest.id}',
          ),
    );
    final result = <String>[];

    // 1) battlefield.
    final battlefieldPool = keywords
        .where(
          (k) =>
              k.category == 'battlefield' && _toneMatchesEnv(k, state.envTags),
        )
        .toList();
    final bf = _weightedPick(battlefieldPool, toneRng);
    if (bf != null) result.add(bf.key);

    if (result.length < count) {
      // 적의 enemyKeywordKey는 EnemySnapshot에 정의되지만 시뮬레이션 상태에는 직접 보관하지 않으므로
      // archetype id를 fallback 키로 사용한다.
      final enemyKeys = state.enemyState.map((e) {
        final archId = e.id.split('#').first;
        return archId;
      }).toSet();
      final enemyPool = keywords
          .where((k) => k.category == 'enemy' && enemyKeys.contains(k.key))
          .toList();
      final en = _weightedPick(enemyPool, toneRng);
      if (en != null) result.add(en.key);
    }

    if (result.length < count) {
      final decisivePool = keywords
          .where((k) => k.category == 'decisive')
          .toList();
      final remaining = (count - result.length).clamp(0, 1);
      for (var i = 0; i < remaining; i++) {
        final d = _weightedPick(decisivePool, toneRng);
        if (d != null && !result.contains(d.key)) result.add(d.key);
      }
    }
    return result;
  }

  static bool _toneMatchesEnv(CombatReportKeyword k, List<String> envTags) {
    final tags = k.parsedTags;
    final raw = tags['env_tags'];
    if (raw is List) {
      return raw.any((e) => envTags.contains(e));
    }
    return envTags.contains(k.key);
  }

  static CombatReportKeyword? _weightedPick(
    List<CombatReportKeyword> pool,
    Random rng,
  ) {
    if (pool.isEmpty) return null;
    final total = pool.fold<int>(
      0,
      (s, k) => s + (k.weight <= 0 ? 1 : k.weight),
    );
    if (total <= 0) return pool.first;
    var roll = rng.nextInt(total);
    for (final k in pool) {
      final w = k.weight <= 0 ? 1 : k.weight;
      roll -= w;
      if (roll < 0) return k;
    }
    return pool.last;
  }

  // ==========================================================================
  // 보조: 점수·인원·진형·환경·트레잇 유틸
  // ==========================================================================

  static int _sideInitiativeScore(List<_Combatant> side, List<String> envTags) {
    if (side.isEmpty) return 0;
    final avgAgi = side.fold<int>(0, (s, c) => s + c.agi) / side.length;
    final avgRoleW =
        side.fold<int>(
          0,
          (s, c) =>
              s + (CombatSimulatorConstants.roleInitiativeWeight[c.role] ?? 0),
        ) /
        side.length;
    var traitSum = 0;
    for (final c in side) {
      final bonus = _traitKeywordSumInt(
        c.traitIds,
        CombatSimulatorConstants.initiativeKeywords,
      ).clamp(0, CombatSimulatorConstants.traitInitiativeCapPerMerc);
      traitSum += bonus;
    }
    final teamTraitBonus = traitSum.clamp(
      0,
      CombatSimulatorConstants.traitInitiativeCapTeam,
    );
    final envMod = envTags.isEmpty
        ? 0
        : (CombatSimulatorConstants.environmentInitiativeMod[envTags.first] ??
              0);
    return (avgAgi + avgRoleW + teamTraitBonus + envMod).round();
  }

  static int _computeMorale(List<_Combatant> side) {
    var morale = CombatSimulatorConstants.moraleBase;
    if (side.any(
      (c) => c.traitIds.any((t) => t.contains('brave') || t.contains('valor')),
    )) {
      morale += 10;
    }
    if (side.any(
      (c) => c.traitIds.any((t) => t.contains('coward') || t.contains('timid')),
    )) {
      morale -= 10;
    }
    return morale.clamp(
      CombatSimulatorConstants.moraleMin,
      CombatSimulatorConstants.moraleMax,
    );
  }

  static int _traitKeywordSumInt(
    List<String> traitIds,
    Map<String, int> matrix,
  ) {
    var sum = 0;
    for (final t in traitIds) {
      for (final entry in matrix.entries) {
        if (t.contains(entry.key)) sum += entry.value;
      }
    }
    return sum;
  }

  static double _traitKeywordSumDouble(
    List<String> traitIds,
    Map<String, double> matrix,
  ) {
    var sum = 0.0;
    for (final t in traitIds) {
      for (final entry in matrix.entries) {
        if (t.contains(entry.key)) sum += entry.value;
      }
    }
    return sum;
  }

  static double _envHitMod(String role, List<String> envTags) {
    var sum = 0.0;
    for (final tag in envTags) {
      final map = CombatSimulatorConstants.environmentHitMod[tag];
      if (map != null) sum += map[role] ?? 0.0;
    }
    return sum;
  }

  static double _envEvasionMod(String role, List<String> envTags) {
    var sum = 0.0;
    for (final tag in envTags) {
      final map = CombatSimulatorConstants.environmentEvasionMod[tag];
      if (map != null) sum += map[role] ?? 0.0;
    }
    return sum;
  }

  static int _envActionMod(String role, List<String> envTags) {
    var sum = 0;
    for (final tag in envTags) {
      final map = CombatSimulatorConstants.environmentActionMod[tag];
      if (map != null) sum += map[role] ?? 0;
    }
    return sum;
  }

  static bool _enemyFrontAllDead(_Phase1State state, _Combatant def) {
    final side = def.isEnemy ? state.enemyState : state.partyState;
    return side
        .where((c) => c.positionRow == PositionRow.front)
        .every((c) => !c.alive);
  }

  static PositionRow _resolvePositionRow(String role) {
    if (role == 'warrior' || role == 'specialist') return PositionRow.front;
    if (role == 'rogue' || role == 'ranger') return PositionRow.middle;
    return PositionRow.back;
  }

  static void _assignFormationIndicesParty(List<CombatantSnapshot> items) {
    // row별 index 0..n.
    final byRow = <PositionRow, int>{};
    for (final item in items) {
      final row = item.positionRow;
      final idx = byRow[row] ?? 0;
      item.positionIndex = idx;
      byRow[row] = idx + 1;
    }
  }

  static void _assignFormationIndicesEnemy(List<EnemySnapshot> items) {
    // row별 index 0..n.
    final byRow = <PositionRow, int>{};
    for (final item in items) {
      final row = item.positionRow;
      final idx = byRow[row] ?? 0;
      item.positionIndex = idx;
      byRow[row] = idx + 1;
    }
  }

  static Map<String, int> _snapshotHp(_Phase1State state) {
    final map = <String, int>{};
    for (final c in [...state.partyState, ...state.enemyState]) {
      map[c.id] = c.hp;
    }
    return map;
  }

  static List<_Combatant> _alliesOf(_Phase1State state, _Combatant actor) =>
      actor.isEnemy ? state.enemyState : state.partyState;

  static List<_Combatant> _enemiesOf(_Phase1State state, _Combatant actor) =>
      actor.isEnemy ? state.partyState : state.enemyState;

  static String _resolvePosition(int roundIndex, int totalRounds) {
    // FR-18 §3 5 위치 — 라운드 비율로 자동 매핑.
    if (roundIndex == 0) return 'entry';
    if (totalRounds <= 1) return 'resolution';
    final ratio = roundIndex / totalRounds;
    if (ratio <= 0.25) return 'entry';
    if (ratio <= 0.65) return 'development';
    if (ratio <= 0.85) return 'crisis';
    if (ratio < 1.0) return 'resolution';
    return 'aftermath';
  }

  static void _accumulateDecisive(
    _Phase1State state,
    _Combatant c,
    String key,
  ) {
    final score = CombatSimulatorConstants.decisiveActionScores[key] ?? 0;
    if (score <= 0) return;
    state.decisiveScores[c.id] = (state.decisiveScores[c.id] ?? 0) + score;
  }

  static void _migrateNextRoundQueue(_Phase1State state) {
    for (final entry in state.nextRoundExtraAction.entries) {
      if (entry.value <= 0) continue;
      state.extraActionRoundStart[entry.key] =
          (state.extraActionRoundStart[entry.key] ?? 0) + entry.value;
    }
    state.nextRoundExtraAction.clear();
  }

  // ==========================================================================
  // 적 그룹 구성 — FR-7
  // ==========================================================================

  static List<EnemySnapshot>? _buildEnemyGroup({
    required int seed,
    required ActiveQuest quest,
    QuestPool? pool,
    required StaticGameData staticData,
    required List<String> envTags,
  }) {
    final archetypes = staticData.enemyArchetypes;
    final orderRng = Random(
      seed ^
          stableSeed32('${CombatSimulatorConstants.seedKeyGroup}|${quest.id}'),
    );

    final factionTag = pool?.factionTag ?? quest.factionTag;
    final candidates = <EnemyArchetype>[];

    // §1.1: eliteId + unique.
    if (quest.eliteId != null) {
      final unique = archetypes.where(
        (a) =>
            a.eliteMonsterId == quest.eliteId &&
            a.enemyKind == EnemyKind.unique,
      );
      if (unique.isNotEmpty) {
        final lead = unique.first;
        final normals = archetypes
            .where((a) => a.enemyKind == EnemyKind.normal)
            .toList();
        final extra = normals.isEmpty ? 0 : orderRng.nextInt(4);
        return _materializeGroup(
          lead: lead,
          extras: normals,
          extraCount: extra,
          orderRng: orderRng,
          factionTag: factionTag,
        );
      }
      // §1.2: eliteId + elite.
      final elite = archetypes.where(
        (a) =>
            a.eliteMonsterId == quest.eliteId && a.enemyKind == EnemyKind.elite,
      );
      if (elite.isNotEmpty) {
        final lead = elite.first;
        final normals = archetypes
            .where((a) => a.enemyKind == EnemyKind.normal)
            .toList();
        final extra = normals.isEmpty ? 0 : (orderRng.nextInt(3) + 1);
        return _materializeGroup(
          lead: lead,
          extras: normals,
          extraCount: extra,
          orderRng: orderRng,
          factionTag: factionTag,
        );
      }
    }

    // §1.3: factionTag 매칭.
    if (factionTag != null && factionTag.isNotEmpty) {
      final factionPool = archetypes
          .where((a) => a.factionTags.contains(factionTag))
          .toList();
      if (factionPool.isNotEmpty) {
        final normals = factionPool
            .where((a) => a.enemyKind == EnemyKind.normal)
            .toList();
        final elites = factionPool
            .where((a) => a.enemyKind == EnemyKind.elite)
            .toList();
        candidates.addAll(normals);
        final normalCount = normals.isEmpty ? 0 : (orderRng.nextInt(3) + 2);
        final eliteCount = elites.isEmpty ? 0 : orderRng.nextInt(2);
        final snapshots = <EnemySnapshot>[];
        for (var i = 0; i < normalCount && normals.isNotEmpty; i++) {
          final pick = normals[orderRng.nextInt(normals.length)];
          snapshots.add(
            _archetypeToSnapshot(pick, snapshots.length, factionTag),
          );
        }
        for (var i = 0; i < eliteCount && elites.isNotEmpty; i++) {
          final pick = elites[orderRng.nextInt(elites.length)];
          snapshots.add(
            _archetypeToSnapshot(pick, snapshots.length, factionTag),
          );
        }
        if (snapshots.isNotEmpty) return snapshots;
      }
    }

    // §1.4: 환경 태그 매칭.
    final envPool = archetypes
        .where(
          (a) =>
              a.enemyKind == EnemyKind.normal &&
              a.environmentTags.any((t) => envTags.contains(t)),
        )
        .toList();
    final fallbackPool = envPool.isEmpty
        ? archetypes.where((a) => a.enemyKind == EnemyKind.normal).toList()
        : envPool;
    if (fallbackPool.isEmpty) return null;
    final count = orderRng.nextInt(2) + 2;
    final snapshots = <EnemySnapshot>[];
    for (var i = 0; i < count; i++) {
      final pick = fallbackPool[orderRng.nextInt(fallbackPool.length)];
      snapshots.add(_archetypeToSnapshot(pick, snapshots.length, factionTag));
    }
    return snapshots;
  }

  static List<EnemySnapshot> _materializeGroup({
    required EnemyArchetype lead,
    required List<EnemyArchetype> extras,
    required int extraCount,
    required Random orderRng,
    String? factionTag,
  }) {
    final out = <EnemySnapshot>[];
    out.add(_archetypeToSnapshot(lead, 0, factionTag));
    for (var i = 0; i < extraCount && extras.isNotEmpty; i++) {
      final pick = extras[orderRng.nextInt(extras.length)];
      out.add(_archetypeToSnapshot(pick, out.length, factionTag));
    }
    return out;
  }

  static EnemySnapshot _archetypeToSnapshot(
    EnemyArchetype a,
    int instanceIndex,
    String? factionTag,
  ) {
    return EnemySnapshot(
      archetypeId: a.id,
      instanceId: '${a.id}#$instanceIndex',
      name: a.name,
      role: a.role,
      tier: a.tier,
      str: a.baseStr,
      int_: a.baseInt,
      vit: a.baseVit,
      agi: a.baseAgi,
      hp: a.baseHp,
      attack: a.baseAttack,
      defense: a.baseDefense,
      skillIds: List<String>.from(a.skillIds),
      behaviorPattern: a.behaviorPattern,
      factionTag: factionTag,
      positionRow: _resolvePositionRow(a.role),
      positionIndex: 0,
      formationGroupId: 'g0',
      enemyKeywordKey: a.enemyKeywordKey,
    );
  }
}

// ============================================================================
// 내부 가변 상태 클래스
// ============================================================================

enum _Side { party, enemy }

class _StaticIndex {
  final Map<String, CombatSkill> skills;
  final Map<String, CombatStatusEffect> statusEffects;
  final List<CombatReportKeyword> toneKeywords;

  const _StaticIndex({
    required this.skills,
    required this.statusEffects,
    required this.toneKeywords,
  });

  factory _StaticIndex.build(StaticGameData staticData) {
    return _StaticIndex(
      skills: {for (final s in staticData.combatSkills) s.id: s},
      statusEffects: {for (final e in staticData.combatStatusEffects) e.id: e},
      toneKeywords: staticData.combatReportKeywords,
    );
  }
}

class _Phase1State {
  final int seed;
  final ActiveQuest quest;
  final QuestPool? pool;
  final List<_Combatant> partyState;
  final List<_Combatant> enemyState;
  final List<String> envTags;
  final int partyMorale;
  final int enemyMorale;
  final _Side? initiativeSide;
  final List<StatusEffectEvent> history;
  final _StaticIndex staticIndex;
  final List<CombatTurn> turns;
  final Map<String, int> decisiveScores;
  final Map<String, int> damageDealt;
  final List<CombatantSnapshot> combatantSnapshots;
  final List<EnemySnapshot> enemySnapshots;
  int killedEnemyCount;
  CombatExitCondition exitCondition = CombatExitCondition.dRoundLimit;
  int lastRoundIndex = 0;
  final Map<String, int> extraActionRoundStart = {};
  final Map<String, int> nextRoundExtraAction = {};

  _Phase1State({
    required this.seed,
    required this.quest,
    required this.pool,
    required this.partyState,
    required this.enemyState,
    required this.envTags,
    required this.partyMorale,
    required this.enemyMorale,
    required this.initiativeSide,
    required this.history,
    required this.staticIndex,
    required this.turns,
    required this.decisiveScores,
    required this.damageDealt,
    required this.killedEnemyCount,
    required this.combatantSnapshots,
    required this.enemySnapshots,
  });

  int get lastRoundIndexEstimate => lastRoundIndex < 1 ? 1 : lastRoundIndex;
}

class _Combatant {
  final String id;
  final String role;
  final int tier;
  final int level;
  final int str;
  final int int_;
  final int vit;
  final int agi;
  final int maxHp;
  int hp;
  final List<String> traitIds;
  final List<String> skillIds;
  PositionRow positionRow;
  int positionIndex;
  final bool isEnemy;
  final BehaviorPattern? behaviorPattern;
  final String enemyKind; // 'normal'/'elite'/'unique' or '' for party
  final DateTime? recruitedAt;
  bool injured = false;
  bool deceased = false;
  bool flagBattleFuryUsed = false;
  bool flagSummonUsed = false;
  bool isFirstInActionOrder = false;
  final List<_ActiveStatusEffect> statusEffects = [];
  final Map<String, int> cooldowns = {};
  final Map<String, int> usedCounts = {};

  _Combatant({
    required this.id,
    required this.role,
    required this.tier,
    required this.level,
    required this.str,
    required this.int_,
    required this.vit,
    required this.agi,
    required this.maxHp,
    required this.hp,
    required this.traitIds,
    required this.skillIds,
    required this.positionRow,
    required this.positionIndex,
    required this.isEnemy,
    this.behaviorPattern,
    this.enemyKind = '',
    this.recruitedAt,
  });

  bool get alive => !deceased && hp > 0;

  bool get hasMezStunned =>
      statusEffects.any((e) => e.effectId == 'mez_stunned');

  factory _Combatant.fromMerc(CombatantSnapshot s, Mercenary? merc) {
    final vitCoef = CombatSimulatorConstants.roleVitCoef[s.role] ?? 4.0;
    final hpFlat = CombatSimulatorConstants.roleHpFlat[s.role] ?? 20;
    final maxHp = (s.effectiveVit * vitCoef).round() + hpFlat;
    return _Combatant(
      id: s.mercId,
      role: s.role,
      tier: s.tier,
      level: s.level,
      str: s.effectiveStr,
      int_: s.effectiveInt,
      vit: s.effectiveVit,
      agi: s.effectiveAgi,
      maxHp: maxHp,
      hp: maxHp,
      traitIds: s.traitIds,
      skillIds: const [],
      positionRow: s.positionRow,
      positionIndex: s.positionIndex,
      isEnemy: false,
      recruitedAt: merc?.recruitedAt,
    );
  }

  factory _Combatant.fromEnemy(EnemySnapshot s) {
    return _Combatant(
      id: s.instanceId,
      role: s.role,
      tier: s.tier,
      level: s.tier,
      str: s.str,
      int_: s.int_,
      vit: s.vit,
      agi: s.agi,
      maxHp: s.hp,
      hp: s.hp,
      traitIds: const [],
      skillIds: List<String>.from(s.skillIds),
      positionRow: s.positionRow,
      positionIndex: s.positionIndex,
      isEnemy: true,
      behaviorPattern: s.behaviorPattern,
      enemyKind: 'normal',
    );
  }

  bool isChainProtagonist(_Phase1State state) {
    if (isEnemy) return false;
    if (!state.quest.isChainQuest) return false;
    final flagged = state.quest.specialFlags?['chain_protagonist_id'];
    return flagged is String && flagged == id;
  }
}

class _ActiveStatusEffect {
  final String effectId;
  double intensity;
  int durationTurns;
  int stack;
  final int appliedAtRound;

  _ActiveStatusEffect({
    required this.effectId,
    required this.intensity,
    required this.durationTurns,
    this.stack = 1,
    required this.appliedAtRound,
  });
}

class _ScoredCombatant {
  final _Combatant c;
  final int score;
  const _ScoredCombatant(this.c, this.score);
}
