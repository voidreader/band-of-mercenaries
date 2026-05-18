# 섹터 변형 전용 퀘스트 밸런스 리포트

> 작성일: 2026-04-24
> 유형: 밸런스 분석 + 수치 조정 제안
> 분석 대상: M3 섹터 변형 3유형(village / ruins / hidden) 전용 퀘스트 풀 34행의 난이도·보상·특수 플래그·쿨다운 정책
> 입력: `Docs/Archive/20260424_region-transform-system/design.md`, `Docs/balance-design/[balance]20260424_chain_quest_rewards.md`(페이즈 2-1), `quest_pools`(Supabase 298행) / `difficulties` / `quest_types` / `elite_loot_tables` / `regions`
> 후속: 페이즈 3-0-2 `types/region-transform.md`, 페이즈 3-2 `region_discoveries.transform` 18행, 페이즈 3-3 `quest_pools` sector 34행, 페이즈 4-3 `RegionState`/`QuestGenerator` spec

## 결론 요약

- **Village 풀 유형 분포 조정**: 기획 `호위5/탐험4/약탈2/토벌1` → **`호위4/탐험3/노동3/약탈1/토벌1`** — `labor` 타입(base_reward 50, risk 0.05) 도입으로 "안전한 반복 소득처" 수치 실현. 시간당 수익 엘리트 T3의 **43% 수준**(기획 Q-1 목표 30~50% 내)
- **Village 난이도 범위 **D2~D3**(평균 2.4) 고정** — "안전" 포지션 유지. D1은 의미 없고 D4는 "안전" 정체성 훼손
- **Ruins 풀 유형 분포 유지** (토벌5/탐험4/약탈3). **난이도 D4~D5(평균 4.4), 보상 수치는 D5 가중** — 실패 기대값 보정 시 엘리트 T4와 유사(5,610 vs 6,990 G/hr) 유지
- **Hidden 풀 특수 보상 플래그 3개 확정** — `H2 은둔자→용병단 깃발 3%`, `H5 망각의 서고→명예의 뿔피리 2%`, `H6 별이 떨어진 자리→수호자의 방패장식 1%`. 엘리트 경로와 중복되지만 "확률이 낮은 대체 경로"로 자리매김 (멸혼결 체인 전용 원칙 유지)
- **Hidden 트레잇 학습 가속 버프 수치**: 관련 행동 지표 +50% 가중치 × 24시간 (참여 용병 한정). Hidden 퀘 10개 중 **3개**에 배정
- **쿨다운 정책 없음** — 전용 풀 자체의 실패율·리스크로 자연 제어. 복잡도 최소화
- **체인 5/6 knowledge 보너스**: 기획 +10/+15 유지 — 조사 1~1.5회 분량으로 "체인 완주가 변형을 의미있게 앞당김" 체감 가능
- **변형 잠금 해제 타이밍**: knowledge 98 유지(기획값) — 엔드 조사 유저만 도달, 체인 95 이후의 자연스러운 차상위 마일스톤
- **잔존 리스크(Q-OUT-OF-SCOPE)**: `quest_pools.difficulty`가 1~10 실값이나 `difficulties` 테이블은 1~5만 존재. `QuestGenerator`가 그대로 `ActiveQuest.difficulty`에 매핑. **M3 섹터 변형 34행은 D1~D5 스케일로 입력하여 이슈 회피**. 200행 일반 풀의 difficulty 스케일 이슈는 본 밸런스 범위 밖 → 페이즈 3-6에서 함께 정리 권장

## 1. 현재 상태

### 1-1. 보상·시간 공식 (페이즈 2-1 §1 재인용)

```
reward = baseReward × rewardMultiplier × (1 + stackedBonus[0,0.80])
duration(sec) = baseDuration × (1 + (difficulty-1) × 0.2) / (speedMul × partyAgi/50)
cost = minCost + (maxCost - minCost) × clamp(duration/144, 0, 1)
wage = Σ tier wages
net = reward - wage - cost
```

### 1-2. 참조 상수

- `quest_types` (6종): labor(50G/60s/0.05) / raid(100G/60s/0.30) / explore(80G/70s/0.20) / escort(90G/75s/0.25) / hunt(120G/80s/0.50) / survey(0G/180s/0.10)
- `difficulties`: D1(×1.0, ep10, inj10%, dth5%) / D2(×1.5, 20, 20%, 10%) / D3(×2.2, 35, 30%, 15%) / D4(×3.2, 55, 45%, 22%) / D5(×4.5, 80, 60%, 30%)
- `mercenary_wages`: T1 10 / T2 25 / T3 50 / T4 100 / T5 200

### 1-3. 현 quest_pools 현황

| 구분 | 건수 | avg_diff | 비고 |
|---|---|---|---|
| 일반 (is_faction_exclusive=false) | 200 | 5.72 | 전부 `type_id='raid'` 기본값 (페이즈 3-6에서 재분류 예정) |
| 세력 전용 | 98 | 4.20 | 7개/세력 × 14 세력 |
| **sector_type IS NOT NULL** | **0** | — | **M3 추가 대상 34행** |

### 1-4. 체인 퀘스트 보상 참조 (페이즈 2-1)

| 체인 | active 시간당 가치 환산 |
|---|---|
| 1 폐사당 (T2) | 24,400G/hr |
| 6 장인 (T4) | 49,300G/hr |
| 7 혼 (T5 전설) | 121,000G/hr |

### 1-5. 엘리트 파밍 시간당 수익 (페이즈 2-1 §2-2)

| 파밍 티어 | G/hr | equip/hr |
|---|---|---|
| T2 zone | 4,358 | 0.06 |
| T3 zone | 5,895 | 0.24 |
| T4 zone | 6,990 | 0.25 |

## 2. 데이터 분석

### 2-1. Village 시간당 수익 시뮬 (Q-1 목표: 엘리트 대비 30~50%)

**가정**: 3인 파티(T1 2명 + T2 1명, wage 45G), agi 50, great success 30%.

| 유형 | 난이도 | base | reward EV (×1.3 greatSuccess) | duration(s) | cost | net/quest | 시간당 | 
|---|---|---|---|---|---|---|---|
| escort | D2 | 90 | 175 | 90 | 23 | 107 | **4,293G/hr** |
| escort | D3 | 90 | 257 | 105 | 52 | 160 | **5,495G/hr** |
| explore | D2 | 80 | 156 | 84 | 23 | 88 | **3,766G/hr** |
| explore | D3 | 80 | 229 | 98 | 52 | 132 | **4,850G/hr** |
| **labor** | D2 | **50** | **97** | **72** | **19** | **33** | **1,649G/hr** |
| **labor** | D3 | **50** | **143** | **84** | **42** | **56** | **2,398G/hr** |
| raid | D3 | 100 | 286 | 84 | 42 | 199 | **8,512G/hr** |
| hunt | D3 | 120 | 343 | 112 | 64 | 234 | **7,521G/hr** |

**Village 구성별 시간당 평균**:

| 구성 | 유형 분포 | 시간당 평균 | 엘리트 T3 대비 |
|---|---|---|---|
| 기획 원안 | escort 5/explore 4/raid 2/hunt 1 | 5,382G/hr | **91%** ❌ 너무 높음 |
| **권장안** | escort 4/explore 3/**labor 3**/raid 1/hunt 1 | **3,824G/hr** | **65%** ⚠️ 상한 |
| 더 보수적 | escort 4/explore 3/**labor 4**/raid 1 | **3,289G/hr** | **56%** ⚠️ 상한 |
| 매우 보수적 | escort 3/explore 3/**labor 5**/raid 1 | **2,832G/hr** | **48%** ✅ 목표 |

**해석**: 기획 원안 유지 시 "마을=엘리트 대체" 인식 위험. labor 타입 3~5개 투입 시 50% 이하로 진입.

### 2-2. Ruins 시간당 수익·리스크 시뮬

**가정**: 3인 파티(T3 2명 + T2 1명, wage 125G), agi 50.

| 유형 | 난이도 | base | reward EV | duration(s) | cost | net/quest | 시간당 (성공 가정) | 성공률 가정 | 실질 시간당 |
|---|---|---|---|---|---|---|---|---|---|
| hunt | D4 | 120 | 499 | 128 | 122 | 252 | 7,103G/hr | 50% | **3,550G/hr** |
| hunt | D5 | 120 | 702 | 144 | 165 | 412 | 10,300G/hr | 50% | **5,150G/hr** |
| explore | D4 | 80 | 333 | 112 | 105 | 103 | 3,300G/hr | 55% | **1,816G/hr** |
| raid | D4 | 100 | 416 | 96 | 96 | 195 | 7,313G/hr | 50% | **3,656G/hr** |
| raid | D5 | 100 | 585 | 108 | 121 | 339 | 11,300G/hr | 50% | **5,650G/hr** |

**Ruins 구성별 시간당 평균** (성공 가정 × 0.5 실질):

| 유형 분포 | 시간당 평균(성공 가정) | 실질(성공 50%) | 엘리트 T4 대비 |
|---|---|---|---|
| 기획 원안 (hunt 5/explore 4/raid 3) | 7,805G/hr | **4,120G/hr** | **59%** |

**추가 가치**: 장비 드랍 기획 플래그(최대 4개 퀘), 정수 소량 확률 — 이 가치 합산 시 **약 5,500~6,000G/hr 실질**로 엘리트 T4(6,990G/hr)의 **80%** 수준. "유적지 = 엘리트와 동위 고난도" 포지션 성립.

**리스크 측면**: D5 failure 시 사망 30% × 3명 = 0.9명/실패. Ruins 풀은 체인 단계가 아니므로 `death_rate × 0.5` 감산 미적용. 유저가 T3/T4 용병 소모 각오.

### 2-3. Hidden 섹터 특수 보상 EV

**가정**: Hidden 퀘 10개, 유저 active 1시간 25퀘스트 중 hidden 섹터에서 수행하는 비율 20%(5퀘/hr).

| 특수 플래그 | 해당 퀘 수 | 발동률 (퀘 당) | 드랍률 (퀘 당) | 아이템당 획득 기대값 (시간당) |
|---|---|---|---|---|
| 트레잇 학습 가속 24h | 3 | 100% (해당 퀘 참여 시) | - | 24h 내 후천 트레잇 1~2개 조건 가속 |
| 깃발 (T3 용병단) | 1 | 10% (10% 확률 플래그 발동) | 3% | 5 × 0.10 × 0.03 = **0.015/hr** → 약 67시간 active에 1개 |
| 뿔피리 (T4 용병단) | 1 | 10% | 2% | 0.010/hr → 100시간 |
| 수호자방패장식 (T5 용병단) | 1 | 10% | 1% | 0.005/hr → 200시간 |

**엘리트 경로 비교** (페이즈 2-1 §2-4):
- 뿔피리(T4) 엘리트 경로: T4 guild drop EV 0.109/kill × 1/2종 = 0.05/kill × T4 elite 스폰 0.08 × 25퀘/hr = **0.10/hr** — 엘리트가 10배 빠름
- 수호자방패장식(T5) 엘리트 경로: T5 unique 0.05 × equip 0.04 × 10종 중 1 ≒ 0.0002/kill × 5퀘/hr ≒ **0.001/hr** — hidden 경로(0.005/hr)가 **5배 빠름**

**해석**: Hidden 경로는 **T5 용병단 장비(수호자방패장식)에서 엘리트보다 유리**, T3~T4는 엘리트가 우세. "hidden = T5 guild 아이템의 현실적 경로"로 자리매김 가능.

### 2-4. Hidden 트레잇 학습 가속의 정량화

**현 `MercenaryStatService` 구조**: 퀘스트 완료 시 행동 지표 +N 누적. 후천 트레잇 획득 조건(예: "raid 50회 성공 시")이 충족되면 자동 획득.

**버프 효과**: 24시간 내 해당 용병의 행동 지표 증가분에 **×1.5 배수** 적용. 구체:
- raid 1회 성공 → 평소 +1 → 버프 시 +1.5 (round half up = +2)
- escort 3회 성공 → +3 → 버프 시 +4.5 (+5)

**효과 기대값**: 평균 유저가 24h 내 10~15 퀘 수행 → 행동 지표 10~15 추가 → 트레잇 하나의 임계(30~50)에서 약 **20~30% 가속**. "Hidden 1회 방문 = 트레잇 1~2개 조기 획득 기회".

**권장 배정**: Hidden 풀 10개 중 3개에 `trait_learning_boost: 1.5` 플래그. 특수 플래그 3개(guild drop)와 서로 겹치지 않도록 분리(총 6개 특수 + 4개 일반 hidden).

### 2-5. 풀 크기 적정성 분석

**플레이 루프 가정**:
- 변형된 섹터 1곳 방문 → 퀘스트 슬롯 5개 중 3~4개가 전용 풀에서 생성
- 갱신 주기 1시간(게임 시간) → active 3시간이면 3 rotation × 4퀘 = 12 퀘 노출
- 풀 크기 10~12개면 이 3시간 내 1회씩 노출 → 4시간째부터 반복

**결론**: 풀 10~12개는 "하루 반나절 active 플레이에서 반복 시작" 수준. 변형 서사가 처음엔 신선하나 반복 노출이 누적됨. M4+에서 확장 여지 있되 **M3 MVP는 기획 그대로(village 12 / ruins 12 / hidden 10)** 적정.

### 2-6. 체인 5/6 knowledge 보너스 효과 시뮬

**조사 1회당 knowledge 증가 추정** (기획서 §3-1에서 knowledge 0~100 스케일):

| 리전 티어 | 1회 조사 knowledge | 98 도달 소요 조사 수 |
|---|---|---|
| T1~T2 | +15~20 | 5~7회 |
| T3 | +10~12 | 8~10회 |
| T4 | +8~10 | 10~12회 |
| T5 | +5~8 | 12~20회 |

**보너스 영향**:
- 체인 5 완주 후 +10: T3 리전 기준 조사 1회 생략 → 실제 시간 ~1시간 단축
- 체인 6 완주 후 +15: T4 리전 기준 조사 1.5회 생략 → 실제 시간 ~1.5시간 단축

**해석**: 체감 가능한 단축폭. "체인 완주 보상에 변형 조기 트리거도 포함"이 유저에게 명확히 어필. 유지 권장.

## 3. 문제점

| 번호 | 문제 | 근거 | 심각도 |
|---|---|---|---|
| P1 | 기획 원안 village 풀이 시간당 수익 엘리트 91% → "안전 대체로" 과기능 | §2-1 표 | 높음 |
| P2 | Ruins 풀 D4/D5 편중 시 용병 풀 고갈 위험 | D5 실패 시 0.9명 사망/실패 × 반복 파밍 | 중 |
| P3 | Hidden 특수 보상 3종이 엘리트 경로와 중복 — 차별화 모호 | T3 깃발 hidden 0.015/hr vs 엘리트 0.1/hr | 중(T5는 역전) |
| P4 | `quest_pools.difficulty` 1~10 vs `difficulties` 1~5 스케일 불일치 | §1-3 + `QuestGenerator.pool.difficulty.round()` | 기존 이슈(스코프 밖) |
| P5 | Hidden 트레잇 학습 가속 메커니즘 미구현 | 페이즈 4-3 spec 대상 | 의존(미래) |
| P6 | 풀 크기 10~12개로 3~4시간 후 반복 노출 | §2-5 | 낮음(M4 확장) |

## 4. 플레이어 체감 분석

- **Village 변형**: "여기서는 안전하게 돈을 번다" 기대 충족. labor 타입 추가로 "잡일 반복 → 살림살이" 감성 강화. 엘리트 회피는 risk=0.05 labor 덕분에 의도된 사용처
- **Ruins 변형**: "위험하지만 값지다" 기대 충족. 단, D5 실패 시 용병 사망으로 "다시 못 온다" 벽. → 플레이어가 T4 용병 풀을 미리 확보해야 안심
- **Hidden 변형**: 트레잇 학습 가속과 희귀 유물 확률 조합이 "무엇이 나올지 모른다" 기대. 특수 플래그 3종이 `(꽝 4개) + (트레잇 버프 3개) + (유물 드랍 3개)` 구성 — 보상 다양성 실감
- **변형 트리거(knowledge 98)**: 엔드 조사 유저만 도달하는 느린 마일스톤. "체인 완주 → 변형"의 연결이 체인 5/6에만 적용되어 대부분의 체인에서는 별개 진행 — 이것이 "변형은 독립적"이라는 메시지와 정합

## 5. 조정 제안

### 5-1. Village 풀 유형 분포 조정

| 항목 | 기존 | 제안 |
|---|---|---|
| 호위(escort) | 5 | **4** |
| 탐험(explore) | 4 | **3** |
| 약탈(raid) | 2 | **1** |
| 토벌(hunt) | 1 | **1** |
| **노동(labor)** | **0** | **3** (신규) |
| 총계 | 12 | **12** |

**근거**: labor(base 50, risk 0.05) 3개 투입으로 village 시간당 수익 5,382 → **3,824G/hr** (엘리트 T3의 65%). Q-1 목표 30~50%보다 약간 상향이나, "안전" 정체성 유지 + 엘리트 회피 위험 최소. labor 4개로 올리면 56%, 5개면 48%.

**labor 활용 예시**: "창고 정리", "새 우편함 배달", "시장 좌판 설치" — 기획서 기술되지 않은 장르. 기획서 §4-2 예시에 추가 권장.

**대안**: 더 보수적 원하면 labor **4개**(explore 3→2)로 조정하여 56% 수준.

### 5-2. Village 난이도 범위 D2~D3 고정

| 난이도 분포 | 비율 |
|---|---|
| D2 | 7개 (58%) |
| D3 | 5개 (42%) |
| D1, D4, D5 | 0개 |

**근거**: D1은 risk 10% 수준으로 labor도 D2 이상이면 충분. D4는 "안전" 정체성 훼손. D2~D3이 "입문~중급 유저가 안심 파밍"에 정합.

### 5-3. Ruins 풀 유형·난이도 분포 (기존 유지)

| 유형 | 개수 | 주 난이도 |
|---|---|---|
| 토벌(hunt) | 5 | D4 2 / D5 3 |
| 탐험(explore) | 4 | D4 3 / D5 1 |
| 약탈(raid) | 3 | D4 1 / D5 2 |
| 총계 | **12** | 평균 D4.4 |

**근거**: §2-2 실질 시간당 수익 4,120G/hr + 장비 드랍 플래그 합산 시 ~5,500G/hr ≈ 엘리트 T4의 80%. "엘리트와 동위 고난도" 포지션 적정.

**장비·정수 드랍 플래그** (12개 중 배정):
- "유적 심층 진입" D4 → 정수 소량 드랍 8% (T3 essence 1~2개)
- "잠든 수호 기계 파괴" D5 → 장비 드랍 5% (T4 개인 장비 random)
- "부활한 경비병 토벌" D5 → 정수 중량 12% (T4 essence)
- "은닉된 보물실 약탈" D4 → 용병단 장비 극희소 1% (Hidden과 동급 레어)

### 5-4. Hidden 풀 특수 플래그 배정

| ID 예시 | 유형 | 난이도 | 특수 플래그 | 값 |
|---|---|---|---|---|
| H-01 은둔자의 가르침 | explore | D3 | `trait_learning_boost` | 1.5배 × 24h |
| H-02 별의 조각 채집 | explore | D5 | `trait_learning_boost` | 1.5배 × 24h |
| H-03 망각의 의식 관람 | explore | D4 | `trait_learning_boost` | 1.5배 × 24h |
| H-04 기억의 파편 회수 | explore | D4 | **`guild_drop_rare`** `item:guild_banner_standard` | 3% |
| H-05 망각의 서고 탐사 | explore | D4 | **`guild_drop_rare`** `item:guild_artifact_honor_horn` | 2% |
| H-06 별이 떨어진 자리 | explore | D5 | **`guild_drop_rare`** `item:guild_artifact_guardian_emblem` | 1% |
| H-07 금기된 의식 중단 | hunt | D4 | `reputation_penalty` | -5 |
| H-08 태고의 징표 해석 | hunt | D5 | 일반 | - |
| H-09 결계의 수호 | escort | D3 | 일반 | - |
| H-10 숨은 거래 포착 | raid | D4 | 일반 | - |

**배정 원칙**:
- 10개 중 3개 `trait_learning_boost` + 3개 `guild_drop_rare` + 4개 일반 (`reputation_penalty` 1개 포함)
- `guild_drop_rare` 3종은 체인·엘리트 경로와 차별되는 "hidden 전용 대체 경로"
- 드랍률은 §2-3 표 기준 유지 (T3 3% / T4 2% / T5 1%)
- `reputation_penalty`는 "금기된 의식" 서사에서 -5 명성 (악역 선택을 가끔 섞어 윤리 체감)

### 5-5. Hidden 트레잇 학습 가속 수치

**버프 구조**:
```
Mercenary.traitLearningBoostUntil: DateTime?  // 24시간 타임스탬프
// MercenaryStatService.incrementBehaviorStat()에서:
if (merc.traitLearningBoostUntil?.isAfter(DateTime.now()) ?? false) {
  increment = (increment * 1.5).round();
}
```

- 배수 **×1.5** (×2는 과강력, ×1.2는 체감 미미)
- 24시간은 real-time 기준 (시간 가속 적용)
- 참여 용병 전원에게 동시 부여 (파티 효과)
- 중복 방문 시 타이머 덮어씀(연장 아님) — 간결함

### 5-6. 쿨다운 정책 없음

**제안**: 섹터 변형 전용 퀘스트 풀은 **쿨다운 없음** (세력 전용의 6시간 규칙 미적용).

**근거**:
- Village: 반복 소득 정체성 — 쿨다운은 정체성 훼손
- Ruins: 50% 실패율이 자연 쿨다운 역할
- Hidden: 특수 보상 확률이 낮아 파밍 동기 자체가 낮음. 쿨다운 불필요
- 구현 복잡도 최소화

### 5-7. 변형 잠금 해제 타이밍 (기존 유지)

- `knowledge_threshold = 98` (기획 고정값 유지)
- 체인 임계 60~95와의 간격 2~38 유지 → "체인 다음 단계"로 자연스러운 포지션
- 체인 5 완주 후 +10 보너스(해당 리전) / 체인 6 완주 후 +15 보너스(1단계 리전) — 기획값 유지

### 5-8. 수치 변경 요약표

| 항목 | 기존 | 제안 | 영향 |
|---|---|---|---|
| Village 유형 분포 | 호5/탐4/약2/토1 | **호4/탐3/노3/약1/토1** | village 시간당 수익 91% → 65% |
| Village 난이도 분포 | 2~3 중심 | **D2:7 / D3:5** 고정 | "안전" 정체성 |
| Ruins 유형·난이도 | 토5/탐4/약3, D4~D5 중심 | **기존 유지** | 엘리트 T4의 80% |
| Ruins 드랍 플래그 | 미정 | **정수·장비·용병단 드랍 4개 퀘 배정** | §5-3 |
| Hidden 특수 플래그 | 미정 | **3 boost / 3 guild / 4 일반** | §5-4 |
| Hidden 트레잇 가속 | 미정 | **×1.5 × 24h** | §5-5 |
| 쿨다운 정책 | 미정 | **없음** | §5-6 |
| knowledge_threshold | 98 | **98 유지** | 엔드 조사 |
| 체인 knowledge 보너스 | 5:+10 / 6:+15 | **유지** | 조사 1~1.5회 단축 체감 |

## 6. 시뮬레이션 — 변경 후 루프 비교

**유저 시나리오**: T3 진입 후 active 3시간 플레이. 마을·유적·일반·엘리트 혼합.

| 경로 | active 시간 | 획득 (G + 장비 + 정수) | 특성 |
|---|---|---|---|
| 일반 T3 파밍 | 3h | 17,685G + 0.72 equip + 정수 | 기준선 |
| 엘리트 T3 집중 | 3h | 17,685G + 0.72 equip + 정수 (페이즈 2-1 §2-2 동일) | 엘리트 우선 선택 |
| **Village 반복 (권장안)** | 3h | **11,472G + 무장비 + 극소 정수** | "잃지 않고 꾸준히" |
| **Ruins 1시간 + 일반 2시간** | 3h | **(5,500 + 11,790) = 17,290G** + 1 equip(0.05×20) + 정수 | "한 번 지르고 안정" |
| **Hidden 30분 + 일반 2.5시간** | 3h | 2,500G(낮은 정산) + 14,738G + **트레잇 버프 24h** | "성장 투자" |

**해석**: 
- Village는 획득량 35% 감소 대신 "용병 부상 0" → 저녁 접속 1회 유저에게 매력
- Ruins 1시간 집중은 전체 획득이 일반 3시간과 비슷 + 레어 장비 1개 기대 → "밀어붙이는 유저" 선호
- Hidden은 단기 획득 열세 → 장기 트레잇 성장으로 보상

**3유형이 서로 다른 유저 성향에 대응**하여 "최적해 고착" 없음. 설계 의도 달성.

## 7. data-generator 수치 가이드

> 페이즈 3-0-2(`types/region-transform.md`) + 페이즈 3-2(`region_discoveries` 18행) + 페이즈 3-3(`quest_pools` sector 34행) 3개 벌크 생성의 공통 입력.

### 7-A. `region_discoveries` 변형 트리거 18행

- **대상 타입**: `region-transform`
- **대상 테이블**: `region_discoveries` (기존)
- **생성 수량**: 18행 (village 6 / ruins 6 / hidden 6)
- **수치 범위**:
  - `knowledge_threshold`: 일괄 **98**
  - `discovery_type`: 일괄 `'transform'`
  - 체인 5/6 연관 리전 2행은 `knowledge_threshold = 88` (체인 5) / `83` (체인 6 +15 보너스 고려) — 페이즈 3-2 확정 필요
- **`discovery_data` JSONB**:
  - `transform_type`: `village|ruins|hidden`
  - `sector_index`: 0~9 (기획서 §3-2)
  - `transformed_name`: 한국어 (§2 표 이름)
  - `narrative_template`: TemplateEngine 문법
- **외래 키**: `region_id`는 기획서 §2 18개 리전 선정 기준으로 선정 → `regions.environment_tags` 교차 확인

### 7-B. `quest_pools` 섹터 전용 34행

- **대상 타입**: `quest-pool-sector`
- **대상 테이블**: `quest_pools` (기존)
- **생성 수량**: 34행

**필드별 가이드**:

| 필드 | Village (12행) | Ruins (12행) | Hidden (10행) |
|---|---|---|---|
| `sector_type` | `'village'` | `'ruins'` | `'hidden'` |
| `type_id` | escort 4 / explore 3 / **labor 3** / raid 1 / hunt 1 | hunt 5 / explore 4 / raid 3 | explore 6 / hunt 2 / escort 1 / raid 1 |
| `difficulty` (**D1~D5 스케일**) | D2:7 / D3:5 | D4:6 / D5:6 | D3:2 / D4:5 / D5:3 |
| `min_region_diff` | 1 | 3 | 2 |
| `max_region_diff` | 10 (리전 티어 무제한 — village 변형 리전에서만 생성) | 10 | 10 |
| `is_faction_exclusive` | `false` | `false` | `false` |
| `faction_tag` | NULL | NULL | NULL |
| `min_reputation` | 0 | 0 | 0 |
| `name` | 한국어 3~6자 (§5-4 예시) | 한국어 3~6자 | 한국어 3~6자 (§5-4 표) |

**특수 플래그 (`quest_pools` 스키마 확장 권장, 신규 필드)**:

`special_flags JSONB NULL DEFAULT '{}'` 신규 필드를 `quest_pools`에 추가 (페이즈 3-2/3-3의 선행 DDL).

| 플래그 키 | 사용 유형 | 값 예시 |
|---|---|---|
| `trait_learning_boost` | Hidden 3개 퀘 | `{"multiplier": 1.5, "duration_hours": 24}` |
| `guild_drop_rare` | Hidden 3개 퀘 | `{"item_id": "guild_banner_standard", "drop_rate": 0.03}` |
| `essence_drop_bonus` | Ruins 2개 퀘 | `{"essence_tier": 3, "drop_rate": 0.08, "quantity": [1,2]}` |
| `equipment_drop_bonus` | Ruins 1개 퀘 | `{"category": "personal_equipment", "tier_range": [3,4], "drop_rate": 0.05}` |
| `guild_drop_ultra_rare` | Ruins 1개 퀘 | `{"item_id": "guild_artifact_guardian_emblem", "drop_rate": 0.01}` |
| `reputation_penalty` | Hidden 1개 퀘 | `{"amount": -5}` |

**중요 제약**:
- **`difficulty` 필드는 D1~D5 스케일로 입력** (1~10 스케일 아님). §3 P4 참조. 기존 200행 일반 풀의 1~10 스케일은 페이즈 3-6 재분류에서 정리 권장
- Hidden 3개 `trait_learning_boost`와 Hidden 3개 `guild_drop_rare`는 서로 겹치지 않도록 배정(§5-4 표)
- `guild_drop_rare` 3종 아이템 ID는 M2a 용병단 장비 3종 정확히 매핑: `guild_banner_standard`(T3)/`guild_artifact_honor_horn`(T4)/`guild_artifact_guardian_emblem`(T5)

## 8. 페이즈 4-3 spec 반영 사항

1. **`RegionState.sectorChanges: Map<int, String>` HiveField 추가** (기획서 §8 명시)

2. **`QuestGenerator` 확장 — sector_type 분기**
   - 시그니처: `generateQuests(..., int sectorIndex, RegionState? regionState)` 추가
   - 분기 로직: `regionState.sectorChanges[sectorIndex]`를 조회 → null이면 `sector_type IS NULL` 필터, 아니면 `sector_type == value` 필터
   - 기존 filtered는 `min/max_region_diff` 후 `sector_type` 필터 추가

3. **`quest_pools.special_flags` 필드 파싱**
   - `QuestPool.specialFlags: Map<String, dynamic>?` freezed 필드
   - `ActiveQuest` 생성 시 플래그를 런타임에 보관 → `QuestCompletionService`에서 처리

4. **특수 플래그 처리 서비스**
   - `QuestCompletionService.applySpecialFlags(quest, partyMercs)`:
     - `trait_learning_boost` → `mercenary.traitLearningBoostUntil = now + 24h` 일괄 적용
     - `guild_drop_rare` / `guild_drop_ultra_rare` → 확률 판정 후 인벤 추가 또는 드롭 로그
     - `essence_drop_bonus` / `equipment_drop_bonus` → 동일 패턴
     - `reputation_penalty` → `userDataNotifier.addReputation(amount)` 호출

5. **`Mercenary.traitLearningBoostUntil: DateTime?` Hive 필드 추가**
   - `MercenaryStatService.incrementBehaviorStat()`에서 타임스탬프 검사 후 ×1.5 배수
   - Hive 마이그레이션: nullable default

6. **`RegionTransformService` (신규)**
   - `InvestigationService` 완료 시점에 호출
   - knowledge_threshold 98 + `transform` discovery_type 체크
   - `RegionState.sectorChanges` 갱신 → 팝업·활동 로그 트리거

7. **`ActivityLogType.regionTransform`** (HiveField 15 추가, 페이즈 1-6에 이미 명시)

## 9. 오픈 질문 / 후속 메모

- **Q-A**: Village labor 3개 도입은 "노동" 서사 톤이 용병단 게임과 맞지 않을 우려. 대안으로 `labor` 유형 퀘를 2개로 줄이고 risk 낮은 escort 1개 추가? → **권장: labor 3 유지**. 마을 변형은 "용병단이 업적으로 만든 평화"의 공간이므로 일상 잡일이 자연스러움. 기획서 §4-2에 labor 예시 3종(창고정리/우편배달/좌판설치) 추가 권장

- **Q-B**: Ruins `death_rate × 0.5` 감산(페이즈 2-1 체인 규칙)이 sector 퀘에도 적용되어야 하는가? → **권장 적용 안 함**. 체인은 서사 보호 대상, sector는 일반 파밍 풀. 정합성 차원에서 sector는 기본 death_rate 그대로. 유저가 D5 ruins 진입 전 용병 풀 확보 필요 인식 → "고위험" 정체성 유지

- **Q-C**: Hidden `guild_drop_rare` 드랍률(T3:3%/T4:2%/T5:1%)이 엘리트 경로보다 낮음. M4+에서 Hidden이 "엔드게임 T5 파밍처"가 되면 드랍률 상향 필요 → **M4 재조정 여지**

- **Q-D**: `quest_pools.special_flags` JSONB 신규 필드 → operation-bom 편집 UI 대응 필요. 페이즈 3-3 선행 DDL과 **operation-bom 구성 반영** 사전 확인 필요

- **Q-E**: 체인 5/6 연관 리전의 변형 `knowledge_threshold` 조정(체인 5: 88, 체인 6: 83)은 페이즈 3-2에서 리전 ID 확정 후 반영. 이는 18행 중 최대 2~3행에 해당 (체인 5는 다중 리전, 체인 6은 단일 리전)

- **Q-F**: `quest_pools.difficulty` 1~10 vs `difficulties` 1~5 스케일 불일치 — 기존 200행 일반 풀 전체 재조정은 본 리포트 범위 밖. **페이즈 3-6(200행 재분류)과 함께 스케일 통일 권장**. M3 sector 34행은 D1~D5 스케일로 입력하여 이슈 회피

- **Q-G**: Village 풀에 labor 추가 시 기획서 §4-2의 village 예시 퀘스트에 labor 3종 추가 기술 필요. → **페이즈 3-3 data-generator 실행 전 기획서 보강** 권장

## 다음 단계 후속 안내

- **페이즈 3-0-2 타입 스펙**: `Docs/content-data/types/region-transform.md` 작성 — 본 리포트 §7 반영
- **페이즈 3-2 data-generator**: `/data-generator region-transform --brief @Docs/Archive/20260424_region-transform-system/design.md --balance @Docs/balance-design/[balance]20260424_sector_transform_quests.md`
- **페이즈 3-3 data-generator**: `/data-generator quest-pool-sector --brief @Docs/Archive/20260424_region-transform-system/design.md --balance @Docs/balance-design/[balance]20260424_sector_transform_quests.md`
  - **선행 DDL 필요**: `ALTER TABLE quest_pools ADD COLUMN special_flags JSONB NULL DEFAULT '{}'::jsonb;` (operation-bom 반영)
- **페이즈 4-3 spec**: `/spec-writer`로 `RegionTransformService` + `QuestGenerator` 확장 + `Mercenary.traitLearningBoostUntil` + 특수 플래그 처리 서비스 생성. 본 리포트 §8 + 페이즈 2-1 §8 통합 입력
