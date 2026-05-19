# M8b QuestCompletionService 전투 시뮬레이터 통합 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1 — combatSimulationEligible 게이트·M8b 데이터 흐름·QuestResult 매핑·fallback 정책)
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3 — 사망 저항·체인 주인공 90% 상한)
> - `Docs/spec/[spec]20260519_m8b_combat_simulator.md` (페이즈 4 #1 — `CombatSimulator.simulate()` 시그니처와 출력 계약)
> - `Docs/spec/[spec]20260519_m8b_phase4_models.md` (페이즈 4 #2 — `CombatSimulationResult` 13 필드 + `CombatReport` HiveField 8~14 확장)
> 관련 코드:
> - `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` (구현 완료)
> - `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` (수정 대상)
> - `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` `_completeQuest`/`_applyCompletionResult` (수정 대상)
> - `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart` (수정 대상 — `simulationResult` 인자 확장 + M8b 필드 최소 임베드)
> 작성일: 2026-05-19
> 마일스톤: M8b 페이즈 4 #3 (QuestCompletionService 통합)

## 1. 개요

페이즈 4 #1에서 구현된 `CombatSimulator.simulate()`를 `QuestCompletionService.calculate()` 흐름에 통합한다. 일부 특별 의뢰(엘리트·체인 핵심/최종·지명·고급 트랙 세력)는 기존 `QuestCalculator` 성공률 해석 대신 4 페이즈 결정적 시뮬레이션 결과로 `QuestResult`/부상자/사망자를 산출하고, 그 결과 기반으로 보상·XP·명성·eliteLoot을 재계산한다. 일반 의뢰는 시뮬레이터를 호출하지 않고 기존 `QuestCalculator` 경로를 그대로 사용한다.

시뮬레이션 결과(`CombatSimulationResult`)는 이미 페이즈 4 #2에서 확장된 `CombatReport.HiveField 8~14` 필드로 분해 임베드한다. 본 명세는 도메인 통합, 최소 영속 매핑, 데이터 변환에 집중한다. 보고서 상세 문장 생성과 UI 표시는 페이즈 4 #4 명세에서 다룬다.

본 명세는 다음을 명시한다:
- `QuestCompletionService.calculate()` 시그니처 1 인자 추가(`regionState`)와 내부 흐름 7단계 재구성
- `QuestCompletionResult` 2 필드 추가(`combatSimulationEligible: bool` + `simulationResult: CombatSimulationResult?`)
- `combatSimulationEligible` 판정 정책 (페이즈 1 #1 §적용 범위 표 그대로 코드화)
- 시뮬레이션 결과 → `MercDamageResult` 변환 알고리즘 (legendary ⑤ 다운그레이드 호환 포함)
- `CombatReportService.generate()` 시그니처 1 인자 추가(`simulationResult: CombatSimulationResult?`) + `CombatReport` 확장 필드 최소 임베드
- 체인 주인공 사망 저항 90% 상한을 활성화하기 위한 `chain_protagonist_id` 전달 경로
- 시뮬레이션 결과와 기존 위업/지역 상태 훅의 성공 조건 정합성 보정
- fail-soft fallback 5종

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.1 `QuestCompletionService.calculate()` 시그니처 확장

- **[FR-1]** `calculate()` 정적 메서드의 named 인자 1개를 추가한다.
  - 추가 인자: `RegionState? regionState = null`
  - 위치: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` line 97~122
  - 기존 인자는 모두 유지한다(`quest`/`mercs`/`staticData`/`playerRegion`/`facilities`/`speedMultiplier`/`random`/`passiveEffects`/`partyEquipmentBonuses`/`legendaryEffects`/`mercCooldowns`/`eliteLootEntries`/`isChainStep`/`templateEngine`/`userData`/`factionStates`/`sectorChanges`/`currentTrustLevel`/`currentInfraTier`).
  - default `null`이므로 기존 호출 측 영향 없음. `quest_provider._completeQuest`는 명시적으로 `regionStateRepositoryProvider.getState(quest.region)` 결과를 전달한다(아래 [FR-12]).

#### 2.1.2 `QuestCompletionResult` 필드 확장

- **[FR-2]** `QuestCompletionResult` 클래스에 2개 final 필드를 추가한다(`band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` line 62~94).
  ```dart
  // M8b 페이즈 4 #3 추가
  final bool combatSimulationEligible;
  final CombatSimulationResult? simulationResult;
  ```
  - 생성자 named 인자 추가: `this.combatSimulationEligible = false`, `this.simulationResult`(nullable, default null).
  - 기존 `combatReportEligible: bool` 필드 패턴과 동일한 default false 정책을 유지한다.
  - `simulationResult`는 nullable이므로 일반 의뢰·fallback·페이즈 4 #2 모델 미시드 환경에서 자연히 null이다.

#### 2.1.3 `combatSimulationEligible` 판정 정책

- **[FR-3]** `calculate()` 내부에서 다음 평가식을 사용한다. 평가는 pool/difficulty/questType 추출 직후, 기존 성공률 roll 수행 전(아래 [FR-4] 단계 2)에 1회 수행한다.
  ```text
  combatSimulationEligible =
        quest.isElite                                                       // 엘리트(일반·유니크) 의뢰
     || (quest.isChainQuest && _isChainSimulationStep(quest, staticData))   // 체인 핵심/최종 단계
     || (pool?.isNamed == true)                                             // 지명 의뢰 (M6 7행 + M8a 12행)
     || (quest.isFactionExclusive
         && (quest.isAdvancedTrack == true
             || _factionReputation(quest, factionStates) >= 31))            // 고급 트랙 세력 의뢰
  ```
- **[FR-3.1]** `_isChainSimulationStep(quest, staticData)`는 static private helper로 추가하며, `quest.isChainQuest && quest.chainId != null`을 전제로 다음 분기 결과를 반환한다.
  - **체인 최종 단계**: `quest.chainStep + 1 == staticData.chainQuests.where(c => c.chainId == quest.chainId).fold(0, (max, c) => c.totalSteps > max ? c.totalSteps : max)` (CombatReportService._isChainFinalStep과 동일 식).
  - **체인 핵심 단계**: M8b MVP는 `quest.specialFlags?['chain_core_step'] == true` 플래그를 우선 평가하고, 플래그 부재 시 `quest.isElite || quest.eliteId != null` (체인 단계 중 엘리트 동반)을 보조 조건으로 평가한다. 둘 다 거짓이면 false.
  - 일반 체인 단계(거점 사건 포함)는 본 시뮬레이션 게이트에서 제외한다(페이즈 1 #1 §적용 범위 「연계 퀘스트 최종 단계 + 핵심 단계」와 정합).
  - **[Q-1]** 「체인 핵심 단계」의 데이터 식별 방식은 본 명세에서 `chain_core_step` 플래그를 우선 채택한다. M8b 출시 전 `chain_quests` 시드에 해당 플래그 운영 여부는 페이즈 4 #5 검증 단계에서 결정한다. 부재 시 보조 조건(엘리트 동반)으로 fail-soft.
- **[FR-3.2]** `_factionReputation(quest, factionStates)`는 static private helper로 추가하며, `quest.factionTag == null` 시 0 반환, non-null 시 `factionStates.where((s) => s.factionId == quest.factionTag).firstOrNull?.currentReputation ?? 0`. `CombatReportService._resolveImportance` line 197~211과 동일 로직.
- **[FR-3.3]** 더스트빌 허드렛일·일반 의뢰·세력 기본 트랙(평판 11~30 + `isAdvancedTrack != true`)은 모두 false. 페이즈 1 #1 §「보고서 대상이면서 시뮬레이션 비대상」 표와 정합.
- **[FR-3.4]** 평가 결과는 `combatSimulationEligible` 지역 변수에 저장하고, 이후 [FR-2]의 result 인스턴스 생성 시 그대로 필드에 매핑한다.
- **[FR-3.5]** `combatReportEligible` 평가는 기존 조건에 `combatSimulationEligible`을 OR로 추가한다. 시뮬레이션이 실행된 결과는 반드시 `CombatReport`에 저장되어야 하므로, `combatSimulationEligible == true`인데 `combatReportEligible == false`인 조합을 허용하지 않는다.
  ```text
  combatReportEligible = existingCombatReportEligible || combatSimulationEligible
  ```

#### 2.1.4 `CombatSimulator` 호출과 결과 적용

- **[FR-4]** `calculate()` 내부 흐름을 다음 7단계로 재구성한다. 단계 표시는 line 번호가 아닌 논리적 순서.
  1. **선행 데이터 추출** (기존 line 123~141 유지) — pool 조회 / partyPower / difficulty / questType / distancePenalty.
  2. **시뮬레이션 eligible 판정** — [FR-3] 평가 후 `combatSimulationEligible` bool 결정.
  3. **시뮬레이션 호출**:
     ```dart
     CombatSimulationResult? simulationResult;
     if (combatSimulationEligible && userData != null) {
       try {
         simulationResult = CombatSimulator.simulate(
           quest: quest,
           partyMercs: mercs,
           pool: pool,
           staticData: staticData,
           userData: userData,
           factionStates: factionStates,
           regionState: regionState,
           partyEquipmentBonuses: partyEquipmentBonuses,
         );
       } catch (e, st) {
         debugPrint('[BOM][CombatSimulator] simulate throw: $e\n$st');
         simulationResult = null;
       }
     }
     ```
     - `combatSimulationEligible == true && userData == null`이면 `simulationResult = null`로 두고 기존 `QuestCalculator` 경로로 fallback한다.
     - `seed` 인자는 운영 호출에서 미전달한다(테스트에서만 override). `CombatSimulator`가 내부에서 `stableSeed32('${quest.startTime!.toUtc().microsecondsSinceEpoch}|${quest.id}')`로 결정성을 보장한다(페이즈 4 #1 [FR-6] §1).
  4. **resultType 결정 분기**:
     - `simulationResult != null` → `resultType = simulationResult.questResult` (override). 기존 line 175~191의 `random.nextDouble() * 100` + `LegendaryResultUpgrade` 분기는 **건너뛴다**(시뮬레이션이 결정한 resultType은 final).
     - `simulationResult == null` → 기존 line 158~191 경로 그대로 수행 (성공률 → roll → `LegendaryResultUpgrade` 적용).
  5. **보상/XP/명성/eliteLoot 계산** — [FR-5]~[FR-7] 정책. 결정된 `resultType` 단일 변수 기반.
  6. **mercDamages 변환** — [FR-8]. `simulationResult != null`이면 시뮬레이션 결과 기반, 아니면 기존 line 335~436 경로.
  7. **`QuestCompletionResult` 인스턴스 반환** — [FR-2]에서 추가한 `combatSimulationEligible`/`simulationResult` 필드 포함.

#### 2.1.5 보상/XP/명성/eliteLoot 재계산 정책

- **[FR-5]** 보상 계산(line 193~252)은 결정된 `resultType` 기반으로 무수정 재사용한다. `simulationResult != null`인 경우에도 다음을 그대로 적용:
  - `passiveRewardBonus` / `trackBonus` / `QuestCalculator.calculateReward(...)`
  - `quest.questPoolId == 'dustvile_chore_03'` 채집 의뢰 배수 (M8b 시뮬레이션 대상 아님, 영향 없음)
  - `pool.isNamed` 시 `named_reward_multiplier` 적용 (line 232~238)
  - `pool.isFixed` 시 `rewardGoldOverride`
  - `mercTiers` 기반 `totalWage` 계산
- **[FR-6]** XP/명성 계산(line 254~297)도 동일하게 결정된 `resultType` 기반으로 재사용한다.
  - `xpMultiplier = ExperienceService.resultMultiplier(resultType)`
  - 시설 보너스(`training`) / 패시브 / `LegendaryRewardBonus`
  - `pool.isFixed` 시 `rewardXpBonusOverride`
  - `repGain` 계산 (성공/대성공만)과 `pool.isNamed` 시 `named_reputation_multiplier`
- **[FR-7]** `eliteLoot` 계산(line 484~491)도 결정된 `resultType` 기반으로 재사용한다. `simulationResult != null`이고 `quest.isElite`인 경우 시뮬레이션이 `criticalFailure`로 종결되면 드랍 없음, 그 외에는 `EliteLootService.rollDrops`가 `random` 인스턴스로 정상 롤한다(`calculate`의 `random: Random` 인자 그대로 사용).
- **[FR-7.1]** `factionRepGain`(line 439~470) — `simulationResult != null` / null 모두 동일 로직. `quest.specialFlags['faction_named']` 기반 분기 + 기본 세력 태그 의뢰 분기 그대로.
- **[FR-7.2]** `renderedNarrative`(line 493~506) — `templateEngine`/`userData` 모두 non-null인 경우 기존 그대로 수행. 시뮬레이션 활성과 무관.
- **[FR-7.3]** `settlementTrustGain`(line 509~518) — region 3 일반 의뢰 한정. 조건에 `pool?.isNamed != true`를 추가해 지명 의뢰는 일반 신뢰도 반복 보상에서 제외한다. 따라서 `simulationResult`가 null인 일반 의뢰에서만 양수 가능하다.

#### 2.1.6 mercDamages 변환 + legendary ⑤ 다운그레이드 호환

- **[FR-8]** `simulationResult != null`인 경우 기존 line 335~436 데미지 계산 루프를 다음 변환 알고리즘으로 대체한다:
  1. `injuredSet = simulationResult.injuredMercIds.toSet()`
  2. `deceasedSet = simulationResult.deceasedMercIds.toSet()`
  3. `mercDamages = <MercDamageResult>[]` 빈 리스트 준비.
  4. `now = DateTime.now()` (한 번만).
  5. `effectiveRecoveryReduction` / `passiveRecoveryMultiplier`는 기존 line 300~329 헬퍼 추출을 통해 동일하게 계산(infirmary / `recovery_time_multiplier` 패시브). 이 두 값은 시뮬레이션 결과 적용 분기에도 그대로 사용한다.
  6. 각 `merc in mercs`에 대해 다음 분기:
     - **case a) `deceasedSet.contains(merc.id)`** — 사망 마킹:
       1. legendary ⑤ 평가: `special = legendaryEffects.whereType<LegendarySpecial>().firstOrNull` / `cooldownUntil = mercCooldowns[merc.id]` / `canPrevent = special != null && (cooldownUntil == null || now.isAfter(cooldownUntil))`.
       2. `canPrevent == true`이면 기존 line 354~384 동일 패턴으로 `MercDamageResult(newStatus: MercenaryStatus.injured, recoveryEndTime: ..., legendaryPreventedDeath: true, newCooldownUntil: now.add(Duration(hours: special.cooldownHours)))`. `damageRoll`은 시뮬레이션 결과를 의미 있게 표현할 1.0 단일 값으로 고정(기존 random.nextDouble() 의미와는 다름, M8b MVP 단순화). 자세한 노출은 페이즈 4 #4 UI 명세.
       3. `canPrevent == false`이면 `MercDamageResult(newStatus: MercenaryStatus.dead, damageRoll: 1.0, recoveryEndTime: null)`.
     - **case b) `injuredSet.contains(merc.id)`** — 부상 마킹:
       1. `MercDamageResult(newStatus: MercenaryStatus.injured, recoveryEndTime: now + Duration(seconds: adjustedRecoverySeconds), damageRoll: 0.5)`. `damageRoll = 0.5`는 부상 영역 중간값으로 고정(기존 `QuestCalculator.calculateDamage`의 `damageRoll < injuryRate` 의미 호환).
     - **case c) 그 외 (생존 + 부상 없음)** — `case resultType` 분기:
       1. `resultType ∈ {greatSuccess, success}` 또는 `criticalFailure/failure`이지만 simulation 결과에서 무사 → `MercDamageResult(newStatus: MercenaryStatus.tired, recoveryEndTime: now + Duration(seconds: tiredSeconds), damageRoll: 0.0)`. `tiredSeconds = (5 * 60 / speedMultiplier).round()` 기존 line 427과 동일.
  7. `adjustedRecoverySeconds` 산출식:
     ```text
     baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMultiplier).round()
     adjustedRecoverySeconds = (baseRecoverySeconds
                                × (1.0 - recoveryReduction)
                                × passiveRecoveryMultiplier).round()
     ```
     - 기존 line 365~370 / 401~406과 동일.
- **[FR-8.1]** 변환 알고리즘은 `_convertSimulationToMercDamages(...)` static private helper로 분리한다(기존 데미지 루프 가독성 보존). 시그니처:
  ```dart
  static List<MercDamageResult> _convertSimulationToMercDamages({
    required CombatSimulationResult simulationResult,
    required List<Mercenary> mercs,
    required Difficulty difficulty,
    required double speedMultiplier,
    required QuestResult resultType,
    required double recoveryReduction,
    required double passiveRecoveryMultiplier,
    required List<LegendaryEffect> legendaryEffects,
    required Map<String, DateTime?> mercCooldowns,
    required DateTime now,
  });
  ```
- **[FR-8.2]** `simulationResult == null` 경로는 기존 line 335~436 데미지 루프를 그대로 유지한다. 단, `effectiveInjuryRate` 계산 / `effectiveDeathRate` 계산도 본 명세에서 동일하게 보존한다(isChainStep × 0.5 / passive injury_rate_multiplier).
- **[FR-8.3]** 변환 알고리즘이 처리하지 않는 케이스:
  - 시뮬레이션 결과가 `failure`인데 simulation의 `injuredMercIds`/`deceasedMercIds`가 모두 빈 경우 → 모든 mercenary가 case c (tired) 처리. (페이즈 1 #1 §종료 조건 (e) 도주 → 실패, 부상자 없음 케이스와 정합.)
  - 시뮬레이션 결과가 `greatSuccess`인데 injured가 있는 경우 → injured는 case b 처리, 나머지는 case c (tired). (페이즈 1 #1 §QuestResult 매핑 표 「적 진영 전멸 + 부상자 0~1 → 대성공」 케이스 호환.)

#### 2.1.7 `simulationResult` 영속 위치

- **[FR-9]** 시뮬레이션 결과 영속은 `_applyCompletionResult`(`quest_provider.dart` line 875~914)에서 `QuestCompletionResult.simulationResult`를 `CombatReportService.generate(simulationResult:)`로 전달하고, 반환된 `CombatReport`를 기존 trailing(`quest.combatReport = report` / `quest.save()`)으로 저장하는 방식으로 처리한다.
  - `simulationResult != null`이면 `CombatReport`는 반드시 `schemaVersion = 1`과 `CombatReport.HiveField 8~14` 최소 매핑을 포함해야 한다.
  - 최소 매핑은 다음과 같다: `combatantSnapshots = simulationResult.combatantSnapshots`, `turns = simulationResult.turns`, `exitCondition = simulationResult.exitCondition`, `objectiveProgress = simulationResult.objectiveProgress`, `enemySnapshots = simulationResult.enemySnapshots`, `statusEffectHistory = simulationResult.statusEffectHistory`.
  - `simulationResult == null`이면 기존 M8a 보고서 경로를 유지하고 신규 필드는 null로 둔다.
- **[FR-9.1]** 본 명세는 시뮬레이션 결과의 **저장 가능한 구조 필드**를 페이즈 4 #3에서 즉시 채운다. 페이즈 4 #4는 저장된 구조 필드를 어떻게 요약·상세 문장과 UI로 노출할지만 결정한다. 이 경계를 지켜야 페이즈 4 #3 이후 완료된 의뢰의 시뮬레이션 결과가 후속 UI 작업 전에 유실되지 않는다.
- **[FR-9.2]** `CombatReportService.generate(simulationResult: non-null)`는 템플릿 선택 실패 또는 `protagonistMercId == null`이어도 가능하면 null을 반환하지 않는다. 최소 fallback 보고서를 만들어 `schemaVersion = 1`과 구조 필드를 저장한다. fallback 문장은 짧은 일반 문장으로 충분하며, 고급 라인 구성은 페이즈 4 #4에서 보강한다.

#### 2.1.8 `CombatReportService.generate()` 시그니처 확장과 최소 임베드

- **[FR-10]** `CombatReportService.generate()`에 named optional 인자 1개를 추가한다(`combat_report_service.dart` line 27~38).
  ```dart
  static CombatReport? generate({
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    required QuestResult resultType,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    required TemplateEngine templateEngine,
    RegionState? regionState,
    Map<String, String>? sectorChanges,
    int? seed,
    CombatSimulationResult? simulationResult,           // M8b 페이즈 4 #3 추가
  }) { ... }
  ```
  - default `null`이므로 기존 M8a MVP 호출 측 영향 없음(`simulationResult == null` 분기는 기존 경로).
  - `simulationResult != null`이면 반환 `CombatReport`에 [FR-9]의 최소 매핑을 반드시 채운다.
  - `protagonistMercId`는 `simulationResult.protagonistMercId`를 우선 사용하고, null이면 기존 `QuestNarrativeService.pickProtagonist` 결과로 fallback한다.
  - `featuredMercIds`는 `simulationResult.featuredMercIds`를 우선 사용하되, 비어 있으면 기존 protagonist/ally dedup 결과를 사용한다.
  - `toneTags`는 기존 템플릿 tagSet과 `simulationResult.toneTags`를 합쳐 dedup한다.
- **[FR-10.1]** 페이즈 4 #4가 본 시그니처를 받아 다음과 같이 문장 생성과 표시를 확장한다:
  - `simulationResult == null`: 기존 M8a MVP 경로(line 47~155). `protagonist`/`enemyName`/`toneTags`/`summary`/`details` 모두 템플릿 가중 random 기반.
  - `simulationResult != null`: 시뮬레이터가 결정한 라운드 로그·결정적 장면 액션 기반으로 `summary`/`details` 라인을 개선한다. 단, 구조 필드 저장 자체는 본 명세 [FR-9]에서 완료한다.

#### 2.1.9 fallback 정책

- **[FR-11]** `CombatSimulator.simulate()`가 null 또는 throw를 반환하는 5가지 fail-soft 경로를 본 명세에서 통합 처리한다.
  1. **`combatSimulationEligible == false`** (일반 의뢰): 시뮬레이션 호출 자체를 하지 않음. 기존 `QuestCalculator` 경로.
  2. **`userData == null`** ([FR-4] §3): `simulationResult = null` 강제. `calculate()` 내부에서 userData가 null인 케이스는 페이즈 4 #1 명세 §2.1.1 [FR-2] 시그니처상 unreachable이나 안전 가드로 명시.
  3. **`CombatSimulator.simulate()` 반환값 null** (페이즈 4 #1 [FR-20]): 정적 데이터(`combatSkills`/`combatStatusEffects`/`enemyArchetypes`) 부재 또는 적 그룹 구성 실패. `simulationResult = null`. 기존 `QuestCalculator` 경로로 fallback.
  4. **`CombatSimulator.simulate()` throw**: try/catch로 `debugPrint('[BOM][CombatSimulator] simulate throw: ...')` 후 `simulationResult = null`. `QuestCalculator` 경로로 fallback.
  5. **`quest.startTime == null`**: 페이즈 4 #1 명세 §4.3 엣지 케이스에서 `simulate()` 내부가 null 반환. case 3과 동일.
- **[FR-11.1]** fallback 발생 시 `combatSimulationEligible`은 그대로 true로 유지(판정 자체가 거짓이 된 것이 아니라 실행이 실패한 것). 사용자가 결과 화면에서 시뮬레이션이 활성화될 의도였음을 추적할 수 있도록 명시 보존. 페이즈 4 #5 검증·디버그에 사용.
- **[FR-11.2]** fallback 발생 시 `simulationResult` 필드는 null이므로 `_applyCompletionResult`에서 `CombatReportService.generate(simulationResult: null)`이 호출되어 기존 M8a MVP 경로가 자연 적용된다.

#### 2.1.10 `quest_provider._completeQuest` / `_applyCompletionResult` 통합 포인트

- **[FR-12]** `quest_provider._completeQuest` (line 700 전후 ~ 850)에서 `QuestCompletionService.calculate(...)` 호출(line 808~837)에 `regionState` 인자를 추가한다.
  ```dart
  final questRegionState = ref
      .read(regionStateRepositoryProvider)
      .getState(quest.region);
  final result = QuestCompletionService.calculate(
    quest: quest,
    mercs: mercs,
    // ... 기존 17개 인자 유지 ...
    sectorChanges: questRegionState?.sectorChanges,
    regionState: questRegionState,              // M8b 페이즈 4 #3 추가
  );
  ```
- **[FR-12.1]** 체인 주인공 사망 저항을 활성화하기 위해 `_completeQuest`는 `QuestCompletionService.calculate(...)` 호출 전에 non-settlement chain의 `ChainQuestProgress.protagonistMercId`를 `quest.specialFlags['chain_protagonist_id']`에 병합한다.
  - 조회 경로: `ref.read(chainQuestRepositoryProvider).get(quest.chainId!)?.protagonistMercId`.
  - 조건: `quest.isChainQuest == true`, `quest.isSettlementStep == false`, `quest.chainId != null`, `protagonistMercId != null`.
  - 병합 방식: `quest.specialFlags = {...?quest.specialFlags, 'chain_protagonist_id': protagonistMercId}`. 저장은 필수 아님. 완료 계산 중 `CombatSimulator`에 전달되는 런타임 컨텍스트면 충분하다.
  - 기존 `chain_core_step` 플래그가 있으면 함께 보존한다.
- **[FR-13]** `_applyCompletionResult`(line 852~914)에서 `CombatReportService.generate(...)` 호출(line 889~899)에 `simulationResult: result.simulationResult` 인자를 추가한다.
  ```dart
  final report = CombatReportService.generate(
    quest: quest,
    partyMercs: partyMercs,
    resultType: result.resultType,
    staticData: staticData,
    userData: userData,
    factionStates: factionStates,
    templateEngine: ref.read(templateEngineProvider),
    regionState: regionState,
    sectorChanges: regionState?.sectorChanges,
    simulationResult: result.simulationResult,    // M8b 페이즈 4 #3 추가
  );
  ```
- **[FR-14]** `_applyCompletionResult`의 mercDamages 적용 루프(line 1067~1164) / 재료 드랍(line 1033~1065) / XP·트레잇(line 1166~)은 기존 경로를 유지한다. 단, 엘리트 유니크 첫 처치 위업 hook(line 955~1001)과 엘리트 region_state trailing(line 1003~1031)은 [FR-15]의 성공 조건을 추가한다.
  - 사망 memorial hook (line 1090~1128): `damage.newStatus == MercenaryStatus.dead` 분기는 시뮬레이션 결과 적용 후에도 자연 동작.
  - flagship 자동 복귀 (line 1113~1120) / 지명 의뢰 자동 종료 (line 1122~1126) 동일.
  - status hook (line 1136~1156, `damage.newStatus == MercenaryStatus.injured`) 동일.
  - 전설 ⑤ 쿨다운 기록 (line 1158~1163) — `damage.legendaryPreventedDeath`가 [FR-8] case a §2에서 true로 설정되면 자연 발화.

#### 2.1.11 위업/칭호/지역 상태 trailing hook 호환

- **[FR-15]** 페이즈 4 #1 §6 (엘리트 유니크 첫 처치 위업 / 체인 완주 위업 / 사망 memorial / 부상 status hook)은 `_applyCompletionResult`에서 다음 조건으로 호환된다.
  - **엘리트 유니크 첫 처치 위업** (line 955~1001): `quest.eliteId != null && eliteData.isUnique && result.resultType ∈ {success, greatSuccess}`일 때만 grant한다. 실패/대실패에서 "첫 처치" 위업이 발급되면 시뮬레이션 결과와 서사가 충돌하므로 본 명세에서 성공 조건을 추가한다.
  - **엘리트 region_state trailing** (line 1003~1031, `eliteRegionStateMapping`): `eliteData.isUnique && result.resultType ∈ {success, greatSuccess}`일 때만 flag toggle/dangerScore를 적용한다. 실패한 유니크 전투가 지역 안정화 플래그를 여는 것을 방지한다.
  - **사망 memorial hook** (line 1090~1112): `damage.newStatus == MercenaryStatus.dead` 자연 호환.
  - **flagship 자동 복귀** (line 1113~1120) / **지명 의뢰 자동 종료** (line 1122~1126): 동일.
  - **부상 status hook** (line 1136~1156, M6 페이즈 4 #2): `damage.newStatus == MercenaryStatus.injured` 기반, `injuredMercIds` 변환 결과로 자연 동작.
- **[FR-15.1]** 페이즈 4 #2 §2.1 (`CombatReport` HiveField 8~14 확장)의 신규 구조 필드는 본 명세 [FR-9]에서 직접 채운다. 페이즈 4 #4 UI 명세는 해당 필드의 표시·문장화 방식을 확장한다.
- **[FR-15.2]** 체인 완주 위업(`ChainQuestService.completeChain`) / 거점 사건 완주 위업은 `_applyCompletionResult` 외부 별도 trailing이므로 본 명세 무관.

### 2.2 데이터 요구사항

#### 신규/수정 모델

- `QuestCompletionResult` (`quest_completion_service.dart` line 62~94): 2 필드 추가 — `combatSimulationEligible: bool` / `simulationResult: CombatSimulationResult?`.
- `CombatReportService.generate()` 시그니처: `simulationResult: CombatSimulationResult?` named optional 인자 추가 + non-null 시 `CombatReport` 확장 필드 최소 임베드.

#### Hive 박스 변경

- 없음. 페이즈 4 #2에서 이미 `CombatReport`(typeId 21)에 HiveField 8~14 확장 + `CombatSimulationResult`(typeId 22) 등 그룹 B 모델 9종 어댑터 등록 완료.

#### Supabase 변경

- 없음. 페이즈 4 #2가 `combat_skills`/`combat_status_effects`/`enemies` 신규 3 테이블 + `combat_report_templates` 행 확장을 모두 수행.

#### import 추가

- `quest_completion_service.dart`:
  - `package:band_of_mercenaries/features/investigation/domain/region_state_model.dart` (RegionState)
  - `package:band_of_mercenaries/features/quest/domain/combat_simulator.dart` (CombatSimulator)
  - `package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart` (CombatSimulationResult)
- `combat_report_service.dart`:
  - `package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart` (CombatSimulationResult)
- `quest_provider.dart`:
  - 기존 import 변경 없음 (regionStateRepositoryProvider / CombatReportService / QuestCompletionService 모두 이미 import됨)

### 2.3 UI 요구사항

해당 없음. 본 명세는 도메인 통합·데이터 변환만 다룬다. 시뮬레이션 결과의 UI 표시는 페이즈 4 #4 명세에서 다룬다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | (a) `QuestCompletionResult` 2 필드 추가 (`combatSimulationEligible`, `simulationResult`). (b) `calculate()` 시그니처에 `regionState` 1 인자 추가. (c) 내부 흐름 7단계 재구성: pool 조회 → eligible 판정 → 시뮬레이션 호출 → resultType 분기 → 보상/XP/명성 재사용 → mercDamages 변환 → result 반환. (d) `combatReportEligible = 기존 조건 || combatSimulationEligible` 보장. (e) 지명 의뢰를 일반 신뢰도 반복 보상에서 제외. (f) `_isChainSimulationStep` / `_factionReputation` / `_convertSimulationToMercDamages` 3개 static private helper 추가. (g) RegionState/CombatSimulator/CombatSimulationResult 3 import 추가. | M8b 페이즈 4 #3 핵심 통합 |
| `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart` | `generate()` 시그니처에 `simulationResult: CombatSimulationResult?` named optional 인자 추가(default null). `simulationResult != null`이면 `schemaVersion = 1`과 HiveField 8~14 구조 필드를 채우며, 템플릿 실패 시 최소 fallback 보고서를 반환. CombatSimulationResult import 추가. | M8b 시뮬레이션 결과 영속화 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | (a) `_completeQuest`(line 808~837)의 `QuestCompletionService.calculate(...)` 호출에 `regionState` 인자 추가. (b) `_completeQuest`에서 `chain_protagonist_id` 런타임 플래그 병합. (c) `_applyCompletionResult`(line 889~899)의 `CombatReportService.generate(...)` 호출에 `simulationResult: result.simulationResult` 인자 추가. (d) 엘리트 유니크 첫 처치 위업 / 엘리트 region_state trailing에 성공·대성공 guard 추가. | 통합 진입점 + 영속/훅 정합성 보정 |

### 3.2 신규 생성 파일

없음. 페이즈 4 #1·#2가 신규 파일 모두 생성 완료.

### 3.3 코드 생성 필요 파일

없음. freezed/Hive 모델 변경 없음(필드 추가는 일반 Dart 클래스). `build_runner` 실행 불필요.

### 3.4 관련 시스템

- **CombatSimulator** (페이즈 4 #1): 본 명세의 진입점 호출 대상. 변경 없음.
- **CombatSimulationResult / CombatReport / CombatantSnapshot 등** (페이즈 4 #2): 본 명세의 데이터 모델. 변경 없음.
- **QuestCalculator**: fallback 경로의 성공률·데미지 계산. 변경 없음.
- **QuestCompletionService**: 본 명세의 핵심 수정 대상.
- **QuestProvider**: `_completeQuest`에 `regionState`/체인 주인공 컨텍스트를 추가하고, `_applyCompletionResult`에 `simulationResult` 전달과 엘리트 성공 조건 guard를 추가.
- **CombatReportService**: 시그니처 1 인자 확장 + `simulationResult` 구조 필드 최소 임베드. 문장 품질 확장은 페이즈 4 #4 위임.
- **AchievementService** (위업): 엘리트 유니크 첫 처치 hook은 성공·대성공 guard를 추가한다. 체인 완주 hook과 사망 memorial hook은 기존 경로를 유지한다.
- **TitleService** (M6): 부상 status hook / 행동 지표 hook / 위업 hook. 본 명세와 무관.
- **RegionStateRepository** (M7): 엘리트 region_state trailing(`eliteRegionStateMapping`)은 성공·대성공 guard를 추가한다. 일반 의뢰 완료 dangerScore 적용은 기존 경로를 유지한다.
- **ChainQuestService**: 체인 완주 → 위업 grant. 본 명세와 무관.
- **EliteLootService**: `EliteLootService.rollDrops` — `random` 인자 그대로 사용. 변경 없음.
- **PassiveBonusService / ExperienceService / ReputationService / HerbalistService**: 보상/XP/명성/채집 배수 계산. 변경 없음.
- **MercenaryRepository**: `mercDamages` 적용 시 `setDispatched`/`updateStatus`/`setLegendaryCooldown` 호출. 변경 없음.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `quest_completion_service.dart:62~94` — `QuestCompletionResult` 클래스. 추가 필드는 동일한 final + default 패턴.
- `quest_completion_service.dart:97~122` — `calculate()` named 인자 패턴. 새 인자는 default null로 추가.
- `quest_completion_service.dart:299~436` — 데미지 계산 루프. `_convertSimulationToMercDamages` helper의 case b / case c 변환 알고리즘은 line 394~425(injured/normal)와 동일 형태.
- `quest_completion_service.dart:350~393` — legendary ⑤ canPrevent 평가 패턴. [FR-8] case a §1~3에서 그대로 재사용.
- `quest_completion_service.dart:475~481` — `combatReportEligible` 평가 패턴. [FR-3.5]에 따라 기존 조건에 `combatSimulationEligible`을 OR로 추가한다.
- `quest_provider.dart:808~837` — `calculate()` 호출 패턴. `regionState` 전달 + `chain_protagonist_id` 런타임 플래그 병합.
- `quest_provider.dart:889~899` — `CombatReportService.generate()` 호출 패턴. `simulationResult` 인자 전달.
- `combat_report_service.dart:177~219` — `_resolveImportance` 「체인 최종 단계」 / 「세력 평판 ≥ 31」 평가 패턴. [FR-3] `_isChainSimulationStep` / `_factionReputation` helper도 동일 형태.
- `combat_report_service.dart:225~235` — `_isChainFinalStep` 정적 helper. 본 명세 `_isChainSimulationStep`도 동일 식 + chain_core_step 플래그 추가 분기.
- `combat_report_keyword.dart` — M8a 패턴(freezed + json_serializable). 본 명세에서 추가 없음.

### 4.2 주의사항

- **fail-soft 우선**: 시뮬레이터가 throw하거나 null 반환 시 반드시 `QuestCalculator` 경로로 fallback해야 한다. 게임이 멈추거나 사용자 경험이 손상되지 않도록 try/catch + debugPrint 가드를 [FR-4] §3과 [FR-11]에서 명시.
- **resultType override 시 boost 차단**: `simulationResult != null`이면 기존 line 181~191의 `LegendaryResultUpgrade` 분기는 건너뛴다. 시뮬레이션이 결정한 결과는 final. 「전설 ② 결과 승격」을 시뮬레이션에 통합하려면 페이즈 4 #5 검증 단계에서 검토.
- **`damageRoll` 의미 변경**: 기존 `damageRoll`은 random 0.0~1.0 (death/injury rate 비교용). 시뮬레이션 경로에서는 [FR-8] case a §2 = 1.0 / case b = 0.5 / case c = 0.0으로 의미 변경. 페이즈 4 #4 UI / 페이즈 4 #5 검증에서 이 점을 명시.
- **mercDamages 분기 일관성**: `simulationResult != null` 분기는 시뮬레이션 결과만 사용. 기존 `effectiveInjuryRate`/`effectiveDeathRate`/`isChainStep × 0.5` 등은 fallback 경로에서만 사용. 페이즈 4 #5 검증에서 두 경로의 부상/사망 분포를 비교 검증.
- **`combatSimulationEligible` 평가 비용**: chain_core_step 판정에 `staticData.chainQuests` fold 1회. M8b 출시 시 chain_quests 행수가 100 미만이므로 매 의뢰당 비용 무시 가능. 캐싱 불필요.
- **`regionState` 입력**: `regionStateRepositoryProvider.getState(quest.region)`이 null을 반환해도 `CombatSimulator.simulate()` 호출은 유지한다. 이 경우 지역 위험도·플래그·환경 보정 일부만 빠지고, 필수 정적 데이터가 있으면 시뮬레이션은 계속 가능해야 한다.
- **시뮬레이션과 `random` 인자 분리**: `calculate()`의 기존 `random: Random` 인자는 `QuestCalculator` fallback과 `eliteLoot` 드랍에 계속 사용. 시뮬레이션은 자체 `seed` 기반(`stableSeed32`) → 두 random은 독립.
- **`partyEquipmentBonuses` 일관 사용**: 본 명세는 `CombatSimulator.simulate()`에 `partyEquipmentBonuses`를 그대로 전달. 기존 `QuestCalculator.calculatePartyPower(equipmentBonuses: partyEquipmentBonuses)` 호출과 동일 객체 공유.

### 4.3 엣지 케이스

- **시뮬레이션 활성 의뢰가 chain 최종 단계 + criticalFailure**: 시뮬레이션 결과로 chain 진행 실패 분기. 보상 0, mercDamages 변환 결과 다수 사망 가능. memorial hook이 다수 발화. 페이즈 4 #5 검증에서 plurality 검증.
- **시뮬레이션 결과 모든 mercenary가 deceased**: legendary ⑤ 적용 후 일부 dead, 나머지 injured로 다운그레이드. `_applyCompletionResult`에서 flagship 자동 복귀가 다수 호출되어도 멱등.
- **`pool == null`인 경우** (시드 데이터 누락): `combatSimulationEligible` 평가의 `pool?.isNamed == true` 분기가 false 반환. 시뮬레이터 호출 자체가 차단되거나 다른 조건(엘리트/체인/세력)으로 활성. `CombatSimulator.simulate(pool: null)`은 페이즈 4 #1 [FR-7] §1~5 fallback 적 그룹 구성 사용.
- **`mercs.isEmpty`**: `partyPower`/`combatSimulationEligible`/시뮬레이션 모두 비정상. `CombatSimulator.simulate(partyMercs: [])`이 null 반환(페이즈 4 #1 [FR-2] §FR-20). `QuestCalculator` 경로 fallback도 mercDamages 빈 리스트.
- **시뮬레이션 결과 `injuredSet ∩ deceasedSet != ∅`** (논리적으로 발생 불가지만 가드): 변환 알고리즘 [FR-8] case a 우선 분기(deceased 먼저 평가). 페이즈 4 #1 명세상 두 집합은 서로소.
- **`quest.startTime == null`**: 페이즈 4 #1 [FR-6] §1 가드에서 null 반환. fallback.
- **`quest.combatReport != null`** (이미 생성됨): `_applyCompletionResult` line 875 `quest.combatReport == null` 가드. 시뮬레이션 호출 자체는 `_completeQuest` 1회 흐름이므로 중복 발생 어려움. 단, 재실행 시 보고서 미덮어쓰기 정책 유지(M8a 그대로).
- **`speedMultiplier == 0` 또는 음수**: 기존 코드에 가드 없음. M8b도 동일. `Duration(seconds: ...)` 계산이 무한대로 가는 케이스는 `SpeedMultiplierProvider`에서 사전 차단.

### 4.4 구현 힌트

- **진입점**: `quest_provider._completeQuest`(line ~700~850) → `QuestCompletionService.calculate(quest, ..., regionState: ...)`
- **데이터 흐름**:
  ```
  _completeQuest
    → partyEquipmentBonuses 수집 (EquipmentEffectContext.forParty)
    → legendaryEffects / mercCooldowns / passiveEffects 수집
    → QuestCompletionService.calculate(
         quest, mercs, staticData, ...,
         regionState: regionStateRepositoryProvider.getState(quest.region),
       )
         → 내부 분기:
           [eligible] CombatSimulator.simulate(...) → CombatSimulationResult? simResult
              → simResult != null: resultType/mercDamages 시뮬레이션 기반
              → simResult == null: QuestCalculator fallback
           [not eligible] QuestCalculator 기존 경로
         → QuestCompletionResult (combatSimulationEligible / simulationResult 포함)
    → _applyCompletionResult(quest, result, mercs, ...)
         → completeQuest 저장
         → renderedNarrative 저장
         → if (combatReportEligible)
             CombatReportService.generate(..., simulationResult: result.simulationResult)
              → simulationResult 분해 → CombatReport.HiveField 8~14 채움
             quest.combatReport = report; quest.save();
        → 골드/엘리트/위업/regionState/material/mercDamages 적용/XP/트레잇
           (엘리트 유니크 위업·region_state trailing은 성공/대성공 guard 추가)
  ```
- **참조 구현**:
  - `quest_completion_service.dart:62~94` — `QuestCompletionResult` 클래스(`combatReportEligible` 필드 위치)
  - `quest_completion_service.dart:127~141` — pool / partyPower / difficulty / questType 추출(시뮬레이션 호출 직전 단계)
  - `quest_completion_service.dart:299~436` — 기존 데미지 루프(fallback 경로 그대로 유지)
  - `quest_completion_service.dart:350~393` — legendary ⑤ canPrevent 평가 패턴(case a §1~3 참조)
  - `quest_completion_service.dart:472~481` — `combatReportEligible` 평가 패턴([FR-3.5] 새 평가식 참조)
  - `combat_simulator.dart:43~89` — `CombatSimulator.simulate()` public API
  - `combat_report_service.dart:225~235` — `_isChainFinalStep` helper(`_isChainSimulationStep` 참조)
  - `combat_report_service.dart:177~219` — `_resolveImportance`(`_factionReputation` 참조)
  - `quest_provider.dart:808~837` — `calculate()` 호출 컨텍스트
  - `quest_provider.dart:875~914` — `CombatReportService.generate()` 호출 컨텍스트
- **확장 지점**:
  - 페이즈 4 #4 UI: `CombatReport.schemaVersion == 1`과 구조 필드를 기준으로 `summary`/`details` 라인 품질 및 라운드 로그 표시를 확장.
  - 페이즈 4 #5 검증: 시뮬레이션 vs fallback의 부상/사망 분포 비교. chain_core_step 플래그 운영 여부 결정. `damageRoll` 의미 변경의 활동 로그 호환성 검증.
- **테스트 시드**: `CombatSimulator.simulate(seed: <임의>)`로 override해 결정성 테스트. `_isChainSimulationStep` / `_factionReputation` 단위 테스트(`combat_report_service.dart` 패턴).

## 5. 기획 확인 사항

- **[Q-1]** 「체인 핵심 단계」의 데이터 식별 방식 (페이즈 1 #1 §적용 범위 표 "연계 퀘스트 최종 단계 + 핵심 단계")
  → 처리 방향(본 명세 채택): **MVP에서 `quest.specialFlags['chain_core_step'] == true` 플래그 우선 + 보조 조건 「엘리트 동반」**. M8b 출시 전 `chain_quests` 시드에 해당 플래그 운영 여부는 페이즈 4 #5 검증 단계에서 결정. 플래그·보조 조건 모두 부재 시 false(체인 일반 단계는 시뮬레이션 대상 아님).

- **[Q-2]** 시뮬레이션 활성 의뢰의 `resultType` override 시 `LegendaryResultUpgrade` (전설 ② 결과 승격)을 시뮬레이션 결과에도 적용할지?
  → 처리 방향(본 명세 채택): **적용하지 않는다**. 시뮬레이션이 결정한 결과는 final. `LegendaryResultUpgrade`는 fallback(`QuestCalculator`) 경로의 random `resultType`에만 적용. M8b 시뮬레이션의 결정성을 보장하기 위함. 「시뮬레이션 결과에도 결과 승격 적용」 정책은 페이즈 4 #5 검증에서 재검토.

- **[Q-3]** 시뮬레이션 결과 `MercDamageResult.damageRoll` 필드의 의미를 어떻게 정의할지?
  → 처리 방향(본 명세 채택): **case a (deceased) = 1.0 / case b (injured) = 0.5 / case c (tired/normal) = 0.0**. 기존 `damageRoll`은 `QuestCalculator.calculateDamage`의 `random.nextDouble()` 결과(0.0~1.0)로 사망/부상/무사 분기 비교용. 시뮬레이션 경로에서는 시뮬레이터가 직접 결정했으므로 의미가 다르며, 위 매핑으로 단순화. `MercenaryStatService.updateStatsAfterQuest`가 `damageRoll`을 사용하는 부분은 페이즈 4 #5 검증에서 호환성 확인.

- **[Q-4]** 시뮬레이션 결과의 `recoveryEndTime` 산출에 시뮬레이션의 DoT 누적량을 반영할지?
  → 처리 방향(본 명세 채택): **반영하지 않는다**. 기존 공식(`difficulty.level × 10분 / speedMultiplier × (1.0 - recoveryReduction) × passiveRecoveryMultiplier`)을 그대로 사용. M8b MVP 단순화. DoT 누적량 반영은 페이즈 4 #5 검증에서 정밀화 검토. infirmary / field_hospital / `recovery_time_multiplier` 패시브는 시뮬레이션 경로에서도 동일 적용.

- **[Q-5]** 유니크 엘리트 의뢰에서 시뮬레이션 결과가 `failure` 또는 `criticalFailure`일 때 「엘리트 유니크 첫 처치 위업」을 grant할지?
  → 처리 방향(본 명세 채택): **grant하지 않는다**. `resultType ∈ {success, greatSuccess}`일 때만 위업과 엘리트 region_state trailing을 발화한다. 실패한 전투가 "처치"와 "지역 안정화"로 기록되는 것을 방지한다.

- **[Q-6]** `CombatReport.combatantSnapshots/turns/exitCondition/objectiveProgress/enemySnapshots/statusEffectHistory` 신규 필드(페이즈 4 #2)를 본 명세에서 직접 채울지, 페이즈 4 #4에서 처리할지?
  → 처리 방향(본 명세 채택): **본 명세에서 최소 임베드한다**. 페이즈 4 #4는 저장된 구조 필드를 읽어 표시 방식과 문장 품질을 확장한다.

- **[Q-7]** `CombatSimulator.simulate()`가 throw하는 경우 stacktrace 노출 정도?
  → 처리 방향(본 명세 채택): **`debugPrint` 1줄 + stacktrace**(`[BOM][CombatSimulator] simulate throw: $e\n$st`). 사용자에게는 fallback이 자연스럽게 적용되어 게임 흐름 영향 없음. `flutter analyze`의 `avoid_print` 규칙은 `debugPrint` 사용으로 충족.

- **[Q-8]** `combatSimulationEligible == true && simulationResult == null` 케이스의 활동 로그 표기?
  → 처리 방향(본 명세 채택): **활동 로그 미발화**. 사용자에게 시뮬레이션 실패를 노출하지 않는다(M8a `CombatReportService.generate` null fallback과 동일 정책). `debugPrint`만으로 개발자 추적 가능.

## 6. 검증 계획

구현 후 다음 검증을 수행한다. 각 항목은 verifier가 코드와 테스트 결과로 PASS/FAIL을 판정할 수 있어야 한다.

- `quest_completion_service_test.dart`: `combatSimulationEligible` 판정 케이스를 검증한다. 엘리트, 체인 최종, `chain_core_step`, M6/M8a 지명, 세력 고급 트랙은 true이고 일반 의뢰·더스트빌 허드렛일·세력 기본 트랙 평판 11~30은 false여야 한다.
- `quest_completion_service_test.dart`: `combatSimulationEligible == true`인 모든 케이스에서 `combatReportEligible == true`여야 한다. 특히 세력 기본 트랙이지만 평판 31 이상이라 시뮬레이션 대상이 된 케이스를 포함한다.
- `quest_completion_service_test.dart`: `CombatSimulator.simulate()`가 null을 반환하는 eligible 의뢰는 `combatSimulationEligible == true`, `simulationResult == null`을 유지하고 기존 `QuestCalculator` 결과 경로로 완료되어야 한다.
- `quest_completion_service_test.dart`: `simulationResult`가 있는 경우 `resultType`은 `simulationResult.questResult`와 동일하고, `LegendaryResultUpgrade`는 적용되지 않아야 한다.
- `quest_completion_service_test.dart`: region 3 지명 의뢰는 성공/대성공이어도 `settlementTrustGain == 0`이어야 한다.
- `quest_completion_service_test.dart`: `injuredMercIds`/`deceasedMercIds` → `MercDamageResult` 변환을 검증한다. deceased가 injured보다 우선하며, 전설 ⑤가 사용 가능하면 dead가 injured로 다운그레이드되고 `newCooldownUntil`이 설정되어야 한다.
- `combat_report_service_test.dart`: `simulationResult != null`이면 템플릿 선택 실패 상황에서도 `CombatReport`가 null이 아니며, `schemaVersion == 1`(HiveField 8)과 HiveField 9~14 구조 필드가 채워져야 한다.
- `quest_provider` 통합 테스트 또는 notifier 테스트: non-settlement chain 완료 계산 전에 `ChainQuestProgress.protagonistMercId`가 `quest.specialFlags['chain_protagonist_id']`로 병합되어야 한다.
- `quest_provider` 통합 테스트: 유니크 엘리트 실패/대실패에서는 `elite_unique_first_kill:*` 위업과 `eliteRegionStateMapping` trailing이 발화하지 않고, 성공/대성공에서는 기존처럼 발화해야 한다.
- 정적 검증: `cd band_of_mercenaries && flutter analyze`.
- 회귀 검증: `cd band_of_mercenaries && flutter test test/features/quest/domain/quest_completion_service_test.dart` 및 신규/수정한 보고서 서비스 테스트.

---

## 부록 A: 페이즈 1·2·4 산출물 ↔ 본 명세 매핑 표

| 페이즈 산출물 | 본 명세 반영 위치 |
|------------|---------------|
| 페이즈 1 #1 §적용 범위 표 (시뮬레이션 적용 대상 의뢰) | [FR-3] 평가식 |
| 페이즈 1 #1 §eligibility 평가 위치 (`combatSimulationEligible` 분리) | [FR-2] / [FR-3] |
| 페이즈 1 #1 §M8b 데이터 흐름 (시뮬레이션 → resultType/mercDamages override → 후속 처리) | [FR-4] 7단계 |
| 페이즈 1 #1 §QuestResult 매핑 표 | [FR-4] §4 (시뮬레이터가 결정, 본 명세는 override만) |
| 페이즈 1 #1 §fallback 정책 (try/catch + QuestCalculator) | [FR-11] 5종 |
| 페이즈 1 #1 §M8a 전투 보고서와의 연결 (`CombatReportService.generate(simulationResult:)`) | [FR-10] |
| 페이즈 1 #1 §featured / protagonist 일관성 (시뮬레이션 활성 시 우선) | [FR-9] / [FR-10] |
| 페이즈 1 #3 §사망 저항 클램프 / 체인 주인공 예외 | `CombatSimulator` 내부 처리 + [FR-12.1] `chain_protagonist_id` 전달 |
| 페이즈 4 #1 [FR-1]~[FR-3] 진입점/입력 계약 | [FR-4] §3 호출 인자 |
| 페이즈 4 #1 [FR-4] 출력 11 필드 | [FR-2] `simulationResult` 필드 |
| 페이즈 4 #1 [FR-5] injure/die 마킹만 | [FR-8] 변환 알고리즘 |
| 페이즈 4 #1 [FR-20] fail-soft | [FR-11] |
| 페이즈 4 #2 [FR-9.6] `CombatReport` HiveField 8~14 | [FR-9] / [FR-10] |
| 페이즈 4 #2 [FR-10] StaticGameData 3 컬렉션 | `CombatSimulator.simulate(staticData:)` 통해 자동 전달 |

## 부록 B: 명세 외 결정 사항 (페이즈 4 #5 검증·정밀화 위임)

1. 「체인 핵심 단계」의 `chain_core_step` 플래그 운영 여부 및 `chain_quests` 시드 데이터 결정
2. 시뮬레이션 활성 의뢰의 `LegendaryResultUpgrade` 적용 정책
3. 시뮬레이션 결과 `damageRoll` 의미 변경의 `MercenaryStatService.updateStatsAfterQuest` 호환성 검증
4. 부상자 `recoveryEndTime`에 시뮬레이션 DoT 누적량 반영 검토
5. 시뮬레이션 vs fallback의 부상/사망 분포 비교 검증 (밸런스)
6. `CombatReport.summary/details`의 시뮬레이션 기반 문장 품질 개선 (페이즈 4 #4 명세)
