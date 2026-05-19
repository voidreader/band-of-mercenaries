-- M8b 페이즈 4 #2 — combat_skills 신설 + 16행 INSERT
-- FK: status_effect_id → combat_status_effects(id)
-- 마이그레이션: m8b_phase4_combat_skills

CREATE TABLE combat_skills (
  id TEXT PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('warrior','rogue','ranger','mage','support','specialist')),
  party_only BOOL NOT NULL DEFAULT false,
  trigger_kind TEXT NOT NULL CHECK (trigger_kind IN ('passive','active','triggered','on_hit','on_kill')),
  trigger_condition TEXT,
  action_cost TEXT NOT NULL CHECK (action_cost IN ('action','extraAction','passive')),
  cooldown_rounds INT NOT NULL DEFAULT 0,
  max_uses_per_combat INT,
  targeting_kind TEXT NOT NULL CHECK (targeting_kind IN ('self','single_enemy','single_ally','aoe_enemy','aoe_ally','party')),
  targeting_max_count INT,
  targeting_priority TEXT,
  multi_hit_count INT,
  skill_damage_multiplier NUMERIC,
  shield_block_bonus NUMERIC,
  crit_rate_bonus NUMERIC,
  status_effect_id TEXT REFERENCES combat_status_effects(id),
  status_effect_apply_chance NUMERIC,
  status_effect_intensity NUMERIC,
  status_effect_duration_turns INT,
  dispel_kind TEXT CHECK (dispel_kind IN ('debuff','buff','dot','debuff+dot')),
  dispel_max_count INT,
  display_label TEXT NOT NULL,
  description TEXT NOT NULL
);

-- 16행 INSERT (CSV 정확 매핑, 빈 값은 NULL)
INSERT INTO combat_skills (
  id, role, party_only, trigger_kind, trigger_condition, action_cost,
  cooldown_rounds, max_uses_per_combat, targeting_kind, targeting_max_count,
  targeting_priority, multi_hit_count, skill_damage_multiplier, shield_block_bonus,
  crit_rate_bonus, status_effect_id, status_effect_apply_chance,
  status_effect_intensity, status_effect_duration_turns,
  dispel_kind, dispel_max_count, display_label, description
) VALUES
(
  'skill_warrior_shield_bulwark', 'warrior', false, 'passive', NULL, 'passive',
  0, NULL, 'self', NULL,
  NULL, NULL, NULL, 0.10,
  NULL, NULL, NULL,
  NULL, NULL,
  NULL, NULL, '방패 보루', '피격 시 방패 막기 감소율 +10% 패시브.'
),
(
  'skill_warrior_battle_fury', 'warrior', false, 'triggered', 'self.hp <= maxHp * 0.5', 'extraAction',
  0, 1, 'self', NULL,
  NULL, NULL, NULL, NULL,
  NULL, 'buff_attack_up', 1.00,
  0.30, 3,
  NULL, NULL, '전투 분노', 'HP 50% 이하 자동 발동 분노. 공격력 +30% 3턴 (오버라이드).'
),
(
  'skill_rogue_mass_blind', 'rogue', false, 'active', NULL, 'action',
  3, NULL, 'aoe_enemy', 3,
  'front_row', NULL, 0.7, NULL,
  NULL, 'debuff_attack_down', 0.70,
  NULL, NULL,
  NULL, NULL, '광역 약화', '적 전열 3 대상 광역 약화. 피해 0.7×.'
),
(
  'skill_ranger_marksman_focus', 'ranger', false, 'triggered', 'self.isFirstInRound', 'action',
  4, NULL, 'self', NULL,
  NULL, NULL, NULL, NULL,
  0.15, 'buff_accuracy_up', 1.00,
  NULL, NULL,
  NULL, NULL, '정조준', '라운드 1순위 자동 발동. 명중 강화 + 치명타율 +15% (페이즈 1 #4 §1.5 hook 직접).'
),
(
  'skill_ranger_volley_shot', 'ranger', false, 'triggered', 'self.hasBuff(''buff_accuracy_up'')', 'action',
  3, NULL, 'single_enemy', NULL,
  NULL, 3, 0.65, NULL,
  NULL, NULL, NULL,
  NULL, NULL,
  NULL, NULL, '연속 사격', '정조준 콤보. 동일 대상 3회 연사. 회당 피해 0.65×.'
),
(
  'skill_mage_arcane_blast', 'mage', false, 'triggered', 'enemies.alive >= 2', 'action',
  3, NULL, 'aoe_enemy', 3,
  'random', NULL, 1.0, NULL,
  NULL, NULL, NULL,
  NULL, NULL,
  NULL, NULL, '광역 마법', '적 임의 3 대상 광역 마법. 피해 1.0×.'
),
(
  'skill_mage_stun_bolt', 'mage', false, 'triggered', 'enemies.any(isElite or highest_hp)', 'action',
  4, NULL, 'single_enemy', NULL,
  'highest_hp', NULL, 0.7, NULL,
  NULL, 'mez_stunned', 0.50,
  NULL, NULL,
  NULL, NULL, '기절 일격', '위협 적 단일 기절. 피해 0.7×.'
),
(
  'skill_support_aegis_aura', 'support', false, 'triggered', 'allies.none(hasBuff(''buff_defense_up''))', 'action',
  4, NULL, 'aoe_ally', NULL,
  NULL, NULL, NULL, NULL,
  NULL, 'buff_defense_up', 1.00,
  NULL, NULL,
  NULL, NULL, '수호의 오라', '아군 전원 방어력 강화.'
),
(
  'skill_support_cleansing_word', 'support', true, 'triggered', 'allies.any(hasDebuff or hasDot)', 'action',
  3, NULL, 'aoe_ally', NULL,
  NULL, NULL, NULL, NULL,
  NULL, NULL, NULL,
  NULL, NULL,
  'debuff+dot', 1, '정화의 외침', '아군 전원 디버프/DoT 각 1개 해제. 파티 전용.'
),
(
  'skill_specialist_adaptive_footwork', 'specialist', false, 'triggered', 'self.hp <= maxHp * 0.6 or self.incomingHighRisk', 'action',
  4, NULL, 'self', NULL,
  NULL, NULL, NULL, NULL,
  NULL, 'buff_evasion_up', 1.00,
  NULL, NULL,
  NULL, NULL, '임기응변', '위기 시 자가 회피 강화.'
),
(
  'skill_enemy_bleeding_cut', 'rogue', false, 'active', NULL, 'action',
  2, NULL, 'single_enemy', NULL,
  'lowest_hp', NULL, 1.2, NULL,
  NULL, 'dot_bleeding', 0.60,
  NULL, NULL,
  NULL, NULL, '출혈 베기', '적 전용. 단일 적 출혈 부여. 피해 1.2×.'
),
(
  'skill_enemy_armor_break', 'warrior', false, 'active', NULL, 'action',
  3, NULL, 'single_enemy', NULL,
  'highest_defense', NULL, 1.0, NULL,
  NULL, 'debuff_defense_down', 0.80,
  NULL, NULL,
  NULL, NULL, '갑옷 깨기', '적 전용. 방어 최고 대상 갑옷 깨기.'
),
(
  'skill_enemy_poison_bite', 'rogue', false, 'active', NULL, 'action',
  2, NULL, 'single_enemy', NULL,
  'lowest_hp', NULL, 0.8, NULL,
  NULL, 'dot_poisoned', 0.70,
  NULL, NULL,
  NULL, NULL, '독니 물기', '적 전용. 단일 대상 독 부여. 피해 0.8×.'
),
(
  'skill_enemy_taunt_roar', 'warrior', false, 'triggered', 'roundIndex == 1 or self.hp <= maxHp * 0.7', 'action',
  4, NULL, 'aoe_ally', NULL,
  NULL, NULL, NULL, NULL,
  NULL, 'debuff_attack_down', 0.60,
  0.15, NULL,
  NULL, NULL, '위협의 포효', '적 전용. 광역 위협으로 파티 공격력 약화 (오버라이드 0.15).'
),
(
  'skill_enemy_summon', 'mage', false, 'triggered', 'self.hp <= maxHp * 0.6', 'action',
  0, 1, 'self', NULL,
  NULL, NULL, NULL, NULL,
  NULL, NULL, NULL,
  NULL, NULL,
  NULL, NULL, '소환', '적 전용. HP 60% 이하 1회 발동. 부하 1~2명 소환.'
),
(
  'skill_enemy_self_dispel', 'mage', false, 'triggered', 'self.activeNegativeEffects >= 2', 'action',
  3, NULL, 'self', NULL,
  NULL, NULL, NULL, NULL,
  NULL, NULL, NULL,
  NULL, NULL,
  'debuff+dot', 1, '자기 정화', '적 전용. 자기 디버프/DoT 각 1개 해제.'
);
