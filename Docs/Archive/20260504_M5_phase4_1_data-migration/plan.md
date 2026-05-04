# M5 페이즈 4 #1 — 데이터 모델 확장 + 시드 마이그레이션 구현 계획

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260504_M5_phase4_1_data-migration.md`
> 작성일: 2026-05-04
> 검증 모드: 풀 검증 (TASK 10개 ≥ 3)
> 최종 판정: PASS

---

## 1. 구현 개요

M5 "재료와 제작" 마일스톤의 데이터 모델 인프라 + Supabase 시드 마이그레이션. UI 변경 0건. 페이즈 4 #2(`CraftingService`) / #3(드랍 hook + 거점 화면)의 선행 인프라.

### 적용 범위 요약

- Supabase: ALTER 1 + CREATE TABLE 2 + CREATE INDEX 4 + INSERT 36행 (items 20 / crafting_recipes 10 / elite_monsters 1 / elite_loot_tables 1 / region_discoveries 3 / data_versions 2 신규) + UPDATE 11행 (chain_quests 6 / data_versions 5)
- Dart: 신규 Freezed 모델 2개 + 기존 모델 1 필드 추가 + ActivityLogType enum 1 값 추가 + GameConstants 상수 1 + SyncService 2 항목 추가 + StaticGameData 4 변경
- build_runner: 7개 .freezed.dart / .g.dart 파일 재생성

---

## 2. 실행한 TASK (10개)

### Stage 1 (병렬 7개)

#### TASK-0: SQL 사전 조회
- main이 `mcp__plugin_supabase_supabase__execute_sql`로 직접 수행
- 결과: `items_category_check` 존재(3종 → 4종 갱신 필요), `items_slot_check` 존재(11종 → 16종 갱신 필요 — **명세서 §FR-4 가정 위반 발견**), settlement_3_pyegwang_reopen 6 step reward_items 모두 빈 맵, items 22개 신규 id 충돌 없음
- **사용자 옵션 1 승인**: items_slot_check DROP/ADD로 신규 5종 slot 포함

#### TASK-1: CraftingRecipeData Freezed 모델 신규 생성
- 파일: `band_of_mercenaries/lib/core/models/crafting_recipe_data.dart`
- 정의 클래스 4개: `CraftingRecipeData` / `RecipeInput` / `RecipeUnlockCondition` / `ChainStepCondition`
- 모두 `fromJson` factory 포함, JSONB 매핑 (`inputs_json` → `List<RecipeInput>`, `unlock_condition_json` → `RecipeUnlockCondition?`)

#### TASK-2: QuestPoolMaterialDropData Freezed 모델 신규 생성
- 파일: `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.dart`
- 단일 클래스 7 필드 (id/poolId/itemId/dropRate/qtyMin/qtyMax/createdAt)

#### TASK-3: ItemData regionExclusive 필드 추가
- 파일: `band_of_mercenaries/lib/core/models/item_data.dart`
- 위치: tier 다음, effectJson 직전 (명세서 §6.2 Q-4 권고)
- `@JsonKey(name: 'region_exclusive') int? regionExclusive`

#### TASK-4: ActivityLogType.craftCompleted HiveField 27
- 파일: `band_of_mercenaries/lib/core/domain/activity_log_model.dart`
- 라인 60(`smithyRepairCompleted = 26`) 다음에 `@HiveField(27) craftCompleted` 추가
- typeId 6 유지

#### TASK-5: GameConstants.stackMaxByCategory 상수
- 파일: `band_of_mercenaries/lib/core/constants/game_constants.dart`
- 4 키 Map 상수 추가 (personal_equipment:1, guild_equipment:1, consumable:999, material:999)

#### TASK-6: SyncService.allTables 확장
- 파일: `band_of_mercenaries/lib/core/data/sync_service.dart`
- 라인 45 다음에 `'crafting_recipes'`, `'quest_pool_material_drops'` 2 항목 추가

### Stage 2

#### TASK-7: build_runner 코드 생성
- 명령: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
- 결과: 9.3초, 15 outputs 정상 생성
- 영향 파일: item_data / crafting_recipe_data / quest_pool_material_drop_data / activity_log_model 의 .freezed.dart / .g.dart

### Stage 3

#### TASK-8: StaticGameData 확장
- 파일: `band_of_mercenaries/lib/core/providers/static_data_provider.dart`
- 4개 변경: import 2개 + 필드 2개 + 생성자 매개변수 2개 + staticDataProvider loader 호출 2개
- StaticGameData 인스턴스 생성처 1곳 (staticDataProvider 내부)

#### PHASE 2.5 빌드 게이트 — 1차 실패
- `flutter analyze` 결과 9개 에러 발생
  - `home_screen.dart:525` ActivityLogType switch 비포괄 (TASK-4 craftCompleted 추가 영향)
  - 4개 테스트 파일에서 StaticGameData 생성 시 `craftingRecipes` / `questPoolMaterialDrops` required 매개변수 누락 (TASK-8 코더가 호출처 grep을 부정확하게 보고)
- `dart-build-resolver` 호출 → 5개 파일 외과적 수정 → flutter analyze PASS

### Stage 4

#### TASK-9: Supabase SQL 마이그레이션
- 파일 작성: `band_of_mercenaries/supabase/migrations/20260504_m5_phase4_1_data_migration.sql` (260줄)
- 1차 적용 실패 — `region_discoveries.discovery_type='normal'` CHECK 위반 발견 (**명세서 §FR-10 가정 위반**)
- **사용자 옵션 A 승인**: discovery_type CHECK에 'normal' 추가하여 6종 갱신
- 2차 적용 성공 (`mcp__plugin_supabase_supabase__apply_migration`)
- 검증 쿼리 8종 모두 PASS:
  - material 12 / 결과물 8 / 레시피 10 / 거대 박쥐 1 + loot 1 / 폐광 발견 3 / chain reward 5 (step 3 빈 맵 유지) / 신규 data_versions 2

---

## 3. 변경 파일 목록

### 직접 변경 파일 (Dart, 명세서 §3.1 범위 내)

| 파일 경로 | 유형 | 설명 |
|---|---|---|
| `band_of_mercenaries/lib/core/models/item_data.dart` | 수정 | regionExclusive 필드 1개 추가 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | 수정 | allTables 2 항목 추가 |
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | 수정 | stackMaxByCategory Map 1 상수 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | 수정 | craftCompleted HiveField 27 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | 수정 | import/필드/생성자/loader 4 변경 |

### 신규 생성 파일 (명세서 §3.2 범위 내)

| 파일 경로 | 설명 |
|---|---|
| `band_of_mercenaries/lib/core/models/crafting_recipe_data.dart` | 4 Freezed 클래스 |
| `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.dart` | 단일 Freezed 클래스 |
| `band_of_mercenaries/supabase/migrations/20260504_m5_phase4_1_data_migration.sql` | 단일 트랜잭션 SQL 마이그레이션 |

### 빌드 게이트 외과적 수정 (명세서 §3.1 범위 외 — 컴파일 통과용)

| 파일 경로 | 유형 | 설명 |
|---|---|---|
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | 수정 | ActivityLogType switch에 craftCompleted case 1줄 추가 (smithyRepairCompleted와 동일 매핑, 페이즈 4 #2에서 별도 매핑 예정) |
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | 수정 | StaticGameData 생성에 `craftingRecipes: const []` / `questPoolMaterialDrops: const []` 인자 추가 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | 수정 | 동일 |
| `band_of_mercenaries/test/features/quest/domain/quest_narrative_render_test.dart` | 수정 | 동일 |
| `band_of_mercenaries/test/features/quest/domain/special_flag_processor_test.dart` | 수정 | 동일 |

### 자동 생성 파일 (build_runner)

| 파일 경로 |
|---|
| `band_of_mercenaries/lib/core/models/item_data.freezed.dart` |
| `band_of_mercenaries/lib/core/models/item_data.g.dart` |
| `band_of_mercenaries/lib/core/models/crafting_recipe_data.freezed.dart` |
| `band_of_mercenaries/lib/core/models/crafting_recipe_data.g.dart` |
| `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.freezed.dart` |
| `band_of_mercenaries/lib/core/models/quest_pool_material_drop_data.g.dart` |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` |

---

## 4. 명세서 가정 위반 — 사용자 결정 사항

본 구현 중 명세서 §6.3 "검증 완료 사항" 외에 추가 가정 위반 2건이 사전 조회·SQL 적용 단계에서 발견됨. 사용자 승인 후 처리.

### 위반 1 — `items_slot_check` CHECK 제약 존재 (옵션 1 승인)

- **명세서 §FR-4 가정**: "현재 slot 컬럼은 자유 문자열, DB CHECK 제약 변경 없음"
- **실 DB 상태**: `items_slot_check` 제약이 11종 slot만 허용
- **처리**: DROP/ADD로 신규 5종(`material_ore`/`material_hide`/`material_herb`/`material_relic_fragment`/`material_monster_part`) 포함 16종 갱신
- **반영 위치**: SQL 파일 라인 26~33

### 위반 2 — `region_discoveries.discovery_type` CHECK 제약 (옵션 A 승인)

- **명세서 §FR-10 가정**: discovery_type='normal' INSERT 가능
- **실 DB 상태**: `region_discoveries_discovery_type_check` 제약이 5종(`info`/`elite`/`hidden_quest`/`faction_clue`/`transform`)만 허용
- **처리**: DROP/ADD로 'normal' 추가 6종 갱신
- **반영 위치**: SQL 파일 라인 36~39

---

## 5. 검증 결과

### PHASE 2.5 빌드 게이트
- 1차 실패 (9 issues) → dart-build-resolver 외과적 수정 → 2차 PASS
- `flutter analyze`: No issues found
- `flutter test`: 512/512 PASS

### PHASE 3 풀 검증 (병렬)

| 에이전트 | 판정 | 비고 |
|---|---|---|
| verifier | PASS | 모든 REQ 충족 + 시그니처 일치 + 호환성 OK |
| flutter-reviewer | APPROVE | CRITICAL·HIGH 0건. MEDIUM 3건 (차단 아님) |

### MEDIUM 이슈 3건 (차회 정리 사이클로 이월)

1. `sync_service.dart` allTables 인라인 번호 주석 (27/28/29) — 일부만 번호 붙어 일관성 부족
2. `static_data_provider.dart` `// M5 추가` 주석 8개 반복 — CLAUDE.md "기본 코멘트 없음" 위반
3. `crafting_recipe_data.dart` 4개 클래스 `///` doc-comment — 다른 모델 컨벤션과 불일치 (item_data.dart는 무주석)

### Supabase 검증 쿼리 결과

| 항목 | 기대값 | 실측값 |
|---|---|---|
| items WHERE category='material' | 12 | 12 |
| 결과물 8종 INSERT 확인 | 8 | 8 |
| crafting_recipes 행 | 10 | 10 |
| elite_giant_bat | 1 | 1 |
| elite_loot_tables(elite_giant_bat) | 1 | 1 |
| region_discoveries (region_id=3, 폐광 prefix) | 3 | 3 |
| chain_quests reward_items 비-빈 (5건, step 3 빈 맵) | 5 | 5 |
| 신규 data_versions (crafting_recipes / quest_pool_material_drops) | 2 | 2 |
| data_versions 갱신 (items / elite_monsters / elite_loot_tables / region_discoveries / chain_quests) | +1 | 모두 +1 |

---

## 6. build_runner 재실행 필요 파일

해당 없음 (PHASE 2.5에서 일괄 실행 완료). 후속 모델 변경 발생 시 다시 실행.

---

## 7. CLAUDE.md 위반 사항

### typeId 정책 — 위반 없음
- 신규 Hive 모델 0건 (CraftingRecipeData / QuestPoolMaterialDropData는 정적 JSON 데이터, Hive 미저장)
- 신규 typeId 0건
- ActivityLogType (typeId 6)에 HiveField 27만 추가 — CLAUDE.md "다음 HiveField" 표 갱신 권고: 27 → 28 (별도 문서 작업, finalize-feature 단계)

### 코멘트 정책 — 부분 위반 (MEDIUM 이슈로 기록)
- `static_data_provider.dart` 8개 위치 `// M5 추가` 주석 중복
- `crafting_recipe_data.dart` 4개 `///` doc-comment
- 사유: 코더 자체 결정. CLAUDE.md "기본 코멘트 없음, WHY만" 원칙에 부분 반함. flutter-reviewer가 MEDIUM 권고로 분류, 차회 정리 사이클로 이월.

### avoid_print 등 분석 룰 — 위반 없음
- `flutter analyze` No issues found

---

## 8. 후속 작업 (페이즈 4 #2·#3 위임 사항)

### 페이즈 4 #2 (CraftingService + 인벤토리 4탭)
- `CraftingService.craft(recipeId)` 구현 — `craftingRecipesProvider` 조회 → InventoryItem 차감 → 결과물 추가 → ActivityLog `craftCompleted` 기록
- `craftingRecipesProvider` 등 derived Provider 추가
- `home_screen.dart` ActivityLogType switch에 craftCompleted 별도 아이콘/색상 매핑 (현재 임시: smithyRepairCompleted와 동일)

### 페이즈 4 #3 (드랍 출처 hook + 거점 대장간)
- 5종 드랍 hook 추가: QuestCompletionService / InvestigationNotifier / EliteLootService / TravelChoiceService / ChainQuestService
- `quest_pool_material_drops` 행 INSERT (본 명세서는 스키마만)
- 거점 대장간 화면 (settlement)
