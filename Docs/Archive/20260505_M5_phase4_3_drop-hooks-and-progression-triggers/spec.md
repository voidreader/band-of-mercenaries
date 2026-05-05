# M5 페이즈 4 #3 — 드랍 출처 hook 5종 + 거대 박쥐 step 3 강제 spawn + 신뢰도 단계 진입 보너스 + region_discoveries 발견 hook + firstAcquiredItem 영속 추적 개발 명세서

> 기획 문서:
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-content-dustvile-materials.md` (페이즈 1 #2 — 재료 10종 + 5종 출처 매핑)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-balance-material-droprate.md` (페이즈 2 #1 — 5종 출처 drop_rate 곡선 + 거대 박쥐 power 80 + 신뢰도 단계 진입 보너스)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/spec.md` + `plan.md` (페이즈 4 #1 — 데이터 인프라: items 22행 + crafting_recipes 10행 + quest_pool_material_drops 스키마 + elite_giant_bat 1 + region_discoveries 3 + chain_quests reward 5)
> - `Docs/Archive/20260505_M5_phase4_2_crafting-service-and-inventory-ui/spec.md` + `plan.md` (페이즈 4 #2 — InventoryRepository.addItem material stack 분기 + ActivityLogType.craftCompleted HiveField 27 + firstAcquiredItem 임시 평가 위임 명시)
>
> 작성일: 2026-05-05
> 마일스톤: M5 페이즈 4 #3 — 마지막 페이즈
> 선행: 페이즈 4 #1 (commit `3b6506c`) + 페이즈 4 #2 (commit `d03c5b4`) — 모든 데이터/UI 인프라 적용 완료
> 후속: M5 마일스톤 종결 (페이즈 4 #4 없음 — 본 페이즈 후 종료 조건 검증 + finalize-feature)
> Visual Companion: 미적용 (UI 변경 0건 — 본 명세는 백엔드 hook + 영속 모델 + 데이터 INSERT 전용)

---

## 1. 개요

페이즈 4 #1 데이터 + 페이즈 4 #2 도메인/UI 인프라가 적용된 상태에서, **5종 드랍 출처 hook**(QuestCompletion / Investigation / EliteLoot / TravelChoice / ChainQuest)을 활성화하여 실제 InventoryItem이 누적되도록 한다. 동시에 **거대 박쥐 step 3 강제 spawn** + **신뢰도 단계 진입 일회성 보너스**(2단계 #6 ×1, 3단계 #1 ×3) + **region_discoveries 발견 hook** + **firstAcquiredItem 영속 추적**(`RegionState.firstAcquiredMaterialIds` HiveField 7) + **`quest_pool_material_drops` 신규 INSERT 데이터**(약 15~18행) + **`travel_choice_results.effect_type='material_drop'` 신규 값 6행** + **EliteLootService drop_type='material' 분기**를 추가한다. 본 페이즈 완료로 M5 종료 조건(첫 제작 30~45분 / 첫 희귀 90~150분)이 실 플레이로 검증 가능해진다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### (a) QuestCompletionService → 의뢰 완료 시 재료 드랍 hook (FR-1)

- **[FR-1]** `QuestListNotifier._applyCompletionResult` 내 의뢰 완료 처리에 `quest_pool_material_drops` 매핑 적용
  - 위치: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` 라인 641~653 인근 (eliteLoot 처리 직후)
  - 흐름:
    1. `staticData.questPoolMaterialDrops.where((d) => d.poolId == quest.questPoolId)` 매핑 조회
    2. 각 매핑에 대해 `Random.nextDouble() < drop.dropRate`이면 `quantity = qtyMin + Random.nextInt(qtyMax - qtyMin + 1)` 산출
    3. `inventoryRepository.addItem(itemId: drop.itemId, quantity: quantity, items: staticData.items)` 호출
    4. addItem 직후 항상 `regionStateRepository.addAcquiredMaterial(regionId, drop.itemId)` 호출 — FR-9 멱등성 보장으로 중복 호출 안전
    5. ActivityLog 기록은 본 명세 범위 외 (페이즈 4 #2 toast 정책 정합 — 단순 inventory 누적만)
  - 호출 측: `QuestListNotifier._completeQuest()` 라인 524~601 → `_applyCompletionResult()` 라인 603~940

#### (b) EliteLootService.rollDrops → drop_type='material' 분기 (FR-2)

- **[FR-2]** `EliteLootService.rollDrops`에 drop_type='material' 분기 추가
  - 위치: `band_of_mercenaries/lib/features/quest/domain/elite_loot_service.dart` 라인 32~49 switch 문 내
  - 추가 분기 (기존 'essence' case 패턴 차용):
    ```dart
    case 'material':
      if (entry.itemId != null) {
        final qty = entry.quantity > 0 ? entry.quantity : 1;
        for (var i = 0; i < qty; i++) {
          itemDrops.add(entry.itemId!);
        }
      }
      break;
    ```
  - 효과: 거대 박쥐 처치 시 `mat_monster_giant_bat_fang` ×1이 `EliteLootResult.itemDrops`로 반환됨 (drop_rate 1.0 확정)
  - 호출 측: `QuestCompletionService.calculate()` 라인 345~349 → `_applyCompletionResult()` 라인 641~653 (기존 inventory.addItem 호출 그대로 활용 — 본 hook은 EliteLootService 내부 분기만 추가)

#### (c) QuestGenerator → 거대 박쥐 step 3 강제 spawn (FR-3)

- **[FR-3]** `QuestGenerator.generateQuests` 내 elite spawn 루프(라인 130~159)에 step 3 강제 spawn 분기 추가
  - 진입 조건: `quest_pool.fixedChainId == 'settlement_3_pyegwang_reopen' && quest_pool.fixedStep == 3`
  - 강제 spawn 대상: `elite_giant_bat`
  - 매핑 방식: **하드코딩 1줄** (M5 단일 거점/단일 사건 한정 — 본 명세 §5 권고 정합)
  - 추가 로직 (라인 155~159 spawn 조건 체크 직전):
    ```dart
    final isSettlement3Step3 = quest.fixedChainId == 'settlement_3_pyegwang_reopen' && quest.fixedStep == 3;
    final shouldForceSpawn = isSettlement3Step3 && monster.id == 'elite_giant_bat';
    if (shouldForceSpawn || random.nextDouble() < monster.spawnRate) {
      // 기존 ActiveQuest 생성 로직
      eliteGenerated++;
    }
    ```
  - **TODO 주석 1줄**: `// TODO(M6+): elite_monsters에 fixed_chain_id/fixed_step 컬럼 또는 매핑 테이블 도입 시 하드코딩 제거`
  - 효과: step 3 박쥐 둥지 소탕 의뢰 진입 시 거대 박쥐 100% spawn → 처치 시 #9 거대 박쥐 송곳니 1.0 확정 드랍 (FR-2 정합)

#### (d) InvestigationNotifier → region_discoveries 발견 시 재료 드랍 hook (FR-4)

- **[FR-4]** `InvestigationNotifier._completeInvestigation`에 `discoveryData.items` 적용 분기 추가
  - 위치: `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart` 라인 282~286 인근 (활동 로그 기록 직전)
  - `RegionDiscoveryData.discoveryData`(`Map<String, dynamic>?`) 안의 `'items'` 배열 처리:
    ```dart
    final items = d.discoveryData?['items'];
    if (items is List) {
      for (final entry in items) {
        if (entry is! Map) continue;
        final itemId = entry['item_id'] as String?;
        final quantity = (entry['quantity'] as num?)?.toInt() ?? 1;
        final dropRate = (entry['drop_rate'] as num?)?.toDouble() ?? 1.0;
        if (itemId != null && _random.nextDouble() < dropRate) {
          await _ref.read(inventoryRepositoryProvider).addItem(
            itemId: itemId, quantity: quantity, items: staticData.items);
          await _ref.read(regionStateRepositoryProvider)
            .addAcquiredMaterial(regionId, itemId);  // FR-12 영속 추적
        }
      }
    }
    ```
  - 효과: knowledge 25/50/80 도달 시 페이즈 4 #1 등록된 3개 발견(`disc_dustvile_pyegwang_normal/hidden/deepest`)에서 #1 ×3 / #8 + #7 보조 / #10 자동 인벤토리 추가
  - `resettable: true` (deepest)는 본 명세 범위 외 — 별도 검토 위임 (페이즈 1 #2 §3-2 정합 — knowledge 80 도달 1회로 제한, 재발견 위해서는 reset 메커니즘 필요. 본 명세는 1회 적용만 보장)

#### (e) MovementNotifier → travel_choice 'material_drop' 분기 (FR-5)

- **[FR-5]** `MovementNotifier.applyTravelChoiceEffect` switch에 `'material_drop'` case 추가
  - 위치: `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart` 라인 447~500 switch 문
  - 추가 case:
    ```dart
    case 'material_drop':
      final itemId = result.effectTarget;
      if (itemId != null) {
        final staticData = ref.read(staticDataProvider).valueOrNull;
        if (staticData != null) {
          final qty = result.effectMagnitude.toInt().clamp(1, 99);
          await ref.read(inventoryRepositoryProvider).addItem(
            itemId: itemId, quantity: qty, items: staticData.items);
          // 영속 추적은 region 3 한정이므로 movement 컨텍스트의 currentRegion 검증 후 호출
          final currentRegion = ref.read(userDataProvider)?.currentRegion;
          if (currentRegion == GameConstants.startingRegionId) {
            await ref.read(regionStateRepositoryProvider)
              .addAcquiredMaterial(currentRegion!, itemId);
          }
        }
      }
      break;
    ```
  - `TravelChoiceResultData.effectMagnitude`(double)를 qty로 재활용 (`.toInt()`). drop_rate는 옵션 선택 가중치(`travel_choice_options.weight`)로 표현되므로 결과 적용 시 100% 드랍
  - `summarizeEffect()`(라인 143~165)에 `'material_drop'` case 추가 → "재료 획득" 또는 "{itemId 한국어 이름} ×{qty}" 반환 (페이즈 4 #2 패턴 정합)

#### (f) ChainQuestService → step 완료 시 reward_items 적용 (FR-6)

- **[FR-6]** `ChainQuestService.completeChain`에 `addRewardItems` 콜백 신규 추가 + step 진행 시 매 step `rewardItems` 적용
  - 위치: `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` 라인 58~153
  - **시그니처 변경**: 기존 콜백 DI 패턴 정합 (`logActivity`, `onChainCompleted`와 동일 위치) — `addRewardItems` 콜백 추가
    ```dart
    Future<void> onStepCompleted({
      required String chainId,
      required ChainQuestProgress progress,
      required ChainQuestData currentStep,
      required Future<void> Function(String message, ActivityLogType type) logActivity,
      required Future<void> Function(String chainId, ChainQuestData finalStep) onChainCompleted,
      required Future<void> Function(String itemId, int quantity) addRewardItems,  // 신규
    });
    ```
  - **현재 페이즈 4 #1 `chain_quests.reward_items`는 step별로 채워짐**: step 1 = `{#7:1, #1:1}` / step 2 = `{#2:2}` / step 3 = `{}` (elite_loot 처리) / step 4 = `{#7:1, #5:1}` / step 5 = `{#1:3, #8:1}` / step 6 = `{#10:1, #8:2}`
  - 흐름: step 진행 성공 시(라인 101~107 인근) `currentStep.rewardItems.entries`를 순회하여 각 itemId/quantity에 대해 `addRewardItems` 콜백 호출
  - **호출 측 (`quest_provider.dart` 라인 873~892)**:
    ```dart
    addRewardItems: (itemId, quantity) async {
      final staticData = ref.read(staticDataProvider).requireValue;
      await ref.read(inventoryRepositoryProvider).addItem(
        itemId: itemId, quantity: quantity, items: staticData.items);
      await ref.read(regionStateRepositoryProvider)
        .addAcquiredMaterial(GameConstants.startingRegionId, itemId);
    },
    ```
  - 효과: 거점 사건 진행 시 step별 reward_items 자동 inventory 누적

#### (g) RegionStateRepository.addSettlementTrust → 단계 진입 보너스 hook (FR-7)

- **[FR-7]** `RegionStateRepository.addSettlementTrust` 라인 174 직후에 단계 진입 재료 보너스 분기 추가
  - 위치: `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` 라인 154~174 인근 (단계 보상 합산 로직 직후)
  - 추가 로직 (M4 페이즈 4 #5 골드/XP/명성 보상 처리 직후):
    ```dart
    // M5 페이즈 4 #3 — 신뢰도 단계 진입 일회성 재료 보너스
    if (regionId == GameConstants.startingRegionId) {
      final staticData = ref.read(staticDataProvider).valueOrNull;
      if (staticData != null) {
        if (newLevel >= 2 && oldLevel < 2) {
          await ref.read(inventoryRepositoryProvider).addItem(
            itemId: 'mat_hide_faded_cloth', quantity: 1, items: staticData.items);
          await addAcquiredMaterial(regionId, 'mat_hide_faded_cloth');
        }
        if (newLevel >= 3 && oldLevel < 3) {
          await ref.read(inventoryRepositoryProvider).addItem(
            itemId: 'mat_ore_rusty_scrap', quantity: 3, items: staticData.items);
          await addAcquiredMaterial(regionId, 'mat_ore_rusty_scrap');
        }
      }
    }
    ```
  - 효과: 2단계 진입 시 #6 빛바랜 천 조각 ×1 / 3단계 진입 시 #1 녹슨 쇳조각 ×3 자동 지급 (페이즈 2 #1 §1-6 정합)
  - 4단계 진입 시는 재료 없음 (페이즈 2 #1 §1-6 정합 — 골드/명성만 유지)
  - **다중 단계 동시 도달 처리**: `oldLevel=1` → `newLevel=3` 케이스에서 2단계와 3단계 보너스 모두 지급 (>= 비교)

#### (h) RegionState 모델 → firstAcquiredMaterialIds HiveField 7 추가 (FR-8~10)

- **[FR-8]** `RegionState` Hive 모델에 신규 필드 추가
  - 위치: `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart`
  - 신규 필드:
    ```dart
    @HiveField(7)
    @Default(<String>[])
    List<String> firstAcquiredMaterialIds,
    ```
  - typeId 8 그대로 유지
  - CLAUDE.md HiveField 점유표 갱신: RegionState 다음 HiveField 7 → 8
  - `region_state_model.g.dart` 자동 재생성 필요 (`dart run build_runner build`)

- **[FR-9]** `RegionStateRepository.addAcquiredMaterial(int regionId, String itemId)` 신규 메서드 추가
  - 위치: `region_state_repository.dart`에 추가
  - 시그니처: `Future<void> addAcquiredMaterial(int regionId, String itemId)`
  - 동작:
    - 현재 RegionState 조회 (`getState(regionId)`)
    - `firstAcquiredMaterialIds.contains(itemId)`이면 즉시 반환 (이미 추적됨)
    - 미존재 시 `state = state.copyWith(firstAcquiredMaterialIds: [...state.firstAcquiredMaterialIds, itemId])` + `save()`
    - region 3 외 다른 region 호출은 무시 또는 빈 동작 (M5 시점 region 3 한정 — 미래 다중 거점 시 자연 확장)

- **[FR-10]** `CraftingService.evaluateState`의 `firstAcquiredItem` 분기 영속 평가로 교체
  - 위치: `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` 라인 74~79 (페이즈 4 #2에서 `getQuantityForItemId > 0` 임시 평가 + TODO 주석 추가됨)
  - 변경 전 (페이즈 4 #2):
    ```dart
    // TODO(M5 페이즈 4 #3): 첫 입수 영속 추적 도입
    final qty = inventoryRepository.getQuantityForItemId(condition.firstAcquiredItem!);
    if (qty <= 0) return RecipeState.locked;
    ```
  - 변경 후 (본 페이즈 4 #3):
    ```dart
    final regionState = regionStateRepository.getState(GameConstants.startingRegionId);
    final acquired = regionState?.firstAcquiredMaterialIds.contains(condition.firstAcquiredItem!) ?? false;
    if (!acquired) return RecipeState.locked;
    ```
  - TODO 주석 제거
  - 효과: `recipe_dustvile_miner_charm`(`first_acquired_item: mat_relic_pyegwang_shard`)이 첫 입수 후 모두 소비해도 해금 유지

#### (i) InventoryRepository.addItem 999 stack 클램프 알림 (FR-11)

- **[FR-11]** 999 stack 도달 시 신규 `ActivityLogType.inventoryStackCapped` HiveField 28 활동 로그 1행 기록 (확정)
  - 페이즈 4 #2 시점: `addItem`이 999 클램프된 `InventoryItem`을 반환하지만 호출 측에서 클램프 발생을 명시적으로 알 수 없음
  - 본 명세 결정 (확정 — verify-spec ISSUE-3 반영):
    - `ActivityLogType` enum에 신규 값 `inventoryStackCapped` HiveField 28 추가 (typeId 6 그대로)
    - 위치: `band_of_mercenaries/lib/core/domain/activity_log_model.dart` 라인 60 후 (페이즈 4 #1 craftCompleted = 27 다음)
    - CLAUDE.md HiveField 점유표 갱신: ActivityLogType 다음 HiveField 28 → **29**
  - 호출 측 사전 평가 흐름 (본 명세 §FR-1 / §FR-4 / §FR-5 / §FR-6 / §FR-7 5종 hook 모두):
    1. addItem 호출 전 `inventoryRepository.getQuantityForItemId(itemId)` 조회
    2. 보유량이 stackMax(999)와 같거나 그 차이가 추가 quantity보다 작으면 → addItem 호출은 그대로 수행하되(클램프됨), 클램프 발생 시 `activityLogNotifier.addLog('{재료 이름} 보유량이 가득 찼습니다 (999 도달)', ActivityLogType.inventoryStackCapped)` 1행 기록
    3. 메시지 카피는 페이즈 1 #4 §5-3 정합
  - 멱등성: 999 도달 후 동일 itemId에 대한 추가 hook 발생 시 매번 활동 로그 발생 가능 — 본 명세 범위에서는 매 hook 발생 시 1행 기록 허용 (드물게 발생)
  - 적용 위치: 본 명세 §FR-1 (의뢰 hook) / §FR-4 (조사 hook) / §FR-5 (이동 hook) / §FR-6 (체인 hook) / §FR-7 (신뢰도 hook) 모든 호출 측에서 사전 평가 + 활동 로그 1행

#### (j) firstAcquiredMaterialIds 일괄 갱신 통합 (FR-12)

- **[FR-12]** §FR-1 / §FR-4 / §FR-5 / §FR-6 / §FR-7 모든 hook에서 `regionStateRepository.addAcquiredMaterial(regionId, itemId)` 일괄 호출
  - 호출 시점: `inventoryRepository.addItem` 직후 (성공 시)
  - 멱등성: `addAcquiredMaterial`이 이미 추적된 itemId는 무시하므로 다중 호출 안전
  - 효과: M5 시점 region 3 한정으로 firstAcquiredMaterialIds Set 누적. 페이즈 1 #2 §1-2 재료 12종 모두 첫 입수 시점부터 추적

#### (k) Supabase 데이터 INSERT — quest_pool_material_drops + travel_choice_results material_drop (FR-13~14)

- **[FR-13]** `quest_pool_material_drops` 신규 INSERT 약 15~18행
  - 페이즈 2 #1 §1-1 (a) 의뢰 보상 표 기반 매핑
  - 대상 quest_pools (페이즈 4 #1 시점 25행 기준):
    - `dustvile_chore_03` 약초 채집 (신뢰도 2단계 labor): #3 마른 약초 1.0 (qty 1~3) + #5 접착 수액 1.0 (qty 1~2)
    - `dustvile_chore_05` 도적 흔적 조사 (field labor): #2 마른 가죽끈 0.4 (qty 1)
    - `dustvile_chore_06` 잡동사니 회수 (dungeon labor): #1 녹슨 쇳조각 1.0 (qty 1)
    - `dustvile_chore_10` 늑대 떼 (field hunt): #2 마른 가죽끈 0.8 (qty 1~2)
    - `qp_dv_d1_scout` / `qp_dv_d3_tool` / `qp_dv_d5_check` (dungeon explore): #1 녹슨 쇳조각 0.6 (qty 1)
    - `qp_dv_d4_rubble` 잡석 정리 (dungeon labor): #1 녹슨 쇳조각 1.0 (qty 1~2)
    - `qp_dv_f3_dog` 들개 퇴치 (field hunt): #2 마른 가죽끈 0.8 (qty 1~2)
    - `qp_dv_f3_herb` 약초 채집 (field labor): #3 마른 약초 1.0 (qty 1~2) + #4 산기슭 버섯 0.5 (qty 1) + #8 폐광의 유물 파편 0.3 (qty 1) (페이즈 2 #1 §1-1 보조 출처 정합)
    - `qp_dv_f3_patrol` 야간순찰 (field escort): #2 마른 가죽끈 0.5 (qty 1)
    - `qp_dv_r4_bandit` 도적 추적 (field hunt): #2 마른 가죽끈 0.8 (qty 1~2)
    - `qp_dv_r4_escort` 행상 호위 (field escort): #2 마른 가죽끈 0.5 (qty 1)
    - `qp_dv_v2_supply` 행상 짐 내리기 (village labor): #6 빛바랜 천 조각 0.05 (qty 1)
  - **예상 INSERT 행 수: 약 18행** (chore_03이 2행 분기 / qp_dv_f3_herb 3행 분기 포함)
  - 본 명세 §5 SQL INSERT로 인라인 처리
  - **검증 사전 조회 필요**: implement-agent/coder가 본 작업 시작 시점에 `mcp__plugin_supabase_supabase__execute_sql`로 quest_pools 25행 id 정확히 매칭 확인 (페이즈 4 #1 시점 풀 id 변경 가능성 방어)

- **[FR-14]** `travel_choice_results` 행 6개 신규 INSERT (effect_type='material_drop')
  - 페이즈 2 #1 §1-4 매핑 표 기반
  - 신규 6행 (대상 옵션 id는 본 명세 §5 SQL 인라인 — implement-agent/coder가 사전 조회로 정확한 option_id 확인):
    - 마른 초원 야간 순찰 (평온): mat_herb_mountain_mushroom × 1 (effect_magnitude=1.0)
    - 마른 초원 야간 순찰 (들개 조우): mat_hide_dry_strap × 1
    - 폐광길 짐 더미 (평온): mat_relic_pyegwang_shard × 1
    - 폐광길 짐 더미 (위험): mat_ore_rusty_scrap × 2 (effect_magnitude=2.0)
    - 먼지 길 여행자 조우 (호위 성공): mat_hide_dry_strap × 1
    - 먼지 길 도적 흔적: mat_hide_faded_cloth × 1
  - **option_id 매핑 위임**: 페이즈 4 #1 시점 travel_choice_options 30행에 본 명세의 6개 결과가 매핑될 option이 존재하는지 사전 조회 필요. 미존재 시 신규 option INSERT를 동반해야 함 (본 명세 §5 SQL 작성 시 검증)
  - **CHECK 제약 사전 조회 필요**: `travel_choice_results.effect_type` CHECK 제약 존재 여부 — 존재 시 'material_drop' 추가 ALTER

#### (l) `data_versions` 갱신 (FR-15)

- **[FR-15]** 신규 INSERT/UPDATE 적용 후 `data_versions` 갱신
  - `quest_pool_material_drops`: 기존 행 version + 1 (페이즈 4 #1에서 INSERT됨)
  - `travel_choice_results`: 기존 행 version + 1
  - region_discoveries / chain_quests 등은 변경 없음 (페이즈 4 #1에서 이미 갱신)

### 2.2 데이터 요구사항

#### 신규 Hive 박스/필드

- 신규 박스: **없음**
- **변경 박스**: `regionStates` (typeId 8) — `firstAcquiredMaterialIds` HiveField 7 신규 필드 추가
- **변경 enum**: `ActivityLogType` (typeId 6) — `inventoryStackCapped` HiveField 28 신규 추가
- 신규 typeId: **없음** (기존 typeId 8 RegionState 내부 필드 + typeId 6 ActivityLogType enum 값만 추가)
- CLAUDE.md HiveField 점유표 갱신: RegionState 다음 7 → **8** / ActivityLogType 다음 28 → **29**

#### 신규/변경 정적 데이터 모델

| 모델 | 변경 내용 |
|---|---|
| `RegionState` (Hive) | `firstAcquiredMaterialIds: List<String>` HiveField 7 신규 추가 (Default: []) |
| `ActivityLogType` (Hive enum) | `inventoryStackCapped` HiveField 28 신규 enum 값 추가 |
| (그 외) | 페이즈 4 #1·#2에서 등록된 모델 그대로 사용 — 변경 0건 |

#### 도메인 서비스 시그니처 변경

| 서비스 | 변경 내용 |
|---|---|
| `ChainQuestService.completeChain` 또는 `onStepCompleted` | `addRewardItems` 콜백 파라미터 신규 추가 |
| `RegionStateRepository.addAcquiredMaterial(int, String)` | 신규 메서드 추가 |
| `CraftingService.evaluateState` (firstAcquiredItem 분기) | 영속 평가로 교체 (RegionState.firstAcquiredMaterialIds 사용) |
| `EliteLootService.rollDrops` | drop_type='material' 분기 추가 |
| `QuestGenerator.generateQuests` | step 3 강제 spawn 분기 추가 |
| `MovementNotifier.applyTravelChoiceEffect` | 'material_drop' case 추가 |
| `MovementNotifier.summarizeEffect` | 'material_drop' case 추가 |
| `InvestigationNotifier._completeInvestigation` | discovery_data.items 적용 분기 추가 |
| `RegionStateRepository.addSettlementTrust` | 단계 진입 재료 보너스 분기 추가 |
| `QuestListNotifier._applyCompletionResult` | quest_pool_material_drops 매핑 적용 추가 |

#### Supabase 테이블 변경

| 테이블 | 작업 |
|---|---|
| `quest_pool_material_drops` | INSERT 약 18행 (페이즈 4 #1에서 스키마만 신설됨) |
| `travel_choice_results` | INSERT 6행 + (CHECK 제약 존재 시) ALTER 'material_drop' 추가 |
| `data_versions` | UPDATE 2행 (quest_pool_material_drops / travel_choice_results version + 1) |
| (그 외) | 페이즈 4 #1에서 적용 완료 — 본 명세 변경 0건 |

#### 밸런스 수치

본 명세서는 페이즈 1 #2 / 페이즈 2 #1 / 페이즈 4 #1·#2 산출물의 수치를 그대로 적용. 임의 변경 없음.

- 5종 출처 drop_rate — 페이즈 2 #1 §1-1
- 단계 진입 재료 보너스 — 페이즈 2 #1 §1-6 (2단계 #6 ×1, 3단계 #1 ×3)
- region_discoveries discovery_data — 페이즈 4 #1 §5.7
- chain_quests reward_items — 페이즈 4 #1 §5.8
- elite_giant_bat 시그니처 송곳니 — 페이즈 4 #1 §5.6 (drop_rate 1.0)

### 2.3 UI 요구사항

해당 없음. 본 명세서는 백엔드 hook + 영속 모델 + 데이터 INSERT 전용. UI는 페이즈 4 #2에서 처리 완료.

다만 다음 간접 효과:
- 인벤토리 4탭째 MaterialTab(페이즈 4 #2)에 실제 InventoryItem이 누적되어 표시됨
- RecipeCard 4상태 평가가 실 데이터 기반으로 작동 (잠김/부족/충족 전환)

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `_applyCompletionResult` 라인 653 인근에 quest_pool_material_drops 매핑 적용 hook 추가 | FR-1 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `onChainCompleted` 콜백에 `addRewardItems` 콜백 신규 전달 (라인 873~892) | FR-6 |
| `band_of_mercenaries/lib/features/quest/domain/elite_loot_service.dart` | `rollDrops` switch에 'material' 분기 추가 (라인 39 인근) | FR-2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `generateQuests` elite spawn 루프에 거대 박쥐 step 3 강제 spawn 분기 추가 (라인 130~159) | FR-3 |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart` | `_completeInvestigation` 라인 282~286 인근에 discovery_data.items 적용 hook 추가 | FR-4 |
| `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart` | `applyTravelChoiceEffect` switch에 'material_drop' case 추가 + `summarizeEffect` 갱신 | FR-5 |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | `completeChain` 또는 `onStepCompleted` 시그니처에 `addRewardItems` 콜백 추가 + step 진행 시 rewardItems 순회 호출 | FR-6 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | `addSettlementTrust` 라인 174 직후 단계 진입 재료 보너스 분기 추가 + 신규 `addAcquiredMaterial` 메서드 | FR-7·9 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | `firstAcquiredMaterialIds` HiveField 7 신규 필드 추가 | FR-8 |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` | `evaluateState` firstAcquiredItem 분기를 RegionState 영속 평가로 교체 + TODO 주석 제거 | FR-10 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType.inventoryStackCapped` HiveField 28 enum 값 추가 (라인 60 후) | FR-11 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/supabase/migrations/20260505_m5_phase4_3_drop_hooks.sql` | quest_pool_material_drops INSERT 약 18행 + travel_choice_results INSERT 6행 + data_versions UPDATE 2행 (단일 트랜잭션) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | RegionState HiveField 7 추가로 hive_generator 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType HiveField 28 추가로 hive_generator 재생성 |

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 1회 실행 필요.

### 3.4 관련 시스템

- **인벤토리 시스템 (M2a + 페이즈 4 #2)**: InventoryRepository.addItem 호출 5종 hook으로 분산. 999 stack 클램프는 페이즈 4 #2 정합 — 사전 평가로 호출 측이 인지
- **퀘스트 시스템 (M1)**: QuestCompletionService → _applyCompletionResult에 재료 드랍 적용. EliteLootService 분기. QuestGenerator spawn 정책 분기
- **이동 시스템 (M3)**: MovementNotifier travel choice 효과에 'material_drop' 케이스 추가
- **연계 퀘스트 시스템 (M3)**: ChainQuestService 콜백 DI 패턴 정합 — `addRewardItems` 콜백 추가
- **지역 조사 시스템 (M3)**: InvestigationNotifier 발견 hook 추가. RegionStateRepository에 메서드 1개 신규
- **시작 거점 시스템 (M4)**: RegionStateRepository.addSettlementTrust 단계 진입 보상에 재료 1행씩 추가 (golden path 정합)
- **신뢰도 시스템 (M4)**: 2/3단계 진입 시 일회성 재료 보너스 자동 지급
- **엘리트 시스템 (M2b + 페이즈 4 #1)**: EliteLootService drop_type='material' 분기. QuestGenerator 거대 박쥐 강제 spawn
- **CraftingService (페이즈 4 #2)**: firstAcquiredItem 평가가 임시 InventoryRepository → 영속 RegionState로 교체 (페이즈 4 #2 TODO 주석 해제)
- **build_runner**: RegionState 모델 변경 → 일괄 재생성 필요

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **드랍 hook 적용 패턴**: `quest_provider.dart` 라인 641~653 — 기존 eliteLoot 처리(`for (final itemId in result.eliteLoot!.itemDrops) { await inventoryRepository.addItem(...) }`)와 동일 흐름. quest_pool_material_drops 적용도 이 직후에 동일 루프 추가
- **콜백 DI 패턴**: `chain_quest_service.dart` `logActivity` / `onChainCompleted` 콜백 — `addRewardItems` 콜백도 동일 위치에 추가하여 호출 측에서 inventory 처리
- **단계 진입 보너스 패턴**: `region_state_repository.dart` `addSettlementTrust` 라인 154~174 — 골드/XP/명성 합산 후 일회성 적용. 재료 보너스도 동일 위치에 추가
- **Hive 모델 필드 추가 패턴**: M4 페이즈 4 #5에서 `RegionState`에 settlementTrust(HiveField 4), settlementTrustLevel(HiveField 5), lastEventCompletedAt(HiveField 6) 추가한 패턴 — `firstAcquiredMaterialIds`(HiveField 7)도 동일 패턴
- **drop_type 분기 패턴**: `elite_loot_service.dart` 라인 32~49 — 'gold'/'essence'/'equipment'/'guild_item' 케이스에 'material' 추가
- **effect_type 분기 패턴**: `movement_provider.dart` `applyTravelChoiceEffect` switch — 기존 8종 effectType에 'material_drop' 추가
- **discovery_data 파싱 패턴**: 페이즈 4 #1 §5.7 SQL이 `{"items":[...]}` 형태로 INSERT — investigation_notifier에서 `Map<String, dynamic>?` 파싱
- **Supabase 단일 트랜잭션 마이그레이션**: 페이즈 4 #1 SQL 파일과 동일 BEGIN/COMMIT 구조 + `mcp__plugin_supabase_supabase__apply_migration` 적용
- **CraftingService firstAcquiredItem TODO 해제**: 페이즈 4 #2 spec.md §FR-4 영속 추적 위임 명시

### 4.2 주의사항

- **CLAUDE.md HiveField 정책 준수**: RegionState typeId 8 그대로, HiveField 7 신규 등록. 신규 typeId 발급 없음
- **build_runner 재실행 필수**: RegionState 변경으로 `region_state_model.g.dart` 재생성. `--delete-conflicting-outputs` 권고
- **avoid_print rule**: SQL 마이그레이션 결과 로깅 금지
- **중복 hook 호출 방지**: §FR-1 / §FR-4 / §FR-5 / §FR-6 / §FR-7에서 모두 `addAcquiredMaterial` 호출 → 멱등성 보장(§FR-9)으로 중복 안전
- **거대 박쥐 step 3 매핑 하드코딩 사유**: M5 단일 거점/단일 사건이라 `quest_generator.dart`에 1줄 하드코딩 + TODO 주석. M6+ 다중 거점/다중 사건 도입 시 데이터 모델 확장 (`elite_monsters`에 `fixed_chain_id`/`fixed_step` 컬럼 또는 신규 매핑 테이블)
- **999 stack 사전 평가**: addItem 호출 전 `getQuantityForItemId >= 999` 체크. 신규 enum 추가는 코더 재량 (본 명세 권고는 메시지 텍스트 구분 또는 신규 `inventoryStackCapped` HiveField 28)
- **firstAcquiredItem 영속화 vs 임시 평가 차이점**: 페이즈 4 #2는 InventoryRepository 보유량으로 평가 (소비 시 풀림), 본 명세는 RegionState 영속 추적 (한 번 입수하면 영구). recipe_dustvile_miner_charm 해금 안정성 확보
- **다중 단계 동시 도달 처리**: `addSettlementTrust`가 한 번에 oldLevel=1 → newLevel=3로 점프 가능 → 2단계와 3단계 보너스 모두 지급 (>= 비교)
- **운영 도구 영향 (operation-bom)**: travel_choice_results.effect_type CHECK 제약에 'material_drop' 추가 시 `table-config.ts` 셀렉트 옵션 동기화 필요 — 별도 운영 도구 작업
- **resettable: true 처리**: disc_dustvile_pyegwang_deepest의 `resettable: true`는 본 명세 범위 외 (한 번 발견 후 reset 메커니즘 별도 검토 필요 — 페이즈 1 #2 §3-2 정합)

### 4.3 엣지 케이스

- **quest_pool_material_drops 매핑 의뢰가 미존재**: implement-agent/coder가 사전 조회로 quest_pools 25행 id 정확히 매칭 확인. 미존재 의뢰 (`qp_dv_d2_*` 등 페이즈 4 #1 시점 변경 가능성)는 SQL INSERT에서 제외
- **travel_choice_options 매핑 옵션 부재**: 페이즈 2 #1 §1-4 6개 결과가 매핑될 옵션이 페이즈 4 #1 시점 travel_choice_options 30행에 존재하지 않으면 신규 옵션 INSERT 동반. 사전 조회 필수
- **999 stack 도달 + drop hook 동시**: drop hook이 999 도달 직전 stack 보유량 + drop_quantity > 999면 InventoryRepository.addItem이 999로 클램프 + 호출 측이 사전 평가로 인지
- **거대 박쥐 spawn 실패**: shouldForceSpawn = true이면 random 무시하고 100% spawn → spawn 실패 케이스 없음
- **firstAcquiredMaterialIds 누적 한계**: List에 12개 재료 + 결과물 8개 = 최대 20개 itemId 누적 → 데이터량 작음, 성능 영향 없음
- **chain_quests step 3 빈 reward_items**: `{}` 빈 맵이면 `addRewardItems` 콜백 호출 0회 → step 3 보상은 EliteLootService 거대 박쥐 송곳니로 처리 (정합)
- **신뢰도 단계 진입 시 staticData 미로딩**: `ref.read(staticDataProvider).valueOrNull == null` 케이스 방어. 정상 흐름에서는 발생하지 않으나 앱 초기화 시점 가능성 → null 체크 후 무시
- **region 3 외 region 신뢰도 보너스**: M5 시점 region 3 한정. `addSettlementTrust(regionId)`이 region 3가 아니면 재료 보너스 분기 자체 미실행 (`if (regionId == GameConstants.startingRegionId)` 가드)
- **deepest discovery resettable 미처리**: 본 명세는 1회 적용만. 재발견 시도 시 InvestigationNotifier 라인 122~131의 중복 방지 로직으로 차단됨 (정합 — 페이즈 1 #2 §3-2)

### 4.4 구현 힌트

- **진입점 1 — 의뢰 완료**: `QuestListNotifier._completeQuest()` (quest_provider.dart 라인 524~601) → `_applyCompletionResult()` (라인 603~940) 라인 653 직후
- **진입점 2 — 엘리트 처치**: `EliteLootService.rollDrops()` 라인 32~49 switch
- **진입점 3 — 의뢰 생성 시 elite spawn**: `QuestListNotifier.generateQuests()` (quest_provider.dart 라인 153~201) → `QuestGenerator.generateQuests()` (라인 12~32, spawn 루프 라인 130~159)
- **진입점 4 — 조사 발견**: `InvestigationNotifier._completeInvestigation()` 라인 80~120 → discovery 처리 라인 122~286
- **진입점 5 — 이동 선택 결과 적용**: `MovementNotifier.applyTravelChoiceEffect()` 라인 447~500
- **진입점 6 — 체인 step 진행**: `ChainQuestService.onStepCompleted` (또는 `completeChain`) → `quest_provider.dart` 라인 873~892 호출 측
- **진입점 7 — 신뢰도 단계 진입**: `RegionStateRepository.addSettlementTrust()` 라인 126~207
- **데이터 흐름** (의뢰 완료):
  ```
  QuestListNotifier._completeQuest()
    → QuestCompletionService.calculate() (순수 계산)
    → _applyCompletionResult(quest, result)
      → eliteLoot 처리 (기존)
      → quest_pool_material_drops 매핑 (신규 FR-1)
        → for each drop: random < dropRate ? addItem + addAcquiredMaterial
      → mercDamage 처리 (기존)
  ```
- **데이터 흐름** (체인 step):
  ```
  ChainQuestService.onStepCompleted
    → step 진행 (currentStep += 1)
    → currentStep.rewardItems 순회
      → addRewardItems(itemId, quantity) 콜백
        → quest_provider 측: addItem + addAcquiredMaterial
  ```
- **참조 구현**:
  - eliteLoot 처리: `quest_provider.dart` 라인 641~653
  - 콜백 DI: `chain_quest_service.dart` `logActivity`/`onChainCompleted` 패턴
  - HiveField 추가: `region_state_model.dart` settlementTrust HiveField 4 패턴
  - drop_type 분기: `elite_loot_service.dart` 'essence' case
  - effect_type 분기: `movement_provider.dart` 'item' case
  - addSettlementTrust 단계 보상: `region_state_repository.dart` 라인 154~174 (M4 페이즈 4 #5 골드/XP/명성)
- **확장 지점**:
  - M5 종료 후 M6+: 거대 박쥐 강제 spawn 매핑을 데이터 모델로 마이그레이션 (elite_monsters 컬럼 또는 신규 테이블)
  - M5 종료 후 M6+: travel_choice_results.effect_type 'material_drop' 활용을 다른 거점으로 확장
  - 다중 거점 도입 시: firstAcquiredMaterialIds가 region별 자연 분리 → 모델 변경 0건

---

## 5. 마이그레이션 SQL (인라인)

본 절은 페이즈 4 #3 SQL 인라인 처리 약 25행. Supabase migrations에 단일 SQL 파일로 작성하여 `apply_migration`으로 적용한다.

### 5.1 사전 조회 (코더가 첫 단계로 실행)

```sql
-- quest_pools 25행 id 정확히 매칭 확인
SELECT id FROM quest_pools WHERE region_diff = 1 ORDER BY id;

-- travel_choice_options 30행 + travel_choice_results 매핑 확인
SELECT id, option_id, effect_type FROM travel_choice_results ORDER BY id;
SELECT id, event_id, label FROM travel_choice_options WHERE event_id IN (SELECT id FROM travel_choice_events WHERE region_id = 3) ORDER BY id;

-- travel_choice_results.effect_type CHECK 제약 존재 여부 조회
SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint
WHERE conrelid = 'travel_choice_results'::regclass AND contype = 'c';
```

### 5.2 quest_pool_material_drops INSERT (페이즈 2 #1 §1-1 매핑)

```sql
BEGIN;

INSERT INTO quest_pool_material_drops (pool_id, item_id, drop_rate, qty_min, qty_max) VALUES
  -- chore 의뢰 (10건 중 3건 매핑)
  ('dustvile_chore_03', 'mat_herb_dry', 1.0, 1, 3),
  ('dustvile_chore_03', 'mat_herb_dust_resin', 1.0, 1, 1),  -- #5 접착 수액 확정 1개
  ('dustvile_chore_03', 'mat_herb_dust_resin', 0.2, 1, 1),  -- #5 접착 수액 보너스 0.2 추가 1개 (페이즈 2 #1 §1-1 / 조정 1 (a) "1.0 + 0.2 보너스" 평균 1.2개/회 정합)
  ('dustvile_chore_05', 'mat_hide_dry_strap', 0.4, 1, 1),
  ('dustvile_chore_06', 'mat_ore_rusty_scrap', 1.0, 1, 1),
  ('dustvile_chore_10', 'mat_hide_dry_strap', 0.8, 1, 2),
  -- dungeon 의뢰
  ('qp_dv_d1_scout', 'mat_ore_rusty_scrap', 0.6, 1, 1),
  ('qp_dv_d3_tool', 'mat_ore_rusty_scrap', 0.6, 1, 1),
  ('qp_dv_d4_rubble', 'mat_ore_rusty_scrap', 1.0, 1, 2),
  ('qp_dv_d5_check', 'mat_ore_rusty_scrap', 0.6, 1, 1),
  -- field 의뢰
  ('qp_dv_f3_dog', 'mat_hide_dry_strap', 0.8, 1, 2),
  ('qp_dv_f3_herb', 'mat_herb_dry', 1.0, 1, 2),
  ('qp_dv_f3_herb', 'mat_herb_mountain_mushroom', 0.5, 1, 1),
  -- (qp_dv_f3_herb → mat_relic_pyegwang_shard 매핑은 페이즈 2 #1 §1-1 / 페이즈 1 #2 §2-1에 미정의 — 컨셉 정합성 위해 제외. #8은 (b) 조사 발견과 (d) 이동 짐 더미가 출처)
  ('qp_dv_f3_patrol', 'mat_hide_dry_strap', 0.5, 1, 1),
  -- road 의뢰
  ('qp_dv_r4_bandit', 'mat_hide_dry_strap', 0.8, 1, 2),
  ('qp_dv_r4_escort', 'mat_hide_dry_strap', 0.5, 1, 1),
  -- village 의뢰
  ('qp_dv_v2_supply', 'mat_hide_faded_cloth', 0.05, 1, 1);

-- 약 17행 INSERT (chore_03 #5 두 행 분리 / qp_dv_f3_herb #8 행 제거. 사전 조회 결과에 따라 매핑 정확성 검증 — 위 id가 실제 quest_pools에 모두 존재해야 함)
```

### 5.3 travel_choice_results INSERT (페이즈 2 #1 §1-4 매핑)

```sql
-- 사전 조회로 정확한 option_id 결정 후 INSERT
-- effect_target = item_id, effect_magnitude = qty
-- 6행 신규 INSERT (option_id는 사전 조회 결과로 치환)
INSERT INTO travel_choice_results (id, option_id, effect_type, effect_magnitude, effect_target, description) VALUES
  ('tcr_dustvile_field_patrol_calm_mushroom', '{option_id_야간순찰_평온}', 'material_drop', 1.0, 'mat_herb_mountain_mushroom', '바위틈에서 산기슭 버섯을 발견했다.'),
  ('tcr_dustvile_field_patrol_dog_strap', '{option_id_야간순찰_들개}', 'material_drop', 1.0, 'mat_hide_dry_strap', '들개를 처리하고 가죽끈을 건졌다.'),
  ('tcr_dustvile_dungeon_pile_calm_shard', '{option_id_짐더미_평온}', 'material_drop', 1.0, 'mat_relic_pyegwang_shard', '짐 더미 속에서 정체 모를 유물 파편을 발견했다.'),
  ('tcr_dustvile_dungeon_pile_danger_scrap', '{option_id_짐더미_위험}', 'material_drop', 2.0, 'mat_ore_rusty_scrap', '위험을 무릅쓰고 쇳조각 두 개를 회수했다.'),
  ('tcr_dustvile_road_traveler_escort_strap', '{option_id_여행자_호위}', 'material_drop', 1.0, 'mat_hide_dry_strap', '여행자 호위에 성공해 가죽끈 한 묶음을 받았다.'),
  ('tcr_dustvile_road_bandit_trace_cloth', '{option_id_도적흔적_희귀}', 'material_drop', 1.0, 'mat_hide_faded_cloth', '도적의 흔적에서 빛바랜 천 조각을 찾았다.');

-- effect_type CHECK 제약이 존재하면 사전 ALTER 필요:
-- ALTER TABLE travel_choice_results DROP CONSTRAINT travel_choice_results_effect_type_check;
-- ALTER TABLE travel_choice_results ADD CONSTRAINT travel_choice_results_effect_type_check
--   CHECK (effect_type IN ('gold', 'reputation', 'injury', 'heal_tired', 'trait_innate', 'trait_acquired', 'item', 'material_drop', 'nothing'));
```

### 5.4 data_versions 갱신

```sql
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'quest_pool_material_drops';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'travel_choice_results';

COMMIT;
```

**총 SQL 변경량**:
- INSERT quest_pool_material_drops 약 17행 (chore_03 #5 보너스 분리 + qp_dv_f3_herb #8 행 제거 결과 17행 유지)
- INSERT travel_choice_results 6행
- (CHECK 제약 존재 시) ALTER travel_choice_results 1건
- UPDATE data_versions 2행

→ **총 약 25행 변경**

---

## 6. 기획 확인 사항

본 명세서는 페이즈 1·2 산출물 + 페이즈 4 #1·#2 인프라가 모든 결정을 명시했으나, 다음 항목은 사용자 확인이 권고된다:

### 6.1 사용자 확인이 권고되는 항목

- **[Q-1] firstAcquiredItem 영속화 위치**: `RegionState.firstAcquiredMaterialIds` HiveField 7 (region별 추적, 본 명세 권고) vs `UserData.firstAcquiredItemIds` HiveField 24 (글로벌 추적) → 본 명세 권고 **RegionState** (다중 거점 확장성 우수, M5 region 3 한정 자연 정합). 사용자 확인 권고.

- **[Q-2] 거대 박쥐 step 3 강제 spawn 매핑 방식**:
  - (A) `quest_generator.dart`에 1줄 하드코딩 + TODO 주석 (본 명세 권고 — M5 단일 사건 한정)
  - (B) `elite_monsters`에 `fixed_chain_id`/`fixed_step` 컬럼 추가 (마이그레이션 부담)
  - (C) 신규 매핑 테이블 (`fixed_step_elites`)
  - → 본 명세 권고 **(A)** + M6+ 다중 거점 시 데이터 모델로 마이그레이션. 사용자 확인 권고.

- **[Q-3] 999 stack 도달 알림 방식 (확정 — verify-spec 1차 ISSUE-3 반영)**: 신규 `ActivityLogType.inventoryStackCapped` HiveField 28 추가로 확정. CLAUDE.md HiveField 점유표 갱신: ActivityLogType 다음 HiveField 28 → 29. 분류 명확성 + verifier 검증 가능성 확보. FR-11에 본문 코드 흐름 반영 완료.

### 6.2 코더 재량 항목

- **[Q-4] ChainQuestService 콜백 vs Repository 주입**: `addRewardItems` 콜백 추가 (본 명세 권고 — 기존 콜백 DI 패턴 정합) vs `InventoryRepository` 직접 주입 → 본 명세 권고 **콜백 추가**. 코더 재량 허용.

- **[Q-5] travel_choice_results.effect_magnitude(double) 재활용**: qty를 effect_magnitude로 표현 (본 명세 권고) vs 모델에 qty 필드 신규 추가 (마이그레이션 부담) → 본 명세 권고 **effect_magnitude 재활용**(`.toInt()`). 코더 재량 허용.

- **[Q-6] resettable: true 처리 (disc_dustvile_pyegwang_deepest)**: 본 명세 범위 외 — 1회 적용만 (페이즈 1 #2 §3-2 정합). 후속 마일스톤에서 reset 메커니즘 별도 설계.

- **[Q-7] quest_pool_material_drops INSERT 행 수 변동**: 페이즈 4 #1 시점 quest_pools 25행 id가 정확히 매칭되지 않으면 SQL INSERT에서 제외 (사전 조회 후 코더가 결정). 본 명세 §5 SQL은 매핑 가이드라인이며 실제 INSERT는 사전 조회 결과 정합.

- **[Q-8] travel_choice_options option_id 매핑 부재**: 페이즈 2 #1 §1-4 6개 결과가 매핑될 옵션이 페이즈 4 #1 시점 travel_choice_options에 존재하지 않으면 신규 옵션 INSERT 동반 (코더 사전 조회 후 결정). 본 명세 §5 SQL의 `{option_id_*}` 토큰을 실제 id로 치환.

### 6.3 검증 완료 사항 (페이즈 4 #1·#2 적용 결과)

| 항목 | 결과 | 근거 |
|---|---|---|
| `quest_pool_material_drops` 테이블 스키마 | 신설 완료 | 페이즈 4 #1 commit `3b6506c` |
| `chain_quests.reward_items` 6 step UPDATE | 적용 완료 | 페이즈 4 #1 SQL §5.8 |
| `region_discoveries` 3행 INSERT | 적용 완료 | 페이즈 4 #1 SQL §5.7 |
| `elite_giant_bat` + elite_loot_tables 1행 | 적용 완료 | 페이즈 4 #1 SQL §5.6 |
| `ActivityLogType.craftCompleted` HiveField 27 | 적용 완료 | 페이즈 4 #1 |
| `RegionState` typeId 8 / 다음 HiveField 7 | CLAUDE.md 정합 확인 | 본 명세 §FR-8 |
| `CraftingService.evaluateState` firstAcquiredItem 임시 평가 | 페이즈 4 #2에서 TODO 명시 | 페이즈 4 #2 spec.md §FR-4 |
| 인벤토리 4탭 MaterialTab + RecipeListSection | UI 구현 완료 | 페이즈 4 #2 commit `d03c5b4` |
| InventoryRepository.addItem material 분기 + 999 클램프 | 구현 완료 | 페이즈 4 #2 commit `d03c5b4` |
| InventoryRepository.consumeMaterial / getQuantityForItemId | 구현 완료 | 페이즈 4 #2 |

---

## 7. M5 마일스톤 종료 조건 검증 (본 페이즈 완료 후)

본 페이즈 4 #3 완료로 M5 마일스톤 종료 조건이 모두 충족된다:

| 종료 조건 | 충족 여부 | 근거 |
|---|---|---|
| 재료 인벤토리 별도 구분 | ✅ | 페이즈 4 #2 인벤토리 4탭째 MaterialTab |
| 제작 레시피 충족/부족 표시 | ✅ | 페이즈 4 #2 RecipeCard 4상태 |
| 출처 3개 이상 연결 | ✅ | 본 페이즈 5종 출처 hook 모두 활성 (페이즈 1 #2 §2-1 정합 — 5개 모두 연결) |
| 첫 제작 목표 3개 달성 가능 | ✅ | 본 페이즈 hook으로 깃발 복원·광부 단검·폐광 유물 조각 모두 제작 가능 |
| 완제품 드랍과 제작 루트 공존 | ✅ | 페이즈 2 #3 검증 — 격차 보존 |
| 첫 제작 30~45분 (이상 시나리오 38분) | ✅ | 페이즈 2 #1 시뮬레이션 정합 |
| 첫 희귀 장비 90~150분 (광부 단검 60분, 폐광 유물 98분) | ✅ | 페이즈 2 #1 시뮬레이션 정합 |
