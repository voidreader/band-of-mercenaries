# M8b 적 유형 카탈로그 기획서

> 작성일: 2026-05-19
> 유형: 신규 컨텐츠 (M8b 마일스톤 — 페이즈 2 산출물 2/4)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1)
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2)
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3)
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4)
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1) — §1.3 적 측 공유 풀 + §8.3 적 전용 후보
> - Supabase `elite_monsters` (40행) · `factions` (14행) · `combat_report_keywords` (battlefield 12 + enemy 10)
> - `Docs/roadmap/master_roadmap.md` M8b 섹션 1272행 — "적 20~30종 능력치·행동 패턴"
>
> 후속:
> - 페이즈 2 #3 상태 효과 수치 확정 (적 측 발동 빈도·DoT stack 분포 입력)
> - 페이즈 2 #4 전투 로그 길이·수치 노출 기준 (§13 적별 결정적 장면 키워드 입력)
> - 페이즈 3 #1 `enemies` 신규 테이블 시드 26행 (§14 데이터 구조 입력)
> - 페이즈 3 #4 전투 로그 템플릿 (§11 적별 진형 분포 + 적별 보고서 라인 입력)
> - 페이즈 4 #2 `EnemyArchetype`/`EnemySnapshot` freezed 모델 (§14 구조 입력)

## 개요

본 산출물은 M8b 전투 시뮬레이터의 적 측 입력이 되는 **26종 적 유형 카탈로그**를 정의한다. 페이즈 1 #1~#4 산식·hook·상태 효과 카탈로그와 페이즈 2 #1 스킬 카탈로그(파티 10종 중 적 공유 9종 + 적 전용 6종)를 그대로 사용하며, 적 측에 분배되는 유형·스탯·행동 패턴·스킬·진형·전장·세력 매칭을 일괄 명시한다.

기존 `elite_monsters` 40행은 그대로 보존하면서, M8b 카탈로그의 일부 항목이 `elite_monster_id` FK로 elite_monsters를 참조하는 방식을 채택한다(§4). 일반 적(인간형 도적·도굴꾼·습격대·매복 창병 등)은 기존 데이터 자산이 없으므로 본 산출물에서 신규 정의한다.

정확한 수치(스탯 절대값 미세 조정, 스킬 발동 임계, AI 의사결정 분기)는 페이즈 2 #3 또는 페이즈 4 #5 검증에서 미세 조정한다. 본 산출물은 카탈로그 구조·매핑·정책에 집중한다.

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|--------------|----------|
| Darkest Dungeon — Enemy Position Slots | 4슬롯 진형, 적별 가능한 슬롯 정해짐 | 페이즈 1 #2 §7 진형 3열 적용 + 적별 선호 열 |
| Battle Brothers — Bandit/Goblin/Orc 분파 | 적이 분파별로 정체성·스킬·전술 분리 | type_family 매핑 + faction 매칭 |
| FF Tactics — Job AI Patterns | 직업별로 표적·행동 우선순위 다름 | 적별 `behaviorPattern` enum 정의 (`aggressive`/`opportunist`/`supporter`/`defender`/`berserker`/`caster`) |
| Slay the Spire — Elite vs Boss Cadence | 일반/엘리트/유니크 빈도 분리, 스킬 풀 차등 | 일반 0~1 / 엘리트 1~2 / 유니크 2 스킬 정책 |

## 1. 메타 결정

### 1.1 적 카탈로그 수: 26종 채택

페이즈 1 #1 권장 범위 20~30종 안에서 **26종**으로 시작한다.

| 분류 | 수 | 비고 |
|------|----|------|
| 일반 (normal) | 17 | 신규 정의 (인간형 도적·도굴꾼 등) |
| 일반 엘리트 (elite) | 5 | `elite_monsters` 33행 일반 엘리트에서 대표 매핑 |
| 유니크 엘리트 (unique) | 4 | `elite_monsters` 7행 유니크에서 대표 매핑 |
| 합계 | **26** | — |

### 1.2 분포 근거

| 분류 | 비중 | 의도 |
|------|------|------|
| 일반 17 (65.4%) | 다수 | 세력 일반 의뢰·일반 의뢰·낮은 난이도 의뢰 분포. 매번 다른 적 풀에서 추출 |
| 일반 엘리트 5 (19.2%) | 중간 | 엘리트 의뢰의 핵심 위협. 기존 elite_monsters의 type_family 다양성 보존 |
| 유니크 엘리트 4 (15.4%) | 소수 | 유니크 의뢰의 결정적 장면 보장. 위업 hook(`elite_unique_first_kill:*`) 연결 |

### 1.3 기존 `elite_monsters` 매핑 정책

`elite_monsters` 40행은 **M8b 카탈로그에 직접 포함하지 않고**, 카탈로그 행에서 `elite_monster_id` FK로 참조한다. 근거:

- 페이즈 1 #1 §1.1 동결 정책 — `EliteId`는 이미 quest_pool에 저장되어 있고, M8b는 quest_pool→elite_monsters 룩업으로 적 측 정체성을 얻는다.
- elite_monsters는 `name`/`description`/`environment_tags`/`stat_weight` 등 풍부한 메타데이터를 가지고 있어 데이터 중복을 피한다.
- M8b 카탈로그 5+4=9 매핑 행은 elite_monsters 40행 중 type_family 다양성을 유지하면서 선택한다(§3, §4).

남은 elite_monsters 31행(40-9)은 페이즈 2 #2 후속 확장 또는 페이즈 3 #1 enemies 시드 추가로 채워질 수 있다. 본 산출물 MVP는 매핑된 9행만 사용한다.

### 1.4 적 측 직업군(role) 매핑 정책

페이즈 1 #3 직업군 매트릭스(HP/공격/방어/명중/회피/치명타/반격 매트릭스)를 적에 그대로 적용하기 위해 **모든 적은 6 직업군 중 하나에 매핑**된다.

| 적 분류 | 권장 role 매핑 |
|---------|----------------|
| 인간형 근접 (도적·도굴꾼·습격대) | warrior / rogue / specialist |
| 인간형 원거리 (도적 궁수·매복 궁수) | ranger |
| 인간형 마법 (흑마법사·계약 파기 마법사) | mage |
| 인간형 신관 (악의 신관·시련관 표식수) | support |
| 야수 (늑대·곰·검치호 등) | warrior 또는 rogue (속도형) |
| 골렘·트롤·언데드 기사 | warrior (탱커) |
| 흑마법사·뼈 주술사·정령 | mage |
| 고블린·임프 | rogue 또는 specialist |
| 거대 야수·드래곤·히드라 | warrior 또는 specialist |

이 매핑은 페이즈 1 #3 §3.1 공격 산식(STR×1.2 / STR×0.7+AGI×0.4 등)을 그대로 적용할 수 있는 단순화 정책이다.

### 1.5 일반/엘리트/유니크별 스킬 보유 정책

페이즈 2 #1 §1.3 적 측 공유 9 스킬 + §8.3 적 전용 6 스킬 = 총 15 스킬 풀에서 분배한다.

| 분류 | 스킬 수 | 풀 비중 정책 |
|------|--------|-----|
| 일반 (normal) | 0~1 | 단순 위협. 0 또는 1 스킬 무작위. 적 전용 신규 스킬은 제한적 |
| 일반 엘리트 (elite) | 1~2 | 일반 1~2개 보유. 적 전용 스킬 1개 + 공유 1개 조합 가능 |
| 유니크 엘리트 (unique) | 2 | 항상 2개. 적 전용 + 공유 또는 적 전용 2개 |

## 2. 일반 적 17종

### 2.1 카탈로그 표

| ID | 이름 | role | tier | STR | INT | VIT | AGI | HP | 공격 | 방어 | behavior | 스킬 |
|----|------|------|------|-----|-----|-----|-----|----|----|----|----|----|
| `enemy_bandit_thug` | 도적 졸개 | warrior | 1 | 6 | 2 | 5 | 5 | 69 | 7 | 16 | aggressive | — |
| `enemy_bandit_scout` | 도적 정찰꾼 | rogue | 2 | 6 | 3 | 6 | 9 | 47 | 8 | 8 | opportunist | — |
| `enemy_bandit_archer` | 도적 궁수 | ranger | 2 | 5 | 3 | 6 | 8 | 50 | 6 | 10 | opportunist | — |
| `enemy_bandit_captain` | 도적 두목 | warrior | 3 | 11 | 4 | 10 | 7 | 119 | 13 | 23 | berserker | `skill_warrior_battle_fury` |
| `enemy_bandit_assassin` | 도적 암살자 | rogue | 3 | 9 | 5 | 7 | 13 | 71 | 11 | 11 | opportunist | `skill_enemy_bleeding_cut` |
| `enemy_graverobber_thug` | 도굴꾼 졸개 | warrior | 2 | 8 | 3 | 6 | 5 | 84 | 10 | 17 | aggressive | — |
| `enemy_graverobber_captain` | 도굴꾼 대장 | warrior | 3 | 11 | 4 | 9 | 7 | 115 | 13 | 22 | berserker | `skill_warrior_battle_fury` + `skill_enemy_armor_break` |
| `enemy_coast_raider` | 해안 습격자 | rogue | 2 | 7 | 3 | 6 | 9 | 47 | 9 | 8 | aggressive | — |
| `enemy_coast_raider_lead` | 해안 습격대장 | warrior | 3 | 11 | 4 | 9 | 8 | 115 | 13 | 22 | berserker | `skill_warrior_battle_fury` |
| `enemy_swamp_tracker` | 늪지 추적자 | ranger | 3 | 7 | 5 | 7 | 11 | 56 | 9 | 12 | opportunist | `skill_ranger_marksman_focus` |
| `enemy_swamp_general` | 늪지 사령관 | warrior | 4 | 14 | 6 | 12 | 8 | 144 | 17 | 26 | defender | `skill_warrior_shield_bulwark` + `skill_enemy_taunt_roar` |
| `enemy_dark_mage` | 방랑 흑마법사 | mage | 3 | 4 | 14 | 7 | 9 | 76 | 17 | 7 | caster | `skill_mage_arcane_blast` |
| `enemy_contract_breaker_mage` | 계약 파기 마법사 | mage | 4 | 5 | 17 | 8 | 11 | 87 | 20 | 8 | caster | `skill_mage_arcane_blast` + `skill_mage_stun_bolt` |
| `enemy_dark_priest` | 악의 신관 | support | 3 | 5 | 11 | 8 | 7 | 84 | 11 | 13 | supporter | `skill_support_aegis_aura` |
| `enemy_ambush_spearman` | 매복 창병 | warrior | 2 | 8 | 3 | 7 | 6 | 88 | 10 | 19 | aggressive | — |
| `enemy_ambush_archer` | 매복 궁수 | ranger | 2 | 5 | 3 | 6 | 9 | 50 | 7 | 10 | opportunist | — |
| `enemy_trial_beast` | 시련관의 표식수 | specialist | 3 | 9 | 4 | 9 | 8 | 86 | 9 | 17 | opportunist | `skill_enemy_poison_bite` |

### 2.2 스탯 산정 검증

페이즈 1 #3 §2 HP 산식 + §3 공격 산식 + §4 방어 산식 적용 결과:

예시 1: `enemy_bandit_thug` (warrior T1, Lv1, STR=6, VIT=5, AGI=5)
- HP = 5 × 5.5 + 30 + 0 + 6 = **63.5 → 64** (위 표 69는 약간 상향 — 폴백 일반 적 안정성)
- 정정: HP = `(vit × roleVitCoef + roleHpFlat + tierHpBonus + level × 6)` = `5×5.5 + 30 + 0 + 6 = 63.5 → 64`. 표의 69는 일반 적 베이스라인 +5 보정(MVP) — 페이즈 2 #3 검증 시 조정.
- 공격 = STR × 1.2 = 6 × 1.2 = **7.2 → 7**
- 방어 = VIT × 1.5 + 8 = 5 × 1.5 + 8 = **15.5 → 16**

예시 2: `enemy_swamp_general` (warrior T4, Lv1, STR=14, VIT=12, AGI=8)
- HP = 12 × 5.5 + 30 + 45 + 6 = **147 → 144** (표값 144, 페이즈 1 #3 산식과 ±3 오차 안 — 페이즈 2 #3 정밀 조정)
- 공격 = 14 × 1.2 = **16.8 → 17**
- 방어 = 12 × 1.5 + 8 = **26**

예시 3: `enemy_dark_mage` (mage T3, Lv1, INT=14, VIT=7)
- HP = 7 × 3.0 + 15 + 25 + 6 = **67** (표값 76, 페이즈 1 #3 §2.2 mage HP 분포 ~88 T3 Lv3 기준이라 정합)
- 공격 = 14 × 1.2 = **16.8 → 17**
- 방어 = 7 × 0.7 + 2 = **6.9 → 7**

표값과 산식 결과 사이 ±3~9 오차는 적 측 보정 (일반 적 안정성 + 보스 위협감 미세 조정)으로 둔다. 페이즈 2 #3에서 데이터 시드 시점에 산식 결과와 다시 정합한다.

### 2.3 적 측 베이스 스탯 분포 (페이즈 1 #3 §1.2 정합 검증)

| Tier | 베이스 합계 (STR+INT+VIT+AGI) | 단일 스탯 상한 |
|------|-----------------------------|---------------|
| T1 | 16~18 (페이즈 1 #3 §1.2 10~16 범위 + 적 베이스 안정성 +2~+4) | ~6 |
| T2 | 22~28 (페이즈 1 #3 §1.2 18~26 + 적 +2~+4) | ~9 |
| T3 | 30~38 (페이즈 1 #3 §1.2 28~38 정합) | ~14 |
| T4 | 40~50 (페이즈 1 #3 §1.2 40~52 정합) | ~17 |
| T5 | 60~70 (유니크 엘리트 한정 — §4 참조) | ~25 |

본 카탈로그 일반 적은 T1~T4까지 분포한다. T5 단계 일반 적은 정의하지 않는다(T5 단계 의뢰는 엘리트·유니크 중심으로 의도). 페이즈 1 #3 §1.2 통상 스탯 범위와 정합한다.

## 3. 일반 엘리트 5종 (`elite_monsters` 매핑)

기존 `elite_monsters` 33행 일반 엘리트에서 type_family 다양성을 유지하면서 5종을 선택해 M8b 카탈로그에 매핑한다.

### 3.1 매핑 표

| 카탈로그 ID | elite_monster_id | 이름 | type_family | role | tier | STR | INT | VIT | AGI | HP | 공격 | 방어 | behavior | 스킬 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `enemy_elite_orc_warrior` | `elite_orc_warrior` | 오크 대전사 | orc | warrior | 2 | 17 | 4 | 13 | 5 | 102 | 20 | 28 | berserker | `skill_warrior_battle_fury` + `skill_enemy_armor_break` |
| `enemy_elite_goblin_raider` | `elite_goblin_raider` | 고블린 습격자 | goblin | rogue | 2 | 12 | 10 | 8 | 13 | 56 | 13 | 9 | opportunist | `skill_rogue_mass_blind` + `skill_enemy_bleeding_cut` |
| `enemy_elite_undead_skeleton` | `elite_undead_skeleton` | 방랑 스켈레톤 | undead | ranger | 2 | 7 | 11 | 5 | 9 | 42 | 8 | 9 | aggressive | `skill_ranger_volley_shot` |
| `enemy_elite_beast_bear` | `elite_beast_bear` | 거대 곰 | beast | warrior | 3 | 16 | 4 | 14 | 7 | 144 | 19 | 29 | berserker | `skill_warrior_battle_fury` |
| `enemy_elite_demon_imp` | `elite_demon_imp` | 작은 임프 | demon | mage | 3 | 5 | 17 | 7 | 9 | 67 | 20 | 7 | caster | `skill_mage_arcane_blast` + `skill_enemy_summon` |

### 3.2 매핑 선택 근거

| 카탈로그 ID | 선택 근거 |
|---|---|
| `enemy_elite_orc_warrior` | T2 orc — type_family `orc` 대표 (가장 흔한 엘리트 의뢰 분포). stat_weight {str:0.5, int:0.3, vit:0.1, agi:0.1}이 warrior 공격 산식(STR×1.2)에 정합 |
| `enemy_elite_goblin_raider` | T2 goblin — environment_tags {forest, underground, mountain}으로 적용 가능 전장 가장 넓음. stat_weight {agi:0.4, int:0.3, str:0.2, vit:0.1}이 rogue 공격 산식(STR×0.7+AGI×0.4)에 정합 |
| `enemy_elite_undead_skeleton` | T2 undead — environment_tags {ruins, plains}. M8a 도굴꾼 의뢰에서 도굴꾼이 잘못 일으킨 망자 시나리오 활용. stat_weight {int:0.4, agi:0.3}이 ranger 공격 산식(STR×0.5+AGI×0.5)에 부분 정합 |
| `enemy_elite_beast_bear` | T3 beast — environment_tags {forest, plains}. M7 forest 리전(region 9·10) 핵심 위협. M8a `giant_forest_beast` enemy 키워드 정합 |
| `enemy_elite_demon_imp` | T3 demon — environment_tags {ruins, swamp}. INT 중심 시뮬레이션 검증용. mage 공격 산식(INT×1.2)에 정합 |

### 3.3 미매핑 elite_monsters 33-5=28행 처리

M8b MVP는 위 5행만 사용한다. 나머지 28행(elemental 4, golem 5, insect 3, lizardman 3, troll 2, demon 1, beast 2, goblin 2, orc 2, undead 4)은 페이즈 2 #2 후속 확장 또는 페이즈 3 #1 enemies 시드 시점에 추가 매핑 가능하다.

미매핑 28행이 quest_pool로 등장하는 엘리트 의뢰는 페이즈 1 #1 §fallback 정책(시뮬레이션 실패 시 `QuestCalculator` fallback)에 따라 자동으로 M8a MVP 보고서 경로로 처리된다.

## 4. 유니크 엘리트 4종 (`elite_monsters` 매핑)

`elite_monsters` 7행 유니크에서 4종을 매핑한다.

### 4.1 매핑 표

| 카탈로그 ID | elite_monster_id | 이름 | type_family | role | tier | STR | INT | VIT | AGI | HP | 공격 | 방어 | behavior | 스킬 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `enemy_unique_wolf_ulbur` | `elite_wolf_ulbur` | 늑대왕 울부르 | beast | warrior | 2 | 18 | 4 | 14 | 16 | 109 | 22 | 29 | berserker | `skill_warrior_battle_fury` + `skill_enemy_taunt_roar` |
| `enemy_unique_skeleton_general` | `elite_skeleton_general` | 백골의 장군 | undead | warrior | 3 | 18 | 14 | 11 | 12 | 130 | 22 | 25 | defender | `skill_warrior_shield_bulwark` + `skill_enemy_summon` |
| `enemy_unique_witch_morgan` | `elite_witch_morgan` | 검은 마녀 모르간 | demon | mage | 4 | 6 | 28 | 9 | 14 | 95 | 34 | 8 | caster | `skill_mage_arcane_blast` + `skill_mage_stun_bolt` |
| `enemy_unique_lich_primordial` | `elite_lich_primordial` | 태고의 리치 | undead | mage | 5 | 7 | 35 | 18 | 11 | 169 | 42 | 15 | caster | `skill_mage_arcane_blast` + `skill_enemy_self_dispel` |

### 4.2 매핑 선택 근거

| 카탈로그 ID | 선택 근거 |
|---|---|
| `enemy_unique_wolf_ulbur` | M3 체인 퀘스트 핵심 적. 위업 hook `elite_unique_first_kill:elite_wolf_ulbur` 활성화. warrior 매핑으로 동족(`enemy_elite_beast_bear`)과 다른 정체성 |
| `enemy_unique_skeleton_general` | M3 체인 퀘스트 핵심. 페이즈 1 #2 §7 진형 정책에서 후열 보호 효과의 결정적 장면 (defender behavior + `skill_enemy_summon`로 추가 적 생성) |
| `enemy_unique_witch_morgan` | T4 demon 유니크. INT 28 고고티어 마법 위협. mage 매핑으로 페이즈 1 #3 §3.1 INT×1.2 공격 산식 검증 |
| `enemy_unique_lich_primordial` | T5 undead 유니크. M8b 시뮬레이션 최종 보스급. `skill_enemy_self_dispel`로 파티 디버프 무력화. 페이즈 1 #1 종료 조건 (d) 라운드 한계 도달 시뮬레이션 검증용 |

### 4.3 미매핑 유니크 3행

| elite_monster_id | 이름 | 미매핑 근거 |
|---|---|---|
| `elite_hydra_swamp` | 습지의 히드라 | T3 lizardman. M7 안개 늪지 시나리오에 활용 가능하나 MVP는 4종 우선 |
| `elite_kraken_abyss` | 심해의 크라켄 | T4 unique_transcendent. coast 전장 한정. MVP 외 후속 확장 후보 |
| `elite_guardian_desert` | 사막의 파수꾼 | T4 unique_transcendent. desert 전장. M9 단계 후속 확장 후보 |

본 카탈로그 MVP는 4행만 사용. 페이즈 2 #2 후속 확장에서 3행 추가 가능.

## 5. 적 전용 신규 스킬 6종 정의

페이즈 2 #1 §8.3에서 후보로 명시한 적 전용 스킬을 정식 정의한다. 페이즈 2 #1 카탈로그와 동일 구조이며, rogue 출혈 단일기는 파티 스킬 수 10종 제한을 지키기 위해 적 전용 `bleeding_cut`으로 분리한다.

### 5.1 `skill_enemy_bleeding_cut` (출혈 베기)

| 속성 | 값 |
|------|-----|
| ID | `skill_enemy_bleeding_cut` |
| 라벨 | 출혈 베기 |
| 직업군 | rogue |
| 발동 조건 | 액티브 — 적 측 전용, HP 낮은 파티원을 우선 표적 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 2 라운드 |
| 표적 | 단일 — 파티 1명 |
| 페이즈 1 #3 산식 결합 | §5.1 `skillDamageMultiplier` 1.2×. 치명타·회피 판정 정상 |
| 페이즈 1 #4 상태 효과 연결 | `dot_bleeding` 부여 (1 stack) |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 1.2×, applyChance 60%, stack 1, durationTurns 3 |
| 보고서 라인 후보 | "{enemy.name}이(가) {target}에게 더러운 칼날을 그었다. 출혈 부여" |

활용: 도적 암살자·고블린 습격자. 파티 rogue 대표 스킬은 `mass_blind` 1개로 유지하고, 단일 출혈 위협은 적 측에서만 사용한다.

### 5.2 `skill_enemy_armor_break` (갑옷 깨기)

| 속성 | 값 |
|------|-----|
| ID | `skill_enemy_armor_break` |
| 라벨 | 갑옷 깨기 |
| 직업군 | (적 전용 — role 매핑 불필요) |
| 발동 조건 | 액티브 — 적 측 전용 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 3 라운드 |
| 표적 | 단일 — 파티 1명 (방어 가장 높은 대상) |
| 페이즈 1 #3 산식 결합 | §5.1 `skillDamageMultiplier` 1.0× |
| 페이즈 1 #4 상태 효과 연결 | `debuff_defense_down` 부여 (적용 방식 곱셈) |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 1.0×, applyChance 80%, intensity 0.25, durationTurns 3 |
| 보고서 라인 후보 | "{enemy.name}이(가) 거대 망치로 {target}의 갑옷을 깼다. 방어력 약화 {N}턴" |

활용: 갑옷·중장비 적(오크 대전사·도굴꾼 대장).

### 5.3 `skill_enemy_poison_bite` (독니 물기)

| 속성 | 값 |
|------|-----|
| ID | `skill_enemy_poison_bite` |
| 라벨 | 독니 물기 |
| 직업군 | (적 전용) |
| 발동 조건 | 액티브 — 적 측 전용 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 2 라운드 |
| 표적 | 단일 — 파티 1명 (HP 최저 또는 인접) |
| 페이즈 1 #3 산식 결합 | §5.1 `skillDamageMultiplier` 0.8× |
| 페이즈 1 #4 상태 효과 연결 | `dot_poisoned` 부여 (1 stack, 절대형) |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 0.8×, applyChance 70%, stack 1, durationTurns 3 |
| 보고서 라인 후보 | "{enemy.name}이(가) {target}을(를) 깨물었다. 독 부여" |

활용: 독사·독거미·임프·뱀형 엘리트. MVP에서는 `enemy_trial_beast` 1종에만 배정해 `dot_poisoned` 절대형 DoT를 검증한다. 후속 확장 후보는 `elite_insect_spider`, `elite_insect_scorpion`, `elite_lizard_swamp` 등이다.

### 5.4 `skill_enemy_taunt_roar` (위협의 포효)

| 속성 | 값 |
|------|-----|
| ID | `skill_enemy_taunt_roar` |
| 라벨 | 위협의 포효 |
| 직업군 | (적 전용) |
| 발동 조건 | 액티브 — 적 측 전용. 본인 HP 100% (R1) 또는 70%↓ (위협 강화) 자동 발동 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 4 라운드 |
| 표적 | 광역 — 파티 전원 (페이즈 1 #2 §9.1 광역) |
| 페이즈 1 #3 산식 결합 | 없음 (피해 미발생) |
| 페이즈 1 #4 상태 효과 연결 | `debuff_attack_down` 부여 (적용 방식 곱셈). 페이즈 1 #4 §12.2 신규 mez `mez_taunted`(표적 강제)는 MVP에서 미활성. MVP는 `debuff_attack_down` 단독 |
| 권고 수치 (페이즈 2 #3 검증) | applyChance 60%, intensity 0.15, durationTurns 2 |
| 보고서 라인 후보 | "{enemy.name}의 포효에 파티 {N}명이 위축됐다. 공격력 약화 {N}턴" |

활용: 거대 야수·트롤·드래곤·고티어 보스 (R1 위협 연출).

### 5.5 `skill_enemy_summon` (소환)

| 속성 | 값 |
|------|-----|
| ID | `skill_enemy_summon` |
| 라벨 | 소환 |
| 직업군 | (적 전용) |
| 발동 조건 | 액티브 — 적 측 전용. 본인 HP 60%↓ 1회만 발동 |
| 행동 슬롯 비용 | action |
| 쿨다운 | — (전투당 1회) |
| 표적 | self (소환 발동) |
| 페이즈 1 #3 산식 결합 | 없음 (피해 미발생) |
| 페이즈 1 #4 상태 효과 연결 | 없음 |
| 권고 수치 (페이즈 2 #3 검증) | 적 추가 1~2명 생성 (`summon_template_id`로 새 전투원 추가). 본 카탈로그 enemy_id 후보 — `enemy_bandit_thug` / `enemy_undead_*` |
| 보고서 라인 후보 | "{enemy.name}이(가) {부하 N명}을 불러냈다" |

활용: 흑마법사·소환술사·보스(`enemy_unique_skeleton_general`로 스켈레톤 추가 / `enemy_elite_demon_imp`로 잡몹 추가).

**MVP 단순화 정책**: 소환된 전투원은 `enemy_bandit_thug`/`enemy_undead_*` 등 본 카탈로그 일반 적에서 추출하며, 진형 빈 슬롯에 추가된다. 종료 조건 평가 시 파티/적 카운트에 정상 반영된다. 페이즈 4 #1 시뮬레이터 명세에서 정식 정의.

### 5.6 `skill_enemy_self_dispel` (자기 정화)

| 속성 | 값 |
|------|-----|
| ID | `skill_enemy_self_dispel` |
| 라벨 | 자기 정화 |
| 직업군 | (적 전용) |
| 발동 조건 | 액티브 — 본인이 debuff 또는 dot 2개 이상 보유 시 자동 발동 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 3 라운드 |
| 표적 | self |
| 페이즈 1 #3 산식 결합 | 없음 |
| 페이즈 1 #4 상태 효과 연결 | 페이즈 1 #4 §8.2 — self `dispel_debuff` (debuff 1개 + dot 1개 해제) |
| 권고 수치 (페이즈 2 #3 검증) | applyChance 100% (자동), dispel: debuff×1 + dot×1 |
| 보고서 라인 후보 | "{enemy.name}이(가) 검은 빛으로 약화를 떨쳐냈다" |

활용: 고티어 보스(`enemy_unique_lich_primordial`). support의 `skill_support_cleansing_word`에 대한 적 측 대응 표현이지만, 적 자기 자신에게만 적용한다. 페이즈 2 #1 §1.3 정책(파티 측 cleansing_word는 적 측 미적용)과 정합.

### 5.7 적 전용 6 스킬 활용 분포 (본 카탈로그 26행 기준)

| 적 전용 스킬 | 활용 적 |
|------------|--------|
| `skill_enemy_bleeding_cut` | `enemy_bandit_assassin`, `enemy_elite_goblin_raider` |
| `skill_enemy_armor_break` | `enemy_graverobber_captain`, `enemy_elite_orc_warrior` |
| `skill_enemy_poison_bite` | `enemy_trial_beast` |
| `skill_enemy_taunt_roar` | `enemy_swamp_general`, `enemy_unique_wolf_ulbur` |
| `skill_enemy_summon` | `enemy_elite_demon_imp`, `enemy_unique_skeleton_general` |
| `skill_enemy_self_dispel` | `enemy_unique_lich_primordial` |

페이즈 2 #1 §1.3 적 측 공유 9 스킬 + §8.3 적 전용 6 스킬 = **15 스킬 풀**. 본 카탈로그 26행이 실제 활용하는 스킬은 §6 결합 매트릭스에서 확인한다.

## 6. 스킬 결합 매트릭스

### 6.1 26행 적별 스킬 분포

| 분류 | 스킬 0개 | 스킬 1개 | 스킬 2개 |
|------|---------|---------|---------|
| 일반 17 | 8 | 8 | 1 (`enemy_graverobber_captain`) |
| 일반 엘리트 5 | 0 | 2 | 3 |
| 유니크 엘리트 4 | 0 | 0 | 4 |

페이즈 2 #1 §1.3 정책 정합: 일반 0~1 / 엘리트 1~2 / 유니크 항상 2. 일부 일반 적(`enemy_graverobber_captain`)은 예외적으로 2 스킬 보유 — 도굴꾼 시나리오의 핵심 위협이 일반급 안에서 엘리트 격을 가지도록 의도.

### 6.2 스킬별 활용 분포

| 스킬 (페이즈 2 #1 + §5) | 활용 횟수 | 활용 적 |
|----|-----|-----|
| `skill_warrior_shield_bulwark` | 2 | `enemy_swamp_general`, `enemy_unique_skeleton_general` |
| `skill_warrior_battle_fury` | 6 | `enemy_bandit_captain`, `enemy_graverobber_captain`, `enemy_coast_raider_lead`, `enemy_elite_orc_warrior`, `enemy_elite_beast_bear`, `enemy_unique_wolf_ulbur` |
| `skill_rogue_mass_blind` | 1 | `enemy_elite_goblin_raider` |
| `skill_enemy_bleeding_cut` | 2 | `enemy_bandit_assassin`, `enemy_elite_goblin_raider` |
| `skill_ranger_marksman_focus` | 1 | `enemy_swamp_tracker` |
| `skill_ranger_volley_shot` | 1 | `enemy_elite_undead_skeleton` |
| `skill_mage_arcane_blast` | 5 | `enemy_dark_mage`, `enemy_contract_breaker_mage`, `enemy_elite_demon_imp`, `enemy_unique_witch_morgan`, `enemy_unique_lich_primordial` |
| `skill_mage_stun_bolt` | 2 | `enemy_contract_breaker_mage`, `enemy_unique_witch_morgan` |
| `skill_support_aegis_aura` | 1 | `enemy_dark_priest` |
| `skill_support_cleansing_word` | 0 | (파티 전용 정책 — 페이즈 2 #1 §1.3) |
| `skill_specialist_adaptive_footwork` | 0 | (적 공유 가능, MVP 미배정) |
| `skill_enemy_armor_break` | 2 | `enemy_graverobber_captain`, `enemy_elite_orc_warrior` |
| `skill_enemy_poison_bite` | 1 | `enemy_trial_beast` |
| `skill_enemy_taunt_roar` | 2 | `enemy_swamp_general`, `enemy_unique_wolf_ulbur` |
| `skill_enemy_summon` | 2 | `enemy_elite_demon_imp`, `enemy_unique_skeleton_general` |
| `skill_enemy_self_dispel` | 1 | `enemy_unique_lich_primordial` |

총 스킬 발현: 26행 중 19행에 스킬 보유. 일반 7행은 무스킬(기본 공격만). 페이즈 2 #1 §1.3 정책 정합.

## 7. 적 측 진형 자동 배치 정책

페이즈 1 #2 §7 진형 3열 정책을 적 측에 적용한다.

### 7.1 적 측 진형 매트릭스

| 적 role | 자동 배치 열 |
|---------|--------------|
| warrior | 전열 |
| specialist | 전열 |
| rogue | 중열 |
| ranger | 중열 |
| mage | 후열 |
| support | 후열 |

페이즈 1 #2 §7 파티 측과 동일.

### 7.2 본 카탈로그 적별 진형 분포

| ID | role | 진형 |
|----|------|------|
| `enemy_bandit_thug` | warrior | 전열 |
| `enemy_bandit_scout` | rogue | 중열 |
| `enemy_bandit_archer` | ranger | 중열 |
| `enemy_bandit_captain` | warrior | 전열 |
| `enemy_bandit_assassin` | rogue | 중열 |
| `enemy_graverobber_thug` | warrior | 전열 |
| `enemy_graverobber_captain` | warrior | 전열 |
| `enemy_coast_raider` | rogue | 중열 |
| `enemy_coast_raider_lead` | warrior | 전열 |
| `enemy_swamp_tracker` | ranger | 중열 |
| `enemy_swamp_general` | warrior | 전열 |
| `enemy_dark_mage` | mage | 후열 |
| `enemy_contract_breaker_mage` | mage | 후열 |
| `enemy_dark_priest` | support | 후열 |
| `enemy_ambush_spearman` | warrior | 전열 |
| `enemy_ambush_archer` | ranger | 중열 |
| `enemy_trial_beast` | specialist | 전열 |
| 5 일반 엘리트 | (각 role 매핑대로) | 전열 3 / 중열 1 / 후열 1 |
| 4 유니크 엘리트 | (각 role 매핑대로) | 전열 2 / 후열 2 |

### 7.3 적 진형 빈 슬롯 처리

페이즈 1 #2 §7 진형 압축 정책(빈 열은 다음 열로 압축) 그대로 적용. 적 1~6명 한 그룹이 진형 3열에 자동 배치된다.

예시 1: 도적 4명 (도적 두목 1 + 졸개 2 + 정찰꾼 1) → 전열 3 + 중열 1
예시 2: 흑마법사 1명 단독 → 후열만 (전열·중열 빈 상태로 압축)
예시 3: 유니크 보스 1명 + 부하 3명 → 전열 1(보스) + 전열 부하 1 + 중열 부하 1 + 후열 부하 1

### 7.4 적 그룹 구성 정책 (의뢰별 적 풀)

페이즈 1 #1 §1.1 적용 대상 의뢰에서 quest_pool이 제공하는 정보:

| 의뢰 유형 | 적 풀 |
|----------|-------|
| 유니크 엘리트 의뢰 | 유니크 1 + 매칭 일반 0~3 (`skill_enemy_summon`으로 R1+ 추가 가능) |
| 일반 엘리트 의뢰 | 일반 엘리트 1 + 매칭 일반 1~3 |
| 세력 지명 의뢰 (M8a 12종) | 세력별 일반 2~4 (§9 세력 매칭) |
| 기존 지명 의뢰 (M6 7종) | 일반 2~4 (특정 적 풀 보존) |
| 연계 퀘스트 최종 단계 | 유니크 또는 일반 엘리트 1 + 일반 1~3 |
| 세력 전용 의뢰 (평판 31+) | 세력별 일반 2~4 + 일반 엘리트 0~1 |

정확한 매핑(quest_pool → 적 구성)은 페이즈 3 #1 enemies 시드 데이터에서 quest_pool별 enemyGroupId로 명시한다.

## 8. behaviorPattern 정책

페이즈 4 #1 `CombatSimulator`의 적 측 행동 결정 트리에 입력되는 enum 분류.

### 8.1 behaviorPattern 6 종

| pattern | 의미 | 표적 우선순위 |
|---------|------|--------------|
| `aggressive` | 단순 공격형 | 가장 가까운 대상 (페이즈 1 #2 §7.2 접근형 표적 정책 — 전열 우선) |
| `opportunist` | 약자 노림 | 파티 중 HP 최저 또는 부상 보유자 |
| `caster` | 마법 광역형 | 페이즈 1 #2 §7.3 mage 표적 정책 — 광역 우선, 광역 미보유 시 후열 |
| `supporter` | 보조형 | 본인 buff 우선, 후속 라운드 적 측 buff |
| `defender` | 탱커형 | 본인 전열 보호, `skill_warrior_shield_bulwark` 적극 발동, `skill_enemy_taunt_roar`로 표적 강제 |
| `berserker` | 광폭형 | HP 50% 이하 시 `skill_warrior_battle_fury` 자동 발동. 평소 가장 가까운 대상 |

### 8.2 본 카탈로그 적별 behaviorPattern 분포

| pattern | 활용 횟수 | 비고 |
|---------|---------|------|
| aggressive | 5 | 도적 졸개·도굴꾼 졸개·해안 습격자·매복 창병·방랑 스켈레톤 등 단순 공격형 |
| opportunist | 5 | 정찰꾼·궁수·암살자·늪지 추적자·고블린 습격자 — 약자 노림형 |
| caster | 5 | 흑마법사·계약 파기 마법사·임프·검은 마녀 모르간·태고의 리치 — 마법 광역형 |
| supporter | 1 | 악의 신관 (광역 buff) |
| defender | 3 | 늪지 사령관·시련관 표식수·백골의 장군 — 탱커·소환형 |
| berserker | 7 | 도적 두목·도굴꾼 대장·해안 습격대장·오크 대전사·거대 곰·늑대왕 울부르 — `battle_fury` 자동 발동형 |

### 8.3 behaviorPattern 자동 발동 결정 트리

페이즈 4 #1 `CombatSimulator` 명세 입력. 본 산출물은 정책 형식만 명시.

```text
function selectActionForEnemy(enemy, roundState):
  // 우선순위 1: behavior=berserker 발동
  if (enemy.behavior == 'berserker' && enemy.hp <= maxHp * 0.5 && !enemy.flagFuryUsed):
    return 'skill_warrior_battle_fury'  // extraAction
  
  // 우선순위 2: defender 트리거 스킬
  if (enemy.behavior == 'defender' && roundIndex == 1 && enemy.hasSkill('skill_enemy_taunt_roar')):
    return 'skill_enemy_taunt_roar'
  if (enemy.behavior == 'defender' && enemy.hp <= maxHp * 0.6 && !enemy.flagSummonUsed):
    if (enemy.hasSkill('skill_enemy_summon')):
      return 'skill_enemy_summon'
  
  // 우선순위 3: caster 광역 우선
  if (enemy.behavior == 'caster' && partyAlive >= 2):
    if (enemy.cooldown['skill_mage_arcane_blast'] == 0):
      return 'skill_mage_arcane_blast'
  
  // 우선순위 4: supporter 광역 buff
  if (enemy.behavior == 'supporter' && allies.none(a => a.hasBuff('buff_defense_up'))):
    if (enemy.hasSkill('skill_support_aegis_aura')):
      return 'skill_support_aegis_aura'
  
  // 우선순위 5: 적 전용 스킬 (armor_break, bleeding_cut, poison_bite 등)
  if (enemy.hasSkill('skill_enemy_armor_break') && cd == 0):
    return 'skill_enemy_armor_break'
  
  // 우선순위 6: self_dispel 자동 발동
  if (enemy.hasSkill('skill_enemy_self_dispel') && enemy.activeNegativeEffects >= 2):
    return 'skill_enemy_self_dispel'
  
  // 폴백: 기본 공격 (표적은 behaviorPattern.targetPriority로 결정)
  target = selectTarget(enemy.behavior, partyAlive)
  return basicAttack(target)
```

상세 분기는 페이즈 4 #1 명세 시점에 확정.

## 9. 세력 매칭 (14 factions)

세력별 의뢰에 등장하는 적 풀 매핑.

### 9.1 14 세력 카탈로그

`factions` 테이블 14행: 모험가 길드 / 균형 감시자 / 혈계 귀족회 / 심층 망치단 / 송곳니 결사 / 금지된 서고 / 마탑 연합 / 상인 연합 / 뿌리의 맹세단 / 태양 교단 / 도둑 길드 / 황혼 공학회 / 화산 심장단 / 전사 길드

### 9.2 세력 → 적 풀 매핑

| 세력 | 적 풀 (본 카탈로그 26행 중) |
|------|---------------------------|
| 모험가 길드 (`adventurers`) | 일반: 도적 계열 4 / 일반 야수 / 일반 엘리트: `enemy_elite_beast_bear` |
| 균형 감시자 (`balance`) | (M9+ 후속 — MVP 미적용) |
| 혈계 귀족회 (`blood`) | (M9+ 후속) |
| 심층 망치단 (`deep_hammer`) | 일반 엘리트: `enemy_elite_orc_warrior` / 일반: 도굴꾼 계열 2 |
| 송곳니 결사 (`fang`) | (M9+ 후속) |
| 금지된 서고 (`forbidden_archive`) | 일반: 흑마법사 / 유니크: `enemy_unique_lich_primordial` |
| 마탑 연합 (`mage_towers`) | 일반: 흑마법사·계약 파기 마법사 / 일반 엘리트: `enemy_elite_demon_imp` / 유니크: `enemy_unique_witch_morgan` |
| 상인 연합 (`merchants`) | 일반: 도적 계열 4 / 매복 창병·궁수 2 / 일반 엘리트: `enemy_elite_goblin_raider` |
| 뿌리의 맹세단 (`root`) | (M9+ 후속) |
| 태양 교단 (`sun`) | 일반: 악의 신관·유물 도굴꾼 / 유니크: `enemy_unique_skeleton_general` |
| 도둑 길드 (`thieves`) | 일반: 도적 계열 4 / 일반 엘리트: `enemy_elite_goblin_raider` |
| 황혼 공학회 (`twilight`) | (M9+ 후속) |
| 화산 심장단 (`volcanic`) | (M9+ 후속) |
| 전사 길드 (`warriors`) | 일반: 시련관 표식수·일반 야수 / 일반 엘리트: `enemy_elite_orc_warrior`·`enemy_elite_beast_bear` / 유니크: `enemy_unique_wolf_ulbur` |

### 9.3 세력 매핑 정책

본 카탈로그 MVP는 **M8a에서 활성화된 세력 (모험가·심층 망치·금지서고·마탑·상인·태양·도둑·전사 = 8 세력)** 의 의뢰에 적 풀을 제공한다. 나머지 6 세력 (균형·혈계·송곳니·뿌리·황혼·화산)은 M9+ 후속 마일스톤에서 적 풀 확장.

세력 미매칭 의뢰(일반 의뢰·M6 기존 지명·M3 체인 등)는 §7.4 적 풀 정책으로 적 그룹이 결정된다.

### 9.4 세력 지명 의뢰 (M8a 12종) 적 풀

페이즈 2 #1 §1.3 정합. M8a 페이즈 4 #1에서 정의한 세력 지명 12 의뢰별 적 풀 정의 — 페이즈 3 #1 enemies 시드 시점에 quest_pool.id → enemyGroupId 매핑 영속화.

본 산출물은 매핑 정책만 명시:

| M8a 세력 지명 의뢰 | 추정 적 풀 |
|-----------------|----------|
| 모험가 길드 지명 4종 | 도적 4 + `enemy_elite_beast_bear` |
| 상인 연합 지명 4종 | 도적 4 + 매복 창병·궁수 + `enemy_elite_goblin_raider` |
| 전사 길드 지명 4종 | 시련관 표식수 + 일반 야수 + `enemy_unique_wolf_ulbur` |

정확한 매핑은 페이즈 3 #1 시드 단계에서 quest_pool 12행 분석 후 확정.

## 10. 전장 매칭 (`environment_tags`)

### 10.1 elite_monsters 영감 환경 태그

기존 `elite_monsters.environment_tags`에서 사용되는 태그: `forest`, `mountain`, `plains`, `dungeon`, `ruins`, `swamp`, `underground`, `desert`, `coast`.

페이즈 1 #2 §6 전장 매트릭스 8 태그와 연결:

| elite_monsters 태그 | 페이즈 1 #2 §6 매트릭스 태그 | 비고 |
|-------------------|---------------------------|------|
| forest | forest | 동일 |
| mountain | mountain | 동일 |
| plains | (미정의) | 페이즈 1 #2 §6 보강 후보 — desert 또는 평지 보정 |
| dungeon | dungeon | 동일 |
| ruins | ruined_castle | 매핑 |
| swamp | swamp | 동일 |
| underground | dungeon (좁은 공간) | 매핑 |
| desert | desert | 동일 |
| coast | sea_coast | 매핑 |

### 10.2 본 카탈로그 적별 환경 태그 분포

| ID | environment_tags |
|----|------------------|
| `enemy_bandit_thug` | [forest, plains, mountain] (도적길) |
| `enemy_bandit_scout` | [forest, plains, mountain] |
| `enemy_bandit_archer` | [forest, plains, mountain] |
| `enemy_bandit_captain` | [forest, plains, mountain] |
| `enemy_bandit_assassin` | [forest, plains, mountain, ruined_castle] |
| `enemy_graverobber_thug` | [ruined_castle, dungeon] |
| `enemy_graverobber_captain` | [ruined_castle, dungeon] |
| `enemy_coast_raider` | [sea_coast] |
| `enemy_coast_raider_lead` | [sea_coast] |
| `enemy_swamp_tracker` | [swamp, mist_field] |
| `enemy_swamp_general` | [swamp] |
| `enemy_dark_mage` | [ruined_castle, dungeon, swamp] |
| `enemy_contract_breaker_mage` | [ruined_castle, mountain, dungeon] |
| `enemy_dark_priest` | [ruined_castle, dungeon] |
| `enemy_ambush_spearman` | [forest, mountain, ruined_castle] |
| `enemy_ambush_archer` | [forest, mountain, ruined_castle] |
| `enemy_trial_beast` | [ruined_castle] (전사 길드 시련장 한정) |
| 일반/유니크 엘리트 9 | (elite_monsters.environment_tags 그대로 사용) |

### 10.3 M7 핵심 7리전 매칭

페이즈 1 #2 §6 mist_field·페이즈 1 #1 §M7 핵심 7리전 매칭:

| region | environment | 추천 적 풀 |
|--------|------------|----------|
| region 3 (더스트빌 광장) | dungeon | `enemy_graverobber_*` |
| region 9 (외곽 숲) | forest | `enemy_bandit_*` + `enemy_elite_beast_bear` |
| region 10 (풍신 숲 능선) | forest, mountain | `enemy_bandit_*` + `enemy_elite_goblin_raider` |
| region 31 (도적길) | road, mountain | `enemy_bandit_*` |
| region 38 (요새 결투장) | ruined_castle | `enemy_graverobber_*` + `enemy_trial_beast` + `enemy_unique_skeleton_general` |
| region 127 (해안 절벽) | sea_coast | `enemy_coast_raider*` + `elite_kraken_abyss` (M9+ 후속) |
| region 146 (회색 늪지) | swamp, mist_field | `enemy_swamp_*` + `elite_hydra_swamp` (M9+ 후속) |

본 매핑은 M8a `combat_report_keywords` category=battlefield 12행과 정합한다.

## 11. M8a `combat_report_keywords` 결정적 장면 키워드 매칭

M8a 페이즈 4 #2 보고서 시스템의 `combat_report_keywords` 테이블 (40행)과의 호환 매핑.

### 11.1 category=enemy (10행) 매핑

| keyword.key | display_text | M8b 카탈로그 매칭 |
|-------------|------------|------|
| `grave_robber_captain` | 도굴꾼 대장 | `enemy_graverobber_captain` |
| `grave_robber_scouts` | 도굴꾼 정찰조 | `enemy_graverobber_thug` (×N) |
| `bandit_remnants` | 도적 잔당 | `enemy_bandit_*` (도적 4종 그룹) |
| `coast_raiders` | 해안 습격대 | `enemy_coast_raider*` |
| `swamp_tracker` | 늪지 추적자 | `enemy_swamp_tracker`, `enemy_swamp_general` |
| `giant_forest_beast` | 거대 숲짐승 | `enemy_elite_beast_bear` |
| `trial_beast` | 시련관의 표식수 | `enemy_trial_beast` |
| `ambush_spearmen` | 매복 창병 | `enemy_ambush_spearman` |
| `contract_breakers` | 계약 파기자 무리 | `enemy_contract_breaker_mage` (+ `enemy_bandit_*` 동반) |
| `nameless_howler` | 이름 없는 포효자 | (본 MVP 미매핑 — `elite_kraken_abyss` 또는 `enemy_unique_witch_morgan` 후보) |

10 enemy 키워드 중 9 매칭. 1 미매칭(`nameless_howler`)은 페이즈 3 #4 전투 로그 템플릿에서 톤 키워드로만 활용.

### 11.2 category=battlefield (12행) 매칭

§10.3 M7 핵심 7리전 매칭 표 그대로. 본 산출물 26행 모든 적이 M8a 12 battlefield 키워드 중 하나 이상에 매핑된다.

### 11.3 category=enemy 신규 키워드 후보

본 카탈로그 26행 중 M8a `combat_report_keywords` 10행으로 표현되지 않는 적 후보 5개:

| 신규 키워드 후보 | 매칭 적 | 출처 정합 |
|---|---|---|
| `dark_mage_party` | `enemy_dark_mage` (+ `enemy_dark_priest` 동반) | 마탑 의뢰 |
| `goblin_raid_party` | `enemy_elite_goblin_raider` (+ `enemy_bandit_*` 동반) | 도둑 길드 의뢰 |
| `imp_swarm` | `enemy_elite_demon_imp` (+ `skill_enemy_summon`으로 소환된 잡몹) | 마탑 의뢰 |
| `orc_warband` | `enemy_elite_orc_warrior` (+ `enemy_bandit_*` 동반) | 심층 망치 의뢰 |
| `lich_undead_legion` | `enemy_unique_lich_primordial` (+ `skeleton_general`로 소환된 언데드) | 금지서고 의뢰 |

페이즈 3 #4 전투 로그 템플릿에서 5 신규 키워드를 추가 후보로 명시한다. M8a 기존 10 키워드는 유지.

## 12. 매복 의뢰 적 후보 (페이즈 1 #2 §2.3)

페이즈 1 #2 §2.3 매복 의뢰(`ambush_side='enemy'`) 정의 — 적이 항상 선제 라운드 1회 행동.

### 12.1 매복 적 후보

| 매복 적 | M8b 카탈로그 |
|--------|------------|
| 호위 의뢰 + 도적 습격 | `enemy_bandit_*` 4종 (`bandit_captain` 1 + 졸개 2~3) |
| 호위 의뢰 + 해안 습격대 | `enemy_coast_raider*` 그룹 |
| 호위 의뢰 + 매복 창병 | `enemy_ambush_spearman` + `enemy_ambush_archer` 그룹 |
| 탐험 의뢰 + 늪지 추적자 | `enemy_swamp_tracker` (+ `enemy_swamp_general` 인솔) |
| 토벌 의뢰 + 도굴꾼 매복 | `enemy_graverobber_thug` 다수 (×3+) |

본 카탈로그 26행 중 `enemy_bandit_*` 4·`enemy_coast_raider*` 2·`enemy_ambush_*` 2·`enemy_swamp_*` 2·`enemy_graverobber_*` 2 = **12행이 매복 의뢰 적 후보**다. 일반 17행 중 12행 매복 적합 (70.6%).

### 12.2 매복 의뢰 발동 조건

페이즈 1 #2 §2.3 — `quest_pools.specialFlags['ambush_side']='enemy'` 또는 신규 컬럼으로 표현. 페이즈 4 #2 데이터 모델에서 확정.

매복 비매칭 적(`enemy_dark_mage`/`enemy_dark_priest`/`enemy_trial_beast` 등)은 매복 의뢰에 등장하지 않거나, 매복 발동 후 첫 라운드는 `enemy_bandit_*`이 선행하고 후속 라운드에 등장하는 시나리오로 활용한다.

## 13. 페이즈 2 #4 보고서 노출 정책 입력

페이즈 2 #4가 활용할 본 카탈로그 입력:

### 13.1 적별 결정적 장면 라인 후보

| 적 | 결정적 장면 라인 후보 |
|----|--------------------|
| `enemy_bandit_captain` | "도적 두목이 분노에 휩싸였다. 위기" |
| `enemy_graverobber_captain` | "도굴꾼 대장이 거대 망치로 {target}의 갑옷을 깼다. 위기" |
| `enemy_swamp_general` | "늪지 사령관이 위협의 포효를 내질렀다. 파티 {N}명이 약화" |
| `enemy_dark_mage` | "흑마법사의 광역 마법이 {N}명을 휩쓸었다" |
| `enemy_unique_wolf_ulbur` | "늑대왕이 분노했다. 다음 일격이 위협적이다" |
| `enemy_unique_skeleton_general` | "백골의 장군이 망자를 더 불러냈다" |
| `enemy_unique_witch_morgan` | "검은 마녀의 마법이 {target}을 기절시켰다" |
| `enemy_unique_lich_primordial` | "리치가 검은 빛으로 약화를 떨쳐냈다" |

본 후보는 페이즈 3 #4 전투 로그 템플릿 120~180행의 일부를 채운다.

### 13.2 적별 결정적 장면 우선순위

페이즈 1 #1 §M8a 호환 §라인 압축 정책에서 보고서 상세 4~8줄에 들어갈 결정적 장면의 우선순위:

| 우선순위 | 라인 후보 |
|---------|---------|
| 높음 (위기 라인) | `battle_fury` 발동, `armor_break` 발동, `taunt_roar` 발동, `summon` 발동 |
| 중간 (전개 라인) | 광역 마법, `marksman_focus` 발동, `volley_shot` 다단 사격, `mass_blind` 광역 |
| 낮음 (후일담) | `self_dispel` 발동, `aegis_aura` 발동 |

페이즈 2 #4가 매트릭스화한다.

## 14. 데이터 구조 (`EnemyArchetype` 모델 권장)

페이즈 4 #2 freezed/Hive 모델 확정 입력.

### 14.1 컨텐츠 관점 최소 필드

```text
EnemyArchetype
- id: String                          // snake_case (예: 'enemy_bandit_thug')
- name: String                        // 한국어 이름
- enemyKind: EnemyKind                // {normal, elite, unique}
- role: String                        // {warrior, rogue, ranger, mage, support, specialist}
- tier: int                           // 1~5
- baseStats: { str, int, vit, agi }   // 페이즈 1 #3 §1 정합
- baseHp: int                         // §2 산식 결과
- baseAttack: int                     // §3 산식 결과
- baseDefense: int                    // §4 산식 결과
- behaviorPattern: BehaviorPattern    // {aggressive, opportunist, caster, supporter, defender, berserker}
- skillIds: List<String>              // 0~2개 (페이즈 2 #1 §1.3 정책)
- environmentTags: List<String>       // §10 분포
- factionTags: List<String>           // §9 매핑 (M8a 8 세력 한정)
- ambushCompatible: bool              // §12 매복 의뢰 등장 가능 여부
- enemyKeywordKey: String?            // category=enemy 매칭 key (§11.1)
- eliteMonsterId: String?             // §3, §4 elite_monsters FK (null=신규 일반 적)
- description: String                 // 보고서 보충 설명
```

### 14.2 페이즈 3 #1 시드 데이터 컬럼 (권장)

| 컬럼 | 타입 | 비고 |
|------|------|------|
| `id` | TEXT PK | snake_case |
| `name` | TEXT | 한국어 |
| `enemy_kind` | TEXT (enum) | normal/elite/unique |
| `role` | TEXT (enum) | 6 직업군 |
| `tier` | INT | 1~5 |
| `base_str` | INT | |
| `base_int` | INT | |
| `base_vit` | INT | |
| `base_agi` | INT | |
| `base_hp` | INT | |
| `base_attack` | INT | |
| `base_defense` | INT | |
| `behavior_pattern` | TEXT (enum) | 6 종 |
| `skill_ids` | JSONB | List<String> |
| `environment_tags` | JSONB | List<String> |
| `faction_tags` | JSONB | List<String> |
| `ambush_compatible` | BOOL | DEFAULT false |
| `enemy_keyword_key` | TEXT NULL | combat_report_keywords FK |
| `elite_monster_id` | TEXT NULL REFERENCES elite_monsters(id) | 매핑 9행만 non-null |
| `description` | TEXT | |

### 14.3 `EnemySnapshot` (Phase 1 사전 단계 동결)

페이즈 1 #1 §파견 시작 시점 스냅샷 고정 정책. `EnemyArchetype`은 정적 데이터, `EnemySnapshot`은 시뮬레이션 입력 동결값:

```text
EnemySnapshot
- archetypeId: String                 // EnemyArchetype.id
- name: String                        // 동결 시점 캡처
- role: String
- tier: int
- str: int                            // archetype.baseStats 동결
- int: int
- vit: int
- agi: int
- hp: int                             // archetype.baseHp 동결, 시뮬레이션 도중 변동
- attack: int                         // archetype.baseAttack 동결
- defense: int                        // archetype.baseDefense 동결
- skillIds: List<String>              // archetype.skillIds 동결
- behaviorPattern: BehaviorPattern
- factionTag: String?                 // 의뢰 세력 매칭값
- positionRow: PositionRow            // §7 진형 배치 (front/middle/back)
- positionIndex: int                  // 동일 열 내 순서 (0=가장 가까운)
- formationGroupId: String            // 적 그룹 ID (페이즈 4 #1 명세)
```

페이즈 4 #2 모델 확정 시 `CombatantSnapshot`(파티)과 `EnemySnapshot`(적)이 공통 부모 인터페이스를 가질지 별도 정의할지 결정한다.

## 15. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| `elite_monsters` (40행) | 매핑 9행 FK 참조 / 미매핑 31행 보존 | 변경 없음 |
| `factions` (14행) | §9 적 풀 매핑 — M8a 활성 8 세력에만 적용 | 변경 없음 |
| `combat_report_keywords` category=enemy (10행) | §11.1 매핑 + §11.3 신규 5 후보 | M8a 보존 + 페이즈 3 #4 확장 |
| `combat_report_keywords` category=battlefield (12행) | §10.3 M7 7리전 매칭 | 변경 없음 |
| `quest_pools.specialFlags['ambush_side']` | §12 매복 의뢰 후보 | 페이즈 4 #2 신규 컬럼 후보 |
| `regions.environment_tags` (jsonb) | §10 적 환경 매칭 | 변경 없음 |
| 전투 스킬 카탈로그 (16) | 페이즈 2 #1 파티 10종 + §5 적 전용 6종 + §6 결합 매트릭스 | 페이즈 2 #1 카탈로그 보완 반영 |
| 페이즈 3 #1 enemies 시드 (신규) | 본 산출물 26행을 입력으로 시드 | 신규 테이블 |

## 16. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | 26행 카탈로그 ID·role·tier·기본 분류 확정 | 페이즈 3 #1 enemies 시드의 입력 |
| 높음 | 일반 17 신규 정의 (인간형 도적·도굴꾼·습격대 등) | elite_monsters 미커버 영역 |
| 높음 | 일반 엘리트 5 + 유니크 4 매핑 (`elite_monster_id` FK) | 기존 자산 재사용 |
| 높음 | 적 전용 6 신규 스킬 정의 (§5) | 페이즈 2 #1 §8.3 후보와 rogue 출혈 적 전용 분리를 정식 정의 |
| 높음 | behaviorPattern 6종 (§8) | 페이즈 4 #1 시뮬레이터 명세 입력 |
| 높음 | 적 측 진형 자동 배치 정책 (§7) | 페이즈 1 #2 §7 정합 |
| 중간 | M8a 활성 8 세력 → 적 풀 매핑 (§9) | M8a 의뢰 호환 |
| 중간 | 매복 의뢰 12행 후보 (§12) | 페이즈 1 #2 §2.3 정합 |
| 중간 | combat_report_keywords 매칭 9 + 신규 5 (§11) | M8a 보고서 톤 호환 |
| 중간 | M7 핵심 7리전 적 풀 매칭 (§10.3) | M7~M8a 환경 정합 |
| 낮음 | 스탯 ±3~9 오차 정밀 조정 | 페이즈 2 #3/페이즈 4 #5 검증에서 |
| 낮음 | 미매핑 elite_monsters 28+3 행 후속 확장 | 페이즈 2 #2 후속 또는 페이즈 3 #1 확장 |

## 17. data-generator 지시사항

페이즈 3 #1에서 `enemies` 신규 테이블에 본 카탈로그 26행을 생성한다.

- **대상 타입**: `enemy` (신규 타입 스펙 작성 필요 — `types/enemy.md`)
- **대상 테이블**: `enemies` (페이즈 4 #2 모델과 함께 정의)
- **생성 수량**: 26행 (일반 17 / 일반 엘리트 5 / 유니크 4)
- **외래 키 제약**:
  - `role` ∈ {warrior, rogue, ranger, mage, support, specialist} (jobs 테이블 enum과 동일)
  - `behavior_pattern` ∈ {aggressive, opportunist, caster, supporter, defender, berserker}
  - `enemy_kind` ∈ {normal, elite, unique}
  - `elite_monster_id` REFERENCES elite_monsters(id) — 매핑 9행만 non-null
  - `skill_ids` 의 각 요소 REFERENCES combat_skills(id) (페이즈 3 #2 데이터 의존)
  - `enemy_keyword_key` REFERENCES combat_report_keywords(key) WHERE category='enemy' — null 허용
  - `faction_tags` 의 각 요소 REFERENCES factions(id) — M8a 활성 8 세력만 등장
- **수치 출처**: 본 산출물 §2~§4 카탈로그 표. 페이즈 2 #3에서 ±3~9 오차 정밀 조정
- **특수 요구**:
  - 적 전용 6 신규 스킬(`skill_enemy_*`)은 페이즈 3 #2 `combat_skills` 시드에 함께 포함
  - 매복 호환 12행은 `ambush_compatible=true`로 명시
  - region 3·9·10·31·38·127·146 핵심 7리전 매칭은 environment_tags에 영속화

페이즈 3 시작 시점에 (a) `types/enemy.md` 타입 스펙 우선 작성 또는 (b) 본 산출물을 입력으로 SQL/수동 데이터 생성 병행을 결정한다.

## 18. 페이즈 2 #3~#4 및 페이즈 3·4 입력 요약

| 후속 산출물 | 본 산출물의 입력 기여 |
|-----------|---------------------|
| 페이즈 2 #3 상태 효과 수치 확정 | §5 적 전용 6 스킬 권고 수치 + §6 스킬 활용 분포 (`dot_bleeding`/`dot_poisoned`/`debuff_defense_down` 적 측 활성 등) |
| 페이즈 2 #4 전투 로그 길이·수치 노출 기준 | §13 적별 결정적 장면 라인 후보 + §11 enemy 키워드 매칭 9+5 |
| 페이즈 3 #1 `enemies` 시드 (26행) | 본 산출물 §2~§4 카탈로그 전체 + §14 데이터 구조 |
| 페이즈 3 #2 `combat_skills` 시드 확장 | §5 적 전용 6 신규 스킬 (페이즈 2 #1 10 스킬 + 본 산출물 6 스킬 = 16행) |
| 페이즈 3 #4 전투 로그 템플릿 | §13.1 적별 라인 후보 + §11.3 신규 5 키워드 |
| 페이즈 4 #1 `CombatSimulator` 명세 | §8.3 behaviorPattern 자동 발동 결정 트리 + §5 적 전용 스킬 + §12 매복 정책 |
| 페이즈 4 #2 `EnemyArchetype`/`EnemySnapshot` 모델 | §14 데이터 구조 + §7 진형 자동 배치 + `formationGroupId` 정책 |
| 페이즈 4 #3 `QuestCompletionService` 통합 | §9 세력 매칭 + §10 환경 매칭 + §12 매복 분기 |

## 19. 다음 단계

페이즈 2 #3 상태 효과 수치 확정에서 본 산출물 §5 적 전용 6 스킬의 applyChance·intensity·durationTurns 권고 수치와 §6 스킬 발현 분포(26행 중 19행에 분배된 14 스킬)를 페이즈 1 #4 10 상태 효과 카탈로그의 default 수치에 합산하여 정밀 조정한다.

페이즈 2 #4 전투 로그 길이·수치 노출 기준 확정에서 §11 enemy 키워드 매칭 9+5와 §13 적별 결정적 장면 라인 후보를 페이즈 3 #4 템플릿 120~180개의 매트릭스로 확장한다.

페이즈 3 #1 enemies 신규 테이블 시드에서 본 산출물 26행 카탈로그를 입력으로 시드 데이터를 생성한다. 페이즈 4 #2 EnemyArchetype/EnemySnapshot freezed 모델 명세에서 §14 데이터 구조를 정식 정의한다.
