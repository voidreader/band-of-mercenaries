# M5 페이즈 4 #1 — 데이터 모델 확장 + 시드 마이그레이션 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260504_material-taxonomy.md` (페이즈 1 #1 — 분류 체계)
> - `Docs/content-design/[content]20260504_dustvile-materials.md` (페이즈 1 #2 — 재료 10종)
> - `Docs/content-design/[content]20260504_dustvile-recipes.md` (페이즈 1 #3 — 레시피 10개)
> - `Docs/content-design/[content]20260504_dustvile-craft-ui.md` (페이즈 1 #4 — UI 컨셉)
> - `Docs/balance-design/[balance]20260504_dustvile-material-droprate.md` (페이즈 2 #1 — drop_rate 곡선)
> - `Docs/balance-design/[balance]20260504_dustvile-recipe-effects.md` (페이즈 2 #2 — effect_json 매트릭스)
> - `Docs/balance-design/[balance]20260504_dustvile-completion-vs-craft.md` (페이즈 2 #3 — 공존 정책)
>
> 작성일: 2026-05-04
> 마일스톤: M5 페이즈 4 #1
> 후속: 페이즈 4 #2 (CraftingService + 인벤토리 4탭) / 페이즈 4 #3 (드랍 출처 hook + 거점 대장간)
> Visual Companion: 미적용 (UI 변경 없음 — 데이터 모델 + SQL 마이그레이션 전용)

---

## 1. 개요

M5 "재료와 제작" 마일스톤의 데이터 모델 인프라를 구축한다. `items` 테이블에 신규 `category=material` 4번째 카테고리와 `region_exclusive` 컬럼을 추가하고, `crafting_recipes` 신규 테이블을 신설하여 12종 재료 + 10개 레시피 + 8종 결과물 + 거대 박쥐 엘리트 + 폐광 발견 3건 + chain_quests 6행 보상 갱신을 SQL 인라인 처리한다. Hive 모델은 `InventoryItem` 그대로 재사용하며, `ActivityLogType.craftCompleted`(HiveField 27) 1개만 신규 추가한다. 본 명세서는 페이즈 4 #2(`CraftingService`) / #3(드랍 hook + 거점 화면)의 선행 인프라이며, M2b signature drop 보강은 별도 마일스톤으로 분리한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### items 테이블 스키마 확장

- **[FR-1]** `items.category` 값 공간에 `'material'` 추가
  - 상세 동작: 기존 3종(`personal_equipment`/`guild_equipment`/`consumable`)에 4번째 값 `material` 허용
  - DB CHECK 제약: `CHECK (category IN ('personal_equipment','guild_equipment','consumable','material'))`
  - 구현 위치: 본 명세서 §"마이그레이션 SQL — items 스키마 확장"

- **[FR-2]** `items.region_exclusive` 신규 컬럼 추가
  - 타입: `INTEGER NULL REFERENCES regions(id)`
  - NULL 허용 (지역 한정 없음 = 범용)
  - 정수 값이면 해당 region_id에서만 드랍/제작 가능 (페이즈 1 #1 §5)
  - 인덱스: `CREATE INDEX idx_items_region_exclusive ON items(region_exclusive) WHERE region_exclusive IS NOT NULL`
  - 보조 인덱스: `CREATE INDEX idx_items_category_slot ON items(category, slot)` (operation-bom 필터링)

- **[FR-3]** `ItemData` Freezed 모델에 `regionExclusive` 필드 추가
  - 타입: `int?` nullable
  - JsonKey: `region_exclusive`
  - 구현 위치: `band_of_mercenaries/lib/core/models/item_data.dart` 라인 17 이전 (effect_json 필드 직전 또는 직후)
  - `build_runner build` 재실행 필요 (`item_data.freezed.dart` / `item_data.g.dart` 재생성)

#### 신규 slot 5종 등록

- **[FR-4]** items 테이블의 `slot` 컬럼에 신규 5종 사용
  - `material_ore` / `material_hide` / `material_herb` / `material_relic_fragment` / `material_monster_part`
  - DB CHECK 제약 변경 없음 (현재 slot 컬럼은 자유 문자열)
  - Dart 단에서 enum 또는 상수 검증 미강제 (페이즈 1 #1 정책 — 코드 상수만 사용)

#### crafting_recipes 신규 테이블

- **[FR-5]** `crafting_recipes` 신규 테이블 신설 (페이즈 1 #3 §6 결정 — 옵션 A 채택)
  - 결정 근거: 미래 확장성(다중 결과물·동일 결과물 다중 레시피)에 대비. JSONB MVP는 거점별 분기 도입 시 테이블 마이그레이션 부담
  - 컬럼:
    ```sql
    CREATE TABLE crafting_recipes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      result_item_id TEXT NOT NULL REFERENCES items(id),
      result_quantity INT NOT NULL DEFAULT 1,
      inputs_json JSONB NOT NULL,
      unlock_condition_json JSONB,
      craft_location_id TEXT NOT NULL DEFAULT 'old_smithy',
      sort_order INT NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    ```
  - `inputs_json` 형식: `[{"item_id":"mat_hide_dry_strap","quantity":3}, ...]`
  - `unlock_condition_json` 형식 (옵션):
    - `{"trust_level": 2}` — 신뢰도 2단계 진입
    - `{"chain_step": {"chain_id": "settlement_3_pyegwang_reopen", "step": 1}}` — chain 단계 완료
    - `{"first_acquired_item": "mat_relic_pyegwang_shard"}` — 특정 재료 첫 입수
    - NULL이면 무조건 해금
  - 인덱스: `CREATE INDEX idx_crafting_recipes_result_item ON crafting_recipes(result_item_id)`
  - `data_versions` 행 신규 추가 (table_name='crafting_recipes')

- **[FR-6]** `CraftingRecipeData` Freezed 모델 신규 생성
  - 위치: `band_of_mercenaries/lib/core/models/crafting_recipe_data.dart`
  - 컬럼 1:1 대응 + `inputs` (List<RecipeInput>) + `unlockCondition` (RecipeUnlockCondition?)
  - `RecipeInput` / `RecipeUnlockCondition` 서브 Freezed 모델 동일 파일에 정의
  - `build_runner build` 필요

#### quest_pool_material_drops 신규 매핑 테이블

- **[FR-7]** `quest_pool_material_drops` 신규 매핑 테이블 신설 (페이즈 2 #1 §"조정 5" 옵션 B 채택)
  - 결정 근거: 한 의뢰가 여러 재료를 분기 drop_rate로 떨어뜨림 (#1·#7 / #2·#3·#4·#5 등). 매핑 테이블이 자연스러움
  - 컬럼:
    ```sql
    CREATE TABLE quest_pool_material_drops (
      id BIGSERIAL PRIMARY KEY,
      pool_id TEXT NOT NULL REFERENCES quest_pools(id) ON DELETE CASCADE,
      item_id TEXT NOT NULL REFERENCES items(id),
      drop_rate REAL NOT NULL CHECK (drop_rate >= 0 AND drop_rate <= 1),
      qty_min INT NOT NULL DEFAULT 1,
      qty_max INT NOT NULL DEFAULT 1,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      UNIQUE(pool_id, item_id)
    );
    ```
  - 인덱스: `CREATE INDEX idx_qpmd_pool ON quest_pool_material_drops(pool_id)`
  - `data_versions` 행 신규 추가
  - **본 명세서 데이터 INSERT 범위 외**: drop hook 적용 시점은 페이즈 4 #3. 본 명세서는 **테이블 스키마만 신설**

- **[FR-8]** `QuestPoolMaterialDropData` Freezed 모델 신규 생성
  - 위치: `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.dart`
  - 컬럼 1:1 대응
  - `build_runner build` 필요

#### chain_quests.reward_items JSONB UPDATE

- **[FR-9]** `chain_quests` 6행 UPDATE — `reward_items` JSONB에 재료 보상 반영 (페이즈 2 #1 §1-5)
  - 대상: `settlement_3_pyegwang_reopen` step 1~6
  - 형식: `{"item_id": qty, ...}`
  - **실 스키마 검증 결과** (Supabase information_schema 조회): `chain_quests.reward_items` 컬럼 이미 존재 (`jsonb NOT NULL DEFAULT '{}'::jsonb`). **ALTER TABLE 불필요** — UPDATE만으로 적용 가능
  - `ChainQuestData` 모델은 이미 `rewardItems Map<String, int>` 필드 보유 (라인 24) — 모델 변경 없음

#### region_discoveries 신규 3행 INSERT

- **[FR-10]** `region_discoveries` 신규 3행 INSERT (페이즈 2 #1 §1-2)
  - region_id=3 (더스트플레인), knowledge_threshold=25/50/80, discovery_type 별 페이로드 (`#1×3` / `#8×1+#7 보조 0.3` / `#10×1`)
  - **본 명세서 INSERT 범위 외**: 발견 시 재료 드랍 hook 자체는 페이즈 4 #3. 본 명세서는 **discoveries 행만 INSERT**

#### elite_monsters / elite_loot_tables 신규 INSERT

- **[FR-11]** `elite_monsters` 거대 박쥐 1행 INSERT (페이즈 2 #1 §1-3)
  - id=`elite_giant_bat`, type_family='beast', tier=2, power=80, spawn_rate=0.15
  - environment_tags=`["mountain","dungeon"]`, fixed_region_environments=`[3]`
  - stat_weight=`{"agi":0.4,"str":0.4,"vit":0.2}`
  - title='갱도의 우두머리'

- **[FR-12]** `elite_loot_tables` 거대 박쥐 1행 INSERT
  - **실 스키마 검증 완료** (Supabase information_schema 조회): 컬럼은 `id, elite_id, drop_type, item_id, gold_min, gold_max, drop_rate, rarity_grade, quantity` 9종이며 `qty_min`/`qty_max` 컬럼 미존재. `id`와 `rarity_grade`는 NOT NULL DEFAULT 없음
  - INSERT 값: id=`elite_giant_bat_fang_drop`, elite_id=`elite_giant_bat`, drop_type='material', item_id=`mat_monster_giant_bat_fang`, drop_rate=1.0, rarity_grade='rare', quantity=1
  - rarity_grade='rare' 선택 근거: 페이즈 2 #1 §1-3 "시그니처 트로피 정책 — drop_rate 1.0 확정". M2b 페이즈 2-2 §"signature drop 확정 매핑"에서 시그니처는 일반적으로 'rare' 등급
  - **drop_type 값 결정**: 기존 elite_loot_tables.drop_type CHECK 제약은 **실 스키마에 미존재** (Supabase information_schema 조회로 확인). drop_type 컬럼은 자유 TEXT → M5에서 'material' 값을 INSERT만 하면 끝. ALTER TABLE 불필요

- **[FR-13]** ~~`elite_loot_tables.drop_type` 값 공간에 `'material'` 추가~~ (삭제 — 실 스키마 검증 결과 CHECK 제약 미존재 → ALTER TABLE 작업 자체가 불필요)

#### items 22행 신규 INSERT

- **[FR-14]** items 재료 10종 신규 INSERT (페이즈 1 #2 §1-2)
  - 상세는 §"마이그레이션 SQL — items INSERT (재료 10종)" 참조

- **[FR-15]** items 중간재 2종 신규 INSERT (페이즈 1 #3 §3-1·§3-2)
  - `mat_hide_rough_bundle` / `mat_ore_polished_scrap`
  - category='material', tier=2, region_exclusive=NULL

- **[FR-16]** items 결과물 8종 신규 INSERT (페이즈 2 #2 §"data-generator 수치 가이드")
  - effect_json은 페이즈 2 #2 §"8종 결과물 effect_json 최종 확정 매트릭스" 그대로 적용
  - 상세는 §"마이그레이션 SQL — items INSERT (결과물 8종)" 참조

#### crafting_recipes 10행 신규 INSERT

- **[FR-17]** crafting_recipes 10행 신규 INSERT (페이즈 1 #3 §4)
  - 10개 레시피 모두 `craft_location_id='old_smithy'`
  - `unlock_condition_json` = 페이즈 1 #3 §1-4 해금 정책 그대로 적용
  - 상세는 §"마이그레이션 SQL — crafting_recipes INSERT" 참조

#### Hive InventoryItem 모델 처리

- **[FR-18]** `InventoryItem` Hive 모델 변경 없음
  - 현재 5개 HiveField (id, itemId, quantity, equippedTo, acquiredAt) 그대로 유지
  - category 정보는 itemId → ItemData 동적 조회로 해결 (정적 데이터 참조)
  - 신규 typeId 추가 없음

- **[FR-19]** `GameConstants.stackMaxByCategory` 신규 상수 추가
  - 위치: `band_of_mercenaries/lib/core/constants/game_constants.dart` 클래스 내부 끝부분
  - 형식:
    ```dart
    static const Map<String, int> stackMaxByCategory = {
      'personal_equipment': 1,
      'guild_equipment': 1,
      'consumable': 999,
      'material': 999,
    };
    ```
  - 페이즈 1 #1 §6-1 정책 (단일 999 상한)

#### ActivityLogType craftCompleted 신규

- **[FR-20]** `ActivityLogType` enum에 `craftCompleted` HiveField 27 추가
  - 위치: `band_of_mercenaries/lib/core/domain/activity_log_model.dart` 라인 60 후 (smithyRepairCompleted = 26 다음)
  - typeId 6 (기존) 그대로 유지
  - 신규 enum 값:
    ```dart
    @HiveField(27)
    craftCompleted,
    ```
  - **본 명세서 사용 위치 없음**: 실제 ActivityLog 생성은 페이즈 4 #2 `CraftingService.craft()` 시점

#### ItemEffectService material 분기

- **[FR-21]** `ItemEffectService` 변경 없음 — 기존 fail-soft 동작 활용
  - 검증 결과: `item_effect_service.dart` 라인 22 (`resolvePersonalEquipment`)와 라인 56 (`resolveGuildEquipment`)는 category가 자기 카테고리가 아니면 zero/empty 반환하는 fail-soft 구조
  - category=`material` ItemData가 들어오면 자동으로 두 메서드 모두 zero/empty 반환 → M5 신규 분기 코드 불필요
  - **결론**: `ItemEffectService` 코드 수정 0건. 신규 `resolveMaterial` 메서드 추가 금지 (사문화 회피)

#### SyncService 신규 테이블 등록

- **[FR-22]** `SyncService.allTables` 리스트에 신규 테이블 2종 추가
  - 위치: `band_of_mercenaries/lib/core/data/sync_service.dart` 라인 18-46
  - 추가: `'crafting_recipes'`, `'quest_pool_material_drops'`
  - `data_versions` 테이블에 두 행 신규 INSERT 필요 (Supabase 측)

#### DataLoader / StaticGameData

- **[FR-23]** `static_data_provider.dart`의 `StaticGameData` 클래스 확장
  - 위치: `band_of_mercenaries/lib/core/providers/static_data_provider.dart` 라인 33 (StaticGameData 클래스)
  - 신규 필드 2종 추가: `final List<CraftingRecipeData> craftingRecipes;` / `final List<QuestPoolMaterialDropData> questPoolMaterialDrops;`
  - 생성자(라인 62) `const StaticGameData(...)`에 두 필드 추가
  - `staticDataProvider` FutureProvider(라인 93~)의 `StaticGameData(...)` 생성 호출(라인 97~)에 다음 2줄 추가:
    ```dart
    craftingRecipes: dataLoader.loadFromCache('crafting_recipes', CraftingRecipeData.fromJson),
    questPoolMaterialDrops: dataLoader.loadFromCache('quest_pool_material_drops', QuestPoolMaterialDropData.fromJson),
    ```
  - **`DataLoader` 자체는 수정 불필요** — `loadFromCache<T>(tableName, fromJson)`은 제네릭이라 신규 분기 추가 없음
  - 본 명세서 범위: StaticGameData 필드/생성 호출 추가만. `craftingRecipesProvider` 등 derived Provider는 페이즈 4 #2에서 추가

### 2.2 데이터 요구사항

#### 신규 Hive 박스/필드

- 신규 박스: **없음**
- 변경 박스: **없음**
- 신규 typeId: **없음** (CLAUDE.md 정합 — 사용 중 typeId 6·8·9·10·11·13·14·15에 추가 없음)
- 변경 enum: `ActivityLogType` (typeId 6) — HiveField 27 `craftCompleted` 추가

#### 신규/변경 정적 데이터 모델

| 모델 | 변경 내용 |
|---|---|
| `ItemData` | `regionExclusive: int?` 필드 추가 (`@JsonKey(name: 'region_exclusive')`) |
| `CraftingRecipeData` (신규) | id, name, description, resultItemId, resultQuantity, inputs, unlockCondition, craftLocationId, sortOrder, createdAt |
| `RecipeInput` (신규, CraftingRecipeData 서브) | itemId, quantity |
| `RecipeUnlockCondition` (신규, CraftingRecipeData 서브) | trustLevel, chainStep, firstAcquiredItem 중 하나 |
| `QuestPoolMaterialDropData` (신규) | poolId, itemId, dropRate, qtyMin, qtyMax |
| `ChainQuestData` | 변경 없음 (rewardItems 필드 이미 존재 — 라인 24) |
| `RegionDiscoveryData` | 변경 없음 (discovery_type/payload 이미 존재) |
| `EliteMonsterData` / `EliteLootEntry` | 변경 없음 (drop_type 'material' 값만 추가) |

#### Supabase 테이블 변경

| 테이블 | 작업 |
|---|---|
| items | ALTER TABLE — `region_exclusive INTEGER NULL` 컬럼 추가 + 인덱스 2종 |
| items | CHECK 제약 갱신 — category 값 공간에 'material' 추가 |
| items | INSERT 20행 (재료 10 + 중간재 2 + 결과물 8) |
| crafting_recipes | 신규 테이블 + INSERT 10행 + 인덱스 1종 |
| quest_pool_material_drops | 신규 테이블 (스키마만, INSERT는 페이즈 4 #3) |
| elite_monsters | INSERT 1행 (거대 박쥐) |
| elite_loot_tables | INSERT 1행 (CHECK 제약 미존재 검증 완료 — ALTER 불필요) |
| region_discoveries | INSERT 3행 (knowledge 25/50/80) |
| chain_quests | UPDATE 6행 (reward_items 컬럼 이미 존재 — ALTER 불필요) |
| data_versions | INSERT 2행 (crafting_recipes / quest_pool_material_drops) + UPDATE 다수 |

#### 밸런스 수치

본 명세서는 페이즈 1·2 산출물의 수치를 그대로 적용한다. 임의 변경 없음.

- 재료 10종 + 중간재 2종 — 페이즈 1 #2 §1-2 / 페이즈 1 #3 §3-1·§3-2
- 결과물 8종 effect_json — 페이즈 2 #2 §"8종 결과물 effect_json 최종 확정 매트릭스"
- 레시피 10개 입력 수량 — 페이즈 1 #3 §4 요약표
- 거대 박쥐 사양 — 페이즈 2 #1 §1-3
- region_discoveries — 페이즈 2 #1 §1-2
- chain_quests reward_items — 페이즈 2 #1 §1-5

### 2.3 UI 요구사항

해당 없음. 본 명세서는 데이터 모델 + SQL 마이그레이션 전용. UI는 페이즈 4 #2·#3에서 처리.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/item_data.dart` | `regionExclusive: int?` 필드 추가 (라인 17 직전) | FR-3 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables` 리스트에 'crafting_recipes', 'quest_pool_material_drops' 추가 (라인 45 후) | FR-22 |
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | `stackMaxByCategory` Map 상수 추가 | FR-19 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType.craftCompleted` HiveField 27 추가 (라인 60 후) | FR-20 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | StaticGameData 클래스 라인 33 + 생성자 라인 62 + staticDataProvider 라인 97 — `craftingRecipes`·`questPoolMaterialDrops` 필드/loader 2줄 추가 | FR-23 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/crafting_recipe_data.dart` | CraftingRecipeData + RecipeInput + RecipeUnlockCondition Freezed 모델 |
| `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.dart` | QuestPoolMaterialDropData Freezed 모델 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/item_data.freezed.dart` | ItemData에 regionExclusive 필드 추가 |
| `band_of_mercenaries/lib/core/models/item_data.g.dart` | 위와 동일 (json_serializable) |
| `band_of_mercenaries/lib/core/models/crafting_recipe_data.freezed.dart` | 신규 모델 |
| `band_of_mercenaries/lib/core/models/crafting_recipe_data.g.dart` | 신규 모델 |
| `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.freezed.dart` | 신규 모델 |
| `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.g.dart` | 신규 모델 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType enum 갱신 (HiveField 27) |

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 1회 실행 필요.

### 3.4 관련 시스템

- **인벤토리 시스템 (M2a)**: InventoryItem Hive 박스 그대로 재사용. material 카테고리 행 추가만 발생 — 모델 변경 없음
- **장비 시스템 (M2a)**: ItemEffectService에 material 분기 추가. 기존 personal/guild equipment 동작 변경 없음
- **정적 데이터 동기화 (Supabase)**: SyncService allTables에 신규 2종 등록. DataLoader 디코딩 분기 추가
- **시작 거점 시스템 (M4)**: 신뢰도 단계 진입 / chain_quests 보상 / region_discoveries 발견 hook은 페이즈 4 #3 위임 — 본 명세서 영향 없음
- **엘리트 시스템 (M2b)**: elite_monsters 1행 + elite_loot_tables 1행 INSERT. drop_type='material' 값 신규 허용. EliteSpawnService / EliteLootService 코드 변경은 페이즈 4 #3 위임
- **build_runner**: ItemData 변경 + 신규 2종 모델 + ActivityLogType 변경 → 일괄 재생성 필요

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **ItemData Freezed 패턴**: `band_of_mercenaries/lib/core/models/item_data.dart` 라인 9-21 — `@JsonKey(name: 'snake_case')` 패턴, `@Default(...)` 사용. CraftingRecipeData도 동일 패턴 적용
- **ChainQuestData rewardItems JSONB**: `band_of_mercenaries/lib/core/models/chain_quest_data.dart` 라인 24 `@Default({}) @JsonKey(name: 'reward_items') Map<String, int> rewardItems` — JSONB ↔ Dart Map 매핑 표준 패턴
- **EliteMonsterData / EliteLootEntry 정적 데이터 패턴**: `band_of_mercenaries/lib/core/models/elite_monster_data.dart` / `elite_loot_entry.dart` — `data_versions` 갱신 + DataLoader 디코딩 분기 동일 적용
- **SyncService allTables 등록**: `band_of_mercenaries/lib/core/data/sync_service.dart` 라인 18-46 — 마일스톤별 추가 주석 (`// M2b 추가`) 패턴 따라 `// M5 추가`로 신규 2종 마킹
- **InventoryItem typeId 11 + 5개 HiveField**: `band_of_mercenaries/lib/features/inventory/domain/inventory_item_model.dart` — material 카테고리 추가 시 모델 변경 없이 재사용
- **ActivityLogType HiveField 추가 패턴**: `band_of_mercenaries/lib/core/domain/activity_log_model.dart` 라인 5-61 — 마지막 enum 값 다음 라인에 `@HiveField(N) newValue,` 추가 패턴

### 4.2 주의사항

- **CLAUDE.md typeId 정책 준수**: 신규 Hive 모델 미생성. 모든 신규 정적 데이터는 Freezed/JSON으로만 표현 (Hive 박스 미저장)
- **`build_runner build --delete-conflicting-outputs` 1회 실행 필수** — 일부 freezed 파일이 conflict 발생 가능
- **avoid_print rule**: SQL 마이그레이션 결과 로깅 금지. 디버그용 print 사용 시 analysis warning
- **operation-bom 영향 (별도 레포)**: items.region_exclusive 컬럼 추가 시 `table-config.ts` 셀렉트 필드 동기화 필요. 본 명세서 범위 외 — 운영 도구 작업으로 별도 처리 권고
- **drop_type='material' 신규 값**: elite_loot_tables에 'material' 값 도입은 EliteLootService 처리 코드(페이즈 4 #3)와 동시 적용해야 안전. 본 명세서는 데이터만 INSERT하되, drop이 실제로 발동하는 시점은 페이즈 4 #3 이후
- **chain_quests.reward_items UPDATE 후 동기화**: 기존 6행 UPDATE 시 `data_versions.chain_quests` 행을 갱신해야 클라이언트가 새로운 보상 데이터를 받음. SyncService 자가치유 로직은 빈 캐시만 복구 — 실제 row UPDATE 후 version 갱신 필수
- **M2b signature drop 보강 미포함 (페이즈 2 #3 §"조정 3" 권고)**: 본 명세서 SQL은 elite_loot_tables에 거대 박쥐 1행만 INSERT. 기존 39종 엘리트의 personal_equipment·guild_artifact·signature drop 데이터 보강은 별도 마일스톤 또는 hotfix 처리

### 4.3 엣지 케이스

- **items.region_exclusive 외래키 위반**: 존재하지 않는 region_id가 들어가면 INSERT 실패 → SQL 적용 시 region 3 (더스트플레인) 사전 존재 확인. M4 페이즈 4 시점에 region 3 INSERT 완료된 상태이므로 안전
- **crafting_recipes.result_item_id 외래키 위반**: 결과물 8종 + 중간재 2종 = 10종 items가 crafting_recipes INSERT 전에 모두 INSERT되어야 함 → SQL 트랜잭션 순서: items 22행 → crafting_recipes 10행 → 기타
- **inputs_json 내 item_id 무결성**: JSONB 안의 item_id는 외래키 자동 검증되지 않음. 데이터 무결성 검증은 페이즈 4 #2 `CraftingService.craft()` 시점에 ItemData 조회 실패 처리
- **chain_quests UPDATE 시 기존 reward_items 손실**: 현재 모든 6행이 `{}` 빈 맵이므로 UPDATE 안전. 만약 기존 보상이 있는 행이 있으면 merge 필요 (현재 시점 무관)
- **`data_versions` 행 누락**: SyncService는 `data_versions` 테이블 기반으로 변경 감지 → crafting_recipes / quest_pool_material_drops 신규 테이블의 data_versions 행이 누락되면 sync에서 다운로드 안 됨
- **CHECK 제약 미존재 확인**: 실 스키마 검증 결과 `elite_loot_tables.drop_type`은 CHECK 제약 없는 자유 TEXT. 'material' INSERT 자유롭게 가능. ALTER TABLE 불필요

### 4.4 구현 힌트

- **진입점**: SQL 마이그레이션 — Supabase migrations 디렉토리에 SQL 파일 1개 작성. `mcp__plugin_supabase_supabase__apply_migration` 도구로 적용
- **데이터 흐름** (Dart 측): Supabase items/crafting_recipes/quest_pool_material_drops → SyncService 다운로드 → DataLoader JSON 캐시 → `staticDataProvider` (FutureProvider) → 페이즈 4 #2 `CraftingService` 사용
- **참조 구현**:
  - SQL 마이그레이션 패턴: `Docs/spec/M4/` 하위 명세서들의 SQL INSERT 패턴 참조 (M4 페이즈 4 #1 `region_sectors` / `factions` INSERT)
  - Freezed 모델 패턴: `band_of_mercenaries/lib/core/models/item_data.dart` 라인 7-25 그대로 차용
  - JSONB 매핑: `chain_quest_data.dart` 라인 24 `Map<String, int> rewardItems` 패턴
  - SyncService 등록: `sync_service.dart` 라인 38-45 (M2a/M2b/M3 추가 주석)
- **확장 지점**:
  - 페이즈 4 #2: `CraftingService.craft(recipeId)` — `craftingRecipesProvider` 조회 → InventoryItem 차감 → 결과물 추가 → ActivityLog `craftCompleted` 기록
  - 페이즈 4 #3: 5종 출처 드랍 hook — QuestCompletionService / InvestigationNotifier / EliteLootService / TravelChoiceService / ChainQuestService 5개 도메인에 InventoryItem 추가 호출

---

## 5. 마이그레이션 SQL (인라인)

본 절은 페이즈 4 #1 SQL 인라인 처리 ~41행. Supabase migrations에 단일 SQL 파일로 작성하여 `apply_migration`으로 적용한다.

### 5.1 스키마 확장

```sql
-- M5 페이즈 4 #1 마이그레이션 — 데이터 모델 확장
-- 작성일: 2026-05-04
-- 선행: M4 페이즈 4 완료 (region 3 / settlement_3_pyegwang_reopen 활성)

BEGIN;

-- 1. items 테이블 확장
ALTER TABLE items ADD COLUMN region_exclusive INTEGER NULL REFERENCES regions(id);
CREATE INDEX idx_items_region_exclusive ON items(region_exclusive)
  WHERE region_exclusive IS NOT NULL;
CREATE INDEX idx_items_category_slot ON items(category, slot);

-- items.category CHECK 제약 갱신 ('material' 추가)
-- 기존 제약명 확인 후 DROP/ADD (제약명 미상이면 생략 가능, 응용 측 검증 의존)
-- 필요 시 운영 도구에서 별도 진행 권고

-- 2. elite_loot_tables.drop_type — CHECK 제약 미존재 확인 (실 스키마 검증 완료)
-- ALTER 불필요. drop_type='material' INSERT 자유

-- 3. crafting_recipes 신규 테이블
CREATE TABLE crafting_recipes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  result_item_id TEXT NOT NULL REFERENCES items(id),
  result_quantity INT NOT NULL DEFAULT 1,
  inputs_json JSONB NOT NULL,
  unlock_condition_json JSONB,
  craft_location_id TEXT NOT NULL DEFAULT 'old_smithy',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_crafting_recipes_result_item ON crafting_recipes(result_item_id);

-- 4. quest_pool_material_drops 신규 매핑 테이블 (스키마만, INSERT는 페이즈 4 #3)
CREATE TABLE quest_pool_material_drops (
  id BIGSERIAL PRIMARY KEY,
  pool_id TEXT NOT NULL REFERENCES quest_pools(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items(id),
  drop_rate REAL NOT NULL CHECK (drop_rate >= 0 AND drop_rate <= 1),
  qty_min INT NOT NULL DEFAULT 1,
  qty_max INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(pool_id, item_id)
);
CREATE INDEX idx_qpmd_pool ON quest_pool_material_drops(pool_id);

-- 5. data_versions 행 추가 (sync 대상 등록)
INSERT INTO data_versions (table_name, version, updated_at) VALUES
  ('crafting_recipes', 1, now()),
  ('quest_pool_material_drops', 1, now());
```

### 5.2 items INSERT (재료 10종 — 페이즈 1 #2)

```sql
-- 재료 10종 (페이즈 1 #2 §1-2)
INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json, flavor_text) VALUES
  ('mat_ore_rusty_scrap', '녹슨 쇳조각', 'material', 'material_ore', 1, NULL, '{}'::jsonb,
   '폐광 갱도에서 흩어진 평범한 쇳조각. 한때 곡괭이 끝이었거나 광차 부속이었을 것이다.'),
  ('mat_hide_dry_strap', '마른 가죽끈', 'material', 'material_hide', 1, NULL, '{}'::jsonb,
   '마른 초원 들개·도적 가방에서 풀린 짧은 가죽끈. 마을 어디서나 쓰인다.'),
  ('mat_herb_dry', '마른 약초', 'material', 'material_herb', 1, NULL, '{}'::jsonb,
   '마른 초원에 흔하게 자라는 잡초성 약초. 약초상의 가장 기본 재료.'),
  ('mat_herb_mountain_mushroom', '산기슭 버섯', 'material', 'material_herb', 1, NULL, '{}'::jsonb,
   '마른 초원 가장자리 바위틈에 무리 짓는 작은 버섯. 야간 순찰 중 자주 발견된다.'),
  ('mat_herb_dust_resin', '접착 수액', 'material', 'material_herb', 1, 3, '{}'::jsonb,
   '더스트플레인 특산 식물의 점착성 분비물. 먼지를 머금어 더 끈끈해진다.'),
  ('mat_hide_faded_cloth', '빛바랜 천 조각', 'material', 'material_hide', 2, NULL, '{}'::jsonb,
   '더스트빌 광장에 모인 잡동사니에서 풀린 오래된 천. 깃발의 원래 재질을 짐작케 한다.'),
  ('mat_relic_pyegwang_pickaxe_head', '녹슨 곡괭이 머리', 'material', 'material_ore', 2, 3, '{}'::jsonb,
   '폐광 깊숙이 박힌 채 부러진 곡괭이의 머리. 단단한 강철의 흔적.'),
  ('mat_relic_pyegwang_shard', '폐광의 유물 파편', 'material', 'material_relic_fragment', 2, 3, '{}'::jsonb,
   '폐광 안쪽에서 발견되는 정체 모를 고대 유물의 작은 조각. 마을 사람도 못 알아본다.'),
  ('mat_monster_giant_bat_fang', '거대 박쥐 송곳니', 'material', 'material_monster_part', 3, NULL, '{}'::jsonb,
   'step 3 박쥐 둥지의 우두머리에서 얻는 시그니처 트로피. 비정상적으로 크고 단단하다.'),
  ('mat_relic_ancient_seal_piece', '고대 인장 조각', 'material', 'material_relic_fragment', 3, 3, '{}'::jsonb,
   'step 6 폐광 재개방식에서 우연히 발굴되는 고대 인장의 일부. 마을 역사보다 오래된 것.');
```

### 5.3 items INSERT (중간재 2종 — 페이즈 1 #3 §3-1·§3-2)

```sql
INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json, flavor_text) VALUES
  ('mat_hide_rough_bundle', '거친 가죽끈 묶음', 'material', 'material_hide', 2, NULL, '{}'::jsonb,
   '흩어진 마른 가죽끈을 정성껏 엮어 한 묶음으로 만든다. 더 큰 작업의 기초.'),
  ('mat_ore_polished_scrap', '연마된 쇳조각', 'material', 'material_ore', 2, NULL, '{}'::jsonb,
   '녹슨 쇳조각을 사포로 갈아 본래의 강철빛을 일부 되살린다. 단단한 무기 부속의 베이스가 된다.');
```

### 5.4 items INSERT (결과물 8종 — 페이즈 2 #2)

페이즈 2 #2 §"data-generator 수치 가이드" SQL 그대로 적용 (region_exclusive 컬럼 추가 반영):

```sql
INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json, flavor_text) VALUES
  ('item_banner_dustvile_repaired', '낡은 용병단 깃발', 'guild_equipment', 'banner', 2, 3,
   '{"reputation_gain_modifier": 0.04}'::jsonb,
   '광장의 잡동사니 더미에서 발견한 천을 풀고, 마른 가죽끈으로 깃대를 묶고, 접착 수액으로 마무리한다. 처음으로 휘날리는 용병단의 정체성.'),
  ('item_weapon_miner_dagger', '광부의 단검', 'personal_equipment', 'weapon', 2, NULL,
   '{"str": 3}'::jsonb,
   '폐광에서 회수한 곡괭이 머리를 단검 형태로 다듬고, 녹슨 쇳조각을 손잡이 보강에 쓴다. 광부의 단단한 손길이 칼날 끝에 묻어 있다.'),
  ('item_artifact_pyegwang_relic', '폐광의 유물 조각', 'guild_equipment', 'artifact', 3, 3,
   '{"recruit_high_tier_chance": 0.01, "gold_reward_multiplier": 0.02}'::jsonb,
   '폐광에서 모은 유물 파편을 거대 박쥐의 송곳니로 다듬고, 마지막 발굴된 고대 인장 조각으로 봉인한다. 마을의 첫 지역 아티팩트.'),
  ('item_armor_solid_piece', '단단한 갑옷 조각', 'personal_equipment', 'armor', 2, NULL,
   '{"vit": 3}'::jsonb,
   '녹슨 쇳조각을 가죽끈으로 묶어 즉석에서 만든 갑옷. 광부 출신 마을 사람들도 이 정도는 만들 수 있다고 한다.'),
  ('item_weapon_rusty_pickaxe', '녹슨 곡괭이', 'personal_equipment', 'weapon', 2, NULL,
   '{"vit": 3}'::jsonb,
   '곡괭이 머리를 그대로 살리고 새 자루를 박았다. 단검보다 둔하지만 한 방의 무게가 다르다.'),
  ('item_banner_herbalist_seal', '약초사 인장', 'guild_equipment', 'banner', 2, 3,
   '{"injury_rate_modifier": -0.04}'::jsonb,
   '약초사 네리스가 만들어준 인장. 마른 약초와 산기슭 버섯을 정제해 봉인했다. 부상자 회복이 한결 빠르다.'),
  ('item_accessory_herb_pouch', '약초 향낭', 'personal_equipment', 'accessory', 2, NULL,
   '{"vit": 2}'::jsonb,
   '마른 약초와 산기슭 버섯을 가죽 주머니에 담아 허리춤에 걸친다. 부상의 위험을 향기로 누른다.'),
  ('item_artifact_miner_charm', '광부의 부적', 'guild_equipment', 'artifact', 2, 3,
   '{"injury_rate_modifier": -0.03}'::jsonb,
   '폐광 깊은 곳에서 마을 노인이 건네준 부적. 작은 유물 파편이 쇳조각에 박혀 있다. 부상을 막아준다는 속설.');
```

### 5.5 crafting_recipes INSERT (10행 — 페이즈 1 #3 §4)

```sql
INSERT INTO crafting_recipes (id, name, description, result_item_id, result_quantity, inputs_json, unlock_condition_json, craft_location_id, sort_order) VALUES
  ('recipe_dustvile_banner_repair', '낡은 용병단 깃발 복원', '천과 가죽끈, 접착 수액으로 깃발을 복원한다.',
   'item_banner_dustvile_repaired', 1,
   '[{"item_id":"mat_hide_dry_strap","quantity":3},{"item_id":"mat_herb_dust_resin","quantity":2},{"item_id":"mat_hide_faded_cloth","quantity":1}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 10),
  ('recipe_dustvile_miner_dagger', '광부의 단검', '폐광 곡괭이 머리를 단검으로 다듬는다.',
   'item_weapon_miner_dagger', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":3},{"item_id":"mat_hide_dry_strap","quantity":1},{"item_id":"mat_relic_pyegwang_pickaxe_head","quantity":1}]'::jsonb,
   '{"chain_step":{"chain_id":"settlement_3_pyegwang_reopen","step":1}}'::jsonb, 'old_smithy', 20),
  ('recipe_dustvile_pyegwang_relic', '폐광의 유물 조각', '유물 파편과 송곳니, 고대 인장으로 마을 아티팩트를 만든다.',
   'item_artifact_pyegwang_relic', 1,
   '[{"item_id":"mat_relic_pyegwang_shard","quantity":3},{"item_id":"mat_monster_giant_bat_fang","quantity":1},{"item_id":"mat_relic_ancient_seal_piece","quantity":1}]'::jsonb,
   '{"chain_step":{"chain_id":"settlement_3_pyegwang_reopen","step":6}}'::jsonb, 'old_smithy', 30),
  ('recipe_dustvile_hide_bundle', '거친 가죽끈 묶음', '마른 가죽끈을 정제하여 한 묶음으로 만든다.',
   'mat_hide_rough_bundle', 1,
   '[{"item_id":"mat_hide_dry_strap","quantity":3}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 100),
  ('recipe_dustvile_ore_polished', '연마된 쇳조각', '녹슨 쇳조각을 갈아 강철빛을 되살린다.',
   'mat_ore_polished_scrap', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":4}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 110),
  ('recipe_dustvile_armor_solid', '단단한 갑옷 조각', '녹슨 쇳조각과 가죽끈으로 갑옷을 만든다.',
   'item_armor_solid_piece', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":4},{"item_id":"mat_hide_dry_strap","quantity":2}]'::jsonb,
   '{"trust_level":2}'::jsonb, 'old_smithy', 40),
  ('recipe_dustvile_rusty_pickaxe', '녹슨 곡괭이', '곡괭이 머리에 새 자루를 박는다.',
   'item_weapon_rusty_pickaxe', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":2},{"item_id":"mat_relic_pyegwang_pickaxe_head","quantity":1},{"item_id":"mat_hide_dry_strap","quantity":1}]'::jsonb,
   '{"chain_step":{"chain_id":"settlement_3_pyegwang_reopen","step":1}}'::jsonb, 'old_smithy', 50),
  ('recipe_dustvile_herbalist_seal', '약초사 인장', '마른 약초와 버섯을 정제해 봉인한다.',
   'item_banner_herbalist_seal', 1,
   '[{"item_id":"mat_herb_dry","quantity":3},{"item_id":"mat_herb_mountain_mushroom","quantity":2},{"item_id":"mat_hide_dry_strap","quantity":1}]'::jsonb,
   '{"trust_level":3}'::jsonb, 'old_smithy', 60),
  ('recipe_dustvile_herb_pouch', '약초 향낭', '약초와 버섯을 가죽 주머니에 담는다.',
   'item_accessory_herb_pouch', 1,
   '[{"item_id":"mat_herb_dry","quantity":4},{"item_id":"mat_herb_mountain_mushroom","quantity":3},{"item_id":"mat_hide_dry_strap","quantity":2}]'::jsonb,
   '{"trust_level":3}'::jsonb, 'old_smithy', 70),
  ('recipe_dustvile_miner_charm', '광부의 부적', '폐광 유물 파편이 박힌 부적을 만든다.',
   'item_artifact_miner_charm', 1,
   '[{"item_id":"mat_ore_rusty_scrap","quantity":2},{"item_id":"mat_relic_pyegwang_shard","quantity":1}]'::jsonb,
   '{"first_acquired_item":"mat_relic_pyegwang_shard"}'::jsonb, 'old_smithy', 80);
```

### 5.6 elite_monsters / elite_loot_tables INSERT (페이즈 2 #1 §1-3, 실 스키마 검증 반영)

**스키마 검증 결과** (Supabase information_schema 조회):
- `elite_monsters.fixed_region_environments`: `jsonb`, NULLABLE — **실데이터 형식은 환경 태그 문자열 배열** (예: `["forest","mountain"]`, `["ruins","underground"]`, `["swamp"]`). 페이즈 2 #1 §1-3 원안의 `[3]`(region_id 정수)은 실 스키마와 불일치 → 환경 태그 형식으로 정정
- `elite_loot_tables`: 컬럼 9종 `(id, elite_id, drop_type, item_id, gold_min, gold_max, drop_rate, rarity_grade, quantity)`. id·rarity_grade NOT NULL DEFAULT 없음. quantity 단일 컬럼

```sql
INSERT INTO elite_monsters (
  id, name, description, is_unique, type_family, tier, power, spawn_rate,
  duration_multiplier, environment_tags, fixed_region_environments,
  stat_weight, title, lore
) VALUES (
  'elite_giant_bat',
  '거대 박쥐',
  '폐광 갱도에 둥지를 튼 거대 박쥐 무리의 우두머리.',
  false,
  'beast',
  2,
  80,
  0.15,
  1.0,
  '["mountain", "dungeon"]'::jsonb,
  '["mountain", "dungeon"]'::jsonb,
  '{"agi": 0.4, "str": 0.4, "vit": 0.2}'::jsonb,
  '갱도의 우두머리',
  '폐광 깊숙이 둥지를 튼 거대 박쥐. 평범한 박쥐의 두 배 크기로, 송곳니가 비정상적으로 단단하다.'
);

INSERT INTO elite_loot_tables (id, elite_id, drop_type, item_id, drop_rate, rarity_grade, quantity)
VALUES ('elite_giant_bat_fang_drop', 'elite_giant_bat', 'material', 'mat_monster_giant_bat_fang', 1.0, 'rare', 1);
```

**fixed_region_environments 정책 결정**: 페이즈 2 #1 §1-3 의도("region 3 한정 spawn")를 실 스키마(환경 태그)로 환산. 거대 박쥐는 mountain/dungeon 환경에서만 spawn → 환경 태그 `["mountain","dungeon"]` 적용. M5 시점 region 3 외 다른 region에 mountain/dungeon 환경이 활성화되어 있지 않으므로 사실상 region 3 한정 동작. M6+ 다중 거점 도입 시 mountain/dungeon 환경의 다른 region이 추가되면 재spawn될 가능성은 페이즈 2 #1 §"문제점 2" 의도(M6+ 거대 박쥐 일반 spawn 활성)와 정합.

### 5.7 region_discoveries INSERT (페이즈 2 #1 §1-2)

```sql
-- region 3 폐광 발견 3건 (knowledge 25/50/80)
-- discovery_data 페이로드 형식은 기존 region_discoveries 패턴 따라 기록
INSERT INTO region_discoveries (
  id, region_id, knowledge_threshold, discovery_type, discovery_data, description
) VALUES
  ('disc_dustvile_pyegwang_normal', 3, 25, 'normal',
   '{"items":[{"item_id":"mat_ore_rusty_scrap","quantity":3,"drop_rate":1.0}]}'::jsonb,
   '폐광의 흔적 — 갱도 입구에서 녹슨 쇳조각을 발견했다.'),
  ('disc_dustvile_pyegwang_hidden', 3, 50, 'hidden_quest',
   '{"items":[{"item_id":"mat_relic_pyegwang_shard","quantity":1,"drop_rate":1.0},{"item_id":"mat_relic_pyegwang_pickaxe_head","quantity":1,"drop_rate":0.3}]}'::jsonb,
   '폐광 깊은 흔적 — 정체 모를 유물의 파편을 찾았다.'),
  ('disc_dustvile_pyegwang_deepest', 3, 80, 'hidden_quest',
   '{"items":[{"item_id":"mat_relic_ancient_seal_piece","quantity":1,"drop_rate":1.0}],"resettable":true}'::jsonb,
   '폐광 최심부 — 고대 인장의 일부가 봉인을 풀고 떨어진다.');
```

### 5.8 chain_quests UPDATE (페이즈 2 #1 §1-5)

```sql
-- settlement_3_pyegwang_reopen 6 step의 reward_items JSONB 갱신
UPDATE chain_quests SET reward_items = '{"mat_relic_pyegwang_pickaxe_head":1,"mat_ore_rusty_scrap":1}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 1;
UPDATE chain_quests SET reward_items = '{"mat_hide_dry_strap":2}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 2;
-- step 3은 elite_loot_tables (#9)와 quest_pool drop hook으로 처리 — reward_items 빈 맵 유지
UPDATE chain_quests SET reward_items = '{}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 3;
UPDATE chain_quests SET reward_items = '{"mat_relic_pyegwang_pickaxe_head":1,"mat_herb_dust_resin":1}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 4;
UPDATE chain_quests SET reward_items = '{"mat_ore_rusty_scrap":3,"mat_relic_pyegwang_shard":1}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 5;
UPDATE chain_quests SET reward_items = '{"mat_relic_ancient_seal_piece":1,"mat_relic_pyegwang_shard":2}'::jsonb
  WHERE chain_id = 'settlement_3_pyegwang_reopen' AND step = 6;
```

### 5.9 data_versions 갱신

```sql
-- 변경된 테이블의 data_versions 갱신 (sync에서 변경 감지)
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'items';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'elite_monsters';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'elite_loot_tables';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'region_discoveries';
UPDATE data_versions SET version = version + 1, updated_at = now() WHERE table_name = 'chain_quests';

COMMIT;
```

**총 SQL 변경량**:
- ALTER TABLE 1건 (items)
- CREATE TABLE 2건 (crafting_recipes, quest_pool_material_drops)
- CREATE INDEX 4건
- INSERT items 22행 (재료 10 + 중간재 2 + 결과물 8 + ... 즉 본 명세서 §5.2~5.4 합계 20행 + 페이즈 4 #1 외 인라인 추가는 없음)
- INSERT crafting_recipes 10행
- INSERT elite_monsters 1행 / elite_loot_tables 1행
- INSERT region_discoveries 3행
- UPDATE chain_quests 6행
- INSERT data_versions 2행 (신규 테이블) + UPDATE 5행 (기존 테이블)

→ **총 약 50행 변경** (테이블 스키마 + 데이터 + 버전 갱신 합산)

---

## 6. 기획 확인 사항

본 명세서는 페이즈 1·2 산출물 7건이 모든 결정을 명시했으므로 추가 사용자 확인 사항이 거의 없다. 적용 시점 사전 조회 항목 + 코더 재량 항목으로 분리:

### 6.1 적용 시점 사전 조회 (코더가 첫 단계로 실행)

implement-spec/coder가 마이그레이션 SQL 작성 직전에 `mcp__plugin_supabase_supabase__execute_sql`로 다음을 사전 조회한다:

```sql
-- items.category CHECK 제약 존재 여부 조회
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'items'::regclass AND contype = 'c';

-- elite_monsters.fixed_region_environments 실데이터 형식 검증 (이미 검증 완료, 본 문서 §5.6 결정 반영)

-- chain_quests.reward_items 컬럼 존재 여부 (검증 완료 — 컬럼 존재, ALTER 불필요)
```

- **[Q-1]** items.category CHECK 제약이 현재 DB에 존재하는가? → 조회 결과에 따라 ALTER TABLE 진행 결정. 제약 미존재 시 §5.1 ALTER 단계 생략, 응용 코드 측 검증 의존
- **[Q-2]** ~~elite_loot_tables.drop_type CHECK 제약~~ — **검증 완료 (제약 미존재)**. ALTER 불필요로 확정
- **[Q-3]** ~~chain_quests.reward_items 컬럼 존재~~ — **검증 완료 (컬럼 존재)**. ALTER 불필요로 확정

### 6.2 코더 재량 항목

- **[Q-4]** ItemData에 추가할 `regionExclusive` 필드의 위치 — `effectJson` 직전 vs 직후 vs `tier` 직후 → 본 명세서는 `effectJson` 직전 권고 (slot/tier/region_exclusive 묶음). 코더 재량 허용
- **[Q-5]** SQL을 단일 마이그레이션 파일에 넣을지, 5.1~5.9 섹션별로 나눠 적용할지 → 본 명세서 권고: **단일 트랜잭션** (BEGIN/COMMIT 한 번). 단계별 적용은 `data_versions` 일관성을 보장하기 어려움

### 6.3 검증 완료 사항 (실 DB 조회 결과)

본 명세서 작성 중 다음 사항이 Supabase 조회로 확정됨:

| 항목 | 결과 | 근거 |
|---|---|---|
| `chain_quests.reward_items` 컬럼 | 존재 (jsonb NOT NULL DEFAULT '{}') | information_schema 조회 |
| `elite_loot_tables` 컬럼 구조 | id/elite_id/drop_type/item_id/gold_min/gold_max/drop_rate/rarity_grade/quantity 9종 | information_schema 조회 |
| `elite_loot_tables.drop_type` CHECK 제약 | 미존재 (자유 TEXT) | 실데이터 검증 |
| `elite_monsters.fixed_region_environments` 형식 | 환경 태그 문자열 배열 (예: `["forest","mountain"]`) | 실데이터 3행 조회 |
| `items.region_exclusive` 컬럼 | 미존재 → ALTER 필요 | information_schema 조회 |
