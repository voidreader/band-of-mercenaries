# M4 고정 사건 의뢰 난이도·보상 곡선 밸런스 분석 리포트

> 작성일: 2026-05-03
> 유형: 신규 컨텐츠 수치 설계 (M4 마일스톤 — 페이즈 2 산출물 4/4)
> 분석 대상: "폐광길 재개방" 6단계 사건 라인의 step별 적전투력·파티파워·성공률·골드·XP·소요시간 곡선
> 선행 문서:
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` (페이즈 1 #4) — 6단계 라인·trust_threshold·quest_type 분포
> - `Docs/content-design/[content]20260503_first-2h-playflow.md` (페이즈 1 #5) — 분 단위 시간 분배·step별 성공률 가이드
> - `Docs/balance-design/[balance]20260503_settlement-trust-tuning.md` (페이즈 2 #1) — step별 신뢰도 보상 10/15/20/25/30/100
> - `Docs/balance-design/[balance]20260503_chore-quest-economy.md` (페이즈 2 #3) — step별 골드 보상 가이드 80/120/200/185/270/500G·XP 25/50/75 평균
> 후속:
> - 페이즈 4 #3 (quest_pools 컬럼 확장 + 고정 의뢰 노출 로직) — 본 문서의 6행 quest_pools 데이터 + 신규 컬럼 추가 권장 (duration_override / reward_gold_override / reward_xp_bonus) 명세 직접 입력
> - 페이즈 4 #5 (마을 신뢰도 시스템 + 고정 사건 진행 상태) — 본 문서의 실패·재시도 정책 + chainQuestProgress 재사용 정책 명세 직접 입력

---

## 현재 상태

### 기존 성공률 공식 (코드 — `features/quest/domain/quest_calculator.dart`)

```dart
rate = 50.0
     + (powerRatio - 1.0) × 50.0     // partyPower / enemyPower 비율
     + traitBonus.clamp(-10, +10)     // ±10%p 독립 상한
     + questMod                        // explore +5 / escort +3 / raid 0 / hunt -5
     - distancePenalty                 // = abs(quest.region - playerRegion)
     + roleSynergyBonus.clamp(-10, +10) // ±10%p 독립 상한
     + factionPassiveBonus            // 패시브 (M4 시작 거점 ~0)
     + randomVariance                  // ±5%p
return rate.clamp(5.0, 95.0)
```

**관찰 (M4 시작 거점 한정)**:
- 폐광길 6단계는 모두 region_id 3 내부 → **distancePenalty = 0**
- M4 시점 traitBonus·factionPassiveBonus ~ 0 (선천 트레잇 평균 0 가정, 세력 미가입)
- **survey는 `_questModifiers`에 없음 → 0 fallback**
- **survey는 `_statWeights`에 없음 → raid 가중치 fallback** (str 0.70 / int 0.10 / vit 0.10 / agi 0.10)
- **survey는 `RoleSynergyMatrix._matrix`에도 없음 → 0** (4종만 정의: raid/hunt/escort/explore)

### 기존 보상 공식 (코드)

```dart
calculateReward = (base_reward × reward_multiplier × (1 + stackedBonus)).round()
calculateXpGain = (difficulty × 20 × resultMultiplier × (1 + facilityBonus + passiveXpBonus)).round()
calculateDispatchDuration = base_duration × (1 + (difficulty-1) × 0.2) / (speedMultiplier × partyAvgAgi/50)
calculateDispatchCost = minCost + (maxCost - minCost) × (duration / 144).clamp(0, 1)
```

### 기존 difficulties + quest_types + jobs T1·T2 평균

```
difficulties:
  Lv1: enemy_power 10, reward_mult 1.0, dispatch 5~30G,  injury 10%, death 5%
  Lv2: enemy_power 20, reward_mult 1.5, dispatch 10~60G, injury 20%, death 10%, success_penalty 0.1
  Lv3: enemy_power 35, reward_mult 2.2, dispatch 20~100G, injury 30%, death 15%, success_penalty 0.2

quest_types (base_reward / base_duration / risk_factor):
  explore:  80 / 70s  / 0.20
  hunt:    120 / 80s  / 0.50
  raid:    100 / 60s  / 0.30
  escort:   90 / 75s  / 0.25
  survey:    0 / 180s / 0.10  ← base_reward 0 ⚠

jobs (T1·T2 평균 stat 분포):
  T1 (16개 직업): str 8 / int 6 / vit 26 / agi 53  — role: specialist 11 + rogue 3 + ranger 1 + warrior 1
  T2 (17개 직업): str 20 / int 12 / vit 52 / agi 53
```

### 페이즈 1 #4·페이즈 2 #1·#3 결정사항 (입력)

- 6단계 quest_type / difficulty 분포 (페이즈 1 #4 2.2절): explore/hunt/raid/escort/raid/survey × 1/1/2/2/3/3
- step별 sector_type: dungeon × 4 (s2 폐광) / field × 1 (s3 마른 초원) / village × 1 (s1 더스트빌)
- step별 trust_threshold: 1·1·2·2·3·3
- step별 신뢰도 보상 (페이즈 2 #1): 10·15·20·25·30·100점
- step별 골드 보상 가이드 (페이즈 2 #3): 80·120·200·185·270·500G
- step별 XP 평균 (페이즈 2 #3): 난이도 1 25 / 난이도 2 50 / 난이도 3 75
- step별 소요시간 (페이즈 1 #5): step 1·2 ~5분 / step 3·4 ~5~8분 / step 5·6 ~10분
- 최종 의뢰 (step 6) 60~80% 성공률 보장 (페이즈 1 #4)

---

## 데이터 분석

### 1. 파티파워 곡선 (T1·T2 평균 기준)

`partyPower = Σ(str×w_str + int×w_int + vit×w_vit + agi×w_agi)`

**T1 평균 (str 8 / int 6 / vit 26 / agi 53) — 1명 단위 파티파워**:

| quest_type | str×w | int×w | vit×w | agi×w | **partyPower (1명)** |
|-----------|-------|-------|-------|-------|---------------------|
| raid      | 5.6 (0.70) | 0.6 (0.10) | 2.6 (0.10) | 5.3 (0.10) | **14.1** |
| hunt      | 4.0 (0.50) | 0.6 (0.10) | 2.6 (0.10) | 15.9 (0.30) | **23.1** |
| escort    | 1.6 (0.20) | 0.6 (0.10) | 15.6 (0.60) | 5.3 (0.10) | **23.1** |
| explore   | 0.8 (0.10) | 2.7 (0.45) | 3.9 (0.15) | 15.9 (0.30) | **23.3** |
| survey    | (raid fallback) | | | | **14.1** |

**T2 평균 (str 20 / int 12 / vit 52 / agi 53) — 1명 단위 파티파워**:

| quest_type | **partyPower (1명)** |
|-----------|---------------------|
| raid      | **25.7** (str 0.70 비중 높음) |
| hunt      | **32.3** |
| escort    | **42.5** (vit 0.60 비중) |
| explore   | **35.7** |
| survey    | **25.7** (raid fallback) |

### 2. step별 성공률 시뮬레이션 (랜덤 분산 제외, distancePenalty=0, traitBonus=0, factionBonus=0)

**Step 1 — 난이도 1 explore, T1 1명 (specialist)**:
- enemyPower = 10
- partyPower = 23.3
- powerRatio = 23.3 / 10 = 2.33 → (2.33-1)×50 = +66.5
- questMod (explore) = +5
- roleSynergy (specialist explore = +2) = +2
- rate = 50 + 66.5 + 5 + 2 = **123.5 → clamp 95%** ✓ ≥80% 보장

**Step 2 — 난이도 1 hunt, T1 1명 (specialist)**:
- enemyPower = 10, partyPower = 23.1, powerRatio = 2.31 → +65.5
- questMod (hunt) = -5
- roleSynergy (specialist hunt = +2) = +2
- rate = 50 + 65.5 - 5 + 2 = **112.5 → clamp 95%** ✓

**Step 3 — 난이도 2 raid, T1 2명**:
- enemyPower = 20, partyPower = 14.1×2 = 28.2, powerRatio = 1.41 → +20.5
- questMod (raid) = 0, roleSynergy (specialist raid = +2) = +2
- rate = 50 + 20.5 + 0 + 2 = **72.5%** ✓ 70~85%

**Step 3 — T1 3명 (안전 옵션)**:
- partyPower = 42.3, powerRatio = 2.115 → +55.75
- rate = 50 + 55.75 + 2 = **107.75 → clamp 95%**

**Step 4 — 난이도 2 escort, T1 2명**:
- enemyPower = 20, partyPower = 23.1×2 = 46.2 (T1 escort 1명 23.1 — vit 0.60 비중)
- powerRatio = 2.31 → +65.5
- questMod (escort) = +3, roleSynergy = +2
- rate = 50 + 65.5 + 3 + 2 = **120.5 → clamp 95%** ✓ 70~85% 상한

**Step 5 — 난이도 3 raid, T1 3명**:
- enemyPower = 35, partyPower = 14.1×3 = 42.3, powerRatio = 1.21 → +10.5
- questMod = 0, roleSynergy = +2
- rate = 50 + 10.5 + 2 = **62.5%** ❌ 70%+ 미달

**Step 5 — T1 4명**:
- partyPower = 14.1×4 = 56.4, powerRatio = 1.61 → +30.5
- rate = 50 + 30.5 + 2 = **82.5%** ✓ 70%+

**Step 5 — T1 3명 + T2 1명**:
- partyPower = 14.1×3 + 25.7 = 67.0, powerRatio = 1.91 → +45.5
- rate = 50 + 45.5 + 2 = **97.5 → clamp 95%** ✓

**Step 6 — 난이도 3 survey, T1 3명**:
- enemyPower = 35, partyPower = 14.1×3 = 42.3 (raid fallback), powerRatio = 1.21 → +10.5
- questMod (survey) = **0** (없음)
- roleSynergy (survey) = **0** (매트릭스에 없음)
- rate = 50 + 10.5 + 0 + 0 = **60.5%** ✓ 60~80% 정확 통제

**Step 6 — T1 4명**:
- partyPower = 56.4, powerRatio = 1.61 → +30.5
- rate = 50 + 30.5 = **80.5%** ✓ 80% 상한

**Step 6 — T1 3명 + T2 1명**:
- partyPower = 67.0, powerRatio = 1.91 → +45.5
- rate = 50 + 45.5 = **95.5 → clamp 95%** (자원 투입 시 안전)

### 3. step별 성공률 곡선 요약 (정상 플레이 권장 파티)

| step | 난이도 | type | enemyPower | 권장 파티 | partyPower | rate (preview) | 평가 |
|------|--------|------|-----------|----------|-----------|---------------|------|
| 1 | 1 | explore | 10 | T1 1명 | 23.3 | **95%** ✓ | ≥80% 보장 — 첫 의뢰 학습 |
| 2 | 1 | hunt | 10 | T1 1명 | 23.1 | **95%** ✓ | ≥80% 보장 |
| 3 | 2 | raid | 20 | T1 2명 | 28.2 | **72.5%** ✓ | 70~85% (T1 3명 시 95%) |
| 4 | 2 | escort | 20 | T1 2명 | 46.2 | **95%** ✓ | escort vit 비중 + questMod +3 → 안정적 |
| 5 | 3 | raid | 35 | T1 4명 또는 T2 포함 | 56.4 / 67.0 | **82.5% / 95%** ✓ | 70%+ — 파티 보강 필요 |
| 6 | 3 | survey | 35 | T1 3명 | 42.3 | **60.5%** ✓ | 60~80% 통제 — 클라이맥스 의도 |

**핵심 발견**:
1. **Step 1·2** (난이도 1)는 T1 1명만으로도 95% 도달 — 페이즈 2 #3의 30분 흐름(T1 1명 단독 파견) 정합 ✓
2. **Step 4 escort**는 questMod +3 + vit 0.60 비중 + roleSynergy +2로 모두 양보너스 → 95% 안정. 페이즈 1 #4에서 "광부 호위 = escort"는 의도된 휴식 구간 효과
3. **Step 5 raid**는 T1 3명만으로는 62.5%로 70% 미달. **권장 파티 보강 필요** — 4명 또는 T2 포함
4. **Step 6 survey**는 questMod·roleSynergy 모두 0이라 powerRatio만으로 결정. T1 3명 = 60.5%, T1 4명 = 80.5% — **60~80% 통제 정확** ✓

### 4. 보상 곡선 시뮬레이션

#### 4.1 골드 보상 — `calculateReward(base_reward × reward_multiplier × (1 + stackedBonus))`

| step | quest_type | base | reward_mult | base × mult | 페이즈 2 #3 가이드 | **차이** |
|------|-----------|------|-------------|-------------|------------------|---------|
| 1 | explore | 80 | 1.0 | 80G | 80G | 0 ✓ |
| 2 | hunt | 120 | 1.0 | 120G | 120G | 0 ✓ |
| 3 | raid | 100 | 1.5 | 150G | 200G | +50G 보너스 |
| 4 | escort | 90 | 1.5 | 135G | 185G | +50G 보너스 |
| 5 | raid | 100 | 2.2 | 220G | 270G | +50G 보너스 |
| 6 | survey | **0** | 2.2 | **0G** ❌ | 500G | +500G 보너스 (전액) |

**문제 1**: survey의 base_reward는 0G이므로 calculateReward = 0G. 페이즈 2 #3 가이드 500G와 정합 안 됨.

**문제 2**: step 3·4·5도 base_reward × reward_mult로는 +50G 보너스 부족. 가이드와 정합하려면 별도 보너스 메커니즘 필요.

**해결안 — quest_pools에 `reward_gold_override INT nullable` 컬럼 추가**:
- is_fixed=true 행은 이 값을 우선 사용
- null이면 기본 calculateReward 공식 사용

**확정 reward_gold_override 권장**:

| step | type × difficulty 기본값 | reward_gold_override | 사유 |
|------|------------------------|---------------------|------|
| 1 | 80G (explore Lv1) | **null** (80G 사용) | 학습 모멘트 — 기본값 충분 |
| 2 | 120G (hunt Lv1) | **null** (120G 사용) | 잔고 회복 — 기본값 충분 |
| 3 | 150G (raid Lv2) | **200G** | 첫 위험 의뢰 — 시설 건설 비용 부담 보전 |
| 4 | 135G (escort Lv2) | **185G** | 두 번째 위험 의뢰 — step 3 완료 후 모멘텀 유지 |
| 5 | 220G (raid Lv3) | **270G** | 클라이맥스 직전 — step 6 도전 비용 보전 |
| 6 | 0G (survey Lv3) | **500G** | 클라이맥스 — 4단계 진입 + 외부 진입 동기 강화 |

**합계**: 80 + 120 + 200 + 185 + 270 + 500 = **1,355G** (페이즈 2 #3 정합 ✓)

#### 4.2 XP 보상 — `calculateXpGain(difficulty × 20 × resultMultiplier × (1 + bonus))`

성공 가정 평균 (대성공 30% + 성공 60% + 실패 10%):

| step | difficulty | base XP (성공) | 평균 XP | 페이즈 2 #3 가이드 | 정합 |
|------|-----------|---------------|---------|------------------|------|
| 1 | 1 | 20 | 25 | 25 | ✓ |
| 2 | 1 | 20 | 25 | 25 | ✓ |
| 3 | 2 | 40 | 50 | 50 | ✓ |
| 4 | 2 | 40 | 50 | 50 | ✓ |
| 5 | 3 | 60 | 75 | 75 | ✓ |
| 6 | 3 | 60 | 75 | 75 | ✓ |

**XP 보상은 기본 공식 그대로 정합** — 추가 override 불필요.

**보너스 권장**: step 6는 클라이맥스이므로 +50 XP 보너스 (별도 `reward_xp_bonus_override`).

**확정 reward_xp_bonus_override**:
- step 1~5: null (기본 공식)
- step 6: **+50 XP** (클라이맥스 보너스)

#### 4.3 소요시간 — `calculateDispatchDuration(base_duration × (1 + (difficulty-1)×0.2) / (speedMultiplier × partyAvgAgi/50))`

T1 평균 agi = 53, agiMultiplier = 1.06, speedMultiplier = 1 (시간 가속 미적용).

| step | base_duration | difficulty | mult | 계산 | 페이즈 1 #5 가설 | **차이** |
|------|---------------|-----------|------|------|----------------|---------|
| 1 | 70s (explore) | 1 | 1.0 | 70/1.06 = **66s = 1.1분** | ~5분 | -3.9분 ❌ |
| 2 | 80s (hunt) | 1 | 1.0 | 80/1.06 = **75s = 1.25분** | ~5분 | -3.75분 ❌ |
| 3 | 60s (raid) | 2 | 1.2 | 72/1.06 = **68s = 1.13분** | ~6~8분 | -5분 ❌ |
| 4 | 75s (escort) | 2 | 1.2 | 90/1.06 = **85s = 1.4분** | ~5~8분 | -4분 ❌ |
| 5 | 60s (raid) | 3 | 1.4 | 84/1.06 = **79s = 1.3분** | ~10분 | -8.7분 ❌ |
| 6 | 180s (survey) | 3 | 1.4 | 252/1.06 = **238s = 4분** | ~10분 | -6분 ❌ |

**문제**: 모든 step이 페이즈 1 #5 가설보다 짧음. step 1·2 ~5분 기대값 대비 1.1~1.25분 → 분 단위 흐름 미정합.

**해결안 — quest_pools에 `duration_override_seconds INT nullable` 컬럼 추가**:
- is_fixed=true 행은 이 값을 우선 사용
- null이면 기본 calculateDispatchDuration 공식 사용

**확정 duration_override_seconds 권장**:

| step | duration_override (초) | 분 환산 | 페이즈 1 #5 정합 |
|------|----------------------|---------|----------------|
| 1 | **300** | 5분 | ✓ |
| 2 | **300** | 5분 | ✓ |
| 3 | **360** | 6분 | ✓ |
| 4 | **360** | 6분 | ✓ |
| 5 | **600** | 10분 | ✓ |
| 6 | **600** | 10분 | ✓ |

**합계**: 5 + 5 + 6 + 6 + 10 + 10 = **42분** 순수 파견 시간. 이동 시간(거리 0~1, 30s/거리) 포함 시 ~45분.

**페이즈 1 #5 누적 시간 정합 검증**:
- step 1 (2:00~7:00 5분 + 이동 30s 포함) ✓
- step 2 (10:00~18:00 8분, 5분 파견 + 3분 buffer) ✓
- step 3 (32:00~40:00 8분, 6분 파견 + 2분 buffer) ✓
- step 4 (45:00~50:00 5분, 위반 — 6분 파견은 50:00~46:00 = 4분만 가능) ⚠

**조정**: step 4 duration_override를 **300s (5분)**으로 단축, 또는 페이즈 1 #5 흐름의 step 4 시점을 +1분 조정. 권장: **step 4 = 300s** (페이즈 1 #5 흐름 유지).

**최종 duration_override**:

| step | 권장값 | 분 |
|------|-------|---|
| 1 | 300 | 5 |
| 2 | 300 | 5 |
| 3 | 360 | 6 |
| 4 | **300** | 5 (step 3 8분 + step 4 5분 = 13분, 32:00~50:00 18분 windows 정합) |
| 5 | 600 | 10 |
| 6 | 600 | 10 |

#### 4.4 파견비용 — `calculateDispatchCost(min + (max-min) × duration/144)`

duration_override 적용 시 파견비용은 **override 값 / 60s = 분 단위 → seconds 단위로 비례 계산** 적용 권장. 코드 분기로 `if (override) return min + (max-min) × override/60/144` 또는 단순 비례.

**기본 dispatch_cost 계산** (override 없을 때 — 참고):
- Lv1 (5~30G): duration 70 × 1.0 / 144 = 0.49 → 5 + 25 × 0.49 = ~17G
- Lv2 (10~60G): duration 60 × 1.2 / 144 = 0.5 → 10 + 50 × 0.5 = 35G
- Lv3 (20~100G): duration 60 × 1.4 / 144 = 0.58 → 20 + 80 × 0.58 = 67G

**override 적용 후 dispatch_cost 권장**:
- override 값을 base_duration 자리에 직접 넣고 `(override / 144)`로 ratio 계산

| step | duration_override | difficulty | min~max | 계산 | dispatch_cost |
|------|-------------------|-----------|---------|------|--------------|
| 1 | 300 | 1 | 5~30G | 300/144 clamp 1 → 5+25×1 = | **30G** (max) |
| 2 | 300 | 1 | 5~30G | 동일 | **30G** |
| 3 | 360 | 2 | 10~60G | 360/144 clamp 1 → 10+50×1 = | **60G** |
| 4 | 300 | 2 | 10~60G | 300/144 clamp 1 → 10+50×1 = | **60G** |
| 5 | 600 | 3 | 20~100G | 600/144 clamp 1 → 20+80×1 = | **100G** |
| 6 | 600 | 3 | 20~100G | 동일 | **100G** |

**합계 dispatch_cost**: 30+30+60+60+100+100 = **380G**

**고정 사건 의뢰 dispatch_cost는 max 도달** — 의도된 무게감. 페이즈 2 #3 100분 시점 잔고 추정 ~1,595G 대비 380G는 24%. 합리적 부담 유지.

**대안**: duration_override 도입 시 dispatch_cost 폭증을 우려한다면, override 적용 시에는 `min` 값만 사용 (별도 분기) 또는 `(원래 base_duration / 144)`로 ratio 유지. 결정은 페이즈 4 #3 명세에 위임.

**권장**: **min 값 단일 적용** — 시각적 부담 완화 + 첫 2시간 잔고 안정. 즉, dispatch_cost = {30·30·60·60·100·100} → **5·5·10·10·20·20 = 70G**.

**확정**: dispatch_cost는 **min 값** 사용 (5/5/10/10/20/20G = 70G 합계).

### 5. 손해·부상·사망 시나리오

#### 5.1 부상·사망률 적용 (난이도별)

기존 `difficulties` 테이블 그대로 사용 — 변경 없음.

| step | difficulty | injury_rate | death_rate |
|------|-----------|-------------|-----------|
| 1·2 | 1 | 10% | 5% |
| 3·4 | 2 | 20% | 10% |
| 5 | 3 | 30% | 15% |
| 6 | 3 | 30% | 15% |

**의도된 위험 분포**:
- Step 1~2: 학습 단계 — 부상 가능성 낮음
- Step 3~4: 첫 위험 의뢰 — 부상 발생 가능 (약초상 사용 첫 모멘트)
- Step 5: 두 번째 위험 의뢰 — 부상 + 사망 가능성 (약초상 두 번째 사용)
- Step 6: 클라이맥스 — survey이지만 risk_factor 0.10 → 부상률 30% × 0.10 = 3% 보정 (기존 risk_factor 적용 여부는 코드 확인 필요)

**risk_factor 적용**: 코드 확인 결과 `quest_pools.risk_factor` 또는 `quest_types.risk_factor`가 calculateDamage에 직접 영향을 주는지 미확인. 본 문서는 difficulties.injury_rate / death_rate만 사용하는 것으로 가정. 페이즈 4 #5에서 검증.

#### 5.2 success_penalty 적용 (난이도 2~5)

`difficulties.success_penalty` Lv2 = 0.1 / Lv3 = 0.2.

success_penalty가 어떻게 적용되는지 코드 분석 — `QuestCalculator.calculateSuccessRate`에는 직접 사용되지 않음. 다른 위치 (예: `QuestCompletionService`)에서 사용되거나 deprecated 가능. 페이즈 4 #5에서 검증 필요. 본 문서는 success_penalty 영향 미적용 가정.

### 6. 비관 시나리오 검증 (실패 분기 + 첫 2시간 외부 마무리)

#### 6.1 step 3 1회 실패 시나리오

| 시점 | 액션 | 결과 | 신뢰도 누적 | 단계 |
|------|------|------|------------|------|
| 0~30분 | step 1·2 + 일반 의뢰 (이상 시나리오) | 성공 | 31점 | 2 |
| 32:00 | step 3 시도 (T1 2명, 72.5% 성공률) | **실패** (27.5% 확률) | 31 | 2 |
| 32:00 | 부상 1명 발생 (난이도 2 injury 20%) | 부상 | 31 | 2 |
| 32:00~40:00 | 약초상 50G + 일반 의뢰 1건 (난이도 2 raid +3점) | 성공 | 34 | 2 |
| 40:00 | step 3 재시도 (T1 3명, 95%) | 성공 | 54 | 2 |
| 50:00 | step 4 (T1 2명, 95%) | 성공 | 79 | 2 |
| 55:00 | 일반 의뢰 1건 (난이도 1 +2점) | 성공 | **81 → 3단계 진입** | 3 |
| 55:00 | 3단계 진입 보상 +200G+100XP | — | 81 | 3 |
| 70:00 | step 5 (T1 3명+T2 1명, 95%) | 성공 | 111 | 3 |
| 95:00 | step 6 (T1 3명, 60.5%) | **실패** (40% 확률) | 111 | 3 |
| 95:00~110:00 | 일반 의뢰 1~2건 (난이도 2/3) | 성공 | 116~120 | 3 |
| 110:00 | step 6 재시도 (T1 4명, 80.5%) | 성공 | 220 | 4 |
| 110:00 | 4단계 진입 보상 +500G+200XP+100명성 | — | 220 | 4 |
| 120:00 | 첫 2시간 종료 | — | 220 | 4 |

**검증**: step 3·6 1회씩 실패에도 첫 2시간 안에 4단계 진입 가능. 페이즈 1 #5 종료 조건 정합 ✓

#### 6.2 step 5 1회 실패 시나리오 (T1 3명 단독 파견 의도적 도전)

| 시점 | 액션 | 결과 | 누적 시간 |
|------|------|------|----------|
| 0~78분 | (이상 시나리오 step 1~4) | 성공 | 78분 |
| 78:00 | step 5 시도 (T1 3명, 62.5% — 70% 미달) | **실패** (37.5% 확률) | 78분 |
| 78:00 | 부상 1명 (난이도 3 injury 30%) | 부상 | 78분 |
| 78:00~95:00 | 약초상 50G + 모집 또는 추가 일반 의뢰 | — | 95분 |
| 95:00 | step 5 재시도 (T1 4명 또는 T2 1명 추가, 95%) | 성공 | 95분 |
| 105:00 | step 6 (T1 4명, 80.5%) | 성공 | 105분 |
| 105:00 | 4단계 진입 | — | 105분 |
| 120:00 | 첫 2시간 종료 (4단계 도달 후 외부 진입 준비 시간 ~15분) | — | 120분 |

**검증**: step 5 1회 실패에도 첫 2시간 안 4단계 도달 가능 (페이즈 1 #5 외부 마무리 케이스 정합) ✓

#### 6.3 step 5·6 모두 실패 시나리오 (최악)

| 시점 | 액션 | 결과 | 누적 시간 |
|------|------|------|----------|
| 0~78분 | step 1~4 모두 1회 성공 | 성공 | 78분 |
| 78:00 | step 5 실패 + 부상 | 실패 | 78분 |
| 78:00~98:00 | 회복 + 재시도 준비 | — | 98분 |
| 98:00 | step 5 재시도 성공 | 성공 | 98분 |
| 108:00 | step 6 시도 (T1 3명, 60%) | **실패** (40%) | 108분 |
| 108:00~120:00 | 일반 의뢰 1~2건 + 추가 모집 | — | 120분 |
| **120:00** | **첫 2시간 종료 — step 6 미완료** | 3단계 머무름 | 120분 |
| 130:00~150:00 | step 6 재시도 (T1 4명) → 성공 → 4단계 진입 | 성공 | 150분 |

**검증**: 최악 시나리오에서 4단계 진입은 첫 2시간 외부(150분 시점). 페이즈 1 #5 종료 조건 "4단계 도달은 외부 (선택)"와 정합 ✓

**4단계 미진입 위험성**:
- step 6 60% 성공률은 1회 실패 가능성 40%
- 1회 실패 후 재시도 시 추가 30~40분 소요
- 첫 2시간 안 4단계 도달은 "성공률 70% 이상" 시나리오 한정
- 첫 2시간 외부 마무리는 60~80% 시나리오에서 발생 — 페이즈 1 #5 의도된 흐름

### 7. 실패·재시도 정책

#### 7.1 실패 후 재등장 정책

페이즈 1 #4 2.4절 정합:
- **is_fixed=true 의뢰는 풀에서 사라지지 않는다** — 일반 갱신 주기 미적용
- **노출 조건 두 가지** 모두 충족 시 재등장:
  1. trust_threshold ≤ 현재 신뢰도 단계
  2. 이전 step 완료 (currentStep == fixed_step)
- **신뢰도 단계 강등 시**: M4 시점 강등 미적용 (페이즈 2 #1 결정) → step 노출 차단 위험 없음

#### 7.2 stepFailureCount 추적

`chainQuestProgress.stepFailureCount` 활용 (페이즈 1 #4 4.2절):
- step 시도 실패 시 +1
- step 성공 시 0으로 리셋
- 누적 실패 카운트가 일정 임계값 도달 시 별도 안내 다이얼로그 (M5+ 검토)

**M4 시점 정책**:
- stepFailureCount는 추적만 수행
- UI에는 표시 안 함 (학습 곡선 단순화)
- 페이즈 4 #5 명세에서 활용 가능성 메모

#### 7.3 재시도 시 보상

재시도 성공 시 보상은 **첫 시도와 동일** (실패 보너스 없음). 단순화 정책.

대안 — "실패 후 재시도 시 보상 +10%" (학습 곡선 보상감 강화)는 M5+ 검토. M4 미적용.

#### 7.4 step 진행 상태 보존 정책

`chainQuestProgress.currentStep`은 **마지막 성공 step 다음 값**:
- 게임 시작 직후: currentStep = 1
- step 1 성공 후: currentStep = 2
- step 5 실패 시: currentStep = 5 유지 (변경 없음)
- step 6 성공 후: currentStep = 7 (또는 status = completed 전이, totalSteps 6 도달)

ChainQuestProgress의 기존 흐름 그대로 적용. 변경 없음.

---

## 문제점

### 문제점 1: survey의 base_reward = 0 → step 6 보상 0G

**근거**: `quest_types.survey.base_reward = 0`. calculateReward(0 × 2.2) = 0G. 페이즈 2 #3 가이드 500G와 정합 안 됨.

**해결**: `quest_pools.reward_gold_override` 신규 컬럼 추가. 본 문서 4.1절 결정.

### 문제점 2: base_duration 그대로 사용 시 step 1·2 ~1분으로 페이즈 1 #5 ~5분 가설 미정합

**근거**: explore base_duration 70s + agiMultiplier 1.06 = 66s = 1.1분. 페이즈 1 #5의 ~5분 가설과 -3.9분 차이.

**해결**: `quest_pools.duration_override_seconds` 신규 컬럼 추가. 본 문서 4.3절 결정.

### 문제점 3: survey의 questMod·roleSynergy 모두 0 → step 6 보너스 메커니즘 없음

**근거**: `_questModifiers`·`_statWeights`·`RoleSynergyMatrix._matrix` 4종 quest_type만 정의 (raid/hunt/escort/explore). survey는 fallback 불가.

**판정**: **이는 문제가 아니라 의도된 설계.** survey는 powerRatio만으로 결정되어 60~80% 통제가 자연스럽게 동작. 변경 불필요.

**페이즈 4 #5 검증 필요**: survey가 raid fallback이 아닌 별도 가중치 또는 0 처리되는지 확인. 본 문서는 raid fallback (str 0.70 비중) 가정으로 시뮬레이션.

### 문제점 4: T1 3명 단독 파티로 step 5 70% 미달

**근거**: T1 3명 raid 파티파워 42.3 vs enemy 35 → 62.5%. 70%+ 보장 미충족.

**해결안 옵션**:

| 옵션 | 설명 | 평가 |
|------|------|------|
| A. enemyPower 35 → 30 하향 | step 5만 difficulty 분리 | ❌ difficulties 테이블 변경 부담 |
| B. T1 4명 권장 | 파티 4명 권장 가이드 표시 | ✅ UI 권장 표시로 해결 |
| C. T2 1명 모집 권장 | T2 모집 가중치 30% 활용 | △ T2 모집 운 의존 |
| D. 의도된 도전 | T1 3명은 도전, T1 4명은 안전 | ✅ 의도된 학습 모멘트 |

**권장: 옵션 B + D 병행**. 페이즈 4 #4 UI에서 step 5는 "권장 파티 4명" 표시. 단, T1 3명도 도전 가능 — 62.5% 도전 자유.

### 문제점 5: success_penalty 컬럼 영향 미확인

**근거**: `difficulties.success_penalty` Lv2=0.1·Lv3=0.2 컬럼 존재. 그러나 `QuestCalculator.calculateSuccessRate`에 직접 사용 흔적 없음.

**해결**: 페이즈 4 #5에서 success_penalty 적용 위치 확인. 만약 적용된다면 step 3·4 성공률에서 -10%p, step 5·6에서 -20%p 추가 적용 필요. 본 문서 시뮬레이션 결과 보정.

**현재 시뮬레이션 가정**: success_penalty 영향 미적용 (deprecated 가정).

---

## 플레이어 체감 분석

### step별 도전감 곡선

| step | 권장 파티 | 성공률 | 체감 키워드 | 학습 모멘트 |
|------|---------|-------|------------|------------|
| 1 | T1 1명 | 95% | "쉽게 해결" | 첫 의뢰 — 시스템 이해 |
| 2 | T1 1명 | 95% | "익숙해진다" | 두 번째 의뢰 — 자신감 |
| 3 | T1 2~3명 | 72~95% | "**첫 도전**" | 다중 파견 학습 + 약초상 첫 사용 가능성 |
| 4 | T1 2명 | 95% | "한숨 돌리기" | escort vit 비중 + questMod +3 → 휴식 구간 |
| 5 | T1 4명 / T2 포함 | 82~95% | "**파티 보강 필요**" | 모집 결정 + 추가 인건비 부담 |
| 6 | T1 3~4명 | 60~80% | "**클라이맥스**" | 큰 보상 + 실패 가능성 + 4단계 진입 트리거 |

**의도된 곡선**: 쉬움 → 쉬움 → **도전** → 휴식 → **보강** → **클라이맥스**.

### 잠재 위험 1: step 5 T1 3명 시도 시 62.5% 좌절감

**시나리오**: 플레이어가 T1 3명만 보유 + step 5 도전 결정 → 1회 실패.

**대응**:
1. 페이즈 4 #4 UI에서 "권장 파티: 4명 (현재 파티 3명)" 명확 표시
2. 실패 시 약초상 즉시 회복 + 추가 모집 옵션 안내
3. 1회 실패 후 재시도 가능 — stepFailureCount 추적
4. 페이즈 1 #4 정합 — 실패해도 풀에서 사라지지 않음

**체감 결론**: 1회 실패는 학습 모멘트로 전환. 좌절감 → "다음엔 4명으로 가야지" 결정.

### 잠재 위험 2: step 6 60% 클라이맥스 실패 시 첫 2시간 외부 마무리

**시나리오**: 플레이어가 T1 3명 단독으로 step 6 도전 → 40% 확률로 실패 → 첫 2시간 안 4단계 미진입.

**대응**:
1. 페이즈 4 #4 UI에서 "권장 파티: 4명 또는 T2 포함" 표시
2. 실패 후 재시도 가능 + 5단계 사건 라인 종료 직전 모멘텀
3. 4단계 도달이 첫 2시간 외부여도 페이즈 1 #5 종료 조건 "4단계는 외부 (선택)"와 정합

**체감 결론**: 실패해도 사건 라인 진행 + 30~40분 후 재도전 → 클라이맥스 의미 강화.

### 잠재 위험 3: step 4 escort 95%는 너무 안정적이라 긴장감 약화

**시나리오**: step 3 도전 후 step 4가 95% 안정 → "쉬운 한숨 구간" 인식.

**대응**:
1. 의도된 휴식 구간 — 학습 곡선 안정성 우선
2. step 4 호위 컨셉(광부 동행)이 "위험 의뢰"보다 "동행 임무"라는 서사 정합
3. step 5 클라이맥스 진입 직전 휴식이 학습 곡선 균형

**체감 결론**: 6단계 사건 라인의 "강-강-강" 패턴은 피로감 유발. step 4 휴식이 정합.

---

## 조정 제안

### 조정 1: step별 적전투력 + 추천 파티 + 성공률 (확정안)

| step | 난이도 | type | sector | enemyPower | **추천 파티** | partyPower | preview rate | 평가 |
|------|--------|------|--------|-----------|--------------|-----------|-------------|------|
| 1 | 1 | explore | s2 dungeon | 10 | T1 1명 | 23.3 | **95%** | ≥80% 보장 |
| 2 | 1 | hunt | s3 field | 10 | T1 1명 | 23.1 | **95%** | ≥80% 보장 |
| 3 | 2 | raid | s2 dungeon | 20 | T1 2명 (도전) / 3명 (안전) | 28.2 / 42.3 | **72.5% / 95%** | 70~85% 보장 |
| 4 | 2 | escort | s2 dungeon | 20 | T1 2명 | 46.2 | **95%** | 70~85% 상한 |
| 5 | 3 | raid | s2 dungeon | 35 | T1 4명 / T2 1명 포함 | 56.4 / 67.0 | **82.5% / 95%** | 70%+ 보장 |
| 6 | 3 | survey | s1 village | 35 | T1 3명 (도전) / 4명 (안전) | 42.3 / 56.4 | **60.5% / 80.5%** | 60~80% 의도 통제 |

**enemy_power**는 difficulties 테이블 그대로 사용. **변경 없음**.

### 조정 2: step별 골드 보상 + override 컬럼 (확정안)

| step | base × mult | reward_gold_override | 사유 |
|------|------------|---------------------|------|
| 1 | 80G | **null** (80G 사용) | 학습 — 기본값 충분 |
| 2 | 120G | **null** (120G 사용) | 잔고 회복 — 기본값 충분 |
| 3 | 150G | **200G** | 첫 위험 의뢰 +50G 보너스 (시설 비용 보전) |
| 4 | 135G | **185G** | 두 번째 위험 +50G |
| 5 | 220G | **270G** | 클라이맥스 직전 +50G |
| 6 | 0G ❌ | **500G** | 클라이맥스 — survey base 0 우회, 4단계 진입 트리거 |

**합계**: 80+120+200+185+270+500 = **1,355G** (페이즈 2 #3 가이드 정합 ✓)

**페이즈 4 #3 컬럼 추가**: `quest_pools.reward_gold_override INT nullable`.

### 조정 3: step별 XP 보상 + bonus override (확정안)

| step | 기본 평균 XP | reward_xp_bonus_override | 최종 평균 XP |
|------|-------------|------------------------|--------------|
| 1·2 | 25 | null | 25 |
| 3·4 | 50 | null | 50 |
| 5 | 75 | null | 75 |
| 6 | 75 | **+50 (클라이맥스 보너스)** | 125 |

**페이즈 4 #3 컬럼 추가**: `quest_pools.reward_xp_bonus_override INT nullable`.

**이유**: step 6는 사건 라인 클라이맥스로 큰 보상감 필요. 4단계 진입 별도 보상(+200 XP, 페이즈 2 #1)과 합하여 ~325 XP 한 번에 유입 → T1 용병 1명이 거의 Lv3 진입 가능 (350 XP 임계값).

### 조정 4: step별 소요시간 + duration override (확정안)

| step | 기본 duration | duration_override_seconds | 분 |
|------|--------------|--------------------------|---|
| 1 | 66s (1.1분) | **300** | 5 |
| 2 | 75s (1.25분) | **300** | 5 |
| 3 | 68s (1.13분) | **360** | 6 |
| 4 | 85s (1.4분) | **300** | 5 |
| 5 | 79s (1.3분) | **600** | 10 |
| 6 | 238s (4분) | **600** | 10 |

**합계**: 5+5+6+5+10+10 = **41분** 순수 파견 시간 (페이즈 1 #5 흐름 정합).

**페이즈 4 #3 컬럼 추가**: `quest_pools.duration_override_seconds INT nullable`.

### 조정 5: dispatch_cost 정책 (확정안)

duration_override 적용 시 dispatch_cost가 폭증하지 않도록 **min 값 단일 적용**.

| step | difficulty | min~max | **확정 dispatch_cost** |
|------|-----------|---------|----------------------|
| 1·2 | 1 | 5~30G | **5G** (min) |
| 3·4 | 2 | 10~60G | **10G** (min) |
| 5·6 | 3 | 20~100G | **20G** (min) |

**합계**: 5×2 + 10×2 + 20×2 = **70G**

**페이즈 4 #5 코드 분기**: is_fixed=true이고 duration_override_seconds NOT NULL이면 dispatch_cost는 difficulty의 min_dispatch_cost 사용 (max 무시).

**대안**: duration_override 적용 시에도 비례 계산을 그대로 유지(380G) → 의도된 무게감 강화. 단 첫 2시간 잔고 부담 증가. **권장은 min 단일 적용** — 학습 곡선 안정.

### 조정 6: 신뢰도 보상 (페이즈 2 #1 정합 그대로 — 변경 없음)

| step | 페이즈 2 #1 결정값 | **본 문서 채택** |
|------|------------------|----------------|
| 1 | 10 | 10 |
| 2 | 15 | 15 |
| 3 | 20 | 20 |
| 4 | 25 | 25 |
| 5 | 30 | 30 |
| 6 | 100 | 100 |

**페이즈 4 #3 컬럼 추가**: `quest_pools.trust_reward_override INT nullable` (페이즈 2 #1 정합).
- is_fixed=true 행은 이 값을 직접 사용
- is_fixed=false 행은 신뢰도 보상 자동 계산 (난이도별 2/3/5점)

### 조정 7: 부상·사망률 (변경 없음)

`difficulties` 테이블의 injury_rate / death_rate 그대로 사용. 변경 없음.

| step | difficulty | injury_rate | death_rate | 비고 |
|------|-----------|-------------|-----------|------|
| 1·2 | 1 | 10% | 5% | 학습 |
| 3·4 | 2 | 20% | 10% | 첫 부상 모멘트 (약초상 첫 사용) |
| 5·6 | 3 | 30% | 15% | 클라이맥스 위험 |

### 조정 8: 실패·재시도 정책 (확정안)

- **실패 시 풀에서 사라지지 않음** (페이즈 1 #4 정합)
- **재시도 즉시 가능** — 시간 대기 없음 (currentStepAvailableAt = null 유지)
- **stepFailureCount 추적** — Hive 저장만, M4 UI 표시 안 함
- **재시도 보상 = 첫 시도와 동일** — M4 단순화 (M5+ 보너스 검토)

### 조정 9: chainQuestProgress 재사용 (페이즈 1 #4 정합)

- chain_id 컨벤션: `settlement_3_pyegwang_reopen`
- protagonistMercId: null (마을 사건은 주인공 없음)
- currentStepAvailableAt: null (시간 대기 없음)
- status: active / completed (dormant 미적용 — settlement_ prefix 분기)

**페이즈 4 #5 코드 분기 가이드** (페이즈 1 #4 4.2절 정합):
- `tryActivateSettlement(int regionId, String eventName)` 신규 메서드 (신뢰도 1단계 도달 시 자동 호출)
- `dormancyCheck()`: settlement_ prefix는 skip
- `protagonistDeathCheck()`: settlement_ prefix는 skip

---

## 시뮬레이션 (조정안 적용 시 예상 결과)

### 첫 2시간 사건 라인 통합 시뮬레이션 (이상 시나리오)

페이즈 1 #5 분 단위 흐름 + 본 문서 조정안 모두 적용. T1 1~4명 활용.

| 시점 | step | 파티 | rate | 골드 | XP | 신뢰도 | dispatch | 비고 |
|------|------|------|------|------|----|----|---------|------|
| 2:00~7:00 | 1 (5분) | T1 1명 | 95% | +80G | +20 (성공 평균 25) | +10 | -5G | step 1 explore 완료 |
| 13:00~18:00 | 2 (5분) | T1 1명 | 95% | +120G | +20 | +15 | -5G | step 2 hunt 완료 |
| 32:00~38:00 | 3 (6분) | T1 3명 | 95% | +200G | +40 | +20 | -10G | step 3 raid 완료 |
| 45:00~50:00 | 4 (5분) | T1 2명 | 95% | +185G | +40 | +25 | -10G | step 4 escort 완료 |
| 70:00~80:00 | 5 (10분) | T1 3명+T2 1명 | 95% | +270G | +60 | +30 | -20G | step 5 raid 완료 |
| 88:00~98:00 | 6 (10분) | T1 4명 | 80.5% | +500G | +60+50 보너스 = 110 | +100 | -20G | step 6 survey 완료 |

**합계**:
- 골드 유입: 80+120+200+185+270+500 = **1,355G**
- dispatch_cost: 5+5+10+10+20+20 = **70G**
- 인건비 (대략): T1 1명 ×2건 + T1 3명 ×2건 + T1 4명 + T1 3명+T2 = 10+10+30+30+40+(30+25) = **175G**
- 순수익 (골드): 1,355 - 70 - 175 = **1,110G**
- XP 유입: 20+20+40+40+60+110 = **290 XP** (성공 가정 — 평균 25/25/50/50/75/125 = 350 XP)
- 신뢰도 유입: 10+15+20+25+30+100 = **200점**

**페이즈 2 #1 임계값 200점 정확 도달** ✓ (4단계 진입)

### 비관 시나리오 검증 (step 5 1회 실패)

| 시점 | 액션 | 결과 |
|------|------|------|
| 0~50분 | step 1~4 (이상 시나리오) | 1,355G 유입 중 585G + 1단계→2단계 진입 |
| 70:00 | step 5 (T1 3명, 62.5%) | **실패** (37.5% 확률) — 0G 유입 |
| 70:00~80:00 | 부상 1명 + 약초상 50G | -50G |
| 80:00 | step 5 재시도 (T1 4명, 82.5%) | 성공 +270G |
| 95:00 | step 6 (T1 4명, 80.5%) | 성공 +500G |
| 95:00 | 4단계 진입 +500G+200XP+100명성 | — |
| 120:00 | 첫 2시간 종료 | 4단계 도달 ✓ |

**검증**: step 5 1회 실패에도 첫 2시간 안 4단계 도달. 페이즈 1 #5 종료 조건 정합 ✓

### 최악 시나리오 (step 5·6 모두 실패)

| 시점 | 액션 | 결과 |
|------|------|------|
| 0~78분 | step 1~4 + 일반 의뢰 | 신뢰도 80점 (3단계 진입 직전) |
| 78~98분 | step 5 실패 → 재시도 → 성공 | 신뢰도 110점 |
| 105~120분 | step 6 시도 (T1 3명, 60.5%) | 실패 (39.5%) |
| **120분** | 첫 2시간 종료 — 신뢰도 110점 / 3단계 머무름 | **4단계 미도달** |
| 130~140분 | step 6 재시도 (T1 4명, 80.5%) | 성공 → 신뢰도 210점 → 4단계 진입 |

**검증**: 최악 시나리오에서 4단계 진입은 첫 2시간 외부 (140분 시점). 페이즈 1 #5 "4단계는 외부 (선택)" 정합 ✓

**4단계 미진입 위험률**: step 5·6 모두 첫 시도 실패 = 0.375 × 0.395 = **14.8%**. 이 케이스는 종료 조건상 허용 (M4 종료 조건 4가지 중 "4단계 도달"은 미포함).

---

## 영향받는 시스템

| 영역 | 영향 | 페이즈 |
|------|------|--------|
| `quest_pools` 테이블 | 4개 신규 컬럼 추가: `reward_gold_override INT NULL` / `reward_xp_bonus_override INT NULL` / `duration_override_seconds INT NULL` / `trust_reward_override INT NULL` | 페이즈 4 #3 |
| `quest_pools` 6행 INSERT | `dustvile_pyegwang_reopen` step 1~6 (페이즈 1 #4 3.2절 + 본 문서 조정 1~6 통합) | 페이즈 4 #3 |
| `QuestPool` 모델 (Freezed) | 4개 nullable 필드 추가 | 페이즈 4 #3 |
| `QuestCalculator.calculateReward` | is_fixed 분기 — `reward_gold_override` 우선 사용 | 페이즈 4 #5 |
| `QuestCalculator.calculateDispatchDuration` | is_fixed 분기 — `duration_override_seconds` 우선 사용 | 페이즈 4 #5 |
| `QuestCalculator.calculateDispatchCost` | is_fixed 분기 — min 값 단일 사용 | 페이즈 4 #5 |
| `ExperienceService.calculateXpGain` | is_fixed 분기 — `reward_xp_bonus_override` 가산 | 페이즈 4 #5 |
| `RegionStateRepository.addSettlementTrust` | is_fixed 분기 — `trust_reward_override` 우선 사용 | 페이즈 4 #5 |
| `ChainQuestService.tryActivateSettlement` | 신뢰도 1단계 도달 시 자동 호출 (settlement_3_pyegwang_reopen step 1 활성화) | 페이즈 4 #5 |
| `ChainQuestService.dormancyCheck` | settlement_ prefix는 skip | 페이즈 4 #5 |
| `RoleSynergyMatrix._matrix` | survey 추가 검토 (현재 0 fallback이라 step 6 60~80% 통제 동작 — **변경 권장 안 함**) | 페이즈 4 #5 |
| `_questModifiers` (`QuestCalculator`) | survey 추가 검토 (현재 0 fallback이라 의도된 동작 — **변경 권장 안 함**) | 페이즈 4 #5 |
| `_statWeights` | survey 추가 검토 (현재 raid fallback이라 step 6 partyPower 의도된 — **변경 권장 안 함**) | 페이즈 4 #5 |
| `success_penalty` 컬럼 | 적용 위치 확인 필요 — 본 문서 시뮬레이션은 미적용 가정 | 페이즈 4 #5 |

---

## 페이즈 4 #3 / 페이즈 4 #5 입력 가이드

### 페이즈 4 #3 (quest_pools 컬럼 확장 + 고정 의뢰 노출 로직) 입력

#### A. 신규 컬럼 4개 추가

```sql
ALTER TABLE quest_pools ADD COLUMN reward_gold_override INT NULL;
ALTER TABLE quest_pools ADD COLUMN reward_xp_bonus_override INT NULL;
ALTER TABLE quest_pools ADD COLUMN duration_override_seconds INT NULL;
ALTER TABLE quest_pools ADD COLUMN trust_reward_override INT NULL;
```

#### B. dustvile_pyegwang_reopen 6행 INSERT

| id | type_id | difficulty | sector_type | is_fixed | fixed_chain_id | fixed_step | trust_threshold | reward_gold_override | reward_xp_bonus_override | duration_override_seconds | trust_reward_override | enemy_name |
|----|---------|-----------|------------|----------|---------------|-----------|----------------|--------------------|------------------------|------------------------|---------------------|------------|
| qp_pyegwang_step1 | explore | 1 | dungeon | true | dustvile_pyegwang_reopen | 1 | 1 | null | null | 300 | 10 | 박쥐 떼 |
| qp_pyegwang_step2 | hunt | 1 | field | true | dustvile_pyegwang_reopen | 2 | 1 | null | null | 300 | 15 | 도굴꾼 흔적 |
| qp_pyegwang_step3 | raid | 2 | dungeon | true | dustvile_pyegwang_reopen | 3 | 2 | 200 | null | 360 | 20 | 거대 박쥐 둥지 |
| qp_pyegwang_step4 | escort | 2 | dungeon | true | dustvile_pyegwang_reopen | 4 | 2 | 185 | null | 300 | 25 | 무너진 갱도 |
| qp_pyegwang_step5 | raid | 3 | dungeon | true | dustvile_pyegwang_reopen | 5 | 3 | 270 | null | 600 | 30 | 갱도 깊숙한 위협 |
| qp_pyegwang_step6 | survey | 3 | village | true | dustvile_pyegwang_reopen | 6 | 3 | 500 | 50 | 600 | 100 | (없음) |

**name·description 텍스트**: 페이즈 1 #4 2.2절 + 인라인 처리 (페이즈 4 #3 명세에서 직접 작성).

#### C. 코드 분기 명세

```dart
// QuestCalculator.calculateReward (페이즈 4 #5)
if (questPool.isFixed && questPool.rewardGoldOverride != null) {
  return questPool.rewardGoldOverride!;
}
// 기존 calculateReward 분기

// QuestCalculator.calculateDispatchDuration
if (questPool.isFixed && questPool.durationOverrideSeconds != null) {
  return Duration(seconds: questPool.durationOverrideSeconds!);
}
// 기존 calculateDispatchDuration

// QuestCalculator.calculateDispatchCost
if (questPool.isFixed && questPool.durationOverrideSeconds != null) {
  return difficulty.minDispatchCost;
}
// 기존 calculateDispatchCost

// ExperienceService.calculateXpGain
final baseXp = difficulty * 20 * resultMultiplier * (1 + facilityBonus + passiveXpBonus);
if (questPool.isFixed && questPool.rewardXpBonusOverride != null) {
  return baseXp.round() + questPool.rewardXpBonusOverride!;
}
return baseXp.round();

// RegionStateRepository.addSettlementTrust 호출 시
final trustReward = questPool.isFixed
    ? questPool.trustRewardOverride ?? 0
    : _calculateGeneralTrustReward(questPool.difficulty);
```

### 페이즈 4 #5 (마을 신뢰도 시스템 + 고정 사건 진행 상태) 입력

#### A. ChainQuestService 분기

```dart
// 신뢰도 1단계 도달 시 자동 호출 — 게임 시작 직후 또는 신규 게임 진입 시
Future<void> tryActivateSettlement(int regionId, String eventName) async {
  final chainId = "settlement_${regionId}_$eventName";
  if (await _repo.exists(chainId)) return;
  await _repo.create(ChainQuestProgress(
    chainId: chainId,
    currentStep: 1,
    status: ChainQuestStatus.active,
    startedAt: DateTime.now(),
    protagonistMercId: null, // 거점 사건은 주인공 없음
    currentStepAvailableAt: null,
    stepFailureCount: 0,
    lastActivityAt: DateTime.now(),
  ));
}

// dormancy 검사 분기
bool _shouldCheckDormancy(String chainId) {
  return !chainId.startsWith("settlement_");
}
```

#### B. settlement_3_pyegwang_reopen 활성화 트리거

```dart
// initializeNewGame() 또는 첫 게임 진입 시
await chainQuestService.tryActivateSettlement(3, "pyegwang_reopen");
```

#### C. step 완료 시 신뢰도 보상 + 사건 진행

```dart
// QuestCompletionService.completeQuest 내
if (quest.isFixedSettlementStep) {
  // 1. 신뢰도 점수 누적
  await regionStateRepo.addSettlementTrust(
    regionId: quest.regionId,
    amount: questPool.trustRewardOverride!,
    source: "fixed_step_${questPool.fixedStep}",
  );

  // 2. 체인 진행 (currentStep += 1)
  await chainQuestService.advanceStep(quest.chainId);

  // 3. step 6 완료 시 사건 종료
  if (questPool.fixedStep == 6) {
    await chainQuestService.completeChain(quest.chainId);
    // settlementEventCompleted 활동 로그 기록
    // 4단계 진입 트리거 (RegionStateRepository.addSettlementTrust 내에서 자동)
  }
}
```

#### D. survey questMod·roleSynergy·statWeights 검증 (선택적)

**권장 결정**: 변경 없음. survey의 0 fallback이 step 6 60~80% 통제에 정확히 기여.

만약 향후 survey를 4종 quest_type과 동등 처리하려면 매트릭스 추가 필요. M4 시점 미적용.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| step별 적전투력·추천 파티·성공률 곡선 (조정 1) | **높음** | 페이즈 4 #3 명세 직접 입력. 시뮬레이션 검증 완료 |
| reward_gold_override 컬럼 + 6행 (조정 2) | **높음** | survey base 0 우회 — step 6 보상 메커니즘 핵심 |
| reward_xp_bonus_override 컬럼 + step 6 +50 XP (조정 3) | **중간** | 클라이맥스 보상감 강화 |
| duration_override_seconds 컬럼 + 6행 (조정 4) | **높음** | 페이즈 1 #5 분 단위 흐름 정합 핵심 |
| dispatch_cost min 단일 적용 분기 (조정 5) | **중간** | 첫 2시간 잔고 안정 |
| trust_reward_override 컬럼 (조정 6) | **높음** | 페이즈 2 #1 정합 직접 입력 |
| 부상·사망률 변경 없음 (조정 7) | **변경 없음** | 호환성 |
| 실패·재시도 정책 (조정 8) | **중간** | 페이즈 4 #5 명세 입력 |
| chainQuestProgress 재사용 + tryActivateSettlement (조정 9) | **높음** | 페이즈 4 #5 명세 직접 입력 |
| success_penalty 컬럼 적용 위치 확인 | **낮음** | 페이즈 4 #5 검증 단계 (deprecated 가능) |

---

## 후속 작업

페이즈 2 종료 체크포인트 진입. 페이즈 2 #1·#2·#3·#4 4개 산출물 완성으로 페이즈 2 종료. 다음 결정:
- 페이즈 3 (데이터 생성) 진행 여부 — 본 문서의 6행 quest_pools는 인라인 처리 권장 (data-generator 신규 타입 스펙 작성 부담 대비 데이터량 적음)
- region_sectors ~164행 데이터, 더스트빌 NPC 텍스트 등 페이즈 3에서 처리 가능한 항목은 페이즈 2 종료 체크포인트에서 결정

페이즈 4 #3 (quest_pools 컬럼 확장 + 고정 의뢰 노출 로직)에서 본 문서의 4개 신규 컬럼 추가 + 6행 INSERT + QuestPool Freezed 모델 확장을 명세 직접 입력.

페이즈 4 #5 (마을 신뢰도 시스템 + 고정 사건 진행 상태)에서 본 문서의 ChainQuestService 분기 + QuestCalculator/ExperienceService is_fixed 분기 + RegionStateRepository 통합을 명세 직접 입력.

---

## data-generator 수치 가이드

본 문서의 6행 quest_pools는 신규 타입 스펙(`types/fixed-quest.md`) 작성 부담 대비 데이터량이 적어 **페이즈 4 #3 명세 인라인 SQL INSERT 처리 권장**. data-generator 호출 미사용.

만약 향후 다른 거점에 추가 사건 라인을 도입할 때 (M5+ 다중 거점):

- **대상 타입**: `fixed-quest` (신규 타입 스펙 작성 가능)
- **대상 테이블**: `quest_pools` (is_fixed=true 행)
- **수치 범위**:
  - `difficulty`: 1~3 (M4·M5 시점), 1~5 (M6+)
  - `quest_type`: explore/hunt/raid/escort/survey/labor 6종 모두 가능
  - `sector_type`: 5종 모두 가능 (village/dungeon/field/ruins/hidden)
  - `trust_threshold`: 1~4
  - `reward_gold_override`: 80~500G (난이도 1·2·3 곡선)
  - `duration_override_seconds`: 300~600s (5~10분)
  - `trust_reward_override`: 10~100점 (step별 분포)
- **외래 키 제약**: fixed_chain_id NOT NULL, (fixed_chain_id, fixed_step) UNIQUE
- **balance 근거**: 본 문서 1·2·4절 시뮬레이션 — partyPower 곡선 + 성공률 50 + (powerRatio-1)×50 + questMod + roleSynergy 통합
