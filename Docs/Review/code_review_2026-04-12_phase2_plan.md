Skill used : implement-spec

# Phase 2 — 아키텍처 정리 구현 결과

> **명세서:** `Docs/Review/code_review_2026-04-12.md` Phase 2
> **실행일:** 2026-04-12

---

## 구현 계획 및 실제 개발 사항

### 작업 10: 미사용 XxxList 래퍼 클래스 제거
11개 모델 파일에서 미사용 `XxxList` wrapper 클래스를 삭제. build_runner 재생성으로 `.freezed.dart`, `.g.dart` 파일 크기 감소.

### 작업 9: Settings 키 상수화
`SettingsKeys` 상수 클래스를 `core/data/settings_keys.dart`에 신규 생성. `main.dart`, `app.dart`, `sync_service.dart`, `mercenary_repository.dart` 4개 파일의 매직 스트링을 상수 참조로 교체.

### 작업 11: QuestResult enum 통일
`QuestResultType` (quest_calculator.dart)을 삭제하고 `QuestResult` (quest_model.dart, Hive adapter 보유)로 통일. `QuestCompletionResult`에서 불필요해진 `questResult` 필드 제거. `ExperienceService.resultMultiplier`도 `QuestResult` 직접 수용으로 변경. 소스 7개 + 테스트 3개 파일 업데이트.

### 작업 5: UserData → core/models/ 이동
`features/movement/domain/movement_model.dart`에서 `UserData` 클래스를 `core/models/user_data.dart`로 이동. 원본 파일 및 `.g.dart` 삭제. 6개 lib 파일 + 1개 테스트 파일의 import 경로 변경.

### 작업 6: 서비스 core/domain/ 승격
`core/domain/` 디렉토리 신설. ActivityLog (model, provider, repository), ExperienceService, ReputationService 5개 파일을 feature에서 core로 이동. ~15개 파일의 import 경로 일괄 변경.

### 작업 7: addGold(0) → refresh() 교체
`UserDataNotifier`에 `refresh()` 메서드 추가. `MovementNotifier`에서 `addGold(0) // trigger rebuild` 해킹 3군데를 `refresh()` 호출로 교체.

### 작업 8: MovementState 분리
`MovementState` 클래스 신규 생성 (이동 관련 필드만 포함). `MovementNotifier`의 state 타입을 `UserData?` → `MovementState?`로 변경. UserData 직접 보유를 제거하여 단일 진실 원천(SSOT) 복원.

---

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|----------|----------|------|
| `core/models/user_data.dart` | 신규 생성 | UserData 클래스 (movement_model.dart에서 이동) |
| `core/data/settings_keys.dart` | 신규 생성 | SettingsKeys 상수 클래스 |
| `core/domain/activity_log_model.dart` | 이동 | features/home/domain/ → core/domain/ |
| `core/domain/activity_log_provider.dart` | 이동 | features/home/domain/ → core/domain/ |
| `core/domain/activity_log_repository.dart` | 이동 | features/home/data/ → core/domain/ |
| `core/domain/experience_service.dart` | 이동 | features/quest/domain/ → core/domain/ |
| `core/domain/reputation_service.dart` | 이동 | features/home/domain/ → core/domain/ |
| `features/movement/domain/movement_state.dart` | 신규 생성 | MovementState 클래스 |
| `features/movement/domain/movement_model.dart` | 삭제 | UserData가 core로 이동됨 |
| `core/models/difficulty.dart` | 수정 | DifficultyList 삭제 |
| `core/models/facility.dart` | 수정 | FacilityList 삭제 |
| `core/models/job.dart` | 수정 | JobList 삭제 |
| `core/models/mercenary_wage.dart` | 수정 | MercenaryWageList 삭제 |
| `core/models/person_name.dart` | 수정 | PersonNameList 삭제 |
| `core/models/quest_pool.dart` | 수정 | QuestPoolList 삭제 |
| `core/models/quest_type.dart` | 수정 | QuestTypeList 삭제 |
| `core/models/rank.dart` | 수정 | RankList 삭제 |
| `core/models/region.dart` | 수정 | RegionList 삭제 |
| `core/models/trait_data.dart` | 수정 | TraitDataList 삭제 |
| `core/models/travel_event.dart` | 수정 | TravelEventList 삭제 |
| `core/data/hive_initializer.dart` | 수정 | import 경로 변경 |
| `core/data/sync_service.dart` | 수정 | SettingsKeys 사용 |
| `core/providers/game_state_provider.dart` | 수정 | import 변경 + refresh() 추가 |
| `features/quest/domain/quest_calculator.dart` | 수정 | QuestResultType 삭제 |
| `features/quest/domain/quest_completion_service.dart` | 수정 | enum 통일 + import 변경 |
| `features/quest/domain/quest_provider.dart` | 수정 | enum 통일 + import 변경 |
| `features/quest/domain/experience_service.dart` | 수정(이동) | QuestResult enum 수용 |
| `features/movement/domain/movement_provider.dart` | 수정 | MovementState + refresh() + import 변경 |
| `features/movement/data/movement_repository.dart` | 수정 | import 변경 |
| `features/movement/view/movement_screen.dart` | 수정 | import 변경 |
| `features/home/view/home_screen.dart` | 수정 | import 변경 |
| `features/mercenary/data/mercenary_repository.dart` | 수정 | SettingsKeys + import 변경 |
| `features/mercenary/view/mercenary_card.dart` | 수정 | import 변경 |
| `features/mercenary/domain/mercenary_provider.dart` | 수정 | import 변경 |
| `main.dart` | 수정 | SettingsKeys 사용 |
| `app.dart` | 수정 | SettingsKeys 사용 |
| `test/` 다수 파일 | 수정 | import 경로 변경, enum 통일 |

---

## build_runner 재실행

필요함 — 실행 완료됨 (`dart run build_runner build --delete-conflicting-outputs`)

대상: core/models/ 11개 freezed 모델 + core/models/user_data.dart + core/domain/activity_log_model.dart

## 검증 결과

- **build_runner:** 성공 (139 outputs, 8.4s)
- **정적 분석:** 기존 info 경고 1건만 존재 (dispatch_screen.dart), 신규 이슈 없음
- **테스트:** 전체 115개 통과

## CLAUDE.md 금지사항 위반

없음
