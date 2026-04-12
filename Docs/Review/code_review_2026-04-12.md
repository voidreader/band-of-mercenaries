# 코드베이스 종합 리뷰 리포트

> **일자:** 2026-04-12
> **대상:** band_of_mercenaries/lib/ 전체
> **규모:** 소스 파일 53개 · ~4,900줄 · 테스트 12개(104 assertions) · 정적 분석 경고 1건
> **Phase 1 완료 후:** 소스 54개 · 테스트 13개(115 assertions) · QuestCompletionService 신규 추가

---

## 목차

1. [총평](#총평)
2. [CRITICAL — 즉시 수정 필요 (4건)](#critical--즉시-수정-필요)
3. [MAJOR — 프로젝트 성장 전에 수정 권장 (10건)](#major--프로젝트-성장-전에-수정-권장)
4. [MINOR — 여유 있을 때 개선 (8건)](#minor--여유-있을-때-개선)
5. [테스트 커버리지 분석](#테스트-커버리지-분석)
6. [의존성 & 설정 건강성](#의존성--설정-건강성)
7. [리팩토링 우선순위 로드맵](#리팩토링-우선순위-로드맵)

---

## 총평

### 잘된 부분

- **feature 모듈 구조**: view/domain/data 3계층 분리가 일관되게 적용되어 있음
- **순수 도메인 서비스**: QuestCalculator, ExperienceService, TravelEventService, ReputationService, FacilityService, RecruitmentService가 static 메서드 + 주입식 의존성으로 설계되어 테스트 용이
- **정적 데이터 동기화**: Supabase 버전 비교 → 변경 테이블만 다운로드 → 로컬 JSON 캐시 전략이 잘 설계됨
- **Hive 박스명 중앙화**: HiveInitializer에서 박스명 관리
- **freezed 모델**: snake_case @JsonKey로 Supabase 컬럼명과 일치, 일관된 패턴
- **네이밍 컨벤션**: Provider(`xxxProvider`), Notifier(`XxxNotifier`), Service(`XxxService`), Repository(`XxxRepository`) 전체적으로 일관
- **테스트 품질**: 기존 테스트는 시드 Random, 경계값 테스트 등 잘 작성됨

### 핵심 문제 영역

- **공유 뮤터블 상태**: Hive 객체가 여러 Provider에서 같은 참조를 공유하며 상태 불일치 발생
- **God 메서드**: `_completeQuest()` 185줄에 게임의 핵심 로직이 집중, 테스트 불가
- **Feature 간 그물망 의존성**: 공유 관심사(ActivityLog, XP, 명성)가 core가 아닌 개별 feature에 위치
- **틱 레이스 컨디션**: async 완료 처리가 다음 틱에 의해 중복 실행 가능

---

## CRITICAL — 즉시 수정 필요

### C1. ~~게임 틱 레이스 컨디션 — 퀘스트/이동 이중 처리~~ [FIXED in Phase 1]

**파일:** `quest_provider.dart:231-239`, `movement_provider.dart:117-124`

`_checkCompletions()`과 `_checkArrival()`이 매 1초 틱마다 호출된다. 내부의 `_completeQuest()`와 `_completeMovement()`가 **async**이므로, 이전 틱의 처리가 끝나기 전에 다음 틱이 같은 퀘스트/이동을 다시 처리할 수 있다.

**영향:**
- 보상 2배 지급
- XP/명성 2배 적용
- 여행 이벤트 효과 2회 적용
- 용병 상태 전환 중복

**수정안:**
- (A) 처리 중인 ID를 `Set<String>`으로 관리, 이미 처리 중이면 스킵
- (B) 비동기 처리 시작 전에 동기적으로 상태를 전환 상태로 즉시 변경
- (C) `_isProcessing` 플래그로 전체 틱 핸들러 가드

---

### C2. Hive 뮤터블 객체 공유 — 상태 불일치

**파일:** `game_state_provider.dart`, `movement_provider.dart`

`UserData`가 `HiveObject`(뮤터블)인데, `userDataProvider`와 `movementProvider` 모두 **같은 메모리 객체 참조**를 state로 보유한다. 한쪽에서 수정하면 다른쪽 state도 변하지만 Riverpod는 감지하지 못한다.

**증상:** `movement_provider.dart:100,114,131`에서 `ref.read(userDataProvider.notifier).addGold(0)` 해킹으로 리빌드를 강제 트리거

**추가 문제:** `game_state_provider.dart:68-69`에서 `state = state`로 Riverpod 알림을 시도하지만, `UserData`에 커스텀 `==`/`hashCode`가 없고 `HiveObject`는 identity equality를 사용하므로, 같은 참조를 재할당하면 리빌드가 발생하지 않을 수 있다.

**수정안:**
- (A) UserData를 이뮤터블 value class로 래핑 (추천)
- (B) state 할당 시 clone 생성
- (C) 최소한 `==`/`hashCode` 오버라이드

---

### C3. ~~QuestListNotifier._completeQuest() — 185줄 God 메서드~~ [FIXED in Phase 1]

**파일:** `quest_provider.dart:242-426`

단일 메서드에서 다음을 모두 처리:
- 성공률 계산 → 결과 판정 → 보상 계산
- 파견비용/인건비 차감 → 골드 분배
- 데미지 처리 (사망/부상/피곤)
- 의무실 시설 보너스 계산
- XP 분배 → 레벨업 체크
- 명성 분배
- 활동 로그 기록
- 용병 상태 원복

**6개 provider와 3개 repository를 횡단**하면서, 코드베이스에서 가장 복잡한 로직이 **테스트 커버리지 0%**이다.

**수정안:**
- `QuestCompletionService` — 결과 판정 + 보상 계산 오케스트레이션
- `DamageService` — 데미지/상태 처리 로직
- 시설 보너스 조회를 기존 `FacilityService`로 통합
- 각 서비스를 순수 함수로 추출하여 단위 테스트 가능하게 설계

---

### C4. ~~UserData 모델이 movement feature에 위치하면서 전역 사용~~ [FIXED in Phase 2]

**파일:** `features/movement/domain/movement_model.dart`

`UserData`(골드, 지역, 섹터, 명성, 시설, 이동 상태 등)가 movement feature의 domain 레이어에 정의되어 있지만, **모든 feature에서 import하여 사용**한다. 이것이 feature 간 의존성 그물망의 근본 원인 중 하나이다.

**수정안:** `core/models/user_data.dart`로 이동

---

## MAJOR — 프로젝트 성장 전에 수정 권장

### M1. ~~Feature 간 의존성이 그물망 구조~~ [FIXED in Phase 2]

현재 import 관계:
```
quest     → mercenary, home (reputation_service, activity_log)
movement  → quest, mercenary, home (reputation_service, activity_log)
mercenary → home (activity_log), quest (experience_service)
home      → quest, mercenary, movement
settings  → quest, movement, mercenary
```

모든 feature가 다른 2개 이상의 feature에 의존한다. 특히:
- ActivityLog가 `home` feature에 있지만 모든 feature에서 사용
- ExperienceService가 `quest` feature에 있지만 `mercenary` repository에서도 import
- ReputationService가 `home` feature에 있지만 `quest`, `movement`에서 사용

**수정안:** ActivityLog, ExperienceService, ReputationService를 `core/domain/` 또는 `shared/domain/`으로 승격하여 feature 간 직접 의존 제거

---

### M2. 성공률 미리보기와 실제 계산 불일치

**파일:** `dispatch_detail_page.dart:201` vs `quest_provider.dart:261`

미리보기 (View에서 인라인 계산):
```dart
'${(partyPower / difficulty.enemyPower * 50 + 50).clamp(5, 95).round()}%'
```

실제 (`QuestCalculator.calculateSuccessRate()`):
- 전투력 비율 + 특성 보너스 + 퀘스트 타입 보정 - 거리 패널티 + 랜덤 편차

**플레이어가 보는 예상 성공률과 실제 결과의 성공률이 다르다.** View에서 `QuestCalculator`를 호출해야 한다 (랜덤 편차 제외).

---

### M3. SyncService 부분 실패 시 불완전 캐시

**파일:** `sync_service.dart:111-115`

첫 실행 시 `Future.wait`로 11개 테이블을 동시 다운로드한다. 일부만 성공하면:
1. 불완전한 캐시가 로컬에 남음
2. 다음 실행에서 `hasCache()` → true → incremental sync 경로로 진입
3. 버전 맵이 저장 안 됨 → 전체 재다운로드 시도 → 이번엔 try-catch에서 offline 반환
4. 결과: `StaticGameData`에 빈 리스트 전달 → `firstWhere` 크래시

**수정안:**
- (A) 트랜잭셔널 처리 — 실패 시 캐시 전체 롤백
- (B) `staticDataProvider`에서 필수 테이블 존재 검증 추가

---

### M4. View 레이어에 비즈니스 로직 침투

| 위치 | 내용 |
|------|------|
| `recruit_screen.dart:26-29` | 무료 모집 쿨다운 계산 (2시간 × 속도배율) |
| `recruit_screen.dart:95-96` | `userData.lastFreeRecruit = DateTime.now(); await userData.save();` 직접 모델 수정 + 저장 |
| `main.dart:148-186` | 방치형 보상 계산 (1G/분, 480G 상한) |

**수정안:** 각각 `RecruitmentService`, `UserDataNotifier`, `IdleRewardService`로 이동

---

### M5. ~~퀘스트 결과 enum 이중 정의~~ [FIXED in Phase 2]

**파일:** `quest_model.dart:16-25` vs `quest_calculator.dart:4`

- `QuestResult` — Hive 모델용 enum
- `QuestResultType` — Calculator 반환값 enum

같은 의미의 enum이 2개 존재하고, `quest_provider.dart:273-278`에서 수동 매핑한다. ~~`ExperienceService.resultMultiplier()`도 enum 대신 String을 받아서 (`quest_provider.dart:303-308`) 타입 안전성이 깨진다.~~ [PARTIAL FIX in Phase 1: resultMultiplier가 QuestResultType enum을 직접 수용하도록 수정됨]

**수정안:** 하나의 enum으로 통일 (enum 이중 정의 자체는 Phase 2에서 처리 예정)

---

### M6. 퀘스트 수 계산 로직 중복

**파일:** `quest_provider.dart:57-67` vs `82-97`

정보망 시설 보너스를 포함한 퀘스트 수 계산이 `generateQuests()`와 `getMaxQuestCount()` 양쪽에 복사-붙여넣기 되어 있다. 공식 변경 시 양쪽을 동시에 수정해야 하며, 한쪽을 놓치면 불일치 발생.

**수정안:** `generateQuests()`가 `getMaxQuestCount()`를 호출하도록 통합

---

### M7. ~~Settings 박스 키가 매직 스트링으로 분산~~ [FIXED in Phase 2]

| 파일 | 키 |
|------|-----|
| `main.dart:150` | `'lastActiveTime'` |
| `app.dart:110` | `'lastActiveTime'` (동일 키 2군데) |
| `sync_service.dart:17` | `'dataVersions'` |
| `mercenary_repository.dart:66` | `'dismissedMercIds'` |

키 오타나 한쪽만 리네이밍 시 컴파일 에러 없이 기능 실패.

**수정안:** `SettingsKeys` 상수 클래스로 중앙화

---

### M8. ~~addGold(0) 해킹으로 UI 리빌드 트리거~~ [FIXED in Phase 2]

**파일:** `movement_provider.dart:100, 114, 131`

`MovementNotifier`가 `UserData`를 수정한 뒤 Riverpod에 알리기 위해 `addGold(0)`을 호출한다. 의도가 불명확하고, 새 기능 추가 시 누락될 가능성이 높다.

**수정안:** `UserDataNotifier`에 `refresh()` 또는 `notifyListeners()` 메서드 추가, 또는 MovementNotifier가 UserData를 직접 관리하지 않도록 구조 변경 (M10 참조)

---

### M9. timer 재계산 유틸리티 미사용

**파일:** `timer_provider.dart:14-22`

`recalculateEndTime()` 유틸리티가 존재하지만, `quest_provider.dart`만 사용하고 `movement_provider.dart`와 `mercenary_provider.dart`는 같은 로직을 인라인으로 중복 구현한다.

**수정안:** 3개 Notifier 모두 `recalculateEndTime()` 사용으로 통일

---

### M10. ~~UserData 이중 상태 관리~~ [FIXED in Phase 2]

**파일:** `game_state_provider.dart` + `movement_provider.dart`

`UserDataNotifier`와 `MovementNotifier` 모두 state 타입이 `UserData?`이고, 같은 Hive 박스에서 로드한다. 단일 진실 원천(Single Source of Truth)이 깨져 있다.

**수정안:** `MovementNotifier`의 state를 `MovementState` (isMoving, moveEndTime 등만 포함)로 분리하고, UserData 변경은 `userDataProvider`를 통해서만 수행

---

### M11. ~~미사용 XxxList 래퍼 클래스 11개~~ [FIXED in Phase 2]

**파일:** `core/models/` 내 모든 모델 파일

`DifficultyList`, `FacilityList`, `JobList` 등 래퍼 클래스가 정의되어 있으나 어디서도 사용되지 않는다. 빌드 시간만 증가시킨다. `DifficultyList`는 JSON 키에 `'Difficultys'` 오타까지 존재.

**수정안:** 전체 삭제

---

## MINOR — 여유 있을 때 개선

### m1. 매직 넘버 산재

| 위치 | 값 | 의미 |
|------|-----|------|
| `main.dart:159-160` | `480` | 최대 방치 보상 분(8시간) |
| `main.dart:160` | `1G/분` | 방치 보상 비율 |
| `game_state_provider.dart:35` | `10` | 섹터 수 |
| `game_state_provider.dart:37` | `500` | 시작 골드 |
| `game_state_provider.dart:41` | `Duration(hours: 3)` | 무료 모집 쿨다운 |
| `mercenary_model.dart:78` | `0.1` | 레벨 보너스 배율 |
| `mercenary_model.dart:82` | `0.8` | 피곤 디버프 배율 |
| `quest_provider.dart:59,87` | `5` | 기본 퀘스트 수 |

**수정안:** `GameConfig` 또는 `GameConstants` 클래스로 중앙화

---

### m2. 리전 상한 하드코딩

**파일:** `movement_screen.dart:182`

```dart
if (_selectedRegion < 199) _selectedRegion++;
```

정적 데이터에서 `data.regions.length` 또는 `data.regions.last.region`으로 도출해야 한다.

---

### m3. use_build_context_synchronously 경고

**파일:** `dispatch_screen.dart:236`

async gap 이후 `BuildContext` 사용. `mounted` 체크가 있지만 분석기가 경고. 유일한 정적 분석 이슈.

---

### m4. ~~enemyPower 0일 때 division by zero~~ [FIXED in Phase 1]

**파일:** `quest_calculator.dart:21`

`partyPower / enemyPower`에서 `enemyPower`가 0이면 런타임 에러. 현재 데이터에는 0인 경우가 없지만 방어 코드 필요.

---

### m5. 테마 색상 하드코딩

**파일:** `app.dart:43`

`backgroundColor: const Color(0xFF1A1A1A)` — AppTheme.primary와 동일한 값이지만 직접 참조하지 않음. 테마 변경 시 불일치.

---

### m6. ActivityLogRepository.boxName 역의존

**파일:** `activity_log_repository.dart:6`

`ActivityLogRepository`가 자체 `boxName = 'activityLogs'`를 정의하고, `HiveInitializer`가 이를 역참조한다. core → feature 방향 의존성.

---

### m7. QuestPool 필드 타입 부정합

**파일:** `quest_pool.dart:11-12`

`type`과 `difficulty` 필드가 `double` 타입이지만, 의미적으로 식별자/정수이다. 부동소수점 비교 문제 가능성.

---

### m8. CLAUDE.md 테마 설명과 실제 불일치

**파일:** `app.dart` + `core/theme/app_theme.dart:77`

CLAUDE.md에 "Material 3 다크 프라이머리 테마"라고 되어 있지만, 실제 코드는 `ColorScheme.light()`를 사용하는 라이트 테마이다.

---

## 테스트 커버리지 분석

### 현재 테스트 현황

| 테스트 파일 | 모듈 | 테스트 대상 | 품질 |
|------------|------|------------|------|
| `data_loader_test.dart` | core/data | 캐시 저장/로드, parseList, hasCache | 양호 |
| `reputation_service_test.dart` | home/domain | 랭크 계산, 티어 잠금, 명성 계산 | 양호 (경계값 포함) |
| `travel_event_service_test.dart` | movement/domain | 확률, 필터링, 이벤트 롤 | 양호 (FixedRandom) |
| `movement_model_test.dart` | movement/domain | 거리/시간 계산, 속도 배율 | 적절 |
| `quest_calculator_dispatch_cost_test.dart` | quest/domain | 파견비용 범위 클램핑 | 적절 |
| `quest_generator_test.dart` | quest/domain | 퀘스트 생성 수, 리전 필터링 | 양호 (시드 Random) |
| `quest_calculator_test.dart` | quest/domain | 성공률, 결과판정, 보상, 데미지, 비용 | 강함 (22 tests) |
| `experience_service_test.dart` | quest/domain | XP 획득, 레벨업 체크 | 강함 (모든 임계값) |
| `facility_service_test.dart` | mercenary/domain | 업그레이드 비용, 효과값 | 양호 |
| `mercenary_model_test.dart` | mercenary/domain | 실효 능력치, 상태 체크 | 강함 (스태킹 테스트) |
| `recruitment_service_test.dart` | mercenary/domain | 티어 선택, 용병 생성 | 양호 (통계 분포 10K회) |
| `widget_test.dart` | root | `expect(true, isTrue)` | 무가치 (placeholder) |

### 커버리지 갭 (우선순위별)

| 영역 | 현재 | 위험도 | 비고 |
|------|------|--------|------|
| 순수 도메인 서비스 | **커버됨** | 낮음 | 잘 작성됨 |
| ~~`_completeQuest()` 오케스트레이션~~ | **커버됨** | ~~매우 높음~~ | [FIXED] QuestCompletionService로 분리 + 테스트 9개 추가 |
| `dispatch()` 파견 로직 | **0%** | 높음 | 비용 차감, 타이머 설정 |
| `_completeMovement()` + 이벤트 적용 | **0%** | 높음 | 여행 이벤트 효과 적용 |
| `SyncService.sync()` | **0%** | 높음 | 데이터 무결성 레이어 |
| `recalculateEndTime()` | **0%** | 중간 | 순수 함수, 테스트 용이 |
| Repository 전체 (4개) | **0%** | 중간 | Hive 래퍼 + 일부 로직 |
| Provider/Notifier 전체 | **0%** | 높음 | mocktail 미설치로 인프라 부재 |
| Widget/UI 전체 | **0%** | 중간 | widget_test.dart는 placeholder |

### 테스트 품질 이슈

- ~~`enemyPower = 0` division by zero 테스트 없음~~ [FIXED: 방어 코드 + 테스트 2개 추가]
- 음수 입력 (음수 골드, 음수 난이도) 엣지 케이스 테스트 없음
- `quest_calculator_test.dart`의 "returns around 50%" 테스트가 범위(5-95)만 확인 — 공식이 깨져도 clamp만 작동하면 통과
- ~~`mocktail`/`mockito`가 dev_dependencies에 없어서 Provider/Repository 테스트 인프라 자체가 부재~~ [FIXED: mocktail 1.0.5 추가]

---

## 의존성 & 설정 건강성

### pubspec.yaml

| 패키지 | 버전 | 상태 |
|--------|------|------|
| SDK | `^3.11.4` | 최신 |
| flutter_riverpod | 2.5.1 | 현행 (3.x 존재하지만 마이그레이션 불급) |
| hive / hive_flutter | 2.2.3 / 1.1.0 | **유지보수 모드** — 장기적 마이그레이션 리스크 |
| supabase_flutter | 2.8.4 | 활발 유지보수 |
| freezed / json_serializable | 2.4.7 / 6.8.0 | 현행 |
| flutter_lints | 6.0.0 | 적절 |

**누락:**
- ~~`mocktail` 또는 `mockito` — 테스트 인프라 부재 원인~~ [FIXED: mocktail 1.0.5 추가]
- 통합 테스트 설정 없음

### analysis_options.yaml

- `invalid_annotation_target: ignore` — freezed 호환 필수, 정상
- 커스텀 린트 룰 없음. 추천: `prefer_single_quotes`, `require_trailing_commas`, `avoid_print`
- generated 파일(`.g.dart`, `.freezed.dart`) exclude 패턴 없음

### 기타

- TODO/FIXME/HACK 주석: 없음 (깨끗함)
- `.env` Flutter asset으로 번들 — CI 빌드 시 주입 필요

---

## 리팩토링 우선순위 로드맵

### Phase 1 — 안정성 확보 (즉시) [COMPLETED 2026-04-12]

| # | 작업 | 관련 이슈 | 상태 |
|---|------|----------|------|
| 1 | ~~틱 레이스 컨디션 가드 추가~~ | C1 | DONE |
| 2 | ~~`_completeQuest()` 서비스 분리 + 테스트~~ | C3 | DONE |
| 3 | ~~`enemyPower` 0 방어 코드~~ | m4 | DONE |
| 4 | ~~`mocktail` 추가, 핵심 로직 테스트~~ | 테스트 갭 | DONE |

### Phase 2 — 아키텍처 정리 (1~2주) [COMPLETED 2026-04-12]

| # | 작업 | 관련 이슈 | 상태 |
|---|------|----------|------|
| 5 | ~~`UserData`를 `core/models/`로 이동~~ | C4 | DONE |
| 6 | ~~ActivityLog, ExperienceService, ReputationService → core 승격~~ | M1 | DONE |
| 7 | ~~addGold(0) → refresh() 교체~~ (최소 수정) | C2 | DONE |
| 8 | ~~`MovementNotifier` state를 `MovementState`로 분리~~ | M10 | DONE |
| 9 | ~~Settings 키 상수화~~ | M7 | DONE |
| 10 | ~~미사용 `XxxList` 래퍼 클래스 제거~~ | M11 | DONE |
| 11 | ~~퀘스트 결과 enum 통일~~ | M5 | DONE |

### Phase 3 — 품질 강화 (2~4주)

| # | 작업 | 관련 이슈 |
|---|------|----------|
| 12 | 성공률 미리보기 수식 통일 | M2 |
| 13 | View 레이어 비즈니스 로직 → 도메인 이동 | M4 |
| 14 | SyncService 부분 실패 처리 | M3 |
| 15 | timer 재계산 유틸리티 통일 | M9 |
| 16 | 매직 넘버 → GameConstants 추출 | m1 |
| 17 | Provider/Repository 테스트 확충 | 테스트 갭 |
| 18 | 커스텀 린트 룰 적용 | 설정 건강성 |

---

*이 리포트는 Claude Code에 의해 자동 생성되었습니다.*
