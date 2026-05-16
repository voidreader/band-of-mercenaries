# 지명 의뢰 컨텐츠 기획서

> 작성일: 2026-05-12
> 유형: 신규 컨텐츠 (M6 마일스톤 페이즈 1 #3 — 페이즈 1 마지막 산출물)
> 선행 문서:
> - `Docs/content-design/[content]20260512_achievement-chronicle-system.md` (M6 #1) — 6 위업 카테고리·templateId
> - `Docs/content-design/[content]20260512_titles-and-flagship.md` (M6 #2) — 11 칭호·간판 용병 알고리즘·UserData.flagshipMercId
> - `Docs/roadmap/master_roadmap.md` 라인 1039·1088·1094
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — M4 fixed_quests 컬럼 확장 패턴 (`is_fixed`/`fixed_chain_id`/`fixed_step`/`trust_threshold`)
> - 코드: `QuestSortService` 6슬롯 정렬 (Tier 0 체인 + fixedTier + settlementTier + Tier 1~4)
> 후속:
> - M6 페이즈 2 #1 칭호 효과 수치 (#2 입력) — 본 문서 보상 보너스 수치도 함께 검토
> - M6 페이즈 2 #2 노출 빈도·획득 페이스 — 본 문서 가중치·쿨다운 검증
> - M6 페이즈 4 #3 지명 의뢰 시스템 명세 — 본 문서 + 페이즈 2 결과로 spec-writer 호출

---

## 개요

본 문서는 M6 "이름을 얻는 용병단" 마일스톤의 마지막 토대 시스템인 **지명 의뢰**를 정의한다. 페이즈 1 #1(위업 6 카테고리)과 #2(칭호 11종 + 간판 용병)의 결과를 의뢰 등장 조건으로 활용하여, "강한 용병과 성장한 용병단이 세계에서 다르게 취급받는다"는 M6 컨셉을 의뢰 흐름으로 구현한다.

핵심 결정 사항:
1. **데이터 모델**: `quest_pools` 신규 4 컬럼 추가 (M4 fixed_quests 패턴 100% 재사용). 신규 테이블 없음.
2. **등장 hook 3종**: (a) 칭호 보유 요구 / (b) 위업 보유 요구 / (c) 간판 용병 지명. **의뢰별 단일 조건**(M6 MVP, 복합 조건은 페이즈 4 #3 위임).
3. **노출 빈도**: 일반 풀 자동 갱신 주기(1시간)에 섞여 노출 + 조건 매칭 시 풀 가중치 +α + 24h 쿨다운.
4. **정렬 위치**: 신규 `NamedTier` 추가 — settlementTier 다음, Tier 1(세력 전용) 위. `QuestSortService` 6슬롯 → 7슬롯.
5. **의뢰 7개**: (a) 3개(칭호 hook) + (b) 2개(위업 hook) + (c) 2개(간판 hook).
6. **보상 보너스**: 골드 +30~50% + 명성 +30~50%. 칭호 효과 가산은 자동(#2 칭호 보유 용병 파견 시 PassiveBonusService가 처리).
7. **isDispatched 처리**: **잠금** — 지명 용병이 파견 중일 때 의뢰 카드에 "지명 용병 복귀 대기" 표시. 다른 파티 허용 안 함.
8. **간판 변경 처리**: 진행 중 의뢰 유지(이미 발급된 의뢰는 그대로). 신규 의뢰 생성 시 신규 간판 기준.

종료 조건 매핑:
| roadmap 종료 조건 | 본 문서 충족 |
|---|---|
| "신규 유저 3~5시간 안 1회 이상 지명 의뢰 등장" (라인 1094) | 의뢰 7개 중 5개가 M5 시점 발급 가능. 가중치 +α로 평균 2~4시간 안 1회 자연 노출 |
| "조건 너무 좁아 노출 안 되는 상황 피하기" (라인 1088) | 단일 조건 정책 + 가중치 시스템 + (b) 위업 count 임계 hook으로 누구나 누적 시 도달 가능 |
| "강한 용병/특정 칭호 보유 용병을 요구하는 의뢰가 1회 이상" (라인 1094) | 11 칭호 × 7 의뢰 매칭 + (a)·(b)·(c) 3 hook |

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 본 시스템 적용 |
|---------|-------------|---------------|
| **Crusader Kings III — Personal Quest Offers** | 가신의 특성·평판에 따라 영주에게 다른 의뢰 제시 | 칭호·위업 기반 의뢰. 용병의 정체성이 의뢰 종류를 결정 |
| **Mount & Blade II Bannerlord — Town Notable Quests** | NPC가 플레이어의 명성·관계에 따라 특정 영웅을 지명한 의뢰 부여 | 간판 용병 지명 의뢰 — UserData.flagshipMercId 기준 |
| **Skyrim — Daedric Quests / Companions Quests** | 특정 칭호·길드 가입 후만 받을 수 있는 의뢰 라인 | (a) 칭호 hook — title_road_hunter 보유 시만 "도적길 추적자에게" 의뢰 노출 |
| **Kingdom of Loathing — Specialty Adventures** | 누적 행동/명성 기반 잠금 해제 의뢰 | (b) 위업 count hook — `requires_achievement_count >= N` |
| **Hades — Boon Offers (특정 동료 보유 시)** | 메인 동료의 정체성에 따라 특수 보너스 제시 | (c) 간판 hook — 간판 용병 정체성이 의뢰의 톤·보상 결정 |
| **Pillars of Eternity — Bounty Quests** | 특정 명성에 도달한 PC에게만 보상이 큰 현상금 의뢰 등장 | (b) 위업 임계 hook + 보상 +30~50% 보너스 |

**핵심 설계 원칙**: "**의뢰가 용병을 찾아온다**" — M3 체인은 지역 조사 결과로 발견, M4 fixed_quests는 거점 신뢰도로 해금되지만, 지명 의뢰는 **용병 개인의 정체성을 보고 의뢰인이 찾아오는** 구조. 이것이 M6 컨셉 "이름 얻은 용병단"의 의뢰 차원 구현이다.

---

## 상세 설계

### 1. 데이터 모델 — `quest_pools` 컬럼 확장

#### 1.1 신규 4 컬럼

M4 fixed_quests 패턴 재사용. 새 테이블 없음. SyncService 변경 없음.

| 컬럼 | 타입 | 제약 | 의미 |
|------|------|------|------|
| `is_named` | BOOL | NOT NULL DEFAULT false | 지명 의뢰 여부. true이면 일반 갱신 풀에서 제외하고 named hook 평가 후 노출 |
| `named_hook_type` | TEXT | NULL CHECK | `title` / `achievement` / `flagship`. is_named=true일 때만 NOT NULL |
| `named_hook_value` | TEXT | NULL | hook별 값. title이면 title_id, achievement이면 templateId 또는 count 임계, flagship이면 빈 문자열 |
| `named_cooldown_hours` | INT | NULL DEFAULT 24 | 발급 후 동일 의뢰 재등장 쿨다운 (시간 단위). 페이즈 2 #2에서 조정 |

**CHECK 제약**:
```sql
CONSTRAINT named_hook_type_check CHECK (named_hook_type IS NULL OR named_hook_type IN ('title', 'achievement_count', 'achievement_id', 'flagship')),
CONSTRAINT named_consistency CHECK (
  (is_named = false AND named_hook_type IS NULL AND named_hook_value IS NULL) OR
  (is_named = true AND named_hook_type IS NOT NULL)
)
```

#### 1.2 named_hook_value 형식

| named_hook_type | named_hook_value 예시 | 의미 |
|----------------|----------------------|------|
| `title` | `title_road_hunter` | 칭호 ID. 해당 칭호 보유 용병이 1명 이상일 때 노출 |
| `achievement_count` | `3` (정수 문자열) | 사용자의 위업 보유 수 >= N일 때 노출 (전체 bandAchievements 중 type='achievement' 카운트) |
| `achievement_id` | `chain_completed:chain_roadside_shrine` | 특정 위업 templateId 보유 시 노출 (M6 MVP는 미사용, 페이즈 4 #3 검토) |
| `flagship` | `""` 또는 `"any"` | UserData.flagshipMercId가 non-null일 때 노출 (간판 지정 상태) |

#### 1.3 신규 테이블 미선택 사유

신규 `named_quests` 테이블도 검토했으나 다음 이유로 제외:
- M4 fixed_quests는 이미 `quest_pools.is_fixed` 컬럼 확장 패턴을 정착시켰음 — 패턴 일관성
- SyncService 28개 테이블 추가 부담 (M6 #1·#2 이미 +2개 = 28→30)
- 일반 의뢰와 named 의뢰의 본질적 데이터 구조 동일(quest_type/difficulty/region/sector/enemy/rewards)
- 신규 테이블이면 quest_pools 풀에서 분리 관리 필요 → 코드 복잡도 증가

### 2. 등장 hook 3종 매핑

#### 2.1 Hook 평가 시점

지명 의뢰는 **일반 의뢰 자동 갱신 주기**(1시간)에 hook 평가 후 풀에 포함된다.

```
QuestGenerator.generateQuests() 수정:
  pool := SELECT FROM quest_pools WHERE
    [기존 조건 — region tier 매칭, sector_type 매칭 등]
    AND (
      is_named = false                              -- 일반 의뢰
      OR (
        is_named = true
        AND named_hook 평가 통과
        AND named_cooldown 통과 (마지막 발급 후 24h+)
      )
    )

  최종 5~8개 의뢰 = pool 가중치 sampling
```

named_hook 평가는 다음 단순 분기:

```dart
bool evaluateNamedHook(QuestPool pool, GameState state) {
  switch (pool.namedHookType) {
    case 'title':
      // 사용자가 보유한 모든 용병 중 1명이라도 해당 칭호 보유 시
      return state.mercenaries.any((m) => m.titleIds.contains(pool.namedHookValue));
    case 'achievement_count':
      final required = int.tryParse(pool.namedHookValue ?? '0') ?? 0;
      return state.bandAchievements
        .where((a) => a.type == BandAchievementType.achievement)
        .length >= required;
    case 'achievement_id':
      return state.bandAchievements.any((a) => a.templateId == pool.namedHookValue);
    case 'flagship':
      return state.userData.flagshipMercId != null;
    default:
      return false;
  }
}
```

#### 2.2 쿨다운 추적

named_cooldown_hours 추적을 위해 **UserData.namedQuestCooldowns Map<String, DateTime>** 신규 HiveField **25** 추가 (UserData 다음 가용 25 — #2의 flagshipMercId 24 다음):

```dart
@HiveField(25)
Map<String, DateTime> namedQuestCooldowns;  // quest_pool_id -> 다음 발급 가능 시각
```

발급 흐름:
1. QuestGenerator가 named 의뢰 후보 풀 평가 시 `namedQuestCooldowns[poolId]` 확인
2. 미존재 또는 now() 이후이면 풀 포함 (가중치 +α 부여)
3. 의뢰가 실제 생성되면 (= ActiveQuest로 발급) → `namedQuestCooldowns[poolId] = now + cooldown_hours`
4. 24h 후 다시 발급 가능

**대안 검토**: pool별 last_issued_at 추적 vs 발급 후 cooldown set. 후자가 단순 (페이즈 4 #3에서 확정).

#### 2.3 단일 조건 정책 (M6 MVP)

각 quest_pools 행은 **단일 named_hook**만 사용. 즉:
- "칭호 X 보유 AND 위업 N개 이상" 같은 복합 조건 미지원
- 이유: M6 MVP 단순화. 복합 조건은 페이즈 4 #3 spec-writer 단계 또는 M9+ 검토
- 7개 의뢰 중 #7만 자연스럽게 복합 의미(간판 + 위업)를 가지는데, 이는 hook=flagship으로 단순화하고 의뢰 description에서 의미 표현

### 3. 노출 빈도·쿨다운 정책

#### 3.1 일반 풀 가중치 +α

QuestGenerator의 sampling 알고리즘에서 named 의뢰가 hook 통과 시 가중치 +α 부여:

```dart
List<QuestPool> pickPools(int count, GameState state) {
  final candidates = allEligiblePools(state);
  final weighted = candidates.map((p) {
    int weight = 1; // 기본
    if (p.isNamed && evaluateNamedHook(p, state) && !inCooldown(p)) {
      weight += 3; // +α 가중치 (페이즈 2 #2에서 미세 조정)
    }
    return WeightedItem(p, weight);
  }).toList();
  return weightedSample(weighted, count);
}
```

#### 3.2 노출 페이스 시뮬레이션 (페이즈 2 #2 입력)

신규 유저 누적 플레이 시간 기준 예상 지명 의뢰 등장 횟수:

| 누적 플레이 | 지명 의뢰 등장 | 보유 가능 hook |
|---|---|---|
| 0~1시간 | 0~1회 | flagship만 (간판 자동 지정 시 #6 노출 가능) |
| 1~3시간 | 1~3회 | + (a) 칭호 일부 (#1·#3) + (b) achievement_count 3 (#4) |
| 3~5시간 | 3~6회 | + 추가 칭호 + 위업 누적 |
| 10시간 | 7~10회 | 모든 hook 활성. 쿨다운 24h로 자연 순환 |

roadmap "신규 유저 3~5시간 안 1회 이상 등장"은 1~3시간에 이미 달성 가능. 충분히 안전.

#### 3.3 너무 자주 등장 방지

- 24h 쿨다운으로 동일 의뢰 재등장 차단
- 가중치 +α=3이지만 일반 풀 풀이 크면 (10~20개) 매번 named 의뢰 선택 보장 안 됨 — 자연 분산
- 페이즈 2 #2에서 α=3이 적절한지 검증. 너무 자주 등장하면 α=2, 부족하면 α=5

### 4. 정렬 위치 — 신규 `NamedTier`

`QuestSortService` 6슬롯 → **7슬롯**으로 확장:

```
Tier 0:   체인 active 단계 (ChainTopSection 별도 렌더)
fixedTier: 고정 의뢰 (M4 is_fixed=true, 거점 사건 외)
settlementTier: 거점 사건 (settlement_ prefix)
NamedTier:  지명 의뢰 (is_named=true, 본 문서) ← 신규
Tier 1:   세력 전용 (M1 is_faction_exclusive)
Tier 2:   엘리트 (유니크 → 보통)
Tier 3:   변형 섹터 전용
Tier 4:   일반
```

**왜 settlementTier 다음, Tier 1 위인가**:
- 체인·거점은 시스템 차원 진행도 — 가장 우선
- 지명 의뢰는 용병 개인 정체성 기반 → 세력보다 더 사적 (사용자 1명의 1명 용병에게 의뢰)
- 세력 전용은 가입 세력의 집단 의뢰 — 지명보다 광역
- 엘리트 이하는 일반 의뢰 풀의 분기

**QuestSortService 코드 변경** (페이즈 4 #3):

```dart
class QuestSortService {
  static QuestSortResult sort({...}) {
    // ...
    final namedTier = <ActiveQuest>[];
    // ...
    for (final q in quests) {
      if (poolMap[q.questPoolId]?.isFixed == true) {
        // ... 기존 분기 ...
      } else if (poolMap[q.questPoolId]?.isNamed == true) {
        namedTier.add(q);  // 신규
        continue;
      } else if (q.isChainQuest && ...) {
        // ...
      }
    }
    _sortByEstimatedReward(namedTier, poolMap, typeMap);
    return QuestSortResult(
      chainTier0: chainTier0,
      settlementTier: settlementTier,
      sortedRest: [
        ...fixedTier, ...settlementTier,
        ...namedTier,  // 신규 위치
        ...tier1, ...tier2, ...tier3, ...tier4
      ],
    );
  }
}
```

`QuestSortResult`에 `namedTier` 필드 추가는 선택사항(현재 sortedRest에 흡수해도 충분). 페이즈 4 #3에서 결정.

### 5. 지명 의뢰 7개 명세

#### 5.1 표

| # | id | 의뢰명 | hook | hook_value | quest_type | difficulty | region | 보상 보너스 | M5 발급 |
|---|----|--------|------|-----------|-----------|-----------|--------|----------|---------|
| 1 | `qp_named_village_savior` | 마을의 은인을 찾는다 | title | `title_village_savior` | escort | 2 | 3 (더스트빌 인근) | gold +30% / rep +30% | ✓ |
| 2 | `qp_named_road_hunter` | 도적길 추적자에게 | title | `title_road_hunter` | raid | 3 | T2~T3 기본 | gold +40% / rep +30% | ✓ (raid_count 30 도달 시) |
| 3 | `qp_named_monster_hunter` | 괴물의 흔적을 따른다 | title | `title_monster_hunter` | hunt | 4 | T3~T4 | gold +40% / rep +30% | ✓ (유니크 첫 처치 후) |
| 4 | `qp_named_renowned_3` | 이름 있는 용병단을 찾는다 | achievement_count | `3` | explore | 2 | 광역 (어느 리전이든) | gold +30% / rep +30% | ✓ (2~3시간) |
| 5 | `qp_named_renowned_10` | 전설을 들은 의뢰인 | achievement_count | `10` | raid | 5 | T4~T5 | gold +50% / rep +50% | △ M6 후반 |
| 6 | `qp_named_flagship_letter` | 깃대를 보고 온 편지 | flagship | `""` | escort | 2 | 광역 | gold +30% / rep +30% | ✓ (간판 자동 지정 후) |
| 7 | `qp_named_flagship_legend` | 깃대의 전설을 찾는 자 | flagship | `""` | raid | 4 | T3~T4 | gold +50% / rep +40% | ✓ (간판 + 일정 시간) |

**총 7개**. roadmap "5~8개" 범위 정합.

**hook 분포**:
- (a) title: 3개 (#1·#2·#3)
- (b) achievement_count: 2개 (#4·#5)
- (c) flagship: 2개 (#6·#7)

**M5 발급 가능**: 6개 (#5 제외). roadmap "3~5시간 안 1회 등장" 자연 충족.

#### 5.2 의뢰별 상세 톤 가이드 (페이즈 3 또는 페이즈 4 #3 텍스트 작성용)

##### #1 마을의 은인을 찾는다
- **컨셉**: 더스트빌 인근 마을에서 "폐광길 재개방"의 명성을 들은 한 노인이 호위 의뢰. region 3(더스트빌)과 인접 리전.
- **enemy_name 또는 description 톤**: "그 일을 해낸 사람이라면..."
- **서사 hook**: 칭호 `title_village_savior` 보유 용병이 파견되면 결과 다이얼로그에 "마을의 은인의 명성이 또 하나의 마을에 닿았다" 추가 메시지 (페이즈 4 #3에서 선택).

##### #2 도적길 추적자에게
- **컨셉**: 도적단의 새로운 거점 단서. raid 의뢰. T2~T3 리전.
- **톤**: "도적길에 익숙한 자가 필요하다"
- **보상 정합**: raid_count 30 카운터를 가진 용병이 raid 의뢰를 받으면 칭호 효과 +5%(자동) + 의뢰 보너스 +40% = 자연 시너지.

##### #3 괴물의 흔적을 따른다
- **컨셉**: 엘리트 유니크 첫 처치자에게 또 다른 거대 위협 추적 의뢰. hunt 의뢰. T3~T4.
- **톤**: "그 짐승의 흔적을 본 적 있는가"
- **주의**: M5 시점 유니크 8종 정의 미완성. #2(칭호) 페이즈 1 작성과 의존 — 페이즈 4 #3에서 해당 유니크 ID 매핑 확정.

##### #4 이름 있는 용병단을 찾는다
- **컨셉**: 용병단의 누적 명성이 일정 이상 도달했을 때 처음 등장. explore 의뢰. 광역(어느 리전이든).
- **톤**: "이름 있는 용병단이라 들었다"
- **achievement_count 3**: 신규 유저 2~3시간 기준 위업 3개 누적 자연. 첫 칭호 hook 의뢰가 발급되기 전 fallback 역할.

##### #5 전설을 들은 의뢰인
- **컨셉**: 위업 10개 누적 시 전설급 의뢰. raid 5난이도. T4~T5.
- **톤**: "당신들의 전설을 들었다. 진위를 확인하고 싶다"
- **achievement_count 10**: M6 후반(10~15시간) 도달 가능.

##### #6 깃대를 보고 온 편지
- **컨셉**: 용병단 간판 용병에게 직접 편지가 온 escort 의뢰. 광역.
- **톤**: "용병단의 깃대를 보고 왔습니다. 당신께만 부탁드릴 것이 있습니다."
- **isDispatched 처리**: 간판 용병이 파견 중이면 의뢰 카드에 "{name} 복귀 대기" 표시. 다른 파티 허용 안 함.

##### #7 깃대의 전설을 찾는 자
- **컨셉**: 간판 용병의 명성을 듣고 찾아온 강한 의뢰인. raid 4난이도.
- **톤**: "당신의 깃대 아래에서 임무를 수행하고 싶다는 자가 찾아왔습니다."
- **간판 변경 시**: 의뢰 발급 후 간판이 다른 용병으로 바뀌어도 의뢰는 유지. 단, 의뢰 카드의 description에 표시된 용병 이름은 발급 당시 간판으로 동결.

### 6. 보상 정책

#### 6.1 보너스 구조

지명 의뢰는 일반 의뢰 대비 다음 보너스:

| 항목 | 일반 의뢰 | 지명 의뢰 |
|------|---------|---------|
| 골드 보상 | 기본 (questType.baseReward × difficulty × resultMultiplier) | **기본 × 1.30~1.50** (의뢰별, §5.1 표) |
| 명성 보상 | 기본 (difficulty × 1) | **기본 × 1.30~1.50** |
| XP 분배 | 일반과 동일 | 일반과 동일 (변경 없음) |
| 트레잇 hook | 일반과 동일 | 일반과 동일 |
| 위업 발급 | 카테고리별 hook | **추가 위업 발급 X** (위업은 #1 6 카테고리만, 지명 의뢰 자체는 위업 아님) |

#### 6.2 PassiveBonusService와 자동 통합

지명 의뢰 보너스는 ActiveQuest 발급 시점에 quest_pool.reward 컬럼 또는 별도 reward multiplier 컬럼으로 표현. PassiveBonusService와 별개로 작동.

**보상 배수 적용 순서** (M4 fixed_quests 패턴 정합):
1. 기본 보상 = questType.baseReward × difficulty
2. 결과 배수 (대성공 ×2 등)
3. **지명 의뢰 배수 ×1.3~1.5** (신규)
4. 칭호 효과 (#2 PassiveBonusService.collect — 칭호 보유 용병 파견 시 questRewardMultiplier 등)
5. 세력 효과 / 랭크 효과
6. 최종 골드 결정

명성도 동일 순서. **표 §5.1의 보너스 수치는 페이즈 2 #1·#2에서 검증.**

#### 6.3 칭호 효과와의 시너지

지명 의뢰는 **칭호 보유 용병이 파견되기 자연스러운** 의뢰. 예:
- #2 도적길 추적자에게(raid) → `title_road_hunter` 보유 용병(raid +5%) 파견 → 자동 시너지
- 의뢰 보너스 +40% + 칭호 효과 +5% = "이 용병이 의뢰 적격이다" 명확한 보상 차이

PassiveBonusService가 자동 처리하므로 본 문서에서 추가 정의 불요.

### 7. isDispatched 처리

#### 7.1 잠금 정책

지명된 용병(칭호 보유 / 간판)이 **파견 중일 때 해당 지명 의뢰 카드는 잠금**:

```
지명 의뢰 카드 UI 상태:
  - 통상: [용병 선택 → 파견] 활성
  - 지명 용병 파견 중:
    배경 흐림 + 카드 우측 상단 "{지명 용병명} 복귀 대기" 배지
    [용병 선택] 버튼 비활성
    탭 시 토스트: "지명 용병 {name}이 복귀해야 수행할 수 있습니다"
```

**왜 잠금인가**:
- "지명"의 의미 보존 — 다른 파티로 수행 가능하면 지명 무력화
- 사용자가 지명 용병 복귀 후 자연스럽게 의뢰 수행
- 의뢰 풀에서 사라지는 게 아니라 잠금 상태로 대기 → 사용자에게 시각 단서 유지

#### 7.2 어떤 용병이 "지명"인가

각 hook별 정의:

| hook | 지명 용병 정의 |
|------|-------------|
| (a) title | 해당 칭호 보유 용병들 (1명일 수도, 여러 명일 수도). **전원 파견 중**일 때만 잠금. 한 명이라도 가용하면 통상 |
| (b) achievement_count | 지명 용병 개념 없음. 잠금 무관 (모든 용병이 파티 후보) |
| (c) flagship | UserData.flagshipMercId. 1명 고정. 파견 중이면 잠금 |

#### 7.3 의뢰 만료 처리

지명 의뢰도 일반 의뢰와 동일하게 1시간 갱신 주기에 만료 가능. 단:
- 사용자가 의뢰 풀에서 명시적으로 선택해 파견 → 의뢰는 ActiveQuest 진행으로 전환되어 만료 무관
- 의뢰 풀에 표시만 된 상태로 사용자가 무시 → 1시간 후 풀 갱신 시 다른 의뢰로 교체될 수 있음

### 8. 간판 변경 시 처리

#### 8.1 진행 중 의뢰 유지 정책

간판 용병이 자동/수동 교체되어도 **이미 발급되어 ActiveQuest로 진행 중인 지명 의뢰는 유지**:
- (c) flagship hook 의뢰 발급 시점에 그 의뢰의 "지명 용병"은 당시 간판 용병 ID 고정
- 이후 간판이 다른 용병으로 바뀌어도, 진행 중 의뢰의 지명 용병은 발급 시점 기준 유지
- ActiveQuest에 신규 필드 `namedTargetMercId: String?` (HiveField 26, ActiveQuest 다음 가용 26)로 발급 시점 지명 용병 ID 동결

#### 8.2 신규 의뢰는 신규 간판 기준

발급 시점의 UserData.flagshipMercId 기준으로 신규 의뢰 평가. 간판이 교체된 후 다음 1시간 갱신 주기에는 새 간판 기준으로 hook 평가.

#### 8.3 간판이 사라진 경우 (사망/방출)

간판 용병 사망 → UserData.flagshipMercId = null (자동 리셋, #2 결정) → 자동 알고리즘 재적용 → 새 간판 지정.

진행 중 (c) flagship 의뢰는:
- ActiveQuest.namedTargetMercId가 사망/방출된 용병 ID이므로 의뢰 카드에 "지명 용병 故 {name} — 의뢰 자동 종료" 표시
- 1시간 또는 즉시 ActiveQuest 자동 제거. 사용자에게 1줄 활동 로그 ("지명 의뢰 '{quest_name}'가 지명 용병의 부재로 종료되었다")

페이즈 4 #3에서 종료 정책 확정.

### 9. ActiveQuest 모델 확장 (검토)

#### 9.1 신규 필드 후보

| 필드 | HiveField | 용도 | 도입 결정 |
|------|----------|------|----------|
| `isNamed: bool?` | 26 | 지명 의뢰 여부 (UI 분기) | ❌ 미도입 — quest_pool.is_named로 lookup 가능 |
| `namedTargetMercId: String?` | 26 | 지명 용병 ID 동결 (flagship 의뢰 한정) | ✅ 도입 — flagship 의뢰에 필수, lookup 불가 |
| `namedHookSnapshot: Map<String, dynamic>?` | 27 | hook 평가 스냅샷 (디버그용) | ❌ 미도입 — 페이즈 4 #3에서 필요 시 검토 |

**ActiveQuest HiveField 점유 갱신**: 현재 다음 26 (CLAUDE.md), 본 문서 추가 후 다음 **27**.

#### 9.2 namedTargetMercId 활용

- flagship 의뢰(#6·#7)에서만 사용
- isDispatched 잠금 평가 시 mercenaries[namedTargetMercId].isDispatched 확인
- 의뢰 카드 description 렌더 시 "{name}의 깃대 아래" 동결 표시

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 시스템 | 영향 내용 | 마이그레이션 |
|--------|----------|-------------|
| Supabase `quest_pools` 테이블 | 4 컬럼 추가 (`is_named`/`named_hook_type`/`named_hook_value`/`named_cooldown_hours`) + CHECK 제약 2종 + 7행 INSERT | 페이즈 4 #3 |
| `QuestPool` Freezed 모델 | 4 필드 추가 (`isNamed`/`namedHookType`/`namedHookValue`/`namedCooldownHours`) | 페이즈 4 #3 |
| `UserData` 모델 | HiveField 25 `namedQuestCooldowns: Map<String, DateTime>` 추가 (#2의 flagshipMercId HiveField 24 다음) | 페이즈 4 #3 |
| `ActiveQuest` 모델 | HiveField 26 `namedTargetMercId: String?` 추가 — 다음 가용 27 | 페이즈 4 #3 |
| `QuestGenerator.generateQuests()` | named hook 평가 + 가중치 +α 분기 추가 | 페이즈 4 #3 |
| `QuestSortService` | 신규 NamedTier 분기 추가 (settlementTier 다음, Tier 1 위) — sortedRest 7슬롯 | 페이즈 4 #3 |
| `QuestCompletionService` | 발급 시점 namedQuestCooldowns Map 업데이트 (poolId → next_available_at) | 페이즈 4 #3 |
| 의뢰 카드 UI (`QuestCardBadges` / `LayerSidebar`) | 신규 NamedQuest 배지(✩ 지명 / 칭호명 또는 간판명) + LayerSidebar 색상(예: `AppTheme.chainGold` 또는 신규 `AppTheme.namedAccent`) | 페이즈 4 #3 |
| 의뢰 카드 — isDispatched 잠금 상태 | 지명 용병 파견 중 표시 + 비활성 버튼 + 토스트 | 페이즈 4 #3 |
| operation-bom | quest_pools 편집 폼에 4개 컬럼 추가 (M4 fixed_quests 4 컬럼 추가 패턴 재사용) | 별도 작업 |

### 호환성 검토

- **기존 quest_pools 데이터**: is_named DEFAULT false로 모든 기존 행 자동 호환. named_hook_type NULL.
- **기존 ActiveQuest 세이브**: namedTargetMercId nullable. 기존 데이터 그대로 호환.
- **기존 UserData**: namedQuestCooldowns 빈 Map으로 초기화.
- **QuestSortService**: 신규 NamedTier 추가는 기존 sortedRest에 단순 삽입. 기존 6슬롯 동작 영향 없음.
- **QuestGenerator**: named hook 분기 추가는 기존 일반 풀 로직 영향 없음 (is_named=false 행은 기존대로).

### 호환성 리스크

- **낮음**: named_hook 평가 실패 시 (예: titles 데이터 로딩 안 됨) 의뢰가 풀에 포함되지 않음 — 일반 의뢰로 fallback 자연.
- **중간**: namedQuestCooldowns Map이 Hive에 영속되어 시간 가속 설정 시 cooldown이 어긋날 수 있음. 페이즈 4 #3에서 시간 가속 적용 정책 결정 (기존 퀘스트/건설과 동일 비율 재계산 권장).
- **낮음**: flagship 의뢰 발급 후 간판 변경 시 namedTargetMercId가 stale — 페이즈 4 #3에서 종료 또는 표시 정책 명시 (§8.3).

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| quest_pools 4 컬럼 추가 + 7행 INSERT (§1·§5) | **높음** | 페이즈 4 #3 명세 입력. 데이터 모델 토대 |
| QuestGenerator named_hook 평가 + 가중치 (§2·§3) | **높음** | 의뢰 발급의 핵심 로직 |
| QuestSortService NamedTier 추가 (§4) | **높음** | UI 노출 위치 결정 |
| UserData.namedQuestCooldowns + 쿨다운 추적 (§2.2) | **높음** | 24h 쿨다운 정합 |
| ActiveQuest.namedTargetMercId (§9) | **높음** | flagship 의뢰 동결 |
| 의뢰 카드 차별화 UI (§NamedTier 표시) | **중간** | 신규 배지·색상. 빠르게 보여야 함 |
| isDispatched 잠금 상태 UI (§7) | **중간** | UX 정합 |
| 7행 의뢰 텍스트 데이터 작성 (§5.2 톤 가이드) | **중간** | data-generator 또는 페이즈 4 #3 인라인 |
| 보상 배수 적용 (§6.2) | **중간** | 페이즈 2 #1·#2 검증 후 수치 확정 |
| 간판 변경 시 의뢰 종료 정책 (§8.3) | **낮음** | 드물게 발생. 페이즈 4 #3에서 단순화 가능 |

---

## data-generator 지시사항

본 문서의 7행 quest_pools는 신규 타입 스펙 작성 부담 대비 데이터량이 적어 페이즈 4 #3 명세 인라인 처리를 권장한다. 만약 별도 처리 필요 시 다음 가이드를 따른다.

- **대상 타입**: `named-quest` (신규 — 단순 7행이라 권장 안 함, 페이즈 4 #3 인라인 권장)
- **대상 테이블**: `quest_pools` (is_named=true 행)
- **생성 수량**: **7행** (§5.1 표 그대로 고정)
- **톤/세계관 가이드**:
  - 한국어 판타지 톤. 각 의뢰는 "용병 정체성을 알아본 의뢰인" 톤
  - description 1~2문장. 의뢰인의 1인칭 톤 권장 ("당신의 도적길 추적자에게 부탁드릴 것이..." 등)
  - 각 의뢰의 §5.2 톤 가이드 그대로 사용
  - 고유명사 저작권 금칙
- **구조적 제약**:
  - is_named = true (전 행)
  - named_hook_type 분포: title(3) / achievement_count(2) / flagship(2)
  - named_hook_value §5.1 표 그대로
  - named_cooldown_hours = 24 (기본, 페이즈 2 #2 조정)
  - quest_type 분포: escort(3) / raid(3) / explore(1) / hunt(0)
  - difficulty 분포: 2(3) / 3(1) / 4(2) / 5(1)
  - reward 컬럼은 기본값으로 채우고 reward_multiplier 별도 컬럼 또는 데이터 인라인 추가 (페이즈 2 #1·#2 결정)
- **수치 출처**: 페이즈 2 #1·#2 보상 배수 검증
- **특수 요구**:
  - #2 도적길 추적자에게: enemy_name 도적 관련 ("도적단 척후병" 등)
  - #3 괴물의 흔적: M5 시점 유니크 8종 정의 후 매칭 — 페이즈 4 #3에서 hook_value 정확화
  - #7 깃대의 전설: 간판 용병이 살아있을 때만 발급 — flagship hook으로 자연 충족 (UserData.flagshipMercId null이면 평가 false)
- **검증**:
  - is_named=true 행은 일반 갱신 주기 sampling에서 named hook 평가 후 가중치 +α
  - cooldown 24h 추적 동작 검증

---

## 오픈 질문

- **Q-1 (가중치 α 수치)**: §3.1 명시 +α=3. 페이즈 2 #2에서 시뮬레이션으로 검증. 너무 자주 등장(매 1시간 1개 이상)이면 α=2, 신규 유저 3~5시간 안 미발급이면 α=5. **권장**: 페이즈 2 #2 위임
- **Q-2 (복합 조건 도입 시점)**: 현재 단일 hook만. 복합 조건(예: 칭호 + achievement_count) 도입은 M6 페이즈 4 #3 또는 M9+. **권장**: M6 페이즈 4 #3 검토. 11 칭호 + 24~25 위업 매트릭스가 풀리면 복합 hook이 필요해질 수 있음
- **Q-3 (의뢰 description의 칭호명·간판명 동적 렌더)**: "{merc_with_title.name}이라 들었습니다" 같은 TemplateEngine 활용? **권장**: 페이즈 4 #3 결정. 기본은 정적 텍스트, 동적 렌더는 부가 옵션
- **Q-4 (NamedTier UI 색상)**: chainGold 재사용 vs 신규 namedAccent. **권장**: 페이즈 4 #3 결정. AppTheme에 namedAccent 신규 추가하면 5계층 색상 언어 통일 (chain=금, settlement=주황, named=신규, faction=세력별, elite=elite색)
- **Q-5 (간판 의뢰 발급 후 간판 변경 — 자동 종료 vs 유지)**: §8.3 권장은 사망/방출 시 자동 종료. 자동 알고리즘 교체(생존 상태)는 진행 유지. **권장**: 페이즈 4 #3 spec에서 단순화 결정
- **Q-6 (의뢰 만료 정책)**: 1시간 갱신 시 사용자가 안 받으면 사라지는가? 지명 의뢰는 더 오래 유지? **권장**: 일반 의뢰와 동일 1시간 만료. 단, 다음 갱신 주기에도 hook 통과하면 자연 재등장. 쿨다운은 발급(ActiveQuest 생성) 시에만 시작

---

## 후속 작업

### 페이즈 1 완료

본 문서는 M6 페이즈 1의 마지막 산출물이다. 페이즈 1 완료 체크포인트:
- [x] #1 위업·연대기 시스템 (`[content]20260512_achievement-chronicle-system.md`)
- [x] #2 칭호·간판 용병 (`[content]20260512_titles-and-flagship.md`)
- [x] #3 지명 의뢰 (본 문서)

### 페이즈 2 입력 (예고)

본 문서는 페이즈 2의 두 산출물에 동시 입력:

- **페이즈 2 #1 칭호 효과 수치 밸런스** — 본 문서 §6 보상 배수 (1.30~1.50)가 #2 칭호 효과(2~5%)와 곱해질 때 풀스택 시너지 검증 필요
- **페이즈 2 #2 노출 빈도·획득 페이스 밸런스** — 본 문서 §3 가중치 α=3 / 쿨다운 24h / 7개 의뢰 풀의 신규 유저 5시간 발급 시뮬레이션

### 페이즈 3 (스킵 권장)

7행 데이터는 페이즈 4 #3 명세 인라인 처리. data-generator 타입 스펙(`types/named-quest.md`) 작성 부담 대비 데이터량 적음. M4·M5 동일 방식.

### 페이즈 4 #3 명세 입력

본 문서 + 페이즈 2 #1·#2 결과를 입력으로 spec-writer 호출. 핵심 spec 항목:
- quest_pools 4 컬럼 마이그레이션
- QuestGenerator named_hook 평가 분기
- QuestSortService NamedTier 추가
- UserData.namedQuestCooldowns (HiveField 25)
- ActiveQuest.namedTargetMercId (HiveField 26)
- 의뢰 카드 UI 차별화 + isDispatched 잠금 상태
- 7개 named 의뢰 INSERT (인라인 SQL)

### 밸런스 검토 필요

**예**. 페이즈 2 #1·#2에서 통합 검토.

### 벌크 데이터 생성 필요

**아니오** (소량 7행, 페이즈 4 #3 인라인 권장).

### 구현 명세서 생성

페이즈 4 #3에서:
- 호출: `/spec-writer @Docs/content-design/[content]20260512_named-quests.md` (페이즈 2 #1·#2 결과 + #1·#2 산출물 모두 입력)
