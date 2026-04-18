# 파견 상성 시스템 컨텐츠 기획서

> 작성일: 2026-04-17
> 유형: 신규 컨텐츠 (M1 마일스톤)
> 선행: `Docs/content-design/[content]20260416_faction_system.md`, `CLAUDE.md`의 QuestCalculator 로직
> 후속: 페이즈 2 `/balance-designer`로 수치 확정 → 페이즈 4 `/spec-writer`

---

## 개요

현재 파견은 "스탯 총량이 클수록 유리"한 단일 축 게임이다. 본 기획은 **퀘스트 유형과 용병의 직업군(role)·트레잇 간 상성**을 독립 보정 레이어로 추가하여, "이 퀘스트에는 누구를 보낼 것인가"를 전략적 선택 문제로 승격시킨다.

핵심 설계:
- `jobs` 테이블에 `role` 필드 신규 추가(6개 enum)
- role × 퀘스트 유형 상성 매트릭스는 **Dart 정적 상수**로 관리
- **성공률 +%p 독립 레이어**로 `QuestCalculator`에 합산 (partyPower 로직 불변)
- **트레잇 시너지는 기존 `TraitEffectService` 확장**으로 처리 (신규 서비스 추가 없음)
- 파견 화면에 상성 배지 + 성공률 분해 UI 추가

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Darkest Dungeon — Hero Class 조합 | 4인 파티에서 앞/뒤 열과 직업 조합이 전투 효율을 결정 | 4 role이 각 quest_type에 차등 보너스 → 조합 고민 유도 |
| Battle Brothers — Background trait | 특정 background(사냥꾼·방랑자 등)가 특정 맵/적에 보정 | 트레잇 effect_json의 `quest_type_bonus` 필드 확장 |
| Melvor Idle — Combat Style Triangle | 공격·원거리·마법 삼각 상성이 적 타입에 맞춰 달라짐 | role × quest_type 매트릭스가 같은 원리의 2D 테이블 |
| Final Fantasy Tactics — Job Role | 캐릭터가 속한 job role이 전투 행동 가중치를 부여 | `jobs.role` 필드 → role 기반 상성 매트릭스 조회 |

---

## 상세 설계

### 1. Role 분류 체계 (6개)

#### Role enum

| 키 | 이름 | 설명 | 대표 스탯 |
|----|------|------|----------|
| `warrior` | 전사 | 근접 전투, 정면 돌파 | STR 주 |
| `ranger` | 순찰자 | 원거리 사격, 추적, 정찰 | AGI + STR |
| `mage` | 마법사 | 마법·학문·탐구 | INT 주 |
| `rogue` | 도적 | 은밀·기습·기술 | AGI 주 |
| `support` | 지원 | 치유·호위·버프 | VIT + INT |
| `specialist` | 전문가 | 장인·공예·특수 기능 | 기타 (광부, 상인, 성직자 등) |

**매핑 원칙:**
- 기본 85개 직업 각각에 role을 **명시적으로** 할당 (content-status의 "85개 직업" 가정)
- 티어와 role은 **독립**. 동일 role 내에서도 티어별 기본 스탯이 다름
- role 할당 예시 (가이드라인):
  - T1 검사/도끼수/창병 → warrior
  - T1 궁수/사냥꾼 → ranger
  - T2 마법사/학자/정령술사 → mage
  - T2 도적/암살자/밀정 → rogue
  - T3 사제/치유사/호위기사 → support
  - 광부/대장장이/연금술사 → specialist

**실제 85개 직업별 role 매핑은 페이즈 4(`/spec-writer`)에서 데이터 마이그레이션 스크립트로 확정.** 스탯 분포를 참고하되 기획자 수동 검토 필수 (이름이 주는 서사적 역할 우선).

#### `jobs` 테이블 스키마 확장

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|-------|------|
| `role` | text | 'specialist' | 6개 enum 중 하나 — M1에서 신규 추가 |

`JobData` Freezed 모델에 `role` 필드 추가(`@JsonKey(name: 'role')`).

---

### 2. 상성 매트릭스 (role × quest_type)

성공률에 가산되는 **독립 레이어**. 단위는 **%p** (percentage point).

| role / quest_type | raid (약탈) | hunt (토벌) | escort (호위) | explore (탐험) |
|------------------|:----------:|:----------:|:-----------:|:-------------:|
| **warrior** | +8 | +5 | +3 | -2 |
| **ranger** | +3 | +8 | +2 | +3 |
| **mage** | -2 | +2 | +3 | +8 |
| **rogue** | +5 | +3 | 0 | +5 |
| **support** | 0 | +2 | +8 | +2 |
| **specialist** | +2 | +2 | +2 | +2 |

**값 범위:** -2 ~ +8 (페이즈 2에서 최종 확정)

**설계 의도:**
- **strengths(+8)**: 해당 role의 존재 이유 — 이 역할을 위한 직업군임을 명시
- **weakness(-2)**: 근본적 부적합. 강한 패널티는 아니지만 "다른 role을 써라"라는 신호
- **specialist는 모든 유형에 +2**: 범용 지원형. 특수 직업이라 존재감은 있지만 뾰족한 강점은 없음
- **rogue × escort = 0**: 은밀이 호위의 덕목은 아님 (서사적 자연스러움)

**저장 방식:**

```dart
// QuestCalculator 또는 신규 DispatchSynergyCalculator 내부
static const Map<String, Map<String, double>> _roleSynergyMatrix = {
  'warrior':    {'raid': 8.0, 'hunt': 5.0, 'escort': 3.0, 'explore': -2.0},
  'ranger':     {'raid': 3.0, 'hunt': 8.0, 'escort': 2.0, 'explore': 3.0},
  'mage':       {'raid': -2.0, 'hunt': 2.0, 'escort': 3.0, 'explore': 8.0},
  'rogue':      {'raid': 5.0, 'hunt': 3.0, 'escort': 0.0, 'explore': 5.0},
  'support':    {'raid': 0.0, 'hunt': 2.0, 'escort': 8.0, 'explore': 2.0},
  'specialist': {'raid': 2.0, 'hunt': 2.0, 'escort': 2.0, 'explore': 2.0},
};
```

**편집 정책:** 이 매트릭스는 Dart 상수로 유지. 밸런스 조정은 코드 변경 + 앱 릴리스 경로. 이유:
- 셀 수가 24개로 소규모
- 게임의 근본 규칙이라 런타임 변경 시 전체 밸런스 영향 → 코드 리뷰가 오히려 안전
- operation-bom은 `jobs.role` 편집만 지원 (매트릭스 자체는 미편집)

---

### 3. 보정 적용 공식

기존 공식:
```
rate = 50 + (partyPower/enemyPower - 1) × 50 + traitBonus + questMod - distancePenalty + randomVariance
clamp(5, 95)
```

M1 확장 공식:
```
rate = 50 + (partyPower/enemyPower - 1) × 50
     + traitBonus          ← 기존 TraitEffectService
     + questMod            ← 기존 _questModifiers
     - distancePenalty
     + roleSynergyBonus    ← 신규: 아래 정의
     + factionPassiveBonus ← 신규: 세력 패시브 매핑 기획 산출물
     + randomVariance
clamp(5, 95)
```

#### `roleSynergyBonus` 계산

**파티 평균 기반**:

```
roleSynergyBonus = Σ(각 용병의 role × quest_type 보정값) / 파티 크기
```

**예시:** explore 퀘스트, 파티 3명
- 용병1 (mage): +8
- 용병2 (warrior): -2
- 용병3 (rogue): +5
- roleSynergyBonus = (8 - 2 + 5) / 3 = +3.67%p

**파티 크기에 나누는 이유:**
- 1명만 파견해도 해당 role의 보정이 온전히 적용
- 여러 명 파견해도 평균으로 수렴 → 파티 구성 선택이 의미 있게 남음
- 단순 합산이면 6명 파티가 1명 파티보다 6배 유리해져 왜곡

**반올림:** 계산은 double로, UI 표시는 소수 첫째 자리까지.

---

### 4. 트레잇 시너지 (기존 시스템 확장)

`TraitEffectService.calculateSuccessRateBonus`는 이미 `questTypeId`, `partySize`를 받는다. 기존 `trait_effect_json` 스키마를 **확장**하여 상성 시너지를 트레잇 수준에서 부여할 수 있도록 한다.

#### effect_json 확장 필드

기존 필드에 추가:

```json
{
  "success_rate": {"value": 0.03, "type": "percentage"},
  "quest_type_synergy": [
    {"quest_type": "explore", "bonus": 5.0},
    {"quest_type": "escort", "bonus": -2.0}
  ]
}
```

- `quest_type_synergy`: 배열. 각 요소는 `{quest_type, bonus}`
- `bonus`는 %p 단위. `roleSynergyBonus`와 별도 합산 (스태킹)

#### 대상 트레잇 (예시)

| 트레잇 | 시너지 |
|--------|-------|
| "추적자" (Tracker) | hunt +5, explore +3 |
| "호위 전문가" (Escort Specialist) | escort +6 |
| "그림자 발걸음" (Shadow Step) | raid +4, explore +3 |
| "지식의 탐구자" (Knowledge Seeker) | explore +4 |
| "방어 자세" (Defensive Stance) | escort +4, raid -2 |
| "방랑자의 경험" (Wanderer's Wisdom) | explore +3, hunt +2 |

**실제 트레잇별 시너지 할당은 페이즈 4에서 기존 106개 트레잇 중 10~20개에 선별 적용.** M1 범위에선 **모든 트레잇에 시너지 필드를 부여하지 않는다** — 트레잇 고유성을 유지하면서 점진적으로 추가.

---

### 5. 상성 보너스의 상한

| 보너스 레이어 | M1 상한 | 이유 |
|------------|---------|------|
| `questMod` (기존) | -5 ~ +5 | 기존 유지 |
| `roleSynergyBonus` (신규) | **-5 ~ +10 %p** | 평균 계산이므로 단일 role의 최대 +8에서 약간 여유 |
| `traitBonus`+`quest_type_synergy` (확장) | **-5 ~ +10 %p** | 여러 트레잇 합산 |
| `factionPassiveBonus` (신규, 별도 기획) | **+0 ~ +20 %p** | 세력 패시브 매핑 기획 참조 |
| `distancePenalty` (기존) | 0 ~ +N | 거리 기반 |

**개별 상한을 둔 후, 최종 rate는 5~95% 클램프.** 개별 상한이 낮으면 클램프 빈도가 줄어 보상 체감이 정확해짐.

---

### 6. 파견 화면 UI 힌트

파견 시 플레이어가 상성을 **한눈에** 파악하도록 다음 요소를 추가한다.

#### A. 퀘스트 카드에 추천 role 배지

각 퀘스트 카드의 유형 옆에 **+8 role 아이콘 2개**를 표시 (해당 유형의 상성 매트릭스에서 가장 높은 role들).

예시:
- 약탈 퀘스트 → `⚔️ 전사` (+8) / `🗡️ 도적` (+5) 배지
- 탐험 퀘스트 → `🔮 마법사` (+8) / `🗡️ 도적` (+5) / `🏹 순찰자` (+3) 배지

> 아이콘은 Material Icons 또는 이모지. 컬러는 Material 3 primary 계열.

#### B. 용병 선택 시 상성 하이라이트

파견 상세(`DispatchDetailPage`)의 용병 목록에서, 현재 퀘스트에 **+5 이상인 role의 용병은 카드 배경에 연한 primary tint** 적용.

#### C. 성공률 분해 툴팁

성공률 퍼센트 표시 옆에 `?` 아이콘 탭 → 보너스 분해 툴팁:

```
성공률 72%

기본값         50%
파티력 비율   +22%  (power 185 / enemy 120)
퀘스트 유형    +5%  (탐험 보정)
상성           +4%  (파티 평균)
트레잇         +3%  (지식의 탐구자)
세력 패시브    +8%  (마탑 연합)
거리 패널티   -20%  (8 리전)
───────────────
합계           72%
```

#### D. 용병 상세 오버레이에 퀘스트 유형 친화도 표시

용병 상세 화면에 **"퀘스트 유형별 상성"** 섹션 추가 (기존 트레잇 슬롯 아래):

```
이 용병의 상성 (순찰자)
  약탈 +3 · 토벌 +8 · 호위 +2 · 탐험 +3
  트레잇 시너지: 호위 전문가 (+6 호위)
```

---

### 7. 세력 패시브와의 구분

**패시브와 상성의 개념적 역할 차이:**

| 차원 | 패시브 (세력) | 상성 (퀘스트) |
|------|-------------|-------------|
| 주체 | 가입 세력 | 파견되는 용병 |
| 대상 | 상시 적용 또는 특정 유형/상황 | 해당 퀘스트 1회 |
| 데이터 | `factions.passive_bonus_json` (DB) | `jobs.role` + Dart 매트릭스 |
| 편집성 | operation-bom 편집 가능 | 코드 변경 필요 |
| 스태킹 | 여러 세력 가입 시 가산 | 파티 평균 |
| 상한 | +20%p (성공률 한정) | +10%p |

**두 레이어는 서로 독립**. 공식에서 별도 항목으로 합산되며, 각자 별도 상한을 가짐.

**예시 혼동 방지:**
- 전사 길드 가입 패시브 "raid/hunt 성공률 +5%" (`faction passive`)
- 전사(warrior) role의 raid 보정 +8 (`role synergy`)
- → 전사 길드 가입 상태에서 warrior 2명으로 raid 파견 → **둘 다 적용** (패시브 +5 / 상성 +8 = 합 +13)

---

### 8. 엣지 케이스

- **빈 파티**: `roleSynergyBonus = 0` (현재도 partyPower 0 → 성공률 낮음)
- **role이 null인 직업**: 기본값 `specialist`로 fallback (마이그레이션 안전망)
- **알 수 없는 quest_type**: 보정 0
- **트레잇 effect_json에 `quest_type_synergy` 미지정**: 무시, 0

---

## 현재 시스템과의 연관

| 영역 | 영향 | 처리 방식 |
|------|------|----------|
| `jobs` 테이블 | `role` 컬럼 추가, 85개 직업에 role 할당 | M1 마이그레이션 + 데이터 업데이트 |
| `JobData` Freezed 모델 | `role` 필드 추가 | @JsonKey(name: 'role') |
| `QuestCalculator.calculateSuccessRate` | 파라미터 `List<String> partyRoles` 또는 `List<Mercenary>` 추가 | 시그니처 확장, 기존 호출부 업데이트 |
| `QuestCalculator._roleSynergyMatrix` | 신규 상수 | 정적 Map |
| `TraitEffectService.calculateSuccessRateBonus` | effect_json의 `quest_type_synergy` 필드 파싱 | 기존 함수 내 확장 |
| `DispatchDetailPage` | 성공률 분해 툴팁, role 배지 | UI 위젯 추가 |
| 용병 상세 오버레이 | 상성 섹션 추가 | 기존 용병 상세 확장 |
| `jobs` 정적 데이터 캐시 | 버전 증가 필요 | SyncService 자동 처리 |
| operation-bom | 직업 편집 화면에 role 드롭다운 | 신규 UI |

**`MercenaryTemplate`/`Mercenary` 모델은 변경 없음** — role은 직업에서 파생. 용병 객체는 `job.role`로 접근.

---

## 구현 우선순위 제안

### 높음 — 핵심 로직

| 작업 | 내용 |
|------|------|
| `jobs.role` 컬럼 + 85개 데이터 입력 | operation-bom 또는 SQL 스크립트 |
| `JobData` 모델 확장 | role 필드 |
| `QuestCalculator` 상성 보정 로직 | `_roleSynergyMatrix` + `calculateRoleSynergyBonus()` 신규 메서드 |
| 성공률 계산 공식에 상성 레이어 합산 | `calculateSuccessRate()` + `calculateSuccessRatePreview()` 둘 다 |

### 중간 — UI 힌트

| 작업 | 내용 |
|------|------|
| 퀘스트 카드 추천 role 배지 | 퀘스트 생성 시 상위 2개 role 미리 계산 |
| 용병 카드 상성 하이라이트 | `DispatchDetailPage` 내 조건부 스타일 |
| 성공률 분해 툴팁 | 기존 성공률 표시 위젯 확장 |
| 용병 상세 상성 섹션 | 용병 상세 오버레이 내 추가 |

### 낮음 — 트레잇 시너지

| 작업 | 내용 |
|------|------|
| `trait_effect_json` `quest_type_synergy` 파싱 확장 | `TraitEffectService` 내 |
| 10~20개 트레잇에 시너지 데이터 할당 | operation-bom에서 수동 입력 |

---

## data-generator 지시사항

> 본 기획안은 **시스템/로직 설계**이며 벌크 데이터 생성이 불필요하다.
>
> 단, 다음 데이터 입력 작업이 필요(벌크 텍스트 생성 아님):
> - 85개 직업에 `role` 할당 (operation-bom 또는 SQL 직접 입력). 기획자 판단 필요 — data-generator 자동 생성 비권장
> - 10~20개 트레잇에 `quest_type_synergy` 필드 추가 (기획자 선별)
>
> 이 두 작업은 **페이즈 4(`/spec-writer`) 명세에 포함**되거나 operation-bom 편집 작업으로 처리.

---

## 후속 안내

- 본 기획안은 M1 페이즈 1 산출물 3/4.
- `/balance-designer`로 다음 검증 권장 (페이즈 2에서 진행):
  - role 상성 매트릭스 수치(-2 ~ +8)의 성공률 분포 영향
  - 파티 평균 계산 방식의 실제 효과 (1명 vs 3명 vs 6명 파티 비교)
  - 상성 상한 +10%p의 실효 도달 빈도
  - 세력 패시브 + 상성 동시 적용 시 최종 성공률 이상치
  - 트레잇 시너지 10~20개를 선별할 때 어떤 트레잇이 가장 적합한지
- 구현 진행: `/spec-writer @Docs/content-design/[content]20260417_dispatch_synergy.md` (페이즈 4)
- milestone-runner 재진입: `/milestone-runner M1 --resume`
