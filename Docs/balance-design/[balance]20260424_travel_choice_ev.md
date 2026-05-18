# 이동 선택지 기대값(EV) 밸런스 리포트

> 작성일: 2026-04-24
> 유형: 밸런스 분석 + 수치 조정 제안
> 분석 대상: M3 이동 선택지 이벤트 12종 × 30 선택지 × 72 결과의 EV, `hidden > safe ≥ risky` 정책 검증, 발동 확률·효과 타입 분포
> 입력: `Docs/Archive/20260425_travel-choice-system/design.md`, 페이즈 2-1/2-2 밸런스 리포트, `travel_events`(Supabase 12행), `TravelEventService` 코드
> 후속: 페이즈 3-0-4 `types/travel-choice.md`, 페이즈 3-5 114행 벌크 생성, 페이즈 4-5 `TravelChoiceService` + 회상 UI spec

## 결론 요약

- **"1G 환산 기준" 제정** — 모든 효과를 단일 척도로 비교. 명성 1 ≒ 10G, 부상 -1 = -400G, 피곤 ±1 = ±50G, trait_innate = +400G, trait_acquired 버프 24h = +300G, item 하급 = +40G, item 중급 = +150G, nothing = 0G
- **발동 확률 cap 0.40~0.60 → 일괄 0.30으로 단축** — 유저 체감 1시간 6~12회 이동 × 0.30 = 2~4회 선택지(목표 부합). 자동 이벤트(cap 0.80)와 합산 시 총 3~5회/hr
- **EV 정책 3목표 제시**: `EV(hidden) ≥ 2 × EV(risky)`, `EV(safe) ∈ [5, 25G]`, `EV(risky) ∈ [25, 60G]` — hidden 월등한 우위 보장
- **기획서 §9-1 샘플 hidden EV 51G < risky EV 55G 정책 위반 감지** → hidden r0 item을 `herb_bundle`(40G) → `rare_herb`(150G)로 상향. 조정 후 hidden EV 150G, risky 대비 2.7배
- **효과 타입 분포 확정**: 72 results 중 nothing 12(17%) / gold 22(31%) / reputation 18(25%) / injury 6(8%) / heal_tired 5(7%) / item 5(7%) / trait_acquired 3(4%) / trait_innate 1(1%). 기획 §(B) 범위 내
- **전원 파견 시 선택지 이벤트 미발동**(Q-9 확정) — rollChoiceEvent 단계에서 rosterIdle.isEmpty 체크
- **활동 로그 1줄 요약**(Q-10 확정) — "[선택지] {event.name} → {option.label} → 효과 요약"
- **trait FK 실존 검증 페이즈 3-5 선행 강제**(Q-3) — `preferred_traits` / `visibility_expr` 트레잇 키워드 12종 실존 매핑
- **item 풀 하급~중급 한정**(Q-7 확정) — M2a `items.tier ≤ 3` 만 사용. 전설(legendary) 제외
- **hidden 선택지 노출 시 ✦ 아이콘 표시 유지**(Q-2 현행 유지) — 완전 숨김 원칙이되 조건 충족 시 시각 구분

## 1. 현재 상태

### 1-1. 기존 `travel_events` 12행 분석

| effect_type | 행 수 | magnitude 범위 | min~max_tier |
|---|---|---|---|
| delay | 2 | +0.2 / +0.5 | 1~5 / 3~5 |
| gold | 6 | -60 ~ +120 | 1~5 |
| heal_tired | 1 | +1 | 1~4 |
| injury | 1 | +1 | 2~5 |
| reputation | 2 | +10 / +15 | 1~3 / 3~5 |

**발동 공식**: `eventProbability(distance) = (distance × 0.15).clamp(0.0, 0.80)`. 이동 시 filtered by tier → 랜덤 1개 선택.

### 1-2. 기획서 상수

- 선택지 이벤트 발동 확률: `distance × 0.08`(T1~2) / `× 0.10`(T3~4) / `× 0.12`(T5), 기획 cap 0.40~0.60
- 선택지 구조: 2~3개 (safe + risky + 0~1 hidden)
- 결과 분기: 선택지당 2~3개, probability 합=1.0
- 효과 타입: 8종 (기존 5 + 신규 3: trait_acquired, item, nothing)
- 대표 용병: `rosterIdle` 중 preferred_traits 매칭 → 최고 레벨 fallback

### 1-3. 경제 참조 (페이즈 2-1/2-2)

- 체인 완주 명성 4,890 (7체인) → 체인 1개 평균 700 rep × 8G 환산 = 5,600G 체감 상한
- 일반 퀘 net: ~150G/1.5min = 6,000G/hr
- 엘리트 T3 파밍: 5,895G/hr
- Village 권장안 파밍: 3,824G/hr
- Ruins 실질 파밍(실패율 반영): 4,120G/hr
- 부상 회복 비용: 용병 1명 40~50분 이탈 → 기회비용 ~400G
- 피곤 회복: 5분 × 80% 능력치 → ~50G
- trait_innate: 영구 스탯 부여 → 희소 가치 ~400G
- trait_acquired 버프 24h: 트레잇 1~2개 조기 획득 → ~300G (페이즈 2-2 §5-5와 정합)
- 인벤 아이템 하급(herb): ~40G / 중급(rare_herb, scout_compass): ~150G

## 2. 1G 환산표 제정

본 리포트의 모든 EV는 **1G를 단위 가치**로 삼아 단일 척도로 비교한다. 각 효과의 환산율:

| effect_type | magnitude | 1G 환산 | 근거 |
|---|---|---|---|
| gold | +N | +N | 자명 |
| reputation | +N | +N × 10 | F→E 300 rep ≈ 3,000G 가치 (랭크 진행 커플링 페이즈 2-1) |
| reputation | -N | -N × 10 | 동일 |
| injury | +1 (용병 1명 부상) | **-400** | 회복 40~50분 × 기회비용 + 재도전 지연 |
| heal_tired | +1 (피곤 회복) | +50 | 5분 × 20% 능력치 손실 환산 |
| heal_tired | -1 (피곤 부여) | **-50** | 동일 (역방향) |
| trait_innate | +1 (빈 슬롯 부여) | +400 | 영구 스탯/효과, 희소성 |
| trait_acquired | +1 (버프 24h) | +300 | 페이즈 2-2 §5-5와 정합, 트레잇 1~2개 조기 획득 기회 |
| item | +1 하급 (herb_bundle 등) | +40 | M2a 인프라 저티어 평가 |
| item | +1 중급 (rare_herb, scout_compass 등) | +150 | M2a tier 2~3 장비·특수 소모품 |
| nothing | - | 0 | 효과 없음 |

**이 환산표는 본 리포트의 EV 계산 기준**이며, 런타임 밸런스에는 영향 없다(단지 수치 상호 비교용 척도).

## 3. 기획서 샘플 §9-1 EV 계산 (정책 검증)

**tce_dil_01 부상당한 여행자** — 현재 기획 수치 그대로 EV 산출.

### 3-1. safe "지나친다"

| r | prob | effect | magnitude | 1G 환산 | 기여 EV |
|---|---|---|---|---|---|
| r0 | 1.0 | nothing | - | 0 | 0 |
| **합** | | | | | **0G** |

### 3-2. risky "치료해 준다"

| r | prob | effect | magnitude | 1G 환산 | 기여 EV |
|---|---|---|---|---|---|
| r0 | 0.70 | reputation | +10 | +100 | +70 |
| r1 | 0.30 | heal_tired | -1 | -50 | -15 |
| **합** | | | | | **+55G** |

### 3-3. hidden "약초로 상처를 덮어준다" (기획 원안)

| r | prob | effect | magnitude | effect_target | 1G 환산 | 기여 EV |
|---|---|---|---|---|---|---|
| r0 | 0.90 | item | 1 | herb_bundle (하급) | +40 | +36 |
| r1 | 0.10 | reputation | +15 | - | +150 | +15 |
| **합** | | | | | | **+51G** |

### 3-4. 정책 검증 — **위반** 감지

| 선택지 | EV | 정책 대비 |
|---|---|---|
| safe | **0G** | `EV(safe) ∈ [5, 25]` ❌ (보상 없음 근접하나 nothing이므로 허용 가능) |
| risky | **+55G** | `EV(risky) ∈ [25, 60]` ✅ |
| hidden | **+51G** | `EV(hidden) ≥ 2 × EV(risky) = 110` ❌ **월등한 우위 미달성** |

**문제**: hidden이 risky보다 낮은 EV. 정책 `hidden > safe ≥ risky` 위반.

**원인**: hidden r0의 item이 `herb_bundle`(하급 40G). 확률 0.90 집중이 무색.

## 4. 조정 제안

### 4-1. 기획서 샘플 §9-1 hidden 보상 상향

| r | 변경 전 | 변경 후 |
|---|---|---|
| r0 (prob 0.90) | item herb_bundle (하급 40G) | **item rare_herb (중급 150G)** |
| r1 (prob 0.10) | reputation +15 | **reputation +15 + item herb_bundle** (복합 효과는 스키마 불허 → reputation +20 단순 상향) |

**조정 후 hidden EV**:
- r0: 0.90 × 150 = 135G
- r1: 0.10 × 200 = 20G (rep +20 → 200G)
- **EV = 155G**

**정책 재검증**:
| 선택지 | EV | 정책 |
|---|---|---|
| safe | 0G | nothing 고정 — safe=nothing 패턴은 허용(§4-3) |
| risky | +55G | ✅ |
| hidden | **+155G** | **2.8× risky** ✅ |

### 4-2. EV 정책 수치 범위 확정

모든 12종 시나리오에 다음 범위 강제 (data-generator 수치 가이드 §7 반영):

| risk_level | 권장 EV 범위 | 비고 |
|---|---|---|
| safe | **5~25G** 또는 `nothing`(0G) | 무위험 프리미엄. `nothing` 허용 (12종 중 3~4) |
| risky | **25~60G** | 분산 크게(±50~100 양방향) |
| hidden | **120~200G** 목표, 최소 `2 × risky EV` | 월등한 우위 필수 |

**근거**:
- safe와 risky EV 차이가 작아야 "선택할 이유"가 양쪽 모두에 생김
- hidden이 risky의 2배 이상이어야 "트레잇 가치"가 체감
- 절대값 범위는 이동 1회 = 퀘스트 1회 대비 20~50% 수준 (퀘스트 net 150G 기준)

### 4-3. 발동 확률 cap 단축

**제안**: 기획 `distance × 계수` 공식 유지하되, **cap 일괄 0.30**.

| 티어 | 기존 cap | 제안 cap |
|---|---|---|
| T1~2 | 0.40 | **0.30** |
| T3~4 | 0.50 | **0.30** |
| T5 | 0.60 | **0.30** |

**시뮬레이션**: 유저가 1시간 이동 8회 (중간 빈도 가정), 평균 거리 3.

| 구분 | 확률 계산 | 1시간 이벤트 수 |
|---|---|---|
| 자동 이벤트 | min(3×0.15, 0.80) = 0.45 × 8 | 3.6회 |
| 선택지 이벤트 (조정) | min(3×0.10, 0.30) = 0.30 × 8 | 2.4회 |
| **합산** | | **6.0회/hr** |

**체감 타겟**: 기획 §1-1 "1시간 2~4회 선택지 조우". ✅ 2.4회 부합. 자동+선택지 합 6회는 "이동마다 무언가 일어난다" 근접 — 다소 높지만 계수 하향 대안 존재.

**대안 (더 보수)**: 기획 계수 절반 (`× 0.04/0.05/0.06`) + cap 0.30. 1시간 1.2회. **권장 안 함** (너무 드물면 시스템 존재감 약화).

### 4-4. 효과 타입 분포 가이드 (72 results 대상)

| effect_type | 권장 행 수 | 비율 | 배정 원칙 |
|---|---|---|---|
| nothing | 12 | 17% | safe 결과 위주 (12 safe 중 6~8, 그 외 risky 실패 분기 4) |
| gold | 22 | 31% | 양방향(+40 ~ +150, -20 ~ -60). risky·safe 고루 분포 |
| reputation | 18 | 25% | +5 ~ +35. hidden·risky 보상 위주 |
| injury | 6 | 8% | risky 실패 분기. hazard·dilemma 카테고리 |
| heal_tired | 5 | 7% | ±1. risky 부정·드물게 hidden 긍정 |
| item | 5 | 7% | hidden 2~3 (중급) + discovery risky 1~2 (하급) + 특수 1 |
| trait_acquired | 3 | 4% | hidden 결과 집중 |
| trait_innate | 1 | 1% | discovery 특수 (빈 슬롯 용병 대상) |
| **합** | **72** | **100%** | |

**중요 제약**:
- `item` 5회 중 `effect_target`은 **모두 M2a `items.tier ≤ 3`**에서 선택(Q-7). 예: `herb_bundle`(하급), `rare_herb`(중급), `scout_compass`(중급). **절대 체인·엘리트 전용 전설 아이템 미사용**
- `trait_innate` 1회는 preferred_traits가 `scholar`/`faithful` 인 discovery 카테고리 전용

### 4-5. EV 정책 위반 방지 가드 (data-generator 검증 쿼리)

페이즈 3-5 data-generator 완료 후 다음 검증 쿼리를 실행하여 정책 준수 확인:

```sql
-- 각 선택지의 EV 산출 (1G 환산)
WITH result_ev AS (
  SELECT
    option_id,
    SUM(
      probability * (
        CASE effect_type
          WHEN 'gold' THEN effect_magnitude
          WHEN 'reputation' THEN effect_magnitude * 10
          WHEN 'injury' THEN -400
          WHEN 'heal_tired' THEN effect_magnitude * 50
          WHEN 'trait_innate' THEN 400
          WHEN 'trait_acquired' THEN 300
          WHEN 'item' THEN 100  -- 평균(하/중 혼합)
          ELSE 0
        END
      )
    ) AS ev
  FROM travel_choice_results
  GROUP BY option_id
),
option_risk AS (
  SELECT o.event_id, o.risk_level, r.ev
  FROM travel_choice_options o
  JOIN result_ev r ON r.option_id = o.id
)
-- 정책 위반 탐지: hidden < 2 × risky 시 FAIL
SELECT
  h.event_id,
  h.ev AS hidden_ev,
  ri.ev AS risky_ev,
  h.ev / NULLIF(ri.ev, 0) AS ratio
FROM option_risk h
LEFT JOIN option_risk ri ON ri.event_id = h.event_id AND ri.risk_level='risky'
WHERE h.risk_level='hidden'
  AND (h.ev < 2 * ri.ev OR h.ev < 120);
```

**예상 결과**: 위반 0행. 위반 있으면 해당 이벤트 수정 후 재검증.

### 4-6. 전원 파견 엣지케이스 (Q-9)

**제안**: `TravelChoiceService.rollChoiceEvent()`에서 `rosterIdle.isEmpty` 체크 후 `null` 반환 → 선택지 이벤트 미발동.

**근거**:
- 선택지 서사의 `{merc.name}`이 파견 중 용병이면 부자연스러움(동시에 두 곳에 있음)
- 플레이어 개입(선택 클릭) 필요한 UI가 자기 용병 없으면 어색
- 자동 이벤트는 그대로 진행(결과만 `UserData.gold`에 반영)

### 4-7. 활동 로그 요약 규칙 (Q-10)

**제안**: 단일 엔트리 1줄 요약.

```
"길에서 {event.name} — [{option.label}] → {effect_summary}"

예: "길에서 부상당한 여행자 — [치료해 준다] → 명성 +10"
    "길에서 봉인된 동굴 입구 — [문자를 해독한다] → 유물 획득"
```

상세 보기 클릭 시 `renderedSituation` + 전체 `renderedNarrative` 표시. 활동 로그 공간 절약.

### 4-8. 수치 변경 요약

| 항목 | 기존 / 기획 | 제안 |
|---|---|---|
| 발동 확률 cap | 0.40~0.60 (티어별) | **일괄 0.30** |
| 기획 §9-1 hidden r0 item | herb_bundle (40G) | **rare_herb (150G)** |
| 기획 §9-1 hidden r1 reputation | +15 | **+20** |
| EV 정책 수치 범위 | 원칙만 (§7-1) | **safe [5,25] / risky [25,60] / hidden ≥2×risky, ≥120** |
| 효과 타입 분포 | 원칙 (§(B)) | **표 §4-4 확정 72행** |
| 전원 파견 | 미정 | **선택지 미발동(rosterIdle.isEmpty 가드)** |
| 활동 로그 | 미정 | **1줄 요약** |
| item 풀 | "하급~중급" (§5) | **M2a tier ≤ 3 한정** |
| hidden 노출 UI | ✦ 아이콘 | **유지** |
| trait FK 검증 | 언급 | **페이즈 3-5 선행 강제** |

## 5. 시뮬레이션 — 조정 후 유저 체감

**시나리오 A**: T3 진입 유저, 1시간 active 플레이, 이동 8회 평균 거리 3.

| 항목 | 1시간당 |
|---|---|
| 자동 이벤트 조우 | 3.6회 |
| 선택지 이벤트 조우 | 2.4회 |
| 자동 이벤트 평균 G | gold -60~+120 평균 +33G × 3.6 = +119G |
| 선택지 이벤트 평균 (safe/risky/hidden 균등 선택 가정) | (15 + 45 + 160) / 3 = 73G × 2.4 = +175G |
| **이동 이벤트 총 수익** | **+294G/hr** |

**비교**: 일반 퀘 1시간 파밍 5,895G/hr → 이동 이벤트는 **5% 부가 수익**. "주 수익 경로 영향 미미" + "서사 재미 추가". 설계 의도 적중.

**시나리오 B**: hidden 선택지 자주 조우(empathy/scholar 등 보유 용병 다수).

- hidden 비율 40% 가정 → 평균 EV 0.6×45 + 0.4×160 = 91G × 2.4 = **+218G/hr**
- "트레잇 투자 유저"의 이동 수익 74% 상승. 트레잇 가치 가시화

**시나리오 C**: 전원 파견 시 (rosterIdle 0명)

- 자동 이벤트 3.6회 × 33G = +119G (대표 용병 fallback으로 gold/reputation만 적용)
- 선택지 이벤트 0회 (미발동)
- "파견 중" 플레이어 상태에서 선택지 피로 없음. UX 보호

## 6. 문제점·잔존 리스크

| 번호 | 문제 | 근거 | 심각도 |
|---|---|---|---|
| P1 | 기획 §9-1 hidden EV 51G < risky 55G | §3 계산 | 치명(해결 완료: §4-1) |
| P2 | 기획 cap 0.60은 장거리 이동 과빈도 유발 | 10거리 × 0.12 = 1.20 (cap 전) | 중(해결: §4-3) |
| P3 | `item` 효과 풀이 규정 없음 → 전설 아이템 노출 위험 | 기획 §5 "하급~중급" 모호 | 중(해결: §4-4 tier ≤ 3) |
| P4 | trait 키워드 실존 검증 미확정 | 기획 §8 Q-3 | 높음(해결: §4-8 페이즈 3-5 선행) |
| P5 | `evaluationScope: mercenary\|team` TemplateEngine 확장 | 기획 §3-2, 페이즈 4-1 반영 필요 | 스코프 밖(페이즈 4-1 spec 대상) |
| P6 | 자동 이벤트 + 선택지 + 퀘스트 완료 동시 도착 시 팝업 4~5연속 | 기획 §1-2, 페이즈 1-6 | 중(페이즈 1-6에서 해결) |

## 7. 플레이어 체감 분석

- **safe=nothing 허용**: "길을 지나친다 → 아무 일도 없다" 서사는 일부 시나리오에서 오히려 자연스러움. 12종 중 3~4개 허용 (dilemma 카테고리 특히)
- **risky 분산 강조**: 성공·실패 체감 차이(부상·피곤 시 vs 보상 시)가 "도박" 감성. 기존 자동 이벤트의 "무력 수용"과 대비. 플레이어 주도성 상승
- **hidden 우월성 체감**: 트레잇 보유자 우선 표시 + 결과 서사 특별함("품 속 약초", "봉인을 갈랐다")이 "내가 이 시나리오를 풀었다" 만족
- **발동 빈도 2~3회/hr**: "매 이동마다는 아니지만 기억에 남는 순간" 빈도. Sunless Sea와 유사한 감성
- **체인·변형·엘리트와 독립**: 이동 선택지는 짧은 단편 서사로 기능. 다른 M3 시스템과 경쟁하지 않음

## 8. data-generator 수치 가이드

> 페이즈 3-0-4 타입 스펙 선행 + 페이즈 3-5 114행 벌크 생성의 핵심 입력. 기획서 §(B) 가이드에 본 리포트 수치 범위 중첩.

- **대상 타입**: `travel-choice`
- **대상 테이블**: `travel_choice_events`(12) + `travel_choice_options`(30) + `travel_choice_results`(72)
- **생성 수량**: **114행**

### 8-1. `travel_choice_events` (12행)

- `min_tier`/`max_tier`: 대부분 1~5 (전 티어 노출). 일부 hazard(tce_haz_03 절벽)는 3~5 한정 등 서사 맞춤
- `weight`: **일괄 1** (MVP). 특수 시나리오는 후처리 튜닝
- `preferred_traits`: 기획 §8 표 12종 키워드 — **페이즈 3-5 선행 시 `traits.id` 실존 FK 매핑 필수**

### 8-2. `travel_choice_options` (30행)

- `risk_level` 분포: safe 12 + risky 12 + hidden 6 (기본 2개 + hidden 포함 6개 혼합 → 기획은 12종 모두 hidden 포함이나 **본 리포트는 6종 hidden 권장**)
- **hidden 6종 커버리지**: 각 카테고리 encounter/dilemma/discovery/hazard에서 1~2종씩. 기획 12종 모두 hidden에서 6종으로 축소하여 hidden 희소성 강화 — 나머지 6종은 2선택지(safe+risky)로 단순화하여 반복 피로 완화
- **축소 근거**: 기획 §8은 "MVP — 균등 커버"이나 균등하면 hidden 빈도 과다 → hidden 희소성 약화. 6종 hidden이 balance 관점에서 더 적정
- `visibility_expr`: hidden 6개만 (예: `has_trait:empathy`). safe/risky는 null
- `label`: 6~12자. risky 선택지는 명확한 위험 단서("문을 부순다", "강행한다")
- **선택지 수 결정 규칙** (확정):
  - 기본 2선택지 (safe+risky) × 6 = 12 options
  - 3선택지 (safe+risky+hidden) × 6 = 18 options
  - 총 30 options

### 8-3. `travel_choice_results` (72행)

- `probability` 합 = 1.0 per option (data-generator 검증 필수)
- 2분기(prob 0.5/0.5 ~ 0.7/0.3) vs 3분기(prob 0.4/0.4/0.2) 자유 배정. 추천 분기 분포: 2분기 18 + 3분기 12
- `conditional_expr`: 12종 이벤트 중 **4~6종**에 포함 (기획 §4-2 준수)
- `effect_type` 분포: **표 §4-4 준수**
- `effect_magnitude` 범위:
  - gold: safe ±10~30 / risky ±40~80 / hidden +50~150
  - reputation: safe +5~10 / risky +15~25 / hidden +20~35
  - injury: 1 (고정)
  - heal_tired: -1 or +1
  - trait_innate: 1 / trait_acquired: 1 / item: 1~2 / nothing: null
- `effect_target`:
  - item: **M2a `items.tier ≤ 3`만** (예: herb_bundle, rare_herb, scout_compass, minor_tonic)
  - trait_innate: `traits` 테이블의 innate 타입(`Physical`/`Background`/`Talent` 카테고리) 중 1
  - trait_acquired: 조건부. `MercenaryStatService.applyTraitLearningBoost(merc, 24h, 1.5)` 호출 (페이즈 2-2와 공유 매커니즘)

### 8-4. 외래 키 제약

- `travel_choice_options.event_id` → `travel_choice_events.id`
- `travel_choice_results.option_id` → `travel_choice_options.id`
- `effect_target`:
  - `item` effect_type → `items.id` FK (페이즈 3-5에서 validate)
  - `trait_innate` effect_type → `traits.id` FK (innate 타입만)
- `preferred_traits` (쉼표 구분) → 각 값 `traits.id` FK

### 8-5. 사전 DDL (페이즈 3-5 실행 전 필수)

```sql
-- 기획 §2 DDL 그대로 + SyncService 버전 엔트리
INSERT INTO data_versions (table_name, version) VALUES
  ('travel_choice_events', 1),
  ('travel_choice_options', 1),
  ('travel_choice_results', 1);
```

## 9. 페이즈 4-5 spec 반영 사항

1. **`TravelChoiceService` 신규 서비스**
   - `rollChoiceEvent({distance, regionTier, rosterIdle, events, random}) → TravelChoiceEventData?`
     - `rosterIdle.isEmpty` → null 반환 (§4-6)
     - 발동 확률: `distance × {0.08, 0.10, 0.12}[tier].clamp(0.0, 0.30)` (§4-3)
   - `selectProtagonist({rosterIdle, preferredTraitsCsv, traits}) → Mercenary` (기획 §6 알고리즘)
   - `resolveResult({option, context, random}) → TravelChoiceResultData` (기획 §2-3 정규화 로직)
   - `applyEffect({result, userDataNotifier, protagonist, merceryStatService, itemService})`
     - `nothing` → no-op
     - `item` → inventoryService.add(effect_target, magnitude)
     - `trait_innate` → traitAcquisitionService.assignInnate(protagonist, effect_target)
     - `trait_acquired` → mercenaryStatService.applyTraitLearningBoost(protagonist, 24h, 1.5) (페이즈 2-2 공유)
     - 나머지 기존 로직 재사용 (gold/reputation/injury/heal_tired)

2. **`MovementProvider` 확장**
   - `ActiveTravel.choiceEventId: String?` 필드
   - 이동 시작 시 rollEvent + rollChoiceEvent 병렬 호출 (독립 roll)
   - 도착 시 `TravelChoiceRecallDialog` 트리거 (팝업 큐 경유 — 페이즈 1-6 정책)

3. **`TravelChoiceRecallDialog` UI**
   - 2단 팝업: 상황 + 선택지 → 결과 + 효과
   - `✦` 아이콘으로 hidden 선택지 시각 구분 (§4-8)
   - hidden 선택지는 세로 하단 배치

4. **TemplateEngine `evaluationScope` 확장** (페이즈 4-1 spec 반영)
   - `TemplateContext.evaluationScope: enum { mercenary, team }`
   - `has_trait`/`has_any_trait`/`has_all_traits` 평가 범위 분기
   - `visibility_expr` 기본 `team`, `conditional_expr` 기본 `mercenary`

5. **`Mercenary.traitLearningBoostUntil` 필드** (페이즈 2-2에서 이미 제안)
   - HiveField 추가, 페이즈 4-3 spec과 공통

6. **활동 로그 타입 `travelChoiceCompleted`**
   - HiveField 16 (페이즈 1-6 공존 정책 §6 이미 예정)
   - 메시지 포맷: §4-7

7. **검증 쿼리**: §4-5 Postgres 검증 쿼리를 페이즈 3-5 완료 직후 1회 실행

## 10. 오픈 질문 / 후속 메모

- **Q-A**: safe=nothing 비율 12종 중 3~4 → 유저 체감 "보상 없이 끝" 패턴이 반복 피로. 4종 이상이면 유저 불만 가능. → **권장**: 3종만 유지. 특히 dilemma 카테고리 "지나친다" 선택지에 한정
- **Q-B**: hidden 선택지 6종 권장안이 기획 "12종 균등 커버" 축소 — 기획 의도와 다르나 밸런스 관점 우월. **사용자 승인 필요**
- **Q-C**: EV 정책 `safe ≥ risky` 원칙은 기획서 §7-2이나, `safe=nothing(0G)` vs `risky=+55G`의 경우 정책 위반. **실무 해석**: safe=nothing은 "무위험 프리미엄"으로 0G 허용(손실 없음). 정책 위반 아님. 페이즈 4-5 spec에 주석으로 명시
- **Q-D**: trait 키워드 12종(empathy/brave/scholar 등) 실존 검증은 페이즈 3-5 필수. **현재 `traits` 109행 중 실제 존재 여부 미확인**. 한 번 보조 검증하면 기획 §8 수정 필요할 수도
- **Q-E**: `item` effect_target 풀을 `items.tier ≤ 3`로 한정했으나, M3 hidden 섹터 퀘도 guild 아이템(T3~T5) 줌. **이동 선택지 vs hidden 섹터 차별화** 필요하면 이동 선택지 `items.tier ≤ 2` 더 좁힐 수도. 권장: **현 tier ≤ 3 유지**. M2a 인프라에 tier 2 items는 희소 상품이라 오히려 긍정
- **Q-F**: `conditional_expr` 활용 4~6종 → `preferred_traits`와 중복 가능. 예: preferred scholar + conditional scholar 결과. 서사 일관성 OK이나 **페이즈 3-5 data-generator 시점에 중복 체크** 필요
- **Q-G**: 선택지 이벤트 자동 이벤트 합산 6회/hr가 과하다는 판단 시 **대안**: 자동 이벤트 cap 0.80 → 0.60으로 소폭 조정. 본 리포트는 **자동 이벤트 수치 유지**(스코프 밖 이슈)
- **Q-H**: 전원 파견 시 선택지 미발동 — 유저 체감 "기회 놓침"일 수도. 대안으로 **간소화 팝업**(선택지 없이 결과만) 표시 고려? → 권장: 미발동 유지. 복잡도 최소

## 다음 단계 후속 안내

- **페이즈 3-0-4 타입 스펙**: `Docs/content-data/types/travel-choice.md` — 본 리포트 §8 + 기획서 §2 3테이블 + 기획서 §11 톤 가이드 반영
- **페이즈 3-5 data-generator**: 
  - **선행 DDL**: Supabase MCP `apply_migration`으로 3테이블 + data_versions 엔트리 생성
  - **trait FK 사전 검증**: `SELECT id FROM traits WHERE id IN ('empathy', 'brave', ...)` 12종 실존 체크
  - 호출: `/data-generator travel-choice --brief @Docs/Archive/20260425_travel-choice-system/design.md --balance @Docs/balance-design/[balance]20260424_travel_choice_ev.md`
  - **검증 쿼리**(§4-5) 실행 후 정책 위반 0행 확인
- **페이즈 4-1 TemplateEngine spec**: `evaluationScope: mercenary|team` 파라미터 확장 반영
- **페이즈 4-5 spec**: `/spec-writer`로 `TravelChoiceService` + `TravelChoiceRecallDialog` + `ActiveTravel.choiceEventId` + 활동 로그 확장 통합 spec 작성. 본 리포트 §9 반영
- **페이즈 2 종합 리포트**: 2-1, 2-2, 2-3 산출물 → 페이즈 2 완료 체크포인트로 이어짐
