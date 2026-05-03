# M2a 아이템/인벤토리 인프라 구현 결과

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure.md`
> 실행일: 2026-04-19
> 결과: 전체 PASS

---

## 1. 실행 요약

- 파이프라인: planner → coder(1단계 병렬 4건) → Supabase MCP 마이그레이션 → build_runner → coder(3단계 병렬 3건) → coder(테스트) → verifier(풀 검증)
- TASK 수: 10개 (+ MCP 마이그레이션, build_runner, verifier 3건) → TASK ≥ 3 → **풀 검증 모드** 적용
- 검증 루프: 1회 PASS (재작업 없음)
- 정적 분석: `flutter analyze` → No issues found
- 테스트: `flutter test` → 300/300 passed (신규 InventoryRepository 8건 포함)

## 2. 사용자 지시로 인한 범위 조정

원본 명세서 대비 2건의 조정:

- **TASK-8**: operation-bom 리포에 SQL 파일 생성 대신 **Supabase MCP `apply_migration`로 직접 적용**. 이름 `007_items_table`. 결과: `items` 테이블 + RLS 5정책 + `data_versions('items')` 행 추가. `list_tables` 확인으로 `items` 존재 및 `data_versions` 19행 확인.
- **TASK-9 (operation-bom `table-config.ts`)**: 이번 파이프라인에서 제외. 운영 웹앱 편집 UI 추가는 operation-bom 관련 작업으로 후속 일괄 진행.

## 3. 변경 파일 목록

### 3.1 신규 생성 (Flutter)

| 경로 | 유형 | 설명 |
|---|---|---|
| `band_of_mercenaries/lib/core/models/item_data.dart` | 신규 | Freezed `ItemData` 모델 (snake_case JsonKey + @Default Map 패턴) |
| `band_of_mercenaries/lib/features/inventory/domain/inventory_item_model.dart` | 신규 | Hive `InventoryItem` 모델, typeId: 11, HiveField 0~4 |
| `band_of_mercenaries/lib/features/inventory/data/inventory_repository.dart` | 신규 | `InventoryRepository` + `inventoryRepositoryProvider` |
| `band_of_mercenaries/test/features/inventory/data/inventory_repository_test.dart` | 신규 | 단위 테스트 8건 (CRUD + 장착/해제 + 수량 분기) |

### 3.2 수정 (Flutter)

| 경로 | 유형 | 설명 |
|---|---|---|
| `band_of_mercenaries/lib/core/data/sync_service.dart` | 수정 | `allTables` 리스트 18 → 19 (`'items'` 추가) |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | 수정 | `inventoryBoxName` 상수 + `InventoryItemAdapter` 등록 + `openBox<InventoryItem>` 호출 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | 수정 | `StaticGameData.items` 필드 + 생성자 + `loadFromCache('items', ItemData.fromJson)` |
| `band_of_mercenaries/lib/core/models/user_data.dart` | 수정 | HiveField(18) `bannerItemId` + HiveField(19) `artifactItemIds` + 초기화 식 확장 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | 파급 수정 | `StaticGameData` 생성자 required 필드 추가에 따른 `items: const <ItemData>[]` 보강 + import 추가 |

### 3.3 Supabase (MCP로 직접 적용)

- `apply_migration(name: '007_items_table')` — `items` 테이블 DDL + CHECK 제약 3종(category/slot/tier) + RLS 5정책(anon SELECT / authenticated SELECT / Editors INSERT/UPDATE/DELETE) + `data_versions('items') ON CONFLICT DO NOTHING`

### 3.4 자동 생성 (build_runner)

| 경로 | 이유 |
|---|---|
| `lib/core/models/item_data.freezed.dart` | freezed |
| `lib/core/models/item_data.g.dart` | json_serializable |
| `lib/features/inventory/domain/inventory_item_model.g.dart` | hive_generator |
| `lib/core/models/user_data.g.dart` (재생성) | hive_generator (HiveField 18/19 반영) |

## 4. 검증 결과 요약

| 항목 | 결과 |
|---|---|
| FR-1 (ItemData Freezed) | PASS |
| FR-2 (InventoryItem + inventory 박스) | PASS |
| FR-3 (InventoryRepository + Provider) | PASS |
| FR-4 (SyncService/staticDataProvider 확장) | PASS |
| FR-5 (UserData HiveField 18/19) | PASS |
| FR-6 (Supabase items + data_versions) | PASS |
| FR-7 (operation-bom table-config.ts) | 범위 외 — 사용자 지시로 후속 일괄 처리 |
| Q-1 UserData 필드 방식 | 준수 (equippedTo='guild' 미사용) |
| Q-2 소모품 수량 누적 | 준수 (addItem 내 category 분기) |
| Q-5 uuid v4 생성 | 준수 (기존 uuid ^4.4.2 재사용) |
| typeId 11 유일성 | 준수 (최대 10 → 11 신규 할당) |
| HiveField 순차 (UserData 17→18→19) | 준수 (결번 없음) |
| CLAUDE.md 금지사항 | 위반 없음 (print 없음, 한국어 주석) |
| `flutter analyze` | 0 issues |
| `flutter test` | 300/300 pass |

검증 루프 재작업 횟수: **0회** (verifier 1회 호출로 PASS).

## 5. 정적 분석 재확인

`flutter analyze` 초기 실행에서 4개 이슈 발견 후 모두 수정:

- (info) `item_data.dart:1` dangling library doc comment → docstring을 import 이후로 이동
- (info) `inventory_item_model.dart:1` dangling library doc comment → 동일 처리
- (warning) `inventory_repository.dart:1` unused import `package:flutter/foundation.dart` → 제거
- (error) `quest_completion_service_test.dart:20` missing required argument `items` → `items: const <ItemData>[]` + import 추가

수정 후 재분석: **No issues found**.

## 6. 후속 작업 안내

- **operation-bom 일괄 작업 (연기됨)**:
  - `operation-bom/src/lib/table-config.ts`에 `items` 엔트리 추가 (카테고리 `balance`, 필드 8종, TEXT PK)
  - operation-bom 측 마이그레이션 파일 기록(선택) — Supabase DB에는 이미 MCP로 적용되어 있으므로 파일은 기록용
- **후속 명세 (페이즈 4 산출물 2/3, 3/3)**:
  - 장착/해제 UI + `ItemEffectService` (effect_json 파싱 + Mercenary 스탯 주입 + 전설 카테고리 ①~⑤)
  - 정수 사용 UI + `EssenceService` (Mercenary base 스탯 영구 증가 필드 신설)
  - `PassiveBonusService.collect()`에 용병단 장비 effect_json 수집 경로 추가
  - `UserDataNotifier`에 `setBanner(itemId)` / `setArtifact(slot, itemId)` 등 장착 액션 추가

## 7. CLAUDE.md 금지사항 위반

**없음.**

## 8. build_runner 재실행 필요 여부

이번 파이프라인에서 이미 수행 완료. 후속 명세에서 Mercenary 모델 확장 등이 발생하면 재실행 필요.

```
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```
