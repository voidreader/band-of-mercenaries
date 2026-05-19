-- M8b 페이즈 4 #2 — data_versions 4행 upsert
-- 마이그레이션: m8b_phase4_data_versions

INSERT INTO data_versions (table_name, version, updated_at)
VALUES
  ('combat_skills', 1, NOW()),
  ('combat_status_effects', 1, NOW()),
  ('enemies', 1, NOW()),
  ('combat_report_templates', 1, NOW())
ON CONFLICT (table_name) DO UPDATE
  SET version = data_versions.version + 1,
      updated_at = NOW();
