-- M5 페이즈 4 #1 마이그레이션 — 데이터 모델 확장 + 시드
-- 명세서: Docs/spec/[spec]20260504_M5_phase4_1_data-migration.md
-- 작성일: 2026-05-04
-- 선행: M4 페이즈 4 완료 (region 3 / settlement_3_pyegwang_reopen 활성)

BEGIN;

-- ============================================================
-- §5.1 스키마 확장
-- ============================================================

-- 1. items 테이블 확장 — region_exclusive 컬럼 + 인덱스 2종
ALTER TABLE items ADD COLUMN region_exclusive INTEGER NULL REFERENCES regions(id);
CREATE INDEX idx_items_region_exclusive ON items(region_exclusive)
  WHERE region_exclusive IS NOT NULL;
CREATE INDEX idx_items_category_slot ON items(category, slot);

-- items.category CHECK 제약 갱신 ('material' 추가)
-- 사전 조회 결과: 제약명 items_category_check 존재 확인 → DROP/ADD
ALTER TABLE items DROP CONSTRAINT items_category_check;
ALTER TABLE items ADD CONSTRAINT items_category_check
  CHECK (category IN ('personal_equipment', 'guild_equipment', 'consumable', 'material'));

-- items.slot CHECK 제약 갱신 (신규 material 슬롯 5종 추가)
-- 사전 조회 결과: 제약명 items_slot_check 존재 확인 → DROP/ADD (사용자 옵션 1 승인)
ALTER TABLE items DROP CONSTRAINT items_slot_check;
ALTER TABLE items ADD CONSTRAINT items_slot_check
  CHECK (slot IN (
    'weapon', 'armor', 'helmet', 'boots', 'accessory', 'banner', 'artifact',
    'essence_str', 'essence_int', 'essence_vit', 'essence_agi',
    'material_ore', 'material_hide', 'material_herb',
    'material_relic_fragment', 'material_monster_part'
  ));

-- region_discoveries.discovery_type CHECK 제약 갱신 ('normal' 추가)
-- 사전 조회 결과: 기존 5종(info/elite/hidden_quest/faction_clue/transform) → 6종 갱신 (사용자 옵션 A 승인)
ALTER TABLE region_discoveries DROP CONSTRAINT region_discoveries_discovery_type_check;
ALTER TABLE region_discoveries ADD CONSTRAINT region_discoveries_discovery_type_check
  CHECK (discovery_type IN ('info', 'elite', 'hidden_quest', 'faction_clue', 'transform', 'normal'));

-- 2. elite_loot_tables.drop_type — CHECK 제약 미존재 확인 (실 스키마 검증 완료)
-- ALTER 불필요. drop_type='material' INSERT 자유

-- 3. crafting_recipes 신규 테이블
CREATE TABLE crafting_recipes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  result_item_id TEXT NOT NULL REFERENCES items(id),
  result_quantity INT NOT NULL DEFAULT 1,
  inputs_json JSONB NOT NULL,
  unlock_condition_json JSONB,
  craft_location_id TEXT NOT NULL DEFAULT 'old_smithy',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_crafting_recipes_result_item ON crafting_recipes(result_item_id);

-- 4. quest_pool_material_drops 신규 매핑 테이블 (스키마만, INSERT는 페이즈 4 #3)
CREATE TABLE quest_pool_material_drops (
  id BIGSERIAL PRIMARY KEY,
  pool_id TEXT NOT NULL REFERENCES quest_pools(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items(id),
  drop_rate REAL NOT NULL CHECK (drop_rate >= 0 AND drop_rate <= 1),
  qty_min INT NOT NULL DEFAULT 1,
  qty_max INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(pool_id, item_id)
);
CREATE INDEX idx_qpmd_pool ON quest_pool_material_drops(pool_id);

-- 5. data_versions 행 추가 (sync 대상 등록)
INSERT INTO data_versions (table_name, version, updated_at) VALUES
  ('crafting_recipes', 1, now()),
  ('quest_pool_material_drops', 1, now());

-- ============================================================
-- §5.2 items INSERT (재료 10종 — 페이즈 1 #2)
-- ============================================================

INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json, flavor_text) VALUES
  ('mat_ore_rusty_scrap', '녹슨 쇳조각', 'material', 'material_ore', 1, NULL, '{}'::jsonb,
   '폐광 갱도에서 흩어진 평범한 쇳조각. 한때 곡괭이 끝이었거나 광차 부속이었을 것이다.'),
  ('mat_hide_dry_strap', '마른 가죽끈', 'material', 'material_hide', 1, NULL, '{}'::jsonb,
   '마른 초원 들개·도적 가방에서 풀린 짧은 가죽끈. 마을 어디서나 쓰인다.'),
  ('mat_herb_dry', '마른 약초', 'material', 'material_herb', 1, NULL, '{}'::jsonb,
   '마른 초원에 흔하게 자라는 잡초성 약초. 약초상의 가장 기본 재료.'),
  ('mat_herb_mountain_mushroom', '산기슭 버섯', 'material', 'material_herb', 1, NULL, '{}'::jsonb,
   '마른 초원 가장자리 바위틈에 무리 짓는 작은 버섯. 야간 순찰 중 자주 발견된다.'),
  ('mat_herb_dust_resin', '접착 수액', 'material', 'material_herb', 1, 3, '{}'::jsonb,
   '더스트플레인 특산 식물의 점착성 분비물. 먼지를 머금어 더 끈끈해진다.'),
  ('mat_hide_faded_cloth', '빛바랜 천 조각', 'material', 'material_hide', 2, NULL, '{}'::jsonb,
   '더스트빌 광장에 모인 잡동사니에서 풀린 오래된 천. 깃발의 원래 재질을 짐작케 한다.'),
  ('mat_relic_pyegwang_pickaxe_head', '녹슨 곡괭이 머리', 'material', 'material_ore', 2, 3, '{}'::jsonb,
   '폐광 깊숙이 박힌 채 부러진 곡괭이의 머리. 단단한 강철의 흔적.'),
  ('mat_relic_pyegwang_shard', '폐광의 유물 파편', 'material', 'material_relic_fragment', 2, 3, '{}'::jsonb,
   '폐광 안쪽에서 발견되는 정체 모를 고대 유물의 작은 조각. 마을 사람도 못 알아본다.'),
  ('mat_monster_giant_bat_fang', '거대 박쥐 송곳니', 'material', 'material_monster_part', 3, NULL, '{}'::jsonb,
   'step 3 박쥐 둥지의 우두머리에서 얻는 시그니처 트로피. 비정상적으로 크고 단단하다.'),
  ('mat_relic_ancient_seal_piece', '고대 인장 조각', 'material', 'material_relic_fragment', 3, 3, '{}'::jsonb,
   'step 6 폐광 재개방식에서 우연히 발굴되는 고대 인장의 일부. 마을 역사보다 오래된 것.');

-- ============================================================
-- §5.3 items INSERT (중간재 2종 — 페이즈 1 #3 §3-1·§3-2)
-- ============================================================

INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json, flavor_text) VALUES
  ('mat_hide_rough_bundle', '거친 가죽끈 묶음', 'material', 'material_hide', 2, NULL, '{}'::jsonb,
   '흩어진 마른 가죽끈을 정성껏 엮어 한 묶음으로 만든다. 더 큰 작업의 기초.'),
  ('mat_ore_polished_scrap', '연마된 쇳조각', 'material', 'material_ore', 2, NULL, '{}'::jsonb,
   '녹슨 쇳조각을 사포로 갈아 본래의 강철빛을 일부 되살린다. 단단한 무기 부속의 베이스가 된다.');

-- ============================================================
-- §5.4 items INSERT (결과물 8종 — 페이즈 2 #2)
-- ============================================================

INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json, flavor_text) VALUES
  ('item_banner_dustvile_repaired', '낡은 용병단 깃발', 'guild_equipment', 'banner', 2, 3,
   '{"reputation_gain_modifier": 0.04}'::jsonb,
   '광장의 잡동사니 더미에서 발견한 천을 풀고, 마른 가죽끈으로 깃대를 묶고, 접착 수액으로 마무리한다. 처음으로 휘날리는 용병단의 정체성.'),
  ('item_weapon_miner_dagger', '광부의 단검', 'personal_equipment', 'weapon', 2, NULL,
   '{"str": 3}'::jsonb,
   '폐광에서 회수한 곡괭이 머리를 단검 형태로 다듬고, 녹슨 쇳조각을 손잡이 보강에 쓴다. 광부의 단단한 손길이 칼날 끝에 묻어 있다.'),
  ('item_artifact_pyegwang_relic', '폐광의 유물 조각', 'guild_equipment', 'artifact', 3, 3,
   '{"recruit_high_tier_chance": 0.01, "gold_reward_multiplier": 0.02}'::jsonb,
   '폐광에서 모은 유물 파편을 거대 박쥐의 송곳니로 다듬고, 마지막 발굴된 고대 인장 조각으로 봉인한다. 마을의 첫 지역 아티팩트.'),
  ('item_armor_solid_piece', '단단한 갑옷 조각', 'personal_equipment', 'armor', 2, NULL,
   '{"vit": 3}'::jsonb,
   '녹슨 쇳조각을 가죽끈으로 묶어 즉석에서 만든 갑옷. 광부 출신 마을 사람들도 이 정도는 만들 수 있다고 한다.'),
  ('item_weapon_rusty_pickaxe', '녹슨 곡괭이', 'personal_equipment', 'weapon', 2, NULL,
   '{"vit": 3}'::jsonb,
   '곡괭이 머리를 그대로 살리고 새 자루를 박았다. 단검보다 둔하지만 한 방의 무게가 다르다.'),
  ('item_banner_herbalist_seal', '약초사 인장', 'guild_equipment', 'banner', 2, 3,
   '{"injury_rate_modifier": -0.04}'::jsonb,
   '약초사 네리스가 만들어준 인장. 마른 약초와 산기슭 버섯을 정제해 봉인했다. 부상자 회복이 한결 빠르다.'),
  ('item_accessory_herb_pouch', '약초 향낭', 'personal_equipment', 'accessory', 2, NULL,
   '{"vit": 2}'::jsonb,
   '마른 약초와 산기슭 버섯을 가죽 주머니에 담아 허리춤에 걸친다. 부상의 위험을 향기로 누른다.'),
  ('item_artifact_miner_charm', '광부의 부적', 'guild_equipment', 'artifact', 2, 3,
   '{"injury_rate_modifier": -0.03}'::jsonb,
   '폐광 깊은 곳에서 마을 노인이 건네준 부적. 작은 유물 파편이 쇳조각에 박혀 있다. 부상을 막아준다는 속설.');

-- ============================================================
-- §5.5 crafting_recipes INSERT (10행 — 페이즈 1 #3 §4)
-- ============================================================

INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order) VALUES
  ('recipe_dustvile_banner_repair', '낡은 용병단 깃발 복원', '천과 가죽끈, 접착 수액으로 깃발을 복원한다.',
   'item_banner_dustvile_repaired', 1,
   '[{"item_id":"mat_hide_dry_strap","quantity":3},{"item_id":"mat_herb_dust_resin","quantity":2},{"item_id":"mat_hide_faded_cloth","quantity":1}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 10),
  ('recipe_dustvile_miner_dagger', '광부의 단검', '폐광 곡괭이 머리를 단검으로 다듬는다.',
   'item_weapon_miner_dagger', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":3},{"item_id":"mat_hide_dry_strap","quantity":1},{"item_id":"mat_relic_pyegwang_pickaxe_head","quantity":1}]'::jsonb,
   '{"chain_step":{"chain_id":"settlement_3_pyegwang_reopen","step":1}}'::jsonb, 'old_smithy', 20),
  ('recipe_dustvile_pyegwang_relic', '폐광의 유물 조각', '유물 파편과 송곳니, 고대 인장으로 마을 아티팩트를 만든다.',
   'item_artifact_pyegwang_relic', 1,
   '[{"item_id":"mat_relic_pyegwang_shard","quantity":3},{"item_id":"mat_monster_giant_bat_fang","quantity":1},{"item_id":"mat_relic_ancient_seal_piece","quantity":1}]'::jsonb,
   '{"chain_step":{"chain_id":"settlement_3_pyegwang_reopen","step":6}}'::jsonb, 'old_smithy', 30),
  ('recipe_dustvile_hide_bundle', '거친 가죽끈 묶음', '마른 가죽끈을 정제하여 한 묶음으로 만든다.',
   'mat_hide_rough_bundle', 1,
   '[{"item_id":"mat_hide_dry_strap","quantity":3}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 100),
  ('recipe_dustvile_ore_polished', '연마된 쇳조각', '녹슨 쇳조각을 갈아 강철빛을 되살린다.',
   'mat_ore_polished_scrap', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":4}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 110),
  ('recipe_dustvile_armor_solid', '단단한 갑옷 조각', '녹슨 쇳조각과 가죽끈으로 갑옷을 만든다.',
   'item_armor_solid_piece', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":4},{"item_id":"mat_hide_dry_strap","quantity":2}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 40),
  ('recipe_dustvile_rusty_pickaxe', '녹슨 곡괭이', '곡괭이 머리에 새 자루를 박는다.',
   'item_weapon_rusty_pickaxe', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":2},{"item_id":"mat_relic_pyegwang_pickaxe_head","quantity":1},{"item_id":"mat_hide_dry_strap","quantity":1}]'::jsonb,
   '{"chain_step":{"chain_id":"settlement_3_pyegwang_reopen","step":1}}'::jsonb, 'old_smithy', 50),
  ('recipe_dustvile_herbalist_seal', '약초사 인장', '마른 약초와 버섯을 정제해 봉인한다.',
   'item_banner_herbalist_seal', 1,
   '[{"item_id":"mat_herb_dry","quantity":3},{"item_id":"mat_herb_mountain_mushroom","quantity":2},{"item_id":"mat_hide_dry_strap","quantity":1}]'::jsonb,
   '{"trust_level":3}'::jsonb, 'old_smithy', 60),
  ('recipe_dustvile_herb_pouch', '약초 향낭', '약초와 버섯을 가죽 주머니에 담는다.',
   'item_accessory_herb_pouch', 1,
   '[{"item_id":"mat_herb_dry","quantity":4},{"item_id":"mat_herb_mountain_mushroom","quantity":3},{"item_id":"mat_hide_dry_strap","quantity":2}]'::jsonb,
   '{"trust_level":3}'::jsonb, 'old_smithy', 70),
  ('recipe_dustvile_miner_charm', '광부의 부적', '폐광 유물 파편이 박힌 부적을 만든다.',
   'item_artifact_miner_charm', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":2},{"item_id":"mat_relic_pyegwang_shard","quantity":1}]'::jsonb,
   '{"first_acquired_item":"mat_relic_pyegwang_shard"}'::jsonb, 'old_smithy', 80);

-- ============================================================
-- §5.6 elite_monsters / elite_loot_tables INSERT (페이즈 2 #1 §1-3)
-- fixed_region_environments: 환경 태그 형식 ["mountain","dungeon"] 적용
-- (실 스키마 검증 완료 — 정수 배열 [3] 아님)
-- ============================================================

INSERT INTO elite_monsters (
  id, name, description, is_unique, type_family, tier, power, spawn_rate,
  duration_multiplier, environment_tags, fixed_region_environments,
  stat_weight, title, lore
) VALUES (
  'elite_giant_bat',
  '거대 박쥐',
  '폐광 갱도에 둥지를 튼 거대 박쥐 무리의 우두머리.',
  false,
  'beast',
  2,
  80,
  0.15,
  1.0,
  '["mountain", "dungeon"]'::jsonb,
  '["mountain", "dungeon"]'::jsonb,
  '{"agi": 0.4, "str": 0.4, "vit": 0.2}'::jsonb,
  '갱도의 우두머리',
  '폐광 깊숙이 둥지를 튼 거대 박쥐. 평범한 박쥐의 두 배 크기로, 송곳니가 비정상적으로 단단하다.'
);

INSERT INTO elite_loot_tables (id, elite_id, drop_type, item_id, drop_rate, rarity_grade, quantity)
VALUES ('elite_giant_bat_fang_drop', 'elite_giant_bat', 'material', 'mat_monster_giant_bat_fang', 1.0, 'rare', 1);

-- ============================================================
-- §5.7 region_discoveries INSERT (페이즈 2 #1 §1-2)
-- region 3 폐광 발견 3건 (knowledge 25/50/80)
-- ============================================================

INSERT INTO region_discoveries (
  id, region_id, knowledge_threshold, discovery_type, discovery_data, description
) VALUES
  ('disc_dustvile_pyegwang_normal', 3, 25, 'normal',
   '{"items":[{"item_id":"mat_ore_rusty_scrap","quantity":3,"drop_rate":1.0}]}'::jsonb,
   '폐광의 흔적 — 갱도 입구에서 녹슨 쇳조각을 발견했다.'),
  ('disc_dustvile_pyegwang_hidden', 3, 50, 'hidden_quest',
   '{"items":[{"item_id":"mat_relic_pyegwang_shard","quantity":1,"drop_rate":1.0},{"item_id":"mat_relic_pyegwang_pickaxe_head","quantity":1,"drop_rate":0.3}]}'::jsonb,
   '폐광 깊은 흔적 — 정체 모를 유물의 파편을 찾았다.'),
  ('disc_dustvile_pyegwang_deepest', 3, 80, 'hidden_quest',
   '{"items":[{"item_id":"mat_relic_ancient_seal_piece","quantity":1,"drop_rate":1.0}],"resettable":true}'::jsonb,
   '폐광 최심부 — 고대 인장의 일부가 봉인을 풀고 떨어진다.');

-- ============================================================
-- §5.8 chain_quests UPDATE (페이즈 2 #1 §1-5)
-- settlement_3_pyegwang_reopen 6 step의 reward_items JSONB 갱신
-- ============================================================

UPDATE chain_quests SET reward_items = '{"mat_relic_pyegwang_pickaxe_head":1,"mat_ore_rusty_scrap":1}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 1;
UPDATE chain_quests SET reward_items = '{"mat_hide_dry_strap":2}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 2;
-- step 3은 elite_loot_tables (#9)와 quest_pool drop hook으로 처리 — reward_items 빈 맵 유지
UPDATE chain_quests SET reward_items = '{}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 3;
UPDATE chain_quests SET reward_items = '{"mat_relic_pyegwang_pickaxe_head":1,"mat_herb_dust_resin":1}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 4;
UPDATE chain_quests SET reward_items = '{"mat_ore_rusty_scrap":3,"mat_relic_pyegwang_shard":1}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 5;
UPDATE chain_quests SET reward_items = '{"mat_relic_ancient_seal_piece":1,"mat_relic_pyegwang_shard":2}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 6;

-- ============================================================
-- §5.9 data_versions 갱신 (변경된 테이블 sync 감지)
-- ============================================================

UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'items';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'elite_monsters';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'elite_loot_tables';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'region_discoveries';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'chain_quests';

COMMIT;
