# Phase 6: operation-bom 트레잇 웹앱 확장 개발 명세서

> 기획 문서: `Docs/content-design/20260412_trait_system_design.md`
> 로드맵: `Docs/Trait-Roadmap.md` (Phase 6)
> 작성일: 2026-04-13
> 담당자: Claude

## 1. 개요

operation-bom 운영 웹앱에 트레잇 시스템 6개 테이블(trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)의 CRUD 관리 기능을 추가하고, 진화 경로/충돌 관계를 한눈에 파악할 수 있는 시각화 페이지를 구축한다.

## 2. 요구사항

### 2.1 기능 요구사항

- [FR-1] `table-config.ts`에 6개 트레잇 테이블 설정 추가
  - 기존 `traits` 설정을 신규 스키마(`key, name, category_key, type, description, effect_text, acquisition_condition, effect_json`)로 완전 교체
  - `trait_categories`, `trait_conflicts`, `trait_transitions`, `trait_combo_evolutions`, `trait_synergies` 5개 신규 설정 추가
  - 모든 트레잇 테이블은 `category: "trait"`으로 분류

- [FR-2] `types.ts`에 트레잇 관련 TypeScript 인터페이스 추가
  - 기존 `Trait` 인터페이스를 신규 스키마로 교체
  - `TraitCategory`, `TraitConflict`, `TraitTransition`, `TraitComboEvolution`, `TraitSynergy` 5개 신규 인터페이스

- [FR-3] `FieldType`에 `"json"` 타입 추가
  - JSONB 컬럼(`acquisition_condition`, `effect_json`, `condition_json`) 처리용
  - 폼: `Textarea` + JSON 유효성 검증 (submit 시 `JSON.parse` 실패 → 에러 토스트)
  - 테이블 목록: 축약 표시 (예: `null` → `-`, 객체 → `{3 keys}`, 빈 객체 → `{}`)
  - 파싱: 문자열 → `JSON.parse()`, 빈 문자열 → `null`
  - 포맷: `JSON.stringify(value, null, 2)` (편집 폼에서 보기 좋게)

- [FR-4] `trait_conflicts` 테이블 복합 PK 지원
  - `TableConfig`에 `compositeKey?: string[]` 옵션 필드 추가
  - `compositeKey` 존재 시: 편집 링크 숨김 (추가/삭제만 지원)
  - 삭제: `DeleteButton`이 복합 키의 모든 컬럼으로 `.eq()` 체이닝
  - `primaryKey`는 첫 번째 복합 키 컬럼으로 설정 (정렬용)

- [FR-5] 사이드바에 "트레잇" 카테고리 신설
  - 기존 "용병" 카테고리에서 `Traits` 링크 제거
  - 새 "트레잇" 카테고리에 6개 테이블 + 시각화 페이지 링크 배치
  - "용병" 카테고리와 "밸런스" 카테고리 사이에 위치

- [FR-6] 트레잇 관계 시각화 페이지
  - 경로: `/traits/visualization`
  - 읽기 전용, Supabase에서 직접 조회
  - **섹션 A — 진화 경로**: 단일 진화(trait_transitions) 카드. `from_trait → to_trait` 화살표 + condition_json 요약
  - **섹션 B — 조합 진화**: trait_combo_evolutions 카드. `trait_1 + trait_2 → result_trait` 형태
  - **섹션 C — 충돌 관계**: trait_conflicts 쌍 목록. 양방향 화살표, 카테고리별 색상
  - **섹션 D — 시너지**: trait_synergies 테이블. 선천 → 후천 연결 + 감소율 표시
  - 각 섹션은 카테고리별 필터링 가능

### 2.2 데이터 요구사항

- Supabase 테이블 변경: 없음 (migration 003, 004에서 이미 생성 완료)
- `TableConfig` 인터페이스 변경:
  - `category` 타입에 `"trait"` 추가
  - `compositeKey?: string[]` 옵션 필드 추가
- `FieldType` 타입에 `"json"` 추가

**DB 스키마 참조 (migration 003 + 004 기준):**

| 테이블 | PK | 컬럼 |
|--------|-----|------|
| `trait_categories` | `key` (text) | name, slot_type |
| `traits` | `key` (text) | name, category_key (FK), type, description, effect_text, acquisition_condition (JSONB), effect_json (JSONB) |
| `trait_conflicts` | `(trait_key, conflict_trait_key)` 복합 | — |
| `trait_transitions` | `id` (serial) | from_trait_key, to_trait_key, condition_json (JSONB) |
| `trait_combo_evolutions` | `id` (serial) | required_trait_1, required_trait_2, result_trait_key |
| `trait_synergies` | `id` (serial) | innate_trait_key, target_trait_key, reduction_percent (real) |

### 2.3 UI 요구사항

- CRUD UI: 기존 `data/[table]` 동적 라우팅 자동 활용 (table-config 추가만으로 동작)
- 시각화 페이지: 카드 기반 레이아웃 (외부 그래프 라이브러리 없이 Tailwind + shadcn 카드)
- 진화 카드: `from_trait.name → to_trait.name` + 조건 표시, 카테고리별 배경색
- 조합 카드: `trait_1.name + trait_2.name = result.name`, 3컬럼 레이아웃
- 충돌 쌍: 뱃지 2개 + 양방향 화살표, 중복 제거 (양방향 32행 → 16쌍)
- 시너지 테이블: `innate → acquired` + `reduction_percent%` 표시

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `src/lib/table-config.ts` | `FieldType`에 `"json"` 추가, `TableConfig`에 `compositeKey?` 추가, `category`에 `"trait"` 추가, `traits` config 교체, 5개 신규 config 추가 | FR-1, FR-3, FR-4 |
| `src/lib/types.ts` | `Trait` 인터페이스 교체, 5개 신규 인터페이스 추가 | FR-2 |
| `src/components/sidebar.tsx` | "트레잇" 카테고리 추가, "용병"에서 Traits 제거 | FR-5 |
| `src/components/record-form.tsx` | `parseFieldValue`에 `"json"` 분기 추가, `formatFieldValue`에 JSON.stringify 분기, 렌더링에 `"json"` → Textarea + rows=6 처리 | FR-3 |
| `src/app/(authenticated)/data/[table]/table-client.tsx` | `"json"` 컬럼 축약 표시, `compositeKey` 존재 시 편집 링크 숨김 | FR-3, FR-4 |
| `src/components/delete-button.tsx` | `compositeKey` props 추가, 복합 키 `.eq()` 체이닝 삭제 | FR-4 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `src/app/(authenticated)/traits/visualization/page.tsx` | 시각화 페이지 서버 컴포넌트 (Supabase 조회 + 데이터 전달) |
| `src/app/(authenticated)/traits/visualization/visualization-client.tsx` | 시각화 클라이언트 컴포넌트 (필터링, 카드 렌더링) |

### 3.3 코드 생성 필요 파일

없음 (TypeScript 프로젝트, 코드 생성기 미사용)

### 3.4 관련 시스템

- **data/[table] 동적 CRUD**: table-config에 추가된 테이블은 자동으로 목록/생성/편집/삭제 UI가 생성됨. json 타입과 compositeKey 지원은 이 시스템의 확장
- **대시보드**: `getAllTableConfigs()`로 모든 테이블 카운트 표시 → 신규 6개 테이블 자동 포함
- **PublishVersionButton**: 기존 버전 발행 시스템은 수정 불필요. data_versions에 이미 6개 테이블 등록됨 (migration 003)
- **Flutter SyncService**: 웹앱에서 data_versions 버전을 올리면 Flutter 앱이 다음 싱크 시 자동 반영

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `src/lib/table-config.ts:175-191` (facilities config): `int_array`, `real_array` 커스텀 타입 처리 패턴 → `"json"` 타입도 동일 방식으로 추가
- `src/components/record-form.tsx:20-34` (parseFieldValue): 타입별 파싱 분기 → `"json"` case 추가
- `src/components/record-form.tsx:36-40` (formatFieldValue): 타입별 포맷 분기 → JSON.stringify 추가
- `src/app/(authenticated)/data/[table]/table-client.tsx:27-29` (Array 처리): 특수 타입 셀 렌더링 패턴 → `"json"` 셀 축약 표시
- `src/components/delete-button.tsx:38-44` (handleDelete): 단일 PK `.eq()` → 복합 키 확장 지점

### 4.2 주의사항

- `trait_conflicts`는 양방향 32행 (16쌍 × 2). 시각화 페이지에서 중복 제거 필요: `trait_key < conflict_trait_key` 조건으로 16쌍만 표시
- `traits` config 교체 시 기존 `id` → `key`로 PK 컬럼명 변경. `autoIncrementPK: false` 유지
- `trait_transitions`, `trait_combo_evolutions`, `trait_synergies`는 `id` (serial) PK, `autoIncrementPK: true` 설정. 폼에서 id 필드 readOnly 처리
- 시각화 페이지는 traits 테이블을 join하여 key → name 변환 필요 (FK 컬럼은 key 값이므로)
- `compositeKey` 도입 시 기존 단일 PK 테이블에 영향 없도록 옵셔널로 처리. `compositeKey` 미설정 시 기존 동작 유지

### 4.3 엣지 케이스

- JSON 필드에 빈 문자열 입력 시 `null`로 저장 (기존 nullable 컬럼 동작과 일치)
- JSON 필드에 잘못된 JSON 입력 시 submit 전에 에러 토스트, 저장 차단
- `trait_conflicts` 삭제 시 양방향 쌍의 반대편도 삭제해야 하는지 → **아니오**, 각 행은 독립. 운영자가 쌍으로 관리 (seed-traits.ts에서 양방향 삽입)
- `compositeKey` 테이블에서 `new` 페이지는 정상 동작 (create 모드는 PK readOnly 미적용)
- 시각화 페이지에서 traits 데이터가 0건인 경우 빈 상태 메시지 표시

### 4.4 구현 힌트

- **진입점**: `table-config.ts`의 `tableConfigs` 객체 확장이 핵심. 여기에 config을 추가하면 `data/[table]` 라우팅, `dashboard` 카운트, `PublishVersionButton`이 자동 연동
- **데이터 흐름 (CRUD)**: `sidebar 링크 클릭 → /data/[table]/page.tsx → getTableConfig(slug) → Supabase SELECT → TableClient 렌더링` / `추가 버튼 → /data/[table]/new → RecordForm → parseFieldValue → Supabase INSERT`
- **데이터 흐름 (시각화)**: `/traits/visualization/page.tsx(서버)` → Supabase에서 traits + transitions + combos + conflicts + synergies 병렬 조회 → `visualization-client.tsx`에 props 전달 → 클라이언트에서 필터링/렌더링
- **참조 구현**:
  - `table-config.ts:175-191` (facilities) — 복잡한 필드 타입(int_array, real_array) 설정 패턴
  - `record-form.tsx:117-148` — 필드 타입별 렌더링 분기
  - `table-client.tsx:26-48` — 필드 타입별 셀 렌더링 분기
  - `delete-button.tsx:38-44` — 삭제 로직 확장 지점
- **확장 지점**:
  - `table-config.ts:1` — `FieldType` union에 `"json"` 추가
  - `table-config.ts:12` — `TableConfig` 인터페이스에 `compositeKey?` 추가
  - `table-config.ts:16` — `category` union에 `"trait"` 추가
  - `table-config.ts:105-118` — 기존 `traits` config 교체 위치
  - `sidebar.tsx:20-68` — categories 배열에 "트레잇" 추가 (용병과 밸런스 사이)
  - `record-form.tsx:23` — `parseFieldValue` switch에 `"json"` case
  - `record-form.tsx:37` — `formatFieldValue`에 JSON 분기
  - `table-client.tsx:26` — 셀 렌더링에 json 축약 분기
  - `delete-button.tsx:24-25` — props에 compositeKey 관련 추가

## 5. 기획 확인 사항

- [Q-1] JSONB 필드 → 새 `"json"` FieldType으로 Textarea + JSON 검증 처리 → **확인됨**
- [Q-2] trait_conflicts 복합 PK → 추가/삭제만 지원 (편집 불가) → **확인됨 (옵션 A)**
- [Q-3] 사이드바 구성 → 새 "트레잇" 카테고리 신설 → **확인됨 (옵션 B)**
- [Q-4] 시각화 범위 → CRUD UI + 별도 시각화 페이지 모두 구현 → **확인됨 (옵션 C)**
- [Q-5] 기존 traits config → 신규 스키마로 완전 교체 → **확인됨**
