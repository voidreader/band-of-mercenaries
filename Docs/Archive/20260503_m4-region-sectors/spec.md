# M4 페이즈 4 #2 region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260503_sector-system-redesign.md` (페이즈 1 #2 — 섹터 시스템 재설계)
> - `Docs/content-design/[content]20260503_starting-settlement.md` (페이즈 1 #3 — 시작 거점 더스트플레인·더스트빌)
> 작성일: 2026-05-03
> 선행 페이즈: 페이즈 4 #1 `[spec]20260503_m4-region-migration.md` — regions 199→40, region 3 = 더스트플레인(mountain)·`startingRegionId/startingSector` 상수 도입, `GameConstants.sectorCount` `@Deprecated` 마킹 (값 10 stub 유지)

---

## 1. 개요

`regions.sector_count` 컬럼 + `region_sectors` 정규화 테이블을 신설하여 모든 리전의 섹터 개수·이름·유형(`sector_type` 5종)을 데이터 기반으로 전환한다. 기존 하드코딩된 `List.generate(10, ...)`(MovementScreen) + `GameConstants.sectorCount = 10` stub을 제거하고, region별 sector_count(4·5·6 가변, M4 MVP 기준 4 또는 5)에 따라 동적으로 그리드를 렌더링한다. AppTheme에 `sectorDungeon`/`sectorField` 신규 색상 2종을 추가하며, MovementScreen 그리드에서만 dungeon/field 아이콘+테두리 표시(LayerSidebar/QuestCardBadges 시각 정책은 기존 village/ruins/hidden 3종 그대로).

본 명세는 **인프라 코드 마이그레이션에 집중**하고, region_sectors 약 164행 데이터 시드는 별도 페이즈 3(또는 페이즈 4 후속)에서 일괄 처리한다. 본 페이즈에서는 더스트플레인(region 3) 4섹터를 코드 fallback 상수로 인라인하여 데이터 시드 부재 시에도 시작 거점 진입이 가능하도록 보장한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1 — `regions.sector_count` 컬럼 신설 (Supabase + Region 모델)
- **상세 동작**: Supabase `regions` 테이블에 `sector_count INT NOT NULL DEFAULT 4 CHECK (sector_count BETWEEN 1 AND 6)` 컬럼 추가. Flutter `Region` 모델(`band_of_mercenaries/lib/core/models/region.dart`)에 `@JsonKey(name: 'sector_count') @Default(4) int sectorCount` 필드 추가.
- **조건**: 본 컬럼은 region.sectorCount 동적 조회의 근거. 기존 39개 보존 region 중 4개(region_id 1, 23, 127, 146)는 `sector_count = 5`로 UPDATE, 나머지 36개는 기본값 4 유지. 신규 region 200(T9)은 4.
- **검증**: ALTER 후 모든 region에 NOT NULL 충족. CHECK 위반 0건.

#### FR-2 — `region_sectors` 정규화 테이블 신설 (Supabase)
- **상세 동작**: `region_sectors` 신규 테이블 생성. 컬럼:
  ```
  id              TEXT PRIMARY KEY                            -- 명명 규칙: r{region_id}_s{sector_index}
  region_id       INTEGER NOT NULL REFERENCES regions(region) ON DELETE CASCADE
  sector_index    INTEGER NOT NULL CHECK (sector_index BETWEEN 1 AND 6)  -- 1-based
  name            TEXT NOT NULL
  sector_type     TEXT NOT NULL CHECK (sector_type IN ('village','ruins','hidden','dungeon','field'))
  environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb
  description     TEXT
  UNIQUE (region_id, sector_index)
  ```
- **조건**: 본 페이즈에서는 **테이블 생성·인덱스만 만들고 데이터 INSERT는 수행하지 않는다** (Q1=D 결정). region_sectors 약 164행 시드는 후속 페이즈에서 일괄 처리. SyncService 구동 시 빈 결과(`[]`)로 정상 캐시되어야 한다.
- **검증**: `SELECT COUNT(*) FROM region_sectors = 0`. 테이블 메타데이터·CHECK·UNIQUE 모두 적용. `data_versions`에 `region_sectors` 신규 항목 추가 (version=1).

#### FR-3 — `RegionSector` Freezed 모델 + DataLoader/StaticGameData/SyncService 통합
- **상세 동작**:
  - `band_of_mercenaries/lib/core/models/region_sector.dart` 신규 작성 (freezed + json_serializable). 필드 7종: `id`, `regionId`(@JsonKey 'region_id'), `sectorIndex`(@JsonKey 'sector_index'), `name`, `sectorType`(@JsonKey 'sector_type'), `environmentTags`(@JsonKey 'environment_tags', `@Default(<String>[])`), `description`(nullable String).
  - `StaticGameData`(`band_of_mercenaries/lib/core/providers/static_data_provider.dart`)에 `final List<RegionSector> regionSectors` 필드 추가, 생성자 파라미터·`staticDataProvider` 빌더 모두 갱신. import 추가.
  - `SyncService.allTables`(`band_of_mercenaries/lib/core/data/sync_service.dart` 18~45행)에 `'region_sectors'` 항목 `'regions'` 다음 줄에 추가 (M4 페이즈 4 #2 코멘트 표기).
- **조건**: build_runner 재실행 필수 (`region_sector.freezed.dart`, `region_sector.g.dart` 생성).
- **검증**: 정적 분석 통과 + 첫 실행 시 27개 테이블 모두 다운로드 + 빈 region_sectors 캐시 정상 로드 (`isCacheEmpty` 자가치유 대상 진입 시 자동 재시도).

#### FR-4 — `GameConstants.sectorCount` 상수 완전 제거 + 잔여 호출자 마이그레이션
- **상세 동작**: `band_of_mercenaries/lib/core/constants/game_constants.dart` 5~6행의 `@Deprecated` `sectorCount = 10` 라인 완전 삭제. 잔여 hardcoded `10` 사용처 1곳 동적 변환:
  - `band_of_mercenaries/lib/features/movement/view/movement_screen.dart:238` `List.generate(10, ...)` → `List.generate(currentRegion.sectorCount, ...)`. (currentRegion은 movement_screen build() 라인 77에서 이미 추출됨.)
- **조건**: 페이즈 4 #1에서 `GameConstants.sectorCount` 직접 호출자 0건 확인됨 (Explore 보고). hardcoded `10`은 movement_screen.dart 단일 지점.
- **검증**: `grep -r "sectorCount" lib/` → `region.sectorCount` / `RegionSector` 관련만 매칭, `GameConstants.sectorCount` 매칭 0건. `flutter analyze` 통과.

#### FR-5 — MovementScreen 동적 섹터 그리드 렌더링
- **상세 동작**: `band_of_mercenaries/lib/features/movement/view/movement_screen.dart`의 섹터 선택 Wrap(225~260행)에서:
  1. `List.generate(10, ...)` → `List.generate(targetRegion.sectorCount, ...)` 변경. (`_selectedRegion` 기준 — 사용자가 선택 중인 리전의 sector_count 사용. 이미 라인 78에서 추출된 `targetRegion`을 그대로 사용.)
  2. _selectedSector가 targetRegion.sectorCount 초과인 케이스(다른 리전 선택 후 남은 잔여 값) → setState 시 `_selectedSector = _selectedSector.clamp(1, targetRegion.sectorCount)` 또는 region 변경 시 `_selectedSector = 1`로 리셋. 현재 코드의 region 변경 핸들러 위치를 확인하여 가장 영향 적은 지점에 clamp 도입.
  3. Wrap 레이아웃은 **단일 가로 Wrap 유지** (Q4=A). sector_count 4·5·6 모두 spacing 6 / runSpacing 6의 가로 정렬로 표시.
- **조건**: `_SectorTile` 위젯은 변경 없음. `chainTargetSectors` 매칭(라인 244~246)은 1-based sector 값 그대로 사용 — 기존 동작 유지.
- **검증**: 더스트플레인 진입 시 4개 타일만 렌더, region 1·23·127·146 진입 시 5개 타일 렌더, 그 외 현존 region 모두 4개 타일 (sector_count 컬럼 데이터 기반).

#### FR-6 — `region_sectors` 데이터 부재 시 더스트플레인 4섹터 fallback 상수
- **상세 동작**: `band_of_mercenaries/lib/core/data/region_sector_fallback.dart` 신규 작성. 더스트플레인(region 3) 4섹터 정적 상수(`List<RegionSector> dustplainSectors`) 정의. 기획서 `starting-settlement.md` 1.2~1.3절 데이터 그대로:
  - `r3_s1` (1, 더스트빌, village, ["mountain","village"], "산기슭의 작은 마을…")
  - `r3_s2` (2, 폐광, dungeon, ["mountain","dungeon"], "한때 마을의 생계였던 광산…")
  - `r3_s3` (3, 마른 초원, field, ["mountain","plains"], "마을 외곽의 거친 풀밭…")
  - `r3_s4` (4, 먼지로 덮인 길, field, ["mountain","road"], "외부와 더스트플레인을 잇는 유일한 산길…")
- **조건**: 본 fallback은 `staticData.regionSectors`에서 `regionId == 3`이 비어있을 때만 사용. region_sectors 시드(후속 페이즈)가 적용되면 자동으로 비활성화. 다른 region 39개에 대한 fallback은 **제공하지 않는다** — 시드 미배포 시 MovementScreen은 sector_count는 동적이지만 섹터 이름·sector_type 정보가 없어 기존 시각(번호만 표시)으로 렌더(Q1=D 결정).
- **검증**: 시드 미배포 상태 첫 실행 시 더스트빌만 sector_type 'village' 아이콘 노출. 기타 리전은 "1" "2" "3" "4" 번호만.

#### FR-7 — RegionSector lookup 헬퍼 (StaticGameData 확장)
- **상세 동작**: `StaticGameData`에 인스턴스 메서드 또는 별도 헬퍼 함수로 `RegionSector? lookupSector(int regionId, int sectorIndex)` 제공. 우선순위:
  1. `regionSectors.where((s) => s.regionId == regionId && s.sectorIndex == sectorIndex).firstOrNull` 먼저 조회.
  2. null이면 region 3에 한해 `RegionSectorFallback.dustplainSectors`에서 fallback 조회.
  3. 그 외 region은 null 반환 — 호출자가 sector_type 표시를 생략.
- **조건**: MovementScreen `_SectorTile` 빌드 시 sector_type 아이콘 표시는 본 lookup 결과를 사용. 기존 `sectorChanges` 변형(0-based key) 우선순위는 유지(M3 변형 결과가 더스트빌 fallback보다 우선). 우선순위 정책: `sectorChanges` (변형) > `regionSectors` lookup (data 또는 fallback) > 표시 없음.
- **검증**: 변형이 없는 더스트빌 1번 섹터 진입 → village 아이콘. 변형 발생한 섹터 → 변형 결과 아이콘.

#### FR-8 — AppTheme `sectorDungeon` / `sectorField` 신규 색상
- **상세 동작**: `band_of_mercenaries/lib/core/theme/app_theme.dart` 43~50행 영역에 신규 색상 2종 추가:
  ```dart
  static const Color sectorDungeon = Color(0xFFB71C1C); // dungeon (위험 적갈색)
  static const Color sectorField = Color(0xFF558B2F);   // field (평온 녹색)
  ```
- **조건**: MovementScreen `_SectorTile._transformColor`에 dungeon/field 분기 추가:
  - `'dungeon' => AppTheme.sectorDungeon`
  - `'field' => AppTheme.sectorField`
  - village/ruins/hidden은 기존 transformVillage/Ruins/Hidden 그대로
- **조건**: dungeon/field는 **MovementScreen 그리드에서만 시각 적용** (Q4=A 일관성 유지). LayerSidebar는 변경 없음(기존 village/ruins/hidden 3종만), QuestCardBadges도 변경 없음(기존 village/ruins/hidden 이모지만). 기획서 3.4절에 명시된 "LayerSidebar 8단계 fold 의미 보존" 정책.
- **검증**: 더스트플레인 sector 2(폐광) 타일에 적갈색 테두리 + ⛏️ 아이콘 노출 (fallback 데이터 기반).

#### FR-9 — MovementScreen `_SectorTile` 아이콘 매핑 확장
- **상세 동작**: `_SectorTile._transformIcon` 함수 확장:
  - `'dungeon' => '⛏️'`
  - `'field' => '🌾'`
  - 기존 village/ruins/hidden 그대로
- **조건**: 본 매핑은 `_SectorTile`이 받는 `transformType` 값이 sectorChanges(변형) 또는 region_sectors lookup 결과 중 하나임을 가정. 호출자(MovementScreen 라인 251~256)는 sector_type 결정 우선순위(FR-7)를 따라 단일 String을 전달.
- **검증**: dungeon 아이콘 ⛏️ 정상 표시. field 아이콘 🌾 정상 표시.

#### FR-10 — 인덱싱 베이스 일관성 정책 명문화
- **상세 동작**: 기획서 2.2절의 인덱싱 정책을 코드 주석으로 명문화. 다음 위치에 한 줄 주석 추가:
  - `region_sector.dart` 모델 클래스 docstring: "sectorIndex는 1-based(1..6). 마스터 데이터 가독성 우선."
  - `region_state_model.dart:17` 기존 주석 보강: "key는 0-based('0'~'9'), region_sectors.sector_index는 1-based(1..6) — 변환 시 -1/+1."
  - `quest_provider.dart:173` 기존 주석 보강: "user.sector(1-based) → quest_generator/sectorChanges key(0-based) 변환 위해 -1."
- **조건**: 본 페이즈에서는 변환 헬퍼(`_to0Based` / `_to1Based` static)를 신규 추가하지 않는다 — 기존 인라인 패턴(`(userData.sector - 1).toString()`)이 충분히 작동 중이므로 어댑터 추가는 페이즈 4 #4 또는 페이즈 5에서 필요 시 도입.
- **조건**: 본 페이즈는 **헬퍼 도입을 보류**한다. 인덱싱 일관성은 주석 명문화로만 처리.
- **검증**: `quest_provider.dart`·`dispatch_screen.dart`·`quest_sort_service.dart`·`quest_narrative_service.dart`의 `userData.sector` 사용처가 모두 동일 변환 패턴을 따르는지 grep 확인 (이미 일관됨).

#### FR-11 — chain_quests `target_sector_id` 검증 ASSERT
- **상세 동작**: 본 페이즈의 Supabase 마이그레이션 SQL에 다음 ASSERT 단계 포함:
  ```sql
  DO $$
  BEGIN
    IF (SELECT COUNT(*) FROM chain_quests WHERE target_sector_id IS NOT NULL) > 0 THEN
      RAISE EXCEPTION 'chain_quests.target_sector_id 비-null 행 감지 — 1-based(1..sectorCount) 변환 룰 필요';
    END IF;
  END $$;
  ```
- **조건**: 기획서 4.1절 명시 — 실측 24행 모두 null이므로 변환 작업 자체는 불필요. 본 ASSERT는 미래 데이터 입력 시 회귀 방지 목적.
- **검증**: 마이그레이션 실행 시 EXCEPTION 미발생.

#### FR-12 — region_discoveries 3행 sector_index 재매핑 SQL
- **상세 동작**: 기획서 4.2절의 SQL을 본 페이즈 마이그레이션에 인라인:
  ```sql
  -- region 18: sector_count=4 유지, sector_index 5→1 재매핑 (M9 이연 region이지만 정합성 확보)
  UPDATE region_discoveries
  SET discovery_data = jsonb_set(discovery_data, '{sector_index}', '1')
  WHERE region_id = 18 AND discovery_type = 'transform'
    AND (discovery_data->>'sector_index')::int >= 4;

  -- region 23, 146: sector_count=5 승격 + sector_index 6/7 → 4 재매핑 (1-based로는 5번 섹터)
  UPDATE region_discoveries
  SET discovery_data = jsonb_set(discovery_data, '{sector_index}', '4')
  WHERE region_id IN (23, 146) AND discovery_type = 'transform'
    AND (discovery_data->>'sector_index')::int >= 4;
  ```
- **조건**: 본 SQL은 0-based sector_index 컨벤션 유지(region_discoveries.discovery_data.sector_index). transform_type='hidden' 데이터를 보존하는 것이 목적. UPDATE 행 수는 기획서 기준 최대 3건.
- **검증**: UPDATE 후 모든 region_discoveries(transform)의 sector_index가 0..3(region 18) 또는 0..4(region 23·146)에 들어옴.

#### FR-13 — Hive `RegionState.sectorChanges` 키 정리 어댑터
- **상세 동작**: 페이즈 4 #1의 `RegionMigrationService.migrate()`(`band_of_mercenaries/lib/core/data/region_migration_service.dart`)에 추가 단계 도입:
  1. 살아남은 40개 region의 `sectorChanges` 키 중 `key >= sectorCount`(0-based 기준)인 항목 제거.
  2. 별도 멱등성 플래그 `region_sector_count_v1`(`SettingsKeys`에 신규 상수) 사용.
  3. 페이즈 4 #1 플래그(`region_migration_v1`)와 분리된 별도 1회 실행.
- **조건**: 페이즈 4 #1 플래그가 이미 true인 사용자도 본 단계는 새로 실행되어야 함. 따라서 별도 플래그 사용. region_sector_count_v1 미적용 사용자만 본 단계 진입.
- **조건**: staticData를 입력으로 받아 region_id → sectorCount 맵을 만들어야 함. RegionMigrationService.migrate 시그니처는 이미 `StaticGameData`를 받으므로 그대로 활용.
- **검증**: 마이그레이션 후 `regionStates` 박스의 모든 sectorChanges에서 key >= sectorCount인 항목 0건. 변형 hidden 보존되어야 하는 region 23·146은 sector_count=5 → 0..4 키 허용 → 4(0-based) 키 보존 OK.

#### FR-14 — 운영 도구(operation-bom) 영향 범위 — 본 페이즈 제외
- **상세 동작**: 운영 도구 `operation-bom`은 별개 프로젝트 디렉토리이며 본 Flutter 저장소(`band-of-mercenaries`)와 분리됨. 본 명세는 Flutter 코드·Supabase SQL만 다루고, operation-bom 측 region 편집 폼·`region_sectors` CRUD 페이지·`data_versions` 신규 항목은 별개 PR로 처리.
- **조건**: 본 명세에서 단순 메모로만 기록. 실제 변경 사항 없음.
- **검증**: 본 PR에 operation-bom 변경 없음.

### 2.2 데이터 요구사항

**Supabase 테이블 변경:**
- `regions`: 신규 컬럼 `sector_count INT NOT NULL DEFAULT 4 CHECK (sector_count BETWEEN 1 AND 6)`. UPDATE 4행 (region 1, 23, 127, 146 → 5).
- `region_sectors`: 신규 테이블 (FR-2 컬럼 정의). 데이터 INSERT 0건 (Q1=D 결정 — 후속 페이즈 위임).
- `region_discoveries`: UPDATE 최대 3행 (FR-12).
- `chain_quests`: 변경 없음 (FR-11 ASSERT만).
- `data_versions`: `region_sectors` 신규 항목 추가 (`INSERT INTO data_versions (table_name, version, updated_at) VALUES ('region_sectors', 1, NOW())`). 기존 `regions`, `region_discoveries` 항목은 `version = version + 1` UPDATE.

**Hive 박스 변경:**
- 박스 스키마 변경 **없음** (RegionState typeId 8 그대로, sectorChanges Map<String,String> 그대로).
- `settings` 박스에 신규 키 `region_sector_count_v1`(SettingsKeys 상수) 추가 — RegionMigrationService 멱등성 플래그용.

**신규 정적 데이터 모델:**
- `RegionSector` (Freezed, snake_case @JsonKey).

**신규 enum:**
- 별도 enum 생성하지 않음. sector_type은 String 그대로 처리(기존 transform_type 패턴 일관). 향후 안전성 강화가 필요하면 별도 페이즈에서 enum 도입.

**밸런스 수치:**
- 본 명세 단독으로는 게임 밸런스 수치 변경 없음. region별 sector_count는 기획서 1.3절 분포표 그대로(36개×4 + 4개×5 = 164행 미래 데이터 기준).

### 2.3 UI 요구사항

- **화면 진입 조건**: MovementScreen 진입 시(앱 부팅 후 이동 탭 또는 다른 탭에서 이동 탭으로 전환). 본 명세는 신규 화면을 추가하지 않음.
- **위젯 계층 변경**: 기존 그대로 — `Wrap > GestureDetector > _SectorTile`. List.generate의 인자(고정 10 → 동적 sectorCount)만 변경.
- **상태 변수**: `_MovementScreenState._selectedRegion`, `_MovementScreenState._selectedSector` 그대로. 다른 region 선택 시 `_selectedSector` clamp 또는 1 리셋 추가 (FR-5).
- **화면 전환**: 변경 없음. 상태 기반 렌더링 유지.
- **연출/애니메이션**: 변경 없음.
- **시각 마커**:
  - 더스트빌(region 3 sector 1, village) → 1번 타일에 🏘️ + transformVillage 색상 테두리.
  - 폐광(region 3 sector 2, dungeon) → 2번 타일에 ⛏️ + sectorDungeon(0xFFB71C1C) 테두리.
  - 마른 초원 / 먼지로 덮인 길(region 3 sector 3·4, field) → 🌾 + sectorField(0xFF558B2F) 테두리.
- **시각 정책**: dungeon/field는 MovementScreen 그리드 한정. LayerSidebar 우선순위 8단계는 그대로 보존(`sectorType` 케이스 분기는 village/ruins/hidden 3종만 처리하여 dungeon/field는 사이드바에서 미반영). QuestCardBadges도 동일.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/region.dart` | `sectorCount` 필드 추가 (`@JsonKey('sector_count')`, `@Default(4)`) | FR-1 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `RegionSector` import + `regionSectors` 필드 추가 + builder 갱신 | FR-3 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 `'region_sectors'` 추가 (regions 다음) | FR-3 |
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | `@Deprecated sectorCount` 라인 삭제 | FR-4 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | `List.generate(10, ...)` → `List.generate(targetRegion.sectorCount, ...)`. region 변경 시 sector clamp. `_SectorTile._transformColor`/`_transformIcon` dungeon/field 분기 추가. sector_type 우선순위(변형 > regionSectors > 없음) 적용 | FR-4·5·8·9 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `sectorDungeon`/`sectorField` 색상 추가 | FR-8 |
| `band_of_mercenaries/lib/core/data/region_migration_service.dart` | `region_sector_count_v1` 플래그 + sectorChanges 키 정리 단계 추가 | FR-13 |
| `band_of_mercenaries/lib/core/data/settings_keys.dart` | `regionSectorCountV1` 상수 추가 | FR-13 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | 라인 17 주석 보강 (인덱싱 정책) | FR-10 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 라인 173·262·395 주석 보강 (인덱싱 정책) | FR-10 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region_sector.dart` | `RegionSector` Freezed 모델 (FR-3) |
| `band_of_mercenaries/lib/core/data/region_sector_fallback.dart` | 더스트플레인 4섹터 fallback 상수 + `lookupSector()` 헬퍼 (FR-6·7) |
| `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_2_region_sectors.sql` | regions.sector_count 컬럼 + region_sectors 테이블 + 4행 UPDATE + region_discoveries 재매핑 + ASSERT + data_versions (FR-1·2·11·12) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region.dart` | freezed 모델 변경 (sectorCount 필드 추가) → `region.freezed.dart`, `region.g.dart` 재생성 |
| `band_of_mercenaries/lib/core/models/region_sector.dart` | freezed 신규 모델 → `region_sector.freezed.dart`, `region_sector.g.dart` 신규 생성 |

명령어: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

### 3.4 관련 시스템

- **이동 시스템(MovementScreen)**: 섹터 그리드 동적 렌더링, sector_type 시각 마커 도입.
- **정적 데이터 동기화(SyncService/DataLoader/StaticGameData)**: 신규 테이블 1종 + 기존 모델 1종 확장. 첫 실행 시 27개 테이블 다운로드.
- **지역 변형(M3 transform)**: `region_state_model.sectorChanges` Map 그대로 작동. region 23·146의 hidden 변형 보존. `RegionStateRepository.applyTransform` 동작 변경 없음.
- **연계 퀘스트(M3 chain)**: `chain_quests.target_sector_id` 검증 ASSERT만 도입. 코드 변경 없음.
- **퀘스트 생성(QuestGenerator)**: sectorChanges key(0-based) 처리 그대로. region_sectors의 sector_type 정보는 본 페이즈에서 quest 풀에 매칭되지 않음(페이즈 4 #3에 위임).
- **운영 도구(operation-bom)**: 별도 PR — 본 명세 영향 없음 (FR-14).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Freezed + JsonKey snake_case 패턴**: `band_of_mercenaries/lib/core/models/region.dart` (기존 7필드 모두 snake_case 명시). `RegionSector` 신규 모델도 동일 컨벤션 적용.
- **StaticGameData 신규 필드 추가 패턴**: M3 추가분(chainQuests, questNarratives, travelChoiceEvents 등) 5개 항목 patch 참조. `staticDataProvider` 빌더 한 라인 추가, 생성자 `required` 파라미터 한 줄 추가, 클래스 필드 한 줄 추가 — 3곳 모두 갱신 필요.
- **SyncService.allTables 추가 패턴**: 라인 18~45 — 위치는 의미 있는 그룹(M2a/M2b/M3 코멘트 표기 그대로 따름). M4 페이즈 4 #2 코멘트 추가.
- **fallback 상수 패턴**: 본 프로젝트에 동일 패턴 선례 없음 — Hive 박스 자가치유(`SyncService` 라인 71~77 빈 캐시 재다운로드)와 유사한 "데이터 부재 시 코드 fallback" 전략. region_sector_fallback.dart는 단순 const List<RegionSector>로 작성.
- **`@Deprecated` 상수 제거**: 별도 선례 없음. 단순 라인 삭제 + grep 확인.
- **Supabase 마이그레이션 파일 패턴**: `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql` 참조. 단일 트랜잭션(BEGIN/COMMIT), 마지막에 `data_versions` UPDATE/INSERT.
- **RegionMigrationService 멱등성 플래그 패턴**: `region_migration_service.dart` 라인 17~20 그대로. `_flagKey` 상수 + `if (settings.get(_flagKey) == true) return;` 가드.

### 4.2 주의사항

- **build_runner 충돌**: Region 모델 변경 시 freezed 재생성 필요. `--delete-conflicting-outputs` 플래그 필수.
- **첫 실행 vs 재실행 동기화**: `SyncService.sync()`의 첫 실행 분기(라인 59~63)는 27개 테이블 모두 다운로드. 재실행은 `data_versions` 변경분만. region_sectors는 신규 추가이므로 기존 사용자도 재실행 시 자동 다운로드(version=1 초기값).
- **빈 region_sectors 캐시 자가치유**: `DataLoader.isCacheEmpty('region_sectors')`가 `[]`를 빈 캐시로 판정 → 매번 재다운로드 시도. 현재 자가치유 로직(SyncService 라인 71~77)이 모든 빈 테이블에 적용되므로 region_sectors 시드가 0건이면 매 sync 시도마다 GET 요청 1건 발생. 후속 페이즈에서 시드 데이터가 들어오면 자연스럽게 해소됨. 본 페이즈에서 별도 처리하지 않음.
- **fallback 우선순위**: `lookupSector(regionId, sectorIndex)`가 staticData → fallback → null 순서 — staticData가 region_sectors 시드를 보유한 후에는 fallback이 자동 비활성화. 시드와 fallback 데이터가 공존하면 staticData가 우선(fallback은 보조).
- **region 변경 시 sector clamp**: `_selectedSector`가 새 region의 sectorCount 초과인 경우 사용자 명시적 액션 없이 자동 보정. 현재 region 선택 핸들러 코드는 별도로 _selectedSector를 리셋하지 않으므로, region 변경 onTap 핸들러 또는 build() 진입점에서 `_selectedSector = _selectedSector > targetRegion.sectorCount ? 1 : _selectedSector` 처리.
- **regionStates Hive 키 정리는 RegionMigrationService 1회 실행 후 영구**: 사용자가 페이즈 4 #1을 거친 후 페이즈 4 #2 마이그레이션을 받으면 별도 플래그(region_sector_count_v1)로 1회 실행. 두 플래그가 합쳐지지 않도록 분리.
- **CLAUDE.md 코멘트 정책**: 코드 코멘트는 WHY 중심. 인덱싱 베이스(0-based vs 1-based) 주석은 "WHY"에 해당하므로 작성 정당. 단순 WHAT 주석은 회피.

### 4.3 엣지 케이스

- **시드 미배포 + region 3 외 region 진입**: sectorCount는 동적이지만 sector 이름·sector_type 정보 없음. 1·2·3·4 번호만 표시. lookupSector → null → 시각 마커 미표시. (Q1=D 의도된 동작.)
- **시드 미배포 + 더스트플레인 진입**: fallback 4섹터 데이터 사용. village/dungeon/field 아이콘 정상 노출.
- **시드 일부 배포(예: region 3만)**: staticData.regionSectors의 region 3 데이터가 fallback보다 우선 사용. 다른 region은 lookupSector → null.
- **region_sectors 데이터와 fallback 충돌**: 시드 데이터의 sector_index·sector_type이 fallback과 다르면 staticData 우선. fallback은 보조.
- **regionStates.sectorChanges 키가 1-based로 저장된 가상의 케이스**: M3 ApplyTransform이 0-based로만 저장하므로 발생 불가. 그러나 운영 도구가 잘못 입력한 경우 → FR-13 sectorChanges 키 정리에서 sectorCount 초과 키만 제거(1..sectorCount는 0-based 한도(sectorCount-1) 초과이므로 함께 정리됨). 추가 검증 불필요.
- **region 200(T9 신규) 시드 부재**: M9 이연 region이며 게임플레이 진입 불가. fallback 미제공. 정적 분석에서 문제없음.

### 4.4 구현 힌트

- **진입점**: 본 명세는 데이터 모델·동기화·렌더링의 인프라 작업. 호출이 시작되는 진입점은 다음 3곳:
  1. `staticDataProvider`(앱 부팅 시 FutureProvider 초기 로드) → `regionSectors` 필드를 통해 lookup.
  2. `MovementScreen.build()` → `targetRegion.sectorCount` + `lookupSector()` 사용.
  3. `RegionMigrationService.migrate(staticData)`(앱 부팅 시 main.dart에서 1회) → sectorChanges 키 정리.
- **데이터 흐름**:
  1. Supabase `regions.sector_count` + `region_sectors` 테이블 → SyncService가 다운로드 → 로컬 JSON 캐시 → DataLoader → StaticGameData → MovementScreen.
  2. 시드 부재 시 → StaticGameData.regionSectors가 빈 List → lookupSector가 region 3에 한해 fallback 상수 반환.
  3. region_sectors lookup 결과 → `_SectorTile`이 sectorChanges(변형 우선) 또는 lookup(데이터 또는 fallback)을 통해 transformType String 결정 → `_transformColor`/`_transformIcon` 분기.
- **참조 구현**:
  - `core/models/region.dart` — Freezed snake_case 패턴.
  - `core/providers/static_data_provider.dart:32-122` — StaticGameData 필드 + builder 패턴.
  - `core/data/sync_service.dart:18-45` — allTables 목록 + 신규 테이블 추가 위치.
  - `features/movement/view/movement_screen.dart:225-262` — 섹터 Wrap 렌더링.
  - `features/movement/view/movement_screen.dart:356-449` — `_SectorTile` 위젯 (transformType 처리).
  - `core/data/region_migration_service.dart:11-82` — 멱등성 플래그 + 박스 정리 패턴.
  - `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_1_region_migration.sql` — 단일 트랜잭션 마이그레이션 + data_versions 갱신.
- **확장 지점**:
  - 향후 sector_type enum 도입 → `RegionSector.sectorType String` → `enum SectorType { village, ruins, hidden, dungeon, field }`로 마이그레이션 (별도 페이즈).
  - 0-based↔1-based 변환 헬퍼(`SectorIndex._to0Based` 등) 도입 — 페이즈 4 #4 또는 페이즈 5 (현 페이즈는 보류).
  - quest_pools.sector_type='dungeon'/'field' 신규 풀 추가 → 페이즈 4 #3에 위임 (Q5=B).

---

## 5. 기획 확인 사항

- [Q-1] **region_sectors 데이터 시드 범위** — 본 페이즈 4 #2 명세에 어디까지 인라인할지? → **D 확정**: 컬럼·CRUD·렌더링 코드만 본 페이즈, 데이터 시드 약 164행은 별도 후속(페이즈 3 또는 페이즈 4 추가 작업). 더스트플레인 4섹터는 코드 fallback 상수로 인라인하여 게임 첫 실행 가능 보장.
- [Q-2] **기존 세이브 UserData.sector clamp 처리** — 페이즈 4 #1 후 sector가 region.sectorCount 초과인 케이스 처리? → **C 확정**: 페이즈 4 #1로 충분. 본 페이즈에서 별도 처리 없음. 단, FR-13에서 regionStates.sectorChanges의 sectorCount 초과 키 정리는 별도 멱등성 플래그(region_sector_count_v1)로 1회 실행.
- [Q-3] **GameConstants.sectorCount 상수 — 완전 제거 vs Deprecated 유지** → **A 확정**: 본 페이즈에서 완전 제거 + 잔여 hardcoded 10(movement_screen.dart:238) 동적 변환. 페이즈 4 #1에서 호출자 0개 확인됨.
- [Q-4] **MovementScreen 그리드 레이아웃** → **A 확정**: 단일 Wrap 레이아웃 유지. sector_count 4·5·6 모두 가로 정렬로 표시. 분기형 레이아웃은 페이즈 4 #4 마을 방문 UI 작업과 함께 시각화 가능.
- [Q-5] **dungeon/field quest_pools 풀 추가** → **B 확정**: 페이즈 4 #3 `quest_pools 컬럼 확장 + 고정 의뢰 노출`에 위임. 본 페이즈는 region_sectors 인프라에만 집중.
- [Q-6] **sectorType String vs enum** → **String 유지**: 기존 `transform_type` String 컨벤션 일관. enum 마이그레이션은 별도 페이즈에서 안전성 강화 시 도입.
- [Q-7] **region_sectors 시드 미배포 시 다른 region(3 외)의 시각 표시** → **번호만 표시(시각 마커 생략)**: lookupSector → null → `_SectorTile`이 transformType 없이 번호만 렌더. 시드 배포 후 자동 활성화.
- [Q-8] **0-based↔1-based 변환 헬퍼 도입 시점** → **본 페이즈 보류**: 기존 인라인 패턴(`(userData.sector - 1).toString()`)이 일관되게 작동 중이므로 헬퍼 미도입. 주석 명문화(FR-10)로 인덱싱 정책만 명확화.
