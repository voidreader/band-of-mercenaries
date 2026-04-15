# 세계 확장 Phase 1 — 지역 조사 시스템 구현 계획서

Skill used : implement-agent

> 명세서: Docs/spec/[spec]20260415_world-expansion-phase1.md
> 구현일: 2026-04-15

---

## 1. 구현 개요

199개 리전에 유저별 RegionState(지역 상태)를 부여하고, 용병 1명을 파견과 독립된 "지역 조사" 행동에 배치하여 지식 포인트를 누적하는 시스템을 구현했다. 기존 시설 건설(construction) 시스템의 UserData 3-필드 + StateNotifier + StateProvider + app.dart 리스너 패턴을 그대로 차용했다.

---

## 2. 구현 계획 및 실행 순서

### 태스크 실행 순서

| 단계 | 태스크 | 처리 방식 |
|------|--------|----------|
| 1 | TASK-1~5, TASK-7, TASK-11 | 병렬 |
| 2 | TASK-6 (build_runner) | 순차 |
| 3 | TASK-8~10, TASK-12, TASK-16~18 | 병렬 |
| 4 | TASK-13 | 순차 |
| 5 | TASK-14 | 순차 |
| 6 | TASK-19 | 순차 |
| 7 | TASK-20, TASK-21 | 병렬 |

### 핵심 설계 결정

- `InvestigationNotifier`는 `StateNotifier<void>` — 실제 상태는 UserData에 위임
- gameTickProvider 연동은 app.dart 외부 호출 방식 (건설 패턴 동일)
- UI 컴포넌트(위젯, BottomSheet, ResultDialog)는 `investigation_widget.dart` 단일 파일에 통합
- `RegionStateRepository` Provider는 동일 파일 상단 선언

---

## 3. 변경 파일 목록

### 수정된 파일 (12개)

| 파일 경로 | 변경 유형 | 변경 내용 |
|-----------|----------|----------|
| `lib/core/models/user_data.dart` | 수정 | HiveField(15) investigatingMercId, HiveField(16) investigationEndTime, HiveField(17) investigationRegionId 추가 |
| `lib/core/providers/game_state_provider.dart` | 수정 | startInvestigation(), clearInvestigation(), recalculateInvestigationTimer(), _checkPastInvestigation() 추가 |
| `lib/core/domain/activity_log_model.dart` | 수정 | ActivityLogType에 HiveField(10) investigationSuccess, HiveField(11) investigationFailed, HiveField(12) discoveryFound 추가 |
| `lib/core/data/sync_service.dart` | 수정 | allTables에 'region_discoveries' 추가 (16개 → 17개) |
| `lib/core/providers/static_data_provider.dart` | 수정 | StaticGameData에 regionDiscoveries 필드 추가, FutureProvider 로딩 호출 추가 |
| `lib/core/data/hive_initializer.dart` | 수정 | RegionStateAdapter 등록, regionStates 박스 오픈, regionStateBoxName 상수 추가 |
| `lib/features/movement/domain/movement_provider.dart` | 수정 | startMovement()에 조사 중 이동 불가 조건 추가 |
| `lib/features/movement/view/movement_screen.dart` | 수정 | 이동 버튼 비활성 조건 추가, 조사 중 안내 문구 추가 |
| `lib/features/quest/view/dispatch_detail_page.dart` | 수정 | availableMercs 필터에 investigatingMercId 제외 조건 추가 |
| `lib/features/home/view/home_screen.dart` | 수정 | InvestigationWidget 삽입, _logIcon switch 케이스 3개 추가 |
| `lib/app.dart` | 수정 | gameTickProvider listener에 checkCompletion() 추가, investigationCompletedProvider listener + InvestigationResultDialog 팝업 추가 |
| `lib/features/settings/view/settings_screen.dart` | 수정 | recalculateInvestigationTimer() 호출 추가 (시간 가속 변경 시 조사 타이머 재계산) |
| `test/features/quest/domain/quest_completion_service_test.dart` | 수정 | StaticGameData 생성자 호출에 regionDiscoveries: const [] 추가 |

### 신규 생성 파일 (8개)

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/investigation/domain/region_state_model.dart` | RegionState Hive 모델 (typeId:8) |
| `lib/features/investigation/domain/region_discovery_data.dart` | RegionDiscoveryData 정적 데이터 모델 (freezed + json_serializable) |
| `lib/features/investigation/domain/investigation_result.dart` | InvestigationResult DTO (순수 Dart) |
| `lib/features/investigation/domain/investigation_service.dart` | 조사 계산 순수 static 메서드 모음 |
| `lib/features/investigation/domain/investigation_notifier.dart` | InvestigationNotifier (StateNotifier<void>) |
| `lib/features/investigation/domain/investigation_completion_provider.dart` | investigationCompletedProvider (StateProvider<InvestigationResult?>) |
| `lib/features/investigation/data/region_state_repository.dart` | RegionStateRepository + regionStateRepositoryProvider |
| `lib/features/investigation/view/investigation_widget.dart` | InvestigationWidget + 용병 선택 BottomSheet + InvestigationResultDialog |

---

## 4. build_runner 재실행 필요 파일

| 파일 | 이유 | 생성 파일 |
|------|------|----------|
| `lib/core/models/user_data.dart` | hive_generator (신규 필드 3개) | user_data.g.dart |
| `lib/core/domain/activity_log_model.dart` | hive_generator (신규 enum 값 3개) | activity_log_model.g.dart |
| `lib/features/investigation/domain/region_state_model.dart` | hive_generator | region_state_model.g.dart |
| `lib/features/investigation/domain/region_discovery_data.dart` | freezed + json_serializable | region_discovery_data.freezed.dart, region_discovery_data.g.dart |

build_runner는 구현 과정에서 이미 실행됨 (`dart run build_runner build --delete-conflicting-outputs`).

---

## 5. verifier 검증 결과

| 회차 | 결과 | 수정 이슈 |
|------|------|----------|
| 1차 | FAIL | 3개 이슈 |
| 2차 | PASS | — |

### 1차 검증 이슈 목록

**ISSUE-1** (critical — 해소):
- `movement_screen.dart` — nullable userData를 null 체크 이전에 접근하는 컴파일 오류
- 수정: isInvestigating 변수 선언을 null 체크 블록 이후로 이동

**ISSUE-2** (critical — 해소):
- `test/features/quest/domain/quest_completion_service_test.dart` — StaticGameData 생성자에 regionDiscoveries 파라미터 누락
- 수정: `regionDiscoveries: const []` 추가

**ISSUE-3** (warning — 해소):
- `settings_screen.dart` — 시간 가속 변경 시 조사 타이머 재계산 누락
- 수정: `recalculateInvestigationTimer(oldSpeed, speed)` 호출 추가

### 최종 검증

- flutter analyze: 오류 0건, 경고 0건 (info 4건은 기존 dispatch_screen.dart 사전 존재 경고)
- flutter test: 176/176 PASS

---

## 6. CLAUDE.md 금지사항 위반 사항

없음.

단, 다음 사항은 CLAUDE.md 준수를 위해 계획 대비 변경됨:
- `game_state_provider.dart`의 `_isCompletingInvestigation` 필드 미추가 (미사용 필드 lint 방지)
- `game_state_provider.dart`의 investigationCompletedProvider import 미추가 (미사용 import lint 방지)

---

## 7. Supabase 작업 (완료)

| 항목 | 내용 |
|------|------|
| 테이블 생성 | `region_discoveries` (id TEXT PK, region_id INTEGER, knowledge_threshold INTEGER, discovery_type TEXT, discovery_data JSONB, description TEXT) |
| RLS | 활성화, anon read 정책 추가 |
| data_versions | `region_discoveries` version:1 행 추가 |
| 테스트 데이터 | region_id=1 기준 3건 삽입 (threshold 10/50/90, type: info/elite/hidden_quest) |

앱 첫 실행 시 SyncService가 자동으로 다운로드. region_id=1 리전에서 조사 기능 테스트 가능.
