# regions.environment_tags 마이그레이션 + Region 모델 확장 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260420_elite_monster_catalog.md` §3.2
> 데이터 소스: `Docs/content-data/[region-environment-tag]20260423_m2b-regions.csv` (199행)
> 작성일: 2026-04-23
> 마일스톤: M2b 페이즈 4-1

---

## 1. 개요

Supabase `regions` 테이블에 `environment_tags JSONB` 컬럼을 추가하고, 기존 199개 리전에 각 1~3개의 환경 태그를 채운다. Flutter `Region` Freezed 모델에 대응 필드를 추가하여 엘리트 몬스터 출현 필터링(M2b 4-3)과 M3 지역 변형 인프라를 준비한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1]** `regions` 테이블에 `environment_tags JSONB NOT NULL DEFAULT '[]'` 컬럼을 추가한다.
  - 조건: 이미 컬럼이 존재하면 `ADD COLUMN IF NOT EXISTS`로 멱등 실행
  - 8개 허용 태그 값: `ruins` / `forest` / `swamp` / `mountain` / `desert` / `coast` / `underground` / `plains`
  - 리전당 1~3개 태그. 빈 배열(`[]`)은 예외적인 특수 리전에만 허용
  
- **[FR-2]** 199개 리전의 `environment_tags`를 CSV 데이터로 일괄 UPDATE한다.
  - 소스: `Docs/content-data/[region-environment-tag]20260423_m2b-regions.csv`
  - VALUES 테이블 조인 UPDATE 방식(단일 쿼리) 사용으로 마이그레이션 크기 최소화

- **[FR-3]** `data_versions.regions` 버전을 +1 올려 Flutter 앱이 재동기화를 트리거하도록 한다.
  - 현재 버전: 2 → 신규 버전: 3
  - Supabase MCP `execute_sql`로 직접 실행: `UPDATE data_versions SET version = 3 WHERE table_name = 'regions';`

- **[FR-4]** Flutter `Region` Freezed 모델에 `environmentTags` 필드를 추가한다.
  - 타입: `List<String>`, `@Default(<String>[])` (기존 캐시 backward compatibility)
  - `@JsonKey(name: 'environment_tags')` 어노테이션 필수
  - 기존 5개 필드는 변경 없음

- **[FR-5]** `build_runner`를 재실행하여 `region.freezed.dart` / `region.g.dart`를 재생성한다.

### 2.2 데이터 요구사항

| 항목 | 상세 |
|------|------|
| 수정 Supabase 테이블 | `regions` — `environment_tags JSONB` 컬럼 추가 (DDL) |
| 수정 Supabase 데이터 | `regions` 199행 UPDATE (environment_tags 값 채우기) |
| 수정 Supabase 메타 | `data_versions.regions` 버전 2 → 3 |
| 수정 Freezed 모델 | `Region` — `environmentTags` 필드 추가 |
| build_runner 대상 | `region.dart` (freezed + json_serializable) |

**새 필드 스펙:**
```dart
@JsonKey(name: 'environment_tags')
@Default(<String>[])
List<String> environmentTags,
```

**FactionData의 conflictFactionIds가 동일 패턴의 참조 구현:**
`lib/features/info/domain/faction_data.dart:22`

### 2.3 UI 요구사항

없음. 이 명세는 데이터 마이그레이션 + 모델 확장만 포함한다.
`environmentTags` 필드의 실제 활용(엘리트 출현 필터링 등)은 M2b 4-3 명세에서 다룬다.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/region.dart` | `environmentTags` 필드 추가 | FR-4 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/supabase/migrations/20260423_m2b_4_1_region_environment_tags.sql` | DDL + 199행 UPDATE + data_versions 갱신 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region.freezed.dart` | `Region` 모델 필드 추가 |
| `band_of_mercenaries/lib/core/models/region.g.dart` | json_serializable fromJson/toJson 재생성 |

```bash
cd band_of_mercenaries && dart run build_runner build
```

### 3.4 관련 시스템

| 시스템 | 영향 |
|--------|------|
| `SyncService` | 변경 없음. `regions` 테이블이 이미 `allTables`에 포함. data_versions 버전 변경 감지 시 자동 재다운로드 |
| `staticDataProvider` | 변경 없음. `dataLoader.loadFromCache('regions', Region.fromJson)` 경로 유지 |
| `StaticGameData.regions` | 변경 없음. `List<Region>` 유지. 앱 재시작 시 새 캐시에서 `environmentTags` 자동 포함 |
| M2b 4-3 엘리트 퀘스트 생성 | **의존 선행 조건**. `region.environmentTags`를 읽어 엘리트 출현 타입 필터링 |

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

| 파일 | 참고 내용 |
|------|----------|
| `lib/features/info/domain/faction_data.dart:22` | `@Default(<String>[]) List<String>` — JSONB 배열 필드 패턴 |
| `lib/core/models/region.dart` | 기존 `Region` 모델 전체 — 필드 추가 위치 |
| `supabase/migrations/20260418_m1_phase4_complete.sql` | 마이그레이션 파일 형식 (BEGIN/COMMIT, ADD COLUMN IF NOT EXISTS, UPDATE) |

### 4.2 주의사항

- **`regions` 테이블 PK 컬럼명 확인 필요**: Supabase 실제 스키마에서 `regions` 테이블의 PK가 `region`인지 `id`인지 확인 후 UPDATE WHERE 절에 사용. Flutter `Region` 모델의 `region` 필드가 Supabase 컬럼명 `region`에 매핑되어 있으므로 `WHERE region = {n}` 이 기본 추정.

- **@Default 필수**: 기존 로컬 캐시(앱 이미 설치된 경우)에 `environment_tags`가 없으므로 `@Default(<String>[])` 없이 `required`로 선언하면 파싱 오류 발생.

- **마이그레이션 멱등성**: `ADD COLUMN IF NOT EXISTS`와 조건부 UPDATE를 사용하여 재실행 안전하게 작성.

- **build_runner 충돌 방지**: `dart run build_runner build --delete-conflicting-outputs` 플래그를 사용하면 기존 생성 파일과 충돌 시 자동 삭제.

### 4.3 엣지 케이스

- **앱 오프라인 상태**: `environmentTags`가 빈 리스트(`[]`)인 캐시로 앱이 실행될 수 있음. 4-3 엘리트 출현 로직에서 `environmentTags.isEmpty`를 엘리트 미출현 조건으로 처리해야 함 (4-1 범위 외, 4-3에서 처리).
- **캐시 버전 불일치**: `data_versions.regions` 버전 변경 → Flutter 앱 포그라운드 복귀 시 `SyncService` 자동 감지 → `regions` 테이블만 재다운로드 → `staticDataProvider` 무효화 → 앱 내 region 데이터 자동 갱신.

### 4.4 구현 힌트

- **진입점**: 없음 (순수 마이그레이션 + 모델 확장)
- **데이터 흐름**: Supabase `regions` ← 마이그레이션 SQL → 앱 재시작/복귀 시 `SyncService.sync()` → `DataLoader.saveToCache('regions', ...)` → `DataLoader.loadFromCache('regions', Region.fromJson)` → `staticDataProvider` → 앱 전역에서 `Region.environmentTags` 접근 가능
- **참조 구현**: `lib/features/info/domain/faction_data.dart:7-29` — Freezed + JSONB 배열 패턴
- **확장 지점**: `region.dart`에 필드 추가 후 build_runner 재실행만으로 전 레이어에 자동 전파

---

## 5. 기획 확인 사항

- **[Q-1]** `environment_tags` 컬럼의 DB CHECK 제약 추가 여부 (기획서 §8 [Q-1])  
  → 추천: **검증은 data-generator 자체 검증만 유지 (DB CHECK 제약 없음)**. CHECK 제약은 `desert`+`swamp` 조합 금지 등 복합 조건이므로 JSONB 배열에서 구현이 복잡. 프로덕션 단계에서 도입 검토.

- **[Q-2]** 엘리트 퀘스트 생성 명세에서: `environmentTags.isEmpty` 리전은 보통 엘리트 출현 후보에서 제외하는지?  
  → 4-1 명세 범위 외. 4-3 명세 작성 시 결정.

---

## 6. 구현 순서 체크리스트

구현 담당자가 따라야 할 순서:

1. **[Supabase]** Supabase MCP `execute_sql` 또는 CLI로 마이그레이션 SQL 실행
   - `ALTER TABLE regions ADD COLUMN IF NOT EXISTS environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb;`
   - 199행 UPDATE (VALUES 조인 방식 단일 쿼리 권장)
   - `UPDATE data_versions SET version = 3 WHERE table_name = 'regions';`

2. **[Flutter]** `lib/core/models/region.dart` 수정 — `environmentTags` 필드 추가

3. **[Flutter]** `dart run build_runner build --delete-conflicting-outputs`

4. **[검증]** `flutter analyze` 통과 확인

5. **[검증]** 앱 실행 → SyncService가 regions 버전 변경 감지 → 재다운로드 → `staticDataProvider.regions[0].environmentTags` 비어있지 않음 확인

6. **[마이그레이션 파일]** 로컬 Supabase가 사용 중이면 `supabase db pull m2b_4_1_region_environment_tags --local --yes` 로 마이그레이션 파일 생성 (필요 시)
