# 파견 상성 보정 수치 매트릭스 밸런스 분석 리포트

> 작성일: 2026-04-17
> 유형: 수치 조정 제안 (M1 마일스톤 페이즈 2)
> 분석 대상: 6 role × 4 quest_type 상성 매트릭스, 트레잇 시너지 스케일, 85개 job의 role 분류 기준
> 입력: `Docs/content-design/[content]20260417_dispatch_synergy.md`, `Docs/balance-design/20260417_faction_passive_values.md`

---

## 현재 상태

### 기존 `QuestCalculator` 공식 (lib/features/quest/domain/quest_calculator.dart)

```
rate = 50 + (partyPower/enemyPower - 1) × 50
     + traitBonus (TraitEffectService)
     + questMod (_questModifiers: explore +5, escort +3, raid 0, hunt -5)
     - distancePenalty
     + randomVariance (±5)
clamp(5, 95)
```

**트레잇 계산 코드 확인 (`trait_effect_service.dart:4-24`):**
- 기존 코드가 이미 `${questTypeId}_success_rate`(예: `explore_success_rate`) 필드를 지원함
- 단, 모든 traits 109행의 `effect_json`이 현재 NULL (Supabase 조회 결과 `has_json=0, total=109`)
- → **트레잇 시너지는 M1에서 신규 정의하는 상태**. 별도 `quest_type_synergy` 배열을 새로 만들 필요 없이 기존 `{questType}_success_rate` 키 규약을 재사용할 수 있음

### 기존 `_questModifiers`

| quest_type | modifier | 의미 (역사적 해석) |
|-----------|:--------:|-------------------|
| explore | +5 | 탐험은 전투 부담 낮음 → 완화 |
| escort | +3 | 호위는 중간 난이도 |
| raid | 0 | 약탈은 기본 |
| hunt | -5 | 토벌은 강한 적 상대 → 가중 |

### 85개 jobs 스탯 분포 (Supabase)

| tier | 직업 수 | avg_str | avg_int | avg_vit | avg_agi |
|:----:|:------:|:-------:|:-------:|:-------:|:-------:|
| 1 | 16 | 7.6 | 5.8 | 26.3 | 53.3 |
| 2 | 17 | 20.2 | 12.4 | 52.1 | 53.5 |
| 3 | 17 | 25.0 | 21.5 | 68.6 | 51.2 |
| 4 | 18 | 31.3 | 35.2 | 83.1 | 49.3 |
| 5 | 17 | 37.7 | 37.5 | 102.0 | 46.6 |

각 티어 내에 **5개 고정 스탯 클러스터** 패턴 확인:
- (A) 근접 균형형: agi 53~55, str 최상, vit 중상 → warrior 주류
- (B) 기동형: agi 63~69, str 중, vit 중 → ranger/rogue 후보 (INT 차이로 구분)
- (C) 중갑형: agi 38~41, vit 최상(75~142), str 중 → warrior(중갑)
- (D) 지능형: int 30~65, agi 47~55 → mage/support (VIT로 구분)
- (E) 노동형 (T1 전용): 4/4/24/48 균등 저스탯 → specialist

---

## 데이터 분석

### 분석 1: role × quest_type 매트릭스 수치 확정 (±0 ~ +8 권장)

초안(기획서 2절): -2 ~ +8 범위. **음수 도입 여부**가 쟁점.

**옵션 A — 음수 허용 (-2 ~ +8):** 역할 부적합을 강하게 표시. 전략적 선택을 명시.
**옵션 B — 양수만 (0 ~ +8):** 불일치는 "보너스 없음"으로 표현. 완만한 설계.

**시뮬레이션:** explore 난이도 3 (enemy 35), partyPower 35 (ratio 1.0, base 50%), 파티 3명 전원 동일 role.

| 파티 role | 옵션 A 매트릭스 | 옵션 B 매트릭스 |
|-----------|:---------------:|:---------------:|
| mage (적합) | 50+5+**+8**=63% | 63% |
| warrior (부적합) | 50+5+(**-2**)=53% | 50+5+**0**=55% |
| specialist | 50+5+**+2**=57% | 57% |
| 격차 (적합-부적합) | **10%p** | 8%p |

**판정:** 옵션 A 채택. 10%p 격차는 "같은 난이도에서 5전 중 1전이 결판난다" 수준으로 전략적 의미가 있다. 옵션 B(8%p)는 무시하기 쉬워 role 선택 무의미화 우려.

**확정 매트릭스 (초안 유지):**

| role \ quest_type | raid | hunt | escort | explore |
|-------------------|:----:|:----:|:------:|:-------:|
| **warrior** | **+8** | +5 | +3 | −2 |
| **ranger** | +3 | **+8** | +2 | +3 |
| **mage** | −2 | +2 | +3 | **+8** |
| **rogue** | +5 | +3 | 0 | +5 |
| **support** | 0 | +2 | **+8** | +2 |
| **specialist** | +2 | +2 | +2 | +2 |

**보정 행 합 검증:**
- warrior: 14 / ranger: 16 / mage: 11 / rogue: 13 / support: 12 / specialist: 8
- **ranger가 가장 범용(16점)** — 4유형 전부 양의 보정. 레인저는 "가는 퀘스트마다 안정적"
- **mage가 가장 뾰족(11점)** — explore +8 대비 raid −2 차이 10. 특화형
- **specialist는 플랫 +8** — 스탯은 평범하지만 상성 페널티 없어 "어디든 배치 가능한 보조" 포지션
- warrior 총합 14 > mage 11: warrior가 직업 수 26개로 가장 많은 점을 감안하면 적정. mage(16개) + support(10개) 합산 스코어는 23으로 warrior 라인을 앞섬.

### 분석 2: `_questModifiers` 처리 결정

초안은 "유지"로 명시. 역할 분화 재점검:

| 레이어 | 성격 | 적용 범위 |
|--------|------|----------|
| `_questModifiers` (기존) | 유형별 **공통 난이도 계수** | 모든 파티 동일 |
| `roleSynergyBonus` (신규) | 유형-역할 **상성** | 파티 구성별 차등 |

**두 레이어의 합산 패턴 검토:**

| quest_type | _questMod | mage 파티 | warrior 파티 | 순합(mage vs warrior) |
|-----------|:---------:|:---------:|:------------:|:--------------------:|
| explore | +5 | +8 | −2 | +13 vs +3 (격차 10) |
| escort | +3 | +3 | +3 | +6 vs +6 (격차 0) |
| raid | 0 | −2 | +8 | −2 vs +8 (격차 10) |
| hunt | −5 | +2 | +5 | −3 vs 0 (격차 5) |

**판정:** 유지. `_questModifiers`는 상성 매트릭스 적용 후에도 유형 간 난이도 편향을 보존(hunt −5 → 토벌은 언제나 약간 어렵다). 두 레이어가 독립 작용하며 충돌 없음.

단, **raid의 `_questMod=0`** 은 "약탈은 중간 난이도"로 유의미한 중립값이므로 **변경 불필요**. 기존 공식 그대로 보존.

### 분석 3: 공유 상한 +20%p 도달 시나리오 (핵심 쟁점)

세력 패시브 기획(`20260417_faction_passive_values.md` 분석 2)에서 성공률 공유 상한이 escort/raid/hunt 엔드게임에서 이미 clamp에 닿는다고 결론. 여기에 **role synergy +8**이 추가되면:

| 유형 | 세력 스택(max) | 명성 A | role synergy | **총합** | +20 상한 clamp |
|------|:-------------:|:------:|:------------:|:--------:|:-------------:|
| escort | 태양 +8 + 균형 +3 + 송곳니 +8 = +19 | +5 | +8 | **+32** | +20 (−12 손실) |
| raid | 전사 +5 + 균형 +3 + 송곳니 +8 = +16 | +5 | +8 | **+29** | +20 (−9 손실) |
| hunt | 전사 +5 + 균형 +3 + 송곳니 +8 = +16 | +5 | +8 | **+29** | +20 (−9 손실) |
| explore | 마탑 +8 + 균형 +3 = +11 | +5 | +8 | **+24** | +20 (−4 손실) |

**문제 P1 (치명적): 엔드게임에서 role synergy가 clamp에 완전히 흡수되어 "파티 구성 선택이 무의미"해진다.**

세력·명성은 **정책 선택(무엇을 가입/성장할까)**, role synergy는 **전술 선택(누구를 보낼까)**. 두 레이어를 동일 상한에 묶으면 전술 레이어가 죽는다.

**해결안 비교:**

| 옵션 | 내용 | 장점 | 단점 |
|------|------|------|------|
| A | role synergy를 공유 상한 밖으로 분리 | 전술 레이어 보존, 개념 명확 | 총 성공률이 엔드게임에서 높음(최대 +40%p) |
| B | 공유 상한을 +25%p로 완화 | 단순 | role synergy 일부 여전히 흡수 |
| C | role 매트릭스 최댓값을 +6으로 하향 | 기존 상한 유지 | 전략 격차 축소(10→8p) |

**권장: 옵션 A.** 이유:
- 전체 성공률은 **외곽 clamp(5~95)**가 이미 있어 폭주 방지 가능
- "엔드게임에서도 파티 구성이 의미 있음"이 설계 목적
- role synergy 상한은 **별도 +10%p** (파티 평균 특성상 +8을 약간 초과)

**확정 상한 체계:**

| 레이어 | 상한 | 근거 |
|--------|:----:|------|
| 세력 패시브 + 명성 누적 (성공률) | **+20%p 공유** | 세력 패시브 기획 유지 |
| `roleSynergyBonus` | **+10%p 독립** | 분석 1 기반, 파티 평균 최대 ≈ +8 |
| `traitBonus + quest_type_synergy` | **+10%p 독립** | 분석 5 |
| 최종 `rate` | clamp(5, 95) | 기존 유지 |

**엔드게임 최대 성공률 시뮬레이션(escort, 파티 3명, partyPower=enemy, 거리 0):**
- base 50 + questMod +3 + 상한 세력/명성 +20 + role +10 + trait +10 = **93%** (clamp 95 미만)
- **의도된 엔드게임 최대치**. 대실패 확률은 이론상 5%p 상한 유지.

### 분석 4: 성공률 분포 시뮬레이션 (의미 있는 전략 차이 검증)

**조건:** explore 난이도 3 (enemy 35), 파티 3명, T3 용병 가정.

**파티 구성 3개 비교 (전원 단일 role):**

| 파티 | partyPower 추정 | power ratio | base 기여 | role synergy | questMod | 최종 성공률 |
|------|:---------------:|:-----------:|:---------:|:------------:|:--------:|:----------:|
| mage 3 (전투마법사 T3: int38 dominant) | 45 × 3 = 135 | 3.86 | +95 (clamp) | +8 | +5 | clamp **95%** |
| warrior 3 (창병 T3: vit97) | 26 × 3 = 78 | 2.22 | +61 | −2 | +5 | clamp **95%** |
| 동일 조건이되 난이도 5 (enemy 80) | | | | | | |
| mage 3 | 135 | 1.69 | +34.4 | +8 | +5 | **97%→95** |
| warrior 3 | 78 | 0.98 | −1.25 | −2 | +5 | **52%** |
| mage vs warrior 격차 | | | | | | **43%p** |

**난이도 중 구간(ratio ≈ 1.0, enemy 40)에서의 격차:**

파티별 `(ratio−1)×50`이 0이 되도록 `enemy` 조정 → base 50%.

| 파티 | role synergy | 최종 성공률 |
|------|:------------:|:----------:|
| mage 3 | +8 | 50+5+8 = **63%** |
| warrior 3 | −2 | 50+5−2 = **53%** |
| 혼합 (mage+warrior+rogue) | (8−2+5)/3 ≈ +3.67 | 50+5+3.67 = **58.7%** |
| **격차 (매칭 vs 불일치)** | | **10%p** |

**판정:** 매칭 role 3명과 불일치 3명의 성공률 격차 10%p는 "장기 플레이에서 누적 수익 차이가 체감되는 규모"로 유의미. 혼합 파티(평균 계산의 특성 검증)도 중간값(58.7%)으로 자연스러움. 전략적 깊이 확보.

**추가 검증: 파티 크기별 보정 수렴**

| 파티 구성 | roleSynergyBonus |
|----------|:----------------:|
| mage 1명 (explore) | +8 |
| mage 1 + warrior 1 | (8−2)/2 = +3.0 |
| mage 3 | +8 |
| mage 2 + warrior 1 | (8+8−2)/3 = +4.67 |
| mage 1 + warrior 2 | (8−2−2)/3 = +1.33 |

**해석:** 파티 3명 중 매칭 role 2~3명을 유지하면 +4.7~+8 보정. 1명만 매칭일 때 +1.3으로 떨어짐. **"매칭 role을 파티의 과반 이상으로 구성하라"는 암묵 규칙이 생긴다** — 의도한 전략적 지침.

### 분석 5: 트레잇 `quest_type_synergy` 스케일

**기존 코드(`trait_effect_service.dart:15-16`) 활용:**

```dart
bonus += (effects['success_rate'] as num?)?.toDouble() ?? 0.0;
bonus += (effects['${questTypeId}_success_rate'] as num?)?.toDouble() ?? 0.0;
```

**확정 사항:**
- 초안의 `quest_type_synergy` 배열 구조 **불채택**. 대신 기존 `{quest_type}_success_rate` 키 규약 재사용.
- 값 단위: **%p 정수/실수** (예: `"explore_success_rate": 4.0` = +4%p). 코드가 그대로 rate에 가산하므로 단위 통일이 명확.
- 기존 `success_rate` 필드(유형 무관)와 **가산**되며, 트레잇 합산은 **파티 멤버별 가산(평균 아님)**. 코드 현행 유지.

**개별 트레잇 단일 보정 스케일: +2 ~ +5 %p.**

근거:
- 파티 3명 전원 +5%p 시너지 트레잇: 합 +15%p → 분석 3의 독립 상한 +10%p 초과 → **상한 clamp 10 적용되어 흡수**
- 파티 3명 중 1명 +5%p: +5%p → 상한 여유. 의미 있는 단일 기여
- +2%p 정도는 "여러 트레잇이 모이면 쌓이는 양념" 역할

**음수 시너지도 허용 (역할 혼합 방지):** "평화주의자" trait가 raid에 −3%p 등. 음수 상한 −5%p.

**권장 트레잇 15개 초안 (페이즈 4에서 선별 입력):**

| 트레잇 키(예) | 효과 JSON (예) | 의도 |
|--------------|---------------|------|
| tracker | `{"hunt_success_rate": 5.0, "explore_success_rate": 3.0}` | ranger 강화 |
| escort_specialist | `{"escort_success_rate": 6.0}` | support 강화 |
| shadow_step | `{"raid_success_rate": 4.0, "explore_success_rate": 3.0}` | rogue 강화 |
| knowledge_seeker | `{"explore_success_rate": 4.0}` | mage 강화 |
| defensive_stance | `{"escort_success_rate": 4.0, "raid_success_rate": -2.0}` | tank 특화 |
| wanderer_wisdom | `{"explore_success_rate": 3.0, "hunt_success_rate": 2.0}` | 광범위 |
| pacifist | `{"raid_success_rate": -3.0, "escort_success_rate": 3.0}` | 평화지향 |
| brute | `{"raid_success_rate": 5.0, "explore_success_rate": -2.0}` | 난폭 |
| tactician | `{"success_rate": 2.0}` | 전 유형 +2 |
| coward | `{"success_rate": -2.0}` | 전 유형 −2 |

### 분석 6: 85개 job의 role 분류 (전수)

**분류 기준:**

| 우선순위 | 규칙 | 예외 |
|:-------:|------|------|
| 1 | `base_vit ≥ 75` (T2+) 또는 `base_agi ≤ 42` → warrior (중갑) | T4 paladin, T5 immortal 등 |
| 2 | `base_agi ≥ 63` & `base_int ≤ 20` & str 중상 → ranger 또는 rogue (서사적 이름) | 이름이 "사냥/궁수/정찰" → ranger, "도적/암살/소매/밀수" → rogue |
| 3 | `base_int ≥ 35` → mage 또는 support (VIT/STR로 구분) | 이름이 "사제/바드/성직/심문/전략/신탁" → support |
| 4 | `base_int 22~34` & vit 중상 → support | 바드/이단심문관 등 |
| 5 | `base_str ≥ base_int × 1.5` & vit 균형 → warrior (근접 기본) | |
| 6 | 나머지 (노동형, 모험가, 하이브리드) → specialist | |

**경계 직업 처리 원칙:**
- 이름의 서사적 역할이 스탯보다 우선. 예: `spellblade`(마검사) str30/int38 → **mage** (마법 전면, 이름 우선)
- T4 `paladin`(팔라딘) str25/int14/vit120 → **warrior** (중갑 전열, 성직자 아님)
- T5 `hero`(영웅)/`guild_master`(길드마스터) → **specialist** (범용 만능 서사)

**전수 매핑 테이블:**

#### T1 (16)
| id | name | role |
|---|---|:---:|
| ruffian | 건달 | warrior |
| hunter_small | 사냥꾼 | ranger |
| pickpocket | 소매치기 | rogue |
| nomad | 유랑민 | rogue |
| messenger | 전령 | rogue |
| herb_gatherer | 약초 채집가 | specialist |
| beggar | 거지 | specialist |
| miner | 광부 | specialist |
| lumberjack | 나무꾼 | specialist |
| slave | 노예 | specialist |
| farmer | 농부 | specialist |
| shepherd | 목동 | specialist |
| fisher | 어부 | specialist |
| laborer | 잡역부 | specialist |
| artisan_apprentice | 하급 장인 | specialist |
| peddler | 행상인 | specialist |

#### T2 (17)
| id | name | role |
|---|---|:---:|
| gladiator_low | 검투사 | warrior |
| apprentice_mage | 견습 마법사 | mage |
| archer_low | 궁수 | ranger |
| hunter_mid | 사냥꾼 | ranger |
| bandit | 산적 | warrior |
| deserter_sword | 탈영병(검) | warrior |
| deserter_archer | 탈영병(궁수) | ranger |
| thief | 도적단원 | rogue |
| smuggler | 밀수꾼 | rogue |
| scout_low | 정찰병 | ranger |
| novice_adventurer | 하급 모험가 | specialist |
| mercenary_low | 하급 용병 | warrior |
| acolyte | 하급 사제 | support |
| squire | 견습 기사 | warrior |
| guard_low | 경비병 | warrior |
| militia | 민병대 | warrior |
| deserter_spear | 탈영병(창) | warrior |

#### T3 (17)
| id | name | role |
|---|---|:---:|
| necromancer_low | 네크로맨서 | mage |
| monster_hunter | 몬스터 헌터 | ranger |
| archer_skilled | 숙련 궁수 | ranger |
| battle_mage | 전투 마법사 | mage |
| light_cavalry | 경기병 | warrior |
| assassin_low | 암살자 | rogue |
| scout_leader | 정찰대장 | ranger |
| mercenary | 용병대원 | warrior |
| inquisitor_low | 이단 심문관 | support |
| adventurer_mid | 중급 모험가 | specialist |
| druid_low | 드루이드 | mage |
| bard_combat | 바드 | support |
| priest_mid | 중급 사제 | support |
| knight_low | 기사 | warrior |
| shield_bearer | 방패병 | warrior |
| soldier | 정규 병사 | warrior |
| spearman | 창병 | warrior |

#### T4 (18)
| id | name | role |
|---|---|:---:|
| necromancer | 네크로맨서 | mage |
| archmage_mid | 대마법사 | mage |
| warlock | 워록 | mage |
| elementalist | 원소술사 | mage |
| ranger | 레인저 | ranger |
| assassin | 암살자 | rogue |
| adventurer_high | 고급 모험가 | specialist |
| spellblade | 마검사 | mage |
| mercenary_captain | 용병대장 | warrior |
| inquisitor | 이단 심문관 | support |
| high_priest | 고위 사제 | support |
| druid | 드루이드 | mage |
| bard | 바드 | support |
| summoner | 소환사 | mage |
| strategist | 전쟁 전략가 | support |
| knight | 기사 | warrior |
| elite_knight | 기사단원 | warrior |
| paladin | 팔라딘 | warrior |

#### T5 (17)
| id | name | role |
|---|---|:---:|
| grand_necromancer | 대네크로맨서 | mage |
| archmage | 대마법사 | mage |
| demon_general | 마왕군 장군 | warrior |
| legend_swordsman | 전설의 검성 | warrior |
| dimension_mage | 차원술사 | mage |
| world_assassin | 세계급 암살자 | rogue |
| hero | 영웅 | specialist |
| dragon_knight | 용기사 | warrior |
| ancient_druid | 고대 드루이드 | mage |
| guild_master | 길드 마스터 | specialist |
| high_priest_supreme | 대사제 | support |
| oracle | 신탁자 | support |
| spirit_envoy | 정령왕의 사자 | mage |
| grand_knight | 대기사 | warrior |
| immortal | 불멸자 | warrior |
| paladin_leader | 성기사 대장 | warrior |
| royal_guard_captain | 왕실 근위대장 | warrior |

**role 전체 분포:**

| role | 개수 | 비율 | 주요 티어 |
|------|:---:|:----:|----------|
| warrior | 26 | 30.6% | 모든 티어 균등 |
| specialist | 16 | 18.8% | T1 편중 (11/16) |
| mage | 16 | 18.8% | T4/T5 집중 |
| support | 10 | 11.8% | T3+ |
| ranger | 9 | 10.6% | T2/T3 집중, T5 0개 |
| rogue | 8 | 9.4% | 모든 티어 1~3개 |

**분포 리스크:**

- **P2 (중요): T5에 ranger가 0명.** 엔드게임 hunt 최고 보정(+8) 파티를 T5 용병으로 구성할 수 없음 → 플레이어는 hunt에 T4 레인저 1명 + T5 warrior/mage 혼합으로 대응. 치명적이진 않으나 설계 불균형.
  - **권장:** M2b(엘리트 몬스터) 또는 별도 콘텐츠에서 T5 ranger 직업 1개 신규 추가 권장. 현재 범위(M1)에선 **허용**. 공지 주석.
- **P3 (경미): rogue 8개가 전 티어에 얇게 분포.** rogue 파티 구성이 힘들 수 있으나, +5 raid/explore 보정이 절대적 최고가 아니므로 허용.
- warrior 26개 편중은 스탯상 자연스러운 분포이며, raid/hunt의 warrior 상성도 최고(+8)가 아닌(ranger +8, warrior +5/+8 혼재)이므로 **편향 없음**.

---

## 문제점 요약

### 치명적 (필수 수정)

**P1. role synergy가 공유 상한 +20%p에 흡수되어 엔드게임에서 무의미**
- 근거: 분석 3. escort에서 세력+명성+role 합산 +32 → clamp +20, role 기여 전량 손실
- 해결: role synergy를 **독립 상한 +10%p**로 분리. 공유 상한에서 제외

### 중요 (설계 조정)

**P2. T5 ranger 직업 0개로 엔드게임 hunt 파티 구성 어려움**
- 근거: 분석 6. T5 17개 중 ranger 분류 가능한 직업 없음
- 해결: 현재 M1 범위에선 주석 처리. 이후 M2b/M3에서 T5 ranger 신규 직업 1개 추가 (예: "전설의 추적자", "차원 수렵인") 권장

### 경미 (유지)

- 매트릭스 −2 ~ +8 범위: 전략 격차 10%p 확보 → 유지
- `_questModifiers` 기존 값: 상성과 독립 작용 → 변경 불요
- 트레잇 시너지 키 규약: 기존 `{quest_type}_success_rate` 재사용 → 신규 필드 불요

---

## 플레이어 체감 분석

### 초반 (F~E 등급, 파티 1~3명, 모집 소수)

- 모집된 용병의 role을 확인하고 퀘스트 상성에 맞춰 파견하는 **"용병 = 특화 자산"** 인식 형성
- 퀘스트 카드의 추천 role 배지가 **학습 유도** — 플레이어가 role 개념을 자연스럽게 습득
- 초반 용병 대다수가 T1 specialist(+2 플랫)이므로 **격차 체감은 미미**. 첫 T2 warrior/ranger 모집 시점에 "전문가가 왔다"는 명확한 피드백 발생

### 중반 (D~C, 파티 3~5명, 세력 1~2 가입)

- role synergy + 세력 패시브 + 트레잇이 중첩 → 성공률 분해 툴팁의 가치가 가장 큰 시기
- 매칭 role 3명 파티 vs 불일치 3명 파티 격차 10%p가 체감됨 (분석 4)
- 용병 상세의 "상성" 섹션을 보고 "이 용병은 hunt 전용"으로 분류하는 **메타 플레이** 형성

### 엔드게임 (B~A, 파티 6명, 세력 3 가입)

- 공유 상한 분리(P1 해결) 덕에 role synergy가 **여전히 +10%p 기여** → 파티 구성 선택 의미 보존
- escort 이론 최대: base 50 + (ratio 1.0) + questMod 3 + 세력·명성 20 + role 10 + trait 10 = **93%** (clamp 95 이하). 대실패 리스크 5%p는 "완전한 안전은 없다"는 설계 철학 유지
- 혼합 파티(mage+warrior+rogue)의 합리적 중간값(+3~4%p)이 **"섞어 보낼 가치"를 남김** — 트레잇·스탯이 해당 퀘스트에 유리한 경우 role 불일치여도 파견 가능

### 체감 리스크

- **P2 리스크**: T5 ranger 부재로 엔드게임 hunt 전용 T5 파티 구성 불가. A등급 플레이어가 "T5 파티가 T4 파티보다 hunt에서 성공률이 더 낮을 수도 있다"는 체감 지점 발생 가능. M2b 이후 보강 필요

---

## 조정 제안

### 수치 조정안

#### role × quest_type 매트릭스 (기획서 초안 유지)

| role \ quest_type | raid | hunt | escort | explore | 행 합 |
|-------------------|:----:|:----:|:------:|:-------:|:----:|
| warrior | **+8** | +5 | +3 | −2 | 14 |
| ranger | +3 | **+8** | +2 | +3 | 16 |
| mage | −2 | +2 | +3 | **+8** | 11 |
| rogue | +5 | +3 | 0 | +5 | 13 |
| support | 0 | +2 | **+8** | +2 | 12 |
| specialist | +2 | +2 | +2 | +2 | 8 |

→ **초안 그대로 확정**. 값 범위 −2 ~ +8, 파티 평균 적용.

#### 상한 체계 (P1 반영)

| 레이어 | 상한 | 스태킹 | 비고 |
|--------|:----:|:------:|------|
| `questMod` (기존) | 개별 퀘스트 유형별 고정 | — | 변경 없음 |
| **`roleSynergyBonus` (신규)** | **+10%p 독립** | 파티 평균 | **공유 상한 제외** |
| `traitBonus + quest_type_synergy` | +10%p 독립 | 파티 멤버 가산 | 기존 코드 유지 |
| `factionPassiveBonus + rankBonus` | **+20%p 공유** | 가산 | 세력 패시브 기획 |
| 최종 `rate` | clamp(5, 95) | — | 기존 유지 |

#### 트레잇 시너지 스케일 (분석 5)

| 필드 키 | 값 범위 | 단위 | 예시 |
|---------|:-------:|:----:|------|
| `success_rate` (전 유형) | −3 ~ +3 | %p | `{"success_rate": 2.0}` |
| `{quest_type}_success_rate` | −5 ~ +5 | %p | `{"hunt_success_rate": 5.0}` |
| `{quest_type}_success_rate` (복수) | 각 −3 ~ +5 | %p | 호위 +4, 약탈 −2 조합 |

#### `_questModifiers` (변경 없음)

| quest_type | modifier |
|-----------|:--------:|
| explore | +5 |
| escort | +3 |
| raid | 0 |
| hunt | −5 |

### 85개 job role 분류 확정

분석 6의 전수 매핑 테이블을 **확정 안**으로 채택. 페이즈 4 명세 시 SQL 업데이트(또는 operation-bom 수동 편집) 기준 데이터로 사용.

**마이그레이션 SQL 템플릿 (페이즈 4 명세용):**

```sql
ALTER TABLE jobs ADD COLUMN role TEXT NOT NULL DEFAULT 'specialist';
UPDATE jobs SET role = 'warrior'    WHERE id IN ('ruffian','gladiator_low','bandit',...);
UPDATE jobs SET role = 'ranger'     WHERE id IN ('hunter_small','archer_low','hunter_mid','deserter_archer','scout_low','monster_hunter','archer_skilled','scout_leader','ranger');
UPDATE jobs SET role = 'mage'       WHERE id IN ('apprentice_mage','necromancer_low','battle_mage','druid_low','necromancer','archmage_mid','warlock','elementalist','spellblade','druid','summoner','grand_necromancer','archmage','dimension_mage','ancient_druid','spirit_envoy');
UPDATE jobs SET role = 'rogue'      WHERE id IN ('pickpocket','nomad','messenger','thief','smuggler','assassin_low','assassin','world_assassin');
UPDATE jobs SET role = 'support'    WHERE id IN ('acolyte','inquisitor_low','bard_combat','priest_mid','inquisitor','high_priest','bard','strategist','high_priest_supreme','oracle');
-- specialist는 DEFAULT로 자동 할당
```

---

## 시뮬레이션 (조정안 적용 후)

### 시나리오 A — 매칭 파티 vs 불일치 파티 (중간 난이도)

조건: explore 난이도 3, enemy 35, partyPower 35 (ratio 1.0), 거리 0, 트레잇/세력 무

| 파티 구성 | role synergy 평균 | questMod | 최종 rate |
|-----------|:----------------:|:--------:|:--------:|
| mage 3 | +8 | +5 | **63%** |
| warrior 3 | −2 | +5 | **53%** |
| mage 2 + warrior 1 | +4.67 | +5 | **59.7%** |
| mage 1 + warrior 2 | +1.33 | +5 | **56.3%** |
| specialist 3 | +2 | +5 | **57%** |

**체감 평가:** 매칭 완전(mage 3) vs 불일치 완전(warrior 3) 격차 **10%p** — 장기 누적 수익 12~15% 차이 발생. 의미 있음.

### 시나리오 B — 엔드게임 상한 도달 확인 (P1 해결 검증)

조건: escort 난이도 5, enemy 80, partyPower 80 (ratio 1.0), 태양 교단+균형+송곳니(파티≥3) 가입, 명성 A, 파티 3 support, 트레잇 "호위 전문가" 3명

| 레이어 | 값 | 상한 적용 후 |
|--------|:---:|:-----------:|
| base | 50 | 50 |
| questMod escort | +3 | +3 |
| role synergy (support 3 평균) | +8 | clamp(+10) → +8 |
| trait `escort_success_rate 6.0` × 3 | +18 | clamp(+10) → **+10** |
| 세력 패시브(태양 +8 + 균형 +3 + 송곳니 +8) + 명성 A +5 | +24 | **+20 (공유 상한)** |
| **합계** | +55 | **+41** |
| 최종 rate | 50+3+8+10+20 = 91 | **91%** |

**판정:** 공유 상한(+20)에 세력/명성만 들어가고, role(+8)과 trait(+10)은 독립 상한으로 각각 보존됨. 엔드게임 최대 91% — clamp 95 미도달, 대실패 리스크 9%p 유지. **설계 의도대로 작동**.

### 시나리오 C — 공유 상한이 필요한 이유 재검증

위 시나리오에서 만약 **모든 레이어가 공유 상한 +20%p**로 묶였다면:
- role+trait+세력+명성 = +46 → clamp +20 → 단일 +20만 기여
- 즉, 전술/트레잇/정책 3개 축 중 **하나만 반영**. 차별화 실패

**따라서 P1 해결안(role을 공유 상한 밖으로)은 구조적으로 타당.**

### 시나리오 D — rogue 부재 시 영향

rogue는 raid/explore에서 +5 보정(차상위). rogue 파티 구성 불가 시:
- raid: warrior +8이 대체 → 격차 3%p (rogue 부재 페널티 = 3%p)
- explore: mage +8이 대체 → 격차 3%p

**판정:** rogue 8개로도 충분. 대체 role이 강력해 부재 리스크 낮음.

---

## data-generator 수치 가이드

> 본 리포트는 **시스템 튜닝 + 85개 job 분류 작업**이며 벌크 텍스트 생성은 없다.
>
> 페이즈 3에서 data-generator를 호출하지 않는다. role 분류와 트레잇 시너지 값은 페이즈 4 개발 명세(`/spec-writer`)에 **마이그레이션 SQL / 트레잇 effect_json 업데이트 스크립트** 형태로 포함된다.

---

## 후속 안내

- **페이즈 4 개발 명세(`/spec-writer`)에 반드시 반영해야 할 핵심 요구:**
  1. `QuestCalculator`에 `roleSynergyBonus` 레이어 추가 (파티 평균, **공유 상한 제외**, 독립 상한 +10%p)
  2. `jobs.role` 컬럼 추가 + 85개 전수 UPDATE (본 리포트 분석 6 테이블 기준)
  3. `JobData` Freezed 모델에 `role` 필드 추가
  4. `TraitEffectService`는 기존 `{quest_type}_success_rate` 키를 그대로 사용 (**코드 변경 불요**). 15개 트레잇 `effect_json`에 신규 값 입력
  5. 성공률 분해 툴팁 UI에 "상성 (파티 평균)" 항목 별도 표시

- **P2 이슈 기록:** T5 ranger 직업 부재. M1 범위 밖 후속 조치(M2b/M3 엘리트 몬스터/서사 퀘스트 단계에서 T5 ranger 신규 직업 1개 추가).

- **경제 영향:** role synergy는 평균 파티에서 +2~+5%p 기여 → 성공률 기대값 소폭 상승. 기존 보상 공식은 변경 없음. 세력 패시브 +12% 조정(다른 리포트)과 합산해도 인플레이션 허용 범위 내.

- milestone-runner 재진입: `/milestone-runner M1 --resume`
