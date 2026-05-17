-- ====================================================================
-- M7 페이즈 3 산출물 5: 인프라 narrative + 체인 단계 + M5 신규 레시피
-- ====================================================================
--
-- 작성일: 2026-05-17
-- 마일스톤: M7 (지역 생활권 확장)
-- 페이즈: 3 #5 (페이즈 3 마지막)
-- 처리 방식: SQL 마이그레이션 형태. 페이즈 4 #4 spec 단계에서 일괄 적용
--
-- 본 스크립트 구성:
--   (A) items 6행 INSERT — M7 신규 6 레시피 결과 아이템 (placeholder effect_json)
--   (B) crafting_recipes 6행 INSERT — M7 신규 레시피 (M5 unlock_condition 확장)
--   (C) chain_quests 2행 INSERT — chain_m7_mist_clearing (페이즈 3 #3 hidden_quest 트리거 의존)
--   (D) 검증 DO 블록 3종
--
-- 적용 시점: 페이즈 4 #4 "마을 인프라 성장 시스템 + 진입점 통합" spec 단계에서
--   CraftingService.evaluateState() unlock_condition 분기 추가 + ChainQuestService trigger 정합 후
--   본 마이그레이션 일괄 적용 (게임 동작 시점 일치)
-- ====================================================================


-- ====================================================================
-- (A) items 6행 INSERT — M7 신규 6 레시피 결과 아이템
-- ====================================================================
--
-- 페이즈 1 #3 4절 명시 카테고리:
--   - 야수 가죽 도구: personal_equipment T2 weapon
--   - 들꽃 약초 향료: consumable T1
--   - 유목민 가죽 장비: personal_equipment T2 armor
--   - 해안 약물: consumable T1
--   - 안개 늪 인장 장신구: guild_equipment T2 artifact
--   - 부서진 요새 인장 장비: guild_equipment T3 artifact
--
-- effect_json은 페이즈 4 #4 spec 단계에서 최종 확정 — 본 산출물은 placeholder

INSERT INTO items (id, name, description, flavor_text, category, slot, tier, effect_json, region_exclusive) VALUES
('equip_weapon_beast_tool', '야수 가죽 도구', 'weapon / STR +3 (placeholder)', '외곽 숲의 거대 야수 송곳니로 다듬은 단검. 가죽 작업 + 근접 무기 겸용.', 'personal_equipment', 'weapon', 2, '{"str":3}'::jsonb, NULL),
('cons_wildflower_oil', '들꽃 약초 향료', 'consumable / 임시 회복 (placeholder)', '도적길 들꽃 향유. 잠깐의 휴식과 함께 마음을 진정시킨다.', 'consumable', 'consumable', 1, '{}'::jsonb, NULL),
('equip_armor_nomad', '유목민 가죽 장비', 'armor / VIT +3 (placeholder)', '변방 해안 유목민이 직접 무두질한 가죽으로 만든 흉갑. 거친 모래바람을 막는다.', 'personal_equipment', 'armor', 2, '{"vit":3}'::jsonb, NULL),
('cons_seaweed_tonic', '해안 약물', 'consumable / 임시 회복 (placeholder)', '해초 약재로 끓인 강장제. 바닷바람의 짠 향이 코끝을 찌른다.', 'consumable', 'consumable', 1, '{}'::jsonb, NULL),
('guild_artifact_swamp_seal', '안개 늪 인장 장신구', 'artifact / 명성+7% (placeholder)', '회색 늪지 깊은 곳에서 건진 인장의 조각. 안개 너머의 무언가가 새겨져 있다.', 'guild_equipment', 'artifact', 2, '{"reputation_gain_modifier":0.07}'::jsonb, NULL),
('guild_artifact_burnt_seal', '부서진 요새 인장 장비', 'artifact / 고티어 모집+3% (placeholder)', '부서진 요새의 잿더미에서 발굴된 검은 인장. 옛 서약의 무게가 손에 남는다.', 'guild_equipment', 'artifact', 3, '{"recruit_high_tier_chance":0.03}'::jsonb, NULL);


-- ====================================================================
-- (B) crafting_recipes 6행 INSERT — M7 신규 레시피
-- ====================================================================
--
-- M5 unlock_condition_json 확장 (페이즈 1 #3 4절 + 페이즈 2 #3):
--   기존 (M5): {"trust_level": N} / {"chain_step": {...}} / {"first_acquired_item": "..."}
--   신규 (M7): {"type": "regionFlag", "flag": "..."} / {"type": "all", "conditions": [...]}
--
-- CraftingService.evaluateState() 분기 추가 페이즈 4 #4 spec 의존.
-- M5 기존 10행은 변경 없음 (type 필드 없음 → M5 기존 분기 처리).

-- Tier 2: 야수 가죽 도구 (region 9 야수 처치 hook)
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order)
VALUES ('recipe_m7_beast_tool', '야수 가죽 도구', '외곽 숲의 거대 야수 송곳니로 다듬은 단검과 가죽 도구', 'equip_weapon_beast_tool', 1,
  '[{"item_id":"mat_monster_beast_fang","quantity":1},{"item_id":"mat_hide_rough_bundle","quantity":2}]'::jsonb,
  '{"type":"regionFlag","flag":"region_9_giant_beast_killed"}'::jsonb,
  'old_smithy', 100);

-- Tier 2: 들꽃 약초 향료 (region 31 shrine 완주 hook)
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order)
VALUES ('recipe_m7_wildflower_oil', '들꽃 약초 향료', '도적길 들꽃과 마른 약초를 섞어 만든 향유', 'cons_wildflower_oil', 1,
  '[{"item_id":"mat_herb_wildflower","quantity":3},{"item_id":"mat_herb_dry","quantity":2}]'::jsonb,
  '{"type":"regionFlag","flag":"region_31_shrine_quest_completed"}'::jsonb,
  'old_smithy', 101);

-- Tier 3: 유목민 가죽 장비 (region 127 친교 + infraTier 3 복합)
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order)
VALUES ('recipe_m7_nomad_armor', '유목민 가죽 장비', '유목민 가죽끈과 빛바랜 천을 엮어 만든 흉갑', 'equip_armor_nomad', 1,
  '[{"item_id":"mat_hide_nomad_strap","quantity":3},{"item_id":"mat_hide_faded_cloth","quantity":1}]'::jsonb,
  '{"type":"all","conditions":[{"type":"infrastructureTier","value":3},{"type":"regionFlag","flag":"region_127_nomad_friendly"}]}'::jsonb,
  'old_smithy', 102);

-- Tier 3: 해안 약물 (region 127 친교 hook)
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order)
VALUES ('recipe_m7_seaweed_tonic', '해안 약물', '해초 약재와 산기슭 버섯을 끓여 만든 강장제', 'cons_seaweed_tonic', 1,
  '[{"item_id":"mat_herb_seaweed","quantity":2},{"item_id":"mat_herb_mountain_mushroom","quantity":2}]'::jsonb,
  '{"type":"regionFlag","flag":"region_127_nomad_friendly"}'::jsonb,
  'old_smithy', 103);

-- Tier 3: 안개 늪 인장 장신구 (region 146 안개 해소 hook)
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order)
VALUES ('recipe_m7_swamp_seal', '안개 늪 인장 장신구', '회색 늪지 인장 조각과 독초·거친 가죽끈을 조합', 'guild_artifact_swamp_seal', 1,
  '[{"item_id":"mat_relic_swamp_seal","quantity":2},{"item_id":"mat_herb_poison","quantity":1},{"item_id":"mat_hide_rough_bundle","quantity":1}]'::jsonb,
  '{"type":"regionFlag","flag":"region_146_mist_cleared"}'::jsonb,
  'old_smithy', 104);

-- Tier 4: 부서진 요새 인장 장비 (region 38 ironbound + infraTier 4 복합)
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order)
VALUES ('recipe_m7_burnt_seal', '부서진 요새 인장 장비', '탄 인장 파편·연마된 쇳조각·고대 인장 조각의 결합', 'guild_artifact_burnt_seal', 1,
  '[{"item_id":"mat_relic_burnt_seal","quantity":2},{"item_id":"mat_ore_polished_scrap","quantity":2},{"item_id":"mat_relic_ancient_seal_piece","quantity":1}]'::jsonb,
  '{"type":"all","conditions":[{"type":"infrastructureTier","value":4},{"type":"regionFlag","flag":"region_38_ironbound_pact_completed"}]}'::jsonb,
  'old_smithy', 105);


-- ====================================================================
-- (C) chain_quests 2행 INSERT — chain_m7_mist_clearing
-- ====================================================================
--
-- 페이즈 3 #3 region_discoveries rdsc_m7_r146_mist_omen (knowledge=85, hidden_quest)
-- 트리거 의존. 안개 사건 해소 단발 -50 (페이즈 2 #2 특수 단발).
--
-- 1단계: 안개 정찰 — region 146 내부
-- 2단계: 안개의 야수 추적 — 안개 해소 (최종 보상)

INSERT INTO chain_quests (id, chain_id, chain_name, step, total_steps, region_id, target_region_id, target_sector_id, name, description, quest_type_id, difficulty, combat_power, reward_gold, reward_xp, reward_items, final_reward, final_reputation_bonus, duration_seconds, next_step_delay_seconds, faction_tag_id) VALUES
('chain_m7_mist_clearing_s1', 'chain_m7_mist_clearing', '회색 늪지 안개 해소', 1, 2, 146, 146, NULL,
  '안개 속 정찰', '늪의 안개가 평소보다 짙어졌다는 보고가 있어. 안개 사이로 무언가 움직인다지만 정체는 모르겠어. 가까이서 확인만 해와도 충분해.',
  'explore', 2, 30, 120, 80,
  '{"mat_herb_poison":1,"mat_relic_swamp_seal":1}'::jsonb,
  false, NULL, 360, 600, NULL),

('chain_m7_mist_clearing_s2', 'chain_m7_mist_clearing', '회색 늪지 안개 해소', 2, 2, 146, 146, NULL,
  '안개의 야수 추적', '안개 속에서 움직이던 게 짐승이었어. 야수가 늪의 인장을 흩어놓아 안개가 짙어진 거였지. 야수를 처리하면 안개도 가라앉을 거야. 끝까지 가서 매듭을 짓자.',
  'hunt', 3, 50, 250, 200,
  '{"mat_relic_swamp_seal":2,"mat_herb_poison":1,"mat_hide_rough_bundle":1}'::jsonb,
  true, 200, 540, 0, NULL);


-- ====================================================================
-- (D) 검증 DO 블록
-- ====================================================================

-- D1: items 6행 INSERT 검증
DO $$
DECLARE v_n INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_n FROM items WHERE id IN (
    'equip_weapon_beast_tool', 'cons_wildflower_oil', 'equip_armor_nomad',
    'cons_seaweed_tonic', 'guild_artifact_swamp_seal', 'guild_artifact_burnt_seal'
  );
  IF v_n <> 6 THEN
    RAISE EXCEPTION 'M7 신규 6 아이템 INSERT 검증 실패: % 행', v_n;
  END IF;
END $$;

-- D2: crafting_recipes 6행 INSERT 검증 + unlock_condition_json type 확인
DO $$
DECLARE v_n INTEGER; v_invalid INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_n FROM crafting_recipes WHERE id LIKE 'recipe_m7_%';
  IF v_n <> 6 THEN
    RAISE EXCEPTION 'M7 신규 6 레시피 INSERT 검증 실패: % 행', v_n;
  END IF;

  SELECT COUNT(*) INTO v_invalid FROM crafting_recipes
    WHERE id LIKE 'recipe_m7_%'
      AND unlock_condition_json->>'type' NOT IN ('regionFlag', 'all', 'infrastructureTier');
  IF v_invalid > 0 THEN
    RAISE EXCEPTION 'M7 unlock_condition_json.type 검증 실패: % 행', v_invalid;
  END IF;
END $$;

-- D3: chain_m7_mist_clearing 2단계 검증
DO $$
DECLARE v_n INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_n FROM chain_quests WHERE chain_id = 'chain_m7_mist_clearing';
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'chain_m7_mist_clearing 2단계 검증 실패: % 행', v_n;
  END IF;

  -- final_reward=true 검증 (step 2 = final)
  IF NOT EXISTS (SELECT 1 FROM chain_quests WHERE chain_id = 'chain_m7_mist_clearing' AND step = 2 AND final_reward = true) THEN
    RAISE EXCEPTION 'chain_m7_mist_clearing step 2 final_reward 검증 실패';
  END IF;
END $$;


-- ====================================================================
-- 적용 후 후속 작업 (수동)
-- ====================================================================
--
-- 1. data_versions 갱신:
--    UPDATE data_versions SET version = version + 1 WHERE table_name IN ('items', 'crafting_recipes', 'chain_quests');
--
-- 2. 페이즈 4 #4 spec 단계 구현:
--    - CraftingService.evaluateState() 신규 type 분기 (regionFlag / all / infrastructureTier)
--    - 페이즈 4 #4 SettlementInfrastructureConfig 코드 상수 적용
--    - 신규 6 아이템 effect_json 최종 확정 (placeholder 대체)
--    - chain_m7_mist_clearing oneshot trigger — region 146 dangerScore -50 (페이즈 2 #2 특수 단발)
--
-- ====================================================================
