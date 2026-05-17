# M7 페이즈 3 산출물 1 메타: regions UPDATE + region_adjacency 신설

> 작성일: 2026-05-17
> 마일스톤: M7 (지역 생활권 확장)
> 페이즈: 3 #1
> 산출 파일: `Docs/content-data/m7_region_metadata.sql`

---

## 생성 근거

### 참조 기획 문서

- `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` (페이즈 1 #1)
  - 1절: 7리전 선정 + 신규 명명
  - 5절: 이동 인접성 컨셉 + 옵션 A (region_adjacency) 권장
- `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md` (페이즈 1 #4)
  - 4.4절: region_adjacency 21행 시드 표
  - 4.4절: MovementService._calculateDistance() 그래프 기반 의사 코드

### data-generator 미사용 사유

본 산출물은 다음 이유로 data-generator 스킬 대신 main agent 직접 작성:

1. **타입 스펙 부재**: `.claude/skills/data-generator/types/region-adjacency.md` 미존재 (현재 10개 지원 타입에 미포함)
2. **기획서 명시 권장**: 페이즈 1 #4 산출물 (A)절에서 "별도 타입 스펙 작성 불필요, 페이즈 4 #3 명세 인라인 처리 권장 (M4 region_migration CSV 패턴 답습)"
3. **데이터 양 적음**: 22행 (양방향 11쌍)은 data-generator 벌크 생성 부담 대비 효율 낮음
4. **M4 region_migration 선례**: `Docs/content-data/region_migration_199_to_40.csv`도 동일하게 인라인 처리됨

---

## 생성 요약

### (A) regions UPDATE 6행

| region | 기존 region_name | 신규 region_name | 출처 |
|--------|----------------|------------------|------|
| 31 | 초원 | **도적길** | 페이즈 1 #1 1.1절 |
| 127 | 해안 | **변방 해안** | 페이즈 1 #1 1.1절 |
| 9 | 숲 | **외곽 숲** | 페이즈 1 #1 1.1절 |
| 10 | 숲 | **풍신 숲** | 페이즈 1 #1 1.1절 |
| 146 | 늪 | **회색 늪지** | 페이즈 1 #1 1.1절 |
| 38 | 폐허 | **부서진 요새** | 페이즈 1 #1 1.1절 |

- **region 3 "더스트플레인" 보존** (시작 거점, M4 결정 유지)
- 기타 region_tier·environment_tags·recommend_power·sector_count 등 변경 없음

### (B) region_adjacency 신규 테이블 + 22행 INSERT

**DDL 컬럼**:
- `id SERIAL PRIMARY KEY`
- `from_region INTEGER NOT NULL REFERENCES regions(region)`
- `to_region INTEGER NOT NULL REFERENCES regions(region)`
- `distance_units INTEGER NOT NULL CHECK (distance_units > 0)`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `UNIQUE (from_region, to_region)`
- `CHECK (from_region <> to_region)` — 자기 자신 매핑 금지
- INDEX `idx_region_adjacency_from` ON `from_region` (쿼리 빈번)

**22행 시드 (양방향 11쌍)**:

| 쌍 | from ↔ to | distance | 비고 |
|----|----------|----------|------|
| 1 | 3 ↔ 31 | 2 | 더스트빌 → 도적길 |
| 2 | 3 ↔ 127 | 2 | 더스트빌 → 변방 해안 |
| 3 | 3 ↔ 9 | 3 | 더스트빌 → 외곽 숲 |
| 4 | 3 ↔ 10 | 3 | 더스트빌 → 풍신 숲 |
| 5 | 3 ↔ 38 | 4 | 더스트빌 → 부서진 요새 (먼 직접) |
| 6 | 3 ↔ 146 | 4 | 더스트빌 → 회색 늪지 (간접 경로) |
| 7 | 31 ↔ 10 | 3 | 도적길 → 풍신 숲 (외곽 인접) |
| 8 | 9 ↔ 146 | 2 | 외곽 숲 → 회색 늪지 (외곽 인접) |
| 9 | 127 ↔ 38 | 4 | 변방 해안 → 부서진 요새 (해안→산) |
| 10 | 10 ↔ 50 | 4 | chain_windrunner_trail 2단계 target |
| 11 | 38 ↔ 21 | 3 | chain_blade_of_border target |

**기획서 4.4절 표는 21행 추정**이었으나 실제 22행 (양방향 11쌍 = 11 × 2). 페이즈 1 #4 추정 수치 "21행"은 비공식 추정.

---

## 검증 결과

### SQL 스크립트 자체 검증 (스크립트 내 DO 블록)

1. **UPDATE 대상 6리전 존재성 검증** (line 32-41): `RAISE EXCEPTION` 트리거
2. **UPDATE 갱신 결과 검증** (line 72-86): 6행 모두 신규 이름과 일치하는지
3. **region_adjacency 양방향 정합성 검증** (line 178-194): from=A,to=B 존재 시 from=B,to=A도 동일 distance
4. **22행 총량 검증** (line 197-206)
5. **region 3 도달 가능성 검증** (line 209-223): 7리전 모두 region 3과 직접 인접

### 추가 검증 항목 (운영 도구에서 수동)

- [ ] regions 갱신 후 operation-bom 웹 UI에서 7리전 표시 확인
- [ ] region_adjacency 양방향 정합 도구 권장 (페이즈 4 #3 명세 입력)
- [ ] chain_windrunner_trail / chain_blade_of_border 등 기존 chain 동작 회귀 테스트

---

## 적용 절차 (페이즈 4 #1·#3 명세 단계)

본 SQL 스크립트는 **즉시 적용하지 않는다**. 페이즈 4 명세 단계에서 다음 순서로 적용:

1. **페이즈 4 #1 RegionState 모델 확장 명세** 작성 시 본 스크립트 인라인 참조
2. **페이즈 4 #3 이동 화면 + 거점 상세 UI 명세** 작성 시 region_adjacency 그래프 기반 거리 계산 코드 명세 통합
3. **operation-bom table-config.ts에 region_adjacency 추가**:
   - 컬럼: from_region, to_region, distance_units
   - 운영 도구 양방향 정합성 검증 버튼 추가 권장
4. **SyncService 마이그레이션**:
   - data_versions 테이블에 `('region_adjacency', 1)` INSERT
   - Flutter `StaticGameData.regionAdjacency: Map<int, Map<int, int>>` 캐시 로드
5. **Supabase 실행**:
   - 본 스크립트를 단일 트랜잭션으로 실행
   - DO 블록 5개의 검증 통과 후 commit

---

## 다음 단계

- **페이즈 3 산출물 1번 완료** → milestone-runner로 갱신 (산출물 파일 경로 매칭)
- **다음 페이즈 3 산출물 2번**: 지역 특산 재료 10~20개 (items 8행 + quest_pool_material_drops ~34행) — `/data-generator item --brief @Docs/balance-design/[balance]20260517_m7_material_economy_curve.md`

---

## 참고: M4 region_migration 패턴

본 산출물은 다음 M4 산출물의 인라인 처리 패턴을 답습:

- `Docs/content-data/region_migration_199_to_40.csv` — 199→40 리전 매핑 CSV (M4 페이즈 4 #1 마이그레이션 입력)
- `Docs/content-data/postponed_regions_dump.json` — 삭제 리전 159개 컨텐츠 보관

→ M9+ 마일스톤에서 다른 리전 그룹 인접성 추가 시 본 산출물 형식 그대로 확장 가능 (`Docs/content-data/m8_region_metadata.sql` 등).
