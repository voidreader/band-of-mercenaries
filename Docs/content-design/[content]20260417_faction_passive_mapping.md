# 세력 패시브 효과 매핑 컨텐츠 기획서

> 작성일: 2026-04-17
> 최종 수정: 2026-04-17 (페이즈 2 밸런스 리포트 역반영)
> 유형: 신규 컨텐츠 (M1 마일스톤)
> 선행: `Docs/content-design/[content]20260416_faction_system.md` (14개 세력 카탈로그)
> 후속: `/balance-designer`로 수치 확정 → `/spec-writer`로 개발 명세
> 관련 밸런스 리포트: `Docs/balance-design/20260417_faction_passive_values.md` — 본 문서의 스태킹 규칙 및 수치는 해당 리포트의 P1~P4 권고를 반영하여 갱신됨

---

## 개요

14개 세력의 `passive_bonus_json`을 게임 메커니즘에 연결하기 위한 **효과 타입 체계**를 정의한다. 기존 서술형 텍스트("탐험 보상 +15%", "트레잇 진화 조건 완화" 등)를 구조화된 JSON 스키마로 변환하고, 각 효과 타입이 **어느 서비스의 어느 시점에 적용되는지** 매핑한다. 이 기획안이 확정되면 `PassiveBonusService`의 인터페이스 설계와 operation-bom의 편집 스키마가 결정된다.

**핵심 산출물:**
- 범용 효과 타입 8개 + 특수 효과 타입 5개 + 조건부 효과 타입 1개 (총 14개)
- 14개 세력의 `passive_bonus_json` 구체 값
- 스태킹 규칙(효과 타입별 가산/곱셈 구분) 및 성공률 상한(+20%)
- 서비스별 적용 지점 매핑표

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| OGame — Officer Bonuses | 고정된 소수의 보너스 타입이 전역 승수로 적용 | 범용 타입 8개로 85%의 세력 패시브 커버 |
| Path of Exile — Passive Tree Mod Types | 개별 효과를 `modifier` 단위로 타입화 | 효과 타입이 문자열 키, 서비스는 switch로 분기 |
| Melvor Idle — Mastery Bonus | 특정 스킬에 조건부 보너스 부여 | 조건부 타입을 조건 인코딩 방식으로 표현 |
| Darkest Dungeon — Faction Trinkets | 세력 소속이 특정 상황에서만 발동 | M1에서는 상시 발동으로 단순화, 향후 확장 여지 |

---

## 상세 설계

### 1. 효과 타입 체계 (14개)

**설계 원칙:**
- 범용 타입은 파라미터로 조건/대상 세분화 → 서비스 구현 단순 (switch + 파라미터 검색)
- 특수 타입은 독립 시스템(트레잇/조사) 연동이 필요한 케이스만 별도 정의
- 조건부 타입은 M1 범위에서 조건 종류가 제한적이므로 **조건 별 전용 타입**으로 인코딩 (조건 엔진을 만들지 않음)

#### 범용 타입 (8개)

| # | 효과 타입 | 파라미터 | 설명 | 적용 서비스 |
|---|----------|---------|------|-----------|
| 1 | `quest_reward_multiplier` | `quest_type` (raid/hunt/escort/explore/all), `value` | 퀘스트 보상 골드 배율 증가 | `QuestCompletionService` 보상 계산 시점 |
| 2 | `quest_success_rate_bonus` | `quest_type` (raid/hunt/escort/explore/all), `value` | 퀘스트 성공률 가산 | `QuestCalculator.calculateSuccessRate()` |
| 3 | `recovery_time_reduction` | `status` (injured/fatigued/all), `value` | 부상/피곤 회복 시간 비율 감소 | 용병 상태 회복 로직 (`core/domain/mercenary_recovery`) |
| 4 | `recruitment_tier_boost` | `tier_min`, `tier_max`, `value` | 특정 티어 구간 용병 모집 확률 가산 | `RecruitmentService.rollTier()` |
| 5 | `facility_cost_reduction` | `cost_type` (gold/time/all), `value` | 시설 건설 비용/시간 비율 감소 | `ConstructionService` 건설 개시 시점 |
| 6 | `facility_effect_bonus` | `facility_id`(nullable), `value` | 시설 효과 배율 증가 (null=전체 시설) | `FacilityService.getEffect()` 호출 후단 |
| 7 | `idle_reward_bonus` | `bonus_type` (rate/cap/all), `value` | 방치 보상 분당 획득량 또는 상한 증가 | `IdleRewardService.computeReward()` |
| 8 | `travel_event_mitigation` | `event_type` (gold_loss/damage/all), `value` | 이동 이벤트 음성 효과 경감 | `TravelEventService.applyEvent()` |

#### 특수 타입 (5개)

| # | 효과 타입 | 파라미터 | 설명 | 적용 서비스 |
|---|----------|---------|------|-----------|
| 9 | `investigation_success_rate_bonus` | `value` | 지역 조사 성공률 가산 | `InvestigationNotifier` 조사 시작 시점 |
| 10 | `trait_acquisition_condition_relief` | `value` | 후천 트레잇 획득 조건 임계값 완화 비율 | `TraitAcquisitionService` 조건 체크 시점 |
| 11 | `trait_evolution_condition_relief` | `value` | 트레잇 진화 조건 임계값 완화 비율 | `TraitEvolutionService` 진화 판정 시점 |
| 12 | `mercenary_xp_bonus` | `value` | 용병 XP 획득량 배율 증가 (시설 훈련소와 중첩 가산) | `ExperienceService.awardXp()` |
| 13 | `trait_unlock_category` | `category_key` | 특정 카테고리 트레잇 해금 (거점 방문 필요, 현재 stub) | 미구현 — `FactionJoinService`에서 플래그만 노출 |

#### 조건부 타입 (1개)

| # | 효과 타입 | 파라미터 | 설명 | 적용 서비스 |
|---|----------|---------|------|-----------|
| 14 | `quest_success_rate_bonus_party_size` | `min_party_size`, `value` | 최소 파티 인원 충족 시 성공률 가산 | `QuestCalculator` 성공률 계산 시 파티 크기 체크 |

**M1 범위 밖 조건은 추가하지 않는다.** M2a/M3 이후 조건이 늘어나면 범용 `conditions` 배열 필드로 리팩토링 가능하지만, M1은 최소 범위 유지.

---

### 2. JSON 스키마

`passive_bonus_json`은 **효과 배열**. 한 세력이 여러 효과를 동시에 가질 수 있다.

```json
{
  "effects": [
    {
      "type": "quest_reward_multiplier",
      "quest_type": "escort",
      "value": 0.15
    },
    {
      "type": "idle_reward_bonus",
      "bonus_type": "rate",
      "value": 0.10
    }
  ]
}
```

**필수 필드:**
- `effects`: 배열 (비어있어도 허용, 빈 배열은 "패시브 없음")
- 각 요소: `type` (필수, string enum), `value` (필수, float)
- 타입별 추가 파라미터는 위 표 참조

**value 의미 규약:**
- `*_multiplier`, `*_bonus`, `*_reduction`, `*_relief`: **비율** (0.15 = +15%, 0.30 = -30%)
- `recovery_time_reduction`의 0.20은 "회복 시간을 20% 단축"
- `quest_success_rate_bonus`의 0.05는 "성공률에 +5%p 가산" (비율이 아닌 절대 %p)
- `recruitment_tier_boost`의 0.05는 "해당 티어 확률에 +5%p 가산"

서비스 구현 시 이 규약을 `PassiveBonusService` 내부 주석으로 명시.

---

### 3. 스태킹 규칙

플레이어는 최대 3개 세력에 동시 가입 가능 → 동일 효과 타입이 중첩될 수 있다. 추가로 시설 효과(의무실 회복, 훈련소 XP 등)와도 중첩이 발생하므로 **효과 타입별로 스태킹 방식을 구분**한다.

#### 3.1 효과 타입별 스태킹 규칙

| 효과 타입 | 스태킹 방식 | 상한/하한 |
|---------|----------|---------|
| `quest_reward_multiplier` | **가산** | 없음 (quest_type별 독립이므로 실질 한계) |
| `quest_success_rate_bonus` (+ `_party_size`) | **가산** | **누적 합산 ≤ +20%p** (패시브+명성 공유 상한) |
| `investigation_success_rate_bonus` | 가산 | +20%p 공유 상한 내 |
| `idle_reward_bonus` | 가산 | 없음 |
| `travel_event_mitigation` | 가산 | 없음 (event_type별 독립) |
| `recruitment_tier_boost` | 가산 | 없음 |
| `facility_effect_bonus` | 가산 | 없음 |
| `facility_cost_reduction` (gold) | 가산 | 없음 |
| `mercenary_xp_bonus` (명성 전용) | 가산 | 없음 |
| `recovery_time_reduction` | **곱셈** | 최종 결과값 **하한 0.10** 클램프 |
| `facility_cost_reduction` (time) | **곱셈** | 최종 결과값 **하한 0.10** 클램프 |
| `trait_acquisition_condition_relief` | **곱셈** | 최종 결과값 **하한 0.10** 클램프 |
| `trait_evolution_condition_relief` | **곱셈** | 최종 결과값 **하한 0.10** 클램프 |

**곱셈 스태킹이 필요한 이유(`recovery_time_reduction` 예시):**

의무실 Lv25(-70%) + 태양 교단(-15%) + 뿌리의 맹세단(-15%)이 가산으로 합쳐지면 -100%로 회복 시간이 0 이하가 된다. 곱셈으로 처리하면:
```
최종 계수 = (1 - 0.70) × (1 - 0.15) × (1 - 0.15) = 0.30 × 0.85 × 0.85 = 0.2168
→ 회복 시간은 기본의 21.68% (즉 -78.3% 감소). 음수 불가.
```

곱셈 대상 효과 타입은 **최종 계수가 0.10 미만이면 0.10으로 클램프**하여 극단 스택 시에도 최소 10%는 유지한다.

#### 3.2 공통 규칙

| 규칙 | 동작 |
|------|------|
| **이질 파라미터** | 같은 타입이라도 파라미터가 다르면 독립 (예: explore 보상 +15% ≠ raid 보상 +20%) |
| **`all`과 특정 타입 중첩 (가산군)** | `quest_type: "all"` +3%와 `quest_type: "explore"` +15%는 탐험 시 +18%로 중첩 |
| **세력 + 명성 합산 (성공률 한정)** | 두 소스의 `quest_success_rate_bonus` + `_party_size` 총합이 +20%p 상한 공유 |
| **세력 + 명성 합산 (회복/시설/트레잇)** | 곱셈 방식으로 통합 (모든 소스를 한 번의 곱셈 파이프라인으로) |

**스태킹 예시:**
- 균형 감시자(전체 성공률 +3%) + 마탑 연합(탐험 성공률 +8%) → 탐험 퀘스트 +11% (가산)
- 모험가 길드(탐험 보상 +12%) + 상인 연합(호위 보상 +12%) → 중첩 안됨 (quest_type 다름)
- 의무실 Lv25(-70%) + 태양 교단(-15%) + 뿌리(-15%) → (1-0.70)(1-0.15)(1-0.15) = 0.2168 → 회복 시간 -78.3% (곱셈)

---

### 4. 적용 타이밍 및 해제

| 시점 | 동작 |
|------|------|
| **가입 직후** | 다음 계산부터 적용 (재시작/리로드 불필요) |
| **탈퇴** | 즉시 해제 |
| **충돌 세력 가입으로 인한 강제 탈퇴** | 즉시 해제, 평판 -100 |
| **적대 상태(-100)** | M1에선 추가 디버프 없음. 태그 퀘스트 미발생으로만 페널티 표현 |
| **세션 복귀** | 가입 상태는 Hive에 영속 → 복귀 시 재조회 자동 적용 |

**서비스 설계 원칙:** `PassiveBonusService.getEffectiveValue(type, params)`는 매 호출 시점에 `FactionStateRepository.getJoinedFactionIds()` → 각 세력 `passive_bonus_json` 순회 → 스태킹 후 반환. 캐싱은 구현 단순화를 위해 M1에서 미도입 (틱당 호출 수가 많지 않음 — 주요 호출은 퀘스트 계산/시설 건설/모집 시점).

---

### 5. 14개 세력 매핑안

기존 기획서의 서술을 구조화 JSON으로 변환한다. **아래 값은 페이즈 2 밸런스 리포트(`Docs/balance-design/20260417_faction_passive_values.md`)의 P2/P3/P4 권고를 반영한 최종값이다.**

#### 공개 세력 (6개)

| # | 세력 | passive_bonus_json |
|---|------|-------------------|
| 1 | 모험가 길드 | `{"effects":[{"type":"quest_reward_multiplier","quest_type":"explore","value":0.12}]}` |
| 2 | 상인 연합 | `{"effects":[{"type":"quest_reward_multiplier","quest_type":"escort","value":0.12},{"type":"idle_reward_bonus","bonus_type":"rate","value":0.10}]}` |
| 3 | 전사 길드 | `{"effects":[{"type":"quest_success_rate_bonus","quest_type":"raid","value":0.05},{"type":"quest_success_rate_bonus","quest_type":"hunt","value":0.05}]}` |
| 4 | 도둑 길드 | `{"effects":[{"type":"travel_event_mitigation","event_type":"gold_loss","value":0.30},{"type":"investigation_success_rate_bonus","value":0.05}]}` |
| 5 | 마탑 연합 | `{"effects":[{"type":"quest_success_rate_bonus","quest_type":"explore","value":0.08},{"type":"trait_acquisition_condition_relief","value":0.10}]}` |
| 6 | 태양 교단 | `{"effects":[{"type":"quest_success_rate_bonus","quest_type":"escort","value":0.08},{"type":"recovery_time_reduction","status":"injured","value":0.15}]}` |

#### 비밀 세력 (4개)

| # | 세력 | passive_bonus_json |
|---|------|-------------------|
| 7 | 균형 감시자 | `{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.03}]}` |
| 8 | 금지된 서고 | `{"effects":[{"type":"trait_evolution_condition_relief","value":0.15}]}` |
| 9 | 뿌리의 맹세단 | `{"effects":[{"type":"travel_event_mitigation","event_type":"damage","value":0.40},{"type":"recovery_time_reduction","status":"injured","value":0.15}]}` |
| 10 | 황혼 공학회 | `{"effects":[{"type":"facility_cost_reduction","cost_type":"gold","value":0.10},{"type":"facility_effect_bonus","facility_id":null,"value":0.05}]}` |

#### 지역·종족 세력 (4개)

| # | 세력 | passive_bonus_json |
|---|------|-------------------|
| 11 | 심층 망치단 | `{"effects":[{"type":"facility_cost_reduction","cost_type":"time","value":0.20}]}` |
| 12 | 화산 심장단 | `{"effects":[{"type":"quest_reward_multiplier","quest_type":"raid","value":0.15}]}` |
| 13 | 혈계 귀족회 | `{"effects":[{"type":"recruitment_tier_boost","tier_min":4,"tier_max":5,"value":0.04}]}` |
| 14 | 송곳니 결사 | `{"effects":[{"type":"quest_success_rate_bonus_party_size","min_party_size":3,"value":0.08}]}` |

> 위 수치는 페이즈 2 밸런스 리포트 반영 완료. 초안 대비 변경:
> - 모험가 길드 explore +15% → **+12%** (P2: 순수익 증폭 완화)
> - 상인 연합 escort +15% → **+12%** (P2)
> - 화산 심장단 raid +20% → **+15%** (P2: 스케일 통일)
> - 뿌리의 맹세단 회복 -20% → **-15%** (P4: 체감 차별화)
> - 혈계 귀족회 T4~T5 모집 +5% → **+4%** (P3: 주점 중첩 과점 완화)
> - 스태킹 규칙: recovery / facility(time) / trait_condition은 **곱셈 + 하한 0.10 클램프** (P1: 음수 방지)

---

### 6. UI 표시 규칙

세력 도감 `FactionDetailScreen`의 "패시브 보너스" 섹션은 현재 `passive_bonus_json`의 원본 JSON을 텍스트 변환 없이 표시하는 stub 상태. M1 구현 시:

| 효과 타입 | 표시 템플릿 |
|----------|-----------|
| `quest_reward_multiplier` | `{퀘스트 유형} 보상 +{value*100}%` |
| `quest_success_rate_bonus` | `{퀘스트 유형} 성공률 +{value*100}%` |
| `recovery_time_reduction` | `{상태} 회복 시간 −{value*100}%` |
| `recruitment_tier_boost` | `티어 {tier_min}~{tier_max} 모집 확률 +{value*100}%` |
| `facility_cost_reduction` | `시설 건설 {cost_type=gold?골드:시간} −{value*100}%` |
| `facility_effect_bonus` | `시설 효과 +{value*100}%` (facility_id 있으면 특정 시설명) |
| `idle_reward_bonus` | `방치 보상 {분당/상한} +{value*100}%` |
| `travel_event_mitigation` | `이동 중 {골드 손실/피해} −{value*100}%` |
| `investigation_success_rate_bonus` | `지역 조사 성공률 +{value*100}%` |
| `trait_acquisition_condition_relief` | `트레잇 획득 조건 −{value*100}% 완화` |
| `trait_evolution_condition_relief` | `트레잇 진화 조건 −{value*100}% 완화` |
| `mercenary_xp_bonus` | `용병 XP +{value*100}%` |
| `trait_unlock_category` | `{카테고리} 트레잇 해금 (거점 방문 필요)` |
| `quest_success_rate_bonus_party_size` | `{min_party_size}명 이상 파견 시 성공률 +{value*100}%` |

**퀘스트 유형 한글 매핑:** raid→약탈, hunt→토벌, escort→호위, explore→탐험, all→모든 퀘스트
**상태 한글 매핑:** injured→부상, fatigued→피곤, all→모든 상태

`PassiveBonusFormatter`(신규 유틸 클래스)를 만들어 이 변환을 전담. operation-bom의 세력 편집 화면에서도 동일 포맷 사용.

---

## 현재 시스템과의 연관

| 영역 | 영향 | 처리 방식 |
|------|------|----------|
| `factions` 테이블 | `passive_bonus_json` 필드는 이미 JSONB로 존재 | 스키마 변경 없이 14개 row 값만 갱신 |
| `FactionData` Freezed 모델 | `passiveBonusJson` 필드를 `Map<String, dynamic>`로 파싱 중 | 신규 `PassiveBonusEffect` 값 타입 정의 필요 |
| `PassiveBonusService` | **신규** | 스태킹/상한 로직 전담. 각 기존 서비스에서 의존성 주입 |
| `QuestCalculator` | 성공률/보상 계산 직전 `PassiveBonusService` 조회 | 인터페이스 확장 (brief 변경) |
| `RecruitmentService`, `ConstructionService`, `FacilityService`, `IdleRewardService`, `TravelEventService`, `InvestigationNotifier`, `TraitAcquisitionService`, `TraitEvolutionService`, `ExperienceService`, 회복 로직 | 각 서비스 내 해당 계산 지점에 패시브 훅 추가 | 서비스별 명세는 페이즈 4 (`/spec-writer`) |
| `FactionDetailScreen` | 패시브 보너스 섹션 포맷 교체 | `PassiveBonusFormatter` 사용 |
| operation-bom | 세력 편집 화면에 패시브 효과 추가/편집 UI 필요 | 타입 드롭다운 + 파라미터 동적 폼 (별도 작업) |

**`faction_passive_bonuses` 테이블 신설 여부:** 기존 기획서(proto_design 및 roadmap M1)는 "`passive_bonus_json` → 정규화 테이블 `faction_passive_bonuses`로 전환"을 제안했다. 그러나 본 설계에서는 **JSONB 유지를 권장**한다. 이유:
- M1 범위에선 타입 수가 14개로 관리 가능
- Supabase JSONB 컬럼으로 Flutter 모델 파싱이 단순 (freezed + json_serializable 기본 동작)
- operation-bom UI는 타입 드롭다운 + 파라미터 폼으로 해결 가능 (정규화 테이블 없이도 편집성 확보)
- 정규화 전환은 효과 타입이 30개+로 늘어날 때(M6 시점) 재검토
- roadmap의 "정규화 전환" 제안과 차이 → 페이즈 2/4에서 최종 결정 권장

---

## 구현 우선순위 제안

### 높음 — M1 핵심

| 작업 | 내용 |
|------|------|
| 효과 타입 enum/Freezed | `PassiveBonusEffect` sealed 클래스 또는 타입 enum + 파라미터 Map |
| `PassiveBonusService` | 스태킹 + 성공률 상한 + 조건 체크 |
| 각 도메인 서비스 연동 | QuestCalculator, RecruitmentService, FacilityService, 회복 로직 우선 |
| 14개 세력 passive_bonus_json 갱신 | operation-bom 또는 SQL로 직접 입력 |
| `FactionDetailScreen` 포맷터 | 한국어 표시 교체 |

### 중간 — M1 구현 중

| 작업 | 내용 |
|------|------|
| IdleRewardService, TravelEventService, InvestigationNotifier 연동 | 상대적으로 적용 포인트가 단순 |
| `trait_acquisition_condition_relief` / `trait_evolution_condition_relief` 연동 | 기존 서비스의 임계값 비교에 보정 주입 |
| operation-bom 패시브 편집 UI | 타입 드롭다운 + 파라미터 동적 폼 |

### 낮음 — 후속

| 작업 | 내용 |
|------|------|
| `trait_unlock_category` 실제 동작 | 거점 시스템 도입 시 (M3 이후) |
| 성공률 외 상한 재검토 | M6 전역 재조정 시 |
| 캐싱 레이어 | 성능 이슈 발생 시 |

---

## data-generator 지시사항

> 본 기획안은 **시스템 설계**이며 벌크 데이터 생성이 불필요하다. 14개 세력 패시브 값은 이 문서의 섹션 5 표를 operation-bom 또는 SQL로 직접 입력한다.
>
> 섹션 5의 JSON은 페이즈 2(`/balance-designer`) 수치 검증 후 최종 확정된 값으로 교체한다.

---

## 후속 안내

- 본 기획안은 M1 페이즈 1 산출물 1/4. 다음 페이즈 2에서 밸런스 검증 필요.
- `/balance-designer`로 다음 항목을 시뮬레이션 권장:
  - `quest_reward_multiplier` 중첩 시 골드 인플레이션
  - `recruitment_tier_boost` + 주점 시설 중첩 시 티어 분포
  - `facility_cost_reduction` + `facility_effect_bonus` 동시 적용 시 시설 ROI
  - 성공률 상한 +20%의 실효 도달 빈도
- 구현 진행 시(페이즈 4) `/spec-writer @Docs/content-design/[content]20260417_faction_passive_mapping.md`로 개발 명세 생성
- milestone-runner 재진입: `/milestone-runner M1 --resume`
