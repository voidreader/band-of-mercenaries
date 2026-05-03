# PassiveBonusService 신설 및 기존 서비스 통합 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260417_faction_passive_mapping.md` (효과 타입 체계 원안)
> - `Docs/balance-design/20260417_faction_passive_values.md` (14세력 수치 확정 + P1~P4)
> - `Docs/balance-design/20260417_rank_bonuses_values.md` (16개 효과 타입 최종 카탈로그, 명성 누적 스펙)
> 작성일: 2026-04-18
> 마일스톤: M1 페이즈 4 (1/4)
> UI 목업: 사용 안 함 (백엔드 서비스 중심, UI 변경은 `FactionDetailScreen`의 포맷터 교체만)

## 1. 개요

세력 가입(`factions.passive_bonus_json`)과 명성 누적 랭크(`ranks.bonus_json`)에서 파생되는 **16개 효과 타입**을 통합 스태킹하여 게임 메커니즘에 주입하는 단일 진입점 서비스 `PassiveBonusService`를 신설한다. 6개 도메인 서비스(QuestCalculator / RecruitmentService / ConstructionService / TraitAcquisitionService·TraitEvolutionService / IdleRewardService / TravelEventService)에 조회 훅을 추가하여 런타임 보정값을 받아가도록 한다. **P1: `recovery_time_reduction` 계열은 반드시 곱셈 스태킹 + 하한 0.10 클램프**로 처리하여 음수 회복 시간 버그를 방지한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: 16개 효과 타입 카탈로그 정의

하나의 단일 카탈로그로 세력·명성 모두 커버한다. 범용 8 + 특수 5 + 조건부 1 + 명성전용 1 + 공통추가 1 = **16개**.

| # | 타입 키 | 파라미터 | 적용 서비스 | 스태킹 | 수치 범위 |
|:-:|--------|---------|-----------|:-----:|:--------:|
| 1 | `quest_reward_multiplier` | `quest_type`(raid/hunt/escort/explore/all), `value` | QuestCompletionService 보상 계산 | 가산 | 0.03~0.15 |
| 2 | `quest_success_rate_bonus` | `quest_type`, `value` (%p) | QuestCalculator 성공률 | 가산 (공유 상한 +20%p) | 0.02~0.08 |
| 3 | `quest_success_rate_bonus_party_size` | `min_party_size`, `value` (%p) | QuestCalculator | 가산 (공유 상한 +20%p) | 0.08 |
| 4 | `recovery_time_reduction` | `status`(injured/fatigued/all), `value` | 회복 시간 계산 (QuestCompletionService 내) | **곱셈 (하한 0.10)** | 0.10~0.20 |
| 5 | `recruitment_tier_boost` | `tier_min`, `tier_max`, `value` (%p) | RecruitmentService.selectTier | 가산 | 0.03~0.04 |
| 6 | `recruitment_cost_reduction` | `value` | RecruitmentService 유료 모집 비용 | **곱셈 (하한 0.10)** | 0.10 |
| 7 | `facility_cost_reduction`(gold) | `cost_type="gold"`, `value` | ConstructionService.calculateCost | 가산 | 0.10~0.20 |
| 8 | `facility_cost_reduction`(time) | `cost_type="time"`, `value` | ConstructionService.calculateBuildDuration | **곱셈 (하한 0.10)** | 0.10~0.20 |
| 9 | `facility_effect_bonus` | `facility_id`(nullable), `value` | ConstructionService.getEffectValue 후단 | 가산 | 0.05~0.10 |
| 10 | `idle_reward_bonus` | `bonus_type`(rate/cap), `value` | IdleRewardService | 가산 | 0.05~0.15 |
| 11 | `travel_event_mitigation` | `event_type`(gold_loss/damage/all), `value` | TravelEventService | 가산 (event_type 독립) | 0.20~0.40 |
| 12 | `investigation_success_rate_bonus` | `value` (%p) | InvestigationNotifier | 가산 (공유 상한 +20%p) | 0.03~0.05 |
| 13 | `trait_acquisition_condition_relief` | `value` | TraitAcquisitionService 조건 임계값 | **곱셈 (하한 0.10)** | 0.10~0.15 |
| 14 | `trait_evolution_condition_relief` | `value` | TraitEvolutionService 조건 임계값 | **곱셈 (하한 0.10)** | 0.10~0.15 |
| 15 | `mercenary_xp_bonus` | `value` | ExperienceService | 가산 | 0.10~0.15 |
| 16 | `dispatch_slot_bonus` | `value` (int) | 파견 슬롯 계산 | 가산 (상한 **+10**) | +1 (정수) |

**미구현 stub 타입 (M1 범위 밖):** `trait_unlock_category` — 기획서에는 언급되나 거점 시스템이 있는 M3 이후 도입. PassiveBonusService는 이 타입을 파싱은 하되 **적용 단계에서 무시**한다.

#### FR-2: PassiveBonusService 단일 진입점

- 새 파일: `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart`
- 단일 정적 유틸 클래스(기존 `ExperienceService` / `ReputationService` 패턴 준수. DI 없음).
- 주요 API:
  - `double effectiveMultiplier(EffectType type, {Map params, required CollectedEffects effects})` — 가산/곱셈 스태킹 계산 후 **곱셈 스태킹은 (1 - Σ 또는 Π)** 형태의 "남는 비율" 반환 (예: 회복 시간은 0.195 = 19.5%). 가산 스태킹은 0.15 같은 **보너스 증분** 반환 (곱하기는 호출측에서 `× (1 + bonus)` 또는 `+ bonus`로 수행).
  - `int effectiveIntegerBonus(EffectType type, {CollectedEffects effects})` — `dispatch_slot_bonus` 전용, 상한 +10 적용.
  - `double cappedSuccessRateBonus({required String questTypeId, required int partySize, required CollectedEffects effects})` — 공유 상한 +20%p 적용. `role_synergy`, `trait_synergy`는 **입력으로 받지 않음** (별도 레이어).
  - `double cappedInvestigationSuccessBonus({required CollectedEffects effects})` — 공유 상한은 분석 7에서 `investigation_success_rate_bonus`만 별도 풀로 둠 → 같은 20%p 상한을 자체 내에서만 적용.
  - `CollectedEffects collect({required List<FactionData> joinedFactions, required Rank currentRank, required List<Rank> rankChain})` — 세력 effects + 현재 랭크까지 누적 effects 통합.

- 내부 타입 `CollectedEffects`: `List<PassiveEffect>` 래핑. `PassiveEffect`는 **freezed union** (`PassiveEffect.questReward(...)`, `PassiveEffect.successRate(...)`, etc.) 또는 단순 `class` + `Map<String,dynamic>` params. **선택 결정은 FR-3 참조**.

#### FR-3: PassiveEffect 모델 설계 결정

2개 옵션 검토:
- (A) **Freezed sealed class**: 타입 안전성 +, 16개 variant 생성 비용, params 필드가 효과마다 다르므로 각 variant에서 명시. 권장.
- (B) **단일 class + type enum + params Map**: 단순하나 param key 오타 위험.

**결정(권장):** (A) Freezed sealed class. 파일 `band_of_mercenaries/lib/core/models/passive_effect.dart`.

```dart
@freezed
sealed class PassiveEffect with _$PassiveEffect {
  const factory PassiveEffect.questReward({
    required String questType, required double value,
  }) = QuestRewardEffect;
  const factory PassiveEffect.successRate({
    required String questType, required double value,
  }) = SuccessRateEffect;
  const factory PassiveEffect.successRatePartySize({
    required int minPartySize, required double value,
  }) = SuccessRatePartySizeEffect;
  const factory PassiveEffect.recoveryTime({
    required String status, required double value,
  }) = RecoveryTimeEffect;
  const factory PassiveEffect.recruitmentTierBoost({
    required int tierMin, required int tierMax, required double value,
  }) = RecruitmentTierBoostEffect;
  const factory PassiveEffect.recruitmentCost({
    required double value,
  }) = RecruitmentCostEffect;
  const factory PassiveEffect.facilityCost({
    required String costType, required double value,
  }) = FacilityCostEffect;
  const factory PassiveEffect.facilityEffect({
    String? facilityId, required double value,
  }) = FacilityEffectBonus;
  const factory PassiveEffect.idleReward({
    required String bonusType, required double value,
  }) = IdleRewardEffect;
  const factory PassiveEffect.travelEventMitigation({
    required String eventType, required double value,
  }) = TravelEventMitigationEffect;
  const factory PassiveEffect.investigationSuccessRate({
    required double value,
  }) = InvestigationSuccessRateEffect;
  const factory PassiveEffect.traitAcquisitionRelief({
    required double value,
  }) = TraitAcquisitionReliefEffect;
  const factory PassiveEffect.traitEvolutionRelief({
    required double value,
  }) = TraitEvolutionReliefEffect;
  const factory PassiveEffect.mercenaryXp({
    required double value,
  }) = MercenaryXpEffect;
  const factory PassiveEffect.dispatchSlot({
    required int value,
  }) = DispatchSlotEffect;
  const factory PassiveEffect.traitUnlockCategory({
    required String categoryKey,
  }) = TraitUnlockCategoryEffect;

  factory PassiveEffect.fromJson(Map<String, dynamic> json) =>
      _$PassiveEffectFromJson(json);
}
```

JSON 역직렬화는 `type` 필드 기반 discriminator 수동 switch 구현. `value`가 없는 `traitUnlockCategory`는 null-safe.

#### FR-4: 세력/명성 effects 수집 로직

`PassiveBonusService.collect(...)`:

```
1. joinedFactions의 각 FactionData.passiveBonusJson 파싱 → List<PassiveEffect>
2. rankChain (F → currentRank까지 순서대로)의 각 Rank.bonusJson 파싱 → List<PassiveEffect>
   - F는 bonus_json 빈 배열. E~A까지 순차 포함
3. 두 리스트를 합쳐 CollectedEffects로 반환
4. collect()는 순수 함수. 캐싱 없음 (M1 범위). 호출당 JSON 파싱 비용 허용
```

`rankChain`은 호출측에서 `ranks` 정적 데이터 + `ReputationService.getCurrentRank()` 결과를 조합해 전달.

#### FR-5: 스태킹 규칙 구현

공식:

```
// 가산 (quest_reward_multiplier, success_rate, tier_boost, ...)
sum = Σ(matching effects).value

// 곱셈 (recovery_time, facility_cost(time), trait_relief, recruitment_cost)
residual = Π(matching effects).(1 - value)   // 남는 비율
clamped = max(residual, 0.10)                 // 하한 클램프

// 공유 상한 +20%p (success_rate 계열)
combined = Σ(successRate + successRatePartySize[파티≥min일 때]).value
capped = min(combined, 0.20)
```

**중요:** 곱셈 계산의 반환 타입 일관성 유지. `effectiveMultiplier`는 "남는 비율"(0.0~1.0) 반환이므로 호출측에서 `(baseValue × residual)` 또는 `(baseValue × (1 - 합산))` 용례를 **문서 주석에 명기**한다.

#### FR-6: QuestCalculator 연동

- 파일: `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart`
- `calculateSuccessRate`, `calculateSuccessRatePreview` 시그니처에 `double factionPassiveBonus = 0.0` 파라미터 추가 (기본값 0 → 기존 호출 호환)
- 수식:
  ```
  rate = 50 + (partyPower/enemyPower - 1) × 50
       + traitBonus        ← 독립 상한 (본 명세 범위 밖)
       + questMod          ← 기존
       - distancePenalty
       + factionPassiveBonus  ← 신규 (공유 상한 +20%p 적용된 값)
       + (roleSynergyBonus)    ← M1 페이즈 4의 3번 명세에서 별도 추가. 본 명세에서는 파라미터만 `0.0` 기본값으로 자리만 확보
       + randomVariance (calculateSuccessRate만)
  clamp(5, 95)
  ```
- 호출측 `QuestCompletionService` (`lib/features/quest/domain/quest_completion_service.dart`)에서 `PassiveBonusService.cappedSuccessRateBonus(...)` 호출 후 전달

- **보상 계산 훅**: `QuestCompletionService`의 `calculateReward` 호출 구간(현재 라인 기준 보상 로직)에 `quest_reward_multiplier` 가산 적용:
  ```
  final_reward = base_reward × difficulty.reward_multiplier
               × (1 + sum(quest_reward_multiplier for quest_type in [current, 'all']))
               × (isGreatSuccess ? 2 : 1)
  ```
  가산 총합 상한은 향후 `faction_quests_balance.md`의 +0.80 클램프 별도 명세(페이즈 4의 2번)에서 통합 구현 예정. **본 명세 FR-6에서는 세력·명성만 합산하고 상한 미적용** (페이즈 4의 2번 명세와 병합 시 상한 적용).

#### FR-7: RecruitmentService 연동

- 파일: `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart`
- `selectTier(Random, double recruitBonus, {double extraHighTierBoost = 0.0})` — 기존 `recruitBonus`는 주점 시설 효과 유지. 신규 파라미터 `extraHighTierBoost`: `recruitment_tier_boost`의 T4~T5 가산. 호출측에서 `PassiveBonusService`로 수집 후 전달
- 유료 모집 비용: `recruit_screen.dart:118` 주변의 `GameConstants.paidRecruitCost` 직접 참조를 **새 헬퍼 `RecruitmentService.effectivePaidCost(int baseCost, double costReduction)`**로 교체. `costReduction`은 `recruitment_cost_reduction` 곱셈 결과 "남는 비율".
  ```
  finalCost = round(baseCost × costReduction)
  ```
- UI: `recruit_screen.dart`에서 `ref.watch` → joinedFactions + currentRank → PassiveBonusService.collect → effectivePaidCost 호출. 할인 금액 표시 텍스트 추가 (UI 세부는 별도 스펙에서 다룸)

#### FR-8: ConstructionService 연동

- 파일: `band_of_mercenaries/lib/features/facility/domain/construction_service.dart`
- `calculateCost(int level, double goldReduction)` 신규 파라미터. 기본값 0.0. 적용: `cost × (1 - goldReduction)` (가산 스태킹)
- `calculateBuildDuration(int level, double speedMultiplier, double timeResidual)` — `timeResidual`은 곱셈 스태킹 결과 "남는 비율" (0.10~1.0). `finalSeconds = baseSeconds × timeResidual / speedMultiplier`
- `getEffectValue(Facility f, int level, double effectBonus)` — 기존 시설 효과 계산 후 `× (1 + effectBonus)` 가산
- 호출측: `ConstructionNotifier` (또는 건설 관련 Provider). 현재 호출 지점 식별 후 `PassiveBonusService` 주입

#### FR-9: TraitAcquisitionService / TraitEvolutionService 연동

- 파일 1: `band_of_mercenaries/lib/features/mercenary/domain/trait_acquisition_service.dart`
  - 기존 `_meetsCondition(..., double reductionPercent)` private 메서드에 이미 시너지 감소 로직 있음
  - 신규: `checkAcquisitionCandidates` 시그니처에 `double passiveRelief` 파라미터 추가 (기본 0.0). 내부에서 기존 `reductionPercent`와 **곱셈 결합** — 시너지는 개별 트레잇 특화, 패시브는 전역
  - 공식: `effectiveThreshold = threshold × synergyResidual × passiveResidual`
    - `synergyResidual = (1 - reductionPercent)` (기존)
    - `passiveResidual = PassiveBonusService.effectiveMultiplier(traitAcquisitionRelief)` (곱셈)
    - 최종 클램프: `max(effectiveThreshold, threshold × 0.10)`

- 파일 2: `band_of_mercenaries/lib/features/mercenary/domain/trait_evolution_service.dart`
  - 현재 `_meetsCondition()`은 조건 검증만 수행 (완화 훅 없음)
  - 신규: `checkSingleEvolutions(..., double passiveRelief)`, `checkComboEvolutions(..., double passiveRelief)` 파라미터 추가
  - `_meetsCondition` 내부에 동일 공식으로 임계값 완화 로직 주입

#### FR-10: IdleRewardService 연동

- 파일: `band_of_mercenaries/lib/core/domain/idle_reward_service.dart`
- `calculateReward(DateTime since, int idleBonusAmount, {double rateBonus = 0.0, double capBonus = 0.0})` — 신규 두 파라미터
- 공식:
  ```
  base_rate = idleRewardPerMinute × (1 + rateBonus)
  base_cap = MAX_IDLE_MINUTES × idleRewardPerMinute + idleBonusAmount × (1 + capBonus)
  reward = min(elapsedMinutes × base_rate, base_cap)
  ```
- 호출측: `main.dart` 방치형 보상 로직 (기존 구조 유지, 파라미터 주입만)

#### FR-11: TravelEventService 연동

- 파일: `band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart`
- 기존 `applyDamageReduction(magnitude, damageReduction)` 훅 활용
- 신규: `applyGoldLossMitigation(goldLoss, goldLossReduction)` 추가
- `TravelEventNotifier` 또는 호출측에서 `PassiveBonusService`로 `event_type="damage"`와 `event_type="gold_loss"` 각각 가산 수집 후 전달
- `event_type="all"` 효과는 모든 이벤트 타입에 가산 (기획서 섹션 3.2)

#### FR-12: ExperienceService 연동 (mercenary_xp_bonus)

- 파일: `band_of_mercenaries/lib/core/domain/experience_service.dart` (파일 존재 확인됨)
- `awardXp` 또는 `calculateXpGain(..., double passiveXpBonus = 0.0)` 파라미터 추가
- 훈련소 시설 보너스와 **가산 스태킹**: `totalBonus = trainingFacilityBonus + passiveXpBonus`
- 호출측 `QuestCompletionService`에서 `PassiveBonusService`로 수집 후 전달

#### FR-13: `dispatch_slot_bonus` 적용

- 기본 동시 파견 수 계산 위치 식별 필요 (현재 코드 추정: `QuestProvider` 또는 `QuestGenerator` 내 정보망 시설 효과 가져오는 지점)
- 공식: `maxSlots = 1 + intelligenceFacilityEffect + PassiveBonusService.effectiveIntegerBonus(dispatchSlot, effects) /* 상한 +10 */`
- 상한: `PassiveBonusService`가 내부에서 `min(Σ value, 10)` 적용

#### FR-14: FactionDetailScreen 포맷터 교체

- 파일 1 (신규): `band_of_mercenaries/lib/features/info/domain/passive_bonus_formatter.dart`
- 파일 2: `band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart` (현재 stub 상태로 원본 JSON 표시)
- 포맷터는 `PassiveEffect` 인스턴스를 받아 기획서 섹션 6 템플릿 표 기준 한국어 문자열 반환
- 퀘스트 유형 한글 매핑: raid→약탈, hunt→토벌, escort→호위, explore→탐험, all→모든 퀘스트
- 상태 한글 매핑: injured→부상, fatigued→피곤, all→모든 상태

### 2.2 데이터 요구사항

#### 2.2.1 Supabase 스키마 확장

**결정:** 기존 `factions.passive_bonus_json` (JSONB) 유지. 별도 `faction_passive_bonuses` 정규화 테이블 **미신설** (기획서 섹션 현재 시스템과의 연관 표 권장안).

**신규 테이블/컬럼:**

| 테이블 | 변경 내용 | 용도 |
|--------|----------|------|
| `ranks` | **`bonus_json` JSONB 컬럼 추가** (default `'{"effects": []}'::jsonb`) | 6개 row(F~A)에 랭크별 누적 보너스 저장 |
| `ranks` | **`required_reputation` UPDATE**: E 500 → **300** | C1 조정 |

**세력 데이터 UPDATE** (`UPDATE factions SET passive_bonus_json = ...`):
- `20260417_faction_passive_values.md` "조정 제안" 표의 14개 세력 최종 수치 입력
- P1 (회복 곱셈 스태킹), P2 (보상 +15→+12%), P3 (혈계 +5→+4%), P4 (뿌리 -20→-15%) 반영

**랭크 데이터 INSERT** (`UPDATE ranks SET bonus_json = ...`):
- `20260417_rank_bonuses_values.md` "수치 조정안" 표 기준:
  - F: `{"effects":[]}`
  - E: `recruitment_cost_reduction 0.10`
  - D: `quest_reward_multiplier all 0.03, recovery_time_reduction injured 0.10`
  - C: `quest_success_rate_bonus all 0.03, dispatch_slot_bonus 1`
  - B: `quest_reward_multiplier all 0.07, idle_reward_bonus rate 0.15, trait_acquisition_condition_relief 0.10, quest_success_rate_bonus all 0.02`
  - A: `quest_success_rate_bonus all 0.05, facility_cost_reduction time 0.10, mercenary_xp_bonus 0.15, dispatch_slot_bonus 1`

#### 2.2.2 Flutter 데이터 모델

**신규 파일:**
- `band_of_mercenaries/lib/core/models/passive_effect.dart` — Freezed sealed class (FR-3)

**수정 파일:**
- `band_of_mercenaries/lib/core/models/rank.dart` — `@JsonKey(name: 'bonus_json')` 필드 추가, 타입 `Map<String, dynamic>?` 또는 `PassiveEffectList`
- `band_of_mercenaries/lib/core/models/faction_data.dart` — `passive_bonus_json` 이미 파싱 중. 내부 변환 로직에서 `PassiveEffect` 리스트로 변환하는 헬퍼 getter 추가 (`List<PassiveEffect> get passiveEffects`)

#### 2.2.3 SyncService 등록

- 파일: `band_of_mercenaries/lib/core/data/sync_service.dart` (또는 `data_loader.dart`)
- `ranks` 테이블 sync 시 `bonus_json` 컬럼 포함하도록 쿼리 확인 (현재 `SELECT *` 가정 시 자동 포함). 필요 시 `bonus_json`을 명시적으로 SELECT 목록에 추가
- `data_versions` 테이블의 `ranks` / `factions` 엔트리 버전 증가 필요 (SQL 마이그레이션과 함께 수행)

#### 2.2.4 operation-bom 편집 UI (범위 밖, 후속 작업)

- 본 명세 범위 **아님**. 한국어 문자열 입력은 SQL 직접 UPDATE로 1회성 수행. operation-bom UI는 별도 작업으로 분리.

### 2.3 UI 요구사항

#### 2.3.1 FactionDetailScreen 패시브 섹션 (기존 stub 교체)

- **위젯 계층**: 기존 `FactionDetailScreen` 내부 "패시브 보너스" 섹션을 `Column > ListView.builder(effects)` 구조로. 각 항목은 `Card > ListTile(leading: icon, title: Text(formatter.format(effect)))`.
- **상태 변수**: 기존 FactionDetailScreen에 신규 추가 없음. `factionData.passiveEffects` getter로 렌더 시 계산.
- **화면 전환**: 기존 `InfoScreen → FactionCodexScreen → FactionDetailScreen` 상태 기반 렌더링 유지. CLAUDE.md의 `Navigator.push` 금지 제약 준수.
- **연출**: 없음. 정적 리스트.

#### 2.3.2 RankBonusScreen (M1 범위 밖, 페이즈 4의 4번 명세에서 신설)

- 본 명세에서는 **정의하지 않음**. ReputationService 랭크 보너스 명세(페이즈 4의 4번)에서 담당.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | `calculateSuccessRate`/`calculateSuccessRatePreview`에 `factionPassiveBonus` 파라미터 추가 | FR-6 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 보상·XP·명성 계산 직전에 PassiveBonusService 조회 | FR-6, FR-12 |
| `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` | `selectTier` 파라미터 확장 + `effectivePaidCost` 신규 static | FR-7 |
| `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart` | `GameConstants.paidRecruitCost` 직접 참조를 PassiveBonusService 경유로 교체 | FR-7 |
| `band_of_mercenaries/lib/features/facility/domain/construction_service.dart` | 3개 메서드에 파라미터 추가 (`calculateCost`, `calculateBuildDuration`, `getEffectValue`) | FR-8 |
| `band_of_mercenaries/lib/features/mercenary/domain/trait_acquisition_service.dart` | `checkAcquisitionCandidates`에 `passiveRelief` 추가 | FR-9 |
| `band_of_mercenaries/lib/features/mercenary/domain/trait_evolution_service.dart` | `checkSingleEvolutions`/`checkComboEvolutions`에 `passiveRelief` 추가 | FR-9 |
| `band_of_mercenaries/lib/core/domain/idle_reward_service.dart` | `rateBonus`, `capBonus` 파라미터 추가 | FR-10 |
| `band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart` | `applyGoldLossMitigation` 신규 | FR-11 |
| `band_of_mercenaries/lib/core/domain/experience_service.dart` | `calculateXpGain`에 `passiveXpBonus` 추가 | FR-12 |
| `band_of_mercenaries/lib/core/models/rank.dart` | `bonusJson` 필드 추가 (`@JsonKey(name: 'bonus_json')`) | FR-4, 2.2.2 |
| `band_of_mercenaries/lib/core/models/faction_data.dart` | `passiveEffects` getter 추가 | 2.2.2 |
| `band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart` | 패시브 섹션 포맷터 교체 | FR-14 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `ranks.bonus_json` 쿼리 포함 확인 | 2.2.3 |
| `band_of_mercenaries/lib/main.dart` | 방치형 보상 호출 경로에 rateBonus/capBonus 전달 | FR-10 |
| `band_of_mercenaries/lib/app.dart` | (확인 필요) 포그라운드 싱크 시 ranks 버전 포함 | 2.2.3 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/passive_effect.dart` | Freezed sealed class (16개 variant) + fromJson 수동 디스패치 |
| `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart` | 단일 진입점 서비스 (수집·스태킹·상한 적용) |
| `band_of_mercenaries/lib/features/info/domain/passive_bonus_formatter.dart` | 한국어 표시 템플릿 변환 유틸 |
| `band_of_mercenaries/supabase/migrations/20260418_ranks_bonus_json.sql` | ranks.bonus_json 컬럼 추가 + E 임계값 UPDATE + 세력/랭크 데이터 UPDATE (단일 트랜잭션) |
| `band_of_mercenaries/test/core/domain/passive_bonus_service_test.dart` | 16개 타입별 스태킹·상한 케이스 유닛 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/passive_effect.g.dart` `.freezed.dart` | 신규 Freezed sealed class |
| `band_of_mercenaries/lib/core/models/rank.g.dart` `.freezed.dart` | bonus_json 필드 추가 |
| `band_of_mercenaries/lib/core/models/faction_data.g.dart` `.freezed.dart` | passiveEffects getter는 freezed 재생성 불필요하나 기존 모델 유지 |

`cd band_of_mercenaries && dart run build_runner build` 필수.

### 3.4 관련 시스템

- **퀘스트 시스템**: QuestCalculator/QuestCompletionService에 훅 주입 (성공률·보상·XP·명성). 페이즈 4의 2번 명세(세력 태그 + 전용 퀘스트)와 **파라미터 레벨 통합 필요** — QuestCalculator 시그니처는 두 명세가 동시 변경하므로 병합 주의
- **세력 시스템**: FactionData 모델 `passiveEffects` getter 추가. FactionDetailScreen 표시 교체
- **명성 시스템**: Rank 모델 `bonusJson` 필드 추가. 페이즈 4의 4번 명세에서 ReputationService 확장 (rankChain 수집) 필요 — **본 명세와 의존**
- **용병 시스템**: Recruitment, Trait(Acquisition/Evolution), XP 훅. 주점 시설과 가산 스태킹(모집 확률)
- **시설 시스템**: ConstructionService 3개 메서드 훅
- **이동 시스템**: TravelEventService 훅
- **방치 시스템**: IdleRewardService 훅

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **정적 유틸 클래스 패턴**: `ExperienceService`, `ReputationService`, `QuestCalculator`의 `static` 메서드 기반 서비스. DI 없음. `PassiveBonusService`도 동일 스타일
- **Freezed sealed class**: 현재 코드에 기존 sealed class 사용 예는 없으나 `freezed` 패키지가 이미 도입됨. `CLAUDE.md`의 "모델이나 Provider를 수정한 후에는 반드시 `dart run build_runner build`를 실행" 준수
- **JSONB 파싱**: `FactionData`의 `passiveBonusJson` (`Map<String, dynamic>`) 이미 파싱 중 → 동일 패턴으로 `Rank.bonusJson` 추가
- **트레잇 시너지 완화 공식 재사용**: `TraitAcquisitionService._meetsCondition`에서 `reductionPercent` 기반 임계값 완화 로직이 이미 존재 → `passiveRelief`와 곱셈 결합

### 4.2 주의사항

- **P1 (치명적)**: `recovery_time_reduction` / `facility_cost_reduction(time)` / `trait_*_condition_relief` / `recruitment_cost_reduction` 네 개는 **반드시 곱셈 스태킹 + 하한 0.10 클램프**. 유닛 테스트에서 의무실 Lv25 + 태양 교단 + 뿌리 + 명성 D 조합이 음수가 되지 않는지 필수 검증
- **공유 상한 +20%p**: `quest_success_rate_bonus` + `quest_success_rate_bonus_party_size`(조건 충족 시) **만** 공유 상한 적용. `investigation_success_rate_bonus`는 자체 20%p 상한 별도 풀(기획서 스태킹 규칙 3.1 표). `role_synergy`, `trait_synergy`는 PassiveBonusService 외부에서 처리
- **시그니처 호환성**: 모든 신규 파라미터는 `= 0.0` 또는 `= 1.0` 기본값 제공. 기존 호출부가 즉시 깨지지 않도록 함. 단계별 마이그레이션 가능
- **페이즈 4의 2/3/4 명세와의 중복 수정 주의**: QuestCalculator 시그니처는 본 명세(`factionPassiveBonus`) + 상성 명세(`roleSynergyBonus`) + 세력 퀘스트 명세(`trackRewardBonus`)가 **모두 변경함**. 구현 순서 1→2→3→4 또는 병합 시 merge conflict 대비
- **캐싱 미도입**: M1 범위에서는 매 호출 JSON 파싱 + 수집. 성능 이슈 관찰 시 M6 전역 재조정에서 도입
- **Hive 모델 변경 없음**: 본 명세는 static 데이터(Supabase)만 변경. Hive 박스 스키마는 그대로

### 4.3 엣지 케이스

- **세력 미가입 + F등급**: `joinedFactions`=[], `rankChain`=[F(bonus_json empty)] → `CollectedEffects` 빈 리스트. 모든 스태킹 결과 중립값(가산 0, 곱셈 1.0)
- **`all` + 특정 유형 중첩**: 기획서 섹션 3.2 규칙. `quest_type='all'` +0.03과 `quest_type='explore'` +0.08은 explore 퀘스트에서 **가산 결합** (+0.11)
- **Event_type 'all'**: TravelEventService에서 `damage`, `gold_loss` 모두에 가산
- **dispatch_slot_bonus 파싱 실패 시**: `value`가 float로 들어온 경우 int 변환 + 반올림. `value <= 0`은 무시
- **랭크 하향 (M2a 이후)**: 현재 M1은 상향만 처리. 하향은 `ReputationService.getCurrentRank()`가 자동으로 하위 랭크 반환 → `collect()`가 올바르게 축소된 rankChain 전달. 별도 처리 불요
- **적대 세력 (-100)**: 기존 `FactionStateRepository.getJoinedFactionIds()`는 `isJoined=true`만 반환. 적대 상태는 `isJoined=false`이므로 자동 제외
- **JSON 파싱 오류**: 알 수 없는 `type` 필드 → 해당 effect 무시 (throw 하지 않음). 경고 로그만

### 4.4 구현 힌트

- **진입점**: QuestCompletionService (기존 퀘스트 완료 시 보상/XP/명성 일괄 처리 지점)에서 PassiveBonusService 최초 호출 패턴 확립. 다른 서비스도 동일 패턴으로 확장
- **데이터 흐름**:
  ```
  FactionStateRepository.getJoinedFactionIds()
    → staticDataProvider.factions에서 해당 FactionData 조회
    → Rank 정적 데이터 + ReputationService.getCurrentRank() → rankChain
    → PassiveBonusService.collect(joinedFactions, currentRank, rankChain) → CollectedEffects
    → 각 서비스별 effectiveMultiplier(type, ...) 호출
    → 반환값을 기존 서비스 파라미터로 주입
  ```
- **참조 구현**:
  - `quest_completion_service.dart:125~141` — 훈련소 시설 보너스를 외부 계산 후 `ExperienceService.calculateXpGain`에 주입하는 기존 패턴. `PassiveBonusService`도 동일 스타일 적용
  - `trait_acquisition_service.dart` `_meetsCondition` — `reductionPercent` 임계값 완화 로직 그대로 `passiveRelief`와 결합
  - `faction_state_repository.dart` — `getJoinedFactionIds()` 이미 구현됨, 그대로 활용
- **확장 지점**:
  - `PassiveEffect.fromJson`의 type discriminator switch — 향후 효과 타입 추가 시 여기와 `PassiveBonusService.effectiveMultiplier` switch 2곳만 수정
  - operation-bom 편집 UI 추가 시 동일 JSON 스키마로 호환

### 4.5 마이그레이션 SQL 초안

```sql
-- 20260418_ranks_bonus_json.sql
BEGIN;

-- 1. ranks 스키마 확장
ALTER TABLE ranks ADD COLUMN IF NOT EXISTS bonus_json JSONB NOT NULL DEFAULT '{"effects": []}'::jsonb;

-- 2. E 임계값 하향 (C1)
UPDATE ranks SET required_reputation = 300 WHERE grade = 'E';

-- 3. 6개 등급 bonus_json 입력 (수치 조정안 기준)
UPDATE ranks SET bonus_json = '{"effects":[]}'::jsonb WHERE grade = 'F';
UPDATE ranks SET bonus_json = '{"effects":[{"type":"recruitment_cost_reduction","value":0.10}]}'::jsonb WHERE grade = 'E';
UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"all","value":0.03},{"type":"recovery_time_reduction","status":"injured","value":0.10}]}'::jsonb WHERE grade = 'D';
UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.03},{"type":"dispatch_slot_bonus","value":1}]}'::jsonb WHERE grade = 'C';
UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"all","value":0.07},{"type":"idle_reward_bonus","bonus_type":"rate","value":0.15},{"type":"trait_acquisition_condition_relief","value":0.10},{"type":"quest_success_rate_bonus","quest_type":"all","value":0.02}]}'::jsonb WHERE grade = 'B';
UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.05},{"type":"facility_cost_reduction","cost_type":"time","value":0.10},{"type":"mercenary_xp_bonus","value":0.15},{"type":"dispatch_slot_bonus","value":1}]}'::jsonb WHERE grade = 'A';

-- 4. 14개 세력 passive_bonus_json 최종 수치 (P1~P4 반영)
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"explore","value":0.12}]}'::jsonb WHERE id = 'faction_adventurers_guild';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"escort","value":0.12},{"type":"idle_reward_bonus","bonus_type":"rate","value":0.10}]}'::jsonb WHERE id = 'faction_merchants_alliance';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"raid","value":0.05},{"type":"quest_success_rate_bonus","quest_type":"hunt","value":0.05}]}'::jsonb WHERE id = 'faction_warriors_guild';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"travel_event_mitigation","event_type":"gold_loss","value":0.30},{"type":"investigation_success_rate_bonus","value":0.05}]}'::jsonb WHERE id = 'faction_thieves_guild';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"explore","value":0.08},{"type":"trait_acquisition_condition_relief","value":0.10}]}'::jsonb WHERE id = 'faction_mage_towers';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"escort","value":0.08},{"type":"recovery_time_reduction","status":"injured","value":0.15}]}'::jsonb WHERE id = 'faction_sun_order';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.03}]}'::jsonb WHERE id = 'faction_balance_watchers';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"trait_evolution_condition_relief","value":0.15}]}'::jsonb WHERE id = 'faction_forbidden_archive';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"travel_event_mitigation","event_type":"damage","value":0.40},{"type":"recovery_time_reduction","status":"injured","value":0.15}]}'::jsonb WHERE id = 'faction_root_oath';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"facility_cost_reduction","cost_type":"gold","value":0.10},{"type":"facility_effect_bonus","facility_id":null,"value":0.05}]}'::jsonb WHERE id = 'faction_twilight_artificers';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"facility_cost_reduction","cost_type":"time","value":0.20}]}'::jsonb WHERE id = 'faction_deep_hammer';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"raid","value":0.15}]}'::jsonb WHERE id = 'faction_volcanic_heart';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"recruitment_tier_boost","tier_min":4,"tier_max":5,"value":0.04}]}'::jsonb WHERE id = 'faction_blood_council';
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus_party_size","min_party_size":3,"value":0.08}]}'::jsonb WHERE id = 'faction_fang_brotherhood';

-- 5. data_versions 버전 증가
UPDATE data_versions SET version = version + 1 WHERE table_name IN ('ranks', 'factions');

COMMIT;
```

## 5. 기획 확인 사항

- [Q-1] `PassiveEffect` 모델을 Freezed sealed class (옵션 A, 16 variants) vs `class + type enum + Map` (옵션 B) 중 어느 쪽으로 진행? → **FR-3 권장: 옵션 A**. 타입 안전성이 중요하고 16개는 관리 가능한 규모.
- [Q-2] `recruitment_cost_reduction`을 `recruit_screen.dart`에 한정해 적용할지, 향후 "재모집" 등 다른 유료 모집에도 범용으로 설계할지? → 본 명세는 `RecruitmentService.effectivePaidCost(int baseCost, double costReduction)` 범용 static 헬퍼로 설계하여 확장 가능.
- [Q-3] `mercenary_xp_bonus`의 스태킹 방식 — 기획서는 "훈련소와 중첩 가산"이나 훈련소 효과가 이미 로그 스케일 배수(`+0.80`)로 복잡. 가산 스태킹(`total = 1 + training + passive`)으로 확정? → **확정: 가산**. `20260417_rank_bonuses_values.md` 분석 8에 따름.
- [Q-4] `investigation_success_rate_bonus`의 공유 상한 풀은 `quest_success_rate_bonus`와 **동일 풀인지 별도 풀인지**? → **기획서 섹션 3.1 표 기준: 별도 풀** (둘 다 +0.20 상한이지만 독립). 본 명세 FR-5의 `cappedInvestigationSuccessBonus`가 자체 상한만 적용.
- [Q-5] `dispatch_slot_bonus` 가산 상한 +10의 적용 레이어 — 명성+세력만 합산해서 +10인지, 정보망 시설과 합산해서 +10인지? → **기획서 분석 3 권장: 명성+세력 합산에만 +10 적용**. 정보망(+8)과는 별도. 최종 슬롯 = 1 + 정보망 + min(명성+세력, 10) = 최대 1 + 8 + 10 = 19. **단 주둔지 용량과 주문 풀 자연 제약으로 실효 11 근처 유지.**

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260418_passive-bonus-service.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 수정 16개 + 신규 5개 = **21개** | **대규모** |
| 영향 시스템 | 퀘스트/세력/명성/용병(3종)/시설/이동/방치 = **7개 시스템** | **대규모** |
| 신규 클래스 | `PassiveEffect`(sealed, 16 variant), `PassiveBonusService`, `PassiveBonusFormatter` = **3개** | **대규모** (경계선) |
| 데이터 모델 | `ranks.bonus_json` 신규 컬럼 + 세력/랭크 대량 UPDATE + `PassiveEffect` 모델 신규 | **대규모** |
| UI 작업 | `FactionDetailScreen` 섹션 포맷 교체 (기존 위젯 수정) | **소규모** |
| 기존 시스템 변경 | 6개 도메인 서비스 시그니처 확장 + 호출부 2군데 | **대규모** |

**추천: implement-agent** (5/6점)
- 7개 시스템에 걸친 시그니처 변경 + 신규 서비스 도입 + Supabase 스키마 변경이 동시 진행되므로 analyzer→architect→coder→verifier 파이프라인 권장

```
구현을 진행하려면 아래 명령어를 실행해주세요:

/implement-agent @Docs/spec/[spec]20260418_passive-bonus-service.md  ← 추천 (파이프라인)
/implement-spec @Docs/spec/[spec]20260418_passive-bonus-service.md  (올인원, 비추천)
```
