-- M6 페이즈 4 #2 — 칭호·간판 용병 시스템
-- 31번째 정적 데이터 테이블 신규 + 11행 시드
-- 명세서: Docs/spec/[spec]20260515_M6_phase4_2_titles-flagship.md §7
-- 작성일: 2026-05-15

BEGIN;

-- ============================================================
-- §7.1 titles 테이블 DDL + INDEX + data_versions
-- ============================================================

CREATE TABLE IF NOT EXISTS public.titles (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  description     TEXT NOT NULL,
  hook_type       TEXT NOT NULL CHECK (hook_type IN ('achievement', 'action_stat', 'status')),
  hook_condition  JSONB NOT NULL DEFAULT '{}'::jsonb,
  effect_json     JSONB NOT NULL DEFAULT '{}'::jsonb,
  icon_key        TEXT NOT NULL DEFAULT 'default',
  narrative_hint  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_titles_hook_type ON public.titles (hook_type);

-- data_versions에 신규 테이블 등록
INSERT INTO public.data_versions (table_name, version, updated_at)
VALUES ('titles', 1, NOW())
ON CONFLICT (table_name) DO UPDATE SET version = EXCLUDED.version, updated_at = EXCLUDED.updated_at;

-- ============================================================
-- §7.2 11행 시드 INSERT
-- 카테고리 분류:
--   achievement × 6 (hook_target: require_protagonist / last_dispatch_protagonist /
--                                most_dispatched_to_region_3 / first_only / require_protagonist×2)
--   action_stat × 4 (stat_key: raid_count / total_dispatch_count / explore_count / escort_count)
--   status × 1 (trigger_status: injured)
-- 합계: 6 + 4 + 1 = 11행
-- ============================================================

-- 1. 마을의 은인 (a) - 거점 사건 완주 위업 hook
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_village_savior',
 '마을의 은인',
 '더스트빌의 사건을 해결하고 작은 잔치의 주역이 된 용병.',
 'achievement',
 '{"achievement_template_id": "settlement_event_completed:settlement_3_pyegwang_reopen", "hook_target": "require_protagonist"}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "all", "value": 0.025}]}'::jsonb,
 'ic_village_savior',
 '거점 사건 주인공에게 부여. 광역 +2.5%p (페이즈 2 #1 미세 하향).');

-- 2. 폐광의 생존자 (c) - 상태 hook (부상에서 회복)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_pyegwang_survivor',
 '폐광의 생존자',
 '폐광의 어둠 속에서 부상을 입고도 다시 일어선 자.',
 'status',
 '{"trigger_status": "injured", "context": {"chain_id": "settlement_3_pyegwang_reopen", "require_chain_completion": true}}'::jsonb,
 '{"effects": [{"type": "recovery_time_reduction", "status": "injured", "value": -0.10}]}'::jsonb,
 'ic_survivor',
 '폐광 체인 완주 중 부상 진입 시 부여. 회복 -10%.');

-- 3. 첫 깃발을 든 자 (a) - 제작 첫 희귀 위업 hook (last_dispatch_protagonist)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_first_banner',
 '첫 깃발을 든 자',
 '용병단의 깃발을 처음 휘날린 자.',
 'achievement',
 '{"achievement_template_id": "craft_first_rare:recipe_dustvile_banner_restoration", "hook_target": "last_dispatch_protagonist"}'::jsonb,
 '{"effects": [{"type": "reputation_gain_modifier", "value": 0.02}]}'::jsonb,
 'ic_banner',
 '깃발 복원 위업 발급 시 최근 파견 1위 mercenary에게 부여. 명성 +2%.');

-- 4. 도적길 추적자 (b) - 행동 지표 hook (raid_count >= 20, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_road_hunter',
 '도적길 추적자',
 '도적을 쫓아 거리를 누빈 자.',
 'action_stat',
 '{"stat_key": "raid_count", "threshold": 20, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "raid", "value": 0.05}]}'::jsonb,
 'ic_road_hunter',
 '20회 약탈 의뢰 누적 시 부여. raid 한정 +5%p.');

-- 5. 백전노장 (b) - 행동 지표 hook (total_dispatch_count >= 80, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_veteran',
 '백전노장',
 '수많은 의뢰를 견디며 단단해진 노련한 용병.',
 'action_stat',
 '{"stat_key": "total_dispatch_count", "threshold": 80, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "injury_rate_modifier", "value": -0.03}]}'::jsonb,
 'ic_veteran',
 '80회 누적 파견 시 부여. 부상률 -3%.');

-- 6. 정찰의 눈 (b) - 행동 지표 hook (explore_count >= 15, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_scout_eye',
 '정찰의 눈',
 '예리한 시선으로 미답의 길을 밝힌 자.',
 'action_stat',
 '{"stat_key": "explore_count", "threshold": 15, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "investigation_success_rate_bonus", "value": 0.05}]}'::jsonb,
 'ic_scout_eye',
 '15회 정찰/조사 누적 시 부여. 조사 +5%p.');

-- 7. 호위의 노련함 (b) - 행동 지표 hook (escort_count >= 12, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_escort_master',
 '호위의 노련함',
 '의뢰인을 끝까지 지켜낸 침착한 호위자.',
 'action_stat',
 '{"stat_key": "escort_count", "threshold": 12, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "escort", "value": 0.05}]}'::jsonb,
 'ic_escort_master',
 '12회 호위 의뢰 누적 시 부여. escort 한정 +5%p.');

-- 8. 더스트빌의 친우 (a) - 거점 소속 위업 hook (most_dispatched_to_region_3)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_dustvile_friend',
 '더스트빌의 친우',
 '더스트빌 사람들이 이름을 부르는 가까운 동무.',
 'achievement',
 '{"achievement_template_id": "settlement_trust_belonging:region_3", "hook_target": "most_dispatched_to_region_3"}'::jsonb,
 '{"effects": [{"type": "quest_reward_multiplier", "quest_type": "all", "value": 0.02}]}'::jsonb,
 'ic_dustvile_friend',
 '거점 소속 위업 발급 시 region 3 최다 파견 mercenary에게 부여. 보상 +2% (페이즈 2 #1 미세 하향).');

-- 9. 괴물 사냥꾼 (a) - 엘리트 유니크 첫 처치 hook (first_only)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_monster_hunter',
 '괴물 사냥꾼',
 '평범하지 않은 짐승을 처음 마주하고 끝낸 자.',
 'achievement',
 '{"achievement_template_id_prefix": "elite_unique_first_kill:", "first_only": true, "hook_target": "require_protagonist"}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "hunt", "value": 0.05}]}'::jsonb,
 'ic_monster_hunter',
 '8 유니크 엘리트 첫 처치 위업 중 첫 1회만 부여. hunt 한정 +5%p.');

-- 10. 이름을 알린 자 (a) - 명성 D 진입 hook (top_contributor_24h)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_renowned',
 '이름을 알린 자',
 '용병단의 명성을 처음 세상에 알린 자.',
 'achievement',
 '{"achievement_template_id": "reputation_rank:D", "hook_target": "top_contributor_24h"}'::jsonb,
 '{"effects": [{"type": "reputation_gain_modifier", "value": 0.03}]}'::jsonb,
 'ic_renowned',
 '명성 D 등급 진입 시 24h 누적 기여 1위 mercenary에게 부여. 명성 +3%.');

-- 11. 혼을 끊은 자 (a) - 엔드 칭호, 체인 완주 hook (require_protagonist)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_soul_severer',
 '혼을 끊은 자',
 '저주의 매듭을 끊고 망령의 굴레에서 자유롭게 한 자.',
 'achievement',
 '{"achievement_template_id": "chain_completed:chain_soul_severance", "hook_target": "require_protagonist"}'::jsonb,
 '{"effects": [{"type": "reputation_gain_modifier", "value": 0.05}, {"type": "mercenary_xp_bonus", "value": 0.10}]}'::jsonb,
 'ic_soul_severer',
 '저주 단절 체인 완주 protagonist에게 부여. 복합 효과: 명성 +5% + XP +10%.');

COMMIT;
