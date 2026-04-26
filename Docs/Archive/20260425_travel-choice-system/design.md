# 이동 선택지 이벤트 컨텐츠 기획서

> 작성일: 2026-04-24
> 유형: 신규 컨텐츠 (M3 페이즈 1-5)
> 선행 의존: 페이즈 1-1 TemplateEngine(`Docs/content-design/[content]20260423_template_engine.md`), 페이즈 1-4 퀘스트 서사(`Docs/content-design/[content]20260424_quest_narratives.md`), 기존 TravelEvent 12종(`travel_events` 테이블 / `TravelEventService`)
> 후속 페이즈 의존: 페이즈 2-3(EV 수치 시뮬레이션), 페이즈 3-0-4(`types/travel-choice.md` 타입 스펙), 페이즈 3-5(12종·114행 벌크 생성), 페이즈 4-5(TravelEventService 확장 + 회상 UI spec)

## 개요

이동 완료 시점에 "**오는 길에 이런 일이 있었소**" 형식의 회상 팝업이 뜨고, 2~3개 선택지 중 하나를 고르면 결과 서사와 효과가 반영된다. 기존 자동 이벤트(`travel_events` 12종)와 병렬로 동작하며, **방치형 게임 특성을 지키면서도 결정의 감성**을 추가한다.

이 문서는 **기존 자동 이벤트와의 관계(분리)**, **스키마 3테이블(`travel_choice_events` + `travel_choice_options` + `travel_choice_results`)**, **4 카테고리 × 3개 = 12종 시나리오 윤곽**, **선택지 구조(안전·위험·숨겨진)**, **결과 분기(2~3개 probability 합=1.0)**, **효과 타입 8종**, **대표 용병 선정 규칙**, **EV 정책**, **도착 후 회상 UI 흐름**을 확정한다. 구체 텍스트·114행 데이터는 페이즈 3-5에서 data-generator가 생성한다.

## 레퍼런스 분석

| 게임 | 참고 포인트 | 차용/변형 |
|------|-----------|----------|
| **FTL: Faster Than Light** | 워프 중간 이벤트가 2~4개 선택지로 분기, 트레잇·자원 조건으로 일부 선택지 잠금 해제 | 선택지 구조 + visibility 조건의 원형. 단 이동 중 인터럽트 방식은 탈락 |
| **Darkest Dungeon — Curios / Town Events** | 지도 탐사 중 발견물에 선택지 상호작용. 결과는 확률 기반 | 확률 기반 결과 분기 차용 |
| **Sunless Sea** | 항해 완료 후 "기억(storylet)" 팝업. 짧은 서사 + 선택지 | **회상 UI 타이밍**의 직접 모델. 방치형과의 정합 확인 |
| **Reigns** | 좌우 스와이프로 2선택지. 단순성·반복 피로 완화 | 기본 2선택지 구조 차용. 단 숨겨진 선택지로 깊이 추가 |
| **Fallen London** | 품질(Quality) 임계로 선택지 가시성·결과 분기 | `visibility_expr` + `conditional_expr` 모델의 직접 조상 |

**핵심 설계 원칙**: "**이동이 멈추지 않는다. 그러나 돌아왔을 때 한 번의 기억이 남는다.**" 선택은 이동 완료 후 단 한 번. 이동 중 UI 변화는 없다.

**반면교사**: Kingdom of Loathing 같은 반 농담 톤은 본 게임의 판타지 정통 톤에 맞지 않는다. labor 유형의 가벼움은 quest_narratives(페이즈 1-4)에 한정된다.

## 상세 설계

### 1. 기존 자동 이벤트와의 관계

**분리 정책 확정**.

| 구분 | 자동 이벤트 | 선택지 이벤트 |
|------|-----------|------------|
| 테이블 | `travel_events` (기존 12행) | `travel_choice_events` 3테이블 (신규) |
| 발동 | 이동 시작 시 `rollEvent` → 즉시 결정 | 이동 시작 시 `rollEvent` → 결정만 저장, 도착 시 회상 팝업 |
| UI | 도착 팝업에 결과 요약 | 도착 팝업 → 선택 UI → 결과 서사 |
| 개입 | 없음 | 선택지 클릭 |
| 기존 로직 | 그대로 유지 | 신규 |

#### 1-1. rollEvent 통합 흐름 (페이즈 4-5 spec 대상)

이동 시작 시점:
```
1. roll1: 자동 이벤트 발생? (distance × 0.15, 최대 0.80 — 기존)
   → YES → travel_events에서 1개 선택, ActiveTravel.autoEventId 저장

2. roll2: 선택지 이벤트 발생? (독립 roll, 본 기획 신규 확률)
   → YES → travel_choice_events에서 1개 선택
           (tier 범위 + preferred_traits 보유자 있으면 가중치 상향)
           ActiveTravel.choiceEventId 저장

3. 두 roll은 독립. 동시 발동 가능 (자동 결과 + 선택지 회상 둘 다)
```

**선택지 이벤트 발생 확률 초기값**:
- 리전 티어 1~2: `distance × 0.08` (최대 0.40) — 저빈도
- 리전 티어 3~4: `distance × 0.10` (최대 0.50)
- 리전 티어 5: `distance × 0.12` (최대 0.60)

유저 체감 빈도: 1시간(6~12회 이동) 중 2~4번 선택지 조우. 수치는 페이즈 2-3에서 조정.

#### 1-2. 두 이벤트 동시 발동 시 팝업 순서

도착 팝업 순서:
```
1. 퀘스트 완료 팝업 (해당 이동 중 완료된 파견) — 기존 경로
2. 자동 이벤트 결과 (기존 te_* 12종) — 기존 경로
3. 선택지 이벤트 회상 (신규) — 본 기획
4. 기타 알림 (건설 완료·세력 랭크업 등)
```

세부 우선순위는 페이즈 1-6(공존 정책)에서 확정. 본 문서에서는 **3번 위치 제안**만.

### 2. 스키마 3테이블

#### 2-1. `travel_choice_events` (마스터)

```sql
CREATE TABLE travel_choice_events (
  id TEXT PRIMARY KEY,                          -- tce_enc_01, tce_dil_02, ...
  name TEXT NOT NULL,                           -- "부상당한 여행자"
  category TEXT NOT NULL CHECK (category IN
    ('encounter','dilemma','discovery','hazard')),
  situation TEXT NOT NULL,                      -- TemplateEngine 템플릿 (150~250자)
  min_tier INT NOT NULL DEFAULT 1,
  max_tier INT NOT NULL DEFAULT 5,
  weight INT NOT NULL DEFAULT 1,                -- rollEvent 가중치 튜닝용
  preferred_traits TEXT                         -- "empathy,brave" 쉼표구분, nullable
);
CREATE INDEX idx_tce_tier ON travel_choice_events(min_tier, max_tier);
CREATE INDEX idx_tce_category ON travel_choice_events(category);
```

**`preferred_traits` 용도**:
- 이벤트 선정 후 **대표 용병** 선정 시 매칭 기준
- visibility_expr와 별개 (visibility는 **용병단 전체에 보유자 존재 여부**, preferred_traits는 **서사 주인공 선정 우선순위**)
- nullable — 없으면 최고 레벨 용병 fallback

#### 2-2. `travel_choice_options` (선택지)

```sql
CREATE TABLE travel_choice_options (
  id TEXT PRIMARY KEY,                          -- tce_enc_01_o0, _o1, _o2
  event_id TEXT NOT NULL REFERENCES travel_choice_events(id) ON DELETE CASCADE,
  choice_index INT NOT NULL,                    -- 0, 1, 2
  label TEXT NOT NULL,                          -- "돕는다" (6~12자)
  visibility_expr TEXT,                         -- nullable → 항상 노출
  description TEXT,                             -- 선택지 보조 설명 (옵션, 1문장)
  risk_level TEXT NOT NULL CHECK (risk_level IN ('safe','risky','hidden')),
  UNIQUE(event_id, choice_index)
);
CREATE INDEX idx_tco_event ON travel_choice_options(event_id);
```

**`risk_level` 의미**:
- **safe**: 손실 없음, 낮은 이득 (EV 저분산)
- **risky**: 명백한 손실·이득 양방향 (EV 고분산)
- **hidden**: `visibility_expr` 있는 행. 월등한 EV + 저분산

UI 측 시각 차별화에 활용 (safe/risky는 color tag, hidden은 별도 아이콘).

#### 2-3. `travel_choice_results` (결과 분기)

```sql
CREATE TABLE travel_choice_results (
  id TEXT PRIMARY KEY,                          -- tce_enc_01_o0_r0, _r1, _r2
  option_id TEXT NOT NULL REFERENCES travel_choice_options(id) ON DELETE CASCADE,
  result_index INT NOT NULL,
  probability REAL NOT NULL CHECK (probability > 0 AND probability <= 1),
  conditional_expr TEXT,                        -- nullable → 무조건 후보
  narrative TEXT NOT NULL,                      -- TemplateEngine 결과 서사 (40~120자)
  effect_type TEXT NOT NULL CHECK (effect_type IN
    ('gold','injury','heal_tired','reputation',
     'trait_innate','trait_acquired','item','nothing')),
  effect_magnitude REAL,                        -- nothing이면 NULL 허용
  effect_target TEXT,                           -- trait_id, item_id 등 nullable
  UNIQUE(option_id, result_index)
);
CREATE INDEX idx_tcr_option ON travel_choice_results(option_id);
```

**선택 알고리즘** (선택지 클릭 시):
```
1. candidates ← travel_choice_results WHERE option_id = clicked.id
2. filtered ← candidates.filter(r =>
     r.conditional_expr IS NULL OR
     TemplateEngine.evaluate(r.conditional_expr, ctx)
   )
3. normalized_probs ← filtered 내 probability 합으로 정규화 (합=1.0 재계산)
4. selected ← weighted_random(filtered, by: normalized_probs)
5. rendered ← TemplateEngine.render(selected.narrative, ctx)
6. applyEffect(selected.effect_type, effect_magnitude, effect_target)
7. return {narrative: rendered, effect: selected}
```

**정규화 이유**: `conditional_expr`로 일부 결과가 탈락하면 남은 확률 합이 1.0이 아님. 남은 후보 내에서 재분배 → 항상 1개 선택 보장.

**엣지 케이스**: 모든 결과가 탈락(예: 조건이 충족 안 됨)하면 기본 result `{narrative: "{merc.name}은 아무 일 없이 돌아왔다.", effect_type: "nothing"}` fallback (코드 상수).

**데이터 규모**:
- 이벤트 12
- 선택지 12 × (2~3) ≈ 30
- 결과 30 × (2~3) ≈ 72
- **총 약 114행**

### 3. 선택지 구조

#### 3-1. 선택지 개수 정책

| 시나리오 유형 | 선택지 수 | risk_level 구성 |
|-------------|---------|---------------|
| 기본 | 2 | safe + risky |
| 숨겨진 포함 | 3 | safe + risky + hidden |

12종 중 **9~10종**에 `hidden` 선택지 포함 (트레잇·세력 기반). 2~3종은 기본 2선택지만.

#### 3-2. `visibility_expr` 평가 범위 확장 (페이즈 1-1 영향)

선택지 이벤트의 `visibility_expr`는 **용병단 전체**에서 평가한다. 예:

```
visibility_expr: has_trait:empathy
```

→ 용병단 **누구라도** `empathy` 보유 시 선택지 표시. 이 평가 범위 확장은 페이즈 4-1 TemplateEngine spec에 후속 반영 필요:

- `has_trait`/`has_any_trait`/`has_all_traits`의 평가 범위가 **컨텍스트에 따라** 달라짐:
  - 퀘스트 서사(quest_narratives): `merc.*` 1명 기준
  - 이동 선택지 `visibility_expr`: 용병단 전체 기준
  - 이동 선택지 `conditional_expr`: 대표 용병 1명 기준(용병단 전체 기준도 선택 가능)

이 구분은 `TemplateContext`에 `evaluationScope: enum { mercenary | team }` 파라미터 추가로 명시. 페이즈 4-1 spec에서 API 재설계.

#### 3-3. 선택지 숨김 vs 회색 표시

페이즈 1-1 기획서 §4-4에서 "가려진 선택지는 **목록에서 제외**"로 명시 → 본 기획도 동일. 회색 비활성 표시는 하지 않는다.

**근거**:
- 유저가 "숨겨진 선택지가 존재함"을 UI로 인지하면 트레잇 획득이 "달성 강박"으로 변질
- Fallen London/FTL 모두 동일하게 완전 숨김

예외 허용: description에 은유적 힌트("풀숲 쪽에서 약초 냄새가 난다" 등)를 넣어 **관찰력 있는 유저만** 단서를 느끼게. 기획 재량으로 12종 중 3~5종에 적용.

### 4. 결과 분기

#### 4-1. `probability` 규칙

- 선택지당 결과 2~3개
- `probability` 합 = 1.0 (CHECK 제약은 아니나 data-generator가 보장)
- `conditional_expr` 충족 여부와 무관하게 초기 probability 합=1.0 유지. 런타임 정규화로 실제 확률 조정

#### 4-2. `conditional_expr` 사용 사례

트레잇·세력·스탯에 따라 **결과가 달라지는 경우**만 사용:

```
-- 봉인된 동굴 입구, "봉인 파괴" 선택지의 결과 중 하나
conditional_expr: has_trait:hardy
narrative: "{merc.name}의 억센 어깨 덕에 봉인이 깨졌다. 안에서 낡은 유물이 나왔다."
probability: 0.40
effect_type: item
```

같은 선택지에 `conditional_expr` 없는 결과(기본 후보) 2개 + `hardy` 조건 결과 1개가 공존. `hardy` 보유 대표 용병이면 3후보 중 선택, 아니면 기본 2후보 중 선택.

**12종 중 약 4~6종**에 `conditional_expr` 활용. 나머지는 무조건 확률 분기.

#### 4-3. 결과 후보 설계 유형

| 유형 | 구조 | 사용 예 |
|------|------|--------|
| **2분기** | 성공 p% + 실패 (1-p)% | 단순 위험 선택지 |
| **3분기** | 대박 p1% + 평범 p2% + 실패 p3% | 위험·숨겨진 선택지 |
| **조건 3분기** | 기본 2후보 + 조건 1후보 | 트레잇 보유 시 특이 결과 |

### 5. 효과 타입 8종

| effect_type | 기존/신규 | magnitude 의미 | effect_target | 적용 |
|-----------|---------|-------------|-------------|------|
| `gold` | 기존 | +/- 골드량 (int) | null | `UserData.gold` 즉시 반영 |
| `injury` | 기존 | 부상 횟수(int, 1=용병 1명 부상) | null | 대표 용병 부상 |
| `heal_tired` | 기존 | 회복 용병 수(int, 1=1명) or 음수(피곤 부여) | null | 대표 용병 대상 |
| `reputation` | 기존 | +/- 명성(int) | null | `UserData.reputation` 반영 |
| `trait_innate` | 기존 | 1(부여) | trait_id(옵션) | 빈 선천 슬롯 보유 용병에게 부여. `effect_target` null이면 랜덤 |
| `trait_acquired` | 🆕 M3 신규 | 1(학습 기회 버프) | trait_id(우선) | `MercenaryStatService` 가중치 +50% 24시간 (hidden 섹터 퀘스트와 매커니즘 공유) |
| `item` | 🆕 M3 신규 | 수량(int, 기본 1) | item_id | 인벤토리에 아이템 지급 (M2a 인프라) |
| `nothing` | 🆕 M3 신규 | null | null | 효과 없음, 서사만 |

**`delay` 효과는 선택지 이벤트에서 제외**. 회상 맥락에서 "이동이 지연됐다"는 기시감. 기존 자동 이벤트(`te_storm_*`)만 유지.

**`heal_tired` magnitude 음수 처리**:
- 기존 자동 이벤트는 양수만 사용(피곤 회복)
- 본 기획에서 음수 허용 → 대표 용병에게 피곤 부여 (예: D1 "치료하다 병 옮음" 시나리오)
- 페이즈 4-5 spec에서 `applyEventEffect` 확장

### 6. 대표 용병 선정

이동은 전체 용병단 단위(개별 용병 개입 없음). 회상 팝업의 `merc.*` 바인딩 규칙:

```dart
Mercenary selectTravelProtagonist(
  List<Mercenary> rosterIdle,           // 이동 중 비파견 용병
  String? preferredTraitsCsv,           // "empathy,brave" or null
  Map<String, TraitData> traits,
) {
  if (rosterIdle.isEmpty) return FALLBACK;  // 극단 상황 (파견 전원)

  // 1. preferred_traits 매칭 우선
  if (preferredTraitsCsv != null) {
    final targets = preferredTraitsCsv.split(',').toSet();
    final matches = rosterIdle.where(
      (m) => m.allTraitIds.any(targets.contains)
    ).toList();
    if (matches.isNotEmpty) {
      // 동률 시 최고 레벨, 그다음 id lexical
      matches.sort((a, b) {
        final lv = b.level.compareTo(a.level);
        return lv != 0 ? lv : a.id.compareTo(b.id);
      });
      return matches.first;
    }
  }

  // 2. fallback: 최고 레벨
  rosterIdle.sort((a, b) {
    final lv = b.level.compareTo(a.level);
    return lv != 0 ? lv : a.id.compareTo(b.id);
  });
  return rosterIdle.first;
}
```

**`rosterIdle` 정의**: 이동 시점에 "파견 중이 아닌" 용병 전체. 이동에 "동행"하는 용병 개념이 없으므로 전체 로스터 중 비파견자.

**엣지 케이스**:
- 전원 파견 → 팝업 표시는 하되 `merc.*`는 **FALLBACK**(rosterFull의 최고 레벨)으로 렌더. 선택지 결과 `injury` 효과는 파견 중 용병에게 적용하지 않음 (안전 가드)
- 로스터 0명 → 이론상 발생 불가(파견 완료 후 1명 이상). 발생 시 이벤트 무시(팝업 생략)

### 7. EV 정책 (수치는 페이즈 2-3 위임)

#### 7-1. 원칙

| 선택지 | 성공률 | 기대 보상 | 실패 시 |
|-------|------|---------|--------|
| safe | 80~95% | 낮음 (+평판 5~10, +20~40G) | `nothing` |
| risky | 40~60% | 높음 (+60~120G, +15~25 평판) | 손실(`injury`/`gold`/`heal_tired` 음수) |
| hidden | 80~95% | 월등(+100~150G, +20~35 평판, trait/item) | 소량 보상 (완전 실패 없음) |

#### 7-2. 수량 균형 원칙

**동일 리스크 투입 기준 EV**:
```
EV(hidden) > EV(safe) ≥ EV(risky)
```

- hidden이 risky보다 월등한 EV여야 트레잇 가치가 보장됨
- safe는 risky와 같거나 약간 높게 (무위험 프리미엄) — 단, safe의 기대 보상은 낮으므로 **분산 없는 안정** 가치
- risky는 "모 아니면 도" 감성 유지 (최악 결과의 강렬함이 핵심, EV는 낮아도 됨)

#### 7-3. 세부 수치 결정 대상

페이즈 2-3 `/balance-designer`에서 검토할 항목:
- `probability` 분포 (40~60 vs 20~80 등 폭)
- `effect_magnitude` 절대값 (티어 스케일)
- 선택지 이벤트 발생 확률(§1-1 `distance × 0.08~0.12` 타당성)
- 숨겨진 선택지 EV가 일반 보상과 충분히 차별되는지

### 8. 12종 시나리오 윤곽

#### 8-1. encounter (조우) 3개

| ID | 이름 | 핵심 딜레마 | preferred_traits | visibility 조건(hidden) |
|----|------|-----------|------------------|---------------------|
| tce_enc_01 | 광인의 수수께끼 | 수수께끼에 답할 것인가 | scholar,curious | has_trait:scholar |
| tce_enc_02 | 경쟁 용병단의 도움 요청 | 라이벌을 도울 것인가 | leader | has_trait:leader |
| tce_enc_03 | 왕실 전령의 급행 | 길을 비키고 인사할 것인가 | — (세력) | joined_faction:silver_company *or 유사 공식 세력* |

#### 8-2. dilemma (딜레마) 3개

| ID | 이름 | 핵심 딜레마 | preferred_traits | visibility 조건(hidden) |
|----|------|-----------|------------------|---------------------|
| tce_dil_01 | 부상당한 여행자 | 낯선 자를 도울 것인가 | empathy | has_trait:empathy |
| tce_dil_02 | 쫓기는 도망자 | 정의와 동정 사이 | brave | has_trait:brave |
| tce_dil_03 | 무덤 도굴 가족 | 척살·방관·가담 | cunning | has_trait:cunning |

#### 8-3. discovery (발견) 3개

| ID | 이름 | 핵심 탐색 | preferred_traits | visibility 조건(hidden) |
|----|------|---------|------------------|---------------------|
| tce_dis_01 | 봉인된 동굴 입구 | 봉인을 풀 것인가 | scholar | has_trait:scholar |
| tce_dis_02 | 버려진 마차 | 흔적을 추적할 것인가 | tracker | has_trait:tracker |
| tce_dis_03 | 고대 제단의 돌 | 제단을 해석할 것인가 | faithful | has_trait:faithful |

#### 8-4. hazard (위험) 3개

| ID | 이름 | 지형 | preferred_traits | visibility 조건(hidden) |
|----|------|------|------------------|---------------------|
| tce_haz_01 | 부서진 다리 | 강 건너 | hardy | has_trait:hardy |
| tce_haz_02 | 안개 낀 늪 | 시야 차단 | survival | has_trait:survival |
| tce_haz_03 | 절벽 위 좁은 길 | 고도·바람 | agile | has_trait:agile |

**숨겨진 선택지 포함 분포**:
- 전 12종에 hidden 포함 (MVP — 균등 커버). 운영 후 일부 제거 검토
- 단 `preferred_traits`가 없는 tce_enc_03은 세력 기반 hidden (가입 조건)

**트레잇 커버리지 주의**: 각 hidden 선택지가 요구하는 트레잇 12종은 실제 `traits` 테이블에 존재하는 id여야 함. 페이즈 3-5에서 data-generator가 `traits` 테이블 FK 체크하여 매핑 확정. 존재하지 않는 trait 키워드(예: `leader`)는 근사 id(예: `charismatic`, `natural_born_leader`)로 대체 또는 `join_needs_clue` 기반 세력 분기로 전환.

### 9. 샘플 시나리오 (전체 구조)

#### 9-1. tce_dil_01 — 부상당한 여행자 (dilemma)

```
[travel_choice_events]
id: tce_dil_01
name: 부상당한 여행자
category: dilemma
situation: "길가 풀숲에서 낮은 신음 소리가 들렸다. {merc.name}이 다가가 보니
           낯선 여행자가 다리를 다친 채 쓰러져 있었다. 일행은 걸음을 멈추고
           {merc.name}을 돌아봤다."
min_tier: 1, max_tier: 5
weight: 1
preferred_traits: "empathy"

[travel_choice_options]
-- 0: safe
tce_dil_01_o0
  choice_index: 0
  label: "지나친다"
  risk_level: safe
  visibility_expr: null
  description: "갈 길이 멀다. 마음을 비우고 지나친다."

-- 1: risky
tce_dil_01_o1
  choice_index: 1
  label: "치료해 준다"
  risk_level: risky
  visibility_expr: null
  description: "멈춰 설 수 있다. 그러나 시간이 걸릴 것이다."

-- 2: hidden (empathy 보유자 있을 때)
tce_dil_01_o2
  choice_index: 2
  label: "약초로 상처를 덮어준다"
  risk_level: hidden
  visibility_expr: "has_trait:empathy"
  description: "품 안에 지닌 약초 뭉치가 떠올랐다."

[travel_choice_results]
-- o0 safe
tce_dil_01_o0_r0
  option_id: tce_dil_01_o0, result_index: 0
  probability: 1.0
  conditional_expr: null
  narrative: "{merc.name}은 걸음을 멈추지 않았다. 신음 소리는 곧 멀어졌다."
  effect_type: nothing

-- o1 risky (2분기)
tce_dil_01_o1_r0
  option_id: tce_dil_01_o1, result_index: 0
  probability: 0.70
  conditional_expr: null
  narrative: "{merc.name}은 응급처치를 마쳤다. 여행자는 [pick]눈물로|두 손을 모아[/pick] 감사를 전했다."
  effect_type: reputation, effect_magnitude: 10

tce_dil_01_o1_r1
  option_id: tce_dil_01_o1, result_index: 1
  probability: 0.30
  conditional_expr: null
  narrative: "돌보는 사이 병이 옮았다. {merc.name}은 기력을 잃은 채 돌아섰다."
  effect_type: heal_tired, effect_magnitude: -1

-- o2 hidden (2분기, 둘 다 보상)
tce_dil_01_o2_r0
  option_id: tce_dil_01_o2, result_index: 0
  probability: 0.90
  conditional_expr: null
  narrative: "{merc.name}의 손길 아래 여행자는 편히 눈을 감았다 떴다. 품 속에서 말린 약초 뭉치를 꺼내 건넸다."
  effect_type: item, effect_target: herb_bundle, effect_magnitude: 1

tce_dil_01_o2_r1
  option_id: tce_dil_01_o2, result_index: 1
  probability: 0.10
  conditional_expr: null
  narrative: "{merc.name}은 성심껏 도왔으나 여행자의 상처가 깊었다. 그래도 소문은 남았다."
  effect_type: reputation, effect_magnitude: 15
```

#### 9-2. tce_dis_01 — 봉인된 동굴 입구 (discovery, conditional_expr 활용 예시)

```
[travel_choice_events]
id: tce_dis_01
category: discovery
preferred_traits: "scholar"
situation: "벽에 이끼가 짙게 낀 동굴 입구가 있었다. 입구에는 읽히지 않는
           글자가 새겨진 봉인돌이 걸려 있었다. {merc.name}이 천천히 다가섰다."

[options]
o0 (safe):   "지나친다"          — visibility: null
o1 (risky):  "봉인을 깨뜨린다"    — visibility: null
o2 (hidden): "문자를 해독한다"    — visibility: "has_trait:scholar"

[results — o1 risky, 3분기 with conditional_expr]
o1_r0: probability 0.40, conditional_expr: null,
       narrative: "{merc.name}은 돌을 깨뜨렸다. 안에서 낡은 유물이 드러났다.",
       effect_type: item, effect_target: ancient_relic

o1_r1: probability 0.40, conditional_expr: null,
       narrative: "돌은 완고했다. {merc.name}은 어깨를 다쳤다.",
       effect_type: injury, effect_magnitude: 1

o1_r2: probability 0.20, conditional_expr: "has_trait:hardy",
       narrative: "{merc.name}의 억센 어깨 아래 봉인이 둘로 갈라졌다. 안에서 더 큰 것이 빛을 냈다.",
       effect_type: item, effect_target: ancient_relic, effect_magnitude: 2
```

**런타임 동작**:
- `hardy` 미보유 → r2 탈락, r0(0.40)/r1(0.40) → 정규화 → 0.50/0.50
- `hardy` 보유 → r0(0.40)/r1(0.40)/r2(0.20) → 합=1.0, 그대로 랜덤

#### 9-3. tce_haz_02 — 안개 낀 늪 (hazard, hidden 경계 예시)

```
[events]
situation: "길은 깊은 안개에 삼켜졌다. {merc.name}은 발끝을 더듬으며 늪의
           기척을 읽었다. 뒤에서 일행의 발소리가 불안하게 멈췄다."

[options]
o0 (safe):   "지역 가이드를 고용한다"       — cost -20G
o1 (risky):  "안개를 뚫고 강행한다"          — 부상 위험
o2 (hidden): "늪의 기척을 읽는다"            — visibility: "has_trait:survival"

[results — o0 safe]
o0_r0: probability 1.0, narrative: "{merc.name}은 가이드의 등을 따라 안개를 빠져나왔다.",
       effect_type: gold, effect_magnitude: -20

[results — o1 risky]
o1_r0: probability 0.55, narrative: "{merc.name}은 늪을 지나왔다. 진창에 옷이 엉망이었다.",
       effect_type: nothing
o1_r1: probability 0.45, narrative: "{merc.name}은 늪에 발이 빠졌다. 겨우 빠져나왔을 땐 지쳐 있었다.",
       effect_type: heal_tired, effect_magnitude: -1

[results — o2 hidden]
o2_r0: probability 0.85, narrative: "{merc.name}은 늪의 숨결을 읽고 일행을 안전히 이끌었다.",
       effect_type: reputation, effect_magnitude: 5
o2_r1: probability 0.15, narrative: "{merc.name}의 직감이 빛났다. 희귀 약초가 진창 속에서 고개를 내밀었다.",
       effect_type: item, effect_target: rare_herb
```

**시간 가속·피드백 참고**: `heal_tired -1`은 대표 용병에게 피곤 상태 5분(기존 상수) 부여. 이는 시간 가속 영향 받음.

### 10. 도착 후 회상 UI 흐름

페이즈 4-5 spec 대상. 개념 수준에서:

```
┌──────────────────────────────────┐
│  🗺️ 도착 · {region.name}          │
│                                   │
│  오는 길에 있었던 일              │
│                                   │
│  {situation 렌더 결과 — 2~3줄}    │
│                                   │
├──────────────────────────────────┤
│  [ 지나친다 ]     [ 치료해 준다 ] │
│  [ ✦ 약초로 상처를 덮어준다 ]     │
│                                   │
│  (숨겨진 선택지는 ✦ 아이콘 표시 ─ │
│   자동완성, 조건 맞으면 노출)     │
└──────────────────────────────────┘
          ↓ 선택지 클릭
┌──────────────────────────────────┐
│  결과                             │
│                                   │
│  {narrative 렌더 결과}            │
│                                   │
│  + 명성 15                        │
│  + 약초 묶음 1                    │
│                                   │
│          [ 확인 ]                 │
└──────────────────────────────────┘
```

**포인트**:
- 팝업 1: 상황·선택지 / 팝업 2: 결과·효과
- 선택지 버튼 UX는 2개면 가로 배치, 3개면 세로 배치(hidden 하단)
- hidden 선택지에 `✦` 아이콘(또는 별도 색상)으로 "희소한 선택" 힌트. **완전 숨김**이 원칙이나 **조건 충족 시 노출**된 순간 시각 구분
- 활동 로그에 `renderedSituation` + 선택 label + `renderedNarrative` 저장 (퀘스트 서사와 동일 패턴)

### 11. 톤 가이드

#### 11-1. 길이 규격

| 요소 | 규격 |
|------|------|
| situation | 2~3문장, 150~250자. 배경→용병 시점→일행 반응 |
| option.label | 6~12자, 동사형 ("돕는다", "지나친다", "안개를 뚫고 간다") |
| option.description | 0~1문장, 40~80자. 선택 단서·마음가짐 |
| result.narrative | 1~2문장, 40~120자 (quest_narratives 규격 공유) |

#### 11-2. 카테고리별 톤 키워드

| 카테고리 | 톤 중심 | 전형적 표현 | 금지 |
|---------|--------|-----------|------|
| encounter | 사람·말투·권력 | "말투가 서렸다", "이름을 알렸다" | 과장된 허풍 |
| dilemma | 양심·무게·여운 | "돌아섰다", "소문은 남았다", "눈을 감았다 떴다" | 유머, 명백한 설교 |
| discovery | 신비·서늘함·기록 | "이끼가 짙게 낀", "숨결을 읽고", "빛을 냈다" | 과학 용어 |
| hazard | 자연·지형·인내 | "진창에 옷이 엉망이었다", "바람이 거세다", "숨결을 읽고" | 전투 묘사 |

#### 11-3. 결과 톤 매트릭스

| risk_level | 성공 톤 | 실패 톤 |
|-----------|--------|-------|
| safe | 담담·무탈 | 손실 없음 — 서사로 기억만 남김 |
| risky | 보상 강조 | 손실·부상 명시 (유머 금지) |
| hidden | 월등한 보상 + 특별함("소문이 남았다") | 거의 없음. 있어도 소량 보상 후퇴 |

#### 11-4. 공통 제약

- 문어체 기본 ("~했다", "~였다")
- 판타지 정통 톤, 현대어·영단어 금지
- 레퍼런스 고유명사 금지
- `greatFail`급 사망 암시 톤은 사용하지 않음 (이동 중 사망은 자동 이벤트 `injury`·보스 전투로 충분)

## 현재 시스템과의 연관

### 영향받는 기존 시스템

| 시스템 | 영향 내용 |
|--------|---------|
| `TravelEventService` | `rollChoiceEvent` 메서드 추가 (기존 `rollEvent` 유지 + 병렬). 이동 시작 시 **2개의 독립 roll** |
| `MovementProvider` | `ActiveTravel`(기존 상태)에 `choiceEventId: String?` 추가. 도착 시점에 회상 팝업 트리거 |
| `MovementState` | 상태 확장 소폭 |
| `ActivityLog` | 새 엔트리 타입 `travelChoiceCompleted` (HiveField 16) 추가 |
| `QuestResultDialog` / 도착 팝업 | 회상 팝업은 **별도 Dialog 컴포넌트** `TravelChoiceRecallDialog`. 팝업 순서(페이즈 1-6)에 삽입 |
| TemplateEngine(페이즈 1-1) | `evaluationScope: mercenary\|team` 파라미터 추가(§3-2). `has_trait`/`has_any_trait`/`has_all_traits` 평가 범위 확장 |
| `quest_pools.enemy_name`(페이즈 1-4) | 본 이벤트는 `quest.*` 변수 미사용 (`{merc.*}`/`{region.*}`/`{world.*}`만 사용). 영향 없음 |
| Supabase SyncService | `travel_choice_events` / `travel_choice_options` / `travel_choice_results` 3테이블 + `data_versions` 엔트리 |
| M2a 인벤토리(item 효과) | `effect_type=item` 처리 시 `effect_target`을 아이템 id로 인식하여 인벤토리 추가. M2a 인프라 재사용 |

### 신규 인프라 (페이즈 4-5 spec 대상)

| 파일 | 용도 |
|------|------|
| `lib/core/models/travel_choice_event_data.dart` | Freezed 모델 (마스터) |
| `lib/core/models/travel_choice_option_data.dart` | Freezed (선택지) |
| `lib/core/models/travel_choice_result_data.dart` | Freezed (결과) |
| `lib/features/movement/domain/travel_choice_service.dart` | rollChoiceEvent / selectProtagonist / resolveResult / applyEffect |
| `lib/features/movement/view/travel_choice_recall_dialog.dart` | 회상 팝업 UI |

### 호환성 리스크

- **낮음**: 3 신규 테이블 — 기존 데이터 흐름 역영향 없음
- **중간**: `MovementProvider` 도착 처리 흐름에 팝업 추가 단계 삽입. 기존 자동 이벤트 팝업·퀘스트 완료 팝업과 **순서 충돌 우려** → 페이즈 1-6 공존 정책에서 해결
- **중간**: TemplateEngine `evaluationScope` 확장 — 기존 퀘스트 서사 사용처는 `mercenary` default로 호환. 단 페이즈 4-1 spec 소폭 수정
- **낮음**: `applyEventEffect` 확장(`heal_tired` 음수·신규 `item`/`trait_acquired`/`nothing`). 기존 12종 자동 이벤트 영향 없음

## MVP vs 확장 가능 지점

| 범주 | MVP | 확장 가능 |
|------|-----|---------|
| 시나리오 수 | 12종 (카테고리당 3) | M6에서 20~30종으로 확장 |
| 카테고리 | 4종 | 세력 이벤트 카테고리(M4) 추가 |
| 선택지 수 | 2~3개 | 4개 이상 (복잡한 도덕 갈등, M5+) |
| 결과 분기 | 선택지당 2~3개 | 최대 5개 이상 |
| 발동 타이밍 | 도착 후 회상 | 이동 중 "응급 알림"(M4+ 세력 거점 기반) |
| `preferred_traits` | 단일 태그 매칭 | 가중치 기반 매칭, 복수 트레잇 조합 보너스 |
| 효과 타입 | 8종 | `merc_relation`(M5 용병 관계), `chain_progress_boost`(M3 체인 연계) |
| UI | 2단 팝업 (상황→결과) | 멀티스텝 분기(선택지 A→2차 선택지→결과) |
| 데이터 규모 | 12 + 30 + 72 ≈ 114행 | M6에서 250~400행 |

## 구현 우선순위 제안

**우선순위: 높음 (M3 크리티컬 패스)**

사유:
- 페이즈 1-1 TemplateEngine의 두 번째 실사용 영역 — `visibility_expr`·`conditional_expr` 첫 투입
- 방치형 UX를 지키면서 서사 깊이를 추가하는 M3 표어의 절반 구현 (나머지 절반: 체인 퀘스트·변형 섹터·서사 템플릿)
- 페이즈 2-3 balance-designer 수치 튜닝 선행 필요 (선택지 이벤트 확률·EV)

**M3 내 착수 순서 권장**:
1. 페이즈 2-3 balance-designer — EV 정책·발동 확률 수치 확정
2. 페이즈 3-0-4 타입 스펙 `types/travel-choice.md` 작성
3. 페이즈 3-5 data-generator 12종·114행 벌크 생성
4. 페이즈 4-1 TemplateEngine spec에 `evaluationScope` 확장 반영
5. 페이즈 4-5 spec 작성 → 구현

## data-generator 지시사항

본 기획서는 **한 개의 data-generator 호출 + 한 개의 DDL 마이그레이션**을 유발한다.

### (A) Supabase 직접 DDL 마이그레이션

페이즈 3-5 벌크 생성 선행 작업. Supabase MCP `apply_migration`로 3테이블 생성:

```sql
-- §2-1, 2-2, 2-3 DDL 그대로
CREATE TABLE travel_choice_events (...);
CREATE TABLE travel_choice_options (...);
CREATE TABLE travel_choice_results (...);
-- 인덱스 4개
```

`data_versions` 테이블에도 3개 엔트리 추가 (SyncService 감지용).

### (B) `travel_choice_events`/`_options`/`_results` 114행 벌크 생성

- **대상 타입**: `travel-choice` (신규 — 타입 스펙 페이즈 3-0-4 선행 필요)
- **대상 테이블**: 3개 (events 12 + options 30 + results 72)
- **생성 수량**: **약 114행**
- **톤/세계관 가이드**:
  - §11 톤 매트릭스 준수
  - §9 샘플 3개 스타일 참조 (정통 판타지, 문어체, 감성)
  - 레퍼런스 고유명사·현대어 금지
- **구조적 제약**:
  - `id` 명명: `tce_{cat_abbr}_{seq:02d}` (예: `tce_dil_01`). cat_abbr: enc/dil/dis/haz
  - option id: `{event_id}_o{index}` (예: `tce_dil_01_o0`)
  - result id: `{option_id}_r{index}` (예: `tce_dil_01_o0_r0`)
  - category 4종에 각 3개 시나리오 (§8 윤곽 준수)
  - 선택지 수: 기본 시나리오 2개, hidden 포함 시나리오 3개 (12종 중 12종 모두 hidden 포함 MVP — trait FK 실존 확인하여 대체 허용)
  - 결과 수: 선택지당 2~3개, `probability` 합=1.0 유지
  - `conditional_expr` 활용: 12종 중 4~6종, 해당 결과의 probability는 전체 합 1.0 내에서 재분배
  - `visibility_expr`는 **TemplateEngine 허용 연산자만** 사용 (has_trait/joined_faction 등)
  - `preferred_traits` 존재 trait_id FK 확인 (페이즈 3-4 기준 traits 109행)
  - `effect_type` CHECK 제약 준수
  - `effect_magnitude` 범위:
    - gold: -60 ~ +150 (safe ±20~40, risky ±50~100, hidden +100~150)
    - reputation: -10 ~ +35
    - injury: 1 (단일 부상 고정)
    - heal_tired: -1 or +1 (피곤 부여/회복)
    - trait_innate: 1
    - trait_acquired: 1 (버프 부여, 24h)
    - item: 1~2 (수량)
  - `item`의 `effect_target`: M2a 인벤토리 아이템 id 중 하급~중급 풀에서 선택 (herb_bundle, rare_herb, ancient_relic, scout_compass 등 임시 id. 페이즈 3-5 확정 시 `items` 테이블 FK 참조)
  - TemplateEngine 제약 준수 (pick 2~4 후보, if 2단계 상한, 중첩 금지)
- **수치 출처**: 페이즈 2-3 balance-designer 결과 대기. 밸런스 검토 전에는 §7 원칙 적용
- **특수 요구**:
  - `merc.*` 변수 필수 사용 (대표 용병 주인공) — situation/narrative 모두
  - `region.*` 변수 권장 (situation에 `{region.name}` 1회 이상)
  - `world.*`·`quest.*` 변수는 사용하지 않음 (이동 선택지 맥락에서 무의미)
  - `pick` 블록: 12종 중 약 50%에 포함 (narrative 주로)
  - `[if ...]` 블록: situation에 드물게, narrative는 `conditional_expr` 경로로 처리
  - `nothing` effect: safe 선택지 결과에 최소 1회 이상 사용 (12종 중 6~8회)
  - `item` effect: hidden 결과 또는 discovery 카테고리 risky 결과 중심 (12종 중 4~6회)
  - `trait_acquired`: 3~5회 (hidden 선택지 집중)
  - `trait_innate`: 1~2회 (discovery·dilemma 특수 상황)

### (C) 검증 쿼리 (페이즈 3-5 마무리)

data-generator 산출 후 Supabase에서:
```sql
-- 선택지별 probability 합 검증
SELECT option_id, SUM(probability) AS total
FROM travel_choice_results
GROUP BY option_id
HAVING ABS(SUM(probability) - 1.0) > 0.001;

-- visibility_expr의 has_trait 대상 검증
-- (application 측에서 trait FK 확인 — Postgres CHECK 불가)

-- CHECK 제약 전체 확인
-- effect_type, risk_level, category 위반 행 없음
```

## 오픈 질문

- **Q-1 (선택지 이벤트 발동 확률)**: §1-1의 `distance × 0.08~0.12` 초기값이 유저 체감(시간당 2~4회)에 맞는지. → **페이즈 2-3 balance-designer에서 자동 이벤트 확률과 합산 기대치 검증**. 너무 빈번하면 피로, 너무 드물면 시스템 존재감 약화

- **Q-2 (hidden 선택지 UI 표시)**: §3-3 "완전 숨김" 원칙. 단 조건 충족 시 노출되는 순간 **✦ 아이콘 표시** 정도는 유지(§10). 이것도 UX에 부담이면 완전히 숨길지. → **페이즈 4-5 UI spec 프로토타입 시험 후 결정**

- **Q-3 (trait 키워드 실존 검증)**: §8의 preferred_traits에 쓴 `empathy`, `brave`, `scholar` 등 12개 트레잇 키가 **실제 `traits` 테이블의 id로 존재**하는지 확인 필요. 존재하지 않으면 근사 id로 대체(예: `leader` → `charismatic`). → **페이즈 3-5 data-generator 생성 시 traits 조회하여 매핑 확정**

- **Q-4 (preferred_traits vs visibility_expr 트레잇 일치)**: §8 시나리오마다 preferred_traits와 hidden visibility_expr의 트레잇이 동일. **일부러 일치시킴** — 대표 용병(주인공)이 hidden 선택지의 조건 트레잇도 보유한 경우 서사 자연스러움. 단, visibility는 team-wide이므로 대표 용병이 보유하지 않고 다른 용병이 보유하는 경우도 발생 → 서사에서 "동료 {other_merc.name}이 알아봤다"는 식의 분기가 없어 **어색**할 수 있음. → **권장**: 본 MVP에서는 일치 유지. narrative는 "{merc.name}의 품 속에서"처럼 대표 용병 주인공으로 서술. 실제로는 팀에 empathy 보유자가 있으면 표시되지만 서사 주인공이 다른 사람일 수 있다는 미세 불합치 허용. M6 이후 `protagonist = visibility 보유자 중 1명`으로 교체 검토

- **Q-5 (delay 효과 제외 확인)**: §5에서 delay 제외 명시. 그러나 선택지 "가이드 고용" 같은 결과에서 "이동 시간 +N%"가 자연스러울 수 있음. → **권장**: 선택지 이벤트는 **다음 이동 시 적용되는 delay** 효과로 확장 가능(페이즈 4-5 결정). 본 MVP는 제외 유지, 필요 시 effect_type 확장 9번째 추가

- **Q-6 (trait_acquired 학습 가속 매커니즘)**: 페이즈 1-3 region_transform §4-2에서 hidden 섹터 퀘스트에도 동일 매커니즘 제안. **공유 구현** 원칙 확정 필요. → **권장**: `MercenaryStatService`에 `applyTraitLearningBoost(merc_id, duration: 24h, multiplier: 1.5)` API 추가하여 **hidden 섹터 퀘스트·이동 선택지 양쪽에서 공유**. 페이즈 4-3 + 페이즈 4-5 spec 공통 반영

- **Q-7 (item 효과의 아이템 풀)**: 이동 선택지에서 주는 item은 **하급~중급 장비·소모품 풀**에서만. 최고급(`legendary`) 획득은 엘리트·체인 보상 영역. → **권장**: item 풀을 "이동 선택지 드랍 풀"로 별도 태깅 또는 M2a `items.rarity` 필드 기준 common/uncommon만 사용. 페이즈 3-5에서 확정

- **Q-8 (도착 후 팝업 순서 충돌)**: §1-2의 순서 제안(퀘스트→자동 이벤트→선택지→기타)은 페이즈 1-6에서 최종 확정. 만약 퀘스트 완료와 선택지 이벤트가 **동일 도착 시점**에 발동하면 유저는 연속 팝업 4~5개를 클릭. 피로 우려. → **페이즈 1-6 해결**: 한 화면에 "오늘의 기록" 형식으로 요약 표시 후 개별 확장 vs 순차 팝업 유지

- **Q-9 (대표 용병이 FALLBACK인 경우 item 효과)**: 전원 파견 시 `merc.*`는 fallback 용병이지만 선택지 "약초를 건네받는다"의 item 효과는 로스터에 즉시 지급. 서사상 "{merc.name}(파견 중인 용병)이 약초를 받았다"는 부자연스러움. → **권장**: 전원 파견이면 선택지 이벤트 자체를 **발동하지 않음**(rollChoiceEvent 단계에서 건너뜀). 페이즈 4-5 spec 반영

- **Q-10 (로그 표시 규칙)**: 활동 로그에 `renderedSituation`+`선택 label`+`renderedNarrative` 3줄로 쌓이면 한 이벤트가 3개 엔트리 차지. 공간 소비 큼. → **권장**: 단일 엔트리에 "길에서 {name} — [선택] → 결과" 한 줄 요약 + 상세 보기 시 전체 서사. 페이즈 4-5 UI spec

## 다음 단계 후속 안내

**동일 페이즈(1) 남은 산출물**:
- 페이즈 1-6: 공존 정책 정의 — 본 기획서의 도착 후 회상 팝업이 다른 팝업(퀘스트 완료/자동 이벤트/건설 완료/세력 랭크업)과의 순서에서 어디에 위치할지 확정

**후속 페이즈 연결**:
- 페이즈 2-3: `/balance-designer` 인자로 "이동 선택지 기대값 시뮬레이션 — 안전/위험/숨겨진 EV 차별, 자동 이벤트와 합산 체감 빈도" 전달
- 페이즈 3-0-4: `types/travel-choice.md` 타입 스펙 선행 작성 (3테이블 구조 반영)
- 페이즈 3-5: `/data-generator travel-choice --brief @Docs/content-design/[content]20260424_travel_choices.md` 114행 생성. DDL 선행 필요
- 페이즈 4-1 후속 반영: TemplateEngine `evaluationScope` 파라미터 확장(has_trait 등의 team-wide 평가)
- 페이즈 4-5: `/spec-writer @Docs/content-design/[content]20260424_travel_choices.md` (TemplateEngine·balance·data 산출물 경로 포함)

**밸런스 검토 필요 여부**: **예.** EV 정책(§7)·발동 확률(§1-1)·effect_magnitude 범위는 수치 검토 대상. 페이즈 2-3 `/balance-designer` 호출 필수.

**벌크 데이터 생성 필요 여부**: **예.** 페이즈 3-0-4 타입 스펙 선행 후 페이즈 3-5에서 data-generator. DDL은 페이즈 3-5 직전 MCP apply_migration으로 일괄 반영.
