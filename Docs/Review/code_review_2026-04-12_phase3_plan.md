Skill used : implement-spec

# Phase 3 — 품질 강화 구현 결과

> **명세서:** `Docs/Review/code_review_2026-04-12.md` Phase 3
> **실행일:** 2026-04-12

---

## 구현 사항

### 작업 16: GameConstants 추출
`core/constants/game_constants.dart` 신규 생성. 10개 매직 넘버를 상수로 중앙화. `game_state_provider`, `main.dart`, `quest_provider`, `mercenary_model`, `recruit_screen` 5개 파일에서 상수 참조로 교체.

### 작업 15: timer 재계산 통일
`movement_provider`와 `mercenary_provider`의 인라인 타이머 재계산 로직을 `recalculateEndTime()` 유틸리티 호출로 통일. 3개 Notifier가 동일 유틸 사용.

### 작업 18: 린트 룰
`analysis_options.yaml`에 `avoid_print: true` 추가. `prefer_single_quotes`, `require_trailing_commas`는 기존 코드 대량 변경 필요로 이번 Phase에서 제외.

### 작업 12: 성공률 미리보기 수식 통일
`QuestCalculator.calculateSuccessRatePreview()` 추가 — 랜덤 편차 없이 특성 보너스, 퀘스트 타입 보정, 거리 패널티를 포함한 결정적 성공률 계산. `dispatch_detail_page.dart`의 인라인 수식을 교체.

### 작업 13: View 비즈니스 로직 도메인 이동
- `RecruitmentService`: `canFreeRecruit()`, `freeRecruitRemaining()` 추가
- `UserDataNotifier`: `recordFreeRecruit()` 추가
- `IdleRewardService`: 신규 생성 (`core/domain/`)
- `recruit_screen.dart`: 쿨다운 계산 → `RecruitmentService`, 모델 직접 수정 → `recordFreeRecruit()`, 비용 100 → `GameConstants.paidRecruitCost`
- `main.dart`: 방치형 보상 계산 → `IdleRewardService.calculateReward()`

### 작업 14: SyncService 부분 실패 처리
`_fullDownload()`에 try-catch 추가. 실패 시 `_dataLoader.clearCache()`로 불완전 캐시 롤백 후 rethrow. `DataLoader.clearCache()` 메서드 추가.

### 작업 17: 테스트 확충
- `quest_calculator_preview_test.dart` — 8개 테스트 (결정적 성공률 미리보기)
- `idle_reward_service_test.dart` — 4개 테스트 (방치형 보상)
- `recruitment_service_cooldown_test.dart` — 6개 테스트 (쿨다운 계산)
- `timer_provider_test.dart` — 5개 테스트 (타이머 재계산 유틸)

---

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|----------|----------|------|
| `core/constants/game_constants.dart` | 신규 | 게임 상수 10개 |
| `core/domain/idle_reward_service.dart` | 신규 | 방치형 보상 계산 서비스 |
| `core/data/data_loader.dart` | 수정 | clearCache() 추가 |
| `core/data/sync_service.dart` | 수정 | _fullDownload() 에러 핸들링 |
| `core/providers/game_state_provider.dart` | 수정 | 상수 사용 + recordFreeRecruit() |
| `features/quest/domain/quest_calculator.dart` | 수정 | calculateSuccessRatePreview() 추가 |
| `features/quest/domain/quest_provider.dart` | 수정 | 상수 사용 |
| `features/quest/view/dispatch_detail_page.dart` | 수정 | 성공률 미리보기 수식 교체 |
| `features/mercenary/domain/mercenary_model.dart` | 수정 | 상수 사용 |
| `features/mercenary/domain/mercenary_provider.dart` | 수정 | recalculateEndTime() 통일 |
| `features/mercenary/domain/recruitment_service.dart` | 수정 | 쿨다운 메서드 추가 |
| `features/mercenary/view/recruit_screen.dart` | 수정 | 서비스 호출 + 상수 사용 |
| `features/movement/domain/movement_provider.dart` | 수정 | recalculateEndTime() 통일 |
| `main.dart` | 수정 | IdleRewardService + 상수 사용 |
| `analysis_options.yaml` | 수정 | avoid_print 추가 |
| `android/app/src/main/AndroidManifest.xml` | 수정 | INTERNET 퍼미션 추가 (버그픽스) |
| `test/` 4개 파일 | 신규 | 23개 테스트 추가 |

## build_runner 재실행

불필요 (freezed/hive 대상 파일 미수정)

## 검증 결과

- **정적 분석:** 기존 info 1건만 (dispatch_screen.dart), 신규 이슈 0
- **테스트:** 전체 138개 통과 (기존 115 + 신규 23)

## CLAUDE.md 금지사항 위반

없음
