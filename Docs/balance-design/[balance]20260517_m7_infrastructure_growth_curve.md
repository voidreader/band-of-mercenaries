# M7 마을 인프라 성장 비용·요구 사건 수 확정 밸런스 분석 리포트

> 작성일: 2026-05-17
> 유형: 밸런스 분석 + 수치 조정 제안 (M7 마일스톤 — 페이즈 2 산출물 3/3, 페이즈 2 마지막)
> 분석 대상: 임계 flag 수 (2/4/6), HerbalistService infra multiplier 3종, 광장 이정표 효과, 신규 레시피 분포, 외래 좌판 가격, 단계 전이 보상
> 선행 문서:
> - `Docs/content-design/[content]20260517_m7_settlement_infrastructure_growth.md` — M7 페이즈 1 #3 4단계 구조 + 거점 효과 multiplier 컨셉
> - `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md` — M7 페이즈 1 #4 5~8시간 흐름 + flag 누적 곡선
> - `Docs/balance-design/[balance]20260517_m7_material_economy_curve.md` — M7 페이즈 2 #1 외래 좌판 거래 가격 컨셉
> - `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart:25,30` — M4 신뢰도 임계값 0/30/80/200 + 보상 실측
>
> 후속:
> - 페이즈 3 #5 "마을 인프라 성장 narrative + 체인 단계" — 본 문서의 6개 신규 레시피 분포 + 단계 전이 보상 텍스트 입력
> - 페이즈 4 #4 "마을 인프라 성장 시스템 + 진입점 통합" — 본 문서의 모든 수치 상수를 코드 상수로 매핑

---

## 현재 상태

### 1. M4 신뢰도 시스템 실측 (코드 region_state_repository.dart:25,30)

```dart
// 신뢰도 단계 임계값 (코드 line 25)
static const Map<int, int> _trustThresholds = {1: 0, 2: 30, 3: 80, 4: 200};

// 단계 진입 일회성 보상 (코드 line 30)
static const Map<int, ({int gold, int xp, int rep})> _trustRewards = {
  2: (gold: 100, xp: 50, rep: 0),    // 인지
  3: (gold: 200, xp: 100, rep: 0),   // 친근
  4: (gold: 500, xp: 200, rep: 100), // 소속
};
```

→ M7 페이즈 1 #4 추정값 (0/30/80/200) **정확히 일치** ✅. 페이즈 1 #4 시뮬레이션 신뢰도 곡선이 실데이터 기반이었음을 확인.

### 2. HerbalistService 현재 multiplier (코드 herbalist_service.dart)

```dart
static const Map<int, double> _costMultipliers = {1: 1.5, 2: 1.0, 3: 0.9, 4: 0.8};
static const Map<int, int> _cooldownMinutes = {1: 45, 2: 30, 3: 15, 4: 10};
static const Map<int, double> _gatheringMultipliers = {1: 1.0, 2: 1.0, 3: 1.1, 4: 1.2};

static int calculateCost(int trustLevel) => (50 * (_costMultipliers[trustLevel] ?? 1.0)).round();
```

**기본 약초상 회복 비용**: 50G × trust_modifier
- Trust 1 (의심): 75G
- Trust 2 (인지): 50G
- Trust 3 (친근): 45G
- Trust 4 (소속): 40G

**기본 쿨다운**: 분 단위 (Trust 1=45 / 2=30 / 3=15 / 4=10)
**기본 채집 배수**: Trust 3=+10% / 4=+20%

### 3. 페이즈 1 #4 flag 누적 곡선 (M7 시뮬레이션)

| 시점(분) | 누적 flag | 트리거 사건 |
|---------|---------|------------|
| 120 | 1 | r3 폐광 step 6 완료 (M4→M7 연결) |
| 170 | 2 | r31 chain_roadside_shrine 완주 |
| 215 | 3 | r9 거대 야수 처치 |
| 255 | 4 | r31 도적 5회 cumulative cap 도달 |
| 290 | 5 | r127 유목민 친교 |
| 330 | 6 | r10 chain_windrunner_trail 완주 |
| 380 | 7 | r38 chain_ironbound_pact 완주 |
| 430 | 8 | r146 안개 해소 |

---

## 데이터 분석

### 1. 임계 flag 수 (페이즈 1 #3 권장 2/4/6 검증)

**페이즈 1 #4 시뮬레이션과 비교**:

| Tier 임계 | 도달 시점 (페이즈 1 #4) | M7 8시간 중 비중 | 체감 |
|----------|---------------------|----------------|------|
| Tier 2 (2 flag) | **170분 (2시간 50분)** | 35% | 외출 시작 후 50분만에 인프라 첫 변화 — 적정 |
| Tier 3 (4 flag) | **255분 (4시간 15분)** | 53% | 중반 시점에 외래 좌판 신설 — 적정 |
| Tier 4 (6 flag) | **330분 (5시간 30분)** | 69% | 클라이맥스 후 안정화 시간 충분 — 적정 |

**대안 검토**:

| 옵션 | Tier 2 | Tier 3 | Tier 4 | 8개 중 여유 | 체감 평가 |
|------|--------|--------|--------|-----------|----------|
| A (권장) | **2** | **4** | **6** | 2개 | 페이즈 1 #4 정합, 적정 곡선 |
| B (느림) | 3 | 5 | 7 | 1개 | Tier 4 도달이 6.5시간 후로 미뤄짐 — 클라이맥스 약함 |
| C (빠름) | 2 | 3 | 5 | 3개 | Tier 4 도달이 4.5시간만에 — 너무 빠름, 플래토 길어짐 |

**채택: A안 (2/4/6)**. 페이즈 1 #4 시뮬레이션과 정확히 정합. 8개 중 6개 = 2개 여유로 안개·도굴꾼 후반 사건 자유도 제공.

### 2. 거점 효과 multiplier 정량 (HerbalistService 확장)

**페이즈 1 #3 권장값 검증 + 신규 cooldown multiplier 추가**:

```dart
// 신규 추가 — infraTier 1~4
static const Map<int, double> _infraCostMultipliers = {1: 1.0, 2: 1.0, 3: 0.9, 4: 0.8};
static const Map<int, double> _infraGatheringMultipliers = {1: 1.0, 2: 1.05, 3: 1.10, 4: 1.20};
static const Map<int, double> _infraCooldownMultipliers = {1: 1.0, 2: 1.0, 3: 0.85, 4: 0.70}; // 신규
```

**곱셈 합산 시뮬레이션 (Trust × Infra)**:

| Trust + Infra | cost (50G × T × I) | cooldown (45분 × T_cd × I_cd) | gathering (1.0 × T_g × I_g) |
|---------------|-------------------|------------------------------|---------------------------|
| T1 (의심) + Infra 1 (고립) | 50×1.5×1.0 = **75G** | 45 × 1.0 = **45분** | 1.0 × 1.0 = **1.0×** |
| T2 (인지) + Infra 2 (연결) | 50×1.0×1.0 = **50G** | 30 × 1.0 = **30분** | 1.0 × 1.05 = **1.05×** |
| T3 (친근) + Infra 3 (거점화) | 50×0.9×0.9 = **41G** | 15 × 0.85 = **13분** | 1.1 × 1.10 = **1.21×** |
| **T4 (소속) + Infra 4 (변방의 중심)** | 50×0.8×0.8 = **32G** | 10 × 0.70 = **7분** | 1.2 × 1.20 = **1.44×** |

**기본 대비 변화율 (Trust 1 + Infra 1 = 75G 기준)**:
- T2 + Infra 2: -33% 비용 / 쿨다운 -33% / 채집 +5%
- T3 + Infra 3: **-45% 비용** / 쿨다운 **-71%** / 채집 **+21%**
- T4 + Infra 4: **-57% 비용** / 쿨다운 **-84%** / 채집 **+44%**

**검증 — T4 강력함 우려**:
- Trust 4 + Infra 4 도달은 페이즈 1 #4 기준 **6시간 시점** (Trust 4 = 폐광 step 6 완료 ~120분 / Infra 4 = 330분)
- M7 종료 시점(8시간) 기준 32G 즉시 회복 + 7분 쿨다운 = 강력하나 **이미 5~6시간 플레이 후 도달**
- 체감: "마을이 정말로 풍요로워졌다"의 정서적 보상 — 의도된 동작 ✅
- 경제 충격: 약초상 비용 누적 차이 (M7 8시간) = (75 - 32) × 평균 사용 4회 = **-170G** 차이 — 무시 가능

**채택: 권장 multiplier 그대로**. 단, _infraCooldownMultipliers는 페이즈 1 #3에서 명시 안 된 항목이므로 본 문서에서 신규 정의.

### 3. 광장 이정표 효과 (Tier 2 이후 적용)

페이즈 2 #1 분석 결과 통합:
- **이동 시간 -10%** (region 3 출발/도착 한정)
- **재료 수급 +3%** (5~8시간 누적 기준 — 페이즈 2 #1 4절)
- **외출 빈도 +11%** (이동 시간 절감으로 추가 의뢰 1~2건 가능)

**페이즈 4 #4 명세 입력 코드 위치**:
```dart
// MovementService._calculateDistance() 분기 (페이즈 4 #3 + #4 통합)
int finalDistance = baseDistance;
final infraTier = regionStateRepo.getOrCreate(3).currentInfrastructureTier;
if (infraTier >= 2 && (fromRegion == 3 || toRegion == 3)) {
  finalDistance = (finalDistance * 0.9).round(); // -10%
}
```

### 4. 신규 레시피 14~16개 정합 검증

페이즈 2 #1 시뮬레이션 결과 6개 신규 레시피 확정:

| Tier | 신규 레시피 | result 카테고리 | unlock_condition (페이즈 1 #3 4절) |
|------|----------|---------------|----------------------------------|
| Tier 2 | 야수 가죽 도구 | personal_equipment T2 | `{type: "regionFlag", flag: "region_9_giant_beast_killed"}` |
| Tier 2 | 들꽃 약초 향료 | consumable T1 | `{type: "regionFlag", flag: "region_31_shrine_quest_completed"}` |
| Tier 3 | 유목민 가죽 장비 | personal_equipment T2 | `{type: "all", conditions: [infraTier 3, region_127_nomad_friendly]}` |
| Tier 3 | 해안 약물 | consumable T1 | `{type: "regionFlag", flag: "region_127_nomad_friendly"}` |
| Tier 3 | 안개 늪 인장 장신구 | guild_equipment T2 | `{type: "regionFlag", flag: "region_146_mist_cleared"}` |
| Tier 4 | 부서진 요새 인장 장비 | guild_equipment T3 | `{type: "all", conditions: [infraTier 4, region_38_ironbound_pact_completed]}` |

→ **M5 기존 10개 + M7 신규 6개 = 총 16개** (페이즈 1 #3 권장 14~16개 상한)

**분포 분석**:
- Tier 2 해금: 2개 (170분 시점)
- Tier 3 해금: 3개 (255분 시점)
- Tier 4 해금: 1개 (330분 시점)

→ Tier 3 도달 후 5시간 시점에 누적 5개 신규 레시피 노출. 페이즈 1 #4 시나리오 "5시간 시점 제작 목표 2+" 충족 ✅

### 5. 외래 좌판 거래 가격 곡선 (페이즈 2 #1 가격 + Tier 4 할인 결정)

**Tier 4 -20% 할인 적용 여부 분석**:

| 옵션 | 설명 | 영향 |
|------|------|------|
| A (할인 없음) | Tier 3·4 동일 가격 | Tier 4 도달 보상 시각 효과만 (잔치 분위기) |
| B (Tier 4 -20% 할인) | 거점 효과 cost multiplier 0.8과 동일 | 시간 절약 + 골드 절약 이중 보상 |

**채택: B안 (Tier 4 -20% 할인)**. 이유:
- 약초상 cost multiplier가 Tier 4에서 0.8× 적용되는 것과 통일성 유지
- Tier 4 도달이 5.5시간 + 골드 누적 충분 시점 → -20% 할인 체감 가능
- 외래 좌판 거래 골드 영향 (페이즈 2 #1 시뮬레이션): -370G → -296G (74G 추가 절약)

**최종 가격 표**:

| 재료 (페이즈 2 #1 권장) | Tier 3 가격 | Tier 4 가격 (-20%) |
|---------------------|-----------|------------------|
| mat_herb_wildflower (r31 T1) | 60G | **48G** |
| mat_herb_seaweed (r127 T1) | 60G | **48G** |
| mat_hide_nomad_strap (r127 T2) | 120G | **96G** |
| mat_herb_wind (r10 T2) | 150G | **120G** |
| mat_herb_poison (r146 T2) | 150G | **120G** |
| mat_relic_swamp_seal (r146 T2) | 200G | **160G** |
| mat_relic_burnt_seal (r38 T3) | 250G | **200G** |
| mat_relic_ancient_seal_piece (r3 T3) | 300G | **240G** |

**Tier 3 거래 종류**: 2~3종 (페이즈 1 #3 2.4절 권장 — wildflower / seaweed / nomad_strap 노출)
**Tier 4 거래 종류**: 4~6종 (전체 노출 + 할인 적용)

**페이즈 1 #3 2.4절 권장 "Tier 4 거래 종류 +50%" 정량**: Tier 3 3종 → Tier 4 5~6종 → **+67%~+100%** (페이즈 1 #3 +50% 권장 초과). 본 문서에서 +67% 조정.

### 6. 단계 전이 일회성 보상 정량 (M4 신뢰도 보상 패턴 답습)

M4 신뢰도 보상 실측 비교:

| Tier | M4 신뢰도 보상 | M7 인프라 권장 보상 |
|------|--------------|------------------|
| Tier 2 (170분) | trust 2: 100G + 50XP + 0 명성 | **100G + 100XP + 50 명성** |
| Tier 3 (255분) | trust 3: 200G + 100XP + 0 명성 | **200G + 200XP + 100 명성** |
| Tier 4 (330분) | trust 4: 500G + 200XP + 100 명성 | **500G + 500XP + 300 명성 + 위업 "변방의 영주"** |

**M4 신뢰도 보상과의 차별화**:
- M7 인프라 보상은 **명성·XP 비중 더 큼** — M4는 사회적 친밀도, M7은 마을 성장의 외부 영향력
- Tier 4 보상은 위업 "변방의 영주" 추가 — M6 hook 7번째 `region_state_transition` 또는 신규 `infrastructure_tier` hook으로 발급

**명성 합계 검증**: 50 + 100 + 300 = **450 명성** 가산
- M7 5~6시간 시점 누적 명성 ~2000~3500 (페이즈 1 #4 시나리오) 중 **약 15~22% 기여** — 인프라 진행이 명성에 의미 있는 영향 (의도된 동작)

**XP 합계 검증**: 100 + 200 + 500 = **800 XP** 가산
- Tier 3 용병 임계 350 → Tier 4 용병 임계 850 → 800 XP는 Tier 3 용병 1명 레벨 1→2 보장 + Tier 4 용병 1명 거의 레벨 4 도달
- 적정 (M7 종료 시점 평균 용병 레벨 3~4 진입)

**골드 합계 검증**: 100 + 200 + 500 = **800G** 가산
- M7 5~6시간 시점 누적 골드 (페이즈 1 #4 추정) 약 2000~3000G
- 800G = **약 27~40% 기여** — 인프라 보상이 의미 있는 골드 보상 (의도된 동작)

### 7. 8개 flag 진행 곡선 정합 검증

페이즈 1 #4 표 vs 본 문서 임계값 적용 시 단계 진입 시점:

| 시점(분) | 누적 flag | 인프라 Tier 변화 |
|---------|---------|----------------|
| 120 | 1 | Tier 1 (변화 없음 — 임계 2개 미달) |
| **170** | 2 | **Tier 1 → 2 진입** (다이얼로그 + 보상 100G/100XP/50명성) |
| 215 | 3 | Tier 2 (변화 없음 — 임계 4개 미달) |
| **255** | 4 | **Tier 2 → 3 진입** (다이얼로그 + 보상 200G/200XP/100명성 + 외래 좌판 신설) |
| 290 | 5 | Tier 3 (변화 없음) |
| **330** | 6 | **Tier 3 → 4 진입** (다이얼로그 + 보상 500G/500XP/300명성 + 위업 "변방의 영주") |
| 380 | 7 | Tier 4 (변화 없음 — 이미 최고 단계) |
| 430 | 8 | Tier 4 (변화 없음) |

→ 8시간 동안 단계 전이 다이얼로그 **3회 발동** — medium priority 채널 적정. M4 신뢰도 다이얼로그 4회 + M7 인프라 3회 + 페이즈 1 #2 region_state 1회 + M3 chain·transform 2~3회 = 총 약 10~11회 다이얼로그 발동 → 8시간 분산 ✅

---

## 문제점

### 1. Tier 3 단계 머무름 시간 짧음 (255분 → 330분 = 75분만)

Tier 3는 외래 좌판 신설이라는 가장 큰 변화 단계지만 머무름 시간 75분 ≈ 1.25시간으로 짧음. Tier 3 효과 (외래 좌판 거래·신규 레시피 2~3개) 충분히 체감할 시간 부족 우려.

**완화 방안**:
- 페이즈 1 #4 시나리오는 **이상적 시나리오** — 실제 플레이어는 시설 건설·이동·실패 등으로 75분이 90~120분으로 늘어남
- Tier 3 효과는 외래 좌판 거래·신규 레시피처럼 영구 — Tier 4 도달 후에도 계속 사용 가능
- **추가 권고 없음** — 페이즈 1 #4 시나리오 그대로 채택

### 2. Tier 4 도달 후 안정화 시간 (330분 ~ 480분 = 150분 = 2.5시간)

Tier 4 도달 후 2.5시간 동안 더 발전할 인프라가 없음. "할 게 없는 시간" 우려.

**완화 방안**:
- Tier 4 도달 후 7·8번째 flag (r38 ironbound + r146 mist) 진행이 핵심 활동
- 위업 "변방의 영주" 외에도 M6 위업 hook 다수 발동 가능 (region_pacified 7개 위업)
- 외래 좌판 거래 종류 확장 + 신규 레시피 "부서진 요새 인장 장비" 제작 활동 잔여
- 페이즈 1 #4 시나리오 6~8시간 구간 (J 구간)의 마지막 사건 + Tier 4 보상 활용이 분량 정합 ✅

### 3. 8개 flag 중 미사용 가능 (2개 여유)

페이즈 1 #4 시나리오상 7개만 필수, 1개 (r10 chain) 또는 (r127 friendly)는 선택. 페이즈 2 #3 입력 가이드:

| 페르소나 | 도달 flag | Tier 4 도달 가능 여부 |
|---------|---------|-------------------|
| 적극 | 8/8 | Tier 4 (5.5시간 시점) ✅ |
| 평균 | 7/8 | Tier 4 (6시간 시점) ✅ |
| 보수 | 6/8 | Tier 4 (8시간 시점, 마지막) ✅ |

→ 6개 임계는 보수 페르소나도 Tier 4 도달 가능 — 적정 ✅

---

## 플레이어 체감 분석

### 1. 단계 전이 다이얼로그 빈도 (3회) — 적정

8시간 동안 3회 발동 = 평균 2.7시간/회. 너무 잦지도, 드물지도 않음. M4 신뢰도 4회와 합산해도 평균 1.5시간/회 — 적정.

### 2. 보상 체감 곡선

- Tier 2 (170분): 100G/100XP/50명성 = "작은 진전감" (5단계 첫 발견 단계의 보상 수준)
- Tier 3 (255분): 200G/200XP/100명성 + 외래 좌판 = "중간 마일스톤"
- Tier 4 (330분): 500G/500XP/300명성 + 위업 = "큰 클라이맥스"

→ 점진적 보상 증가 곡선 ✅. 가산 비율 1:2:5 (M4 신뢰도와 동일 패턴)

### 3. 거점 효과 누적 체감

- T1 (의심) + Infra 1 (고립) — 약초상 비용 75G, 쿨다운 45분
- T4 (소속) + Infra 4 (변방의 중심) — 약초상 비용 **32G**, 쿨다운 **7분**

→ M7 종료 시점 -57% 비용, -84% 쿨다운 = "마을이 정말로 풍요로워졌다" 강한 체감 ✅

### 4. 외래 좌판 Tier 4 할인 체감

| 거래 시점 | 가격 | 체감 |
|---------|------|------|
| Tier 3 첫 거래 (~260분) | 250G (탄 인장 파편) | "외래 상인이 비싸게 받는다" |
| Tier 4 동일 거래 (~340분 이후) | **200G** (-20%) | "이제 외래 상인이 자네를 알아본다" |

→ 골드 절약 + 정서적 보상 ✅

---

## 조정 제안

### 1. 임계 flag 수 (페이즈 1 #3 권장 그대로 채택)

| Tier 전이 | flag 임계 | 이유 |
|----------|---------|------|
| 1 → 2 | **2개** | 페이즈 1 #4 170분 시점 정합 |
| 2 → 3 | **4개** | 페이즈 1 #4 255분 시점 정합 |
| 3 → 4 | **6개** | 페이즈 1 #4 330분 시점 정합, 8개 중 2개 여유 |

### 2. 거점 효과 multiplier 정량 (페이즈 1 #3 권장 + cooldown 신규)

```dart
// HerbalistService 신규 상수 (페이즈 4 #4 명세 입력)
static const Map<int, double> _infraCostMultipliers = {1: 1.0, 2: 1.0, 3: 0.9, 4: 0.8};
static const Map<int, double> _infraGatheringMultipliers = {1: 1.0, 2: 1.05, 3: 1.10, 4: 1.20};
static const Map<int, double> _infraCooldownMultipliers = {1: 1.0, 2: 1.0, 3: 0.85, 4: 0.70};

// 메서드 시그니처 확장 (default 값으로 하위호환)
static int calculateCost(int trustLevel, {int infraTier = 1}) {
  final base = 50;
  final trust = _costMultipliers[trustLevel] ?? 1.0;
  final infra = _infraCostMultipliers[infraTier] ?? 1.0;
  return (base * trust * infra).round();
}
```

### 3. 광장 이정표 효과 (페이즈 1 #3 그대로 채택)

- 이동 시간 -10% (region 3 출발/도착 한정)
- 활용 정량: 5~8시간 누적 재료 수급 +3%, 외출 빈도 +11%

### 4. 신규 레시피 6개 분포 확정 (페이즈 1 #3 권장 그대로)

위 데이터 분석 4절 표. M5 10개 + M7 6개 = 총 16개.

### 5. 외래 좌판 거래 가격 + Tier 4 -20% 할인

| 재료 | Tier 3 가격 | Tier 4 가격 (-20%) |
|------|-----------|------------------|
| T1 region_exclusive | 60G | 48G |
| T2 region_exclusive | 120~150G | 96~120G |
| T3 region_exclusive | 250~300G | 200~240G |

거래 종류: Tier 3 = 2~3종, Tier 4 = 4~6종 (확장 +67%).

### 6. 단계 전이 일회성 보상

| Tier | 골드 | XP | 명성 | 추가 |
|------|------|-----|------|------|
| 2 (연결) | 100G | 100XP | 50 명성 | — |
| 3 (거점화) | 200G | 200XP | 100 명성 | 외래 좌판 신설 |
| 4 (변방의 중심) | 500G | 500XP | 300 명성 | **위업 "변방의 영주"** (M6 hook 7번째) |

**총 합계**: 800G + 800XP + 450 명성 + 위업 1개

---

## 시뮬레이션

### 시나리오: 평균 페르소나 5~8시간 흐름 (페이즈 1 #4 정합)

**HerbalistService 누적 사용 시뮬레이션** (5시간 동안 약초상 4회 사용 가정):

| 시점 | trust | infra | 비용 합계 | 쿨다운 누적 |
|------|-------|-------|---------|------------|
| 60~120분 (M4) | 2 | 1 | 50G × 1회 = 50G | 30분 1회 |
| 120~170분 | 3 | 1 | 45G × 1회 = 45G | 15분 1회 |
| 170~255분 | 3 | 2 | 45G × 1회 = 45G | 15분 1회 |
| 255~330분 | 4 | 3 | 41G × 1회 = 41G | 13분 1회 |
| 330~480분 | 4 | 4 | 32G × 2회 = 64G | 7분 2회 |
| **8시간 합계** | — | — | **245G** | 합계 **87분** 쿨다운 대기 |

**Trust + Infra 미적용 (M4 단독) 시 비교**:
- 8시간 동안 trust 1~4만 적용: 75 + 50 + 50 + 45 + 32×2 = **252G** (-7G 차이만)
- 차이 미미 — 단, Trust 4 + Infra 4 시점의 32G 비용 + 7분 쿨다운은 강한 체감

### 단계 전이 보상 누적 시뮬레이션

평균 페르소나 5~8시간 종료 시점 누적:
- 신뢰도 4단계 보상 (M4): 100 + 200 + 500 = 800G + 50 + 100 + 200 = 350XP + 0 + 0 + 100 = 100명성
- 인프라 4단계 보상 (M7): 100 + 200 + 500 = 800G + 100 + 200 + 500 = 800XP + 50 + 100 + 300 = 450명성

**합계 (M4 + M7)**:
- 골드: **1,600G** (M7 8시간 총 누적 골드 ~5000~8000G의 20~32%)
- XP: **1,150 XP** (M7 종료 시점 평균 용병 6명 × 약 200 XP)
- 명성: **550 명성** (E랭크 진입 명성 300의 1.8배, D랭크 진입 2000의 27.5%)

→ 보상이 명성·XP 위주로 의미 있는 기여 ✅ 페이즈 1 #4 시뮬레이션상 명성 누적 ~3500~5000 추정과 정합

### 외래 좌판 활용 시뮬레이션

활용 페르소나 (Tier 3 도달 후 적극 거래):
- Tier 3 첫 거래 (1회, ~260분): 유목민 가죽끈 120G
- Tier 4 거래 (2회, ~340분, ~440분): 탄 인장 파편 200G + 야수 송곳니 96G
- **외래 좌판 총 골드 소비**: 120 + 200 + 96 = **416G**

미활용 페르소나 (모두 채집):
- 추가 외출 시간 ~60~90분 = 추가 의뢰 8~12건 처리 가능 = 추가 골드 약 +400~600G
- **외래 좌판 + 활용 = 시간 거래** — 균형적 선택

---

## data-generator 수치 가이드

페이즈 3 #5 (마을 인프라 narrative + 체인 단계) 데이터 생성 시 적용 가이드:

- **대상 타입**: `quest-narrative` (재사용) + `crafting-recipe` (재사용, M5 패턴)
- **대상 테이블**: 
  - `quest_narratives` 또는 단계 전이 텍스트 인라인 (페이즈 4 #4 결정)
  - `crafting_recipes` (6행 INSERT, M7 신규 레시피)
- **수치 범위**:
  - **신규 레시피 6행** (페이즈 1 #3 4절 unlock_condition_json 그대로 적용):
    - Tier 2: 2개 (regionFlag 단순 조건)
    - Tier 3: 3개 (regionFlag 또는 all 복합 조건)
    - Tier 4: 1개 (all 복합 조건 — infraTier 4 + regionFlag)
  - **재료 요구량** (페이즈 2 #1 시뮬레이션 정합):
    - Tier 2 레시피: 재료 총 수량 3~5개
    - Tier 3 레시피: 재료 총 수량 4~6개
    - Tier 4 레시피: 재료 총 수량 5~7개
  - **result_quantity**: 모두 1 (M5 패턴 답습)
  - **단계 전이 narrative 텍스트** (페이즈 1 #4 3절 다이얼로그 텍스트 3개 + NPC 인사말 변주):
    - Tier 2/3/4 진입 다이얼로그 텍스트 3행
    - 외래 상인 NPC 인사말 + 거래 멘트 5~7행
    - 인프라 단계별 거점 3종 NPC 인사말 첨부 8행 (Tier 2/3/4 × 거점 3종, 일부 통합)
    - **합계 약 16~18행** narrative 또는 별도 NPC 테이블 (페이즈 4 #4 결정)
- **외래 키 제약**:
  - crafting_recipes.unlock_condition_json 신규 type (`regionFlag`, `all`, `any`) — 페이즈 4 #4 명세에서 CraftingService.evaluateState() 분기 추가 후 INSERT
  - 신규 레시피 result_item_id는 페이즈 3 #2 신규 items 8행 또는 기존 items 활용
- **balance 근거**: 본 문서 모든 절 (임계 2/4/6 + multiplier + 보상 + 가격)

### 검증 항목

- crafting_recipes 6행 INSERT 후 unlock_condition_json `regionFlag` 활용 3행 / `all` 복합 활용 3행
- 6개 신규 레시피 재료 요구량 합계: M5 + M7 = 16개 레시피 × 평균 5개 재료 = 80~96개 재료 — 8시간 누적 수급 50~60개 (페이즈 2 #1)의 1.3~1.6배 → 모든 레시피 1회 제작 불가능 (의도) — **플레이어가 우선순위 선택** 게임플레이 보장
- 외래 좌판 거래 가격 데이터는 페이즈 4 #4 명세 코드 상수 처리 (DB 미저장 권장)
- 단계 전이 보상 (100/200/500 골드 등)도 페이즈 4 #4 명세 코드 상수 처리

### 페이즈 4 #4 명세 입력 요약

```dart
// 페이즈 4 #4 명세 — 인프라 단계 전이 시스템 상수
class SettlementInfrastructureConfig {
  // 임계 flag 수 (Tier → 필요 flag 합)
  static const Map<int, int> infraTierThresholds = {1: 0, 2: 2, 3: 4, 4: 6};

  // 단계 전이 일회성 보상
  static const Map<int, ({int gold, int xp, int rep})> infraTierRewards = {
    2: (gold: 100, xp: 100, rep: 50),
    3: (gold: 200, xp: 200, rep: 100),
    4: (gold: 500, xp: 500, rep: 300),
  };

  // 외래 좌판 거래 가격 (Tier 3 기준, Tier 4 = -20%)
  static const Map<String, int> foreignStallBasePrices = {
    'mat_herb_wildflower': 60,
    'mat_herb_seaweed': 60,
    'mat_hide_nomad_strap': 120,
    'mat_herb_wind': 150,
    'mat_herb_poison': 150,
    'mat_relic_swamp_seal': 200,
    'mat_relic_burnt_seal': 250,
    'mat_relic_ancient_seal_piece': 300,
  };

  // Tier 4 할인율
  static const double foreignStallTier4Discount = 0.80; // -20%

  // 광장 이정표 효과
  static const double signpostDistanceMultiplier = 0.90; // -10%
  static const int signpostMinTier = 2; // Tier 2부터 활성

  // M7 인프라 관련 8개 flag
  static const Set<String> infrastructureRelevantFlags = {
    'region_3_pyegwang_reopen_completed',
    'region_31_bandits_cleared',
    'region_31_shrine_quest_completed',
    'region_127_nomad_friendly',
    'region_9_giant_beast_killed',
    'region_10_windrunner_chain_completed',
    'region_146_mist_cleared',
    'region_38_ironbound_pact_completed',
  };
}
```
