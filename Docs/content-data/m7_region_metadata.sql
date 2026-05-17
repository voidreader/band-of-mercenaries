-- ====================================================================
-- M7 페이즈 3 산출물 1: 생활권 리전 정의 (regions UPDATE + region_adjacency 신설)
-- ====================================================================
--
-- 작성일: 2026-05-17
-- 마일스톤: M7 (지역 생활권 확장)
-- 페이즈: 3 #1
--
-- 선행 문서:
--   - Docs/content-design/[content]20260516_m7_livingsphere_regions.md
--     (페이즈 1 #1 — 7리전 신규 명명 + 인접성 컨셉)
--   - Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md
--     (페이즈 1 #4 — region_adjacency 21행 시드 4.4절)
--
-- 본 스크립트는 두 가지 데이터 변경을 포함한다:
--   (A) regions UPDATE 6행 — region_name 갱신 (region 3 더스트플레인 보존)
--   (B) region_adjacency 신규 테이블 DDL + INSERT 22행 (양방향 11쌍)
--
-- 실행 순서: 본 스크립트는 페이즈 4 #1·#3 명세 단계에서 Supabase에 적용한다.
-- 적용 전 operation-bom table-config + SyncService 마이그레이션 선행 필요.
--
-- 검증 대상:
--   - 6리전 region_name 갱신 후 운영 도구 표시 확인
--   - region_adjacency 양방향 정합성 (from=A,to=B 존재 시 from=B,to=A 동일 distance)
--   - 7리전 모두 region 3과 직접 또는 간접 도달 가능
--
-- 롤백 정책:
--   - regions UPDATE는 변경 전 region_name을 주석으로 보존 (수동 롤백 가능)
--   - region_adjacency는 DROP TABLE으로 일괄 롤백
-- ====================================================================


-- ====================================================================
-- (A) regions UPDATE: 6리전 region_name 갱신
-- ====================================================================
--
-- 페이즈 1 #1 1절 7리전 매핑표:
--   region 3   "더스트플레인"   유지 (시작 거점)
--   region 31  "초원"        → "도적길"
--   region 127 "해안"        → "변방 해안"
--   region 9   "숲"          → "외곽 숲"
--   region 10  "숲"          → "풍신 숲"
--   region 146 "늪"          → "회색 늪지"
--   region 38  "폐허"        → "부서진 요새"

-- 안전 검증: 갱신 대상 6리전이 모두 존재하는지 확인
DO $$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM (VALUES (9), (10), (31), (38), (127), (146)) AS v(rid)
  WHERE NOT EXISTS (SELECT 1 FROM regions WHERE region = v.rid);

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'M7 마이그레이션 중단: 갱신 대상 region 중 % 개가 누락되었습니다.', missing_count;
  END IF;
END $$;

-- region 31: "초원" → "도적길"
UPDATE regions SET region_name = '도적길' WHERE region = 31;

-- region 127: "해안" → "변방 해안"
UPDATE regions SET region_name = '변방 해안' WHERE region = 127;

-- region 9: "숲" → "외곽 숲"
UPDATE regions SET region_name = '외곽 숲' WHERE region = 9;

-- region 10: "숲" → "풍신 숲"
UPDATE regions SET region_name = '풍신 숲' WHERE region = 10;

-- region 146: "늪" → "회색 늪지"
UPDATE regions SET region_name = '회색 늪지' WHERE region = 146;

-- region 38: "폐허" → "부서진 요새"
UPDATE regions SET region_name = '부서진 요새' WHERE region = 38;

-- 갱신 결과 검증
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM regions
  WHERE (region = 31  AND region_name = '도적길')
     OR (region = 127 AND region_name = '변방 해안')
     OR (region = 9   AND region_name = '외곽 숲')
     OR (region = 10  AND region_name = '풍신 숲')
     OR (region = 146 AND region_name = '회색 늪지')
     OR (region = 38  AND region_name = '부서진 요새');

  IF v_count <> 6 THEN
    RAISE EXCEPTION 'M7 region_name UPDATE 검증 실패: 6행이 갱신되어야 하나 % 행만 일치합니다.', v_count;
  END IF;
END $$;


-- ====================================================================
-- (B) region_adjacency 신규 테이블 + 22행 INSERT
-- ====================================================================
--
-- 페이즈 1 #4 4.4절 시드 (22행 = 양방향 11쌍):
--
-- 양방향 쌍 11개:
--   3 ↔ 31  (2칸, 더스트빌 → 도적길)
--   3 ↔ 127 (2칸, 더스트빌 → 변방 해안)
--   3 ↔ 9   (3칸, 더스트빌 → 외곽 숲)
--   3 ↔ 10  (3칸, 더스트빌 → 풍신 숲)
--   3 ↔ 38  (4칸, 더스트빌 → 부서진 요새)
--   3 ↔ 146 (4칸, 더스트빌 → 회색 늪지 / 간접 경로)
--   31 ↔ 10 (3칸, 도적길 → 풍신 숲)
--   9 ↔ 146 (2칸, 외곽 숲 → 회색 늪지)
--   127 ↔ 38 (4칸, 변방 해안 → 부서진 요새)
--   10 ↔ 50 (4칸, chain_windrunner_trail 2단계 target)
--   38 ↔ 21 (3칸, chain_blade_of_border target)
--
-- 7리전 모두 region 3과 직접 인접 (안정성 보장)
-- chain target reach 2쌍 (10↔50, 38↔21)은 기존 chain 컨텐츠 보존을 위해 포함

CREATE TABLE IF NOT EXISTS region_adjacency (
  id              SERIAL PRIMARY KEY,
  from_region     INTEGER NOT NULL REFERENCES regions(region),
  to_region       INTEGER NOT NULL REFERENCES regions(region),
  distance_units  INTEGER NOT NULL CHECK (distance_units > 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (from_region, to_region),
  CHECK  (from_region <> to_region)
);

CREATE INDEX IF NOT EXISTS idx_region_adjacency_from
  ON region_adjacency (from_region);

COMMENT ON TABLE region_adjacency IS
  'M7 페이즈 4 #3 — 리전 간 인접성 매트릭스. MovementService가 거리 계산 시 |ID 차이| 대신 본 그래프 조회. 양방향 정합 필수.';

COMMENT ON COLUMN region_adjacency.distance_units IS
  '이동 칸 수 (1칸 = 30초, 이동수단/광장 이정표 곱셈 적용 전 기본값). 페이즈 1 #4 4.4절 표 참조.';


-- 22행 INSERT (양방향 11쌍)
INSERT INTO region_adjacency (from_region, to_region, distance_units) VALUES
  -- 3 ↔ 31 (더스트빌 → 도적길)
  (3, 31, 2),
  (31, 3, 2),

  -- 3 ↔ 127 (더스트빌 → 변방 해안)
  (3, 127, 2),
  (127, 3, 2),

  -- 3 ↔ 9 (더스트빌 → 외곽 숲)
  (3, 9, 3),
  (9, 3, 3),

  -- 3 ↔ 10 (더스트빌 → 풍신 숲)
  (3, 10, 3),
  (10, 3, 3),

  -- 3 ↔ 38 (더스트빌 → 부서진 요새, 가장 먼 직접 경로)
  (3, 38, 4),
  (38, 3, 4),

  -- 3 ↔ 146 (더스트빌 → 회색 늪지, 간접 경로 — 직접 갈 수도 있음)
  (3, 146, 4),
  (146, 3, 4),

  -- 31 ↔ 10 (도적길 → 풍신 숲, 인접 외곽)
  (31, 10, 3),
  (10, 31, 3),

  -- 9 ↔ 146 (외곽 숲 → 회색 늪지, 인접 외곽)
  (9, 146, 2),
  (146, 9, 2),

  -- 127 ↔ 38 (변방 해안 → 부서진 요새, 해안에서 산 경유)
  (127, 38, 4),
  (38, 127, 4),

  -- 10 ↔ 50 (풍신 숲 → 풍신 추격 target, chain_windrunner_trail 2단계)
  (10, 50, 4),
  (50, 10, 4),

  -- 38 ↔ 21 (부서진 요새 → 산악, chain_blade_of_border target)
  (38, 21, 3),
  (21, 38, 3);


-- 양방향 정합성 검증: from=A,to=B 존재 시 from=B,to=A도 존재 + distance 동일
DO $$
DECLARE
  v_violation_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_violation_count
  FROM region_adjacency AS a
  WHERE NOT EXISTS (
    SELECT 1
    FROM region_adjacency AS b
    WHERE b.from_region = a.to_region
      AND b.to_region = a.from_region
      AND b.distance_units = a.distance_units
  );

  IF v_violation_count > 0 THEN
    RAISE EXCEPTION 'region_adjacency 양방향 정합성 위반: % 행이 역방향 매칭 없음', v_violation_count;
  END IF;
END $$;


-- 행 수 검증
DO $$
DECLARE
  v_total INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM region_adjacency;

  IF v_total <> 22 THEN
    RAISE EXCEPTION 'region_adjacency INSERT 검증 실패: 22행이어야 하나 실제 % 행', v_total;
  END IF;
END $$;


-- region 3 도달 가능성 검증 (7리전 모두 region 3과 직접 인접)
DO $$
DECLARE
  v_unreachable_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_unreachable_count
  FROM (VALUES (31), (127), (9), (10), (146), (38)) AS v(rid)
  WHERE NOT EXISTS (
    SELECT 1 FROM region_adjacency
    WHERE (from_region = 3 AND to_region = v.rid)
       OR (from_region = v.rid AND to_region = 3)
  );

  IF v_unreachable_count > 0 THEN
    RAISE EXCEPTION 'M7 생활권 리전 중 region 3과 직접 인접하지 않은 리전 % 개', v_unreachable_count;
  END IF;
END $$;


-- ====================================================================
-- 적용 후 후속 작업 (수동)
-- ====================================================================
--
-- 1. data_versions 갱신 (Flutter 앱 동기화):
--    UPDATE data_versions SET version = version + 1 WHERE table_name = 'regions';
--    INSERT INTO data_versions (table_name, version) VALUES ('region_adjacency', 1)
--      ON CONFLICT (table_name) DO UPDATE SET version = data_versions.version + 1;
--
-- 2. operation-bom table-config.ts에 region_adjacency 테이블 추가
--    - 컬럼: from_region, to_region, distance_units
--    - 운영 도구 양방향 정합성 검증 도구 권장
--
-- 3. Flutter 측 변경 사항 (페이즈 4 #3 명세 영역):
--    - StaticGameData.regionAdjacency: Map<int, Map<int, int>> 추가
--    - DataLoader region_adjacency JSON 캐시 로드
--    - SyncService data_versions 항목 등록
--    - MovementService._calculateDistance() 인접 그래프 분기 추가
--
-- ====================================================================
