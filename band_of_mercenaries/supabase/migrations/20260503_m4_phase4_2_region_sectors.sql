-- M4 페이즈 4 #2: region_sectors 신규 테이블 + regions.sector_count 컬럼 + 종속 데이터 정리
-- 작성일: 2026-05-03
-- 명세서: Docs/spec/M4/[spec]20260503_m4-region-sectors.md
-- 본 마이그레이션은 단일 트랜잭션이며, 실패 시 전체 롤백된다.
-- 페이즈 4 #1(20260503_m4_phase4_1_region_migration.sql)이 선행되어야 한다.

BEGIN;

-- §1. chain_quests.target_sector_id 비-null 행 없음 확인 (REQ-11)
-- 비-null이 존재한다면 1-based(1..sectorCount) 변환 룰이 적용되지 않은 데이터가 잔존한다는 의미이므로 롤백
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM chain_quests WHERE target_sector_id IS NOT NULL) > 0 THEN
    RAISE EXCEPTION 'chain_quests.target_sector_id 비-null 행 감지 — 1-based(1..sectorCount) 변환 룰 필요';
  END IF;
END $$;

-- §2. regions.sector_count 컬럼 추가 + region_sectors 테이블 생성 (REQ-1, REQ-2)
ALTER TABLE regions ADD COLUMN sector_count INT NOT NULL DEFAULT 4 CHECK (sector_count BETWEEN 1 AND 6);

CREATE TABLE region_sectors (
  id TEXT PRIMARY KEY,
  region_id INTEGER NOT NULL REFERENCES regions(region) ON DELETE CASCADE,
  sector_index INTEGER NOT NULL CHECK (sector_index BETWEEN 1 AND 6),
  name TEXT NOT NULL,
  sector_type TEXT NOT NULL CHECK (sector_type IN ('village', 'ruins', 'hidden', 'dungeon', 'field')),
  environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  description TEXT,
  UNIQUE (region_id, sector_index)
);

CREATE INDEX idx_region_sectors_region ON region_sectors(region_id);

-- §3. 거점급·transform 보존 대상 4개 region을 5섹터로 승격 (REQ-1)
-- 기획서 1.3절: T5 region 1 / T2 region 23 / T1 region 127 / T2 region 146
UPDATE regions SET sector_count = 5 WHERE region IN (1, 23, 127, 146);

-- §4. region_discoveries sector_index 재매핑 — sector_count 한도 초과 transform 데이터 정합성 확보 (REQ-12)
-- region 18 (T8 마계경계, M9 이연): sector_count=4이므로 index >= 4인 transform은 1로 재매핑
UPDATE region_discoveries
SET discovery_data = jsonb_set(discovery_data, '{sector_index}', '1')
WHERE region_id = 18 AND discovery_type = 'transform'
  AND (discovery_data->>'sector_index')::int >= 4;

-- region 23, 146 (sector_count=5 승격): 0-based 4번 섹터(1-based 5번)가 상한이므로 >= 4는 4로 재매핑
UPDATE region_discoveries
SET discovery_data = jsonb_set(discovery_data, '{sector_index}', '4')
WHERE region_id IN (23, 146) AND discovery_type = 'transform'
  AND (discovery_data->>'sector_index')::int >= 4;

-- §5. data_versions 갱신 (클라이언트 증분 동기화 트리거)
-- REQ-1·12 영향을 받은 기존 테이블 버전 증가
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'regions';
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'region_discoveries';

-- 신규 region_sectors 항목 등록 (REQ-2, version=1)
INSERT INTO data_versions (table_name, version, updated_at) VALUES ('region_sectors', 1, NOW())
ON CONFLICT (table_name) DO NOTHING;

COMMIT;
