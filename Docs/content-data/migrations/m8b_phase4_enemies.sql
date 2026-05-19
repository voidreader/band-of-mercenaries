-- M8b 페이즈 4 #2 — enemies 신설 + 26행 INSERT
-- FK: elite_monster_id → elite_monsters(id) (nullable)
-- 마이그레이션: m8b_phase4_enemies

CREATE TABLE enemies (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  enemy_kind TEXT NOT NULL CHECK (enemy_kind IN ('normal','elite','unique')),
  role TEXT NOT NULL CHECK (role IN ('warrior','rogue','ranger','mage','support','specialist')),
  tier INT NOT NULL,
  base_str INT NOT NULL,
  base_int INT NOT NULL,
  base_vit INT NOT NULL,
  base_agi INT NOT NULL,
  base_hp INT NOT NULL,
  base_attack INT NOT NULL,
  base_defense INT NOT NULL,
  behavior_pattern TEXT NOT NULL CHECK (behavior_pattern IN ('aggressive','opportunist','caster','supporter','defender','berserker')),
  skill_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  faction_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  ambush_compatible BOOL NOT NULL DEFAULT false,
  enemy_keyword_key TEXT,
  elite_monster_id TEXT REFERENCES elite_monsters(id),
  description TEXT NOT NULL
);

-- 26행 INSERT (CSV 정확 매핑)
INSERT INTO enemies (
  id, name, enemy_kind, role, tier,
  base_str, base_int, base_vit, base_agi,
  base_hp, base_attack, base_defense,
  behavior_pattern, skill_ids, environment_tags, faction_tags,
  ambush_compatible, enemy_keyword_key, elite_monster_id, description
) VALUES
(
  'enemy_bandit_thug', '도적 졸개', 'normal', 'warrior', 1,
  6, 2, 5, 5,
  69, 7, 16,
  'aggressive', '[]'::jsonb, '["forest","plains","mountain"]'::jsonb, '["faction_thieves_guild","faction_adventurers_guild","faction_merchants_alliance"]'::jsonb,
  true, 'bandit_remnants', NULL, '도적단의 말단 무리. 단순 돌격형 위협.'
),
(
  'enemy_bandit_scout', '도적 정찰꾼', 'normal', 'rogue', 2,
  6, 3, 6, 9,
  47, 8, 8,
  'opportunist', '[]'::jsonb, '["forest","plains","mountain"]'::jsonb, '["faction_thieves_guild","faction_adventurers_guild","faction_merchants_alliance"]'::jsonb,
  true, 'bandit_remnants', NULL, '도적단의 정찰조. 회피와 은신에 능하다.'
),
(
  'enemy_bandit_archer', '도적 궁수', 'normal', 'ranger', 2,
  5, 3, 6, 8,
  50, 6, 10,
  'opportunist', '[]'::jsonb, '["forest","plains","mountain"]'::jsonb, '["faction_thieves_guild","faction_adventurers_guild","faction_merchants_alliance"]'::jsonb,
  true, 'bandit_remnants', NULL, '원거리에서 표적을 노리는 도적 궁수.'
),
(
  'enemy_bandit_captain', '도적 두목', 'normal', 'warrior', 3,
  11, 4, 10, 7,
  119, 13, 23,
  'berserker', '["skill_warrior_battle_fury"]'::jsonb, '["forest","plains","mountain"]'::jsonb, '["faction_thieves_guild","faction_adventurers_guild","faction_merchants_alliance"]'::jsonb,
  true, 'bandit_remnants', NULL, '도적단의 우두머리. HP 50% 이하에서 분노 발동.'
),
(
  'enemy_bandit_assassin', '도적 암살자', 'normal', 'rogue', 3,
  9, 5, 7, 13,
  71, 11, 11,
  'opportunist', '["skill_enemy_bleeding_cut"]'::jsonb, '["forest","plains","mountain","ruined_castle"]'::jsonb, '["faction_thieves_guild","faction_merchants_alliance"]'::jsonb,
  true, 'bandit_remnants', NULL, '급소를 노리는 도적 암살자. 출혈 단일기 보유.'
),
(
  'enemy_graverobber_thug', '도굴꾼 졸개', 'normal', 'warrior', 2,
  8, 3, 6, 5,
  84, 10, 17,
  'aggressive', '[]'::jsonb, '["ruined_castle","dungeon"]'::jsonb, '["faction_deep_hammer","faction_sun_order"]'::jsonb,
  true, 'grave_robber_scouts', NULL, '폐허를 파헤치는 도굴꾼 말단.'
),
(
  'enemy_graverobber_captain', '도굴꾼 대장', 'normal', 'warrior', 3,
  11, 4, 9, 7,
  115, 13, 22,
  'berserker', '["skill_warrior_battle_fury","skill_enemy_armor_break"]'::jsonb, '["ruined_castle","dungeon"]'::jsonb, '["faction_deep_hammer","faction_sun_order"]'::jsonb,
  true, 'grave_robber_captain', NULL, '도굴꾼 우두머리. 거대 망치로 갑옷을 깬다.'
),
(
  'enemy_coast_raider', '해안 습격자', 'normal', 'rogue', 2,
  7, 3, 6, 9,
  47, 9, 8,
  'aggressive', '[]'::jsonb, '["sea_coast"]'::jsonb, '[]'::jsonb,
  true, 'coast_raiders', NULL, '해안에서 약탈하는 습격대 일원.'
),
(
  'enemy_coast_raider_lead', '해안 습격대장', 'normal', 'warrior', 3,
  11, 4, 9, 8,
  115, 13, 22,
  'berserker', '["skill_warrior_battle_fury"]'::jsonb, '["sea_coast"]'::jsonb, '[]'::jsonb,
  true, 'coast_raiders', NULL, '해안 습격대의 우두머리.'
),
(
  'enemy_swamp_tracker', '늪지 추적자', 'normal', 'ranger', 3,
  7, 5, 7, 11,
  56, 9, 12,
  'opportunist', '["skill_ranger_marksman_focus"]'::jsonb, '["swamp","mist_field"]'::jsonb, '[]'::jsonb,
  true, 'swamp_tracker', NULL, '늪지에 숨어 표적을 정조준한다.'
),
(
  'enemy_swamp_general', '늪지 사령관', 'normal', 'warrior', 4,
  14, 6, 12, 8,
  144, 17, 26,
  'defender', '["skill_warrior_shield_bulwark","skill_enemy_taunt_roar"]'::jsonb, '["swamp"]'::jsonb, '[]'::jsonb,
  false, 'swamp_tracker', NULL, '늪지 무리를 지휘하는 방패병. 위협의 포효로 파티 약화.'
),
(
  'enemy_dark_mage', '방랑 흑마법사', 'normal', 'mage', 3,
  4, 14, 7, 9,
  76, 17, 7,
  'caster', '["skill_mage_arcane_blast"]'::jsonb, '["ruined_castle","dungeon","swamp"]'::jsonb, '["faction_mage_towers","faction_forbidden_archive"]'::jsonb,
  false, 'contract_breakers', NULL, '광역 마법을 다루는 방랑 마법사.'
),
(
  'enemy_contract_breaker_mage', '계약 파기 마법사', 'normal', 'mage', 4,
  5, 17, 8, 11,
  87, 20, 8,
  'caster', '["skill_mage_arcane_blast","skill_mage_stun_bolt"]'::jsonb, '["ruined_castle","mountain","dungeon"]'::jsonb, '["faction_mage_towers","faction_forbidden_archive"]'::jsonb,
  false, 'contract_breakers', NULL, '상인 연합과의 계약을 깬 흑마법사. 광역·기절 마법.'
),
(
  'enemy_dark_priest', '악의 신관', 'normal', 'support', 3,
  5, 11, 8, 7,
  84, 11, 13,
  'supporter', '["skill_support_aegis_aura"]'::jsonb, '["ruined_castle","dungeon"]'::jsonb, '["faction_sun_order"]'::jsonb,
  false, NULL, NULL, '어둠을 따르는 신관. 광역 방어 강화로 적을 지원.'
),
(
  'enemy_ambush_spearman', '매복 창병', 'normal', 'warrior', 2,
  8, 3, 7, 6,
  88, 10, 19,
  'aggressive', '[]'::jsonb, '["forest","mountain","ruined_castle"]'::jsonb, '["faction_merchants_alliance","faction_adventurers_guild"]'::jsonb,
  true, 'ambush_spearmen', NULL, '호위 의뢰를 노리는 매복형 창병.'
),
(
  'enemy_ambush_archer', '매복 궁수', 'normal', 'ranger', 2,
  5, 3, 6, 9,
  50, 7, 10,
  'opportunist', '[]'::jsonb, '["forest","mountain","ruined_castle"]'::jsonb, '["faction_merchants_alliance","faction_adventurers_guild"]'::jsonb,
  true, 'ambush_spearmen', NULL, '매복하여 원거리 표적을 노리는 궁수.'
),
(
  'enemy_trial_beast', '시련관의 표식수', 'normal', 'specialist', 3,
  9, 4, 9, 8,
  86, 9, 17,
  'opportunist', '["skill_enemy_poison_bite"]'::jsonb, '["ruined_castle"]'::jsonb, '["faction_warriors_guild"]'::jsonb,
  false, 'trial_beast', NULL, '전사 길드의 시련관이 풀어둔 표식수. 약한 대상을 물어 독을 남긴다.'
),
(
  'enemy_elite_orc_warrior', '오크 대전사', 'elite', 'warrior', 2,
  17, 4, 13, 5,
  102, 20, 28,
  'berserker', '["skill_warrior_battle_fury","skill_enemy_armor_break"]'::jsonb, '["forest","mountain","plains"]'::jsonb, '["faction_deep_hammer","faction_warriors_guild"]'::jsonb,
  false, NULL, 'elite_orc_warrior', '오크 전사단의 정예. 분노 발동과 갑옷 깨기 결합.'
),
(
  'enemy_elite_goblin_raider', '고블린 습격자', 'elite', 'rogue', 2,
  12, 10, 8, 13,
  56, 13, 9,
  'opportunist', '["skill_rogue_mass_blind","skill_enemy_bleeding_cut"]'::jsonb, '["forest","underground","mountain"]'::jsonb, '["faction_merchants_alliance","faction_thieves_guild"]'::jsonb,
  false, 'goblin_raid_party', 'elite_goblin_raider', '고블린 습격대의 정예. 광역 약화와 출혈 결합.'
),
(
  'enemy_elite_undead_skeleton', '방랑 스켈레톤', 'elite', 'ranger', 2,
  7, 11, 5, 9,
  42, 8, 9,
  'aggressive', '["skill_ranger_volley_shot"]'::jsonb, '["ruined_castle","plains"]'::jsonb, '["faction_sun_order","faction_forbidden_archive"]'::jsonb,
  false, NULL, 'elite_undead_skeleton', '썩지 않은 망자. 연속 사격으로 압박한다.'
),
(
  'enemy_elite_beast_bear', '거대 곰', 'elite', 'warrior', 3,
  16, 4, 14, 7,
  144, 19, 29,
  'berserker', '["skill_warrior_battle_fury"]'::jsonb, '["forest","plains"]'::jsonb, '["faction_adventurers_guild","faction_warriors_guild"]'::jsonb,
  false, 'giant_forest_beast', 'elite_beast_bear', '숲 속의 거대 야수. 광폭화 일격으로 위협.'
),
(
  'enemy_elite_demon_imp', '작은 임프', 'elite', 'mage', 3,
  5, 17, 7, 9,
  67, 20, 7,
  'caster', '["skill_mage_arcane_blast","skill_enemy_summon"]'::jsonb, '["ruined_castle","swamp"]'::jsonb, '["faction_mage_towers"]'::jsonb,
  false, 'imp_swarm', 'elite_demon_imp', '마탑이 잘못 소환한 작은 악마. 잡몹 소환과 광역 마법.'
),
(
  'enemy_unique_wolf_ulbur', '늑대왕 울부르', 'unique', 'warrior', 2,
  18, 4, 14, 16,
  109, 22, 29,
  'berserker', '["skill_warrior_battle_fury","skill_enemy_taunt_roar"]'::jsonb, '["forest","mountain"]'::jsonb, '["faction_warriors_guild"]'::jsonb,
  false, NULL, 'elite_wolf_ulbur', 'M3 체인 핵심 적. 늑대 무리의 왕.'
),
(
  'enemy_unique_skeleton_general', '백골의 장군', 'unique', 'warrior', 3,
  18, 14, 11, 12,
  130, 22, 25,
  'defender', '["skill_warrior_shield_bulwark","skill_enemy_summon"]'::jsonb, '["ruined_castle","plains"]'::jsonb, '["faction_sun_order"]'::jsonb,
  false, NULL, 'elite_skeleton_general', 'M3 체인 핵심 적. 방패와 망자 소환으로 전선을 유지.'
),
(
  'enemy_unique_witch_morgan', '검은 마녀 모르간', 'unique', 'mage', 4,
  6, 28, 9, 14,
  95, 34, 8,
  'caster', '["skill_mage_arcane_blast","skill_mage_stun_bolt"]'::jsonb, '["forest","ruined_castle"]'::jsonb, '["faction_mage_towers"]'::jsonb,
  false, NULL, 'elite_witch_morgan', 'T4 데몬 유니크 마녀. 광역과 기절 결합.'
),
(
  'enemy_unique_lich_primordial', '태고의 리치', 'unique', 'mage', 5,
  7, 35, 18, 11,
  169, 42, 15,
  'caster', '["skill_mage_arcane_blast","skill_enemy_self_dispel"]'::jsonb, '["ruined_castle","dungeon"]'::jsonb, '["faction_forbidden_archive"]'::jsonb,
  false, 'lich_undead_legion', 'elite_lich_primordial', 'M8b 최종 보스급 유니크. 자기 정화로 디버프 무력화.'
);
