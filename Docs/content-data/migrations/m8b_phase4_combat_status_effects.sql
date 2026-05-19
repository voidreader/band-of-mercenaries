-- M8b 페이즈 4 #2 — combat_status_effects 신설 + 10행 INSERT
-- 마이그레이션: m8b_phase4_combat_status_effects

CREATE TABLE combat_status_effects (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('buff','debuff','mez','dot')),
  display_label TEXT NOT NULL,
  default_duration_turns INT NOT NULL,
  default_intensity NUMERIC NOT NULL,
  stack_policy TEXT NOT NULL CHECK (stack_policy IN ('refresh','stack','ignore')),
  hook_target JSONB NOT NULL,
  apply_method TEXT NOT NULL CHECK (apply_method IN ('multiplicative','additive','proportional','absolute','none')),
  description TEXT NOT NULL
);

INSERT INTO combat_status_effects (id, kind, display_label, default_duration_turns, default_intensity, stack_policy, hook_target, apply_method, description) VALUES
('buff_attack_up', 'buff', '공격력 강화', 2, 0.20, 'refresh', '["attack"]'::jsonb, 'multiplicative', '공격력을 곱셈으로 강화한다.'),
('buff_defense_up', 'buff', '방어력 강화', 3, 0.20, 'refresh', '["defense"]'::jsonb, 'multiplicative', '방어값을 곱셈으로 강화한다.'),
('buff_accuracy_up', 'buff', '명중 강화', 2, 0.15, 'refresh', '["hit"]'::jsonb, 'additive', '명중률을 가산으로 강화한다.'),
('buff_evasion_up', 'buff', '회피 강화', 2, 0.10, 'refresh', '["evasion"]'::jsonb, 'additive', '회피율을 가산으로 강화한다.'),
('debuff_attack_down', 'debuff', '공격력 약화', 2, 0.20, 'refresh', '["attack"]'::jsonb, 'multiplicative', '공격력을 곱셈으로 약화한다.'),
('debuff_defense_down', 'debuff', '방어력 약화', 3, 0.25, 'refresh', '["defense"]'::jsonb, 'multiplicative', '방어값을 곱셈으로 약화한다.'),
('debuff_accuracy_down', 'debuff', '명중 약화', 2, 0.10, 'refresh', '["hit"]'::jsonb, 'additive', '명중률을 가산으로 약화한다.'),
('mez_stunned', 'mez', '기절', 1, 1, 'refresh', '["action_skip"]'::jsonb, 'none', '행동 1회를 스킵한다. 회피·방어 판정은 정상.'),
('dot_bleeding', 'dot', '출혈', 3, 1, 'stack', '["round_end"]'::jsonb, 'proportional', '라운드 종료마다 maxHp×0.04×stack 비례 피해.'),
('dot_poisoned', 'dot', '중독', 3, 3, 'stack', '["round_start"]'::jsonb, 'absolute', '라운드 시작마다 intensity×5+level×2 절대 피해.');
