# Phase 6: operation-bom 트레잇 웹앱 확장 — 구현 계획 및 결과

> Skill used: implement-agent
> 명세서: `Docs/20260413_phase6-trait-operation-bom.md`
> 작성일: 2026-04-13

## 1. 구현 계획

### 태스크 구성 (8개)

| TASK | 대상 파일 | 유형 | 작업 내용 |
|------|-----------|------|----------|
| TASK-1 | `src/lib/table-config.ts` | 수정 | FieldType에 "json" 추가, TableConfig에 compositeKey 추가, category에 "trait" 추가, traits config 교체, 5개 신규 config |
| TASK-2 | `src/lib/types.ts` | 수정 | Trait 인터페이스 교체, 5개 신규 인터페이스 (TraitCategory, TraitConflict, TraitTransition, TraitComboEvolution, TraitSynergy) |
| TASK-3 | `src/components/delete-button.tsx` | 수정 | compositeKeyValues 옵셔널 props 추가, 복합 키 .eq() 체이닝 삭제, 로그 직렬화 |
| TASK-4 | `src/components/record-form.tsx` | 수정 | parseFieldValue에 json case, formatFieldValue에 JSON.stringify 분기, handleSubmit에 JSON 검증, Textarea(rows=6, monospace) 렌더링 |
| TASK-5 | `src/app/(authenticated)/data/[table]/table-client.tsx` | 수정 | json 컬럼 축약 표시 (null→"-", 객체→"{N keys}"), compositeKey 편집 링크 숨김, DeleteButton에 복합 키 전달 |
| TASK-6 | `src/components/sidebar.tsx` | 수정 | "트레잇" 카테고리 신설 (7개 링크), "용병"에서 Traits 제거 |
| TASK-7 | `src/app/(authenticated)/traits/visualization/page.tsx` | 신규 | 서버 컴포넌트 — 6개 테이블 Promise.all 병렬 조회 |
| TASK-8 | `src/app/(authenticated)/traits/visualization/visualization-client.tsx` | 신규 | 클라이언트 컴포넌트 — 카테고리 필터 + 4개 섹션(충돌/진화/조합/시너지) 카드 렌더링 |

### 실행 순서

```
Step 1: TASK-1, TASK-2, TASK-3, TASK-6 (병렬)
Step 2: TASK-4, TASK-5 (병렬) — Step 1 완료 후
Step 3: TASK-7 — TASK-2 완료 후
Step 4: TASK-8 — TASK-7 완료 후
```

## 2. 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `src/lib/table-config.ts` | 수정 | FieldType/TableConfig 인터페이스 확장, traits config 교체, 5개 신규 config 추가 |
| `src/lib/types.ts` | 수정 | Trait 인터페이스 교체, 5개 신규 인터페이스 추가 |
| `src/components/delete-button.tsx` | 수정 | compositeKeyValues 옵셔널 prop + 복합 키 삭제 로직 |
| `src/components/record-form.tsx` | 수정 | json 타입 파싱/포맷/검증/렌더링 |
| `src/app/(authenticated)/data/[table]/table-client.tsx` | 수정 | json 축약 표시 + compositeKey 편집 제한 |
| `src/components/sidebar.tsx` | 수정 | "트레잇" 카테고리 신설, "용병"에서 Traits 이동 |
| `src/app/(authenticated)/traits/visualization/page.tsx` | 신규 | 시각화 서버 컴포넌트 |
| `src/app/(authenticated)/traits/visualization/visualization-client.tsx` | 신규 | 시각화 클라이언트 컴포넌트 |

## 3. verifier 검증 결과

### 1차 검증: FAIL (이슈 1건)

| FR | 판정 | 비고 |
|----|------|------|
| FR-1 | PASS | traits config 8개 필드 + 5개 신규 config, category: "trait" |
| FR-2 | PASS | Trait 교체 + 5개 신규 인터페이스, JSONB는 Record<string, unknown> | null |
| FR-3 | FAIL | JSON 테이블 목록 축약 표시 누락 (필터로 완전 숨김) |
| FR-4 | PASS | compositeKey, 편집 숨김, 복합 키 삭제 |
| FR-5 | PASS | "트레잇" 카테고리 7개 링크 |
| FR-6 | PASS | 6개 테이블 조회, 4개 섹션, 카테고리 필터, 충돌 중복 제거 |

- ISSUE-1: TASK-5에서 json 필드가 `f.type !== "json"`으로 테이블에서 완전 제외됨 → 축약 표시로 수정 필요

### 2차 검증 (ISSUE-1 수정 후): PASS

| 항목 | 판정 |
|------|------|
| json 필드 필터 제거 | PASS |
| json 축약 표시 분기 | PASS |
| 분기 순서 (Array/tier 앞) | PASS |
| 기존 렌더링 유지 | PASS |
| compositeKey 코드 유지 | PASS |
| tsc --noEmit | PASS |

### 정적 분석 결과

- `tsc --noEmit`: 오류 없음
- `eslint src/`: 기존 경고 1건만 존재 (data-table.tsx의 useReactTable 관련, 변경 파일과 무관)

## 4. build_runner 재실행 필요 파일

없음 (TypeScript 프로젝트, 코드 생성기 미사용)

## 5. CLAUDE.md 금지사항 위반

없음
