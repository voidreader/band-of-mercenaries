# M8b 적 유형 26행 시드 데이터

> 작성일: 2026-05-19
> 유형: 데이터 생성 (M8b 마일스톤 — 페이즈 3 산출물 1/4)
> 선행 기획서: `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2 + 코덱스 보완)
> 페어 CSV: `[enemy]20260519_m8b-enemies.csv` (26 시드 데이터)
> 신규 테이블: `enemies` (M8b 신규 — Supabase 32~36번째 테이블 중 후보)
>
> 후속:
> - 페이즈 3 #2 `combat_skills` 16행 시드 (skill_ids FK)
> - 페이즈 3 #3 `combat_status_effects` 10행 시드 (combat_skills 의존)
> - 페이즈 3 #4 `combat_report_templates` 85행 추가 INSERT
> - 페이즈 4 #2 `EnemyArchetype`/`EnemySnapshot` freezed 모델 명세

## 개요

본 산출물은 M8b 페이즈 2 #2 적 유형 카탈로그 26행을 `enemies` 신규 테이블에 시드하기 위한 CSV 데이터와 DDL 명세를 담는다. 페이즈 2 #2 §14.2 권장 컬럼 19개를 그대로 사용한다.

페이즈 2 #2 보완 후 정합:
- 코덱스 보완으로 `enemy_bandit_assassin`·`enemy_elite_goblin_raider`의 skill_ids 매핑이 `skill_rogue_dirty_blade` → `skill_enemy_bleeding_cut`으로 갱신됨.

## 신규 테이블 DDL

```sql
CREATE TABLE IF NOT EXISTS enemies (
  id                  TEXT PRIMARY KEY,
  name                TEXT NOT NULL,
  enemy_kind          TEXT NOT NULL,
  role                TEXT NOT NULL,
  tier                INT  NOT NULL,
  base_str            INT  NOT NULL,
  base_int            INT  NOT NULL,
  base_vit            INT  NOT NULL,
  base_agi            INT  NOT NULL,
  base_hp             INT  NOT NULL,
  base_attack         INT  NOT NULL,
  base_defense        INT  NOT NULL,
  behavior_pattern    TEXT NOT NULL,
  skill_ids           JSONB NOT NULL DEFAULT '[]'::jsonb,
  environment_tags    JSONB NOT NULL DEFAULT '[]'::jsonb,
  faction_tags        JSONB NOT NULL DEFAULT '[]'::jsonb,
  ambush_compatible   BOOLEAN NOT NULL DEFAULT FALSE,
  enemy_keyword_key   TEXT NULL,
  elite_monster_id    TEXT NULL REFERENCES elite_monsters(id),
  description         TEXT NOT NULL DEFAULT '',

  CONSTRAINT enemies_kind_check     CHECK (enemy_kind IN ('normal','elite','unique')),
  CONSTRAINT enemies_role_check     CHECK (role IN ('warrior','rogue','ranger','mage','support','specialist')),
  CONSTRAINT enemies_behavior_check CHECK (behavior_pattern IN ('aggressive','opportunist','caster','supporter','defender','berserker')),
  CONSTRAINT enemies_tier_check     CHECK (tier BETWEEN 1 AND 5),
  CONSTRAINT enemies_elite_kind_consistency CHECK (
    (enemy_kind = 'normal' AND elite_monster_id IS NULL) OR
    (enemy_kind IN ('elite','unique'))
  )
);

CREATE INDEX IF NOT EXISTS idx_enemies_role          ON enemies(role);
CREATE INDEX IF NOT EXISTS idx_enemies_kind          ON enemies(enemy_kind);
CREATE INDEX IF NOT EXISTS idx_enemies_ambush        ON enemies(ambush_compatible) WHERE ambush_compatible = TRUE;
CREATE INDEX IF NOT EXISTS idx_enemies_elite_monster ON enemies(elite_monster_id)  WHERE elite_monster_id IS NOT NULL;

INSERT INTO data_versions (table_name, version) VALUES ('enemies', 1)
ON CONFLICT (table_name) DO UPDATE SET version = data_versions.version + 1;
```

### 후속 FK 제약 (페이즈 3 #2 시드 이후 ALTER)

`skill_ids` 각 요소가 `combat_skills(id)`를 참조하도록 `combat_skills` 시드 직후 트리거 또는 JSONB 검증 추가:

```sql
-- 페이즈 3 #2 combat_skills 시드 완료 후 실행
ALTER TABLE enemies
  ADD CONSTRAINT enemies_skill_ids_valid
  CHECK (
    NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements_text(skill_ids) AS sk
      WHERE NOT EXISTS (SELECT 1 FROM combat_skills cs WHERE cs.id = sk)
    )
  );
```

`enemy_keyword_key`는 `combat_report_keywords.key` (category='enemy') 참조:

```sql
ALTER TABLE enemies
  ADD CONSTRAINT enemies_keyword_valid
  CHECK (
    enemy_keyword_key IS NULL OR EXISTS (
      SELECT 1 FROM combat_report_keywords ck
      WHERE ck.key = enemies.enemy_keyword_key AND ck.category = 'enemy'
    )
  );
```

`faction_tags` 각 요소가 `factions(id)` 참조 — 페이즈 4 #2 모델에서 정식 보장.

## 26 시드 분포

| 분류 | 수 | 행 ID 범위 |
|------|----|---------|
| 일반 (normal) | 17 | `enemy_bandit_*` 5 / `enemy_graverobber_*` 2 / `enemy_coast_raider*` 2 / `enemy_swamp_*` 2 / `enemy_dark_mage` / `enemy_contract_breaker_mage` / `enemy_dark_priest` / `enemy_ambush_*` 2 / `enemy_trial_beast` |
| 일반 엘리트 (elite) | 5 | `enemy_elite_orc_warrior` / `enemy_elite_goblin_raider` / `enemy_elite_undead_skeleton` / `enemy_elite_beast_bear` / `enemy_elite_demon_imp` |
| 유니크 엘리트 (unique) | 4 | `enemy_unique_wolf_ulbur` / `enemy_unique_skeleton_general` / `enemy_unique_witch_morgan` / `enemy_unique_lich_primordial` |

### role 분포

| role | 일반 | 엘리트 | 유니크 | 합계 |
|------|-----|------|------|------|
| warrior | 7 | 2 | 2 | 11 |
| rogue | 3 | 1 | 0 | 4 |
| ranger | 3 | 1 | 0 | 4 |
| mage | 2 | 1 | 2 | 5 |
| support | 1 | 0 | 0 | 1 |
| specialist | 1 | 0 | 0 | 1 |

페이즈 1 #3 직업군 매트릭스 6 직업군 모두 적 측에 활성. warrior가 가장 다양하고 support는 단일 적(악의 신관).

### tier 분포

| tier | 수 |
|------|----|
| T1 | 1 |
| T2 | 9 |
| T3 | 10 |
| T4 | 5 |
| T5 | 1 |

T2~T3에 집중되어 평균 의뢰 난이도 분포와 정합.

### behaviorPattern 분포

| pattern | 수 | 활용 |
|---------|----|------|
| aggressive | 5 | 도적 졸개·도굴꾼 졸개·해안 습격자·매복 창병·방랑 스켈레톤 |
| opportunist | 7 | 정찰꾼·궁수·암살자·늪지 추적자·시련관 표식수·고블린 습격자 |
| caster | 5 | 흑마법사·계약 파기 마법사·임프·모르간·리치 |
| supporter | 1 | 악의 신관 |
| defender | 2 | 늪지 사령관·백골의 장군 |
| berserker | 6 | 도적 두목·도굴꾼 대장·해안 습격대장·오크 대전사·거대 곰·늑대왕 울부르 |

### 스킬 분포 (16 스킬 중 14 활용)

26행 중 스킬 보유:
- 스킬 0개: 8행 (일반 단순 공격형)
- 스킬 1개: 11행
- 스킬 2개: 7행

총 14 스킬 활용 분포 (페이즈 2 #2 §6.2 정합):

| 스킬 | 활용 행 수 |
|------|---------|
| skill_warrior_shield_bulwark | 2 |
| skill_warrior_battle_fury | 6 |
| skill_rogue_mass_blind | 1 |
| skill_enemy_bleeding_cut | 2 |
| skill_ranger_marksman_focus | 1 |
| skill_ranger_volley_shot | 1 |
| skill_mage_arcane_blast | 5 |
| skill_mage_stun_bolt | 2 |
| skill_support_aegis_aura | 1 |
| skill_enemy_armor_break | 2 |
| skill_enemy_poison_bite | 1 |
| skill_enemy_taunt_roar | 2 |
| skill_enemy_summon | 2 |
| skill_enemy_self_dispel | 1 |

본 `combat_skills` 16행 중 enemies 미참조 스킬은 `skill_support_cleansing_word`(파티 전용), `skill_specialist_adaptive_footwork`(파티 전용) 2개이다. `skill_enemy_poison_bite`는 `enemy_trial_beast` 1행에 제한 배정한다. `skill_rogue_dirty_blade`는 코덱스 보완으로 적 전용 `skill_enemy_bleeding_cut`으로 분리되어 본 카탈로그에 포함하지 않는다.

### 매복 호환 분포

12행이 `ambush_compatible=TRUE`. 페이즈 2 #2 §12.1 정합 (도적 5 + 도굴꾼 2 + 해안 2 + 매복 2 + 늪지 1). 늪지 사령관(`enemy_swamp_general`)은 보스라 매복 단순화 정책으로 FALSE.

### M8a 8 활성 세력 매핑

| 세력 | 매핑 행 수 |
|------|---------|
| adventurers_guild | 6 (도적 4 + 매복 2 + bear) |
| merchants_alliance | 7 (도적 5 + 매복 2 + goblin_raider) |
| thieves_guild | 5 (도적 4 + goblin_raider) |
| deep_hammer | 3 (도굴꾼 2 + orc) |
| sun_order | 4 (도굴꾼 2 + 신관 + skeleton + skeleton_general) |
| mage_towers | 4 (mage 2 + imp + morgan) |
| forbidden_archive | 3 (mage 2 + lich) |
| warriors_guild | 4 (trial_beast + orc + bear + wolf_ulbur) |

세력 미매핑 4행: 해안 습격대 2 + 늪지 추적자 2 → `[]` (M9+ 세력 확장 시 송곳니 결사·균형 감시자 매칭 후보).

### enemy_keyword_key 매핑

| keyword.key | 매핑 행 |
|----|-------|
| bandit_remnants | bandit_thug, bandit_scout, bandit_archer, bandit_captain, bandit_assassin |
| grave_robber_scouts | graverobber_thug |
| grave_robber_captain | graverobber_captain |
| coast_raiders | coast_raider, coast_raider_lead |
| swamp_tracker | swamp_tracker, swamp_general |
| contract_breakers | dark_mage, contract_breaker_mage |
| ambush_spearmen | ambush_spearman, ambush_archer |
| trial_beast | trial_beast |
| giant_forest_beast | elite_beast_bear |
| (NULL) | dark_priest, 5 엘리트, 4 유니크 |

`combat_report_keywords` enemy 10행 중 `nameless_howler`는 미매핑 (페이즈 2 #2 §11.1 정합). 11.3 신규 5 키워드 후보(`dark_mage_party`/`goblin_raid_party`/`imp_swarm`/`orc_warband`/`lich_undead_legion`)는 페이즈 3 #4에서 추가 시 매핑 가능 — 본 시드는 `goblin_raid_party`/`imp_swarm`/`lich_undead_legion`을 임시 매핑 (페이즈 3 #4 신규 키워드 INSERT 보장 필요).

## 페이즈 1 #3 산식 정합 검증

페이즈 2 #2 §2.2에서 정의된 산식 정합. 26행 모두 검증:

### 표본 검증 5건

| 적 | role | base | HP 산식 | HP 시드 | 차이 | 비고 |
|----|------|-----|--------|-------|-----|------|
| `enemy_bandit_thug` | warrior T1 | vit=5 | 5×5.5 + 30 + 0 + 6 = 63.5 → 64 | 69 | +5 | 일반 적 베이스라인 보정 |
| `enemy_swamp_general` | warrior T4 | vit=12 | 12×5.5 + 30 + 45 + 6 = 147 | 144 | -3 | 적 보스 보정 |
| `enemy_dark_mage` | mage T3 | vit=7 | 7×3.0 + 15 + 25 + 6 = 67 | 76 | +9 | 마법사 적 강화 |
| `enemy_elite_orc_warrior` | warrior T2 | vit=13 | 13×5.5 + 30 + 10 + 6 = 117.5 → 118 | 102 | -16 | 엘리트 보스 보정 |
| `enemy_unique_lich_primordial` | mage T5 | vit=18 | 18×3.0 + 15 + 70 + 6 = 145 | 169 | +24 | 유니크 보스 강화 |

차이 ±3~24는 페이즈 2 #2 §2.2 명시 ±3~9 오차 범위에서 일부 보스급 적은 의도적 강화. 페이즈 4 #5 검증 단계에서 시뮬레이션 분포 검증 후 미세 조정.

## 데이터 사용 가이드

### Supabase 적용 순서

1. `enemies` 테이블 DDL 실행 (위 SQL 블록)
2. CSV 파일 (`[enemy]20260519_m8b-enemies.csv`)을 operation-bom 또는 Supabase Dashboard에서 import
3. 페이즈 3 #2 `combat_skills` 시드 완료 후 `enemies_skill_ids_valid` CHECK 제약 ALTER 실행
4. 페이즈 3 #4 `combat_report_keywords` 신규 5 키워드 추가 INSERT 후 `enemies_keyword_valid` CHECK 제약 ALTER 실행 (선택)
5. `data_versions` 테이블에 `enemies` 버전 등록 (DDL에 포함됨)
6. 클라이언트 SyncService에 `enemies`를 `allTables`에 추가 (페이즈 4 #2 명세)

### M8a CombatReport 호환

- M8b 시뮬레이션 결과의 `EnemySnapshot.archetypeId`는 본 시드의 `id` 참조
- `enemy_keyword_key`는 `CombatReport.toneTags` 또는 보고서 라인 변수에 사용
- `description`은 enemy_keyword_key 미매핑 적의 fallback 텍스트

### data_versions 충돌 방지

`enemies` 테이블이 SyncService에 등록되기 전 시드 데이터가 들어가도 안전. 클라이언트는 신규 테이블이 추가되어도 기존 캐시는 무효화되지 않음 (Hive box 별도).

## 후속 입력 매트릭스

| 후속 산출물 | 본 시드의 입력 기여 |
|-----------|--------------------|
| 페이즈 3 #2 `combat_skills` 시드 | 본 시드 26행이 참조하는 14 스킬 ID 풀 (skill_ids JSONB 검증 입력) |
| 페이즈 3 #3 `combat_status_effects` 시드 | 본 시드의 적 측 스킬이 부여하는 상태 효과 ID (간접 의존) |
| 페이즈 3 #4 `combat_report_templates` 시드 | 본 시드의 enemy_keyword_key + behavior_pattern → 라인 후보 매칭 |
| 페이즈 4 #1 `CombatSimulator` 명세 | behavior_pattern 6종 결정 트리 + 적 그룹 구성 로직 |
| 페이즈 4 #2 `EnemyArchetype`/`EnemySnapshot` 모델 | 본 시드의 19 컬럼 → freezed/Hive 필드 매핑 |
| 페이즈 4 #3 `QuestCompletionService` 통합 | quest_pool → 적 그룹 매칭 정책 (faction_tags + environment_tags 기반) |

## 다음 단계

페이즈 3 #2 `combat_skills` 16행 시드 작성. 본 시드의 `skill_ids` JSONB가 참조하는 14 스킬 풀 + 미참조 2 스킬(`skill_support_cleansing_word`·`skill_specialist_adaptive_footwork`)을 모두 정의.
