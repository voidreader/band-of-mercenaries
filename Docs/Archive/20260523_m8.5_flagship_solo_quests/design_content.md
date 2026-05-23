# 간판 용병 솔로/소수정예 의뢰 컨텐츠 기획서

> 작성일: 2026-05-21
> 유형: 신규 컨텐츠 (M8.5 페이즈 1 #2)
> 적용 마일스톤: M8.5 "재미 가시화와 폴리싱"
> 선행 문서:
> - `Docs/content-design/[content]20260520_m8.5_livingsphere_dashboard.md` (M8.5 페이즈 1 #1)
> - `Docs/Archive/20260515_M6_phase4_3_named-quests/design.md` (M6 지명 의뢰) — quest_pools 컬럼 확장 패턴, NamedTier 정렬, namedQuestCooldowns
> - `Docs/Archive/20260515_M6_phase4_2_titles-flagship/design.md` (M6 칭호·간판 용병) — 11 칭호, action_stat hook 패턴, flagship 5단계 정렬
> - `Docs/spec/[spec]20260519_m8b_combat_simulator.md` (M8b CombatSimulator) — 사망 저항 cap [0.20, 0.80], 체인 주인공 0.90 상한, 4 페이즈 결정적 시뮬레이션
> - `Docs/roadmap/master_roadmap.md` M8.5 섹션 — 페이즈 1 #2 요구사항
> 후속:
> - M8.5 페이즈 2 #2 "간판 용병 의뢰 보상·난이도 수치" — 본 문서 §보상 정책 수치 검증
> - M8.5 페이즈 3 #4 "간판 솔로/소수정예 의뢰 풀 시드" — 본 문서 §의뢰 5개 명세 SQL화
> - M8.5 페이즈 4 #2 "간판 솔로/소수정예 QuestGenerator 확장 명세" — 본 문서 + 페이즈 2 #2 결과로 spec-writer 호출

---

## 1. 개요

M6 지명 의뢰가 "용병의 정체성을 알아본 의뢰인"을 도입했다면, M8.5 솔로/소수정예 의뢰는 한 발 더 들어가 "**그 용병 한 명에게만 부탁하는 의뢰**"를 만든다. 의뢰의 무게가 파티가 아니라 한 사람(또는 두세 명)에게 실리게 하여, M6에서 자동 선정된 간판 용병에게 "단독 임무의 부담과 영광"이라는 서사적 의미를 부여한다.

M8b CombatSimulator의 결정적 시뮬레이션이 1인 파티에서 분산이 극단적으로 커진다는 점을 이용해 **위험과 보상의 비대칭**을 만든다. 솔로 의뢰는 사망 저항 cap 0.95(체인 주인공 0.90보다도 높음)로 보호하되 안전망은 두지 않고, 보상을 큰 폭으로 부풀려 "감수할 가치가 있는 도전"으로 설계한다.

핵심 결정 사항:
1. **데이터 모델**: M6 지명 의뢰 `quest_pools` 신규 4 컬럼 확장 패턴을 그대로 따른다. `party_size_min` / `party_size_max` 2개 INT 컬럼 추가. 신규 테이블 없음, NamedTier 슬롯 재활용.
2. **파티 규모 2계층**: **솔로**(정확히 1인) + **소수정예**(2~3인). 3계층 이상은 일반 의뢰와 구분 모호.
3. **사망 저항 cap**: 솔로 의뢰 **0.95** / 소수정예 의뢰 **0.90**. 체인 주인공 0.90 상한과 동일선, 솔로는 그보다 0.05 높게.
4. **개인 숙련도 = 4 신규 전용 칭호 + `Mercenary.stats` 카운터**: `solo_completion_count` / `solo_great_success_count` / `pair_completion_count` / `small_party_count` 4 카운터 신설. M6 action_stat hook 패턴을 재사용한다. 신규 mastery 시스템 없음.
5. **장비 목표**: M8a 4 아이템(아티팩트·장신구) 보장 드랍 + 신규 1~2 아이템 확률 드랍. 정식 무기/방어구 진화는 M9로 위임.
6. **의뢰 5개**: 솔로 3(title/achievement/flagship hook 각 1) + 소수정예 2(achievement_count 기반 pair/small_party). 기존 named 풀(M6 7종 + M8a 세력 지명 12종)에 5종을 추가한다.
7. **보상 배수**: 솔로 골드 ×1.8~2.2 / 명성 ×1.7~2.0, 소수정예 ×1.4~1.6 / ×1.3~1.5. M8.5 의뢰는 `special_flags.named_reward_multiplier` / `named_reputation_multiplier`에 최종 배수를 직접 저장하며, 별도 솔로 배수와 중복 적용하지 않는다.

종료 조건 매핑:
| roadmap M8.5 #2 종료 조건 | 본 문서 충족 |
|---|---|
| "간판 용병 1인/소수정예 의뢰가 1종 이상 동작" | 솔로 3 + 소수정예 2 = 5종 |
| "단일 용병에게 의미 부여, M6 간판 시스템과 시너지" | flagship hook 솔로 의뢰 #3 (간판 자동 지정 + 솔로 보상) |
| "M8b 사망 위험과 결합한 도전 의뢰" | 사망 저항 cap 솔로 0.95 / 소수 0.90 + M8b 1인 파티 분산 자연 활용 |

---

## 2. 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 본 시스템 적용 |
|---------|-------------|---------------|
| **Battle Brothers — Specific Contract Requirements** | 일부 의뢰가 "최대 N명" 인원 제한을 명시. 의뢰인의 요구 조건 | 솔로/소수정예 의뢰의 `party_size_max` 강제 — 의뢰가 인원을 제약 |
| **Wartales — Lonely Wolf Side Quests** | 특정 용병 1명만 보내야 하는 단발 의뢰. 큰 보상 + 큰 위험 | 솔로 의뢰 컨셉의 기초 차용. 사망 리스크 + 보상 ×2 |
| **Darkest Dungeon — Heroes' Confessional Quests** | 영웅 1명의 정체성과 트라우마를 다루는 단독 임무 | 솔로 의뢰의 톤 — 의뢰인이 "그 한 사람"에게 의뢰. 다른 용병 동반 불가 |
| **Crusader Kings III — Personal Duels & Quests** | 인물 1명의 명성·실력에 기반한 1대1 결투 의뢰 | 솔로 의뢰의 보상 톤 — "당신의 깃대 아래 단 한 명에게 부탁하고 싶다" |
| **Mount & Blade II — Two-Brothers Smuggling Quests** | "두 명을 보내라"는 명시적 인원 제약 의뢰 | 소수정예 페어(2인) 의뢰 — pair_completion_count 카운터 |
| **Fire Emblem: Three Houses — Paralogue (Side Story) Chapter** | 특정 인물의 과거 사건을 다룬 소규모 정예 임무 | 소수정예 small_party(3인) 의뢰 — "삼인행" 톤 |
| **Stardew Valley — Special Order (Time-Limited Solo Tasks)** | 시간 제한 1인 임무. 완수 시 명성 + 전용 아이템 | 솔로 의뢰의 보상 아이템 드랍 (M8a 아티팩트/장신구 보장) |
| **Hades — Bouldy & Companion Boons (Specific Pair Synergies)** | 특정 캐릭터 페어가 함께 활동할 때만 발생하는 시너지 | 소수정예 페어 의뢰 — 2인 파티의 의도된 협력 톤 |

**핵심 설계 원칙**:
- **"파티가 아니라 사람에게"** — M6 지명 의뢰가 "용병의 정체성"을 호출했다면, M8.5는 "그 용병 한 명 혹은 두세 명"에게 의뢰 무게를 옮긴다. M3 체인 주인공이 "1단계 성공자"라면 솔로 의뢰의 주인공은 "당신이 직접 선택한 그 한 사람"이다.
- **"위험과 영광의 비대칭"** — M8b CombatSimulator의 1인 파티 분산을 게임 디자인의 도구로 사용. 사망 저항 0.95 cap이라도 PRNG 한 번의 critical fail이 그 1명을 위협한다. 보상 ×2.0 배수는 그 위험을 감수할 가치를 보장한다.
- **"기존 시스템의 확장, 신규 시스템 최소화"** — M6 NamedTier · 칭호 action_stat hook · namedQuestCooldowns · MercenarySnapshot.titleIds · M8a 아이템 카탈로그를 모두 재사용. 신규 데이터 모델은 `party_size_min/max` 2개 컬럼뿐.

---

## 3. 상세 설계

### 3.1 데이터 모델 — `quest_pools` 컬럼 확장

#### 3.1.1 신규 2 컬럼

M6 지명 의뢰가 `quest_pools`에 4 컬럼(`is_named`/`named_hook_type`/`named_hook_value`/`named_cooldown_hours`)을 추가했다. M8.5는 그 위에 2 컬럼만 더 추가한다.

| 컬럼 | 타입 | 제약 | 의미 |
|------|------|------|------|
| `party_size_min` | INT | NOT NULL DEFAULT 1 | 의뢰 수행 최소 파견 인원. 일반 의뢰는 1, 솔로 의뢰는 1, 소수정예는 2 |
| `party_size_max` | INT | NULL | 의뢰 수행 최대 파견 인원. NULL이면 제약 없음(일반 의뢰), 솔로는 1, 소수정예는 3 |

**CHECK 제약**:
```sql
CONSTRAINT party_size_check CHECK (
  party_size_min >= 1
  AND (party_size_max IS NULL OR party_size_max >= party_size_min)
)
```

기존 `quest_pools` 행 전체에 `party_size_min = 1`, `party_size_max = NULL`로 자동 채워져 호환된다. 솔로/소수정예 의뢰 5행만 명시 값을 가진다.

앱 모델도 동일한 기본값을 가져야 한다. `QuestPool` Freezed 모델에는 `@Default(1) @JsonKey(name: 'party_size_min') int partySizeMin`과 `@JsonKey(name: 'party_size_max') int? partySizeMax`를 추가한다. 로컬 JSON 캐시가 오래된 경우에도 `partySizeMin=1`, `partySizeMax=null`로 역직렬화되어야 한다.

#### 3.1.2 별도 컬럼 vs `is_named`+JSONB 비교

`named_hook_value` JSONB 안에 인원 제약을 끼워 넣는 방법도 검토했으나 별도 컬럼이 우월하다:
- **UI 분기**: 의뢰 카드에서 "솔로 ⭐"·"페어 ⭐⭐" 배지를 표시하려면 매번 JSONB 파싱이 필요 → 별도 컬럼이 자연
- **DB 인덱스**: `WHERE party_size_max = 1` 같은 검색이 자연
- **QuestGenerator 가독성**: 분기 조건이 명료
- **마이그레이션 부담 적음**: 2 컬럼 NULL/DEFAULT는 호환성 100%

### 3.2 파티 규모 정책

#### 3.2.1 2계층 분류

| 등급 | `party_size_min` | `party_size_max` | 의뢰 카드 배지 | 의뢰 명세 개수 |
|------|------------------|------------------|--------------|---------------|
| **솔로** | 1 | 1 | ⭐ 솔로 | 3종 (§3.6 #1·#2·#3) |
| **소수정예 (페어)** | 2 | 2 | ⭐⭐ 페어 | 1종 (§3.6 #4) |
| **소수정예 (삼인행)** | 3 | 3 | ⭐⭐⭐ 삼인행 | 1종 (§3.6 #5) |
| **일반 의뢰** | 1 | NULL | (배지 없음) | 변경 없음 |

페어와 삼인행을 별도 `party_size`로 묶지 않고 정확한 인원으로 제약하는 것은 의뢰 톤과 부합한다. "두 명이 함께 가는 임무"와 "세 명이 함께 가는 임무"는 서사적으로 다르며 보상도 다르다.

#### 3.2.2 파티 선택 UI 규칙

`DispatchDetailScreen` (의뢰 상세 화면)에서:
- 솔로 의뢰: 용병 1명만 선택 가능. 2명째 체크 시 첫 번째 선택 자동 해제 (radio 동작) + 토스트 "솔로 의뢰는 1명만 파견할 수 있습니다"
- 페어 의뢰: 정확히 2명 선택 강제. 1명 또는 3명 선택 시 [파견] 버튼 비활성 + 안내 "정확히 2명을 선택하세요"
- 삼인행 의뢰: 정확히 3명 선택 강제
- 일반 의뢰: 기존 동작 유지 (1~partyPower 한도)

페이즈 4 #2 명세에서 `partySizeValidation` 헬퍼 추가.

#### 3.2.3 isDispatched 잠금 정책 (M6 정합)

솔로/소수정예 의뢰의 `flagship` hook은 M6 §7.1 잠금 정책을 그대로 따른다:
- (a) title hook 솔로 의뢰: 해당 칭호 보유 용병 전원 파견 중일 때 카드 잠금
- (b) achievement hook: 잠금 없음 (어느 용병이든 후보)
- (c) flagship hook 솔로 의뢰: 간판 용병 파견 중일 때 카드 잠금
- (d) 페어/삼인행 의뢰: hook 매칭 용병 + 다른 용병 조합 자유 (n명 잠금이 너무 까다로움)

### 3.3 위험도 차별화 — M8b CombatSimulator 연계

#### 3.3.1 사망 저항 cap 정책

M8b CombatSimulator는 사망 저항을 `[0.20, 0.80]`로 clamp하고 체인 주인공만 `0.90` 상한으로 예외 처리한다. M8.5는 이 예외 처리 패턴을 확장한다.

| 의뢰 등급 | 사망 저항 cap | 사망 가능 여부 | 보호 정책 |
|----------|-------------|-------------|----------|
| 일반 의뢰 | 0.80 (기본) | 가능 | 없음 |
| 체인 주인공 | 0.90 | 가능 | M8b 기존 예외 |
| **소수정예 의뢰 참가 용병** | **0.90** | **가능** | 본 문서 신규 |
| **솔로 의뢰 참가 용병** | **0.95** | **가능** | 본 문서 신규 |

cap 0.95라도 PRNG 1회의 `nextDouble() >= 0.95`는 5% 확률로 일어난다. 솔로 의뢰의 1인 용병은 그 5%에 노출되며, M8b 시뮬레이션에서 critical hit + flank bonus + 환경 디버프가 겹치면 사망 후보가 된다. 안전망 없음.

#### 3.3.2 M8b 인자 추가

`CombatSimulator.simulate` 호출 시 어떻게 솔로/소수정예 지명 용병의 cap을 알리는가:
- 옵션 A: `CombatSimulator.simulate`에 `Map<String, double> deathResistanceCaps` 신규 인자 추가
- 옵션 B: `ActiveQuest`에 `Map<String, double>? namedMercDeathResistanceCaps` 영속 필드 추가
- 옵션 C: M8b 본체 수정 없이 `QuestCompletionService` 호출 측에서 `partyEquipmentBonuses`에 임시 cap을 끼워넣음

**권장**: 옵션 A. M8b CombatSimulator의 순수 도메인 서비스 특성 유지. `QuestCompletionService`가 `pool.partySizeMax`와 파견 인원 목록으로 `deathResistanceCaps`를 구성해 `CombatSimulator.simulate`에 넘긴다. M8b §FR-11.5 사망 저항 롤 시점에 `deathResistanceCaps[combatantId]` 조회 후 cap 적용. 페이즈 4 #2 spec에서 정밀화.

#### 3.3.3 의뢰 실패 시 처리

솔로 의뢰가 `failure` 또는 `criticalFailure`로 끝났을 때 지명 용병이 사망 후보가 되었으나 cap 0.95에서 살아난 경우:
- 부상 마킹은 정상 적용 (`Mercenary.injure()`)
- 의뢰 자체는 실패로 종료 (보상 없음)
- 활동 로그: `'솔로 의뢰 "{quest_name}" — {merc.name}이(가) 중상으로 귀환했다'`
- 솔로 카운터 증가하지 않음 (성공·대성공 시에만 카운트)

소수정예 의뢰에서 페어/삼인행 중 일부가 사망하면 의뢰는 실패로 처리되되 살아남은 용병의 카운터는 증가하지 않음. "함께 완수한 횟수"가 칭호 발급 hook이다.

### 3.4 발급 hook 매핑

#### 3.4.1 M6 NamedTier 풀에 통합

솔로/소수정예 의뢰는 M6에 도입된 NamedTier 슬롯에 함께 노출된다. 별도 슬롯 만들지 않음. `QuestSortService` 변경 없음.

`QuestSortResult.namedTier` 풀 안에서 추가 정렬:
1. 솔로 의뢰 (`party_size_max = 1`) 우선 (가장 희소)
2. 페어/삼인행 의뢰 (`party_size_max IN (2,3)`) 다음
3. 기존 지명 의뢰 (`party_size_max IS NULL` && `is_named = true`) 그 다음

UI 카드 배지로 시각 구분: ⭐ 솔로 / ⭐⭐ 페어 / ⭐⭐⭐ 삼인행 / (배지 없음) M6 지명. 색상은 모두 `AppTheme.namedAccent`(분홍 마젠타) 공유.

#### 3.4.2 신규 hook 종류

본 문서는 새로운 hook_type을 만들지 않는다. M6 hook 3종(`title`/`achievement_count`/`flagship`)을 그대로 사용한다. 페어/삼인행 의뢰는 신규 hook이 필요하지 않으며, `achievement_count` 또는 `title` hook으로 발급 조건을 만든다.

| 의뢰 | named_hook_type | named_hook_value | party_size |
|-----|----------------|------------------|-----------|
| #1 솔로 (title) | `title` | `title_lone_wolf` (신규) | 1/1 |
| #2 솔로 (achievement) | `achievement_count` | `5` | 1/1 |
| #3 솔로 (flagship) | `flagship` | `""` | 1/1 |
| #4 페어 | `achievement_count` | `8` | 2/2 |
| #5 삼인행 | `achievement_count` | `10` | 3/3 |

#### 3.4.3 발급 가중치·쿨다운

M6 §3.1 가중치 α=3, 쿨다운 24h 정책을 약간 강화한다. 현재 구현은 named 의뢰 전체에 동일 α를 적용하므로, 페이즈 4 #2에서는 `party_size_max` 기반 분기 또는 `special_flags.named_weight_alpha`를 추가해 솔로/소수정예만 α=2를 적용한다.

| 의뢰 등급 | 가중치 α | 쿨다운 |
|----------|---------|--------|
| M6 지명 의뢰 (party_size 무제약) | +3 (M6 기존) | 24h |
| **솔로 의뢰** | **+2** (조금 더 희소) | **48h** |
| **소수정예 의뢰** | **+2** | **36h** |

희소성을 높여 "이 의뢰가 나타났을 때 의미가 있게" 만든다. 페이즈 2 #2에서 신규 유저 누적 플레이 5~10시간 기준 1~2회 자연 노출되는지 검증 후 미세 조정.

### 3.5 개인 숙련도 — `Mercenary.stats` 카운터 + 4 전용 칭호

#### 3.5.1 신규 카운터

`Mercenary.stats` Map<String, int>에 4 신규 카운터:

| 카운터 키 | 증가 시점 | 의미 |
|----------|----------|------|
| `solo_completion_count` | 솔로 의뢰 성공·대성공 완료 시 +1 | 단독 임무 완수 횟수 |
| `solo_great_success_count` | 솔로 의뢰 대성공 완료 시 +1 | 단독 임무 대성공 횟수 |
| `pair_completion_count` | 페어 의뢰 성공·대성공 완료 시 +1 (2명 모두) | 페어 임무 완수 횟수 |
| `small_party_count` | 삼인행 의뢰 성공·대성공 완료 시 +1 (3명 모두) | 삼인행 임무 완수 횟수 |

`failure`·`criticalFailure` 시에는 카운터 증가하지 않음. 사망 시에도 증가하지 않음. "완수한 횟수"만 카운트.

`QuestCompletionService`에서 ActiveQuest 결과 처리 직후 trailing fail-soft로 카운터 증가:
```dart
if (resultType == success || resultType == greatSuccess) {
  if (pool.partySizeMax == 1) {
    // 솔로 카운터
    partyMercs.first.stats['solo_completion_count'] += 1;
    if (resultType == greatSuccess) {
      partyMercs.first.stats['solo_great_success_count'] += 1;
    }
  } else if (pool.partySizeMax == 2 && pool.partySizeMin == 2) {
    for (final m in partyMercs) m.stats['pair_completion_count'] += 1;
  } else if (pool.partySizeMax == 3 && pool.partySizeMin == 3) {
    for (final m in partyMercs) m.stats['small_party_count'] += 1;
  }
}
// 그 다음 TitleService.evaluateActionStatHook fail-soft 호출 (M6 기존)
```

#### 3.5.2 신규 전용 칭호 4종

`titles` 테이블에 4행 추가. M8.5 신규 칭호는 모두 `hook_type='action_stat'`로 통일한다. 신규 위업 템플릿 없이 `Mercenary.stats` 카운터만으로 발급하므로 M6 칭호 발급 경로를 그대로 재사용한다.

| ID | 한국어명 | 발급 hook | 임계값 | PassiveEffect (제안) |
|----|---------|-----------|--------|-------------------|
| `title_lone_wolf` | 외로운 늑대 | action_stat | `solo_completion_count >= 5` | `quest_reward_multiplier(all, +0.03)` |
| `title_silver_pair` | 은빛 페어 | action_stat | `pair_completion_count >= 8` | `mercenary_xp_bonus(+0.08)` |
| `title_three_kings` | 삼인행의 일원 | action_stat | `small_party_count >= 10` | `quest_success_rate_bonus_party_size(min_party_size: 3, +0.03)` |
| `title_unyielding_solo` | 굽히지 않은 자 | action_stat | `solo_great_success_count >= 1` | `injury_rate_modifier(-0.03)` |

신규 PassiveEffect 추가 없음. 위 효과는 현재 `PassiveEffect` sealed type에 존재하는 `quest_reward_multiplier`, `mercenary_xp_bonus`, `quest_success_rate_bonus_party_size`, `injury_rate_modifier`만 사용한다. 효과 강도는 페이즈 2 #2에서 검증한다.

**`title_unyielding_solo` hook**: 솔로 의뢰 대성공 1회 시 `solo_great_success_count`가 증가하고, `TitleService.evaluateActionStatHook`이 이를 평가한다. AchievementService 신규 템플릿은 만들지 않는다.

#### 3.5.3 칭호 효과 자기참조 시너지

`title_lone_wolf` 보유 용병이 솔로 의뢰를 받으면:
- 의뢰 자체 보상 배수 (페이즈 2 #2 결정) — 예 ×2.0 gold
- M6 칭호 PassiveBonusService 효과 +3% gold
- **최종 보상 = 기본 보상 × 솔로 의뢰 배수 × 칭호·세력·랭크 가산 효과**. 중복 솔로 배수는 적용하지 않는다.

플레이어가 의도적으로 외로운 늑대 칭호 보유 용병을 솔로 의뢰에 보내면 "이 의뢰는 그 용병에게 적격이다"라는 명확한 보상 차별이 발생한다. 의뢰 카드에서 추천 용병 힌트 표시도 가능 (페이즈 4 #2 UI 분기).

### 3.6 의뢰 5개 명세

#### 3.6.1 표

| # | id | 의뢰명 | hook | hook_value | quest_type | difficulty | region | party_size | 보상 배수 (제안) |
|---|----|--------|------|-----------|-----------|-----------|--------|-----------|----------------|
| 1 | `qp_solo_lone_wolf_letter` | 그 이름의 되돌아온 일 | title | `title_lone_wolf` | escort | 2 | T1~T2 광역 | 1/1 | gold ×2.0 / rep ×1.7 |
| 2 | `qp_solo_legend_continued` | 전설을 이어붙이는 자 | achievement_count | `5` | raid | 3 | T2~T3 | 1/1 | gold ×1.8 / rep ×1.8 |
| 3 | `qp_solo_flagship_request` | 셔행장의 부탁 | flagship | `""` | hunt | 4 | T3~T4 | 1/1 | gold ×2.2 / rep ×2.0 |
| 4 | `qp_pair_shadow_couple` | 한 쌍의 그림자 | achievement_count | `8` | raid | 3 | T2~T3 | 2/2 | gold ×1.5 / rep ×1.4 |
| 5 | `qp_small_three_kings_march` | 삼인행 | achievement_count | `10` | explore | 4 | T3~T4 | 3/3 | gold ×1.4 / rep ×1.3 |

**총 5개**. 기존 named 풀(M6 일반 지명 7종 + M8a 세력 지명 12종)에 M8.5 솔로/소수정예 5종을 추가한다. 페이즈 3 #4 시드 SQL 작성 입력.

**hook 분포**:
- title: 1개 (#1)
- achievement_count: 3개 (#2·#4·#5)
- flagship: 1개 (#3)

#### 3.6.2 의뢰별 톤 가이드 (페이즈 3 #4 텍스트 작성용)

##### #1 그 이름의 되돌아온 일 (솔로, title hook)
- **컨셉**: `title_lone_wolf` 칭호 보유 용병에게 "그 이름을 들었다, 당신께만 부탁한다"는 호위 의뢰. T1~T2 광역.
- **톤**: "혼자 다닌다는 자가 있다 들었습니다. 그래서 당신께만 부탁하고 싶은 일이 있습니다."
- **서사 hook**: 의뢰 완료 시 결과 다이얼로그에 "외로운 늑대의 이름이 또 한 번 입에 오르내렸다" 추가 메시지 (페이즈 4 #2 결정).

##### #2 전설을 이어붙이는 자 (솔로, achievement_count hook)
- **컨셉**: 용병단 위업 5개 누적 시 등장. "당신들 중 한 명이 전설의 이야기를 새로 써달라" raid 의뢰. T2~T3.
- **톤**: "당신네들 중 가장 강한 한 사람이라면 이 일을 해낼 수 있을 거라 들었다."
- **achievement_count 5**: 신규 유저 3~5시간 누적 가능. M6 #4(achievement_count 3)보다 약간 강한 hook으로 솔로 도전 가치 표현.

##### #3 셔행장의 부탁 (솔로, flagship hook)
- **컨셉**: 간판 용병 본인에게 직접 부탁이 들어온 hunt 의뢰. T3~T4의 어려운 짐승 사냥. 솔로 의뢰의 정점.
- **톤**: "용병단의 깃대를 누구보다 빛나게 한 그분께만 부탁드릴 일이 있습니다. 다른 분과 함께 가지 마시고, 혼자서 가주십시오."
- **isDispatched 처리**: 간판 용병이 파견 중이면 잠금. flagship hook 솔로 의뢰는 M6 §7.1 정합으로 자연 처리.
- **위험**: hunt 4난이도 + 솔로 + T3~T4. 사망 저항 cap 0.95라도 critical fail 시 위험. 의뢰인의 부탁에 응할 가치가 있는지 플레이어의 판단을 요구.

##### #4 한 쌍의 그림자 (페어, achievement_count hook)
- **컨셉**: 두 명의 용병이 함께 가야 하는 raid 의뢰. T2~T3. "한 쌍"으로 다닐 때 빛나는 두 정찰병 톤.
- **톤**: "두 명이 같이 가는 게 좋겠습니다. 한쪽이 다른 한쪽의 등을 봐줄 수 있는 그런 일입니다."
- **부합 직업군**: rogue/ranger 페어가 자연. 다만 강제는 아님 (페이즈 4 #2 UI 추천 힌트로 표시).
- **`pair_completion_count`** 카운터 누적 → 8회 도달 시 `title_silver_pair` 발급.

##### #5 삼인행 (소수정예 삼인행, achievement_count hook)
- **컨셉**: 위업 10개 이상을 남긴 용병단에 들어오는 정확히 3인 explore 의뢰. T3~T4.
- **톤**: "세 사람이 함께 걷는 길이 있습니다. 옛 전우들이 다시 모인다는 의미일 수도, 새 인연이 맺어진다는 의미일 수도 있습니다."
- **부트스트랩 구조**: `achievement_count=10`으로 첫 삼인행 의뢰가 노출된다. 이후 `small_party_count` 10회 도달 시 `title_three_kings`가 발급되고, 해당 칭호의 3인 이상 성공률 보너스가 후속 삼인행 의뢰에 작동한다.

### 3.7 보상 정책

#### 3.7.1 보너스 배수

지명 의뢰 §6.1 패턴을 따르되 솔로/소수정예는 큰 폭 상향:

| 항목 | M6 지명 의뢰 | M8.5 솔로 | M8.5 소수정예 |
|------|------------|---------|--------------|
| 골드 보너스 | 기본 × 1.30~1.50 | **× 1.8~2.2** | × 1.4~1.6 |
| 명성 보너스 | 기본 × 1.30~1.50 | **× 1.7~2.0** | × 1.3~1.5 |
| XP 분배 | 일반 동일 | **일반 동일** (인건비 절감으로 시간당 효율 자연 상승) | 일반 동일 |

페이즈 2 #2에서 시뮬레이션 검증. 시간당 골드 효율 + 사망 리스크의 트레이드오프 정합.

#### 3.7.2 보상 배수 적용 순서 (M6 정합)

1. 기본 보상 = `questType.baseReward × difficulty`
2. 결과 배수 (대성공 ×2)
3. **지명 배수 × (1.4~2.2)** — M8.5 솔로/소수정예 의뢰는 `special_flags.named_reward_multiplier`에 최종 배수를 직접 저장한다.
4. 칭호 효과 (PassiveBonusService — `title_lone_wolf` `QuestRewardMultiplier` 등)
5. 세력 효과 / 랭크 효과
6. 최종 골드 결정

**중요**: 본 문서 솔로/소수정예 의뢰도 `is_named = true`다. 따라서 "M6 지명 배수 + M8.5 솔로 배수"처럼 2개 배수를 따로 곱하지 않는다. 기존 `QuestCompletionService`의 named multiplier 경로를 그대로 쓰고, 각 M8.5 quest_pool 행에 높은 최종 배수를 저장한다.

`DispatchDetailScreen`의 보상·순수익 미리보기에도 동일 배수를 반영해야 한다. 미리보기와 실제 완료 보상이 다르면 고위험 솔로 의뢰의 가치가 화면에서 낮게 보인다.

#### 3.7.3 아이템 드랍 — M8a 카탈로그 재활용

솔로 의뢰 성공 시 (대성공도 포함):
- **보장 드랍**: M8a 4 아이템 중 1종 (등급에 따라 차등)
  - 솔로 #1 (T1~T2): `equip_accessory_red_spear_wristwrap` (붉은 창의 손목끈)
  - 솔로 #2 (T2~T3): `guild_artifact_trade_seal` (상단 보증서)
  - 솔로 #3 (T3~T4): `guild_artifact_merchant_warrant` (상인 위임장)
- **확률 드랍**: 신규 1~2 아티팩트 (페이즈 3 #4에서 SQL 추가)
  - 신규 아이템 후보: `guild_artifact_lone_wolf_compass` (외로운 늑대의 나침반, 솔로 의뢰 보상 배수 +0.05)
  - 신규 아이템 후보: `guild_artifact_three_kings_seal` (삼인행의 인장, 소수정예 의뢰 성공률 +0.03)

소수정예 의뢰 성공 시:
- 보장 드랍: M8a 상점/보상 후보 아이템 중 1종 (시드에서 결정, 페이즈 3 #4)
- 확률 드랍: 없음 (소수정예는 솔로보다 인원 분배 보상이 자연 상승)

중복 정책:
- M8a 전용 보상 아이템을 이미 보유했거나 이미 세력 보상으로 지급받은 경우, 동일 아이템을 추가 지급하지 않고 대체 골드 또는 재료 묶음으로 변환한다.
- 신규 M8.5 아티팩트 2종은 일반 아이템처럼 중복 보유 가능 여부를 페이즈 3 #4 시드에서 결정한다.

신규 아이템 효과 수치는 페이즈 2 #2 + 페이즈 3 #4에서 결정. M9 본격 장비 시스템에서 효과 정교화 위임.

### 3.8 ActiveQuest 모델 확장 (검토)

#### 3.8.1 신규 필드 후보

| 필드 | HiveField | 용도 | 도입 결정 |
|------|----------|------|----------|
| `partySize: int?` | 다음 가용 | 의뢰 발급 시점 인원 동결 | ❌ 미도입 — `pool.partySizeMin/Max`로 lookup |
| `partyEquipmentBonusesSnapshot: Map<String, EquipmentStatBonus>?` | 다음 가용 | M8b 시뮬레이션 입력 동결 | ❌ 미도입 — 호출 시점에 수집 |
| `soloDeathResistanceCap: double?` | 다음 가용 | M8b 사망 저항 cap 동결 | ❌ 미도입 — `pool.partySizeMax == 1`로 분기 |

본 문서는 ActiveQuest 신규 HiveField 추가하지 않음. `quest_pools` 컬럼 lookup으로 모두 처리 가능. M6 `namedTargetMercId` HiveField 26은 그대로 활용 (flagship hook 의뢰는 M6 패턴 그대로).

---

## 4. 현재 시스템과의 연관

### 4.1 영향받는 시스템

| 시스템 | 영향 내용 | 마이그레이션 |
|--------|----------|-------------|
| Supabase `quest_pools` 테이블 | 2 컬럼 추가 (`party_size_min` INT DEFAULT 1 / `party_size_max` INT NULL) + CHECK 1종 + 5행 INSERT | 페이즈 3 #4 |
| Supabase `titles` 테이블 | 4행 INSERT (title_lone_wolf / title_silver_pair / title_three_kings / title_unyielding_solo) | 페이즈 3 #4 |
| Supabase `items` 테이블 | 신규 2 아이템 INSERT (guild_artifact_lone_wolf_compass / guild_artifact_three_kings_seal) | 페이즈 3 #4 |
| `QuestPool` Freezed 모델 | 2 필드 추가 (`partySizeMin`/`partySizeMax`) | 페이즈 4 #2 |
| `QuestGenerator.generateQuests()` | partySize 기반 named 가중치 분기 추가 (`partySizeMax` 또는 `special_flags.named_weight_alpha`) | 페이즈 4 #2 |
| `QuestSortService` | NamedTier 내부 추가 정렬 (솔로 우선 → 소수정예 → 일반 named) | 페이즈 4 #2 |
| `QuestCompletionService` | partySize 방어 검증 + 4 카운터 증가 trailing + 솔로/소수정예 보상 드랍 처리 | 페이즈 4 #2 |
| `CombatSimulator.simulate` | `deathResistanceCaps: Map<String, double>` 인자 추가 + §FR-11.5 cap 분기 | 페이즈 4 #2 (M8b 본체 수정) |
| 의뢰 카드 UI (`QuestCardBadges`/`LayerSidebar`) | 솔로 ⭐·페어 ⭐⭐·삼인행 ⭐⭐⭐ 배지 신규. 색상은 `AppTheme.namedAccent` 공유 | 페이즈 4 #2 |
| `DispatchDetailScreen` | 파티 선택 시 partySize 강제 (1명 강제 / 2명 강제 / 3명 강제) + 안내 토스트 | 페이즈 4 #2 |
| `DispatchDetailScreen` 보상 미리보기 | named reward multiplier·칭호 효과 반영 순수익 preview 보정 | 페이즈 4 #2 |
| `TitleService.evaluateActionStatHook` | 신규 4 카운터 임계값 평가 추가 | 페이즈 4 #2 |
| `Mercenary.stats` Map | 신규 4 카운터 키 도입 (모델 변경 없음, Map 값 추가만) | 마이그레이션 불요 |
| operation-bom | `quest_pools` 편집 폼에 `party_size_min`/`party_size_max` 2 컬럼 추가 + `titles` 편집 폼에 4행 추가 | 별도 작업 |

### 4.2 호환성 검토

- **기존 `quest_pools` 데이터**: `party_size_min = 1`, `party_size_max = NULL` default로 모든 기존 행 자동 호환. 솔로/소수정예 의뢰는 명시적 NOT NULL 값.
- **기존 로컬 JSON 캐시**: 모델 기본값으로 `partySizeMin=1`, `partySizeMax=null`을 보장해야 한다. DB default만으로는 오래된 캐시 역직렬화 호환을 보장하지 못한다.
- **기존 ActiveQuest 세이브**: 신규 HiveField 없음 → 100% 호환.
- **기존 `titles` 데이터**: 4행 추가만, 기존 11행 영향 없음.
- **M8b CombatSimulator**: `deathResistanceCaps` 인자가 NULL이면 기존 cap [0.20, 0.80] + 체인 주인공 0.90 그대로 동작. M6 호환성 100%.
- **기존 named 의뢰**: `party_size_max IS NULL`로 자동 분류되어 NamedTier 내부 정렬에서 "일반 named" 그룹에 위치. M6 일반 지명과 M8a 세력 지명 모두 동작 영향 없음.

### 4.3 호환성 리스크

- **낮음**: `party_size_min`/`max` CHECK 위반 시 INSERT 실패 → 시드 작성 시 검증 필요.
- **중간**: `deathResistanceCaps` 인자 추가는 M8b 본체 시그니처 변경. 페이즈 4 #2에서 M8b spec과 정합 검증. 기존 호출 측 `partyEquipmentBonuses = const {}` 패턴 그대로 default 값.
- **낮음**: `title_three_kings` 부트스트랩은 #5 hook을 `achievement_count=10`으로 바꿔 해소한다. 첫 삼인행 의뢰는 위업 누적으로 열리고, 칭호는 후속 보너스 역할을 한다.
- **중간**: 솔로 의뢰의 1인 파티는 M8b 시뮬레이션에서 `actionScore` 정렬·결정적 장면 기여자 집계가 모두 1명에 집중. `protagonistMercId == featuredMercIds[0]` 같은 동일 ID 케이스 발생 가능. M8a `CombatReport.featuredMercIds`에서 protagonist 제외 정책과 충돌 가능 → 페이즈 4 #2에서 정합 검증.
- **중간**: difficulty 3~4 솔로 의뢰는 1인 `partyPower` 구조상 성공률이 5% 하한에 붙을 수 있다. 페이즈 2 #2에서 enemyPower 보정, solo 전용 성공률 보정, enemy group 축소 중 하나를 반드시 선택한다.

---

## 5. 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| `quest_pools` 2 컬럼 추가 (`party_size_min`/`max`) + CHECK + 5행 INSERT | **높음** | 페이즈 4 #2 명세 입력. 데이터 모델 토대 |
| `titles` 4행 INSERT | **높음** | 칭호 hook 평가 입력 |
| `QuestGenerator` partySize 기반 가중치 분기 추가 | **높음** | 솔로/소수정예 희소성 제어 |
| `DispatchDetailScreen` 파티 선택 UI 강제 | **높음** | UX 정합 (사용자가 4명 선택 시도하면 즉시 차단 필요) |
| `DispatchDetailScreen` 보상 미리보기 보정 | **높음** | 실제 보상과 화면 기대값 정합 |
| `QuestCompletionService` 카운터 증가 + 칭호 hook 평가 | **높음** | 4 신규 칭호 발급 |
| `CombatSimulator.simulate` `deathResistanceCaps` 인자 추가 | **높음** | 솔로 0.95 / 소수 0.90 cap 적용 |
| 의뢰 카드 차별화 UI (솔로 ⭐ 등 배지) | **중간** | 시각 단서 |
| 신규 2 아이템 추가 + 보상 드랍 trailing | **중간** | 솔로 의뢰 보상 차별화 |
| `QuestSortService` NamedTier 내부 추가 정렬 | **중간** | UI 노출 순서 (페어/삼인행 사이 정합) |
| `TitleService.evaluateActionStatHook` 4 카운터 임계 평가 | **중간** | M6 칭호 hook 패턴 100% 재사용으로 단순 |
| operation-bom 편집 폼 확장 | **낮음** | 관리 도구. 본 마일스톤 외 작업 |

---

## 6. data-generator 지시사항

본 문서의 5행 quest_pools + 4행 titles + 2행 items는 신규 타입 스펙 작성 부담 대비 데이터량이 적어 페이즈 3 #4 또는 페이즈 4 #2 명세 인라인 SQL 처리를 권장한다.

- **대상 타입**: 별도 타입 스펙 불요 (M6 named-quest 패턴과 동일)
- **대상 테이블**: `quest_pools` (5행) + `titles` (4행) + `items` (2행)
- **생성 수량**:
  - quest_pools: 5행 (§3.6.1 표 그대로 고정)
  - titles: 4행 (§3.5.2 표 그대로 고정)
  - items: 2행 (§3.7.3 신규 아이템 후보)
- **톤/세계관 가이드**:
  - 한국어 판타지 톤. 각 의뢰는 "용병 한 명(혹은 두세 명)에게만 부탁하는 의뢰인" 톤
  - description 1~2문장. 의뢰인의 1인칭 톤 권장
  - §3.6.2 톤 가이드 그대로 사용
  - 칭호 description 1~2문장. "이 용병이 어떤 사건의 주인공이었나" 기록 톤
  - 고유명사 저작권 금칙
- **구조적 제약**:
  - is_named = true (5행 전체)
  - named_hook_type 분포: title(1) / achievement_count(3) / flagship(1)
  - party_size 분포: 1/1(3) / 2/2(1) / 3/3(1)
  - quest_type 분포: escort(1) / raid(2) / hunt(1) / explore(1)
  - difficulty 분포: 2(1) / 3(2) / 4(2)
  - titles 4행 hook_type 분포: action_stat(4)
- **수치 출처**: 페이즈 2 #2에서 보상 배수·칭호 효과 수치 검증
- **특수 요구**:
  - #3 `flagship` hook 솔로 의뢰는 `UserData.flagshipMercId` non-null일 때만 노출 (M6 정책 그대로)
  - #5 `삼인행` 의뢰는 `achievement_count=10` 조건으로 첫 노출 경로를 보장한다.
  - 칭호 #4 `title_unyielding_solo`는 hook_type=action_stat, `stat_key=solo_great_success_count`, `threshold=1`
- **검증**:
  - party_size CHECK 위반 행 없음
  - 의뢰 5행이 `is_named=true` + `party_size_max IS NOT NULL` 모두 충족
  - 칭호 4행이 현재 코드의 PassiveEffect sealed type만 사용
  - #5 삼인행 의뢰가 `title_three_kings` 없이도 발급 가능

---

## 7. 오픈 질문

- **Q-1 (보상 배수 정확 수치)**: §3.7.1 솔로 ×1.8~2.2 / 명성 ×1.7~2.0 / 소수 ×1.4~1.6 / ×1.3~1.5. **권장**: 페이즈 2 #2 위임. 시뮬레이션으로 시간당 골드 효율 검증.
- **Q-2 (가중치 α 수치)**: §3.4.3 솔로 +2 / 소수 +2. 신규 유저 5~10시간 누적 시 솔로 의뢰 1~2회 자연 노출 검증. **권장**: 페이즈 2 #2 위임.
- **Q-3 (`title_unyielding_solo` hook 정밀화)**: **결정**. achievement hook 대신 action_stat `solo_great_success_count >= 1` 카운터를 사용한다. 신규 위업 템플릿을 만들지 않는다.
- **Q-4 (`CombatSimulator.simulate` 인자 변경 vs 옵션)**: §3.3.2 옵션 A (인자 추가). M8b 본체 시그니처 변경 부담은 있으나 순수 함수 원칙에 부합. **권장**: 페이즈 4 #2에서 M8b spec과 정합 검증.
- **Q-5 (솔로 의뢰 도중 의뢰 취소 정책)**: 사용자가 일반 의뢰처럼 솔로 의뢰를 취소할 수 있는가? "1인 의뢰 취소 시 사기 손실" 패널티? **권장**: M6와 동일. 의뢰 취소 자체는 가능, 패널티 없음 (일반 의뢰 정합).
- **Q-6 (페어 의뢰의 직업군 추천)**: §3.6.2 #4 페어 의뢰는 rogue/ranger 페어가 자연. 의뢰 카드 추천 직업군 chip 표시 검토. **권장**: 페이즈 4 #2 결정. UI 추천 힌트는 부가 옵션.
- **Q-7 (소수정예 의뢰 한 명만 사망 시 카운터 처리)**: 페어 의뢰 중 1명만 사망하면 살아남은 1명의 `pair_completion_count` 증가하는가? **결정**: 증가하지 않음 (§3.3.3 명시). 사망 시 의뢰 자체가 실패 처리되며 카운터 미증가.
- **Q-8 (M8.5 #5 "전투 기억" 시스템과의 연계)**: 본 문서 솔로 의뢰가 페이즈 1 #5 "용병 전투 기억"의 핵심 입력. 솔로 의뢰 완수 1건마다 전투 기억 1엔트리 생성? **권장**: 페이즈 1 #5 작성 시점에 결합 정밀화.

---

## 8. 후속 작업

### 페이즈 1 후속 산출물 입력

본 문서는 다음 페이즈 1 산출물의 입력:
- **페이즈 1 #5 "용병 전투 기억"** — 본 문서 §3.6 솔로 의뢰 완수 + §3.5 카운터가 전투 기억 엔트리의 원천 사건

### 페이즈 2 입력

- **페이즈 2 #2 "간판 용병 의뢰 보상·난이도 수치"** — 본 문서 §3.7 보상 배수 1.8~2.2 / §3.5.2 칭호 효과 / §3.4.3 가중치 α=2 / 쿨다운 48h / 36h를 시뮬레이션 검증
- **페이즈 2 #3 "감정 반응 상태 발동 확률·지속·수치"** — 솔로 의뢰의 1인 파티 위기 상황이 감정 반응 hook으로 자연 입력 (페이즈 1 #3과 결합)

### 페이즈 3 #4 입력

- **페이즈 3 #4 "간판 용병 솔로/소수정예 의뢰 풀 시드"** — 본 문서 §3.6.1 표 + §3.5.2 칭호 4종 + §3.7.3 신규 2 아이템을 SQL 시드로 변환

### 페이즈 4 #2 명세 입력

본 문서 + 페이즈 2 #2 결과 + 페이즈 3 #4 시드를 입력으로 spec-writer 호출:
- `quest_pools` 2 컬럼 마이그레이션 + 5행 INSERT
- `QuestPool` 모델 기본값 추가 + build_runner 재생성
- `titles` 4행 INSERT
- `items` 2행 INSERT
- `QuestGenerator` partySize 분기
- `QuestCompletionService` 카운터 증가 + 칭호 hook
- `CombatSimulator.simulate` `deathResistanceCaps` 인자 추가
- `DispatchDetailScreen` 파티 선택 강제 UI
- `DispatchDetailScreen` 보상·순수익 preview 보정
- 의뢰 카드 차별화 UI (솔로 ⭐·페어 ⭐⭐·삼인행 ⭐⭐⭐ 배지)
- M6 `namedTargetMercId` 동결 패턴 그대로 활용

### 밸런스 검토 필요

**예**. 페이즈 2 #2에서 통합 검토.

### 벌크 데이터 생성 필요

**아니오** (소량 5+4+2=11행, 페이즈 3 #4 또는 페이즈 4 #2 인라인 권장).

### 구현 명세서 생성

페이즈 4 #2에서:
- 호출: `/spec-writer @Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md` (페이즈 2 #2 결과 + 페이즈 3 #4 시드 모두 입력)
