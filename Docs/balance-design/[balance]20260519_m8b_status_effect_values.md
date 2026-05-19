# M8b 상태 효과 수치 확정 밸런스 리포트

> 작성일: 2026-05-19
> 유형: 밸런스 분석 / 수치 확정
> 분석 대상: M8b 전투 시뮬레이터 상태 효과 10 타입 (페이즈 1 #4 카탈로그)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4) — 카탈로그 구조 + hook 매핑 + stackPolicy
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1) — 파티 10 스킬 권고 수치
> - `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2) — 적 전용 6 스킬 + 26 적 카탈로그 발동 빈도
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3) — HP/공격/방어 산식, hook 클램프
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2) — 트레잇·환경 매핑
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1) — 라운드 권장 범위 3~6
>
> 후속:
> - 페이즈 2 #4 전투 로그 길이·수치 노출 기준 (§11 라인 노출 정책 입력)
> - 페이즈 3 #3 `combat_status_effects` 신규 테이블 시드 10행 (§13 권장 컬럼)
> - 페이즈 4 #2 `CombatStatusEffect` freezed 모델 (§13 데이터 구조)

## 개요

본 산출물은 페이즈 1 #4의 10 상태 효과 카탈로그(buff 4 / debuff 3 / mez 1 / dot 2)의 정확한 default 수치를 확정한다. 페이즈 2 #1·#2의 스킬 권고 수치를 종합하여 카탈로그 default와 스킬별 오버라이드를 매트릭스화하고, 페이즈 1 #3 HP·hook 클램프 분포 안에서 시뮬레이션 정합성을 검증한다.

페이즈 1·2의 결정·산식·카탈로그 구조는 변경하지 않는다. 본 산출물은 페이즈 3 #3 시드 데이터 입력과 페이즈 4 #2 모델의 default 필드 값을 확정하는 데이터 수치 산출물이다.

## 1. 현재 상태 — 페이즈 1 #4 카탈로그 + 페이즈 2 #1·#2 권고

### 1.1 페이즈 1 #4 10 상태 효과 카탈로그

| ID | kind | hook | stack_policy | apply_method | 출처 |
|----|------|------|--------------|--------------|------|
| `buff_attack_up` | buff | attack | refresh | multiplicative | 페이즈 1 #4 §1.1 |
| `buff_defense_up` | buff | defense | refresh | multiplicative | 페이즈 1 #4 §1.1 |
| `buff_accuracy_up` | buff | hit | refresh | additive | 페이즈 1 #4 §1.1 |
| `buff_evasion_up` | buff | evasion | refresh | additive | 페이즈 1 #4 §1.1 |
| `debuff_attack_down` | debuff | attack | refresh | multiplicative | 페이즈 1 #4 §1.2 |
| `debuff_defense_down` | debuff | defense | refresh | multiplicative | 페이즈 1 #4 §1.2 |
| `debuff_accuracy_down` | debuff | hit | refresh | additive | 페이즈 1 #4 §1.2 |
| `mez_stunned` | mez | action_skip | refresh | n/a (행동 스킵) | 페이즈 1 #4 §1.3 |
| `dot_bleeding` | dot | round_end | stack (max 3) | proportional (`maxHp×0.04×stack`) | 페이즈 1 #4 §1.4 §5.1 |
| `dot_poisoned` | dot | round_start | stack (max 3) | absolute (`intensity×5 + level×2`) | 페이즈 1 #4 §1.4 §5.2 |

### 1.2 페이즈 2 #1 스킬 권고 수치 (10 스킬 — 파티 측)

| 스킬 | applyChance | intensity | duration | 활용 상태 효과 |
|------|------------|-----------|----------|-------------|
| `skill_warrior_shield_bulwark` | passive | shieldBlockBonus +0.10 | — | (방패 직접 가산, 상태 효과 미사용) |
| `skill_warrior_battle_fury` | 1.00 (자동) | 0.30 | 3 | `buff_attack_up` |
| `skill_rogue_mass_blind` | 0.70 | 0.20 | 2 | `debuff_attack_down` |
| `skill_ranger_marksman_focus` | 1.00 (자동) | 0.15 | 2 | `buff_accuracy_up` + critRate +0.15 (직접) |
| `skill_ranger_volley_shot` | — | — | — | (상태 효과 미사용) |
| `skill_mage_arcane_blast` | — | — | — | (상태 효과 미사용) |
| `skill_mage_stun_bolt` | 0.50 | (의미 없음) | 1 | `mez_stunned` |
| `skill_support_aegis_aura` | 1.00 (자동) | 0.20 | 3 | `buff_defense_up` |
| `skill_support_cleansing_word` | 1.00 (자동) | — | — | `dispel_debuff` (debuff 1 + dot 1) |
| `skill_specialist_adaptive_footwork` | 1.00 (자동) | 0.10 | 2 | `buff_evasion_up` |

### 1.3 페이즈 2 #2 적 전용 6 스킬 권고 수치

| 스킬 | applyChance | intensity | duration | 활용 상태 효과 |
|------|------------|-----------|----------|-------------|
| `skill_enemy_bleeding_cut` | 0.60 | stack 1 | 3 | `dot_bleeding` |
| `skill_enemy_armor_break` | 0.80 | 0.25 | 3 | `debuff_defense_down` |
| `skill_enemy_poison_bite` | 0.70 | stack 1 | 3 | `dot_poisoned` |
| `skill_enemy_taunt_roar` | 0.60 | 0.15 | 2 | `debuff_attack_down` |
| `skill_enemy_summon` | 1.00 (자동) | — | — | (적 추가 — 상태 효과 미사용) |
| `skill_enemy_self_dispel` | 1.00 (자동) | — | — | `dispel_debuff` self (debuff 1 + dot 1) |

### 1.4 페이즈 1 #1 환경 자동 부여 정책

페이즈 1 #1 Phase 1 사전 단계 자동 부여:

| 환경 | 부여 대상 | 상태 효과 | 권고 수치 |
|------|---------|---------|---------|
| `mist_field` (M7 안개) | 적군 전원 | `debuff_accuracy_down` | intensity 0.10, duration 2 |

### 1.5 페이즈 1 #2 §5 트레잇 카테고리 매핑

| 트레잇 카테고리 | 부여 상태 효과 (선제 라운드 시작 시 자동) | 권고 수치 |
|----------------|------------------------------|---------|
| Talent · `vigilant` 키워드 | `buff_evasion_up` 자기 부여 (1턴) | intensity 0.10, duration 1 |
| Survival · `huntsman` 키워드 | `buff_accuracy_up` 자기 부여 (1턴) | intensity 0.05, duration 1 |

MVP 단순화 — 페이즈 4 #1 시뮬레이터 명세에서 정식 hook 확정. 본 산출물은 트레잇 hook 활성화 정책만 명시.

## 2. 10 상태 효과 default 수치 확정

페이즈 1·2 권고를 종합하여 `combat_status_effects` 테이블의 default 값을 확정한다. 스킬·트레잇·환경에서 발동될 때 명시적 오버라이드가 없으면 이 default가 적용된다.

### 2.1 buff 4 타입

| ID | default_duration | default_intensity | clamp_max_intensity | 비고 |
|----|------------------|-------------------|---------------------|------|
| `buff_attack_up` | 2 | 0.20 | 0.50 | battle_fury 오버라이드 0.30 / 3턴 — 다른 스킬·트레잇은 default 사용 |
| `buff_defense_up` | 3 | 0.20 | 0.50 | aegis_aura 권고 동일 — default 그대로 |
| `buff_accuracy_up` | 2 | 0.15 | 0.40 | marksman_focus 권고 동일 — default 그대로 |
| `buff_evasion_up` | 2 | 0.10 | 0.30 | specialist 스킬 2턴 / 트레잇 자동 부여 1턴 |

### 2.2 debuff 3 타입

| ID | default_duration | default_intensity | clamp_max_intensity | 비고 |
|----|------------------|-------------------|---------------------|------|
| `debuff_attack_down` | 2 | 0.20 | 0.50 | mass_blind 권고 동일 / taunt_roar 오버라이드 0.15 — default 그대로 |
| `debuff_defense_down` | 3 | 0.25 | 0.50 | armor_break 권고 동일 — default 그대로 |
| `debuff_accuracy_down` | 2 | 0.10 | 0.40 | mist_field 환경 자동 부여만 활용 — default 그대로 |

### 2.3 mez 1 타입

| ID | default_duration | default_intensity | clamp_max_duration | 비고 |
|----|------------------|-------------------|---------------------|------|
| `mez_stunned` | 1 | 1 (의미 없음) | 3 | stun_bolt 권고 동일 — default 그대로. duration 상한 3 — 무한 락 방지 |

### 2.4 dot 2 타입

| ID | default_duration | default_intensity (stack) | clamp_max_stack | clamp_max_duration | 비고 |
|----|------------------|-------------------|---------------------|---------------------|------|
| `dot_bleeding` | 3 | 1 (stack 1) | 3 | 5 | 비례형 — maxHp×0.04×stack |
| `dot_poisoned` | 3 | 3 (intensity 3) | 3 (stack) | 5 | 절대형 — intensity×5 + level×2 |

`dot_poisoned` intensity 3을 default로 채택한 근거: §3.2 시뮬레이션에서 stack 1 시 17~25 피해 (T1~T5)가 평균 단발 일반 공격(5~15)의 ~1.5~2배. stack 3 누적 시 51 피해/라운드는 mage HP 88(T3)을 단일 라운드에서 위협. 페이즈 2 #2에서 권고한 단일 stack은 적정.

## 3. DoT stack 시뮬레이션

페이즈 1 #4 §5.1·§5.2 산식을 페이즈 1 #3 §2.3 HP 분포에 대입한다.

### 3.1 `dot_bleeding` 비례형 라운드 종료 피해

산식: `bleedingDamage = max(1, floor(maxHp × 0.04 × stack))`

| Tier | warrior HP | mage HP | stack 1 | stack 2 | stack 3 |
|------|----------|---------|---------|---------|---------|
| T1 Lv1 | 58 | 33 | 2/1 | 4/2 | 6/3 |
| T3 Lv3 | 128 | 88 | 5/3 | 10/7 | 15/10 |
| T5 Lv5 | 229 | 169 | 9/6 | 18/13 | 27/20 |

(왼쪽: warrior HP × 4% / 오른쪽: mage HP × 4%)

### 3.2 `dot_poisoned` 절대형 라운드 시작 피해

산식: `poisonedDamage = max(1, floor(intensity × 5 + level × 2))`

| stack | intensity | level 1 | level 3 | level 5 |
|-------|-----------|---------|---------|---------|
| 1 | 3 | 17 | 21 | 25 |
| 2 | 5 | 27 | 31 | 35 |
| 3 | 8 | 42 | 46 | 50 |

### 3.3 HP 분포 정합 검증

평균 6라운드 전투에서 DoT 누적 피해 비율:

| Tier × role | maxHp | bleeding stack 1 ×6 라운드 누적 | 누적 비율 |
|------------|-------|---------|----------|
| T1 mage Lv1 | 33 | 6 | 18% (1턴 누적 1, 6턴 누적 6) |
| T3 mage Lv3 | 88 | 18 | 20% |
| T5 mage Lv5 | 169 | 36 | 21% |
| T1 warrior Lv1 | 58 | 12 | 21% |
| T5 warrior Lv5 | 229 | 54 | 24% |

비례형이라 HP 클래스 사이 비율이 안정적(18~24%). bleeding stack 1은 위협적이지만 즉사가 아니다. **stack 3 도달 시 누적 비율 60~72%** — 평균 6라운드 전투를 결정짓는 위협으로 작동한다.

| Tier × role | maxHp | poisoned stack 1 (default intensity 3) ×6 라운드 누적 | 누적 비율 |
|------------|-------|---------|----------|
| T1 mage Lv1 | 33 | 102 (17×6) | **309% (즉사)** |
| T3 mage Lv3 | 88 | 126 (21×6) | **143% (즉사)** |
| T5 mage Lv5 | 169 | 150 (25×6) | 89% |
| T1 warrior Lv1 | 58 | 102 (17×6) | **176% (즉사)** |
| T5 warrior Lv5 | 229 | 150 (25×6) | 66% |

**관측**: poisoned stack 1 (intensity 3)은 T1~T3 모든 직업군에 6라운드 누적 즉사 위협. mage·rogue 류 저HP에 치명적.

### 3.4 dot stack 도달 빈도

`bleeding_cut` 적용 (applyChance 0.60, 쿨다운 2 라운드) — 6라운드 동안 적이 사용할 수 있는 횟수: R1·R3·R5 = 3회 시도.

- stack 1 도달: 1 - (1-0.6)^1 = **60%**
- stack 2 도달: 1 - (1-0.6)^2 = **84%**
- stack 3 도달 (3회 모두 성공): 0.6^3 = **22%**

`poison_bite` 적용 (applyChance 0.70, 쿨다운 2 라운드) — 6라운드 R1·R3·R5 = 3회 시도.

- stack 1 도달: **70%**
- stack 2 도달: **91%**
- stack 3 도달: 0.7^3 = **34%**

### 3.5 결론

| DoT | default intensity 채택 | 근거 |
|-----|---------------------|------|
| `dot_bleeding` | stack 1 | 비례형 18~24% 누적 비율로 자연스러운 위협. stack 3 누적 60~72%로 보조 위협 정도. **균형적** |
| `dot_poisoned` | stack 1 (intensity 3) | 절대형 — 저HP 직업군 6라운드 즉사. **위협적**. stack 2+는 보스급 위협. mage 위협 표현용 |

본 default는 페이즈 2 #4 보고서 노출 정책 및 페이즈 4 #5 검증 시뮬레이션에서 분포 재검증.

## 4. 다중 결합 시뮬레이션

페이즈 1 #4 §3 결합 규칙(곱셈 vs 가산)을 본 default 수치에 적용한다.

### 4.1 곱셈 hook 결합 (attack, defense)

예시 1: warrior 본인 `battle_fury` 발동 (intensity 0.30) + 적이 `mass_blind` 부여 (intensity 0.20)

```text
statusEffectAttackMod = (1 + 0.30) × (1 - 0.20) = 1.30 × 0.80 = 1.04
```

| 단계 | mage hook 값 | warrior 공격력 (baseAttack 18) |
|------|------------|----------------------------|
| 초기 | 1.00 | 18 |
| battle_fury 발동 | 1.30 | 23.4 (+30%) |
| 적 mass_blind 부여 | 1.04 | 18.7 (+4% — 무력화) |
| 적 mass_blind 만료 (2턴 후) | 1.30 | 23.4 |

플레이어 체감: "분노 발동했는데 적 광역 디버프가 거의 무력화시킴". 페이즈 1 #4 §3.1 곱셈 정책 정합 — 의도된 동작.

예시 2: support `aegis_aura` 부여 (intensity 0.20) + 적 `armor_break` (intensity 0.25)

```text
statusEffectDefenseMod = (1 + 0.20) × (1 - 0.25) = 1.20 × 0.75 = 0.90
```

| 단계 | warrior 방어값 (baseDefense 26) |
|------|----------------------------|
| 초기 | 26 |
| aegis_aura 부여 | 31.2 (+20%) |
| 적 armor_break 적용 | 23.4 (-10% 순수) |

armor_break(intensity 0.25)가 aegis_aura(intensity 0.20)보다 강해서 디버프 우세. 의도: armor_break는 페이즈 2 #2 §5.1에서 갑옷 깨기 위협으로 의도됨.

### 4.2 가산 hook 결합 (hit, evasion)

예시 3: ranger `marksman_focus` 발동 (intensity +0.15) + 트레잇 `marksman` (+5% per trait, 2 trait 합산 상한 +10%)

```text
statusEffectHitMod = +0.15 + 0.10 (trait) = +0.25
```

ranger T3 baseHit 82% + AGI 차이 +4% + +25% (상태 효과 + 트레잇) = 111% → **클램프 95% 도달**

플레이어 체감: marksman_focus + 정조준 트레잇 ranger는 명중 95% 상한. 의도: 페이즈 1 #3 §6 명중 클램프 [50, 95]가 marksman 정체성을 보장.

예시 4: mage `mist_field` 안개 진입 시 적 자동 `debuff_accuracy_down` 0.10

```text
statusEffectHitMod (적 측) = -0.10
```

적 baseHit 75% (mage) → 65%. 페이즈 1 #3 §6 클램프 [50, 95] 안에서 보호되지만 명중 손실 큰 영향.

### 4.3 다중 결합 분포 분석

본 카탈로그 default가 만드는 효과 범위:

| 결합 시나리오 | 결과 |
|-------------|------|
| 단일 buff_attack_up 0.20 | 공격 ×1.20 (+20%) |
| 단일 buff_attack_up 0.30 (battle_fury) | 공격 ×1.30 (+30%) |
| 단일 debuff_attack_down 0.20 | 공격 ×0.80 (-20%) |
| buff + debuff (default × default) | 공격 ×0.96 (-4%) — 거의 상쇄 |
| buff 0.30 + debuff 0.25 (armor_break 결합) | 공격 ×0.975 (-2.5%) |
| 2× buff_attack_up refresh (intensity 갱신 없음) | ×1.20 (refresh 정책에 따라 intensity 변동 없음) |

페이즈 1 #4 §7.1 refresh 정책 정합 — 같은 ID 재부여 시 duration만 갱신, intensity 누적 없음. 본 default가 의도와 정합.

## 5. 명중·회피·치명타 클램프 도달 빈도

페이즈 1 #3 클램프와 본 default 결합 분석.

### 5.1 명중 [50%, 95%]

| 조건 | 명중률 계산 | 결과 |
|------|-----------|------|
| T1 warrior 기본 (AGI 5 vs AGI 5) | 80 + 0 + 0 = 80% | **80%** |
| T1 warrior + 적 mist_field debuff_accuracy_down | 80 - 10 = 70% | **70%** |
| T5 ranger 정조준 (AGI 25 vs AGI 12) + marksman trait ×2 | 82 + 10.4 + 15 + 10 = 117% → 95% | **95% (클램프)** |
| T5 ranger 정조준 + mist_field 환경 | 82 + 10.4 + 15 + 10 - 10 = 107% → 95% | **95% (클램프)** |
| T1 mage 기본 vs 회피형 적 | 75 + 0 + 0 = 75% | **75%** |

클램프 도달 빈도: marksman_focus + 트레잇 2개 ranger만 95% 도달. 일반적 매치업은 65~85% 분포 — 페이즈 1 #4 §11 비노출 정책 안에서 자연스럽다.

### 5.2 회피 [0%, 75%]

| 조건 | 회피율 계산 | 결과 |
|------|-----------|------|
| T1 warrior 기본 | 5 + 0 + 0 = 5% | **5%** |
| T3 rogue + Survival trait ×3 (상한 +12%) | 18 + 0 + 12 = 30% | **30%** |
| T3 rogue + Survival trait ×3 + forest 환경 (+3% 전원) | 18 + 0 + 12 + 3 = 33% | **33%** |
| T5 rogue + Survival trait ×3 + mist_field 환경 (+5%) + AGI 차이 +5% | 18 + 5 + 12 + 5 = 40% | **40%** |
| T5 rogue + buff_evasion_up 0.10 (트레잇 또는 specialist 스킬) | 위 + 10 = 50% | **50%** |

**관측**: `buff_evasion_up`이 specialist 스킬로 직접 활성화되어도 회피 클램프 75% 도달은 불가능하다. 최대 50% 분포. 페이즈 2 #1 §4.3 매트릭스 정합 — 생존 보조는 의미 있지만 회피 탱킹을 만들지는 않는다.

### 5.3 치명타 [5%, 60%]

| 조건 | 치명타율 계산 | 결과 |
|------|-----------|------|
| T1 warrior 기본 (AGI 5) | 5 + 1.5 + 0 = 6.5% → 7% | **7%** |
| T3 rogue 후방 공격 (AGI 15) | 15 + 4.5 + 10 (flank) = 29.5% → 30% | **30%** |
| T3 ranger 정조준 + CombatStyle trait ×3 | 10 + 4.5 + 15 + 15 (marksman_focus critMod) = 44.5% | **45%** |
| T3 ranger 정조준 + flank (후열) + trait ×3 | 위 + 5 (ranger flank) = 49.5% | **50%** |
| T5 rogue + 모든 트레잇 + flank | 15 + 7.5 + 15 + 10 = 47.5% | **48%** |

**관측**: 클램프 60% 상한은 거의 도달하지 않는다. 페이즈 1 #4 §1.5 미매핑 hook(`statusEffectCritMod`)이 marksman_focus에서만 활성화되어 정조준 ranger 정체성을 보장. 일반 매치업은 5~30% — 결정적 장면 빈도 적정.

### 5.4 클램프 도달 빈도 종합

| 클램프 | 도달 빈도 | 의미 |
|--------|---------|------|
| 명중 95% 상한 | marksman ranger + 트레잇 시 도달 | 정조준 정체성 보장 |
| 명중 50% 하한 | mist_field + 적 거리 패널티 결합 시 도달 가능 | 환경 위협 보장 |
| 회피 75% 상한 | MVP에서 미도달 | `buff_evasion_up` 강도 0.10 유지 — 페이즈 4 #5 후속 검증 |
| 회피 0% 하한 | warrior 기본 매치업에서 가까움 | 페이즈 1 #3 §8 정책 정합 |
| 치명타 60% 상한 | MVP에서 미도달 | 5~50% 분포가 자연스러움 |
| 치명타 5% 하한 | T1 신참 기본 | 페이즈 1 #3 §7 정책 정합 |

## 6. 카탈로그 default vs 스킬 오버라이드 매트릭스

페이즈 2 #1·#2의 권고 수치가 카탈로그 default와 일치/오버라이드되는 영역 정리.

### 6.1 일치 영역 (스킬이 default 그대로 사용)

| 스킬 | 상태 효과 | applyChance | intensity | duration |
|------|---------|------------|-----------|---------|
| `skill_rogue_mass_blind` | `debuff_attack_down` | 0.70 | **0.20 (default)** | **2 (default)** |
| `skill_ranger_marksman_focus` | `buff_accuracy_up` | 1.00 | **0.15 (default)** | **2 (default)** |
| `skill_mage_stun_bolt` | `mez_stunned` | 0.50 | **1 (default)** | **1 (default)** |
| `skill_support_aegis_aura` | `buff_defense_up` | 1.00 | **0.20 (default)** | **3 (default)** |
| `skill_specialist_adaptive_footwork` | `buff_evasion_up` | 1.00 | **0.10 (default)** | **2 (default)** |
| `skill_enemy_bleeding_cut` | `dot_bleeding` | 0.60 | **stack 1 (default)** | **3 (default)** |
| `skill_enemy_armor_break` | `debuff_defense_down` | 0.80 | **0.25 (default)** | **3 (default)** |
| `skill_enemy_poison_bite` | `dot_poisoned` | 0.70 | **stack 1 (default)** | **3 (default)** |

8개 스킬이 default 그대로 사용 — 카탈로그 default가 대부분의 상태 효과 사례에서 1차 진실의 원천.

### 6.2 오버라이드 영역

| 스킬 | 상태 효과 | 오버라이드 항목 |
|------|---------|--------------|
| `skill_warrior_battle_fury` | `buff_attack_up` | intensity 0.30 (default 0.20에서 +0.10), duration 3 (default 2에서 +1) — 자기 부여 자동 발동의 강도 보강 |
| `skill_enemy_taunt_roar` | `debuff_attack_down` | intensity 0.15 (default 0.20에서 -0.05), duration 2 동일 — 광역 부여로 약화 |

오버라이드는 2 스킬만. 페이즈 4 #2 모델은 `CombatSkill.statusEffectIntensity`/`statusEffectDurationTurns` 필드를 nullable로 두어 null=default 사용, non-null=오버라이드 정책을 채택.

### 6.3 default 미사용 영역 (스킬·환경에서 부여되지 않음)

| 상태 효과 | 미사용 출처 | 향후 활성화 가능성 |
|---------|-----------|--------------------|
| `debuff_accuracy_down` (스킬) | 페이즈 2 #1 미배정 | 환경(mist_field)으로만 활성 |
| `dot_poisoned` | 페이즈 2 #2 `enemy_trial_beast` 1종에만 제한 배정 | 후속 확장에서 `elite_insect_*` 1~2종 추가 가능 |

본 카탈로그 10 타입 중 8 직접 활성 + 1 환경 활성(`debuff_accuracy_down`) + 1 제한 활성(`dot_poisoned`). 페이즈 2 #1 §4.3 매트릭스 정합.

### 6.4 dispel 상태 효과 처리

페이즈 1 #4 §8.2 dispel은 `combat_status_effects` 카탈로그에 별도 ID로 두지 않는다. dispel은 스킬의 `dispelKind` 필드로 표현 (페이즈 2 #1 §10 + 페이즈 2 #2 §5.5):

- `skill_support_cleansing_word` → dispelKind: `debuff+dot`, dispelMaxCount: 1+1, target: aoe_ally
- `skill_enemy_self_dispel` → dispelKind: `debuff+dot`, dispelMaxCount: 1+1, target: self

dispel은 상태 효과 ID 자체가 아니라 상태 효과를 해제하는 메커니즘이므로 카탈로그 외 처리.

## 7. 트레잇·환경 자동 부여 default

페이즈 1 #2 §5 트레잇 매핑 + 페이즈 1 #1 환경 효과의 default 부여 수치.

### 7.1 트레잇 자동 부여 (선제 라운드 시작 시)

| 트레잇 키워드 | 부여 상태 효과 | applyChance | intensity | duration | 비고 |
|-------------|-------------|------------|-----------|---------|------|
| `vigilant` | self `buff_evasion_up` | 1.00 (자동) | 0.10 | 1 | 페이즈 1 #2 §5 매핑 |
| `huntsman` | self `buff_accuracy_up` | 1.00 (자동) | 0.05 | 1 | 페이즈 1 #2 §5 매핑 |
| `scout` | (선제 점수 가산만 — 상태 효과 미부여) | — | — | — | 페이즈 1 #2 §5 |

본 카탈로그 default(`buff_evasion_up` 0.10 / `buff_accuracy_up` 0.15)와 일치 또는 약함. 트레잇은 약한 default를 둬서 스킬 발동과 누적되지 않도록 보호한다.

### 7.2 환경 자동 부여 (Phase 1 사전 단계)

| 환경 | 부여 상태 효과 | applyChance | intensity | duration | 비고 |
|------|------------|------------|-----------|---------|------|
| `mist_field` | 적군 전원 `debuff_accuracy_down` | 1.00 (자동) | 0.10 | 2 | 카탈로그 default 그대로. M7 안개 늪지 시나리오 |

기타 환경(forest, mountain, swamp, dungeon, ruined_castle, sea_coast, desert, mist_field 8 태그)은 페이즈 1 #2 §6 매트릭스로 명중·회피·행동 순서에만 영향. 상태 효과 자동 부여는 mist_field만 활성.

## 8. 라운드 권장 범위 정합 검증

페이즈 1 #1 §라운드 권장 범위 3~6 (상한 8)과 본 default가 만드는 평균 전투 길이 검증.

### 8.1 평균 단발 피해 + DoT 누적

| 매치업 | 라운드 평균 피해 (양측 합) | 평균 6라운드 누적 |
|--------|--------------------------|------------------|
| T3 warrior vs T3 mage (DoT 없음) | 25~30 | 150~180 |
| T3 warrior vs T3 rogue + bleeding_cut stack 1 | 20~25 + bleeding 6/라운드 종료 | 156~186 |
| T3 warrior vs T3 mage + arcane_blast 3대상 광역 | 35~50 (광역) | 210~300 |
| T5 warrior vs T5 mage + poison_bite stack 2 | 30~40 + poisoned 31/라운드 시작 | 366 |

평균 6라운드 안에서 HP 88~169가 양측에서 1~2명 쓰러질 분포. 페이즈 1 #1 권장 범위 3~6 라운드 정합.

### 8.2 DoT가 라운드 길이를 단축시키는 경우

| 시나리오 | 영향 |
|--------|------|
| 적 `bleeding_cut` stack 2 (84% 도달) on T3 mage | mage HP 88 vs bleeding 7/라운드 종료 × 3라운드 = 21 + 일반 피해 → 4~5 라운드 만에 mage 쓰러짐 |
| 적 `poison_bite` stack 2 (91% 도달) on T3 mage | mage HP 88 vs poisoned 31/라운드 시작 → 3라운드 만에 즉사 |

`poison_bite`는 적 측 위협 강도가 높다. 페이즈 2 #2 §5.7에서 MVP 1종(`enemy_trial_beast`)에만 제한 배정한 결정이 정합 — 모든 적이 가지면 라운드 수가 너무 짧아진다. 페이즈 2 #2 후속 확장에서 `elite_insect_*` 1~2 적에만 추가 배정 권고.

## 9. 페이즈 2 #4 보고서 노출 정책 입력

페이즈 1 #4 §11 노출 정책 + 본 default 정합:

### 9.1 노출 텍스트 매트릭스

| 이벤트 | 텍스트 패턴 | 수치 노출 |
|--------|-----------|---------|
| `buff_attack_up` 부여 | "{merc.name}이(가) 분노에 휩싸였다. 공격력 강화 {duration}턴" | duration |
| `buff_attack_up` 해제 | "{merc.name}의 분노가 가라앉았다" | — |
| `debuff_attack_down` 부여 (광역) | "{enemy.name}의 연막으로 {N}명이 약화" | 대상 수 N |
| `debuff_defense_down` 부여 | "{enemy.name}이(가) 거대 망치로 {target}의 갑옷을 깼다. 방어력 약화 {duration}턴" | duration |
| `mez_stunned` 부여 | "{merc.name}의 마법이 {enemy.name}을(를) 기절시켰다" | — |
| `mez_stunned` 행동 스킵 | "{enemy.name}이(가) 기절해 행동하지 못했다" | — |
| `dot_bleeding` 부여 | "{enemy.name}이(가) {target}에게 더러운 칼날을 그었다. 출혈 부여" | — |
| `dot_bleeding` stack 증가 | "{target}의 출혈이 {stack}스택" | stack |
| `dot_bleeding` 피해 (라운드 종료) | "{target}이(가) 출혈로 {N}의 피해" | 피해 N |
| `dot_poisoned` 부여 | "{enemy.name}이(가) {target}을(를) 깨물었다. 독 부여" | — |
| `dot_poisoned` 피해 (라운드 시작) | "{target}이(가) 독으로 {N}의 피해" | 피해 N |

**비노출** (페이즈 1 #4 §11.3 정합):
- intensity 값 (예: 0.20, 0.30)
- applyChance 발동 결과 (시도 → 부여 성공/실패만 텍스트로)
- stack 도달 확률
- DoT 산식 (maxHp × 0.04 × stack 등의 계산식)

### 9.2 보고서 라인 예시 (페이즈 2 #4 입력)

```text
[전개] 김철수가 분노에 휩싸였다. 공격력 강화 3턴.
[전개] 늪지 사령관의 포효에 파티 3명이 위축됐다.
[위기] 도굴꾼 대장이 거대 망치로 김철수의 갑옷을 깼다. 방어력 약화 3턴.
[위기] 박영희가 출혈로 10의 피해.
[해소] 마법사가 도굴꾼 대장의 일격을 막아냈다.
[후일담] 박영희의 출혈이 사라졌다.
```

페이즈 2 #4가 본 노출 매트릭스를 활용해 전투 로그 템플릿을 매트릭스화한다.

## 10. data-generator 수치 가이드

### 10.1 대상 정보

- **대상 타입**: `status-effect` (신규 타입 스펙 작성 필요 — `types/status-effect.md`)
- **대상 테이블**: `combat_status_effects` (페이즈 3 #3 신규)
- **생성 수량**: 10행
- **외래 키 제약**: 없음 (정적 카탈로그)

### 10.2 시드 10행 정밀 값

| id | kind | display_label | default_duration_turns | default_intensity | stack_policy | hook_target | apply_method | description |
|----|------|---------------|----------------------|-------------------|--------------|-------------|--------------|-------------|
| `buff_attack_up` | buff | 공격력 강화 | 2 | 0.20 | refresh | `['attack']` | multiplicative | 공격력을 곱셈으로 강화한다 |
| `buff_defense_up` | buff | 방어력 강화 | 3 | 0.20 | refresh | `['defense']` | multiplicative | 방어값을 곱셈으로 강화한다 |
| `buff_accuracy_up` | buff | 명중 강화 | 2 | 0.15 | refresh | `['hit']` | additive | 명중률을 가산으로 강화한다 |
| `buff_evasion_up` | buff | 회피 강화 | 1 | 0.10 | refresh | `['evasion']` | additive | 회피율을 가산으로 강화한다 |
| `debuff_attack_down` | debuff | 공격력 약화 | 2 | 0.20 | refresh | `['attack']` | multiplicative | 공격력을 곱셈으로 약화한다 |
| `debuff_defense_down` | debuff | 방어력 약화 | 3 | 0.25 | refresh | `['defense']` | multiplicative | 방어값을 곱셈으로 약화한다 |
| `debuff_accuracy_down` | debuff | 명중 약화 | 2 | 0.10 | refresh | `['hit']` | additive | 명중률을 가산으로 약화한다 |
| `mez_stunned` | mez | 기절 | 1 | 1 | refresh | `['action_skip']` | n/a | 행동 1회를 스킵한다 |
| `dot_bleeding` | dot | 출혈 | 3 | 1 | stack | `['round_end']` | proportional | 라운드 종료마다 maxHp×0.04×stack 비례 피해 |
| `dot_poisoned` | dot | 중독 | 3 | 3 | stack | `['round_start']` | absolute | 라운드 시작마다 intensity×5+level×2 절대 피해 |

### 10.3 수치 범위 제약

| 필드 | 최소 | 최대 | 기본 채택 |
|------|------|------|---------|
| `default_duration_turns` | 1 | 5 (clamp_max) | 1~3 |
| `default_intensity` (buff/debuff) | 0.05 | 0.50 (clamp_max) | 0.10~0.25 |
| `default_intensity` (dot stack) | 1 | 3 (clamp_max_stack) | 1 (poisoned default 3은 산식 입력) |
| `apply_chance` (스킬 오버라이드 또는 카탈로그 기본) | 0.0 | 1.0 | 0.50~1.00 |

### 10.4 balance 근거 요약

| 상태 효과 | 채택 근거 |
|---------|---------|
| `buff_attack_up` 0.20 / 2턴 | §4 곱셈 결합 — debuff와 결합 시 ±10~20% 변동성. battle_fury는 0.30/3턴 오버라이드 (자기 부여 자동) |
| `buff_defense_up` 0.20 / 3턴 | aegis_aura 광역 buff. armor_break(0.25)에 대해 약간 약세 — 위협 우세 의도 |
| `buff_accuracy_up` 0.15 / 2턴 | §5.1 ranger 정조준 + 트레잇 결합 시 명중 95% 클램프 도달 |
| `buff_evasion_up` 0.10 / 2턴 | specialist 스킬 기본값. 트레잇 자동 부여는 1턴으로 약하게 유지 |
| `debuff_attack_down` 0.20 / 2턴 | mass_blind 광역. 곱셈 결합 시 적 공격 무력화 |
| `debuff_defense_down` 0.25 / 3턴 | armor_break — aegis_aura(0.20)보다 강한 위협 |
| `debuff_accuracy_down` 0.10 / 2턴 | mist_field 환경 자동 부여. 명중 65~85% 분포 안에서 자연스러운 변동 |
| `mez_stunned` 1턴 | 페이즈 1 #4 §6.5 행동 스킵 정책 — 라운드 1회 행동 1회 차단으로 균형 |
| `dot_bleeding` stack 1 / 3턴 | §3.3 누적 18~24% — 균형적 위협 |
| `dot_poisoned` intensity 3 / stack 1 / 3턴 | §3.3 누적 89~143% — 저HP 직업군 위협. 보스급 위협 표현용 |

## 11. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| 페이즈 1 #4 카탈로그 구조 | default 값만 확정. 카탈로그 자체 변경 없음 | 변경 없음 |
| 페이즈 2 #1 10 스킬 카탈로그 | §6.1 default 일치 5개 / §6.2 오버라이드 1개 / 상태 효과 미사용 4개 | specialist 보완 반영 |
| 페이즈 2 #2 적 6 스킬 카탈로그 | §6.1 default 일치 3개 / §6.2 오버라이드 1개 / 상태 효과 미사용 2개 | poison_bite MVP 1종 배정 반영 |
| 페이즈 1 #3 hook 클램프 | §5 명중 [50,95] / 회피 [0,75] / 치명타 [5,60] 정합 검증 | 변경 없음 |
| 페이즈 1 #3 §2 HP 산식 | §3 DoT 시뮬레이션 입력 | 변경 없음 |
| `combat_status_effects` (페이즈 3 #3 신규) | 본 산출물 10행 시드 입력 | 신규 테이블 |
| 페이즈 4 #2 `CombatStatusEffect` 모델 | default_duration_turns / default_intensity / stack_policy / hook_target / apply_method | 페이즈 4 #2 입력 |
| 페이즈 4 #2 `CombatSkill` 모델 | statusEffectIntensity / statusEffectDurationTurns nullable 정책 | 페이즈 4 #2 입력 |

## 12. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | 10 상태 효과 default_duration / default_intensity 확정 | 페이즈 3 #3 시드의 입력 |
| 높음 | stack_policy / apply_method 확정 | 페이즈 1 #4 §3·§7 정합 |
| 높음 | `dot_bleeding` 비례형 산식 검증 | §3.3 평균 6라운드 18~24% 비례 |
| 높음 | `dot_poisoned` 절대형 intensity 3 채택 | §3.3 저HP 즉사 위협 표현 |
| 높음 | 클램프 도달 빈도 검증 | §5 명중·회피·치명타 정합 |
| 중간 | §6 스킬 default vs 오버라이드 매트릭스 | 페이즈 4 #2 모델 nullable 정책 입력 |
| 중간 | §7 트레잇·환경 자동 부여 default | 페이즈 4 #1 시뮬레이터 명세 입력 |
| 중간 | §9 보고서 노출 정책 매트릭스 | 페이즈 2 #4 입력 |
| 낮음 | clamp_max_intensity / clamp_max_duration 상한 | 페이즈 4 #2 모델 검증 |
| 낮음 | dispel 정책 (카탈로그 외 처리) | 페이즈 4 #2 모델 `CombatSkill.dispelKind` 필드 |

## 13. 페이즈 2 #4·페이즈 3·4 입력 요약

| 후속 산출물 | 본 산출물의 입력 기여 |
|-----------|---------------------|
| 페이즈 2 #4 전투 로그 길이·수치 노출 기준 | §9 노출 매트릭스 11종 + §9.2 라인 예시 |
| 페이즈 3 #3 `combat_status_effects` 시드 | §10.2 10행 정밀 값 |
| 페이즈 4 #1 `CombatSimulator` 명세 | §4 결합 계산 정책 + §7 트레잇·환경 자동 부여 hook + §5 클램프 도달 적용 |
| 페이즈 4 #2 `CombatStatusEffect` 모델 | §10.2 default 9 컬럼 + clamp_max 컬럼 |
| 페이즈 4 #2 `CombatSkill` 모델 | §6.2 nullable 오버라이드 정책 (statusEffectIntensity / statusEffectDurationTurns null=default) |
| 페이즈 4 #5 검증 명세 | §3 DoT 누적 분포 + §5 클램프 도달 빈도 + §8 라운드 권장 범위 정합 |

## 14. 다음 단계

페이즈 2 #4 전투 로그 길이·수치 노출 기준 확정에서 본 산출물 §9 노출 매트릭스 11종을 페이즈 3 #4 전투 로그 템플릿 120~180개의 분포로 확장한다.

페이즈 3 #3 `combat_status_effects` 신규 테이블 시드에서 §10.2 10행 정밀 값을 그대로 시드 데이터로 영속화한다. `types/status-effect.md` 타입 스펙 부재 시 (a) 타입 스펙 우선 작성 또는 (b) 본 산출물을 입력으로 SQL/수동 데이터 생성 병행을 페이즈 3 시작 시 결정한다.

페이즈 4 #2 `CombatStatusEffect`/`CombatSkill` 모델 명세에서 §6.2 오버라이드 nullable 정책과 §13 모델 입력을 정식 정의한다.
