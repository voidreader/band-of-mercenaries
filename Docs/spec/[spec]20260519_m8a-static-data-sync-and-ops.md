# M8a 정적 데이터 스키마·동기화·operation-bom 편집 지원 개발 명세서

> 기획 문서:
> - `Docs/milestone-runs/M8a/state.md` (M8a 마일스톤 상태)
> - `Docs/spec/[spec]20260518_m8a-faction-system.md` (M8a #1 세력 시스템 명세)
> - `Docs/spec/[spec]20260518_m8a-combat-report-system.md` (M8a #2 전투 보고서 시스템 명세)
> - 페이즈 3 산출물 5종 CSV (`Docs/content-data/`)
>
> 작성일: 2026-05-19
> 마일스톤: M8a 페이즈 4 #3

## 1. 개요

M8a는 5개의 신규 정적 데이터 테이블(`faction_contacts`·`faction_reactions`·`faction_shop_items`·`combat_report_templates`·`combat_report_keywords`)을 도입했다. 본 명세는 (a) 이 5개 테이블의 스키마 정합성 점검, (b) `SyncService.optionalTables` 운영 정책 확정, (c) `data_versions` 버전 발행 규약, (d) `operation-bom` 운영 웹앱에서의 편집 지원 가이드, (e) 캐시 무효화·재동기화 시나리오를 통합한다.

코드 측 변경은 이미 M8a #1·#2 구현에서 적용 완료된 상태이며, 본 명세의 핵심은 **운영 정책의 문서화**와 **후속 마일스톤(M8b·M8.5·M9)에서 신규 테이블 추가 시 동일 정책을 따르도록 하는 규약 확립**이다. 일부 항목(operation-bom `table-config.ts` 등록)은 별도 프로젝트(`/Users/radiogaga/git/operation-bom`) 작업으로 분리한다.

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] M8a 신규 5 테이블 SyncService 등록 정합성 검증**
  - `band_of_mercenaries/lib/core/data/sync_service.dart`의 `allTables` 리스트(36~37번 인덱스)와 `optionalTables` Set 양쪽에 다음 5개가 모두 등록되어 있어야 한다.
    - `faction_contacts` (M8a #1, 인덱스 33)
    - `faction_reactions` (M8a #1, 인덱스 34)
    - `faction_shop_items` (M8a #1, 인덱스 35)
    - `combat_report_templates` (M8a #2, 인덱스 36)
    - `combat_report_keywords` (M8a #2, 인덱스 37)
  - 본 명세 작성 시점 기준 모두 등록 완료 상태이다.

- **[FR-2] optionalTables 운영 정책 확정**
  - 새 정적 데이터 테이블이 도입될 때, 다음 조건 중 **하나라도** 해당하면 `optionalTables` Set에 등록한다.
    - 후속 마일스톤에서 Supabase 스키마가 모든 환경에 적용되기 전에 클라이언트가 먼저 배포될 가능성이 있다.
    - 빈 테이블 상태에서도 핵심 게임 루프(이동/파견/모집/시설/제작/조사)가 동작 가능하다.
    - 데이터 부재 시 해당 기능이 fail-soft(미생성/skip/empty list)로 동작한다.
  - 위 조건에 부합하지 않는 테이블(예: `regions`, `jobs`, `quest_pools`)은 `requiredTables`(자동 산출)에 남는다.
  - `requiredTables`는 `validateRequiredCaches` 단계에서 캐시 부재 시 `StateError`를 throw하여 앱 기동을 막는다. `optionalTables`는 캐시 부재 시 빈 리스트(`[]`)로 fallback 한다.

- **[FR-3] data_versions 버전 발행 규약**
  - 새 테이블 시드 시 SQL: `INSERT INTO data_versions (table_name, version, updated_at) VALUES ('{table}', 1, NOW())`.
  - 기존 테이블 데이터 갱신 시 `version = version + 1`로 발행. 자동 트리거는 사용하지 않는다(`operation-bom` "버전 발행" 버튼 또는 수동 SQL).
  - 본 명세 시점에 `combat_report_templates`/`combat_report_keywords`는 version=1으로 시드 완료. `faction_contacts`/`faction_reactions`/`faction_shop_items`도 M8a #1 구현 시점에 version=1로 시드되어 있어야 한다(검증 필요 — [Q-1]).
  - `data_versions` 행이 누락된 테이블은 클라이언트의 `_fetchServerVersions`에서 누락되어 변경 감지 대상에서 빠진다. 결과적으로 캐시 무한 stale.

- **[FR-4] 클라이언트 캐시 fail-soft 정책 명문화**
  - `DataLoader.loadFromCache(tableName, fromJson)`는 캐시가 없으면 빈 리스트(`[]`)를 반환한다(코드상 이미 그렇게 동작).
  - optional table을 사용하는 모든 정적 데이터 소비자(`CombatReportService`·`FactionContactService` 등)는 빈 리스트 입력 시 null/skip을 반환하는 fail-soft 분기를 가져야 한다.
  - 본 명세 시점에 `CombatReportService.generate()`는 templates 빈 리스트 → null 반환으로 검증됨.

- **[FR-5] 자가치유(self-heal) 로직 보존**
  - `SyncService.sync()`는 캐시가 비어 있는 테이블(`isCacheEmpty`)을 매 sync 시 재다운로드 대상에 포함한다. 본 명세 시점 코드 보존(수정 없음).
  - 이 로직 덕분에 과거 빈 응답(`[]`)으로 캐시된 테이블도 다음 sync 시 자동 복구된다.

- **[FR-6] operation-bom table-config 등록 (별도 프로젝트 작업, 본 PR 범위 외)**
  - `/Users/radiogaga/git/operation-bom/src/lib/table-config.ts`에 M8a 신규 5 테이블을 추가하면 자동으로 CRUD UI가 생성된다.
  - 등록 필요 항목:

    | 테이블 | category 후보 | 핵심 필드 | tags_json 처리 |
    |--------|--------------|-----------|----------------|
    | `faction_contacts` | `quest` 또는 신규 `faction` | id/faction_id/npc_id/npc_name/region_id/sector_id/dialogue 등 | 해당 시 type: `json` |
    | `faction_reactions` | `quest` | id/faction_id/trigger_kind/text 등 | type: `json` |
    | `faction_shop_items` | `balance` | id/faction_id/item_id/price/stock_limit 등 | type: `json` |
    | `combat_report_templates` | `quest` | id/group/scope/faction_id/quest_type/result_type/line_type/importance/weight/template/tags_json | tags_json: type: `json` |
    | `combat_report_keywords` | `quest` | id/category/key/display_text/tags_json/weight | tags_json: type: `json` |

  - 등록 작업은 별도 PR로 진행한다(본 명세는 가이드 제공). `FieldType`은 `text` / `number` / `real` / `textarea` / `int_array` / `real_array` / `json` 중 적합한 것을 선택.
  - 현 시점 `operation-bom/src/lib/table-config.ts`는 17개 테이블만 등록되어 있어, M2a~M8a 신규 테이블 다수가 미등록 상태이다. 후속 작업 백로그로 분리한다([Q-2]).

- **[FR-7] 캐시 무효화·재동기화 시나리오 명세**
  - **시나리오 A — 앱 신규 설치 / 캐시 박스 비어 있음**: `SyncService.sync()` 진입 시 `hasCache == false` → `_fullDownload()` 호출 → `requiredTables` 다운로드 후 `optionalTables` 다운로드(개별 try/catch). 실패 시 캐시 clear + rethrow.
  - **시나리오 B — 정상 재실행 (캐시 존재)**: `_fetchServerVersions` 호출 → `_findChangedTables` 비교 → 변경된 테이블만 다운로드. 빈 캐시도 자동 추가.
  - **시나리오 C — 포그라운드 복귀**: `app.dart`의 `WidgetsBindingObserver.didChangeAppLifecycleState`에서 `AppLifecycleState.resumed`일 때 `sync()` 호출. `SyncStatus.updated` 반환 시 `ref.invalidate(staticDataProvider)`로 정적 데이터 재로딩.
  - **시나리오 D — 서버 연결 실패**: `_fetchServerVersions` catch → `SyncStatus.offline` 반환. 캐시 그대로 사용.
  - **시나리오 E — optional 테이블 누락**: `_downloadOptionalTables`의 개별 try/catch에서 swallow. 캐시는 빈 리스트로 저장되지 않고 키 자체가 없는 상태가 된다. 다음 sync 시 자가치유 로직(`isCacheEmpty`)이 동작하지 않을 수 있으므로 [Q-3] 명시.

- **[FR-8] 후속 마일스톤(M8b+) 신규 테이블 추가 워크플로 명시**
  새 정적 데이터 테이블을 추가할 때 다음 순서를 지킨다:
  1. Supabase에 `CREATE TABLE` 마이그레이션 + RLS + 인덱스 + RLS SELECT 정책(anon/authenticated 허용).
  2. `data_versions`에 `INSERT (table_name, version, updated_at) VALUES ('{table}', 1, NOW())`.
  3. CSV 시드 데이터 INSERT.
  4. `band_of_mercenaries/lib/core/data/sync_service.dart`의 `allTables`에 추가. 필요 시 `optionalTables`에도 추가(FR-2 기준).
  5. freezed 정적 데이터 모델 생성(`lib/core/models/` 또는 `lib/features/*/domain/`).
  6. `StaticGameData` 4-step 통합(import → 필드 → 생성자 → loadFromCache).
  7. (선택) `operation-bom/src/lib/table-config.ts`에 등록.
  8. `dart run build_runner build --delete-conflicting-outputs` + `flutter analyze` + `flutter test` 검증.

- **[FR-9] CLAUDE.md 정적 데이터 테이블 카운트 갱신**
  - 현재 `band_of_mercenaries/CLAUDE.md`는 "정적 데이터 (Supabase 동기화)" 절에 "32개 테이블"로 표기되어 있을 가능성이 있다(M7 페이즈 4 #3 기준). M8a #1·#2 도입 후 **37개**로 갱신해야 한다.
  - 본 명세에서는 코드 변경 없이 문서만 다룬다 — CLAUDE.md 갱신은 `finalize-feature` 단계에서 처리.

### 2.2 데이터 요구사항

- **Supabase 측 검증 항목**:
  - `data_versions` 테이블에 M8a 신규 5 테이블 모두 row 존재 확인.
  - `combat_report_templates` (96행) · `combat_report_keywords` (40행) row count 검증 완료 (M8a #2 마이그레이션 직후 확인됨).
  - `faction_contacts` · `faction_reactions` · `faction_shop_items` row count는 본 명세 시점에 별도 검증 필요([Q-1]).
- **클라이언트 측 변경 없음**: 본 명세는 코드 변경 없는 정책 명세이다(M8a #1·#2 구현 PR에서 모두 반영 완료).
- **신규 enum / 모델 변경**: 없음.

### 2.3 UI 요구사항

해당 사항 없음(운영 정책 명세, UI 변경 없음).

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| (없음) | 본 명세는 코드 변경을 동반하지 않는다 | 정책 문서화 단계 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `Docs/spec/[spec]20260519_m8a-static-data-sync-and-ops.md` | 본 명세서 |

### 3.3 코드 생성 필요 파일

해당 사항 없음.

### 3.4 관련 시스템

- **SyncService** (`band_of_mercenaries/lib/core/data/sync_service.dart`): allTables 37개 / optionalTables 5개 등록 상태 검증.
- **StaticGameData** (`band_of_mercenaries/lib/core/providers/static_data_provider.dart`): 신규 5 모델 4-step 통합 완료 확인.
- **CombatReportService** (`band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart`): templates 빈 리스트 fail-soft 검증 완료(M8a #2 단위 테스트 통과).
- **FactionContactService** (`band_of_mercenaries/lib/features/info/domain/faction_contact_service.dart`): contacts 빈 리스트 fail-soft 검증 필요([Q-4]).
- **operation-bom** (`/Users/radiogaga/git/operation-bom`): table-config.ts 등록은 별도 PR.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `band_of_mercenaries/lib/core/data/sync_service.dart`: `optionalTables` Set + `_downloadOptionalTables` try/catch 패턴.
- `band_of_mercenaries/lib/core/data/data_loader.dart`: `loadFromCache` null → 빈 리스트 fallback.
- `band_of_mercenaries/lib/core/providers/static_data_provider.dart`: 4-step 통합 패턴(import → 필드 → 생성자 → loadFromCache).
- `operation-bom/CLAUDE.md`: "버전 발행" 규약, RLS 정책 가이드.
- `operation-bom/src/lib/table-config.ts`: 테이블 등록 시 FieldConfig 타입 정의.

### 4.2 주의사항

- **자동 버전 트리거 금지**: operation-bom CLAUDE.md에 명시된 대로 `data_versions.version`은 자동 증가하지 않는다. 미완성 변경이 클라이언트에 전파되지 않도록 수동 발행(operation-bom 버튼 또는 수동 SQL)을 유지한다.
- **optionalTables 추가 후 동기화 캐시 키 부재 케이스**: `_downloadOptionalTables`의 try/catch는 다운로드 실패 시 빈 리스트로 캐시하지 않고 키 자체를 만들지 않는다. 다음 sync 시 자가치유 로직(`isCacheEmpty`)이 키 부재로 동작하지 않을 수 있다([Q-3]).
- **RLS 정책 일관성**: 신규 게임 데이터 테이블은 모두 `anon` + `authenticated` SELECT 허용, INSERT/UPDATE/DELETE는 `editor`/`admin`만 허용. M8a #2 마이그레이션은 이 정책을 따랐다.
- **CSV ↔ JSONB 호환**: 본 명세에 다룬 5 테이블 중 `combat_report_*` 2종은 `tags_json` 컬럼을 JSONB로 사용한다. Flutter 모델의 `Object? tagsJson` 패턴(M8a #2 명세 Q-3 결정사항)을 후속 정적 데이터에서도 동일하게 적용한다.
- **빈 캐시 vs 빈 데이터**: `isCacheEmpty`는 캐시된 JSON이 `[]`인지 검사한다. 키가 아예 없는 경우(다운로드 실패로 캐시 미생성) 다른 조건이다. FR-7 시나리오 E 참조.

### 4.3 엣지 케이스

- **신규 환경에서 일부 optional 테이블만 누락**: `_downloadOptionalTables`가 각 테이블 개별 try/catch이므로, 누락된 테이블만 빈 캐시 상태로 남고 나머지는 정상 다운로드된다.
- **operation-bom의 버전 발행 누락**: 운영자가 데이터 수정 후 "버전 발행" 버튼을 클릭하지 않으면 클라이언트는 변경을 인지하지 못한다. 자가치유 로직은 빈 캐시만 감지하므로 부분 갱신은 누락 가능.
- **마이그레이션 적용 환경 vs 미적용 환경 혼재**: 동일한 클라이언트 빌드가 서로 다른 Supabase 환경(개발/스테이징/프로덕션)에서 동작할 때, optional 테이블 부재 환경에서도 기동되어야 한다. M8a 5 테이블 모두 optional 등록되어 있어 이 요건을 충족.
- **`data_versions` row 누락**: 신규 테이블의 `data_versions` row가 INSERT 되지 않으면 `_findChangedTables`에서 누락된다. 초기 캐시에는 들어가지만 이후 갱신이 안 됨.

### 4.4 구현 힌트

- **검증 절차**:
  1. `grep -n "optionalTables" band_of_mercenaries/lib/core/data/sync_service.dart` → M8a 5 테이블 모두 등록 확인
  2. Supabase MCP `execute_sql`: `SELECT table_name, version FROM data_versions WHERE table_name IN ('faction_contacts', 'faction_reactions', 'faction_shop_items', 'combat_report_templates', 'combat_report_keywords')` → 5 row 반환 검증
  3. Supabase MCP `execute_sql`: 각 테이블 `SELECT COUNT(*)` 검증 (combat_report_templates=96, combat_report_keywords=40, faction_* = M8a #1 시드 행수)
  4. `flutter test test/features/quest/domain/combat_report_service_test.dart` 통과 확인 → optional 빈 리스트 fail-soft 검증
- **operation-bom 등록 작업 (별도 PR)**:
  - `src/lib/table-config.ts`에 FR-6 표를 따라 `TableConfig` 5건 추가
  - `category`는 기존 4종(`world`/`mercenary`/`balance`/`quest`/`trait`)에서 선택 (필요 시 `faction` 신설 → `TableConfig.category` 타입 확장)
  - `tags_json` 컬럼은 `FieldType: "json"` 사용

## 5. 기획 확인 사항

- [Q-1] **`faction_contacts`/`faction_reactions`/`faction_shop_items` Supabase 시드 상태**: M8a #1 마이그레이션이 이미 적용되었는지, `data_versions`에 row가 있는지 별도 검증 필요. → **답변: 본 명세 작성 시점 미검증. 본 명세는 정책 문서이므로 추후 별도 검증 SQL 실행으로 확인. 미적용 시 별도 마이그레이션 PR.**
- [Q-2] **operation-bom 누락 테이블 일괄 등록**: 현재 `table-config.ts`에 17개 테이블만 등록되어 있고, M2a~M8a 신규 테이블 다수(items/elite_monsters/chain_quests/quest_narratives/region_sectors/crafting_recipes/band_achievement_templates/titles/region_adjacency/factions + M8a 5 테이블)가 미등록. → **답변: 본 PR 범위 외. operation-bom 별도 백로그로 분리. 본 명세는 가이드라인 제공.**
- [Q-3] **optional 테이블 다운로드 실패 시 자가치유**: `_downloadOptionalTables`가 실패한 테이블에 빈 리스트(`'[]'`)를 캐시 저장하지 않으므로, 다음 sync 시 `isCacheEmpty` 자가치유가 동작하지 않을 수 있다. → **답변: 본 명세 시점에는 기존 동작 보존(보수적). 후속 M9 이전에 `_downloadOptionalTables`가 실패 시 빈 리스트로 캐시 저장하도록 개선 검토. 변경은 별도 명세로 분리.**
- [Q-4] **FactionContactService fail-soft 검증**: M8a #1 명세에서 `factionContacts == []` 케이스가 명시적으로 검증되었는지 확인 필요. → **답변: M8a #1 구현 plan 문서 참조. 본 명세 범위 외. 미흡 시 별도 작업으로 분리.**
- [Q-5] **CLAUDE.md 테이블 카운트 갱신**: 본 명세에서 `band_of_mercenaries/CLAUDE.md`의 "32개 테이블" 표기를 37개로 갱신할지. → **답변: 본 명세는 코드/문서 변경 없음. CLAUDE.md 갱신은 `finalize-feature` 단계에서 일괄 처리(M8a #1·#2 PR과 함께).**
