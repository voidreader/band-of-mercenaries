Skill used : implement-spec

# Phase 1 — 안정성 확보 구현 결과

> **명세서:** `Docs/Review/code_review_2026-04-12.md` Phase 1
> **실행일:** 2026-04-12

---

## 구현 계획 및 실제 개발 사항

### 작업 1: 틱 레이스 컨디션 가드 추가

**문제:** `_checkCompletions()`과 `_checkArrival()`이 매초 호출되는데 async 처리 중 다음 틱이 같은 대상을 재처리할 수 있음

**구현:**
- `QuestListNotifier`에 `_completingQuestIds` (`Set<String>`) 추가 — 처리 시작 시 ID 등록, `whenComplete`로 제거
- `MovementNotifier`에 `_isCompletingMovement` (`bool`) 플래그 추가 — 처리 중이면 `_checkArrival` 조기 반환

### 작업 2: _completeQuest() God 메서드 분리

**문제:** 185줄 단일 메서드에 보상/데미지/XP/명성 로직이 집중, 테스트 불가

**구현:**
- `QuestCompletionService` 신규 생성 — 순수 static `calculate()` 메서드로 모든 계산 수행
- `QuestCompletionResult` / `MercDamageResult` 결과 모델 정의
- `quest_provider.dart`의 `_completeQuest()`를 서비스 호출 + `_applyCompletionResult()` 부수효과 적용으로 분리
- `ExperienceService.resultMultiplier()` 파라미터를 `String` → `QuestResultType` enum으로 변경

### 작업 3: enemyPower 0 방어 코드

**구현:** `QuestCalculator.calculateSuccessRate()`에서 `enemyPower <= 0`이면 `95.0` 즉시 반환

### 작업 4: mocktail 추가 + 테스트 작성

**구현:**
- `mocktail 1.0.5` dev_dependency 추가
- `QuestCompletionService` 테스트 9개 신규 작성 (성공/대성공/실패/대실패, 시설 보너스, 거리 패널티, 다중 용병, 속도 배율)
- `QuestCalculator` 테스트 2개 추가 (enemyPower 0, 음수)
- `ExperienceService` 테스트를 `QuestResultType` enum 기반으로 업데이트

---

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|----------|----------|------|
| `lib/features/quest/domain/quest_completion_service.dart` | 신규 생성 | 순수 계산 서비스 (QuestCompletionResult, MercDamageResult 포함) |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | 레이스 컨디션 가드 + _completeQuest 리팩토링 (185줄 → ~30줄 + 서비스 위임) |
| `lib/features/quest/domain/quest_calculator.dart` | 수정 | enemyPower <= 0 방어 코드 1줄 추가 |
| `lib/features/quest/domain/experience_service.dart` | 수정 | resultMultiplier 파라미터 String → QuestResultType |
| `lib/features/movement/domain/movement_provider.dart` | 수정 | _isCompletingMovement 가드 추가 |
| `pubspec.yaml` | 수정 | mocktail 1.0.5 dev_dependency 추가 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 신규 생성 | 9개 테스트 케이스 |
| `test/features/quest/domain/quest_calculator_test.dart` | 수정 | enemyPower 0/음수 테스트 2개 추가 |
| `test/features/quest/domain/experience_service_test.dart` | 수정 | QuestResultType enum 테스트로 업데이트 |

---

## 검증 결과

- **정적 분석:** 기존 info 경고 1건만 존재 (`dispatch_screen.dart:236` — use_build_context_synchronously), 신규 이슈 없음
- **테스트:** 전체 115개 통과 (기존 104 + 신규 11)
- **build_runner 재실행:** 불필요 (freezed/hive_generator/riverpod_generator 대상 파일 미수정)

## CLAUDE.md 금지사항 위반

없음
