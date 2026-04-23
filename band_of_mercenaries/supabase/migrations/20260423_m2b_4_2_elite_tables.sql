-- ============================================================================
-- M2b 페이즈 4-2: elite_monsters / elite_loot_tables 테이블 신설
-- ============================================================================
-- 생성일: 2026-04-23
-- 마일스톤: M2b (엘리트의 시대)
-- 출처 명세: Docs/spec/[spec]20260423_m2b-4-2-elite-data-models.md
-- 멱등성: CREATE TABLE IF NOT EXISTS + ON CONFLICT DO NOTHING
-- ============================================================================

BEGIN;

-- §1. elite_monsters 테이블 생성
-- 엘리트 몬스터 마스터 데이터 (이름, 티어, 전투력, 출현율, 환경 태그 등)
CREATE TABLE IF NOT EXISTS elite_monsters (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  is_unique BOOLEAN NOT NULL DEFAULT false,
  type_family TEXT NOT NULL,
  tier INTEGER NOT NULL,
  power INTEGER NOT NULL,
  spawn_rate REAL NOT NULL,
  duration_multiplier REAL NOT NULL DEFAULT 1.0,
  environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  stat_weight JSONB NOT NULL DEFAULT '{}'::jsonb,
  fixed_region_environments JSONB,
  lore TEXT,
  title TEXT
);

-- §2. elite_loot_tables 테이블 생성
-- 엘리트 몬스터별 드롭 테이블 (아이템/골드, 드롭율, 희귀도 등)
CREATE TABLE IF NOT EXISTS elite_loot_tables (
  id TEXT PRIMARY KEY,
  elite_id TEXT NOT NULL REFERENCES elite_monsters(id),
  drop_type TEXT NOT NULL,
  item_id TEXT REFERENCES items(id),
  gold_min INTEGER,
  gold_max INTEGER,
  drop_rate REAL NOT NULL CHECK (drop_rate BETWEEN 0.0 AND 1.0),
  rarity_grade TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1
);

-- §3. 조회 성능을 위한 인덱스 (elite_id 기준 드롭 테이블 조회)
CREATE INDEX IF NOT EXISTS idx_elite_loot_tables_elite_id ON elite_loot_tables(elite_id);

-- §4. data_versions 등록 (Flutter 앱 동기화 트리거)
INSERT INTO data_versions(table_name, version) VALUES ('elite_monsters', 1) ON CONFLICT (table_name) DO NOTHING;
INSERT INTO data_versions(table_name, version) VALUES ('elite_loot_tables', 1) ON CONFLICT (table_name) DO NOTHING;

COMMIT;
