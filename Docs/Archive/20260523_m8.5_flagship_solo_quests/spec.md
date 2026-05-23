# 간판 용병 솔로/소수정예 의뢰 QuestGenerator 확장 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md`
> - `Docs/balance-design/[balance]20260521_m8.5_flagship_solo_quest_balance.md`
> 작성일: 2026-05-23
> 마일스톤: M8.5 페이즈 4 #2

---

## 1. 개요

M6 지명 의뢰(`is_named`)의 확장으로 `quest_pools`에 `party_size_min`/`party_size_max` 2개 INT 컬럼을 추가하고, 솔로(정확히 1인) 3종 + 소수정예(2인/3인) 2종 의뢰 5행을 삽입한다. `CombatSimulator`에 per-merc 사망 저항 cap 인자를 추가하고, `quest_provider._applyCompletionResult()`에서 카운터 증가·아이템 드랍·칭호 hook 평가를 trailing fail-soft로 수행한다. `DispatchDetailPage`에서 파티 규모 강제 UI를 적용하며, 의뢰 카드에 ⭐/⭐⭐/⭐⭐⭐ 배지를 추가한다. 신규 Hive 박스·typeId 추가 없이 기존 M6 지명 의뢰 패턴과 M8b CombatSimulator를 최소 확장으로 재활용한다.

### 1.1 검토 보완 요약

2026년 5월 23일 구현 전 검토에서 현재 코드와 충돌하는 지점을 보정했다. 본 절의 결정은 아래 요구사항 본문에 반영되며, 구현자는 이 보완 내용을 우선한다.

| 항목 | 기존 초안 문제 | 보완 결정 |
|------|---------------|-----------|
| 아이템 카테고리 | 신규 아티팩트 `category='guild_artifact'`, `slot='guild_equipment'`로 표기 | 현 `items` 규약에 맞춰 `category='guild_equipment'`, `slot='artifact'`로 고정 |
| 인벤토리 보유 확인 | `InventoryRepository.hasItem()` 호출을 가정 | 현 API에는 `hasItem`이 없으므로 `getAll().any((row) => row.itemId == itemId)` 또는 로컬 helper를 사용 |
| 인벤토리 추가 | `inventoryRepo.addItem(itemId)`처럼 축약 호출 | 현 API에 맞춰 `await inventoryRepo.addItem(itemId: itemId, items: staticData.items)` 사용 |
| 골드 지급 | `userData.addGold(goldAmount)` 호출 | `await ref.read(userDataProvider.notifier).addGold(goldAmount)` 사용 |
| 활동 로그 | `activityLog.add(ActivityLog(...))` 직접 추가 | `await ref.read(activityLogProvider.notifier).addLog(message, ActivityLogType.xxx)` 사용 |
| 칭호 hook | `evaluateActionStatHook(merc)`처럼 객체 전달 | 현 시그니처에 맞춰 `evaluateActionStatHook(merc.id)` 호출 |
| 스탯 Map 타입 | `Map<String, dynamic>` 예시 | `Mercenary.stats`와 `updateStats`에 맞춰 `Map<String, int>` 유지 |
| 결과 처리 위치 | `QuestCompletionService`가 카운터 영속화하는 듯한 문장 | `QuestCompletionService`는 계산만 수행하고, 카운터·드랍·로그는 `quest_provider._applyCompletionResult()`에서 처리 |

---

## 2. 요구사항

### 2.1 기능 요구사항

#### 데이터 / 모델

- **[FR-1]** `quest_pools` ALTER: `party_size_min INT NOT NULL DEFAULT 1` + `party_size_max INT NULL` + CHECK `quest_pools_party_size_check` (`party_size_min >= 1 AND (party_size_max IS NULL OR party_size_max >= party_size_min)`) 추가
  - 기존 전체 행은 DEFAULT로 자동 호환 (`partySizeMin=1`, `partySizeMax=null`)
- **[FR-2]** `quest_pools` 5행 INSERT (§8.1 표 기준, `is_named=true`, `party_size_max IS NOT NULL`):

  | id | hook_type | hook_value | party_size_min | party_size_max | named_reward_multiplier | named_reputation_multiplier | death_resistance_cap | named_weight_alpha | named_cooldown_hours |
  |----|-----------|------------|--------------|--------------|------------------------|----------------------------|--------------------|--------------------|---------------------|
  | `qp_solo_lone_wolf_letter` | `title` | `title_lone_wolf` | 1 | 1 | 2.0 | 1.7 | 0.95 | 2 | 48 |
  | `qp_solo_legend_continued` | `achievement_count` | `5` | 1 | 1 | 1.8 | 1.8 | 0.95 | 2 | 48 |
  | `qp_solo_flagship_request` | `flagship` | `""` | 1 | 1 | 2.2 | 2.0 | 0.95 | 2 | 48 |
  | `qp_pair_shadow_couple` | `achievement_count` | `8` | 2 | 2 | 1.5 | 1.4 | 0.90 | 2 | 36 |
  | `qp_small_three_kings_march` | `achievement_count` | `10` | 3 | 3 | 1.4 | 1.3 | 0.90 | 2 | 36 |

  `special_flags` JSONB 형식:
  ```json
  {
    "named_reward_multiplier": 2.0,
    "named_reputation_multiplier": 1.7,
    "death_resistance_cap": 0.95,
    "named_weight_alpha": 2
  }
  ```
  `party_size_min`, `party_size_max`, `named_cooldown_hours`는 별도 컬럼 저장.

- **[FR-3]** `titles` 4행 INSERT (모두 `hook_type='action_stat'`):

  | id | 한국어명 | stat_key | threshold | PassiveEffect |
  |----|---------|----------|-----------|--------------|
  | `title_lone_wolf` | 외로운 늑대 | `solo_completion_count` | 5 | `quest_reward_multiplier(all, +0.03)` |
  | `title_silver_pair` | 은빛 페어 | `pair_completion_count` | 8 | `mercenary_xp_bonus(+0.08)` |
  | `title_three_kings` | 삼인행의 일원 | `small_party_count` | 10 | `quest_success_rate_bonus_party_size(min_party_size: 3, +0.03)` |
  | `title_unyielding_solo` | 굽히지 않은 자 | `solo_great_success_count` | 1 | `injury_rate_modifier(-0.03)` |

  모든 4 PassiveEffect(`quest_reward_multiplier`/`mercenary_xp_bonus`/`quest_success_rate_bonus_party_size`/`injury_rate_modifier`)는 기존 `PassiveEffect` sealed type에 존재한다. 신규 PassiveEffect 추가 없음.
  - `titles.hook_condition` JSONB는 기존 `TitleData.hookCondition` 모델에 맞춰 `{"stat_key":"solo_completion_count","threshold":5}` 형식으로 저장한다.
  - `effect_json`은 기존 `PassiveEffect.parseEffects()`가 읽는 `{"effects":[...]}` 컨테이너 형식을 따른다. 예: `{"effects":[{"type":"quest_reward_multiplier","quest_type":"all","value":0.03}]}`.

- **[FR-4]** `items` 2행 신규 INSERT — `guild_artifact_lone_wolf_compass` / `guild_artifact_three_kings_seal` (`category='guild_equipment'`, `slot='artifact'`, `tier=3`). **INSERT 자체는 본 명세 구현 범위이며, verifier는 Supabase `items` 테이블에 해당 2행 존재 여부와 category/slot 정합성으로 PASS/FAIL 판정한다.** 효과 수치(`effect_json`)는 페이즈 3 #4에서 확정한다 (현재는 `{}` 빈 객체로 INSERT).

- **[FR-5]** `QuestPool` freezed 모델에 2 필드 추가:
  ```dart
  @Default(1) @JsonKey(name: 'party_size_min') int partySizeMin,
  @JsonKey(name: 'party_size_max') int? partySizeMax,
  ```
  → `build_runner build` 재실행으로 `quest_pool.freezed.dart` / `quest_pool.g.dart` 재생성 필요.
  - 기존 로컬 JSON 캐시는 `@Default(1)`/`int?`로 역직렬화 100% 호환.

- **[FR-6]** `FlagshipSoloQuestConfig` 정적 상수 클래스 신설 (`features/quest/domain/flagship_solo_quest_config.dart`):
  ```dart
  class FlagshipSoloQuestConfig {
    static const double soloDeathResistanceCap = 0.95;
    static const double smallPartyDeathResistanceCap = 0.90;
    static const double soloNamedWeightAlpha = 2.0;
    static const double smallPartyNamedWeightAlpha = 2.0;
    static const int soloCooldownHours = 48;
    static const int smallPartyCooldownHours = 36;

    /// pool.id → (partySizeMin, partySizeMax)
    static const partySizeMatrix = <String, ({int min, int max})>{
      'qp_solo_lone_wolf_letter': (min: 1, max: 1),
      'qp_solo_legend_continued': (min: 1, max: 1),
      'qp_solo_flagship_request': (min: 1, max: 1),
      'qp_pair_shadow_couple': (min: 2, max: 2),
      'qp_small_three_kings_march': (min: 3, max: 3),
    };

    /// pool.id → 보장 드랍 itemId (성공/대성공 시 항상 지급)
    /// [FR-19] 참조. 중복 보유 시 대체 골드 변환.
    static const guaranteedDropMatrix = <String, String>{
      'qp_solo_lone_wolf_letter': 'equip_accessory_red_spear_wristwrap',
      'qp_solo_legend_continued': 'guild_artifact_trade_seal',
      'qp_solo_flagship_request': 'guild_artifact_merchant_warrant',
    };

    /// pool.id → (itemId, 확률) 확률 드랍 (성공/대성공 시 확률 적용)
    /// [FR-20] 참조. 정확한 수치는 페이즈 3 #4 확정, 현재 0.05~0.10 임시 고정.
    static const probabilisticDropMatrix =
        <String, ({String itemId, double chance})>{
      'qp_solo_lone_wolf_letter':
          (itemId: 'guild_artifact_lone_wolf_compass', chance: 0.10),
      'qp_solo_legend_continued':
          (itemId: 'guild_artifact_lone_wolf_compass', chance: 0.05),
      'qp_solo_flagship_request':
          (itemId: 'guild_artifact_three_kings_seal', chance: 0.08),
    };

    /// pool.id → 결과 다이얼로그 또는 ActivityLog 후속 메시지
    /// [FR-21] 참조. M9+ 확장 시 추가 entry 삽입.
    static const epilogueMessages = <String, String>{
      'qp_solo_lone_wolf_letter': '외로운 늑대의 이름이 또 한 번 입에 오르내렸다.',
    };
  }
  ```

#### 도메인

- **[FR-7]** `QuestGenerator.computeFinalWeight()` — 하드코딩된 `weight += 3.0` 제거, `pool.specialFlags['named_weight_alpha']`를 우선 사용, 없으면 `3.0` fallback:
  ```dart
  // 변경 전 (line 305):
  if (pool.isNamed) weight += 3.0;

  // 변경 후:
  if (pool.isNamed) {
    final namedAlpha =
        (pool.specialFlags['named_weight_alpha'] as num?)?.toDouble() ?? 3.0;
    weight += namedAlpha;
  }
  ```
  → 기존 M6/M8a 지명 의뢰(`named_weight_alpha` 키 없음)는 α=3 그대로 유지.

- **[FR-8]** `QuestSortService.sort()` — `namedTier` 내부 추가 정렬 (`_sortByEstimatedReward` → 아래 커스텀 정렬로 교체):
  - 솔로(`party_size_max == 1`) 먼저 → 소수정예(`party_size_max IN [2,3]`) → 기존 지명(`party_size_max == null`) 순.
  - 같은 그룹 내는 기존 `_sortByEstimatedReward` 기준 유지.
  - `poolMap`에서 `pool.partySizeMax`를 조회하여 정렬 키로 사용.

- **[FR-9]** `CombatSimulator.simulate()` 시그니처 확장:
  ```dart
  static CombatSimulationResult? simulate({
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    QuestPool? pool,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    RegionState? regionState,
    Map<String, EquipmentStatBonus> partyEquipmentBonuses = const {},
    int? seed,
    Map<String, double> deathResistanceCaps = const {},  // 신규
  })
  ```
  - 기존 모든 호출 측은 인자 미전달 → `const {}` default로 100% 호환.
  - `_evaluateDeathResist()` 내부에서 `deathResistanceCaps[combatantId]` 조회 후 cap 적용:
    - `_evaluateDeathResist()` 내부에서 `baseCap`(isChainProtagonist=true이면 0.90, 아니면 0.80)과 `perMercCap`(`deathResistanceCaps[c.id]`) 중 더 높은 값을 `effectiveMax`로 계산하여 **1회만 clamp** 적용.
    - 솔로 체인 주인공: effectiveMax = max(0.95, 0.90) = **0.95** (솔로 cap 우선).
    - 소수정예 체인 주인공: effectiveMax = max(0.90, 0.90) = 0.90 (동일).
    - 비체인 솔로: effectiveMax = max(0.95, 0.80) = 0.95.

- **[FR-10]** `quest_provider.dart`의 `_applyCompletionResult()` — 4 카운터 증가 trailing fail-soft. **`QuestCompletionService`는 순수 계산 서비스 원칙을 유지하므로 카운터 영속화·hook 평가는 `quest_provider` 계층에 위치한다.** 기존 `region_N_dispatch_count` 갱신(line 1300~1318) 직후에 추가:
  ```dart
  // quest_provider.dart - _applyCompletionResult() 내부
  // (result는 QuestCompletionResult 반환값, pool은 StaticGameData에서 lookup)
  // pool.partySizeMax 기반 분기 (성공/대성공만)
  try {
    if (pool != null &&
        pool.partySizeMax != null &&
        (result.resultType == QuestResult.success ||
         result.resultType == QuestResult.greatSuccess)) {
      if (pool.partySizeMax == 1) {
        // 솔로: partyMercs.first만 (1인 파티)
        final merc = partyMercs.first;
        final latest = mercRepo.getAll().where((m) => m.id == merc.id).firstOrNull ?? merc;
        final updatedStats = Map<String, int>.from(latest.stats);
        updatedStats['solo_completion_count'] =
            (updatedStats['solo_completion_count'] ?? 0) + 1;
        if (result.resultType == QuestResult.greatSuccess) {
          updatedStats['solo_great_success_count'] =
              (updatedStats['solo_great_success_count'] ?? 0) + 1;
        }
        await mercRepo.updateStats(merc.id, updatedStats);
      } else if (pool.partySizeMax == 2 && pool.partySizeMin == 2) {
        for (final merc in partyMercs) {
          final latest = mercRepo.getAll().where((m) => m.id == merc.id).firstOrNull ?? merc;
          final updatedStats = Map<String, int>.from(latest.stats);
          updatedStats['pair_completion_count'] =
              (updatedStats['pair_completion_count'] ?? 0) + 1;
          await mercRepo.updateStats(merc.id, updatedStats);
        }
      } else if (pool.partySizeMax == 3 && pool.partySizeMin == 3) {
        for (final merc in partyMercs) {
          final latest = mercRepo.getAll().where((m) => m.id == merc.id).firstOrNull ?? merc;
          final updatedStats = Map<String, int>.from(latest.stats);
          updatedStats['small_party_count'] =
              (updatedStats['small_party_count'] ?? 0) + 1;
          await mercRepo.updateStats(merc.id, updatedStats);
        }
      }
      // 칭호 hook 평가 (M6 기존 패턴 — evaluateActionStatHook fail-soft)
      for (final merc in partyMercs) {
        await ref.read(titleServiceProvider).evaluateActionStatHook(merc.id);
      }
    }
  } catch (e) {
    debugPrint('[FR-10] solo/pair/small_party counter error: $e');
  }
  ```
  - `partyMercs`는 `_applyCompletionResult`에서 이미 `dispatchedMercIds`로 구성한 목록을 재사용한다 (line 754 기준).
  - `mercRepo.updateStats(merc.id, updatedStats)`: `MercenaryRepository.updateStats` 또는 동등한 Hive 영속화 메서드 사용.
  - **최신 stats 보존 필수**: `_applyCompletionResult()` 후반에는 `MercenaryStatService.updateStatsAfterQuest()`와 기존 `region_N_dispatch_count` 갱신이 이미 stats를 수정한다. 솔로/소수정예 카운터를 추가할 때는 `partyMercs`의 오래된 스냅샷이 아니라 `mercRepo.getAll()`에서 최신 용병을 다시 조회한 뒤 `Map<String, int>.from(latest.stats)`를 기준으로 병합해야 한다. 그렇지 않으면 같은 완료 처리에서 직전에 기록한 지역 카운터·행동 지표가 덮어써질 수 있다.

- **[FR-11]** `QuestCompletionService`(또는 `quest_provider.dart` 호출 측)에서 `deathResistanceCaps` 맵 구성 후 `CombatSimulator.simulate()`에 전달:
  ```dart
  // pool.partySizeMax로 per-merc cap 결정
  final deathResistanceCaps = <String, double>{};
  if (pool != null && pool.partySizeMax != null) {
    final configuredCap =
        (pool.specialFlags['death_resistance_cap'] as num?)?.toDouble();
    final fallbackCap = pool.partySizeMax == 1
        ? FlagshipSoloQuestConfig.soloDeathResistanceCap       // 0.95
        : FlagshipSoloQuestConfig.smallPartyDeathResistanceCap; // 0.90
    final cap = configuredCap ?? fallbackCap;
    for (final merc in partyMercs) {
      deathResistanceCaps[merc.id] = cap;
    }
  }
  simulationResult = CombatSimulator.simulate(
    ...
    deathResistanceCaps: deathResistanceCaps,
  );
  ```
  - `special_flags.death_resistance_cap`이 있으면 DB 값을 우선한다. 키가 없거나 파싱 실패하면 `FlagshipSoloQuestConfig` 상수로 fallback한다.

- **[FR-12]** 솔로/소수정예 의뢰 실패(`failure`/`criticalFailure`) 시 처리:
  - 사망 저항 cap 0.95/0.90 적용은 CombatSimulator가 담당.
  - 부상 마킹은 기존 `_convertSimulationToMercDamages` 또는 fallback 경로가 담당.
  - 카운터 증가하지 않음 (`result.resultType ∈ {failure, criticalFailure}`이면 FR-10 분기 미진입).
  - **신규 활동 로그 메시지** — `quest_provider._applyCompletionResult` trailing fail-soft으로 발급:
    - **솔로 의뢰 실패** (`pool.partySizeMax == 1` && `result.resultType ∈ {failure, criticalFailure}` && 해당 mercenary가 injured 마킹):
      `'솔로 의뢰 "{quest_name}" — {merc.name}이(가) 중상으로 귀환했다'`
    - **페어 의뢰 실패** (`pool.partySizeMax == 2` && 동일 조건): 부상 마킹된 각 용병에 대해
      `'페어 의뢰 "{quest_name}" — {merc.name}이(가) 중상으로 귀환했다'`
    - **삼인행 의뢰 실패** (`pool.partySizeMax == 3` && 동일 조건): 동일 패턴으로 N개 메시지 발급.
    - `pool.partySizeMax == null`(일반 의뢰)이면 기존 경로 그대로.
  - **신규 `ActivityLogType` enum 값**: `soloQuestInjuredReturn` (`@HiveField(40)`) 추가 권장. 솔로/소수정예 의뢰 서사 차별화를 위해 신규 enum 값을 사용한다. `activity_log_model.dart` HiveField 40 추가 후 `build_runner build` 재실행.
  - 처리 위치: `quest_provider._applyCompletionResult` 내부, 부상 마킹 직후 trailing fail-soft (`try/catch` 래핑).
  - verifier 검증 기준: `pool.partySizeMax == 1`인 의뢰 실패 시 `ActivityLog.type == ActivityLogType.soloQuestInjuredReturn` && 메시지 포맷 `'솔로 의뢰 "..." — ...이(가) 중상으로 귀환했다'` 확인.

- **[FR-19]** 솔로 의뢰 성공·대성공 시 아이템 **보장 드랍** trailing fail-soft (ISSUE-1·5 해소):
  - 처리 위치: `quest_provider.dart` `_applyCompletionResult()` 내부 — FR-10 카운터 증가 직후, AchievementService elite trailing 직전.
  - 조건: `pool.id`가 `FlagshipSoloQuestConfig.guaranteedDropMatrix` 키에 존재 && `result.resultType ∈ {success, greatSuccess}`.
  - **보장 드랍 처리**:
    ```dart
    try {
      final guaranteedItemId = FlagshipSoloQuestConfig.guaranteedDropMatrix[pool.id];
      if (guaranteedItemId != null &&
          (result.resultType == QuestResult.success ||
           result.resultType == QuestResult.greatSuccess)) {
        final alreadyHas = inventoryRepo
            .getAll()
            .any((row) => row.itemId == guaranteedItemId);
        if (!alreadyHas) {
          await inventoryRepo.addItem(
            itemId: guaranteedItemId,
            items: staticData.items,
          );
          await ref.read(activityLogProvider.notifier).addLog(
            '솔로 의뢰 보상 — {item_name}(을)를 획득했다',
            ActivityLogType.factionRewardGranted,
          );
        } else {
          // 중복 정책: 대체 골드 변환
          final goldAmount = 100 * pool.difficulty.round();
          await ref.read(userDataProvider.notifier).addGold(goldAmount);
          await ref.read(activityLogProvider.notifier).addLog(
            '솔로 의뢰 보상 — ${goldAmount}G로 변환되었다',
            ActivityLogType.questResult,
          );
        }
      }
    } catch (e) {
      debugPrint('[FR-19] guaranteedDrop error: $e');
    }
    ```
  - **매핑**: 솔로 #1(`qp_solo_lone_wolf_letter`) → `equip_accessory_red_spear_wristwrap` / 솔로 #2(`qp_solo_legend_continued`) → `guild_artifact_trade_seal` / 솔로 #3(`qp_solo_flagship_request`) → `guild_artifact_merchant_warrant`.
  - **중복 정책**: `inventoryRepo.getAll().any((row) => row.itemId == itemId) == true`이면 대체 골드 `100G * pool.difficulty.round()`. 재료 묶음 변환은 페이즈 3 #4에서 SQL 검토 위임.
  - verifier 검증: 솔로 의뢰 성공 후 인벤토리에 보장 아이템 존재 || (이미 보유 시) 골드 +100×difficulty 확인.

- **[FR-20]** 솔로 의뢰 성공·대성공 시 신규 2 아이템 **확률 드랍** trailing fail-soft (ISSUE-2 해소):
  - 처리 위치: FR-19 보장 드랍 직후 trailing fail-soft.
  - 조건: `pool.id`가 `FlagshipSoloQuestConfig.probabilisticDropMatrix` 키에 존재 && `result.resultType ∈ {success, greatSuccess}`.
  - **확률 드랍 처리**:
    ```dart
    try {
      final dropEntry = FlagshipSoloQuestConfig.probabilisticDropMatrix[pool.id];
      if (dropEntry != null &&
          (result.resultType == QuestResult.success ||
           result.resultType == QuestResult.greatSuccess)) {
        // CombatSimulator와 동일한 stableSeed32 패턴 사용
        final seed = stableSeed32(
          '${quest.startTime?.toUtc().microsecondsSinceEpoch ?? 0}|${quest.id}|drop');
        final rng = Random(seed);
        if (rng.nextDouble() < dropEntry.chance) {
          final alreadyHas = inventoryRepo
              .getAll()
              .any((row) => row.itemId == dropEntry.itemId);
          if (!alreadyHas) {
            await inventoryRepo.addItem(
              itemId: dropEntry.itemId,
              items: staticData.items,
            );
            await ref.read(activityLogProvider.notifier).addLog(
              '솔로 의뢰 보상 — 희귀 아이템 {item_name}(을)를 획득했다',
              ActivityLogType.factionRewardGranted,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[FR-20] probabilisticDrop error: $e');
    }
    ```
  - **확률 수치** (임시 고정, 페이즈 3 #4 확정 위임):
    - `qp_solo_lone_wolf_letter` → `guild_artifact_lone_wolf_compass` 10%
    - `qp_solo_legend_continued` → `guild_artifact_lone_wolf_compass` 5%
    - `qp_solo_flagship_request` → `guild_artifact_three_kings_seal` 8%
  - **중복 정책**: 확률 드랍 신규 아티팩트는 이미 보유 중이면 추가하지 않는다. 확률 드랍 실패와 동일하게 별도 보상 없이 종료한다.
  - **아이템명 치환**: `{item_name}`은 `staticData.items.firstWhereOrNull((i) => i.id == itemId)?.name ?? itemId`로 치환한다.
  - **시드 패턴**: `stableSeed32('${quest.startTime?.toUtc().microsecondsSinceEpoch ?? 0}|${quest.id}|drop')` — `combat_simulator.dart`의 FNV-1a 32-bit 패턴(`core/util/stable_seed.dart`) 재사용.
  - 페이즈 3 #4 확정 사항: 확률 수치 + 신규 2 아이템 효과 수치.

- **[FR-21]** 솔로 #1 성공·대성공 시 **후속 메시지** 노출 (ISSUE-3 해소):
  - 처리 위치: `quest_provider._applyCompletionResult()` 내부 — FR-20 확률 드랍 직후 trailing fail-soft.
  - 조건: `FlagshipSoloQuestConfig.epilogueMessages[pool.id] != null` && `result.resultType ∈ {success, greatSuccess}`.
  - **처리 방식** (합리적 default — ActivityLog 단독):
    ```dart
    try {
      final epilogue = FlagshipSoloQuestConfig.epilogueMessages[pool.id];
      if (epilogue != null &&
          (result.resultType == QuestResult.success ||
           result.resultType == QuestResult.greatSuccess)) {
        await ref.read(activityLogProvider.notifier).addLog(
          epilogue,  // '외로운 늑대의 이름이 또 한 번 입에 오르내렸다.'
          ActivityLogType.questResult,
        );
      }
    } catch (e) {
      debugPrint('[FR-21] epilogueMessage error: $e');
    }
    ```
  - **M9 확장 예정**: `FlagshipSoloQuestConfig.epilogueMessages` 정적 Map에 entry 추가만으로 다른 솔로 의뢰별 후속 메시지 확장 가능. 본 명세에서는 `qp_solo_lone_wolf_letter` 1건만 시드.
  - 페이즈 4 #2 위임 사항: `QuestResultDialog` footer 영역 직접 노출 여부 — 현재는 ActivityLog 단독으로 단순화.

- **[FR-13]** `quest_provider.dart`의 `dispatch()` 메서드에 `partySizeValidation` 헬퍼 추가:
  - `pool.partySizeMin`/`partySizeMax`가 non-null이면 `mercIds.length`가 해당 범위인지 검증.
  - 불일치 시 `return false` (파견 차단).
  - 이 검증은 UI에서 이미 강제하지만, 서버 측 이중 방어선 역할.

#### UI

- **[FR-14]** `DispatchDetailPage` 파티 선택 강제:
  - 의뢰의 `pool.partySizeMax`가 non-null인 경우 파티 선택 동작 변경:
    - **솔로(`partySizeMax == 1`)**: 용병 선택 시 radio 동작 구현. 이미 1명 선택된 상태에서 2번째 체크 → 기존 선택 자동 해제 + `ScaffoldMessenger`로 토스트 `'솔로 의뢰는 1명만 파견할 수 있습니다'`.
    - **페어(`partySizeMin == 2 && partySizeMax == 2`)**: `_selectedMercIds.length != 2`이면 [파견 출발] 버튼 비활성 (`onPressed: null`). 카운트 안내 문구 `'정확히 2명을 선택하세요 (현재 N명)'` 상시 표시.
    - **삼인행(`partySizeMin == 3 && partySizeMax == 3`)**: 동일 패턴으로 3명 강제.
    - **일반 의뢰(`partySizeMax == null`)**: 기존 동작 유지 (1명 이상 선택 시 버튼 활성).
  - [파견 출발] 버튼 활성 조건: `_selectedMercIds.isNotEmpty && hasEnoughGold && _partySizeValid(pool)` 통합.

- **[FR-15]** `DispatchDetailPage` 보상·순수익 미리보기 보정:
  - `grossReward` 계산 후 `pool.isNamed == true`이면 `named_reward_multiplier`를 곱해 미리보기에 반영:
    ```dart
    int previewGross = QuestCalculator.calculateReward(...);
    if (pool != null && pool.isNamed) {
      final multi = (pool.specialFlags['named_reward_multiplier'] as num?)?.toDouble() ?? 1.0;
      previewGross = (previewGross * multi).round();
    }
    final netProfit = previewGross - totalWage - dispatchCost;
    ```
  - 파견비(`dispatchCost`)도 함께 표시 (기존 로직은 이미 dispatchCost를 계산하여 `netProfit`에 반영 — 기존 `calculateNetProfit` 호출 경로 확인 후 `named_reward_multiplier` 추가만).

- **[FR-16]** 의뢰 카드 배지 추가 — `QuestLayerInfo`에 `partySizeLabel: String?` 필드 추가:
  - 솔로: `'⭐ 솔로'` / 페어: `'⭐⭐ 페어'` / 삼인행: `'⭐⭐⭐ 삼인행'` / 일반 지명 또는 비지명: `null`
  - `QuestCardBadges._namedBadge()` 내부에서 `info.partySizeLabel`이 non-null이면 배지 라벨에 반영:
    - 예: `'⭐ 솔로 · 칭호 — 외로운 늑대'` (솔로 + title hook 조합)
    - `info.partySizeLabel`이 null이면 기존 `'✩ 지명'` 라벨 사용.
  - 색상은 `AppTheme.namedAccent` 공유.

- **[FR-17]** 카드 잠금 정책 M6 정합:
  - `dispatch_screen.dart`의 `_isNamedQuestLocked()`:
    - 솔로 title hook: 기존 logic 그대로 (칭호 보유 alive 용병 전원 파견 중 시 잠금).
    - 솔로 flagship hook: 기존 logic 그대로 (`namedTargetMercId` 파견 중 시 잠금).
    - achievement_count hook: 잠금 없음 (기존 `default: return false` 그대로).
    - **페어/삼인행 의뢰**: 잠금 없음 (`default: return false` — 어느 용병이든 조합 자유).
  - 기존 `_isNamedQuestLocked()` 로직 변경 없음. 페어/삼인행은 hookType이 `achievement_count`이므로 자동으로 잠금 없음.

- **[FR-18]** `dispatch_screen.dart`의 `_buildLayerInfo()` — `partySizeLabel` 필드를 `QuestLayerInfo`에 추가하여 `_resolvePartySizeLabel(pool)` 헬퍼로 결정:
  ```dart
  static String? _resolvePartySizeLabel(QuestPool? pool) {
    if (pool == null || !pool.isNamed) return null;
    final max = pool.partySizeMax;
    if (max == null) return null; // 일반 지명 의뢰
    if (max == 1) return '⭐ 솔로';
    if (max == 2) return '⭐⭐ 페어';
    if (max == 3) return '⭐⭐⭐ 삼인행';
    return null;
  }
  ```

### 2.2 데이터 요구사항

| 대상 | 변경 내용 |
|------|----------|
| Supabase `quest_pools` | ALTER 2 컬럼 (`party_size_min INT NOT NULL DEFAULT 1`, `party_size_max INT NULL`) + CHECK 1종 + 5행 INSERT |
| Supabase `titles` | 4행 INSERT (`title_lone_wolf` / `title_silver_pair` / `title_three_kings` / `title_unyielding_solo`) — `hook_type='action_stat'` |
| Supabase `items` | 2행 INSERT (`guild_artifact_lone_wolf_compass` / `guild_artifact_three_kings_seal`, `category='guild_equipment'`, `slot='artifact'`) — 효과 수치 페이즈 3 #4 확정 |
| `QuestPool` freezed | `partySizeMin`/`partySizeMax` 2 필드 추가 → build_runner 재생성 |
| `Mercenary.stats` Map | 4 신규 카운터 키 (`solo_completion_count`/`solo_great_success_count`/`pair_completion_count`/`small_party_count`) — Hive 모델 변경 없음, Map 값 추가만 |
| ActiveQuest | 신규 HiveField 추가 없음 — `pool.partySizeMax` lookup으로 처리 |

### 2.3 UI 요구사항

| 화면 | 변경 내용 |
|------|----------|
| `DispatchDetailPage` | 솔로 radio 동작 + 페어/삼인행 정확 인원 강제 + [파견 출발] 버튼 비활성 안내 |
| `DispatchDetailPage` 보상 미리보기 | `named_reward_multiplier` 반영 순수익 preview |
| `QuestLayerInfo` | `partySizeLabel: String?` 필드 신규 추가 |
| `QuestCardBadges._namedBadge()` | `partySizeLabel` 반영 배지 텍스트 |
| `dispatch_screen.dart` `_buildLayerInfo()` | `_resolvePartySizeLabel()` 헬퍼 추가 |

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 변경 내용 | FR |
|----------|----------|-----|
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | `partySizeMin`/`partySizeMax` 2 freezed 필드 추가 | FR-5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `computeFinalWeight()` line 305 — `weight += 3.0` → `named_weight_alpha` 분기 | FR-7 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | `namedTier` 내부 추가 정렬 (솔로→소수정예→일반 named) | FR-8 |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` | `simulate()` 시그니처에 `deathResistanceCaps` 추가, `_evaluateDeathResist()` cap 적용 분기 | FR-9 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `dispatch()` partySizeValidation + `_applyCompletionResult()` 4 카운터 증가 trailing + `evaluateActionStatHook` 호출 | FR-10, FR-11, FR-13 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | `CombatSimulator.simulate()` 호출 시 `deathResistanceCaps` 구성·전달 | FR-11 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 파티 선택 강제 UI + 보상 미리보기 배수 반영 | FR-14, FR-15 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `_buildLayerInfo()` `partySizeLabel` 추가, `_resolvePartySizeLabel()` 헬퍼 | FR-18 |
| `band_of_mercenaries/lib/shared/widgets/quest_card_badges.dart` | `_namedBadge()` — `partySizeLabel` 반영 | FR-16 |
| `band_of_mercenaries/lib/core/models/dialog_request.dart` | `QuestLayerInfo`에 `partySizeLabel: String?` 필드 추가 | FR-16 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType.soloQuestInjuredReturn` `@HiveField(40)` 추가 | FR-12 |

### 3.2 신규 생성 파일

| 파일 경로 | 용도 | FR |
|----------|------|-----|
| `band_of_mercenaries/lib/features/quest/domain/flagship_solo_quest_config.dart` | `FlagshipSoloQuestConfig` 정적 상수 클래스 | FR-6 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 재생성 이유 |
|----------|------------|
| `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart` | `QuestPool` freezed 2 필드 추가 |
| `band_of_mercenaries/lib/core/models/quest_pool.g.dart` | `QuestPool` json_serializable 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | `ActivityLogType` HiveField 40 추가 후 재생성 |

### 3.4 관련 시스템

- **M6 지명 의뢰 시스템**: `NamedHookEvaluator` 변경 없음. 기존 7종 지명 의뢰 + M8a 세력 지명 12종에 5종 추가.
  **namedQuestCooldowns 영속화**: 본 5행의 48h/36h 쿨다운은 M6 `_updateNamedCooldownsForQuests` 헬퍼가 의뢰 발급 직후 `pool.namedCooldownHours`를 읽어 `UserData.namedQuestCooldowns: Map<String, DateTime> HiveField 26`에 동결한다. 기존 M6 7종(24h)·M8a 12종(24h)과 자연 공존하며, 본 명세에서 헬퍼 변경 없음 — `quest_pools` 테이블에 `named_cooldown_hours` 컬럼 값(솔로 48, 소수정예 36)이 정확히 시드되었는지만 검증한다.
- **M8b CombatSimulator**: `_evaluateDeathResist()` 확장이 유일한 M8b 본체 변경. 기존 체인 주인공 0.90 예외와 per-merc cap 0.95/0.90이 공존.
- **M6 칭호 시스템**: `TitleService.evaluateActionStatHook()` 변경 없음. 신규 4 칭호를 DB에 추가하면 기존 평가 루프가 자동 처리.
- **`PassiveBonusService`**: 신규 4 칭호의 PassiveEffect는 기존 sealed type 재활용. 코드 변경 없음.

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

#### M6 named quest 가중치 분기 (참조 구현)

`quest_generator.dart` line 304~306:
```dart
// 현재 (변경 전):
// 7. 지명 의뢰 +α=3 가중치 (M6 페이즈 4 #3, 가산)
if (pool.isNamed) weight += 3.0;
```
`computeFinalWeight()` 전체는 `quest_generator.dart` line 254~308.

#### M6 named quest 잠금 UI (참조 구현)

`dispatch_screen.dart` line 432~484: `_isNamedQuestLocked()` / `_resolveLockedMercName()`. 페어/삼인행은 `default: return false`로 자동 처리되어 잠금 없음.

#### M8b CombatSimulator 사망 저항 clamp (참조 구현)

`combat_simulator.dart` line 1495~1514: `_evaluateDeathResist()` 전체.
```dart
static double _evaluateDeathResist(_Combatant c, bool isChainProtagonist) {
  // ... 기본값 계산 후 [0.20, 0.80] clamp
  if (isChainProtagonist) {
    chance += (1.0 - chance) * 0.5;
    chance = chance.clamp(0.0, CombatSimulatorConstants.deathResistChainProtagonistMax); // 0.90
  }
  return chance;
}
```

`combat_simulator_constants.dart` line 256~262:
```dart
static const double deathResistMin = 0.20;
static const double deathResistMax = 0.80;
static const double deathResistChainProtagonistMax = 0.90;
```

`_evaluateDeathResist()` 확장 방향:
```dart
static double _evaluateDeathResist(
  _Combatant c,
  bool isChainProtagonist,
  Map<String, double> deathResistanceCaps,  // 신규 인자
) {
  // ... 기존 [0.20, 0.80] 계산 ...

  // 단일 max 계산 후 1회 clamp — "더 높은 값 우선" 정책
  final baseCap = isChainProtagonist
      ? CombatSimulatorConstants.deathResistChainProtagonistMax  // 0.90
      : CombatSimulatorConstants.deathResistMax;                  // 0.80
  final perMercCap = deathResistanceCaps[c.id];
  final effectiveMax = math.max(perMercCap ?? baseCap, baseCap);
  if (isChainProtagonist) {
    chance += (1.0 - chance) * 0.5;
  }
  chance = chance.clamp(0.0, effectiveMax);
  return chance;
}
```
> **적용 순서 정책**: baseCap과 perMercCap 중 더 높은 값을 effectiveMax로 사용하여 1회만 clamp한다. 솔로 체인 주인공(perMercCap=0.95, isChainProtagonist=true)의 경우 effectiveMax=max(0.95, 0.90)=**0.95**가 적용된다. 소수정예 cap(0.90)==chain protagonist cap(0.90)이므로 effectiveMax=0.90으로 동일. 기존 M8b 코드의 "chain protagonist 분기 후 perMercCap 조건부 clamp" 방식은 이 단일 max 계산으로 대체된다.

#### M8a 지명 배수 적용 경로 (참조 구현)

`quest_completion_service.dart` line 281~286 (골드 배수):
```dart
if (pool != null && pool.isNamed) {
  final flags = pool.specialFlags;
  final namedRewardMulti = (flags['named_reward_multiplier'] as num?)?.toDouble() ?? 1.0;
  rewardGold = (rewardGold * namedRewardMulti).round();
}
```
line 339~344 (명성 배수): 동일 패턴.

#### M6 카운터 증가 + action_stat hook 패턴 (참조 구현)

`quest_provider.dart` line 1300~1318: `region_N_dispatch_count` 갱신 + `evaluateActionStatHook` fail-soft 호출. 신규 4 카운터도 동일 trailing 패턴으로 추가한다.

### 4.2 주의사항

1. **카운터 영속화 위치**: `QuestCompletionService`는 순수 계산 서비스이므로 `Mercenary.stats` 갱신은 `quest_provider.dart`의 `_applyCompletionResult`에서 `mercRepo.updateStats(merc.id, updatedStats)` 호출로 수행한다. `QuestCompletionService` 내부에서 Hive에 직접 쓰지 않는다.
2. **`partyMercs` 접근**: `quest_provider.dart`의 `_applyCompletionResult`에서 이미 `dispatchedMercIds`로 파티 용병 목록을 구성하므로 (line 754), 카운터 증가도 동일 목록을 재사용한다.
3. **ActiveQuest HiveField**: `ActiveQuest` 다음 가용 HiveField는 **28**. 본 명세는 신규 HiveField 추가 없음 (`pool.partySizeMin/Max` lookup으로 처리).
4. **`QuestLayerInfo`에 필드 추가**: `dialog_request.dart`에 `partySizeLabel: String?` 추가 시 기존 생성자를 named parameter + default null로 추가하여 기존 생성 위치 전부 호환.
5. **`avoid_print`**: `analysis_options.yaml`에서 활성화. `debugPrint` 사용.
6. **타이틀 CHECK 확장**: `titles` 테이블의 `hook_type CHECK`가 `'action_stat'`을 이미 포함하는지 확인 필요. M6 기준으로 `action_stat`은 기존 CHECK에 포함되어 있으므로 별도 ALTER 불요. (M8a에서 `faction_reputation` 추가 시 확장한 바 있음.)
7. **추가 import**: FR-20 확률 드랍 시드를 `quest_provider.dart`에서 직접 계산하면 `package:band_of_mercenaries/core/util/stable_seed.dart` import가 필요하다. `dart:math`는 이미 import되어 있다.

### 4.3 엣지 케이스

1. **1인 파티 `featuredMercIds` 충돌**: `CombatSimulationResult.featuredMercIds`는 `simulationResult.featuredMercIds.isNotEmpty`이면 그대로 사용(`combat_report_service.dart` line 106~107). 솔로 의뢰는 `protagonistMercId == featuredMercIds[0]`일 수 있으나, `CombatReportService`는 `protagonist`와 `featuredMercIds`를 UI 표시용으로만 사용하므로 동일 ID 중복은 기능적으로 무해하다. 단, Chip 렌더 시 중복 표시 방지를 위해 `featuredMercIds.where((id) => id != protagonistMercId)` dedup이 이미 구현되어 있는지 확인 필요.
   - 현재 `CombatReportService` line 108~115에서 `protagonist != null`이면 `{protagonist.id, if (ally != null) ally.id}`로 구성. 1인 파티에서 `ally == null`이므로 `featuredMercIds = [protagonist.id]`만 포함 → protagonist와 동일.
   - 결정: **1인 파티에서 `featuredMercIds`는 protagonist 단독 허용** (빈 리스트 강제하지 않음). 상세 뷰 Chip 렌더는 `protagonistMercId`를 제외한 나머지를 표시하는 기존 로직 그대로.

2. **솔로 의뢰 fallback 경로(시뮬레이션 null)**: `CombatSimulator.simulate()` null 반환 시 `QuestCompletionService`는 기존 `QuestCalculator` random roll 기반 fallback으로 처리. fallback 경로에서는 `deathResistanceCaps`가 반영되지 않으므로 사망 저항은 기본 [0.20, 0.80]으로 처리됨. 솔로 의뢰는 `combatSimulationEligible = true`(`pool.isNamed == true`)이므로 시뮬레이션 정상 경로를 탈 확률이 높음. fallback 시 cap 미반영은 페이즈 4 #5 검증 항목.

3. **difficulty 3~4 솔로 의뢰 성공률 5% 하한**: `QuestCalculator.calculateSuccessRate()`의 clamp `[5.0, 95.0]`에 의해 최저 5%가 보장됨. 1인 파티 `partyPower`가 enemyPower에 크게 부족해도 5% 하한이 보호함. 실제 사망 분산은 CombatSimulator PRNG에서 발생.

4. **`quest_pools_party_size_check` CHECK 이름**: Supabase의 기존 CHECK 이름과 충돌하지 않는지 확인 후 사용. 위 SQL: `ADD CONSTRAINT quest_pools_party_size_check CHECK (...)`.

5. **솔로 의뢰 취소 정책**: M6 기존 취소 정책과 동일. 의뢰 취소 가능, 패널티 없음.

### 4.4 구현 힌트

#### 진입점

1. **데이터 진입점**: Supabase `quest_pools` ALTER → `SyncService.allTables` 컬럼 자동 반영 → `StaticGameData.questPools` 재로드 → `QuestPool.partySizeMin/Max` 자동 읽힘.
2. **발급 진입점**: `QuestGenerator.generateQuests()` → `computeFinalWeight()` (FR-7 변경). 기존 M6 named hook 평가 경로 그대로.
3. **완료 진입점**: `quest_provider.dart`의 `_applyCompletionResult()` → `QuestCompletionService.calculate()` → `CombatSimulator.simulate()` (FR-11) → 카운터 증가 (FR-10) → `evaluateActionStatHook` (FR-10).
4. **UI 진입점**: `DispatchScreen` → `QuestCard._buildLayerInfo()` (FR-18) → `QuestCardBadges._namedBadge()` (FR-16). `DispatchDetailPage` (FR-14, FR-15).

#### 데이터 흐름

```
quest_pools 5행 INSERT
→ SyncService 동기화
→ QuestPool.partySizeMin/Max 역직렬화 (@Default(1)/int?)
→ QuestGenerator.computeFinalWeight() — named_weight_alpha 분기 (α=2)
→ ActiveQuest 생성 (partySizeMax는 pool에서 lookup, ActiveQuest에 저장 안 함)
→ QuestSortService.sort() — namedTier 내부 솔로→소수정예→일반 named 정렬
→ DispatchScreen — _buildLayerInfo() partySizeLabel 추가
→ QuestCardBadges._namedBadge() — ⭐/⭐⭐/⭐⭐⭐ 배지
→ DispatchDetailPage — 파티 선택 강제 + 보상 미리보기 배수 반영
→ quest_provider.dispatch() — partySizeValidation
→ QuestCompletionService.calculate() — deathResistanceCaps 구성·전달
→ CombatSimulator.simulate() — _evaluateDeathResist() per-merc cap 적용
→ quest_provider._applyCompletionResult() — 4 카운터 증가 (FR-10 trailing)
→ evaluateActionStatHook() — 4 칭호 평가 (FR-10)
→ guaranteedDrop 처리 (FR-19 trailing)
→ probabilisticDrop 처리 (FR-20 trailing)
→ epilogueMessage ActivityLog 발급 (FR-21 trailing)
→ 실패 시 soloQuestInjuredReturn ActivityLog (FR-12)
```

#### 참조 구현 (파일:라인)

| 참조 위치 | 내용 |
|----------|------|
| `quest_generator.dart:304-306` | 현재 하드코딩 `weight += 3.0` (FR-7 변경 대상) |
| `quest_sort_service.dart:108-115` | `namedTier` 정렬 위치 (FR-8 변경 대상) |
| `combat_simulator.dart:1495-1514` | `_evaluateDeathResist()` 전체 (FR-9 확장 대상) |
| `combat_simulator_constants.dart:256-262` | `deathResistMin/Max/ChainProtagonistMax` 상수 |
| `quest_completion_service.dart:163-178` | `CombatSimulator.simulate()` 호출 위치 (FR-11 수정 위치) |
| `quest_completion_service.dart:281-286` | `named_reward_multiplier` 적용 (FR-15 미리보기 참조) |
| `quest_provider.dart:1300-1318` | 카운터 증가 + `evaluateActionStatHook` 패턴 (FR-10 추가 위치) |
| `quest_provider.dart:524-555` | `dispatch()` 메서드 (FR-13 partySizeValidation 추가 위치) |
| `dispatch_screen.dart:357-430` | `_buildLayerInfo()` 전체 (FR-18 수정 위치) |
| `dispatch_screen.dart:436-460` | `_isNamedQuestLocked()` (페어/삼인행 자동 처리 확인) |
| `dispatch_detail_page.dart:248-257` | 선택/해제 onTap (FR-14 radio 동작 적용 위치) |
| `dispatch_detail_page.dart:415-426` | [파견 출발] ElevatedButton + onPressed 조건 (FR-14 비활성 추가) |
| `dispatch_detail_page.dart:80-97` | 보상 미리보기 계산 (FR-15 `named_reward_multiplier` 추가 위치) |
| `title_service.dart:161-201` | `evaluateActionStatHook()` 전체 (신규 칭호 자동 평가 확인) |

#### 확장 지점

- `QuestLayerInfo` (`dialog_request.dart`): `partySizeLabel: String?` 신규 필드 추가.
- `QuestCardBadges._namedBadge()`: `partySizeLabel` non-null 시 배지 텍스트 앞에 prepend.
- `CombatSimulator.simulate()`: `deathResistanceCaps` named optional 인자.
- `CombatSimulatorConstants`: 신규 상수 `soloDeathResistanceCap`/`smallPartyDeathResistanceCap` 추가 — 또는 `FlagshipSoloQuestConfig`에서만 정의.

---

## 5. 기획 확인 사항

- **[Q-1 보상 배수 정확 수치]**: 해소됨. 페이즈 2 #2에서 확정 — 솔로 #1 ×2.0/×1.7 / #2 ×1.8/×1.8 / #3 ×2.2/×2.0 / 페어 ×1.5/×1.4 / 삼인행 ×1.4/×1.3.

- **[Q-2 가중치 α 수치]**: 해소됨. α=2 (솔로/소수정예 공통). `special_flags.named_weight_alpha=2` 방식.

- **[Q-3 `title_unyielding_solo` hook]**: 해소됨. `action_stat` hook `solo_great_success_count >= 1`.

- **[Q-4 `CombatSimulator.simulate()` 인자 변경]**: 해소됨. 옵션 A (인자 추가, `Map<String, double> deathResistanceCaps = const {}`). M8b 본체 수정이나 default 빈 맵으로 기존 호환 100%.

- **[Q-5 솔로 의뢰 취소 정책]**: 해소됨. M6 동일. 취소 가능, 패널티 없음.

- **[Q-6 페어 의뢰 직업군 추천]**: 미결정. 의뢰 카드 추천 직업군 chip은 부가 옵션. 본 명세 범위 외 (페이즈 4 #5 또는 이후 폴리싱 위임).

- **[Q-7 소수정예 사망 시 카운터 처리]**: 해소됨. 사망 시 의뢰 실패 처리, 살아남은 용병 카운터 미증가.

- **[Q-8 M8.5 #5 전투 기억 연계]**: 해소됨. 페이즈 1 #5 작성 시점에 결합 정밀화 예정.

- **[Q-9 `quest_pools_party_size_check` 이름 충돌]**: 구현 전 반드시 사전 검증 필요. Supabase MCP `list_tables` 또는 아래 SQL로 충돌 여부 확인:
  ```sql
  SELECT conname FROM pg_constraint
  WHERE conrelid = 'quest_pools'::regclass AND contype = 'c';
  ```
  결과에 `quest_pools_party_size_check`가 존재하면 이름 충돌 — `quest_pools_party_size_check_m85` 같은 마일스톤 접미사로 회피. `ADD CONSTRAINT IF NOT EXISTS`는 CHECK에 미지원이므로 충돌 시 오류 발생. 검증 없이 배포 금지.

- **[Q-10 solitary 배지와 기존 지명 배지 중첩 표시]**: `_namedBadge()`에서 `partySizeLabel`과 `namedSublabel`을 조합하는 방식은 구현자 재량. 배지 텍스트 최대 길이 한도(UI 오버플로우) 검토 필요.

- **[Q-11 fallback 경로에서 사망 저항 cap 미반영]**: `CombatSimulator.simulate()` null 시 기존 random roll fallback은 per-merc cap을 적용받지 못함. 솔로 의뢰가 `combatSimulationEligible = true`이므로 빈 `combatSkills`/`enemyArchetypes` 등 staticData 부재 시에만 fallback 진입. 이 경우 cap 미반영은 허용 — 데이터 완전성이 전제.

---

## 6. 검증 계획

본 구현은 정적 데이터, 결정적 전투 시뮬레이션, Hive enum, UI 선택 로직을 동시에 건드리므로 단위 테스트와 정적 분석을 함께 수행한다. 구현 완료 후 아래 검증을 최소 기준으로 통과해야 한다.

### 6.1 단위 테스트

- `quest_generator_test.dart`: `special_flags.named_weight_alpha=2`인 지명 의뢰가 기존 지명 α=3보다 낮은 최종 가중치를 갖는지 확인한다.
- `quest_sort_service_test.dart`: `namedTier` 내부 정렬이 솔로 → 페어/삼인행 → 일반 지명 순서를 유지하는지 확인한다.
- `combat_simulator_test.dart`: `deathResistanceCaps`가 비체인 솔로 0.95, 체인 주인공 솔로 0.95, 소수정예 0.90 effectiveMax로 적용되는지 seed 고정 테스트를 추가한다.
- `quest_provider` 또는 완료 처리 통합 테스트: 성공·대성공에서 `solo_completion_count`, `solo_great_success_count`, `pair_completion_count`, `small_party_count`가 최신 stats에 병합되고 기존 `region_N_dispatch_count`를 덮어쓰지 않는지 확인한다.
- `dispatch_detail_page` 위젯 테스트: 솔로 radio 동작, 페어/삼인행 정확 인원 버튼 비활성, 일반 의뢰 기존 동작 유지 여부를 확인한다.

### 6.2 데이터 검증

- Supabase `quest_pools`에 `party_size_min`, `party_size_max` 컬럼과 CHECK 제약이 존재하는지 확인한다.
- 신규 5개 의뢰가 `is_named=true`, `named_cooldown_hours` 48/36, `special_flags.named_weight_alpha=2`, `special_flags.death_resistance_cap` 0.95/0.90 값을 갖는지 확인한다.
- 신규 2개 아이템이 `category='guild_equipment'`, `slot='artifact'`, `effect_json={}`로 삽입되었는지 확인한다.
- 신규 4개 칭호가 `hook_type='action_stat'`이고 `hook_condition`에서 §FR-3의 stat key와 threshold를 정확히 참조하는지 확인한다.

### 6.3 명령어 검증

구현 완료 후 Flutter 프로젝트 디렉토리에서 다음 명령어를 실행한다.

```bash
dart run build_runner build
flutter analyze
flutter test
```

모델·Hive enum 변경이 포함되므로 `build_runner` 결과물(`quest_pool.freezed.dart`, `quest_pool.g.dart`, `activity_log_model.g.dart`)을 반드시 커밋 대상에 포함한다.

---

## 부록: SQL 참고 (페이즈 3 #4 시드 입력용)

```sql
-- quest_pools 컬럼 추가
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS party_size_min INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS party_size_max INT NULL;

ALTER TABLE quest_pools
  ADD CONSTRAINT quest_pools_party_size_check
  CHECK (
    party_size_min >= 1
    AND (party_size_max IS NULL OR party_size_max >= party_size_min)
  );

-- 5행 INSERT (수치는 §8.1 표 기준, 실제 name/description은 페이즈 3 #4에서 확정)
-- special_flags 예시 (qp_solo_lone_wolf_letter):
-- {"named_reward_multiplier": 2.0, "named_reputation_multiplier": 1.7, "death_resistance_cap": 0.95, "named_weight_alpha": 2}
```
