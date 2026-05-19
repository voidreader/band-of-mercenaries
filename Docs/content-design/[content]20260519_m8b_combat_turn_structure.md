# M8b 전투 턴 구조 기획서

> 작성일: 2026-05-19
> 유형: 신규 컨텐츠 (M8b 마일스톤 — 페이즈 1 산출물 1/4)
> 선행 문서:
> - `Docs/roadmap/master_roadmap.md` — M8b 섹션 (1258~1325행)
> - `Docs/Archive/20260519_m8a_faction_combat_report/design_p1_4_combat_report_mvp.md`
> - `Docs/Archive/20260519_m8a_faction_combat_report/balance_p2_3_combat_report_exposure.md`
> - `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart`
> - `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` (line 852 `_applyCompletionResult`)
> - `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart`
>
> 후속:
> - 페이즈 1 #2 선제권·행동 순서·공격자/방어자 판정 설계
> - 페이즈 1 #3 기본 공격·피해량·명중·회피·치명타 공식 설계
> - 페이즈 1 #4 상태 효과 MVP 타입 설계

## 개요

M8b 전투 시뮬레이터는 일부 특별 의뢰에 한해 `QuestCalculator`의 성공률 해석 결과 대신 턴 단위 시뮬레이션을 실행한다. 시뮬레이션이 만든 결과(승패·부상·사망·라운드 로그)는 기존 `QuestResult` 4단계로 매핑되어 보상·평판·체인 등 후속 처리에 그대로 연결되며, 동시에 M8a 전투 보고서 시스템의 입력 데이터로 사용된다. M8b의 전투는 화면 조작 없이 파견 완료 시 결정적으로 1회 실행되고, 전투 스냅샷과 압축 턴 로그를 도메인 결과로 영속화한다.

이 산출물은 M8b 페이즈 1 #1 범위인 **턴 구조·스냅샷 고정 정책·적용 대상 범위·종료 조건·라운드 수·M8a 보고서 호환 데이터 형태**만 다룬다. 선제권 산식, 공격/회피/치명타 수치, 상태 효과 카탈로그는 페이즈 1 #2~#4와 페이즈 2~3에서 확정한다.

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|--------------|----------|
| Battle Brothers — 자동 전투 후 로그 | 턴 단위 사건이 로그로 누적되어 사후 재구성 가능 | 라운드별 `CombatAction` 시퀀스를 압축 로그로 저장 |
| Football Manager — 사전 결정 시뮬레이션 | 경기 시작 시 모든 입력을 동결하고 시드 기반으로 결과를 계산 | 파견 시작 시점에 `CombatantSnapshot` 동결, 안정 시드로 디버그 재현성 보조 |
| Final Fantasy Tactics — Active Time Battle | 행동 순서가 AGI 외 직업·트레잇 가중치로 결정 | 선제 라운드 + 일반 라운드 반복으로 단순화한 MVP |
| Darkest Dungeon — 사기 붕괴 후퇴 | HP 외에 사기/도주가 종료 조건이 된다 | 종료 조건 (e) 도주, (f) 시간 초과 분기 도입 |

## 적용 범위

### 시뮬레이션 적용 대상 의뢰 (`combatSimulationEligible`)

M8a `combatReportEligible`(QuestCompletionService 477~481행) 정책과 분리한다. 시뮬레이션은 보고서보다 좁은 범위에서 시작하여 점진적으로 확장한다.

| 의뢰 유형 | M8b 적용 | 비고 |
|----------|---------|------|
| 유니크 엘리트 의뢰 | 항상 | 기억 가치가 가장 높다 |
| 일반 엘리트 의뢰 | 항상 | 강적 전투 체감 |
| 연계 퀘스트 최종 단계 + 핵심 단계 | 항상 | M8a 보고서 정책과 동일 |
| 세력 지명 의뢰 12개 (M8a 신규) | 항상 | M8a 핵심 루프 |
| 기존 지명 의뢰 7개 (M6) | 항상 | 지명 의뢰 의미 강화 |
| 세력 전용 의뢰 고급 트랙 | 평판 31 이상 또는 `isAdvancedTrack==true` 만 | M8a 보고서 정책과 정렬 |
| 일반 의뢰 | 제외 | `QuestCalculator` fallback 유지 |
| 더스트빌 허드렛일 | 제외 | 빠른 루프 보호 |

### 보고서 대상이면서 시뮬레이션 비대상인 케이스

세력 전용 의뢰 중 평판 11~30 구간(기본 트랙)은 M8a 보고서는 생성되지만 M8b 시뮬레이션은 실행하지 않는다. 이 경우 보고서는 `QuestCalculator` 결과를 그대로 해석하는 M8a MVP 경로로 생성된다.

### eligibility 평가 위치

`QuestCompletionService.evaluate(...)`(line 96)가 반환하는 `QuestCompletionResult`에 `combatSimulationEligible: bool` 필드를 신규 추가한다. `combatReportEligible`과 분리되어 있다.

```text
combatSimulationEligible =
    quest.isElite
 || quest.isChainQuest && (체인 최종 또는 핵심 단계)
 || pool.isNamed
 || (quest.isFactionExclusive && (quest.isAdvancedTrack == true || factionRep >= 31))
```

`_applyCompletionResult`(quest_provider.dart line 852~)에서 분기 처리한다.

## 전투 턴 구조

### 4 페이즈 흐름

```text
[Phase 1] 사전 단계
   ├─ CombatantSnapshot 동결
   ├─ 사기(morale) 초기값 계산
   ├─ 진형(formation) 결정 — 직업군 기반 자동 배치
   └─ 양측 선제권 후보 판정 (페이즈 1 #2)

[Phase 2] 선제 라운드 (0 또는 1회)
   ├─ 선제권 보유 진영만 1턴 행동
   ├─ 상대 진영 반격 불가
   └─ 종료 조건 평가 후 다음 페이즈

[Phase 3] 일반 라운드 반복 (최소 1 ~ 최대 8)
   ├─ 라운드 시작 → 행동 순서 결정 (페이즈 1 #2)
   ├─ 각 전투원 1행동 (기본 공격 또는 스킬, 페이즈 2)
   ├─ 상태 효과 적용·해제·중첩 갱신 (페이즈 1 #4)
   ├─ 라운드 종료 → 종료 조건 평가
   └─ 종료 조건 미충족 시 다음 라운드 진행

[Phase 4] 마무리 판정
   ├─ 라운드 시퀀스를 결과 메트릭으로 정리
   ├─ QuestResult 4단계로 매핑
   ├─ 부상자·사망자 확정 (Mercenary.injure / die 호출)
   └─ CombatSimulationResult 반환
```

### 페이즈별 책임

#### Phase 1 (사전 단계)

- `CombatSimulator.simulate(...)` 호출 즉시 `CombatantSnapshot` 리스트를 양측에 대해 생성한다.
- 사기는 파티 평균 사기 100을 기본으로 하고, 직업군·트레잇·세력 패시브로 ±20 조정한다. 사기 수치는 페이즈 1 #3에서 확정한다.
- 진형은 직업군 우선 순위로 자동 배치한다(전열: warrior/specialist, 중열: ranger/rogue, 후열: mage/support). 진형은 페이즈 1 #2 회피/반격 판정의 입력이다.
- 선제권 후보(선제 라운드를 가질 진영) 판정은 페이즈 1 #2가 정의한다.

#### Phase 2 (선제 라운드)

- 선제 라운드는 0 또는 1회만 발생한다.
- 선제권 보유 진영의 행동 1회 후, 즉시 종료 조건을 평가한다. 종료 조건이 (a)~(f) 어느 것에도 해당하지 않으면 Phase 3로 진입한다.
- 선제 라운드에서 상대 진영의 반격은 발생하지 않는다.

#### Phase 3 (일반 라운드 반복)

- 라운드는 최소 1회 보장, 최대 8회 상한이다.
- 라운드 내부에서는 모든 행동 가능한 전투원이 페이즈 1 #2가 정한 순서로 1회씩 행동한다.
- 한 라운드 종료 시점에 상태 효과(중첩, 지속 턴, 해제 트리거)를 갱신한다.
- 라운드 종료 후 종료 조건 (a)~(f)를 평가한다.

#### Phase 4 (마무리 판정)

- 라운드 시퀀스 정리 결과를 `QuestResult` 4단계로 매핑(아래 매핑 표 참조).
- 부상·사망 적용은 시뮬레이션 도중이 아니라 Phase 4에서 일괄 호출하여 데이터 일관성을 유지한다.
- 사망 판정 단계: HP가 0 이하로 떨어진 시점에서 사망 저항 롤(직업군 티어 + 트레잇 + 세력 패시브)을 수행하고, 살아남으면 부상 처리한다. 저항 수치 산식은 페이즈 1 #3에서 확정한다.

### 한 전투의 라운드 수

| 항목 | 값 | 비고 |
|------|----|------|
| 최소 일반 라운드 | 1 | 선제 라운드에서 종결되어도 Phase 3 진입 후 즉시 종료 조건 평가 가능 |
| 권장 라운드 범위 | 3~6 | 보고서 상세 4~8줄 분량과 정렬 |
| 최대 일반 라운드 | 8 | 라운드 상한. 초과 시 종료 조건 (d) 발동 |

### 종료 조건

라운드 종료마다 다음 조건을 순서대로 평가한다.

| 코드 | 조건 | 의미 | 기본 결과 매핑 |
|------|------|------|----------------|
| (a) | 파티 HP 합계 ≤ 0 | 파티 전멸 | 대실패 |
| (b) | 적 진영 HP 합계 ≤ 0 | 적 진영 전멸 | 대성공 또는 성공 (잔존 비율로 분기) |
| (c) | 의뢰 목표 진행도 100% (호위·탐험류) | 목표 달성 | 성공 (잔존 비율 양호 시 대성공) |
| (d) | 라운드 한계 도달 (8라운드 종료) | 시간 초과 | 잔존 비율·목표 진행도로 매핑 (성공/실패) |
| (e) | 파티 사기 ≤ 25% + AGI 비례 회피 판정 통과 | 도주 | 실패 (부상 발생 가능, 사망은 발생하지 않음) |
| (f) | 의뢰 호위 대상 사망 (호위형 의뢰만) | 임무 실패 | 실패 또는 대실패 |

### QuestResult 매핑

| 종료 조건 | 잔존 비율·부상자 수 | 매핑 결과 |
|----------|---------------------|----------|
| (b) 적 진영 전멸 | 파티 부상자 0~1, 사망자 0 | 대성공 |
| (b) 적 진영 전멸 | 파티 부상자 2+, 사망자 0 | 성공 |
| (c) 목표 달성 | 파티 부상자 0~1, 사망자 0 | 대성공 |
| (c) 목표 달성 | 파티 부상자 2+, 사망자 0 | 성공 |
| (d) 라운드 한계 도달 | 양측 잔존, 목표 진행도 70%+ | 성공 |
| (d) 라운드 한계 도달 | 양측 잔존, 목표 진행도 < 70% | 실패 |
| (e) 도주 | 사망자 0 | 실패 |
| (f) 호위 대상 사망 | — | 대실패 |
| (a) 파티 전멸 | 사망자 ≥ 1 | 대실패 |

세부 비율 기준과 부상자 수치는 페이즈 2 #4(전투 로그 길이·수치 노출 기준)와 페이즈 4 #5(검증 명세)에서 확정한다.

## 파견 시작 시점 스냅샷 고정 정책

### 동결 시점

`CombatantSnapshot`은 **파견 완료 시점이 아니라 파견 시작 시점**(`quest.startTime` 직후)에 동결된다. 시뮬레이션 자체는 파견 완료 시점에 실행되지만, 입력으로 들어가는 모든 상태는 시작 시점에서 캡처된 값을 사용한다.

이렇게 하면 같은 의뢰를 같은 파티로 같은 시각에 보냈다면 항상 같은 결과가 나온다. 결정성은 디버깅·재현·추후 영상화 후보의 기반이다.

### 동결 대상 데이터

| 대상 | 동결 필드 | 비고 |
|------|----------|------|
| 파티 용병 (1~N명) | `id`, `name`, `jobId`, `tier`, `level`, `effectiveStr/int/vit/agi`, `titleIds`, `traitIds`(선천+후천), `equippedItemIds` | `effectiveXxx` getter는 동결 당시의 레벨 보너스·피로 디버프 반영 결과 |
| 적 진영 | `enemyType`, `combatPower`, `behaviorPattern`, `skillIds` | 페이즈 3 데이터 |
| 전장 | `regionId`, `regionEnvironmentTags`, `sectorTransform`, `dangerLevel`, `unlockedFlags` | 페이즈 4 #2 모델에서 확정 |
| 세력 맥락 | `factionTag`, `factionRep`(보고서 톤 결정용) | M8a CombatReport 호환 |
| 의뢰 메타 | `quest.id`, `quest.difficulty`, `quest.questType`, `quest.isElite/isChainQuest/isNamed`, `quest.eliteId`, `pool.specialFlags`(불변 사본) | |
| 시드 | `seed = stableSeed32('${quest.startTime!.toUtc().microsecondsSinceEpoch}|${quest.id}')` | `hashCode` 금지. 안정 해시로 산출 후 저장 |

### 시뮬레이션 도중 변경되는 상태

전투 진행 중에는 다음만 변동한다.

- HP, 사기, 상태 효과(activeEffects, 잔여 턴)
- 라운드별 행동 순서 캐시와 추가 행동 예약 슬롯
- 사망/부상 마킹 (Phase 4 일괄 적용 전까지는 마킹만)

`CombatantSnapshot`의 동결 필드는 시뮬레이션 도중에 변경되지 않는다.

### 파견 중 외부 변경 무시

파견이 진행되는 동안 다른 의뢰 결과로 트레잇이 새로 진화하거나 장비가 바뀌어도, 이 의뢰의 시뮬레이션 입력에는 반영되지 않는다. 이 결정은 다음을 보장한다.

- 결정성: 시작 시점만 알면 결과를 재현할 수 있다.
- 단순성: 시뮬레이션 도중 mercenary 상태를 다시 읽지 않는다.
- 공정성: 한 파티가 두 의뢰에 동시에 들어갈 수 없으므로 (파견 중 용병 사용 불가) 실질적 충돌은 없다.

다만 **부상/사망 적용 결과는 Phase 4에서 실시간 mercenary 상태에 반영**된다. 즉 동결은 입력 측이고, 출력은 영속 처리한다.

## CombatSimulationResult 데이터 형태

페이즈 4 #2가 정확한 freezed/Hive 모델을 정의하지만, 컨텐츠 관점의 최소 출력은 다음과 같다. **이 출력은 `CombatReportService.generate(...)` 입력이 된다.**

```text
CombatSimulationResult
- questResult: QuestResult         // 기존 4단계 enum 그대로
- turns: List<CombatTurn>          // 라운드별 압축 액션 시퀀스 (영속 대상)
- protagonistMercId: String?       // Phase 4에서 결정
- featuredMercIds: List<String>    // 결정적 장면 기여자
- injuredMercIds: List<String>     // Phase 4 일괄 적용 대상
- deceasedMercIds: List<String>    // Phase 4 일괄 적용 대상
- objectiveProgress: double        // 0.0~1.0
- exitCondition: CombatExitCondition   // (a)~(f) enum
- statusEffectHistory: List<...>   // 상태 효과 시작·해제 이벤트
- seed: int                        // 동일 입력 재현용
```

`turns` 시퀀스는 영속화한다. M8b는 UI에서 전투 로그를 재생성하지 않고, 도메인 결과로 저장된 압축 로그를 그대로 표시한다. 시드는 디버그 재현성과 테스트 보조용이며, 영속 로그를 대체하지 않는다.

| 영속 대상 | 위치 | 정책 |
|-----------|------|------|
| 부상/사망 결과 | `Mercenary` 본체 (`injure`/`die`) | 기존 시스템 호환 |
| 보상·평판·체인 진행 | 기존 `QuestCompletionService` 흐름 | 변경 없음 |
| 전투 스냅샷 | 확장된 `CombatReport.combatantSnapshots` 후보 | 파견 시작 시점 입력 동결 |
| 라운드 로그 | 확장된 `CombatReport.turns` 후보 | `CombatTurn`/`CombatAction` 압축 영속 |
| 보고서 요약·상세 | `ActiveQuest.combatReport` (M8a 필드 0~7 유지) | 기존 UI 호환 |
| 시드 | `ActiveQuest.combatReport.seed` | 안정 해시 seed 저장 |
| 결정적 장면 키워드 | `CombatReport.toneTags` + `featuredMercIds` | M8a 그대로 |

`CombatReport`의 기존 HiveField 0~7은 유지한다. 페이즈 4 #2는 HiveField 8+에 `schemaVersion`, `combatantSnapshots`, `turns`, `exitCondition`, `objectiveProgress` 같은 optional 필드를 추가하는 방향을 우선 검토한다. 기존 M8a 보고서는 신규 필드가 null이어도 정상 표시되어야 한다.

## M8a 전투 보고서와의 연결

### 데이터 흐름

```text
[기존 M8a 흐름]
QuestCompletionService.evaluate(...)
  → QuestCompletionResult { resultType, combatReportEligible, ... }
quest_provider._applyCompletionResult(quest, result)
  → if (result.combatReportEligible) → CombatReportService.generate(...)
       → ActiveQuest.combatReport = report

[M8b 흐름]
QuestCompletionService.evaluate(...)
  → QuestCompletionResult { resultType, combatReportEligible, combatSimulationEligible, ... }
quest_provider._applyCompletionResult(quest, result)
  → if (combatSimulationEligible)
       → CombatSimulator.simulate(...)
             → CombatSimulationResult
       → result = result.copyWith(
             resultType: simResult.questResult,        // 시뮬레이션 결과로 오버라이드
             mercDamages: simResult.injured + deceased  // 시뮬레이션 결과로 오버라이드
         )
  → 보상·평판·체인 등 기존 후속 처리 그대로
  → if (result.combatReportEligible)
       → CombatReportService.generate(..., simulationResult: simResult?)
             → ActiveQuest.combatReport = report
```

### CombatReport 모델 호환

기존 `CombatReport` (typeId 21, HiveField 0~7)는 호환 필드로 유지된다. M8b는 같은 모델을 확장하되 기존 필드 번호를 변경하지 않는다.

`CombatReportService.generate(...)`는 `simulationResult: CombatSimulationResult?` 인자를 새로 받는다.

| 인자 | M8a 동작 | M8b 동작 |
|------|---------|---------|
| `simulationResult == null` | M8a MVP 경로: `QuestCalculator` 결과를 해석하여 템플릿 선택 | (변경 없음) |
| `simulationResult != null` | — | 영속될 시뮬레이션 라운드 시퀀스에서 키워드를 직접 추출하여 `details` 라인을 구성 |

`summary` 길이 매트릭스(2~4문장), `details` 길이 매트릭스(4~8줄)는 M8a 그대로 사용한다. 시뮬레이션 결과가 있을 때는 라운드 액션·결정적 장면·부상/사망 이벤트가 직접 입력이므로 템플릿 변형 폭이 더 풍부하다.

### featured / protagonist 일관성

기존 `QuestNarrativeService.pickProtagonist`는 파티 기여도 기반 단순 알고리즘이다. M8b 시뮬레이션이 활성화된 의뢰에서는 `CombatSimulator`가 **실제 결정적 장면 기여자**(킬·결정타·방패·치료 등)를 추적하여 `protagonistMercId`와 `featuredMercIds`를 직접 결정한다. `CombatReportService`는 이 값을 우선 사용하고, 시뮬레이션이 없으면 `QuestNarrativeService.pickProtagonist`로 폴백한다.

이 정책은 M6 칭호 hook(`last_dispatch_protagonist`, `top_contributor_24h`)과 정합한다. M8b 결정적 장면 기여자가 더 정확한 입력이 된다.

### 보고서 라인이 시뮬레이션 라운드를 압축하는 방식

보고서 상세는 4~8줄로 제한된다. 시뮬레이션 라운드가 6라운드 30액션이라면 그 모두를 노출하지 않는다. M8b는 다음 압축 정책을 권장한다.

| 라인 위치 | 후보 소스 |
|-----------|----------|
| 1줄 (진입) | Phase 1 진형·사기·선제권 |
| 2~3줄 (전개) | Phase 3 결정적 장면 1~2개 (높은 피해 액션, 광역 액션, 메즈/디버프) |
| 4~5줄 (위기) | 부상 발생 시점 또는 적 결정타 시점 |
| 6~7줄 (해소) | 종료 조건 (b)/(c) 직전 결정타 또는 (e)/(d) 도주·후퇴 |
| 8줄 (후일담) | 종료 후 사기 평가, 사망/부상 후일담 |

8줄 모두 채우지 않을 때는 빈 줄을 건너뛰고 4~7줄로 축약한다.

## 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| `QuestCompletionService.evaluate` | `QuestCompletionResult`에 `combatSimulationEligible` 추가 | 페이즈 4 #1에서 명세 |
| `quest_provider._applyCompletionResult` | 시뮬레이터 분기 추가, `resultType`/`mercDamages` 오버라이드 | 페이즈 4 #3에서 명세 |
| `QuestCalculator` | 일반 의뢰 fallback 경로 유지 | 변경 없음 |
| `Mercenary.injure/die` | Phase 4 일괄 호출 | 변경 없음 |
| `CombatReport` (typeId 21) | 기존 HiveField 0~7 유지 + HiveField 8+ optional 확장 후보 | M8a 보고서 호환 |
| `CombatReportService.generate` | `simulationResult` 인자 추가 | 페이즈 4 #2에서 명세 |
| `QuestNarrativeService.pickProtagonist` | 시뮬레이션 활성 시 우선순위 하향 | 폴백 경로로만 유지 |
| `ActivityLogType.combatReportGenerated` (HiveField 39) | 변경 없음 | 시뮬레이션 결과도 동일 활동 로그 |
| `EliteLootService.rollDrops` | 시뮬레이션 결과의 `resultType`을 입력으로 받도록 정렬 | 페이즈 4 #3에서 명세 |
| `RegionState`/`FactionState`/체인 진행 | 시뮬레이션 결과의 `resultType` 그대로 사용 | 변경 없음 |

## 결정성과 디버깅

### 시드 생성

```text
seed = stableSeed32('${quest.startTime!.toUtc().microsecondsSinceEpoch}|${quest.id}')
```

이 시드는 `CombatantSnapshot` 동결 시점에 결정되며, 시뮬레이션 도중 모든 랜덤 롤(`Random(seed)`)에 사용된다. Dart의 런타임 `hashCode`는 앱 실행마다 달라질 수 있으므로 사용하지 않는다. 페이즈 4 #1은 FNV-1a 32-bit 또는 동등한 안정 해시 유틸을 정적 함수로 명세한다.

### 디버그 재실행

M8b MVP는 사용자 향 디버그 화면을 제공하지 않는다. 다만 명세 단계에서 다음 운영 정책을 권장한다.

- `CombatSimulationResult`는 메모리에서 1회 생성된 후 `CombatReport`의 요약·상세·압축 턴 로그로 저장된다.
- 디버깅 필요 시 저장된 `seed`, `CombatantSnapshot`, `CombatTurn`을 함께 확인한다.
- 디버그 빌드에서는 저장된 압축 로그와 재실행 결과가 일치하는지 비교하는 옵션을 둘 수 있다. 명세서 자유.

## fallback 정책

시뮬레이션 호출이 실패하거나 정적 데이터(`enemies`/`combat_skills`/`combat_status_effects`)가 부재한 경우, M8b는 항상 안전 폴백을 보장한다.

```text
try {
  simResult = CombatSimulator.simulate(...);
  result = result.copyWith(resultType: simResult.questResult, ...);
} catch (e) {
  // 시뮬레이터가 어떤 이유로 실패 → 기존 QuestCalculator 결과 그대로 사용
  // 보고서는 M8a MVP 경로로 생성 (simulationResult: null)
  log.error('CombatSimulator failed: $e');
}
```

이 정책은 (a) Supabase 정적 데이터 캐시 부재 시, (b) 신규 적/스킬 ID가 정의되지 않은 경우, (c) M8b 출시 후 핫픽스 상황에서 게임이 멈추지 않도록 보장한다.

## 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | `combatSimulationEligible` 평가 + `_applyCompletionResult` 분기 | M8b 시뮬레이터의 진입점 |
| 높음 | `CombatantSnapshot` 동결 시점·필드 확정 | 결정성 보장의 기반 |
| 높음 | 종료 조건 (a)~(f) + QuestResult 매핑 | M8a 보고서·체인·평판 호환 |
| 높음 | fallback 정책 | 안전 가드 |
| 중간 | 라운드 압축 정책 (시뮬레이션 → 보고서 라인) | 보고서 가독성 |
| 중간 | featured/protagonist 결정 권한 이동 | M6 칭호 hook 정합 |
| 높음 | 압축 라운드 로그 영속화 (`CombatReport` HiveField 8+ 후보) | 로드맵의 도메인 결과 저장 요구 |

## data-generator 지시사항

이 산출물은 시스템·흐름 설계이며 벌크 데이터 생성을 직접 요구하지 않는다. 페이즈 3에서 별도로 다음 데이터가 필요해진다.

- 적 유형 20~30개 (페이즈 3 산출물 1)
- 직업군 대표 스킬 6~10개 (페이즈 3 산출물 2)
- 상태 효과 8~12개 (페이즈 3 산출물 3)
- 라운드 로그·결정적 장면 템플릿 120~180개 (페이즈 3 산출물 4)

각 산출물의 타입 스펙(`types/enemy.md`, `types/combat-skill.md`, `types/status-effect.md`, `types/combat-log-template.md`)이 부재한 경우 페이즈 3 시작 시점에 (a) 타입 스펙 우선 작성 또는 (b) SQL/수동 데이터 생성 병행을 결정한다.

## 다음 단계

페이즈 1 #2에서 선제권·행동 순서·공격자/방어자 판정을 설계한다. 이 산출물의 Phase 1 사전 단계·Phase 2 선제 라운드·Phase 3 일반 라운드 행동 순서가 #2의 입력이 된다.

페이즈 1 #3은 기본 공격·피해량·명중·회피·치명타 공식을 설계한다. 이 산출물의 종료 조건 매핑 표가 #3의 사기·HP 수치 산식의 출력 검증에 사용된다.

페이즈 1 #4는 상태 효과 MVP 타입을 설계한다. 이 산출물의 Phase 3 라운드 종료 시점 상태 갱신 정책이 #4의 입력이 된다.
