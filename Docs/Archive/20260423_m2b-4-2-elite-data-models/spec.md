# 엘리트 데이터 모델 + SyncService 확장 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260420_elite_monster_catalog.md`
> 기획 문서: `Docs/content-design/[content]20260420_elite_drop_table.md`
> 작성일: 2026-04-23
> 마일스톤: M2b 페이즈 4-2

---

## 1. 개요

엘리트 몬스터 시스템의 데이터 기반을 구축한다. `elite_monsters` / `elite_loot_tables` Supabase 테이블 DDL, 두 테이블에 대응하는 Flutter Freezed 모델(`EliteMonsterData` / `EliteLootEntry`), SyncService 및 StaticGameData 확장, `InvestigationNotifier`의 `discovery_type = 'elite'` 처리를 포함한다. 이 명세 완료 후 M2b 4-3(엘리트 퀘스트 생성 + 드랍 판정)의 선행 조건이 충족된다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1]** `elite_monsters` 테이블 DDL을 Supabase에 적용한다.
  - 컬럼: `id TEXT PK`, `name TEXT`, `description TEXT`, `is_unique BOOLEAN`, `type_family TEXT`, `tier INTEGER`, `power INTEGER`, `spawn_rate REAL`, `duration_multiplier REAL`, `environment_tags JSONB NOT NULL DEFAULT '[]'`, `stat_weight JSONB NOT NULL DEFAULT '{}'`
  - 유니크 전용 추가 컬럼: `fixed_region_environments JSONB nullable`, `lore TEXT nullable`, `title TEXT nullable`
  - `data_versions` 테이블에 `elite_monsters` 행 INSERT (version=1)

- **[FR-2]** `elite_loot_tables` 테이블 DDL을 Supabase에 적용한다.
  - 컬럼: `id TEXT PK`, `elite_id TEXT NOT NULL FK → elite_monsters.id`, `drop_type TEXT NOT NULL`, `item_id TEXT nullable FK → items.id`, `gold_min INTEGER nullable`, `gold_max INTEGER nullable`, `drop_rate REAL NOT NULL`, `rarity_grade TEXT NOT NULL`, `quantity INTEGER NOT NULL DEFAULT 1`
  - CHECK 제약: `drop_rate BETWEEN 0.0 AND 1.0`
  - 인덱스: `(elite_id)` — 엘리트 완료 시 드랍 테이블 조회용
  - `data_versions` 테이블에 `elite_loot_tables` 행 INSERT (version=1)

- **[FR-3]** `EliteMonsterData` Freezed 모델을 신규 작성한다.
  - 파일: `band_of_mercenaries/lib/core/models/elite_monster_data.dart`
  - 모든 컬럼 매핑. `environmentTags`, `statWeight`, `fixedRegionEnvironments`는 `@Default` 사용
  - `build_runner` 재실행 필요

- **[FR-4]** `EliteLootEntry` Freezed 모델을 신규 작성한다.
  - 파일: `band_of_mercenaries/lib/core/models/elite_loot_entry.dart`
  - 모든 컬럼 매핑. `quantity`는 `@Default(1)`
  - `build_runner` 재실행 필요

- **[FR-5]** `SyncService.allTables`에 `'elite_monsters'`(20번째)와 `'elite_loot_tables'`(21번째)를 추가한다.
  - 파일: `band_of_mercenaries/lib/core/data/sync_service.dart`

- **[FR-6]** `StaticGameData`에 `eliteMonsters`와 `eliteLootEntries` 필드를 추가하고 `staticDataProvider`에서 각 테이블을 캐시에서 로드한다.
  - 파일: `band_of_mercenaries/lib/core/providers/static_data_provider.dart`

- **[FR-7]** `InvestigationNotifier._completeInvestigation()`에 `discovery_type = 'elite'` 처리 분기를 추가한다.
  - 파일: `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart`
  - `discoveryData['elite_id']` 파싱 → `unlockedEliteIds`에 누적
  - 활동 로그: `discoveryData['reveal_text']` 우선, 없으면 기본 메시지
  - `addTriggeredDiscovery`는 기존 코드에서 이미 모든 `discoveryType`에 공통 처리됨 (변경 불필요)

- **[FR-8]** `InvestigationResult`에 `unlockedEliteIds` 필드를 추가한다.
  - 파일: `band_of_mercenaries/lib/features/investigation/domain/investigation_result.dart`
  - Phase 4-4 UI에서 엘리트 발견 팝업 표시에 사용

### 2.2 데이터 요구사항

| 항목 | 상세 |
|------|------|
| 신규 Supabase 테이블 | `elite_monsters` (DDL) |
| 신규 Supabase 테이블 | `elite_loot_tables` (DDL) |
| 신규 data_versions 행 | `elite_monsters` version=1, `elite_loot_tables` version=1 |
| 신규 Freezed 모델 | `EliteMonsterData`, `EliteLootEntry` |
| 수정 파일 | `static_data_provider.dart`, `sync_service.dart`, `investigation_notifier.dart`, `investigation_result.dart` |

**`EliteMonsterData` 필드 스펙:**
```dart
@freezed
class EliteMonsterData with _$EliteMonsterData {
  const factory EliteMonsterData({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'is_unique') required bool isUnique,
    @JsonKey(name: 'type_family') required String typeFamily,
    required int tier,
    required int power,
    @JsonKey(name: 'spawn_rate') required double spawnRate,
    @JsonKey(name: 'duration_multiplier') required double durationMultiplier,
    @JsonKey(name: 'environment_tags')
    @Default(<String>[])
    List<String> environmentTags,
    @JsonKey(name: 'stat_weight')
    @Default(<String, double>{})
    Map<String, double> statWeight,
    @JsonKey(name: 'fixed_region_environments')
    List<String>? fixedRegionEnvironments,
    String? lore,
    String? title,
  }) = _EliteMonsterData;

  factory EliteMonsterData.fromJson(Map<String, dynamic> json) =>
      _$EliteMonsterDataFromJson(json);
}
```

**`EliteLootEntry` 필드 스펙:**
```dart
@freezed
class EliteLootEntry with _$EliteLootEntry {
  const factory EliteLootEntry({
    required String id,
    @JsonKey(name: 'elite_id') required String eliteId,
    @JsonKey(name: 'drop_type') required String dropType,
    @JsonKey(name: 'item_id') String? itemId,
    @JsonKey(name: 'gold_min') int? goldMin,
    @JsonKey(name: 'gold_max') int? goldMax,
    @JsonKey(name: 'drop_rate') required double dropRate,
    @JsonKey(name: 'rarity_grade') required String rarityGrade,
    @Default(1) int quantity,
  }) = _EliteLootEntry;

  factory EliteLootEntry.fromJson(Map<String, dynamic> json) =>
      _$EliteLootEntryFromJson(json);
}
```

**`InvestigationResult` 추가 필드:**
```dart
final List<String> unlockedEliteIds; // 기본값: const []
```

### 2.3 UI 요구사항

없음. 이 명세는 데이터 모델 + 인프라 확장만 포함한다. `unlockedEliteIds`를 활용한 엘리트 발견 팝업 UI는 M2b 4-4 명세에서 다룬다.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 `'elite_monsters'`, `'elite_loot_tables'` 추가 | FR-5 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `StaticGameData`에 `eliteMonsters`, `eliteLootEntries` 필드 + import + loadFromCache 추가 | FR-6 |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart` | `_completeInvestigation()` 내 `elite` 분기 추가 | FR-7 |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_result.dart` | `unlockedEliteIds` 필드 추가 | FR-8 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/elite_monster_data.dart` | `EliteMonsterData` Freezed 모델 |
| `band_of_mercenaries/lib/core/models/elite_loot_entry.dart` | `EliteLootEntry` Freezed 모델 |
| `band_of_mercenaries/supabase/migrations/20260423_m2b_4_2_elite_tables.sql` | DDL + data_versions INSERT |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/elite_monster_data.freezed.dart` | 신규 Freezed 모델 |
| `band_of_mercenaries/lib/core/models/elite_monster_data.g.dart` | json_serializable |
| `band_of_mercenaries/lib/core/models/elite_loot_entry.freezed.dart` | 신규 Freezed 모델 |
| `band_of_mercenaries/lib/core/models/elite_loot_entry.g.dart` | json_serializable |

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

### 3.4 관련 시스템

| 시스템 | 영향 |
|--------|------|
| `SyncService` | `allTables` 확장으로 첫 실행 시 `elite_monsters`, `elite_loot_tables` 자동 다운로드 |
| `staticDataProvider` | `eliteMonsters`, `eliteLootEntries` 캐시 로드 경로 추가 |
| `InvestigationNotifier` | `elite` 발견 타입 처리 + 활동 로그 기록 |
| `InvestigationResult` | `unlockedEliteIds` 추가 — 4-4 UI 소비 대상 |
| `RegionState.triggeredDiscoveries` | 변경 없음. `elite` 발견도 기존 공통 경로로 자동 기록됨 |
| M2b 4-3 엘리트 퀘스트 생성 | **의존 선행 조건**. `staticData.eliteMonsters`와 `Region.environmentTags`를 교차 조회하여 출현 후보 필터링 |

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

| 파일 | 참고 내용 |
|------|----------|
| `lib/core/models/item_data.dart` | Freezed + json_serializable 단순 필드 패턴 |
| `lib/features/info/domain/faction_data.dart:22` | `@Default(<String>[]) List<String>` JSONB 배열 패턴 |
| `lib/core/models/region.dart:15-17` | `@Default(<String>[]) List<String> environmentTags` — 동일 패턴 적용 |
| `lib/core/providers/static_data_provider.dart:19-23` | `items` 필드 추가 패턴(M2a) — 같은 방식으로 확장 |
| `lib/features/investigation/domain/investigation_notifier.dart:134-183` | `faction_clue` 분기 처리 패턴 — `elite` 분기는 이 바로 아래 `else if`로 추가 |
| `lib/features/info/domain/faction_clue_result.dart` | 발견 결과 값 객체 패턴 — `InvestigationResult.unlockedEliteIds`는 더 단순한 `List<String>`으로 충분 |

### 4.2 주의사항

- **`Map<String, double>` 역직렬화**: `stat_weight` JSONB는 Supabase에서 `{"str": 0.4, "vit": 0.4}` 형태로 내려온다. `@Default(<String, double>{})` 사용 시 `json_serializable`이 자동으로 `Map<String, dynamic>` → `Map<String, double>` 캐스팅을 처리하나, Dart의 타입 추론에서 dynamic 값이 `int`(정수)로 내려올 경우 캐스팅 오류 가능. SQL DDL에서 `stat_weight`를 `JSONB` 타입으로 저장하고 값은 항상 float으로 삽입해야 함 (`0.4`가 아닌 `0.4::float`). 대안: `Map<String, dynamic>`으로 선언하고 사용 측에서 `.toDouble()`로 변환.

- **`@Default(<String, double>{})` Lint 오류 가능성**: `freezed_annotation`에서 Map 타입 `@Default`는 Dart 타입 추론과 충돌하여 빌드 오류가 날 수 있음. 안전한 대안: `@JsonKey(name: 'stat_weight') @Default(<String, dynamic>{}) Map<String, dynamic> statWeight` 선언 후 getter에서 변환.

- **`InvestigationResult`는 일반 클래스(non-Freezed)**: `investigation_result.dart`는 Freezed 미사용 일반 클래스이므로 `build_runner` 재실행 불필요. `final List<String> unlockedEliteIds;` 필드 추가 + 생성자에 `this.unlockedEliteIds = const []` 기본값 추가 후 `InvestigationNotifier`의 생성 호출부 2곳(성공/실패) 업데이트 필요.

- **`data_versions`에 신규 테이블 행 INSERT 필수**: `elite_monsters`, `elite_loot_tables`가 `data_versions`에 없으면 `SyncService._findChangedTables()`가 서버 버전을 `0`(로컬 없음)으로 인식해 매 실행마다 풀 다운로드를 시도하지 않는다. 단, 첫 실행 경로(`_fullDownload`)는 `allTables` 목록 기준이므로 DDL 실행 시 함께 INSERT해야 한다.

- **`RegionState.triggeredDiscoveries`를 통한 엘리트 해금**: `elite` 타입 발견도 기존 공통 루프에서 `repo.addTriggeredDiscovery(regionId, d.id)`가 호출되므로 별도 저장 로직 불필요. 4-3에서 엘리트 퀘스트 생성 시 `regionState.triggeredDiscoveries`에 해당 유니크의 discovery ID가 포함되어 있으면 출현 가능 상태로 판정.

### 4.3 엣지 케이스

- **`elite_monsters`/`elite_loot_tables` 데이터 미투입 상태**: DDL은 적용되었으나 데이터가 없는 경우, `staticData.eliteMonsters.isEmpty`가 되어 4-3 엘리트 퀘스트 생성 로직이 아무 후보도 반환하지 않음 → 정상 (빈 풀로 안전 처리). 데이터는 별도 data-generator 단계에서 INSERT.

- **기존 캐시와 신규 테이블**: 이미 앱을 실행한 기기에는 `elite_monsters`, `elite_loot_tables` 캐시가 없음. `DataLoader.loadFromCache()`는 캐시 없으면 빈 리스트 반환하므로 크래시 없음 — `data_versions`에 version=1이 추가되면 다음 포그라운드 복귀 시 자동 다운로드.

- **`stat_weight` JSON 정수/실수 혼용**: Supabase가 `{"str": 0, "vit": 0}` 형태로 0을 int로 내려보낼 수 있음. Dart에서 `Map<String, double>` 직접 캐스팅 시 `'int' is not a subtype of 'double'` 런타임 오류 발생 가능. `Map<String, dynamic>`으로 받아 필요 시 `.toDouble()` 처리 권장.

### 4.4 구현 힌트

- **진입점**: 없음 (데이터 모델 + 인프라 확장)
- **데이터 흐름**: Supabase `elite_monsters` / `elite_loot_tables` → 앱 시작 시 `SyncService.sync()` → `DataLoader.saveToCache()` → `DataLoader.loadFromCache('elite_monsters', EliteMonsterData.fromJson)` → `staticDataProvider` → 앱 전역에서 `staticData.eliteMonsters` 접근 가능
- **`investigation_notifier.dart` 수정 위치**: 127번째 줄 `for (final d in newlyTriggered)` 블록 내, `faction_clue` 분기(line 134-183) 바로 아래 `else if (d.discoveryType == 'elite')` 분기 추가. `continue;`로 기존 generic 로그(line 185-188) 건너뜀
- **`investigation_result.dart` 수정**: 생성자에 `this.unlockedEliteIds = const []` 추가. `InvestigationNotifier` 내 `result =` 생성 호출 2곳에 `unlockedEliteIds:` 파라미터 추가 (성공 시 elite discovery ID 목록, 실패 시 빈 리스트)
- **참조 구현**: `lib/features/info/domain/faction_clue_result.dart` — 발견 결과 값 전달 패턴 (단, 엘리트는 더 단순한 ID 리스트면 충분)
- **확장 지점**: `staticDataProvider` 확장 후 `staticData.eliteMonsters`와 `staticData.eliteLootEntries`가 4-3에서 바로 참조 가능

---

## 5. 기획 확인 사항

- **[Q-1] `stat_weight` JSONB 타입 안전성** → `Map<String, dynamic>` 선언 + 사용 측 `.toDouble()` 변환으로 결정 (runtime type 오류 방지). 명세서 기준: `Map<String, dynamic> statWeight`로 선언.

- **[Q-2] `InvestigationResult.unlockedEliteIds` 도입 범위** → Phase 4-2에서 필드만 추가하고, UI 소비는 Phase 4-4에서 처리. 현재 `investigationCompletedProvider`를 감지하는 UI 코드가 있으므로 필드 추가는 하위 호환적으로 진행 가능.

- **[Q-3] `elite_loot_tables` FK `item_id → items.id` 강제 여부** → DDL에 FK 제약 포함 권장. M2a `items` 테이블은 이미 존재. 단, data-generator가 아직 실행되지 않아 `elite_loot_tables` 데이터 없으므로 FK 위반 없음.

---

## 6. 구현 순서 체크리스트

1. **[Supabase]** `20260423_m2b_4_2_elite_tables.sql` 마이그레이션 실행
   - `elite_monsters` 테이블 CREATE
   - `elite_loot_tables` 테이블 CREATE + 인덱스
   - `data_versions` INSERT × 2

2. **[Flutter]** `elite_monster_data.dart` 신규 작성 (Freezed 모델)

3. **[Flutter]** `elite_loot_entry.dart` 신규 작성 (Freezed 모델)

4. **[Flutter]** `sync_service.dart` — `allTables` 확장

5. **[Flutter]** `static_data_provider.dart` — `StaticGameData` 확장 + import + loadFromCache

6. **[Flutter]** `investigation_result.dart` — `unlockedEliteIds` 추가

7. **[Flutter]** `investigation_notifier.dart` — `elite` 분기 추가 + `InvestigationResult` 생성 호출 업데이트

8. **[빌드]** `dart run build_runner build --delete-conflicting-outputs`

9. **[검증]** `flutter analyze` 통과 확인
