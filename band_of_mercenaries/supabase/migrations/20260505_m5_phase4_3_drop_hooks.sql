-- M5 페이즈 4 #3 마이그레이션 — 드롭 훅 데이터 + 이동 선택 이벤트 확장
-- 명세서: FR-13, FR-14, FR-15
-- 작성일: 2026-05-05
-- 선행: M5 페이즈 4 #1 완료 (quest_pool_material_drops 스키마 신설)

BEGIN;

-- ============================================================
-- §1 quest_pool_material_drops INSERT (17행 — FR-13)
-- ============================================================

-- UNIQUE(pool_id, item_id) 제약으로 인해 dustvile_chore_03/mat_herb_dust_resin
-- 2행(1.0 확정 + 0.2 보너스)을 qty_max=2로 병합 (16행)
INSERT INTO quest_pool_material_drops (pool_id, item_id, drop_rate, qty_min, qty_max) VALUES
  ('dustvile_chore_03', 'mat_herb_dry', 1.0, 1, 3),
  ('dustvile_chore_03', 'mat_herb_dust_resin', 1.0, 1, 2),
  ('dustvile_chore_05', 'mat_hide_dry_strap', 0.4, 1, 1),
  ('dustvile_chore_06', 'mat_ore_rusty_scrap', 1.0, 1, 1),
  ('dustvile_chore_10', 'mat_hide_dry_strap', 0.8, 1, 2),
  ('qp_dv_d1_scout', 'mat_ore_rusty_scrap', 0.6, 1, 1),
  ('qp_dv_d3_tool', 'mat_ore_rusty_scrap', 0.6, 1, 1),
  ('qp_dv_d4_rubble', 'mat_ore_rusty_scrap', 1.0, 1, 2),
  ('qp_dv_d5_check', 'mat_ore_rusty_scrap', 0.6, 1, 1),
  ('qp_dv_f3_dog', 'mat_hide_dry_strap', 0.8, 1, 2),
  ('qp_dv_f3_herb', 'mat_herb_dry', 1.0, 1, 2),
  ('qp_dv_f3_herb', 'mat_herb_mountain_mushroom', 0.5, 1, 1),
  ('qp_dv_f3_patrol', 'mat_hide_dry_strap', 0.5, 1, 1),
  ('qp_dv_r4_bandit', 'mat_hide_dry_strap', 0.8, 1, 2),
  ('qp_dv_r4_escort', 'mat_hide_dry_strap', 0.5, 1, 1),
  ('qp_dv_v2_supply', 'mat_hide_faded_cloth', 0.05, 1, 1);

-- ============================================================
-- §2 travel_choice_results.effect_type CHECK 제약 갱신 (FR-14)
-- 기존: 8종 — material_drop 미포함 → 9종으로 갱신
-- ============================================================

ALTER TABLE travel_choice_results DROP CONSTRAINT travel_choice_results_effect_type_check;
ALTER TABLE travel_choice_results ADD CONSTRAINT travel_choice_results_effect_type_check
  CHECK (effect_type IN ('gold', 'injury', 'heal_tired', 'reputation', 'trait_innate', 'trait_acquired', 'item', 'material_drop', 'nothing'));

-- ============================================================
-- §3 travel_choice_events INSERT (3행 — region 3 한정)
-- tce_dustvile_field_patrol  : encounter (들개 + 버섯 — 지역 조우 성격)
-- tce_dustvile_dungeon_pile  : discovery (폐광 짐 더미 발견)
-- tce_dustvile_road_traveler : dilemma  (호위 요청 or 도적 흔적)
-- ============================================================

INSERT INTO travel_choice_events (id, name, category, situation, min_tier, max_tier, weight, preferred_traits) VALUES
  ('tce_dustvile_field_patrol', '마른 초원 야간 순찰',
   'encounter',
   '마른 초원을 가로지르던 중 들개 발자국을 발견한다. 발자국 주변 바위틈에는 산기슭 버섯이 뭉쳐 자라고 있다.',
   1, 5, 1, NULL),
  ('tce_dustvile_dungeon_pile', '폐광길 짐 더미',
   'discovery',
   '폐광 입구 가까운 길목에 무거운 짐 더미가 방치돼 있다. 주인은 보이지 않고, 안에 무엇이 들었는지 알 수 없다.',
   1, 5, 1, NULL),
  ('tce_dustvile_road_traveler', '먼지 길 여행자 조우',
   'dilemma',
   '먼지 길에서 겁먹은 여행자를 만난다. 도적에게 쫓기고 있다며 호위를 부탁한다. 길 옆에는 최근 도적이 지나간 흔적도 남아 있다.',
   1, 5, 1, NULL);

-- ============================================================
-- §4 travel_choice_options INSERT (6행 — 이벤트당 2개)
-- ============================================================

INSERT INTO travel_choice_options (id, event_id, choice_index, label, visibility_expr, description, risk_level) VALUES
  ('tce_dustvile_field_patrol_o0', 'tce_dustvile_field_patrol', 0,
   '조용히 둘러본다', NULL,
   '들개를 자극하지 않고 바위틈 주변을 살핀다. 버섯을 챙길 수 있을지도 모른다.', 'safe'),
  ('tce_dustvile_field_patrol_o1', 'tce_dustvile_field_patrol', 1,
   '들개 발자국을 쫓는다', NULL,
   '발자국을 따라가 들개와 맞선다. 위험하지만 가죽끈을 얻을 수 있다.', 'risky'),
  ('tce_dustvile_dungeon_pile_o0', 'tce_dustvile_dungeon_pile', 0,
   '조심스레 살핀다', NULL,
   '짐 더미를 천천히 헤쳐 안전하게 내용물을 확인한다. 유물 파편이 있을 수도 있다.', 'safe'),
  ('tce_dustvile_dungeon_pile_o1', 'tce_dustvile_dungeon_pile', 1,
   '강제로 헤집는다', NULL,
   '짐 더미를 거칠게 뒤집는다. 쇳조각을 더 많이 건질 수 있지만 위험 부담이 있다.', 'risky'),
  ('tce_dustvile_road_traveler_o0', 'tce_dustvile_road_traveler', 0,
   '호위해 준다', NULL,
   '여행자를 안전한 곳까지 데려다 준다. 사례로 가죽끈 한 묶음을 받는다.', 'risky'),
  ('tce_dustvile_road_traveler_o1', 'tce_dustvile_road_traveler', 1,
   '도적 흔적을 살핀다', NULL,
   '호위 대신 길가의 도적 흔적을 조사한다. 빛바랜 천 조각이 남아 있을지도 모른다.', 'hidden');

-- ============================================================
-- §5 travel_choice_results INSERT (6행 — material_drop)
-- ============================================================

INSERT INTO travel_choice_results (id, option_id, result_index, probability, conditional_expr, narrative, effect_type, effect_magnitude, effect_target) VALUES
  ('tcr_dustvile_field_patrol_o0_r0', 'tce_dustvile_field_patrol_o0', 0, 1.0, NULL,
   '바위틈에서 산기슭 버섯을 발견했다.', 'material_drop', 1.0, 'mat_herb_mountain_mushroom'),
  ('tcr_dustvile_field_patrol_o1_r0', 'tce_dustvile_field_patrol_o1', 0, 1.0, NULL,
   '들개를 처리하고 마른 가죽끈을 건졌다.', 'material_drop', 1.0, 'mat_hide_dry_strap'),
  ('tcr_dustvile_dungeon_pile_o0_r0', 'tce_dustvile_dungeon_pile_o0', 0, 1.0, NULL,
   '짐 더미 속에서 정체 모를 유물 파편을 발견했다.', 'material_drop', 1.0, 'mat_relic_pyegwang_shard'),
  ('tcr_dustvile_dungeon_pile_o1_r0', 'tce_dustvile_dungeon_pile_o1', 0, 1.0, NULL,
   '위험을 무릅쓰고 쇳조각 두 개를 회수했다.', 'material_drop', 2.0, 'mat_ore_rusty_scrap'),
  ('tcr_dustvile_road_traveler_o0_r0', 'tce_dustvile_road_traveler_o0', 0, 1.0, NULL,
   '여행자 호위에 성공해 가죽끈 한 묶음을 받았다.', 'material_drop', 1.0, 'mat_hide_dry_strap'),
  ('tcr_dustvile_road_traveler_o1_r0', 'tce_dustvile_road_traveler_o1', 0, 1.0, NULL,
   '도적의 흔적에서 빛바랜 천 조각을 찾았다.', 'material_drop', 1.0, 'mat_hide_faded_cloth');

-- ============================================================
-- §6 data_versions UPDATE (4개 테이블 sync 버전 갱신)
-- ============================================================

UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'quest_pool_material_drops';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'travel_choice_events';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'travel_choice_options';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'travel_choice_results';

COMMIT;
