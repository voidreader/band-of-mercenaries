# M8b 직업군 대표 스킬 카탈로그 기획서

> 작성일: 2026-05-19
> 유형: 신규 컨텐츠 (M8b 마일스톤 — 페이즈 2 산출물 1/4)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1)
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2)
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3)
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4)
> - `band_of_mercenaries/lib/features/quest/domain/role_synergy_matrix.dart` — `RoleSynergyMatrix` (의뢰 성공률용, M8b 무관)
> - `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` — `Mercenary.effectiveXxx` (snapshot 동결 입력)
> - Supabase `jobs` 테이블 — role 분포 분석 (§3.1)
> - `Docs/roadmap/master_roadmap.md` M8b 섹션 1271행 — "직업군별 대표 스킬 6~10종"
>
> 후속:
> - 페이즈 2 #2 적 유형 능력치·행동 패턴 (적 측 스킬 공유 카탈로그 §8 입력)
> - 페이즈 2 #3 상태 효과 수치 확정 (applyChance·intensity·duration 정밀 조정)
> - 페이즈 2 #4 전투 로그 길이·수치 노출 기준 (§9 스킬별 보고서 라인)
> - 페이즈 3 #2 `combat_skills` 테이블 시드 데이터 10행
> - 페이즈 4 #2 `CombatSkill` freezed 모델 (§10 데이터 구조)

## 개요

본 산출물은 M8b 전투 시뮬레이터에 들어갈 **파티 측 직업군 대표 스킬 10종**의 구조 카탈로그를 정의한다. warrior/rogue/ranger/mage/support/specialist 6 직업군이 모두 최소 1개 대표 스킬을 가진다. 페이즈 1 #1~#4가 정의한 4 페이즈 흐름·행동 순서·산식 hook·상태 효과 카탈로그를 모두 결합한 첫 번째 컨텐츠 산출물이다.

페이즈 2 #1은 "어떤 스킬이 있고, 어떻게 결합되는가"의 카탈로그에 집중한다. 정확한 수치(피해 배수 N×, applyChance Y%, 쿨다운 Z턴, 지속 N턴)는 **권고값으로 명시**하되 페이즈 2 #3 및 페이즈 4 #5 검증에서 미세 조정한다. 페이즈 1 #1~#4의 모든 결정·산식은 변경하지 않는다.

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|--------------|----------|
| Darkest Dungeon — Class Skills 4개 슬롯 | 직업마다 4 스킬 고정, 광역/단일/회복/디버프 균형 | M8b는 직업군당 1~2 스킬로 축약. 직업군 정체성만 명확히 |
| Battle Brothers — Active Ability vs Passive | 액티브와 패시브가 분리 슬롯, 쿨다운과 AP 모두 사용 | `actionCost` (action/extraAction/passive) + `cooldownRounds`로 단순화 |
| FFXIV — GCD/oGCD 구분 | 일반 행동 슬롯과 즉발 행동 슬롯이 분리 | 추가 행동(`extraAction: true`)은 `oGCD`처럼 라운드 행동 슬롯을 소모하지 않음 |
| Slay the Spire — Card Synergies | 한 카드 효과가 다른 카드를 강화하는 결합 | 광역 디버프 + 후속 단일 대미지로 콤보 가능 |

## 1. 메타 결정

### 1.1 스킬 수: 10종 채택

페이즈 1 #1 권장 범위 8~12 안에서 **10종**으로 시작한다.

| 직업군 | 스킬 수 | 근거 |
|--------|---------|------|
| warrior | 2 | jobs 분포 압도적(26개, T1~T5 전구간 분산). 탱커 패시브와 분노형 액티브 분리 필요 |
| rogue | 1 | 직업군 정체성은 광역 약화 1개로 충분히 표현된다. 출혈 단일기는 적 측 전용으로 분리한다 |
| ranger | 2 | 정조준(액티브 buff)과 연속 사격(다단 행동)이 정체성 핵심 — 분리 필요 |
| mage | 2 | 광역 공격과 mez 부여가 정체성 핵심 — 분리 필요. T1 부재이나 T2 이상에서 의미 |
| support | 2 | 광역 buff와 dispel은 다른 발동 hook이라 1 스킬에 묶을 수 없음 |
| specialist | 1 | jobs T1 11개, T2~T5 합 5개 — 신규 유저 게이트와 페이즈 2 요구사항을 동시에 만족하기 위해 저강도 생존 스킬 1개 배치 |

**최종 채택**: 10종 (warrior 2 / rogue 1 / ranger 2 / mage 2 / support 2 / specialist 1)

specialist는 **저강도 회피 보조 스킬 1개**를 가진다. 근거:
- `state.md` 페이즈 2 #1 권장 내용은 6 직업군 각각 1개 이상 대표 스킬을 요구한다.
- specialist가 T1 직업 대부분을 차지하므로 강한 공격 스킬을 주면 신규 구간 전투 복잡도가 급격히 증가한다.
- `buff_evasion_up`은 페이즈 1 #4 카탈로그에 이미 존재하지만 기존 스킬 카탈로그에서 직접 활용되지 않았다. specialist 스킬은 미활성 hook을 채우면서도 피해량 곡선을 흔들지 않는다.
- 기본 공격 폴백 정체성은 유지하되, 위기 회피 1회로 "임기응변" 역할을 표현한다.

### 1.2 스킬 발동 정책: 직업군 1개만 자동 배정 (단순화)

각 mercenary는 자신의 role에 정의된 스킬 중 **1개만 자동 보유**한다. 보유 스킬은 `mercenary.role`로 결정되며, mercenary의 스킬 선택 UI는 M8b MVP에 포함하지 않는다.

| 직업군 | 자동 보유 스킬 |
|--------|---------------|
| warrior | `skill_warrior_shield_bulwark` (패시브, 항상) + `skill_warrior_battle_fury` (액티브) — 둘 다 보유 |
| rogue | `skill_rogue_mass_blind` (액티브, 광역 디버프 우선) |
| ranger | `skill_ranger_marksman_focus` (액티브 buff) + `skill_ranger_volley_shot` (액티브 다단) — 라운드 교대 자동 |
| mage | `skill_mage_arcane_blast` (액티브 광역) + `skill_mage_stun_bolt` (액티브 mez) — 라운드 교대 자동 |
| support | `skill_support_aegis_aura` (액티브 광역 buff) + `skill_support_cleansing_word` (액티브 dispel) — 상황 자동 선택 |
| specialist | `skill_specialist_adaptive_footwork` (액티브 self buff) — 위기 시 회피 보조 |

| 직업군 | 자동 배정 정책 | 근거 |
|--------|---------------|------|
| warrior | 2개 모두 보유. `shield_bulwark`은 패시브라 슬롯 점유 없음 | 패시브와 액티브가 정체성 다름 |
| rogue | 1개만 자동 보유 (`mass_blind`) | 출혈 단일기는 페이즈 2 #2 적 전용 `bleeding_cut`로 분리. 파티 측 MVP는 광역 우선 |
| ranger | 2개 보유, 라운드별 교대 (`focus` 후 `volley`) | 정조준 → 후속 라운드 연속 사격이 콤보 |
| mage | 2개 보유, 라운드별 교대 (광역 우선 → 위협 적에 stun) | 두 스킬 모두 핵심 정체성 |
| support | 2개 보유, 아군 상태에 따라 자동 선택 | aegis(buff 부재 시) vs cleansing(debuff 보유자 존재 시) |
| specialist | 1개 보유 (`adaptive_footwork`) | 낮은 피해 기여 대신 생존 보조. 기본 공격 폴백 정체성 유지 |

스킬 선택 자동화 로직은 페이즈 4 #1 `CombatSimulator` 명세에서 확정한다. 본 산출물은 보유 정책만 명시한다.

### 1.3 적 측 카탈로그 공유 정책

본 산출물의 10 스킬 중 **일부는 적 측에서 재사용 가능**하다. 적 전용 스킬은 페이즈 2 #2에서 별도 정의한다.

| 스킬 | 적 측 재사용 가능 여부 |
|------|---------------------|
| `skill_warrior_shield_bulwark` | 가능 (방패 든 적 — 토벌 의뢰의 도적 두목 등) |
| `skill_warrior_battle_fury` | 가능 (광폭화 적 — 엘리트 야수 등) |
| `skill_rogue_mass_blind` | 가능 (도적 떼 우두머리) |
| `skill_ranger_marksman_focus` | 가능 (적 궁수) |
| `skill_ranger_volley_shot` | 가능 (적 궁수, 다인 사격 패턴) |
| `skill_mage_arcane_blast` | 가능 (적 흑마법사) |
| `skill_mage_stun_bolt` | 가능 (적 마법사) |
| `skill_support_aegis_aura` | 가능 (적 신관, 도적단 결속 보스) |
| `skill_support_cleansing_word` | **불가** (서사적으로 적이 정화를 외치는 장면 부재) |
| `skill_specialist_adaptive_footwork` | 가능 (기민한 적, 함정꾼, 표식수) |

총 9 스킬이 적 측 공유 가능하며 1 스킬(`cleansing_word`)은 파티 전용이다. 페이즈 2 #2 적 유형 설계에서 적별로 0~2 스킬을 위 풀에서 또는 적 전용 풀에서 선택한다.

## 2. 스킬 카탈로그 (10종)

### 2.1 warrior 2종

#### `skill_warrior_shield_bulwark` (방패 보루)

| 속성 | 값 |
|------|-----|
| ID | `skill_warrior_shield_bulwark` |
| 라벨 | 방패 보루 |
| 직업군 | warrior |
| 발동 조건 | 패시브 — 피격 시 방패 막기 판정에 추가 발동 가능성 |
| 행동 슬롯 비용 | passive (행동 슬롯 미소모) |
| 쿨다운 | 0 |
| 표적 | self (방어 효과) |
| 페이즈 1 #3 산식 결합 | §4.3 `shieldBlockMitigation` +0.10 (방패 트레잇 0~1개 보유 시 효과 가산). 페이즈 1 #2 §8.4 회피 → 방패 막기 판정 순서에 결합 |
| 페이즈 1 #4 상태 효과 연결 | 없음 |
| 권고 수치 (페이즈 2 #3 검증) | shieldBlockBonus = +0.10. 방패 트레잇 없음 시 +0.20 (단독 패시브로 동작) |
| 보고서 라인 후보 | "{merc.name}이(가) 방패로 받아냈다. 피해 -{N}%" |

**산식 결합 메모**: 페이즈 1 #3 §4.3 방패 트레잇 0~2개에 따라 0.20/0.30/0.40 감소가 정의되어 있다. `shield_bulwark`은 이 카탈로그에 **추가로 +0.10** 가산하여 상한 0.60 (§4.3 페이즈 2 #1 발동 시) 안에서 안전하게 동작한다. 패시브이므로 별도 발동 판정 없음.

#### `skill_warrior_battle_fury` (전투 분노)

| 속성 | 값 |
|------|-----|
| ID | `skill_warrior_battle_fury` |
| 라벨 | 전투 분노 |
| 직업군 | warrior |
| 발동 조건 | 액티브 — 본인 HP 50% 이하 시 자동 발동 (1회 / 전투당) |
| 행동 슬롯 비용 | extraAction (행동 슬롯 미소모, 라운드 추가 행동 1회) |
| 쿨다운 | — (전투당 1회 발동 제한) |
| 표적 | self |
| 페이즈 1 #3 산식 결합 | 본인에게 §3.2 `statusEffectAttackMod` 입력 |
| 페이즈 1 #4 상태 효과 연결 | `buff_attack_up` 부여 (적용 방식 곱셈 / intensity 페이즈 2 #3) |
| 권고 수치 (페이즈 2 #3 검증) | applyChance 100% (자동 발동), intensity 0.30, durationTurns 3 |
| 보고서 라인 후보 | "{merc.name}이(가) 분노에 휩싸였다. 공격력 강화 {N}턴" |

**다단 행동 결합 사례**: `battle_fury`는 페이즈 1 #2 §9.3 추가 행동(`extraAction: true`)으로 라운드 행동 슬롯을 소모하지 않고 즉시 발동된다. 발동 라운드에서는 (a) battle_fury 발동(추가 행동) → (b) 정상 기본 공격 또는 다른 액티브 스킬(행동 슬롯 소모) 순서로 2 행동 가능. 단 페이즈 1 #2 §9.3 정책에 따라 추가 행동에서 또 추가 행동은 발생하지 않는다.

### 2.2 rogue 1종

#### `skill_rogue_mass_blind` (광역 약화)

| 속성 | 값 |
|------|-----|
| ID | `skill_rogue_mass_blind` |
| 라벨 | 광역 약화 |
| 직업군 | rogue |
| 발동 조건 | 액티브 — 행동 슬롯 사용 시 자동 선택 (쿨다운 미적용 라운드에서) |
| 행동 슬롯 비용 | action (행동 1회 소모) |
| 쿨다운 | 3 라운드 |
| 표적 | 광역 — 적 전열 전체 (최대 3대상) |
| 페이즈 1 #3 산식 결합 | 페이즈 1 #2 §9.1 광역 공격 정책. 대상별 §6 명중 판정 독립. 피해는 §5.1 `skillDamageMultiplier` 0.7× 적용 |
| 페이즈 1 #4 상태 효과 연결 | `debuff_attack_down` 부여 (적용 방식 곱셈) |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 0.7×, applyChance 70%, intensity 0.20, durationTurns 2 |
| 보고서 라인 후보 | "{merc.name}이(가) 적 전열에 연막을 던졌다. {N}명이 공격력 약화에 빠졌다" |

**산식 결합 메모**: 광역 공격이라 피해 자체는 단발(0.7×)로 낮지만, 광역 디버프(`debuff_attack_down`)가 후속 라운드의 적 공격을 약화시켜 누적 가치가 크다. 광역이라 페이즈 1 #2 §9.1 정책에 따라 대상별 회피·방패 판정과 applyChance 판정은 독립적이다.

단일 출혈 일격은 페이즈 2 #2 적 유형 설계에서 `skill_enemy_bleeding_cut` 적 전용 스킬로 분리한다. 파티 측 rogue는 광역 약화 1개로 대표성을 확보한다.

### 2.3 ranger 2종

#### `skill_ranger_marksman_focus` (정조준)

| 속성 | 값 |
|------|-----|
| ID | `skill_ranger_marksman_focus` |
| 라벨 | 정조준 |
| 직업군 | ranger |
| 발동 조건 | 액티브 — 본인이 가장 빠른 행동(라운드 1순위)인 라운드에 자동 발동 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 4 라운드 |
| 표적 | self (buff 부여) |
| 페이즈 1 #3 산식 결합 | §6 `statusEffectHitMod` (가산) + §7 baseCritRate에 부수 효과 — 페이즈 1 #4 §1.5 미매핑 hook 활용. `statusEffectCritMod` 직접 표현 |
| 페이즈 1 #4 상태 효과 연결 | `buff_accuracy_up` 부여. 단 본 스킬은 `buff_accuracy_up`을 사용하면서 **추가로 치명타 +0.15** 직접 적용 (§1.5 hook 미매핑 항목을 스킬에서 표현하는 사례) |
| 권고 수치 (페이즈 2 #3 검증) | `buff_accuracy_up` intensity 0.15 / durationTurns 2 + 부수 효과 critRate +0.15 (statusEffectCritMod 직접 표현) |
| 보고서 라인 후보 | "{merc.name}이(가) 호흡을 멈추고 조준했다. 명중·치명타 강화 {N}턴" |

**페이즈 1 #4 §1.5 미매핑 hook 직접 처리 예시**: 페이즈 1 #4는 `statusEffectCritMod`를 MVP 상태 효과 카탈로그에서 미매핑으로 분리했다. `marksman_focus`는 이 hook을 `buff_accuracy_up` 표준 상태 효과 + 스킬 자체의 critRate 직접 가산으로 결합한다. `CombatStatusEffect` 모델은 표준 4 카테고리만 유지하면서 스킬이 hook을 직접 활성화하는 패턴 사례다. 페이즈 4 #1 시뮬레이터 명세에서 hook 직접 표현 API 위치를 확정한다.

#### `skill_ranger_volley_shot` (연속 사격)

| 속성 | 값 |
|------|-----|
| ID | `skill_ranger_volley_shot` |
| 라벨 | 연속 사격 |
| 직업군 | ranger |
| 발동 조건 | 액티브 — `marksman_focus` `buff_accuracy_up` 발동 중 시점 자동 선택 (콤보) |
| 행동 슬롯 비용 | action |
| 쿨다운 | 3 라운드 |
| 표적 | 단일 — 동일 대상 3회 연속 타격 (페이즈 1 #2 §9.2 연속 공격) |
| 페이즈 1 #3 산식 결합 | §5.1 `skillDamageMultiplier` 0.65× (회당). 각 타격별 §6 명중 / §7 치명타 / §8 회피 / §9 반격 판정 독립 |
| 페이즈 1 #4 상태 효과 연결 | 없음 |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 0.65× × 3회 = 합산 기대 1.95× (단 명중 판정 독립이라 실효 1.5~1.7×) |
| 보고서 라인 후보 | "{merc.name}이(가) {enemy.name}에게 3연사. {합계N}의 피해" |

**다단 행동 결합 사례**: 페이즈 1 #2 §9.2 연속 공격 정책 — 행동 슬롯 1번만 소모, 동일 대상에 3회 타격. 회피·방패·반격 판정은 N회 독립. 첫 타격에서 대상 사망 시 남은 타격은 무효(추가 표적 전환 없음). 페이즈 1 #2 §9.4 광역+연속 결합은 본 스킬에서 미사용. `marksman_focus`로 명중·치명타가 강화된 라운드에 연속 사격을 결합하는 콤보 디자인.

### 2.4 mage 2종

#### `skill_mage_arcane_blast` (광역 마법)

| 속성 | 값 |
|------|-----|
| ID | `skill_mage_arcane_blast` |
| 라벨 | 광역 마법 |
| 직업군 | mage |
| 발동 조건 | 액티브 — 적 진영에 2명 이상 생존 시 자동 선택 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 3 라운드 |
| 표적 | 광역 — 적 임의 3명 (mage 표적 정책 §7 광역 후보) |
| 페이즈 1 #3 산식 결합 | §5.1 `skillDamageMultiplier` 1.0× (광역이라 단발 동등). 페이즈 1 #2 §9.1 광역 정책 — 대상별 명중·회피·치명타 독립 |
| 페이즈 1 #4 상태 효과 연결 | 없음 |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 1.0×, 표적 수 최대 3 |
| 보고서 라인 후보 | "{merc.name}의 마법이 적 {N}명을 휩쓸었다. 총 {합계}의 피해" |

#### `skill_mage_stun_bolt` (기절 일격)

| 속성 | 값 |
|------|-----|
| ID | `skill_mage_stun_bolt` |
| 라벨 | 기절 일격 |
| 직업군 | mage |
| 발동 조건 | 액티브 — 단일 위협 적(엘리트·HP 최고) 존재 시 자동 선택 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 4 라운드 |
| 표적 | 단일 — 위협 적 (HP 최대 또는 elite_id non-null) |
| 페이즈 1 #3 산식 결합 | §5.1 `skillDamageMultiplier` 0.7× (저피해, mez 의도) |
| 페이즈 1 #4 상태 효과 연결 | `mez_stunned` 부여 (refresh) |
| 권고 수치 (페이즈 2 #3 검증) | skillDamageMultiplier 0.7×, applyChance 50%, durationTurns 1 |
| 보고서 라인 후보 | "{merc.name}의 마법이 {enemy.name}을 기절시켰다" |

**상태 효과 결합 메모**: 페이즈 1 #4 §6.2 stunned 행동 시점 분기에 따라 다음 라운드에 적 위협의 공격 행동이 1회 스킵된다. 페이즈 1 #4 §6.5 추가 행동 hook과의 결합 정책 — stunned 보유자는 트레잇 패시브·스킬 추가 행동은 차단되지만 반격(반응 행동)은 정상 수행한다. applyChance 50%로 의도적으로 낮춰 매 라운드 발동을 금지하고 mez 가치를 보존한다.

### 2.5 support 2종

#### `skill_support_aegis_aura` (수호의 오라)

| 속성 | 값 |
|------|-----|
| ID | `skill_support_aegis_aura` |
| 라벨 | 수호의 오라 |
| 직업군 | support |
| 발동 조건 | 액티브 — 파티에 `buff_defense_up` 보유자 0명일 때 자동 선택 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 4 라운드 |
| 표적 | 광역 — 아군 전원 (생존자 한정) |
| 페이즈 1 #3 산식 결합 | 아군 전원에게 §4 `statusEffectDefenseMod` 입력 |
| 페이즈 1 #4 상태 효과 연결 | `buff_defense_up` 부여 (적용 방식 곱셈) |
| 권고 수치 (페이즈 2 #3 검증) | applyChance 100% (자동 발동), intensity 0.20, durationTurns 3 |
| 보고서 라인 후보 | "{merc.name}의 오라가 아군을 감쌌다. 방어력 강화 {N}턴" |

**다단 행동 결합 사례**: 페이즈 1 #2 §9.1 광역 공격 정책을 아군 광역 buff로 확장한 변형 사례. 표적별 회피·방패 판정 없음 (아군 대상). 행동 슬롯 1번만 소모.

#### `skill_support_cleansing_word` (정화의 외침) — **파티 전용**

| 속성 | 값 |
|------|-----|
| ID | `skill_support_cleansing_word` |
| 라벨 | 정화의 외침 |
| 직업군 | support (파티 전용, 적 측 미배정) |
| 발동 조건 | 액티브 — 파티에 `debuff_*` 또는 `dot_*` 보유자 1명 이상일 때 자동 선택 (aegis_aura보다 우선) |
| 행동 슬롯 비용 | action |
| 쿨다운 | 3 라운드 |
| 표적 | 광역 — 아군 전원 (생존자 한정) |
| 페이즈 1 #3 산식 결합 | 없음 (dispel은 산식 hook 미사용) |
| 페이즈 1 #4 상태 효과 연결 | `dispel_debuff` (페이즈 1 #4 §8.2) — debuff 1개 + dot 1개 해제 (대상별). `mez_stunned`은 해제 불가 (페이즈 1 #4 §8.2 MVP 정책) |
| 권고 수치 (페이즈 2 #3 검증) | applyChance 100%, dispel 우선순위: dot > debuff (대상별 1개씩) |
| 보고서 라인 후보 | "{merc.name}의 외침이 아군의 {효과}를 풀어냈다" |

**적 측 미배정 근거**: §1.3 — 적이 정화를 외치는 서사 부재. 페이즈 2 #2 적 유형에서 dispel 필요 시 적 전용 스킬을 별도 정의한다.

### 2.6 specialist 1종

#### `skill_specialist_adaptive_footwork` (임기응변)

| 속성 | 값 |
|------|-----|
| ID | `skill_specialist_adaptive_footwork` |
| 라벨 | 임기응변 |
| 직업군 | specialist |
| 발동 조건 | 액티브 — 본인에게 `buff_evasion_up`이 없고 적 2명 이상 생존 시 자동 선택. HP 60% 이하이면 우선순위 상승 |
| 행동 슬롯 비용 | action |
| 쿨다운 | 4 라운드 |
| 표적 | self |
| 페이즈 1 #3 산식 결합 | §8 `statusEffectEvasionMod` 입력 |
| 페이즈 1 #4 상태 효과 연결 | `buff_evasion_up` 부여 (가산) |
| 권고 수치 (페이즈 2 #3 검증) | applyChance 100%, intensity 0.10, durationTurns 2 |
| 보고서 라인 후보 | "{merc.name}이(가) 발밑을 고쳐 잡았다. 회피 강화 {N}턴" |

**역할 메모**: specialist는 공격 스킬을 갖지 않는다. `adaptive_footwork`는 행동 1회를 소비해 생존성을 조금 올리는 선택지이며, 신규 구간의 전투 복잡도를 낮게 유지한다. 페이즈 1 #3 회피 상한 75%와 페이즈 2 #3 회피 클램프 검증에 직접 입력된다.

### 2.7 스킬 카탈로그 요약 표

| 스킬 ID | 직업군 | 발동 | 슬롯 | 쿨다운 | 표적 | skillDamage | 상태 효과 | 적 공유 |
|---------|--------|------|------|--------|------|-------------|----------|--------|
| `skill_warrior_shield_bulwark` | warrior | passive | passive | — | self | — | — | O |
| `skill_warrior_battle_fury` | warrior | trigger (HP<50%, 1회) | extraAction | — | self | — | buff_attack_up | O |
| `skill_rogue_mass_blind` | rogue | active | action | 3 | aoe enemy(3) | 0.7× | debuff_attack_down (70%) | O |
| `skill_ranger_marksman_focus` | ranger | active (1순위 자동) | action | 4 | self | — | buff_accuracy_up + critMod +0.15 | O |
| `skill_ranger_volley_shot` | ranger | active (focus 콤보) | action | 3 | single ×3 | 0.65× | — | O |
| `skill_mage_arcane_blast` | mage | active | action | 3 | aoe enemy(3) | 1.0× | — | O |
| `skill_mage_stun_bolt` | mage | active (위협) | action | 4 | single enemy | 0.7× | mez_stunned (50%) | O |
| `skill_support_aegis_aura` | support | active (buff 부재 시) | action | 4 | aoe ally | — | buff_defense_up | O |
| `skill_support_cleansing_word` | support (파티 전용) | active (debuff 보유 시) | action | 3 | aoe ally | — | dispel_debuff | X |
| `skill_specialist_adaptive_footwork` | specialist | active (위기) | action | 4 | self | — | buff_evasion_up | O |

## 3. 데이터 기반 직업군 분포 검증

### 3.1 jobs 테이블 role 분포 (Supabase 실데이터)

| 직업군 | 총 직업 수 | T1 | T2 | T3 | T4 | T5 |
|--------|----------|----|----|----|----|----|
| warrior | 26 | 1 | 8 | 6 | 4 | 7 |
| specialist | 16 | 11 | 1 | 1 | 1 | 2 |
| mage | 16 | 0 | 1 | 3 | 7 | 5 |
| support | 10 | 0 | 1 | 3 | 4 | 2 |
| ranger | 9 | 1 | 4 | 3 | 1 | 0 |
| rogue | 8 | 3 | 2 | 1 | 1 | 1 |

### 3.2 분포 분석

| 관측 | 분석 | 스킬 카탈로그 결정 |
|------|------|-----|
| warrior 26개 (T1~T5 균등) | 신규~엔드게임 전 구간 등장 | 2 스킬(패시브+액티브)로 정체성 다층화 |
| specialist T1 11개 / T2~T5 합 5개 | T1 시기 폴백 직업군 (신규 유저 게이트 F등급 대응) | §1.1 — 공격 스킬 없이 회피 보조 1개만 배치 |
| mage T1 부재 / T4·T5 합 12개 | T2부터 등장. 고티어 비중 큼 | 광역+mez 2 스킬로 고티어에서 핵심 역할 |
| support T1 부재 / T3~T5 분포 | mage와 동일 T2+ 등장 | 광역 buff + dispel 2 스킬로 핵심 역할 |
| ranger 9개 / T5 부재 | T5 단계 비중 작음 (M2b 이후 T5 ranger 1개 추가 예정 — `role_synergy_matrix.dart:6` 주석) | 콤보형 2 스킬(정조준+연속사격)로 가치 보강 |
| rogue 8개 / T1 3개 + T5 1개 | 전 구간 분포되나 풀이 가장 작음 | 1 스킬만 파티 배정(`mass_blind`). 출혈 단일기는 적 측 전용으로 분리 |

### 3.3 신규 유저 게이트 호환

`Docs/roadmap` M3+ `NewbieGate` 정책 — F등급 신규 유저는 T1만 모집. T1 jobs 분포:

| 직업군 | T1 직업 수 | T1 시점 스킬 보유 |
|--------|----------|----------------|
| specialist | 11 | `skill_specialist_adaptive_footwork` (저강도 회피 보조) |
| rogue | 3 | `skill_rogue_mass_blind` |
| warrior | 1 | `skill_warrior_shield_bulwark` (패시브) + `skill_warrior_battle_fury` |
| ranger | 1 | `skill_ranger_marksman_focus` + `skill_ranger_volley_shot` |
| mage | 0 | (없음) |
| support | 0 | (없음) |

F등급 신규 유저는 16/85 (전체 직업의 19%)의 T1 풀에서 모집한다. 그중 specialist 11개는 공격 스킬이 없고 회피 보조만 보유하므로 전투 단순성이 보장된다. 그러나 M8b 시뮬레이션 자체는 신규 유저 의뢰(허드렛일·일반 의뢰)에 적용되지 않으므로 (페이즈 1 #1 §적용 범위), 이 호환성은 사실상 안전 가드일 뿐 실질 발동 빈도는 0에 가깝다.

### 3.4 권고 검증

| 직업군 | jobs 비중 | 스킬 수 | 비중 정합 |
|--------|---------|--------|----------|
| warrior | 30.6% | 2 | 정합 (가장 다수 직업군에 다층 스킬) |
| specialist | 18.8% | 1 | 정합 (저강도 생존 보조) |
| mage | 18.8% | 2 | 정합 (고티어 핵심) |
| support | 11.8% | 2 | 정합 (소수지만 정체성 핵심) |
| ranger | 10.6% | 2 | 정합 (콤보 가치) |
| rogue | 9.4% | 1 (파티) | 정합 (소수, 광역 우선) |

## 4. 산식 결합 종합 매트릭스

### 4.1 페이즈 1 #3 hook 8곳 활성화 매트릭스

| 페이즈 1 #3 hook | 활성화 스킬 | 상태 효과 ID | 결합 방식 |
|----------------|------------|-------------|----------|
| §3.2 `statusEffectAttackMod` | `skill_warrior_battle_fury` | `buff_attack_up` | 곱셈 |
| §4 `statusEffectDefenseMod` | `skill_support_aegis_aura` | `buff_defense_up` | 곱셈 |
| §4.3 `shieldBlockMitigation` | `skill_warrior_shield_bulwark` | — | 직접 가산 +0.10 |
| §5.1 `skillDamageMultiplier` | `mass_blind`(0.7×) / `volley_shot`(0.65×) / `arcane_blast`(1.0×) / `stun_bolt`(0.7×) | — | 직접 배수 |
| §6 `statusEffectHitMod` | `skill_ranger_marksman_focus` | `buff_accuracy_up` | 가산 |
| §7 `statusEffectCritMod` | `skill_ranger_marksman_focus` (직접 표현) | — | §1.5 미매핑 hook 스킬 직접 처리 |
| §8 `statusEffectEvasionMod` | `skill_specialist_adaptive_footwork` | `buff_evasion_up` | 가산 |
| §9 `statusEffectRiposteMod` | (MVP 직접 활성화 스킬 없음 — §1.5 미매핑) | — | 페이즈 2 #1 후속 확장 시 직접 처리 |

| §10 `traitDeathResist` | (스킬 미연결) | — | 트레잇·세력 패시브만 |

**관측**:
- 페이즈 1 #3 hook 8곳 중 7곳이 본 산출물 10 스킬에 의해 활성화된다.
- 미활성 hook 1곳(`statusEffectRiposteMod`)은 페이즈 2 #2 적 측 또는 후속 확장에서 채운다.
- 페이즈 1 #4 카탈로그 10 타입 중 `buff_evasion_up`은 specialist 대표 스킬로 직접 활성화된다.

### 4.2 페이즈 1 #2 다단 행동 정책 결합 매트릭스

| 다단 행동 종류 | 활용 스킬 |
|---------------|---------|
| 광역 공격 (§9.1) | `mass_blind`(적 전열 3) / `arcane_blast`(적 임의 3) / `aegis_aura`(아군 전원) / `cleansing_word`(아군 전원) |
| 연속 공격 (§9.2) | `volley_shot`(동일 대상 3회) |
| 추가 행동 (§9.3) | `battle_fury`(`extraAction: true`, 본인 자기 강화) |
| 광역+연속 결합 (§9.4) | MVP 미사용 — 페이즈 2 #1 후속 확장 시 사례 검토 |

### 4.3 페이즈 1 #4 상태 효과 활용 매트릭스

| 상태 효과 ID | 활용 스킬 | 권고 발동 빈도 |
|------------|---------|-------------|
| `buff_attack_up` | `battle_fury` (warrior 자기 부여) | 전투당 1회 / mercenary |
| `buff_defense_up` | `aegis_aura` (support 광역 부여) | 4 라운드 1회 / mercenary |
| `buff_accuracy_up` | `marksman_focus` (ranger 자기 부여) | 4 라운드 1회 / mercenary |
| `buff_evasion_up` | `adaptive_footwork` (specialist 자기 부여) | 4 라운드 1회 / mercenary |
| `debuff_attack_down` | `mass_blind` (rogue 광역 부여, 적용 70%) | 3 라운드 1회 / mercenary |
| `debuff_defense_down` | (MVP 스킬 미사용 — 페이즈 2 #2 적 측 카탈로그 후보) | — |
| `debuff_accuracy_down` | (MVP 스킬 미사용 — 페이즈 1 #1 환경 효과만, mist_field 적군에 자동 부여) | — |
| `mez_stunned` | `stun_bolt` (mage 단일 부여, 적용 50%) | 4 라운드 1회 / mercenary |
| `dot_bleeding` | (페이즈 2 #2 적 전용 `bleeding_cut` 부여, 적용 60%) | 2 라운드 1회 / 적 |
| `dot_poisoned` | (MVP 스킬 미사용 — 페이즈 2 #2 적 측 독 계열 카탈로그 후보) | — |

**관측**:
- 10 상태 효과 중 6개가 본 산출물 10 스킬에 의해 직접 활성화된다.
- 미활성 4개(`debuff_defense_down`/`debuff_accuracy_down`/`dot_bleeding`/`dot_poisoned`)는 환경·적 측 카탈로그로 채워진다.
- `debuff_accuracy_down`은 페이즈 1 #1 mist_field 전장에서 적군 자동 부여로 활성화됨. MVP 스킬 미사용이 비활성을 의미하지 않음.
- 페이즈 2 #2 적 측 설계에서 `debuff_defense_down`(엘리트 갑옷 파괴)·`dot_bleeding`(암살자)·`dot_poisoned`(독사 계열) 후보가 명확히 보인다.

## 5. 페이즈 1 #4 §1.5 미매핑 hook 직접 처리 사례

페이즈 1 #4 §1.5에서 MVP 미매핑으로 분리한 4 hook 처리 방식:

| Phase 1 #4 §1.5 hook | 본 카탈로그 처리 |
|---------------------|----------------|
| §7 `statusEffectCritMod` | `skill_ranger_marksman_focus`가 `buff_accuracy_up`(표준 상태) + critRate +0.15(스킬 자체 부수 효과)로 분리 표현. `CombatStatusEffect` 모델 확장 불필요. 페이즈 4 #1 시뮬레이터 명세에서 hook 직접 표현 API 위치 확정 |
| §9 `statusEffectRiposteMod` | MVP 미활용. 페이즈 2 #1 후속 확장에서 `skill_warrior_*` 또는 트레잇 보강 시 동일 패턴(`buff_*` 표준 + 스킬 자체 부수 효과)으로 표현 가능 |
| §5.1 `skillDamageMultiplier` | 5 스킬에서 직접 활용 — `CombatSkill.skillDamageMultiplier` 필드로 영속화. 상태 효과 hook 아님 |
| §10 사망 저항 보정 | MVP 미활용 — 트레잇·세력 패시브 hook으로만 활성화 (페이즈 1 #3 §10) |

**핵심 패턴**: 페이즈 1 #4 §1.5의 의도(MVP 범위 보호, 스킬 정체성 강화)를 보존하면서, 스킬 부수 효과를 표준 상태 효과와 비표준 직접 가산으로 분리 표현하는 방식을 채택한다.

## 6. 콤보 패턴 사례

본 카탈로그가 만드는 직업군 콤보:

### 6.1 ranger 콤보 (정조준 → 연속 사격)

| 라운드 | 행동 |
|--------|------|
| R1 | `marksman_focus` 발동 → `buff_accuracy_up` + critMod +0.15 (자기) |
| R2 | `volley_shot` 발동 → 같은 라운드에 명중·치명타 강화 효과 적용 (R1 buff 잔존, R2 라운드 종료 시 -1 → R3까지 적용) |
| R3 | 일반 공격 또는 `volley_shot` 쿨다운 종료 후 재발동 |

평균 R2 라운드의 단발 피해: `baseAttack` × 0.65 × (R1 buff_accuracy +0.15 + R1 critMod +0.15 시너지) × 3회 = 평균 1.7배 효과 (페이즈 2 #3 검증).

### 6.2 rogue + warrior 콤보 (광역 약화 + 반격)

| 라운드 | 파티 행동 | 적 행동 |
|--------|---------|---------|
| R1 | rogue `mass_blind` → 적 전열 3명에 `debuff_attack_down` 70% 부여 | 적 공격 약화 |
| R2 | warrior 일반 공격 | 적 약화된 공격 → warrior 회피·반격 빈도 증가 |
| R3 | rogue 일반 공격 / warrior `battle_fury` (HP 50% 시) | 적 후속 공격 |

페이즈 1 #3 §9 반격 산식에서 warrior 기본 반격 25% + 적 공격력 약화로 반격 발동 가치 증가.

### 6.3 mage + support 콤보 (광역 마법 + 광역 강화)

| 라운드 | 파티 행동 |
|--------|---------|
| R1 | support `aegis_aura` → 아군 전원 `buff_defense_up` 2턴 |
| R2 | mage `arcane_blast` → 적 임의 3명에 광역 |
| R3 | mage `stun_bolt` → 위협 적에 `mez_stunned` |

support 광역 buff로 아군 생존 시간 확보 → mage 광역·mez로 적 전열 와해.

### 6.4 콤보가 적 측 진형 정책과 결합하는 방식

페이즈 1 #2 §7 진형 매칭 — 적 전열이 와해되면 후열 노출. mage·support는 §7.4 전열 보호 정책에 따라 라운드 1~2 동안 후열 보호 받음. R2 mage `arcane_blast`로 적 전열 와해 후 R3에서 적 후열이 직접 공격받기 시작.

## 7. 자동 발동 정책 결정 트리

페이즈 4 #1 `CombatSimulator` 명세에 들어갈 스킬 자동 선택 로직의 의사 코드:

```text
function selectSkillForCombatant(combatant, roundState):
  // 우선순위 1: 트리거 기반 (HP, 상태)
  if (combatant.role == 'warrior' && combatant.hp <= maxHp * 0.5 && !combatant.flagBattleFuryUsed):
    return 'skill_warrior_battle_fury' as extraAction
  
  // 우선순위 2: 콤보·상황 매칭
  if (combatant.role == 'support' && allies.any(a => a.hasDebuff || a.hasDot)):
    if (combatant.cooldown['skill_support_cleansing_word'] == 0):
      return 'skill_support_cleansing_word'
  
  if (combatant.role == 'support' && allies.none(a => a.hasBuff('buff_defense_up'))):
    if (combatant.cooldown['skill_support_aegis_aura'] == 0):
      return 'skill_support_aegis_aura'
  
  if (combatant.role == 'mage' && enemies.any(e => e.isElite || e.hp >= maxEnemyHp)):
    if (combatant.cooldown['skill_mage_stun_bolt'] == 0):
      return 'skill_mage_stun_bolt'
  
  if (combatant.role == 'mage' && enemies.count(alive) >= 2):
    if (combatant.cooldown['skill_mage_arcane_blast'] == 0):
      return 'skill_mage_arcane_blast'
  
  if (combatant.role == 'ranger' && combatant.hasBuff('buff_accuracy_up')):
    if (combatant.cooldown['skill_ranger_volley_shot'] == 0):
      return 'skill_ranger_volley_shot'
  
  if (combatant.role == 'ranger' && combatant.isFirstInOrder):
    if (combatant.cooldown['skill_ranger_marksman_focus'] == 0):
      return 'skill_ranger_marksman_focus'
  
  if (combatant.role == 'rogue' && enemies.frontRow.count >= 2):
    if (combatant.cooldown['skill_rogue_mass_blind'] == 0):
      return 'skill_rogue_mass_blind'

  if (combatant.role == 'specialist' && !combatant.hasBuff('buff_evasion_up') && enemies.count(alive) >= 2):
    if (combatant.hp <= combatant.maxHp * 0.6 || roundState.roundIndex >= 2):
      if (combatant.cooldown['skill_specialist_adaptive_footwork'] == 0):
        return 'skill_specialist_adaptive_footwork'
  
  // 폴백: 기본 공격
  return basicAttack
```

이 결정 트리는 페이즈 4 #1 시뮬레이터 명세에서 정식 확정한다. 본 산출물은 자동 선택 정책의 형식과 우선순위만 명시한다.

## 8. 적 측 카탈로그 공유 정책 (§1.3 상세)

### 8.1 공유 가능 9 스킬

| 스킬 ID | 적 측 활용 예시 |
|--------|---------------|
| `skill_warrior_shield_bulwark` | 도적 두목, 갑옷 입은 엘리트, 늪지 거대 도마뱀 |
| `skill_warrior_battle_fury` | 광폭화 야수, 분노한 엘리트 (HP 50% 시 분노 단계) |
| `skill_rogue_mass_blind` | 도적단 우두머리, 안개 속 그림자 |
| `skill_ranger_marksman_focus` | 적 명사수 (snipers) |
| `skill_ranger_volley_shot` | 적 궁수 무리 (다인 사격) |
| `skill_mage_arcane_blast` | 적 흑마법사, 마탑 수호자 |
| `skill_mage_stun_bolt` | 적 마법사, 안개 속 위협 |
| `skill_support_aegis_aura` | 적 신관, 도적단 결속 보스 |
| `skill_specialist_adaptive_footwork` | 기민한 표식수, 함정꾼, 수비형 적 |

### 8.2 파티 전용 1 스킬

| 스킬 ID | 파티 전용 근거 |
|--------|------------|
| `skill_support_cleansing_word` | §1.3 서사적으로 적이 정화를 외치는 장면 부재 |

### 8.3 적 전용 후보 (페이즈 2 #2 신규 정의 예정)

본 카탈로그가 채우지 않는 적 측 스킬 후보 — 페이즈 2 #2에서 정의:

| 후보 ID | 의도 | 활용 |
|---------|------|------|
| `skill_enemy_bleeding_cut` | `dot_bleeding` 부여 | 도적 암살자, 독칼 사용자 |
| `skill_enemy_armor_break` | `debuff_defense_down` 부여 | 거대 망치 적, 갑옷 깨기 |
| `skill_enemy_poison_bite` | `dot_poisoned` 부여 (절대형 DoT) | 독뱀·독거미 |
| `skill_enemy_taunt_roar` | mez_taunted 등 신규 mez | 거대 야수, 보스 표적 강제 |
| `skill_enemy_summon` | 추가 전투원 소환 (페이즈 2 #2 결정) | 거미 우두머리, 마법사 |
| `skill_enemy_self_dispel` | 자기 디버프 해제 | 보스 정화 (cleansing_word 대응 적 측 표현) |

페이즈 2 #2에서 적별로 0~2 스킬을 §8.1 공유 풀 + §8.3 적 전용 풀에서 선택한다.

## 9. 보고서 라인 매칭 (페이즈 2 #4 입력)

페이즈 1 #1 §M8a 호환 §라운드 압축 정책과 페이즈 1 #4 §11 노출 정책에 정합한다.

### 9.1 스킬별 보고서 라인 후보 (요약)

| 스킬 | 진입(1줄) | 전개(2~3줄) | 위기(4~5줄) | 해소(6~7줄) | 후일담(8줄) |
|------|----------|------------|------------|------------|------------|
| `battle_fury` | — | "{m}이(가) 분노에 휩싸였다" | "{m}이(가) {enemy}에게 {N}의 피해 (강화)" | — | "{m}의 분노가 가라앉았다" |
| `mass_blind` | — | "{m}이(가) 적 전열에 연막을 던졌다. {N}명이 약화" | — | — | — |
| `marksman_focus` | — | "{m}이(가) 호흡을 멈추고 조준했다" | — | "{m}의 치명타! {N}의 피해" | — |
| `volley_shot` | — | "{m}의 3연사로 {N}의 피해" | — | "{m}의 마지막 사격이 {enemy}를 쓰러뜨렸다" | — |
| `arcane_blast` | — | "{m}의 마법이 {N}명을 휩쓸었다. 총 {합계}" | — | — | — |
| `stun_bolt` | — | — | "{m}의 마법이 {enemy}을(를) 기절시켰다" | — | "기절한 {enemy}이(가) 무기력하게 쓰러졌다" |
| `aegis_aura` | "{m}의 오라가 아군을 감쌌다" | — | — | — | — |
| `cleansing_word` | — | "{m}의 외침이 아군의 {효과}를 풀어냈다" | — | — | — |
| `shield_bulwark` | — | — | "{m}이(가) 방패로 받아냈다. 피해 {N}% 감소" | — | — |
| `adaptive_footwork` | — | "{m}이(가) 발밑을 고쳐 잡았다" | "{m}이(가) 아슬아슬하게 피해냈다" | — | — |

### 9.2 페이즈 2 #4 매트릭스화

스킬별로 보고서 라인 풀 N개 (예: 진입 2개, 전개 3개, 위기 2개) → 총 80~120 라인. 페이즈 3 #4 전투 로그 템플릿 120~180 라인의 일부를 채운다.

### 9.3 수치 노출 정책

페이즈 1 #4 §11 정책 그대로 — 피해/합계/지속 턴은 노출, applyChance/intensity %는 비노출. 본 산출물 권고 수치 표의 권고 수치 자체는 운영자 디버그 빌드에서만 노출.

## 10. 데이터 구조 (`CombatSkill` 모델 권장)

페이즈 4 #2 freezed/Hive 모델 확정의 입력. 컨텐츠 관점 최소 필드:

```text
CombatSkill
- id: String                          // snake_case (예: 'skill_warrior_battle_fury')
- role: String                        // {warrior, rogue, ranger, mage, support, specialist}
- partyOnly: bool                     // §1.3 — cleansing_word만 true
- triggerKind: TriggerKind            // {passive, active, triggered, on_hit, on_kill}
- triggerCondition: String?           // 예: 'self.hp <= maxHp * 0.5', 'first_in_round', 'enemies.alive >= 2'
- actionCost: ActionCost              // {action, extraAction, passive}
- cooldownRounds: int                 // 0~5 (passive는 -1 또는 미사용)
- maxUsesPerCombat: int?              // null=무제한 / battle_fury=1
- targetingKind: TargetingKind        // {self, single_enemy, single_ally, aoe_enemy, aoe_ally, party}
- targetingMaxCount: int?             // aoe N대상, null=전체
- targetingPriority: String?          // 'lowest_hp', 'highest_hp', 'front_row', 'random', 'has_debuff'
- multiHitCount: int?                 // volley_shot=3
- skillDamageMultiplier: double?      // §5.1 hook
- shieldBlockBonus: double?           // §4.3 hook (shield_bulwark)
- critRateBonus: double?              // §7 직접 표현 (marksman_focus)
- statusEffectId: String?             // 페이즈 1 #4 카탈로그 ID
- statusEffectApplyChance: double?    // 0.0~1.0
- statusEffectIntensity: double?      // 카탈로그 기본값 오버라이드 (옵션)
- statusEffectDurationTurns: int?     // 카탈로그 기본값 오버라이드 (옵션)
- dispelKind: DispelKind?             // {debuff, buff, dot} (cleansing_word=debuff+dot)
- dispelMaxCount: int?                // 1~N
- displayLabel: String                // 한국어 라벨 (예: '전투 분노')
- description: String                 // 보고서 보충 설명
```

### 10.1 권장 컬럼 (페이즈 3 #2 시드 데이터 입력)

페이즈 3 #2 `combat_skills` 신규 테이블 10행 시드.

| 컬럼 | 타입 | 비고 |
|------|------|------|
| `id` | TEXT PK | snake_case |
| `role` | TEXT (enum) | 6 직업군 |
| `party_only` | BOOL | DEFAULT false |
| `trigger_kind` | TEXT (enum) | passive/active/triggered/on_hit/on_kill |
| `trigger_condition` | TEXT NULL | DSL 또는 사전정의 키 |
| `action_cost` | TEXT (enum) | action/extraAction/passive |
| `cooldown_rounds` | INT | DEFAULT 0 |
| `max_uses_per_combat` | INT NULL | NULL=무제한 |
| `targeting_kind` | TEXT (enum) | 6 종 |
| `targeting_max_count` | INT NULL | |
| `targeting_priority` | TEXT NULL | |
| `multi_hit_count` | INT NULL | |
| `skill_damage_multiplier` | NUMERIC NULL | |
| `shield_block_bonus` | NUMERIC NULL | |
| `crit_rate_bonus` | NUMERIC NULL | |
| `status_effect_id` | TEXT NULL REFERENCES combat_status_effects(id) | |
| `status_effect_apply_chance` | NUMERIC NULL | |
| `status_effect_intensity` | NUMERIC NULL | |
| `status_effect_duration_turns` | INT NULL | |
| `dispel_kind` | TEXT NULL | |
| `dispel_max_count` | INT NULL | |
| `display_label` | TEXT | |
| `description` | TEXT | |

페이즈 4 #2가 freezed 모델 최종 형태를 확정한다. 본 산출물은 컬럼 풀과 enum 후보만 명시.

## 11. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| 페이즈 1 #1 4 페이즈 흐름 | Phase 3 행동 페이즈에 스킬 발동 hook 결합 | 변경 없음 |
| 페이즈 1 #2 행동 순서 / 다단 행동 / 진형 표적 | §6 콤보·§7 자동 선택에 직접 입력 | 변경 없음 |
| 페이즈 1 #3 8 hook 산식 | §4.1 6 hook 활성화 / 2 hook 미활성 | hook 자체는 변경 없음 |
| 페이즈 1 #4 10 상태 효과 | §4.3 6개 활성 / 4개 미활성 | 카탈로그 자체는 변경 없음 |
| `RoleSynergyMatrix` (의뢰 상성) | M8b 전투와 무관 — 의뢰 성공률용 | 영향 없음 |
| `Mercenary.role` | 스킬 자동 보유 결정 | 변경 없음 |
| `Mercenary.traitIds` | 스킬 자체와 직접 연결 없음 (트레잇은 회피·반격·선제 등 hook에만 결합) | 변경 없음 |
| `quest_pool.specialFlags` | M8b 매복 의뢰는 페이즈 1 #2 §2 정의 — 스킬 카탈로그와 무관 | 변경 없음 |
| `combat_status_effects` (페이즈 3 #3 신규) | 스킬에서 `status_effect_id` FK 참조 | 페이즈 3 #3 입력 |
| `combat_skills` (페이즈 3 #2 신규) | 본 산출물 10행 시드 | 페이즈 3 #2 입력 |
| `CombatSimulator` (페이즈 4 #1 신규) | §7 자동 발동 결정 트리 영속화 | 페이즈 4 #1 입력 |

## 12. 결정성 (페이즈 1 #1·#2·#3·#4 정책 정합)

페이즈 1 #1 §결정성 + 페이즈 1 #4 §10 시드 정책 그대로 적용. 본 산출물에 신규 PRNG 인스턴스 추가는 없다.

```text
스킬 자동 선택은 결정적 (Random 미사용 — 우선순위 결정 트리)
스킬 발동 후 효과 판정은 페이즈 1 #4 정책 그대로:

skillApplyRoll = Random(seed ^ stableSeed32('apply|$roundIndex|$casterId|$targetId|$skillId'))
```

페이즈 1 #4 §10 `applyRoll`을 그대로 사용. 별도 신규 PRNG 인스턴스 없음.

## 13. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | 10 스킬 카탈로그 ID·발동 조건·표적 분류 확정 | 페이즈 3 #2 데이터·페이즈 4 #2 모델의 입력 |
| 높음 | §1.2 자동 배정 정책 (mercenary.role → 스킬 0~2개) | 페이즈 4 #1 시뮬레이터 명세 |
| 높음 | §1.3 적 측 카탈로그 공유 정책 (9 공유 / 1 파티 전용) | 페이즈 2 #2 적 유형 설계 입력 |
| 높음 | §7 스킬 자동 선택 결정 트리 | 페이즈 4 #1 시뮬레이터 명세 |
| 높음 | §5 페이즈 1 #4 §1.5 미매핑 hook 직접 표현 패턴 | `marksman_focus` critRate +0.15 결합 |
| 중간 | §6 콤보 패턴 4종 사례 | 페이즈 2 #4 보고서 노출 정책 정합 |
| 중간 | §10 `CombatSkill` 데이터 구조 컬럼 풀 | 페이즈 4 #2 모델 입력 |
| 중간 | §9 스킬별 보고서 라인 풀 80~120 | 페이즈 3 #4 전투 로그 템플릿 입력 |
| 낮음 | 권고 수치 (cooldown, applyChance, intensity, multiplier) | 페이즈 2 #3에서 정밀 조정 |

## 14. data-generator 지시사항

페이즈 3 #2에서 `combat_skills` 신규 테이블에 본 카탈로그 10행을 생성한다.

- **대상 타입**: `combat-skill` (신규 타입 스펙 작성 필요 — `types/combat-skill.md`)
- **대상 테이블**: `combat_skills` (페이즈 4 #2 모델과 함께 정의)
- **생성 수량**: 10행 (본 산출물 §2 카탈로그)
- **외래 키 제약**: `status_effect_id` REFERENCES `combat_status_effects(id)` (페이즈 3 #3 데이터 의존). `role` ∈ {warrior, rogue, ranger, mage, support, specialist} (jobs 테이블 enum과 동일)
- **수치 출처**: 본 산출물 §2 권고 수치 표. 페이즈 2 #3에서 최종 검증
- **특수 요구**: §1.3 적 측 공유 가능 여부를 별도 컬럼 또는 메타에 보존하지 않음 — 페이즈 2 #2 적 유형 데이터에서 적별로 자유 참조

페이즈 3 #2 시작 시점에 (a) `types/combat-skill.md` 타입 스펙 우선 작성, 또는 (b) 본 산출물 §2 표를 입력으로 SQL/수동 데이터 생성 병행을 결정한다.

## 15. 페이즈 2 #2~#4 입력 요약

| 후속 산출물 | 본 산출물의 입력 기여 |
|-----------|---------------------|
| 페이즈 2 #2 적 유형 20~30개 | §1.3 + §8 공유 풀 9 스킬 + §8.3 적 전용 후보 5종 |
| 페이즈 2 #3 상태 효과 수치 확정 | §4.3 활용 매트릭스 + §2 권고 수치 (intensity/duration/applyChance) |
| 페이즈 2 #4 전투 로그 길이·수치 노출 기준 | §9 스킬별 보고서 라인 매칭 + §6 콤보 패턴 4종 + §9.3 수치 노출 정책 |
| 페이즈 3 #2 `combat_skills` 시드 | 본 산출물 §2 + §10 데이터 구조 |
| 페이즈 3 #4 전투 로그 템플릿 | §9.1 스킬별 라인 후보 풀 80~120개 |
| 페이즈 4 #1 `CombatSimulator` 명세 | §7 자동 선택 결정 트리 + §5 hook 직접 표현 API + §1.2 자동 배정 정책 |
| 페이즈 4 #2 `CombatSkill` freezed 모델 | §10 컬럼 풀 + enum 후보 |

## 16. 다음 단계

페이즈 2 #2 적 유형 능력치·행동 패턴 설계에서 본 산출물 §1.3 적 측 공유 풀 9 스킬과 §8.3 적 전용 후보 5종을 입력으로 20~30종 적의 스킬 슬롯 0~2개를 채운다.

페이즈 2 #3 상태 효과 수치 확정에서 본 산출물 §2 권고 수치(applyChance, intensity, durationTurns)를 페이즈 1 #4 카탈로그 10 타입의 기본값에 정밀 조정한다.

페이즈 2 #4 전투 로그 길이·수치 노출 기준 확정에서 §9 스킬별 라인 후보를 페이즈 3 #4 템플릿 120~180개의 매트릭스로 확장한다.
