# M2a 아이템/인벤토리 인프라 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260418_item_taxonomy.md` (분류 체계 — 3카테고리·슬롯·티어)
> - `Docs/balance-design/20260418_equipment_stats.md` (개인 장비 effect_json + 전설 규격)
> - `Docs/balance-design/20260418_guild_equipment_macro.md` (용병단 장비 effect_json + 복합 키)
>
> 작성일: 2026-04-19
> 유형: M2a 마일스톤 페이즈 4 산출물 1/3 (인프라 뼈대)
> 후속 명세: 장착/해제 UI · 정수 사용 UI (본 인프라 완료 후 진행)

---

## 1. 개요

M2a "아이템의 태동" 마일스톤의 **인프라 뼈대**를 구축한다. Supabase `items` 테이블과 이를 역직렬화하는 `ItemData` 모델, 유저별 아이템 보유 상태를 저장하는 Hive `inventory` 박스, 그리고 정적 데이터 동기화 경로(`SyncService` / `DataLoader` / `staticDataProvider`)를 확장한다. 본 명세는 **데이터 레이어와 동기화 경로**에만 한정되며, 장착/해제 로직·정수 사용·UI·`ItemEffectService`·`PassiveBonusService` 확장은 후속 명세가 담당한다.

구체적으로 다음을 구현한다.

- Freezed `ItemData` 모델 (Supabase `items` 테이블 역직렬화, `category` / `slot` / `tier` / `effect_json`)
- Hive `InventoryItem` 모델 (`typeId: 11`, 수량·장착 상태 포함)
- Hive `inventory` 박스 신설 및 `HiveInitializer` 등록
- `InventoryRepository` (CRUD + 장착 상태 헬퍼)
- `SyncService` / `DataLoader` / `staticDataProvider` 확장 (18 → 19 테이블)
- `UserData` 확장 (용병단 장비 장착 슬롯: `bannerItemId`, `artifactItemIds`)
- Supabase `items` 테이블 마이그레이션 + `data_versions` 행 추가
- operation-bom `table-config.ts`에 `items` 정의 추가 (운영 편집용)

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 정적 아이템 데이터 로드**
  - `ItemData` Freezed 모델이 Supabase `items` 테이블을 역직렬화한다.
  - 필드: `id` / `name` / `description` / `flavorText` / `category` / `slot` / `tier` / `effectJson` / `createdAt` (옵션).
  - `effectJson`은 `Map<String, dynamic>`로 직접 보관하며, 카테고리별 스키마 분기 해석은 후속 `ItemEffectService`가 담당한다 (본 명세 범위 외).
  - `staticDataProvider`의 `StaticGameData`에 `List<ItemData> items` 필드가 추가되고, 앱 시작 후 `dataLoader.loadFromCache('items', ItemData.fromJson)`로 로딩된다.

- **[FR-2] 인벤토리 Hive 모델 / 박스**
  - `InventoryItem` Hive 모델(`typeId: 11`) 신설.
  - 필드:
    - `id`(String, 인벤토리 행 고유 id)
    - `itemId`(String, `ItemData.id` 참조)
    - `quantity`(int, 소모품은 수량, 장비는 항상 1)
    - `equippedTo`(String?, `mercenaryId` or `null`. 용병단 장비는 `null` 유지 — 장착은 `UserData` 필드로 관리, [FR-5] 참조)
    - `acquiredAt`(DateTime)
  - `inventory` 박스 신설. 박스명 상수 `HiveInitializer.inventoryBoxName = 'inventory'`.
  - `HiveInitializer.initialize()`에 어댑터 등록(`InventoryItemAdapter`)과 `Hive.openBox<InventoryItem>('inventory')` 추가.

- **[FR-3] InventoryRepository**
  - `inventoryRepositoryProvider`(Riverpod Provider)로 노출.
  - 조회:
    - `List<InventoryItem> getAll()`
    - `InventoryItem? getById(String id)`
    - `List<InventoryItem> getByCategory(String category, List<ItemData> items)` — 정적 데이터와 조인하여 category 필터
    - `List<InventoryItem> getEquippedBy(String mercenaryId)` — `equippedTo == mercenaryId` 필터
    - `List<InventoryItem> getUnequipped()` — `equippedTo == null` 필터
  - 쓰기:
    - `Future<InventoryItem> addItem({required String itemId, int quantity = 1})` — 소모품은 기존 행과 `itemId` 일치 시 수량 가산, 장비는 항상 신규 행(`quantity=1` 강제).
    - `Future<void> removeItem(String id)` — 단일 행 삭제.
    - `Future<void> decrementQuantity(String id, {int delta = 1})` — 소모품 수량 차감. `quantity <= 0` 시 자동 삭제.
    - `Future<void> setEquippedTo(String id, String? mercenaryId)` — 개인 장비 장착/해제.
  - 모든 쓰기 메서드는 `HiveObject.save()` 또는 `box.add()` 경로를 사용한다 (기존 `FactionStateRepository` 패턴 준수).
  - 주의: 본 명세 범위에서는 **장착 충돌 검증**(슬롯 중복·티어 호환 등)을 수행하지 않는다. 그 책임은 후속 `ItemEffectService` / 장착 UI 명세가 담당한다.

- **[FR-4] SyncService / staticDataProvider / DataLoader 확장**
  - `SyncService.allTables`에 `'items'` 추가 (기존 18 → 19).
  - 기존 동기화 흐름(`data_versions` 비교 → 변경 테이블만 다운로드 → 로컬 JSON 캐시)에 자동 편승한다. 추가 로직 불필요.
  - `StaticGameData`에 `final List<ItemData> items` 필드 추가.
  - `staticDataProvider`에서 `dataLoader.loadFromCache('items', ItemData.fromJson)` 호출.
  - 기존 로컬 캐시 보유 유저(업데이트 시나리오)에서는 서버 `data_versions.items` 행이 새로 추가되므로 `_findChangedTables()`가 자동으로 `items`를 변경 대상으로 감지하여 다운로드한다.

- **[FR-5] UserData 확장 — 용병단 장비 장착 슬롯**
  - `UserData`에 HiveField 2개 추가:
    - `@HiveField(18) String? bannerItemId` (용병단 깃발 슬롯 1)
    - `@HiveField(19) List<String> artifactItemIds` (유물 슬롯, 최대 2개)
  - 생성자에 nullable 파라미터 추가. 기본값은 `bannerItemId = null`, `artifactItemIds = <String>[]`.
  - 기존 Hive 데이터와의 호환: 신규 HiveField는 누락 시 기본값으로 복원되므로 별도 마이그레이션 플래그 불필요 (기존 `stat_migration_v2`와 같은 처리 없음).
  - 근거: `guild_equipment_macro.md` §"페이즈 4 명세 반영 필수" 항목 6의 두 옵션 중 **UserData 필드 방식** 채택 — `inventory.equippedTo="guild"` 방식은 2개 artifact 슬롯을 단일 문자열로 구분할 수 없어 UI·장착 로직이 복잡해짐.
  - 참고: 본 명세는 필드만 추가하며, 장착 시 inventory 행과의 정합(동일 `itemId`가 인벤토리에도 있어야 한다 등) 검증은 후속 장착 UI 명세가 담당한다.

- **[FR-6] Supabase 마이그레이션 (items 테이블 + data_versions 행)**
  - 신규 마이그레이션 파일: `operation-bom/supabase/migrations/007_items_table.sql` (번호는 기존 006 다음).
  - `items` 테이블 DDL:
    ```sql
    CREATE TABLE items (
      id           TEXT PRIMARY KEY,
      name         TEXT NOT NULL,
      description  TEXT NOT NULL DEFAULT '',
      flavor_text  TEXT NOT NULL DEFAULT '',
      category     TEXT NOT NULL CHECK (category IN ('personal_equipment', 'guild_equipment', 'consumable')),
      slot         TEXT NOT NULL CHECK (slot IN (
        'weapon', 'armor', 'helmet', 'boots', 'accessory',
        'banner', 'artifact',
        'essence_str', 'essence_int', 'essence_vit', 'essence_agi'
      )),
      tier         INT  NOT NULL CHECK (tier BETWEEN 1 AND 5),
      effect_json  JSONB NOT NULL DEFAULT '{}'::jsonb,
      created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    ```
  - RLS 정책 부여: 기존 `001_initial_schema.sql`의 `DO $$ ... LOOP` 패턴 재사용. 신규 마이그레이션에서도 `ALTER TABLE items ENABLE ROW LEVEL SECURITY` + authenticated SELECT/INSERT/UPDATE/DELETE 정책 4종 생성.
  - `data_versions` 신규 행:
    ```sql
    INSERT INTO data_versions (table_name) VALUES ('items') ON CONFLICT DO NOTHING;
    ```
  - **effect_json 세부 스키마 검증(카테고리별 허용 키 제한)**은 이 마이그레이션에 포함하지 않는다. 클라이언트 측(ItemEffectService 후속 명세) + 운영 측(operation-bom 편집기 검증)에서 담당. 근거: `effect_json`은 카테고리·슬롯 조합에 따라 허용 키 집합이 달라지는 복잡한 스키마이며, DB CHECK로 표현 시 유지보수성이 떨어지고 M2b/M4에서 추가될 효과 축 확장 시마다 마이그레이션을 더해야 하기 때문.

- **[FR-7] operation-bom table-config.ts 확장**
  - `operation-bom/src/lib/table-config.ts`의 테이블 맵에 `items` 정의 추가.
  - 카테고리 분류: `"world"` 또는 신규 카테고리(예: `"item"`)를 도입할지는 운영 측 컨벤션 준수. 현재 분류(world / mercenary / balance / quest / trait) 중 **가장 가까운 `"balance"` 카테고리로 편입 권장** (수치 중심 데이터이므로). 운영 담당이 별도 카테고리 신설을 원하면 해당 선택.
  - 필드 정의:
    | name | label | type | required |
    |---|---|---|---|
    | id | ID | text | true |
    | name | Name | text | true |
    | description | Description | textarea | false |
    | flavor_text | Flavor Text | textarea | false |
    | category | Category | text | true |
    | slot | Slot | text | true |
    | tier | Tier | number | true |
    | effect_json | Effect JSON | json | true |
  - `primaryKey: "id"`, `autoIncrementPK: false` (기존 `traits`와 동일한 TEXT PK 패턴).
  - category/slot은 현 타입 시스템에 셀렉트 타입이 없으므로 `text`로 두되, 운영 담당이 CHECK 제약 위반을 DB 측에서 감지. (셀렉트 타입 신설은 별도 운영 태스크).

### 2.2 데이터 요구사항

**신규 Freezed 정적 데이터 모델:**
- `ItemData` — Supabase `items` 테이블 (신규)
  - `id` TEXT / `name` TEXT / `description` TEXT / `flavor_text` TEXT / `category` TEXT / `slot` TEXT / `tier` INT / `effect_json` JSONB / `created_at` TIMESTAMPTZ

**신규 Hive 박스:**
- `inventory` — `Box<InventoryItem>`, `HiveInitializer.inventoryBoxName = 'inventory'`

**신규 Hive 모델:**
- `InventoryItem` — `typeId: 11`, HiveField 0~4 사용 (id / itemId / quantity / equippedTo / acquiredAt)

**수정 Hive 모델:**
- `UserData`(`typeId: 5`) — HiveField 18(bannerItemId: String?), 19(artifactItemIds: List<String>) 추가. 기존 필드 불변.

**수정 정적 데이터 통합:**
- `StaticGameData` — `final List<ItemData> items` 필드 추가.

**Supabase 스키마 변경:**
- `items` 테이블 신설 (DDL은 FR-6 참조).
- `data_versions` 테이블에 `('items', 1, now())` 행 삽입.

**신규 enum:** 없음. `category` / `slot` 값은 TEXT 그대로 유지하며, 클라이언트 측에서 상수 모음(예: `ItemCategory` 정적 클래스)로 보조 표현 가능 (FR에 포함하지 않음, 구현자 재량).

**밸런스 수치:** 본 명세는 인프라만 다루며 구체 수치는 후속 `data-generator` 페이즈(페이즈 3)가 Supabase에 직접 적재한다.

### 2.3 UI 요구사항

해당 없음. 본 명세는 데이터·동기화 인프라만 담당한다. 인벤토리 화면·장착 슬롯 UI·정수 사용 UX는 후속 명세가 담당한다.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | `inventoryBoxName` 상수 추가, `InventoryItemAdapter` 등록, `Hive.openBox<InventoryItem>('inventory')` 호출 추가 | 신규 박스 초기화 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 `'items'` 엔트리 추가 | 19번째 정적 테이블 동기화 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `StaticGameData`에 `List<ItemData> items` 필드 추가 (생성자 포함) + `staticDataProvider`에서 `loadFromCache('items', ItemData.fromJson)` 호출 + `ItemData` import | 정적 데이터 통합 |
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField(18) `bannerItemId`, HiveField(19) `artifactItemIds` 추가 + 생성자 파라미터 추가 | 용병단 장비 장착 슬롯 저장 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/lib/core/models/item_data.dart` | Freezed `ItemData` 모델 (Supabase 역직렬화) |
| `band_of_mercenaries/lib/features/inventory/domain/inventory_item_model.dart` | Hive `InventoryItem` 모델 (typeId:11) |
| `band_of_mercenaries/lib/features/inventory/data/inventory_repository.dart` | `InventoryRepository` + `inventoryRepositoryProvider` |
| `operation-bom/supabase/migrations/007_items_table.sql` | `items` 테이블 DDL + RLS + `data_versions` 행 |
| `band_of_mercenaries/test/features/inventory/data/inventory_repository_test.dart` | Repository CRUD 단위 테스트 |

**operation-bom 프로젝트 (별도 리포):**

| 파일 경로 | 역할 |
|---|---|
| `operation-bom/src/lib/table-config.ts` | `items` 테이블 정의 엔트리 추가 (수정) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `band_of_mercenaries/lib/core/models/item_data.dart` | freezed + json_serializable (`.freezed.dart`, `.g.dart` 생성) |
| `band_of_mercenaries/lib/features/inventory/domain/inventory_item_model.dart` | hive_generator (`.g.dart` 생성) |
| `band_of_mercenaries/lib/core/models/user_data.dart` | hive_generator (HiveField 추가로 `.g.dart` 재생성 필요) |

구현 완료 후 `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 실행 필수.

### 3.4 관련 시스템

- **정적 데이터 동기화**: `SyncService` 테이블 목록 + `data_versions` 기반 델타 동기화에 자연 편승. 기존 `regions`·`factions`와 동일한 흐름.
- **Hive 영속화**: 기존 8개 박스(`user`, `mercenaries`, `quests`, `settings`, `activityLogs`, `staticDataCache`, `regionStates`, `factionStates`)에 `inventory` 박스 추가 → **총 9개**.
- **UserData**: HiveField 17 → 19로 확장. 기존 필드 미변경.
- **operation-bom 운영 웹앱**: 테이블 편집 자동 UI에 `items` 노출. effect_json은 기존 `json` 타입 필드로 편집.
- **후속 명세 의존**:
  - `ItemEffectService` (effect_json 파싱 + 적용 — 개인 장비 스탯·전설 유니크 효과)
  - `PassiveBonusService` 확장 (용병단 장비 효과 수집)
  - `EssenceService` (정수 소비 → 영구 스탯 증가)
  - 인벤토리 화면 / 장착 UI / 용병단 장비 화면
- **본 명세에서 건드리지 않는 시스템**: `Mercenary` 모델의 `effectiveStr/Int/Vit/Agi` getter (장비 보정 반영은 후속), `QuestCalculator`, `TraitEffectService` (전설 유니크 경로 재사용은 후속 명세 시점에 결정).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Freezed 정적 모델 with JSONB**: `band_of_mercenaries/lib/features/info/domain/faction_data.dart` — `passiveBonusJson`을 `@Default(<String, dynamic>{}) Map<String, dynamic>`로 처리하는 패턴을 그대로 차용. `ItemData.effectJson`도 동일 방식.
- **snake_case JsonKey 매핑**: `band_of_mercenaries/lib/core/models/job.dart` — `@JsonKey(name: 'base_str') required int baseStr` 식의 컨벤션.
- **Hive 모델 + typeId 할당**: `band_of_mercenaries/lib/features/info/domain/faction_state_model.dart` (typeId 9, 10) — 신규 feature에서 Hive 모델·어댑터를 `domain/` 하위에 두고 Repository를 `data/`에 두는 구조. `inventory` 모듈도 동일 구조 적용.
- **Repository + Provider**: `band_of_mercenaries/lib/features/info/data/faction_state_repository.dart` — `Provider((ref) => Repository())` + `Hive.box<T>(HiveInitializer.boxName)` 접근자 + `await state.save()` 패턴.
- **Hive 초기화 시퀀스**: `band_of_mercenaries/lib/core/data/hive_initializer.dart` — 어댑터 등록 → (필요 시 마이그레이션 플래그 체크) → `openBox<T>(name)`. 본 명세에서는 마이그레이션 플래그 불필요.
- **SyncService 테이블 확장**: `band_of_mercenaries/lib/core/data/sync_service.dart:18-38` — `allTables` 상수 리스트에 엔트리 추가만 하면 전체 다운로드·델타 동기화가 자동 적용.
- **Supabase 마이그레이션 템플릿**: `operation-bom/supabase/migrations/006_region_discoveries.sql` — 최신 마이그레이션(DDL + CHECK + RLS + data_versions 행) 구조를 그대로 따라 `007_items_table.sql` 작성.

### 4.2 주의사항

- **typeId 11 고유성**: 현재 등록된 최대 typeId는 10 (FactionClueRecord). 11은 본 명세에서 최초로 할당. 다른 브랜치/명세에서 동일 번호를 선점하지 않았는지 커밋 직전 재확인.
- **HiveField 번호 규칙 (CLAUDE.md)**: UserData에 추가하는 HiveField 18/19는 반드시 **순차 할당**이며 중간에 결번을 두지 않는다.
- **한국어 코멘트**: CLAUDE.md 언어 설정에 따라 코드 주석은 한국어 기본.
- **`avoid_print` 린트**: Repository 내 디버그 출력은 `debugPrint` 사용.
- **ConstrainedBox 제약 (UI 없음)**: 본 명세 범위에 UI 없음 — 위배 가능성 없음.
- **운영 웹앱 배포 독립성**: operation-bom의 `table-config.ts`·Supabase 마이그레이션은 Flutter 앱과 **독립적으로 배포**된다. 순서:
  1. Supabase 마이그레이션 먼저 적용 (서버에 `items` 테이블 + `data_versions` 행 존재해야 함)
  2. Flutter 앱 빌드 배포 (SyncService가 `items`를 자동 감지)
  3. operation-bom 배포 (운영자가 데이터 적재)
- **effect_json 검증 미포함**: DB CHECK로 `effect_json` 내용 검증을 넣지 않는 결정은 의도적. 후속 명세에서 `ItemData.fromJson`에 assertion 또는 `ItemEffectService`의 파싱 실패 처리로 대응.

### 4.3 엣지 케이스

- **동일 itemId 소모품 복수 행**: `addItem()` 호출 시 소모품(essence 등)은 동일 `itemId` 기존 행이 있으면 수량 가산, 없으면 신규 행 생성. `category` 판정을 위해 `ItemData` 리스트를 Repository 메서드에 주입(헬퍼) 또는 `Provider` 내부에서 `staticDataProvider.future` 조회. **본 명세는 전자(주입) 방식 채택** — Repository가 staticData 의존성을 갖지 않도록.
- **장비 quantity 고정**: 장비(`personal_equipment` / `guild_equipment`)는 항상 `quantity=1`. `addItem()` 내부에서 `items` 리스트로 category 판정 후 장비는 **항상 신규 행**으로 `box.add()`.
- **장착 중 아이템 삭제**: `removeItem(id)` 호출 시 `equippedTo != null`이면 삭제 전 자동 해제를 수행하지 않는다 — 호출자(후속 UI 명세) 책임. 본 Repository는 "단일 행 삭제" 원자성만 보장.
- **UserData.artifactItemIds 최대 2개**: Repository 단계에서 강제하지 않는다. 후속 장착 UI 명세가 검증. 본 명세는 List<String>으로 필드만 제공.
- **Supabase 다운로드 부분 실패**: 기존 `SyncService._downloadTables()`는 `Future.wait` 실패 시 rethrow. `items` 추가 후에도 동일 — 첫 실행 전체 다운로드가 실패하면 캐시 초기화. 기존 동작 유지.
- **기존 유저 Hive 호환**: `UserData` HiveField 18/19 신규 추가 시 기존 저장된 UserData는 해당 필드가 누락된 상태로 역직렬화 → Hive가 nullable 타입은 null로, List 타입은 빈 리스트로 기본 복원. 생성자 기본값 지정을 `UserData`의 기존 패턴(`facilities = facilities ?? {}`)과 동일하게 `artifactItemIds ??= <String>[]`로 구현.
- **InventoryItem.id 중복**: `Hive.box<InventoryItem>.add()` 사용 시 Hive가 자체 key를 부여하지만 모델의 `id` 필드는 애플리케이션 레이어 식별자. 생성 시 `DateTime.now().microsecondsSinceEpoch.toString() + '_' + random`과 같이 충돌 가능성 낮은 방식 사용 (기존 `Mercenary.id` 생성 패턴 확인·재사용). `uuid` 패키지 미사용 상태면 기존 패턴 따름.

### 4.4 구현 힌트

- **진입점 (데이터 로드)**:
  - 앱 시작 → `main.dart` → `HiveInitializer.initialize()` (inventory 박스 오픈 추가) → `SupabaseInitializer` → `SyncService.sync()` (items 테이블 자동 다운로드) → `ProviderScope` → 첫 `staticDataProvider` 소비 시 `ItemData` 로딩.
- **데이터 흐름**:
  - 정적: Supabase `items` → 로컬 JSON 캐시(`staticDataCache` 박스의 `items` key) → `DataLoader.loadFromCache('items', ItemData.fromJson)` → `StaticGameData.items`.
  - 유저: `InventoryRepository.addItem()` → `Hive.box<InventoryItem>('inventory').add()` → `box.save()` → (후속 Provider가 watch로 UI 반영).
  - 용병단 장비 장착: `UserDataNotifier.setBanner(itemId)` (후속 명세) → `UserData.bannerItemId = itemId` → `save()`.
- **참조 구현**:
  - Freezed: `band_of_mercenaries/lib/features/info/domain/faction_data.dart:1-29` — JSONB 필드 + `@Default` 조합 그대로 차용.
  - Hive + typeId: `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart:5-21` — 간결한 3필드 모델 구조. `InventoryItem`은 5필드로 확장 적용.
  - Repository: `band_of_mercenaries/lib/features/info/data/faction_state_repository.dart:1-133` — `Provider((ref) => Repository())` + `getOrCreate` + `HiveObject.save()`.
  - SyncService 테이블 추가: `band_of_mercenaries/lib/core/data/sync_service.dart:18-38` — `allTables` 상수에 문자열 한 줄 추가만으로 완료.
  - staticDataProvider 필드 추가: `band_of_mercenaries/lib/core/providers/static_data_provider.dart` — `StaticGameData` 클래스 필드 + 생성자 + `loadFromCache` 한 줄 추가.
  - Supabase 마이그레이션 템플릿: `operation-bom/supabase/migrations/006_region_discoveries.sql` (CHECK 제약 + RLS + data_versions UPDATE 패턴).
- **확장 지점 (후속 명세용, 본 명세에서 미구현)**:
  - `lib/features/inventory/domain/item_effect_service.dart` (effect_json 파싱 + Mercenary 스탯 주입 + 전설 카테고리 ①~⑤ 분기)
  - `lib/features/inventory/domain/essence_service.dart` (정수 소비 → `Mercenary`의 base 스탯 영구 증가 필드 신설)
  - `Mercenary.effectiveStr/Int/Vit/Agi` getter에 `equipmentBonus` 가산 — HiveField 추가 필요 (용병별 영구 정수 누적치 / 장비 참조). 본 명세 범위 외.
  - `PassiveBonusService.collect()`에 용병단 장비 effect_json 수집 경로 추가.
  - `lib/features/inventory/view/*` UI 화면군.

---

## 5. 기획 확인 사항

아래 항목은 기획서에서 복수 옵션을 병렬 제시하거나 구현자 재량이 필요한 부분이다. 기본 결정안을 제시하되 사용자 확인이 필요하면 수정 요청 바람.

- **[Q-1] 용병단 장비 장착 슬롯 저장 방식**
  - 질문: `taxonomy.md:181`은 "`UserData`에 `banner_item_id` / `artifact_1_item_id` / `artifact_2_item_id` 필드"를 제시하고, `guild_equipment_macro.md:306`은 `UserData` 필드 방식 또는 `inventory.equippedTo="guild"` 방식의 양자택일을 허용함.
  - 결정: **UserData 필드 방식** 채택. `bannerItemId`(String?) + `artifactItemIds`(List<String>, 최대 2).
  - 근거: `equippedTo="guild"` 단일 리터럴로는 banner와 2개 artifact 슬롯을 구분할 수 없으며, List로 구분하면 "어느 슬롯에 꽂혔는가"의 순서가 UserData의 List 순서에 암시적으로 묶여 UI·장착 해제 로직이 더 복잡해짐. 필드 분리 방식이 단순 명료.
  - 필요 시 재검토.

- **[Q-2] 정수(essence) 복수 보유를 수량 누적 vs 개별 인스턴스**
  - 질문: 정수는 소모품. 동일 `itemId`(예: `essence_str_t1`) 여러 개를 하나의 InventoryItem 행의 `quantity`로 관리할지, 매 획득마다 새 행을 만들지.
  - 결정: **수량 누적** 방식. `InventoryItem`에 `quantity` 필드가 있으며 소모품은 `addItem()` 시 기존 행에 가산.
  - 근거: 기획서 `taxonomy.md:45` "소모품은 장착 슬롯을 차지하지 않고 **수량으로 보유**"에 직접 부합. UI 표시도 `정수 × 3` 형태가 자연.
  - 필요 시 재검토.

- **[Q-3] `effect_json`의 DB 측 세부 스키마 검증 수준**
  - 질문: Supabase `items` 테이블에 `effect_json` 내부 키를 카테고리별로 검증하는 CHECK 제약을 걸지 여부 (예: `personal_equipment`는 `str|intelligence|vit|agi|legendary_effect` 키만 허용 등).
  - 결정: **DB 측 세부 검증 미도입.** 클라이언트(`ItemEffectService` 후속 명세) + 운영 편집기(operation-bom) 양쪽에서 검증.
  - 근거: 카테고리·슬롯·티어 조합에 따라 허용 키가 달라져 SQL CHECK로 표현하기 복잡하며, 후속 마일스톤에서 효과 축이 확장될 때마다 DDL 마이그레이션이 필요. `category`/`slot`/`tier`의 기본 허용값 CHECK만 유지 (FR-6).
  - 필요 시 재검토 (예: `effect_json` 유효성 테스트를 운영 배포 전에 CI에서 실행).

- **[Q-4] operation-bom `table-config.ts`의 items 카테고리**
  - 질문: 기존 5개 카테고리(world/mercenary/balance/quest/trait) 중 items는 어디에 속하나, 신규 `item` 카테고리를 만들지.
  - 결정: **`balance` 카테고리에 편입**(수치 중심). 신규 카테고리 신설은 운영 UI 분류가 커진 시점에 별도 태스크로.
  - 근거: 기존 facilities·mercenary_wages·ranks 등 수치 데이터가 balance에 있어 톤 일관.
  - 필요 시 재검토 (운영 담당과 협의).

- **[Q-5] `InventoryItem.id` 생성 전략**
  - 질문: 인벤토리 행 고유 id를 어떻게 생성할지. `uuid` 패키지 의존성 도입 vs 기존 패턴 재사용.
  - 결정: 기존 `Mercenary.id` / `ActiveQuest.id` 생성 패턴 재사용 (구현 시 확인). 대부분의 유사 시스템에서 `DateTime.now().microsecondsSinceEpoch.toString()` 기반 + 접두사·랜덤 방식 사용.
  - 근거: 신규 의존성 추가 최소화. `pubspec.yaml`에 `uuid`가 이미 있다면 그것을 사용해도 무방.
  - 구현 시 실제 코드에서 확인하여 통일.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|---|---|---|
| 수정/생성 파일 | 수정 4 + 생성 5(Flutter) + 1(operation-bom) + 1(테스트) = **11개** | 대규모 |
| 영향 시스템 | core/data, core/models, core/providers, 신규 features/inventory, operation-bom, Supabase (**6개 이상**) | 대규모 |
| 신규 클래스 | ItemData, InventoryItem, InventoryRepository (**3개 이상**) | 대규모 |
| 데이터 모델 | Supabase `items` 테이블 신설 + Hive `inventory` 박스 + UserData HiveField 2개 확장 | 대규모 |
| UI 작업 | 없음 | 소규모 |
| 기존 시스템 변경 | SyncService·DataLoader·staticDataProvider·HiveInitializer 4곳 확장 | 대규모 |

**추천: implement-agent (5/6점)**
- 다중 feature 경계(core + 신규 inventory + operation-bom + Supabase)에 걸친 인프라 작업이며, 파이프라인 방식이 단계별 검증·코드 생성(build_runner) 관리에 유리.
