# 간판 용병 의뢰 보상·난이도 수치 밸런스 리포트

> 작성일: 2026-05-21
> 유형: 밸런스 분석 / 수치 확정 / 검토 보완 (M8.5 페이즈 2 #2)
> 분석 대상: M8.5 페이즈 1 #2 솔로/소수정예 의뢰 5종의 보상 배수, 사망 저항 cap, 발급 가중치 α, 쿨다운
> 선행 문서:
> - `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md`
> - `Docs/Archive/20260515_M6_phase4_3_named-quests/design.md`
> - `Docs/spec/[spec]20260519_m8b_combat_simulator.md`
> - `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart`
> - `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart`
> - `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`
> 후속:
> - M8.5 페이즈 3 #4 "간판 용병 솔로/소수정예 의뢰 풀 시드"
> - M8.5 페이즈 4 #2 "간판 솔로/소수정예 QuestGenerator 확장 명세"

---

## 1. 개요

본 리포트는 솔로/소수정예 지명 의뢰 5종의 최종 수치를 확정한다. 검토 과정에서 초안의 파견 시간·비용 계산, 명성 보상 계산, 가중치 α 구현 입력이 현재 코드와 어긋난 점을 보정했다.

### 1.1 주요 보완 결과

다음 항목은 페이즈 4 #2 명세에 반드시 반영한다.

| 항목 | 초안 문제 | 보완 결과 |
|------|----------|----------|
| 시간당 골드 | `base_duration`을 그대로 사용하고 파견비를 임의 중간값으로 계산 | `calculateDispatchDuration`과 `calculateDispatchCost` 산식으로 재계산 |
| 명성 보상 | `difficulty`를 2~4명성처럼 계산 | 실제 `difficulty * 10`, 대성공 `difficulty * 20` 기준으로 보정 |
| 가중치 α | `special_flags.weight_alpha`를 쓰도록 제안했지만 현 코드가 읽지 않음 | `named_weight_alpha`를 명시하고 `QuestGenerator.computeFinalWeight()` 변경 필요로 표기 |
| 부트스트랩 | `title_lone_wolf` 기반 솔로 #1을 신규 초반 노출 후보처럼 해석 | 솔로 #1은 숙련 이후 순환 의뢰로 분리, 초반 노출은 #2/#3 중심 |
| 데이터 가이드 | 삼인행 hook 값이 `achievement_count=10`과 `title_three_kings`로 충돌 | `achievement_count=10`으로 통일 |

### 1.2 최종 결론

페이즈 1 #2의 권장 범위는 유지하되, 실제 경제 산식 기준으로 다음 수치를 확정한다.

| # | id | 난이도 | 유형 | 인원 | 골드 배수 | 명성 배수 | death cap | α | cd |
|---|----|--------|------|------|-----------|-----------|-----------|---|----|
| 1 | `qp_solo_lone_wolf_letter` | 2 | escort | 1 | 2.0 | 1.7 | 0.95 | 2 | 48h |
| 2 | `qp_solo_legend_continued` | 3 | raid | 1 | 1.8 | 1.8 | 0.95 | 2 | 48h |
| 3 | `qp_solo_flagship_request` | 4 | hunt | 1 | 2.2 | 2.0 | 0.95 | 2 | 48h |
| 4 | `qp_pair_shadow_couple` | 3 | raid | 2 | 1.5 | 1.4 | 0.90 | 2 | 36h |
| 5 | `qp_small_three_kings_march` | 4 | explore | 3 | 1.4 | 1.3 | 0.90 | 2 | 36h |

---

## 2. 구현 산식 기준

본 절은 시뮬레이션에 사용하는 실제 코드 기준을 정리한다. 초안의 임의 비용·시간 계산은 사용하지 않는다.

### 2.1 골드 보상

성공 시 골드 보상은 다음 순서로 계산된다.

```text
baseRewardGold = questType.baseReward * difficulty.rewardMultiplier
greatSuccessRewardGold = baseRewardGold * 2
namedRewardGold = rewardGold * special_flags.named_reward_multiplier
finalGrossGold = namedRewardGold * (1 + trackBonus + passiveRewardBonus).clamp(0.0, 0.80)
```

현 코드에서는 `QuestCalculator.calculateReward()`가 기본 보상과 대성공 배수를 먼저 계산하고, `QuestCompletionService`가 `named_reward_multiplier`를 후속 적용한다. 본 리포트의 표는 일반 성공 기준이며, 대성공은 골드와 명성 모두 별도 상향된다.

### 2.2 파견 시간과 파견비

실제 파견 시간은 난이도 보정과 평균 AGI 보정을 받는다. 본 리포트는 비교를 단순화하기 위해 평균 AGI 50, 시간 가속 1.0을 기준으로 한다.

```text
durationSeconds = baseDuration * (1 + (difficulty - 1) * 0.2)
dispatchCost = minCost + (maxCost - minCost) * (durationSeconds / 144)
```

`144`는 난이도 5, `baseDuration=80`일 때의 최대 기준 시간이다. 결과는 `round()` 처리한다.

### 2.3 인건비와 순익

용병 인건비는 파견 성공 여부와 무관하게 완료 보상에서 차감된다. 경제 비교용 순익은 시작 시 선차감되는 파견비까지 포함한다.

```text
economicNetGold = grossGold - totalWage - dispatchCost
goldPerMinute = economicNetGold / (durationSeconds / 60)
```

### 2.4 명성 보상

현 코드의 명성 보상은 `ReputationService.calculateQuestReputation()` 기준이다.

```text
baseReputation = difficulty * (isGreatSuccess ? 20 : 10)
namedReputation = baseReputation * special_flags.named_reputation_multiplier
```

따라서 난이도 2/3/4 성공 보상은 각각 20/30/40명성이다. 초안의 2/3/4명성 계산은 실제 코드와 맞지 않는다.

---

## 3. 솔로 의뢰 보상 시뮬레이션

솔로 의뢰는 인건비가 크게 줄어드는 대신 파티 파워와 사망 분산 리스크가 극단적으로 커진다. 배수는 "고위험 이벤트"로 체감되도록 일반 5인 파티보다 높은 시간당 순익을 허용한다.

### 3.1 솔로 #1: `qp_solo_lone_wolf_letter`

escort, 난이도 2 기준이다. 평균 AGI 50이면 실제 시간은 90초, 파견비는 41G다.

| 케이스 | gross | 인건비 | 파견비 | 순익 | 시간 | 골드/분 |
|--------|-------|--------|--------|------|------|---------|
| 일반 escort d2, 5인 T1 | 135G | 50G | 41G | 44G | 90초 | 29G |
| 일반 escort d2, 5인 T2 | 135G | 125G | 41G | -31G | 90초 | -21G |
| 솔로 x1.8, 1인 T2 | 243G | 25G | 41G | 177G | 90초 | 118G |
| **솔로 x2.0, 1인 T2** | **270G** | **25G** | **41G** | **204G** | **90초** | **136G** |
| 솔로 x2.2, 1인 T2 | 297G | 25G | 41G | 231G | 90초 | 154G |

확정값은 x2.0이다. 이 의뢰는 `title_lone_wolf` 보유자를 대상으로 하므로 초반 부트스트랩 의뢰가 아니라 솔로 숙련 이후의 순환 보상이다.

### 3.2 솔로 #2: `qp_solo_legend_continued`

raid, 난이도 3 기준이다. 실제 시간은 84초, 파견비는 67G다.

| 케이스 | gross | 인건비 | 파견비 | 순익 | 시간 | 골드/분 |
|--------|-------|--------|--------|------|------|---------|
| 일반 raid d3, 5인 T2 | 220G | 125G | 67G | 28G | 84초 | 20G |
| 일반 raid d3, 5인 T3 | 220G | 250G | 67G | -97G | 84초 | -69G |
| 솔로 x1.8, 1인 T3 | 396G | 50G | 67G | 279G | 84초 | 199G |
| 솔로 x2.0, 1인 T3 | 440G | 50G | 67G | 323G | 84초 | 231G |

확정값은 x1.8이다. `achievement_count=5`로 초중반에 열리는 첫 실질 솔로 도전 후보이므로 #3보다 낮은 배수를 유지한다.

### 3.3 솔로 #3: `qp_solo_flagship_request`

hunt, 난이도 4 기준이다. 실제 시간은 128초, 파견비는 137G다.

| 케이스 | gross | 인건비 | 파견비 | 순익 | 시간 | 골드/분 |
|--------|-------|--------|--------|------|------|---------|
| 일반 hunt d4, 5인 T3 | 384G | 250G | 137G | -3G | 128초 | -1G |
| 일반 hunt d4, 5인 T4 | 384G | 500G | 137G | -253G | 128초 | -119G |
| 솔로 x2.0, 1인 T4 | 768G | 100G | 137G | 531G | 128초 | 249G |
| **솔로 x2.2, 1인 T4** | **845G** | **100G** | **137G** | **608G** | **128초** | **285G** |
| 솔로 x2.0, 1인 T3 | 768G | 50G | 137G | 581G | 128초 | 272G |

확정값은 x2.2다. flagship hook 의뢰이며 가장 위험한 솔로 축이므로 최고 배수를 준다.

### 3.4 솔로 명성 보상

성공 기준 명성은 다음과 같다. 대성공은 기본값이 2배가 된 뒤 같은 `named_reputation_multiplier`를 적용한다.

| 의뢰 | 기본 명성 | 배수 | 성공 명성 | 대성공 명성 |
|------|-----------|------|-----------|-------------|
| 솔로 #1 d2 | 20 | 1.7 | 34 | 68 |
| 솔로 #2 d3 | 30 | 1.8 | 54 | 108 |
| 솔로 #3 d4 | 40 | 2.0 | 80 | 160 |

1주 6회 완수, 대성공 30%를 가정하면 솔로/소수정예 의뢰가 만드는 추가 명성은 대략 350~450명성/주다. A랭크 80,000 기준으로는 0.5% 내외이며, E/D 초반 구간에서는 체감 가능한 보상이다. 따라서 명성 인플레이션 위험은 낮지만 초반 랭크업 보조 효과는 존재한다.

---

## 4. 소수정예 의뢰 보상 시뮬레이션

소수정예는 솔로보다 안전하지만 일반 5인 파티보다 인건비가 낮다. 배수는 솔로보다 낮추되, 정확한 인원 제한을 지키는 보상을 제공한다.

### 4.1 페어 #4: `qp_pair_shadow_couple`

raid, 난이도 3, 정확히 2인 기준이다. 시간은 84초, 파견비는 67G다.

| 케이스 | gross | 인건비 | 파견비 | 순익 | 시간 | 골드/분 |
|--------|-------|--------|--------|------|------|---------|
| 일반 raid d3, 5인 T2 | 220G | 125G | 67G | 28G | 84초 | 20G |
| 페어 x1.4, 2인 T3 | 308G | 100G | 67G | 141G | 84초 | 101G |
| **페어 x1.5, 2인 T3** | **330G** | **100G** | **67G** | **163G** | **84초** | **116G** |
| 페어 x1.6, 2인 T3 | 352G | 100G | 67G | 185G | 84초 | 132G |

확정값은 x1.5 / 명성 x1.4다. 2인 파티는 여전히 분산 리스크가 크므로 삼인행보다 높은 배수를 둔다.

### 4.2 삼인행 #5: `qp_small_three_kings_march`

explore, 난이도 4, 정확히 3인 기준이다. 시간은 112초, 파견비는 124G다.

| 케이스 | gross | 인건비 | 파견비 | 순익 | 시간 | 골드/분 |
|--------|-------|--------|--------|------|------|---------|
| 일반 explore d4, 5인 T3 | 256G | 250G | 124G | -118G | 112초 | -63G |
| 삼인행 x1.3, 3인 T3 | 333G | 150G | 124G | 59G | 112초 | 32G |
| **삼인행 x1.4, 3인 T3** | **358G** | **150G** | **124G** | **84G** | **112초** | **45G** |
| 삼인행 x1.5, 3인 T3 | 384G | 150G | 124G | 110G | 112초 | 59G |

확정값은 x1.4 / 명성 x1.3다. 삼인행은 일반 파티와 가장 가까운 규모라 보상 차별을 낮게 잡는다.

### 4.3 소수정예 명성 보상

| 의뢰 | 기본 명성 | 배수 | 성공 명성 | 대성공 명성 |
|------|-----------|------|-----------|-------------|
| 페어 #4 d3 | 30 | 1.4 | 42 | 84 |
| 삼인행 #5 d4 | 40 | 1.3 | 52 | 104 |

명성 배수는 골드보다 낮게 유지한다. 소수정예는 반복 노출 빈도가 솔로보다 높으므로 명성 누적을 억제한다.

---

## 5. 사망 저항 cap 정합성

솔로/소수정예 의뢰는 M8b CombatSimulator의 사망 저항 cap 예외를 사용한다. cap은 사망 불가가 아니라 사망 저항의 상한이다.

### 5.1 최종 cap

| 의뢰 등급 | cap | 이유 |
|-----------|-----|------|
| 일반 의뢰 | 0.80 | 기존 M8b 기본값 |
| 체인 주인공 | 0.90 | 기존 예외 |
| 소수정예 | 0.90 | 체인 주인공과 같은 보호선 |
| 솔로 | 0.95 | 1인 파티 분산 보정 |

### 5.2 예상 사망률

정확한 값은 M8b 전투 로그 시뮬레이터로 재검증해야 한다. 밸런스 입력값으로는 다음 범위를 목표로 한다.

| 의뢰 | 난이도 | cap | 목표 사망률 |
|------|--------|-----|-------------|
| 솔로 #1 escort d2 | 2 | 0.95 | 0.3~0.7% |
| 솔로 #2 raid d3 | 3 | 0.95 | 0.7~1.2% |
| 솔로 #3 hunt d4 | 4 | 0.95 | 1.2~2.0% |
| 페어 #4 raid d3 | 3 | 0.90 | 인당 1.0~1.8% |
| 삼인행 #5 explore d4 | 4 | 0.90 | 인당 1.5~2.5% |

cap을 0.97 이상으로 올리면 솔로 의뢰가 사실상 고수익 안전 의뢰가 된다. cap 0.90으로 낮추면 간판 용병 상실 체감이 너무 강해진다. 따라서 솔로 0.95, 소수정예 0.90을 유지한다.

### 5.3 구현 입력

`CombatSimulator.simulate()`는 현재 per-merc cap 인자를 명시적으로 받지 않는다. 페이즈 4 #2에서는 다음 중 하나를 구현해야 한다.

| 옵션 | 판단 |
|------|------|
| `Map<String, double> deathResistanceCaps` 인자 추가 | 권장. 순수 함수 입력으로 명확하다 |
| `ActiveQuest`에 cap snapshot 저장 | 비권장. pool에서 재구성 가능하고 Hive 필드가 늘어난다 |
| 장비 보너스에 임시로 cap 주입 | 비권장. 의미가 다른 데이터가 섞인다 |

권장 구현은 `QuestCompletionService`가 `pool.partySizeMax`와 파티 구성으로 용병별 cap map을 만들고, `CombatSimulator`의 사망 저항 clamp 단계에서 해당 map을 조회하는 방식이다.

---

## 6. 발급 가중치와 쿨다운

솔로/소수정예 의뢰는 M6 NamedTier 안에 들어간다. 별도 탭을 만들지 않고 `is_named=true` 풀로 발급한다.

### 6.1 현재 코드와 필요한 변경

현재 `QuestGenerator.computeFinalWeight()`는 모든 지명 의뢰에 `+3.0`을 하드코딩한다.

```dart
if (pool.isNamed) weight += 3.0;
```

따라서 SQL에 `special_flags.weight_alpha` 또는 `special_flags.named_weight_alpha`를 넣는 것만으로는 α=2가 적용되지 않는다. 페이즈 4 #2에서 다음처럼 변경해야 한다.

```dart
if (pool.isNamed) {
  final namedAlpha =
      (pool.specialFlags['named_weight_alpha'] as num?)?.toDouble() ?? 3.0;
  weight += namedAlpha;
}
```

키 이름은 `named_weight_alpha`로 고정한다. 기존 M6/M8a 지명 의뢰는 해당 키가 없으므로 α=3을 유지한다.

### 6.2 최종 가중치

| 의뢰 등급 | α | 쿨다운 | 구현 |
|-----------|---|--------|------|
| 기존 M6/M8a 지명 | 3 | 24h | 기본값 |
| 솔로 3종 | 2 | 48h | `special_flags.named_weight_alpha=2` |
| 소수정예 2종 | 2 | 36h | `special_flags.named_weight_alpha=2` |

α=2는 M6 지명 의뢰보다 희소하고, 쿨다운은 솔로가 소수정예보다 길다. 이 조합은 “보이면 고민할 가치가 있는 의뢰”를 만든다.

### 6.3 부트스트랩 빈도

5종 중 초반에 바로 열리는 의뢰와 순환 의뢰를 분리한다.

| 의뢰 | hook | 초반 노출 판단 |
|------|------|----------------|
| 솔로 #1 | `title_lone_wolf` | 솔로 완수 5회 이후 순환 의뢰. 초반 노출 아님 |
| 솔로 #2 | `achievement_count=5` | 초중반 첫 솔로 후보 |
| 솔로 #3 | `flagship` | 간판 용병이 있으면 후보. 난이도 4라 실제 수행은 신중해야 함 |
| 페어 #4 | `achievement_count=8` | 중반 후보 |
| 삼인행 #5 | `achievement_count=10` | 중후반 후보 |

페이즈 1 #2의 “1종 이상 동작” 종료 조건은 #2 또는 #3으로 충족한다. #1은 `title_lone_wolf` 발급 뒤 반복 플레이를 강화하는 역할이다.

---

## 7. 주간 경제 영향

본 절은 초안의 주간 수입 추정을 실제 보상 산식 기준으로 보정한다. 쿨다운이 있으므로 “노출”과 “완수”를 분리한다.

### 7.1 베테랑 주간 완수 가정

베테랑이 대부분의 hook을 충족하고 적극적으로 플레이한다고 가정한다.

| 의뢰 | 주간 완수 | 성공 기준 순익 |
|------|----------|----------------|
| 솔로 #1 | 1~2회 | 204G |
| 솔로 #2 | 1~2회 | 279G |
| 솔로 #3 | 1~2회 | 608G |
| 페어 #4 | 2~3회 | 163G |
| 삼인행 #5 | 2~3회 | 84G |

대표값 10회 완수 기준 주간 순익은 약 2,300~3,000G다. 대성공과 아이템 보상을 포함하면 체감 가치는 더 높아진다.

### 7.2 인플레이션 판단

솔로/소수정예는 일반 의뢰보다 시간당 순익이 높지만 다음 제약을 가진다.

| 제약 | 효과 |
|------|------|
| named hook | 모든 플레이어에게 항상 열리지 않음 |
| 36~48h 쿨다운 | 동일 의뢰 반복 수익 제한 |
| party size 강제 | 파티 파워와 사망 분산 리스크 증가 |
| 인원 파견 잠금 | 핵심 용병 1~3명을 다른 의뢰에 못 씀 |
| 사망 cap 예외 | 사망 가능성을 제거하지 않음 |

따라서 2,300~3,000G/주는 M8.5 핵심 보상 채널로 허용 가능한 범위다. 다만 대성공률이 높고 T4/T5 용병이 솔로 #3을 안정적으로 반복하면 수익이 급증하므로 페이즈 4 #5에서 실제 로그 기반 재검증이 필요하다.

---

## 8. 데이터 시드 매트릭스

페이즈 3 #4 SQL 시드는 아래 값을 직접 사용한다.

### 8.1 `quest_pools` 5행

| id | name | hook_type | hook_value | type_id | difficulty | party_min | party_max | gold | rep | cap | alpha | cd |
|----|------|-----------|------------|---------|------------|-----------|-----------|------|-----|-----|-------|----|
| `qp_solo_lone_wolf_letter` | 그 이름의 되돌아온 일 | `title` | `title_lone_wolf` | `escort` | 2 | 1 | 1 | 2.0 | 1.7 | 0.95 | 2 | 48 |
| `qp_solo_legend_continued` | 전설을 이어붙이는 자 | `achievement_count` | `5` | `raid` | 3 | 1 | 1 | 1.8 | 1.8 | 0.95 | 2 | 48 |
| `qp_solo_flagship_request` | 상행장의 부탁 | `flagship` | `""` | `hunt` | 4 | 1 | 1 | 2.2 | 2.0 | 0.95 | 2 | 48 |
| `qp_pair_shadow_couple` | 한 쌍의 그림자 | `achievement_count` | `8` | `raid` | 3 | 2 | 2 | 1.5 | 1.4 | 0.90 | 2 | 36 |
| `qp_small_three_kings_march` | 삼인행 | `achievement_count` | `10` | `explore` | 4 | 3 | 3 | 1.4 | 1.3 | 0.90 | 2 | 36 |

### 8.2 `special_flags` 형식

`special_flags`는 기존 named multiplier 경로를 재사용한다. 가중치 α는 새 키 `named_weight_alpha`로 읽는다.

```json
{
  "named_reward_multiplier": 2.0,
  "named_reputation_multiplier": 1.7,
  "death_resistance_cap": 0.95,
  "named_weight_alpha": 2
}
```

`party_size_min`, `party_size_max`, `named_cooldown_hours`는 별도 컬럼으로 저장한다.

### 8.3 CHECK 제약

`quest_pools`에 다음 컬럼과 제약을 추가한다.

```sql
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS party_size_min INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS party_size_max INT NULL;

ALTER TABLE quest_pools
  ADD CONSTRAINT quest_pools_party_size_check
  CHECK (
    party_size_min >= 1
    AND (party_size_max IS NULL OR party_size_max >= party_size_min)
  );
```

솔로/소수정예 5행은 모두 `is_named=true`, `party_size_max IS NOT NULL`이어야 한다.

---

## 9. 구현 입력

페이즈 4 #2 명세는 다음 변경을 포함한다.

### 9.1 정적 설정

```dart
class FlagshipSoloQuestConfig {
  static const double soloDeathResistanceCap = 0.95;
  static const double smallPartyDeathResistanceCap = 0.90;
  static const double soloNamedWeightAlpha = 2.0;
  static const double smallPartyNamedWeightAlpha = 2.0;
  static const int soloCooldownHours = 48;
  static const int smallPartyCooldownHours = 36;

  static const partySizeMatrix = <String, ({int min, int max})>{
    'qp_solo_lone_wolf_letter': (min: 1, max: 1),
    'qp_solo_legend_continued': (min: 1, max: 1),
    'qp_solo_flagship_request': (min: 1, max: 1),
    'qp_pair_shadow_couple': (min: 2, max: 2),
    'qp_small_three_kings_march': (min: 3, max: 3),
  };
}
```

### 9.2 필수 코드 변경

| 파일 | 변경 |
|------|------|
| `quest_pool.dart` | `partySizeMin`, `partySizeMax` 추가 후 build_runner 재생성 |
| `quest_generator.dart` | `specialFlags['named_weight_alpha'] ?? 3.0`으로 지명 가중치 계산 |
| `quest_provider.dart` | dispatch 전 `party_size_min/max` 검증 |
| `quest_completion_service.dart` | 솔로/소수정예 성공 시 Mercenary.stats 카운터 증가 |
| `combat_simulator.dart` | per-merc `deathResistanceCaps` 인자 추가 |
| `DispatchDetailScreen` | 정확한 인원 선택 UI와 비활성 안내 |

### 9.3 보상 적용 순서

현재 구현 기준으로 다음 순서를 유지한다.

1. `QuestCalculator.calculateReward()`가 기본 보상, 대성공, track/passive 보너스를 계산한다.
2. `QuestCompletionService`가 `named_reward_multiplier`를 곱한다.
3. 완료 결과에서 인건비를 차감한다.
4. 경제 비교 또는 UI 순수익 표시는 선차감된 파견비까지 함께 보여준다.

중요한 점은 M8.5 솔로 배수를 별도 배수로 추가하지 않는 것이다. 각 `quest_pools` 행의 `named_reward_multiplier`가 최종 지명 배수다.

---

## 10. 검증 항목

페이즈 4 #5에서 다음 수치를 로그로 확인한다.

| 검증 | 목표 범위 |
|------|----------|
| 솔로 #3 성공 기준 순익 | 550~650G |
| 솔로 #3 실제 사망률 | 1.2~2.0% |
| 솔로/소수정예 주간 순익 | 2,300~3,000G |
| 솔로/소수정예 주간 명성 | 350~450 |
| 5~10시간 내 첫 노출 | #2 또는 #3 중 1종 이상 |
| NamedTier 잠식 | 기존 M6/M8a 지명 의뢰가 완전히 밀리지 않을 것 |

검증 결과 솔로 #3이 과도하게 안정적이면 `named_reward_multiplier`를 2.0으로 낮추는 대신 cap은 유지한다. cap을 먼저 낮추면 간판 용병 상실 경험이 급격히 거칠어진다.

---

## 11. 후속 작업

1. 페이즈 3 #4에서 §8.1의 5행 SQL 시드를 작성한다.
2. 페이즈 4 #2에서 `party_size_min/max`, `named_weight_alpha`, `deathResistanceCaps`를 구현한다.
3. `title_lone_wolf`가 #1의 선행 조건이므로 #2/#3이 솔로 숙련 카운터를 먼저 만들 수 있는지 테스트한다.
4. `DispatchDetailScreen`의 보상 미리보기가 `named_reward_multiplier`와 파견비를 모두 반영하는지 확인한다.
5. 페이즈 4 #5에서 실제 로그 기반으로 x2.2 솔로 #3의 골드와 사망률을 재검증한다.
