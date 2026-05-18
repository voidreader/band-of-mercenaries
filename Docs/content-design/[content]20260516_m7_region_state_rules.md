# M7 지역 상태 변화 규칙 — 위험도·안정도·해금 모델 기획서

> 작성일: 2026-05-16
> 유형: 신규 컨텐츠 (M7 마일스톤 — 페이즈 1 산출물 2/4)
> 선행 문서:
> - `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` — M7 페이즈 1 #1, 7개 리전 위험 등급/초기 상태/사건 후 변화 매핑
> - `Docs/Archive/20260424_region-transform-system/design.md` — M3 region-transform (영구 1회성, sector 단위)
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — M4 마을 신뢰도 (region 3 거점, 누적 점수 + 4단계)
> - `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` — RegionState HiveField 0~7 사용 중
> - `CLAUDE.md` — M6 페이즈 4 #1 위업 6 hook (체인·신뢰도·명성·엘리트·제작·사망)
>
> 후속:
> - 페이즈 1 #3 "마을 인프라 성장 설계" — 본 문서의 상태 전이 결과 + 해금 상태 List를 입력으로 받아 거점 단계 전이 트리거 결정
> - 페이즈 1 #4 "이동 목적 강화 + 생활권 진행 곡선" — 본 문서의 7리전 상태 변화 곡선을 입력으로 받아 5~8시간 흐름 검증
> - 페이즈 2 #2 "지역 상태 변화 임계값 확정" — 본 문서의 4단계 + 점수 가감 컨셉을 입력으로 받아 임계 수치 정량화
> - 페이즈 3 #4 "지역 상태별 퀘스트 풀 30~50개" — 본 문서의 QuestGenerator 가중치 정책을 입력으로 받아 quest_pools 신규 컬럼 + 행 생성
> - 페이즈 4 #1 "RegionState 모델 확장 + 지역 상태 시스템" — 본 문서를 명세 입력으로 받아 구현
> - 페이즈 4 #2 "QuestGenerator 지역 상태 가중치 분기" — 본 문서 3.5절을 명세 입력으로 받아 구현

---

## 개요

M7 페이즈 1 #1에서 정의한 7개 생활권 리전(3·31·127·9·10·146·38) 각각이 **자체적으로 상태를 가지고 사건에 따라 변화하는 시스템**을 설계한다. 본 문서는 다음 4가지를 결정한다.

1. **상태 모델** — 위험도(`dangerScore`) 1축 누적 점수 + 4단계 캐시(`dangerLevel`) + 해금 상태 영속 리스트(`unlockedFlags`) 3축
2. **사건 → 상태 전이 규칙** — 같은 quest_type N회 완료 / 특정 사건 단발 / 시간 경과 3가지 트리거가 점수에 영향
3. **QuestGenerator 가중치 정책** — 상태 단계별 quest_pool weight 가중치 + 해금 상태별 가중치 + 비노출 정책
4. **기존 시스템과의 분리 정책** — M3 transform(영구 1회성 섹터 변형) / M4 settlement-trust(region 3 거점 한정 신뢰도) / M5 firstAcquiredMaterialIds(재료 영속) / M6 hook과의 역할 분담

본 문서는 **컨셉 설계**의 산출물이다. 수치(가감량·임계값·시간 단위)는 페이즈 2 #2 밸런스에서 확정한다.

**핵심 원칙 3가지**:
1. **가역적** — region 상태는 사건이나 시간 경과에 따라 양방향으로 변동 가능 (M3 transform의 영구 1회성과 정반대)
2. **region 단위** — 7리전 각각이 독립 상태를 가짐 (M4 settlement-trust는 region 3에만 적용)
3. **단순함 우선** — 1축 점수 + 4단계 캐시로 모델링 (settlement-trust 모델 재사용). 다축 시스템(위협·안정·문화 같은 독립 변수)은 over-engineering으로 판단

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stellaris — Planet "Stability" (-100 ~ +100) | 단일 슬라이더 점수 + 단계 라벨. 사건/정책이 점수 가감. 임계 도달 시 단계 전이 알림 | M7 dangerScore -100 ~ +100 1축 + 4단계 캐시. settlement-trust와 동일 패턴 |
| Crusader Kings 3 — County "Control" + "Development" 분리 | County는 통제도(낮으면 반란) + 개발도(영구 누적) 두 축을 별개로 관리 | M7은 dangerScore(가역) + unlockedFlags(영구) 두 축 분리. 통제도 = dangerLevel, 개발도 = unlockedFlags |
| Mount & Blade Bannerlord — Settlement Loyalty + Prosperity | Loyalty가 낮으면 반란, Prosperity가 높으면 수입. 둘 다 가역적이지만 변동 속도 다름 | M7 dangerScore는 사건당 ±10~20 가감, unlockedFlags는 사건 1회 즉시 토글 — 변동 속도 분리 |
| Pillars of Eternity — Defiance Bay "Faction Reputation" | 세력별 평판이 사건 선택지에 따라 ±. 임계 단계에서 카드 잠금/해금 | M7 dangerLevel별 quest_pool 가중치 분기. 위협 상태에서만 노출되는 의뢰 / 안정 상태에서만 노출되는 의뢰 분리 |
| Slay the Spire — Act 2 Boss-relic "Map Marker" 영속 표시 | 한 번 한 일은 게임 전체에 영구 표시 (다음 런에는 사라짐) | M7 unlockedFlags는 영구 List<String> 누적 (현재 게임 한정, M5 firstAcquiredMaterialIds 패턴) |

**기존 게임과의 차별 포인트**: M3까지의 region 시스템은 정적이었다(이름·티어·환경 태그). M3 region-transform이 첫 동적 변화를 도입했으나 영구 1회성이었다. M4 settlement-trust가 누적+단계 패턴을 도입했지만 region 1곳에만 적용되었다. M7은 **7개 리전 전체에 가역적 상태**를 도입하여 "이동 = 상태 확인 + 사건 진행"이라는 새 게임 루프를 만든다.

---

## 상세 설계

### 1. 상태 3축 모델

#### 1.1 축 1: 위험도 점수 (`dangerScore`) — 1축 누적 점수

```
dangerScore: int (-100 ~ +100)
  -100 ~ -50  : 안정 (stable)
  -49  ~  -1  : 평온 (peaceful)   <- 기본값 (region 생성 시 0)
   0   ~ +49  : 긴장 (tension)
  +50  ~ +100 : 위협 (threat)
```

**근거 (대안 vs 채택)**:

| 옵션 | 설명 | 채택 |
|------|------|------|
| **1축 1점수 (-100~+100)** | settlement_trust 패턴 재사용. 양수=위험, 음수=안정 | ✅ 단순함, 기존 패턴 재사용, 운영 도구 가시성 좋음 |
| 2축 (위험도 0~100 + 안정도 0~100) | 위험과 안정을 독립 축으로 분리 | ❌ 합산 규칙 복잡 (위험 70 + 안정 40 = 어떤 상태?), 4단계 캐시 어려움 |
| 3축 이상 (위험·문화·경제) | RPG 시뮬레이션 게임 패턴 | ❌ M7 MVP에서 over-engineering. M9+ 확장 검토 |

**M4 settlement_trust 패턴과의 차이**:
- settlement_trust: 0~∞ 단방향 누적 (영구 진입, 강등 없음). region 1개.
- M7 dangerScore: -100~+100 양방향. **양방향 변동 가능** (사건으로 점수 증감). 7개 리전.

#### 1.2 축 2: 위험도 단계 캐시 (`dangerLevel`) — 4단계

```dart
enum DangerLevel {
  stable,    // 점수 -100 ~ -50
  peaceful,  // 점수 -49 ~ -1   <- 기본값
  tension,   // 점수  0 ~ +49
  threat,    // 점수 +50 ~ +100
}
```

**용도**: UI 렌더 + QuestGenerator 가중치 분기의 빠른 조회용 캐시. settlement_trust_level과 동일 패턴.

**갱신 시점**: `RegionStateRepository.addDangerScore(regionId, delta)` 호출 후 자동 재계산. dangerLevel 변경 시 트리거 이벤트 발행.

**갱신 후 처리**:
1. dangerLevel이 이전과 다르면 `dangerLevelChangedProvider` publish → dialog queue medium priority
2. ActivityLog `regionDangerLevelChanged` HiveField 32 (페이즈 4 #1에서 신규 추가) — 메시지 예: "{region.name} 상태가 긴장 → 위협으로 변화했다"
3. **M6 위업 hook 평가** (3.7절 참조) — 위협 → 안정 같은 큰 전이 시 위업 발급 후보

#### 1.3 축 3: 해금 상태 영속 리스트 (`unlockedFlags`) — List<String>

```dart
unlockedFlags: List<String>  // 한 번 토글되면 영구 보존 (M7 종료 시점까지)
```

**예시 플래그**:
- `"region_31_bandits_cleared"` — region 31 도적 소탕 첫 완료
- `"region_9_giant_beast_killed"` — region 9 거대 야수 첫 처치
- `"region_146_mist_cleared"` — region 146 안개 사건 첫 해소
- `"region_38_ironbound_pact_completed"` — region 38 chain_ironbound_pact 완주
- `"region_127_nomad_friendly"` — region 127 유목민 친교 달성

**M5 firstAcquiredMaterialIds 패턴 재사용**: 동일한 `List<String>` 영속 리스트. 한 번 추가되면 제거되지 않음. 멱등 추가 (이미 있으면 skip).

**용도**:
1. **QuestGenerator 가중치 적용** — 특정 플래그 존재 시 의뢰 풀 가중치 변경 (3.5절)
2. **거점 인프라 성장 트리거** — 페이즈 1 #3에서 unlockedFlags N개 도달 시 거점 단계 전이 결정
3. **레시피 해금** — `crafting_recipes.unlock_condition_json`에 `{type: "region_flag", flag: "region_9_giant_beast_killed"}` 형태로 통합 (M5 기존 unlock_condition 패턴 확장)

#### 1.4 RegionState HiveField 확장 (페이즈 4 #1 명세 입력)

현재 HiveField 0~7 사용. M7에서 HiveField 8·9·10 추가.

```dart
@HiveType(typeId: 8)
class RegionState extends HiveObject {
  // 기존 0~7 유지
  // ...

  /// M7 — 위험도 점수 (가역적, -100 ~ +100)
  @HiveField(8)
  int? dangerScore; // null = 0 fallback

  /// M7 — 위험도 단계 캐시 (1=stable 2=peaceful 3=tension 4=threat)
  @HiveField(9)
  int? dangerLevel; // null = 2 fallback (peaceful)

  /// M7 — 해금 상태 영속 플래그
  @HiveField(10)
  List<String> unlockedFlags;

  int get currentDangerScore => dangerScore ?? 0;
  int get currentDangerLevel => dangerLevel ?? 2;
  bool hasFlag(String flag) => unlockedFlags.contains(flag);

  RegionState({
    // ... 기존 인자
    this.dangerScore,
    this.dangerLevel,
    List<String>? unlockedFlags,
  }) : unlockedFlags = unlockedFlags ?? [],
       // ... 기존 초기화
}
```

**enum vs int 결정**: 기존 `settlementTrustLevel`을 `int?` 캐시로 저장한 패턴 그대로 따라간다. enum은 코드에서만 사용, Hive 직렬화는 int. typeId 신규 부여 없음.

### 2. 7개 리전의 초기 상태 + 사건 후 변화 매핑 (페이즈 1 #1 입력 반영)

페이즈 1 #1의 7개 리전 매핑표(2.1~2.7절)를 본 모델로 정량화한다.

| 슬롯 | region_id | 이름 | 초기 dangerScore | 초기 dangerLevel | 주요 사건 → 전이 |
|------|-----------|------|------------------|------------------|----------------|
| A | 3 | 더스트플레인 | **0** | peaceful (거점) ~ tension (폐광 sector 2) | 폐광 재개방 6단계 완료 → -30 → stable |
| B | 31 | 도적길 | **+15** | tension | 도적 소탕 5회 → -50 → peaceful → -30 → stable (flag `bandits_cleared`) |
| C | 127 | 변방 해안 | **-10** | peaceful | 유목민 친교 사건 (faction_clue 3단계 모두 달성) → -30 → stable (flag `nomad_friendly`) |
| D | 9 | 외곽 숲 | **+20** | tension | 거대 야수 처치 1회 (elite) → -40 → peaceful (flag `giant_beast_killed`) |
| E | 10 | 풍신 숲 | **+10** | tension | chain_windrunner_trail 3단계 완주 → -30 → peaceful |
| F | 146 | 회색 늪지 | **+30** | tension (초기 위험) | 안개 사건 해소 (특수 사건, 페이즈 1 #4 결정) → -50 → peaceful (flag `mist_cleared`) |
| G | 38 | 부서진 요새 | **+60** | threat (초기 위험, T3 진입) | chain_ironbound_pact 3단계 완주 → -40 → tension → 도굴꾼 소탕 5회 → -30 → peaceful (flag `ironbound_pact_completed`) |

**핵심 관찰**:
- region 3은 dangerScore 0 시작 (거점 sector 1 평온 / 폐광 sector 2 긴장은 sector_type으로 분리되어 quest_pool에 적용 — region 전체로는 0 시작)
- region 38은 dangerScore +60 시작 (T3 첫 진입 시 가장 위험)
- 모든 region이 M7 종료 시점에 **점수 감소 방향**으로 수렴 (사건 해결 → 안정화). 단, 시간 경과로 다시 증가 가능 (3.4절 참조)

**페이즈 2 #2 입력 가이드**:
- 초기 점수 표 그대로 채택 가능 (또는 ±5 조정 자유)
- 사건별 점수 가감량 (-30 ~ -50 범위, 핵심 사건일수록 큰 변동)
- 누적 N회 트리거 사건 (도적 소탕 N회): N=5 권장 + 회당 -10
- 시간 경과 재증가 곡선 (3.4절 참조): 게임 시간 N시간마다 dangerScore +1

### 3. 사건 → 상태 전이 규칙

#### 3.1 트리거 유형 3종

| 트리거 | 발동 조건 | 점수 변동 | 예시 |
|--------|----------|---------|------|
| **누적 (cumulative)** | 같은 quest_pool 또는 quest_type을 N회 완료 | -10 × N (최대 -50) | region 31 도적 소탕 5회 → -50 |
| **단발 (oneshot)** | 특정 사건 1회 완료 | -30 ~ -50 (큰 변동) + unlockedFlags 토글 | region 9 거대 야수 첫 처치 → -40 + flag |
| **시간 경과 (decay)** | dangerScore가 음수일 때 일정 시간 후 자동 증가 | +1 / N시간 (페이즈 2 #2 N 결정) | 시간 경과로 모든 region 점수 0으로 수렴 → 위험 재발 가능 |

#### 3.2 누적 트리거 데이터 모델 (페이즈 3 #4 입력)

`quest_pools` 테이블에 신규 컬럼 1개 추가 권장:

```sql
ALTER TABLE quest_pools ADD COLUMN region_state_effect JSONB;
```

JSONB 구조:
```json
{
  "type": "cumulative",
  "delta_per_completion": -10,
  "cap_per_threshold": -50,
  "threshold_flag": "region_31_bandits_cleared"
}
```

**JSONB 사유**: 단일 정규화 컬럼으로는 표현 어려운 가변 구조 (delta / cap / flag 3개 필드, 일부는 nullable). `quest_pools.special_flags JSONB`와 동일 패턴 (M3 도입).

**대안 (정규화)**: `quest_pool_state_effects` 신규 테이블 생성. M7 MVP에서는 over-engineering으로 판단 → JSONB 채택. M9+ 확장 시 검토.

#### 3.3 단발 트리거 데이터 모델

기존 hook 5종에 통합:
- 체인 완주 → `ChainQuestService.completeChain()` hook 분기 추가 → `RegionStateRepository.addDangerScore(regionId, delta)`
- 엘리트 처치 → `quest_provider._applyCompletionResult` 엘리트 분기 → flag 토글 + 점수 변동
- 특수 사건 (안개 해소 등) → 별도 chain (settlement_146_mist_clearing 같은) → ChainQuestService 완주 hook 활용

**fail-soft trailing side effect 패턴** (M6 페이즈 4 hook과 동일):
```dart
// QuestCompletionService 등 본체 처리 후 마지막에 호출
try {
  await ref.read(regionStateRepositoryProvider).applyDangerScoreFromQuest(
    regionId: quest.regionId,
    questPool: quest.pool,
  );
} catch (_) { /* fail-soft */ }
```

#### 3.4 시간 경과 재증가 (Decay)

**컨셉**: 사건을 해결해도 시간이 지나면 점수가 0(평온)으로 천천히 회귀. 새 사건 발생 가능성.

**파라미터** (페이즈 2 #2 확정):
- 점수가 음수일 때만 적용 (양수일 때는 자연 감소 없음 — 사건 해결 필요)
- 권장: 게임 시간 6시간마다 +1 (실시간 6시간, 시간 가속 적용)
- 양의 점수로 회귀하면 새 quest_pool이 노출되어 사건 재발 트리거

**구현 방식**: `RegionState.lastDangerScoreDecayAt` HiveField 추가 vs gameTick에서 매 틱 체크
- **권장**: 매 틱 체크 (gameTickProvider 1초 stream). dangerScore < 0인 region 7개만 체크하므로 비용 적음. lastDecayAt 필드 추가 없이 `gameTickProvider`에서 `(currentTime - lastDecayAt).inHours >= 6` 식으로 검증

**플레이어 체감**: M7 종료 후 게임 시간 6시간 ~ 12시간 후 region 31·9·146 등이 다시 위험 상태 전이 가능 → 반복 플레이의 동력. M7 시점에서 가장 중요한 건 **단발 / 누적 트리거**. decay는 부차적.

### 4. QuestGenerator 가중치 정책 (페이즈 4 #2 입력)

#### 4.1 상태별 가중치 매트릭스

`QuestGenerator.generateQuests()`에 `RegionState` 주입 → 4단계 dangerLevel × 4 quest_type 매트릭스로 가중치 분기.

| dangerLevel | raid (약탈) | hunt (토벌) | escort (호위) | explore (탐험) |
|-------------|-----------|----------|------------|------------|
| **threat (+50~)** | +200% | +200% | +50% (긴급 호위) | +50% (정찰) |
| **tension (0~+49)** | +100% | +100% | +30% | +30% |
| **peaceful (-49~-1)** | 기본 | 기본 | +20% (안정 시 호위 多) | 기본 |
| **stable (-100~-50)** | -70% (의뢰 적음) | -50% | +50% | +30% (탐험 多) |

→ **위협 상태**: 사건 중심 의뢰 폭증 (raid·hunt 가중치 ↑)
→ **안정 상태**: 일상 의뢰 위주 (호위·탐험 ↑, 약탈·토벌 ↓)

페이즈 2 #2에서 수치 정량화 (+200% / -70% 같은 값 조정).

#### 4.2 해금 플래그별 추가 가중치

`unlockedFlags`에 특정 플래그가 있으면 추가 가중치 적용:

```dart
final flagWeights = {
  'region_31_bandits_cleared': {
    'escort': 1.5,  // 호위 +50% (영구)
    'raid': 0.3,    // 약탈 -70% (도적 다 사라짐)
  },
  'region_9_giant_beast_killed': {
    'hunt': 0.5,    // 토벌 -50% (대형 야수 처리됨)
  },
  // ...
};
```

→ **상태(dangerLevel) 가중치 × 플래그 가중치 = 최종 가중치**

페이즈 3 #4에서 quest_pool마다 어떤 flag와 매칭되는지 데이터로 결정. 페이즈 4 #2에서 가중치 합산 로직 명세.

#### 4.3 비노출 정책 (`region_state_required` / `region_state_excluded`)

특정 의뢰는 특정 상태에서만 노출 (또는 제외):

```sql
ALTER TABLE quest_pools ADD COLUMN region_state_required TEXT;
-- nullable. 값 예: "threat" / "tension" / "stable"
-- 본 컬럼 값과 region의 dangerLevel이 일치할 때만 노출
```

```sql
ALTER TABLE quest_pools ADD COLUMN region_state_excluded TEXT;
-- nullable. 값과 일치 시 노출 안 됨
```

**예시**:
- "도적 정찰" 의뢰 — `region_state_required = "threat"` (위협 상태에서만 노출)
- "평화로운 마차 호위" — `region_state_excluded = "threat"` (위협 상태 제외)

**대안 (정규화)**: `quest_pool_state_conditions` 신규 테이블. 페이즈 4 #2에서 결정. **M7 MVP는 단순 TEXT 컬럼 2개로 충분** → 채택.

#### 4.4 가중치 계산 의사 코드 (페이즈 4 #2 명세 입력)

```dart
double computeFinalWeight(QuestPoolData pool, RegionState state) {
  // 1. 비노출 검증
  if (pool.regionStateRequired != null &&
      pool.regionStateRequired != state.dangerLevelString) return 0.0;
  if (pool.regionStateExcluded != null &&
      pool.regionStateExcluded == state.dangerLevelString) return 0.0;

  // 2. base 가중치 (기존 difficulty + sector_type 기반)
  double weight = pool.baseWeight;

  // 3. dangerLevel 가중치
  weight *= dangerLevelMultiplier[state.dangerLevel][pool.questType];

  // 4. unlockedFlags 가중치
  for (final flag in state.unlockedFlags) {
    weight *= flagMultipliers[flag]?[pool.questType] ?? 1.0;
  }

  // 5. region_state_effect.cap 검증 (cumulative 사건)
  if (pool.regionStateEffect?.type == 'cumulative') {
    final flag = pool.regionStateEffect.thresholdFlag;
    if (state.hasFlag(flag)) {
      // 이미 cap 도달, 의뢰 노출 빈도 축소
      weight *= 0.2;
    }
  }

  return weight;
}
```

### 5. 기존 시스템과의 분리·통합 정책

#### 5.1 M3 region-transform과의 관계

| 항목 | M3 transform | M7 region state |
|------|-------------|----------------|
| **단위** | sector (region 내 1섹터) | region 전체 |
| **가역성** | 영구 1회성 | 가역적 |
| **트리거** | knowledge_threshold=98 임계 | quest 완료 / chain 완주 / 엘리트 처치 / 시간 경과 |
| **저장** | `RegionState.sectorChanges` HiveField 3 | `RegionState.dangerScore`/`dangerLevel`/`unlockedFlags` HiveField 8/9/10 |

**통합 정책**: transform 발생 시 region 상태에는 **약한 영향**. transform이 village/ruins/hidden 어느 것이든 dangerScore -10 (긴장 → 평온 한 단계 완화) 정도. transform 자체는 sector_type을 변경하므로 quest_pool 풀이 바뀌는 별개 효과.

**중요**: M3 transform 18개 리전과 M7 생활권 7개 리전은 거의 겹치지 않음 (region 9 외곽 숲, region 10 풍신 숲, region 146 회색 늪지 등이 transform 대상 — 페이즈 1 #1 SQL 결과 확인). transform이 발생하면 dangerScore도 약하게 갱신.

#### 5.2 M4 settlement-trust와의 관계

| 항목 | M4 settlement-trust | M7 region state |
|------|---------------------|----------------|
| **적용 region** | region 3 한 곳 | 7개 리전 모두 |
| **점수 범위** | 0 ~ ∞ 누적 단방향 | -100 ~ +100 양방향 |
| **단계** | 4단계 (의심·인지·친근·소속) | 4단계 (stable·peaceful·tension·threat) |
| **저장** | `RegionState.settlementTrust`/`settlementTrustLevel` HiveField 4/5 | `RegionState.dangerScore`/`dangerLevel` HiveField 8/9 |
| **트리거** | 고정 사건 + 일반 의뢰 + 이동 선택지 | 의뢰 완료 + 체인 완주 + 엘리트 처치 + 시간 경과 |
| **의미** | "마을 사람들과의 친밀도" — 사회적 | "지역 위험도" — 환경적 |

**통합 정책**: region 3은 두 시스템 모두 보유. 독립 작동. 단, region 3의 특정 사건은 두 시스템에 동시 영향 가능:
- 폐광 재개방 chain step 6 완료 → settlementTrust +100 (4단계 진입) **AND** dangerScore -30 (긴장 → 평온)

**다른 region (31·127·9·10·146·38)은 settlement-trust 미사용**. region_state만 적용. M7 종료 후 M8 세력 재도입 시 거점 추가되면 settlement-trust 패턴 동일 적용 가능.

#### 5.3 M5 firstAcquiredMaterialIds와의 관계

`unlockedFlags`는 firstAcquiredMaterialIds와 **동일 패턴** (영속 List<String>). 데이터 구조 통합 가능성:

| 옵션 | 설명 | 채택 |
|------|------|------|
| A. 두 필드 분리 | firstAcquiredMaterialIds (HiveField 7) + unlockedFlags (HiveField 10) | ✅ 의미 분리. 재료 영속은 M5 고유. 상태 플래그는 M7 고유 |
| B. unlockedFlags 통합 | firstAcquiredMaterialIds 폐기, 모든 영속 플래그를 unlockedFlags로 통합 | ❌ 마이그레이션 필요. M5 코드 변경 부담 |

**권장: A**. 두 필드 분리 유지. 단 양쪽 모두 list 멱등 추가 패턴이므로 코드 재사용 용이.

#### 5.4 M6 hook과의 통합 (페이즈 4 #1 명세 입력)

M6 페이즈 4 #1 위업 시스템의 6 hook (체인·신뢰도·명성·엘리트·제작·사망)에 **신규 7번째 hook 추가 검토**:

- **신규 hook: `region_state_transition`** — dangerLevel 큰 전이 시 (예: threat → peaceful) 위업 발급 후보
  - 예: region 31 첫 안정화 → 위업 "도적길 평정자" 발급
  - 예: region 38 첫 평온 → 위업 "부서진 요새의 영웅" 발급

**band_achievement_templates 신규 카테고리 추가 권장** (페이즈 3 #5에서 결정):
- `region_pacified` 카테고리 신설 — 7개 region 각각 첫 평온 진입 시 위업 발급 (template_id 예: `region_pacified:region_31`)

**M6 칭호 hook과의 통합**: 페이즈 1 #1 4.1절에서 region 31 도적 소탕 → "도적길 추적자" 칭호 매핑됨. M6 칭호 hook은 행동 지표 임계(escort_count 등)와 연결되므로 region_state와 자연 결합:
- 도적 5회 소탕 (dangerScore -50, flag toggle) **AND** escort_count 임계 → 칭호 hook 평가

**페이즈 4 #2 명세 우선순위**:
1. RegionStateRepository.addDangerScore() 내부에서 dangerLevel 전이 감지 → `dangerLevelChangedProvider` publish
2. `dangerLevelChangedProvider` listen → AchievementService.grant(`region_pacified:region_${id}`) fail-soft trailing
3. `dangerLevelChangedProvider` listen → dialogQueue medium priority enqueue (RegionStateChangedDialog 신규)

### 6. 활동 로그·다이얼로그 정책

#### 6.1 ActivityLogType 신규 enum 추가

```dart
@HiveType(typeId: 6)
enum ActivityLogType {
  // ... 기존 0~31 유지
  @HiveField(32) regionDangerLevelChanged,
  @HiveField(33) regionUnlockedFlagToggled,
}
```

**메시지 예시**:
- `regionDangerLevelChanged`: "{region.name} 상태가 긴장 → 평온으로 변화했다"
- `regionUnlockedFlagToggled`: "{region.name}에서 새로운 변화가 일어났다: {flag_description}"

**플래그 description 매핑** (페이즈 3 #4 또는 페이즈 4 #1 인라인 처리):
- `region_31_bandits_cleared` → "도적이 소탕되었다"
- `region_9_giant_beast_killed` → "거대 야수가 처치되었다"
- ... (총 7개 리전 × 약 1~2개 flag = 약 10개 description)

#### 6.2 다이얼로그 정책

신규 다이얼로그 타입 추가 (DialogTypeRegistry 12종 → 13종):

| 타입 | priority | barrierDismissible | 발동 조건 |
|------|----------|-------------------|----------|
| `RegionStateChangedDialog` | **medium** | true | dangerLevel 전이 시 (peaceful → tension 같은 가벼운 변동은 alert 없이 ActivityLog만, 큰 전이만 dialog) |

**가벼운 전이 vs 큰 전이 구분**:
- 가벼운 전이 (alert 없이 ActivityLog만): peaceful ↔ tension, tension ↔ threat (인접 단계)
- 큰 전이 (dialog 발동): stable ↔ tension, stable ↔ threat, peaceful ↔ threat (한 단계 이상 건너뛰기 또는 안정·위협 진입)

**우선순위 vs 기존 다이얼로그**:
- critical: rankUp (변경 없음)
- high: chain / transform / trustUp / achievementUnlocked / titleUnlocked (기존)
- **medium: construction / investigation / travelChoice / regionStateChanged (신규)**

medium에 추가 — investigation 결과와 동일 우선순위. 빈번하지 않은 이벤트이므로 큐 경합 거의 없음.

#### 6.3 Provider 추가

```dart
// RegionStateRepository 변경 → dangerLevel 전이 시 publish
final dangerLevelChangedProvider = StateProvider<DangerLevelChangedEvent?>((ref) => null);

// payload
class DangerLevelChangedEvent {
  final int regionId;
  final DangerLevel from;
  final DangerLevel to;
  final List<String> grantedAchievements; // M6 위업 hook 발급 결과
  final List<String> newFlags;            // 같이 토글된 flag (있으면)
}

// app.dart ref.listen → dialogQueue.enqueue
```

### 7. 페이즈 2·페이즈 3·페이즈 4 입력 요약

#### 7.1 페이즈 2 #2 (지역 상태 변화 임계값 확정) 입력

본 문서에서 결정된 컨셉:
- 4단계 점수 범위: stable -100~-50 / peaceful -49~-1 / tension 0~+49 / threat +50~+100
- 누적 사건 회당 점수 변동: -10 권장
- 단발 사건 점수 변동: -30 ~ -50 권장
- 시간 경과 재증가 (decay): 6시간마다 +1 권장 (양수일 땐 미적용)
- 초기 점수 7개 리전 (2절 표)

**페이즈 2 #2 산출물 권장 내용**:
- 임계값 ±5 범위 조정 (예: tension threshold 0 → -5 또는 +5)
- 누적 사건 회당 변동량 (-10 → -8 또는 -12)
- 단발 사건 변동량 (-40 → -35 또는 -45)
- 시간 경과 N시간 (6 → 4 또는 8)
- region별 초기 점수 자유 조정 (page 1 #1 매핑표 ±10 허용)

#### 7.2 페이즈 3 #4 (지역 상태별 퀘스트 풀 30~50개) 입력

본 문서에서 결정된 컨셉:
- quest_pools 신규 컬럼 3개 (`region_state_effect JSONB` + `region_state_required TEXT` + `region_state_excluded TEXT`)
- 7리전 × 4 quest_type × 4 dangerLevel 매트릭스에서 30~50개 선별

**페이즈 3 #4 산출물 권장 내용**:
- 7리전 각각 4~7개 풀 (총 30~50개)
- 누적 사건 풀 (region_state_effect 채움) ~10개
- 단발 사건 풀 ~7개 (페이즈 1 #1 4.1절 사건 후보표와 정합)
- 상태 조건 풀 (`region_state_required` / `region_state_excluded`) ~10개
- 평범한 의뢰 (모든 조건 null) ~10개

#### 7.3 페이즈 4 #1 (RegionState 모델 확장 + 지역 상태 시스템) 입력

- HiveField 8·9·10 추가 (1.4절)
- `RegionStateRepository.addDangerScore(regionId, delta, source)` 메서드
- `RegionStateRepository.toggleFlag(regionId, flag)` 메서드 (멱등)
- `dangerLevelChangedProvider` Provider (6.3절)
- `RegionStateChangedDialog` 신규 다이얼로그 (6.2절)
- ActivityLog 2종 (6.1절)
- M6 hook 통합 (5.4절) — region_state_transition hook

#### 7.4 페이즈 4 #2 (QuestGenerator 지역 상태 가중치 분기) 입력

- 4단계 × 4 quest_type 가중치 매트릭스 (4.1절)
- 플래그별 추가 가중치 (4.2절)
- 비노출 정책 (4.3절)
- 가중치 계산 의사 코드 (4.4절)

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 영역 | 영향 | 마이그레이션 범위 |
|------|------|------------------|
| `RegionState` 모델 (typeId 8) | HiveField 8·9·10 신규 추가 (dangerScore / dangerLevel / unlockedFlags) | 페이즈 4 #1 |
| `RegionStateRepository` | 신규 메서드 4개 (addDangerScore / setDangerLevel / toggleFlag / hasFlag) | 페이즈 4 #1 |
| `quest_pools` 테이블 | 신규 컬럼 3개 (region_state_effect JSONB / region_state_required TEXT / region_state_excluded TEXT) | 페이즈 3 #4 + 페이즈 4 #1 마이그레이션 |
| `QuestGenerator` | 가중치 분기 + 비노출 정책 + RegionState 주입 | 페이즈 4 #2 |
| `QuestCompletionService` | fail-soft trailing — quest 완료 후 region_state_effect 적용 | 페이즈 4 #1 |
| `ChainQuestService.completeChain()` | hook 추가 — 체인 완주 시 region dangerScore 변동 | 페이즈 4 #1 |
| `EliteLootService` (또는 `_applyCompletionResult`) | hook 추가 — 엘리트 처치 시 flag 토글 + 점수 변동 | 페이즈 4 #1 |
| `gameTickProvider` (1초 stream) | decay 분기 추가 — 음수 dangerScore region 7개 체크, 6시간 경과 시 +1 | 페이즈 4 #1 |
| `ActivityLogType` enum (typeId 6) | HiveField 32·33 추가 | 페이즈 4 #1 |
| `DialogTypeRegistry` | regionStateChanged 신규 추가 (12 → 13종) | 페이즈 4 #1 |
| `dangerLevelChangedProvider` (신규) | StateProvider 채널 | 페이즈 4 #1 |
| `RegionStateChangedDialog` (신규) | medium priority 다이얼로그 | 페이즈 4 #1 |
| `AchievementService` | hook 7번째 추가 (region_state_transition) 검토 | 페이즈 4 #1 (M6 통합 — 본 문서는 권장만) |
| `band_achievement_templates` | `region_pacified` 카테고리 신규 추가 (7행) — 페이즈 3 #5에서 결정 | 페이즈 3 #5 |
| `crafting_recipes.unlock_condition_json` | M5 패턴 확장 — `{type: "region_flag", flag: "..."}` 분기 추가 검토 | 페이즈 4 #2 또는 페이즈 4 #4 |
| `MovementScreen` / `RegionListSection` | region 카드에 dangerLevel 색상 표시 (페이즈 4 #3 별도 결정) | 페이즈 4 #3 |

### 호환성 검토

- **기존 사용자 세이브**: HiveField 8·9·10이 nullable이므로 기존 세이브 호환. null 시 fallback (dangerScore=0, dangerLevel=peaceful, unlockedFlags=[]).
- **M3 transform 시스템**: sectorChanges (HiveField 3)와 dangerScore (HiveField 8) 분리 저장. 상호 영향 약 (5.1절). 기존 transform 18개 리전은 본 M7 7리전과 약간 겹침 (region 9·10·146 — transform 발견 보유), 통합 영향 거의 없음.
- **M4 settlement-trust 시스템**: region 3에 두 시스템 공존. 독립 작동 (5.2절). region 3의 폐광 사건은 두 시스템 모두 영향 가능 (이중 점수 변동, 의도된 동작).
- **M5 firstAcquiredMaterialIds**: 별도 영속 List (HiveField 7). unlockedFlags (HiveField 10)와 분리. 두 시스템 독립 (5.3절).
- **M6 hook 시스템**: 6 hook에 7번째 `region_state_transition` 추가는 본 문서의 권장. AchievementService 코드 변경 1개 메서드 (callback DI 7번째). 페이즈 4 #1에서 결정.
- **운영 도구 (operation-bom)**: regions 편집 폼에 dangerScore 표시 권장 (디버그용). quest_pools 편집 폼에 신규 3컬럼 추가.

### Tier 6~10 비영향 확인

본 시스템은 M7 생활권 7리전(T1~T3)에 한정. 다른 33개 리전(T4~T10)은 RegionState 신규 필드가 nullable이므로 영향 없음. 단, M8 세력 재도입 / M9 데이터 확장 시 동일 패턴 복제 권장.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| 1축 dangerScore + 4단계 캐시 모델 (1절) | **높음** | 페이즈 2 #2 + 페이즈 3 #4 + 페이즈 4 #1 모두 본 모델에 의존 |
| 7개 리전 초기 상태 매핑 (2절) | **높음** | 페이즈 2 #2 수치 입력 |
| 트리거 3종 (누적·단발·decay) 컨셉 (3절) | **높음** | 페이즈 3 #4 + 페이즈 4 #1 데이터·코드 입력 |
| QuestGenerator 가중치 매트릭스 (4절) | **높음** | 페이즈 4 #2 명세 직접 입력 |
| RegionState HiveField 8·9·10 정의 (1.4절) | **높음** | 페이즈 4 #1 모델 확장 입력 |
| quest_pools 신규 컬럼 3개 (3.2·4.3절) | **높음** | 페이즈 3 #4 + 페이즈 4 #1 마이그레이션 |
| M3 transform / M4 settlement-trust 분리 정책 (5.1·5.2절) | **중간** | 페이즈 4 #1 구현 시 모호함 제거 |
| M6 hook 7번째 추가 (5.4절) | **중간** | 페이즈 4 #1에서 결정. 추가 안 해도 M7 자체 동작 가능 (위업 보너스만 없음) |
| 다이얼로그 정책 (6.2절) | **중간** | 페이즈 4 #1 dialogQueue 통합 |
| decay (시간 경과 재증가) (3.4절) | **낮음** | M7 MVP에서는 생략 가능. M8+ 반복 플레이 강화 시 활성 |

---

## 후속 작업

페이즈 1 #3 "마을 인프라 성장 설계"가 본 문서의 unlockedFlags List를 입력으로 받아 다음을 결정한다.
- 거점 인프라 단계 전이 트리거 (예: 7리전 unlockedFlags 합산 N개 도달 → 거점 단계 +1)
- 단계별 해금 효과 (광장 이정표 시각 등) — 본 문서 5.4절 region_state_transition hook과 정합

페이즈 1 #4 "이동 목적 강화 + 생활권 진행 곡선"이 본 문서 2절 7리전 초기 상태 + 사건 후 변화 매핑표를 입력으로 받아 5~8시간 흐름의 dangerScore 변화 곡선을 분 단위로 검증한다.
- 게임 시작 0분: 7리전 점수 평균 +17 (계산: (0+15-10+20+10+30+60)/7 = +17.86)
- 5시간 후 예상: 평균 -15 (사건 진행 결과)
- 8시간 후 예상: 평균 -25 (전반적 안정화)
- 시간 경과 decay (3.4절) 적용 시 12~24시간 후 점수 0 회귀 가능 → 재플레이 동력

페이즈 2 #2 "지역 상태 변화 임계값 확정"이 본 문서 1·3절의 점수·임계 컨셉을 입력으로 받아 수치를 정량화한다.

페이즈 3 #4 "지역 상태별 퀘스트 풀 30~50개"가 본 문서 4절 가중치 매트릭스 + 3절 트리거 데이터 모델을 입력으로 받아 quest_pools 신규 컬럼 + 30~50행 INSERT.

페이즈 4 #1·#2에서 본 문서 전체를 명세 입력으로 받아 구현한다.

---

## data-generator 지시사항

본 문서는 **시스템 모델·규칙 설계** 위주이며 직접적인 벌크 데이터 생성을 유발하지 않는다. 단, 다음 파생 데이터가 후속 페이즈에서 생성된다.

### (A) `quest_pools` 신규 30~50행 (페이즈 3 #4 영역)

- **대상 타입**: `quest-pool` (재사용)
- **대상 테이블**: `quest_pools` (신규 컬럼 3개 추가 후 INSERT)
- **생성 수량**: 30~50행 (M7 페이즈 1 #1 분포: 7리전 × 4 quest_type × 4 dangerLevel 매트릭스에서 선별)
- **톤/세계관 가이드**: 페이즈 1 #1의 7개 리전 분위기 키워드 활용. 도적/야수/안개/도굴꾼 키워드. 변방의 위협을 외지 용병이 해결하는 일상 톤
- **구조적 제약**:
  - 4 quest_type 균형 분포 (raid·hunt·escort·explore)
  - 5 difficulty 분포 (D1·D2·D3 중심, D4·D5는 region 38 부서진 요새 한정)
  - region_state_effect JSONB 분포: 누적 ~10행, 단발 ~7행, 효과 없음 ~25행
  - region_state_required / region_state_excluded 분포: 각 ~5행 / ~5행
- **수치 출처**: 페이즈 2 #2 (임계값) + 페이즈 2 #4 (보상 곡선 — M4 패턴 재사용)
- **특수 요구**:
  - 누적 사건 풀의 `region_state_effect.threshold_flag`는 본 문서 1.3절 8개 flag 중에서만 선택
  - 단발 사건 풀은 페이즈 1 #1 4.1절 7개 리전 사건 후보표와 정합 (region 31 도적 소탕 / region 9 거대 야수 / region 38 도굴꾼 격퇴 등)
- **검증**: 
  - 7리전 각각 최소 4행 이상
  - region_state_effect.threshold_flag 매칭 검증 (1.3절 8개 flag 외 사용 불가)
  - region_state_required 값이 4단계 ('stable'/'peaceful'/'tension'/'threat') 중 하나인지 검증

### (B) `band_achievement_templates` 신규 7행 (페이즈 3 #5 영역 — region_pacified 카테고리)

- **대상 타입**: 기존 26행 패턴 재사용 (별도 타입 스펙 불필요)
- **대상 테이블**: `band_achievement_templates`
- **생성 수량**: 7행 (`region_pacified:region_3` ~ `region_pacified:region_38`)
- **톤/세계관 가이드**: 위업 이름은 7~12자, 지역 명확. 예: "도적길 평정자" / "외곽 숲의 사냥꾼" / "회색 늪지의 빛" / "부서진 요새의 영웅"
- **구조적 제약**:
  - category = "region_pacified"
  - hook_type = "region_state_transition" (M6 hook 신규 추가 — 페이즈 4 #1 결정 의존)
  - hook_value = `region_${id}_first_peaceful` (예: region 31 dangerScore가 처음 0 미만으로 진입 시)
- **수치 출처**: 없음 (스토리/이름만)
- **특수 요구**: M6 hook 7번째 신규 추가 결정 이후에 INSERT (선후 의존). 결정 안 된 경우 페이즈 3 #5에서 보류
