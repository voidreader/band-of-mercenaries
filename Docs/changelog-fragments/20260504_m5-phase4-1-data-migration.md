### M5 페이즈 4 #1: 데이터 모델 확장 + 시드 마이그레이션 (재료/제작 인프라)

- **신규 Supabase 테이블 2종**: `crafting_recipes`(제작 레시피 — id/result_item_id/result_quantity/inputs_json/unlock_condition_json/craft_location_id 9컬럼·10행 INSERT) + `quest_pool_material_drops`(의뢰 풀 재료 드랍 매핑 — pool_id/item_id/drop_rate/qty_min/qty_max·스키마만, INSERT는 페이즈 4 #3 위임). 인덱스 4종 + UNIQUE(pool_id, item_id) + drop_rate CHECK 제약.
- **items 테이블 확장**: `region_exclusive INTEGER NULL REFERENCES regions(id)` 컬럼 추가. category CHECK 4종(`material` 추가) + slot CHECK 16종(신규 `material_ore`/`material_hide`/`material_herb`/`material_relic_fragment`/`material_monster_part` 5종 추가) DROP/ADD 갱신. 인덱스 2종 추가.
- **items 신규 INSERT 20행**: 재료 10종(녹슨 쇳조각·마른 가죽끈·마른 약초·산기슭 버섯·접착 수액·빛바랜 천 조각·녹슨 곡괭이 머리·폐광의 유물 파편·거대 박쥐 송곳니·고대 인장 조각) + 중간재 2종(거친 가죽끈 묶음·연마된 쇳조각) + 결과물 8종(낡은 용병단 깃발·광부의 단검·폐광의 유물 조각·단단한 갑옷 조각·녹슨 곡괭이·약초사 인장·약초 향낭·광부의 부적). region_exclusive로 region 3 한정 6종 마킹.
- **엘리트 신규 1종**: `elite_giant_bat`(거대 박쥐·tier 2·power 80·spawn_rate 0.15·beast·환경 태그 mountain/dungeon — fixed_region_environments 환경 태그 형식 적용) + 시그니처 트로피 1행(`elite_giant_bat_fang_drop` drop_type='material'·drop_rate 1.0·rarity 'rare').
- **region_discoveries 신규 3행**: region 3 폐광 발견 (knowledge 25/50/80 — `disc_dustvile_pyegwang_normal`/`hidden`/`deepest`). discovery_type CHECK에 'normal' 추가하여 6종(info/elite/hidden_quest/faction_clue/transform/normal) 갱신.
- **chain_quests UPDATE 6행**: `settlement_3_pyegwang_reopen` step 1·2·4·5·6 reward_items에 mat_xxx 보상 부여. step 3은 elite_loot_tables(거대 박쥐)·quest_pool drop hook으로 처리하므로 빈 맵 유지.
- **신규 Freezed 모델 2종**: `CraftingRecipeData`(+ `RecipeInput`/`RecipeUnlockCondition`/`ChainStepCondition` 4 클래스 단일 파일·JSONB inputs_json/unlock_condition_json 매핑·trustLevel/chainStep/firstAcquiredItem 3 옵션 nullable 단순 매핑) + `QuestPoolMaterialDropData`. `ItemData.regionExclusive: int?` 필드 1개 추가.
- **`ActivityLogType.craftCompleted` HiveField 27 추가** (typeId 6 유지·실제 사용은 페이즈 4 #2 `CraftingService.craft()` 위임). `GameConstants.stackMaxByCategory` Map 상수(개인/길드 1, 소모품/재료 999) 사전 등록.
- **`StaticGameData` 확장**: craftingRecipes/questPoolMaterialDrops 2 필드 추가 + `SyncService.allTables`에 신규 2 테이블 등록 + `data_versions` INSERT 2행. `DataLoader` 분기 추가 0건(제네릭 진입점 활용).
- **`mcp__plugin_supabase_supabase__apply_migration`로 단일 트랜잭션 적용**. 적용 중 명세서 가정 위반 2건(`items_slot_check`/`region_discoveries_discovery_type_check` CHECK 제약 존재) 발견 → 사용자 승인 후 DROP/ADD로 처리.
