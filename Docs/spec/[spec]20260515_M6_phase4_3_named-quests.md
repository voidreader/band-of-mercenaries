# 지명 의뢰 시스템 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260512_named-quests.md`
> 밸런스 입력:
> - `Docs/balance-design/[balance]20260513_title-effect-values.md` (페이즈 2 #1 — 칭호 효과 풀스택 검증)
> - `Docs/balance-design/[balance]20260513_exposure-pacing.md` (페이즈 2 #2 — 가중치 α=3 / 쿨다운 24h 정량 검증)
> 선행 명세:
> - `Docs/Archive/20260513_M6_phase4_1_achievement-chronicle/spec.md` (페이즈 4 #1 — BandAchievement·MercenarySnapshot·AchievementService)
> - `Docs/Archive/20260515_M6_phase4_2_titles-flagship/spec.md` (페이즈 4 #2 — Mercenary.titleIds·UserData.flagshipMercId·TitleService)
> 작성일: 2026-05-15
> 마일스톤: M6 페이즈 4 #3 (마지막 명세)

---

## 1. 개요

플레이어가 보유한 칭호·위업·간판 용병의 정체성을 의뢰인이 알아보고 의뢰를 보내는 **지명 의뢰** 시스템을 구현한다.

핵심 동작:
- `quest_pools` 테이블에 4 컬럼 추가 (M4 `is_fixed` 패턴 재사용, 신규 테이블 0)
- `QuestGenerator.generateQuests()` 일반 풀 sampling 단계에 named hook 평가 + 가중치 +α=3 분기 추가
- 7개 의뢰 (title hook 3 + achievement_count hook 2 + flagship hook 2)
- `QuestSortService` 6→7 슬롯 (NamedTier 신설, settlementTier 다음·tier1 위)
- 24h 쿨다운 + isDispatched 잠금 + 사망/방출 시 진행 의뢰 자동 종료

본 명세는 **M6 마일스톤의 마지막 시스템**이며, 페이즈 4 #1·#2의 결과물(`bandAchievements` Hive 박스 / `Mercenary.titleIds` / `UserData.flagshipMercId`)에 의존한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### 데이터 모델

- **[FR-1] `quest_pools` 4 컬럼 확장** (Supabase migration)
  - `is_named` BOOL NOT NULL DEFAULT false — 지명 의뢰 여부
  - `named_hook_type` TEXT NULL — `'title' | 'achievement_count' | 'achievement_id' | 'flagship'`
  - `named_hook_value` TEXT NULL — hook별 값 (title_id / count 임계 / templateId / 빈 문자열)
  - `named_cooldown_hours` INT NULL DEFAULT 24 — 발급 후 동일 의뢰 재등장 쿨다운 (시간 단위)
  - CHECK 제약 2종: `named_hook_type_check` (NULL 또는 4종 enum), `named_consistency` (is_named=true ↔ named_hook_type NOT NULL)
  - INDEX `idx_quest_pools_is_named` (부분 인덱스: WHERE is_named = true)

- **[FR-2] `QuestPool` Freezed 모델 4 필드 추가**
  - `@Default(false) @JsonKey(name: 'is_named') bool isNamed`
  - `@JsonKey(name: 'named_hook_type') String? namedHookType`
  - `@JsonKey(name: 'named_hook_value') String? namedHookValue`
  - `@Default(24) @JsonKey(name: 'named_cooldown_hours') int namedCooldownHours`

- **[FR-3] `UserData.namedQuestCooldowns` HiveField 26 신규**
  - 타입: `Map<String, DateTime>` (quest_pool_id → 다음 발급 가능 시각)
  - 기본값: 빈 Map
  - ⚠️ 기획서는 HiveField 25로 계획했으나, 페이즈 4 #2에서 25번이 `lastDispatchProtagonistMercId`로 점유되어 **HiveField 26으로 시프트**

- **[FR-4] `ActiveQuest.namedTargetMercId` HiveField 26 신규**
  - 타입: `String?`
  - flagship 의뢰 발급 시 발급 시점의 `UserData.flagshipMercId`를 동결
  - 기본값: null

#### 의뢰 발급 로직

- **[FR-5] `QuestGenerator.generateQuests()` named hook 평가 분기**
  - 일반 풀 필터 단계에서 `is_named=true` 행은 별도 평가
  - 평가 통과 + 쿨다운 통과 시 가중치 +α=3 부여
  - 시그니처 확장: `Map<String, DateTime>? namedCooldowns` + `List<Mercenary> mercenaries` + `List<BandAchievement> bandAchievements` + `String? flagshipMercId` 옵션 인자 추가
  - 호출처: `QuestRepository.generateQuests()` (mercenary_provider.dart 또는 quest_provider.dart 호출 위치)

- **[FR-6] `evaluateNamedHook(QuestPool pool, NamedHookContext ctx) → bool` 헬퍼 (`quest_generator.dart` 또는 신규 `named_hook_evaluator.dart`)**
  - hook_type 분기 4종:
    - `'title'`: `mercenaries.any((m) => m.titleIds.contains(pool.namedHookValue))`
    - `'achievement_count'`: `bandAchievements.where((a) => a.type == achievement).length >= int.parse(value)`
    - `'achievement_id'`: `bandAchievements.any((a) => a.templateId == value)` (M6 MVP 미사용, FR-13.7개 의뢰는 사용 안 함)
    - `'flagship'`: `flagshipMercId != null`
  - hook_type null/unknown → false (silent skip)
  - **단일 조건 정책**: 행당 단일 hook만 평가 (M6 MVP, 복합 조건은 M9+)

- **[FR-7] 쿨다운 추적 (`QuestRepository` 또는 `QuestCompletionService` 발급 직후)**
  - ActiveQuest 생성 시 `pool.isNamed=true`이면 `userData.namedQuestCooldowns[pool.id] = now + Duration(hours: pool.namedCooldownHours)`
  - 쿨다운 평가: `cooldowns[pool.id] == null || cooldowns[pool.id]!.isBefore(now)` → 통과
  - 시간 가속 적용 시점에는 기존 의뢰/건설과 동일 비율 재계산 정책 따름 (별도 처리 불요 — DateTime 절대값 저장)

#### 정렬·UI

- **[FR-8] `QuestSortService` NamedTier 추가**
  - 6→7 슬롯: `chainTier0 / fixedTier / settlementTier / namedTier(신규) / tier1 / tier2 / tier3 / tier4`
  - `QuestSortResult.namedTier` 필드 신규 (선택사항 — sortedRest 흡수 + 위치 보장)
  - 분기 조건: `poolMap[q.questPoolId]?.isNamed == true` (fixedTier·settlement보다 우선순위 낮고, faction/elite보다 높음)
  - sortedRest 순서: `[...fixedTier, ...settlementTier, ...namedTier, ...tier1, ...tier2, ...tier3, ...tier4]`
  - namedTier 내부 정렬: 기존 `_sortByEstimatedReward` (보너스 적용 후 보상 desc → difficulty asc → id asc)

- **[FR-9] 의뢰 카드 차별화 UI**
  - 신규 `AppTheme.namedAccent = Color(0xFFE91E63)` (분홍 마젠타, 5계층 색상 분리: chain=금 / settlement=주황 / named=분홍 / faction=세력별 / elite=주황)
  - `LayerSidebar`: named 카드는 `namedAccent` 좌측 색띠
  - `QuestCardBadges`: ✩ 지명 배지 (namedAccent + 칭호명 또는 간판명 또는 "위업 N개")
  - 카드 description: hook 정보 1줄 보조 텍스트 (예: "칭호 보유 용병 지명" / "위업 3개 이상" / "간판 용병 지명")

- **[FR-10] isDispatched 잠금 상태 UI** (의뢰 카드)
  - hook=title: 해당 칭호 보유 용병이 **전원 파견 중**이면 카드 잠금
  - hook=flagship: `namedTargetMercId`로 동결된 용병이 파견 중이면 카드 잠금
  - hook=achievement_count: 잠금 무관 (모든 용병 후보)
  - 잠금 상태: 카드 배경 alpha 0.4 + "지명 용병 복귀 대기" 배지 + 용병 선택 버튼 비활성
  - 탭 토스트: "지명 용병 {name}이(가) 복귀해야 수행할 수 있습니다"

#### 보상 적용

- **[FR-11] 지명 의뢰 보상 배수 적용** (`QuestCompletionService` 또는 `QuestCalculator`)
  - 적용 순서:
    1. 기본 보상 (`questType.baseReward × difficulty`)
    2. 결과 배수 (대성공 ×2, 성공 ×1, 실패 ×0.3, 대실패 0)
    3. **지명 의뢰 배수 ×1.30~1.50** (FR-13 표 참조 — `pool.specialFlags['named_reward_multiplier']`로 표현)
    4. 칭호 효과 (PassiveBonusService.collect — questRewardMultiplier 가산)
    5. 세력 효과 / 랭크 효과
    6. 최종 골드 결정
  - 명성 보상도 동일 순서 (`named_reputation_multiplier`)
  - **데이터 표현**: `quest_pools.special_flags` JSONB에 `{"named_reward_multiplier": 1.3, "named_reputation_multiplier": 1.3}` 인라인 (별도 컬럼 추가 없음)
  - 위업 발급 hook은 일반 의뢰와 동일 (지명 의뢰 자체로는 위업 추가 발급 없음)

#### 사망·방출·간판 변경 처리

- **[FR-12] 사망/방출 시 진행 중 flagship 의뢰 자동 종료** (`MercenaryRepository.dismiss` + `QuestProvider` 사망 분기)
  - 조건: 진행 중인 ActiveQuest 중 `namedTargetMercId == deadOrReleasedMercId`인 의뢰
  - 처리: ActiveQuest 자동 제거 + ActivityLog 1줄 발급
    - 메시지: `"지명 의뢰 '{questName}'가 지명 용병의 부재로 종료되었다"`
    - ActivityLogType: 신규 `namedQuestTerminated` (HiveField 31) 추가
  - 자동 알고리즘 교체(생존 용병이 새 간판으로 자동 전환)인 경우는 진행 유지 (namedTargetMercId 동결 유지)
  - dialog enqueue 없음 (조용한 종료)

#### 데이터 시드

- **[FR-13] 7행 지명 의뢰 INSERT** (`supabase/migrations/20260515*_named_quests.sql` 인라인)

| # | id | name | hook_type | hook_value | type_id | difficulty | reward_multi | rep_multi |
|---|----|------|-----------|-----------|---------|-----------|-------------|-----------|
| 1 | `qp_named_village_savior` | 마을의 은인을 찾는다 | title | `title_village_savior` | escort | 2 | 1.30 | 1.30 |
| 2 | `qp_named_road_hunter` | 도적길 추적자에게 | title | `title_road_hunter` | raid | 3 | 1.40 | 1.30 |
| 3 | `qp_named_monster_hunter` | 괴물의 흔적을 따른다 | title | `title_monster_hunter` | raid | 4 | 1.40 | 1.30 |
| 4 | `qp_named_renowned_3` | 이름 있는 용병단을 찾는다 | achievement_count | `3` | explore | 2 | 1.30 | 1.30 |
| 5 | `qp_named_renowned_10` | 전설을 들은 의뢰인 | achievement_count | `10` | raid | 5 | 1.50 | 1.50 |
| 6 | `qp_named_flagship_letter` | 깃대를 보고 온 편지 | flagship | `""` | escort | 2 | 1.30 | 1.30 |
| 7 | `qp_named_flagship_legend` | 깃대의 전설을 찾는 자 | flagship | `""` | raid | 4 | 1.50 | 1.40 |

⚠️ #3 `qp_named_monster_hunter`는 `quest_type='hunt'`가 정적 데이터에 부재할 수 있으므로 `raid`로 통일 (또는 `quest_types` 신규 'hunt' 추가 → M9+ 위임). 본 명세는 **raid 통일**로 진행.

`special_flags` JSONB 예시 (#1):
```json
{
  "named_reward_multiplier": 1.30,
  "named_reputation_multiplier": 1.30,
  "named_description": "그 일을 해낸 사람이라면 부탁드릴 것이 있습니다..."
}
```

`min_region_diff` / `max_region_diff`: #1·#6·#7은 광역(1~5), #2·#3은 T2~T4(2~4), #4는 광역, #5는 T4~T5(4~5)

### 2.2 데이터 요구사항

| 항목 | 변경 내용 |
|------|----------|
| Supabase `quest_pools` | 4 컬럼 추가 (`is_named`/`named_hook_type`/`named_hook_value`/`named_cooldown_hours`) + CHECK 2종 + INDEX 1 + 7행 INSERT |
| `QuestPool` Freezed 모델 | 4 필드 추가 (`isNamed`/`namedHookType`/`namedHookValue`/`namedCooldownHours`) |
| `UserData` Hive 모델 | HiveField **26** 추가 `namedQuestCooldowns: Map<String, DateTime>` (기획서 25 → 페이즈 4 #2 충돌로 26 시프트) |
| `ActiveQuest` Hive 모델 | HiveField **26** 추가 `namedTargetMercId: String?` |
| `ActivityLogType` enum | HiveField **31** 추가 `namedQuestTerminated` |
| `AppTheme` | 신규 `namedAccent = Color(0xFFE91E63)` |
| `data_versions` | `quest_pools` version + 1 (기존 행 호환 + 신규 7행) |

### 2.3 UI 요구사항

**Visual Companion 미사용**: 본 명세는 신규 화면 추가 없이 기존 `dispatch_screen.dart` 의뢰 카드의 차별화 + `QuestCardBadges` + `LayerSidebar` 색상만 추가하므로 텍스트 명세로 충분.

#### 의뢰 카드 (`dispatch_screen.dart` 카드 위젯)

- **화면 진입 조건**: 파견 탭(currentTabProvider == 1) → `sortedPendingQuestsProvider.sortedRest`의 named 의뢰
- **위젯 계층**: `Card > Row [LayerSidebar(color: namedAccent) + Column [Header + Description + BottomActions + (잠금 시 LockOverlay)]]`
- **상태 변수**:
  - `pool.isNamed` (Provider 조회)
  - hook 매칭 mercenary 목록 (`mercenaries.where((m) => m.titleIds.contains(pool.namedHookValue))`)
  - `userData.flagshipMercId` (Provider 조회)
  - 잠금 여부 (FR-10 로직)
- **화면 전환**: 없음. 카드 내부 인라인 차별화만 (상태 기반 렌더링 — CLAUDE.md 제약 준수)
- **연출**: 잠금 시 카드 배경 alpha 0.4 + 회색 LockOverlay. 잠금 해제 시 일반 표시. 애니메이션 없음.

#### `QuestCardBadges` 확장 (선택사항)

- ✩ 지명 아이콘 (namedAccent) + hook 설명 텍스트 1줄
- hook=title: `"칭호 — {titleName}"`
- hook=achievement_count: `"위업 {N}개 이상"`
- hook=flagship: `"간판 용병 지명"`
- 기존 chain/elite/sector/faction 배지와 stack (Wrap 위젯)

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | 4 필드 추가 (FR-2) | freezed 모델 확장 |
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 26 `namedQuestCooldowns` 추가 (FR-3) | 쿨다운 추적 영속 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | HiveField 26 `namedTargetMercId` 추가 (FR-4) | flagship 의뢰 동결 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | HiveField 31 `namedQuestTerminated` enum 추가 (FR-12) | 자동 종료 로그 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | named hook 평가 + 가중치 +α=3 분기 + 인자 확장 (FR-5·FR-6·FR-7) | 의뢰 발급 핵심 로직 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | namedTier 추가 + sortedRest 7슬롯 (FR-8) | 정렬 위치 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` 또는 `quest_calculator.dart` | named 보상 배수 적용 (FR-11) | 보상 정합 |
| `band_of_mercenaries/lib/features/quest/data/quest_repository.dart` | named 발급 시 cooldown 갱신 + namedTargetMercId 동결 (FR-7·FR-4) | 발급 사이드이펙트 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 사망 분기 + 진행 중 flagship 의뢰 종료 (FR-12) | 자동 종료 hook |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` 또는 `mercenary_provider.dart` | dismiss 분기 + flagship 의뢰 종료 (FR-12) | 자동 종료 hook |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | named 카드 차별화 + LockOverlay (FR-9·FR-10) | UI 분기 |
| `band_of_mercenaries/lib/shared/widgets/quest_card_badges.dart` (또는 동등 위치) | ✩ 지명 배지 추가 (FR-9) | UI 차별화 |
| `band_of_mercenaries/lib/shared/widgets/layer_sidebar.dart` (또는 동등 위치) | namedAccent 색상 분기 (FR-9) | UI 차별화 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `namedAccent = Color(0xFFE91E63)` 신규 (FR-9) | 색상 정합 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | 변경 없음 — quest_pools 동기화는 기존 로직 그대로 (4 컬럼 자동 흡수) | (호환 확인용 read-only) |
| `Docs/milestone-runs/M6/state.md` | 페이즈 4 #3 완료 표기 | finalize-feature |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/named_hook_evaluator.dart` (선택) | hook 평가 헬퍼 — `QuestGenerator` 내부 정적 메서드로 통합도 가능 |
| `band_of_mercenaries/supabase/migrations/20260515*_named_quests.sql` | 4 컬럼 ALTER + CHECK + INDEX + 7행 INSERT |
| `band_of_mercenaries/test/features/quest/domain/named_hook_evaluator_test.dart` | hook 평가 단위 테스트 (4 hook 타입 × pass/fail 8 케이스) |
| `band_of_mercenaries/test/features/quest/domain/quest_sort_service_named_test.dart` | NamedTier 정렬 위치 검증 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart` | freezed 4 필드 추가 |
| `band_of_mercenaries/lib/core/models/quest_pool.g.dart` | json_serializable 갱신 |
| `band_of_mercenaries/lib/core/models/user_data.g.dart` | Hive adapter HiveField 26 추가 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart` | Hive adapter HiveField 26 추가 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | Hive enum HiveField 31 추가 |

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 1회 실행 필요.

### 3.4 관련 시스템

- **위업·연대기 (페이즈 4 #1)**: `bandAchievements` Hive 박스 read-only 조회 (achievement_count hook 평가)
- **칭호 (페이즈 4 #2)**: `Mercenary.titleIds` read-only 조회 (title hook 평가)
- **간판 용병 (페이즈 4 #2)**: `UserData.flagshipMercId` read-only 조회 (flagship hook 평가) + `flagshipMercenaryProvider` 활용 가능
- **퀘스트 생성**: `QuestGenerator` 분기 확장
- **퀘스트 정렬**: `QuestSortService` 7슬롯 확장
- **퀘스트 완료**: `QuestCompletionService` 보상 배수 적용
- **활동 로그**: `ActivityLogType.namedQuestTerminated` enum 추가
- **세이브 데이터**: UserData/ActiveQuest HiveField 추가 — nullable로 기존 세이브 자동 호환

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **`quest_pools.is_fixed` 4 컬럼 패턴** (M4): `quest_pool.dart:24-28` — DEFAULT 값 + JSONKey 명명 규칙 그대로 재사용
- **`QuestSortService.fixedTier` 분기**: `quest_sort_service.dart:67-70` — namedTier도 동일 패턴
- **`QuestGenerator` weighted sampling**: `quest_generator.dart:196-226` — `_weightedSample` 함수에 named 가중치 +α 통합
- **HiveField 추가 패턴**: `user_data.dart:80-89` (페이즈 4 #2 flagshipMercId/lastDispatchProtagonistMercId 추가 케이스)
- **DateTime Map Hive 저장**: 기존 `regionStateRepository.dart` 또는 `chain_quest_progress.dart`에서 DateTime Hive 직렬화 동작 확인 후 동일 패턴 (Hive는 DateTime 기본 지원)

### 4.2 주의사항

- **HiveField 충돌**: 기획서는 UserData HiveField 25로 계획했으나 페이즈 4 #2에서 25번이 점유되었으므로 **26으로 시프트**. ActiveQuest는 마지막 25 → 26으로 정상 진행.
- **flagshipMercId 의존**: `QuestGenerator.generateQuests()`가 flagship hook 평가 시 `userData.flagshipMercId` 필요 — 호출처에서 인자로 주입 (Provider 의존 회피, 순수 함수 유지)
- **광역 region 매칭**: #1·#4·#6은 모든 region에서 등장 가능 — `min_region_diff=1` + `max_region_diff=5`로 표현 (기존 패턴)
- **단일 트랜잭션 마이그레이션**: ALTER TABLE + CHECK 2종 + INDEX + 7행 INSERT 모두 단일 BEGIN/COMMIT 블록 (M5 패턴 정합)
- **`hunt` quest_type 미존재**: #3 괴물 사냥꾼은 `raid`로 통일 (별도 type 추가 시 데이터 마이그레이션 분리 위임)
- **시간 가속 정합**: `userData.namedQuestCooldowns`는 절대 DateTime 저장 → 기존 퀘스트/건설 시간 가속 처리와 동일 비율 자동 (별도 처리 불요)
- **`flagshipMercenaryProvider` 직접 의존 금지**: `QuestGenerator`는 순수 함수 유지 — flagshipMercId 값만 인자로 받음
- **단일 hook 정책**: M6 MVP 단일 조건만. `hookCondition` Map 구조는 미사용 (titles 테이블과 달리 quest_pools는 단일 TEXT 값으로 단순화)
- **operation-bom 별도 작업**: quest_pools 편집 폼에 4 컬럼 추가는 별도 작업 (M4 fixed_quests 4 컬럼 추가 패턴 재사용)

### 4.3 엣지 케이스

- **간판 미설정 상태에서 flagship 의뢰 생성 시도**: `evaluateNamedHook`가 false 반환 → 풀에서 자동 제외 (정상 동작)
- **flagship 의뢰 진행 중 간판 자동 알고리즘 교체 (생존)**: 진행 의뢰는 namedTargetMercId 동결 유지 (FR-12 자동 종료 분기는 사망/방출만)
- **flagship 의뢰 진행 중 간판 수동 변경 (생존)**: 위와 동일 — 진행 유지
- **여러 칭호 보유 용병 + title hook 의뢰**: `mercenaries.any((m) => m.titleIds.contains(pool.namedHookValue))` — 1명이라도 보유 시 통과. 잠금 평가는 **전원 파견 중**일 때만 활성화
- **쿨다운 중 풀 평가 시**: 가중치 +α 적용 안 함 — 일반 풀 후보에서도 제외 (false 반환 + cooldown 통과 false)
- **bandAchievements 빈 상태 + achievement_count hook**: count >= 0 매칭이지만 hook value는 항상 1+ → 자연 false (#4=3, #5=10)
- **named_hook_type=`achievement_id` 미사용**: M6 MVP는 사용 안 함 — 평가 분기는 구현하되 7개 의뢰 INSERT에는 없음 (페이즈 4 #4+ 위임)
- **신규 유저 세이브 (namedQuestCooldowns 미존재)**: HiveField 26 nullable이 아닌 default 빈 Map — Hive adapter가 자동 처리
- **isDispatched 잠금 평가 시 mercenaries 빈 상태**: hook=title이면 `any` false → "잠금 무관" (사용자가 칭호 보유 용병이 0명이면 그 의뢰 자체가 풀에서 제외됨)

### 4.4 구현 힌트

- **진입점**:
  - 데이터 마이그레이션 → `supabase/migrations/20260515*_named_quests.sql`
  - 모델 확장 → `quest_pool.dart` + `user_data.dart` + `quest_model.dart` + `activity_log_model.dart`
  - 발급 로직 → `quest_generator.dart::generateQuests()` 일반 풀 sampling 직전 named 평가 추가
  - 정렬 → `quest_sort_service.dart::sort()` for-loop에 isNamed 분기 추가
  - 보상 → `quest_completion_service.dart::completeQuest()` 또는 `quest_calculator.dart::calculateReward()`
  - 자동 종료 → `quest_provider.dart` 사망 분기 + `mercenary_repository.dart::dismiss()` 직전
  - UI → `dispatch_screen.dart` 카드 위젯 + `app_theme.dart::namedAccent`

- **데이터 흐름**:
  ```
  SQL migration → SyncService 자동 감지 (quest_pools version + 1) → 로컬 cache 갱신
    ↓
  QuestPool 모델 4 필드 자동 흡수 (json_serializable)
    ↓
  사용자 액션 (이동 또는 1시간 갱신) → QuestRepository.generateQuests()
    ↓
  QuestGenerator.generateQuests(
    questPools, mercenaries, bandAchievements, flagshipMercId,
    namedCooldowns = userData.namedQuestCooldowns
  )
    ↓
  is_named=true 풀 → evaluateNamedHook + cooldown 통과 → weight +α=3 sampling
    ↓
  ActiveQuest 생성 시 namedTargetMercId 동결 (flagship 한정)
    ↓
  cooldown 갱신: userData.namedQuestCooldowns[poolId] = now + 24h
    ↓
  sortedPendingQuestsProvider → QuestSortService → namedTier 분기
    ↓
  dispatch_screen.dart → 카드 차별화 + LockOverlay
  ```

- **참조 구현**:
  - `quest_generator.dart:48-57` — 일반 풀 필터링 패턴 (where 체인) — named 분기 통합 위치
  - `quest_generator.dart:196-226` — `_weightedSample` 함수 — weight 계산 분기 통합
  - `quest_sort_service.dart:67-70` — fixedTier 분기 패턴 — namedTier도 동일
  - `mercenary_provider.dart` (페이즈 4 #2) — dismiss 분기 hook 패턴
  - `quest_provider.dart` (페이즈 4 #1) — 사망 분기 hook 패턴

- **확장 지점**:
  - `QuestGenerator.generateQuests()` 호출처 = `quest_repository.dart::generateQuests()` (또는 동등) — 인자 4개 추가 (mercenaries, bandAchievements, flagshipMercId, namedCooldowns)
  - `QuestSortResult` Freezed 또는 일반 클래스 → namedTier 필드 선택사항 (sortedRest 흡수만으로 충분)
  - `AppTheme` 신규 색상 → CLAUDE.md UI 섹션 색상 목록에 namedAccent 추가

---

## 5. 기획 확인 사항

기획서의 Q-1~Q-6 및 본 명세 도입 결정:

- **[Q-1] 가중치 α 수치** → 페이즈 2 #2 검증 완료, **α=3** 채택 (`exposure-pacing.md` §3.1)
- **[Q-2] 복합 조건 도입** → M6 MVP **단일 조건만**, 복합 조건은 M9+ 위임
- **[Q-3] 의뢰 description 동적 렌더 (TemplateEngine)** → M6 MVP **정적 텍스트**, 동적 렌더는 페이즈 5+ 검토
- **[Q-4] NamedTier UI 색상** → **`namedAccent = Color(0xFFE91E63)` 신규** (5계층 색상 분리: chain=금 / settlement=주황 / named=분홍 / faction=세력별 / elite=주황 — settlement/elite가 모두 주황이므로 named는 분홍 마젠타로 시각 분리)
- **[Q-5] 간판 변경 처리** → **사망/방출 자동 종료** + **자동 알고리즘 생존 교체 진행 유지** (FR-12)
- **[Q-6] 의뢰 만료 정책** → **일반 의뢰와 동일 1시간 만료** (다음 갱신 주기에도 hook 통과하면 자연 재등장, 쿨다운은 ActiveQuest 발급 시에만 시작)

추가 결정:
- **[Q-N1] HiveField 시프트** → 기획서 UserData HiveField 25 계획 → 페이즈 4 #2 점유 충돌 → **HiveField 26으로 시프트** (FR-3)
- **[Q-N2] `hunt` quest_type 부재** → **#3 의뢰는 raid로 통일** (별도 type 추가는 M9+ 위임)
- **[Q-N3] 보상 배수 표현** → **`special_flags` JSONB 인라인** (`named_reward_multiplier` / `named_reputation_multiplier`) — 별도 컬럼 추가 회피
- **[Q-N4] ActivityLogType 신규** → **HiveField 31 `namedQuestTerminated`** 추가 (FR-12 자동 종료 로그용)
- **[Q-N5] `QuestSortResult.namedTier` 필드** → **선택사항**으로 sortedRest 흡수만으로도 충분. 구현 시 명시 필드 권장 (테스트 가독성)
- **[Q-N6] `named_hook_evaluator.dart` 분리** → **선택사항**. `QuestGenerator` 내부 정적 메서드로 충분히 표현 가능. 단위 테스트 격리 위해 분리 권장
- **[Q-N7] `flagshipMercenaryProvider` 의존** → **QuestGenerator는 순수 함수 유지**, flagshipMercId 값만 인자로 전달 (Provider 직접 의존 회피)

---

## 6. 단위 테스트 요구사항

### 6.1 `named_hook_evaluator_test.dart`

- title hook: 보유/미보유 mercenaries × pass/fail (2 케이스)
- achievement_count hook: 3개 미만/이상/정확 × pass/fail (3 케이스)
- flagship hook: null/non-null flagshipMercId (2 케이스)
- achievement_id hook: M6 MVP 미사용이지만 평가 분기 검증 (1 케이스)
- hook_type null/unknown silent skip (1 케이스 + 1 케이스)
- 총 **8~10 케이스**

### 6.2 `quest_sort_service_named_test.dart`

- named 의뢰 1개 + 일반 의뢰 3개 → namedTier 위치 settlementTier 다음, tier1 위 (1 케이스)
- named + settlement + tier1 혼재 → 순서 검증 (1 케이스)
- named 의뢰 0개 → 기존 동작 영향 없음 (1 케이스)
- 총 **3 케이스**

### 6.3 통합 검증 (수동)

- 실제 신규 유저 1시간 플레이 → 첫 named 의뢰 등장 확인 (페이즈 2 #2 모니터링 지표 5번)
- 칭호 미보유 → title hook 의뢰 풀 제외 확인
- 간판 미설정 → flagship hook 의뢰 풀 제외 확인
- 24h 쿨다운 회전 확인 (시간 가속 + 동일 의뢰 발급 후 25h+ 후 재등장)

---

## 7. 실행 순서 권장 (구현 시)

1. **데이터 모델** (FR-1·FR-2·FR-3·FR-4): Supabase migration + QuestPool freezed + UserData/ActiveQuest HiveField + build_runner
2. **AppTheme**: namedAccent 색상 추가
3. **헬퍼**: `named_hook_evaluator.dart` (또는 QuestGenerator 내부) + 단위 테스트
4. **QuestGenerator**: 인자 확장 + named 평가 + weight +α 분기 + 호출처 인자 주입
5. **QuestSortService**: namedTier 분기 + 단위 테스트
6. **보상 적용** (FR-11): QuestCompletionService 또는 QuestCalculator
7. **쿨다운 갱신** (FR-7): QuestRepository 발급 직후
8. **자동 종료** (FR-12): MercenaryRepository.dismiss + quest_provider 사망 분기 + ActivityLogType.namedQuestTerminated
9. **UI** (FR-9·FR-10): dispatch_screen 카드 + LayerSidebar + QuestCardBadges + LockOverlay
10. **데이터 시드** (FR-13): 7행 SQL INSERT (마이그레이션 단일 트랜잭션에 통합)
11. **finalize-feature**: state.md 갱신 + CHANGELOG fragment + Archive + commit

---

## 8. M6 마일스톤 완료 요건

본 명세 구현 완료 시 M6 마일스톤 전체 완료. roadmap 종료 조건 충족 검증:

- ✅ "신규 유저 3~5시간 안 1회 이상 지명 의뢰 등장": 페이즈 2 #2 정량 검증 (평균 페이스 1.1h마다 1회 자연)
- ✅ "강한 용병/특정 칭호 보유 용병을 요구하는 의뢰가 1회 이상": 11 칭호 × 7 의뢰 매칭 + 3 hook
- ✅ "사망/방출 용병의 기록도 연대기에 유지": 페이즈 4 #1 MercenarySnapshot 5필드 영속 + 페이즈 4 #2 titleIds 동결
- ✅ "최소 1명의 용병 이름·칭호 기억": 페이즈 4 #2 11종 칭호 + AchievementUnlockedDialog grantedTitles 인라인 + TitleUnlockedDialog

M6 페이즈 4 #3 완료 후 마일스톤 전체 `state.md` 상태 `in_progress → completed` 전환.
