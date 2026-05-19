# M8b 페이즈 4 #3 — QuestCompletionService 전투 시뮬레이터 통합 구현 plan

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260519_m8b_quest_completion_integration.md`
> 작성일: 2026-05-19
> 마일스톤: M8b 페이즈 4 #3 (QuestCompletionService 통합)

## 1. 수립한 구현 계획과 실제 개발 사항

### 1.1 PHASE 1 통합 계획 (planner 결과 요약)

4 TASK로 분해, 병렬 모드 적용 (TASK 수 < 5):

| # | TASK | 대상 파일 | 복잡도 | 모델 | 의존 |
|---|------|----------|--------|------|------|
| 1 | `QuestCompletionResult` 2 필드 + `calculate()` 시그니처 1 인자 + import 3개 | quest_completion_service.dart | mechanical | haiku | 없음 |
| 2 | `calculate()` 내부 흐름 7단계 재구성 + 3 private static helper | quest_completion_service.dart | **architecture** | **opus** | TASK-1 |
| 3 | `CombatReportService.generate()` 시그니처 확장 + simulationResult 분기 + 6 구조 필드 임베드 | combat_report_service.dart | integration | sonnet | 없음 |
| 4 | `_completeQuest` chain_protagonist_id 병합 + calculate/generate 호출 인자 + 엘리트 위업/region_state guard | quest_provider.dart | integration | sonnet | TASK-2, TASK-3 |

실행 순서(의존성):
- 1단계 병렬: TASK-1 [haiku] + TASK-3 [sonnet]
- 2단계: TASK-2 [opus] (TASK-1 후)
- 3단계: TASK-4 [sonnet] (TASK-2·TASK-3 후)

사용자 확인 필요 항목 없음 — 명세서 [Q-1]~[Q-8] 모두 채택 방향 결정됨.

### 1.2 실제 개발 결과

- 4 TASK 모두 1회 PASS (재시도 0회)
- TASK-1: import 3개 + 필드 2개 + 시그니처 인자 1개 추가. 단독 analyze 시 `unused_import: combat_simulator.dart` 1 warning이 발생했으나 TASK-2 완료 후 자연 해소.
- TASK-2: 흐름 7단계 재구성 + 3 helper. `passiveRecoveryMultiplier` 단일 변수 추출(기존 fallback 경로의 2회 중복 선언 통합, 동작 동치). `roll` 변수를 fallback 내부로 이동(시뮬레이션 경로 미사용). `core/models/difficulty.dart` import 추가(helper 인자 타입 명시).
- TASK-3: protagonist 우선순위 분기 + summary/details null safety fallback + 6 구조 필드 최소 임베드. `use_null_aware_elements` lint 대응으로 `if (summary != null) summary.id` 패턴 사용.
- TASK-4: 4개 호출점 변경. `chainQuestRepositoryProvider.get(chainId)`가 동기 메서드임을 확인하여 `await` 미사용. `sectorChanges` 인자 출처를 `questRegionState?.sectorChanges`로 통일.
- PHASE 2.5 빌드 게이트: `flutter analyze` 전체 0 issues. build_runner 불필요(Hive/freezed 모델 변경 없음).
- PHASE 3 풀 검증: verifier PASS (15/15 REQ, 이슈 0개) + flutter-reviewer APPROVE (이슈 0개).

## 2. 변경 파일 목록

### 2.1 수정 파일 (3개)

| 파일 경로 | 유형 | 설명 |
|-----------|------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 수정 | import 3개 + `core/models/difficulty.dart` + `flutter/foundation.dart` 추가. `QuestCompletionResult` 2 필드(`combatSimulationEligible`/`simulationResult`) 추가. `calculate()` 시그니처에 `regionState: RegionState?` 인자 추가. 내부 흐름 7단계 재구성. 3 private static helper(`_isChainSimulationStep`/`_factionReputation`/`_convertSimulationToMercDamages`) 추가. `combatReportEligible OR combatSimulationEligible` 보장. `settlementTrustGain`에 `pool?.isNamed != true` guard. |
| `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart` | 수정 | `combat_simulation_result.dart` import 추가. `generate()` 시그니처에 `simulationResult: CombatSimulationResult?` named optional 인자 추가. protagonist/featuredMercIds/toneTags 우선순위 분기. summary null/details empty fallback. `simulationResult != null` 시 `schemaVersion = 1` + HiveField 9~14 6 구조 필드(combatantSnapshots/turns/exitCondition/objectiveProgress/enemySnapshots/statusEffectHistory) 최소 임베드. |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 수정 | `_completeQuest`에서 chain_protagonist_id 런타임 플래그 병합(non-settlement chain). `calculate(...)` 호출에 `regionState: questRegionState` 인자 추가. `_applyCompletionResult`의 `CombatReportService.generate(...)` 호출에 `simulationResult: result.simulationResult` 인자 추가. 엘리트 유니크 첫 처치 위업 hook + `eliteRegionStateMapping` trailing 2곳에 `result.resultType ∈ {success, greatSuccess}` guard 추가. |

### 2.2 신규 생성 파일

없음. 페이즈 4 #1·#2가 모든 신규 파일 생성을 완료한 상태에서 본 통합 작업은 외과적 수정에 한정.

## 3. 실행 모드 / 검증 모드 / 결과 요약

### 3.1 실행 모드
- **병렬 모드** (TASK 수 = 4)
- 1단계 병렬: TASK-1 + TASK-3 (다른 파일이라 안전)
- 2단계: TASK-2 (TASK-1과 동일 파일이라 순차)
- 3단계: TASK-4 (TASK-2·TASK-3 시그니처 확장에 의존)

### 3.2 검증 모드
- **PHASE 3-B 풀 검증** (3 ≤ TASK 수 ≤ 4)
- verifier(spec) + flutter-reviewer(quality) 단일 메시지 병렬 호출
- 검증 가이드: 직접 변경 파일 3개 + REQ별 확인 포인트 15개 + 시그니처 6개 + 호환성 체크 포인트 4개

### 3.3 결과 요약

| TASK | coder | analyze | test | 결과 |
|------|-------|---------|------|------|
| TASK-1 | PASS | 1 warning (unused_import, TASK-2에서 해소) | N/A | PASS |
| TASK-2 | PASS | 0 issues | 10/10 | PASS |
| TASK-3 | PASS | 0 issues (use_null_aware_elements 1회 자체 수정 후) | 7/7 | PASS |
| TASK-4 | PASS | 0 issues | 210/210 (전체 quest) | PASS |
| PHASE 2.5 (전체 빌드 게이트) | — | **0 issues** | — | PASS |
| PHASE 3 verifier | — | — | — | **PASS (15/15 REQ)** |
| PHASE 3 flutter-reviewer | — | — | — | **APPROVE** |

전체 4 TASK × 1회 시도 PASS, 재시도 0회. PHASE 3 통합 검증 이슈 0개.

## 4. build_runner 재실행 필요 파일

**없음.** Hive 모델·freezed 모델·json_serializable 변경 없음. 추가한 필드는 모두 일반 Dart final 필드(`QuestCompletionResult` 2개). Hive 박스 어댑터·json 직렬화 모두 영향 없음.

`flutter analyze` 최종: 0 issues.

## 5. 핵심 시그니처 (Public API)

```dart
// QuestCompletionService
class QuestCompletionResult {
  final QuestResult resultType;
  // ... 기존 11 필드 ...
  final bool combatReportEligible;
  // M8b 페이즈 4 #3 추가
  final bool combatSimulationEligible;
  final CombatSimulationResult? simulationResult;

  const QuestCompletionResult({
    // ... 기존 ...
    this.combatSimulationEligible = false,
    this.simulationResult,
  });
}

class QuestCompletionService {
  static QuestCompletionResult calculate({
    // ... 기존 19개 인자 유지 ...
    RegionState? regionState,            // M8b 페이즈 4 #3 추가
  });

  // M8b 페이즈 4 #3 추가 private static helper 3종
  static bool _isChainSimulationStep(ActiveQuest quest, StaticGameData staticData);
  static int _factionReputation(ActiveQuest quest, List<FactionState> factionStates);
  static List<MercDamageResult> _convertSimulationToMercDamages({...10 required named...});
}
```

```dart
// CombatReportService
static CombatReport? generate({
  // ... 기존 10개 인자 유지 ...
  CombatSimulationResult? simulationResult,   // M8b 페이즈 4 #3 추가
});
```

```dart
// CombatReport (페이즈 4 #2에서 이미 정의된 HiveField 8~14에 본 명세에서 최소 임베드 활성화)
@HiveType(typeId: 21)
class CombatReport extends HiveObject {
  // 기존 0~7
  @HiveField(8) int? schemaVersion;                            // simulationResult != null이면 1
  @HiveField(9) List<CombatantSnapshot>? combatantSnapshots;
  @HiveField(10) List<CombatTurn>? turns;
  @HiveField(11) CombatExitCondition? exitCondition;
  @HiveField(12) double? objectiveProgress;
  @HiveField(13) List<EnemySnapshot>? enemySnapshots;
  @HiveField(14) List<StatusEffectEvent>? statusEffectHistory;
}
```

## 6. CLAUDE.md 금지사항 위반

위반 없음.
- ref/Hive/Provider 직접 접근 0건 (모든 helper는 정적 메서드 + 인자 전달만)
- `Mercenary.injure/die` 직접 호출 0건 (시뮬레이터·QuestCompletionService 모두 마킹만, 적용은 `_applyCompletionResult` 기존 경로)
- Dart `String.hashCode`/`Object.hashCode` 사용 0건 (시뮬레이션 시드는 페이즈 4 #1의 `stableSeed32` 그대로)
- `avoid_print` 정책 준수 — 모든 에러 로깅은 `debugPrint('[BOM][...] ...')` 패턴
- 한국어 주석 유지 (`// M8b 페이즈 4 #3 — ...` 식별자 일관성)

## 7. 후속 단계

1. **페이즈 4 #4 (전투 보고서 UI 확장 명세)**: 본 명세 [FR-9.1]/[FR-10.1]에 위임. `CombatReport.schemaVersion == 1` 분기로 시뮬레이션 결과 표시. `summary`/`details` 라인 품질 개선과 라운드 로그·결정적 장면 강조.
2. **페이즈 4 #5 (검증 및 밸런스 명세)**: 본 명세 §6 검증 계획 항목들을 통합 — 시뮬레이션 vs fallback 부상/사망 분포 비교, chain_core_step 플래그 운영 여부 결정, `damageRoll` 의미 변경 호환성 검증, DoT 누적량 반영 검토, `LegendaryResultUpgrade` 시뮬레이션 적용 정책.

## 8. 명세서 매핑 표 (REQ-n ↔ 구현 위치)

| REQ | 구현 위치 |
|-----|----------|
| REQ-1 (FR-2) QuestCompletionResult 2 필드 | quest_completion_service.dart line 83~85, 101~102 |
| REQ-2 (FR-1) calculate regionState 인자 | quest_completion_service.dart line 132 |
| REQ-3 (FR-3) combatSimulationEligible 평가식 | quest_completion_service.dart line 154~160 |
| REQ-3.1 (FR-3.1) _isChainSimulationStep | quest_completion_service.dart line 617~644 |
| REQ-3.2 (FR-3.2) _factionReputation | quest_completion_service.dart line 648~658 |
| REQ-4 (FR-3.5) combatReportEligible OR | quest_completion_service.dart line 542~549 |
| REQ-5 (FR-4) 7단계 흐름 | quest_completion_service.dart line 135~607 |
| REQ-6 (FR-5~FR-7.2) 보상/XP/명성/eliteLoot 재사용 | quest_completion_service.dart line 241~345 (기존 보존) |
| REQ-7 (FR-7.3) settlementTrustGain 지명 의뢰 제외 | quest_completion_service.dart line 584 |
| REQ-8 (FR-8) _convertSimulationToMercDamages | quest_completion_service.dart line 664~752 |
| REQ-9 (FR-10) CombatReportService.generate 시그니처 | combat_report_service.dart line 39 |
| REQ-10 (FR-9/FR-9.2) schemaVersion + 6 구조 필드 최소 임베드 | combat_report_service.dart line 81~110, 121, 145~147, 178~180, 184~201 |
| REQ-11 (FR-12/FR-12.1) regionState + chain_protagonist_id | quest_provider.dart line 810~832, 860 |
| REQ-12 (FR-13) simulationResult 전달 | quest_provider.dart line 923 |
| REQ-13 (FR-15) 엘리트 위업/region_state guard | quest_provider.dart line 982~984, 1033~1035 |
| REQ-14 (FR-11) fail-soft 5종 | quest_completion_service.dart line 163~180 + combat_simulator.dart 내부 |
