# M7 지역 상태 변화 임계값 확정 밸런스 분석 리포트

> 작성일: 2026-05-17
> 유형: 밸런스 분석 + 수치 조정 제안 (M7 마일스톤 — 페이즈 2 산출물 2/3)
> 분석 대상: dangerScore 4단계 경계, 트리거 점수 가감량, 7리전 초기값, QuestGenerator 4×4 가중치 매트릭스, 플래그별 추가 가중치, decay 시간, 명성 통합
> 선행 문서:
> - `Docs/content-design/[content]20260516_m7_region_state_rules.md` — M7 페이즈 1 #2, 컨셉 4단계 + 트리거 3종 + 7리전 초기값 + 가중치 매트릭스 컨셉
> - `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md` — M7 페이즈 1 #4, 5~8시간 흐름 dangerScore 변화 곡선 2절
> - 현재 `difficulties` 5단계 + `quest_pools` 332행 D1~D10 분포 + `ranks` 6단계
>
> 후속:
> - 페이즈 3 #4 "지역 상태별 퀘스트 풀 30~50개" — 본 문서의 가중치 매트릭스 + 플래그 가중치를 입력으로 받아 quest_pools 신규 컬럼 + 행 INSERT
> - 페이즈 4 #1 "RegionState 모델 확장 + 지역 상태 시스템" — 본 문서의 임계값·가감량 상수를 코드 상수로 매핑
> - 페이즈 4 #2 "QuestGenerator 지역 상태 가중치 분기" — 본 문서의 4×4 매트릭스 + 가중치 계산 의사 코드 구현 입력

---

## 현재 상태

### 1. 페이즈 1 #2 컨셉 (정량화 대상)

**dangerScore 4단계 컨셉**:
- stable: -100 ~ -50
- peaceful: -49 ~ -1 (기본값 0은 tension 진입 직전)
- tension: 0 ~ +49
- threat: +50 ~ +100

**트리거 3종 권장량**:
- 누적: 같은 quest_pool/quest_type N회 완료, 회당 -10, cap -50 (한 flag당)
- 단발: 특정 사건 1회, -30 ~ -50 변동량 + unlockedFlags 토글
- decay: dangerScore가 음수일 때 N시간마다 +1

**7리전 초기값**:
- r3 0 / r31 +15 / r127 -10 / r9 +20 / r10 +10 / r146 +30 / r38 +60
- 평균 +17.86

**QuestGenerator 가중치 매트릭스** (페이즈 1 #2 4.1절):
- threat raid +200% / tension raid +100% / peaceful raid 기본 / stable raid -70%
- 단, 4단계 × 4 quest_type 16 셀 중 일부만 명시. 본 문서에서 전수 정량화.

### 2. 현재 게임 시스템 수치 (Supabase 실측)

**difficulties 5단계**:

| level | enemy_power | reward_x | min_cost | max_cost | injury | death |
|-------|------------|----------|----------|----------|--------|-------|
| 1 | 10 | 1.0× | 5 | 30 | 10% | 5% |
| 2 | 20 | 1.5× | 10 | 60 | 20% | 10% |
| 3 | 35 | 2.2× | 20 | 100 | 30% | 15% |
| 4 | 55 | 3.2× | 35 | 150 | 45% | 22% |
| 5 | 80 | 4.5× | 50 | 200 | 60% | 30% |

**quest_types 6종** (base_reward):
- raid: 100G / hunt: 120G / escort: 90G / explore: 80G / labor: 50G / survey: 0G

**ranks 6단계** (T2 잠금 명성 300 — content_status.md의 500은 구식, 실제 데이터 300):
- F: 0 / E: 300 (T2) / D: 2,000 (T3) / C: 8,000 (T4) / B: 25,000 (T5) / A: 80,000

**quest_pools 332행 D1~D5 분포** (M7 핵심 구간):

| quest_type | D1 | D2 | D3 | D4 | D5 | 소계 |
|------------|----|----|----|----|-----|------|
| escort | 9 | 11 | 11 | 19 | 14 | 64 |
| explore | 12 | 7 | 9 | 19 | 19 | 66 |
| hunt | 11 | 10 | 15 | 13 | 20 | 69 |
| labor | 9 | 2 | 1 | 0 | 0 | 12 |
| raid | 3 | 8 | 7 | 13 | 19 | 50 |
| survey | 0 | 0 | 1 | 0 | 0 | 1 |
| **합계** | 44 | 38 | 44 | 64 | 72 | **262** |

→ M7 7리전 T1~T3 = D1~D3 구간이 핵심 (총 126행). D4~D5는 region 38 한정 + T4 진입 대비 (M7 외 영역).

---

## 데이터 분석

### 1. dangerScore 4단계 경계 검증 (균등 vs 비대칭)

**옵션 A — 균등 분포 (페이즈 1 #2 권장)**:
- stable: -100 ~ -50 (50점 폭)
- peaceful: -49 ~ -1 (49점 폭)
- tension: 0 ~ +49 (50점 폭)
- threat: +50 ~ +100 (51점 폭)

**옵션 B — 비대칭 분포 (체감 우선)**:
- stable: -100 ~ -60 (41점 폭, 가장 좁음 — 도달 어려움)
- peaceful: -59 ~ -10 (50점 폭, 일반)
- tension: -9 ~ +49 (59점 폭, 회색지대 흡수 — 가장 넓음)
- threat: +50 ~ +100 (51점 폭)

| 항목 | A (균등) | B (비대칭) |
|------|---------|----------|
| 단순함 | ✅ | ❌ |
| stable 도달 난이도 | 중 (-50 도달) | 고 (-60 도달, 한 단발 사건으론 부족) |
| tension 회색지대 흡수 | ❌ (0 = 즉시 tension) | ✅ (-9~0 = "긴장 임박") |
| 운영 도구 가시성 | ✅ | 중 |

**채택: 옵션 A (균등)**. 이유:
- 페이즈 1 #2 5.4절에서 결정된 "단순함 우선" 원칙
- 단발 사건 -50 시 stable 도달 가능 (단조로움) — 의도된 동작 (region 146 안개 해소처럼 큰 변화)
- 운영 도구·디버그 친화적 (50/50/50/50 명료)

### 2. 단계 전이 시뮬레이션 (옵션 A 기준)

페이즈 1 #4 5~8시간 흐름 + 페이즈 1 #2 트리거 3종 적용 시 7리전 변동 곡선:

| 시점 | r3 | r31 | r127 | r9 | r10 | r146 | r38 |
|------|-----|-----|------|-----|-----|------|-----|
| **0분 (M7 시작)** | 0 (peaceful) | +15 (tension) | -10 (peaceful) | +20 (tension) | +10 (tension) | +30 (tension) | +60 (threat) |
| **120분 (M4 종료)** | -30 (peaceful, 폐광 step6 완료 -30) | +15 | -10 | +20 | +10 | +30 | +60 |
| **170분 (Tier 2 진입)** | -30 | -15 (roadside_shrine 완주 -20, peaceful) | -15 (info 조사 -5) | +20 | +10 | +30 | +60 |
| **240분 (T2 잠금 해제)** | -30 | -25 (도적 2회 -20) | -25 (조사 추가) | +10 (의뢰 1회 -10) | +10 | +30 | +60 |
| **300분 (Tier 3 진입)** | -30 | -50 (cap 도달, stable) | -45 (친교 완료 -20, peaceful) | -30 (야수 처치 -40, peaceful) | +10 | +30 | +60 |
| **360분 (T3 잠금 해제)** | -30 | -50 | -45 | -30 | -20 (windrunner 완주 -30) | +30 | +40 (도굴꾼 -10 + 1단계 -10) |
| **420분 (Tier 4 진입)** | -30 | -50 | -45 | -30 | -20 | +20 | 0 (ironbound 완주 -40) |
| **480분 (M7 종료)** | -30 | -50 | -45 | -30 | -20 | -50 (mist_cleared -50) | 0 |

**평균 변동**: +17.86 (시작) → -25 (M7 종료). 5시간 시점 평균 -19, 8시간 시점 평균 -25 ✅ (페이즈 1 #4 추정 -27.86과 ±3 일치)

**4단계 분포 변화**:
- 시작: threat 1 (r38) / tension 4 (r31·9·10·146) / peaceful 2 (r3·r127)
- 5시간: stable 1 (r31) / peaceful 4 (r3·127·9·10) / tension 1 (r146) / threat 1 (r38)
- 8시간: stable 3 (r31·127·146) / peaceful 3 (r3·9·10) / tension 0 / threat 0 (r38는 0=tension 경계 — peaceful 진입 직전)

→ M7 종료 시점 전반적 평온화 + 일부 stable 도달 ✅

### 3. 트리거 점수 가감량 정량화 (단발 사건 등급 분리)

페이즈 1 #2 권장 -30 ~ -50을 사건 등급별로 세분화:

| 사건 등급 | 점수 변동 | 예시 |
|----------|---------|------|
| **소형 단발** | -10 ~ -15 | 일반 의뢰 1회 (cumulative cap 도달 후), 체인 1단계 진행 |
| **중형 단발** | -20 ~ -25 | 일반 엘리트 처치, 체인 완주, 정기 사건 1회 |
| **대형 단발** | -30 ~ -40 | 유니크 엘리트 처치, 거점 사건 step 6, M7 7리전 사건 1회 |
| **특수 단발** | **-50** | M7 7리전 핵심 사건 (region 146 안개 해소 등) — stable 직행 가능 |

**누적 트리거 정량**:
- 회당 -10 (페이즈 1 #2 권장 유지)
- cap_per_threshold -50 (5회로 cap 도달) — 1 flag 토글당 5회 의뢰가 적정 학습 곡선

**검증 — region 31 도적 사건**:
- 초기 +15 → 5회 cumulative (-50) → -35 → 다음 의뢰 1회 -10 → -45 (peaceful)
- bandits_cleared flag 토글은 5회 cap 도달 시점에 단발 -5 추가 → -50 (stable 임계 정확)
- 또는 cumulative 5회 cap + 단발 -10 추가 = -55 → stable 안정 진입

**최종 권장**: cap 도달 시 flag 자동 토글 + 추가 -10 보너스 (stable 진입 보장).

### 4. 시간 경과 재증가 (decay) N시간 정량

페이즈 1 #2 권장 "음수일 때 N시간/+1". N 결정 옵션:

| N | 8시간 누적 영향 | 24시간 후 영향 | 72시간 후 영향 | 권장도 |
|---|---------------|--------------|--------------|-------|
| **4시간** | +2 점수 | +6 | +18 | 너무 빠름 (M7 종료 후 즉시 회귀) |
| **6시간** | +1.3 | +4 | +12 | 적당 |
| **12시간** | +0.7 | +2 | +6 | **권장** |
| **24시간** | +0.3 | +1 | +3 | 너무 느림 (decay 거의 무의미) |

**권장: N=12시간**. 이유:
- 일반 플레이어 4~6시간 세션 내 영향 없음 — M7 핵심 흐름 방해 X
- 24시간 이상 미접속 시 일부 region 회귀 → 재방문 동기
- 시간 가속 ×4 시 실시간 3시간 = 게임 12시간 = +1 점수
- M8+ 반복 플레이 활성화 시 자연스러운 위협 복귀

### 5. QuestGenerator 4×4 가중치 매트릭스 정량화

페이즈 1 #2 4.1절 컨셉 → 절대 multiplier 형식:

| dangerLevel | raid | hunt | escort | explore |
|-------------|------|------|--------|---------|
| **threat** (+50~+100) | **3.0×** | **3.0×** | **1.5×** | **1.5×** |
| **tension** (0~+49) | **2.0×** | **2.0×** | **1.3×** | **1.3×** |
| **peaceful** (-49~-1) | **1.0×** (기본) | **1.0×** (기본) | **1.2×** | **1.0×** (기본) |
| **stable** (-100~-50) | **0.3×** | **0.5×** | **1.5×** | **1.3×** |

**근거**:
- 위협 상태에서 raid·hunt는 사건 의뢰 폭증 (3.0×) — 페이즈 1 #2 +200% = 3.0×와 정합
- 안정 상태에서 raid는 거의 미노출 (0.3×) — 사건 끝난 region에 약탈 의뢰 없음
- 안정 상태에서 escort·explore 증가 (1.5× / 1.3×) — "도적 사라진 길 = 안전한 호위 의뢰 무대" 체감 충실
- peaceful은 기본 (1.0×) + escort 약간 ↑ (1.2×) — 일상적 호위 의뢰 위주

**페이즈 1 #2 권장 +200% / -70% / +50% 등 변화율 → 본 문서 multiplier 형식 변환 매핑**:
- +200% = 3.0× ✅
- +100% = 2.0× ✅
- +50% = 1.5× ✅
- +30% = 1.3× ✅
- +20% = 1.2× ✅
- 기본 = 1.0× ✅
- -50% = 0.5× ✅
- -70% = 0.3× ✅

### 6. 플래그별 추가 가중치 정량화

페이즈 1 #2 4.2절 컨셉 → 8개 flag 모두 정량:

| Flag | quest_type 영향 | multiplier |
|------|---------------|------------|
| `region_3_pyegwang_reopen_completed` | hunt (박쥐 격감) | 0.7× |
| `region_3_pyegwang_reopen_completed` | escort (광부 호위 ↑) | 1.2× |
| `region_31_bandits_cleared` | raid (도적 격감) | **0.3×** |
| `region_31_bandits_cleared` | escort (호위 의뢰 ↑) | **1.5×** |
| `region_31_shrine_quest_completed` | explore (탐험 ↑) | 1.3× |
| `region_127_nomad_friendly` | escort (유목민 호위 ↑) | 1.3× |
| `region_127_nomad_friendly` | raid (적대 의뢰 격감) | 0.5× |
| `region_9_giant_beast_killed` | hunt (대형 야수 처리됨) | 0.5× |
| `region_9_giant_beast_killed` | escort (사냥꾼 동행 ↑) | 1.2× |
| `region_10_windrunner_chain_completed` | explore (정찰 ↑) | 1.3× |
| `region_146_mist_cleared` | explore (시야 확보) | 1.3× |
| `region_146_mist_cleared` | hunt (위협 감소) | 0.7× |
| `region_38_ironbound_pact_completed` | raid (도굴꾼 격감) | **0.5×** |
| `region_38_ironbound_pact_completed` | explore (유적 탐사 ↑) | 1.2× |

**해석**:
- flag 토글 효과는 quest_type 별로 미세 가중치 (0.3× ~ 1.5× 범위)
- raid 가중치 가장 강함 (0.3× / 0.5×) — "사건 해결 후 약탈 의뢰 격감" 체감 핵심
- escort·explore 1.2× / 1.3× 보너스 — 일상 복귀 유도

### 7. 최종 가중치 계산 예시 (4·5·6절 통합)

**region 31, bandits_cleared flag 토글 후 (stable 진입) 의뢰 풀 분포**:

| quest_type | base | stable | flag | 최종 |
|-----------|------|--------|------|------|
| raid | 1.0× | 0.3× | 0.3× | **0.09×** (거의 미노출) |
| hunt | 1.0× | 0.5× | — | **0.5×** |
| escort | 1.0× | 1.5× | 1.5× | **2.25×** (가장 빈번) |
| explore | 1.0× | 1.3× | — | **1.3×** |

**원래 quest_pools D2 분포 (r31 ~ T1 region이므로 D1~D2 위주)**:
- D2 escort 11 / D2 explore 7 / D2 hunt 10 / D2 raid 8 = 36행

**stable + bandits_cleared 상태에서 가중치 적용 후 가시 분포**:
- escort 가중치 (11 × 2.25 = 24.75) → 약 49% 점유
- explore (7 × 1.3 = 9.1) → 약 18%
- hunt (10 × 0.5 = 5.0) → 약 10%
- raid (8 × 0.09 = 0.72) → 약 1.4% (거의 미노출)
- (잔여 19.5% — 일반 풀로 채워짐)

→ **"도적 사라진 도로 = 호위 의뢰 49% 점유"** 체감 충실 ✅

### 8. region 38 threat 상태 시뮬레이션

**region 38 +60 (threat) 초기 의뢰 풀 분포** (M7 페이즈 1 #4 5시간 시점 진입):

D3 분포 (T3 region이므로 D2~D3): D3 raid 7 / D3 hunt 15 / D3 escort 11 / D3 explore 9 = 42행

**threat 상태 가중치**:
- raid (7 × 3.0 = 21) → 약 34%
- hunt (15 × 3.0 = 45) → 약 73% (!) — 페이즈 1 #1 region 38 컨셉 (도굴꾼 위협)과 정합
- escort (11 × 1.5 = 16.5) → 약 27%
- explore (9 × 1.5 = 13.5) → 약 22%

합 95.5% → 정규화 후 약 hunt 47% / raid 22% / escort 17% / explore 14%

→ **"위협 상태 region 38에서는 hunt + raid 의뢰 69% 점유"** 체감 충실 ✅

### 9. 명성과의 통합 (선택적 보너스)

페이즈 1 #2에서 미정의된 부분. 본 문서 검토:

**옵션 A — dangerLevel 명성 보너스 무관 (단순)**:
- 기존 difficulty 기반 명성 가산 그대로 (M3 기존 시스템)
- M7 시스템 도입 부담 ↓

**옵션 B — dangerLevel 명성 보너스 적용**:
- threat 상태에서 의뢰 완료 시 명성 +20%
- stable 상태에서 의뢰 완료 시 명성 -10%
- peaceful/tension 기본

**채택: 옵션 A (단순)**. 이유:
- M7 MVP 부담 최소화 (RankUp 시스템 통합 코드 변경 회피)
- dangerLevel 가중치만으로도 충분한 차별화 (위협 = raid·hunt 의뢰 빈번 = 명성 가산 보상 차원과 자연 정합)
- M8+ 세력 재도입 시 옵션 B 재검토 가능

---

## 문제점

### 1. 페이즈 1 #2 4.1절 +200% 등 표시 모호성

페이즈 1 #2는 "+200%" 표시를 사용했으나 절대 multiplier (3.0×)인지 가산 multiplier (1.0+2.0=3.0×)인지 모호. **본 문서에서 절대 multiplier (3.0×)로 통일** — 운영 도구·코드 입력 시 모호함 제거.

### 2. dangerLevel 진입 알림 빈도 우려

페이즈 1 #2 6.2절에서 "큰 전이만 dialog"로 결정. 본 문서 시뮬레이션 기준 8시간 동안 큰 전이 횟수:

| 시간 | 전이 발생 region | 큰 전이 여부 |
|------|----------------|------------|
| 170분 | r31 tension → peaceful | 인접 (alert 없이 ActivityLog만) |
| 240분 | r9 tension → peaceful (야수 처치 -40) | 인접 |
| 300분 | r31 peaceful → stable, r127 peaceful 유지 (-25→-45) | r31 인접 (alert 없이) |
| 360분 | r10 tension → peaceful (chain -30) | 인접 |
| 420분 | r38 threat → tension (ironbound -40) | 인접 |
| 480분 | r146 tension → stable (mist -50, **건너뛰기**) | **큰 전이 → dialog 발동** |

→ 8시간 동안 dialog 1회만. 적정 빈도 ✅. **단**: r38 threat → peaceful 직행 가능성 (ironbound -40 → +20 (tension) — 인접) 외에 chain reward로 -50 추가 시 r38 threat → peaceful 건너뛰기 발생 가능 → dialog 발동.

### 3. quest_pool 가중치 합산 시 분포 왜곡 우려

가중치 매트릭스 적용 후 일부 quest_type 점유율이 50%+ 되면 다양성 손실:
- region 38 threat: hunt 47% — 다양성 ok
- region 31 stable + bandits_cleared: escort 49% — 한 quest_type 49% 점유, 다양성 일부 손실

**완화 방안**:
- 일반 풀에 sector_type 분기·다른 region 풀이 함께 노출되어 자연 희석
- region_state_required 사용 시 신규 풀 추가 (페이즈 3 #4)로 다양성 회복
- 일반 풀이 적은 region (T1) 위주에서만 한 quest_type 점유율 ↑ — 의도된 결과 (영역별 정체성)

---

## 플레이어 체감 분석

### 1. dangerLevel 변화의 "체감 가능 시점"

플레이어가 dangerLevel 변화를 체감하는 시점은:
- (a) RegionStateChangedDialog 발동 시 (큰 전이) — 8시간 동안 1회 (위 분석)
- (b) ActivityLog 메시지 — 모든 인접 전이에서 발동 (4~6회)
- (c) MovementScreen 카드 색상 변화 — 진입 시 매번
- (d) **의뢰 풀 분포 변화** — 가장 강한 체감 (페이즈 1 #4 시나리오의 외출 동기 강화)

**핵심 체감 모멘트**:
- region 9 야수 처치 직후 (구간 F): "야수가 사라진 숲 = 사냥 의뢰 사라지고 가죽 수집 의뢰 늘었네"
- region 31 도적 5회 후 (구간 G): "도적이 사라진 도로 = 호위 의뢰 폭증 = 명성 빠르게 누적"
- region 38 chain 완주 (구간 I): "위협이 평온해진 폐허 = 탐험 의뢰 위주"

### 2. threat 상태 진입 학습 곡선

페이즈 1 #4 시뮬레이션상 첫 threat 진입은 region 38 (5시간 시점). 그 전까지 플레이어는 threat 단계 미경험.

**완화 방안**:
- region 146 +30 (tension 진입 직전) — 4시간 시점 첫 진입 시 "이 region은 처음부터 긴장"의 체감
- region 38 +60 (threat) — 5시간 시점 첫 진입 시 "T3는 위협부터 시작" 명확한 학습 곡선

### 3. cumulative 5회 cap 학습

같은 quest_pool 5회 완료 시 cap 도달은 의도된 학습 모멘트:
- 첫 5회: 25~40분 외출 — "도적 의뢰가 안 보이네" 체감
- flag 토글 다이얼로그 (예: "도적이 사라졌다") — 큰 진행감

**완화 방안**:
- ActivityLog "도적 N/5회 처치"로 진행도 표시 권장 (페이즈 4 #1 명세 입력)
- 체크리스트 UI는 M7 MVP에서 과한 부담 → ActivityLog만으로도 충분

### 4. decay N=12시간의 체감

- 일반 세션 (4~6시간) 내 영향 0 — 학습 부담 없음
- 24시간 미접속 후 재방문 시 +2 점수 회귀 — 미미 (체감 거의 없음)
- 72시간 (3일) 미접속 시 +6 점수 회귀 — 한 region 단계 회귀 가능
- M7 외 장기 미접속자 위협: 미미 (M8+ 시스템과 통합 시 강화)

---

## 조정 제안

### 1. dangerScore 4단계 임계값 (변경 없음, 페이즈 1 #2 그대로 채택)

```dart
enum DangerLevel { stable, peaceful, tension, threat }

DangerLevel resolveLevel(int score) {
  if (score >= 50) return DangerLevel.threat;     // +50 ~ +100
  if (score >= 0) return DangerLevel.tension;      // 0 ~ +49
  if (score >= -50) return DangerLevel.peaceful;   // -49 ~ -1
  return DangerLevel.stable;                       // -100 ~ -50
}
```

### 2. 트리거 점수 가감량 (사건 등급 4종 신설)

페이즈 1 #2의 -30 ~ -50 권장량을 4종 등급으로 세분화:

| 등급 | 변동 | 적용 사례 |
|------|------|---------|
| 소형 단발 | -10 ~ -15 | 일반 의뢰 1회, 체인 1단계 진행 |
| 중형 단발 | -20 ~ -25 | 일반 엘리트 처치, 체인 완주, 정기 사건 |
| 대형 단발 | -30 ~ -40 | 유니크 엘리트 처치, 거점 step 6, M7 핵심 사건 |
| **특수 단발** | **-50** | M7 7리전 안개·도적 등 최고 사건 (stable 직행 가능) |

**누적**: 회당 -10, cap -50, cap 도달 시 단발 -10 추가 보너스 (총 -60, stable 안정 진입 보장).

### 3. decay 시간 N=12시간 (페이즈 1 #2 권장 6→12 조정)

| 변경 전 | 변경 후 |
|--------|---------|
| 페이즈 1 #2 권장 N=6 | **N=12** |

근거: 일반 세션 4~6시간 동안 영향 0이 더 자연스러움. 8시간 누적 +1 점수만 → M7 외 영역.

### 4. QuestGenerator 4×4 가중치 매트릭스 (정량 확정)

위 분석 5절 매트릭스 그대로 채택:

| dangerLevel | raid | hunt | escort | explore |
|-------------|------|------|--------|---------|
| threat | 3.0× | 3.0× | 1.5× | 1.5× |
| tension | 2.0× | 2.0× | 1.3× | 1.3× |
| peaceful | 1.0× | 1.0× | 1.2× | 1.0× |
| stable | 0.3× | 0.5× | 1.5× | 1.3× |

### 5. 플래그별 추가 가중치 14쌍 (정량 확정)

위 분석 6절 표 그대로 채택 (8개 flag × 1~2 quest_type = 총 14쌍).

### 6. dangerLevel 명성 보너스 (M7 MVP 미적용)

옵션 A 채택. M8+ 재검토.

---

## 시뮬레이션

### 시나리오: 5~8시간 흐름 전체 가중치 적용 시 의뢰 분포 변화

페이즈 1 #4 2절 시나리오의 7리전 dangerLevel 변화 (위 데이터 분석 2절) + 매트릭스/플래그 가중치 적용 시 5시간 시점 의뢰 노출 분포 추정.

**5시간 시점 (구간 G 종료) 의뢰 풀 상태**:
- r3 (peaceful, flag: pyegwang_reopen): hunt 0.7× / escort 1.2× → escort 위주
- r31 (stable, flag: bandits_cleared + shrine): escort 2.25× / explore 1.69× / raid 0.09× → escort + explore
- r127 (peaceful → stable 진입 직전, flag: nomad_friendly): escort 1.56× / raid 0.5× → escort + explore
- r9 (peaceful, flag: giant_beast_killed): hunt 0.5× / escort 1.44× → escort + explore
- r10 (tension): raid 2.0× / hunt 2.0× → raid + hunt
- r146 (tension, 사건 미진행): tension raid 2.0× / hunt 2.0× → raid + hunt
- r38 (threat, 사건 미진행): threat raid 3.0× / hunt 3.0× → raid + hunt 폭증

**전체 7리전 의뢰 풀 종합 분포** (5시간 시점):
- escort: 약 32% (r3·r31·r127·r9에서 강세)
- explore: 약 22% (r31에서 강세)
- hunt: 약 25% (r10·r146·r38에서 강세)
- raid: 약 18% (r10·r146·r38에서 강세)
- labor: 약 3% (r3 일부)

→ **사건 진행 region은 안전 의뢰, 사건 미진행 region은 위협 의뢰**의 명확한 차별화 ✅

### 시나리오: 8시간 시점 종합 분포

8시간 시점 (구간 J 종료):
- r3·r31·r127·r9: peaceful/stable + flag 토글 → escort·explore 위주
- r10: peaceful (chain 완주) → escort·explore 위주
- r146: stable (mist_cleared) → 모든 quest_type 균형
- r38: tension (ironbound 완주, peaceful 진입 임박) → 균형

**8시간 시점 종합 분포**:
- escort: 약 35%
- explore: 약 28%
- hunt: 약 17%
- raid: 약 15%
- labor: 약 5%

→ M7 종료 시점 전반적 평온화 + escort/explore 50%+ ✅ (생활권 안정 체감)

---

## data-generator 수치 가이드

페이즈 3 #4 (지역 상태별 퀘스트 풀 30~50개) 데이터 생성 시 적용 가이드:

- **대상 타입**: `quest-pool` (재사용)
- **대상 테이블**: `quest_pools` (신규 컬럼 3개 추가 후 30~50행 INSERT)
- **수치 범위**:
  - region_state_effect JSONB:
    - cumulative type: `{"type": "cumulative", "delta_per_completion": -10, "cap_per_threshold": -50, "threshold_flag": "..."}`
    - oneshot type: `{"type": "oneshot", "delta": -30 ~ -50, "flag": "..."}`
  - region_state_required: 'stable' / 'peaceful' / 'tension' / 'threat' 중 하나, nullable
  - region_state_excluded: 동일 enum, nullable
- **외래 키 제약**:
  - threshold_flag 값은 8개 flag (페이즈 1 #2 1.3절) 중에서만 선택
  - region_state_required·excluded 값은 4 enum 중에서만 선택
- **balance 근거**: 본 문서 4·5절 매트릭스·가중치 + 시뮬레이션 1·2절 검증

### 권장 30~50행 분포 (페이즈 1 #4 시나리오 정합)

| Region | 누적 사건 풀 | 단발 사건 풀 | 상태 조건 풀 | 일반 풀 | 소계 |
|--------|------------|-----------|-----------|-------|------|
| r3 | 1 (폐광 박쥐 cumulative) | 0 (step 6 기존) | 1 (안정 시 호위) | 0 (M5 기존) | 2 |
| r31 | 1 (도적 cumulative -10/회) | 1 (shrine 완주 단발 -20) | 2 (stable 시 호위 / threat 시 약탈) | 2 | 6 |
| r127 | 1 (해안 정찰 cumulative) | 1 (faction_clue 완주 단발 -20) | 1 (stable 시 외래 의뢰) | 2 | 5 |
| r9 | 1 (야수 흔적 hunt cumulative) | 1 (giant_beast 처치 -40) | 2 (peaceful 시 가죽 채집 / tension 시 hunt) | 2 | 6 |
| r10 | 1 (바람 정찰 cumulative) | 1 (windrunner 완주 -30) | 1 (peaceful 시 explore) | 2 | 5 |
| r146 | 1 (안개 정찰 cumulative) | 1 (mist_cleared 특수 단발 **-50**) | 2 (threat 시 hunt / stable 시 explore) | 2 | 6 |
| r38 | 1 (도굴꾼 hunt cumulative) | 1 (ironbound 완주 -40) | 2 (threat 시 raid 폭증 / peaceful 시 explore) | 2 | 6 |
| **합계** | 7 | 6 | 11 | 12 | **36행** |

→ 30~50 범위 내 (36행, 중간값 권장)

### 검증 항목

- 누적 cap 도달 (5회) → flag 토글 확인: 모든 cumulative 풀이 threshold_flag 보유
- 단발 사건 풀 6행 중 5개는 chain/elite hook과 통합 (별도 풀 노출 아닌 chain/elite 트리거에서 호출), 1개(r146 안개 해소)만 독립 풀
- region_state_required·excluded 분포: required 10행 / excluded 1행 (M7 MVP 단순 분기)
- 일반 풀 12행은 region_state_required·excluded 모두 NULL (모든 상태에서 노출)

### 페이즈 4 #2 명세 입력 요약

```dart
// QuestGenerator 가중치 계산 (페이즈 4 #2 명세 입력)
class RegionStateWeightConfig {
  static const Map<DangerLevel, Map<QuestType, double>> dangerLevelMultiplier = {
    DangerLevel.threat: {QT.raid: 3.0, QT.hunt: 3.0, QT.escort: 1.5, QT.explore: 1.5},
    DangerLevel.tension: {QT.raid: 2.0, QT.hunt: 2.0, QT.escort: 1.3, QT.explore: 1.3},
    DangerLevel.peaceful: {QT.raid: 1.0, QT.hunt: 1.0, QT.escort: 1.2, QT.explore: 1.0},
    DangerLevel.stable: {QT.raid: 0.3, QT.hunt: 0.5, QT.escort: 1.5, QT.explore: 1.3},
  };

  // 8개 flag × 1~2 quest_type = 14쌍 (위 6절 표)
  static const Map<String, Map<QuestType, double>> flagMultipliers = {
    'region_3_pyegwang_reopen_completed': {QT.hunt: 0.7, QT.escort: 1.2},
    'region_31_bandits_cleared': {QT.raid: 0.3, QT.escort: 1.5},
    // ... 12쌍 더
  };

  static const Duration decayInterval = Duration(hours: 12);
  static const int decayPerInterval = 1;
}
```

페이즈 4 #1 명세에 dangerLevel 전이 시 ActivityLog/Dialog 발동 로직 + 5절 결정된 모든 enum/매트릭스 상수 포함.
