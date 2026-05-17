# M7 페이즈 4 #3: 이동 화면 + 거점 상세 UI — 생활권 표시 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md` (페이즈 1 #4 — 4절 이동 화면 UI 컨셉 + region_adjacency 도입 결정)
> - `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` (페이즈 1 #1 — 7리전 환경 키워드·역할 매핑)
>
> 데이터 산출물: `Docs/content-data/m7_region_metadata.sql` (페이즈 3 #1 — regions UPDATE 6행 + region_adjacency 신설 + 22행 INSERT, 본 spec 적용 시 마이그레이션)
>
> 동반 spec:
> - `Docs/spec/m7_p4_1_region_state_system.md` (페이즈 4 #1 — RegionState dangerScore/dangerLevel/unlockedFlags + DangerLevel enum + 한국어 라벨)
> - `Docs/spec/m7_p4_2_questgenerator_weights.md` (페이즈 4 #2 — 의뢰 풀 차별화, MovementScreen 카드 상태 표시와 정합)
>
> 작성일: 2026-05-17

## 1. 개요

M7 페이즈 1 #4 4절 컨셉을 입력으로 받아 **MovementScreen UI 확장** + **region_adjacency 정규화 테이블 도입** + **VillageVisitSection 인프라 단계 표시 진입점**을 명세한다. 본 spec은 기존 좌우 화살표 기반 region 네비게이션 구조를 보존하면서 (1) 7리전 생활권 빠른 점프 칩(`LivingsphereJumpBar`) 추가, (2) region 카드에 dangerLevel 4단계 색상·점·한국어 라벨, (3) unlockedFlags 미니 배지(최대 2 + overflow), (4) `region_adjacency` 그래프 기반 거리 계산 (UserData.calculateDistance fallback 보존), (5) Tier 2+ 광장 이정표 -10% 이동 시간 감소 효과(인프라 단계는 페이즈 4 #4 spec 의존)를 구현한다. VillageVisitSection에는 인프라 단계 배지 추가 위치만 명시하고 실제 단계 데이터는 페이즈 4 #4 spec(infrastructureTier 신규 필드 + provider)에 위임한다. region_adjacency 마이그레이션(22행 + region_name UPDATE 6행)은 본 spec 적용 시 일괄 수행.

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `region_adjacency` 신규 테이블 마이그레이션 (Supabase) + SyncService 등록

- `Docs/content-data/m7_region_metadata.sql` 그대로 적용. 단일 트랜잭션 처리:
  - (A) regions UPDATE 6행 — region 31/127/9/10/146/38 region_name 갱신 (도적길/변방 해안/외곽 숲/풍신 숲/회색 늪지/부서진 요새).
  - (B) region_adjacency 테이블 DDL — `id SERIAL PK / from_region INTEGER FK / to_region INTEGER FK / distance_units INTEGER CHECK >0 / created_at` + `UNIQUE(from_region,to_region)` + `CHECK(from_region <> to_region)` + index `idx_region_adjacency_from`.
  - (C) INSERT 22행 (양방향 11쌍): 3↔31(2) / 3↔127(2) / 3↔9(3) / 3↔10(3) / 3↔38(4) / 3↔146(4) / 31↔10(3) / 9↔146(2) / 127↔38(4) / 10↔50(4) / 38↔21(3).
  - (D) 검증 DO 블록 3종 — 양방향 정합 / 22행 / region 3 도달 가능성.
- 적용 후 `data_versions` 수동 갱신:
  ```sql
  UPDATE data_versions SET version = version + 1 WHERE table_name = 'regions';
  INSERT INTO data_versions (table_name, version) VALUES ('region_adjacency', 1)
    ON CONFLICT (table_name) DO UPDATE SET version = data_versions.version + 1;
  ```
- **SyncService.allTables** (`core/data/sync_service.dart` 라인 18~50)에 `'region_adjacency'`를 라인 50 이후 추가 (M7 페이즈 4 #3 32번 항목).
- operation-bom 편집 폼 추가는 본 spec 영역 외 (별도 PR).

#### FR-2: `RegionAdjacency` 신규 freezed 모델 + StaticGameData 확장

- **`RegionAdjacency` freezed 모델** (`core/models/region_adjacency.dart` 신규):
  ```dart
  @freezed
  class RegionAdjacency with _$RegionAdjacency {
    const factory RegionAdjacency({
      required int id,
      @JsonKey(name: 'from_region') required int fromRegion,
      @JsonKey(name: 'to_region') required int toRegion,
      @JsonKey(name: 'distance_units') required int distanceUnits,
    }) = _RegionAdjacency;

    factory RegionAdjacency.fromJson(Map<String, dynamic> json) =>
        _$RegionAdjacencyFromJson(json);
  }
  ```
- **StaticGameData 확장** (`core/providers/static_data_provider.dart` 라인 37~103):
  - 신규 필드 `final List<RegionAdjacency> regionAdjacencies` 추가 (constructor + JSON 로드).
  - 신규 derived field — `Map<int, Map<int, int>> regionAdjacencyMap` (lazy getter 또는 constructor 시점 1회 계산). 라인 109~142 패턴(loadFromCache) 답습:
    ```dart
    regionAdjacencies: dataLoader.loadFromCache('region_adjacency', RegionAdjacency.fromJson),
    ```
- `Map<int, Map<int, int>>`는 `from_region → to_region → distance_units` 인덱싱. O(1) 조회.
- build_runner 재실행 필요: `region_adjacency.freezed.dart`/`.g.dart`.

#### FR-3: `MovementDistanceCalculator` 신규 정적 헬퍼 + `UserData.calculateDistance` 호환성 보존

- **신규 파일** (`features/movement/domain/movement_distance_calculator.dart`):
  ```dart
  class MovementDistanceCalculator {
    /// region_adjacency 그래프 기반 거리 계산 (M7 페이즈 4 #3).
    ///
    /// - 동일 region 이동: |fromSector - toSector|
    /// - 인접 그래프 매칭: distance_units + |fromSector - toSector|
    /// - fallback (인접 미정의): UserData.calculateDistance (|region 차이| + |sector 차이|)
    static int calculate({
      required int fromRegion,
      required int fromSector,
      required int toRegion,
      required int toSector,
      required Map<int, Map<int, int>> adjacencyMap,
    }) {
      if (fromRegion == toRegion) {
        return (toSector - fromSector).abs();
      }
      final adjacencyDistance = adjacencyMap[fromRegion]?[toRegion];
      if (adjacencyDistance != null) {
        return adjacencyDistance + (toSector - fromSector).abs();
      }
      // fallback — region_adjacency 미정의 (M7 외 33리전 간 이동)
      return UserData.calculateDistance(fromRegion, fromSector, toRegion, toSector);
    }
  }
  ```
- **`UserData.calculateDistance` 정적 메서드 유지** (라인 132~135) — 외부 호출자 깨짐 회피 + fallback 경로로 보존.
- **`MovementScreen` 라인 93~95 변경**:
  ```dart
  final distance = MovementDistanceCalculator.calculate(
    fromRegion: userData.region,
    fromSector: userData.sector,
    toRegion: _selectedRegion,
    toSector: effectiveSelectedSector,
    adjacencyMap: data.regionAdjacencyMap,
  );
  ```
- **`MovementService` / `movement_provider.dart`의 다른 거리 호출 지점**도 모두 동일 패턴 변경 (탐색 보고서 라인 104~106).

#### FR-4: 광장 이정표 -10% 이동 시간 감소 (페이즈 4 #4 인프라 단계 의존)

- **적용 위치**: `movement_screen.dart` 라인 97~104 (travelReduction 계산 + moveTime 적용) + `movement_provider.dart` 동일 로직.
- **로직** (movement_screen.dart 라인 104 직전 추가):
  ```dart
  // M7 페이즈 4 #3 — 광장 이정표 -10% 이동 시간 감소 (페이즈 4 #4 인프라 Tier 2+ 의존)
  final infraTier = ref.watch(settlementInfrastructureTierProvider(GameConstants.startingRegionId));
  if (infraTier >= 2 && (userData.region == GameConstants.startingRegionId || _selectedRegion == GameConstants.startingRegionId)) {
    travelReduction = 1.0 - ((1.0 - travelReduction) * 0.9); // 곱셈 합산
  }
  ```
- **곱셈 합산** (페이즈 1 #4 6절): 이동수단 Lv25(-40%) + 광장 이정표(-10%) = (1-0.4)×(1-0.1) = 0.54 → 46% 감소.
- **인프라 단계 provider는 페이즈 4 #4 spec 영역**: `settlementInfrastructureTierProvider` (family<int, regionId>)는 페이즈 4 #4에서 정의. **본 spec 미존재 시 기본 0 반환 stub** — 페이즈 4 #4 implement 시 자동 활성.
- **GameConstants.startingRegionId**는 기존 상수(region 3). 페이즈 1 #4 4.4절 패턴 답습.

#### FR-5: `LivingsphereJumpBar` 신규 위젯 — 7리전 빠른 점프 칩

- **위치**: `MovementScreen` 라인 244 (region selector CardContainer) 직후, 라인 245 SizedBox(14) 뒤.
- **표시 조건**: `userData.region == 3` 또는 region_adjacency에 from_region=userData.region 항목 존재 (M7 핵심 7리전 진입 시에만 노출).
- **신규 위젯** (`features/movement/view/livingsphere_jump_bar.dart`):
  ```dart
  class LivingsphereJumpBar extends ConsumerWidget {
    final ValueChanged<int> onJump;
    final int currentRegion;
    final int selectedRegion;
    // build → Row(scrollable) → 7개 RegionJumpChip
  }
  ```
- 7리전 ID 상수: `static const List<int> m7LivingsphereRegions = [3, 31, 127, 9, 10, 146, 38];` (위치 `core/constants/m7_constants.dart` 신규 또는 GameConstants 확장).
- **칩 시각** (각 region 1개):
  - 라벨: `region.regionName` (페이즈 3 #1 갱신된 이름)
  - 거리: `MovementDistanceCalculator.calculate(...) ~ N분` 부제
  - dangerLevel 점: 4단계 색상 (FR-7 참조) `●`
  - 잠금 표시: `ReputationService.isRegionAccessible == false` 시 회색 + 자물쇠 아이콘
  - 현재 region: 굵은 테두리
  - 선택된 region: AppTheme.primary 배경
- **상호작용**: onTap → `onJump(regionId)` → `MovementScreen._selectedRegion` 변경 (setState).
- **레이아웃**: 가로 스크롤 가능 (Row + SingleChildScrollView horizontal), 칩 너비 자동 (Wrap content).

#### FR-6: `RegionStatusBadgeRow` 신규 위젯 — region 카드 dangerLevel + unlockedFlags 미니 배지

- **위치**: `MovementScreen` 라인 198 (target region name `${targetRegion.regionName} · Tier ${targetRegion.regionTier}`) 직후, 라인 200 잠금 분기 직전.
- **신규 위젯** (`features/movement/view/region_status_badge_row.dart`):
  ```dart
  class RegionStatusBadgeRow extends ConsumerWidget {
    final int regionId;
    // build → Row → [DangerLevelBadge, ...UnlockedFlagBadges(max 2), OverflowBadge(N>2)]
  }
  ```
- **DangerLevelBadge** 자식 위젯:
  - 색상 점 4개 (●●●●) — 현재 단계만 채움, 나머지는 outlined.
  - 한국어 라벨: 안정/평온/긴장/위협 (페이즈 4 #1 FR-2 enum.toString 매핑).
  - 색상은 FR-7 dangerLevelColor 사용.
  - 데이터 출처: `ref.watch(regionStateRepositoryProvider).getState(regionId)?.dangerLevel`. null fallback peaceful(2).
- **UnlockedFlagBadge** 자식 위젯:
  - `regionState.unlockedFlags`에서 region별 매핑된 flag description 조회 (페이즈 4 #1 FR-6 flag_description 매핑 8쌍 활용).
  - 라벨: ✓ 표시 + 짧은 텍스트 (예: "도적 소탕"). 페이즈 4 #1 매핑 표 description을 짧게 축약 — `region_state_flag_descriptions.dart`에 `Map<String, String> shortDescriptions` 추가:
    | flag | shortDescription |
    |------|----------------|
    | region_3_pyegwang_reopen_completed | 폐광 재개 |
    | region_31_bandits_cleared | 도적 소탕 |
    | region_31_shrine_quest_completed | 폐사당 완주 |
    | region_127_nomad_friendly | 유목민 친교 |
    | region_9_giant_beast_killed | 야수 처치 |
    | region_10_windrunner_chain_completed | 풍신 완주 |
    | region_146_mist_cleared | 안개 해소 |
    | region_38_ironbound_pact_completed | 서약 완수 |
  - 최대 2개 표시, 3개 이상이면 마지막에 `+N` overflow 배지.
- **상호작용**: 칩 자체는 정적(tap 없음). M7 MVP.

#### FR-7: `AppTheme.dangerLevelColor()` 헬퍼 + 색상 상수 4종

- **위치**: `core/theme/app_theme.dart` 라인 29 (tier5Bg) 직후.
- **추가 코드**:
  ```dart
  // dangerLevel 색상 (M7 페이즈 4 #1 + #3)
  static const Color dangerStable = Color(0xFF1565C0);    // 파랑 (안정)
  static const Color dangerPeaceful = Color(0xFF2E7D32);  // 초록 (평온)
  static const Color dangerTension = Color(0xFFFFA000);   // 주황 (긴장)
  static const Color dangerThreat = Color(0xFFC62828);    // 빨강 (위협)

  static Color dangerLevelColor(int level) => switch (level) {
    1 => dangerStable,
    2 => dangerPeaceful,
    3 => dangerTension,
    4 => dangerThreat,
    _ => dangerPeaceful, // fallback
  };

  static String dangerLevelLabel(int level) => switch (level) {
    1 => '안정',
    2 => '평온',
    3 => '긴장',
    4 => '위협',
    _ => '평온',
  };
  ```
- **페이즈 4 #1 RegionStateChangedDialog와 색상 공유** — 페이즈 4 #1 spec FR-5의 "{from 한국어} → {to 한국어}" 매핑은 `AppTheme.dangerLevelLabel()` 호출로 통합 (페이즈 4 #1 spec implement 시점에 통일).

#### FR-8: `VillageVisitSection` 인프라 단계 배지 추가 진입점

- **위치**: `features/settlement/view/village_visit_section.dart` 라인 67~85 (신뢰도 배지 Container) 직후.
- **추가 코드**:
  ```dart
  // M7 페이즈 4 #3 — 인프라 단계 배지 (페이즈 4 #4 infrastructureTier provider 의존)
  Consumer(
    builder: (context, ref, _) {
      final tier = ref.watch(settlementInfrastructureTierProvider(GameConstants.startingRegionId));
      if (tier <= 1) return const SizedBox.shrink(); // Tier 1은 기본값, 미표시
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.chainGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.chainGold.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            _infrastructureLabel(tier),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.chainGold),
          ),
        ),
      );
    },
  ),
  ```
- **한국어 라벨 매핑** (페이즈 1 #3 4단계):
  - Tier 1 → 미표시
  - Tier 2 → "거점 연결"
  - Tier 3 → "외래 좌판"
  - Tier 4 → "변방의 중심"
- `_infrastructureLabel(int tier)` 헬퍼는 VillageVisitSection 내부 정적 메서드.
- **provider stub**: `settlementInfrastructureTierProvider`가 페이즈 4 #4 implement 전에는 기본 1 반환 → 본 위젯 미표시 (자동 graceful degradation).

#### FR-9: region 카드 환경 아이콘 추가 (페이즈 1 #4 4.2절 매핑)

- **위치**: `MovementScreen` 라인 198 region name 표시 부분.
- **현재**: `Text('${targetRegion.regionName} · Tier ${targetRegion.regionTier}', ...)` (라인 198~199).
- **변경**:
  ```dart
  Text(
    '${_environmentIcon(targetRegion.environmentTags)} ${targetRegion.regionName} · Tier ${targetRegion.regionTier}',
    style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
  ),
  ```
- **`_environmentIcon(List<String> tags)` 헬퍼** (MovementScreen 내부 정적 메서드 또는 별도 utility):
  ```dart
  static String _environmentIcon(List<String> tags) {
    if (tags.contains('mountain')) return '🏔️';
    if (tags.contains('coast')) return '🌊';
    if (tags.contains('forest')) return '🌳';
    if (tags.contains('swamp')) return '🌫️';
    if (tags.contains('ruins')) return '🏛️';
    if (tags.contains('plains')) return '🌾';
    return '🌍'; // fallback
  }
  ```
- 페이즈 1 #4 4.2절 매핑 정합 (mountain/plains/coast/forest/swamp/ruins).
- **labor/survey 등 미정의 환경 태그는 fallback 🌍**.
- 본 헬퍼는 `LivingsphereJumpBar` 칩 라벨에도 동일 적용.

#### FR-10: 잠금 표시 시각 강화 (기존 패턴 보존)

- 현재 `MovementScreen` 라인 200~217 잠금 배지(`'잠김'`)는 보존.
- **변경**: 잠금 사유를 명시 — `'명성 ${requiredRank.requiredReputation} 부족'` 또는 `'잠김 (랭크 ${requiredRank.gradeKr} 필요)'`.
- **신규 텍스트** (라인 208~215 Text 교체):
  ```dart
  Text(
    '🔒 ${requiredRank.gradeKr} 랭크 필요',
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.tier5),
  ),
  ```
- requiredRank는 기존 라인 109~112에서 이미 조회됨.

#### FR-11: DataLoader / SyncService — region_adjacency 캐시 로드 통합

- **DataLoader 변경 없음** — `loadFromCache<T>` 범용 메서드(라인 30~38)가 자동 처리.
- **SyncService.allTables**에 'region_adjacency' 추가 (FR-1에서 명세).
- **StaticGameData constructor**에서 `regionAdjacencies: dataLoader.loadFromCache('region_adjacency', RegionAdjacency.fromJson)` 추가 (라인 118~119 패턴 답습).

#### FR-12: gameTickProvider · MovementState 호환성 — 변경 없음

- `gameTickProvider`는 MovementScreen에서 `ref.watch` (라인 59) 유지.
- `MovementState` / `_checkArrival()` 흐름 변경 없음 — 거리 계산만 `MovementDistanceCalculator`로 위임.
- `_completeMovement()` trailing은 페이즈 4 #1 FR-4d decay 호출 위치와 무관 (decay는 gameTickProvider 내부 60틱 카운터로 별도 처리).

### 2.2 데이터 요구사항

#### Supabase 정적 데이터

- `regions` 테이블 UPDATE 6행 (region_name 갱신 — 페이즈 3 #1 SQL).
- `region_adjacency` 테이블 신규 + 22행 INSERT + 인덱스 + CHECK 제약 2종.
- `data_versions` 2개 항목 갱신 (regions version+1, region_adjacency 신규 추가).

#### Flutter 모델 / Provider

- **`RegionAdjacency`** freezed 모델 (신규) — `core/models/region_adjacency.dart`.
- **`StaticGameData`** — `regionAdjacencies: List<RegionAdjacency>` 신규 필드 + `regionAdjacencyMap: Map<int, Map<int, int>>` derived.
- **`settlementInfrastructureTierProvider`** — 페이즈 4 #4 spec 영역. 본 spec은 호출만, 정의 없음. **stub 반환값 1 가정**.
- **`regionStateRepositoryProvider`** — 페이즈 4 #1 spec 영역. 본 spec은 `getState(regionId)?.dangerLevel`/`unlockedFlags` 조회만.

#### 신규 enum / 클래스 / 위젯

- `MovementDistanceCalculator` 정적 헬퍼 클래스.
- `LivingsphereJumpBar` ConsumerWidget.
- `RegionStatusBadgeRow` ConsumerWidget.
- `m7LivingsphereRegions` const List<int> (GameConstants 또는 m7_constants.dart).
- `Map<String, String> shortDescriptions` (region_state_flag_descriptions.dart 확장 — 페이즈 4 #1 spec FR-6과 통합).
- `AppTheme.dangerLevelColor(int)` / `dangerLevelLabel(int)` 헬퍼.

#### 밸런스 수치 (페이즈 1 #4 4·6절)

- 광장 이정표 -10% (Tier 2+).
- region_adjacency distance_units 1~5 범위 (실제 22행은 2~4).
- 1칸 = 30초 (UserData.calculateMoveTime 기존 상수, 변경 없음).
- 7리전 모두 region 3과 직접 인접 보장 (페이즈 1 #4 4.4절).

### 2.3 UI 요구사항

#### MovementScreen 변경 영역

- **화면 진입 조건**: 기존과 동일 (하단 BottomNav "이동" 탭 선택).
- **위젯 계층 (변경 영역)**:
  ```
  Column (라인 114)
  ├─ TopBar (변경 없음, 라인 117~131)
  └─ Expanded > SingleChildScrollView > Column (라인 133~)
      ├─ MovingIndicator (변경 없음, 라인 139~152)
      ├─ CurrentLocation Text (변경 없음, 라인 154~159)
      ├─ Region Selector CardContainer (라인 163~244)
      │   └─ Column
      │       ├─ Title (변경 없음)
      │       └─ Row [◀] [SizedBox(width:130) Column [지역N / regionName+envIcon / DangerLevelBadge / UnlockedFlagBadges / 잠금]] [▶]
      │                                                 (FR-9)        (FR-6)           (FR-6)              (FR-10)
      ├─ ★ NEW: LivingsphereJumpBar (FR-5, 라인 245 직전 추가)
      ├─ Sector Selector (변경 없음, 라인 248~285)
      ├─ VillageVisitSection (변경 — FR-8 인프라 배지 추가)
      └─ 이하 변경 없음
  ```
- **상태 변수**: `_selectedRegion`/`_selectedSector`/`_selectedFacility` (변경 없음).
- **화면 전환**: 상태 기반 렌더링 (Navigator.push 미사용) — 기존 패턴 유지.
- **CLAUDE.md 제약**: 상태 기반 렌더링 + ConstrainedBox(maxWidth: 430) 미적용 (기존 MovementScreen에 없음 — 본 spec도 추가하지 않음).
- **연출**: 기본 fade-in (Material Card). 별도 애니메이션 없음.

#### LivingsphereJumpBar 위젯 시각

- **레이아웃**: `Container(height: 56)` > `SingleChildScrollView(scrollDirection: horizontal)` > `Row` > 7개 `RegionJumpChip` (간격 8).
- **각 칩**: `InkWell` > `Container(padding: 8, border: 1px)` > `Column` > [환경아이콘 + 이름 / 거리 ~Nm / dangerLevel ● / 잠금 아이콘(잠긴 경우)].
- **선택 상태**: 현재 region 굵은 테두리(2px AppTheme.primary), 선택 region 채움 배경.
- **빈 상태**: M7 외 region에 있을 때 위젯 자체 미렌더링 (`m7LivingsphereRegions.contains(userData.region)` 분기).

#### RegionStatusBadgeRow 위젯 시각

- **레이아웃**: `Row(mainAxisSize: min)` > [DangerLevelBadge, SizedBox(6), UnlockedFlagBadge×N, SizedBox(6), OverflowBadge].
- **DangerLevelBadge**: `Container(padding: hxv 6x2, color: dangerColor.withAlpha 0.15, border: dangerColor 1px)` > `Text('● {라벨}', fontSize: 11, color: dangerColor)`.
- **UnlockedFlagBadge**: `Container(padding: hxv 5x1, color: surfaceAlt, border: chainGold 1px)` > `Text('✓ {shortDesc}', fontSize: 10, color: chainGold)`.
- **OverflowBadge**: `Text('+${flags.length - 2}', fontSize: 10, color: textHint)`.
- **빈 상태** (RegionState null 또는 unlockedFlags 빈 배열): DangerLevelBadge만 표시 (기본값 peaceful).

#### VillageVisitSection 인프라 배지 (FR-8 영역)

- **위치**: 신뢰도 배지(라인 67~85) 같은 Row 내부 오른쪽 또는 직하 Padding(top: 4).
- **시각**: chainGold 색상 톤(0xFFD4AF37, 신뢰도 배지의 settlementAccent와 시각 분리) + 한국어 라벨.
- **Tier 1 미표시**: tier <= 1 인 경우 SizedBox.shrink (페이즈 4 #4 implement 전 stub 0 또는 1 반환 시 자동 숨김).

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | 라인 93~95 distance 계산 MovementDistanceCalculator 위임 / 라인 97~104 광장 이정표 -10% 추가 / 라인 198 환경 아이콘 / 라인 200 RegionStatusBadgeRow / 라인 208 잠금 텍스트 강화 / 라인 245 LivingsphereJumpBar 추가 | FR-3, FR-4, FR-5, FR-6, FR-9, FR-10 |
| `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart` | 라인 104·167 distance 계산 MovementDistanceCalculator 위임 + 광장 이정표 분기 | FR-3, FR-4 |
| `band_of_mercenaries/lib/features/settlement/view/village_visit_section.dart` | 라인 67~85 신뢰도 배지 다음 인프라 단계 배지 Consumer 추가 + `_infrastructureLabel` 정적 헬퍼 | FR-8 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | 라인 29 직후 dangerLevel 색상 4종 + dangerLevelColor/dangerLevelLabel 헬퍼 | FR-7 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | 라인 50 이후 'region_adjacency' 추가 | FR-1, FR-11 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | StaticGameData 클래스 라인 37~103에 regionAdjacencies/regionAdjacencyMap 추가 + 라인 118 loadFromCache 호출 | FR-2, FR-11 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_flag_descriptions.dart` (페이즈 4 #1 신규) | `shortDescriptions` Map<String, String> 8쌍 추가 | FR-6 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region_adjacency.dart` | RegionAdjacency freezed 모델 (FR-2) |
| `band_of_mercenaries/lib/features/movement/domain/movement_distance_calculator.dart` | 인접 그래프 거리 계산 정적 헬퍼 (FR-3) |
| `band_of_mercenaries/lib/features/movement/view/livingsphere_jump_bar.dart` | 7리전 빠른 점프 칩 위젯 (FR-5) |
| `band_of_mercenaries/lib/features/movement/view/region_status_badge_row.dart` | dangerLevel + unlockedFlags 배지 위젯 (FR-6) |
| `band_of_mercenaries/lib/core/constants/m7_constants.dart` (선택) | `m7LivingsphereRegions` 등 M7 상수 — 또는 GameConstants 확장 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region_adjacency.freezed.dart` | RegionAdjacency freezed 신규 |
| `band_of_mercenaries/lib/core/models/region_adjacency.g.dart` | RegionAdjacency fromJson |

`dart run build_runner build --delete-conflicting-outputs` 1회 실행 필요 (페이즈 4 #1·#2·#4 spec과 통합 implement 시 1회로 처리).

### 3.4 관련 시스템

- **페이즈 4 #1 spec (RegionState 시스템)**: 본 spec의 직접 의존 — `regionStateRepositoryProvider.getState(regionId)?.dangerLevel` / `unlockedFlags` 조회. `DangerLevel` enum의 toCacheInt/fromCacheInt도 페이즈 4 #1에서 제공. **반드시 페이즈 4 #1과 함께 implement**.
- **페이즈 4 #2 spec (QuestGenerator 가중치)**: 영향 없음 (UI 표시만, 의뢰 발급 로직 무관). 단, 플레이어가 MovementScreen에서 region 카드를 보고 외출 결정 → QuestGenerator 가중치 적용 결과가 발급 의뢰에 반영되는 정합 흐름.
- **페이즈 4 #4 spec (인프라 단계 시스템)**: 본 spec은 `settlementInfrastructureTierProvider`만 호출. provider 정의·infrastructureTier HiveField·전이 로직은 페이즈 4 #4. **stub 반환 1 일 때 graceful degradation 보장** (인프라 배지 미표시, 광장 이정표 효과 미적용).
- **MovementScreen 기존 동작**: 좌우 화살표 네비게이션 + sector Wrap + VillageVisitSection 진입은 보존. 본 spec은 확장만.
- **MovementService / _checkArrival / _completeMovement**: 거리 계산 위임만, 흐름 변경 없음.
- **이동수단 시설 (transport)**: 곱셈 합산 정합. (1 - transport) × (1 - 0.1) = 광장 이정표 적용.
- **ReputationService.isRegionAccessible**: 변경 없음. 잠금 판정 그대로.
- **operation-bom**: region_adjacency 편집 폼 추가 권장 (별도 PR — from/to/distance 3 컬럼 단순 CRUD + 양방향 정합성 검증 도구).

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **freezed 모델**: `Region` (`core/models/region.dart`) / `RegionSector` 패턴. snake_case @JsonKey, fromJson factory.
- **DataLoader.loadFromCache**: `static_data_provider.dart:118~119` (`regions` / `region_sectors` 로드). RegionAdjacency도 동일 패턴.
- **SyncService.allTables**: 라인 18~50 — 31개 테이블 목록. 페이즈 4 #3은 32번째 (`region_adjacency`).
- **StaticGameData constructor**: 라인 37~103 — `final` 필드 + immutable. regionAdjacencyMap은 lazy getter 또는 constructor 시점 1회 계산.
- **MovementScreen 좌우 화살표 네비게이션**: 라인 173~239 — `_selectedRegion` setState. LivingsphereJumpBar의 onJump 콜백도 동일 setState 패턴.
- **_SectorTile 위젯**: 라인 395~492 — Stack + Container + 배지 표시. RegionStatusBadgeRow도 동일 시각 구조 답습.
- **AppTheme.tierColor()**: 라인 93~102 — switch case 색상 매핑. dangerLevelColor도 동일 패턴.
- **VillageVisitSection 신뢰도 배지**: 라인 67~85 — Container + decoration + Text. 인프라 배지도 동일 시각.
- **GameConstants.startingRegionId**: 기존 상수 (region 3). 광장 이정표 분기·인프라 배지 region 모두 동일.
- **`ConstructionService.getEffectValue`**: 라인 45~60 (탐색 보고서) — 시설 effect 반환. 광장 이정표는 시설 아닌 인프라 단계 기반이므로 별도 분기 (페이즈 4 #4 provider 호출).

### 4.2 주의사항

- **페이즈 4 #1과의 implement 순서**: 페이즈 4 #1 먼저 (RegionState dangerLevel/unlockedFlags + DangerLevel enum + flag_descriptions.dart) → 본 spec(#3) 활성. 순서 역전 시 컴파일 실패. **build_runner 통합 1회 실행 권장**.
- **페이즈 4 #4와의 implement 순서**: 페이즈 4 #4의 `settlementInfrastructureTierProvider` 정의 전에 본 spec implement 시 — Riverpod undefined provider 에러. 두 방안 중 택일:
  - (A) 페이즈 4 #4 spec implement 후 본 spec implement.
  - (B) 본 spec implement 시 임시 stub provider 생성 (`Provider.family<int, int>((ref, _) => 1)`) → 페이즈 4 #4 spec implement 시 교체.
  - **권장 (B)**: 4 spec 통합 implement 정책 정합. 통합 implement 시 페이즈 4 #4 정의가 stub을 자동 대체.
- **SyncService 신규 테이블 등록 후 첫 실행 동작**: data_versions에 region_adjacency 항목이 있어야 정상 다운로드. SQL 마이그레이션 시 INSERT INTO data_versions 필수 (FR-1 D).
- **`UserData.calculateDistance` 정적 메서드 유지**: 외부 호출자(혹시 있는 곳) 깨짐 회피. MovementDistanceCalculator가 fallback으로 호출. `static` 시그니처 그대로.
- **광장 이정표 곱셈 합산 식 검증**: `travelReduction = 1.0 - ((1.0 - transport) * 0.9)`. 예: transport 0.4 → 1 - 0.6×0.9 = 1 - 0.54 = 0.46. 이동수단 Lv25(-40%) + 광장 이정표(-10%) = 46% 감소 (페이즈 1 #4 6절 정합). 단순 가산(0.4+0.1=0.5)이 아닌 곱셈 합산 주의.
- **LivingsphereJumpBar 노출 조건**: `m7LivingsphereRegions.contains(userData.region)` — M7 핵심 7리전에 있을 때만. 그 외 region에서는 미표시(혼란 회피). 점프 칩에서 외곽 region(M7 외)으로 이동 후 재진입 시 자동 재표시.
- **칩 잠금 표시**: 명성 부족 region은 회색 + 자물쇠 + 점프 비활성 (onTap null 또는 toast). FR-5에 명시.
- **RegionStatusBadgeRow null safety**: `regionStateRepositoryProvider.getState(regionId)`가 null이면 dangerLevel=peaceful(2) fallback. unlockedFlags 빈 배열은 정상.
- **MovementScreen ConstrainedBox(maxWidth:430) 부재**: 기존 MovementScreen에 maxWidth 제약 없음. 본 spec도 추가하지 않음(현재 패턴 답습).
- **build_runner --delete-conflicting-outputs**: RegionAdjacency 신규 + 페이즈 4 #1·#2의 freezed 변경이 충돌할 수 있어 플래그 필수.
- **운영 도구 (operation-bom)**: region_adjacency 양방향 정합 자동 입력 도구 미구현 시 INSERT 시 양쪽 입력 누락 가능. 페이즈 3 #1 SQL 검증 DO 블록이 SQL 단에서 차단 — 안전.

### 4.3 엣지 케이스

- **현재 region이 region_adjacency에 미정의** (M7 외 33리전): `MovementDistanceCalculator.calculate`가 fallback (`UserData.calculateDistance`) 반환. 기존 동작 유지.
- **target region이 미정의**: 동일 fallback. M7 외 region 간 이동 영향 없음.
- **adjacencyMap 빈 상태** (sync 실패 또는 첫 실행): fallback이 자동 작동. M7 핵심 동작 손상 없음, 단 거리는 |ID 차이| 기준.
- **chain target region (50/21)** — region_adjacency에 등록됨 (10↔50, 38↔21). 기존 chain_windrunner_trail / chain_blade_of_border 정합.
- **LivingsphereJumpBar 자기 자신 칩 탭**: 현재 region과 동일하므로 setState 효과 없음(`_selectedRegion = userData.region`). 정상.
- **RegionState 미존재 region** (첫 진입): `getState` null → DangerLevelBadge 평온(peaceful) + UnlockedFlagBadge 빈 상태. 정상 graceful degradation.
- **unlockedFlags에 알 수 없는 flag**: `shortDescriptions[flag] == null` → 배지 미표시 (filter). M7 8 flag 외 미정의 flag silent skip.
- **인프라 단계 stub 1 반환**: tier <= 1 분기에서 인프라 배지 미표시 + 광장 이정표 효과 미적용. 페이즈 4 #4 implement 전 graceful degradation.
- **VillageVisitSection은 region 3 sector 1(village) 전용**: 다른 region 또는 sector에서는 진입 자체 없음 (movement_screen.dart 라인 290~294 분기). 본 spec FR-8 인프라 배지도 region 3 한정.
- **이동 중(`userData.isMoving == true`)**: 좌우 화살표 비활성(라인 174 onPressed null), LivingsphereJumpBar도 동일 비활성 처리 (`isMoving ? null : onTap` 분기).
- **dangerLevel 5단계 이상의 미래 확장**: switch case fallback peaceful(2) 보장. 페이즈 5+ enum 확장 시 본 spec 헬퍼만 갱신.
- **광장 이정표 효과가 두 번 적용되지 않도록**: `infraTier >= 2` 조건이 한 번만 통과. 중복 곱셈 회피.
- **운영 도구 region_adjacency 편집 시 양방향 누락**: SQL CHECK 제약과 검증 DO 블록이 차단. operation-bom 자동 보강 도구 권장 (별도 PR).

### 4.4 구현 힌트

- **진입점**:
  - UI: `MovementScreen.build()` 라인 67~388 (변경 영역 명시됨)
  - 거리 계산: `MovementDistanceCalculator.calculate` (신규)
  - 인접 그래프 로드: `DataLoader.loadFromCache('region_adjacency', RegionAdjacency.fromJson)`
  - dangerLevel/unlockedFlags 데이터: `regionStateRepositoryProvider.getState(regionId)` (페이즈 4 #1)
- **데이터 흐름**:
  1. 앱 시작 → SyncService → region_adjacency 다운로드 → DataLoader 캐시
  2. StaticGameData constructor → regionAdjacencies + regionAdjacencyMap 계산
  3. MovementScreen build → ref.watch(staticDataProvider) → adjacencyMap 추출
  4. distance 계산 → MovementDistanceCalculator → adjacencyMap 조회 또는 fallback
  5. moveTime 계산 → transport 시설 + 광장 이정표(infraTier>=2) 곱셈 합산
  6. LivingsphereJumpBar → m7LivingsphereRegions 순회 → RegionJumpChip 7개 렌더
  7. RegionStatusBadgeRow → regionStateRepositoryProvider.getState → DangerLevelBadge + UnlockedFlagBadges
- **참조 구현**:
  - `core/models/region.dart` — freezed 모델 단순 패턴
  - `core/providers/static_data_provider.dart:37~142` — StaticGameData + loadFromCache 패턴
  - `core/data/sync_service.dart:18~50` — allTables 등록
  - `features/movement/view/movement_screen.dart:395~492` — _SectorTile 위젯 시각 구조 (RegionStatusBadgeRow 답습)
  - `features/settlement/view/village_visit_section.dart:67~85` — 신뢰도 배지 시각 (인프라 배지 답습)
  - `core/theme/app_theme.dart:93~102` — tierColor 헬퍼 (dangerLevelColor 답습)
- **확장 지점**:
  - 추가 인접성: region_adjacency 테이블 INSERT — 자동 반영
  - dangerLevel 5단계: AppTheme.dangerLevelColor switch case 추가
  - 새 flag description: region_state_flag_descriptions.shortDescriptions Map 추가
  - 인프라 단계 5단계: VillageVisitSection._infrastructureLabel switch case 추가

## 5. 기획 확인 사항

- **[Q-1] MovementScreen 전면 재설계 (페이즈 1 #4 ASCII 와이어프레임의 리스트 그룹 방식) vs 좌우 화살표 패턴 보존 + 칩 추가** → 본 spec 채택: **좌우 화살표 보존 + LivingsphereJumpBar 추가**. 이유 — MovementService·gameTickProvider·_checkArrival 호환성 보존, M7 MVP 부담 최소화, 사용자 학습 곡선 회피. 페이즈 1 #4 컨셉은 칩 + 카드 시각 강화로 충족.
- **[Q-2] region_adjacency 매핑이 양방향이지만 distance가 다른 경우 (예: 산악 경로 한쪽 더 멈)** → 본 spec 채택: **양방향 동일 distance 강제**. SQL CHECK 제약 + 검증 DO 블록. 비대칭 거리는 M9+ 검토. 페이즈 3 #1 SQL 정합.
- **[Q-3] LivingsphereJumpBar 노출 조건** → 본 spec 채택: **M7 핵심 7리전에 있을 때만**(`m7LivingsphereRegions.contains(userData.region)`). M7 외 33리전 진입 시 미표시. 혼란 회피.
- **[Q-4] dangerLevel 색상 매핑** → 본 spec 채택: stable=파랑(0xFF1565C0) / peaceful=초록(0xFF2E7D32) / tension=주황(0xFFFFA000) / threat=빨강(0xFFC62828). 페이즈 4 #1 RegionStateChangedDialog와 공유.
- **[Q-5] unlockedFlags 미니 배지 최대 표시 개수** → 본 spec 채택: **2개 + overflow(+N)**. M7 종료 시점 unlockedFlags 8/8이지만 region당 최대 1~2개이므로 overflow는 region 31(bandits + shrine), region 9(beast) 등 일부에만 적용. UI 가독성 확보.
- **[Q-6] 광장 이정표 효과의 인프라 단계 의존** → 본 spec 채택: **페이즈 4 #4 `settlementInfrastructureTierProvider` 의존, stub 1 반환 시 효과 미적용**. 페이즈 4 #4 implement 후 자동 활성. graceful degradation.
- **[Q-7] VillageVisitSection 인프라 단계 배지 표시 조건** → 본 spec 채택: **Tier 2+ 부터 표시** (Tier 1은 기본값, 미표시). 페이즈 1 #3 4단계 매핑 정합.
- **[Q-8] MovementScreen ConstrainedBox(maxWidth: 430) 추가 여부** → 본 spec 채택: **추가하지 않음** (기존 패턴 보존). CLAUDE.md 권장이지만 MovementScreen이 가로 sector Wrap을 사용하므로 좁히면 sector 표시 손상.
- **[Q-9] MovementDistanceCalculator vs UserData.calculateDistance 둘 다 유지 vs 통합** → 본 spec 채택: **둘 다 유지** (UserData는 fallback). 외부 호출자 깨짐 회피, MovementDistanceCalculator는 adjacencyMap 의존성 명시.
- **[Q-10] 환경 아이콘 매핑 (forest 2개 region — region 9 외곽 숲 / region 10 풍신 숲)** → 본 spec 채택: **동일 🌳 아이콘** (페이즈 1 #4 4.2절 정합). 차별화는 regionName으로 충분.
- **[Q-11] 잠금 텍스트 강화 (FR-10)** → 본 spec 채택: **`'🔒 {gradeKr} 랭크 필요'`** (예: "🔒 E 랭크 필요"). 사용자가 즉시 잠금 사유 파악 가능. requiredRank.gradeKr는 기존 Rank 모델 필드.
- **[Q-12] region_adjacency 운영 도구 양방향 정합 자동 보강** → 본 spec 영역 외 (별도 PR). operation-bom table-config.ts에 from/to/distance 3 컬럼만 단순 CRUD 추가 + SQL CHECK 제약이 안전 그물.
