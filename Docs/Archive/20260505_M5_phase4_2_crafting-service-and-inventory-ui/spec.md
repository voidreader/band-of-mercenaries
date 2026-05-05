# M5 페이즈 4 #2 — CraftingService + 인벤토리 4탭 + 낡은 대장간 제작 UI 개발 명세서

> 기획 문서:
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-content-material-taxonomy.md` (페이즈 1 #1 — 분류 체계 / 4탭 구조 / stack_max 999)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-content-dustvile-recipes.md` (페이즈 1 #3 — 레시피 10개 + 해금 정책)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-content-dustvile-craft-ui.md` (페이즈 1 #4 — UI 컨셉 + 4상태 카드 + 양방향 점프)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-balance-recipe-effects.md` (페이즈 2 #2 — 8종 effect_json 확정)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/design-balance-material-droprate.md` (페이즈 2 #1 — 첫 제작 38분 학습 곡선)
> - `Docs/Archive/20260504_M5_phase4_1_data-migration/spec.md` + `plan.md` (페이즈 4 #1 — 데이터 인프라)
>
> 작성일: 2026-05-05
> 마일스톤: M5 페이즈 4 #2
> 선행: 페이즈 4 #1 완료 (commit `3b6506c`) — Supabase items 22행 + crafting_recipes 10행 + region_discoveries 3행 + chain_quests UPDATE 6 + elite_giant_bat 1 + ActivityLogType.craftCompleted HiveField 27 + GameConstants.stackMaxByCategory + CraftingRecipeData/QuestPoolMaterialDropData Freezed + StaticGameData 확장 + SyncService 등록 모두 적용 완료
> 후속: 페이즈 4 #3 (드랍 출처 hook + region_discoveries 발견 hook + 신뢰도 단계 진입 보너스 + 거대 박쥐 step 3 강제 spawn)
> Visual Companion: 미적용 (UI 컨셉은 페이즈 1 #4가 ASCII 와이어프레임으로 충분히 명세 — 본 문서는 위젯 계층·상태 변수·진입 조건만 텍스트화)

---

## 1. 개요

M5 "재료와 제작" 마일스톤의 핵심 기능 면을 구축한다. 페이즈 4 #1에서 적용된 데이터 인프라(crafting_recipes 10행 / items 22행 / `CraftingRecipeData` 모델 / `ActivityLogType.craftCompleted` 등)를 그대로 사용하여, **`CraftingService` 도메인 서비스**(레시피 4상태 평가 + 제작 실행) + **인벤토리 화면 4탭째 MaterialTab**(slot 6칩 + 재료 카드) + **낡은 대장간 정식 제작 화면**(M4 stub 3 tile → 레시피 목록 + 2버튼)을 신설한다. 양방향 점프 4시나리오 + 즉시 토스트 피드백으로 학습 모멘트를 형성한다. 페이즈 4 #3(드랍 출처 hook)이 본 명세 후 실 InventoryItem 추가 경로를 활성화한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### CraftingService 도메인 서비스 신설

- **[FR-1]** `CraftingService` 신규 클래스 (도메인 서비스, 콜백 DI 패턴)
  - 위치: `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart`
  - 책임: 레시피 4상태 평가 + 제작 실행(재료 차감 + 결과물 추가 + ActivityLog 기록)
  - 시그니처:
    ```dart
    class CraftingService {
      const CraftingService({
        required this.staticData,
        required this.inventoryRepository,
        required this.regionStateRepository,
        required this.chainQuestRepository,
        required this.userDataNotifier,
        required this.activityLogNotifier,
        required this.firstAcquiredItemIds, // 파라미터로 주입 (페이즈 4 #3에서 RegionState 또는 별도 박스로 영속화 결정)
      });

      RecipeState evaluateState(CraftingRecipeData recipe);
      Future<CraftingResult> craft(String recipeId);
    }
    ```
  - `RecipeState`: enum `locked` / `insufficient` / `ready` (M5 MVP는 `crafted` 미적용)
  - `CraftingResult`: `success(InventoryItem)` / `failure(reason: lockMissing | materialShortage | unknown)`
  - 의존성: 콜백 DI (ChainQuestService 패턴 차용 — `chain_quest_service.dart` 참조)

- **[FR-2]** `evaluateState(recipe)` 분기 평가
  - 1순위: `unlockCondition` 평가 → 미충족이면 `locked`
    - `unlockCondition == null` → 무조건 해금
    - `unlockCondition.trustLevel != null` → `regionStateRepository.getSettlementTrust(GameConstants.startingRegionId).level >= trustLevel`
    - `unlockCondition.chainStep != null` → `chainQuestRepository.getProgress(chainId).status == completed AND currentStep > step`
    - `unlockCondition.firstAcquiredItem != null` → `firstAcquiredItemIds.contains(itemId)` (M5 MVP는 InventoryItem 보유 여부로 대체 — 페이즈 4 #3에서 영속 추적 결정)
  - 2순위: `inputs` 보유 평가 → 부족이면 `insufficient`
    - 각 `RecipeInput`에 대해 `inventoryRepository.getQuantityForItemId(itemId) >= quantity`
  - 모두 충족 → `ready`

- **[FR-3]** `craft(recipeId)` 제작 실행
  - 1단계: `evaluateState` 재실행 → `ready` 아니면 `failure` 반환
  - 2단계: `inputs` 각 항목에 대해 `inventoryRepository.consumeMaterial(itemId, quantity)` 호출 (다중 InventoryItem 행에서 차감)
  - 3단계: `inventoryRepository.addItem(resultItemId, quantity: result_quantity)` 호출 (페이즈 4 #1에서 추가된 'material' 케이스가 stack 누적, equipment는 신규 행)
  - 4단계: `activityLogNotifier.addLog('{결과물 이름} 제작 완료', ActivityLogType.craftCompleted)` 기록
  - 5단계: `success(InventoryItem)` 반환 — 호출 측이 토스트 표시 책임

- **[FR-4]** `RecipeUnlockCondition.firstAcquiredItem` 평가 정책
  - M5 MVP: `inventoryRepository.getById(itemId)` 또는 `getQuantityForItemId(itemId) > 0` 으로 평가 (현재 보유 여부)
  - 한계: 첫 입수 후 모두 소비하면 `firstAcquiredItem` 해금이 풀릴 수 있음. 본 명세 범위에서는 이 한계를 수용하되, 코더는 페이즈 4 #3 "첫 입수 영속 추적" 위임 명시 주석을 코드에 1줄 남길 것
  - 페이즈 4 #3에서 `RegionState.firstAcquiredMaterialIds Set<String>` 또는 `UserData.firstAcquiredItemIds` 영속화 결정 (본 명세 범위 외)

#### 신규 Provider 추가

- **[FR-5]** Riverpod Provider 4종 신규
  - 위치: `band_of_mercenaries/lib/features/crafting/domain/crafting_provider.dart`
  - 정의:
    ```dart
    final craftingServiceProvider = Provider<CraftingService>((ref) { ... });

    final craftingRecipesProvider = Provider<List<CraftingRecipeData>>((ref) {
      final staticData = ref.watch(staticDataProvider);
      return staticData.maybeWhen(
        data: (d) => d.craftingRecipes,
        orElse: () => const [],
      );
    });

    final recipeStateProvider = Provider.family<RecipeState, String>((ref, recipeId) {
      // gameTickProvider watch — 1초마다 재평가 (chain step·trust level·재료 보유량 변화 감지)
      ref.watch(gameTickProvider);
      final service = ref.watch(craftingServiceProvider);
      final recipes = ref.watch(craftingRecipesProvider);
      final recipe = recipes.firstWhere((r) => r.id == recipeId, orElse: () => throw ...);
      return service.evaluateState(recipe);
    });

    final materialUsageCountProvider = Provider.family<int, String>((ref, materialItemId) {
      // 재료 itemId가 들어가는 레시피 수 — 정적 데이터이므로 Provider 캐시
      final recipes = ref.watch(craftingRecipesProvider);
      return recipes.where((r) => r.inputs.any((i) => i.itemId == materialItemId)).length;
    });
    ```
  - `recipeStateProvider`는 `gameTickProvider` 의존 — 1초마다 재평가하여 chain step 완료/재료 보유량 변화 즉시 반영

- **[FR-6]** `craftingServiceProvider` 인스턴스화 시 콜백·Repository 주입
  - `staticData = ref.watch(staticDataProvider).requireValue` (또는 maybeWhen)
  - `inventoryRepository = ref.watch(inventoryRepositoryProvider)`
  - `regionStateRepository = ref.watch(regionStateRepositoryProvider)`
  - `chainQuestRepository = ref.watch(chainQuestRepositoryProvider)` 또는 `chainQuestProgressProvider` 직접 watch
  - `userDataNotifier = ref.read(userDataProvider.notifier)`
  - `activityLogNotifier = ref.read(activityLogProvider.notifier)`
  - `firstAcquiredItemIds = ref.watch(...)` — M5 MVP는 `inventoryRepository.getAll()` 기반 동적 계산 (페이즈 4 #3에서 영속 박스 도입 결정)

#### InventoryRepository material 분기

- **[FR-7]** `InventoryRepository.addItem`에 `'material'` 카테고리 stack 누적 케이스 추가
  - 위치: `band_of_mercenaries/lib/features/inventory/data/inventory_repository.dart` 라인 53 (`category == 'consumable'` 분기)
  - 변경: `if (itemData.category == 'consumable')` → `if (itemData.category == 'consumable' || itemData.category == 'material')`
  - 또는 `GameConstants.stackMaxByCategory[category] > 1` 기반 분기로 일반화 (코더 재량)
  - 효과: material 카테고리도 동일 itemId 기존 행에 수량 가산. 페이즈 4 #1 §"신규 박스 없음" 정책 정합

- **[FR-8]** `InventoryRepository.consumeMaterial(itemId, quantity)` 신규 메서드
  - 위치: `inventory_repository.dart`에 추가
  - 시그니처: `Future<void> consumeMaterial(String itemId, int quantity)`
  - 동작:
    - `getByItemId(itemId)` 또는 `getAll().where((r) => r.itemId == itemId).first` 조회
    - 보유량 < quantity 시 `StateError` 발생 (호출 측에서 evaluateState 후 호출하므로 정상 흐름에서 발생 안 함)
    - 보유량 ≥ quantity 시 `quantity -= delta`, 0이면 `delete()`, 그 외 `save()`
  - 기존 `decrementQuantity(id, delta)`는 InventoryItem.id 기반이므로 itemId 기반 별도 메서드 필요

- **[FR-9]** `InventoryRepository.getQuantityForItemId(itemId)` 신규 메서드
  - 동작: `_box.values.where((r) => r.itemId == itemId).fold(0, (sum, r) => sum + r.quantity)`
  - 용도: `evaluateState` 재료 보유량 평가

- **[FR-10]** stack_max 999 상한 적용
  - 위치: `addItem` material/consumable 케이스 — `existing.quantity + quantity > GameConstants.stackMaxByCategory[category]!` 시 999로 클램프 + 활동 로그 1행 (페이즈 1 #4 §5-3 정합 — "재료 보유량 가득" 토스트)
  - 본 명세 범위는 stack 클램프 처리만. 토스트는 호출 측 책임 (페이즈 4 #3 드랍 hook이 처리하므로 본 명세는 코드 분기만 추가)

#### 인벤토리 화면 4탭 확장

- **[FR-11]** `InventoryCategoryFilter` enum에 `material` 추가
  - 위치: `band_of_mercenaries/lib/features/inventory/view/inventory_screen.dart` 라인 14
  - 변경: `enum InventoryCategoryFilter { all, personalEquipment, guildEquipment, consumable, material }`

- **[FR-12]** `_categoryFilterToString` switch에 `material` 케이스 추가
  - 위치: 동일 파일 라인 150
  - 추가: `case InventoryCategoryFilter.material: return 'material';`

- **[FR-13]** `_buildCategoryFilter` 4 → 5 탭 확장
  - 위치: 동일 파일 라인 81~148
  - 변경: 마지막에 `filterTab(InventoryCategoryFilter.material, '재료')` 추가
  - 라벨: "재료" — 페이즈 1 #1 §7-1 정합

- **[FR-14]** `MaterialTabContent` 신규 위젯 — slot 6칩 sub-filter
  - 위치: `band_of_mercenaries/lib/features/crafting/view/material_tab_content.dart` 신규
  - 진입: `_buildList`에서 `_categoryFilter == InventoryCategoryFilter.material`이면 `MaterialTabContent`로 분기
  - 구성:
    - 상단: `MaterialSlotChipBar` (전체/광석/가죽/약초/유물 파편/몬스터 부산물 6칩, 가로 스크롤)
    - 본문: `MaterialItemCard` 리스트 (정렬: tier desc → 보유량 desc → id asc)
    - 빈 상태: `EmptyMaterialState` (페이즈 1 #4 §5-1 ASCII와 동일 — "아직 입수한 재료가 없습니다 + [출처 가이드 보기]")

- **[FR-15]** `MaterialItemCard` 신규 위젯 — 4정보 축
  - 위치: `band_of_mercenaries/lib/features/crafting/view/material_item_card.dart` 신규
  - 4정보 축 (페이즈 1 #4 §1-3):
    - 좌측 바: tier 색 (`AppTheme.tierColor(itemData.tier)`)
    - 상단 좌: 재료 이름 + slot 한국어 라벨 + tier
    - 상단 우: `🔨 ×N` 배지 (`materialUsageCountProvider(itemId)`)
    - 하단 우: 보유 수량 (3자리 고정, `getQuantityForItemId`)
  - region_exclusive 시각:
    - `itemData.regionExclusive != null` → `Border.all(color: AppTheme.settlementAccent, width: 1)` + 좌상단 작은 "더스트빌" 라벨 (`itemData.regionExclusive == 3`만 매핑 — M5 단일 거점)
  - 클릭: 카드 펼침 (인라인 `ExpansionTile` 패턴 — `OldSmithyScreen._CraftGoalTile` 참조) → 출처 1~3줄 + `🔨 ×N` 클릭 시 대장간 점프 버튼

- **[FR-16]** slot → 한국어 라벨 매핑 상수
  - 위치: `band_of_mercenaries/lib/features/crafting/domain/material_slot_labels.dart` 신규 (또는 GameConstants 확장 — 코더 재량)
  - 매핑:
    ```dart
    const Map<String, String> materialSlotLabels = {
      'material_ore': '광석',
      'material_hide': '가죽',
      'material_herb': '약초',
      'material_relic_fragment': '유물 파편',
      'material_monster_part': '몬스터 부산물',
    };
    ```

#### 낡은 대장간 정식 제작 화면 (M4 stub 진화)

- **[FR-17]** `OldSmithyScreen` 전면 재작성 — 3 tile → 레시피 목록 메인 + 2버튼
  - 위치: `band_of_mercenaries/lib/features/settlement/view/old_smithy_screen.dart` (기존 320줄 → 재작성)
  - **유지**: `_NpcHeader` (하겐 emoji + 신뢰도별 인사말 — `SettlementNpcData.greetingFor` 그대로 사용)
  - **폐기**: `_RepairMissionTile` 클래스 + `_repairReward` 메서드 + 수리 의뢰 관련 ActivityLog 호출 (`ActivityLogType.smithyRepairCompleted`는 enum 자체는 유지하되 본 화면에서 사용 안 함)
    - 단, `userData.lastSmithyRepairAt` 필드 자체는 페이즈 4 #1에서 이미 24시간 쿨다운 stub으로 등록되어 있음. 본 명세 범위 외 (UserData 모델 변경 금지)
  - **진화**: `_CraftGoalTile` → `RecipeListSection` (정식 레시피 목록)
  - **진화**: `_MaterialHintTile` → `[인벤토리에서 재료 보기]` 단일 OutlinedButton (Inventory tab 4번째로 점프)
  - 새 구성:
    ```
    Column(
      _NpcHeader(greeting),
      Divider,
      Padding (16px) {
        // 신뢰도 1단계: 빈 상태 (페이즈 1 #4 §5-2)
        // 신뢰도 2단계+: RecipeListSection (메인) + 하단 2버튼
        if (level < 2) EmptySmithyMessage()
        else RecipeListSection(),
        SizedBox(24),
        Row [
          OutlinedButton('인벤토리에서 재료 보기', onPressed: → currentTabProvider.set(...)),
          OutlinedButton('닫기', onPressed: onClose),
        ],
      }
    )
    ```

- **[FR-18]** `RecipeListSection` 신규 위젯
  - 위치: `band_of_mercenaries/lib/features/crafting/view/recipe_list_section.dart` 신규
  - 책임: `craftingRecipesProvider` 조회 → 정렬 → 그룹 헤더 삽입 → `RecipeCard` 리스트 렌더링
  - 정렬 정책 (페이즈 1 #4 §2-9):
    1. 4상태 우선순위: ready → insufficient → locked
    2. 동 상태 내 slot 그룹 (banner / weapon / armor / accessory / artifact / material 정제)
    3. 동 그룹 내 결과물 tier desc (T3 → T2)
    4. 동 tier 내 recipe_id asc
  - 자동 필터 컨텍스트: `recipeFilterMaterialIdProvider` (StateProvider<String?>) — null이 아니면 해당 재료를 사용하는 레시피만 표시. 상단에 "필터: {재료 이름} 사용" 칩 1개 + [필터 해제] 버튼

- **[FR-19]** `RecipeCard` 4상태 위젯 (잠김 / 부족 / 충족)
  - 위치: `band_of_mercenaries/lib/features/crafting/view/recipe_card.dart` 신규
  - 상태별 시각 (페이즈 1 #4 §2-2~§2-5):
    - **locked**: 카드 회색 + 🔒 + 결과물 이름 `???` + 해금 조건 텍스트 ("폐광 재개방 사건 step 6 완료" 등)
    - **insufficient**: 카드 반투명 60% + 결과물 이름 표시 + 입력 재료 X/Y 표기 (충족=초록, 부족=빨강 + ✓/✗ 아이콘) + [제작] 버튼 비활성 + 클릭 시 부족 재료 출처 힌트 펼침
    - **ready**: 카드 또렷 + 좌상단 "제작 가능" 초록 라벨 + 입력 재료 X/Y 모두 초록 ✓ + [제작] 버튼 활성 → 클릭 시 `craftingService.craft(recipeId)` 호출
  - 상태 평가: `recipeStateProvider(recipeId)` watch (gameTickProvider 의존이므로 1초마다 재평가)

- **[FR-20]** 양자택일 그룹 헤더 (페이즈 1 #4 §2-6)
  - banner 그룹 (`item_banner_dustvile_repaired` + `item_banner_herbalist_seal`):
    - 헤더 텍스트: "용병단 깃발 (banner 1슬롯 — 양자택일)"
    - 두 카드를 가로 또는 세로로 묶어 표시 (코더 재량 — 모바일 폭 430px 고려 시 세로 권장)
  - artifact 그룹 (`item_artifact_pyegwang_relic` + `item_artifact_miner_charm`):
    - 헤더 텍스트: "용병단 아티팩트 (artifact 2슬롯 — 동시 장착 가능)"
  - weapon (`item_weapon_miner_dagger` + `item_weapon_rusty_pickaxe`):
    - 그룹 헤더 없음 — 페이즈 1 #4 §2-6 정합 (다수 용병 분기 운용이라 명시 부담)
  - 그룹 헤더는 `RecipeGroupHeader` 작은 위젯으로 분리 (코더 재량)

- **[FR-21]** 부족 재료 펼침 + 출처 힌트
  - `insufficient` 상태 카드 클릭 시 카드 하단에 부족 재료 1~3개의 출처 힌트 1줄씩 표시
  - 출처 힌트 데이터 소스: 본 명세 범위에서는 인라인 const Map<String, String> `materialAcquisitionHints` 사용 (페이즈 1 #4 §1-6 표 텍스트 그대로)
  - 위치: `band_of_mercenaries/lib/features/crafting/domain/material_acquisition_hints.dart` 신규
  - 12종 재료 + 결과물 8종 = 총 20행 정도이지만 결과물은 `???` 처리이므로 재료 12종 힌트만 작성
  - 향후 i18n 또는 `items.acquisition_hint` DB 컬럼 도입은 페이즈 4 #3 또는 후속 마일스톤 결정 (페이즈 1 #4 §1-6 §"페이즈 4 #2 위임" 항목)
  - 출처 힌트 1줄 우측에 `[인벤토리에서 보기]` 작은 텍스트 링크 → 인벤토리 탭으로 점프 + 해당 slot chip 자동 선택

#### 양방향 점프 인터랙션

- **[FR-22]** 인벤토리 → 대장간 점프 (재료 카드 🔨 ×N 배지)
  - `MaterialItemCard`의 `🔨 ×N` 배지 클릭 시:
    - 마을 진입 상태 평가: `userDataProvider.location.region == 3 && location.sector == 1` (region 3 sector 1 village)
    - **마을 진입 상태**: `recipeFilterMaterialIdProvider.set(materialItemId)` + 거점 진입 (`selectedFacility = VillageFacility.oldSmithy`) + 인벤토리 닫기
    - **마을 미진입 상태**: `SnackBar` 토스트 "낡은 대장간에서 확인할 수 있습니다" 1.5초 + 이동 화면 강조 (없음 — 토스트만)

- **[FR-23]** 대장간 → 인벤토리 점프 (부족 재료 [인벤토리에서 보기] 링크)
  - `RecipeCard insufficient` 상태의 부족 재료 출처 힌트 우측 링크 클릭 시:
    - `materialJumpTargetItemIdProvider.set(itemId)` (StateProvider<String?>) 설정
    - 인벤토리 탭으로 currentTabProvider 전환 (`currentTabProvider.set(inventoryTabIndex)`)
    - 대장간 화면 닫기 (onClose 또는 selectedFacility 리셋)
  - 인벤토리 화면 진입 시 `materialJumpTargetItemIdProvider` 감지 → 4번째 탭(material)로 자동 전환 + 해당 재료 slot chip 자동 선택 + 카드 ScrollController.animateTo로 스크롤 → state 리셋

- **[FR-24]** 대장간 → 인벤토리 점프 (대장간 하단 [인벤토리에서 재료 보기] 버튼)
  - `OldSmithyScreen` 하단 버튼 클릭 시:
    - 대장간 화면 닫기 + 인벤토리 탭으로 전환 + material 탭(4번째) 자동 선택
    - 특정 재료 점프 없음 (전체 보기)

- **[FR-25]** 빈 인벤토리 → 출처 가이드 인라인 시트
  - `MaterialTabContent`의 빈 상태(`getByCategory('material').isEmpty`)에서 `[출처 가이드 보기]` 버튼 클릭 시:
    - 인라인 ExpansionTile 또는 BottomSheet 펼침 (코더 재량)
    - 5종 slot 출처 가이드 텍스트 표시 (페이즈 1 #4 §5-1 ASCII 그대로)
    - 데이터 소스: `materialAcquisitionHints` 또는 별도 `materialSlotGuides` 상수

#### 제작 결과 피드백

- **[FR-26]** 제작 흐름 (M4 약초상 즉시 회복 패턴 차용)
  - 단계 (페이즈 1 #4 §2-7):
    1. `[제작]` 버튼 클릭 → 50ms 비활성 (`StatefulWidget _isCrafting` 상태 또는 단순 disabled)
    2. `craftingService.craft(recipeId)` 호출
    3. 성공 시:
       - 입력 재료 차감 + 결과물 추가는 service 내부에서 처리 (FR-3)
       - ActivityLog `craftCompleted` 기록 (service 내부)
       - 호출 측(RecipeCard)에서 `SnackBar` 토스트 표시 — `'{결과물 이름} 제작 완료 ✨'` 1.5초
       - `recipeStateProvider`가 1초 내 재평가 → 카드 상태 자동 갱신 (충족 → 부족 전이 가능)
    4. 실패 시: `SnackBar` 토스트 "재료 부족" 1초 (방어적 — 정상 흐름에서 발생 안 함)

- **[FR-27]** ActivityLog `craftCompleted` 메시지 형식
  - 형식: `'{결과물 이름} 제작 완료'` 단일 줄 (M4 `herbalistHeal`·`smithyRepairCompleted` 형식 정합)
  - 예: `'낡은 용병단 깃발 제작 완료'`, `'폐광의 유물 조각 제작 완료'`

#### 빈 상태 / 특수 케이스

- **[FR-28]** 빈 인벤토리 (재료 0종 보유)
  - `MaterialTabContent`에 `EmptyMaterialState` 위젯 표시 (페이즈 1 #4 §5-1 ASCII)
  - `[출처 가이드 보기]` 버튼 → `materialSlotGuides` 인라인 시트

- **[FR-29]** 신뢰도 1단계 잠금 (대장간 자체)
  - `OldSmithyScreen`에서 `level < 2` 시 `EmptySmithyMessage` 위젯 표시 (페이즈 1 #4 §5-2 ASCII)
  - 메시지: "대장장이가 아직 일거리를 주지 않았습니다.\n마을 신뢰도를 쌓으면 제작이 시작됩니다."
  - `RecipeListSection` 미렌더링

- **[FR-30]** 999 stack 도달 처리
  - `InventoryRepository.addItem` material/consumable 케이스에서 `existing.quantity + quantity > stackMax`이면 999로 클램프
  - 본 명세 범위는 클램프만 처리. 활동 로그·토스트 출력은 페이즈 4 #3 드랍 hook 호출 측 책임 (페이즈 4 #1 §FR-19 stack_max 정책 정합)

- **[FR-31]** 충족 → 부족 전이 (제작 직후)
  - 제작 완료 시 `recipeStateProvider`가 다음 1초 tick에서 재평가하여 자동 부족 상태 전이
  - 카드 위치 변화는 즉시 재정렬 (페이즈 1 #4 §5-4) — `RecipeListSection`이 매번 정렬을 다시 계산하므로 자동
  - 애니메이션 미적용 (페이즈 1 #4 §5-4 "M5 MVP 미적용")

- **[FR-32]** 1회성 재료 시각 라벨 없음 (페이즈 1 #4 §5-5)
  - `#6 빛바랜 천 조각` / `#10 고대 인장 조각`에 별도 시각 라벨 부여하지 않음
  - 일반 재료와 동일하게 0 보유 시 카드 비표시

#### CraftingService 미사용 확인 (페이즈 4 #1 인프라 재사용)

- **[FR-33]** 페이즈 4 #1에서 등록된 인프라를 그대로 사용 (재정의·중복 변경 금지)
  - `ItemData.regionExclusive` int? — `MaterialItemCard.region_exclusive 시각`에서 직접 사용
  - `CraftingRecipeData` / `RecipeInput` / `RecipeUnlockCondition` / `ChainStepCondition` — `CraftingService.evaluateState`에서 직접 사용
  - `ActivityLogType.craftCompleted` HiveField 27 — `craft()` 내부에서 직접 호출 (모델 변경 0건)
  - `GameConstants.stackMaxByCategory` — `InventoryRepository.addItem` 클램프에서 참조
  - `StaticGameData.craftingRecipes` / `questPoolMaterialDrops` — `craftingRecipesProvider` 추출 소스
  - `SyncService.allTables` 'crafting_recipes' / 'quest_pool_material_drops' — 동기화 자동 작동
  - 모델·상수·Provider 신규 변경 금지 — 본 명세는 도메인 서비스 + UI + 라우팅만 추가

### 2.2 데이터 요구사항

#### 신규 Hive 박스/필드

- 신규 박스: **없음**
- 변경 박스: **없음**
- 신규 typeId: **없음** (페이즈 4 #1에서 ActivityLogType craftCompleted HiveField 27 등록 완료)
- CLAUDE.md 점유표 변경 없음

#### 신규/변경 정적 데이터 모델

| 모델 | 변경 내용 |
|---|---|
| (없음) | 페이즈 4 #1에서 모든 신규 모델 등록 완료 — 본 명세는 모델 변경 0건 |

#### 신규 Provider/Service

| 위치 | 항목 |
|---|---|
| `lib/features/crafting/domain/crafting_service.dart` | `CraftingService` 클래스 + `RecipeState` enum + `CraftingResult` sealed/record |
| `lib/features/crafting/domain/crafting_provider.dart` | `craftingServiceProvider` / `craftingRecipesProvider` / `recipeStateProvider` (family) / `materialUsageCountProvider` (family) |
| `lib/features/crafting/domain/recipe_filter_provider.dart` | `recipeFilterMaterialIdProvider` (StateProvider<String?>) — 인벤토리→대장간 점프 시 자동 필터 컨텍스트 |
| `lib/features/crafting/domain/material_jump_provider.dart` | `materialJumpTargetItemIdProvider` (StateProvider<String?>) — 대장간→인벤토리 점프 시 스크롤 타겟 |
| `lib/features/crafting/domain/material_acquisition_hints.dart` | `materialAcquisitionHints` const Map + `materialSlotGuides` const Map |
| `lib/features/crafting/domain/material_slot_labels.dart` | `materialSlotLabels` const Map |

#### Supabase 테이블 변경

| 테이블 | 작업 |
|---|---|
| (없음) | 페이즈 4 #1에서 모든 시드 적용 완료 — 본 명세는 SQL 변경 0건 |

#### 밸런스 수치

본 명세서는 페이즈 1·2 산출물의 수치(재료 12종 / 결과물 8종 / 레시피 10개 / effect_json / drop_rate)를 그대로 사용. 임의 변경 없음.

### 2.3 UI 요구사항

#### 인벤토리 4번째 탭 — MaterialTab

- **화면 진입 조건**: 인벤토리 화면(`InventoryScreen`)에서 `_categoryFilter == InventoryCategoryFilter.material` 선택 시
- **위젯 계층** (페이즈 1 #4 §1-1·§1-2·§1-3 정합):
  ```
  MaterialTabContent (StatefulWidget)
    Column [
      MaterialSlotChipBar (가로 스크롤 6칩)
        Row [
          ChipButton('전체'), ChipButton('광석'), ..., ChipButton('몬스터 부산물')
        ]
      Expanded [
        ListView.separated [
          MaterialItemCard {
            Row [
              Container (좌측 4px tier 색 바),
              Column [
                Row [재료 이름 + slot/tier 라벨, 🔨 ×N 배지 (Spacer)],
                if (regionExclusive == 3) "더스트빌" 라벨,
                if (expanded) 출처 힌트 1~3줄,
              ],
              Text '×N' (3자리 고정, 우측)
            ]
          }
          또는 EmptyMaterialState (보유 0종 시)
        ]
      ]
    ]
  ```
- **상태 변수**:
  - `_categoryFilter` (인벤토리 화면 기존 — material 추가)
  - `_selectedSlot` (MaterialTabContent 로컬 — null이면 전체)
  - `_expandedItemId` (카드 펼침 — 인라인 펼침 vs BottomSheet은 코더 재량, 본 명세는 인라인 권고)
- **화면 전환**: Navigator.push 미사용 — 인벤토리 화면 내부 탭 전환만
- **연출**: 카드 펼침 (ExpansionTile 표준), 토스트 (Material SnackBar), 카드 위치 변화 애니메이션 미적용

#### 낡은 대장간 정식 제작 화면

- **화면 진입 조건**: 마을 방문 시 `VillageVisitSection`에서 `selectedFacility = VillageFacility.oldSmithy` 선택 시 (M4 패턴 그대로)
- **위젯 계층**:
  ```
  OldSmithyScreen (ConsumerWidget)
    Column [
      Container (헤더 — 뒤로가기 + '낡은 대장간'),
      Padding (16px) [
        Column [
          _NpcHeader(greeting),  ← M4 그대로
          Divider,
          if (level < 2)
            EmptySmithyMessage()  ← FR-29
          else
            RecipeListSection() {
              if (recipeFilterMaterialIdProvider != null) FilterChipBar(),
              ListView [
                RecipeGroupHeader('용병단 깃발 (banner 1슬롯 — 양자택일)'),
                RecipeCard(item_banner_dustvile_repaired),
                RecipeCard(item_banner_herbalist_seal),
                RecipeGroupHeader('용병단 아티팩트 (artifact 2슬롯)'),
                RecipeCard(item_artifact_pyegwang_relic),
                RecipeCard(item_artifact_miner_charm),
                RecipeCard(...weapon 그룹 헤더 없음...),
                RecipeCard(...armor·accessory·material 정제),
              ]
            },
          SizedBox(24),
          Row [
            OutlinedButton('인벤토리에서 재료 보기', onPressed: → 점프),
            OutlinedButton('닫기', onPressed: onClose)
          ]
        ]
      ]
    ]
  ```
- **상태 변수**:
  - `recipeFilterMaterialIdProvider` (StateProvider — 자동 필터 컨텍스트)
  - `_expandedRecipeId` (RecipeListSection 로컬 — 카드 펼침 1개 한정)
- **화면 전환**: M4 그대로 — `VillageVisitSection`이 `_selectedFacility` enum 상태 기반 렌더링
- **연출**: 토스트 1.5초 (Material SnackBar), 카드 즉시 재정렬 (애니메이션 없음)

#### RecipeCard 4상태 시각

페이즈 1 #4 §2-2~§2-5의 ASCII 와이어프레임을 위젯으로 직접 매핑:

| 상태 | 카드 색상 | 라벨 | [제작] 버튼 |
|---|---|---|---|
| locked | 회색 톤 (`AppTheme.surface` + opacity 50%) | 🔒 + 해금 조건 텍스트 | 미표시 |
| insufficient | 반투명 60% (`Opacity(0.6)` 또는 동등 색 톤) | 부족 재료 빨강 X/Y + ✗ | 비활성 (`onPressed: null`) |
| ready | 또렷 + 미세한 초록 톤 | 좌상단 "제작 가능" 초록 라벨 + 충족 재료 초록 ✓ | 활성 (`onPressed: () => craftingService.craft(...)`) |

색상:
- 충족 재료 초록 = `AppTheme.tier2` (0xFF2E7D32 — 기존 T2 색 재사용)
- 부족 재료 빨강 = `Colors.red` 또는 신규 `AppTheme.dangerRed` 추가 (코더 재량 — 신규 색상 도입은 AppTheme에 1개만 추가 권고)

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/inventory/data/inventory_repository.dart` | `addItem`에 'material' stack 케이스 추가 + `consumeMaterial(itemId, qty)` + `getQuantityForItemId(itemId)` 신규 메서드 + 999 클램프 | FR-7·8·9·10 |
| `band_of_mercenaries/lib/features/inventory/view/inventory_screen.dart` | `InventoryCategoryFilter.material` enum + `_categoryFilterToString` switch + `_buildCategoryFilter` 5탭 + `_buildList` MaterialTabContent 분기 | FR-11·12·13 |
| `band_of_mercenaries/lib/features/settlement/view/old_smithy_screen.dart` | 3 tile 폐기 → `_NpcHeader` + `EmptySmithyMessage`/`RecipeListSection` + 2버튼. `_RepairMissionTile`/`_CraftGoalTile`/`_MaterialHintTile` 제거. `_repairReward` 제거 | FR-17·24·29 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `dangerRed` 또는 `materialInsufficientRed` 1개 색상 상수 추가 (코더 재량 — 빨강 충돌 텍스트용) | FR-19 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` | `CraftingService` + `RecipeState` enum + `CraftingResult` |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_provider.dart` | `craftingServiceProvider` + `craftingRecipesProvider` + `recipeStateProvider` (family) + `materialUsageCountProvider` (family) |
| `band_of_mercenaries/lib/features/crafting/domain/recipe_filter_provider.dart` | `recipeFilterMaterialIdProvider` (StateProvider) |
| `band_of_mercenaries/lib/features/crafting/domain/material_jump_provider.dart` | `materialJumpTargetItemIdProvider` (StateProvider) |
| `band_of_mercenaries/lib/features/crafting/domain/material_acquisition_hints.dart` | `materialAcquisitionHints` const Map (재료 12종 + 결과물 8종 출처 텍스트) + `materialSlotGuides` const Map (slot 5종 출처 가이드) |
| `band_of_mercenaries/lib/features/crafting/domain/material_slot_labels.dart` | `materialSlotLabels` const Map (slot 5종 한국어) |
| `band_of_mercenaries/lib/features/crafting/view/material_tab_content.dart` | MaterialTabContent + MaterialSlotChipBar + EmptyMaterialState + 출처 가이드 시트 |
| `band_of_mercenaries/lib/features/crafting/view/material_item_card.dart` | MaterialItemCard 위젯 (4정보 축 + region_exclusive 시각 + 펼침 + 🔨 ×N 점프) |
| `band_of_mercenaries/lib/features/crafting/view/recipe_list_section.dart` | RecipeListSection + RecipeGroupHeader + 정렬 로직 + 자동 필터 칩 |
| `band_of_mercenaries/lib/features/crafting/view/recipe_card.dart` | RecipeCard 4상태 위젯 + 입력 재료 X/Y 표시 + [제작] 버튼 + 부족 재료 펼침 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| (없음) | 본 명세는 freezed/json_serializable/hive_generator 모델 변경 없음. build_runner 재실행 불필요 |

페이즈 4 #1에서 모델 인프라가 이미 등록되었고, 본 명세는 도메인 서비스 + UI + Provider만 추가하므로 코드 생성 단계 없음.

### 3.4 관련 시스템

- **인벤토리 시스템 (M2a + 페이즈 4 #1)**: InventoryRepository.addItem에 material 분기 추가 + 4탭째 MaterialTab 신설. 기존 3탭 동작 변경 없음. InventoryItem Hive 박스 그대로 (페이즈 4 #1 정책 정합)
- **장비/정수 시스템 (M2a)**: ItemEffectService 변경 없음. material 카테고리는 fail-soft로 zero/empty 반환 (페이즈 4 #1 §FR-21 검증 정합)
- **시작 거점 시스템 (M4)**: VillageVisitSection·OldSmithyScreen 진입 흐름 그대로. 대장간 화면 내부만 진화. ChiefHouseScreen·HerbalistScreen 변경 없음. settlementTrustProvider 그대로 사용
- **신뢰도 시스템 (M4)**: `RegionStateRepository.getSettlementTrust(regionId).level` 평가에 사용. 본 명세는 읽기만, 변경 없음
- **연계 퀘스트 (M3)**: `chainQuestProgressProvider` 또는 `ChainQuestRepository.getProgress(chainId).status == completed AND currentStep > step` 평가에 사용. 본 명세는 읽기만, 변경 없음
- **활동 로그 (M1)**: ActivityLogType.craftCompleted (페이즈 4 #1 등록) 사용. activityLogProvider.notifier.addLog 호출만 추가
- **DialogQueue 시스템**: 본 명세 무관 — 제작 토스트는 SnackBar 즉시 표시 (큐 미사용, 페이즈 1 #4 §2-7 정합)
- **하단 네비게이션 (currentTabProvider)**: 양방향 점프 시 인벤토리 탭 전환에 사용. inventory tab index 확인 필요 (코더가 grep으로 확인)

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **CraftingService 콜백 DI 패턴**: `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` — 순수 서비스 + 콜백 DI 패턴 (RegionState/UserData/ActivityLog 콜백). `CraftingService`도 동일 구조 차용. Repository 직접 의존 대신 콜백 권장
- **즉시 행동 + 토스트 + ActivityLog 패턴**: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` 라인 46~62 `MercenaryListNotifier.healInstant` — Repository 호출 + spendGold/setHerbalistCooldown/ActivityLog 일괄 처리. 본 명세 `craft()` 흐름이 동일 패턴
- **InventoryRepository.addItem 분기 패턴**: `inventory_repository.dart` 라인 53~75 — consumable 케이스가 동일 itemId 기존 행 수량 가산. material 케이스는 동일 로직 재사용 가능 (조건 OR 추가 또는 stackMaxByCategory[category] > 1 일반화)
- **인벤토리 4탭 확장 패턴**: `inventory_screen.dart` 라인 14·150·137~148 — enum 1개 값 + switch 1 케이스 + filterTab 1줄 추가. 기존 패턴 정확히 따라가기
- **ExpansionTile 펼침 패턴**: `old_smithy_screen.dart` 라인 156·277 — 기존 `_CraftGoalTile`·`_MaterialHintTile`이 ExpansionTile로 펼침 구현. 본 명세 RecipeCard 펼침에 동일 패턴 적용 가능
- **신뢰도 단계별 인사말**: `settlement_npc_data.dart` `SettlementNpcData.greetingFor(facility, level)` — `OldSmithyScreen` 진입 시 그대로 호출
- **카드 정렬 + 그룹화 패턴**: `band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart` — 5계층 정렬 패턴 (sortedPendingQuestsProvider). RecipeListSection도 4상태 + slot + tier + id 정렬에 유사 구조 차용
- **gameTickProvider 의존 Provider**: `lib/core/providers/game_state_provider.dart` `gameTickProvider` (1초 Stream). recipeStateProvider가 chain step·trust level·재료 보유량 변화 감지에 사용
- **AppTheme 색상**: `lib/core/theme/app_theme.dart` 라인 19~27 (tier 색·tierBg) + 라인 56 (settlementAccent 0xFFFFA000) + 라인 59 (chainGold 0xFFD4AF37). 본 명세는 settlementAccent + tier2(초록 충족) 재사용. 신규 색상 1개(빨강 부족)만 추가

### 4.2 주의사항

- **CLAUDE.md typeId 정책 준수**: 신규 Hive 모델 미생성. 모든 신규 항목은 코드/Provider/Widget만으로 표현
- **CraftingService는 순수 서비스 + 콜백 DI**: ref 직접 보유 금지 (테스트 가능성 보존). Provider에서 ref.watch/ref.read로 의존성 주입
- **`recipeStateProvider`는 family + gameTickProvider watch**: 1초마다 모든 가시 카드 재평가. 가시 카드가 10개 이상이면 성능 영향 가능. 페이즈 4 #2 단일 거점 10개 레시피 시점에서는 무시 가능. M6+ 다중 거점 도입 시 derivative 캐시 도입 검토
- **CLAUDE.md 코멘트 정책**: `///` doc-comment 신규 클래스 1줄만. 기본 코멘트 없음. WHY만 1줄 한정
- **`_RepairMissionTile` 폐기**: M4에서 등록된 `userData.lastSmithyRepairAt` HiveField 23 + `ActivityLogType.smithyRepairCompleted` HiveField 26은 그대로 유지(데이터 영속성 보존). 본 명세는 화면 사용처만 제거. 페이즈 4 #3 또는 후속 마일스톤에서 모델 정리 결정
- **양방향 점프 StateProvider**: `recipeFilterMaterialIdProvider`·`materialJumpTargetItemIdProvider`는 일회성 컨텍스트. 화면 진입 시 사용 → 즉시 리셋(state = null) 패턴. CLAUDE.md "이벤트 채널 패턴"(reputationRankUpProvider 등)과 다름 — 큐 미사용. 단순 StateProvider로 충분
- **avoid_print rule**: print 사용 금지. 디버그용 print 사용 시 analysis warning
- **운영 도구 영향 (operation-bom)**: 본 명세는 Dart 코드만 변경 — operation-bom 영향 없음
- **인벤토리 → 대장간 점프 게이트**: 마을 진입 상태 평가 시 `userDataProvider.location` 또는 movement state 직접 watch. 코더가 정확한 location 모델 확인하고 사용
- **firstAcquiredItem 한계 명시**: M5 MVP는 InventoryItem 보유 여부로 평가하므로 첫 입수 후 모두 소비 시 해금 풀림. CraftingService.evaluateState에 한계 주석 1줄 + 페이즈 4 #3 영속화 위임 명시

### 4.3 엣지 케이스

- **재료 보유량 조회 시 다중 InventoryItem 행**: 동일 itemId가 여러 행으로 존재하는 경우 (페이즈 4 #1 시점에는 material/consumable이 stack 누적이라 행 1개씩이 정상이지만 방어적 처리). `getQuantityForItemId(itemId)`는 모든 행 quantity 합산
- **`consumeMaterial` 다중 행 차감**: stack 정책상 1개 행만 존재해야 하지만, 만약 다중 행이 발견되면 첫 행부터 차감하되 0이 되면 다음 행으로 넘어가는 fold 패턴 권고
- **잠김 카드의 결과물 노출 방지**: 페이즈 1 #4 §2-3 정합 — `???` 처리. 단 step 6 클라이맥스 보상으로 #10 입수 후에는 자연 노출 (해금되므로 ready/insufficient 상태로 전이). 본 명세는 잠김 시점에만 `???` 처리하고 해금 후 정상 노출
- **chain step 미진입 + 추가 step 완료 시점**: settlement_3_pyegwang_reopen step 1 완료 후 step 2~6 미진행 상태에서도 step 1 단일 게이트 레시피(`recipe_dustvile_miner_dagger`·`recipe_dustvile_rusty_pickaxe`)는 ready 상태로 전이. ChainQuestRepository.getProgress 시 `currentStep > step` 평가로 처리
- **firstAcquiredItem 평가 시 결과물·중간재 구분**: `unlock_condition_json: {"first_acquired_item":"mat_relic_pyegwang_shard"}` (recipe_dustvile_miner_charm) 평가는 mat_relic_pyegwang_shard를 한 번이라도 보유했는지. M5 MVP는 InventoryRepository.getQuantityForItemId > 0
- **빈 인벤토리 + 빈 slot chip**: MaterialTabContent에서 보유 0종이라도 6칩(전체+slot 5종) 모두 표시. chip 클릭 시 빈 상태 + 출처 가이드 노출
- **양자택일 banner 동시 보유 시**: 깃발 복원·약초사 인장 둘 다 인벤토리 보유 가능 (제작은 무제한 반복). 장착 슬롯 1개 한정은 M2a banner 슬롯 정책 그대로 (본 명세는 장착 흐름 변경 없음)
- **거점 진입 ↔ 인벤토리 점프 충돌**: 사용자가 대장간 진입 중에 currentTab 전환 시 selectedFacility 자동 리셋되어야 함. M4 VillageVisitSection의 region 변경 시 자동 리셋 로직 패턴 그대로 적용 (코더가 기존 로직 확인하고 동일하게 처리)
- **gameTickProvider rebuild 영향**: 1초마다 모든 RecipeCard 재평가 → 부족 재료가 충분해진 순간 자동 ready 상태 전이. 기존 화면 활성 시점에 1초 지연 발생 가능 (UX 미세 영향이지만 CPU 비용보다 우선)

### 4.4 구현 힌트

- **진입점 1 — 인벤토리 4탭째**: `InventoryScreen._buildList` 내부 `_categoryFilter == InventoryCategoryFilter.material`이면 `MaterialTabContent` 호출. 그 외는 기존 `ListView.separated(InventoryItemCard)` 그대로
- **진입점 2 — 대장간 정식 화면**: `VillageVisitSection`이 `selectedFacility = VillageFacility.oldSmithy`로 진입 → `OldSmithyScreen` 렌더 → `RecipeListSection` (level >= 2)
- **진입점 3 — 제작 실행**: `RecipeCard.onCraft` → `craftingService.craft(recipeId)` (Riverpod read) → 토스트 표시
- **데이터 흐름** (제작):
  ```
  RecipeCard ([제작] 클릭)
    → ref.read(craftingServiceProvider).craft(recipeId)
    → CraftingService.evaluateState (방어적 재평가)
    → InventoryRepository.consumeMaterial × N (입력 재료)
    → InventoryRepository.addItem (결과물)
    → activityLogNotifier.addLog (craftCompleted)
    → CraftingResult.success(item)
    → RecipeCard SnackBar 토스트
    → 다음 gameTick에서 recipeStateProvider 재평가 → 카드 자동 갱신
  ```
- **데이터 흐름** (양방향 점프):
  ```
  MaterialItemCard (🔨 ×N 클릭)
    → 마을 진입 평가 (userData.location)
    → 진입 상태: ref.read(recipeFilterMaterialIdProvider.notifier).state = itemId
                 + selectedFacility = oldSmithy 전환 (VillageVisitSection)
    → 미진입 상태: SnackBar 토스트 1.5초

  OldSmithyScreen (RecipeCard insufficient 펼침 → 출처 힌트 [인벤토리에서 보기] 클릭)
    → ref.read(materialJumpTargetItemIdProvider.notifier).state = materialItemId
    → currentTabProvider 인벤토리로 전환
    → InventoryScreen 진입 시 materialJumpTargetItemIdProvider 감지 → tab=material + slot=해당 + scroll
  ```
- **참조 구현**:
  - 즉시 행동 패턴: `mercenary_provider.dart` healInstant 라인 46~62
  - 4탭 확장 패턴: `inventory_screen.dart` 라인 14·137~148·150~161
  - ExpansionTile 펼침: `old_smithy_screen.dart` 라인 156·277
  - 정렬 + 그룹화: `sorted_quests_provider.dart` (5계층)
  - colors: `app_theme.dart` 라인 19~27·56·59
- **확장 지점**:
  - 페이즈 4 #3: 5종 드랍 hook이 `InventoryRepository.addItem(itemId, qty)` 호출 → 본 명세의 'material' stack 누적 분기 자동 작동
  - 페이즈 4 #3: 신뢰도 2/3단계 진입 보너스 hook이 동일 호출 → 본 명세 인프라 그대로 사용
  - 페이즈 4 #3: region_discoveries 발견 hook이 동일 호출
  - 페이즈 4 #3: chain_quests step 완료 시 reward_items JSONB → addItem 일괄 호출
  - 페이즈 4 #3: elite_loot_tables drop_type='material' 처리 + 거대 박쥐 step 3 강제 spawn

---

## 5. 기획 확인 사항

본 명세서는 페이즈 1·2 산출물 + 페이즈 4 #1 인프라가 모든 결정을 명시했으므로 사용자 확인이 거의 필요 없다. 코더 재량 항목과 페이즈 4 #3 위임 항목으로 분리:

### 5.1 코더 재량 항목

- **[Q-1]** 카드 펼침 인터랙션: 인라인 ExpansionTile vs 별도 BottomSheet → 본 명세 권고 **인라인 ExpansionTile** (M4 OldSmithyScreen `_CraftGoalTile` 패턴 정합 + 모바일 폭 430px 간결성). 코더 재량 허용
- **[Q-2]** `dangerRed` 색상 추가 위치: AppTheme 신규 상수 vs 인라인 Colors.red.shade700 → 본 명세 권고 **AppTheme에 1개 신규 상수 추가** (`Color(0xFFC62828)` 또는 동등). 사용 위치는 RecipeCard insufficient 부족 재료 텍스트만
- **[Q-3]** 양자택일 그룹 헤더 레이아웃: 카드 가로 배치(Row) vs 세로 배치(Column) → 본 명세 권고 **세로 배치** (모바일 폭 430px 시 Row 배치는 카드 정보 잘림). 코더 재량 허용
- **[Q-4]** `materialAcquisitionHints` 데이터 위치: const Map (lib/features/crafting/domain/) vs `items.acquisition_hint` DB 컬럼 → 본 명세 권고 **const Map** (M5 MVP 데이터량 적음 + 다국어 미적용). DB 컬럼은 후속 마일스톤
- **[Q-5]** `firstAcquiredItem` 평가 임시 정책: InventoryRepository.getQuantityForItemId > 0 vs 영속 박스 → 본 명세 권고 **임시 InventoryRepository 평가** + 페이즈 4 #3 영속화 위임 주석 1줄. 코더가 코드 주석에 명시

### 5.2 페이즈 4 #3 위임 항목 (본 명세 범위 외 — 명세서에 미적용)

- 5종 드랍 hook (QuestCompletionService / InvestigationNotifier / EliteLootService / TravelChoiceService / ChainQuestService)
- 신뢰도 2/3단계 진입 일회성 보너스 hook (`RegionStateNotifier.addSettlementTrust` 분기)
- region_discoveries 발견 트리거 hook (`InvestigationNotifier`)
- 거대 박쥐 step 3 강제 spawn 정책 (`EliteSpawnService` 분기)
- chain_quests step 완료 시 reward_items JSONB 적용 (`ChainQuestService.onStepCompleted`)
- elite_loot_tables drop_type='material' 처리 분기 (`EliteLootService.roll`)
- `firstAcquiredItem` 영속 추적 (RegionState 또는 신규 박스)
- 999 stack 도달 시 활동 로그 + 토스트 카피
- travel_choice_results material_drop effect_type 확장

### 5.3 검증 완료 사항 (페이즈 4 #1에서 확정)

| 항목 | 결과 | 근거 |
|---|---|---|
| `ItemData.regionExclusive` | 모델 등록 완료 (페이즈 4 #1 commit `3b6506c`) | item_data.freezed.dart 자동 생성 |
| `CraftingRecipeData` + 서브 클래스 3종 | 등록 완료 | crafting_recipe_data.freezed.dart |
| `ActivityLogType.craftCompleted` HiveField 27 | 등록 완료 | activity_log_model.g.dart |
| `GameConstants.stackMaxByCategory` Map | 등록 완료 | game_constants.dart |
| `StaticGameData.craftingRecipes` 필드 | 등록 완료 | static_data_provider.dart |
| `SyncService.allTables` 'crafting_recipes' | 등록 완료 | sync_service.dart |
| Supabase items 22행 + crafting_recipes 10행 + region_discoveries 3 + chain_quests UPDATE 6 + elite_giant_bat 1 + elite_loot 1 | 적용 완료 | apply_migration `m5_phase4_1_data_migration` |
| items category·slot CHECK 16종 갱신 | 적용 완료 | DROP/ADD |
| region_discoveries discovery_type CHECK 6종 갱신 | 적용 완료 | DROP/ADD ('normal' 추가) |
