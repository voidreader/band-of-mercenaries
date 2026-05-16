-- M6 페이즈 4 #3 — 지명 의뢰 시스템
-- quest_pools 4 컬럼 확장 + CHECK 2 + INDEX 1 + 7행 INSERT
-- 명세서: Docs/spec/[spec]20260515_M6_phase4_3_named-quests.md §FR-1·FR-13
-- 작성일: 2026-05-15

BEGIN;

-- ============================================================
-- §FR-1 — quest_pools 4 컬럼 확장
-- ============================================================

ALTER TABLE public.quest_pools
  ADD COLUMN IF NOT EXISTS is_named BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS named_hook_type TEXT NULL,
  ADD COLUMN IF NOT EXISTS named_hook_value TEXT NULL,
  ADD COLUMN IF NOT EXISTS named_cooldown_hours INTEGER NULL DEFAULT 24;

-- CHECK 제약: hook_type 4종 enum (NULL 허용)
ALTER TABLE public.quest_pools
  DROP CONSTRAINT IF EXISTS named_hook_type_check;
ALTER TABLE public.quest_pools
  ADD CONSTRAINT named_hook_type_check
  CHECK (named_hook_type IS NULL OR
         named_hook_type IN ('title', 'achievement_count', 'achievement_id', 'flagship'));

-- CHECK 제약: is_named ↔ hook_type 일관성
ALTER TABLE public.quest_pools
  DROP CONSTRAINT IF EXISTS named_consistency;
ALTER TABLE public.quest_pools
  ADD CONSTRAINT named_consistency
  CHECK ((is_named = false AND named_hook_type IS NULL) OR
         (is_named = true AND named_hook_type IS NOT NULL));

-- 부분 인덱스 (named 행만)
CREATE INDEX IF NOT EXISTS idx_quest_pools_is_named
  ON public.quest_pools (is_named) WHERE is_named = true;

-- ============================================================
-- §FR-13 — 7행 지명 의뢰 INSERT
-- ============================================================

-- 1. 마을의 은인을 찾는다 (title hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_village_savior', '마을의 은인을 찾는다',
  3, 2, 1, 5, 'escort',
  true, 'title', 'title_village_savior', 24,
  '{"named_reward_multiplier": 1.30, "named_reputation_multiplier": 1.30, "named_description": "그 일을 해낸 사람이라면 부탁드릴 것이 있습니다..."}'::jsonb,
  '인근 마을 노인'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 2. 도적길 추적자에게 (title hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_road_hunter', '도적길 추적자에게',
  1, 3, 2, 4, 'raid',
  true, 'title', 'title_road_hunter', 24,
  '{"named_reward_multiplier": 1.40, "named_reputation_multiplier": 1.30, "named_description": "도적길에 익숙한 자가 필요하다"}'::jsonb,
  '도적단 척후병'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 3. 괴물의 흔적을 따른다 (title hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_monster_hunter', '괴물의 흔적을 따른다',
  1, 4, 2, 4, 'raid',
  true, 'title', 'title_monster_hunter', 24,
  '{"named_reward_multiplier": 1.40, "named_reputation_multiplier": 1.30, "named_description": "그 짐승의 흔적을 본 적 있는가"}'::jsonb,
  '거대 짐승'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 4. 이름 있는 용병단을 찾는다 (achievement_count hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_renowned_3', '이름 있는 용병단을 찾는다',
  2, 2, 1, 5, 'explore',
  true, 'achievement_count', '3', 24,
  '{"named_reward_multiplier": 1.30, "named_reputation_multiplier": 1.30, "named_description": "이름 있는 용병단이라 들었다"}'::jsonb,
  '미지의 영역'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 5. 전설을 들은 의뢰인 (achievement_count hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_renowned_10', '전설을 들은 의뢰인',
  1, 5, 4, 5, 'raid',
  true, 'achievement_count', '10', 24,
  '{"named_reward_multiplier": 1.50, "named_reputation_multiplier": 1.50, "named_description": "당신들의 전설을 들었다. 진위를 확인하고 싶다"}'::jsonb,
  '강력한 적'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 6. 깃대를 보고 온 편지 (flagship hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_flagship_letter', '깃대를 보고 온 편지',
  3, 2, 1, 5, 'escort',
  true, 'flagship', '', 24,
  '{"named_reward_multiplier": 1.30, "named_reputation_multiplier": 1.30, "named_description": "용병단의 깃대를 보고 왔습니다. 당신께만 부탁드릴 것이 있습니다."}'::jsonb,
  '깃대를 본 의뢰인'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 7. 깃대의 전설을 찾는 자 (flagship hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_flagship_legend', '깃대의 전설을 찾는 자',
  1, 4, 2, 4, 'raid',
  true, 'flagship', '', 24,
  '{"named_reward_multiplier": 1.50, "named_reputation_multiplier": 1.40, "named_description": "당신의 깃대 아래에서 임무를 수행하고 싶다는 자가 찾아왔습니다."}'::jsonb,
  '깃대의 전설을 따르는 자'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- ============================================================
-- data_versions 갱신 (quest_pools version + 1)
-- ============================================================

INSERT INTO public.data_versions (table_name, version, updated_at)
VALUES ('quest_pools', (SELECT COALESCE(MAX(version), 0) + 1 FROM public.data_versions WHERE table_name = 'quest_pools'), NOW())
ON CONFLICT (table_name) DO UPDATE SET
  version = public.data_versions.version + 1,
  updated_at = NOW();

COMMIT;
