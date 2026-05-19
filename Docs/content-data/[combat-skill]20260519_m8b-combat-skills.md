# M8b 전투 스킬 16행 시드 데이터

> 작성일: 2026-05-19
> 유형: 데이터 생성 (M8b 마일스톤 — 페이즈 3 산출물 2/4)
> 선행 기획서:
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1 + 코덱스 보완) — 파티 10 스킬 + §10 데이터 구조
> - `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2 + 코덱스 보완) §5 — 적 전용 6 스킬
> - `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md` (페이즈 2 #3) — applyChance/intensity/duration 권고 + §6 오버라이드 매트릭스
> - `Docs/content-data/[enemy]20260519_m8b-enemies.csv` (페이즈 3 #1) — `skill_ids` JSONB가 참조하는 스킬 풀
> 페어 CSV: `[combat-skill]20260519_m8b-combat-skills.csv` (16 시드 데이터)
> 신규 테이블: `combat_skills` (M8b 신규)
>
> 후속:
> - 페이즈 3 #3 `combat_status_effects` 10행 시드 (`status_effect_id` FK)
> - 페이즈 3 #4 `combat_report_templates` 85행 (`tags_json.skill_id` 참조)
> - 페이즈 4 #2 `CombatSkill` freezed 모델 명세

## 개요

본 산출물은 페이즈 2 #1 파티 10 스킬 + 페이즈 2 #2 §5 적 전용 6 스킬 = **총 16 스킬**을 `combat_skills` 신규 테이블에 시드한다. 페이즈 2 #1 §10.1 권장 컬럼 23개를 그대로 사용한다.

코덱스 보완 반영:
- 파티 측 `skill_specialist_adaptive_footwork` 신규 추가 (specialist 1종 — `buff_evasion_up` 활성)
- 적 측 `skill_enemy_bleeding_cut` 신규 추가 (rogue 출혈 단일기 적 전용 분리)

## 신규 테이블 DDL

```sql
CREATE TABLE IF NOT EXISTS combat_skills (
  id                              TEXT PRIMARY KEY,
  role                            TEXT NOT NULL,
  party_only                      BOOLEAN NOT NULL DEFAULT FALSE,
  trigger_kind                    TEXT NOT NULL,
  trigger_condition               TEXT NULL,
  action_cost                     TEXT NOT NULL,
  cooldown_rounds                 INT  NOT NULL DEFAULT 0,
  max_uses_per_combat             INT  NULL,
  targeting_kind                  TEXT NOT NULL,
  targeting_max_count             INT  NULL,
  targeting_priority              TEXT NULL,
  multi_hit_count                 INT  NULL,
  skill_damage_multiplier         NUMERIC NULL,
  shield_block_bonus              NUMERIC NULL,
  crit_rate_bonus                 NUMERIC NULL,
  status_effect_id                TEXT NULL,
  status_effect_apply_chance      NUMERIC NULL,
  status_effect_intensity         NUMERIC NULL,
  status_effect_duration_turns    INT  NULL,
  dispel_kind                     TEXT NULL,
  dispel_max_count                INT  NULL,
  display_label                   TEXT NOT NULL,
  description                     TEXT NOT NULL DEFAULT '',

  CONSTRAINT combat_skills_role_check         CHECK (role IN ('warrior','rogue','ranger','mage','support','specialist')),
  CONSTRAINT combat_skills_trigger_check      CHECK (trigger_kind IN ('passive','active','triggered','on_hit','on_kill')),
  CONSTRAINT combat_skills_action_check       CHECK (action_cost IN ('action','extraAction','passive')),
  CONSTRAINT combat_skills_target_check       CHECK (targeting_kind IN ('self','single_enemy','single_ally','aoe_enemy','aoe_ally','party')),
  CONSTRAINT combat_skills_dispel_check       CHECK (dispel_kind IS NULL OR dispel_kind IN ('debuff','buff','dot','debuff+dot')),
  CONSTRAINT combat_skills_cooldown_check     CHECK (cooldown_rounds >= 0),
  CONSTRAINT combat_skills_multi_hit_check    CHECK (multi_hit_count IS NULL OR multi_hit_count >= 1),
  CONSTRAINT combat_skills_intensity_clamp    CHECK (status_effect_intensity IS NULL OR (status_effect_intensity >= 0.0 AND status_effect_intensity <= 1.0)),
  CONSTRAINT combat_skills_apply_chance_clamp CHECK (status_effect_apply_chance IS NULL OR (status_effect_apply_chance >= 0.0 AND status_effect_apply_chance <= 1.0))
);

CREATE INDEX IF NOT EXISTS idx_combat_skills_role        ON combat_skills(role);
CREATE INDEX IF NOT EXISTS idx_combat_skills_party_only  ON combat_skills(party_only);
CREATE INDEX IF NOT EXISTS idx_combat_skills_status_fk   ON combat_skills(status_effect_id) WHERE status_effect_id IS NOT NULL;

INSERT INTO data_versions (table_name, version) VALUES ('combat_skills', 1)
ON CONFLICT (table_name) DO UPDATE SET version = data_versions.version + 1;
```

### 후속 FK 제약 (페이즈 3 #3 시드 이후 ALTER)

```sql
-- 페이즈 3 #3 combat_status_effects 시드 완료 후 실행
ALTER TABLE combat_skills
  ADD CONSTRAINT combat_skills_status_effect_fk
  FOREIGN KEY (status_effect_id) REFERENCES combat_status_effects(id);

-- 페이즈 3 #2 완료 후 페이즈 3 #1 enemies.skill_ids 검증 ALTER 실행
ALTER TABLE enemies
  ADD CONSTRAINT enemies_skill_ids_valid
  CHECK (
    NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements_text(skill_ids) AS sk
      WHERE NOT EXISTS (SELECT 1 FROM combat_skills cs WHERE cs.id = sk)
    )
  );
```

## 16 시드 분포

### role 분포

| role | 파티 측 | 적 전용 | 합계 |
|------|--------|--------|------|
| warrior | 2 (shield_bulwark, battle_fury) | 2 (armor_break, taunt_roar) | 4 |
| rogue | 1 (mass_blind) | 2 (bleeding_cut, poison_bite) | 3 |
| ranger | 2 (marksman_focus, volley_shot) | 0 | 2 |
| mage | 2 (arcane_blast, stun_bolt) | 2 (summon, self_dispel) | 4 |
| support | 2 (aegis_aura, cleansing_word) | 0 | 2 |
| specialist | 1 (adaptive_footwork) | 0 | 1 |
| 합계 | 10 | 6 | **16** |

`party_only=TRUE`는 1행 (`skill_support_cleansing_word`). 나머지 15행은 적 측 사용 가능.

### trigger_kind 분포

| trigger_kind | 수 | 활용 |
|-------------|----|------|
| passive | 1 | shield_bulwark (피격 시 자동) |
| active | 4 | mass_blind, bleeding_cut, armor_break, poison_bite |
| triggered | 11 | 조건 자동 발동 |
| on_hit | 0 | MVP 미사용 |
| on_kill | 0 | MVP 미사용 |

### action_cost 분포

| action_cost | 수 | 활용 |
|------------|----|------|
| action | 14 | 행동 슬롯 소모 |
| extraAction | 1 | battle_fury (추가 행동) |
| passive | 1 | shield_bulwark |

### targeting_kind 분포

| targeting_kind | 수 |
|--------------|----|
| self | 5 |
| single_enemy | 5 |
| aoe_enemy | 2 |
| aoe_ally | 3 |
| 합계 | 15 (summon은 self) |

페이즈 1 #2 §7 진형 표적 정책 정합. 광역 표적 5개(aoe_enemy 2 + aoe_ally 3).

### 상태 효과 매트릭스

| 스킬 | status_effect_id | apply_chance | intensity 컬럼 | duration 컬럼 |
|------|----------------|--------------|--------------|-------------|
| skill_warrior_battle_fury | buff_attack_up | 1.00 | **0.30 (오버라이드)** | **3 (오버라이드)** |
| skill_rogue_mass_blind | debuff_attack_down | 0.70 | NULL (default 0.20) | NULL (default 2) |
| skill_ranger_marksman_focus | buff_accuracy_up | 1.00 | NULL (default 0.15) | NULL (default 2) |
| skill_mage_stun_bolt | mez_stunned | 0.50 | NULL (default 1) | NULL (default 1) |
| skill_support_aegis_aura | buff_defense_up | 1.00 | NULL (default 0.20) | NULL (default 3) |
| skill_specialist_adaptive_footwork | buff_evasion_up | 1.00 | NULL (default 0.10) | NULL (default 2) |
| skill_enemy_bleeding_cut | dot_bleeding | 0.60 | NULL (default stack 1) | NULL (default 3) |
| skill_enemy_armor_break | debuff_defense_down | 0.80 | NULL (default 0.25) | NULL (default 3) |
| skill_enemy_poison_bite | dot_poisoned | 0.70 | NULL (default stack 1) | NULL (default 3) |
| skill_enemy_taunt_roar | debuff_attack_down | 0.60 | **0.15 (오버라이드)** | NULL (default 2) |

**오버라이드 정책**: NULL=카탈로그 default 사용 / non-null=스킬 오버라이드. 페이즈 2 #3 §6 정합 — 일치 8 스킬 / 오버라이드 2 스킬(battle_fury 0.30/3턴, taunt_roar 0.15).

### 페이즈 1 #3 산식 결합 매트릭스

| 스킬 | skill_damage_multiplier | shield_block_bonus | crit_rate_bonus |
|------|------------------------|-------------------|----------------|
| skill_warrior_shield_bulwark | — | 0.10 | — |
| skill_warrior_battle_fury | — | — | — |
| skill_rogue_mass_blind | 0.7 | — | — |
| skill_ranger_marksman_focus | — | — | 0.15 |
| skill_ranger_volley_shot | 0.65 (회당, multi_hit=3) | — | — |
| skill_mage_arcane_blast | 1.0 | — | — |
| skill_mage_stun_bolt | 0.7 | — | — |
| skill_enemy_bleeding_cut | 1.2 | — | — |
| skill_enemy_armor_break | 1.0 | — | — |
| skill_enemy_poison_bite | 0.8 | — | — |

페이즈 1 #3 §5.1 `skillDamageMultiplier` hook + §4.3 `shieldBlockMitigation` + §7 `statusEffectCritMod` 직접 표현(`marksman_focus`).

### dispel 매트릭스

| 스킬 | dispel_kind | dispel_max_count | 표적 |
|------|------------|-----------------|------|
| skill_support_cleansing_word | debuff+dot | 1 | aoe_ally (파티 전용) |
| skill_enemy_self_dispel | debuff+dot | 1 | self |

페이즈 1 #4 §8.2 dispel 분류 정합. `mez_stunned`는 dispel 불가 (MVP 정책).

### max_uses_per_combat (전투당 1회 제한)

| 스킬 | max_uses |
|------|---------|
| skill_warrior_battle_fury | 1 (HP 50% 트리거 자동) |
| skill_enemy_summon | 1 (HP 60% 트리거 자동) |
| 나머지 14 | NULL (쿨다운만 제어) |

### multi_hit_count

| 스킬 | multi_hit |
|------|---------|
| skill_ranger_volley_shot | 3 (동일 대상 3 연사) |
| 나머지 15 | NULL |

페이즈 1 #2 §9.2 연속 공격 정합.

## 페이즈 3 #1 enemies.skill_ids 검증

페이즈 3 #1 `[enemy]20260519_m8b-enemies.csv`의 26행이 참조하는 스킬 ID:

| skill_id | 참조 횟수 | 본 시드 정의 여부 |
|----------|---------|----------------|
| skill_warrior_shield_bulwark | 2 | O |
| skill_warrior_battle_fury | 6 | O |
| skill_rogue_mass_blind | 1 | O |
| skill_enemy_bleeding_cut | 2 | O (코덱스 보완) |
| skill_ranger_marksman_focus | 1 | O |
| skill_ranger_volley_shot | 1 | O |
| skill_mage_arcane_blast | 5 | O |
| skill_mage_stun_bolt | 2 | O |
| skill_support_aegis_aura | 1 | O |
| skill_enemy_armor_break | 2 | O |
| skill_enemy_poison_bite | 1 | O |
| skill_enemy_taunt_roar | 2 | O |
| skill_enemy_summon | 2 | O |
| skill_enemy_self_dispel | 1 | O |

14 스킬 / 26 적 활용. 본 시드 16행 중 enemies 미참조 2 스킬:
- `skill_support_cleansing_word` (party_only=TRUE, 파티 전용)
- `skill_specialist_adaptive_footwork` (party_only=TRUE, 파티 전용)

## 결정성 시드 정합

페이즈 1 #1 §결정성 / 페이즈 1 #4 §10 PRNG 분리 정합. 본 시드의 `status_effect_apply_chance`는 페이즈 1 #4 §10 `applyRoll`이 동일 시드에서 동일 결과 보장.

## 데이터 사용 가이드

### Supabase 적용 순서

1. `combat_skills` 테이블 DDL 실행 (위 SQL 블록)
2. CSV 파일 (`[combat-skill]20260519_m8b-combat-skills.csv`)을 operation-bom 또는 Supabase Dashboard에서 import
3. 페이즈 3 #3 `combat_status_effects` 시드 완료 후 `combat_skills_status_effect_fk` FK ALTER 실행
4. 페이즈 3 #1 `enemies.skill_ids` 검증 ALTER 실행 (`enemies_skill_ids_valid` CHECK)
5. `data_versions` 테이블에 `combat_skills` 버전 등록 (DDL에 포함됨)
6. 클라이언트 SyncService에 `combat_skills`를 `allTables`에 추가 (페이즈 4 #2 명세)

## 후속 입력 매트릭스

| 후속 산출물 | 본 시드의 입력 기여 |
|-----------|--------------------|
| 페이즈 3 #3 `combat_status_effects` 시드 | 본 시드의 `status_effect_id` 9 unique ID(buff_attack_up/buff_defense_up/buff_accuracy_up/buff_evasion_up/debuff_attack_down/debuff_defense_down/mez_stunned/dot_bleeding/dot_poisoned) → 페이즈 3 #3 10행 중 9 참조. 미참조 1 ID(`debuff_accuracy_down`)는 환경(mist_field)·트레잇 자동 부여로만 활성 |
| 페이즈 3 #4 `combat_report_templates` 시드 | `combat_skill` scope 신규 30행이 본 시드 16 스킬 ID를 `tags_json.skill_id`에 매칭 |
| 페이즈 4 #1 `CombatSimulator` 명세 | trigger_condition DSL 평가 + targeting_priority 결정 트리 + multi_hit_count 다단 행동 |
| 페이즈 4 #2 `CombatSkill` 모델 | 본 시드의 23 컬럼 → freezed/Hive 필드 매핑 (nullable 정책 정합) |
| 페이즈 4 #3 `QuestCompletionService` 통합 | `dispel_kind`/`status_effect_id` → 시뮬레이션 결과 → 보고서 톤 |
| 페이즈 4 #5 검증 명세 | apply_chance + intensity + duration 시뮬레이션 분포 검증 |

## 다음 단계

페이즈 3 #3 `combat_status_effects` 10행 시드 작성. 본 시드의 `status_effect_id`가 참조하는 9 unique ID + 미참조 1 ID(`debuff_accuracy_down`이 환경 mist_field 자동 부여로만 활성) = 10 카탈로그 ID 풀.
