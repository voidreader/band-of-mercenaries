# 칭호 효과 수치 밸런스 분석 리포트

> 작성일: 2026-05-13
> 유형: 수치 조정 제안 + 풀스택 시너지 검증
> 분석 대상: M6 페이즈 1 #2 산출물의 11종 칭호 effect_json (권장값) + 행동 지표 hook 임계값

---

## 개요

M6 페이즈 1 #2(`[content]20260512_titles-and-flagship.md`)에서 권장된 11종 칭호의 effect_json 수치를 Supabase 실데이터(트레잇 109행·세력 14행·quest_types 6행)와 PassiveBonusService 누적 정책을 기준으로 검증한다. 두 가지 검증 축:

1. **수치 강도 정합** — 칭호 단독 빌드가 "필수 최적해"가 되지 않으면서, 트레잇·세력·랭크 패시브와 풀스택 누적 시 클램프 안전 통과.
2. **행동 지표 hook 임계 적절성** — roadmap "3~5시간 안 1명 이상 칭호 기억"과 정합하는 발급 페이스.

본 리포트의 핵심 결정:
- **11종 effect_json 권장값 9종 그대로 채택 / 2종 수치 미세 조정** (광역 questRewardMultiplier 0.03 → 0.02, 광역 questSuccessRateBonus 0.03 → 0.025)
- **행동 지표 임계 4종 모두 하향 조정** — raid 30→20 / dispatch 100→80 / explore 20→15 / escort 15→12
- **풀스택 시너지 안전 검증 ✓** — PassiveBonusService 클램프 모두 통과, 칭호 단독 빌드 power 트레잇 빌드 미달
- **#11 혼을 끊은 자 복합 효과 그대로 채택** — 엔드게임 격 정합

---

## 현재 상태

### 1.1 페이즈 1 #2 §3.1 권장 effect_json (11종)

| # | 칭호 ID | name | effect_json (권장) |
|---|---------|------|-------------------|
| 1 | `title_village_savior` | 마을의 은인 | `questSuccessRateBonus(quest_type:'all', value:+0.03)` |
| 2 | `title_pyegwang_survivor` | 폐광의 생존자 | `recoveryTimeReduction(status:'injured', value:-0.10)` |
| 3 | `title_first_banner` | 첫 깃발을 든 자 | `reputationGainModifier(value:+0.02)` |
| 4 | `title_road_hunter` | 도적길 추적자 | `questSuccessRateBonus(quest_type:'raid', value:+0.05)` |
| 5 | `title_veteran` | 백전노장 | `injuryRateModifier(value:-0.03)` |
| 6 | `title_scout_eye` | 정찰의 눈 | `investigationSuccessRateBonus(value:+0.05)` |
| 7 | `title_escort_master` | 호위의 노련함 | `questSuccessRateBonus(quest_type:'escort', value:+0.05)` |
| 8 | `title_dustvile_friend` | 더스트빌의 친우 | `questRewardMultiplier(quest_type:'all', value:+0.03)` |
| 9 | `title_monster_hunter` | 괴물 사냥꾼 | `questSuccessRateBonus(quest_type:'hunt', value:+0.05)` |
| 10 | `title_renowned` | 이름을 알린 자 | `reputationGainModifier(value:+0.03)` |
| 11 | `title_soul_severer` | 혼을 끊은 자 | `reputationGainModifier(value:+0.05) + mercenaryXpBonus(value:+0.10)` |

### 1.2 페이즈 1 #2 §3.1 권장 행동 지표 hook 임계

| 칭호 | stat_key | threshold (권장) |
|------|----------|----------------|
| 도적길 추적자 | `raid_count` | **30** |
| 백전노장 | `total_dispatch_count` | **100** |
| 정찰의 눈 | `explore_count` | **20** |
| 호위의 노련함 | `escort_count` | **15** |

### 1.3 PassiveBonusService 누적 정책 (실측 코드)

```dart
// 곱셈 계열 (회복 시간·시설 비용·모집 비용)
return (1.0 - sum).clamp(0.10, 1.0);  // 하한 0.10 보장

// 부상률
return (1.0 + sum).clamp(0.10, 1.0);  // sum 음수 → 1.0 미만
```

- **곱셈 계열 클램프 하한 = 0.10**: Σ value가 0.90을 넘어가도 결과는 0.10 (90% 감소). 안전망.
- 가산 계열 (reputationGainModifier 등): 상한 +0.30 별도 지정.
- 트레잇 effect_json은 **정수%(1~6)** 표현. PassiveEffect와 별도 시스템(TraitEffectService). **누적 풀에 합쳐지지 않음**. 충돌 위험 없음.

---

## 데이터 분석

### 2.1 세력 14개 passive_bonus_json 강도 분포 (실데이터)

Supabase factions 14개 행 분석 결과, 핵심 PassiveEffect 타입별 강도:

| PassiveEffect 타입 | 세력 등장 횟수 | 강도 범위 | 칭호 권장값 |
|------------------|--------------|----------|------------|
| `quest_reward_multiplier` | 3회 (모험가/상인/화산) | **0.12~0.15** | 칭호 #8: 0.03 |
| `quest_success_rate_bonus` | 6회 (마탑/태양/전사×2/균형/...) | **0.03~0.08** | 칭호 #1·#4·#7·#9: 0.03~0.05 |
| `quest_success_rate_bonus_party_size` | 1회 (송곳니) | 0.08 | 칭호 미사용 |
| `recovery_time_reduction` | 2회 (태양/뿌리) | 0.15 | 칭호 #2: -0.10 |
| `trait_acquisition_condition_relief` | 1회 (마탑) | 0.10 | 칭호 미사용 |
| `trait_evolution_condition_relief` | 1회 (금지) | 0.15 | 칭호 미사용 |
| `idle_reward_bonus` | 1회 (상인) | 0.10 | 칭호 미사용 |
| `investigation_success_rate_bonus` | 1회 (도둑) | 0.05 | 칭호 #6: +0.05 (동일) |
| `travel_event_mitigation` | 2회 (도둑/뿌리) | 0.30~0.40 | 칭호 미사용 |
| `recruitment_tier_boost` | 1회 (혈계) | 0.04 (T4~T5) | 칭호 미사용 |
| `facility_cost_reduction` | 2회 (심층/황혼) | 0.10~0.20 | 칭호 미사용 |
| `facility_effect_bonus` | 1회 (황혼) | 0.05 | 칭호 미사용 |

**칭호 권장값 위치 평가**:
- 칭호 questSuccessRateBonus 0.03~0.05 → 세력 최약 동급(균형 0.03) ~ 세력 중간(전사 0.05). **약~중간 강도**.
- 칭호 questRewardMultiplier 0.03 → 세력 0.12의 **1/4 수준**. **매우 약함**.
- 칭호 recoveryTimeReduction 0.10 → 세력 0.15의 **2/3 수준**. **약~중간**.
- 칭호 investigationSuccessRateBonus 0.05 → 세력과 **동급**. 단, 칭호는 용병 1명 효과, 세력은 전체.
- 칭호 reputationGainModifier 0.02~0.05 → 세력에 동급 효과 없음 (대신 랭크 패시브에 등장 추정).

→ **칭호는 세력보다 약하거나 동급**. 단일 빌드 결정력 부족 — "필수 최적해 안 됨" 정책 정합.

### 2.2 트레잇 effect_json 분포 (실데이터)

acquired/evolved 트레잇 30개 샘플 분석:

| 트레잇 키 | type | effect_json |
|----------|------|-------------|
| charger | acquired | `{raid_success_rate: 5, explore_success_rate: -2}` |
| guardian | acquired | `{escort_success_rate: 6}` |
| iron_guard | acquired | `{raid_success_rate: -2, escort_success_rate: 4}` |
| scout | acquired | `{hunt_success_rate: 3, explore_success_rate: 3}` |
| tactician | acquired | `{success_rate: 2}` |
| hero | evolved | `{success_rate: 3, raid_success_rate: 2}` |
| focused | evolved | `{success_rate: 3}` |
| shadow | evolved | `{raid_success_rate: 4, explore_success_rate: 3}` |
| treasure_hunter | evolved | `{explore_success_rate: 5}` |

**관찰**:
- 트레잇 effect는 **정수% 키-값 쌍**. PassiveEffect와 형식·시스템 다름.
- 단일 트레잇 효과 강도: success_rate **2~6%p** (charger raid 5, guardian escort 6).
- evolved 트레잇이 acquired보다 강도 비슷 또는 살짝 위 (success_rate +3 vs +2 등).
- 트레잇은 한 용병 7슬롯(선천 3 + 후천 4) → **최대 누적 trait power ≈ 25%p success_rate**(여러 quest_type 합산 시).

**칭호 vs 트레잇 비교**:
- 트레잇 단일 효과: raid_success_rate **+5%** (charger)
- 칭호 단일 효과: raid_success_rate **+0.05** = **+5%p** (도적길 추적자)
- → **동급 강도**. 하지만 트레잇은 모집·행동으로 7슬롯 누구나, 칭호는 1~2개만 자연 보유.
- 풀스택 칭호 11종 모두 한 용병 보유 가정 시: success_rate +0.13(raid 의뢰 한정, all 0.03 + raid 0.05 + 기타 가산) = **+13%p**. 트레잇 풀 보유와 동급.

→ **칭호 풀스택 ≤ 트레잇 풀스택**. 최적해 고착 위험 없음.

### 2.3 행동 지표 hook 임계 — 신규 유저 페이스 모델링

**가정** (M5 페이즈 2 시뮬레이션 + content_status.md 기반):
- 시간당 평균 파견 수: **8회** (의뢰 5~8개 동시 + 30분 평균 소요)
- quest_type 균등 분포 가정: raid 25% / hunt 25% / escort 25% / explore 25% (1.0 의뢰 풀 가정)
- 신규 유저 누적 플레이 시간: 1h / 3h / 5h / 10h / 20h

**시간당 quest_type별 평균 파견 수** (= 8 × 0.25 = 2회/h):

| 누적 플레이 | raid_count | hunt_count | escort_count | explore_count | total_dispatch_count |
|-----------|-----------|-----------|-------------|---------------|--------------------|
| 1h | 2 | 2 | 2 | 2 | 8 |
| 3h | 6 | 6 | 6 | 6 | 24 |
| 5h | 10 | 10 | 10 | 10 | 40 |
| 10h | 20 | 20 | 20 | 20 | 80 |
| 15h | 30 | 30 | 30 | 30 | 120 |
| 20h | 40 | 40 | 40 | 40 | 160 |

**현재 권장 임계로 칭호 발급 도달 시점**:

| 칭호 | 임계 | 도달 시점 (8회/h 가정) | roadmap 3~5h 정합? |
|------|------|----------------------|-------------------|
| 도적길 추적자 (raid 30) | 30 | **15h** | ❌ 너무 늦음 |
| 백전노장 (total 100) | 100 | **12.5h** | ❌ 너무 늦음 |
| 정찰의 눈 (explore 20) | 20 | **10h** | △ |
| 호위의 노련함 (escort 15) | 15 | **7.5h** | △ 5h 직후 |

**문제점**: 4종 모두 5h 이내 도달 불가. roadmap "신규 유저 3~5시간 안 1명 이상 칭호 기억"은 위업 기반 칭호(예: 마을의 은인 = 거점 사건 완주 시 2h 시점에 자연 발급)로 충족 가능하지만, 행동 지표 칭호 자체로는 페이스가 느림.

**조정 권장**:

| 칭호 | 권장 임계 | 도달 시점 | 평가 |
|------|----------|---------|------|
| 도적길 추적자 (raid) | **20** | 10h | ✓ M6 후반 도달 자연 |
| 백전노장 (total) | **80** | 10h | ✓ M6 후반 도달 자연 |
| 정찰의 눈 (explore) | **15** | 7.5h | ✓ 5~8h 자연 도달 |
| 호위의 노련함 (escort) | **12** | 6h | ✓ 5h 직후 도달 |

→ **5~10시간 누적 플레이 구간에 4종 모두 자연 도달**. 무게감 보존 + 페이스 정합.

**대안 검토**: 더 낮추기 (raid 15 / total 50 등)? — 너무 빨라 무게감 희석. 거부.

### 2.4 풀스택 시너지 검증

**가정**: 한 용병이 칭호 11종 + 트레잇 7개 + 가입 세력 3개 + 랭크 A 모두 적용. raid 의뢰 수행 시.

#### 가산 그룹 — questSuccessRateBonus

| 출처 | 효과 | quest_type 매칭 |
|------|------|---------------|
| 칭호 #1 마을의 은인 | +0.03 | all (raid 의뢰 적용) |
| 칭호 #4 도적길 추적자 | +0.05 | raid |
| 칭호 #11 혼을 끊은 자 | 0 | 미보유 (rep/XP만) |
| 세력 전사 길드 | +0.05 | raid |
| 세력 균형 감시자 | +0.03 | all (중복 가입 시) |
| 트레잇 charger | +5%p | raid (정수% — 별도 시스템) |

칭호 + 세력 합계: 0.03 + 0.05 + 0.05 + 0.03 = **+0.16 = +16%p**

QuestCalculator 성공률 5~95% clamp 안전 통과. 베이스 70% 성공률이면 최종 86% — **자연 강력함, 하지만 over-power 아님**.

#### 가산 그룹 — reputationGainModifier

| 출처 | 효과 |
|------|------|
| 칭호 #3 첫 깃발 | +0.02 |
| 칭호 #10 이름을 알린 자 | +0.03 |
| 칭호 #11 혼을 끊은 자 | +0.05 |
| **칭호 소계** | **+0.10** |

상한 +0.30 통과 ✓. 세력/랭크에 reputation 효과 없음(검증). **칭호 단독으로 +10% 명성** — 적절.

#### 곱셈 그룹 — recoveryTimeReduction(injured)

| 출처 | Σ value |
|------|---------|
| 칭호 #2 폐광의 생존자 | 0.10 |
| 세력 태양 교단 | 0.15 |
| 세력 뿌리의 맹세단 | 0.15 |
| **Σ** | **0.40** |

계산: `(1 - 0.40).clamp(0.10, 1.0)` = **0.60** (40% 감소, 클램프 적용 안 함). ✓ 안전.

극단: 트레잇·아이템 효과 추가로 Σ=0.95 가정 시 → `(1 - 0.95).clamp(0.10, 1.0)` = 0.10 (90% 감소). 클램프 보호. ✓

#### 곱셈 그룹 — injuryRateModifier

| 출처 | value |
|------|-------|
| 칭호 #5 백전노장 | -0.03 |
| 세력/장비 추가 음수 가산 | (M5 페이즈 2 #3 검증한 풀스택 -22.05% 수준) |

`(1 + Σ).clamp(0.10, 1.0)`: Σ가 -0.25 가정 시 → 0.75 (25% 감소). ✓ 클램프 안 침범.

#### 곱셈 그룹 — questRewardMultiplier

| 출처 | value | quest_type |
|------|-------|---------|
| 칭호 #8 더스트빌의 친우 | +0.03 | all |
| 세력 모험가 길드 | +0.12 | explore |
| 세력 화산 심장단 | +0.15 | raid |
| 세력 상인 연합 | +0.12 | escort |

각 quest_type별로 최대 합계: raid 의뢰 시 칭호 0.03(all) + 세력 화산 0.15 = **+0.18 = +18% 보상**. 가산 상한 별도 지정 없음 (페이즈 4 #2 명세에서 정책 결정 필요 — 별도 오픈 질문).

#### 가산 그룹 — investigationSuccessRateBonus

칭호 #6: +0.05 + 세력 도둑 길드: +0.05 = **+0.10** (10%p). 기본 성공률 85% + 10%p = 95% (clamp 상한). 안전 통과 ✓.

#### 가산 그룹 — mercenaryXpBonus

칭호 #11 단독: +0.10. 다른 세력 효과 없음. **+10% XP**. 상한 별도 없음, 단일 효과 충분히 균형.

### 2.5 칭호 단독 빌드 power 비교 (raid 의뢰 시)

**칭호 11종 풀스택 한 용병 + raid 의뢰**:
- 성공률 보너스 합계: +0.08 (칭호 #1·#4 합산) → **+8%p**
- 보상 배수: +0.03 (칭호 #8) → **+3%**
- 부상률: -0.03 (칭호 #5)
- 명성: +0.10 (칭호 #3·#10·#11)
- 회복 시간: -0.10 (칭호 #2, 부상 시만)
- XP: +0.10 (칭호 #11)

**트레잇 7슬롯 풀스택 (charger·hero·shadow 등 raid 강화 조합)**:
- 성공률: +5(charger) + 2(hero) + 4(shadow) + 3(focused) = **+14%p** (raid 의뢰)
- 보상: 직접 보너스 없음 (트레잇 시스템에 reward 효과 없음)

**비교**: 칭호 단독 빌드 +8%p < 트레잇 단독 빌드 +14%p. **칭호는 트레잇 미달**. ✓ "필수 최적해 안 됨"

칭호 강점은 **다종 효과 동시 제공** (성공률 + 보상 + 명성 + XP) 이지만 각 효과 약함. 트레잇은 단일 효과 집중. **빌드 차별화 자연**.

---

## 문제점

### 3.1 광역 효과 두 종 미세 오버

| 칭호 | 권장값 | 문제 |
|------|-------|------|
| #1 마을의 은인 | questSuccessRateBonus(all, +0.03) | 'all'은 모든 quest_type에 가산. 세력 균형 감시자 0.03(all)과 합치면 +0.06 = +6%p 광역. **약간 강함** |
| #8 더스트빌의 친우 | questRewardMultiplier(all, +0.03) | 'all' 광역. 세력 raid 0.15 + 칭호 0.03 = +0.18. 칭호 단독은 약하지만 **광역**이라 의미 낮음 |

**원인**: 'all' 광역 효과는 quest_type 매칭 hook과 합산 시 항상 적용됨. 좁은 효과보다 가치가 높음.

**해결책**: 'all' 광역 효과 강도를 **0.03 → 0.02 또는 0.025**로 미세 하향. 좁은 효과(0.05) 대비 절반 수준.

### 3.2 행동 지표 hook 임계 4종 모두 5h 미달

§2.3 분석 결과. 도달 시점 7.5h~15h로 roadmap "3~5시간 안 1명 이상 칭호 기억"의 행동 지표 경로가 막힘.

위업 기반 칭호(예: #1 마을의 은인은 거점 사건 완주 시 2h 시점에 자연 발급)로 fallback 가능하지만, 칭호 시스템 다양성 보존을 위해 **행동 지표 hook도 5~7h 안 도달 가능**해야 함.

### 3.3 광역 questRewardMultiplier 가산 상한 미정의

칭호 #8 + 세력 quest_type 보상 가산이 누적 시 상한 미정의. 페이즈 4 #2 spec에서 정책 결정 필요(예: +0.30 상한). 본 리포트는 오픈 질문으로 위임.

---

## 플레이어 체감 분석

### 4.1 신규 유저 0~5시간 체감

- **0~1h**: 칭호 0개. "용병단 막 시작" 단계. 정상.
- **1~3h**: 위업 기반 칭호 1~2개 발급 (#3 첫 깃발을 든 자가 깃발 복원 완료 시점에 가장 빠르게 발급, ~30분 시점). 사용자 첫 "이름 기억" 발생.
- **3~5h**: 위업 기반 칭호 누적 3~4개 (#1 마을의 은인 등). roadmap 종료 조건 ✓.
- **5~7h**: 행동 지표 hook 칭호 첫 발급 (#7 호위의 노련함 6h, #6 정찰의 눈 7.5h). 자연 페이스.
- **10h+**: #4·#5 발급. M6 후반 목표.

### 4.2 빌드 의미 평가

칭호 11종이 다음 4종 빌드 방향에 자연 시너지:
- **호위·정찰형**: #2 폐광 생존자 + #6 정찰의 눈 + #7 호위의 노련함 + #11 혼을 끊은 자 (safer + xp)
- **공세형**: #4 도적길 추적자 + #9 괴물 사냥꾼 + #5 백전노장 (raid/hunt 성공률 + 부상률 감소)
- **명성 빌드**: #3 첫 깃발 + #10 이름을 알린 자 + #11 혼을 끊은 자 (rep +10%)
- **거점 충성형**: #1 마을의 은인 + #8 더스트빌의 친우 (region 3 광역 보너스 — hook 좁아 강함)

→ **빌드 다양성 충분, 최적해 고착 없음** ✓.

### 4.3 "필수 최적해" 위험 평가

칭호 단독으로 "이 칭호 없으면 진행 불가" 수준의 효과 없음. 가장 강력한 단일 칭호:
- #2 폐광의 생존자 (-0.10 회복시간) — 부상 시에만 효과. 사용 빈도 제한.
- #4 도적길 추적자 (+0.05 raid) — raid 의뢰 한정. 매 의뢰 5%p.
- #11 혼을 끊은 자 — 엔드 칭호, M5 시점 미발급. 균형.

→ 최적해 고착 위험 **낮음** ✓.

### 4.4 광역 효과 강도 적정성

§3.1 'all' 효과 0.03은 약간 강함. 0.02~0.025로 하향 시:
- 칭호 #1 마을의 은인: +2.5%p (all) — "이름이 들리는 정도" 자연
- 칭호 #8 더스트빌의 친우: +2% (all) — 광역 보상 +2% 자연

좁은 효과(0.05) 대비 절반 강도. 비례 명확.

---

## 조정 제안

### 5.1 effect_json 최종 표 (조정 후)

| # | 칭호 ID | hook | 권장값 (페이즈 1 #2) | **조정 후 (본 리포트)** | 변경 사유 |
|---|---------|------|---------------------|---------------------|---------|
| 1 | `title_village_savior` | (a) | `questSuccessRateBonus(all, +0.03)` | **`questSuccessRateBonus(all, +0.025)`** | 광역 'all' 효과 강도 미세 하향 (좁은 0.05의 절반) |
| 2 | `title_pyegwang_survivor` | (c) | `recoveryTimeReduction(injured, -0.10)` | 그대로 | 세력 0.15 미만, 적절 |
| 3 | `title_first_banner` | (a) | `reputationGainModifier(+0.02)` | 그대로 | rep 약함 1단 |
| 4 | `title_road_hunter` | (b) | `questSuccessRateBonus(raid, +0.05)` | 그대로 | 세력 0.05와 동급, 좁은 효과 정합 |
| 5 | `title_veteran` | (b) | `injuryRateModifier(-0.03)` | 그대로 | 세력 효과 없음, 안전 |
| 6 | `title_scout_eye` | (b) | `investigationSuccessRateBonus(+0.05)` | 그대로 | 세력 0.05와 동급 |
| 7 | `title_escort_master` | (b) | `questSuccessRateBonus(escort, +0.05)` | 그대로 | 좁은 효과 정합 |
| 8 | `title_dustvile_friend` | (a) | `questRewardMultiplier(all, +0.03)` | **`questRewardMultiplier(all, +0.02)`** | 광역 'all' 효과 강도 미세 하향 |
| 9 | `title_monster_hunter` | (a) | `questSuccessRateBonus(hunt, +0.05)` | 그대로 | 좁은 효과 정합 |
| 10 | `title_renowned` | (a) | `reputationGainModifier(+0.03)` | 그대로 | rep 중간 1단 |
| 11 | `title_soul_severer` | (a) | 복합 `reputationGainModifier(+0.05) + mercenaryXpBonus(+0.10)` | 그대로 | 엔드게임 격, 2종 효과 합산 적절 |

**변경 2건만**: #1·#8의 광역 'all' 효과 강도를 0.03 → 0.025·0.02로 미세 하향.

**누적 검증** (조정 후, raid 의뢰 시):
- 칭호 questSuccessRateBonus 합계: 0.025(all) + 0.05(raid) = **+0.075 = +7.5%p**
- 칭호 questRewardMultiplier 합계: 0.02(all) = **+2%**
- 다른 효과들 그대로

→ §2.4 풀스택 시너지 안전 검증 그대로 유효 (변경 미미).

### 5.2 행동 지표 hook 임계 최종 표 (조정 후)

| 칭호 | stat_key | 권장 (페이즈 1 #2) | **조정 후** | 도달 시점 (8회/h) |
|------|----------|------------------|----------|------------------|
| 도적길 추적자 | `raid_count` | 30 | **20** | 10h |
| 백전노장 | `total_dispatch_count` | 100 | **80** | 10h |
| 정찰의 눈 | `explore_count` | 20 | **15** | 7.5h |
| 호위의 노련함 | `escort_count` | 15 | **12** | 6h |

**조정 사유**:
- 5~10시간 누적 플레이 구간에 4종 모두 자연 도달
- "M6 후반에 행동 지표 칭호도 만난다"는 자연 페이스
- 너무 빠르지 않게(3h 이전 발급은 무게감 희석) + 너무 늦지 않게(15h+은 미도달 좌절)

### 5.3 PassiveEffect 타입 별 가산/곱셈 상한 정합 정리

| PassiveEffect | 누적 정책 | 클램프/상한 | 칭호 기여 | 풀스택 안전 |
|--------------|---------|------------|---------|------------|
| `questSuccessRateBonus` (all/raid 등) | 가산 (`Σ`) | QuestCalculator 5~95% clamp | +0.025 ~ +0.075 (raid 의뢰) | ✓ |
| `questRewardMultiplier` (all 등) | 가산 (`Σ`) | **상한 미정의** (페이즈 4 #2 결정 필요) | +0.02 (광역) | ⚠ 오픈 질문 |
| `recoveryTimeReduction(injured)` | `(1 - Σ).clamp(0.10, 1.0)` | 하한 0.10 | -0.10 (Σ에 +0.10 기여) | ✓ |
| `injuryRateModifier` | `(1 + Σ).clamp(0.10, 1.0)` | 하한 0.10 | -0.03 (Σ에 -0.03 기여) | ✓ |
| `investigationSuccessRateBonus` | 가산 | 5~95% clamp (추정) | +0.05 | ✓ |
| `reputationGainModifier` | 가산 (`Σ`) | 상한 +0.30 | +0.10 (칭호 풀) | ✓ (상한 미달) |
| `mercenaryXpBonus` | 가산 (`Σ`) | 상한 미정의 | +0.10 (단일 칭호) | ✓ |

**`questRewardMultiplier` 가산 상한 미정의**: 칭호 #8 +0.02(all) + 세력 화산 +0.15(raid) = +0.17(raid 의뢰) 합계. 페이즈 4 #2 명세에서 상한 +0.30 또는 +0.50 결정 필요. **본 리포트는 오픈 질문으로 위임**.

---

## 시뮬레이션

### 6.1 신규 유저 0~10시간 칭호 보유 누적 (조정 후 임계 적용)

가정: 위업 발급 페이스는 #1 산출물 §2.4 표 그대로 (조정 없음). 행동 지표 임계만 조정.

| 누적 플레이 | 위업 기반 칭호 | 행동 지표 칭호 | 누적 칭호 (한 용병 기준 평균) |
|-----------|---------------|---------------|--------------------------|
| 0.5h | 0 | 0 | 0 |
| 1h | 0~1 (#3 첫 깃발 가능) | 0 | 0~1 |
| 2h | 1~2 (#1·#3) | 0 | 1~2 |
| 3h | 2 (#1·#3) + 가능 #10 | 0 | 2~3 |
| 5h | 3~4 (#1·#3·#10 + #2 폐광생존자 일부) | 0 | 3~4 |
| 7h | 4~5 | 1 (#7 호위, #6 정찰) | 5~6 |
| 10h | 5~6 | 2~3 (#7·#6·#4·#5) | 7~9 |

roadmap "3~5h 안 1명 이상 칭호 기억" → **3h 시점에 평균 2~3개 칭호 보유**. ✓ 자연 충족.

10h 시점에 평균 7~9개 칭호 → **거의 모든 칭호 만나는 자연 페이스**. 풀스택 11종은 #11 엔드 칭호 추가 후 가능.

### 6.2 풀스택 raid 의뢰 최종 성공률 시뮬레이션 (가장 강한 케이스)

가정: 한 용병이 칭호 11종 + 트레잇 raid 강화 7개(charger·hero·shadow 등) + 가입 세력 전사+균형 + 랭크 A. raid 의뢰 difficulty 5 수행.

**기본 partyPower 100, 적전투력 200 가정** (어려운 의뢰).

- 베이스 성공률 (QuestCalculator 공식): 약 35%
- 칭호 #1·#4 가산: +0.025 + 0.05 = +7.5%p
- 세력 전사 raid: +5%p
- 세력 균형 all: +3%p
- 트레잇 합계 (정수%, 별도 시스템): charger 5 + hero 2 + shadow 4 + tactician 2 + focused 3 = 16%p
- 파티 상성·거리 보정 등 (생략)

**최종 성공률**: 35 + 7.5 + 5 + 3 + 16 = **66.5%** (어려운 의뢰의 합리적 성공률)

5~95% clamp 안전 통과. ✓ Over-power 아님.

### 6.3 부상률 풀스택 (#5 백전노장 포함)

가정: 칭호 #5 -0.03 + 세력 무 + 장비 (M2a) 수호자 방패 -0.07 + M5 약초사 인장 -0.04 + 광부 부적 -0.03 = Σ -0.17

`(1 - 0.17).clamp(0.10, 1.0)` = **0.83** (17% 감소). 클램프 안전 ✓.

극단 가정: 추가 세력·트레잇 +음수 가산해서 Σ = -0.45 → `(1 - 0.45).clamp(0.10, 1.0)` = 0.55 (45% 감소). 여전히 클램프 미충돌. ✓

### 6.4 회복 시간 풀스택 (#2 폐광 생존자 포함)

가정: 칭호 #2 -0.10 + 세력 태양 -0.15 + 뿌리 -0.15 + 의무실 Lv25 (시설 효과) 최대 -0.70 = Σ 0.10 + 0.15 + 0.15 + 0.70 = **1.10**

`(1 - 1.10).clamp(0.10, 1.0)` = **0.10** (90% 감소). **클램프 적용**. ✓ 안전망 정상 동작.

세력 둘 다 가입 + 칭호 + 의무실 Lv25 = 회복 시간 90% 감소. 부상 시 회복이 매우 빠르지만 게임적으로 자연 보상.

---

## 페이즈 2 #2 노출 빈도 산출물에 전달할 사항

본 리포트는 effect_json 수치와 행동 지표 임계만 다룬다. 다음은 **페이즈 2 #2 노출 빈도·획득 페이스 밸런스**에서 검증할 항목:

1. **위업 발급 페이스**: #1 산출물 §2.4 시뮬레이션 검증
2. **칭호 발급 페이스**: 본 리포트 §6.1 시뮬레이션 (조정 후 임계 적용) 검증
3. **지명 의뢰 등장 빈도**: #3 산출물 §3.2 시뮬레이션 (가중치 α=3·쿨다운 24h)
4. **세 시스템 통합 페이스**: 신규 유저 3~5h 안 위업·칭호·지명 의뢰 모두 1회 이상 노출

---

## 오픈 질문 (페이즈 4 #2·#3 명세에 위임)

- **Q-1 (`questRewardMultiplier` 가산 상한)**: 현재 PassiveEffect에 상한 미정의. 칭호 0.02(all) + 세력 0.15(raid) + 다른 세력 0.12(escort) 등 누적 시 quest_type 한정 합산이 +0.30 또는 +0.50 넘어갈 위험. **권장**: 페이즈 4 #2 spec에서 가산 상한 +0.30 명시 (reputationGainModifier 동일 정책)
- **Q-2 (`mercenaryXpBonus` 상한)**: 칭호 #11 +0.10 단독. 다른 시스템에 추가 효과 도입 시 누적. 본 리포트 시점엔 상한 불필요하나 페이즈 4 #2 spec에서 권장 상한 +0.30 명시 검토
- **Q-3 (트레잇 effect_json과 칭호 effect_json 시스템 분리)**: 페이즈 4 #2 spec에서 PassiveBonusService와 TraitEffectService의 책임 분리 명시. 칭호 effect_json은 PassiveEffect sealed 형식, 트레잇 effect_json은 정수% Map. 두 시스템 누적 시 별도 계산 후 합산
- **Q-4 (`investigationSuccessRateBonus` 상한)**: 현재 칭호 +0.05 + 세력 도둑 +0.05 = +10%p. 기본 85% + 10%p = 95%(clamp 상한). 페이즈 4 #2 spec에서 clamp 상한 코드 확인 필요
- **Q-5 (시간당 평균 파견 수 8회 가정)**: 본 리포트 §2.3 페이스 모델링의 핵심 가정. 페이즈 2 #2에서 의뢰 풀 갱신 주기(1h) + 평균 의뢰 소요 시간(30min) 통합 검증으로 확정

---

## data-generator 수치 가이드

본 리포트는 11행 데이터 시드 작성용 수치 가이드를 제공한다. 페이즈 1 #2 산출물의 §data-generator 지시사항을 보완.

- **대상 타입**: `title` (페이즈 1 #2와 동일)
- **대상 테이블**: `titles` (29번째 신규 테이블)
- **수치 범위 — effect_json**:
  - 모든 칭호: PassiveEffect 17종 sealed 직렬화 형식
  - 광역 'all' 효과 (#1·#8): **value 0.02~0.025** (좁은 효과의 절반)
  - 좁은 quest_type 효과 (#4·#7·#9): **value 0.05** (세력 동급)
  - 부상 회복 (#2): **value -0.10** (세력 0.15 미만)
  - 부상률 (#5): **value -0.03** (단일 효과, 안전 범위)
  - 조사 성공률 (#6): **value +0.05** (세력 동급)
  - 명성 (#3·#10·#11): **value +0.02 / +0.03 / +0.05** (격차 1단/2단/엔드)
  - XP (#11): **value +0.10** (엔드 단독)
- **수치 범위 — hook_condition (action_stat 4종)**:
  - #4 도적길 추적자: `{stat_key: "raid_count", threshold: 20, operator: ">="}`
  - #5 백전노장: `{stat_key: "total_dispatch_count", threshold: 80, operator: ">="}`
  - #6 정찰의 눈: `{stat_key: "explore_count", threshold: 15, operator: ">="}`
  - #7 호위의 노련함: `{stat_key: "escort_count", threshold: 12, operator: ">="}`
- **balance 근거**:
  - 광역 'all' 0.02~0.025: 좁은 효과 0.05의 절반(§3.1 분석)
  - 좁은 0.05: 세력 동급(§2.1 분석)
  - 행동 지표 임계: 시간당 8회 파견 가정, 5~10h 자연 도달(§2.3 분석)

---

## 후속 작업

### 본 리포트의 결정 사항이 영향을 주는 후속 산출물

- **페이즈 2 #2 노출 빈도·획득 페이스**: 본 리포트 §6.1 시뮬레이션을 입력으로 통합 페이스 검증
- **페이즈 3 #1 (선택)** `types/title.md` 타입 스펙 + 11개 데이터: §5.1 표 + §5.2 임계 그대로 사용
- **페이즈 4 #2 칭호·간판 용병 시스템 명세**: 본 리포트 §5.3 오픈 질문 모두 spec에 명시(상한 정책 결정)

### 데이터 반영 방법

본 리포트의 11행 effect_json + hook_condition 수치는 페이즈 4 #2 명세의 SQL INSERT 인라인으로 처리. 별도 data-generator 호출 불필요(7~11행 소량).

운영 도구 반영: operation-bom에 titles 테이블 CRUD 메뉴 추가 후 운영자가 텍스트(name·description·icon_key) 편집 가능.

### 후속 호출

- 페이즈 2 #2 진행: `/balance-designer 노출 빈도·획득 페이스 — M6 페이즈 1 #1·#3 + 페이즈 2 #1 통합 시뮬레이션`
- 페이즈 4 #2 명세 작성 시: `/spec-writer @Docs/content-design/[content]20260512_titles-and-flagship.md` (본 리포트 경로 + #3 산출물 함께 전달)
