# M8b CombatSimulator 순수 서비스 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1)
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2)
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3)
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4)
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1)
> - `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2)
> - `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md` (페이즈 2 #3)
> - `Docs/balance-design/[balance]20260519_m8b_combat_log_exposure.md` (페이즈 2 #4)
> 작성일: 2026-05-19
> 마일스톤: M8b 페이즈 4 #1 (CombatSimulator 순수 서비스)

## 1. 개요

M8b 전투 시뮬레이터의 **순수 도메인 서비스** `CombatSimulator`를 추가한다. `combatSimulationEligible` 의뢰가 완료될 때 파견 시작 시점 스냅샷을 동결한 결정적 시뮬레이션을 1회 실행하여 4 페이즈(사전·선제·일반 라운드·마무리)를 거친 결과로 `QuestResult`·라운드 로그·결정적 장면 기여자를 산출한다. 산출물은 `CombatSimulationResult`로 반환되며, M8a `CombatReport` 생성과 `Mercenary.injure/die` 호출의 입력이 된다.

본 명세는 순수 서비스 1개만 다루며, freezed/Hive 모델·`QuestCompletionService` 분기·UI 표시·테스트 케이스는 페이즈 4 #2~#5 별도 명세에서 다룬다.

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.1 진입점 / 입력 계약

- **[FR-1]** `CombatSimulator.simulate({...}) → CombatSimulationResult?` 정적 메서드를 제공한다.
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` (신규)
  - 정적 메서드, `ref` 의존 없음. M8a `CombatReportService` 패턴과 동일.
  - 실패 시 `null` 반환(fail-soft). 호출 측은 null → `QuestCalculator` 폴백.
- **[FR-2]** 입력 인자(named, required 기본):
  - `ActiveQuest quest`
  - `List<Mercenary> partyMercs` (파견 mercenary, dispatchedMercIds 순서)
  - `QuestPool? pool` (`pool.specialFlags`/`pool.isNamed`/`pool.factionTag` 참조)
  - `StaticGameData staticData` (페이즈 4 #2 모델 카탈로그 보유 — `combatSkills`/`combatStatusEffects`/`enemyArchetypes`/`combatReportKeywords`/`regions`/`difficulties`)
  - `UserData userData`
  - `List<FactionState> factionStates`
  - `RegionState? regionState`
  - `Map<String, EquipmentStatBonus> partyEquipmentBonuses = const {}` (mercId → 장비·정수 스탯 보정. 호출 측이 `EquipmentEffectContext.forPartySync` 또는 동등한 경로로 수집)
  - `int? seed` (테스트 오버라이드 전용. 운영 호출에서는 미전달)
- **[FR-3]** 적용 대상 의뢰 평가는 `QuestCompletionService`(페이즈 4 #3 명세)가 담당하며, `CombatSimulator.simulate`는 호출되면 무조건 시뮬레이션을 실행한다.
  - 본 서비스는 `combatSimulationEligible` 판정을 하지 않는다. 호출 측이 게이트한다.

#### 2.1.2 출력 계약 (`CombatSimulationResult`)

- **[FR-4]** 페이즈 1 #1 §CombatSimulationResult 데이터 형태를 그대로 채택한다. 11 필드:
  ```text
  CombatSimulationResult
  - questResult: QuestResult           // 기존 4단계 enum
  - turns: List<CombatTurn>            // 라운드별 압축 액션 시퀀스 (영속 대상)
  - protagonistMercId: String?
  - featuredMercIds: List<String>
  - injuredMercIds: List<String>       // Phase 4 일괄 적용 대상
  - deceasedMercIds: List<String>      // Phase 4 일괄 적용 대상
  - objectiveProgress: double          // 0.0~1.0
  - exitCondition: CombatExitCondition // (a)~(f) enum
  - statusEffectHistory: List<StatusEffectEvent>  // 시작·해제 이벤트
  - seed: int                          // 영속화·재현용
  - toneTags: List<String>             // M8a CombatReport 호환 (battlefield/enemy/decisive 키워드)
  ```
- **[FR-5]** `injuredMercIds`/`deceasedMercIds`는 **마킹만** 한다. 실제 `Mercenary.injure()`/`die()` 호출은 시뮬레이터가 직접 수행하지 않으며, 호출 측(`QuestCompletionService` 페이즈 4 #3)이 결과를 받아 적용한다.
  - 본 서비스는 부수효과 없는 순수 함수다 (단, `partyMercs`/`pool`/`regionState`는 read-only 입력).

#### 2.1.3 4 페이즈 알고리즘

- **[FR-6]** Phase 1 (사전 단계):
  1. `seed` 결정 — 미전달 시 `stableSeed32('${quest.startTime!.toUtc().microsecondsSinceEpoch}|${quest.id}')`. `DateTime.hashCode`/`String.hashCode` 사용 금지.
  2. 10개 PRNG 도메인 키 체계 준비([FR-12] 참조). 실제 `Random` 인스턴스는 액션·라운드·대상별로 생성한다.
  3. 파티 측 `CombatantSnapshot` 동결 — `partyMercs` 순회하며 `partyEquipmentBonuses[merc.id] ?? EquipmentStatBonus.zero`를 사용해 `Mercenary.effectiveStrWith/effectiveIntelligenceWith/effectiveVitWith/effectiveAgiWith(equipmentBonus)` 호출 결과를 캡처. `MercenaryStatus.tired` 시 `tiredDebuffMultiplier=0.8`이 자동 반영된다.
  4. 적 측 `EnemySnapshot` 동결 — `quest`/`pool`로부터 적 그룹 구성을 결정한다. 적 그룹 구성 규칙은 [FR-7]에 정의.
  5. 사기 계산 — 파티 평균 100 기본 + 직업군·트레잇·세력 패시브 ±20.
  6. 진형 자동 배치 — 양측 모두 `warrior/specialist→front, rogue/ranger→middle, mage/support→back`(페이즈 1 #2 §7.1). 빈 열은 다음 열로 압축.
  7. 환경 자동 부여 — `staticData.regions.firstWhere((r) => r.region == quest.region).environmentTags`에서 `regionEnvironmentTags`를 산출한다. `RegionState`에는 환경 태그 필드가 없으므로 직접 읽지 않는다. 매칭 실패 시 빈 리스트로 fail-soft 처리한다. 산출된 태그에 `mist_field`가 포함되면 적군 전원에 `debuff_accuracy_down`(intensity 0.10 / duration 2 / applyChance 1.0) 부여(페이즈 2 #3 §7.2).
  8. 트레잇 자동 부여 — 양측 mercenary/적의 `traitIds`를 키워드 매칭([FR-13] 참조)하여 본인에게 `buff_*` 부여(applyChance 1.0).
  9. 선제 점수 산출 — `sideInitiativeScore(side) = avg(effectiveAgi) + avg(roleInitiativeWeight) + traitInitiativeBonus + battlefieldInitiativeModifier + ambushBonus`(페이즈 1 #2 §2).
  10. 매복 보너스 — `pool.specialFlags['ambush_side']` 평가. `'enemy'` 시 `enemySideInitiativeScore += 20` / `'party'` 시 `partySideInitiativeScore += 20` / 둘 다 있는 경우 `'enemy'` 우선(데이터 이상치 가드). `deltaScore = partyScore - enemyScore`는 항상 동일 부호 계산.
  11. 선제 라운드 발동 판정 — `|deltaScore| >= 15`이면 우세 측이 Phase 2 진입, 아니면 Phase 3 직진. 우세 측 결정: `deltaScore >= 15` → 파티 / `deltaScore <= -15` → 적.

- **[FR-7]** 적 그룹 구성 규칙(결정성 보장):
  1. **archetype 후보 풀 선택** (우선순위):
     - `quest.eliteId` non-null + `EnemyArchetype.enemyKind == unique`: 매칭 unique 1 (인원 1로 고정) + 매칭 일반 0~3.
     - `quest.eliteId` non-null + `enemyKind == elite`: 매칭 elite 1 + 매칭 일반 1~3.
     - `pool.factionTag` 매칭(M8a 활성 8 세력): 페이즈 2 #2 §9.2 풀에서 `enemyKind == normal` 2~4 + `enemyKind == elite` 0~1.
     - 그 외(일반 의뢰 fallback): `regionEnvironmentTags`와 `EnemyArchetype.environmentTags` 교집합으로 normal 2~3 (교집합 0이면 환경 무시 fallback).
  2. **인원 수 산출**: `min~max` 범위 N에 대해 `enemyCount = orderRng.nextInt(max - min + 1) + min`. 단 unique 1, elite 1은 고정.
  3. **archetype 선택**: 후보 풀에서 균등 random (`orderRng.nextInt(pool.length)`). 같은 archetype 중복 허용(예: 도적 졸개 2명). 가중치 도입은 페이즈 4 #5 검증에서 결정.
  4. **사용 PRNG**: `orderRng = Random(seed ^ stableSeed32('group|$questId'))` 단일 인스턴스를 그룹 구성 직전 1회 생성하여 인원 수·archetype 선택에 순차 사용.
  5. **fail-soft 가드**:
     - 후보 풀이 비면 환경 태그 미적용 + 직업군 매칭만으로 재시도. 그래도 비면 `null` 반환(fallback 경로).
     - `EnemyArchetype.factionTags` / `QuestPool.enemyGroupId` 컬럼이 페이즈 4 #2에서 미정의 상태이면 위 §1 fallback 분기를 그대로 사용.
  6. **소환된 전투원의 진형 삽입 + 첫 행동 시점**:
     - `skill_enemy_summon` 발동 시 `EnemyArchetype.id` 후보 풀(스킬 정의에 명시된 `summon_template_id` 또는 본 카탈로그 일반 적 `enemy_bandit_thug`/`enemy_undead_*` fallback)에서 1~2명 생성.
     - 진형 빈 슬롯 채움 우선순위: 같은 row 우선 → row 가득 시 다음 row.
     - **소환된 전투원은 발동 라운드의 `actionScore` 정렬에 포함되지 않으며 다음 라운드부터 정렬 대상에 진입**(페이즈 1 #2 §3 라운드 시작 일괄 정렬 정합).
     - 소환된 전투원의 `behaviorPattern`은 archetype의 default를 그대로 사용. `skillIds`도 archetype default 사용(스킬 사용은 첫 행동 라운드부터 가능, 쿨다운은 첫 발동 라운드 = 0).
  - **[Q-1]** 적 그룹 구성의 정확한 매핑(quest_pool → enemyGroupId)은 페이즈 4 #2 모델 명세에서 `QuestPool.enemyGroupId` 또는 `EnemyArchetype.factionTags` 컬럼 추가 시점에 정밀화한다. 본 명세는 §1~5의 fallback 알고리즘만 정의한다.

- **[FR-8]** Phase 2 (선제 라운드, 0 또는 1회):
  1. 우세 측의 행동 슬롯 보유 전투원 전원이 [FR-9] §2~4를 한 번 수행한다.
  2. 상대 측 반격(`riposte`)은 발생할 수 있다(반격은 회피 성공 시 트리거이며 별개 액션이다).
  3. 종료 조건 (a)~(f) 평가 후 미충족 시 Phase 3로 진입.

- **[FR-9]** Phase 3 (일반 라운드 반복, 최대 8):
  1. **라운드 시작**: DoT `dot_poisoned` 각 대상 적용 — `damage = max(1, floor(intensity × 5 + level × 2))`. HP ≤ 0 도달 시 [FR-11.5] 사망 저항 롤로 부상/사망 마킹.
  2. **종료 조건 평가** (a)/(b) 즉시 체크 → 미충족 시 진행.
  3. **행동 순서 정렬** — 모든 생존 전투원에 대해 `actionScore` 계산 후 내림차순:
     ```
     actionScore = effectiveAgi
                 + roleActionWeight[role]
                 + traitActionBonus(traitIds)
                 + battlefieldActionModifier(role, environmentTags)
                 + (orderRngRound.nextInt(7) - 3)
     ```
     여기서 `orderRngRound = Random(seed ^ stableSeed32('order|$roundIndex|$combatantId'))`는 라운드·전투원별 새 인스턴스([FR-12] `orderRng` 도메인 키 형식). 동일 시드+라운드+전투원 → 동일 노이즈.
     동률 처리 4단(상위 → 하위 분기):
     1. 직업군 우선순위 `rogue > ranger > warrior > specialist > support > mage`
     2. tier desc
     3. 파티/적 통합 키 `stableSeed32(combatantId)` asc (mercenary id와 적 `EnemySnapshot.id`(= `archetypeId#instanceIndex`)를 동일 함수로 처리)
     4. 동률 잔존 시 `combatantId` 문자열 lexicographic asc (최종 폴백)
  4. **행동 실행** — 정렬 순서로 각 전투원 1회 행동.
     - `mez_stunned` 보유자는 `recordSkippedTurn(combatant)` 후 다음 전투원으로 넘어간다(회피·방어는 정상).
     - 파티 측: [FR-14] 자동 발동 결정 트리로 스킬/기본공격 선택. 폴백 시 기본공격.
     - 적 측: [FR-15] behaviorPattern 결정 트리로 스킬/기본공격 선택.
     - 표적 결정: [FR-16] 진형 표적 정책.
     - 액션 수행: [FR-11] 명중→회피→방패→피해→상태효과 부여→반격 시퀀스.
     - 다단 행동(광역/연속/추가): 페이즈 1 #2 §9. 행동 슬롯 1번만 소모, 회피·방패·반격은 대상별/타격별 독립 판정. 광역+연속 결합은 MVP 미사용.
     - **`extraAction` 발동 타이밍 분기**:
       - **반격 (`riposte` 회피 성공 후)**: 회피 직후 즉시 큐에 삽입 ([FR-11] §4).
       - **trigger 발동 스킬 (`battle_fury` 류, `CombatSkill.actionCost == extraAction`)**: 자기 행동 슬롯 직전 즉시 발동(`extraActionImmediateQueue`). 같은 라운드에 기본 행동 슬롯도 별도 사용 가능.
       - **트레잇 패시브 추가 행동 (`swift_strike` 류)**: 라운드 시작 시 1회 추가 슬롯 부여(`extraActionRoundStartQueue`). 정렬 후 자기 행동 직전 1회 삽입.
       - **다음 라운드 추가 행동 (`quick_step` 류 스킬 효과)**: `nextRoundExtraActionQueue: Map<combatantId, int>`(또는 페이즈 4 #2 모델 영속 필드)에 +1 누적 → 다음 라운드 시작 시 큐 소비.
     - **`extraAction` 정책**:
       - 추가 행동에서 또 다른 추가 행동 발생 금지(반격→반격 불가, 추가→추가 불가, 페이즈 1 #2 §9.3).
       - `mez_stunned` 보유자는 trigger/트레잇/스킬 추가 행동 차단. 반격(반응 행동)은 정상 수행(페이즈 1 #4 §6.5).
       - 모든 추가 행동도 [FR-11] 명중→회피→방패→치명타→피해→상태효과 부여 시퀀스를 거친다.
  5. **라운드 종료**:
     - DoT `dot_bleeding` 각 대상 적용 — `damage = max(1, floor(maxHp × 0.04 × stack))`. HP ≤ 0 도달 시 사망 저항 롤.
     - 모든 상태 효과 `durationTurns -= 1`. 0 도달 시 자연 해제 + `statusEffectHistory`에 `endEvent` 추가.
     - 종료 조건 (a)/(b)/(c)/(d)/(e)/(f) 평가.
       - (a) 파티 HP 합계 ≤ 0 → 대실패
       - (b) 적 진영 HP 합계 ≤ 0 → 대성공/성공(잔존 비율로 분기)
       - (c) 목표 진행도 100% (호위·탐험류) → 성공/대성공
       - (d) 8 라운드 도달 → 잔존 비율·목표 진행도로 분기
       - (e) 파티 사기 ≤ 25% + AGI 비례 회피 판정 통과 → 실패(부상 가능, 사망 불가)
       - (f) 호위 대상 사망(호위형 의뢰만) → 실패/대실패

- **[FR-10]** Phase 4 (마무리 판정):
  1. 라운드 시퀀스 → `QuestResult` 매핑(페이즈 1 #1 §QuestResult 매핑 표). 잔존 비율·부상자 수·objectiveProgress·exitCondition 결합.
  2. **결정적 장면 기여자 집계**:
     - 카운트 대상 액션 enum + 점수 가중치:
       | 액션 | 점수 |
       |------|------|
       | `kill` (적 처치) | 5 |
       | `criticalKill` (치명타로 적 처치) | 7 |
       | `crit` (치명타 발동) | 3 |
       | `shieldBlock` (방패 막기 성공) | 2 |
       | `riposte` (반격 성공) | 3 |
       | `aoeBigDamage` (광역 대상 ≥ 2명, 합계 피해 ≥ baseAttack×2) | 2 |
       | `mezApply` (`mez_stunned` 부여 성공) | 2 |
       | `dispel` (debuff/dot 1개 이상 해제) | 2 |
       | `dotApply` (`dot_bleeding`/`dot_poisoned` 부여 성공) | 1 |
     - 파티 측 각 mercenary 점수를 합산 → `protagonistMercId` = 최고 점수 mercenary.
     - 동률 시 tiebreaker: (a) 누적 가한 피해 합계 desc → (b) recruitedAt asc → (c) mercId lexicographic asc.
     - 점수 0인 mercenary는 protagonist 후보에서 제외(`protagonistMercId == null` 가능).
     - `featuredMercIds`: 점수 desc 정렬 후 protagonist 제외 상위 최대 2명. 점수 0인 mercenary는 포함하지 않음.
     - **시뮬레이션 active 시 `QuestNarrativeService.pickProtagonist` 폴백 호출 금지** — 시뮬레이터가 권한.
  3. HP ≤ 0 도달 시점에 마킹된 사망 후보에 대해 사망 저항 롤(이미 라운드 중 수행) 결과를 정리해 `injuredMercIds`/`deceasedMercIds` 확정.
  4. **`toneTags` 산출** — `combat_report_keywords`에서 카테고리별 가중 random으로 선택:
     - 개수 결정 매트릭스 (`questResult`별 N):
       | `questResult` | N |
       |---------------|---|
       | `greatSuccess` | 3 |
       | `success` | 2 |
       | `failure` | 1 |
       | `criticalFailure` | 1 |
     - 카테고리별 선택 우선순위:
       1. `battlefield` 카테고리에서 `regionEnvironmentTags`와 매칭되는 키워드 풀에서 가중 random 1개 (`weight` 컬럼 사용).
       2. `enemy` 카테고리에서 시뮬레이션에 등장한 적의 `enemyKeywordKey`(있는 경우)와 매칭되는 키워드 풀에서 가중 random 1개.
       3. `decisive` 카테고리에서 시뮬레이션에서 발생한 결정적 장면 액션과 매칭되는 키워드 풀에서 가중 random N-2개(상한 1).
     - 매칭 풀이 비어 있으면 해당 슬롯 skip(빈 풀로 인한 null은 fail-soft 무시). 결과 `toneTags`는 0~N개 가능.
     - 사용 PRNG: `Random(seed ^ stableSeed32('tone|$questId'))` 단일 인스턴스.
  5. `CombatSimulationResult` 반환.

- **[FR-10.2]** `objectiveProgress` 산출 정책:
  - 토벌·암살류 (적 진영 전멸이 목표): `objectiveProgress = 1.0 - (enemyHpRemainingTotal / enemyHpMaxTotal)`
  - 호위류 (호위 대상 생존 + 종점 도달): 현재 `ActiveQuest`에는 `objectiveProgress` 영속 필드가 없다. `pool.specialFlags['objective_progress']`가 `num`이면 해당 값을 [0.0, 1.0]로 clamp해 사용하고, 없으면 `1.0 - enemyHpRatio`로 fallback한다.
  - 탐험·조사류 (특정 라운드 도달 또는 적 처치율): `objectiveProgress = killedEnemyCount / requiredKillCount` (`requiredKillCount`는 `pool.specialFlags['required_kill_count']` 또는 `enemyCount`)
  - 기본값: `objectiveProgress = 1.0 - (enemyHpRemainingTotal / enemyHpMaxTotal)` (적 전멸 기반). 의뢰 유형별 정밀화는 페이즈 4 #5 검증 위임.

#### 2.1.4 산식 hook

- **[FR-11]** 액션 1회의 표준 시퀀스(공격 액션 기준):
  1. 표적 결정(→ [FR-16])
  2. 명중 판정 — `hitChance = baseHitRate(role) + (atk_agi - def_agi) × 0.008 + traitHitBonus + battlefieldHitMod + statusEffectHitMod − rangePenalty`. clamp [0.50, 0.95]. `hitRng.nextDouble() < hitChance` 통과 시 명중.
  3. 회피 판정(명중 통과 후) — `evasionChance = baseEvasion(role) + (def_agi - atk_agi) × 0.008 + traitEvasionBonus + battlefieldEvasionMod + statusEffectEvasionMod`. clamp [0.0, 0.75]. `evaRng.nextDouble() < evasionChance` 통과 시 회피 성공.
  4. 회피 성공 시: 반격 판정 → `riposteChance = baseRiposte(role) + traitRiposteBonus + statusEffectRiposteMod`. clamp [0.0, 0.60]. `ripRng.nextDouble() < riposteChance` 통과 시 추가 행동 1회 즉시 삽입(공격자↔방어자 swap). **반격에서 반격은 발생하지 않는다.**
  5. 회피 실패 시: 방패 막기 판정 — `shieldBlockMitigation = traitShieldBonus + skillShieldBonus`(상한 0.60). `shdRng.nextDouble() < shieldBlockChance` 통과 시 피해 감소.
  6. 치명타 판정 — `critChance = baseCritRate(role) + atk_agi × 0.003 + traitCritBonus + flankBonus(attackerRole, defenderRow) + skillCritRateBonus + statusEffectCritMod`. clamp [0.05, 0.60]. `critRng.nextDouble() < critChance` 통과 시 `critMultiplier(attackerRole)` 적용.
     - `flankBonus(role, defenderRow)` — 후방 공격 보너스(페이즈 1 #3 §7.4):
       | role | `defenderRow == back` 시 보너스 | 그 외 |
       |------|-----------------------------|-------|
       | rogue | +0.10 | 0.0 |
       | ranger | +0.05 | 0.0 |
       | 그 외 | 0.0 | 0.0 |
       단, 전열이 모두 사망한 상태에서만 후열 직접 공격이 가능하므로([FR-16] 전열 보호), `defenderRow == back && enemyFrontAllDead` 조건 충족 시에만 보너스 적용.
     - `skillCritRateBonus` — 페이즈 1 #4 §1.5 미매핑 hook(`statusEffectCritMod`)을 표준 상태 효과 카탈로그에 추가하지 않고 스킬의 직접 부수효과로 표현하는 hook. `CombatSkill.critRateBonus` 필드(nullable double, 0.0~0.30) 값을 발동 중인 caster의 critChance에 직접 가산. 페이즈 2 #1 §2.3 `skill_ranger_marksman_focus`가 0.15로 활용. duration은 표준 `buff_accuracy_up`의 `durationTurns`를 따른다(동일 스킬이 buff_accuracy_up과 critRateBonus를 함께 부여하면 두 효과의 지속이 동기). `statusEffectCritMod`는 카탈로그 미매핑 상태로 유지.
     - `critMultiplier(role)` (페이즈 1 #3 §7.6): rogue 2.0× / ranger 1.7× / mage 1.7× / warrior 1.5× / specialist 1.5× / support 1.5×.
  7. 피해 계산 — `baseAttack = roleAttackFormula(snapshot) + statusEffectAttackMod`(곱셈). `defense = roleDefFormula(snapshot) + statusEffectDefenseMod`(곱셈). `rawDamage = (max(1, baseAttack - defense) × critMultiplier × (1.0 - shieldMitigation) × skillDamageMultiplier) + dmgRng.nextInt(2*noiseRange+1) - noiseRange`. `noiseRange = clamp(floor(baseAttack*0.10), 1, 5)`. `hitDamage = max(1, round(rawDamage))`.
  8. 피해 적용 → HP 감소 → HP ≤ 0 시 [FR-11.5] 사망 저항 롤.
  9. 부수 효과 적용 — 스킬에 `statusEffectId` 있고 발동 시 [FR-17] 상태 효과 부여 알고리즘.
- **[FR-11.5]** 사망 저항 — HP ≤ 0 시 1회 롤. `deathResistChance = baseDeathResist(tier) + roleDeathResist(role) + traitDeathResist + factionPassiveDeathResist`. clamp [0.20, 0.80]. 체인 주인공이면 `chance += (1.0 - chance) × 0.5`, 최종 clamp [_, 0.90]. `deathRng.nextDouble() < chance` 통과 시 HP=1 + injured 마킹, 실패 시 deceased 마킹.

#### 2.1.5 PRNG 7 인스턴스 분리

- **[FR-12]** 7 PRNG + 보조 3 PRNG = 총 10 PRNG. 모두 `Random(seed ^ stableSeed32(domainKey))` 형태이며 액션 단위 인스턴스를 매번 생성한다. 단일 시드 + 단일 도메인 키 → 단일 결과 보장.
  - 핵심 7종(페이즈 1 #3 §14):
    - `dmgRng = Random(seed ^ stableSeed32('dmg|$roundIndex|$pairId'))` — 피해 노이즈
    - `hitRng = Random(seed ^ stableSeed32('hit|$roundIndex|$pairId'))` — 명중 판정
    - `critRng = Random(seed ^ stableSeed32('crit|$roundIndex|$pairId'))` — 치명타 판정
    - `evaRng = Random(seed ^ stableSeed32('eva|$roundIndex|$pairId'))` — 회피 판정
    - `shdRng = Random(seed ^ stableSeed32('shd|$roundIndex|$pairId'))` — 방패 막기 판정
    - `ripRng = Random(seed ^ stableSeed32('rip|$roundIndex|$pairId'))` — 반격 판정
    - `deathRng = Random(seed ^ stableSeed32('death|$mercId'))` — 사망 저항 롤
  - 보조 3종(페이즈 1 #2 §12 + 페이즈 1 #4 §10):
    - `orderRng = Random(seed ^ stableSeed32('order|$roundIndex|$combatantId'))` — 행동 순서 노이즈(-3~+3 반환은 `nextInt(7)-3`)
    - `applyRng = Random(seed ^ stableSeed32('apply|$roundIndex|$casterId|$targetId|$effectId'))` — 상태 효과 부여 판정
    - `dispelRng = Random(seed ^ stableSeed32('dispel|$roundIndex|$casterId'))` — dispel 판정
  - `pairId = stableSeed32('$attackerId|$defenderId')`.
  - **Dart `hashCode` 사용 금지.** `stableSeed32` 유틸은 본 명세 [FR-19]에서 정의한다.

#### 2.1.6 트레잇·환경 자동 부여 hook

- **[FR-13]** 트레잇 키워드 매칭(페이즈 1 #2 §5 + 페이즈 2 #3 §7.1):
  - 정적 상수 매트릭스로 코드에 내장(`combat_simulator_constants.dart` 또는 `combat_simulator.dart` 내부 private const):
    ```text
    initiativeKeywords  = {'scout': +2, 'ambush': +3, 'first_strike': +3, 'vigilant': +2, 'tracker': +1}
    actionKeywords      = {'swift': +2, 'nimble': +1, 'quick': +1, 'agile': +1}
    evasionKeywords     = {'evasion': 0.04, 'dodge': 0.04, 'nimble': 0.03, 'slippery': 0.04}
    counterKeywords     = {'riposte': 0.08, 'counter': 0.08, 'vengeance': 0.08, 'vigilant': 0.05, 'unyielding': 0.05}
    shieldKeywords      = {'shield': 0.10, 'bulwark': 0.10, 'guardian': 0.10}
    hitKeywords         = {'marksman': 0.05, 'keen_eye': 0.05, 'sniper': 0.05, 'tracker': 0.03, 'huntsman': 0.03, 'veteran': 0.02}
    critKeywords        = {'precise': 0.05, 'deadly': 0.05, 'assassin': 0.05, 'keen_eye': 0.04, 'sharpshooter': 0.04}
    deathResistKeywords = {'survivor': 0.05, 'tough': 0.05, 'resilient': 0.05, 'iron_body': 0.05, 'hardy': 0.05}
    ```
  - **중복 적용 정책**: 한 트레잇 키워드가 여러 매트릭스에 동시 등록되면 각 매트릭스에 독립 적용(페이즈 1 #2 §5.2 정합). 예: `tracker` 보유 시 initiative +1, hit +0.03 동시 적용. `vigilant` 보유 시 initiative +2, counter +0.05 동시 적용. `keen_eye` 보유 시 hit +0.05, crit +0.04 동시 적용.
  - **상한 정책**:
    - 진영 1명당 상한: 선제 +5 / 행동 +5 / 회피 +0.12 / 명중 +0.10 / 치명타 +0.15 / 사망 저항 +0.15. (합산 후 clamp)
    - 진영 합산 상한: **선제 점수만 +15** (페이즈 1 #2 §5.4). 행동 점수·회피·명중·치명타·사망 저항·반격·방패는 진영 합산 상한 없음 — 1명당 상한만 적용된다.
    - clamp는 합산 직후 적용. 페이즈 1 #3 §6/§8 hook 산식 clamp([0.50,0.95] / [0.0,0.75])와 독립.
  - **선제 라운드 시작 시 자동 부여** (Phase 1 사전 단계 마지막 + Phase 2 선제 라운드 직전, applyChance 1.0):
    - `vigilant` 트레잇 보유자: self `buff_evasion_up`(intensity 0.10, duration 1).
    - `huntsman` 트레잇 보유자: self `buff_accuracy_up`(intensity 0.05, duration 1).
    - 페이즈 2 #3 §7.1 정합. 부여는 표준 상태 효과 카탈로그를 통해 hook과 결합된다.

- **[FR-13.5]** 환경 자동 부여(페이즈 2 #3 §7.2):
  - Phase 1 사전 단계에서 `Region.environmentTags` 기반 `regionEnvironmentTags`(스냅샷 동결값) 평가.
  - `RegionState`는 위험도·플래그·신뢰도 상태만 보유하므로 환경 태그의 source of truth로 사용하지 않는다.
  - `mist_field` 포함 시: 적군 전원에 `debuff_accuracy_down`(intensity 0.10, duration 2, applyChance 1.0) 자동 부여.
  - 기타 환경 보정(forest +5 ranger / dungeon +3 warrior 등)은 hit/crit/evasion 산식의 `battlefieldXxxMod` 항으로 적용(상태 효과 부여 아님).

#### 2.1.7 자동 발동 결정 트리

- **[FR-14]** 파티 측 스킬 자동 선택(페이즈 2 #1 §7 의사 코드 영속화). 각 단계는 (a) 직업군 매칭 (b) 발동 조건 매칭 (c) `cooldown[skillId] == 0` && `usedCount[skillId] < maxUsesPerCombat`를 모두 통과해야 진입. 첫 매칭에서 즉시 return:
  1. **trigger (battle_fury)**: `combatant.role == 'warrior' && combatant.hp <= maxHp * 0.5 && !combatant.flagBattleFuryUsed` → `skill_warrior_battle_fury`(`extraAction`로 즉시 발동, 같은 라운드 기본 행동 슬롯은 별도 사용 가능).
  2. **support cleansing_word**: `combatant.role == 'support' && allies.any(a => a.hasAnyStatusEffect(kind: 'debuff') || a.hasAnyStatusEffect(kind: 'dot'))` → `skill_support_cleansing_word`. cleansing_word는 aegis_aura보다 **우선** 자동 발동.
  3. **support aegis_aura**: `combatant.role == 'support' && allies.none(a => a.hasStatusEffect('buff_defense_up'))` → `skill_support_aegis_aura`. cleansing_word 조건 미충족 시 진입(둘 다 자동 발동 가능하지만 단일 라운드에서는 위 우선순위로 1개만).
  4. **mage stun_bolt**: `combatant.role == 'mage' && enemies.any(e => e.enemyKind == 'unique' || e.enemyKind == 'elite' || e.hp >= maxEnemyHp)` → `skill_mage_stun_bolt`.
  5. **mage arcane_blast**: `combatant.role == 'mage' && enemies.count(alive) >= 2` → `skill_mage_arcane_blast`. stun_bolt 조건 미충족 시 진입.
  6. **ranger volley_shot**: `combatant.role == 'ranger' && combatant.hasStatusEffect('buff_accuracy_up')` → `skill_ranger_volley_shot`.
  7. **ranger marksman_focus**: `combatant.role == 'ranger' && combatant.isFirstInActionOrder` → `skill_ranger_marksman_focus`. volley_shot 조건 미충족 시 진입.
  8. **rogue mass_blind**: `combatant.role == 'rogue' && enemies.frontRow.count(alive) >= 2` → `skill_rogue_mass_blind`.
  9. **specialist adaptive_footwork**: `combatant.role == 'specialist' && !combatant.hasStatusEffect('buff_evasion_up') && enemies.count(alive) >= 2 && (combatant.hp <= maxHp * 0.6 || roundIndex >= 2)` → `skill_specialist_adaptive_footwork`.
  10. **폴백**: 기본 공격(표적은 [FR-16]로 결정).

- **[FR-15]** 적 측 behaviorPattern 결정 트리(페이즈 2 #2 §8.3 의사 코드 영속화). 각 단계는 (a) behaviorPattern/직업군 매칭 (b) 발동 조건 매칭 (c) `enemy.hasSkill(skillId)` && `cooldown[skillId] == 0` && 1회성 플래그 미사용을 모두 통과해야 진입:
  1. **berserker battle_fury**: `enemy.behaviorPattern == berserker && enemy.hp <= maxHp * 0.5 && !enemy.flagBattleFuryUsed && enemy.hasSkill('skill_warrior_battle_fury')` → `skill_warrior_battle_fury`(extraAction).
  2. **defender taunt_roar (R1)**: `enemy.behaviorPattern == defender && roundIndex == 1 && enemy.hasSkill('skill_enemy_taunt_roar')` → `skill_enemy_taunt_roar`.
  3. **defender summon**: `enemy.behaviorPattern == defender && enemy.hp <= maxHp * 0.6 && !enemy.flagSummonUsed && enemy.hasSkill('skill_enemy_summon')` → `skill_enemy_summon`. 발동 시 `flagSummonUsed = true` 영속.
  4. **caster arcane_blast**: `enemy.behaviorPattern == caster && partyAliveCount >= 2 && enemy.hasSkill('skill_mage_arcane_blast')` → `skill_mage_arcane_blast`.
  5. **caster stun_bolt**: `enemy.behaviorPattern == caster && partyAliveCount >= 1 && enemy.hasSkill('skill_mage_stun_bolt')` (arcane_blast 미충족 또는 쿨다운 시 진입) → `skill_mage_stun_bolt`.
  6. **supporter aegis_aura**: `enemy.behaviorPattern == supporter && enemyAllies.none(e => e.hasStatusEffect('buff_defense_up')) && enemy.hasSkill('skill_support_aegis_aura')` → `skill_support_aegis_aura`.
  7. **적 전용 스킬**: `enemy.hasSkill('skill_enemy_armor_break')` → `armor_break` / `enemy.hasSkill('skill_enemy_bleeding_cut')` → `bleeding_cut` / `enemy.hasSkill('skill_enemy_poison_bite')` → `poison_bite`. 다중 보유 시 armor_break > bleeding_cut > poison_bite 순.
  8. **self_dispel**: `enemy.hasSkill('skill_enemy_self_dispel') && enemy.activeNegativeEffectCount >= 2` (debuff + dot 합산) → `skill_enemy_self_dispel`(applyChance 1.0, 자동 발동).
  9. **폴백**: 기본 공격. 표적은 `behaviorPattern.targetPriority`로 결정:
     - `aggressive`: 가장 가까운 대상([FR-16] 접근형 기본 매칭, 전열 → 중열 → 후열).
     - `opportunist`: 파티 중 HP 비율 최저(`hp/maxHp`) 또는 부상 보유자. 동률 시 [FR-16] 접근형 기본 매칭.
     - `caster`: [FR-16] mage 표적 정책(광역 후보열 → 후열).
     - `supporter`: 공격 시 [FR-16] support 표적 정책(적 후열). 본인 또는 적 전용 buff·dispel은 위 §6/§8에서 분기.
     - `defender`: 본인 진형 보호 — 가장 가까운 대상(전열 우선) + 본인 방패 막기 확률 우대(`shieldBlockBonus` 가산 발동).
     - `berserker`: 가장 가까운 대상(전열 우선). 후열 직접 공격은 전열 전멸 시에만.
  - `behaviorPattern` enum 6종: `aggressive`/`opportunist`/`caster`/`supporter`/`defender`/`berserker`.
  - **1회성 플래그 영속화**: `EnemySnapshot.flagBattleFuryUsed`/`flagSummonUsed`(페이즈 4 #2 모델에 추가). 시뮬레이션 도중에만 변동, 영속 박스 미사용.

#### 2.1.8 표적 결정

- **[FR-16]** 진형 표적 정책(페이즈 1 #2 §7.2~§7.4):
  - 접근형(warrior/specialist/rogue): 상대 전열 우선 → 전열 전멸 시 중열 → 후열.
  - 원거리(ranger/mage/support): 자유 표적.
    - `ranger`: HP 가장 낮은 적
    - `mage`: 광역 스킬 보유 시 다인 열, 광역 미보유 시 적 후열(mage/support 우선)
    - `support`: 공격 시 적 후열, 보조 시 아군 HP 최저
  - behaviorPattern별 보정:
    - `opportunist`: HP 최저 또는 부상 보유자 (직업군 기본 표적을 오버라이드)
    - `aggressive`: 가장 가까운 대상(직업군 기본 표적과 동일)
  - 전열 보호 — 적 전열 1명 이상 생존 동안 접근형 적은 중·후열 직접 타격 불가. 전열 전멸 후 다음 라운드부터 중·후열 노출.
  - 회피 성공한 액션은 다른 표적으로 재선정하지 않는다. 라운드 행동 1회 소모하고 종료.

#### 2.1.9 상태 효과 결합 알고리즘

- **[FR-17]** 상태 효과 부여 절차:
  1. 스킬 `applyChance` 판정 — `applyRng.nextDouble() < applyChance` 통과 시 부여 진행.
  2. 광역 스킬은 대상별 독립 판정 (페이즈 1 #4 §4 부여 확률 분기).
  3. `stack_policy` 분기:
     - `refresh`: 이미 보유 중이면 `durationTurns = max(existing, new)`, intensity 갱신 없음.
       - `mez_stunned` 특수 상한: `durationTurns = min(3, max(existing, new))`(페이즈 2 #3 §2.3 clamp_max_duration=3, 무한 락 방지).
     - `stack`: 이미 보유 중이면 `intensity = min(clamp_max_stack, existing + 1)`, `durationTurns = max(existing, new)`.
       - `dot_bleeding`/`dot_poisoned` clamp_max_stack = 3, clamp_max_duration = 5.
     - `ignore`: 이미 보유 중이면 무시.
  4. 부여 시점 즉시 `statusEffectHistory`에 `applyEvent`(라운드·caster·target·effectId·intensity·duration·stackResult) 추가.

- **[FR-17.5]** 상태 효과 결합 방식 (`apply_method` 5종):
  - 액션 산식 hook 평가 시 활성 상태 효과를 결합:
    - `multiplicative` (attack/defense):
      `mod = (1 + Σ buff_intensity) × (1 - Σ debuff_intensity)` 후 `baseAttack` 또는 `baseDefense`에 곱셈.
    - `additive` (hit/evasion):
      `mod = Σ buff_intensity - Σ debuff_intensity` 후 chance에 가산 → clamp 적용.
    - `proportional` (DoT bleeding): `damage = max(1, floor(maxHp × 0.04 × stack))`.
    - `absolute` (DoT poisoned): `damage = max(1, floor(intensity × 5 + level × 2))`. `intensity`는 `default_intensity`(현재 3) × stack 분배가 아니라 `intensity * 5`이며, stack 누적은 페이즈 1 #4 §5.2와 페이즈 2 #3 §3.2 산식 정합 — stack 1 시 intensity 3, stack 2 시 intensity 5, stack 3 시 intensity 8 매핑(테이블화는 페이즈 4 #2 모델에서 명세).
    - `none` (mez_stunned): 행동 분기 입력만, 산식 결합 없음.
  - hit/evasion은 합산 후 페이즈 1 #3 §6/§8 clamp [0.50, 0.95] / [0.0, 0.75] 적용.
  - **dispel 부분 해제 우선순위** (페이즈 1 #4 §8.3 + 페이즈 2 #1 §2.5):
    - `dispelKind == 'debuff'`: 대상의 `kind == debuff` 효과 중 부여 시점 desc 정렬 → 상위 `dispelMaxCount`개 해제.
    - `dispelKind == 'buff'`: 대상의 `kind == buff` 효과 중 부여 시점 desc 정렬 → 상위 `dispelMaxCount`개 해제.
    - `dispelKind == 'dot'`: 대상의 `kind == dot` 효과 중 stack desc → duration desc → 부여 시점 desc 정렬 → 상위 `dispelMaxCount`개 해제.
    - `dispelKind == 'debuff+dot'` (cleansing_word/self_dispel 기본): **dot 1개 우선 → debuff 1개 순서**로 해제(페이즈 2 #1 §2.5 권고 명시값). 대상별 최대 (dot 1, debuff 1) = 2 효과 해제. dispelMaxCount는 (dot 카운트, debuff 카운트) 튜플 `(1, 1)` 또는 페이즈 4 #2 모델의 정수 분배 정책에 따른다.
  - duration 0 도달 시 자연 해제. **`mez_stunned`는 dispel로 해제 불가**(자연 해제만, 페이즈 1 #4 §8.2 MVP 정책).
  - **자연 해제 endEvent 필수 필드** (`statusEffectHistory`):
    - `roundIndex` (int, 0=선제 라운드, 1+=일반 라운드)
    - `targetId` (String)
    - `effectId` (String)
    - `labelKey` (String, `CombatStatusEffect.displayLabel` 캐싱)
    - `endCause` (enum: `natural`/`dispel`/`death`/`combatEnd`)
    - `endRoundIndex` (= roundIndex, 명시 보존)
  - 사망/전투 종료로 인한 해제도 endEvent로 동일 구조 기록(`endCause: death`/`combatEnd`).

#### 2.1.10 보고서 라인 압축 알고리즘

- **[FR-18]** 라운드 압축 정책(페이즈 2 #4 §3.3 + §8 + §10.3):
  1. 라운드 수 → 보고서 길이 매핑(페이즈 2 #4 §2):
     - 3 라운드 → 4줄 / 4~5 라운드 → 5~6줄 / 6 라운드 → 6~7줄 / 7~8 라운드 → 7~8줄.
     - 중요도(`importance`)별 보정(페이즈 2 #4 §2.3).
  2. 5 위치 분포(페이즈 2 #4 §3.2):
     | 길이 | entry | development | crisis | resolution | aftermath |
     |------|-------|-------------|--------|------------|-----------|
     | 4 | 1 | 1 | 1 | 1 | 0 |
     | 5 | 1 | 2 | 1 | 1 | 0 |
     | 6 | 1 | 2 | 1 | 1 | 1 |
     | 7 | 1 | 2 | 2 | 1 | 1 |
     | 8 | 1 | 3 | 2 | 1 | 1 |
  3. 위치별 라인 선택 우선순위(페이즈 2 #4 §3.3): 진입 1줄(필수) → 해소 1줄(필수) → 위기 1줄(4줄+) → 전개 1줄(4줄+) → 전개 추가(5줄+) → 위기 추가(7줄+) → 후일담 1줄(6줄+).
  4. 다중 결합 라인 우선순위(페이즈 2 #4 §8.3): kill > injure > aoeTargets ≥ 2 > isDecisive > appliesStatusEffect > maxDamage.
  5. 라인 풀 활용 우선순위(페이즈 2 #4 §10.3): scope 직접 매칭 → `scene` 보충풀 → importance 매칭 fallback → result_type 일반 fallback.
  - **[Q-2]** 본 명세는 `turns` 시퀀스 + `statusEffectHistory` + 결정적 장면 마킹까지를 시뮬레이터의 책임으로 본다. 실제 `CombatReport`(요약/상세) 생성은 `CombatReportService.generate(..., simulationResult: simResult)`(페이즈 4 #3 명세 위임)에서 수행한다. 시뮬레이터는 위 §3.3 5 위치 매핑과 우선순위 결정 트리에 필요한 메타데이터(position/skill_id/status_effect_id/behavior_pattern/decisive_keyword_key/is_combo_compression)를 `CombatTurn`/`CombatAction`에 기록만 한다.

#### 2.1.11 시드 유틸

- **[FR-19]** `stableSeed32(String input) → int`:
  - FNV-1a 32-bit 알고리즘.
  - 위치: `band_of_mercenaries/lib/core/util/stable_seed.dart` (신규).
  - 시그니처: `int stableSeed32(String input)`.
  - `input.codeUnits` 순회하며 FNV-1a 표준 상수(offset=0x811C9DC5, prime=0x01000193)와 XOR + 곱셈을 적용한다. `& 0xFFFFFFFF` 마스킹으로 32-bit 보장.
  - **Dart `String.hashCode`는 앱 실행마다 달라질 수 있으므로 절대 사용하지 않는다.**

#### 2.1.12 fallback 정책

- **[FR-20]** 시뮬레이터 실패 시 안전 폴백:
  - `simulate()` 본체 전체를 `try/catch`로 감싼다. 예외 발생 또는 필수 정적 데이터 부재 시 `null` 반환.
  - 필수 정적 데이터: `staticData.combatSkills`/`combatStatusEffects`/`enemyArchetypes`. 빈 리스트 또는 미정의 ID 참조 시 즉시 null.
  - 호출 측(`QuestCompletionService` 페이즈 4 #3)은 null 수신 시 `QuestCalculator` 기존 결과 그대로 사용 + `CombatReportService.generate(..., simulationResult: null)`(M8a MVP 경로) 호출.
  - 로그: `debugPrint('[BOM][CombatSimulator] simulate failed: $e\n$st')`.

### 2.2 데이터 요구사항

본 명세는 모델·테이블 추가를 직접 요구하지 않는다. 페이즈 4 #2(별도 명세)에서 다음 모델이 정의되어야 본 서비스가 동작한다:

- 신규 모델 (페이즈 4 #2 위임):
  - `EnemyArchetype` (정적 데이터) — 페이즈 2 #2 §14 구조
  - `EnemySnapshot` (시뮬레이션 입력 동결)
  - `CombatantSnapshot` (파티 측 동결)
  - `CombatSkill` (정적 데이터) — 페이즈 2 #1 §10 구조
  - `CombatStatusEffect` (정적 데이터) — 페이즈 1 #4 §2 구조 + 페이즈 2 #3 §10.2 default
  - `CombatSimulationResult` (시뮬레이션 출력) — 페이즈 1 #1 §CombatSimulationResult 11 필드
  - `CombatTurn` / `CombatAction` (라운드별 압축 액션 시퀀스)
  - `StatusEffectEvent` (apply/end/stack/dispel 이벤트)
  - `CombatExitCondition` enum (a~f)
  - `BehaviorPattern` enum (aggressive/opportunist/caster/supporter/defender/berserker)
  - `PositionRow` enum (front/middle/back)
  - `ApplyMethod` enum (multiplicative/additive/proportional/absolute/none)
  - `StackPolicy` enum (refresh/stack/ignore)
  - `ActionCost` enum (action/extraAction/passive)
  - `TriggerKind` enum (passive/active/triggered/on_hit/on_kill)
  - `TargetingKind` enum (self/single_enemy/single_ally/aoe_enemy/aoe_ally/party)
  - `DispelKind` enum (debuff/buff/dot/debuff+dot)
  - `EnemyKind` enum (normal/elite/unique)
- 신규 정적 카탈로그 (페이즈 3 시드 의존):
  - `combat_skills` (16행) / `combat_status_effects` (10행) / `enemies` (26행)
  - `combat_report_templates` (M8a 96 + M8b 85 = 181행). M8b 85행은 페이즈 3 #4에서 시드. 신규 scope `combat_skill` 23행 포함(페이즈 2 #4 §9.2 권장 20행에서 +3 보강). `scope` CHECK 제약 확장 필요: 기존 8종 + `combat_skill` 1종.
  - 신규 `combat_report_keywords` 신규 5 키워드 후보 (페이즈 2 #2 §11.3) — 페이즈 3 #4 위임.
- `StaticGameData` 확장 (페이즈 4 #2):
  - `List<CombatSkill> combatSkills`
  - `List<CombatStatusEffect> combatStatusEffects`
  - `List<EnemyArchetype> enemyArchetypes`
- `ActiveQuest.combatSimulationResult` 또는 `CombatReport.embeddedTurns` 영속 필드(페이즈 4 #2 결정). 본 명세는 메모리 객체 반환만 정의.

본 명세에서는 **Hive 박스 신설 없음**. 시뮬레이션 결과의 영속은 M8a `ActiveQuest.combatReport`(HiveField 27) 본체 또는 페이즈 4 #2 신규 필드를 통해 이루어진다.

### 2.3 UI 요구사항

해당 없음. 본 서비스는 순수 도메인 로직이며 UI 표시는 페이즈 4 #4 별도 명세에서 다룬다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| 없음 | — | 본 명세는 순수 서비스 추가만 다룬다. `QuestCompletionService`/`quest_provider`/`CombatReportService` 통합은 페이즈 4 #3에서 다룬다. |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` | `CombatSimulator.simulate()` 정적 메서드 + 4 페이즈 알고리즘 + private helper |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator_constants.dart` | 직업군 매트릭스(roleInitiativeWeight/roleActionWeight/roleVitCoef/roleHpFlat/baseHitRate/baseEvasion/baseCritRate/baseRiposte/baseDeathResist/critMultiplier/roleAttackFormula/roleDefCoef/roleDefFlat) + 환경 매트릭스(8 태그 × 6 직업군 명중·회피 보정) + 트레잇 키워드 매트릭스 + cumulative cap + 카테고리별 상한 |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator_helpers.dart` | private helper 모음(보고서 압축 알고리즘 + DoT 산식 + 사망 저항 롤 + 자동 선택 결정 트리) — `combat_simulator.dart`에서 분리 가능. 구현 시점 판단 위임 |
| `band_of_mercenaries/lib/core/util/stable_seed.dart` | FNV-1a 32-bit `stableSeed32(String) → int` |
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_test.dart` | (페이즈 4 #5 위임 — 본 명세에서는 placeholder만 권장. 결정성·종료 조건·산식 hook 테스트는 페이즈 4 #5에서 정의) |
| `band_of_mercenaries/test/core/util/stable_seed_test.dart` | FNV-1a 단위 테스트(고정 입력 → 고정 출력 5~10 케이스) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| 없음 | 본 명세는 freezed/Hive 모델을 정의하지 않으므로 `build_runner` 실행이 필요 없다. 페이즈 4 #2에서 신규 모델이 정의되면 그 시점에 실행한다. |

### 3.4 관련 시스템

- **QuestCompletionService (페이즈 4 #3 통합)**: `combatSimulationEligible` 평가 + `simulate` 호출 + 결과 통합. 본 명세는 호출 측 명세 미포함.
- **QuestCalculator**: 일반 의뢰 fallback 유지. 본 명세는 영향 없음.
- **CombatReportService (페이즈 4 #3 확장)**: `simulationResult` 인자 추가. 본 명세는 영향 없음.
- **Mercenary 본체**: `effectiveStrWith/effectiveIntelligenceWith/effectiveVitWith/effectiveAgiWith` 호출만(read-only). `injure/die`는 호출 측이 결과 받아 적용.
- **StaticGameData**: 페이즈 4 #2에서 `combatSkills`/`combatStatusEffects`/`enemyArchetypes` 컬렉션 추가. 본 명세는 사용 측만 명시.
- **TemplateEngine**: 보고서 라인 렌더가 시뮬레이터 외부(`CombatReportService.generate`)에서 수행되므로, 시뮬레이터는 직접 호출하지 않는다.
- **세력·체인·평판**: 본 서비스가 결정하는 `QuestResult`/`mercDamages`는 `QuestCompletionService`(페이즈 4 #3)가 오버라이드 한 후 기존 후속 처리로 연결.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart` — M8a 정적 helper 서비스 패턴. `CombatSimulator`도 동일하게 `class CombatSimulator { CombatSimulator._(); static CombatSimulationResult? simulate({...}) {...} }`로 작성.
- `band_of_mercenaries/lib/features/quest/domain/quest_narrative_service.dart` — `pickProtagonist` 호출 패턴. 시뮬레이터는 자체 결정적 장면 집계로 `protagonistMercId`를 결정하며 `pickProtagonist` 폴백은 호출하지 않는다.
- `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` — `_statWeights` 매트릭스 정적 상수 패턴(직업군별 매트릭스의 코드 내장 방식).
- `band_of_mercenaries/lib/features/quest/domain/named_hook_evaluator.dart` — 순수 정적 헬퍼 + 콜백 미사용 패턴.

### 4.2 주의사항

- **순수 함수 유지**: `CombatSimulator.simulate`는 외부 상태(Hive 박스/Provider/Ref)에 직접 접근하지 않는다. 모든 입력은 named parameter로 전달받고, 결과는 반환값으로만 전달한다. `Mercenary.injure/die` 직접 호출 금지(injuredMercIds/deceasedMercIds 마킹만).
- **결정성 보장**: PRNG는 도메인 키별로 매 액션마다 새로 생성한다(`Random(seed ^ stableSeed32(domainKey))`). 동일 PRNG를 다중 액션에서 재사용 금지 — 호출 순서가 달라지면 결과가 달라지므로.
- **`Dart hashCode` 금지**: `String.hashCode`/`Object.hashCode`/`DateTime.hashCode` 모두 앱 실행마다 다를 수 있다. 시드 산출은 반드시 `stableSeed32` 사용.
- **fail-soft 원칙**: 시뮬레이터가 어떤 이유로든 예외를 던지면 null 반환. 호출 측이 `QuestCalculator` 폴백으로 게임을 계속 진행할 수 있도록 보장(페이즈 1 #1 §fallback).
- **`partyMercs` 입력 동결**: 입력 mercenary 리스트의 상태(HP/사기/상태 효과)는 시뮬레이션 도중 변경되지 않는다. 모든 동결은 `CombatantSnapshot`/`EnemySnapshot`이라는 별도 데이터 구조에서 일어난다(페이즈 4 #2 모델). 이로써 한 mercenary가 동시 여러 시뮬레이션에 들어가도 충돌 없음(실제로는 파견 중 mercenary는 다른 의뢰에 들어갈 수 없으나 결정적 정합을 위해 보장).
- **`pool == null` 대응**: 일반 의뢰 또는 quest_pool 미매칭 시 `pool == null`이 가능. 이 경우 `factionTag`/`specialFlags`는 `ActiveQuest` 본체 값(`quest.factionTag`, `quest.specialFlags`)을 우선 사용하고, `isNamed`/`enemyGroupId`처럼 현재 `ActiveQuest`에 없는 정보는 false/null로 처리한다. `CombatSimulator`는 `pool == null`이어도 simulate를 시도해야 한다(호출 측이 게이트했으므로).
- **CLAUDE.md "주석 작성 정책" 정합**: 산식 hook 위치는 의도가 코드 자체로 표현되어야 하며, 도메인 키 문자열(`'dmg|...'` 등)이나 매트릭스 상수가 페이즈 1·2·3 설계 문서와 1:1 매핑됨을 알릴 필요가 있을 때만 짧은 한 줄 주석을 둔다. WHAT을 설명하는 다중 라인 주석 금지.

### 4.3 엣지 케이스

- **파티 0명**: `partyMercs.isEmpty` → 즉시 null 반환(`QuestCompletionService`가 일반적으로 게이트하나 안전 가드).
- **적 그룹 0명**: 적 archetype 매칭이 하나도 없으면 null 반환 → fallback 경로.
- **`quest.startTime == null`**: 시드 산출 불가 → null 반환.
- **모든 mercenary가 동일 라운드 동시 HP ≤ 0**: 종료 조건 (a) 즉시 트리거. 사망 저항 롤은 각자 독립 수행.
- **DoT로 적이 라운드 시작 시 즉사**: 행동 순서 정렬 이전에 종료 조건 (b) 트리거 가능. 이 경우 라운드 카운터는 진입 직전 라운드까지로 처리하며 turns 시퀀스에 `roundStartDot` 액션만 기록.
- **8 라운드 도달 + 양측 모두 생존**: 종료 조건 (d) → objectiveProgress 70%+ 시 성공, 미만 시 실패.
- **체인 주인공이 파티에 없음**: `quest.isChainQuest && quest.chainProtagonistId != null`이지만 `partyMercs`에 해당 mercId 없음 → 체인 주인공 보호 공식 미적용(일반 사망 저항만).
- **선제권 동률 (`|deltaScore| < 15`)**: Phase 2 스킵, Phase 3 직진. turns[0].phase = 'general'로 시작.
- **매복 보너스 충돌**: `pool.specialFlags['ambush_side']`가 'enemy'와 'party' 둘 다 있는 경우 → enemy 우선(데이터 이상치 가드).
- **광역 액션 + 표적 중간 사망**: 광역 시작 시점의 생존자 N명에 한해 액션 진행. 표적별 개별 회피·피해·상태 효과는 독립.
- **`mez_stunned` + 라운드 1순위**: stunned이어도 행동 순서 정렬에는 포함된다. 본인 차례에 행동 스킵만.
- **반격 추가 행동 도중 표적이 stunned**: 반격은 회피·방패·치명타 판정만 수행. stunned는 공격 행동만 차단하므로 반격 자체에는 영향 없음.

### 4.4 구현 힌트

- **진입점**: 호출 측은 `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart:843` `_applyCompletionResult` (페이즈 4 #3 명세). 현재 구현은 `result.combatReportEligible && quest.combatReport == null` 가드 후 `CombatReportService.generate` 호출. 페이즈 4 #3에서는 이 블록 전에 `combatSimulationEligible` 게이트 + `CombatSimulator.simulate` 호출 + 결과 통합이 추가된다.
- **데이터 흐름**:
  ```
  quest_provider._applyCompletionResult (페이즈 4 #3)
    → CombatSimulator.simulate({quest, partyMercs, pool, staticData, userData, factionStates, regionState, partyEquipmentBonuses, seed})
    → CombatSimulationResult { questResult, turns, protagonistMercId, featuredMercIds, injured, deceased, ... }
    → QuestCompletionResult 재구성(resultType: simResult.questResult, mercDamages: simResult의 injured/deceased를 MercDamageResult로 변환)
    → 기존 보상·평판·체인 처리 흐름
    → CombatReportService.generate(..., simulationResult: simResult) (페이즈 4 #3 확장)
    → ActiveQuest.combatReport = report
  ```
- **참조 구현**:
  - `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart:24~38` — 정적 서비스 시그니처 패턴
  - `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` — 직업군별 가중치 매트릭스 정적 상수 (`_statWeights`)
  - `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart:168~194` — `effectiveStrWith/effectiveIntelligenceWith/effectiveVitWith/effectiveAgiWith` 호출
  - `band_of_mercenaries/lib/core/constants/game_constants.dart` — `levelBonusPerLevel=0.1`, `tiredDebuffMultiplier=0.8` (이미 effective getter에 반영됨)
- **확장 지점**:
  - 새 PRNG 도메인 키 추가 시 `combat_simulator.dart` 상단 도메인 키 상수 영역에 추가.
  - 새 직업군 매트릭스 항목 추가 시 `combat_simulator_constants.dart`에 정적 상수 추가.
  - 새 트레잇 키워드 추가 시 `combat_simulator_constants.dart`의 `initiativeKeywords`/`actionKeywords`/`evasionKeywords` 등에 추가.
  - 페이즈 4 #2 모델이 정의된 후 `EnemyArchetype`/`CombatSkill`/`CombatStatusEffect` 룩업 메서드 추가(예: `_lookupSkill(staticData, skillId)`).
- **권장 메서드 분해**(combat_simulator.dart 내부 private static):
  ```
  static CombatSimulationResult? simulate({...})
  static _Phase1Result _runPhase1(...)                    // 스냅샷 동결 + 진형 + 트레잇/환경 자동 부여 + 선제 판정
  static _Phase2Result _runPhase2(_Phase1Result phase1)   // 선제 라운드
  static _Phase3Result _runPhase3(_Phase2Result phase2)   // 일반 라운드 반복 (최대 8)
  static CombatSimulationResult _runPhase4(_Phase3Result phase3)  // 마무리 판정 + 결과 매핑
  static CombatAction _resolveAction(...)                 // 명중→회피→방패→치명타→피해→상태 효과 부여 시퀀스
  static CombatAction? _resolveRiposte(...)               // 반격 추가 행동
  static String? _selectPartySkill(combatant, roundState) // FR-14
  static String? _selectEnemySkill(enemy, roundState)     // FR-15
  static Combatant _selectTarget(actor, targets, behaviorPattern) // FR-16
  static double _evaluateHitChance(...)                   // FR-11 §2
  static double _evaluateEvasionChance(...)               // FR-11 §3
  static double _evaluateCritChance(...)                  // FR-11 §6
  static double _evaluateRiposteChance(...)               // FR-11 §4
  static double _evaluateShieldChance(...)                // FR-11 §5
  static double _evaluateDeathResist(...)                 // FR-11.5
  static int _computeDamage(...)                          // FR-11 §7
  static void _applyStatusEffect(...)                     // FR-17
  static void _tickStatusEffects(...)                     // 라운드 종료 duration -=1
  static void _applyDotRoundStart(...)                    // FR-9 §1 poisoned
  static void _applyDotRoundEnd(...)                      // FR-9 §5 bleeding
  static List<Combatant> _orderByActionScore(...)         // FR-9 §3
  static bool _checkExitConditions(...)                   // a~f 평가
  static QuestResult _mapToQuestResult(exitCondition, survivalRatios, injuredCount, objectiveProgress)
  ```
- **stableSeed32 구현(`stable_seed.dart`)**:
  ```dart
  // FNV-1a 32-bit. Dart String.hashCode 대체. 결정성 보장.
  int stableSeed32(String input) {
    int hash = 0x811C9DC5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
  ```

## 5. 기획 확인 사항

- **[Q-1]** 적 그룹 구성 정확한 매핑(quest_pool → enemyGroupId)은 페이즈 3 #1 시드 데이터의 `enemies` 테이블과 페이즈 4 #2 `QuestPool.enemyGroupId` 또는 `EnemyArchetype.factionTags` 컬럼으로 영속화 예정. 본 명세는 시뮬레이터가 후보 풀에서 결정적으로 1~6마리를 선택하는 알고리즘만 정의하며, 정확한 풀 구성은 페이즈 3 #1/페이즈 4 #2에서 확정한다.
  → 처리 방향: 본 명세에서는 `[FR-7]` 적 그룹 구성 규칙에 후보 풀 선택 우선순위(eliteId 매칭 / factionTag 매칭 / 환경 태그 매칭)만 정의. 정확한 매핑은 페이즈 3 #1/페이즈 4 #2 위임으로 명시.

- **[Q-2]** 시뮬레이터가 `CombatReport`(요약/상세 텍스트)를 직접 생성하는가, 아니면 `CombatTurn`/`statusEffectHistory` 메타데이터까지만 산출하고 `CombatReportService.generate(..., simulationResult: simResult)`가 텍스트를 생성하는가?
  → 본 명세 채택: **분리**. 시뮬레이터는 메타데이터까지(turns/featuredMercIds/protagonistMercId/toneTags). 텍스트 렌더는 페이즈 4 #3 `CombatReportService` 확장이 담당. 이 분리는 (a) 단위 테스트 분리(시뮬레이터는 결정성 테스트, 보고서는 텍스트 매칭 테스트), (b) 페이즈 4 #4 UI 표시 변경 시 시뮬레이터 미영향 보장. 페이즈 1 #1 §M8a 호환 §데이터 흐름 표와 정합.

- **[Q-3]** 보고서 라인 압축에 필요한 메타데이터(position/skill_id/status_effect_id/behavior_pattern/decisive_keyword_key/is_combo_compression)를 `CombatTurn`/`CombatAction`의 어느 필드에 보존하는가?
  → 처리 방향: 페이즈 4 #2 모델 명세에 위임. 본 명세에서는 `[FR-18.5]`로 시뮬레이터가 이 메타데이터를 채워야 한다는 책임만 명시(필드명 미확정).
  → **[FR-18.5]** 시뮬레이터는 각 `CombatAction`에 다음 메타데이터를 기록한다(페이즈 4 #2 모델에서 정식 필드 확정):
    - `position`(`entry`/`development`/`crisis`/`resolution`/`aftermath` 분류 — 라운드/액션 종류로 자동 매핑)
    - `skillId`(발동 스킬 ID nullable)
    - `statusEffectId`(부여/해제된 상태 효과 ID nullable)
    - `behaviorPattern`(액터가 적이면 enum, 파티이면 null)
    - `decisiveKeywordKey`(`combat_report_keywords.category == 'decisive'` 매칭 키 nullable)
    - `isComboCompression`(다중 결합 압축 여부 bool — [FR-18] §4 우선순위 결과)
  → 시뮬레이터는 메타데이터 **기록만** 책임지고, `combat_report_templates.scope == 'combat_skill'`(페이즈 3 #4 신규 scope 23행) 매칭은 `CombatReportService.generate(..., simulationResult)` 책임(페이즈 4 #3 위임). M8a 기존 96행 `combat_report_templates`는 `tags_json`에 메타가 부재해도 fallback으로 작동(페이즈 2 #4 §9.3).

- **[Q-4]** `objectiveProgress`는 어떻게 계산되는가? (호위·탐험류 의뢰에서만 의미가 있는가?)
  → 처리 방향: 본 명세는 다음 단순 정책을 채택한다.
    - 토벌·암살류 (적 진영 전멸이 목표): `objectiveProgress = 1.0 - (enemyHpRemainingTotal / enemyHpMaxTotal)`
    - 호위류 (호위 대상 생존 + 종점 도달): `pool.specialFlags['objective_progress']`가 있으면 사용, 없으면 적 HP 비율 기반 fallback
    - 탐험·조사류 (특정 라운드 도달 또는 적 처치율): `objectiveProgress = killedEnemyCount / requiredKillCount`
    - 기본값: `objectiveProgress = 1.0 - (enemyHpRemainingTotal / enemyHpMaxTotal)` (적 전멸 기반)
  → **[FR-10.2]** Phase 4에서 위 정책으로 `objectiveProgress` 산출. 정밀한 의뢰 유형별 정책은 페이즈 4 #5 검증에서 확정.

- **[Q-5]** 시뮬레이터 내부에서 `Random(seed ^ stableSeed32(...))` 인스턴스가 매 액션마다 새로 만들어지는 비용은 허용 가능한가?
  → 결정 방향: 결정성 + 단순성 우선. 한 전투 평균 6 라운드 × 양측 10명 × 7 액션 = ~420 PRNG 생성. 데스크탑 Flutter에서는 무시 가능 수준. 모바일 저사양 기기 우려 시 페이즈 4 #5 성능 테스트에서 재검토 위임.

- **[Q-6]** 추가 행동(`extraAction`) 정책: 트레잇 패시브로 발동되는 추가 행동은 라운드 시작 시 즉시 삽입하는가, 정렬 후 첫 행동 직전 삽입하는가?
  → 채택 정책(페이즈 1 #2 §9.3 + 페이즈 1 #4 §6.5):
    - 트레잇 패시브 추가 행동 (예: `swift_strike`): **라운드 시작 시 1회 추가 행동 슬롯 부여**. 정렬 결과의 자기 행동 직전에 1회 삽입.
    - 반격 (회피 성공 후): **회피 직후 즉시** 삽입.
    - 스킬 효과 (예: `quick_step` 다음 라운드 추가 행동): **다음 라운드 시작 시 1회 추가**.
    - 추가 행동에서 또 추가 행동 발생 금지. 반격에서 반격 발생 금지.
    - `mez_stunned` 보유자는 트레잇/스킬 추가 행동 차단, 반격은 정상.

- **[Q-7]** 본 명세 외 페이즈 4 #2~#5 산출물 의존 관계가 본 서비스 구현 가능 시점에 영향을 주는가?
  → 결정 방향:
    - **페이즈 4 #2 (freezed 모델) 선행 필수**: `CombatSimulationResult`/`CombatTurn`/`CombatAction`/`StatusEffectEvent`/`EnemyArchetype`/`EnemySnapshot`/`CombatSkill`/`CombatStatusEffect` 등 모델이 존재해야 본 서비스 컴파일 가능.
    - **페이즈 3 시드 데이터 필수**: `combat_skills` 16행 / `combat_status_effects` 10행 / `enemies` 26행이 영속화돼야 시뮬레이션 입력이 채워진다.
    - **페이즈 4 #3 (QuestCompletionService 통합) 후행**: 본 서비스가 먼저 구현되고, #3에서 호출 흐름 통합.
    - **페이즈 4 #4 (UI) 후행**: 시뮬레이션 결과 표시. 본 서비스 무관.
    - **페이즈 4 #5 (검증) 후행**: 결정성·종료 조건·산식 hook 단위 테스트. 본 명세는 placeholder 테스트만 권장.
  → 본 명세는 페이즈 4 #2 모델 정의가 선행됨을 가정한다. 페이즈 4 #2 모델 명세가 확정되기 전에 본 명세를 구현하면 컴파일 에러가 발생한다.

---

## 부록: 페이즈 1·2·3 산출물 ↔ 본 명세 매핑 표

| 페이즈 산출물 | 본 명세 반영 위치 |
|------------|---------------|
| 페이즈 1 #1 §전투 턴 구조 4 페이즈 | [FR-6]~[FR-10] |
| 페이즈 1 #1 §종료 조건 (a)~(f) | [FR-9] §5, [FR-10] §1 |
| 페이즈 1 #1 §CombatSimulationResult 11 필드 | [FR-4] |
| 페이즈 1 #1 §스냅샷 동결 정책 | [FR-6] §3~4 |
| 페이즈 1 #1 §시드 정책 | [FR-6] §1, [FR-19] |
| 페이즈 1 #1 §fallback | [FR-20] |
| 페이즈 1 #2 §2 선제 점수 | [FR-6] §9~11 |
| 페이즈 1 #2 §3 actionScore | [FR-9] §3 |
| 페이즈 1 #2 §4 직업군 매트릭스 2종 | 3.2 `combat_simulator_constants.dart` |
| 페이즈 1 #2 §5 트레잇 카테고리 매핑 | [FR-13] |
| 페이즈 1 #2 §6 환경 매트릭스 | 3.2 `combat_simulator_constants.dart` + [FR-13.5] |
| 페이즈 1 #2 §7 진형 + 표적 | [FR-6] §6, [FR-16] |
| 페이즈 1 #2 §8 회피/방패/반격 시퀀스 | [FR-11] §2~6 |
| 페이즈 1 #2 §9 다단 행동 | [FR-9] §4 |
| 페이즈 1 #2 §12 PRNG 분리 | [FR-12] |
| 페이즈 1 #3 §1~10 산식 | [FR-11], [FR-11.5] |
| 페이즈 1 #3 §11 노출 정책 | [FR-18] |
| 페이즈 1 #3 §14 PRNG 7 인스턴스 | [FR-12] |
| 페이즈 1 #4 §1 카탈로그 10 타입 | 2.2 데이터 요구사항 |
| 페이즈 1 #4 §3 결합 규칙 | [FR-17.5] |
| 페이즈 1 #4 §5 DoT 산식 | [FR-9] §1, §5, [FR-17.5] |
| 페이즈 1 #4 §6 stunned 처리 | [FR-9] §4 |
| 페이즈 1 #4 §7 stack_policy | [FR-17] §3 |
| 페이즈 1 #4 §8 dispel | [FR-17.5] |
| 페이즈 1 #4 §9 라운드 처리 순서 | [FR-9] |
| 페이즈 1 #4 §10 PRNG (apply/dispel) | [FR-12] |
| 페이즈 2 #1 §7 파티 자동 결정 트리 | [FR-14] |
| 페이즈 2 #1 §1.2 스킬 자동 보유 정책 | [FR-14] (전제) |
| 페이즈 2 #1 §8 적 측 공유 풀 | [FR-15] |
| 페이즈 2 #2 §8.3 적 측 behaviorPattern 결정 트리 | [FR-15] |
| 페이즈 2 #2 §12 매복 정책 | [FR-6] §10 |
| 페이즈 2 #3 §2 default 수치 | 시뮬레이터는 `staticData.combatStatusEffects`에서 default 읽음 |
| 페이즈 2 #3 §3 DoT stack 시뮬레이션 | [FR-17.5] proportional/absolute |
| 페이즈 2 #3 §4 결합 정책 | [FR-17.5] |
| 페이즈 2 #3 §6 default vs 오버라이드 | 시뮬레이터는 스킬의 `statusEffectIntensity`/`statusEffectDurationTurns` non-null 시 오버라이드 적용 |
| 페이즈 2 #3 §7 트레잇·환경 자동 부여 | [FR-13], [FR-13.5] |
| 페이즈 2 #4 §3 5 위치 분류 | [FR-18] §2~3, [FR-18.5] |
| 페이즈 2 #4 §8 다중 결합 우선순위 | [FR-18] §4 |
| 페이즈 2 #4 §9.2 신규 scope `combat_skill` | 2.2 데이터 요구사항 (페이즈 3 #4 위임), [FR-18.5] |
| 페이즈 2 #4 §10.3 라인 풀 활용 우선순위 | [FR-18] §5 |
| 페이즈 3 #1 enemies 26행 | `staticData.enemyArchetypes` (페이즈 4 #2 로드) |
| 페이즈 3 #2 combat_skills 16행 | `staticData.combatSkills` (페이즈 4 #2 로드) |
| 페이즈 3 #3 combat_status_effects 10행 | `staticData.combatStatusEffects` (페이즈 4 #2 로드) |
| 페이즈 3 #4 combat_report_templates 신규 85행 | `staticData.combatReportTemplates` (M8a 기존 96행 + M8b 85행 = 181행, `combat_skill` 23행 포함) |
