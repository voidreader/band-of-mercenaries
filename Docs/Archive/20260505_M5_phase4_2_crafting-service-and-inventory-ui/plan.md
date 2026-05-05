# M5 페이즈 4 #2 — CraftingService + 인벤토리 4탭 + 낡은 대장간 제작 UI 구현 계획서

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260505_M5_phase4_2_crafting-service-and-inventory-ui.md`
> 작성일: 2026-05-05
> 마일스톤: M5 페이즈 4 #2
> 선행: 페이즈 4 #1 (commit `3b6506c` — 데이터 인프라)
> 후속: 페이즈 4 #3 (드랍 출처 hook + 거대 박쥐 step 3 강제 spawn)

---

## 1. 작업 개요

페이즈 4 #1의 데이터 인프라(crafting_recipes 10행 / items 22행 / `CraftingRecipeData` 모델 / `ActivityLogType.craftCompleted` HiveField 27 / `GameConstants.stackMaxByCategory`) 위에 다음을 구축:

1. **CraftingService 도메인 서비스** — 레시피 4상태 평가(잠김/부족/충족) + 제작 실행(재료 차감 + 결과물 추가 + ActivityLog 기록). 콜백 DI 패턴
2. **InventoryRepository 확장** — material 카테고리 stack 누적 + `consumeMaterial` / `getQuantityForItemId` 메서드 + 999 클램프
3. **인벤토리 4탭째 MaterialTab 신설** — slot 6칩 sub-filter + MaterialItemCard 4정보 축 + region_exclusive 시각 차별화
4. **낡은 대장간 정식 제작 화면** — M4 stub 3 tile → RecipeListSection (4상태 RecipeCard 정렬 + 그룹 헤더) + 2버튼
5. **양방향 점프 인터랙션** — `recipeFilterMaterialIdProvider` / `materialJumpTargetItemIdProvider` StateProvider 2종

---

## 2. 변경 파일 목록

### 2.1 신규 생성 (10개)

| 파일 경로 | 변경 유형 | 설명 |
|---|---|---|
| `lib/features/crafting/domain/crafting_service.dart` | 신규 | CraftingService + RecipeState enum + CraftingResult sealed class (CraftingSuccess / CraftingFailure) |
| `lib/features/crafting/domain/crafting_provider.dart` | 신규 | craftingServiceProvider + craftingRecipesProvider + recipeStateProvider(family) + materialUsageCountProvider(family) — gameTickProvider watch로 1초 재평가 |
| `lib/features/crafting/domain/recipe_filter_provider.dart` | 신규 | recipeFilterMaterialIdProvider StateProvider — 인벤토리→대장간 점프 시 자동 필터 컨텍스트 |
| `lib/features/crafting/domain/material_jump_provider.dart` | 신규 | materialJumpTargetItemIdProvider StateProvider — 대장간→인벤토리 점프 시 스크롤 타겟 |
| `lib/features/crafting/domain/material_slot_labels.dart` | 신규 | materialSlotLabels const Map (광석/가죽/약초/유물 파편/몬스터 부산물) + 헬퍼 함수 |
| `lib/features/crafting/domain/material_acquisition_hints.dart` | 신규 | materialAcquisitionHints (재료 12종 출처) + materialSlotGuides (slot 5종 출처 가이드) const Map |
| `lib/features/crafting/view/material_item_card.dart` | 신규 | MaterialItemCard ConsumerStatefulWidget — 4정보 축(tier 색 바·이름·🔨 ×N·보유량) + region_exclusive 시각 + 펼침 출처 힌트 + 🔨 점프 |
| `lib/features/crafting/view/material_tab_content.dart` | 신규 | MaterialTabContent + MaterialSlotChipBar + EmptyMaterialState 통합 — slot 6칩 + 정렬(tier desc → 보유량 desc → id asc) + 출처 가이드 토글 |
| `lib/features/crafting/view/recipe_card.dart` | 신규 | RecipeCard 4상태 위젯 — locked/insufficient/ready 시각 + 입력 X/Y 표기 + [제작] 버튼 + 부족 재료 펼침 + 점프 링크 |
| `lib/features/crafting/view/recipe_list_section.dart` | 신규 | RecipeListSection + RecipeGroupHeader — 정렬 4계층 + banner/artifact 그룹 헤더 + 자동 필터 칩 |

### 2.2 수정 (5개)

| 파일 경로 | 변경 유형 | 설명 |
|---|---|---|
| `lib/core/theme/app_theme.dart` | 수정 | `dangerRed = Color(0xFFC62828)` 1개 상수 추가 — RecipeCard insufficient 부족 재료 텍스트 전용 |
| `lib/features/inventory/data/inventory_repository.dart` | 수정 | addItem 분기를 `stackMaxByCategory[category] > 1` 일반화로 교체 + 999 클램프 + `consumeMaterial(itemId, qty)` 다중 행 fold + `getQuantityForItemId(itemId)` 합산 메서드 |
| `lib/features/inventory/view/inventory_screen.dart` | 수정 | `InventoryCategoryFilter.material` enum 추가 + `_categoryFilterToString` switch + `_buildCategoryFilter` '재료' filterTab + `_buildList` MaterialTabContent 분기 + `materialJumpTargetItemIdProvider` listen 자동 전환 + 빈 상태 가드 material 우회 |
| `lib/features/info/view/info_screen.dart` | 수정 (명세 §3.1 외 보완) | `materialJumpTargetItemIdProvider` listen 추가 (1줄) — non-null 감지 시 `_showInventory = true` 자동 전환. FR-23 충족 필수 |
| `lib/features/settlement/view/old_smithy_screen.dart` | 수정 (전면 재작성) | 320줄 → 149줄. `_RepairMissionTile` / `_CraftGoalTile` / `_MaterialHintTile` / `_repairReward` 폐기. `_NpcHeader` 유지. `_EmptySmithyMessage` (level<2) + RecipeListSection (level≥2) + 2버튼([인벤토리에서 재료 보기] / [닫기]) |

### 2.3 빌드 게이트 외과 수정 (1개)

| 파일 경로 | 변경 유형 | 설명 |
|---|---|---|
| `test/features/inventory/view/inventory_screen_test.dart` | 수정 | switch에 `case InventoryCategoryFilter.material: categoryStr = 'material';` 1줄 추가 — non_exhaustive_switch_statement 해소 |

---

## 3. 구현 내역

### 3.1 CraftingService 시그니처

```dart
enum RecipeState { locked, insufficient, ready }

sealed class CraftingResult { ... }
class CraftingSuccess extends CraftingResult { final InventoryItem item; }
class CraftingFailure extends CraftingResult { final String reason; }
// reason: 'lockMissing' / 'materialShortage' / 'unknown'

class CraftingService {
  const CraftingService({
    required this.staticData,
    required this.inventoryRepository,
    required this.regionStateRepository,
    required this.chainQuestRepository,
    required this.userDataNotifier,
    required this.activityLogNotifier,
  });

  RecipeState evaluateState(CraftingRecipeData recipe);
  Future<CraftingResult> craft(String recipeId);
}
```

- 콜백 DI 패턴 (ref 직접 보유 금지)
- evaluateState 분기:
  1. unlockCondition 1순위 — trustLevel / chainStep / firstAcquiredItem 평가
  2. inputs 2순위 — getQuantityForItemId 합산 ≥ quantity
- craft 흐름:
  1. evaluateState 재평가 → ready 아니면 CraftingFailure
  2. consumeMaterial × N
  3. addItem (페이즈 4 #1 stack 누적 분기 활용)
  4. activityLogNotifier.addLog('${결과물 이름} 제작 완료', ActivityLogType.craftCompleted)
  5. CraftingSuccess 반환

### 3.2 Provider 의존 그래프

```
staticDataProvider (FutureProvider)
  ├→ craftingRecipesProvider (Provider<List<CraftingRecipeData>>)
  │    └→ materialUsageCountProvider (family)
  └→ craftingServiceProvider (Provider<CraftingService>)
       └→ recipeStateProvider (family + gameTickProvider watch)

inventoryRepositoryProvider ──→ craftingServiceProvider
regionStateRepositoryProvider ──→ craftingServiceProvider
chainQuestRepositoryProvider ──→ craftingServiceProvider
userDataProvider.notifier ──→ craftingServiceProvider
activityLogProvider.notifier ──→ craftingServiceProvider

recipeFilterMaterialIdProvider (StateProvider<String?>)
  ←─ MaterialItemCard.🔨 클릭
  ─→ RecipeListSection 자동 필터

materialJumpTargetItemIdProvider (StateProvider<String?>)
  ←─ RecipeCard 부족 재료 [인벤토리에서 보기]
  ─→ InventoryScreen.listen → _categoryFilter = material 전환
  ─→ MaterialTabContent.listen → slot 자동 + scroll → state = null 리셋
  ─→ InfoScreen.listen → _showInventory = true 자동 진입
```

### 3.3 양방향 점프 흐름

#### 인벤토리 → 대장간 (FR-22 — 부분 충족)

- MaterialItemCard 🔨 ×N 클릭 → `recipeFilterMaterialIdProvider.state = itemId` 설정 + `onJumpToSmithy()` 콜백
- MaterialTabContent의 `_onJumpToSmithy`는 두 분기 모두 SnackBar("낡은 대장간에서 확인할 수 있습니다", 1500ms)로 통일
- **부분 충족 사유**: InfoScreen → InventoryScreen → MaterialItemCard 경로에서 `selectedFacility = oldSmithy`로 직접 변경할 hook이 현재 부재. 자동 진입 라우팅은 향후 작업 위임

#### 대장간 → 인벤토리 (FR-23·24)

- RecipeCard 부족 재료 [인벤토리에서 보기] → `materialJumpTargetItemIdProvider.state = itemId` + `currentTabProvider = 5` (정보 탭) + `onClose()`
- OldSmithyScreen 하단 [인벤토리에서 재료 보기] → `currentTabProvider = 5` + `onClose()` (특정 재료 점프 없음, 명세 권고안 그대로)
- InfoScreen이 listen으로 `_showInventory = true` 자동 전환 → InventoryScreen이 listen으로 `_categoryFilter = material` 자동 전환 → MaterialTabContent가 listen으로 slot 자동 + scroll + state 리셋

### 3.4 RecipeCard 4상태 시각

| 상태 | 카드 | 라벨 | 입력 재료 | [제작] |
|---|---|---|---|---|
| locked | Opacity 0.5 + 회색 | 🔒 + 해금 조건 텍스트, 결과물 `???` | 미표시 | 미표시 |
| insufficient | Opacity 0.6 | 결과물 이름 | X/Y 표기 (충족=tier2 초록 ✓ / 부족=dangerRed 빨강 ✗), 한국어 이름 | 비활성 (`onPressed: null`) |
| ready | Opacity 1.0 + tier2 톤 | 좌상단 "제작 가능" 초록 라벨 | 모두 초록 ✓ | 활성 (`onPressed: _onCraftPressed`) |

[제작] 클릭 흐름:
1. `setState(() => _isCrafting = true)` (50ms 비활성)
2. `craftingService.craft(recipe.id)`
3. CraftingSuccess → SnackBar `'{결과물 이름} 제작 완료 ✨'` 1.5초
4. CraftingFailure → SnackBar `'재료 부족'` 1초 (방어적)
5. `setState(() => _isCrafting = false)` (50ms 후)

### 3.5 정렬 정책 (RecipeListSection)

페이즈 1 #4 §2-9 정합:
1. **상태 우선순위**: ready(0) → insufficient(1) → locked(2)
2. **slot 그룹 순서**: banner(0) → weapon(1) → armor(2) → accessory(3) → artifact(4) → 기타(99)
3. **tier 내림차순**: 결과물 tier desc
4. **id asc**: recipe.id 사전순

그룹 헤더:
- banner: "용병단 깃발 (banner 1슬롯 — 양자택일)"
- artifact: "용병단 아티팩트 (artifact 2슬롯 — 동시 장착 가능)"
- 그 외(weapon/armor/accessory/material): 헤더 없음

`ref.watch(gameTickProvider)`을 build() 상단에 추가하여 1초마다 정렬 재평가 — recipeStateProvider stale 해소.

---

## 4. 검증 결과

### 4.1 검증 모드

**풀 검증** (TASK 수 14개 ≥ 3) — verifier + flutter-reviewer 병렬 호출

### 4.2 1차 검증 (FAIL)

#### verifier 결과: FAIL
- ISSUE-1 [critical] FR-23 currentTabProvider 인벤토리 탭 전환 누락
- ISSUE-2 [critical] FR-28 EmptyMaterialState 미노출 (filtered.isEmpty 가드 우선 진입)
- ISSUE-3 [minor] 재료 한국어 이름 미표시 (raw itemId 노출)
- ISSUE-4 [minor] 미사용 파라미터 showShortfallOnly

#### flutter-reviewer 결과: BLOCK
- CRITICAL: build() 내 ref.read(recipeStateProvider) + 정렬 stale (recipe_list_section.dart)
- HIGH: ref.read(inventoryRepositoryProvider) build 파생 메서드 사용 (recipe_card.dart)
- HIGH: raw itemId 노출 [verifier ISSUE-3과 중복]
- HIGH: _buildInsufficientCard/ReadyCard 위젯 클래스 미분리 (스타일 — 명시적 위임)
- HIGH: recipeStateProvider gameTickProvider watch 성능 (가시 카드 N개 — 명세 §4.2 무시 가능 명시)
- HIGH: CraftingService 단위 테스트 부재 (명세 의무 외)
- MEDIUM: O(N²) lookup in material_tab_content
- MEDIUM: requireValue 로딩 중 크래시 위험 (RecipeListSection 진입 시점 staticData ready 보장)
- MEDIUM: IntrinsicHeight 비용 (작은 영향)
- MEDIUM: const FontFeature.tabularFigures (오탐 — TextStyle const 컨텍스트)
- MEDIUM: dangerRed/criticalFailure hex 중복 (의미 분리 정합)
- MEDIUM: dead code _onJumpToSmithy inVillage 분기
- MEDIUM: TextButton 터치 타겟 작음 (UX 개선 후속)
- LOW: catch (_) 예외 타입 미명시 (기존 코드)

### 4.3 수정 작업 (5개 TASK 병렬 재호출)

| TASK | 수정 내용 |
|---|---|
| TASK-12 (recipe_card.dart) | currentTabProvider 호출 + itemMap 한국어 이름 lookup + ref.watch(inventoryRepositoryProvider) + showShortfallOnly 제거 |
| TASK-10 (inventory_screen.dart) | `(filtered.isEmpty && _categoryFilter != material)` 가드 변경 |
| TASK-13 (recipe_list_section.dart) | `ref.watch(gameTickProvider)` build 상단 1줄 추가 |
| TASK-9 (material_tab_content.dart) | dead code 삼항 제거 + itemMap O(N²)→O(1) lookup + userDataProvider import 제거 |
| TASK-8 (material_item_card.dart) | const FontFeature는 오탐 — 변경 없음 |

### 4.4 2차 검증 (PASS)

#### verifier 결과: PASS
- 이전 FAIL 4건 모두 수정 확인
- 회귀 없음
- flutter analyze: PASS (No issues found)
- 테스트: PASS (53/53)

#### flutter-reviewer 결과: APPROVE
- CRITICAL/HIGH/MEDIUM 신규 이슈 없음
- INFO 2건 (의도적 설계 + 스타일 향후 위임)

### 4.5 통합 판정: **PASS**

---

## 5. 명세 부분 충족 / 향후 위임

### 5.1 부분 충족 (명세서 §FR-22)

- **FR-22 마을 진입 상태 자동 진입 미구현**: MaterialItemCard 🔨 클릭 시 두 분기 모두 SnackBar로 통일. 사유: InfoScreen → InventoryScreen → MaterialItemCard 경로에서 `selectedFacility`를 직접 변경할 hook이 현재 부재. 자동 진입 라우팅은 향후 작업 위임.

### 5.2 향후 작업 위임 (본 명세 범위 외)

- **CraftingService 단위 테스트 추가** (명세서가 테스트 신규 추가 의무 미언급 — 권고)
- **_buildInsufficientCard / _buildReadyCard 위젯 클래스 분리** (스타일 — 후속 리팩토링 위임)
- **recipeStateProvider 가시 카드 N개 성능 구조 개선** (명세 §4.2 "가시 카드 10개 무시 가능" 명시 — M6+ 다중 거점 도입 시 derivative 캐시 검토)
- **requireValue 로딩 중 방어적 처리** (RecipeListSection이 OldSmithyScreen 진입 후만 build — staticData ready 보장)
- **MaterialItemCard IntrinsicHeight 최적화** (작은 영향)
- **TextButton 터치 타겟 48dp 보장** (UX 개선 후속)
- **dangerRed/criticalFailure 통합 또는 alias** (의미 분리 정합 — 향후 결정)
- **catch (_) 예외 타입 명시** (기존 코드 — 본 작업 범위 외)

### 5.3 페이즈 4 #3 위임 (명세서 §5.2)

- 5종 드랍 hook (QuestCompletionService / InvestigationNotifier / EliteLootService / TravelChoiceService / ChainQuestService)
- 신뢰도 2/3단계 진입 일회성 보너스 hook
- region_discoveries 발견 트리거 hook
- 거대 박쥐 step 3 강제 spawn 정책
- chain_quests step 완료 시 reward_items JSONB 적용
- elite_loot_tables drop_type='material' 처리
- `firstAcquiredItem` 영속 추적 (RegionState 또는 신규 박스)
- 999 stack 도달 시 활동 로그 + 토스트 카피
- travel_choice_results material_drop effect_type 확장

---

## 6. build_runner 재실행 필요 파일

**없음** — freezed/json_serializable/hive_generator 모델 변경 0건. 페이즈 4 #1에서 이미 등록된 인프라(`CraftingRecipeData`/`QuestPoolMaterialDropData`/`ItemData.regionExclusive`/`ActivityLogType.craftCompleted` HiveField 27)를 그대로 사용.

---

## 7. CLAUDE.md 금지사항 위반

**없음** — 모든 작업이 CLAUDE.md 정책 내에서 수행됨:
- Hive typeId 신규 등록 0건 (FR-33 정합)
- 모델·상수·Provider 재정의 금지 준수
- 코멘트 정책 준수 (WHY 1줄, doc-comment `///`만)
- 의존성 최소화
- avoid_print rule 준수
- 모델 영속성 보존 — `userData.lastSmithyRepairAt` HiveField 23 + `ActivityLogType.smithyRepairCompleted` HiveField 26 모델은 그대로 유지(사용 사이트만 제거)

---

## 8. 변경 라인 수 요약

| 파일 | 라인 수 변화 |
|---|---|
| crafting_service.dart | +0 → +약 130 |
| crafting_provider.dart | +0 → +약 50 |
| recipe_filter_provider.dart | +0 → +약 8 |
| material_jump_provider.dart | +0 → +약 8 |
| material_slot_labels.dart | +0 → +약 15 |
| material_acquisition_hints.dart | +0 → +약 50 |
| material_item_card.dart | +0 → +약 170 |
| material_tab_content.dart | +0 → +약 350 |
| recipe_card.dart | +0 → +약 280 |
| recipe_list_section.dart | +0 → +약 130 |
| app_theme.dart | +2 |
| inventory_repository.dart | +약 30 (확장) |
| inventory_screen.dart | +약 10 (라인 수정) |
| info_screen.dart | +5 (listen 1줄) |
| old_smithy_screen.dart | 320 → 149 (-약 170) |
| inventory_screen_test.dart | +1 (switch 케이스) |

**총 신규 약 1,200줄 + 수정 약 100줄 + 폐기 약 170줄**

---

## 9. 다음 단계 안내

본 구현 완료 후:
1. `finalize-feature` 스킬 실행 — 커밋 + Archive + CLAUDE.md 업데이트 + CHANGELOG fragment
2. `/milestone-runner M5 --resume` — 페이즈 4 #3 (드랍 hook + 거대 박쥐 step 3 + 신뢰도 보너스 hook) 명세 작성으로 진행
