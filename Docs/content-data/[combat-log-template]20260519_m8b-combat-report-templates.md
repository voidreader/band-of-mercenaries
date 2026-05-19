# M8b 전투 로그 템플릿 85행 추가 시드 데이터

> 작성일: 2026-05-19
> 유형: 데이터 생성 (M8b 마일스톤 — 페이즈 3 산출물 4/4, 페이즈 3 마지막)
> 선행 기획서:
> - `Docs/balance-design/[balance]20260519_m8b_combat_log_exposure.md` (페이즈 2 #4) — §9 신규 분포 권고 + §11 라인 예시
> - `Docs/content-data/[enemy]20260519_m8b-enemies.csv` (페이즈 3 #1) — enemy_keyword_key 참조
> - `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` (페이즈 3 #2) — `tags_json.skill_id` 참조 16 스킬
> - `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.csv` (페이즈 3 #3) — `tags_json.status_effect_id` 참조 10 ID
> 페어 CSV: `[combat-log-template]20260519_m8b-combat-report-templates.csv` (85 시드 추가)
> 기존 테이블: `combat_report_templates` (M8a 96행 + M8b 85행 = **총 181행**)
>
> 후속:
> - 페이즈 4 #1 `CombatSimulator` 명세 (보고서 라인 압축 알고리즘 입력)
> - 페이즈 4 #2 `CombatReport` 모델 확장 (tags_json 메타 5 필드)
> - 페이즈 4 #4 전투 보고서 UI 확장 명세 (라인 표시 정책)

## 개요

본 산출물은 페이즈 2 #4 §9 권장 80행에 ±5 분포 안에서 **85행**을 추가 INSERT한다. M8a `combat_report_templates` 96행은 보존되며, 신규 scope `combat_skill` CHECK 확장 ALTER + 85행 추가 INSERT로 총 181행이 된다 (페이즈 2 #4 권장 상한 180에서 +1 — 후속 정밀 조정 가능).

페이즈 2 #4 §9.1 분량과 비교한 본 시드 분포:

| 출처 | §9.1 권장 | 본 시드 | 차이 |
|------|---------|--------|-----|
| 페이즈 2 #1 파티 측 스킬 라인 | 30 | 23 (combat_skill 파티 18 + 환경/상태 5 분산) | -7 |
| 페이즈 2 #2 적 측 스킬 + 일반 | 20 | 17 (combat_skill 적 4 + faction 5 + unique 8) | -3 |
| 페이즈 2 #3 상태 효과 텍스트 | 15 | 15 (combat_skill 10 + scene status 5) | 0 |
| 5 위치 환경·진입 라인 | 10 | 9 (scene entry 5 + chain/elite/unique entry 4) | -1 |
| 후일담 사기 라인 | 5 | 9 (chain after 4 + scene after 4 + faction_named summary 1 wash) | +4 |
| 신규 보충 (chain/elite summary·detail 추가 변형) | — | 12 (chain_final 4 + chain_step 4 + elite summary 4) | +12 |
| **합계** | **80** | **85** | **+5** |

권장 80 ±5 안에 정합. 변형 12행 추가는 M8a 기존 96행에서 chain_step·elite summary가 부재했던 영역을 보강.

## scope CHECK 확장 ALTER

M8a `combat_report_templates.scope` CHECK 제약이 8 enum이면 본 시드의 `combat_skill` 추가 시 거부. 우선 ALTER 필요:

```sql
-- M8a CHECK 제약 확인 후 (없으면 스킵)
ALTER TABLE combat_report_templates
  DROP CONSTRAINT IF EXISTS combat_report_templates_scope_check;

ALTER TABLE combat_report_templates
  ADD CONSTRAINT combat_report_templates_scope_check
  CHECK (scope IN (
    'chain_final',
    'chain_step',
    'elite',
    'faction_named',
    'quest_type',
    'scene',
    'settlement_event',
    'unique_elite',
    'combat_skill'   -- M8b 신규
  ));

-- data_versions 갱신
UPDATE data_versions SET version = version + 1 WHERE table_name = 'combat_report_templates';
```

ALTER 실행 후 85행 INSERT (CSV import).

## 신규 scope `combat_skill` 분포

| scope | M8a 기존 | M8b 본 시드 | 합계 |
|-------|---------|-----------|------|
| chain_final | 4 (summary) | 4 (detail) | 8 |
| chain_step | 4 (detail) | 4 (summary) | 8 |
| elite | 8 (detail) | 8 (summary 4 + detail 4) | 16 |
| faction_named | 24 | 10 (summary 6 + detail 4) | 34 |
| quest_type | 24 | 4 (detail) | 28 |
| scene | 20 | 20 (entry 5·dev 2·crisis 2·resol 2·after 4·status 5) | 40 |
| settlement_event | 4 (detail) | 4 (summary) | 8 |
| unique_elite | 8 | 8 (detail) | 16 |
| **combat_skill (M8b 신규)** | 0 | 23 | **23** |
| **합계** | **96** | **85** | **181** |

페이즈 2 #4 §9.2 신규 row 분포 표 정합 (combat_skill 20 권장 → 23 채택, +3 보강).

## 85행 분포 상세

### line_type 분포

| line_type | 수 | 활용 |
|-----------|----|------|
| summary | 25 (chain_final 4 + chain_step 4 + elite summary 4 + settlement summary 4 + faction summary 6 + scene 0 + 기타 3) | 페이즈 2 #4 §2.1 라운드 짧음·평균 분기 |
| detail | 60 | 상세 5 위치 채움 |

### importance 분포

| importance | 수 | 활용 |
|-----------|----|------|
| normal | 35 | quest_type / faction_named basic / combat_skill 다수 / scene 다수 |
| high | 38 | elite / faction_named advanced / mage_blast/stun / settlement_event / chain_step / enemy_summon |
| veryHigh | 12 | chain_final 4 + unique_elite 8 |

페이즈 2 #4 §7.1 scope 차등 길이 매트릭스 정합.

### result_type 분포

| result_type | 수 |
|-------------|----|
| great_success | 26 |
| success | 22 |
| failure | 18 |
| critical_failure | 19 |

4 분기 균등에 가까운 분포.

### tags_json position 분포 (detail 60행 기준)

| position | 수 |
|----------|----|
| entry | 9 |
| development | 13 |
| crisis | 22 |
| resolution | 11 |
| aftermath | 11 |
| (미명시 — chain_final 일부) | 4 |

페이즈 2 #4 §3.1 5 위치 분류 정합.

### skill_id 매핑 분포 (combat_skill scope 23행 + faction_named 2행 + unique_elite 1행)

| skill_id | 매핑 행 수 |
|----------|---------|
| skill_warrior_battle_fury | 3 |
| skill_warrior_shield_bulwark | 2 |
| skill_rogue_mass_blind | 2 |
| skill_ranger_marksman_focus | 1 |
| skill_ranger_volley_shot | 2 |
| skill_mage_arcane_blast | 2 + 2 (faction) = 4 |
| skill_mage_stun_bolt | 2 |
| skill_support_aegis_aura | 2 |
| skill_support_cleansing_word | 1 |
| skill_specialist_adaptive_footwork | 1 |
| skill_enemy_bleeding_cut | 1 |
| skill_enemy_armor_break | 1 |
| skill_enemy_poison_bite | 1 |
| skill_enemy_taunt_roar | 1 |
| skill_enemy_summon | 1 |
| skill_enemy_self_dispel | 1 (unique_elite) |

16/16 스킬 모두 `tags_json.skill_id` 라인에 매핑한다. `skill_enemy_poison_bite`는 `enemy_trial_beast` 제한 배정에 맞춰 1행을 둔다.

### status_effect_id 매핑 분포 (combat_skill scope 10행 + scene status 5행)

| status_effect_id | 매핑 행 수 |
|------------------|---------|
| buff_attack_up | 2 (battle_fury 1 + scene 1) |
| buff_defense_up | 2 (aegis_aura 1 + scene 1) |
| buff_accuracy_up | 1 (marksman_focus) |
| buff_evasion_up | 1 (adaptive_footwork) |
| debuff_attack_down | 2 (mass_blind + taunt_roar) |
| debuff_defense_down | 1 (armor_break) |
| mez_stunned | 2 (stun_bolt + scene) |
| dot_bleeding | 3 (bleeding_cut + scene status 2) |
| dot_poisoned | 1 (poison_bite) |
| debuff_accuracy_down | 0 (환경 자동 부여만 — scene 라인 없음, 페이즈 4 #4 후속 확장 후보) |

9/10 status_effect_id 라인 매핑. 미매핑 1(`debuff_accuracy_down`)은 환경 자동 부여만 담당하므로 §1.3 페이즈 2 #3 미사용 영역과 정합한다.

### decisive_keyword 매핑 (M8a 12 키워드 활용)

| decisive_key | 매핑 라인 |
|--------------|---------|
| shield_opens_path | crt_m8b_skill_warrior_shield_01 |
| backline_cut | (M8a 4 라인에 매핑됨 — 본 시드 미사용) |
| protagonist_last_step | (M8a 라인에서 활용) |
| cart_saved | crt_m8b_quest_great_02 |
| map_corrected | crt_m8b_quest_critical_01 |
| seal_recovered | (M8a 라인에서 활용) |
| duel_mark_pressed | (M8a 라인에서 활용) |
| retreat_controlled | (M8a 라인에서 활용) |
| second_ambush_failed | (M8a 라인에서 활용) |
| enemy_weakness_seen | crt_m8b_elite_great_04 |
| signal_late | (M8a 라인에서 활용 — 본 시드 후보) |
| formation_split | crt_m8b_chain_critical_03, crt_m8b_unique_critical_02 |

본 시드는 M8a 12 키워드 중 5개 직접 활용. 나머지 7개는 M8a 96행에서 활용 중. M8b 후속 확장(M8.5/M9) 시 라인 추가 가능.

### injury 키워드 매핑 (M8a 6 키워드)

| injury_key | 매핑 라인 |
|-----------|---------|
| knee_gave_way | crt_m8b_elite_critical_04 |
| breath_lost | crt_m8b_scene_crisis_01 |
| retreat_signal_late | crt_m8b_scene_resol_02, crt_m8b_scene_after_04 |
| shield_arm_numb | (M8a 후보) |
| name_checked_late | crt_m8b_scene_after_03 |
| field_dressing_done | crt_m8b_scene_after_02 |

본 시드에서 5/6 키워드 활용. shield_arm_numb은 M8a 라인 위주.

## 페이즈 2 #4 §11 라인 예시 정합 검증

§11 라인 예시 3종(unique_elite/faction_named basic/chain_final critical_failure)이 본 시드로 재현 가능한지 검증:

### 예시 1: 6 라운드 unique_elite (검은 마녀 모르간)

요약 3문장 필요 → 본 시드 unique_elite summary 부재. M8a 4행(`crt_m8a_unique_*_summary`)에서 추출 (M8a 보존).

상세 7줄 필요 →
1. [entry] M8a 또는 scene entry (M7 ruined_castle 매핑 — crt_m8b_scene_entry_05)
2. [development] battle_fury (crt_m8b_skill_warrior_fury_01)
3. [development] mage_blast (crt_m8b_skill_mage_blast_01)
4. [development] marksman_focus (crt_m8b_skill_ranger_focus_01)
5. [crisis] stun_bolt — 단 mage 적 발동, 본 시드 미매핑 → scene crisis 또는 enemy 라인 (crt_m8b_skill_mage_stun_01)
6. [resolution] 치명타 결정 (crt_m8b_unique_great_02 또는 m8b_elite_great_04)
7. [aftermath] crt_m8b_scene_after_01

본 시드 + M8a 라인으로 7줄 모두 채움 가능.

### 예시 2: 4 라운드 faction_named (basic) — 상인 연합 매복 호위

요약 2문장 + 상세 5줄. M8a `faction_named` summary 12 + 본 시드 `crt_m8b_faction_mer_*` 사용 가능.

## M8a 호환 검증

### tags_json 메타 호환

M8a 96행은 `tags_json`에 `mood`/`region`/`scope` 등 메타가 있고, M8b 5 신규 필드(`position`/`skill_id`/`status_effect_id`/`decisive_keyword_key`/`is_combo_compression`)는 없다. 페이즈 4 #1 `CombatSimulator` 명세에서 (a) 신규 필드 누락 시 자동 fallback 또는 (b) M8b 라인만 우선 매칭 정책 결정 위임.

본 시드는 M8b 신규 라인이라 모두 신규 메타 보유. M8a 라인은 기존 mood/region 메타 그대로 활용.

### scope `scene` 보충풀 정책

M8a `scene` scope 20행은 M8b 신규 20행과 합쳐 40행이 된다. 페이즈 2 #4 §7.3 scene 보충풀 fallback 정합. 페이즈 4 #1 시뮬레이터의 라인 선택 알고리즘에서 scope 직접 매칭 후 scene fallback 정책.

## 데이터 사용 가이드

### Supabase 적용 순서

1. `combat_report_templates.scope` CHECK 제약 ALTER 실행 (`combat_skill` 추가)
2. CSV 파일 (`[combat-log-template]20260519_m8b-combat-report-templates.csv`)을 operation-bom 또는 Supabase Dashboard에서 import (85행)
3. `data_versions` 테이블의 `combat_report_templates` 버전 +1 (DDL에 포함)
4. M8a 호환: 기존 96행은 변경 없음. import 후 총 181행.
5. 클라이언트 SyncService는 기존 `combat_report_templates` 그대로 (페이즈 4 #2 명세에서 신규 필드 처리만 확장)

### combat_report_keywords 신규 5 키워드 추가 (선택)

페이즈 2 #2 §11.3에서 후보로 명시한 신규 5 enemy 키워드(`dark_mage_party`/`goblin_raid_party`/`imp_swarm`/`orc_warband`/`lich_undead_legion`)는 본 시드에서 일부 활용. 추가 INSERT 권고:

```sql
INSERT INTO combat_report_keywords (id, category, key, display_text, tags_json, weight) VALUES
('crk_m8b_enemy_01', 'enemy', 'dark_mage_party', '흑마법사 일행', '{"mood":"arcane"}'::jsonb, 80),
('crk_m8b_enemy_02', 'enemy', 'goblin_raid_party', '고블린 습격대', '{"mood":"raid"}'::jsonb, 80),
('crk_m8b_enemy_03', 'enemy', 'imp_swarm', '임프 무리', '{"mood":"swarm"}'::jsonb, 80),
('crk_m8b_enemy_04', 'enemy', 'orc_warband', '오크 전사단', '{"mood":"raid"}'::jsonb, 80),
('crk_m8b_enemy_05', 'enemy', 'lich_undead_legion', '리치의 망자 군단', '{"mood":"undead"}'::jsonb, 80);
```

페이즈 3 #1 `enemies.enemy_keyword_key`에서 `goblin_raid_party`/`imp_swarm`/`lich_undead_legion`을 이미 참조 중. 본 INSERT를 페이즈 3 #4 시드와 함께 실행 권고.

## 후속 입력 매트릭스

| 후속 산출물 | 본 시드의 입력 기여 |
|-----------|--------------------|
| 페이즈 4 #1 `CombatSimulator` 명세 | tags_json 메타 5 필드 + position 5종 + scope 9종 라인 선택 알고리즘 |
| 페이즈 4 #2 `CombatReport` 모델 확장 | tags_json 메타 신규 5 필드 nullable 정책 + scope `combat_skill` enum 추가 |
| 페이즈 4 #4 전투 보고서 UI 확장 명세 | 라운드 ↔ 길이 매트릭스 + 라인 표시 색상·배지 |
| 페이즈 4 #5 검증 명세 | 라인 풀 활용도 분석 + scope 매칭 빈도 + 중복 라인 회피 검증 |

## 페이즈 3 완료

본 산출물로 페이즈 3 데이터 생성 4/4 산출물이 모두 완료된다.

페이즈 3 산출물 요약:
- 페이즈 3 #1: `enemies` 26 시드 (`[enemy]20260519_m8b-enemies.{csv,md}`)
- 페이즈 3 #2: `combat_skills` 16 시드 (`[combat-skill]20260519_m8b-combat-skills.{csv,md}`)
- 페이즈 3 #3: `combat_status_effects` 10 시드 (`[status-effect]20260519_m8b-combat-status-effects.{csv,md}`)
- 페이즈 3 #4: `combat_report_templates` 85 시드 추가 (본 산출물)

총 신규 행 137개 + ALTER 1건. 신규 테이블 3개 + 기존 테이블 1개 확장.

## 다음 단계

페이즈 4 개발 명세 5개 산출물:
- 페이즈 4 #1 `CombatSimulator` 순수 서비스 명세
- 페이즈 4 #2 신규 모델 5종 명세 (`CombatantSnapshot`/`CombatTurn`/`CombatAction`/`CombatStatusEffect`/확장된 `CombatReport`)
- 페이즈 4 #3 `QuestCompletionService` 통합 명세
- 페이즈 4 #4 전투 보고서 UI 확장 명세
- 페이즈 4 #5 검증 및 밸런스 명세
