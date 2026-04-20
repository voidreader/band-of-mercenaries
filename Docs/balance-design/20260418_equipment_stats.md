# 개인 장비 스탯 보정 수치표 밸런스 분석 리포트

> 작성일: 2026-04-18
> 유형: 수치 조정 제안 (M2a 마일스톤 페이즈 2 — 산출물 1/3)
> 분석 대상: 개인 장비 6종의 티어 2~5별 `effect_json` 스탯 보정 범위, 자유 장착 상한, 전설 1종 강도 정책
> 입력:
> - `Docs/content-design/[content]20260418_item_taxonomy.md` (분류 체계 — 슬롯별 효과 축, 자유 장착)
> - `Docs/content-design/[content]20260418_initial_item_set.md` (6종 컨셉 — 슬롯 배분, 전설 후보)
> - `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` (partyPower 가중치)
> - `Docs/balance-design/20260417_dispatch_synergy_values.md`, `20260417_faction_passive_values.md` (±10%p / +20%p 기존 상한 체계)

---

## 현재 상태

### 장비 보정이 공식에 진입하는 경로

장비는 **직접 성공률 보정이 아니라** 용병 스탯(STR/INT/VIT/AGI)을 올려 `partyPower`에 간접 기여한다:

```
effectiveStr/Int/Vit/Agi = (baseStat + equipmentBonus + permanentStatGain) × (1 + levelBonus) × fatigueMod
  ↓
partyPower = Σ(effectiveStr × w_str + effectiveInt × w_int + effectiveVit × w_vit + effectiveAgi × w_agi)
  ↓
successRate 기여 = (partyPower / enemyPower − 1) × 50
  ↓
기존 ±10%p(role/trait) · +20%p(세력·명성 공유) 상한 시스템과 독립적으로 작용
```

**핵심 관찰**: 장비 효과는 **partyPower 스케일 안에서만 작동**하므로 기존 상한 체계와 충돌하지 않지만, 대신 `partyPower`가 무제한 증가할 수 있어 별도 가이드라인이 필요하다.

### partyPower 가중치 (기존, 변경 없음)

| quest_type | STR | INT | VIT | AGI |
|:---:|:---:|:---:|:---:|:---:|
| raid | **0.70** | 0.10 | 0.10 | 0.10 |
| hunt | **0.50** | 0.10 | 0.10 | 0.30 |
| escort | 0.20 | 0.10 | **0.60** | 0.10 |
| explore | 0.10 | **0.45** | 0.15 | 0.30 |

### 85개 job 티어별 스탯 분포 (Supabase)

| 티어 | STR 범위(평균) | INT 범위(평균) | VIT 범위(평균) | AGI 범위(평균) | base 합 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| T1 | 4~16 (**7.6**) | 3~15 (**5.8**) | 24~35 (**26.3**) | 48~69 (**53.3**) | **93.0** |
| T2 | 15~25 (**20.2**) | 7~35 (**12.4**) | 40~75 (**52.1**) | 41~68 (**53.5**) | **138.2** |
| T3 | 20~33 (**25.0**) | 10~42 (**21.5**) | 52~97 (**68.6**) | 41~65 (**51.2**) | **166.3** |
| T4 | 25~42 (**31.3**) | 12~52 (**35.2**) | 64~120 (**83.1**) | 39~63 (**49.3**) | **198.9** |
| T5 | 30~50 (**37.7**) | 14~65 (**37.5**) | 76~142 (**102.0**) | 38~62 (**46.6**) | **223.8** |

**관찰**:
- STR은 T1→T5 5.0배, VIT은 3.9배, INT은 6.5배로 증가. **AGI는 역방향**(T5가 T1보다 낮음 — 중갑·대형 직업이 느린 설계 의도).
- enemyPower(난이도): T1=10 / T2=20 / T3=35 / T4=55 / T5=80.

### 기존 상한 체계 (변경 없음, 참고)

| 레이어 | 상한 | 스태킹 | 비고 |
|---|:---:|:---:|---|
| role synergy | ±10%p 독립 | 파티 평균 | M1 확정 |
| trait × quest_type synergy | ±10%p 독립 | 파티 가산 | M1 확정 |
| 세력 패시브 + 명성 누적 (성공률) | **+20%p 공유** | 가산 | M1 확정 |
| **장비 보정 (신규)** | — | partyPower 가중 합 | **본 리포트에서 정의 — 공식 상한 없음, 설계 가이드라인 적용** |
| 최종 `rate` | clamp(5, 95) | — | 기존 유지 |

---

## 데이터 분석

### 분석 1 — 장비 기여도 스케일 설계 철학

**문제**: 장비는 partyPower를 무제한 스케일할 수 있다. 무제한 방치 시 용병 티어 시스템이 붕괴(T1 용병 + T5 풀세트가 T5 용병을 추월). 따라서 **장비가 용병 base 스탯에 미치는 기여율**의 설계 가이드라인이 필요.

**설계 철학 확정** (컨설팅 Q1): **풀세트 T 동급 장비의 partyPower 실효 기여율을 +25~35%로 조정**.

의미:
- T3 용병이 T3 풀세트를 장착 → partyPower 약 +30% 증가
- 이는 "장비 없는 파티 vs 풀장비 파티" 성공률 약 5~10%p 차이에 해당
- 세력 패시브(+8%p) / role synergy(+8%p)와 비슷한 체감층 → **4번째 전략 레이어**로 정합
- C 옵션(+50% 이상)은 정수(영구 강화)와 역할 겹침 → 기각
- A 옵션(+10~15%)은 "장비가 무의미"라는 인식 → 후속 마일스톤 드랍 설계 왜곡 우려로 기각

### 분석 2 — 티어 곡선 형태

**4개 옵션 비교** (weapon STR 수치 기준):

| 티어 | A: 선형 | **B: 완만 가속** | C: 급격 가속(정수 대칭) | D: 감속 |
|:---:|:---:|:---:|:---:|:---:|
| T2 | +3 | **+3** | +2 | +5 |
| T3 | +6 | **+6** | +5 | +8 |
| T4 | +9 | **+10** | +10 | +11 |
| T5 | +12 | **+15** | +20 | +14 |
| T5/T2 비 | 4.0배 | **5.0배** | 10.0배 | 2.8배 |

**확정**: **B (완만 가속)**.

근거:
- 정수는 희소 재화·영구 소비이므로 ×11배 가속이 타당. 장비는 **교체 가능한 전술 자원**이므로 ×5 증가비가 자연스러움
- Q1 확정 목표(+25~35%)에 가장 잘 맞음
- 엣지 케이스(T1 용병 + T5 weapon) 기여가 "강력하되 버그급 아님" 수준

### 분석 3 — 슬롯별 상대 강도

**가중치 확정** (컨설팅 Q3):

| 슬롯 | 가중치 | 주 효과 축 | 배경 |
|:---:|:---:|---|---|
| weapon | **1.0** | STR 또는 INT | 공격 주력 |
| armor | **1.0** | VIT | 방어 주력 (weapon과 동급) |
| helmet | 0.8 | VIT 또는 복합 | 보조 방어 |
| boots | 0.8 | AGI | 기동 |
| accessory ×2 | **0.6 each** | 복합 (주스탯 1종) | 장신구, 교체 선택지 강조 |

**설계 의도**:
- weapon ≈ armor 동급 → "STR 축 보강 vs VIT 축 보강"의 이원 선택 가능
- helmet/boots를 0.8로 낮춤 → 슬롯 간 차등 명확, 보조 개념 확립
- accessory×2 총합(1.2) > weapon 단일(1.0) → 액세서리 조합이 핵심 수단과 경쟁 가능, 2슬롯을 의미 있게 활용

### 분석 4 — 최종 tier × slot 수치 매트릭스

**B 곡선 × 슬롯 가중치 적용:**

| 슬롯 | 가중 | T2 | T3 | T4 | T5 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| weapon | 1.0 | +3 | +6 | +10 | +15 |
| armor | 1.0 | +3 | +6 | +10 | +15 |
| helmet | 0.8 | +2 | +5 | +8 | +12 |
| boots | 0.8 | +2 | +5 | +8 | +12 |
| accessory 1 | 0.6 | +2 | +4 | +6 | +9 |
| accessory 2 | 0.6 | +2 | +4 | +6 | +9 |
| **풀세트 단순합** | — | **+14** | **+30** | **+48** | **+72** |
| base 단순합 대비 | — | 10.1% | 18.0% | 24.1% | 32.2% |

※ 소수점 반올림 규칙: 0.5 이상 올림, 미만 버림 (예: 0.8×3=2.4 → +2, 0.8×6=4.8 → +5).

### 분석 5 — partyPower 실효 기여율 재검증 (quest_type별)

**T3 용병 base partyPower**:

| quest_type | base (raid) | base (hunt) | base (escort) | base (explore) |
|:---:|:---:|:---:|:---:|:---:|
| STR(25.0)·INT(21.5)·VIT(68.6)·AGI(51.2) → | 31.6 | 36.9 | 53.4 | 37.8 |

**T3 풀세트 기여 (슬롯별 주스탯이 용병 주스탯에 맞춤, 예: warrior용 장비 STR)**:

| quest_type | 풀세트 기여 | 증가율 | 비고 |
|:---:|:---:|:---:|---|
| **raid** | +11.4 | **+36.1%** | STR 비중 큼, weapon·accessory가 지배 |
| **explore** | +9.5 | +25.1% | INT weapon·accessory + AGI boots |
| **escort** | +13.1 | **+24.5%** | armor/helmet VIT가 지배 |
| **hunt** | +8.0 | +21.7% | STR + AGI 균등 |
| 평균 | 10.5 | **+26.9%** | **Q1 목표(+25~35%) 범위 내** |

**판정**: 단순 스탯 합(18%) 대비 partyPower 실효 기여(27%)가 더 높은 이유는 quest_type별 가중치 덕분. 설계 의도와 부합.

### 분석 6 — 자유 장착 엣지 케이스 검증

"T1 용병에 T5 풀세트 끼우기" 시나리오 검증.

**조건**: T1 specialist (STR 7.6, INT 5.8, VIT 26.3, AGI 53.3, base 합 93)에 warrior형 T5 풀세트 장착.

| 스탯 | T1 base | T5 풀세트 추가 | 최종 | T3 warrior base 대비 |
|:---:|:---:|:---:|:---:|:---:|
| STR | 7.6 | +15 (weapon) + 9 (acc1) + 9 (acc2) = +33 | **40.6** | T5 무기군 초과 (T5 base avg 37.7) |
| INT | 5.8 | 0 | 5.8 | 매우 낮음 |
| VIT | 26.3 | +15 (armor) + 12 (helmet) = +27 | **53.3** | T2 avg 수준 |
| AGI | 53.3 | +12 (boots) | **65.3** | T2 최상위 |

**raid partyPower**: 40.6×0.70 + 5.8×0.10 + 53.3×0.10 + 65.3×0.10 = **40.8**
- vs. T3 warrior base (raid) 31.6 → **T3 상위권 수준**
- vs. T5 warrior base (raid) 45~50 → **T5 미달**

**판정**:
- "T1 용병에 T5 풀세트" = **T3 중위~상위 수준 용병으로 변신**. T5 용병 자체를 대체하지는 못함.
- 분류 체계 기획서의 "자유 장착 철학"(저티어 용병을 장비빨로 끌어올리는 검증 허용)에 정확히 부합
- M2a 수동 지급 환경에서 "T1 용병 + T5 세트 전부"는 T5 장비 5~6개가 필요한 비현실적 조합. 실제 검증에서는 "T1 + T3 무기 1개" 같은 현실적 시나리오가 대부분이며, 그 경우 STR 7.6 + 6 = 13.6 (T2 하위)로 체감 온건
- 장기적(M2b 이후) 드랍 경로에서는 T1 용병이 "고티어 장비 풀세트"를 맞출 확률 자체가 낮음 → 자연스러운 진행 압력

### 분석 7 — 엔드게임 상한 시나리오 (T5 파티 + T5 풀세트)

**조건**: T5 warrior 3명 raid, 모두 T5 풀세트 (warrior형: STR weapon + STR acc×2, VIT armor/helmet, AGI boots), 난이도 5 (enemy 80), 거리 0, 무트레잇, 무세력.

| 단계 | 값 |
|---|:---:|
| 1명 base raid partyPower | 37.7×0.70 + 37.5×0.10 + 102.0×0.10 + 46.6×0.10 ≈ **45.0** |
| 1명 풀세트 raid 기여 | 15×0.70 + 15×0.10 + 12×0.10 + 12×0.10 + 9×0.70 + 9×0.70 ≈ **26.5** |
| 1명 최종 raid partyPower | 71.5 |
| 파티 3명 합 | 214.5 |
| ratio (vs enemy 80) | 2.68 |
| base 성공률 기여 | (2.68-1) × 50 = +84 → clamp 95 |
| 최종 성공률 | **95% (상한 clamp)** |

**판정**:
- T5 파티 + T5 풀세트는 **기존 최상 난이도에서 clamp 95 달성**. 대실패 리스크는 최소 5%p 유지(설계 철학).
- 이는 장비가 없어도 이미 달성되는 수준이다 (T5 용병 3명 base raid partyPower = 135, ratio 1.69, 기여 +34.5 → rate 89.5%)
- **장비 효과의 실질 작동 구간**은 "같은 티어 난이도의 challenge 구간"(ratio 0.8~1.3)과 "한 단계 높은 티어 난이도 도전"(T4 파티 + T4 풀세트 → T5 난이도 도전 가능)

### 분석 8 — 전설 1종 강도 설계

**확정** (컨설팅 Q4): **B+D 하이브리드** = 일반 T5 수치 × 1.2 + 유니크 효과 1개.

**수치 규격** (슬롯 × 주스탯 기준):

| 슬롯 | 일반 T5 수치 | 전설 수치 (×1.2) | 반올림 |
|:---:|:---:|:---:|:---:|
| weapon / armor | +15 | +18 | **+18** |
| helmet / boots | +12 | +14.4 | **+14** |
| accessory | +9 | +10.8 | **+11** |

**유니크 효과 풀** (컨설팅 Q5-B, 전체 5 카테고리 허용):

| 카테고리 | 허용 범위 (전설 1개당 1개 선택) | 구현 진입점 | 기존 공식 침해 |
|:---:|---|---|:---:|
| ① 성공률 보정 | `{raid/hunt/escort/explore}_success_rate`: +3~+5 %p | `TraitEffectService` 경로 재사용 | 없음(기존 경로) |
| ② 결과 판정 조작 | "5% 확률로 성공 → 대성공 승격" | `QuestCalculator.determineResult` 확장 | **로직 확장 필요** |
| ③ 데미지 저항 | 부상률 -10% / 사망률 -5% | `TraitEffectService.calculate{Injury,Death}RateModifier` 경로 | 없음(기존 경로) |
| ④ 보상 가산 | 퀘스트 골드 보상 +10% (전설 보유 용병 파견 시) | `QuestCalculator.calculateReward` 확장 | **로직 확장 필요** |
| ⑤ 특수 판정 | "사망 방지 1회 (쿨다운 24시간)" 등 | `QuestCompletionService` 확장 | **로직+상태 확장 필요** |

**판정**:
- 전설 1종만 유니크 효과를 가진다 → 코드 확장 범위가 제한적 (1회만 구현)
- M2a에서는 전설 1종만 생성되므로 ②④⑤ 중 한 가지만 선택하면 **해당 경로만 구현**하면 됨
- 후속 마일스톤에서 추가 전설이 도입될 때 점진적으로 확장 가능

**권장 분배 가이드** (data-generator 시점 전설 후보 선정):
- 전설 A (**멸혼결**, accessory): 카테고리 ③ "사망률 -5%"와 ⑤ "사망 방지 1회" 계열 서사와 맞음 → **③ 또는 ⑤**
- 전설 B (**광란검**, weapon): 카테고리 ② "성공→대성공 승격" 서사와 맞음 → **②**
- 전설 C (**이그드라실 수피갑**, armor): 카테고리 ③ "부상률 -10%" 서사와 맞음 → **③**

### 분석 9 — effect_json 스키마 (단일 주스탯 정책)

**확정** (컨설팅 Q5-A): **주스탯 1종만** 포함. 복합 구성 금지.

**개인 장비 effect_json 스키마**:

```json
// weapon — STR 또는 INT 택 1
{ "str": 15 }          // warrior/ranger/rogue 계열용
{ "intelligence": 15 } // mage/support 계열용

// armor — VIT 고정
{ "vit": 15 }

// helmet — VIT 고정 (분류 체계 기획서 "VIT 또는 복합" 중 단일 정책에 맞춰 VIT로 수렴)
{ "vit": 12 }

// boots — AGI 고정
{ "agi": 12 }

// accessory — STR/INT/VIT/AGI 중 택 1 (data-generator가 아이템 컨셉에 맞춰 선택)
{ "str": 9 }
{ "intelligence": 9 }
{ "vit": 9 }
{ "agi": 9 }

// 전설 (예시 — 멸혼결, accessory, 유니크 효과 ③)
{
  "vit": 11,
  "legendary_effect": {
    "category": "damage_resistance",
    "injury_rate_modifier": -0.10,
    "death_rate_modifier": -0.05
  }
}
```

**설계 의도**:
- accessory는 "복합 슬롯"이지만 M2a에서는 **"주스탯 4축 중 1종만 보유"** 형태로 통일. 복수 스탯 혼합은 M4 이후 재검토
- 분류 체계 기획서의 `helmet` "VIT 또는 복합"은 M2a에서 **VIT 고정**으로 단순화. 향후 helmet에 "INT+VIT" 같은 복합 도입은 별도 마일스톤
- `legendary_effect` 필드는 전설에만 존재. 일반 T2~T5 장비는 주스탯만 단독 보유

---

## 문제점

### 중요 (설계 조정)

**P1. 엔드게임에서 장비 효과가 95% clamp에 흡수될 수 있음**
- 근거: 분석 7. T5 용병 파티는 무장비에서 이미 난이도 5 성공률 89%, T5 풀세트 장착 시 clamp 95 달성.
- 해결: 장비의 주 가치는 "엔드게임 압도"가 아닌 **"중티어 용병의 난이도 한 단계 상회 도전"**. 설계 의도 유지, 별도 조정 불요.
- 문서화 권장: "장비 효과가 실제로 작동하는 구간은 ratio 0.8~1.3"을 페이즈 4 UI 툴팁/도움말에 노출 고려.

### 경미 (유지)

- 자유 장착 철학 (T1 용병 + T5 장비): 분석 6에서 T3 상위 수준 변신은 허용 범위. 운용 문제 없음.
- 전설 유니크 효과 5종 전부 허용: 구현 부담 있으나 M2a에서는 1종만 생성되므로 **선택된 1 카테고리만 구현**하면 됨.

---

## 플레이어 체감 분석

### 초반 (F~E 등급, T2~T3 용병 중심, 아이템 수동 지급 시나리오)

- 첫 장비 수령 시점에 "내 용병 스탯이 눈에 띄게 상승"하는 피드백이 중요
- T2 weapon(+3 STR)은 **T2 warrior(base STR 20) 대비 +15%** → raid partyPower +2.1 (1명당), 유의미한 체감
- 개별 아이템 1개만 끼워도 변화를 느낄 수 있는 스케일 확보 (B 곡선의 의도)

### 중반 (D~C 등급, T3~T4 용병, 풀세트에 가까운 장착)

- 장비 + 세력 패시브 + 트레잇이 중첩 → 성공률이 의미 있게 상승하는 "누적 보상" 구간
- 용병 상세 화면의 effective 스탯 표시 + 장비 영향 분해 UI가 체감 유도의 핵심
- T4 풀세트 장착 T3 용병이 "중급 용병의 고티어 도전"을 실현 → 전략 깊이 확보

### 엔드게임 (B~A 등급, T4~T5 풀세트)

- 장비만으로는 성공률을 더 높이지 못하지만(clamp 흡수), **대체 자원 투자 루트**로서 정수·승급 재료와 교환 가치 형성
- 전설 1종(유니크 효과)이 "얻었을 때의 인상"을 각인 → 드랍 경로 도입(M2b) 시 주요 목표 아이템
- 방치형 장르 특성상 "장비 한 세트를 맞춰가는 과정" 자체가 목표 → 풀세트 완성 체감이 중요

### 체감 리스크

- **분석 7의 clamp 흡수**: 엔드게임에서 "장비를 껴도 효과를 체감하지 못하는" 시기가 존재할 수 있음. UI 보강으로 "장비가 없었다면 X% 떨어졌을 것"을 표시해 체감 유도 필요 (페이즈 4 UX 고려).
- **자유 장착의 양면**: T1 용병에 T5 풀세트 끼우는 시나리오는 "재미있는 실험"이지만, 메인 루트에서 이를 최적 전략으로 유도하면 용병 티어 시스템 의미 약화. 드랍 희귀도(M2b 설계)로 자연스럽게 제어.

---

## 조정 제안

### 최종 tier × slot 수치 매트릭스

| 슬롯 | 주 스탯 | T2 | T3 | T4 | T5 | 전설 (T5×1.2) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| weapon | STR 또는 INT (택 1) | **+3** | **+6** | **+10** | **+15** | **+18** |
| armor | VIT | **+3** | **+6** | **+10** | **+15** | **+18** |
| helmet | VIT | **+2** | **+5** | **+8** | **+12** | **+14** |
| boots | AGI | **+2** | **+5** | **+8** | **+12** | **+14** |
| accessory (각) | STR/INT/VIT/AGI 택 1 | **+2** | **+4** | **+6** | **+9** | **+11** |

### effect_json 스키마

```json
// 일반 장비 (T2~T5) — 주스탯 1종만
{ "<stat_key>": <value> }
// stat_key ∈ {str, intelligence, vit, agi}
// value: 위 매트릭스 티어·슬롯 셀 값

// 전설 장비 (T5 전설 1종만) — 주스탯 + legendary_effect
{
  "<stat_key>": <legendary_value>,
  "legendary_effect": {
    "category": "<category>",
    "<effect_key>": <effect_value>
  }
}
```

### 유니크 효과 풀 (전설 5 카테고리 전부 허용)

| 카테고리 | category 값 | effect_json 필드 | 값 범위 | 구현 경로 |
|:---:|:---:|---|:---:|---|
| ① 성공률 보정 | `success_rate_bonus` | `raid_success_rate` / `hunt_success_rate` / `escort_success_rate` / `explore_success_rate` | +3 ~ +5 %p | `TraitEffectService` 재사용 |
| ② 결과 판정 조작 | `result_upgrade` | `success_to_great_chance` | 0.03 ~ 0.05 (3~5%) | `QuestCalculator.determineResult` 확장 |
| ③ 데미지 저항 | `damage_resistance` | `injury_rate_modifier` / `death_rate_modifier` | -0.05 ~ -0.15 (−5~−15%) | `TraitEffectService` 재사용 |
| ④ 보상 가산 | `reward_bonus` | `gold_reward_multiplier` | 0.05 ~ 0.12 (5~12%) | `QuestCalculator.calculateReward` 확장 |
| ⑤ 특수 판정 | `special` | `death_prevention_count` + `cooldown_hours` | `count` 1, `cooldown_hours` 24 (기본) | `QuestCompletionService` 확장 + 쿨다운 상태 저장 |

**M2a 범위 내 구현 부담 완화 규칙**:
- 전설 1종만 생성되므로, 선택된 카테고리의 경로만 구현
- ①③ 선택 시 → `TraitEffectService` 재사용, 코드 확장 없음
- ②④⑤ 선택 시 → 각각 1회 로직 확장

### 스태킹 규칙

| 효과 | 스태킹 방식 | 상한/하한 |
|---|---|---|
| 장비 스탯 보정 (`str/int/vit/agi`) | **가산** (base + equipment + permanent) | 없음 (partyPower 스케일에서 자연 제어) |
| 장비 최종 적용 | `(base + equipment + permanent) × (1 + levelBonus) × fatigueMod` | 기존 effective 공식 연장 |
| 전설 카테고리 ① `*_success_rate` | `TraitEffectService` 가산 → trait 독립 상한 +10%p 공유 | ±10%p (기존 규칙) |
| 전설 카테고리 ③ injury/death | `TraitEffectService` 가산 | 최종 확률 [0, 1] 클램프 (기존) |
| 전설 카테고리 ② result_upgrade | 독립 판정 (trait와 별개 roll) | 확률 자체 상한 5% |
| 전설 카테고리 ④ reward | `calculateReward` `passiveRewardBonus`에 가산 | 기존 +0.80 상한 공유 |
| 전설 카테고리 ⑤ death_prevention | 쿨다운 기반 1회성 | 24시간 쿨다운 |

---

## 시뮬레이션 (조정안 적용 후)

### 시나리오 A — 기본 장착 체감 (T3 warrior 1명 + T3 weapon + T3 armor, raid 난이도 3)

| 항목 | 무장비 | T3 weapon 추가 | T3 armor 추가 |
|---|:---:|:---:|:---:|
| STR (raid ×0.70) | 25.0 → 17.5 | +6 → 21.7 (+4.2) | 동일 21.7 |
| VIT (raid ×0.10) | 68.6 → 6.86 | 동일 | +6 → 7.46 (+0.6) |
| 1명 raid partyPower | 31.6 | **35.8 (+13%)** | **36.4 (+15%)** |
| 파티 3명 raid partyPower | 94.8 | 107.4 | 109.2 |
| ratio (enemy 35) | 2.71 | 3.07 | 3.12 |
| 기여 | +85 → clamp 95 | clamp 95 | clamp 95 |

**판정**: 난이도 3은 이미 clamp 95 상태. 장비는 "더 높은 난이도 도전"에서 체감. 아래 시나리오 B 참고.

### 시나리오 B — 난이도 상회 도전 (T3 warrior 3명 + T3 풀세트, raid 난이도 5)

| 항목 | 무장비 | T3 풀세트 |
|---|:---:|:---:|
| 1명 raid partyPower | 31.6 | 43.0 (+36%) |
| 파티 3명 | 94.8 | 129.0 |
| ratio (enemy 80) | 1.19 | 1.61 |
| 기여 | +9.5 | +30.6 |
| 최종 성공률 (무트레잇·무세력) | **59% (+5 questMod)** | **85%** |
| **체감 차이** | | **+26%p** |

**판정**: "중급 용병이 최고 난이도에 도전"하는 구간에서 풀세트의 가치 +26%p. 강력하지만 합리적 — 풀세트를 모으는 수집 여정에 대한 명확한 보상.

### 시나리오 C — 엔드게임 상한 (T5 warrior 3명 + T5 풀세트, raid 난이도 5)

| 항목 | 무장비 | T5 풀세트 |
|---|:---:|:---:|
| 1명 raid partyPower | 45.0 | 71.5 (+59%) |
| 파티 3명 | 135 | 214.5 |
| ratio | 1.69 | 2.68 |
| 기여 | +34.5 | +84 → clamp |
| 최종 성공률 | **89.5%** | **95% (clamp)** |

**판정**: 엔드게임은 이미 clamp 구간. 장비의 가치는 "대실패 리스크 감소"(±5~10%p)와 "트레잇·세력 조건 부족 시의 버퍼" 역할.

### 시나리오 D — 자유 장착 엣지 케이스 (T1 specialist + T5 풀세트, hunt 난이도 4)

**조건**: T1 specialist base (STR 7.6, INT 5.8, VIT 26.3, AGI 53.3), hunt 가중치(STR 0.50, INT 0.10, VIT 0.10, AGI 0.30).

| 스탯 | base | +T5풀(warrior형) | 최종 |
|:---:|:---:|:---:|:---:|
| STR | 7.6 | +33 | 40.6 |
| VIT | 26.3 | +27 | 53.3 |
| AGI | 53.3 | +12 | 65.3 |

**hunt partyPower**: 40.6×0.50 + 5.8×0.10 + 53.3×0.10 + 65.3×0.30 = 20.3 + 0.58 + 5.33 + 19.6 = **45.8**
- vs. T3 warrior base hunt partyPower (36.9): T3 초과
- vs. T5 warrior base hunt partyPower (~56): T5 미달

**판정**: "T1에 T5 풀세트 몰빵"은 T3~T4 중간 수준 용병 수준으로 변신. 극단 시나리오에서도 T5 용병을 대체하지 못해 티어 시스템 의미 유지.

### 시나리오 E — 전설 1종 + 일반 풀세트 (T4 warrior + T3 풀세트 + 전설 광란검 weapon)

**광란검** (weapon, 카테고리 ② `result_upgrade`, 성공 → 대성공 승격 5%):

| 항목 | T3 풀세트만 (weapon = 강철 장검 +6 STR) | + 전설 광란검(+18 STR, 유니크 ②) |
|---|:---:|:---:|
| 1명 raid partyPower (T4 base 36.0 + 장비) | 47.4 | 55.8 (+18%) |
| 파티 3명 | 142.2 | 167.4 |
| 난이도 5 ratio | 1.78 | 2.09 |
| 성공률 | 89% | **95% (clamp)** |
| 대성공 확률 (성공률 × 0.3 기반) | 28.5% | 28.5% + 5% = **33.5%** (유니크 ②) |
| 보상 기대값 (대성공 ×2) | 1 + 0.285 = 1.285배 | 1 + 0.335 = **1.335배** (+3.9%) |

**판정**: 전설 광란검은 "수치 ×1.2 + 유니크 ② 5%"가 누적 보상 기대값을 약 **+4% 끌어올림**. 체감 가능하되 파괴적이지 않음.

---

## data-generator 수치 가이드

페이즈 3 `data-generator`에게 넘기는 수치 규격 (개인 장비 6종만 해당, 용병단 장비·정수는 별도 리포트):

### 대상

- **타입**: `item` (개인 장비 하위)
- **테이블**: `items` (신규)
- **생성 수량**: 6종 (weapon 1 / armor 1 / helmet 1 / boots 1 / accessory 2)

### 수치 범위 (tier × slot 매트릭스)

| 슬롯 | 필수 stat_key | T2 | T3 | T4 | T5 일반 | T5 전설 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| weapon | `str` 또는 `intelligence` (택 1) | 3 | 6 | 10 | 15 | **18** |
| armor | `vit` (고정) | 3 | 6 | 10 | 15 | **18** |
| helmet | `vit` (고정) | 2 | 5 | 8 | 12 | **14** |
| boots | `agi` (고정) | 2 | 5 | 8 | 12 | **14** |
| accessory | `str`/`intelligence`/`vit`/`agi` (택 1) | 2 | 4 | 6 | 9 | **11** |

### 아이템 컨셉 → 수치 매핑 (컨셉 기획서 연동)

컨셉 기획서의 평이 5종 + 전설 후보 3안에 대한 수치 가이드. **구체 티어는 data-generator가 아래 권장 범위 내에서 선택**:

| # | 슬롯 | 컨셉 이름 | 권장 티어 | stat_key | 값 |
|:---:|:---:|---|:---:|:---:|:---:|
| 1 | weapon | 강철 장검 | T2 or T3 | `str` | 3 or 6 |
| 2 | armor | 사슬 흉갑 | T2 or T3 | `vit` | 3 or 6 |
| 3 | helmet | 철 투구 | T2 | `vit` | 2 |
| 4 | boots | 질풍의 가죽 부츠 | T3 | `agi` | 5 |
| 5 | accessory | 단련의 은반지 | T3 or T4 | `str` 또는 `vit` | 4 or 6 |
| 6 | accessory | **전설 후보 1안** (멸혼결 / 광란검 / 이그드라실 수피갑) | T5 | 아래 분기 |

**전설 후보 슬롯 조정**:

컨셉 기획서는 "accessory 2슬롯 하나를 전설로 둔다"(후보 A)를 기본안으로 제시했으나, 후보 B(weapon) 또는 후보 C(armor)를 선택하면 평이 5종 중 해당 슬롯 항목을 수정해야 함. 아래 3가지 분기 중 data-generator가 1개 선택:

| 전설 후보 | 전설 슬롯 | 수치 | 유니크 효과 | 평이 5종 조정 |
|:---:|:---:|---|---|---|
| A (멸혼결) | accessory | `vit`: 11 | category ③ `damage_resistance`: `injury_rate_modifier` -0.10, `death_rate_modifier` -0.05 | 변경 없음 (accessory 2 중 하나가 전설) |
| B (광란검) | weapon | `str`: 18 | category ② `result_upgrade`: `success_to_great_chance` 0.05 | 평이 5종에서 weapon 제외 → "강철 장검" 삭제, accessory 2종 유지, 다른 슬롯 T2~T4 재배분 |
| C (이그드라실 수피갑) | armor | `vit`: 18 | category ③ `damage_resistance`: `injury_rate_modifier` -0.15 | 평이 5종에서 armor 제외 → "사슬 흉갑" 삭제, 다른 슬롯 T2~T4 재배분 |

**권장**: 후보 **A (멸혼결)** — 컨셉 기획서 기본안을 따르면 평이 5종을 수정하지 않아도 되어 단순. 후보 B/C는 "전설이 핵심 슬롯에 들어가는" 임팩트가 크므로 해당 서사를 선호하면 선택.

### 구조적 제약

- **단일 주스탯 정책**: 일반 장비의 `effect_json`은 주스탯 1종만 포함. 복합 스탯 금지.
- **accessory의 주스탯 택 1**: 두 accessory의 stat_key를 **다르게** 두면 전술 폭 확대 (예: acc1 `str`, acc2 `agi`). 동일하게 두면 특정 스탯 특화. **권장**: 다른 stat_key 선택.
- **일반 T4 장비 1종 이상 포함**: 티어 분포 가이드라인(T2×1 / T3×2 / T4×2 / T5×1)에서 T4를 최소 1종 채울 것.
- **전설의 stat_key는 해당 슬롯의 기본 주스탯을 따름**: weapon 전설 → `str` 또는 `intelligence`, armor/helmet 전설 → `vit`, boots 전설 → `agi`, accessory 전설 → 4축 중 택 1.

### 수치 출처

본 리포트 **분석 4**(매트릭스) 및 **분석 8**(전설 규격)에서 도출. 페이즈 4 개발 명세에서 `effect_json` 스키마 유효성 검사 규칙으로 반영.

### 특수 요구

- 전설 1종의 `legendary_effect.category` 값은 `{success_rate_bonus, result_upgrade, damage_resistance, reward_bonus, special}` 중 택 1
- 각 카테고리의 effect 필드는 본 리포트 "조정 제안 — 유니크 효과 풀" 표 참조
- 전설의 flavor_text는 컨셉 기획서의 후보 설명을 따름. 고유명사·출처 서사를 충실히 반영

---

## 후속 안내

### 페이즈 2 산출물 1 완료 — 페이즈 2 잔여 2건 미완

본 리포트는 **페이즈 2 산출물 1/3**이다. 동일 페이즈의 잔여 2건 수치 확정이 필요:

- **산출물 2**: 정수 영구 스탯 강화 수치 + 인플레이션 시뮬레이션 (`Docs/balance-design/20260418_essence_inflation.md` 예정)
  - 정수 시스템 기획서의 권장 초안(+1/+2/+4/+7/+11, 용병 티어 상한 +10/+20/+40/+70/+120) 검증
- **산출물 3**: 용병단 장비 거시 지표 수치표 (`Docs/balance-design/20260418_guild_equipment_macro.md` 예정)
  - 4종(깃발 + 유물 3)의 `gold_reward_multiplier`, `recruit_high_tier_chance` 등 보정값 확정

### 페이즈 4 개발 명세 반영 필수 항목

`/spec-writer` 호출 시 본 리포트에서 다음 사항을 필수 반영:

1. **effective 스탯 공식 확장**: `Mercenary.effectiveStr/Int/Vit/Agi` getter에 `equipmentBonus` 가산 추가. 공식:
   ```
   effectiveX = (baseX + equipmentX + permanentX) × (1 + levelBonus) × fatigueMod
   ```
2. **effect_json 스키마 제약**: 개인 장비는 주스탯 1종만 포함. 스키마 유효성 검사는 `ItemData` Freezed 모델 또는 DB CHECK 제약으로.
3. **전설 유니크 효과 5 카테고리 전부 지원 구조 설계**: M2a에서는 선택된 1개만 구현되지만, 5개를 모두 받아들일 수 있는 `legendary_effect.category` 분기 구조를 `ItemEffectService`에 설계.
4. **partyPower 공식 재사용**: `QuestCalculator.calculatePartyPower`는 `effectiveStr/Int/Vit/Agi`만 참조하므로 **코드 변경 없음**. effective getter만 확장.
5. **UI 표시**: 용병 상세 화면의 스탯 표시에 "장비 +X" 기여 분해 추가 권장 (체감 유도).

### 경제 영향

- 장비 인플레이션: 풀세트가 partyPower +27% 평균 → 동일 난이도에서 성공률 +3~8%p → 기대 수익 +5~15%. 기존 세력 패시브·role synergy와 중첩하면 엔드게임 보상 인플레이션 주의. 다만 장비 풀세트를 모으는 비용(M2a 수동, M2b 드랍률)이 자연스러운 제어.
- 전설 유니크 효과 ④ `reward_bonus`를 선택하면 보상 직접 인플레이션 발생. `calculateReward`의 기존 +0.80 상한 공유로 자동 제어됨.

### milestone-runner 재진입

`/milestone-runner M2a --resume`으로 페이즈 2 산출물 2(정수 인플레이션) 또는 3(용병단 장비 거시 지표)로 진행.

---

## 체크리스트

- [x] 장비 공식 경로 정의 (partyPower 간접 기여, 기존 상한 체계와 독립)
- [x] 장비 기여도 스케일 확정 (+25~35%, Q1)
- [x] 티어 곡선 확정 (B 완만 가속, +3/+6/+10/+15, T5/T2 5배, Q2)
- [x] 슬롯 가중치 확정 (weapon/armor 1.0, helmet/boots 0.8, accessory 0.6, Q3)
- [x] tier × slot 최종 매트릭스 산출
- [x] partyPower 실효 기여율 재검증 (평균 +27%)
- [x] 자유 장착 엣지 케이스 검증 (T1 + T5 풀세트 → T3 상위 수준)
- [x] 엔드게임 상한 clamp 흡수 확인
- [x] 전설 강도 확정 (B+D 하이브리드, ×1.2 + 유니크 효과, Q4)
- [x] 유니크 효과 5 카테고리 전체 허용 + 각 수치 범위 (Q5-B)
- [x] effect_json 스키마 확정 (단일 주스탯 정책, Q5-A)
- [x] data-generator 수치 가이드 작성
- [x] 페이즈 4 명세 반영 핵심 요구 5건 명시
