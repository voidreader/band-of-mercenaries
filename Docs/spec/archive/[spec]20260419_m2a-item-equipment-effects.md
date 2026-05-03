# M2a 장비 장착/해제 + 효과 적용 개발 명세서

> 기획 문서:
> - `Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure.md` (인프라 — 이미 구현됨)
> - `Docs/balance-design/20260418_equipment_stats.md` (개인 장비 스탯·전설 유니크 효과 5카테고리)
> - `Docs/balance-design/20260418_guild_equipment_macro.md` (용병단 장비 거시 지표·신규 효과 2종)
>
> 작성일: 2026-04-19
> 유형: M2a 마일스톤 페이즈 4 산출물 2/3 (장착/효과)
> 후속 명세: 정수 사용(페이즈 4 산출물 3)

---

## 1. 개요

M2a 인프라 뼈대(페이즈 4 산출물 1)가 구축한 `ItemData` / `InventoryItem` / `InventoryRepository` / `UserData.bannerItemId·artifactItemIds` 위에, **장비 효과를 실제 게임 공식에 주입**하는 서비스 · UI · 공식 확장을 구현한다. 본 명세는 다음을 다룬다.

- `ItemEffectService` 신설 — `effect_json`을 카테고리·슬롯·티어 기준으로 파싱하여 (a) 용병별 스탯 보정, (b) 전설 유니크 효과 5 카테고리, (c) 용병단 장비 거시 지표 효과를 구조화된 값 객체로 변환.
- `Mercenary.effective*` 재계산 경로 — 기존 getter는 유지하되, **장비 보정을 주입받는 메서드**를 신설하여 `QuestCalculator.calculatePartyPower` 진입 직전에 장비 보정이 합산되도록 한다.
- 용병 상세 오버레이에 **개인 장비 슬롯 그리드** 추가 — `TraitSlotGrid`와 동일한 패턴. 각 슬롯 탭 → 보유 미장착 아이템 목록에서 선택 → `InventoryRepository.setEquippedTo` 호출.
- 정보 탭에 **용병단 장비 화면** 신규 — banner 1슬롯 + artifact 3택2 구조. 각 슬롯 탭 → 보유 미장착 아이템 목록에서 선택 → `UserData.bannerItemId` / `artifactItemIds` 갱신.
- 전설 유니크 효과 5 카테고리 분기 구조 — ① `success_rate_bonus` · ③ `damage_resistance`는 `TraitEffectService` 기존 경로 재사용, ② `result_upgrade` · ④ `reward_bonus` · ⑤ `special`은 각각 `QuestCalculator.determineResult` · `QuestCalculator.calculateReward` · `QuestCompletionService.calculate`에 로직 추가.
- `PassiveBonusService` 확장 — 효과 타입 16 → 18개. 신규: `injury_rate_modifier`(곱셈 스태킹, 하한 0.10), `reputation_gain_modifier`(가산, 상한 +0.30). `collect()` 시그니처에 장비 소스(`personalEquipments`, `guildEquipments`) 인자 추가하여 세력·명성·장비 효과를 일괄 수집.
- `ReputationService.calculateQuestReputation()`에 `reputation_gain_modifier` 곱셈 적용.
- `PassiveEffect` freezed sealed 확장 + `PassiveBonusFormatter`에 신규 2종 한국어 표시 추가.

본 명세는 **수동 장비 지급 환경(M2a)** 에서 장비 효과를 검증하는 최소 구조이며, 드랍·제작·인챈트는 범위 외(M2b 이후).

---

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1. ItemEffectService 신설 — effect_json 파싱 경로

- 파일: `lib/features/inventory/domain/item_effect_service.dart` (신설).
- 역할: `ItemData.effectJson`을 카테고리·슬롯에 따라 구조화 값 객체로 변환.
- 제공 메서드 (모두 정적):

  ```dart
  // 개인 장비(personal_equipment) 1개의 스탯 보정 + 전설 유니크 효과를 반환.
  // category != 'personal_equipment'이면 빈 값 반환.
  static PersonalEquipmentEffect resolvePersonalEquipment(ItemData item);

  // 용병단 장비(guild_equipment) 1개의 거시 지표 효과를 PassiveEffect 리스트로 변환.
  // category != 'guild_equipment'이면 빈 리스트 반환.
  static List<PassiveEffect> resolveGuildEquipment(ItemData item);

  // 용병 1명에게 장착된 personal_equipment 전체의 스탯 보정을 합산.
  static EquipmentStatBonus aggregateMercenaryEquipment({
    required String mercenaryId,
    required List<InventoryItem> inventory,
    required List<ItemData> items,
  });

  // 용병 1명에게 장착된 personal_equipment 전체의 전설 유니크 효과 리스트.
  static List<LegendaryEffect> collectLegendaryEffects({
    required String mercenaryId,
    required List<InventoryItem> inventory,
    required List<ItemData> items,
  });

  // 용병단 장비(banner + artifactItemIds) 전체의 PassiveEffect 리스트.
  static List<PassiveEffect> collectGuildPassiveEffects({
    required String? bannerItemId,
    required List<String> artifactItemIds,
    required List<ItemData> items,
  });
  ```

- 값 객체:
  - `EquipmentStatBonus` — `{int str, int intelligence, int vit, int agi}` (freezed, 기본 0).
  - `PersonalEquipmentEffect` — `{EquipmentStatBonus statBonus, LegendaryEffect? legendary}`.
  - `LegendaryEffect` — sealed class, 5 카테고리 하위 variant (FR-4 참조).
- 파싱 규칙:
  - 개인 장비 스탯 키: `str`, `intelligence`, `vit`, `agi` (단일 키만 허용, 복수 키 무시하지 않고 모두 누적).
  - 전설 필드: `legendary_effect.category` 값으로 5 variant 분기.
  - 용병단 장비 키: `gold_reward_multiplier`, `recruit_high_tier_chance`, `injury_rate_modifier`, `reputation_gain_modifier` — 각각 `PassiveEffect` variant로 변환.
  - 알 수 없는 키는 무시(fail-soft).

#### FR-2. Mercenary 스탯 공식에 장비 보정 합산

- 파일: `lib/features/mercenary/domain/mercenary_model.dart`.
- 기존 getter (`effectiveStr`, `effectiveIntelligence`, `effectiveVit`, `effectiveAgi`)는 **그대로 유지** (하위 호환 + 장비 미적용 조회 경로용).
- 신규 메서드 추가 (인스턴스 메서드):

  ```dart
  int effectiveStrWith(EquipmentStatBonus bonus) {
    final withLevel = ((str + bonus.str) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired
        ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
        : withLevel;
  }
  // effectiveIntelligenceWith, effectiveVitWith, effectiveAgiWith 동일 패턴
  ```

- 공식: `effective = (base + equipment) × (1 + levelBonus) × fatigueMod`.
  - 정수(영구 스탯)는 본 명세 범위 외 — `permanentX` 항은 후속 명세(페이즈 4 산출물 3)에서 `(base + permanent + equipment)` 순서로 삽입됨. 본 명세에서는 `permanent` 자리에 0 고정.
- `QuestCalculator.calculatePartyPower` 시그니처 확장 — 선택적 `Map<String, EquipmentStatBonus>? mercEquipmentBonus` 파라미터 추가(키=mercId). null 또는 미포함 시 기존 getter 경로 유지(후방 호환).
- 호출 경로는 FR-6에서 명시.

#### FR-3. 장비 효과 수집 진입점 — Ref 헬퍼

- 파일: `lib/features/inventory/domain/equipment_effect_context.dart` (신설).
- 역할: `Ref` / `WidgetRef` 에서 용병 1명의 장비 보정을 일괄 계산. `PassiveBonusContext`와 동일 스타일.

  ```dart
  class EquipmentEffectContext {
    static Future<EquipmentStatBonus> forMercenary(Ref ref, String mercId);
    static Future<List<LegendaryEffect>> legendariesFor(Ref ref, String mercId);
    static Future<List<PassiveEffect>> guildEquipmentEffects(Ref ref);
    // 용병 파티 전체의 mercId → EquipmentStatBonus 맵.
    static Future<Map<String, EquipmentStatBonus>> forParty(
      Ref ref, List<String> mercIds,
    );
  }
  ```

- 내부 구현: `inventoryRepositoryProvider.getAll()` + `staticDataProvider.future.items` 조합 → `ItemEffectService` 위임.
- **동기 버전(UI 프리뷰용)** 도 제공:
  ```dart
  static EquipmentStatBonus forMercenarySync(WidgetRef ref, String mercId);
  ```
  staticDataProvider가 이미 로드된 상태(AsyncValue.data)에서만 호출 가능 — AsyncLoading/Error 시 zero bonus 반환.

#### FR-4. 전설 유니크 효과 5 카테고리 분기

각 카테고리별 값 객체(LegendaryEffect sealed variant)와 적용 경로:

| 카테고리 | variant | effect_json 필드 → Dart 필드 | 적용 경로 |
|:---:|:---:|---|---|
| ① `success_rate_bonus` | `LegendarySuccessRateBonus({questType, value})` | `{raid_success_rate, hunt_success_rate, escort_success_rate, explore_success_rate}` 중 1 | `TraitEffectService.calculateSuccessRateBonus` 경로에 가산. trait ±10%p 상한 공유 |
| ② `result_upgrade` | `LegendaryResultUpgrade({chance})` | `success_to_great_chance` | `QuestCalculator.determineResult` 확장 — 성공 판정 시 추가 roll로 대성공 승격 |
| ③ `damage_resistance` | `LegendaryDamageResistance({injuryMod, deathMod})` | `injury_rate_modifier`, `death_rate_modifier` | `TraitEffectService.calculateInjuryRateModifier` / `calculateDeathRateModifier` 경로에 가산 |
| ④ `reward_bonus` | `LegendaryRewardBonus({multiplier})` | `gold_reward_multiplier` | `QuestCalculator.calculateReward`의 `passiveRewardBonus`에 가산 후 +0.80 공유 상한 clamp |
| ⑤ `special` | `LegendarySpecial({deathPreventionCount, cooldownHours})` | `death_prevention_count`, `cooldown_hours` | `QuestCompletionService.calculate` 확장 — 사망 판정 시 소비 후 쿨다운 기록 |

- M2a에서는 전설 1종만 생성되므로 **5 카테고리 전부를 구현하되**, data-generator가 선택한 카테고리 1개만 실제 게임에 등장. 나머지 카테고리의 구현은 동일 구조를 갖지만 통합 테스트 없이 단위 테스트만 작성.
- ② `result_upgrade` 적용 로직:
  ```
  원본 roll로 성공 판정 → 성공인 경우 추가 roll(random.nextDouble()) ≤ chance이면 greatSuccess로 승격
  ```
  위 판정은 `QuestCompletionService.calculate` 내부에서 수행(결과 결정 직후, 보상 계산 전).
- ⑤ `special` death_prevention 적용 로직:
  ```
  데미지 판정 결과 = dead인 경우:
    user의 `legendaryDeathPreventionCooldownUntil`(Mercenary 신규 HiveField, FR-5) 확인
    - null 또는 now 이후면 쿨다운 사용 → newStatus = injured (부상 처리) + cooldownUntil = now + cooldownHours
    - 쿨다운 중이면 dead 유지
  ```
- ④ `reward_bonus`는 `LegendaryRewardBonus.multiplier`를 `QuestRewardMultiplierEffect(questType: 'all', value: ...)`로 변환하여 `PassiveBonusService` 경로에 흡수한다 (기존 +0.80 상한 공유 자동 적용).

#### FR-5. Mercenary 모델 확장 — 전설 ⑤ 쿨다운 상태

- 파일: `lib/features/mercenary/domain/mercenary_model.dart`.
- HiveField 추가:
  - `@HiveField(18) DateTime? legendaryDeathPreventionCooldownUntil` (nullable, 기본 null).
- 생성자 파라미터 추가. 기존 Hive 저장 데이터는 누락 시 null로 복원.
- 모델 마이그레이션 플래그 불필요(nullable 필드).
- 본 필드는 전설 ⑤ `special` 카테고리가 선택된 경우에만 실제 사용되지만, 모든 전설 카테고리가 구현되어야 하므로 필드 자체는 상시 존재.

#### FR-6. QuestCalculator / QuestCompletionService 경로 확장

- `QuestCalculator.calculatePartyPower` 시그니처:
  ```dart
  static int calculatePartyPower(
    List<Mercenary> mercs,
    String questTypeId, {
    Map<String, EquipmentStatBonus>? equipmentBonuses,
  });
  ```
  - null이면 기존 getter 사용, 있으면 `merc.effectiveStrWith(bonuses[merc.id] ?? zero)` 사용.
- `QuestCalculator.calculateSuccessRate` / `calculateSuccessRatePreview` / `calculateSuccessRateBreakdown`는 partyPower를 인자로 받으므로 자체 변경 없음.
- `QuestCalculator.calculateDamage` 시그니처 확장:
  ```dart
  static DamageResult calculateDamage({
    required double roll,
    required double deathRate,
    required double injuryRate,
    required String traitId,
    List<String> traitIds = const [],
    List<TraitData> allTraits = const [],
    List<LegendaryEffect> legendaryEffects = const [], // 신규
  });
  ```
  - `LegendaryDamageResistance` variant 필터링 → `injuryMod`/`deathMod` 가산. Trait 수정치와 동일 합산.
- `QuestCompletionService.calculate` 확장:
  - 파티 장비 보정 수집: `partyEquipmentBonuses = Map<mercId, EquipmentStatBonus>`.
  - 전설 효과 수집: 모든 파티원의 legendary effects + 용병단 장비의 legendary-like 효과(없음 — M2a 용병단 장비에는 legendary_effect 필드 없음).
  - `calculatePartyPower`에 장비 보정 전달.
  - `PassiveBonusService.collect()`에 장비 소스 전달(세력·명성과 일괄 수집).
  - 성공 판정 후 전설 ② variant 탐색 → `success_to_great_chance`로 대성공 승격 roll.
  - 데미지 판정에 전설 ③ 경로 전달(trait 수정치와 합산).
  - 데미지 결과 dead인 경우, 전설 ⑤ variant 탐색 → 쿨다운 확인·소비 → injured로 다운그레이드 시 `legendaryDeathPreventionCooldownUntil` 갱신을 `MercDamageResult`에 플래그로 전달(actual write는 호출측 notifier가 수행).
  - 부상률 계산에 `PassiveBonusService.getInjuryRateMultiplier()` 신규 메서드 적용(FR-7 참조):
    ```
    effectiveInjuryRate = difficulty.injuryRate
      × (1.0 - facilityInjuryReduction)
      × getInjuryRateMultiplier(passiveEffects)
    ```
    곱셈 스태킹. `getInjuryRateMultiplier`는 `(1 - Σ value).clamp(0.10, 1.0)` 반환. 이 결과가 `QuestCalculator.calculateDamage`의 `injuryRate` 파라미터로 전달됨.

#### FR-7. PassiveBonusService 확장 — 효과 타입 16 → 18, 장비 소스 통합

- 파일: `lib/core/domain/passive_bonus_service.dart`.
- `collect()` 시그니처 확장(하위 호환 유지):
  ```dart
  static CollectedEffects collect({
    required int reputation,
    required List<Rank> allRanks,
    required List<FactionData> joinedFactions,
    List<PassiveEffect> personalEquipmentLegendaries = const [], // 신규 (전설 ④만 이 경로로 진입, 나머지는 TraitEffectService/QuestCalculator 직접 경로)
    List<PassiveEffect> guildEquipments = const [],              // 신규
  });
  ```
  - `personalEquipmentLegendaries`는 `ItemEffectService.collectLegendaryEffects(...)` 결과 중 **④ `reward_bonus` variant만** `QuestRewardMultiplierEffect(questType: 'all', value)`로 변환하여 주입.
  - `guildEquipments`는 `ItemEffectService.collectGuildPassiveEffects(...)` 결과 전체를 그대로 주입.
  - `CollectedEffects`에 기존 세력·명성 effects 뒤에 append 추가.
- 신규 PassiveEffect variant 2종 (`lib/core/models/passive_effect.dart`):
  ```dart
  const factory PassiveEffect.injuryRateModifier({
    required double value,  // 음수 허용 (-0.07 등). 곱셈 스태킹: (1 + Σ).clamp(0.10, 1.0)
  }) = InjuryRateModifierEffect;

  const factory PassiveEffect.reputationGainModifier({
    required double value,  // +0.05 등. 가산, 상한 +0.30
  }) = ReputationGainModifierEffect;
  ```
  `fromJson` switch에 신규 type 처리 추가:
  - `'injury_rate_modifier'` → `InjuryRateModifierEffect(value: dbl('value'))`
  - `'reputation_gain_modifier'` → `ReputationGainModifierEffect(value: dbl('value'))`
- 신규 계산 메서드:
  ```dart
  // 곱셈 스태킹, 하한 0.10.  호출측: `baseInjuryRate × return`
  static double getInjuryRateMultiplier(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is InjuryRateModifierEffect) sum += e.value;
    }
    return (1.0 + sum).clamp(0.10, 1.0);
  }

  // 가산 스태킹, 상한 +0.30.  호출측: `× (1 + return)`
  static double getReputationGainModifier(CollectedEffects ce) {
    double sum = 0.0;
    for (final e in ce.effects) {
      if (e is ReputationGainModifierEffect) sum += e.value;
    }
    return sum.clamp(0.0, 0.30);
  }
  ```
- 주의: guild equipment의 `gold_reward_multiplier`는 `QuestRewardMultiplierEffect(questType: 'all', value)`로 변환되어 기존 `getQuestRewardMultiplier` 경로를 재사용. 별도 variant 추가 불필요.
- guild equipment의 `recruit_high_tier_chance`는 기존 `RecruitmentTierBoostEffect(tierMin: 4, tierMax: 5, value)`로 변환 후 편입.

#### FR-8. PassiveBonusFormatter 확장

- 파일: `lib/core/domain/passive_bonus_formatter.dart`.
- `format(PassiveEffect e)` switch에 2 variant 추가:
  - `InjuryRateModifierEffect` → `"부상률 {×100}%"` (부호 그대로, 음수면 감소 표시)
  - `ReputationGainModifierEffect` → `"명성 획득 +{×100}%"`

#### FR-9. ReputationService 확장 — 명성 획득 수정자 적용

- 파일: `lib/core/domain/reputation_service.dart`.
- `calculateQuestReputation` 시그니처 확장(기본값 0.0으로 하위 호환):
  ```dart
  static int calculateQuestReputation({
    required int difficulty,
    required bool isGreatSuccess,
    double reputationGainModifier = 0.0, // 신규
  }) {
    final base = difficulty * (isGreatSuccess ? 20 : 10);
    return (base * (1.0 + reputationGainModifier.clamp(0.0, 0.30))).round();
  }
  ```
- `QuestCompletionService.calculate` 내부에서 `PassiveBonusService.getReputationGainModifier(passiveEffects)` 결과를 전달.

#### FR-10. 용병 상세 오버레이 — 개인 장비 슬롯 UI

- 파일: `lib/features/mercenary/view/mercenary_detail_overlay.dart` (수정).
- 위치: 기존 `TraitSlotGrid`(라인 125-129) **바로 위**에 신규 `EquipmentSlotGrid` 추가 (용병 능력 핵심 정보 → 장비 → 트레잇 순서).
- 신규 위젯: `lib/features/mercenary/view/equipment_slot_grid.dart`.
- 구조:
  - 6개 시각 슬롯(weapon / armor / helmet / boots / accessory 1 / accessory 2). 내부 slot 값은 accessory 1·2 모두 `slot='accessory'`로 저장.
  - 레이아웃: `Wrap(spacing: 6, runSpacing: 6)` + `FractionallySizedBox(widthFactor: 0.5)` (2열 3행, TraitSlotGrid 패턴 재사용).
  - 슬롯 카드 내용: 슬롯 아이콘·한글 라벨 / 장착된 `ItemData.name` / 티어 색상(`AppTheme`의 tier1~5 컬러) / tap → 장착 시트.
  - 빈 슬롯: 점선 테두리.
- 장착 시트(`showModalBottomSheet`): 해당 slot + 미장착(`equippedTo == null`) 조건 충족 개인 장비 목록 + "해제" 옵션. 선택 시:
  1. 기존 장착 아이템 있으면 `setEquippedTo(oldId, null)` 해제.
  2. 선택 아이템 `setEquippedTo(newId, mercenaryId)` 장착.
  3. `inventoryRepositoryProvider` 무효화 트리거로 UI 갱신.
- accessory 슬롯 구분: `getEquippedBy(mercenaryId)` 결과에서 `slot == 'accessory'`인 것을 `id` 오름차순으로 정렬하여 첫 번째 = accessory 1, 두 번째 = accessory 2로 시각 배치.

#### FR-11. 정보 탭 — 용병단 장비 진입점 + 화면 신설

- 파일 수정: `lib/features/info/view/info_screen.dart`.
- 기존 `_showCodex` / `_showRank`와 동일 패턴으로 `_showGuildEquipment` 상태 추가.
- ListTile 3번째 항목 추가:
  - 아이콘: `Icons.flag`
  - 제목: `용병단 장비`
  - 부제: `깃발 1 + 유물 2 장착 슬롯`
  - onTap: `_showGuildEquipment = true`
- 파일 신설: `lib/features/info/view/guild_equipment_screen.dart`.
- 구조:
  - 상단: 헤더 + 뒤로가기.
  - 본문: 3개 슬롯 카드 세로 배치.
    - 슬롯 1: banner — `UserData.bannerItemId`.
    - 슬롯 2·3: artifact — `UserData.artifactItemIds[0]`, `artifactItemIds[1]` (index 존재 여부로 분기).
  - 각 슬롯 카드: 이미지/아이콘, 장착된 `ItemData.name`, 효과 요약(`PassiveBonusFormatter` 활용), tap → 교체 시트.
- 교체 시트: `showModalBottomSheet` — 보유 guild_equipment 중 해당 slot(`banner` 또는 `artifact`) 일치 목록 + 해제. artifact 선택 시 이미 다른 artifact 슬롯에 장착된 아이템은 "장착 중(슬롯 N)" 표시 + 선택 시 해당 슬롯에서 자동 이동. artifact 중복 장착(동일 `itemId`가 두 슬롯 모두에 들어감) 방지를 위해 기존 장착 슬롯에서 제거 후 타겟 슬롯에 삽입.
- 교체 시 변동 프리뷰: 효과 변화를 before/after 라인으로 표시(`PassiveBonusFormatter.format`).
- 복합 효과(깃발의 `reputation_gain_modifier` + `gold_reward_multiplier`) 분해 표시: `PassiveBonusFormatter`가 각 라인 별도 반환하므로 자연 분해.
- 저장 경로:
  ```dart
  // UserDataNotifier에 신규 메서드 (lib/core/providers/user_data_provider.dart 수정)
  Future<void> setGuildBanner(String? itemId);
  Future<void> setGuildArtifact(int slotIndex, String? itemId); // 0 or 1
  ```
  - `bannerItemId` 단순 치환.
  - `artifactItemIds`는 길이 2 보장 리스트로 관리. 비어 있으면 빈 리스트로 저장, 1개면 [id], 2개면 [id1, id2]. UI는 null 스팟을 "빈 슬롯"으로 렌더.

#### FR-12. 파티 능력치 프리뷰 — 파견 UI

- 파일 수정: `lib/features/quest/view/dispatch_detail_page.dart` (기존).
- 용병 선택 후 `SuccessRateBreakdownSheet`에 전달되는 `partyPower` 계산 시 **장비 보정을 반영**하도록 수정:
  - `EquipmentEffectContext.forPartySync(ref, selectedMercIds)`로 장비 보정 수집.
  - `QuestCalculator.calculatePartyPower(mercs, questType, equipmentBonuses: ...)` 호출.
- 본 명세는 UI 세부 변경(장비 기여 분해 표시 등)을 포함하지 않는다. 단순히 성공률 계산만 정확해지면 충분. 기여 분해 UI는 후속 UX 개선 과제.

### 2.2 데이터 요구사항

**수정 Hive 모델:**
- `Mercenary`(`typeId: 2`) — `@HiveField(18) DateTime? legendaryDeathPreventionCooldownUntil` 추가. 기존 HiveField 0~17 불변. 누락 필드는 null로 복원.

**신규 freezed 모델:**
- `EquipmentStatBonus` (`lib/features/inventory/domain/equipment_stat_bonus.dart`) — `{int str, int intelligence, int vit, int agi}`, 기본 0 + `+` 연산자 오버로드.
- `LegendaryEffect` sealed (`lib/features/inventory/domain/legendary_effect.dart`) — 5 variant (SuccessRateBonus / ResultUpgrade / DamageResistance / RewardBonus / Special).
- `PersonalEquipmentEffect` — `{EquipmentStatBonus statBonus, LegendaryEffect? legendary}`.

**수정 freezed 모델:**
- `PassiveEffect` (`lib/core/models/passive_effect.dart`) — `injuryRateModifier` · `reputationGainModifier` variant 2종 추가.

**데이터 변경 없음:**
- Supabase 테이블 변경 없음 (`items` 테이블은 인프라 명세에서 생성 완료).
- 용병단 장비 4종 / 개인 장비 6종의 실제 데이터 적재는 data-generator 페이즈 3에서 처리(별도 명세 외).

### 2.3 UI 요구사항

Visual Companion 생략(기존 패턴 재사용 비중이 높고 텍스트 명세로 충분). 텍스트 기반 명세:

**A. 용병 상세 오버레이 — 개인 장비 슬롯 그리드**
- 화면 진입 조건: `selectedMercenaryIdProvider` non-null.
- 위젯 계층: 기존 오버레이 `Column > [헤더, 프로필, EquipmentSlotGrid(신규), TraitSlotGrid, 상성, BehaviorStatsSection, TraitHistorySection]`.
- 상태 변수: 기존 오버레이 상태 재사용. 장착 시트는 modal bottom sheet.
- 화면 전환: 상태 기반 렌더링 (Navigator.push 금지).
- 연출: 장착 직후 슬롯 카드의 tier color가 페이드인(선택적, 200ms). 간단 `AnimatedSwitcher`.

**B. 정보 탭 — 용병단 장비 화면**
- 화면 진입 조건: 정보 탭의 `용병단 장비` ListTile 탭.
- 위젯 계층: `GuildEquipmentScreen > Column > [헤더, 슬롯 카드 × 3 (banner, artifact 1, artifact 2)]`.
- 상태 변수: `InfoScreen._showGuildEquipment` (bool). `GuildEquipmentScreen` 내부 상태 없음(시트로 처리).
- 화면 전환: 상태 기반 렌더링 (기존 `_showCodex` 패턴 동일).

**C. 장착 시트 (공통 패턴)**
- `showModalBottomSheet(isScrollControlled: true)`.
- 헤더: 슬롯 이름, 닫기 버튼.
- 리스트: 현재 장착 아이템(상단 하이라이트) → 미장착 목록 → "해제" 버튼.
- 아이템 카드: 이름, 티어 뱃지, `effect_json` 해석 한 줄 요약.
- 탭 → 해당 메서드 호출 → 시트 자동 닫힘.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | `@HiveField(18) legendaryDeathPreventionCooldownUntil` 추가 + `effectiveStrWith` 등 4개 메서드 추가 | FR-2, FR-5 |
| `band_of_mercenaries/lib/core/models/passive_effect.dart` | `InjuryRateModifierEffect` · `ReputationGainModifierEffect` variant + `fromJson` 2 case 추가 | FR-7 |
| `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart` | `collect()` 시그니처 확장 + `getInjuryRateMultiplier` / `getReputationGainModifier` 추가 | FR-7 |
| `band_of_mercenaries/lib/core/domain/passive_bonus_formatter.dart` | 신규 2 variant의 `format` case 추가 | FR-8 |
| `band_of_mercenaries/lib/core/domain/reputation_service.dart` | `calculateQuestReputation`에 `reputationGainModifier` 파라미터 추가 | FR-9 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | `calculatePartyPower` equipmentBonuses 파라미터 + `calculateDamage` legendaryEffects 파라미터 | FR-6 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 장비 보정/전설 수집 로직 + ② 대성공 승격 + ⑤ 쿨다운 소비 + 부상률 곱셈 적용 + 명성 수정자 적용 | FR-6, FR-9 |
| `band_of_mercenaries/lib/core/providers/user_data_provider.dart` | `setGuildBanner`, `setGuildArtifact(slotIndex, itemId)` 메서드 추가 | FR-11 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | `EquipmentSlotGrid` 위젯 삽입 | FR-10 |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | `_showGuildEquipment` 상태 + ListTile 3번째 + 분기 추가 | FR-11 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | partyPower 계산에 장비 보정 반영 | FR-12 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/lib/features/inventory/domain/item_effect_service.dart` | `ItemEffectService` — effect_json 파싱 + 수집 |
| `band_of_mercenaries/lib/features/inventory/domain/equipment_stat_bonus.dart` | `EquipmentStatBonus` freezed 값 객체 |
| `band_of_mercenaries/lib/features/inventory/domain/legendary_effect.dart` | `LegendaryEffect` sealed + 5 variant |
| `band_of_mercenaries/lib/features/inventory/domain/equipment_effect_context.dart` | `Ref/WidgetRef` 헬퍼 |
| `band_of_mercenaries/lib/features/mercenary/view/equipment_slot_grid.dart` | 개인 장비 6슬롯 그리드 위젯 |
| `band_of_mercenaries/lib/features/mercenary/view/equipment_equip_sheet.dart` | 공통 장착 시트 위젯 |
| `band_of_mercenaries/lib/features/info/view/guild_equipment_screen.dart` | 용병단 장비 3슬롯 화면 |
| `band_of_mercenaries/lib/features/info/view/guild_equipment_equip_sheet.dart` | 용병단 장비 장착 시트 |
| `band_of_mercenaries/test/features/inventory/domain/item_effect_service_test.dart` | ItemEffectService 단위 테스트 (5 카테고리 포함) |
| `band_of_mercenaries/test/core/domain/passive_bonus_service_equipment_test.dart` | PassiveBonusService 장비 소스 통합 테스트 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_legendary_test.dart` | 전설 ② / ③ / ⑤ 적용 결정론 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `lib/features/mercenary/domain/mercenary_model.dart` | hive_generator (HiveField 18 추가) |
| `lib/features/inventory/domain/equipment_stat_bonus.dart` | freezed |
| `lib/features/inventory/domain/legendary_effect.dart` | freezed (sealed 5 variant) |
| `lib/core/models/passive_effect.dart` | freezed (2 variant 추가) |

구현 완료 후 `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 실행 필수.

### 3.4 관련 시스템

- **인벤토리 인프라**: 본 명세의 선행 산출물(인프라 뼈대)에 의존. `InventoryRepository.setEquippedTo` / `getEquippedBy` / `UserData.bannerItemId` / `artifactItemIds`를 그대로 사용.
- **PassiveBonusService 효과 일괄 수집**: 세력·명성 기반 → 장비 소스 포함으로 확장. 기존 `PassiveBonusContext`의 Ref 헬퍼와 유사하게 `EquipmentEffectContext` 신설.
- **TraitEffectService**: 전설 ① `success_rate_bonus` · ③ `damage_resistance`는 이 서비스 **호출측**에서 legendary bonus를 trait bonus와 합산하여 전달(서비스 자체 시그니처 미변경). 구체적으로:
  - ① 성공률: `QuestCompletionService`에서 trait 결과값 + 전설 ① 값 합산 → `clamp(-10.0, 10.0)` 재적용.
  - ③ 부상률/사망률: `QuestCalculator.calculateDamage`가 `legendaryEffects` 파라미터로 수집 후 trait mod와 합산.
- **QuestCalculator·QuestCompletionService**: 성공률·보상·부상률·결과 판정 경로에 진입하는 장비 효과는 모두 본 명세에서 설계된 경로를 따른다.
- **Mercenary 모델 HiveField 최대**: 현재 17 → 18로 확장. `CLAUDE.md` HiveField 순차 할당 규칙 준수.
- **정보 탭**: 기존 `세력 도감` / `명성`에 `용병단 장비` 3번째 진입점 추가.
- **본 명세 범위 외**:
  - data-generator(페이즈 3) — 실제 6개 개인 장비 + 4개 용병단 장비 Supabase 적재.
  - 정수 시스템(페이즈 4 산출물 3) — 영구 스탯 강화.
  - 드랍·제작·인챈트·효과 축 확장(M2b·M4).
  - 용병별 equipmentBonus 캐싱(현 설계는 모든 프리뷰·계산에서 매 회 재계산; M3 이후 성능 요구 발생 시 캐싱 도입).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **PassiveEffect sealed class + fromJson switch**: `lib/core/models/passive_effect.dart:92-172`. 신규 2 variant 추가 시 동일 스타일(`type` discriminator + `dbl/integer/str` 헬퍼) 따름.
- **PassiveBonusService 스태킹**: `lib/core/domain/passive_bonus_service.dart:129-150` (회복 시간 · 시설 비용 — 곱셈 스태킹 패턴), `:79-101` (성공률 — 가산 + clamp). 신규 `getInjuryRateMultiplier`는 회복 시간과 동형, `getReputationGainModifier`는 단순 가산 + 상한.
- **PassiveBonusContext Ref 헬퍼**: (프로젝트 내 검색 필요) — `EquipmentEffectContext`도 동일 스타일로 Ref에서 여러 Provider를 조합.
- **TraitSlotGrid 레이아웃**: `lib/features/mercenary/view/trait_slot_grid.dart:128-140` — `Wrap(spacing: 6, runSpacing: 6) + FractionallySizedBox(widthFactor: 0.5)`로 2열 그리드. `EquipmentSlotGrid`에 그대로 차용.
- **Mercenary 모델 getter 구조**: `lib/features/mercenary/domain/mercenary_model.dart:104-124` — level 보너스 × 피로 디버프 체인. `effectiveStrWith` 계열은 동일 체인에 `(str + bonus.str)` 교체만 수행.
- **정보 탭 상태 기반 네비게이션**: `lib/features/info/view/info_screen.dart:17-48` — `_showCodex` / `_showRank` / `_selectedFactionId` 분기 우선순위. `_showGuildEquipment`를 `_showRank` 뒤에 동일 패턴으로 추가.
- **InventoryRepository setEquippedTo**: `lib/features/inventory/data/inventory_repository.dart:105-110` — 장착 설정은 `InventoryItem.equippedTo` 단순 치환 후 `box.save()`.
- **freezed sealed 패턴**: `lib/core/models/passive_effect.dart` — `@freezed sealed class ... with _$...`. `LegendaryEffect`도 동일 구조.

### 4.2 주의사항

- **HiveField 번호 순차 할당**: `Mercenary.legendaryDeathPreventionCooldownUntil`은 반드시 18(현재 최대 17 직후). `CLAUDE.md` "HiveField 번호 규칙" 준수.
- **기존 Hive 데이터 호환**: `legendaryDeathPreventionCooldownUntil`은 nullable이며, 기존 저장 데이터는 누락 시 null로 복원되어 마이그레이션 플래그 불필요(기존 `stat_migration_v2` 같은 조치 없음).
- **`PassiveBonusService.collect()` 시그니처 확장 시 하위 호환**: 신규 두 인자(`personalEquipmentLegendaries` · `guildEquipments`)는 기본값 `const []` 제공. 기존 호출부는 무변경.
- **전설 ④ `reward_bonus`의 중복 누적 금지**: `QuestRewardMultiplierEffect`로 변환되어 `PassiveBonusService.getQuestRewardMultiplier`에 편입되므로, `QuestCompletionService.calculate` 내에서 전설 ④를 **별도 경로로 이중 가산하지 않도록** 주의.
- **부상률 곱셈 vs 가산 구분**:
  - 기존: `trait.injury_rate` (가산, `calculateDamage` 내부).
  - 신규 guild equipment `injury_rate_modifier` (곱셈, `PassiveBonusService.getInjuryRateMultiplier`).
  - 전설 ③ `damage_resistance.injury_rate_modifier` (가산, trait과 동형).
  - **동일 키 이름이지만 적용 스태킹이 다름**. 각 소스가 어느 경로로 진입하는지 `ItemEffectService`가 명확히 분기.
- **accessory 슬롯 구분**: 개인 장비의 accessory 슬롯은 `slot='accessory'` 단일 값이며, 인벤토리 상에서 2개의 동일 `slot` 아이템이 한 용병에 장착될 수 있음. UI는 정렬 순서로 1·2를 구분하므로 장착·해제 시 동일 `slot` 중복 장착 제한(2개 초과 금지)을 UI 레벨에서 검증.
- **`avoid_print` 린트**: 디버그 출력은 `debugPrint` 사용.
- **`ConstrainedBox(maxWidth: 430)` 제약**: 용병 상세 오버레이 · 용병단 장비 화면 모두 기존 `_MobileFrame` 내부에 위치 — Navigator.push 금지, 상태 기반 전환만 사용.
- **한국어 코멘트**: 주석·도움말 텍스트는 한국어 기본(CLAUDE.md 언어 설정).

### 4.3 엣지 케이스

- **장착 아이템의 인벤토리 삭제**: 본 명세 범위 내에서는 `InventoryRepository.removeItem`을 호출하지 않지만, 외부 경로(후속 명세)에서 삭제 시 `equippedTo != null`이면 호출자 책임(infrastructure 명세 엣지 케이스). UI 장착 시트는 현재 장착된 아이템이 여전히 인벤토리에 존재한다는 전제.
- **개인 장비 accessory 슬롯 3개 이상 시도**: UI에서 이미 2개 장착 시 세 번째 장착 버튼을 비활성화(disabled state). 장착 시트 열 때 count 검증.
- **같은 guild artifact 동일 `itemId` 중복 장착 시도**: UI가 "이미 슬롯 N에 장착 중" 표시 + 해당 슬롯에서 제거 후 타겟 슬롯에 삽입(이동). 동일 아이템이 두 슬롯에 동시 존재하지 않음을 `setGuildArtifact` 호출 순서로 보장.
- **개인 장비 `effect_json`에 스탯 키 0개**: `ItemEffectService.resolvePersonalEquipment`는 모든 스탯 0 + legendary null 반환. UI는 "효과 없음" 표시. (data-generator 데이터 품질 문제지만 fail-soft.)
- **전설 ⑤ 쿨다운 중 다시 사망 판정**: 쿨다운 만료 전이면 death 원본 유지. 유저가 그 사이 전설을 해제하면 쿨다운 필드는 유지(해제한다고 쿨다운이 리셋되지 않음). 재장착 시 기존 쿨다운 존중.
- **전설 ② 대성공 승격과 ④ 보상 가산 동시 적용**: ②가 먼저 resultType을 변경한 후 ④가 `passiveRewardBonus`에 가산 → 기존 `(trackBonus + passiveRewardBonus).clamp(0, 0.80)` 경로에서 자연 통합. 이중 계산 없음.
- **`reputation_gain_modifier` 상한 초과 누적**: 가산 후 `clamp(0.0, 0.30)`. 초과분은 손실(UI는 초과 여부를 표시하지 않음 — M2a 범위 외).
- **빈 파티로 partyPower 계산**: 기존 로직(`mercs.isEmpty → 0`)과 동일. `equipmentBonuses` 맵이 있어도 파티 크기 0이면 0 반환.
- **`staticDataProvider`가 AsyncLoading인 상태에서 UI 프리뷰 호출**: `EquipmentEffectContext.forMercenarySync` 동기 버전은 `ref.read(staticDataProvider).valueOrNull`로 접근, null이면 zero bonus 반환 → UI는 장비 미적용 상태로 프리뷰. 실제 파견 실행 시점에는 `await ref.read(staticDataProvider.future)` 경로를 통해 정확히 계산.

### 4.4 구현 힌트

- **진입점 (장비 효과 주입)**:
  - 파견 성공률 프리뷰 — `DispatchDetailPage` → `EquipmentEffectContext.forPartySync` → `QuestCalculator.calculatePartyPower(equipmentBonuses: ...)` → `calculateSuccessRatePreview`.
  - 파견 완료 계산 — `QuestCompletionService.calculate` → 파티 장비 / 전설 수집 → `calculatePartyPower` + `calculateDamage(legendaryEffects: ...)` + `getInjuryRateMultiplier` + `getReputationGainModifier`.
  - 용병단 장비 장착 — `GuildEquipmentScreen` → `UserDataNotifier.setGuildArtifact(slotIndex, itemId)` → `UserData.artifactItemIds` 갱신 → 다음 사이클부터 `PassiveBonusService.collect(guildEquipments: ...)`에 반영.
  - 개인 장비 장착 — `EquipmentSlotGrid` 탭 → `InventoryRepository.setEquippedTo(newId, mercId)` → 다음 파견 계산 시 자동 반영.

- **데이터 흐름 (장비 효과)**:
  - ItemData(Supabase) → JSON 캐시 → `StaticGameData.items` → `ItemEffectService.resolve*` → 값 객체(EquipmentStatBonus / LegendaryEffect / PassiveEffect) → QuestCalculator / QuestCompletionService / PassiveBonusService.
  - 장착 상태 → `InventoryRepository.getEquippedBy(mercId)` + `UserData.bannerItemId / artifactItemIds` → `ItemEffectService.aggregate*` → 위와 합류.

- **참조 구현**:
  - PassiveEffect fromJson switch 확장: `lib/core/models/passive_effect.dart:100-170` — 신규 type 2개는 같은 양식으로 case 추가.
  - freezed sealed 5 variant: `PassiveEffect` 전체 구조 복제하여 `LegendaryEffect` 작성. 각 variant는 본 명세 FR-4 표에 따라 필드 정의.
  - Ref 헬퍼: `PassiveBonusContext`(프로젝트 내 검색) — `EquipmentEffectContext`도 동일 스타일.
  - 시트 UX: `lib/features/quest/view/*` 하위 모달 시트 중 `showModalBottomSheet` 사용 예(SuccessRateBreakdownSheet 등). 동일 스타일의 `EquipmentEquipSheet` 작성.
  - HiveField 추가 시 생성자: 기존 `Mercenary`의 `stats ?? {}` 패턴 참조.

- **확장 지점 (후속 명세용, 본 명세 범위 외)**:
  - `Mercenary`에 `@HiveField(19) int permanentStrGain / 20 permanentIntGain / 21 permanentVitGain / 22 permanentAgiGain` (정수 시스템 페이즈 4 산출물 3에서 추가). `effectiveStrWith`도 `(str + permanent + bonus.str)` 형태로 확장.
  - `InventoryRepository.removeItem(id)`에 "장착 중이면 자동 해제" 옵션 추가(후속 UI 편의 명세 시점에 결정).
  - `ItemEffectService`에 소모품(`consumable`) 사용 경로(정수 소비 → 영구 스탯 강화) 추가.
  - 파견 UI에 장비 기여 분해 UI (성공률 breakdown에 `equipmentContribution` 레이어 추가).

---

## 5. 기획 확인 사항

- **[Q-1] 용병 개인 장비 accessory 슬롯 UI 개수**
  - 질문: `equipment_stats.md` 분석 3은 "accessory ×2 each 가중치 0.6"으로 2개 동시 장착 전제. 하지만 인프라 명세 FR-6의 slot 체크 제약은 `'accessory'` 단일 값. UI에서 2개 시각 슬롯을 보여주는 것이 맞는지.
  - 결정: **2개 시각 슬롯(accessory 1, accessory 2)을 제공**. 내부적으로 `slot='accessory'` 동일, 장착 개수 2개 제한을 UI 레이어에서 검증.
  - 근거: 기획서가 2 슬롯을 전제로 스탯 가중치·풀세트 수치를 산출. UI가 이를 반영하지 않으면 풀세트 체감이 불가능.
  - 필요 시 재검토.

- **[Q-2] 장비 보정의 Mercenary 모델 캐싱 여부**
  - 질문: 장비 보정을 Mercenary에 HiveField로 캐싱할지, 호출 시마다 `ItemEffectService`로 계산할지.
  - 결정: **매 호출 시 계산(비캐싱)**. 장착/해제 시 캐시 무효화 로직이 없으면 stale risk 크고, 계산 비용은 용병·아이템 수가 작아(<100) 무시 가능.
  - 근거: 정합성 > 최적화. M3 이후 용병 수 증가 시 성능 요구 발생하면 Riverpod `FutureProvider.family` 기반 캐싱 도입 검토.
  - 필요 시 재검토.

- **[Q-3] 용병단 장비 화면 진입 위치**
  - 질문: 용병단 장비(banner 1 + artifact 2)를 홈 탭 캠프사이트 카드로 배치할지, 정보 탭 ListTile로 배치할지.
  - 결정: **정보 탭 ListTile 3번째 항목**. 기존 `_showCodex` / `_showRank` 패턴 그대로 재사용하여 구현 복잡도 최소화.
  - 근거: 홈 탭은 이미 시간 이벤트 팝업·등급 카드 등 주요 위젯이 밀집. 용병단 장비 변경은 빈번하지 않으므로 정보 탭 접근성으로 충분. 홈 탭 배치는 후속 UX 개선으로 이관 가능.
  - 필요 시 재검토 (홈 탭 카드 추가 선호 시 `HomeScreen` 수정으로 전환).

- **[Q-4] PassiveBonusService.collect 시그니처 확장 방식**
  - 질문: 장비 소스를 기존 `collect()`에 인자로 추가할지, 별도 `collectAll()` 메서드를 만들지.
  - 결정: **기존 `collect()` 시그니처에 기본값 있는 인자 2개 추가**. 하위 호환 유지 + 호출부 1곳(QuestCompletionService)만 업데이트.
  - 근거: 메서드 분리 시 "언제 어느 걸 쓰는지" 규칙이 늘어 유지보수 부담. 단일 진입점 유지가 기존 설계 철학(`PassiveBonusContext` 일괄 수집)과 일관.
  - 필요 시 재검토.

- **[Q-5] 전설 ⑤ `special` 쿨다운 저장 위치**
  - 질문: death_prevention 쿨다운 상태를 Mercenary HiveField에 저장할지, InventoryItem HiveField에 저장할지.
  - 결정: **Mercenary HiveField(18)에 저장**. 전설 아이템을 다른 용병에 이동할 때 쿨다운이 리셋되어도 "용병 단위" 체감이 자연스러움.
  - 근거: 전설은 "이 용병의 생존 보너스"로 인식되며, 아이템 이동으로 쿨다운이 리셋되면 악용 경로가 됨. 유일 1종 전설이므로 인벤토리 간 이동 패턴이 빈번하지 않음.
  - 필요 시 재검토 (InventoryItem.cooldownUntil 필드 선호 시 HiveField 5 추가로 전환).

- **[Q-6] 전설 ② 대성공 승격 판정 roll 시드**
  - 질문: 승격 roll에 기존 성공 roll과 같은 `random` 인스턴스를 사용할지, 새 `random.nextDouble()` 호출로 독립 roll을 할지.
  - 결정: **같은 `random` 인스턴스에서 추가 `nextDouble()` 호출**. 이미 `QuestCompletionService.calculate`가 단일 `Random` 주입받으므로 자연스럽게 동일 seed 사용.
  - 근거: 결정론적 테스트(동일 seed → 동일 결과) 유지. 별도 Random 도입 시 테스트·재현 부담 증가.
  - 필요 시 재검토.

- **[Q-7] 이미 장착된 장비를 다른 용병에 장착 시도 시 동작**
  - 질문: `EquipmentEquipSheet`가 "다른 용병이 장착 중인 아이템"을 목록에 노출할지, 숨길지.
  - 결정: **숨김 (미장착 아이템만 노출)**. 용병 A에서 해제 후 용병 B에 장착하는 명시 플로우만 허용.
  - 근거: 자동 이동 로직은 "어느 용병에게서 해제됐는지"를 UI에 표시해야 하며 설명 부담 증가. 플레이어 의도 명확성 우선.
  - 필요 시 재검토 (자동 이동 선호 시 시트에 "OOO에서 가져오기" 옵션 추가).

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260419_m2a-item-equipment-effects.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|---|---|---|
| 수정/생성 파일 | 수정 11 + 생성 8 + 테스트 3 = **22개** | 대규모 |
| 영향 시스템 | core/models, core/domain, core/providers, features/inventory(신규 domain 4), features/mercenary(model+view), features/quest(calc+completion), features/info(신규 screen), features/quest/view (**7개+**) | 대규모 |
| 신규 클래스 | ItemEffectService, EquipmentStatBonus, LegendaryEffect sealed(5 variant), PersonalEquipmentEffect, EquipmentEffectContext, EquipmentSlotGrid, EquipmentEquipSheet, GuildEquipmentScreen, GuildEquipmentEquipSheet (**9개 이상**) | 대규모 |
| 데이터 모델 | Mercenary HiveField 1 추가 + PassiveEffect 2 variant 추가 + freezed 신규 모델 3종 + sealed 5 variant | 대규모 |
| UI 작업 | 용병 상세 오버레이 섹션 추가 + 정보 탭 화면 신설 + 시트 2종 | 대규모 |
| 기존 시스템 변경 | PassiveBonusService·QuestCalculator·QuestCompletionService·ReputationService·PassiveBonusFormatter·UserDataNotifier 6곳 시그니처·로직 확장 | 대규모 |

**추천: implement-agent (6/6점)**
- 다수 도메인 서비스 시그니처 변경 + 신규 feature UI + freezed/hive 코드 생성 + 5 카테고리 전설 분기 구조가 얽혀 있어, 파이프라인(planner→coder→verifier)의 단계별 검증·build_runner 관리가 필수.

---

구현을 진행하려면 아래 명령어를 실행해주세요:

/implement-agent @Docs/spec/[spec]20260419_m2a-item-equipment-effects.md  ← 추천 (파이프라인)
/implement-spec @Docs/spec/[spec]20260419_m2a-item-equipment-effects.md  (올인원)
