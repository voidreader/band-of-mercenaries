# M4 페이즈 4 #1 — 데이터 마이그레이션 + 시작 거점 고정 구현 계획·산출물

> Skill used : implement-agent
> 명세서: `Docs/spec/M4/[spec]20260503_m4-region-migration.md`
> 작성일: 2026-05-03

---

## 1. 수립한 구현 계획

### 요구사항 분해 (10개 REQ)

명세서 FR-1~FR-10을 코드 작업 단위로 재정렬:

- REQ-1: GameConstants 상수 변경
- REQ-2: SettingsKeys.regionMigrationV1 추가
- REQ-3: RegionMigrationService 신설
- REQ-4: main.dart 마이그레이션 호출 통합
- REQ-5: initializeNewGame 시작 거점 고정
- REQ-6: 시작 의뢰 풀 6슬롯 분포 (정책만, 데이터 의존)
- REQ-7: Supabase 마이그레이션 SQL
- REQ-8: dump JSON 산출물
- REQ-9: 매핑 CSV 산출물
- REQ-10: sectorCount 호출자 deprecated 침묵 처리

### 설계 방향

- **3축 분리**: ① Flutter 코드 ② Supabase SQL ③ 외부 dump JSON. 운영 적용 시점에만 정렬.
- **멱등성 우선**: Hive 마이그레이션은 `region_migration_v1` 플래그로 멱등성 보장, SQL은 단일 BEGIN/COMMIT 트랜잭션.
- **fallback 친화**: 시작 의뢰 6슬롯의 chain step 1 / dustvile_chore ID는 페이즈 4 #3 의존이므로, 데이터 미반영 시 `QuestGenerator` 기존 알고리즘이 5+1건 채우도록 fallback.
- **호출 시점**: `main.dart`의 `_PostSyncApp`을 `ConsumerStatefulWidget`으로 변경 → `staticData.when(data: ...)` 콜백에서 `_ensureMigrationStarted(data)`로 마이그레이션 Future 1회 시작 → `FutureBuilder`로 완료 대기 → 완료 후에만 `userDataProvider` watch.

### 사용자 합의 사항

- **Q-1**: UserData 모델에 `moveStartTime` 필드가 존재하지 않음 → 명세서 골격의 해당 라인 제외. 실제 4개 필드(`isMoving`/`moveTargetRegion`/`moveTargetSector`/`moveEndTime`)만 클리어.

### 태스크 구조 (9개 TASK / 3단계)

```
[1단계 병렬 5개]
  TASK-1: GameConstants 상수 변경
  TASK-2: SettingsKeys.regionMigrationV1 추가
  TASK-7: Supabase 마이그레이션 SQL 작성
  TASK-8: dump JSON 추출 (Supabase MCP + main 직접 처리)
  TASK-9: 매핑 CSV (선택)

[2단계 병렬 3개 — TASK-1/2 완료 후]
  TASK-3: RegionMigrationService 신설          (TASK-1+2 의존)
  TASK-5: initializeNewGame 시작 거점 고정      (TASK-1 의존)
  TASK-6: sectorCount 호출자 침묵 처리          (TASK-1 의존)

[3단계 단일 — TASK-3 완료 후]
  TASK-4: main.dart 마이그레이션 호출 통합
```

---

## 2. 실제 개발 사항

### 변경 파일 목록

#### 수정 (4 파일)

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | 상수 변경·추가 | `startingGold` 500→200, `baseQuestCount` 5→6, `sectorCount` `@Deprecated` 마킹, `startingRegionId=3`/`startingSector=1` 신규 |
| `band_of_mercenaries/lib/core/data/settings_keys.dart` | 1줄 추가 | `regionMigrationV1 = 'region_migration_v1'` |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | 메서드 변경 | `initializeNewGame()` random region/sector 부여 제거 → `region 3 / sector 1` 고정 + 6슬롯 분포 정책 주석 |
| `band_of_mercenaries/lib/main.dart` | 위젯 구조 변경 | `_PostSyncApp`을 `ConsumerStatefulWidget`으로 변경, `_ensureMigrationStarted` / `_buildMigrationErrorScreen` / `_buildStaticDataErrorScreen` 메서드 추가, `_newGameInitiated` 가드 + `mounted` 체크 |

#### 신규 (4 파일)

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/data/region_migration_service.dart` | 신규 작성 | `RegionMigrationService.migrate(StaticGameData)` 정적 메서드 — 멱등성 플래그 + regionStates / user / factionStates 박스 정리 |
| `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql` | 신규 작성 | 단일 트랜잭션: region_discoveries DELETE → regions DELETE → region 3 UPDATE → region 200 INSERT → factions tier_range 검증 → data_versions UPDATE |
| `Docs/content-data/postponed_regions_dump.json` | 신규 작성 | 삭제 region 160개 + 종속 region_discoveries 15개 보관 (rollback 가능) |
| `Docs/content-data/region_migration_199_to_40.csv` | 신규 작성 | 200 라인 매핑표 (보존 39 + 신규 1 + 삭제 160) |

### 명세서 산수 정정

명세서가 표기한 "삭제 159개"는 산수 오기. 실제 데이터 검증 결과 **160개 삭제**가 정확:
- 기존 199 region 중 보존 = 39개 (T1=3 + T2=5 + T3=7 + T4=6 + T5=5 + T6=4 + T7=4 + T8=3 + T10=2)
- 기존 199 region 중 삭제 = 199 - 39 = **160개**
- T9 region 200 신규 INSERT = 1개
- 종합 "살아남는 40개" = 기존 39 + 신규 1

dump JSON의 메타 필드 `deleted_region_count`는 160으로 수정 적용.

### 페이즈 4 #3 의존 사항 (현 명세 범위 외)

본 명세는 다음 데이터에 의존하나 페이즈 4 #3 산출물에서 INSERT 예정 — 현 시점 미반영 환경에서는 fallback 동작:

- chain step 1 (settlement 더스트빌 폐광 사건) — 미존재 시 `QuestGenerator`가 일반 풀 난이도 1로 5건 채움
- dustvile_chore_NN 풀 10건 — 미존재 시 region 3 매칭 풀 부족 가능, 기존 알고리즘 fallback

---

## 3. 검증 모드 및 결과 요약

### 검증 모드: 풀 검증 (TASK 9개 ≥ 3)

verifier(명세 충족) + flutter-reviewer(품질) 병렬 호출. 통합 판정 규칙:
- verifier FAIL → FAIL
- verifier PASS + flutter-reviewer BLOCK → FAIL
- 둘 다 PASS → PASS

### 검증 차수별 결과

| 차수 | verifier | flutter-reviewer | 통합 판정 | 처리 |
|------|----------|-----------------|----------|------|
| 1차 | PASS (499/499 테스트 통과) | BLOCK (이슈 5건) | FAIL | TASK-3/4 재작업 |
| 2차 | (시그니처 변동 없음, 생략) | BLOCK (NEW-1 1건) | FAIL | TASK-4 추가 수정 |
| 3차 | (생략) | APPROVE | PASS | 종료 |

### 1차 flutter-reviewer 발견 이슈 (5건 / 모두 해소)

| ISSUE | 심각도 | 파일 | 1차 지적 | 해소 방식 |
|-------|--------|------|--------|----------|
| ISSUE-1 | blocker | main.dart | `addPostFrameCallback` 중복 등록 | `_newGameInitiated` 가드 필드 추가, 1회만 등록 |
| ISSUE-2 | major | main.dart | `build()` 내 `_migrationFuture` 직접 변이 | `_ensureMigrationStarted(StaticGameData)` 메서드로 캡슐화 |
| ISSUE-3 | major | main.dart | `addPostFrameCallback` 콜백에 `mounted` 미체크 | 콜백 첫 줄에 `if (!mounted) return;` 추가 |
| ISSUE-4 | major | main.dart | 마이그레이션 실패 시 raw exception UI 노출 | `_buildMigrationErrorScreen()` 메서드로 사용자 친화 메시지 + `debugPrint`로 진단 정보 |
| ISSUE-5 | minor | region_migration_service.dart | 상대 경로 import 컨벤션 위반 | `package:band_of_mercenaries/...` 절대 경로로 전환 |

### 2차 flutter-reviewer 발견 이슈 (1건 / 해소)

| ISSUE | 심각도 | 파일 | 지적 | 해소 방식 |
|-------|--------|------|------|----------|
| NEW-1 | HIGH | main.dart | `staticData.when(error: ...)` 브랜치 raw exception 노출 잔존 | `_buildStaticDataErrorScreen(Object, StackTrace?)` 신규 메서드 + `debugPrint` 진단 |

### 3차 flutter-reviewer: APPROVE

모든 이슈 해소 확인. 신규 회귀 없음.

---

## 4. build_runner 재실행 필요 파일

**없음.** 본 명세는 freezed / json_serializable / hive_generator / riverpod_generator 4종 모두 영향받는 모델 변경이 없다 (`UserData`, `RegionState`, `FactionState`, `FactionClueRecord` 모두 필드 변동 없음).

---

## 5. CLAUDE.md 금지사항 위반 여부

**위반 없음.**

확인 항목:
- 코멘트 정책: 자명한 코드에 주석 미추가. 가드 필드(`_newGameInitiated`)와 `??=` 캡슐화 메서드에만 1줄 의도 주석 허용 범위.
- 의존성 줄임: RegionMigrationService는 Ref 의존 없는 순수 정적 서비스. main.dart 에러 스크린은 별도 위젯/Provider 만들지 않고 State 메서드로 캡슐화.
- 기존 패턴 준수: `stat_migration_v2` 일회성 플래그 패턴(`hive_initializer.dart:44~50`)을 RegionMigrationService에 적용. SQL은 `BEGIN/COMMIT` + `data_versions` UPDATE 기존 마이그레이션 형식 유지.

---

## 6. 운영 적용 절차 (코딩 단계 외)

본 명세는 코드 + SQL 마이그레이션 산출물을 PR로 검토받고, 운영자가 단일 시점에 적용한다:

1. **PR 머지 전**: `Docs/content-data/postponed_regions_dump.json` 추출 완료 확인 (rollback 가능 보관)
2. **운영자**: `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql`을 Supabase Studio SQL Editor 또는 Supabase MCP `apply_migration`으로 적용
3. **클라이언트 자동**: 다음 sync 시 `regions` / `region_discoveries` 두 테이블 변경분 자동 다운로드 (data_versions +1 증분)
4. **클라이언트 자동**: 첫 실행 시 `RegionMigrationService.migrate()`가 Hive 박스 정리 + 플래그 저장 (멱등성 — 이후 실행 스킵)

### operation-bom 후속 작업 (별도 프로젝트)

- region 편집 폼이 정확히 40개만 표시되는지 검증
- 삭제된 159(=160)개 region 편집 시도 시 404 또는 "삭제된 region" 표시
- dump JSON 백업 절차 README 추가
- region_id 3 / 200 항목의 신규 필드 값 정상 노출 확인

---

## 7. 명세서 → 구현 트레이스

| 명세 FR | 구현 위치 | 검증 |
|---------|----------|------|
| FR-1 (199→40 SQL) | `supabase/migrations/20260503_m4_phase4_1_region_migration.sql` §1~§4 | verifier PASS + 보존 40개 ID 셋 일치 검증 |
| FR-2 (region 3 재태깅) | 동 SQL §3 | verifier PASS |
| FR-3 (region 200 INSERT) | 동 SQL §4 | verifier PASS |
| FR-4 (종속 데이터 변환) | 동 SQL §1 + §5 (factions tier_range 검증) | verifier PASS |
| FR-5 (data_versions) | 동 SQL §6 | verifier PASS |
| FR-6 (Hive 마이그레이션) | `region_migration_service.dart` 17~81라인 | verifier PASS + flutter-reviewer APPROVE |
| FR-7 (GameConstants) | `game_constants.dart` 2~7라인 | verifier PASS |
| FR-8 (initializeNewGame 고정) | `game_state_provider.dart` 60~84라인 | verifier PASS |
| FR-9 (6슬롯 분포) | 동 파일 107~133라인 | verifier PASS |
| FR-10 (operation-bom 가이드) | 본 문서 §6 | 외부 프로젝트 — 가이드만 제공 |

---

## 8. 산출물 경로 정리

### 코드 산출물

- `band_of_mercenaries/lib/core/constants/game_constants.dart` (수정)
- `band_of_mercenaries/lib/core/data/settings_keys.dart` (수정)
- `band_of_mercenaries/lib/core/data/region_migration_service.dart` (신규)
- `band_of_mercenaries/lib/core/providers/game_state_provider.dart` (수정)
- `band_of_mercenaries/lib/main.dart` (수정)
- `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql` (신규)

### 문서 산출물

- `Docs/spec/M4/[spec]20260503_m4-region-migration.md` (명세, 기존)
- `Docs/spec/M4/[spec]20260503_m4-region-migration_plan.md` (본 문서)
- `Docs/content-data/postponed_regions_dump.json` (신규, 159(=160)개 region rollback 보관)
- `Docs/content-data/region_migration_199_to_40.csv` (신규, 매핑표)

---

## 9. 후속 작업 (페이즈 4 다른 산출물 의존)

본 명세는 페이즈 4 #1 단독으로 PR 가능하나, 다음 페이즈 산출물이 완료되어야 신규 게임 진입 흐름이 완전히 의도대로 동작한다:

- **페이즈 4 #2** (region_sectors 신규 테이블): `GameConstants.sectorCount` 동적 조회 도입. 본 명세의 `@Deprecated` 호출자 일괄 마이그레이션
- **페이즈 4 #3** (quest_pools 컬럼 확장 + 고정 의뢰 노출): 더스트빌 허드렛일 10건 INSERT + 고정 사건 chain step 1 활성화. 시작 풀 6슬롯이 의도대로 채워짐
- **페이즈 4 #4** (마을 방문 UI + 거점 3종 + 약초상/의무실 분리): 더스트빌 마을 진입 UI
- **페이즈 4 #5** (마을 신뢰도 시스템 + 고정 사건 진행 상태): regionStates 확장 + chain_quests 재사용
