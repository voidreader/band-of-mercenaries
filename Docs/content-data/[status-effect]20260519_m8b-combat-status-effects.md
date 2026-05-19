# M8b 전투 상태 효과 10행 시드 데이터

> 작성일: 2026-05-19
> 유형: 데이터 생성 (M8b 마일스톤 — 페이즈 3 산출물 3/4)
> 선행 기획서:
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4) — 카탈로그 구조 + hook 매핑 + stackPolicy
> - `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md` (페이즈 2 #3 + 코덱스 보완) — §10.2 10행 정밀 값
> - `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` (페이즈 3 #2) — `status_effect_id` FK 9 unique 참조
> 페어 CSV: `[status-effect]20260519_m8b-combat-status-effects.csv` (10 시드 데이터)
> 신규 테이블: `combat_status_effects` (M8b 신규)
>
> 후속:
> - 페이즈 3 #4 `combat_report_templates` 85행 (`tags_json.status_effect_id` 참조)
> - 페이즈 4 #2 `CombatStatusEffect` freezed 모델 명세

## 개요

본 산출물은 페이즈 1 #4 10 상태 효과 카탈로그(buff 4 / debuff 3 / mez 1 / dot 2)의 default 정밀 값을 `combat_status_effects` 신규 테이블에 시드한다. 페이즈 2 #3 §10.2의 정밀 수치를 그대로 사용한다.

코덱스 보완 반영:
- `buff_evasion_up` default_duration_turns 1 → **2** (specialist 스킬 `skill_specialist_adaptive_footwork` 활성화로 인한 변경, 페이즈 2 #3 §2.1 정합)

## 신규 테이블 DDL

```sql
CREATE TABLE IF NOT EXISTS combat_status_effects (
  id                        TEXT PRIMARY KEY,
  kind                      TEXT NOT NULL,
  display_label             TEXT NOT NULL,
  default_duration_turns    INT  NOT NULL,
  default_intensity         NUMERIC NOT NULL,
  stack_policy              TEXT NOT NULL,
  hook_target               JSONB NOT NULL DEFAULT '[]'::jsonb,
  apply_method              TEXT NOT NULL,
  description               TEXT NOT NULL DEFAULT '',

  CONSTRAINT cse_kind_check          CHECK (kind IN ('buff','debuff','mez','dot')),
  CONSTRAINT cse_stack_policy_check  CHECK (stack_policy IN ('refresh','stack','ignore')),
  CONSTRAINT cse_apply_method_check  CHECK (apply_method IN ('multiplicative','additive','proportional','absolute','none')),
  CONSTRAINT cse_duration_clamp      CHECK (default_duration_turns >= 1 AND default_duration_turns <= 5),
  CONSTRAINT cse_intensity_clamp     CHECK (default_intensity >= 0.0 AND default_intensity <= 3.0)
);

CREATE INDEX IF NOT EXISTS idx_combat_status_effects_kind ON combat_status_effects(kind);

INSERT INTO data_versions (table_name, version) VALUES ('combat_status_effects', 1)
ON CONFLICT (table_name) DO UPDATE SET version = data_versions.version + 1;
```

### 후속 FK 제약 (페이즈 3 #3 완료 직후 ALTER)

```sql
-- combat_skills.status_effect_id가 본 테이블 참조하도록
ALTER TABLE combat_skills
  ADD CONSTRAINT combat_skills_status_effect_fk
  FOREIGN KEY (status_effect_id) REFERENCES combat_status_effects(id);
```

## 10 시드 분포

### kind 분포

| kind | 수 | ID |
|------|----|-----|
| buff | 4 | buff_attack_up, buff_defense_up, buff_accuracy_up, buff_evasion_up |
| debuff | 3 | debuff_attack_down, debuff_defense_down, debuff_accuracy_down |
| mez | 1 | mez_stunned |
| dot | 2 | dot_bleeding, dot_poisoned |

### apply_method 분포

| apply_method | 수 | 대상 ID |
|--------------|----|--------|
| multiplicative | 4 | buff_attack_up, buff_defense_up, debuff_attack_down, debuff_defense_down |
| additive | 4 | buff_accuracy_up, buff_evasion_up, debuff_accuracy_down |
| proportional | 1 | dot_bleeding (`maxHp × 0.04 × stack`) |
| absolute | 1 | dot_poisoned (`intensity × 5 + level × 2`) |
| none | 1 | mez_stunned (행동 스킵, 산식 미사용) |

### stack_policy 분포

| stack_policy | 수 | 대상 ID |
|-------------|----|--------|
| refresh | 8 | 모든 buff 4 + debuff 3 + mez 1 |
| stack | 2 | dot_bleeding (max 3), dot_poisoned (max 3) |
| ignore | 0 | MVP 예약 |

### hook_target 분포

| hook_target | 활용 ID |
|-------------|--------|
| `attack` | buff_attack_up, debuff_attack_down (페이즈 1 #3 §3.2 hook) |
| `defense` | buff_defense_up, debuff_defense_down (페이즈 1 #3 §4 hook) |
| `hit` | buff_accuracy_up, debuff_accuracy_down (페이즈 1 #3 §6 hook) |
| `evasion` | buff_evasion_up (페이즈 1 #3 §8 hook) |
| `action_skip` | mez_stunned (페이즈 1 #4 §6 행동 시점 분기) |
| `round_end` | dot_bleeding (페이즈 1 #4 §5.1 발동 시점) |
| `round_start` | dot_poisoned (페이즈 1 #4 §5.2 발동 시점) |

7개 hook_target. 페이즈 1 #3 hook 8곳 중 일부는 본 카탈로그 미매핑(예: §7 statusEffectCritMod, §9 statusEffectRiposteMod, §5.1 skillDamageMultiplier — 페이즈 2 #1 스킬 직접 처리). 페이즈 1 #4 §1.5 정합.

## 페이즈 3 #2 combat_skills.status_effect_id 검증

페이즈 3 #2 `[combat-skill]20260519_m8b-combat-skills.csv`의 16 스킬 중 `status_effect_id` non-null 10행이 참조하는 9 unique ID:

| status_effect_id | 참조 스킬 수 | 본 시드 정의 여부 |
|------------------|------------|----------------|
| buff_attack_up | 1 (battle_fury) | O |
| buff_defense_up | 1 (aegis_aura) | O |
| buff_accuracy_up | 1 (marksman_focus) | O |
| buff_evasion_up | 1 (specialist_adaptive_footwork) | O |
| debuff_attack_down | 2 (mass_blind, taunt_roar) | O |
| debuff_defense_down | 1 (armor_break) | O |
| debuff_accuracy_down | 0 | O (환경·트레잇 자동 부여만) |
| mez_stunned | 1 (stun_bolt) | O |
| dot_bleeding | 1 (bleeding_cut) | O |
| dot_poisoned | 1 (poison_bite) | O |

10 ID 모두 본 시드에 정의. `debuff_accuracy_down`은 스킬 미사용이지만 페이즈 1 #1 환경 자동 부여(mist_field 적군 전원) + 페이즈 1 #2 §5 트레잇 매핑으로 활성화 (page 2 #3 §1.4, §7).

## 결합 정합 검증

### 곱셈 hook 결합 (`statusEffectAttackMod`, `statusEffectDefenseMod`)

```text
statusEffectAttackMod = (1 + sum(buff_attack_up.intensity))
                      × (1 - sum(debuff_attack_down.intensity))
```

본 시드 default 적용 시:
- buff_attack_up 0.20 단독 → ×1.20 (+20%)
- battle_fury 오버라이드 0.30 단독 → ×1.30 (+30%)
- debuff_attack_down 0.20 단독 → ×0.80 (-20%)
- battle_fury(0.30) + mass_blind(0.20) → 1.30 × 0.80 = **1.04** (페이즈 2 #3 §4.1 정합)

### 가산 hook 결합 (`statusEffectHitMod`, `statusEffectEvasionMod`)

```text
statusEffectHitMod = sum(buff_accuracy_up.intensity) - sum(debuff_accuracy_down.intensity)
statusEffectEvasionMod = sum(buff_evasion_up.intensity)
```

본 시드 default 적용 시:
- buff_accuracy_up 0.15 단독 → +15% 명중
- mist_field 자동 부여 debuff_accuracy_down 0.10 → -10% 명중 (적군)
- buff_evasion_up 0.10 단독 → +10% 회피

페이즈 1 #3 §6 [50%, 95%] / §8 [0%, 75%] 클램프 안 도달. 페이즈 2 #3 §5 클램프 도달 빈도 정합.

### DoT 산식 정합

| DoT | 산식 | 시뮬레이션 결과 (T3 mage HP 88, Lv3) |
|-----|------|---------------------------------|
| dot_bleeding (stack 1) | `max(1, floor(88 × 0.04 × 1))` = 3 | 1턴 누적 3 / 6턴 누적 18 (20%) |
| dot_bleeding (stack 3) | `max(1, floor(88 × 0.04 × 3))` = 10 | 6턴 누적 60 (68%) |
| dot_poisoned (stack 1, intensity 3, Lv3) | `max(1, floor(3 × 5 + 3 × 2))` = 21 | 6턴 누적 126 (143% — 즉사) |

페이즈 2 #3 §3.3 정합. `dot_poisoned` 위협 강도가 의도적으로 높음.

## 코덱스 보완 영향 검증

### `buff_evasion_up` default_duration 1 → 2 변경

기존 페이즈 2 #3 §2.1 정책: default_duration 1턴 (트레잇만 활용).
코덱스 보완: specialist 스킬 활성화 → duration 2턴 (페이즈 2 #3 §2.1 보완 표 — 본 시드에 반영).

영향:
- 트레잇 자동 부여(`vigilant` 키워드, 페이즈 1 #2 §5 매핑)는 duration 1턴 권고지만 default 2턴 사용. 페이즈 4 #1 시뮬레이터 명세에서 트레잇 hook이 duration 1로 오버라이드하거나 default 2를 그대로 사용 (정책 결정 위임).
- `skill_specialist_adaptive_footwork`는 duration default 2 그대로 사용 (페이즈 3 #2 시드 `status_effect_duration_turns` NULL).

**페이즈 4 #1 명세 위임**: 트레잇 자동 부여 hook의 intensity·duration 오버라이드 정책 (default 사용 vs 트레잇별 명시).

## 데이터 사용 가이드

### Supabase 적용 순서

1. `combat_status_effects` 테이블 DDL 실행 (위 SQL 블록)
2. CSV 파일 (`[status-effect]20260519_m8b-combat-status-effects.csv`)을 operation-bom 또는 Supabase Dashboard에서 import
3. 페이즈 3 #2 `combat_skills` 시드 완료 후 `combat_skills_status_effect_fk` FK ALTER 실행
4. `data_versions` 테이블에 `combat_status_effects` 버전 등록 (DDL에 포함됨)
5. 클라이언트 SyncService에 `combat_status_effects`를 `allTables`에 추가 (페이즈 4 #2 명세)

### M8b 시뮬레이터 입력

- `CombatStatusEffect` freezed 모델은 본 시드의 9 컬럼 그대로 매핑
- `applyChance` / `intensity` / `durationTurns` 오버라이드는 `CombatSkill` 모델의 nullable 필드로 표현
- 시뮬레이터 hook 매핑(7 hook_target → 페이즈 1 #3 산식 7곳)은 페이즈 4 #1 명세에서 정식 정의

## 후속 입력 매트릭스

| 후속 산출물 | 본 시드의 입력 기여 |
|-----------|--------------------|
| 페이즈 3 #4 `combat_report_templates` | `tags_json.status_effect_id`가 본 시드 10 ID 참조 — 상태 효과 부여/해제/스택 라인 후보 |
| 페이즈 4 #1 `CombatSimulator` 명세 | apply_method 5종(multiplicative/additive/proportional/absolute/none) 결합 알고리즘 + stack_policy 정책 |
| 페이즈 4 #2 `CombatStatusEffect` 모델 | 본 시드의 9 컬럼 → freezed/Hive 필드 매핑 |
| 페이즈 4 #5 검증 명세 | DoT 누적 시뮬레이션 + 다중 결합 분포 검증 |

## 다음 단계

페이즈 3 #4 `combat_report_templates` 85행 추가 INSERT 작성. M8a 기존 96행에 M8b 신규 85행 추가 (총 181행, 페이즈 2 #4 §9 권장 80±5 분포). 신규 scope `combat_skill` 도입을 위한 CHECK 제약 ALTER 포함.
