# M8b 검증 및 밸런스 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1 — 4 페이즈 흐름·종료 조건 6종·fail-soft)
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2 — |delta|≥15 선제·진영 합산 상한)
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3 — 클램프 5종·체인 주인공 90% 상한·라운드 권장 범위)
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4 — 10 상태 효과)
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1 — 16 스킬)
> - `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2 — 26 적 카탈로그)
> - `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md` (페이즈 2 #3 — 상태 효과 수치 + 다중 결합 시뮬)
> - `Docs/balance-design/[balance]20260519_m8b_combat_log_exposure.md` (페이즈 2 #4 — 길이 매트릭스·5 위치 분포·노출/비노출)
> - `Docs/content-data/[enemy]20260519_m8b-enemies.md` (페이즈 3 #1 — 26 시드)
> - `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.md` (페이즈 3 #2 — 16 시드)
> - `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.md` (페이즈 3 #3 — 10 시드)
> - `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.md` (페이즈 3 #4 — 85행 추가, 누적 181)
> - `Docs/spec/[spec]20260519_m8b_combat_simulator.md` (페이즈 4 #1 — `CombatSimulator.simulate` 시그니처·결정성·fail-soft)
> - `Docs/spec/[spec]20260519_m8b_phase4_models.md` (페이즈 4 #2 — `CombatReport` HiveField 8~14·구조 필드)
> - `Docs/spec/[spec]20260519_m8b_quest_completion_integration.md` (페이즈 4 #3 — eligible 평가·resultType override·fallback 5종·부록 B 위임 6 항목)
> - `Docs/spec/[spec]20260520_m8b_combat_report_ui.md` (페이즈 4 #4 — schemaVersion 분기·lineBudget·5 위치 색·decisive 배지)
>
> 작성일: 2026-05-20
> 마일스톤: M8b 페이즈 4 #5 (검증 및 밸런스)

## 1. 개요

페이즈 4 #1~#4에서 구현이 완료된 M8b 턴 전투 시뮬레이터·`QuestCompletionService` 통합·전투 보고서 UI 확장의 결정성·산식 범위·로그 노출 정책·M1~M8a 회귀를 한 번에 검증하는 명세다.

본 명세는 다음 5개 검증 영역으로 구성된다.

1. **결정성·결과 분포 검증** — 시드 입력에 대한 결정성, 4종 `QuestResult` 분포, 시뮬레이션 vs `QuestCalculator` fallback 결과 정합성
2. **부상·사망 빈도 검증** — 사망 저항 클램프 `[0.20, 0.80]`, 체인 주인공 사망 저항 90% 상한, T1~T5 부상·사망 분포
3. **로그 가독성 검증** — 라운드 수 ↔ 보고서 길이 매트릭스, 5 위치 분포, `lineBudget` 상한, decisive 배지 displayText lookup, 비노출 항목 미표시
4. **정적 검증 및 회귀 검증 계획** — `flutter analyze` 0 issues, `flutter test` 602 PASS 유지, 신규 테스트 합산 후 baseline 갱신
5. **M1~M8a 기능 회귀 검증 절차** — 일반 의뢰 `QuestCalculator` fallback, M8a `CombatReport`(schemaVersion null) 호환, 위업·칭호·지역 상태·체인·세력 평판 trailing hook 정합

본 명세는 신규 게임 로직을 추가하지 않는다. **신규 코드는 검증 도구(테스트 스위트·간단한 시뮬레이션 통계 스크립트)뿐**이며, 페이즈 4 #1~#4의 구현 본체는 변경하지 않는다. 검증 결과 산식 조정이 필요하면 별도 후속 명세로 분리한다.

또한 페이즈 4 #3 부록 B "페이즈 4 #5 검증·정밀화 위임 6 항목"을 본 명세에서 모두 처리한다(Q-3~Q-8 참조).

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.1 결정성·결과 분포 검증

- **[FR-1]** **시드 결정성 검증** — `CombatSimulator.simulate(seed: <고정>)` 호출은 동일 입력·동일 시드에 대해 `CombatSimulationResult.questResult`/`turns`/`injuredMercIds`/`deceasedMercIds`/`objectiveProgress`/`exitCondition`/`statusEffectHistory` 7 필드가 모두 동일해야 한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_simulator_determinism_test.dart` (신규)
  - 패턴: 동일 quest/party/pool/staticData/seed 입력으로 simulate를 2회 호출 → 결과 deep equality 확인.
  - 검증 시드 표본: `seed ∈ {1, 7, 13, 42, 100, 200, 500, 999}` (8 시드 × 3 quest 시나리오 = 24 케이스).
  - 시나리오: (a) 일반 엘리트, (b) 유니크 엘리트, (c) 체인 핵심 단계 + 엘리트 동반.

- **[FR-2]** **`stableSeed32` 안정 해시 검증** — 입력 문자열에 대해 Dart `String.hashCode`와 무관한 고정 출력을 보장.
  - 위치: `band_of_mercenaries/test/core/util/stable_seed_test.dart` (페이즈 4 #1 명세 §3.2에서 placeholder 권장. 미존재 시 신규 생성).
  - 표본 입력 5종 이상: `''`/`'a'`/`'merc_1|quest_a'`/`'dmg|0|123456'`/`'death|merc_a'`.
  - 동일 입력 → 동일 출력 (반복 호출 1000회 변동 0).
  - 다른 입력 → 다른 출력 (충돌 0/5).

- **[FR-3]** **`questResult` 분포 표본 통계** — 시뮬레이션과 fallback 양쪽 경로에서 4종 `QuestResult`(`greatSuccess`/`success`/`failure`/`criticalFailure`) 비율을 측정한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_simulator_distribution_test.dart` (신규)
  - 측정 방법: 시드 200개 × 3 시나리오 (T2 파티 4명 vs T2 적 3명, T3 vs T3, T4 vs T4) = 600 표본.
  - 검증 기준 (페이즈 1 #3 §12.3 라운드 권장 범위 정합):
    - T3 vs T3 (대칭 매치): `success ∈ [0.40, 0.70]`, `failure ∈ [0.15, 0.40]`, `criticalFailure ∈ [0.00, 0.10]`, `greatSuccess ∈ [0.00, 0.15]`.
    - 한쪽 우세 (T4 vs T2): 우세 측에서 `success + greatSuccess >= 0.70`.
    - 단, `expect`는 분포 비율의 ±0.10 마진 허용. 결정적 분포 검증이 아니라 회귀 검출용.
  - 시뮬레이션 vs fallback 동시 평가: 동일 시나리오에서 `combatSimulationEligible == true`로 시뮬레이션 경로 / `false`로 강제 분기한 fallback 경로를 각각 측정해 두 분포의 평균이 ±0.20 이내인지 확인.
  - 두 경로 평균 차이가 ±0.20을 초과하면 fail (Q-4의 시뮬레이션 vs fallback 분포 비교).

- **[FR-4]** **`combatSimulationEligible` 게이트 검증** — 페이즈 4 #3 [FR-3] 평가식을 다양한 케이스로 검증한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (기존 보강).
  - 매트릭스 (true/false 14 케이스 이상):
    | 케이스 | 기대 |
    |--------|------|
    | 일반 엘리트 의뢰 | true |
    | 유니크 엘리트 의뢰 | true |
    | 체인 최종 단계 | true |
    | `chain_core_step: true` 체인 핵심 단계 | true |
    | 체인 일반 단계 (`chain_core_step` 미설정) | false |
    | 거점 사건 체인 단계 (`isSettlementStep == true`) | false |
    | M6 지명 의뢰 (`pool.isNamed == true`) | true |
    | M8a 세력 지명 의뢰 (`pool.isNamed == true`) | true |
    | 세력 고급 트랙 의뢰 (`isAdvancedTrack == true`) | true |
    | 세력 기본 트랙 + 평판 31 | true |
    | 세력 기본 트랙 + 평판 30 | false |
    | 더스트빌 허드렛일 일반 의뢰 | false |
    | 일반 의뢰 (factionTag null) | false |
    | `pool == null` + `quest.isElite == true` | true |
  - 각 케이스에서 `result.combatSimulationEligible` 값이 위 표와 일치해야 한다.
  - `combatSimulationEligible == true && simulationResult == null`(fail-soft) 케이스에서 `result.resultType`이 `QuestCalculator` fallback과 일치해야 한다.

#### 2.1.2 부상·사망 빈도 검증

- **[FR-5]** **사망 저항 클램프 검증** — `CombatSimulator` 내부 사망 저항 산식이 페이즈 1 #3 §10 클램프를 준수하는지 확인한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_simulator_death_resistance_test.dart` (신규)
  - 검증 항목:
    - 일반 mercenary 200 시드 × 5 T(T1~T5) HP=1 vs 강력 적: `deceasedMercIds.length / 200 ∈ [0.20, 0.80]` 범위 내. T별 평균이 (1.00 - tier별 baseDeathResist) 부근에 위치 (페이즈 1 #3 §10.2 직업군 base 표).
    - 체인 주인공 (`quest.specialFlags['chain_protagonist_id'] == merc.id`): 일반 사망 저항 계산 후 `chance += (1.0 - chance) × 0.5`, 최종 상한 90%를 적용한다. T1 전사 기준 저항 40% → 70%이므로 200 시드 HP=1 vs 강력 적 표본에서 사망률 `<= 0.40`을 검증한다.
  - 검증 방식: simulate를 200회 반복하고 각 결과의 `deceasedMercIds.contains(merc.id)` 비율을 측정. 표본 수 200은 0.05 표준 오차 수용.
  - 클램프 위배 시(체인 주인공 사망률이 산식 기반 기대 범위를 초과) fail.

- **[FR-6]** **부상/사망 변환 결정성 검증** — 시뮬레이션 결과 → `MercDamageResult` 변환이 페이즈 4 #3 [FR-8] case a~c 분기 그대로인지 확인한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (기존 보강)
  - 검증 케이스:
    - case a (deceased + legendary ⑤ canPrevent == true) → `MercDamageResult.newStatus == injured`, `legendaryPreventedDeath == true`, `newCooldownUntil != null`, `damageRoll == 1.0`.
    - case a (deceased + legendary ⑤ canPrevent == false) → `MercDamageResult.newStatus == dead`, `damageRoll == 1.0`, `recoveryEndTime == null`.
    - case b (injured) → `newStatus == injured`, `damageRoll == 0.5`, `recoveryEndTime != null` (difficulty.level × 10분 / speedMultiplier × (1 - recoveryReduction) × passiveRecoveryMultiplier).
    - case c (생존 + 부상 없음) → `newStatus == tired`, `damageRoll == 0.0`, `recoveryEndTime != null` (5분 / speedMultiplier).
  - `injuredSet ∩ deceasedSet == ∅` 보장: simulate 200회 반복하여 두 집합 교집합 케이스가 발생하면 fail.

- **[FR-7]** **체인 주인공 사망 저항 hook 통합 검증** — `quest_provider._completeQuest`에서 `chain_protagonist_id` 런타임 플래그가 시뮬레이터로 정확히 전달되는지 확인한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (기존 보강) 또는 `quest_provider_test.dart` (신규)
  - 검증 항목:
    - non-settlement chain (`isSettlementStep == false`) + `ChainQuestProgress.protagonistMercId == 'merc_a'`인 의뢰 완료 시, 시뮬레이터에 전달된 `quest.specialFlags['chain_protagonist_id'] == 'merc_a'`.
    - settlement chain (`isSettlementStep == true`) 또는 `chainId == null`인 의뢰는 `chain_protagonist_id` 플래그가 병합되지 않는다.
  - 검증 방식: mock chainQuestRepository로 진행도를 주입하고 `QuestCompletionService.calculate` 호출 전후 `quest.specialFlags` 비교.

- **[FR-7.1]** **법정 부상/사망 통계 표본** — 페이즈 4 #3 부록 B 항목 5 "시뮬레이션 vs fallback의 부상/사망 분포 비교" 검증.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_simulator_distribution_test.dart` (FR-3과 동일 파일)
  - 측정 방법: T3 vs T3 600 표본 (FR-3과 동일 시드 풀)에서 부상자 비율, 사망자 비율을 시뮬레이션·fallback 양 경로에서 측정.
  - 검증 기준:
    - 시뮬레이션 경로 부상자 비율 / fallback 경로 부상자 비율 차이 ±0.15 이내.
    - 시뮬레이션 경로 사망자 비율 / fallback 경로 사망자 비율 차이 ±0.10 이내.
  - 차이가 기준을 초과하면 fail. 검증 결과는 산식 조정 후속 작업 트리거 — 본 명세에서는 임계값 위배만 검출하고 조정은 별도.

#### 2.1.3 로그 가독성 검증

- **[FR-8]** **라운드 수 ↔ 보고서 길이 매핑 검증** — 페이즈 2 #4 §2.1 매트릭스 정합.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` (기존 보강)
  - 매트릭스:
    | `report.turns.length` | 기대 `details.length` 범위 |
    |---|---|
    | 3 | 4 |
    | 4 | 5~6 |
    | 5 | 5~6 |
    | 6 | 6~7 |
    | 7 | 7~8 |
    | 8 | 7~8 |
  - 검증 방식: simulate로 다양한 라운드 결과를 만들고 `CombatReportService.generate(simulationResult:)` 반환의 `report.details.length`가 위 범위에 들어가는지 확인. importance veryHigh/high 시나리오는 상한 적용 후 검증.

- **[FR-9]** **5 위치 분포 검증** — 페이즈 2 #4 §3.2 보고서 길이별 위치 분포 매트릭스.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` (기존 보강)
  - 매트릭스:
    | 보고서 길이 | entry | development | crisis | resolution | aftermath |
    |---|---|---|---|---|---|
    | 4 | 1 | 1 | 1 | 1 | 0 |
    | 5 | 1 | 2 | 1 | 1 | 0 |
    | 6 | 1 | 2 | 1 | 1 | 1 |
    | 7 | 1 | 2 | 2 | 1 | 1 |
    | 8 | 1 | 3 | 2 | 1 | 1 |
  - 검증 방식: `CombatReport.turns`에 저장된 `CombatAction.position` 메타와 `report.details` 라인 수의 일치 여부 측정. 위치 분포는 5 라인 매트릭스 fallback이 가능하므로 ±1 마진 허용.

- **[FR-10]** **`lineBudget` 상한 검증** — 페이즈 4 #4 [FR-3] `lineBudget = report.details.isEmpty ? 4 : report.details.length.clamp(4, 8)` 정책.
  - 위치: `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` (기존 보강 — `VT-3` 테스트는 30 라운드 시나리오를 4로 압축하는 테스트가 이미 존재. 보강하여 4/5/6/7/8 lineBudget을 명시적으로 검증).
  - 검증 케이스:
    - `report.details.length == 0` + `report.turns.length == 30` → 라운드 액션 라인 4개만 표시.
    - `report.details.length == 4` + `report.turns.length == 30` → 라운드 액션 라인 4개.
    - `report.details.length == 7` + `report.turns.length == 30` → 라운드 액션 라인 7개.
    - `report.details.length == 9` (overflow) + `report.turns.length == 30` → 라운드 액션 라인 8개 (clamp(4, 8) 상한).

- **[FR-11]** **decisive 배지 displayText lookup 검증** — 페이즈 4 #4 [FR-6] 정책.
  - 위치: `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` (기존 보강 — `VT-4` 테스트 보강).
  - 검증 케이스:
    - `decisiveKeywordKey == 'silenced_arcana'` + `combatReportKeywords`에 동일 key 등록 시 → 위젯 텍스트에 등록된 `displayText` 노출.
    - `decisiveKeywordKey == 'unregistered_key'` + `combatReportKeywords`에 미등록 시 → 위젯 텍스트에 "결정적 장면" 노출. raw key가 UI에 노출되지 않음을 확인.
    - `decisiveKeywordKey == null` → 배지 미렌더링.

- **[FR-12]** **비노출 항목 미표시 검증** — 페이즈 2 #4 §4.2 비노출 매트릭스 14 항목 중 핵심 항목.
  - 위치: `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` (기존 보강 — `VT-5` 테스트 보강)
  - 검증 항목 (위젯 트리에 다음 텍스트 미존재):
    - `damageRoll` 값 (`'1.0'` / `'0.5'` / `'0.0'`).
    - `seed` 값.
    - `actionScore` 값.
    - HP 절대값 (예: `'HP 120/200'`).
    - `intensity` 값 (예: `'intensity 0.30'`).
    - 명중률·회피율·치명타율·사망 저항률 백분율 표기 (예: `'명중률 85%'`).
  - 검증 방식: `find.textContaining(...)`로 위 패턴이 위젯 트리에 존재하지 않음을 확인. 위 항목이 위젯에 노출되면 fail.

- **[FR-12.1]** **schemaVersion 분기 검증** — 페이즈 4 #4 [FR-1] 정책.
  - 위치: `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` (기존 `VT-1`/`VT-2` 보강)
  - 검증 케이스:
    - `report.schemaVersion == null` → 라운드 로그 섹션 위젯 미존재 (M8a 호환).
    - `report.schemaVersion == 1 && report.turns == null` → 라운드 로그 섹션 미존재 (M8b이지만 turns 없음 → 안전 처리).
    - `report.schemaVersion == 1 && report.turns != null` → 라운드 로그 섹션 위젯 존재.

#### 2.1.4 정적 검증 및 회귀 검증 계획

- **[FR-13]** **정적 검증** — 신규 테스트 추가 후 `flutter analyze`가 0 issues로 통과해야 한다.
  - 명령어: `cd band_of_mercenaries && flutter analyze`
  - 통과 기준: stdout 마지막 라인 `No issues found!`.
  - 실패 시 fail. 권장 수정 방향:
    - `avoid_print` lint 위반 시 `debugPrint`로 교체.
    - unused import 제거.
    - lints 위반 (`prefer_const_constructors` 등)은 본 명세 검증 단계에서 수정.

- **[FR-14]** **전체 테스트 회귀** — 신규 테스트 추가 후 `flutter test`가 모두 PASS해야 한다.
  - 명령어: `cd band_of_mercenaries && flutter test`
  - 통과 기준: 현재 baseline 602 PASS + 본 명세 신규 테스트 추가분 = N PASS 이상. 신규 테스트 수는 본 명세 §3.2의 신규 파일 수와 일치.
  - 실패 시 fail. M8b 페이즈 4 #4까지의 회귀 보호는 본 명세 검증의 책임이다.

- **[FR-15]** **신규 테스트 통합 후 baseline 갱신** — `flutter test` 통과 시 본 마일스톤의 PASS 카운트를 CLAUDE.md "테스트 구조" 섹션에 갱신한다.
  - 갱신 위치: `CLAUDE.md` 테스트 구조 섹션 "전체 테스트 593 PASS(M8b 페이즈 4 시점)" 문장 (이미 페이즈 4 #4 구현 후 602로 변경됨, 본 명세 신규 테스트 추가 시 더 증가).
  - 갱신 방향: 본 명세 신규 테스트 파일 수만큼 추가된 합산 카운트로 갱신.

#### 2.1.5 M1~M8a 기능 회귀 검증 절차

- **[FR-16]** **일반 의뢰 `QuestCalculator` fallback 보장** — 시뮬레이션 비대상 의뢰는 페이즈 4 이전과 동일 결과를 유지해야 한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (기존 보강)
  - 검증 케이스:
    - 일반 의뢰 (factionTag null, isElite false, isChainQuest false, pool.isNamed false) 완료 → `result.combatSimulationEligible == false`, `result.simulationResult == null`, `result.resultType`이 페이즈 4 #3 [FR-4] §3 fallback (기존 `QuestCalculator` random roll + `LegendaryResultUpgrade`) 경로와 동일.
    - `result.mercDamages`가 기존 페이즈 4 #3 [FR-8.2] 데미지 루프 (line 335~436) 결과와 동일.

- **[FR-17]** **M8a `CombatReport` 호환 보장** — `simulationResult == null` 경로에서 페이즈 4 #2 신규 HiveField 8~14가 모두 null이거나 default여야 하며, 기존 M8a UI 표시가 변하지 않아야 한다.
  - 위치: `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` (기존 보강)
  - 검증 케이스:
    - `CombatReportService.generate(simulationResult: null, ...)` 호출 → 반환 `CombatReport.schemaVersion == null`, `turns == null`, `combatantSnapshots == null`, `exitCondition == null`, `objectiveProgress == null`, `enemySnapshots == null`, `statusEffectHistory == null`.
    - 동일 입력으로 M8a baseline (`combat_report_service_test.dart` 기존 케이스)과 `summary`/`details`가 동일.

- **[FR-17.1]** **`QuestResultDialog` M8a UI 호환 보장** — 페이즈 4 #4 [FR-1] 분기에서 `schemaVersion == null` 경로는 기존 `_buildDetailView` 위젯 트리와 동일해야 한다.
  - 위치: `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` (기존 `VT-1` 보강)
  - 검증 케이스:
    - M8a 보고서 입력 시 라운드 로그 섹션·ExitCondition 배지·LinearProgressIndicator 미존재.
    - M8a 보고서 입력 시 protagonist/featured Chip Wrap 존재 (M8a 4 #2에서 도입).

- **[FR-18]** **위업·칭호 trailing hook 정합 검증** — 페이즈 4 #3 [FR-15] 성공·대성공 guard 보장.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` 또는 `quest_provider_test.dart` (신규 가능)
  - 검증 케이스:
    - **엘리트 유니크 첫 처치 위업**:
      - `quest.isElite && eliteData.isUnique && result.resultType ∈ {success, greatSuccess}` → `AchievementService.grant('elite_unique_first_kill:$eliteId', ...)` 호출 (mock 검증).
      - `quest.isElite && eliteData.isUnique && result.resultType ∈ {failure, criticalFailure}` → grant 호출 안 함.
    - **엘리트 region_state trailing** (`eliteRegionStateMapping`):
      - 성공/대성공 → flag toggle 또는 dangerScore 적용.
      - 실패/대실패 → 적용 안 함.

- **[FR-18.1]** **사망 memorial hook 정합 검증** — `damage.newStatus == MercenaryStatus.dead` 자연 호환.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (기존 보강)
  - 검증 케이스:
    - 시뮬레이션 경로에서 deceasedMercId 발생 → `MercDamageResult.newStatus == dead` → memorial hook 정상 발화 (mock 검증).
    - legendary ⑤ canPrevent 적용 시 dead 다운그레이드 → memorial hook 발화 안 함.

- **[FR-18.2]** **부상 status hook 정합 검증** — M6 페이즈 4 #2 `TitleService.evaluateStatusHook` 호환.
  - 위치: `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (기존 보강)
  - 검증 케이스: 시뮬레이션 경로 injured mercenary → status hook 평가 호출 (mock 검증).

- **[FR-19]** **체인·세력 평판 trailing 호환** — 본 명세 신규 검증 영역 외, 기존 테스트 보존.
  - 검증 방식: `quest_completion_service_test.dart` / `quest_completion_legendary_test.dart` / `quest_completion_side_effects_test.dart` 기존 케이스가 PASS 상태 유지.
  - 본 명세에서 추가 테스트 없음. flutter test 회귀 (FR-14)로 자연 검증.

#### 2.1.6 페이즈 4 #3 부록 B 위임 6 항목 처리

- **[FR-20]** **부록 B 항목 1: `chain_core_step` 플래그 운영 여부**
  - 처리 방향: M8b MVP는 `chain_quests` 시드에 `chain_core_step` 플래그를 **추가하지 않는다**. 보조 조건(`quest.isElite || quest.eliteId != null`)만으로 체인 핵심 단계를 식별한다.
  - 근거: 현재 `chain_quests` 26단계 (M7 페이즈 4 #4 mist_clearing 2 단계 추가 후) 중 엘리트 동반 단계 가시 비율이 충분하며, 추가 플래그는 데이터 운영 비용만 늘린다. M9+에서 정밀화 필요 시 플래그 도입.
  - 검증: `quest_completion_service_test.dart`의 `_isChainSimulationStep` 단위 테스트에서 `chain_core_step == null` + 엘리트 동반 케이스가 true로 평가됨을 보장.

- **[FR-21]** **부록 B 항목 2: 시뮬레이션 활성 의뢰의 `LegendaryResultUpgrade` 적용 정책**
  - 처리 방향: 시뮬레이션 결정 결과는 final로 유지(페이즈 4 #3 [FR-4] §4 기존 정책 유지). `LegendaryResultUpgrade`는 fallback 경로에만 적용한다.
  - 근거: 시뮬레이션이 결정한 라운드 로그와 `LegendaryResultUpgrade`로 승격된 `resultType` 사이 서사 불일치 위험. M8b MVP는 결정성·서사 일관성 우선.
  - 검증: `quest_completion_service_test.dart`에서 시뮬레이션 활성 의뢰 + legendary ② 보유 시 `result.resultType == simulationResult.questResult` 확인. `LegendaryResultUpgrade.upgradedToGreatSuccess == false`인지 검증.

- **[FR-22]** **부록 B 항목 3: `damageRoll` 의미 변경의 `MercenaryStatService.updateStatsAfterQuest` 호환성**
  - 처리 방향: `MercenaryStatService.updateStatsAfterQuest`는 `MercDamageResult.damageRoll`을 read해 행동 지표 갱신에 사용하므로, 시뮬레이션 경로의 1.0/0.5/0.0 매핑이 기존 행동 지표 분포와 호환되는지 확인한다.
  - 검증: `band_of_mercenaries/test/features/mercenary/domain/mercenary_stat_service_test.dart` (기존이 있다면 보강 / 없다면 신규) — case a (damageRoll 1.0) → 사망 지표 증가, case b (damageRoll 0.5) → 부상 지표 증가, case c (damageRoll 0.0) → 무사 처리. 기존 random damageRoll 분포의 평균 (각 케이스 약 0.33)과 1.0/0.5/0.0 고정값이 같은 분기로 평가되는지 확인.
  - **[Q-1]** `MercenaryStatService`의 `damageRoll` 사용 분기가 단순 threshold 비교(`damageRoll > 0.5`?)인지, 누적 가중치인지 코드베이스 탐색으로 확인 후 검증 케이스를 확정한다. 누적 가중치라면 본 명세에서 산식 조정 후속 작업을 트리거할 수 있다.

- **[FR-23]** **부록 B 항목 4: 부상자 `recoveryEndTime`에 시뮬레이션 DoT 누적량 반영 검토**
  - 처리 방향: M8b MVP는 반영하지 않는다 (페이즈 4 #3 Q-4 채택). 기존 산식(`difficulty.level × 10분 / speedMultiplier × (1 - recoveryReduction) × passiveRecoveryMultiplier`) 유지.
  - 근거: DoT stack은 시뮬레이션 도중 동적 변동하며 보고서 영속 필드와 부상 회복 시간을 결합하면 사용자에게 불투명한 가변값이 노출된다. M9+에서 정밀화 검토.
  - 검증: `quest_completion_service_test.dart`에서 시뮬레이션 결과 DoT stack 3 부상자의 `recoveryEndTime`이 기존 산식과 동일한지 확인.

- **[FR-24]** **부록 B 항목 5: 시뮬레이션 vs fallback 부상/사망 분포 비교**
  - 처리: 본 명세 [FR-7.1]에서 처리.

- **[FR-25]** **부록 B 항목 6: `CombatReport.summary/details` 시뮬레이션 기반 문장 품질**
  - 처리 방향: M8b 범위 외. M8.5/M9 위임.
  - 근거: 페이즈 4 #4 [FR-9]에서도 "본 명세는 데미지/킬 카운트 표시를 포함하지 않는다 ... 후속 마일스톤(M8.5)에서 보고서 카드 영상화·통계 화면 도입 시 확장 위임"으로 명시.
  - 검증: 본 명세는 문장 품질 자체를 검증하지 않는다. 현재 라인 풀(M8a 96 + M8b 85 = 181)이 페이즈 4 #4 lineBudget 압축에서 정상 활용되는지만 확인 (FR-8~FR-10).

### 2.2 데이터 요구사항

- 신규 Hive 박스: 없음
- 신규 정적 데이터 모델: 없음
- 신규 enum: 없음
- 밸런스 수치: 없음 (검증 임계값은 모두 [FR-3]/[FR-5]/[FR-7.1]에 명시)

본 명세는 신규 게임 데이터를 추가하지 않는다.

### 2.3 UI 요구사항

해당 없음. 본 명세는 검증 도구·테스트 추가만 다룬다. UI 자체는 페이즈 4 #4에서 확정됨.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | (a) `combatSimulationEligible` 매트릭스 14 케이스 보강 (FR-4). (b) 시뮬레이션 → MercDamageResult 변환 case a~c 검증 보강 (FR-6). (c) 일반 의뢰 fallback 결과 회귀 보장 (FR-16). (d) 위업/region_state trailing 성공·대성공 guard 검증 (FR-18). (e) 사망 memorial hook (FR-18.1). (f) 부상 status hook (FR-18.2). (g) `LegendaryResultUpgrade` 적용 안 함 검증 (FR-21). (h) DoT 누적량 미반영 검증 (FR-23). | M8b 통합 회귀 |
| `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` | (a) 라운드 수 ↔ 보고서 길이 매트릭스 검증 (FR-8). (b) 5 위치 분포 검증 (FR-9). (c) `simulationResult == null` 경로 M8a 호환 검증 (FR-17). | 보고서 생성 회귀 |
| `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` | (a) `lineBudget` 상한 4/5/6/7/8 명시 검증 (FR-10). (b) decisive 배지 lookup 보강 (FR-11). (c) 비노출 항목 14종 핵심 미표시 (FR-12). (d) schemaVersion 분기 보강 (FR-12.1). (e) M8a `_buildDetailView` 위젯 트리 호환 (FR-17.1). | UI 회귀 |
| `band_of_mercenaries/CLAUDE.md` (테스트 구조 섹션) | "전체 테스트 N PASS" 문장 갱신 (FR-15). 본 명세 신규 테스트 추가 후 합산 카운트 반영. | 문서 동기화 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_determinism_test.dart` | FR-1 시드 결정성 검증 (24 케이스) |
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_distribution_test.dart` | FR-3/FR-7.1 결과 분포·부상/사망 분포 비교 검증 (600 표본 × 2 경로) |
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_death_resistance_test.dart` | FR-5 사망 저항 클램프·체인 주인공 잔여 사망 확률 절반 보정 검증 |
| `band_of_mercenaries/test/core/util/stable_seed_test.dart` (페이즈 4 #1 §3.2 권장 — 미존재 시 신규 생성) | FR-2 `stableSeed32` 안정 해시 검증 |
| `band_of_mercenaries/test/features/quest/domain/quest_provider_chain_protagonist_test.dart` (선택, FR-7 검증을 별도 파일로 분리할 경우) | `_completeQuest`의 `chain_protagonist_id` 병합 검증 |

신규 파일 수: 최대 5개. 기존 파일 보강이 가능하면 `quest_provider_chain_protagonist_test.dart`를 `quest_completion_service_test.dart`에 흡수해 4개로 줄일 수 있다(구현 시점 판단).

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| 없음 | freezed/Hive 모델 변경 없음. `build_runner` 실행 불필요. |

### 3.4 관련 시스템

- **CombatSimulator (페이즈 4 #1)**: 결정성·산식 클램프·체인 주인공 사망 저항·DoT 누적 시뮬 모두 본 명세 검증 대상. 코드 본체 변경 없음.
- **QuestCompletionService (페이즈 4 #3)**: eligible 평가·resultType override·MercDamageResult 변환·위업/region_state guard·`LegendaryResultUpgrade` 미적용 모두 본 명세 검증 대상. 코드 본체 변경 없음.
- **CombatReportService (페이즈 4 #3 확장)**: simulationResult 경로/null 경로 모두 본 명세 검증 대상. 코드 본체 변경 없음.
- **QuestResultDialog (페이즈 4 #4)**: schemaVersion 분기·lineBudget·5 위치 색·decisive 배지·비노출 매트릭스 모두 본 명세 검증 대상. 코드 본체 변경 없음.
- **MercenaryStatService (M2a)**: `damageRoll` 사용 분기. 본 명세 [Q-1] 확인 대상.
- **AchievementService (M6)**: 엘리트 유니크 첫 처치 위업 grant. 본 명세 FR-18 검증 대상.
- **TitleService (M6)**: 부상 status hook. 본 명세 FR-18.2 검증 대상.
- **RegionStateRepository (M7)**: 엘리트 region_state trailing. 본 명세 FR-18 검증 대상.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `band_of_mercenaries/test/features/quest/domain/combat_simulator_test.dart:84` — 200 시드 반복 패턴 (사망 저항 검증에 그대로 활용 가능). seed for-loop + `if (result == null) continue` + 비율 측정.
- `band_of_mercenaries/test/features/quest/domain/combat_simulator_test.dart:18~64` — `_quest`/`_pool`/`_staticData`/`_merc`/`_enemy`/`_userData` 헬퍼 패턴. 신규 분포·결정성 테스트도 동일 헬퍼 재사용.
- `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` — `QuestCompletionResult` 매트릭스 검증 패턴. eligible 14 케이스 추가 시 동일 형태.
- `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart:1~15` — VT-1~VT-6 6 검증 영역 + Hive 어댑터 `registerIfAbsent` 패턴. lineBudget/decisive 보강 시 동일 형태.
- `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` — `simulationResult` 입력 + 출력 구조 필드 검증 패턴 (페이즈 4 #3 이미 활용).
- `band_of_mercenaries/test/features/quest/domain/named_hook_evaluator_test.dart` — 매트릭스 기반 단위 테스트 형태(다수 케이스를 group + nested test로 표현). eligible 매트릭스 14 케이스 표현에 적합.

### 4.2 주의사항

- **검증 표본 수**: 시드 200~600 표본은 매트릭스 검증·결정성 검증 모두 충분하다. 표본 수를 늘리면 CI 시간이 증가하므로 200/600 그대로 유지한다.
- **`expect` 마진 정책**: 분포 검증은 절대값이 아닌 비율 범위로 검증한다. ±0.10 ~ ±0.20 마진은 회귀 검출용이며, 산식 조정 트리거가 아닌 fail은 false-positive다. 마진 초과 시 즉시 fail로 처리하지 말고 본 명세 [FR-7.1] 검증 결과를 후속 산식 조정 작업으로 분리한다.
- **`flutter test` 단일 실행**: 모든 신규 테스트가 `flutter test` 한 번에 통합되어야 한다. 별도 명령어로 분리 실행 금지(CI 단순화).
- **헬퍼 재사용**: 신규 결정성·분포 테스트는 `combat_simulator_test.dart`의 `_quest`/`_pool`/`_staticData`/`_merc`/`_enemy`/`_userData` 헬퍼를 import해 재사용한다. 헬퍼 중복 정의 금지.
  - 단, 헬퍼가 `combat_simulator_test.dart` 내부 private이라면 `band_of_mercenaries/test/features/quest/domain/_combat_test_helpers.dart` (신규)로 추출하여 4 신규 테스트가 공유한다. 추출 여부는 구현 시점 판단.
- **`debugPrint` 사용**: 검증 도구의 통계 출력은 `print` 대신 `debugPrint` 사용. `avoid_print` lint 위반 방지 (FR-13).
- **CI 시간 영향**: 200 시드 × 결정성 24 케이스 + 600 표본 × 분포 = 약 5~10초 추가. 현재 `flutter test` 약 30초 수행 시간 기준 +30% 수용 범위.
- **mock 패턴**: AchievementService/TitleService/RegionStateRepository trailing 검증은 실제 서비스 호출 대신 mock 또는 fake 객체 사용. 기존 `quest_completion_side_effects_test.dart`의 mock 패턴을 그대로 따른다.

### 4.3 엣지 케이스

- **시뮬레이션 결과 `null`이지만 `combatSimulationEligible == true`**: 분포 검증에서 시뮬레이션 표본이 줄어든다. 표본 수 200 이하로 떨어지면 분포 검증을 skip하고 fail-soft 발생 빈도만 별도 표시.
- **legendary ⑤ 쿨다운 진행 중**: case a §1 평가가 false → dead 처리. 200 표본 시뮬레이션에서 legendary ⑤를 가지지 않은 mercenary로 시드하면 분기 단순화.
- **체인 주인공이 파티에 없음**: FR-5 검증에서 `chain_protagonist_id`를 명시적으로 설정하지 않은 케이스. 일반 클램프 [0.20, 0.80]만 검증.
- **`flutter analyze` warning vs error**: warning은 통과 허용. error만 fail. `analysis_options.yaml`에 `avoid_print: true` 활성화되어 있으므로 `print` 사용은 자동 error.
- **테스트 간 격리**: 4 신규 테스트 파일은 모두 `setUp`/`tearDown` 없이 stateless하게 작성. Hive 박스 사용 시 `Hive.initFlutter(testDir)` + 테스트 종료 후 `Hive.close()`.
- **CI 환경의 시간 가속**: `userData.speedMultiplier` 기본값 1.0 유지. 시간 가속 환경에서는 case b/c의 `recoveryEndTime` 절대값이 달라지므로 마진 검증 또는 비율 검증으로 대체.

### 4.4 구현 힌트

- **진입점**: 본 명세는 코드 본체 진입점이 없다. 4 신규 테스트 파일 + 3 기존 테스트 보강이 전부.
- **데이터 흐름**:
  ```
  test 진입
    → 헬퍼 (_quest/_pool/_merc/_enemy/_staticData/_userData)로 시뮬레이션 입력 구성
    → CombatSimulator.simulate(seed: <고정>) 또는 QuestCompletionService.calculate(...)
    → 결과 필드 검증 (expect / matcher)
    → 200~600 표본 반복 시 분포 비율 측정 → 임계값 비교
  ```
- **참조 구현**:
  - `combat_simulator_test.dart:84~120` — 200 시드 반복 + injuredMercIds 검증 (FR-5 사망 저항 패턴 동일)
  - `quest_completion_service_test.dart` 기존 케이스 — `_setupResult` 헬퍼 + `expect(result.combatReportEligible, true)` 패턴 (FR-4 eligible 매트릭스 그대로 활용)
  - `quest_result_dialog_test.dart:VT-3` — 30 라운드 시나리오 + lineBudget 4 검증 (FR-10 lineBudget 4/5/6/7/8 매트릭스 확장 시 그대로 활용)
  - `combat_report_service_test.dart` — `simulationResult` 입력 + 구조 필드 검증 (FR-8/FR-9 길이·위치 분포 검증에 그대로 활용)
- **확장 지점**:
  - 본 명세 검증 결과 분포 임계값 위배가 다수 발견되면, 페이즈 4 #1 산식 매트릭스 조정 후속 명세를 분리한다.
  - `MercenaryStatService.damageRoll` 분기가 누적 가중치라면 (Q-1), 별도 산식 조정 명세로 분리한다.

## 5. 기획 확인 사항

- **[Q-1]** `MercenaryStatService.updateStatsAfterQuest`의 `damageRoll` 사용 분기 (단순 threshold 비교 / 누적 가중치)
  → 처리 방향: **본 명세 구현 시점에 `mercenary_stat_service.dart` 코드를 Read로 확인한 후 검증 케이스 확정**. 누적 가중치라면 본 명세 검증 결과를 산식 조정 후속 명세 트리거로 사용한다. M8b MVP는 시뮬레이션 1.0/0.5/0.0 매핑 그대로 유지 (페이즈 4 #3 Q-3 결정).

- **[Q-2]** 분포 검증 임계값 ±0.10 / ±0.15 / ±0.20 마진의 정확성
  → 처리 방향: **본 명세 [FR-3] / [FR-5] / [FR-7.1]에 명시된 마진 그대로 채택**. 표본 200~600에서 통계적 표준 오차(약 0.02~0.04)의 3~5배로 설정하여 산식 미세 조정이 검증 마진 안에 들어가도록 했다. 향후 표본 수 또는 매트릭스를 정밀화할 때 마진을 좁힌다.

- **[Q-3]** 체인 핵심 단계 식별 — `chain_core_step` 플래그 운영 여부
  → 처리 방향: **FR-20 채택**. M8b MVP는 플래그 미운영, 보조 조건(엘리트 동반)만 사용. M9+에서 정밀화.

- **[Q-4]** 시뮬레이션 활성 의뢰의 `LegendaryResultUpgrade` 적용 정책
  → 처리 방향: **FR-21 채택**. 시뮬레이션 결정 결과 final, fallback만 적용.

- **[Q-5]** `damageRoll` 의미 변경의 `MercenaryStatService` 호환성
  → 처리 방향: **FR-22 채택 + [Q-1] 확인**. 시뮬레이션 1.0/0.5/0.0 매핑 호환성을 코드 탐색으로 확인.

- **[Q-6]** `recoveryEndTime`에 DoT 누적량 반영
  → 처리 방향: **FR-23 채택**. M8b MVP는 미반영.

- **[Q-7]** 시뮬레이션 vs fallback 부상/사망 분포 비교
  → 처리 방향: **FR-7.1 / FR-24 채택**. 600 표본 × 2 경로 측정. 마진 위배 시 후속 산식 조정 명세 트리거.

- **[Q-8]** `CombatReport.summary/details` 시뮬레이션 기반 문장 품질 개선
  → 처리 방향: **FR-25 채택**. M8b 범위 외, M8.5/M9 위임.

- **[Q-9]** 검증 도구가 발견한 임계값 위배의 처리 정책
  → 처리 방향: **본 명세 검증 자체는 임계값 위배만 검출**. 산식·매트릭스 조정은 별도 후속 작업으로 분리. 검증 실패 즉시 PR 차단 정책이 아니라 후속 산식 조정 트리거. 단, FR-13/FR-14 (analyze 0 issues / flutter test PASS)는 즉시 PR 차단 대상.

- **[Q-10]** 신규 테스트의 CI 시간 영향 수용 범위
  → 처리 방향: **+30% (5~10초)까지 수용**. 200/600 표본은 그대로 유지. 표본 수를 늘려야 한다면 별도 통계 분석 명세로 분리(예: `combat_simulator_statistics_report.md`).

## 6. 검증 계획

본 명세 자체가 검증 계획이지만, 본 명세 구현(테스트 추가) 후 다음 절차를 수행한다.

### 6.1 정적 검증

```bash
cd band_of_mercenaries && flutter analyze
```

통과 기준: `No issues found!`. 실패 시 신규 테스트 수정 후 재시도.

### 6.2 전체 회귀 테스트

```bash
cd band_of_mercenaries && flutter test
```

통과 기준: 모든 테스트 PASS. baseline 602 + 본 명세 신규 테스트 추가분 = 신규 PASS 수.

### 6.3 신규 테스트 단독 실행 (선택)

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/combat_simulator_determinism_test.dart
cd band_of_mercenaries && flutter test test/features/quest/domain/combat_simulator_distribution_test.dart
cd band_of_mercenaries && flutter test test/features/quest/domain/combat_simulator_death_resistance_test.dart
cd band_of_mercenaries && flutter test test/core/util/stable_seed_test.dart
```

### 6.4 CLAUDE.md 갱신

`flutter test` 통과 후 CLAUDE.md "테스트 구조" 섹션의 "전체 테스트 N PASS" 카운트를 신규 합산으로 갱신한다.

### 6.5 분포 검증 임계값 위배 시 대응

[FR-3] / [FR-5] / [FR-7.1] 임계값 위배가 발생하면:
1. 위배된 표본 수 / 임계값 / 실측값을 디버그 출력으로 캡처한다.
2. 산식 조정이 필요한 영역 (페이즈 4 #1 산식 매트릭스 / 페이즈 4 #3 변환 알고리즘)을 식별한다.
3. 별도 산식 조정 명세를 작성한다 (`Docs/spec/[spec]20260520_m8b_balance_adjustment.md` 등).
4. 본 명세는 임계값 위배 검출 자체를 PASS로 처리하고, 산식 조정은 후속 단계로 분리한다.

### 6.6 M1~M8a 기능 회귀

`flutter test` 통과 시 자동 회귀. 추가 수동 회귀가 필요하면 다음 시나리오:

- 일반 의뢰 (factionTag null, isElite false) 완료 → 보상/XP/명성/부상 분기 기존과 동일.
- M8a 보고서 (schemaVersion null) 결과 다이얼로그 → 라운드 로그 섹션 미노출, M8a UI 그대로.
- 체인 의뢰 (`chain_protagonist_id` 보유) 시뮬레이션 → 체인 주인공 사망 저항 90% 상한 적용.
- 세력 평판 추이: 시뮬레이션 활성 세력 의뢰 (고급 트랙 또는 평판 31+) 완료 후 평판 변동이 페이즈 4 #3 [FR-7.1]/[FR-7.2]와 동일.
- 위업 grant: 유니크 엘리트 첫 처치 (성공) → 위업 발급. 유니크 엘리트 실패/대실패 → 위업 미발급 (FR-18).

---

## 부록 A: 신규 테스트 파일별 케이스 수 합산

| 파일 | 신규 케이스 | 보강 케이스 |
|------|------------|------------|
| `combat_simulator_determinism_test.dart` | 24 (8 시드 × 3 시나리오) | — |
| `combat_simulator_distribution_test.dart` | 6 (T2/T3/T4 × 2 경로) | — |
| `combat_simulator_death_resistance_test.dart` | 6 (5 tier 일반 + 1 체인 주인공) | — |
| `stable_seed_test.dart` | 7 (5 입력 케이스 + 충돌 검증 + 반복 결정성) | — |
| `quest_completion_service_test.dart` | — | 약 20 (FR-4 14 + FR-6 4 + FR-16 + FR-18 + FR-21 + FR-23) |
| `combat_report_service_test.dart` | — | 약 8 (FR-8 6 + FR-9 + FR-17) |
| `quest_result_dialog_test.dart` | — | 약 8 (FR-10 5 + FR-11 + FR-12 + FR-12.1 + FR-17.1) |
| `mercenary_stat_service_test.dart` (조건부, [Q-1] 결과에 따름) | 약 3 (1.0/0.5/0.0 매핑) | — |
| **합계** | 약 43~46 | 약 36 |

신규 테스트 추가분 약 43~46개로, baseline 602 → 약 645~650 PASS 예상.

## 부록 B: 검증 결과의 후속 작업 매핑

본 명세의 검증 결과가 다음 임계값을 위배하면 별도 후속 명세를 작성한다.

| 위배 항목 | 후속 명세 후보 |
|-----------|---------------|
| FR-3 분포 마진 (±0.10/0.20) 위배 | 페이즈 4 #1 산식 매트릭스 조정 (`Docs/spec/[spec]_m8b_balance_formula_adjustment.md`) |
| FR-5 체인 주인공 사망률이 산식 기반 기대 범위를 초과 | 페이즈 4 #1 사망 저항 산식 조정 또는 체인 주인공 가중치 정밀화 |
| FR-7.1 시뮬레이션 vs fallback 분포 차이 위배 | 페이즈 4 #3 [FR-8] 변환 알고리즘 또는 페이즈 4 #1 시뮬레이션 산식 조정 |
| FR-8 보고서 길이 매트릭스 위배 | 페이즈 4 #1 라인 압축 알고리즘 ([FR-18]) 조정 |
| FR-9 5 위치 분포 위배 | 페이즈 4 #1 보고서 라인 위치 메타 매핑 조정 |
| FR-11 decisive raw key 노출 | 페이즈 4 #4 위젯 fallback 강화 |
| FR-12 비노출 항목 노출 | 페이즈 4 #4 위젯 코드 즉시 수정 (PR 차단 대상) |
| FR-13 analyze issues > 0 | 본 명세 신규 테스트 즉시 수정 (PR 차단 대상) |
| FR-14 flutter test FAIL | 본 명세 신규 테스트 또는 기존 코드 수정 (PR 차단 대상) |

PR 차단 대상은 FR-12 / FR-13 / FR-14 3 항목으로 한정한다. 그 외 분포 임계값 위배는 후속 작업 트리거이며 본 명세 자체의 검증은 통과 처리.

## 부록 C: 페이즈 1~4 산출물 ↔ 본 명세 매핑 표

| 페이즈 산출물 | 본 명세 검증 영역 |
|------------|----------------|
| 페이즈 1 #1 §4 페이즈 흐름 / §종료 조건 6종 | FR-1 결정성 / FR-3 분포 |
| 페이즈 1 #1 §fail-soft 5종 | FR-4 / FR-16 |
| 페이즈 1 #2 §|delta|≥15 선제 | FR-1 결정성 (4종 시나리오에 선제 활성/비활성 포함) |
| 페이즈 1 #3 §클램프 (명중/회피/치명타/반격/사망 저항) | FR-1 / FR-5 |
| 페이즈 1 #3 §10.6 체인 주인공 90% 상한 | FR-5 |
| 페이즈 1 #3 §12.3 라운드 권장 범위 | FR-3 |
| 페이즈 1 #4 §상태 효과 10종 | FR-1 / FR-3 (statusEffectHistory 결정성) |
| 페이즈 2 #1 §16 스킬 | FR-3 분포 표본에 포함 |
| 페이즈 2 #2 §26 적 카탈로그 | FR-3 (3 시나리오 적 구성) |
| 페이즈 2 #3 §다중 결합 시뮬 (battle_fury × mass_blind ×1.04) | FR-1 결정성에 자연 포함 |
| 페이즈 2 #4 §2.1 길이 매트릭스 | FR-8 |
| 페이즈 2 #4 §3.2 5 위치 분포 | FR-9 |
| 페이즈 2 #4 §4.2 비노출 매트릭스 14종 | FR-12 |
| 페이즈 3 #1~#4 시드 데이터 (26/16/10/181) | FR-3 / FR-8 / FR-11 (lookup 데이터 의존) |
| 페이즈 4 #1 [FR-1]~[FR-20] | FR-1 / FR-2 / FR-5 / FR-23 |
| 페이즈 4 #2 §CombatReport HiveField 8~14 | FR-12.1 / FR-17 |
| 페이즈 4 #3 [FR-3] eligible 평가 / [FR-8] 변환 | FR-4 / FR-6 / FR-7.1 |
| 페이즈 4 #3 부록 B 6 항목 | FR-20 ~ FR-25 |
| 페이즈 4 #4 [FR-1] schemaVersion 분기 / [FR-3] lineBudget / [FR-5] 5 위치 색 / [FR-6] decisive 배지 | FR-10 / FR-11 / FR-12 / FR-12.1 / FR-17.1 |
