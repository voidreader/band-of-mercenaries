# M3 공존 정책 후속 정리 — 트레잇 진화 domain 이전 + 정렬 메모이제이션 + 다이얼로그 dismiss 일관성

> 선행 spec: `Docs/spec/M3/[spec]20260425_coexistence-policy.md` (Phase 4-6)
> 선행 plan: `Docs/spec/M3/[spec]20260425_coexistence-policy_plan.md`
> 작성일: 2026-04-26
> 산출 스킬: superpowers:brainstorming → writing-plans → implement-agent

## 1. 개요

M3 Phase 4-6 공존 정책 구현 완료 후 plan 문서에서 후속 권장으로 분리한 4개 항목 중 3개를 한 스프린트로 묶어 처리한다 (옵션 B). 4번째 항목인 `target_sector_id` 스키마 추가 + 섹터 단위 체인 하이라이트는 데이터 마이그레이션이 동반되어 별도 스프린트로 분리한다.

본 spec의 3개 항목은 모두 코드 리팩터링/성능/일관성 정리 성격으로 동작 변경 없음 (사용자 시각 동작은 동일, 내부 구조만 정리).

## 2. 요구사항

### 2.1 FR-1 — 트레잇 진화 적용 로직 domain 이전

**현재 상태**: `dispatch_screen._showTraitEvents()` (line 276~360)가 `mercenaryRepositoryProvider`를 view 레이어에서 직접 read하여 `evolveTrait()`/`comboEvolveTrait()` 호출, ActivityLog 기록, `refresh()`까지 view에서 수행.

**문제**: CLAUDE.md 아키텍처 정책 `view → domain → data` 위반. view가 data 레이어 직접 접근.

**요구사항**:
- `MercenaryListNotifier.applyEvolution(String mercId, EvolutionChoice choice)` 메서드 신설
- 메서드 책임: Repository 호출 + 트레잇 이름 lookup + ActivityLog 기록 + `refresh()`
- 메서드 위치: `features/mercenary/domain/mercenary_provider.dart` (기존 `MercenaryListNotifier` 클래스 내부)
- view(`_showTraitEvents`)는 다음과 같이 단순화:
  ```dart
  if (choice != null) {
    await ref.read(mercenaryListProvider.notifier).applyEvolution(mercId, choice);
  }
  ```
- view에서 `mercenaryRepositoryProvider` 직접 read 제거
- view에서 `activityLogProvider.notifier.addLog()` 직접 호출 제거 (domain으로 이전)
- `EvolutionChoice` 클래스(`features/mercenary/view/trait_evolution_dialog.dart`)는 그대로 활용
- 단, `EvolutionChoice`가 view 레이어에 위치한 점은 별도 검토 — 본 spec에서는 위치 변경 보류 (도메인 import 가능 여부만 확인)

### 2.2 FR-2 — QuestSortService 메모이제이션

**현재 상태**: `dispatch_screen.dart` line 112에서 `QuestSortService.sort()`를 build 메서드 내부에서 직접 호출. 1초 주기 `gameTickProvider` 변경 시마다 정렬/Map 인덱싱 재계산.

**문제**: 입력(quests/chainProgress/userData 등) 변경이 없어도 매 build마다 정렬 비용 발생.

**요구사항**:
- `sortedPendingQuestsProvider: Provider<QuestSortResult>` 신설
- 위치: `features/quest/domain/sorted_quests_provider.dart` (신규 파일)
- 입력 watch:
  - `questListProvider` (pending 필터는 Provider 내부에서 수행)
  - `chainQuestProgressProvider` (StreamProvider — `valueOrNull` 사용)
  - `userDataProvider` (region/sector)
  - `staticDataProvider` (FutureProvider — `valueOrNull`)
- 부수적 read (변경 시 재계산이 필요한 의존성):
  - `regionStateRepositoryProvider.getState(region)` — `regionTransformedProvider` 또는 `currentRegionSectorChangesProvider`를 추가 watch하여 변경 트리거
  - `factionStateRepositoryProvider.getJoinedFactionIds()` — `factionRefreshProvider`(StateProvider<int>) watch로 가입/탈퇴 변경 시 무효화
- staticData/userData null 시 빈 `QuestSortResult` 반환 (기존 dispatch_screen와 동일 fallback)
- dispatch_screen는 `final sortResult = ref.watch(sortedPendingQuestsProvider);` 단일 watch로 교체
- `QuestSortService` 자체는 변경 없음 (순수 정적 함수 유지)
- 별도 단위 테스트 불필요 (기존 `quest_sort_service_test.dart`가 핵심 로직 검증, Provider는 얇은 wiring)

### 2.3 FR-3 — 다이얼로그 큐 dismiss 일관성 통일

**현재 상태**: `app.dart`의 5개 enqueue 어댑터 listen이 도메인 Provider state 리셋 시점이 일관성 없음.
- `home_screen` 이동 채널 2개: enqueue 직후 즉시 `state = null` (큐 패턴 일치)
- `app.dart` 5개 도메인 채널: 위젯 onDismiss 콜백 내에서 리셋 또는 누락 (`InvestigationResultDialog`는 누락)

**문제**:
- `InvestigationResultDialog`가 `Navigator.pop`만 호출하고 `state = null` 미수행 → 동일 result로 listen 재발화 위험
- 5개 채널 패턴 불일치로 유지보수 시 혼동

**요구사항**:
- 5개 도메인 채널(`construction`, `investigation`, `rankUp`, `chainCompleted`, `regionTransform`) listen 어댑터 모두 **enqueue 직후 즉시 `state = null`** 패턴으로 통일
- 위젯의 onDismiss 콜백은 `Navigator.pop`만 수행 (state 책임 분리)
- 적용 후 패턴:
  ```dart
  ref.listen<XxxEvent?>(xxxProvider, (prev, next) {
    if (next == null) return;
    ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
      ...
      builder: (ctx, dismiss) => XxxDialog(event: next, onDismiss: dismiss),
    ));
    ref.read(xxxProvider.notifier).state = null;  // 즉시 리셋
  });
  ```
- 큐의 dequeue 시점은 `app.dart`의 `showDialog().then()` 콜백이 책임
- 위젯 시그니처 변경 없음 (onDismiss 받는 위젯은 그대로, 안 받는 위젯도 그대로)

### 2.4 동작 변경 없음

본 spec 3개 항목은 모두 내부 구조 정리. 사용자 관점 동작 동일:
- 트레잇 진화 팝업 → 선택 → 적용 → 활동 로그 (FR-1)
- 파견 화면 정렬 결과 (FR-2)
- 다이얼로그 큐 표시/닫기 (FR-3)

## 3. 영향 범위

### 3.1 수정 대상 파일 (4개)

| 파일 | 수정 내용 | 사유 |
|------|----------|------|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | `applyEvolution()` 메서드 + 필요 시 `TraitEvolutionApplyResult` 데이터 클래스 | FR-1 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `_showTraitEvents` view→domain 위임 단순화 / `QuestSortService.sort` 호출 제거 후 `sortedPendingQuestsProvider` watch | FR-1, FR-2 |
| `band_of_mercenaries/lib/app.dart` | 5개 enqueue 어댑터 listen에 enqueue 직후 `state = null` 추가 | FR-3 |
| `band_of_mercenaries/lib/features/investigation/view/investigation_widget.dart` (옵션) | `InvestigationResultDialog`의 dismiss 콜백 처리 — 만약 onDismiss를 받지 않는다면 state 리셋 책임 이전이 더 자연스러움 | FR-3 (보조) |

### 3.2 신규 생성 파일 (1개)

| 파일 | 역할 |
|------|------|
| `band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart` | `sortedPendingQuestsProvider` derived Provider |

### 3.3 코드 생성 필요

없음 (freezed/json_serializable/hive 어노테이션 추가 없음).

### 3.4 관련 시스템

- `MercenaryRepository.evolveTrait/comboEvolveTrait`: 그대로 사용
- `EvolutionChoice` (`features/mercenary/view/trait_evolution_dialog.dart`): domain에서 import 가능 여부 확인. view 레이어에 정의되어 있다면 domain이 view를 import하는 구조가 됨 — 권장 옵션은 `EvolutionChoice`를 `features/mercenary/domain/`로 이동 (단순 데이터 클래스, 의존 없음). 본 spec에서 함께 이전.
- `QuestSortService`: 내부 변경 없음
- 기존 `dialogQueueProvider`/`DialogQueueNotifier`/`DialogTypeRegistry`: 그대로 사용

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **derived Provider 패턴**: `lib/features/investigation/domain/region_transformed_provider.dart` `currentRegionSectorChangesProvider` — 다중 입력 watch + 단일 결과 노출 구조
- **Notifier 메서드 패턴**: `lib/features/chain_quest/domain/chain_quest_service.dart` — 콜백 파라미터 의존성 역전, 순수 서비스 (단, 본 spec의 `applyEvolution`은 Notifier 메서드라 ref 직접 사용)
- **enqueue 직후 state 리셋 패턴**: `lib/features/home/view/home_screen.dart`의 `pendingTravelChoiceProvider` listen 블록

### 4.2 주의사항

- **`EvolutionChoice` 위치 이전**: 현재 view 레이어(`trait_evolution_dialog.dart`)에 정의되어 있어 domain에서 import하면 view→domain 의존성 방향 위반. 권장은 `EvolutionChoice` 본체를 `features/mercenary/domain/` 신규 파일로 이전하고 `trait_evolution_dialog.dart`는 import만. 본 spec에서 함께 처리.
- **`factionRefreshProvider` watch**: `sortedPendingQuestsProvider`가 세력 가입/탈퇴 후 자동 갱신되려면 이 카운터를 watch에 포함해야 함. 누락 시 가입 후 정렬 결과가 즉시 갱신되지 않음.
- **`regionState` 무효화**: `regionStateRepositoryProvider`는 read-only Provider라 직접 watch 불가. `currentRegionSectorChangesProvider`(이미 존재)를 watch하면 변형 이벤트 발생 시 자동 갱신.
- **dispatch_screen의 staticData.when 구조**: 현재 build 내부에 `staticDataProvider.when(data: ...)` 구조라 `sortedPendingQuestsProvider`는 staticData null일 때 빈 결과를 반환하므로 dispatch_screen은 when 없이 watch만 해도 됨 → 더 간결.
- **flutter analyze warning 회피**: `applyEvolution` 메서드의 `BuildContext` 의존을 피하기 위해 메시지 생성도 domain에서 수행. context는 view 책임.

### 4.3 엣지 케이스

- **applyEvolution 호출 시 mercId 미존재**: 조용히 무시 (no-op). 로그 기록 없음.
- **applyEvolution 호출 시 trait key 미존재**: Repository 호출은 진행하되 ActivityLog 기록 skip.
- **sortedPendingQuestsProvider staticData/userData null**: 빈 `QuestSortResult` 반환.
- **다중 trait 이벤트 동시 진화**: 기존 for-loop 그대로 유지 (view에서 한 번에 한 mercId씩 순차 처리).
- **state 리셋 후 listen 재발화**: enqueue 직후 `state = null`로 즉시 리셋해도, 큐 dequeue 후 다음 항목 표시는 큐 listen이 처리하므로 영향 없음.

### 4.4 검증 방법

- `flutter analyze`: No issues 유지
- `flutter test`: 기존 497 테스트 PASS 유지
- 시각/동작 테스트 (수동):
  - 파견 화면 진입 → 정렬 결과 동일 확인
  - 트레잇 진화 팝업 → 선택 → ActivityLog "진화!" 메시지 확인
  - 다이얼로그 큐 8단계 시퀀스 (조사 완료 + 체인 완주 + 변형 발동 등) 정상 순차 표시
- view 레이어 직접 import 정리 확인:
  - `dispatch_screen.dart`에서 `mercenaryRepositoryProvider` import 제거
  - `dispatch_screen.dart`에서 `activityLogProvider` import 제거 (만약 본 메서드 외에 사용 없다면)

## 5. 작업 분할 (TASK 후보)

writing-plans 스킬에서 구체화하지만 사전 분할 안내:

- TASK-1: `EvolutionChoice` domain 이전 (선행 — applyEvolution 시그니처에 필요)
- TASK-2: `MercenaryListNotifier.applyEvolution()` + `TraitEvolutionApplyResult` (필요 시)
- TASK-3: `sortedPendingQuestsProvider` 신규 Provider
- TASK-4: `dispatch_screen.dart` 통합 수정 (FR-1 view 단순화 + FR-2 watch 교체)
- TASK-5: `app.dart` 5개 enqueue 어댑터 일관성 통일 (FR-3)

## 6. 명세 외 처리 (별도 스프린트)

본 spec 범위 외:

- **target_sector_id 스키마 추가 + 섹터 단위 체인 하이라이트**: `chain_quests` 테이블 컬럼 추가 → CSV 갱신 → Supabase 마이그레이션 → Dart 모델 갱신 → MovementScreen 적용. 데이터 변경이 동반되어 별도 spec.
- **`InvestigationResultDialog` onDismiss 파라미터 추가 여부**: 본 spec에서 dismiss 책임을 listen 콜백으로 이전하므로 위젯 시그니처 변경 불필요. 단, 다른 위젯과 일관성을 위해 onDismiss 파라미터 추가가 유익하다면 후속 처리.
