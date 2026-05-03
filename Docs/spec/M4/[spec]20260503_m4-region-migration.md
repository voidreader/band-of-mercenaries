# M4 페이즈 4 #1 — 데이터 마이그레이션 + 시작 거점 고정 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260503_region-40-redesign.md` (M4 페이즈 1 #1) — 살아남는 40개 region_id 리스트 + 더스트플레인 region 3 재태깅 + T9 region 200 신규 추가 + 종속 데이터 매핑 정책
> - `Docs/balance-design/[balance]20260503_chore-quest-economy.md` (M4 페이즈 2 #3) — 시작 골드 200G 확정 + 시작 의뢰 풀 6개 분포 (난이도 1 ×5 + 난이도 2 ×1) + freeRecruitCooldown 2h 유지
>
> 작성일: 2026-05-03

---

## 1. 개요

199개 리전을 40개로 축소하고, 시작 거점을 더스트플레인(region 3 / sector 1)으로 고정한다. region_id 보존 정책을 따라 살아남는 40개는 그대로 유지하고, 159개 삭제 region은 단일 dump JSON으로 보관(rollback 가능). 종속 데이터(region_discoveries / chain_quests / quest_pools / elite_loot_tables / factions)는 정책별로 일괄 처리하며, Hive 사용자 데이터(`UserData.region`, `regionStates`, `factionStates.clueRecords`)는 살아남지 못한 region을 참조할 경우 자동 정리한다. 시작 골드는 500G→200G로 하향하고, `initializeNewGame()`은 random region/sector 부여 로직을 제거하여 `(3, 1)`로 고정한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### [FR-1] Supabase regions 테이블 199→40 마이그레이션

- 살아남는 40개 region_id 리스트(페이즈 1 #1 4절 확정안):
  - **T1 (3)**: 3, 31, 127
  - **T2 (5)**: 9, 10, 20, 23, 146
  - **T3 (7)**: 5, 38, 49, 50, 51, 52, 65
  - **T4 (6)**: 13, 16, 21, 24, 28, 35
  - **T5 (5)**: 1, 25, 67, 90, 105
  - **T6 (4)**: 17, 36, 62, 84
  - **T7 (4)**: 44, 56, 115, 154
  - **T8 (3)**: 4, 18, 47
  - **T9 (1)**: 200 (신규)
  - **T10 (2)**: 7, 11
  - 합계: 40개 (T9 신규 포함)
- 위 40개를 제외한 159개 region 행은 삭제한다.
- 마이그레이션 실행 전 159개 region + 해당 region 참조 region_discoveries 행을 단일 JSON 파일(`Docs/content-data/postponed_regions_dump.json`)로 추출하여 보관한다(rollback 가능).
- 마이그레이션 SQL 위치: `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql`
- 단일 트랜잭션(BEGIN/COMMIT)으로 묶어 부분 실패 시 전체 롤백한다.

#### [FR-2] 더스트플레인 region 3 재태깅

- `regions` 테이블에서 region_id = 3 행을 다음과 같이 UPDATE한다:
  - `region_name` → "더스트플레인"
  - `environment_tags` → `["mountain"]` (JSONB)
  - `description` → "광산을 품은 변방 산악 지역. 신참 용병들이 첫 발을 떼는 곳."
  - `region_tier`, `recommend_power`, `region`(=3), `continent` 컬럼은 그대로 유지
- region_id 재부여는 발생하지 않는다(C1 보존 원칙).

#### [FR-3] T9 region 200 신규 추가

- `regions` 테이블에 INSERT:
  - `region` = 200
  - `continent` = 1
  - `region_tier` = 9
  - `region_name` = "망각의 수면"
  - `recommend_power` = 380
  - `environment_tags` = `["underground"]` (JSONB)
  - `description` = "T8 마계경계와 T10 심연 사이의 깊이. 시간이 멈춘 듯한 수면이 펼쳐져 있다. (M9 종속 시스템 확장 예정)"
- M4 시점 진입 불가(명성 랭크 부족 + 종속 시스템 미지원). 데이터 일관성 차원의 추가.

#### [FR-4] 종속 데이터 일괄 변환

- `region_discoveries`: 살아남는 40개 region 한정 보존, 다른 행 삭제. 삭제 전 `postponed_regions_dump.json`에 함께 보관.
- `quest_pools`: region 직접 참조 컬럼 없음(`min_region_diff` / `max_region_diff` 차이 기반 매칭). **변경 없음**.
- `chain_quests`: chain_quests 참조 region_id 13개 {10, 16, 21, 24, 28, 31, 35, 38, 47, 49, 50, 51, 65}는 모두 살아남는 40개 안에 포함된다(페이즈 1 #1 4절 검증). region_id / target_region_id 변환 **불필요**. `target_sector_id`(1..10) 변환은 페이즈 4 #2 산출물에서 처리(본 명세 범위 외).
- `elite_loot_tables`: region 참조 없음. **변경 없음**.
- `factions`: `tier_range` JSONB만 보유, region 직접 참조 컬럼 없음(`stronghold_region_id`는 M4 #2 산출물에서 신설 예정). **변경 없음**. 단, `tier_range` 값이 보존 가능 범위(1..10) 내인지 검증 SQL 한 줄 포함.

#### [FR-5] data_versions 업데이트

- 마이그레이션 SQL 마지막에 `data_versions` 테이블의 다음 키 버전을 +1 한다:
  - `regions`
  - `region_discoveries`
- 기존 클라이언트는 다음 SyncService 호출 시 변경분만 다운로드한다(전체 동기화 불필요).

#### [FR-6] Hive 사용자 데이터 마이그레이션

- 신규 settings 키 `region_migration_v1`(boolean)을 도입한다. 첫 실행 시 false → true 전환하면서 다음 정리를 수행한다:
  - **`regionStates` 박스**: 살아남지 못한 159개 region_id를 키로 가진 `RegionState` 행을 삭제한다. 살아남는 40개 region_id 행은 `knowledge` / `triggeredDiscoveries` / `sectorChanges` 모두 그대로 보존한다.
  - **`user` 박스**: `UserData.region`이 살아남지 못한 region을 참조할 경우, `region = 3` / `sector = 1`로 강제 이동한다. 동시에 이동 중 상태(`isMoving`, `moveTargetRegion`, `moveStartTime`, `moveEndTime`, `moveTargetSector`)와 조사 상태(`investigatingMercId`, `investigationEndTime`, `investigationRegionId`)를 모두 클리어한다(이동/조사 대상 region이 존재하지 않을 가능성).
  - **`factionStates` 박스**: 모든 `FactionState.clueRecords` 리스트를 순회하여 살아남지 못한 region을 참조하는 `FactionClueRecord`를 삭제한다. 0개로 줄어든 `FactionState`는 박스에 그대로 두되 `maxClueLevel` getter가 0을 반환하도록 동작 보장(추가 코드 변경 없음, 기존 getter 그대로).
- 정리 후 settings 박스에 `region_migration_v1 = true`를 저장한다. 이후 실행에서는 스킵.

#### [FR-7] GameConstants 변경

- `startingGold`: 500 → **200** (페이즈 2 #3 결정).
- `startingRegionId`: **3** (신규 상수, int).
- `startingSector`: **1** (신규 상수, int).
- `sectorCount`: 10 → **`@Deprecated('M4 페이즈 4 #2: region_sectors.sector_count로 대체')` 마킹**. 값 자체는 10 유지(기존 호출자 호환). 본 명세는 stub만 마련하며, 실제 동적 조회 도입은 페이즈 4 #2 명세에서 처리한다.

#### [FR-8] initializeNewGame() 변경

- 현재 `random` 기반 Tier 1 region 선택 + sector 1~10 random 부여 로직을 제거한다.
- `region = GameConstants.startingRegionId (3)`, `sector = GameConstants.startingSector (1)` 고정.
- `staticData.regions`에서 region 3을 lookup하여 `regionTier`, `environmentTags`를 후속 `QuestGenerator.generateQuests` 호출에 전달.
- 시작 골드는 `GameConstants.startingGold` (= 200) 그대로 사용.
- 시작 무료 모집 정책 유지: `lastFreeRecruit = DateTime.now().subtract(GameConstants.freeRecruitCooldown)` 그대로(첫 모집 무료 즉시 가능).
- 시작 용병 4명 생성 로직(`RecruitmentService.generateStartingMercenaries`) 변경 없음.

#### [FR-9] 시작 의뢰 풀 6슬롯 분포

- `initializeNewGame()` 내부 시작 의뢰 생성 로직을 다음과 같이 변경:
  - 슬롯 1: 활성 체인 step 1 (region 3 활성화 시 `ChainQuestService.tryActivate` 결과 → `injectChainStep`). 본 명세 시점에 chain_quests에 해당 단계가 존재하지 않으면 일반 풀에서 난이도 1 1건으로 대체.
  - 슬롯 2~5: 더스트빌 허드렛일 4건 (난이도 1 / region 3 매칭 풀에서 random 선택).
  - 슬롯 6: 난이도 2 1건 (region 3 매칭 풀 + `min_region_diff <= 1 <= max_region_diff` 조건 만족 풀에서 random).
- **본 명세는 6슬롯 분포 정책만 정의**한다. 구체적 풀 ID(예: `dustvile_chore_01·07·08·10`)는 페이즈 4 #3 산출물(허드렛일 풀 INSERT)이 선행되어야 활성화되므로, 본 명세 구현 시점에는 `quest_pools` 테이블에 더스트빌 허드렛일 풀이 0건일 수 있다. 이 경우 `QuestGenerator.generateQuests`가 기존 알고리즘으로 난이도 1 풀 5건을 채우도록 한다(임시 fallback).
- `GameConstants.baseQuestCount`를 5 → **6**으로 상향한다(시작 슬롯 6개 정책 정합).

#### [FR-10] 운영 도구(operation-bom) 영향 가이드

- 본 명세는 Flutter 앱과 Supabase 마이그레이션에 집중한다. operation-bom 측 변경은 별도 후속 작업으로 가이드 문서로만 제공한다:
  - 199→40 적용 후 region 편집 폼이 정확히 40개만 표시되는지 검증.
  - 삭제된 159개 region을 편집 시도하면 404 또는 "삭제된 region" 표시.
  - dump JSON(`Docs/content-data/postponed_regions_dump.json`) 백업 절차 README 추가.
  - region_id 3 / 200 항목의 신규 필드 값(`region_name`, `environment_tags`, `description`)이 편집 폼에서 정상 노출되는지 확인.

### 2.2 데이터 요구사항

#### Supabase 정적 데이터

| 테이블 | 변경 내용 | 비고 |
|--------|----------|------|
| `regions` | DELETE 159행 + UPDATE region 3 + INSERT region 200 | 단일 트랜잭션 |
| `region_discoveries` | DELETE — 살아남지 못한 159 region 참조 행 | dump JSON 보관 후 삭제 |
| `chain_quests` | 변경 없음 | 보존 region만 사용 검증 완료 |
| `quest_pools` | 변경 없음 | region 직접 참조 컬럼 없음 |
| `elite_loot_tables` | 변경 없음 | region 참조 없음 |
| `factions` | 변경 없음 | tier_range 값 검증 SQL만 추가 |
| `data_versions` | UPDATE — `regions`, `region_discoveries` 키 버전 +1 | 클라이언트 증분 동기화 트리거 |

#### Hive 박스

| 박스 | 변경 내용 | 비고 |
|------|----------|------|
| `settings` | `region_migration_v1` 키 신규 추가 (bool) | SettingsKeys 상수에 등록 |
| `user` | `UserData.region`이 살아남지 못한 값이면 `region=3 / sector=1`로 강제 변경, 이동·조사 상태 클리어 | 기존 모델 수정 없음(필드 값만 정리) |
| `regionStates` | 살아남지 못한 159 region_id 행 삭제 | 보존 40개 행은 그대로 |
| `factionStates` | 각 `FactionState.clueRecords` 리스트에서 살아남지 못한 region 참조 행 삭제 | 모델 수정 없음 |
| `mercenaries` | 변경 없음 | — |
| `quests` | 변경 없음 | 시작 풀 재생성은 `initializeNewGame()` 호출 시점에만 발생 |
| `chainQuestProgress` | 변경 없음 | 보존 region 한정 — 영향 없음 |

#### 신규 enum / 상수

- `GameConstants.startingRegionId = 3`
- `GameConstants.startingSector = 1`
- `GameConstants.startingGold` 값 변경 (500 → 200)
- `GameConstants.baseQuestCount` 값 변경 (5 → 6)
- `GameConstants.sectorCount` `@Deprecated` 마킹
- `SettingsKeys.regionMigrationV1 = 'region_migration_v1'` (신규)
- `SettingsKeys.dataVersions` 등 기존 상수 유지

#### 밸런스 수치 (확정안)

- 시작 골드: 200G
- 시작 무료 모집 쿨다운: 2시간 유지(`freeRecruitCooldown`)
- 유료 모집 비용: 100G 유지(`paidRecruitCost`)
- 시작 의뢰 슬롯: 6개(이전 5개)
- 시작 용병 수: 4명 유지

### 2.3 UI 요구사항

본 명세는 **데이터 마이그레이션 + 도메인 로직 변경**에 한정한다. 신규/변경 UI 화면 없음. 단, 다음 간접 영향 존재:

- 이동 화면(`MovementScreen`): 화면 자체 변경 없음. 단, 마이그레이션 후 이동 가능 region이 159개 줄어들어 region 그리드 표시가 자동으로 40개 한정으로 노출(StaticGameData 기반).
- 파견 화면: 시작 시점 슬롯 5 → 6으로 1개 증가. `QuestSortService` / 배지 / 카드 렌더 로직 변경 없음.
- 정보 탭 / 세력 도감: `factionStates.clueRecords` 정리 후 `discoveredInRegions` getter 결과가 자동 갱신. 화면 코드 변경 없음.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | `startingGold` 500→200, `baseQuestCount` 5→6, `startingRegionId`/`startingSector` 신규 추가, `sectorCount` `@Deprecated` 마킹 | FR-7, FR-9 |
| `band_of_mercenaries/lib/core/data/settings_keys.dart` | `regionMigrationV1` 상수 신규 추가 | FR-6 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | `initializeNewGame()` 메서드 변경 — random region/sector 제거, 시작 풀 6슬롯 분포, baseQuestCount 6 적용 | FR-8, FR-9 |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | `region_migration_v1` 플래그 체크 + RegionMigrationService 호출 | FR-6 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql` | 199→40 region 마이그레이션 SQL (FR-1, FR-2, FR-3, FR-4, FR-5) |
| `band_of_mercenaries/lib/core/data/region_migration_service.dart` | Hive 사용자 데이터 마이그레이션 서비스 (FR-6) — `RegionMigrationService.migrate(staticData)` 정적 메서드 형태. settings 플래그 검사 + regionStates / user / factionStates 정리 |
| `Docs/content-data/postponed_regions_dump.json` | 159개 삭제 region + 종속 region_discoveries 데이터 dump (rollback 가능) |
| `Docs/content-data/region_migration_199_to_40.csv` | 매핑표 CSV (선택 — 페이즈 1 #1 5절 형식). 디버깅·검증용 |

### 3.3 코드 생성 필요 파일

build_runner 재실행 필요 없음. 본 명세에서는 freezed / json_serializable / hive_generator / riverpod_generator 4종 모두 영향받는 모델 변경이 없다(`UserData`, `RegionState`, `FactionState`, `FactionClueRecord` 모두 필드 변경 없음).

| 파일 경로 | 이유 |
|-----------|------|
| (없음) | 데이터 모델 수정 없음 |

### 3.4 관련 시스템

- **이동 시스템**: `MovementScreen` 그리드 표시는 `staticDataProvider.regions` 의존이므로 자동 40개로 축소된다. 이동 거리 계산 로직 변경 없음.
- **퀘스트 생성**: `QuestGenerator.generateQuests` 알고리즘 변경 없음. 단, 시작 시점 호출에서 `count` 인자가 5 → 6으로 변경된다.
- **체인 퀘스트**: `ChainQuestService.tryActivate` 호출은 시작 시점에는 region 3에 해당하는 chain trigger discovery가 존재해야 활성화. 페이즈 4 #3에서 INSERT되는 chain step 1 데이터에 의존.
- **세력 시스템**: `FactionStateRepository` / `FactionJoinService` 코드 변경 없음. 단, `processClue` 호출 시 살아남지 못한 region에서 단서가 발견되는 경우가 마이그레이션 이후 더 이상 발생하지 않음.
- **지역 조사**: `InvestigationNotifier`는 `userData.region`을 입력으로 받으므로, 마이그레이션 이후 strongRegion 3에서 시작하는 정상 흐름.
- **SyncService**: 마이그레이션 SQL이 `data_versions`를 업데이트하므로, 다음 sync 시 `regions` / `region_discoveries` 두 테이블 변경분이 자동 다운로드됨. SyncService 코드 변경 불필요.
- **operation-bom**: 별도 프로젝트(`/Users/radiogaga/git/operation-bom/`). 본 명세는 가이드만 제시.

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Hive 마이그레이션 플래그 패턴**: `band_of_mercenaries/lib/core/data/hive_initializer.dart:44~50`의 `stat_migration_v2` 처리. settings 박스 키 존재 여부로 일회성 마이그레이션 실행 → 완료 후 플래그 저장. `region_migration_v1`도 동일 방식 사용.
- **SyncService 자가치유 패턴**: `band_of_mercenaries/lib/core/data/sync_service.dart:56~90`. 빈 캐시 자동 재다운로드 로직과 별개로, 본 명세는 `data_versions` 업데이트로 정상 증분 sync 트리거.
- **RegionStateRepository 박스 접근**: `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart:6~26`. `Hive.box<RegionState>(HiveInitializer.regionStateBoxName)` 직접 접근 패턴 그대로 사용.
- **Supabase 마이그레이션 SQL 형식**: `band_of_mercenaries/supabase/migrations/20260423_m2b_4_2_elite_tables.sql` 참조. `BEGIN;` ... `COMMIT;` + `INSERT INTO data_versions` 또는 `UPDATE data_versions SET version = version + 1` 패턴.
- **GameConstants Deprecated 마킹**: `@Deprecated('reason')` Dart annotation 사용. 기존 호출자(예: `lib/features/movement/`)는 그대로 동작하되 분석 경고 표시.
- **initializeNewGame 호출 위치**: `band_of_mercenaries/lib/main.dart:119~140`에서 `staticData.when(data: ...)` 분기 내 `initializeNewGame()` 호출. 변경 없음.

### 4.2 주의사항

- **chain_quests `target_sector_id` 변환은 본 명세 범위 외**. 페이즈 1 #2 산출물(섹터 시스템 재설계)에서 sector_count = 4 결정 후 sector_id 5..10 참조 행 처리(null 변환 또는 6섹터 특수 지역 승격) 별도 처리. 본 명세는 chain_quests 보존 region만 사용함을 검증할 뿐, sector 변환은 수행하지 않는다.
- **sectorCount = 10 폐기 정책**: 본 명세는 `@Deprecated` 마킹 + 값 10 유지(stub)만 처리한다. 실제 사용처(예: `currentSectorIndex = startSector - 1` 같은 1..10 인덱스 사용)는 페이즈 4 #2의 `region_sectors.sector_count` 동적 조회 도입까지 그대로 동작한다. 단, 본 명세에서 `startingSector = 1`로 고정하므로 `sectorCount` 의존성이 신규 게임 진입에서는 사라진다.
- **dump JSON 추출 시점**: 마이그레이션 SQL 실행 **전**에 dump JSON을 생성해야 한다. 옵션 A) Supabase MCP로 `SELECT * FROM regions WHERE region NOT IN (보존 40개)` + `SELECT * FROM region_discoveries WHERE region_id NOT IN (보존 40개)`를 실행하여 결과를 JSON으로 저장. 옵션 B) 마이그레이션 SQL 첫 단계에 `INSERT INTO regions_archive SELECT * FROM regions WHERE region NOT IN ...` 같은 백업 테이블 생성 후 SELECT로 추출. **옵션 A를 권장** — `Docs/content-data/postponed_regions_dump.json` 단일 파일이 region-redesign 7절 옵션 B와 정합.
- **트랜잭션 단위**: 마이그레이션 SQL은 단일 트랜잭션(BEGIN/COMMIT)으로 묶는다. 부분 실패 시 모든 DELETE / UPDATE / INSERT가 롤백되어 일관성 유지.
- **Hive 마이그레이션 실행 시점**: `HiveInitializer.initialize()` 내에서 `staticData` 로딩 **이후** `region_migration_v1` 체크 및 실행이어야 한다. 그러나 현재 `HiveInitializer`는 `staticData` 로딩 이전에 호출된다. 따라서 RegionMigrationService는 `main.dart`의 `staticDataProvider.when(data: ...)` 콜백 내에서 호출하거나, SyncService 완료 후 `_load()` 호출 직전 위치에서 실행해야 한다. 구체적 호출 위치 결정은 4.4 구현 힌트 참조.
- **테스트 세이브 정책**: 사용자 task에 명시된 "테스트 세이브는 폐기 권장(사용자 데이터 마이그레이션 부담 회피)"는 **개발자 가이드라인**이다. 실 사용자에 대해서는 FR-6 마이그레이션이 자동으로 강제 이동 처리하므로, 코드 차원의 "세이브 폐기" 강제 로직은 구현하지 않는다.
- **factions 관련**: CLAUDE.md에 명시된 `stronghold_region_id`는 M4 #2 산출물에서 신설 예정이며 본 명세 시점에는 컬럼이 존재하지 않는다(현재 `FactionData` freezed 모델 확인 결과 `tier_range`만 존재). 따라서 사용자 task의 "factions: tier_range JSONB 검증 + base_region_id 변환 (있다면)" 중 "있다면" 분기는 false → 변환 작업 불필요. tier_range 검증 SQL만 추가.
- **freeRecruitCooldown 변경 없음**: 페이즈 2 #3 결정대로 2시간 유지. `lastFreeRecruit = now - 2h`로 초기화하는 기존 로직 그대로(즉시 첫 모집 무료).
- **build_runner 재실행 불필요**: 본 명세는 freezed / json_serializable / hive_generator / riverpod_generator 영향 모델을 수정하지 않는다. `GameConstants` 변경은 const 상수만 영향 → build_runner 미필요.

### 4.3 엣지 케이스

- **마이그레이션 직전 이동 중인 사용자**: `UserData.isMoving = true`, `moveTargetRegion = <삭제 region>` 보유 가능. → FR-6에서 `region` 강제 이동 시 이동 상태도 함께 클리어.
- **마이그레이션 직전 조사 중인 사용자**: `investigationRegionId = <삭제 region>` 보유 가능. → FR-6에서 `investigatingMercId`, `investigationEndTime`, `investigationRegionId` 모두 클리어.
- **체인 퀘스트 진행 중인 사용자**: `chainQuestProgress` 박스 항목은 chain_quests의 region이 모두 보존 40개에 포함되므로 영향 없음(페이즈 1 #1 4절 검증). 단, `currentStepAvailableAt`, `protagonistMercId` 등 메타데이터는 그대로 유지.
- **기존 `quests` 박스 항목이 삭제 region 참조**: `ActiveQuest.regionId` 또는 chain step의 `target_region_id`가 삭제 region일 가능성 → 본 명세는 시작 풀 재생성 시점에만 발생하므로, 마이그레이션 직후 NewGame 진입 사용자에게는 영향 없음. 기존 진행 중 사용자에 대해서는 `UserDataNotifier._load()` 직후 quests 박스 정합성 검증 추가 검토 필요(추후 운영 결정).
- **시작 풀 6슬롯 중 chain step 1 활성화 실패**: 페이즈 4 #3 chain_quests 데이터 미반영 시 chain step 1이 풀에 주입되지 않음. → 일반 풀에서 난이도 1 1건으로 fallback (FR-9 참조).
- **시작 풀 6슬롯 중 region 3 매칭 풀 부족**: 페이즈 4 #3 dustvile_chore 풀 INSERT 미반영 시 region 3 매칭 풀이 0건일 수 있음. → 기존 알고리즘대로 `min_region_diff <= regionTier <= max_region_diff` 매칭 풀에서 채움(난이도 1 1건 + 난이도 2 1건이 없을 경우 5개 미만으로 시작).
- **마이그레이션 SQL 실행 중 클라이언트 동시 sync 시도**: data_versions 업데이트 전에 클라이언트가 sync 시도하면 일부만 다운로드될 위험. → 본 명세는 운영 환경에서 마이그레이션 SQL을 단일 시점에 실행하므로 무시 가능. 단, 마이그레이션 SQL 마지막에 `data_versions` UPDATE를 두어 모든 변경 후 버전 갱신.
- **dump JSON 파일 누락**: `Docs/content-data/postponed_regions_dump.json` 파일이 없거나 손상된 상태로 마이그레이션 SQL이 실행되면 rollback 불가. → 마이그레이션 실행 전 dump 파일 존재·유효성 수동 확인 필수(개발자 책임).

### 4.4 구현 힌트

- **진입점**:
  - GameConstants 수정 → `band_of_mercenaries/lib/core/constants/game_constants.dart`
  - initializeNewGame 수정 → `band_of_mercenaries/lib/core/providers/game_state_provider.dart:60~128`
  - Hive 마이그레이션 호출 → `band_of_mercenaries/lib/main.dart` 내 SyncService 완료 후 / `userDataProvider._load()` 호출 직전 위치. 또는 `HiveInitializer.initialize()` 끝부분(staticData 로딩 후 별도 호출 흐름).
  - SQL 마이그레이션 → `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql` 신규 작성. `mcp__plugin_supabase_supabase__apply_migration` 도구로 적용 가능(또는 Supabase Studio SQL Editor).
- **데이터 흐름**:
  - 신규 게임: `main.dart` → `staticDataProvider.when(data: ...)` → `initializeNewGame()` → UserData 생성 (region=3, sector=1) → QuestGenerator.generateQuests(count=6) → questBox.add() ×6
  - 마이그레이션: 앱 시작 → `HiveInitializer.initialize()` (settings 박스 오픈) → `SyncService.sync()` (data_versions 비교 후 regions / region_discoveries 다운로드) → `RegionMigrationService.migrate(staticData)` (region_migration_v1 false → true 전환 + Hive 정리) → `userDataProvider._load()` (이미 정리된 상태로 진입)
  - SyncService 완료 후 staticData에 보존 40개 region이 로드된 시점에 RegionMigrationService를 호출해야 정합성 유지(살아남는 region_id 셋을 staticData.regions에서 추출).
- **참조 구현**:
  - `band_of_mercenaries/lib/core/data/hive_initializer.dart:44~50` — stat_migration_v2 패턴 (일회성 마이그레이션 플래그)
  - `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart:6~26` — Hive 박스 접근 + 살아남는 키 필터링 참조
  - `band_of_mercenaries/supabase/migrations/20260423_m2b_4_2_elite_tables.sql` — 마이그레이션 SQL 형식 (BEGIN/COMMIT + data_versions UPDATE)
  - `band_of_mercenaries/supabase/migrations/20260423_m2b_4_1_region_environment_tags.sql` — regions 테이블 컬럼 변경 + 일괄 UPDATE 패턴
  - `band_of_mercenaries/lib/features/info/data/faction_state_repository.dart` — clueRecords 리스트 조작 패턴
- **확장 지점**:
  - RegionMigrationService는 정적 메서드(`migrate(staticData)`) 형태로 작성하여 향후 region_migration_v2(예: M9 시점 T9~T10 컨텐츠 확장)에서도 동일 패턴 재사용 가능.
  - GameConstants의 `startingRegionId` / `startingSector`는 향후 시작 거점 변경 시 단일 상수 수정으로 처리 가능.
  - dump JSON은 향후 M7 "지역 생활권 확장" / M8 "세력 재도입"에서 재배치 후보로 활용.

#### 마이그레이션 SQL 골격 (구현 참고)

```sql
-- 20260503_m4_phase4_1_region_migration.sql
BEGIN;

-- (선행) 159개 region + 종속 region_discoveries dump는 마이그레이션 실행 전 외부 도구로 추출.
-- Docs/content-data/postponed_regions_dump.json 생성 완료 가정.

-- 1. region_discoveries 정리 (살아남지 못한 region 참조 행 삭제)
DELETE FROM region_discoveries
WHERE region_id NOT IN (
  3, 31, 127,
  9, 10, 20, 23, 146,
  5, 38, 49, 50, 51, 52, 65,
  13, 16, 21, 24, 28, 35,
  1, 25, 67, 90, 105,
  17, 36, 62, 84,
  44, 56, 115, 154,
  4, 18, 47,
  7, 11
);
-- 200은 신규이므로 region_discoveries 행 없음(이후 M9에서 추가 가능).

-- 2. 159개 region 삭제
DELETE FROM regions
WHERE region NOT IN (
  3, 31, 127,
  9, 10, 20, 23, 146,
  5, 38, 49, 50, 51, 52, 65,
  13, 16, 21, 24, 28, 35,
  1, 25, 67, 90, 105,
  17, 36, 62, 84,
  44, 56, 115, 154,
  4, 18, 47,
  7, 11,
  200  -- T9 신규는 INSERT 후 보존 대상이지만, 현재 시점에는 행이 없으므로 NOT IN에 포함해도 무영향
);

-- 3. 더스트플레인 region 3 재태깅
UPDATE regions
SET region_name = '더스트플레인',
    environment_tags = '["mountain"]'::jsonb,
    description = '광산을 품은 변방 산악 지역. 신참 용병들이 첫 발을 떼는 곳.'
WHERE region = 3;

-- 4. T9 region 200 신규 INSERT
INSERT INTO regions (continent, region, region_tier, region_name, recommend_power, environment_tags, description)
VALUES (1, 200, 9, '망각의 수면', 380,
        '["underground"]'::jsonb,
        'T8 마계경계와 T10 심연 사이의 깊이. 시간이 멈춘 듯한 수면이 펼쳐져 있다. (M9 종속 시스템 확장 예정)');

-- 5. factions tier_range 검증 (실패 시 트랜잭션 롤백)
DO $$
DECLARE
  invalid_count INT;
BEGIN
  SELECT COUNT(*) INTO invalid_count
  FROM factions
  WHERE EXISTS (
    SELECT 1 FROM jsonb_array_elements(tier_range) elem
    WHERE (elem::int) > 10 OR (elem::int) < 1
  );
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'factions.tier_range 검증 실패: % 행이 1..10 범위를 벗어남', invalid_count;
  END IF;
END $$;

-- 6. data_versions 갱신
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'regions';
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'region_discoveries';

COMMIT;
```

#### RegionMigrationService 골격 (구현 참고)

```dart
// band_of_mercenaries/lib/core/data/region_migration_service.dart
import 'package:hive/hive.dart';
import '../models/user_data.dart';
import '../models/static_game_data.dart';
import '../constants/game_constants.dart';
import 'hive_initializer.dart';
import 'settings_keys.dart';
import '../../features/investigation/domain/region_state_model.dart';
import '../../features/info/domain/faction_state_model.dart';

class RegionMigrationService {
  static const String _flagKey = SettingsKeys.regionMigrationV1;

  /// 살아남는 40개 region_id 셋을 staticData.regions에서 추출하여
  /// regionStates / user / factionStates 박스를 정리.
  /// settings.region_migration_v1 == true 이면 즉시 반환(no-op).
  static Future<void> migrate(StaticGameData staticData) async {
    final settings = Hive.box(HiveInitializer.settingsBoxName);
    if (settings.get(_flagKey) == true) return;

    final survivingIds = staticData.regions.map((r) => r.region).toSet();

    // 1. regionStates 박스 정리
    final regionBox = Hive.box<RegionState>(HiveInitializer.regionStateBoxName);
    final keysToDelete = <dynamic>[];
    for (final key in regionBox.keys) {
      final state = regionBox.get(key);
      if (state != null && !survivingIds.contains(state.regionId)) {
        keysToDelete.add(key);
      }
    }
    await regionBox.deleteAll(keysToDelete);

    // 2. user 박스 정리
    final userBox = Hive.box<UserData>(HiveInitializer.userBoxName);
    if (userBox.isNotEmpty) {
      final userData = userBox.getAt(0);
      if (userData != null && !survivingIds.contains(userData.region)) {
        userData.region = GameConstants.startingRegionId;
        userData.sector = GameConstants.startingSector;
        userData.isMoving = false;
        userData.moveTargetRegion = null;
        userData.moveTargetSector = null;
        userData.moveStartTime = null;
        userData.moveEndTime = null;
        userData.investigatingMercId = null;
        userData.investigationEndTime = null;
        userData.investigationRegionId = null;
        await userData.save();
      }
    }

    // 3. factionStates 박스 정리
    final factionBox = Hive.box<FactionState>(HiveInitializer.factionStateBoxName);
    for (final key in factionBox.keys) {
      final state = factionBox.get(key);
      if (state == null) continue;
      final originalLength = state.clueRecords.length;
      state.clueRecords.removeWhere((r) => !survivingIds.contains(r.regionId));
      if (state.clueRecords.length != originalLength) {
        await state.save();
      }
    }

    // 4. 플래그 저장
    await settings.put(_flagKey, true);
  }
}
```

#### initializeNewGame() 변경 골격 (구현 참고)

```dart
Future<void> initializeNewGame() async {
  final staticData = ref.read(staticDataProvider).value;
  if (staticData == null) return;

  final random = Random();
  // 시작 거점 고정: region 3 (더스트플레인) / sector 1
  final startRegion = staticData.regions.firstWhere(
    (r) => r.region == GameConstants.startingRegionId,
    orElse: () => throw StateError('region ${GameConstants.startingRegionId} 누락 — 마이그레이션 미적용'),
  );
  final startSector = GameConstants.startingSector;

  final userData = UserData(
    gold: GameConstants.startingGold,
    region: startRegion.region,
    sector: startSector,
    lastFreeRecruit: DateTime.now().subtract(GameConstants.freeRecruitCooldown),
    createdAt: DateTime.now(),
  );

  final box = Hive.box<UserData>(HiveInitializer.userBoxName);
  await box.clear();
  await box.add(userData);

  // 시작 용병 4명 — 변경 없음
  final mercBox = Hive.box<Mercenary>(HiveInitializer.mercenaryBoxName);
  await mercBox.clear();
  final startingMercs = RecruitmentService.generateStartingMercenaries(
    jobs: staticData.jobs,
    traits: staticData.traits,
    categories: staticData.traitCategories,
    names: staticData.personNames,
    count: 4,
    random: random,
  );
  for (final merc in startingMercs) {
    await mercBox.add(merc);
  }

  // 시작 의뢰 풀 6개 — baseQuestCount 적용
  final questBox = Hive.box<ActiveQuest>(HiveInitializer.questBoxName);
  await questBox.clear();
  final initialQuests = QuestGenerator.generateQuests(
    regionTier: startRegion.regionTier,
    regionId: startRegion.region,
    questPools: staticData.questPools,
    questTypes: staticData.questTypes,
    count: GameConstants.baseQuestCount,  // 6
    random: random,
    joinedFactionIds: const [],
    factionReputations: const {},
    clueLevelsInRegion: const {},
    cooldownExclusiveQuestIds: const {},
    activeSlotCount: GameConstants.baseQuestCount,
    eliteMonsters: staticData.eliteMonsters,
    regionEnvironmentTags: startRegion.environmentTags,
    currentSectorIndex: startSector - 1,
  );
  for (final quest in initialQuests) {
    await questBox.add(quest);
  }

  // 활성 체인 step 1 주입 시도 (region 3에 chain 활성 조건 충족 시)
  // 페이즈 4 #3 chain_quests 데이터 의존 — 해당 데이터 미반영 시 no-op
  // ChainQuestService.tryActivate / injectChainStep 호출은 staticData / userData 준비 후 수행
  // 본 명세는 시작 풀 분포 정책만 정의하므로, 구체적 ID 매핑은 페이즈 4 #3 산출물 참조

  state = userData;
}
```

---

## 5. 기획 확인 사항

- [Q-1] **dump JSON 추출 시점·도구**: 마이그레이션 SQL 실행 전 단일 JSON(`Docs/content-data/postponed_regions_dump.json`)을 어떤 도구로 추출하는가? → 권장: Supabase MCP (`mcp__plugin_supabase_supabase__execute_sql`)로 SELECT 후 결과를 JSON으로 저장. 또는 운영 도구(operation-bom)에 dump 추출 기능 추가. **확인 결과**: 본 명세에서는 "구현 시점에 개발자가 수동 추출(Supabase MCP / Studio SQL Editor)"를 기본으로 가정. 자동화는 별도 후속 작업.
- [Q-2] **마이그레이션 SQL 실행 시점**: SQL은 (a) Supabase MCP로 즉시 적용 vs (b) 명세서 구현 PR과 함께 마이그레이션 SQL 파일로 커밋 후 별도 적용. **확인 결과**: (b) 권장 — 마이그레이션 SQL을 PR로 검토 후 운영자가 단일 시점에 적용. dump JSON은 PR 생성 전 추출.
- [Q-3] **GameConstants.sectorCount @Deprecated 마킹 시 분석 경고**: 기존 호출자(예: `currentSectorIndex = startSector - 1` 등)에서 분석 경고가 발생하면 PR이 통과하기 어려울 수 있음. → 권장: `// ignore: deprecated_member_use` 주석으로 우선 호출자 침묵 처리, 페이즈 4 #2에서 동적 조회 도입 시 호출자 일괄 변경. **확인 결과**: 호출자 침묵 처리 + 페이즈 4 #2에서 일괄 마이그레이션. 본 명세는 GameConstants 측만 변경.
- [Q-4] **시작 풀 6슬롯 중 chain step 1 / dustvile_chore 풀 ID 매핑**: 페이즈 4 #3 산출물 의존이므로 본 명세 시점에 ID가 미정. → 본 명세는 6슬롯 분포 정책(난이도 1 ×5 + 난이도 2 ×1)만 정의하고, 구체적 풀 ID는 페이즈 4 #3에서 INSERT되는 데이터에 의존. 페이즈 4 #3 미적용 상태에서 본 명세 코드만 적용 시 `QuestGenerator`가 기존 알고리즘으로 5건 + 1건을 채움. **확인 결과**: 정책만 정의 + ID 매핑은 페이즈 4 #3 의존.
- [Q-5] **테스트 세이브 폐기 강제 여부**: 사용자 task에 "테스트 세이브는 폐기 권장" 명시. 그러나 실 사용자에 대해 강제 폐기는 데이터 손실 위험. → 본 명세는 FR-6 마이그레이션으로 자동 정리(살아남지 못한 region 참조 시 region=3으로 강제 이동) 처리하며, 강제 NewGame 진입은 구현하지 않는다. 개발 환경에서는 개발자가 수동으로 `flutter clean` + 앱 재설치로 처리. **확인 결과**: 자동 정리만 수행, 강제 폐기 없음.
- [Q-6] **factions tier_range 검증 실패 시 처리**: 마이그레이션 SQL 5단계의 검증 SQL이 실패하면 트랜잭션 롤백되어 마이그레이션 전체 실패. → 운영자는 factions 테이블의 tier_range 값을 사전 검증(operation-bom 도구) 후 마이그레이션 실행 권장. **확인 결과**: 검증 실패 시 명확한 에러 메시지 출력 후 롤백, 운영자가 수동 수정 후 재실행.
- [Q-7] **regions_archive 백업 테이블 도입 여부**: 사용자 task에 "삭제 159개 region은 단일 dump JSON 보관(rollback 가능)" 명시. → 본 명세는 dump JSON 단일 파일 채택(region-redesign 7절 옵션 B 정합). DB 테이블 백업(옵션 C)은 도입하지 않는다. **확인 결과**: dump JSON만 사용, 백업 테이블 미도입.
- [Q-8] **마이그레이션 적용 환경 분리**: 개발 / 스테이징 / 프로덕션 Supabase 환경 분리 운영 시 어느 환경부터 적용? → 본 명세는 환경 분리 정책 외부. 운영자가 결정. **확인 결과**: 환경 분리 운영은 본 명세 범위 외.
