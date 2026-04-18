# 명성 등급별 보너스 컨텐츠 기획서

> 작성일: 2026-04-17
> 유형: 신규 컨텐츠 (M1 마일스톤)
> 선행: `Docs/content-design/[content]20260417_faction_passive_mapping.md` (효과 타입 체계 재사용)
> 후속: 페이즈 2 `/balance-designer`로 수치 확정 → 페이즈 4 `/spec-writer`

---

## 개요

현재 명성 등급(F~A)은 **상위 티어 리전 잠금 해제** 외 기능이 없어 랭크업 순간의 동기 부여가 약하다. 본 기획은 각 등급에 **누적되는 보너스 세트**를 부여하여, 랭크업이 가시적 성장 이벤트가 되도록 한다. 효과 타입 체계는 세력 패시브 매핑 기획과 동일한 엔진을 공유하되, 명성 전용 효과 타입 `dispatch_slot_bonus`를 추가한다.

**핵심 설계:**
- F~A 6등급, 누적 방식 (상위 등급 = 하위 보너스 전부 유지 + 신규 추가)
- 세력 패시브와 **동일 JSON 스키마** 재사용 (`PassiveBonusService` 통합 처리)
- 명성 전용 효과 타입 `dispatch_slot_bonus` 1개 신규
- 성공률 상한(+20%p)을 세력 패시브와 **공유** (두 소스 합산 후 체크)
- 랭크업 축하 오버레이 + 홈 화면 현재 보너스 섹션

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| OGame — Research Level Cumulative | 연구 레벨이 올라갈수록 보너스가 누적되어 영구 유지 | 랭크 누적 보너스 = 이전 등급 효과 영구 유지 |
| Melvor Idle — Mastery Level Rewards | 숙련도 단계마다 고유 보상 해금 | 각 등급마다 고유 효과 테마 할당 |
| Darkest Dungeon — Hero Resolve Tier | 영웅 등급 상승 시 스탯/능력 추가 | 랭크업을 플레이어 조직 성장 이벤트로 시각화 |
| Battle Brothers — Company Renown | 평판 티어별 의뢰 품질·계약금 배율이 올라감 | 등급별 전역 퀘스트 보상/성공률 보너스 |

---

## 상세 설계

### 1. 등급 체계 (F → A, 6단계)

| 등급 | 이름 | 테마 | 테마 설명 |
|------|------|------|----------|
| **F** | 무명 | 신참 | 활성화된 보너스 없음. 기본 상태 |
| **E** | 등록된 용병단 | 입문자 | 용병단 운영의 초기 이점 (모집 비용 절감) |
| **D** | 인정된 용병단 | 인정받음 | 의뢰 보상 개선 + 부상 회복 시간 단축 |
| **C** | 숙련된 용병단 | 숙련 | 성공률 기본 보정 + 조직 규모 확장 (파견 슬롯 +1) |
| **B** | 유명한 용병단 | 유명세 | 보상·방치·트레잇 복합 강화 |
| **A** | 전설의 용병단 | 전설 | 최상위 복합 보너스 + 추가 파견 슬롯 |

**등급 이름**은 기존 `ranks.name` 필드에 입력. 기존 데이터와 이름이 다르면 operation-bom에서 업데이트.

**required_reputation / unlock_tier**는 기존 값 유지 (balance-designer가 필요 시 재조정).

---

### 2. 효과 타입 체계 (세력 패시브와 공유)

세력 패시브 매핑 기획에서 정의한 **14개 효과 타입을 그대로 재사용**한다. 단일 효과 타입 카탈로그를 유지하여 `PassiveBonusService`가 세력·명성을 통합 처리.

#### 신규 효과 타입 (1개 추가)

| # | 효과 타입 | 파라미터 | 설명 | 적용 서비스 |
|---|----------|---------|------|-----------|
| 15 | `dispatch_slot_bonus` | `value` (int) | 동시 진행 가능한 파견 퀘스트 수 가산 | 파견 액션 진입 시 슬롯 체크 |

**`dispatch_slot_bonus` 정의:**
- `value`는 **정수** (비율 아님). 타 효과 타입의 float 규약과 다르므로 주의
- 기본 동시 파견 수(1개 + 정보망 시설 보너스)에 가산 합산
- 정보망 시설 `max_parallel_quest` 효과와 **가산**으로 중첩 (예: 정보망 Lv20 효과 +3 + 명성 C +1 + A +1 = 최대 +5)
- 동시 진행 가능 수 상한은 별도 미도입 (M1 범위 — 밸런스 페이즈 2에서 재검토)

**세력 패시브는 `dispatch_slot_bonus`를 사용하지 않음.** 명성 전용 효과 타입 (의도적 차별화). 세력이 파견 용량을 늘리는 것은 개념적으로 어색함 (조직 규모는 플레이어 실적이 결정).

#### JSON 스키마 (세력 패시브와 동일)

```json
{
  "effects": [
    {"type": "quest_reward_multiplier", "quest_type": "all", "value": 0.05},
    {"type": "recovery_time_reduction", "status": "injured", "value": 0.10}
  ]
}
```

- 빈 배열 허용 (F등급의 경우 `{"effects": []}`)
- `type`, `value` 필수. 타입별 추가 파라미터는 세력 패시브 매핑 기획 참조

---

### 3. 등급별 보너스 매핑

각 등급 도달 시 **추가로 활성화**되는 효과. 누적이므로 A등급 = F+E+D+C+B+A 모든 보너스의 합.

#### F — 무명

```json
{"effects": []}
```

보너스 없음. 게임 시작 상태.

#### E — 등록된 용병단 (모집 최적화)

```json
{
  "effects": [
    {"type": "recruitment_cost_reduction", "value": 0.10}
  ]
}
```

**신규 효과 타입?** → 세력 패시브 매핑의 14개 타입에 **`recruitment_cost_reduction`은 없음**. 추가 필요:

| # | 효과 타입 | 파라미터 | 설명 | 적용 서비스 |
|---|----------|---------|------|-----------|
| 16 | `recruitment_cost_reduction` | `value` (float) | 유료 모집 비용 비율 감소 | `RecruitmentService` 비용 계산 시 |

> 세력 패시브에서 이 타입이 나올 수 있으므로 카탈로그에 정식 포함. 페이즈 4 명세에서 패시브 매핑 기획과 본 기획에 모두 반영.

#### D — 인정된 용병단 (의뢰 개선 + 회복 단축)

```json
{
  "effects": [
    {"type": "quest_reward_multiplier", "quest_type": "all", "value": 0.05},
    {"type": "recovery_time_reduction", "status": "injured", "value": 0.10}
  ]
}
```

#### C — 숙련된 용병단 (성공률 + 조직 확장)

```json
{
  "effects": [
    {"type": "quest_success_rate_bonus", "quest_type": "all", "value": 0.03},
    {"type": "dispatch_slot_bonus", "value": 1}
  ]
}
```

#### B — 유명한 용병단 (복합 강화)

```json
{
  "effects": [
    {"type": "quest_reward_multiplier", "quest_type": "all", "value": 0.10},
    {"type": "idle_reward_bonus", "bonus_type": "rate", "value": 0.15},
    {"type": "trait_acquisition_condition_relief", "value": 0.10}
  ]
}
```

#### A — 전설의 용병단 (최상위 복합)

```json
{
  "effects": [
    {"type": "quest_success_rate_bonus", "quest_type": "all", "value": 0.05},
    {"type": "facility_cost_reduction", "cost_type": "time", "value": 0.10},
    {"type": "mercenary_xp_bonus", "value": 0.15},
    {"type": "dispatch_slot_bonus", "value": 1}
  ]
}
```

---

### 4. 누적 동작 규칙

**적용 원칙:**
- `PassiveBonusService`가 현재 플레이어 랭크를 조회 → F부터 현재 랭크까지의 `bonus_json.effects`를 순회 수집
- 세력 효과와 함께 단일 리스트로 스태킹

**스태킹:**
- 동일 `type` + `파라미터` 조합은 `value` 단순 합산 (세력 패시브 매핑 기획 규칙 계승)
- 등급 간 중복 효과가 없도록 설계 (위 매핑 검증: D의 `quest_reward_multiplier all 0.05` + B의 `quest_reward_multiplier all 0.10` → 합산 +15%)
- `dispatch_slot_bonus`는 가산 (C +1, A +1 → 총 +2)

**세력 패시브와 합산 예시 (A등급 + 모험가 길드 가입):**

```
quest_reward_multiplier explore:
  - 명성 D (+5% all) + 명성 B (+10% all) = +15%
  - 모험가 길드 explore (+15%) = +15% (quest_type=explore 전용)
  - 합산(explore 퀘스트에 대해): +30%

quest_success_rate_bonus all:
  - 명성 C (+3) + 명성 A (+5) = +8%
  - 세력 패시브 성공률 보너스 (예: 0%) = +0
  - 합산 +8% (상한 +20%p 내)
```

**성공률 상한 +20%p 공유:**
- 세력 패시브와 명성 둘 다의 `quest_success_rate_bonus` + `quest_success_rate_bonus_party_size`의 **누적 합산**이 +20%p 초과 불가
- `PassiveBonusService` 내부에서 합산 후 min(20.0, total) 적용
- 트레잇 시너지(`quest_type_synergy`)는 별도 레이어로 계산 (본 기획 범위 외)

---

### 5. 랭크 하향 시 처리

플레이어 평판은 일반적으로 오르기만 하지만, **세력 적대 페널티**나 이벤트로 **평판 감소**가 발생할 수 있다 (M2a 이후 시스템 확장 시).

**원칙:**
- 평판이 하위 등급 임계치 미만으로 내려가면 **즉시 해당 상위 등급 보너스 해제**
- 이후 다시 평판 회복하면 **자동 재적용**
- 최초 랭크업 시 활동 로그 기록 후에도, 하향·재상향 시 추가 로그 생성

M1 범위에선 평판 감소 메커니즘이 확정되지 않았으므로 **로직만 준비**. balance-designer가 평판 하락 조건을 별도 정의할 때까지는 상향 방향 처리만 중요.

---

### 6. UI 힌트

#### A. 랭크업 축하 오버레이

평판 획득으로 상위 등급 임계치 도달 → **전체 화면 모달**:

```
┌───────────────────────────────┐
│  🎖️                           │
│  명성 상승!                    │
│                               │
│  E → D                        │
│  인정된 용병단                 │
│                               │
│  신규 보너스                   │
│  • 전 퀘스트 보상 +5%          │
│  • 부상 회복 시간 -10%         │
│                               │
│       [확인]                   │
└───────────────────────────────┘
```

- `ActivityLog`에도 랭크업 이벤트 저장 (기존 활동 로그 인프라 활용)
- 모달은 `showDialog` 또는 상태 기반 오버레이 (Navigator.push 대신)

#### B. 홈 화면 프로필 배지

홈 화면 상단 플레이어 정보 영역:

```
[골드: 1,200] [위치: 평야 3구역]  [명성: D | 인정된 용병단]
                                    ↑ 탭하면 보너스 요약 팝업
```

탭 시 하단 시트로 현재 활성 보너스 목록:

```
명성 D — 인정된 용병단
  • 전 퀘스트 보상 +5%
  • 부상 회복 시간 -10%

다음 등급까지: 명성 348 / 500
```

#### C. 정보 탭 "명성" 섹션

정보 탭(`InfoScreen`) 내 "세력 도감"과 나란히 "명성" 진입점 추가.

**명성 화면 구조:**
- 상단: 현재 랭크 배지 + 평판 수치 + 다음 랭크 프로그레스 바
- 중단: F~A 등급 타임라인 (도달한 등급 강조, 미도달 등급 회색)
- 하단: 각 등급 탭 시 해당 등급의 보너스 목록 표시 (미도달 등급도 프리뷰 가능)

#### D. 파견 화면 성공률 분해에 포함

파견 화면의 성공률 툴팁에 **명성 보너스** 항목을 별도 표시:

```
성공률 72%
  기본값         50%
  파티력 비율   +22%
  ...
  명성 보너스    +8%  (C +3, A +5)
  ...
```

파견 상성 기획서의 분해 UI와 동일 포맷 유지.

---

### 7. `ranks` 테이블 스키마 확장

| 컬럼 | 타입 | 기본값 | 설명 |
|------|------|-------|------|
| `bonus_json` | JSONB | `{"effects": []}` | 등급 보너스 정의. 세력 `passive_bonus_json`과 동일 스키마 |

**마이그레이션:**
- 기존 6개 row(F~A)에 각 섹션 3의 JSON 값 입력
- operation-bom의 `table-config.ts`에 `ranks` 테이블 편집 UI 추가 (세력 패시브 편집 UI와 공통 위젯 공유 권장)

**`Rank` Freezed 모델**에 `bonusJson` 필드 추가(`@JsonKey(name: 'bonus_json')`).

---

### 8. 효과 타입 카탈로그 업데이트

세력 패시브 매핑 기획의 14개에 본 기획에서 2개 추가:

| 구분 | 개수 | 타입 |
|------|------|------|
| 범용 타입 (패시브 매핑 기준) | 8 | quest_reward_multiplier, quest_success_rate_bonus, recovery_time_reduction, recruitment_tier_boost, facility_cost_reduction, facility_effect_bonus, idle_reward_bonus, travel_event_mitigation |
| 특수 타입 (패시브 매핑 기준) | 5 | investigation_success_rate_bonus, trait_acquisition_condition_relief, trait_evolution_condition_relief, mercenary_xp_bonus, trait_unlock_category |
| 조건부 타입 (패시브 매핑 기준) | 1 | quest_success_rate_bonus_party_size |
| **명성 전용 타입 (본 기획)** | **1** | `dispatch_slot_bonus` |
| **공통 타입 (본 기획에서 추가)** | **1** | `recruitment_cost_reduction` |
| **합계** | **16** | |

**`recruitment_cost_reduction` 재사용 가능성**: 세력 패시브 매핑 기획 수정 필요 없음 (카탈로그에만 추가). 향후 세력 중 모집 할인 패시브를 가진 세력이 추가되면 이 타입을 참조.

---

## 현재 시스템과의 연관

| 영역 | 영향 | 처리 방식 |
|------|------|----------|
| `ranks` 테이블 | `bonus_json` 컬럼 추가, 6개 row 데이터 업데이트 | M1 마이그레이션 |
| `Rank` Freezed 모델 | `bonusJson` 필드 추가 | @JsonKey(name: 'bonus_json') |
| `ReputationService` (확장) | 현재 랭크 조회 외에 누적 보너스 반환 | `getCumulativeBonuses()` 메서드 추가 |
| `PassiveBonusService` (신규 공통) | 세력 + 명성 통합 스태킹 | 단일 진입점 |
| `QuestGenerator` / 파견 로직 | `dispatch_slot_bonus` 반영 | 동시 진행 상한 계산 시 조회 |
| 홈 화면 프로필 | 랭크 배지 + 보너스 요약 팝업 | 기존 골드/위치 영역 확장 |
| 정보 탭 | "명성" 진입점 추가 | `InfoScreen`에 섹션 추가 |
| 파견 화면 성공률 툴팁 | 명성 보너스 항목 추가 | 상성 기획서 UI와 공통 |
| `ActivityLog` | 랭크업 이벤트 추가 | 기존 로그 타입 확장 |
| operation-bom | 랭크 편집 UI 추가 | 세력 패시브 편집 UI 재사용 |

---

## 구현 우선순위 제안

### 높음 — 핵심 데이터/로직

| 작업 | 내용 |
|------|------|
| `ranks` 스키마 확장 + 6개 row bonus_json 입력 | SQL 또는 operation-bom |
| `Rank` 모델 확장 | bonusJson 필드 |
| `PassiveBonusService` 명성 누적 로직 | `collectRankEffects()` 내부 함수 |
| 효과 타입 카탈로그 확장 (`dispatch_slot_bonus`, `recruitment_cost_reduction`) | 페이즈 4 명세에 반영 |
| 파견 슬롯 로직에 `dispatch_slot_bonus` 조회 반영 | 기존 정보망 시설 로직에 가산 합산 |

### 중간 — 시각적 피드백

| 작업 | 내용 |
|------|------|
| 랭크업 축하 오버레이 | 전체화면 모달 |
| 홈 화면 프로필 배지 + 팝업 | 기존 영역 확장 |
| 정보 탭 "명성" 섹션 | 신규 화면 |

### 낮음 — 통합 UI

| 작업 | 내용 |
|------|------|
| 파견 화면 성공률 툴팁에 명성 보너스 항목 | 상성 기획서 구현과 공통 |
| operation-bom 랭크 편집 UI | 패시브 편집 UI 재사용 |

---

## data-generator 지시사항

> 본 기획안은 **시스템/데이터 설계**이며 벌크 텍스트 생성이 불필요하다. 6개 등급의 `bonus_json` 값은 섹션 3의 표를 operation-bom 또는 SQL로 직접 입력한다.
>
> 섹션 3의 수치는 페이즈 2 `/balance-designer` 검증 후 최종 확정된 값으로 교체한다.

---

## 후속 안내

- 본 기획안은 M1 페이즈 1 산출물 4/4 (페이즈 1 마지막).
- `/balance-designer`로 다음 검증 권장 (페이즈 2에서 진행):
  - 누적 보너스 전체의 경제 영향 (A등급 도달 시 골드 획득률, 성공률 분포)
  - 세력 패시브와의 중첩 시 성공률 상한 +20%p 도달 빈도
  - `dispatch_slot_bonus` 누적 +2가 게임 페이스에 미치는 영향 (파견 회전율 가속)
  - 등급 간 보너스 밸런스 (E→D, C→B 등 전환 체감)
  - `required_reputation` 임계값과 랭크업 체감 간격 검증
- 구현 진행: `/spec-writer @Docs/content-design/[content]20260417_rank_bonuses.md` (페이즈 4)
- milestone-runner 재진입: `/milestone-runner M1 --resume`
