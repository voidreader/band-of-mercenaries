# 세력 발견 시스템 개발 명세서

> 기획 문서: Docs/content-design/[content]20260415_faction_discovery_phase6.md
> 작성일: 2026-04-15

---

## 1. 개요

지역 조사 시스템(Phase 1)의 `region_discoveries` 파이프라인에 `faction_clue` discovery 타입을 추가하여, 조사 중 세력 단서를 발견하는 흐름을 구현한다. 단서는 Hive `factionStates` 박스에 저장되고, 신설되는 **정보 탭**의 세력 도감에 표시된다. 설정 탭은 홈 화면 상단 톱니바퀴 버튼으로 이전되며, 빈 자리에 향후 확장 가능한 정보 탭이 들어선다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 네비게이션 변경**
  - 상세 동작: 하단 탭 인덱스 5를 `⚙ 설정` → `📋 정보`로 교체. 설정 화면은 홈 화면 상단 AppBar 영역(우측 상단)에 `Icons.settings` 아이콘 버튼을 추가하여 상태 기반 렌더링으로 진입한다.
  - 조건: `BottomNavBar`, `app.dart._screens[5]`, `HomeScreen` 상단 영역 변경 포함.

- **[FR-2] factions 정적 데이터 로드**
  - 상세 동작: `SyncService` 동기화 테이블 목록에 `'factions'` 추가. `StaticGameData`에 `List<FactionData> factions` 필드 추가. `DataLoader`가 `factions` JSON 캐시를 읽어 `StaticGameData`에 주입한다.
  - 조건: Supabase `factions` 테이블 및 `data_versions` 행이 선행 생성되어 있어야 한다.

- **[FR-3] factionStates Hive 영속성**
  - 상세 동작: `FactionState`(typeId 9), `FactionClueRecord`(typeId 10) Hive 어댑터를 `HiveInitializer`에 등록하고, `factionStates` 박스를 오픈한다. `FactionStateRepository`를 통해 CRUD.
  - 조건: typeId 9, 10은 현재 미사용 확인됨.

- **[FR-4] faction_clue discovery 처리**
  - 상세 동작: `InvestigationNotifier._completeInvestigation()` 내 `newlyTriggered` 순회 루프에서 `d.discoveryType == 'faction_clue'` 분기를 추가한다. `d.discoveryData`에서 `faction_id`, `clue_level`, `clue_text`를 추출하고, `FactionStateRepository.processClue()`를 호출하여 저장한다. `FactionClueResult` 객체를 생성해 `InvestigationResult.factionClues`에 추가한다.
  - 조건: 동일 faction에 대해 이미 같은 clue_level이 발견된 경우(`processClue` 반환값 `false`), `InvestigationResult`에는 포함하되 활동 로그는 생략.
  - 기존 루프와의 관계: `investigation_notifier.dart` line 113~118의 일반 활동 로그 루프(`'발견: ${d.description}'`)에서 `d.discoveryType == 'faction_clue'`인 항목은 **제외**한다 (일반 발견 메시지와 faction_clue 전용 메시지가 중복 기록되지 않도록). faction_clue 전용 활동 로그는 `processClue` 반환값이 `true`(maxClueLevel 실제 갱신)일 때만 기록한다.
  - 활동 로그: `ActivityLogType.discoveryFound` 재사용. clue_level별 메시지 형식:
    - level 1: `"세력 단서 발견: {clue_text}"`
    - level 2: `"세력 발견: {factionName}의 정체를 파악했다"`
    - level 3: `"거점 발견: {factionName}의 전초기지 위치를 파악했다"`

- **[FR-5] 조사 완료 팝업 — faction_clue 인라인 표시**
  - 상세 동작: `InvestigationResultDialog`(현재 `investigation_widget.dart:357`)의 `_DialogContent`에서 `result.factionClues`가 비어있지 않으면 "✨ 새로운 단서 발견!" 섹션을 인라인 추가한다. `InvestigationResultDialog`를 `ConsumerWidget`으로 전환하고 (`build(context, ref)` 시그니처 사용), "도감에서 확인" 버튼을 `AlertDialog.actions`에 조건부 추가한다. 버튼 탭 시 다음 3단계를 순서대로 실행한다: (1) `Navigator.pop(context)`, (2) `currentTabProvider`를 5로 설정, (3) `factionCodexScrollTargetProvider`에 첫 번째 단서의 `factionId`를 설정하여 세력 도감 화면에서 해당 카드로 자동 스크롤. `factionCodexScrollTargetProvider`는 `StateProvider<String?>`으로 신규 생성하며, `FactionCodexScreen` 진입 후 스크롤 처리가 완료되면 null로 초기화한다.
  - 조건: `factionClues`가 비어있으면 기존 UI 동일 (기존 "확인" 버튼만).

- **[FR-6] 세력 도감 화면**
  - 상세 동작: `InfoScreen`(정보 탭 루트) → `FactionCodexScreen`(세력 도감) 구조. 도감에서 발견된 세력(`maxClueLevel >= 1`)을 `maxClueLevel` 내림차순으로 나열. 미발견 세력 표시 조건: `staticData.factions.length > discoveredFactionStates.length` (discoveredFactionStates = maxClueLevel >= 1인 FactionState 수)일 때만 `???` 행 1개 표시 (전체 세력 수 비공개). 각 세력 카드: 별 3개 진행도(`maxClueLevel` / 3) + 도감 카드에는 `description` 필드 표시 (maxClueLevel >= 2 도달 시 공개, 미달 시 `"???"`) (기획서 표의 "설명(philosophy)" 항목은 description 필드를 지칭하는 것으로 해석함). 발견 기록 로그(`clueRecords`) 시간순 나열.
  - 조건: `staticDataProvider`의 `factions` 리스트와 `factionStates` Hive 박스를 `factionListProvider`로 결합하여 렌더링. Navigator.push 미사용 — `InfoScreen` 내 `_selectedFactionId` 상태 변수 기반 전환.

- **[FR-7] 세력 상세 화면**
  - 상세 동작: 세력 카드 탭 → `FactionDetailScreen` 상태 기반 전환. 표시 내용:
    - 세력 이름: maxClueLevel >= 1이면 공개, 미달 시 `"???"`
    - `description`: maxClueLevel >= 2이면 공개, 미달 시 `"???"`
    - `philosophy` (세력 이념): maxClueLevel >= 2이면 공개, 미달 시 미표시 (philosophy는 상세 화면에서만 부가 표시; 도감 카드에는 미표시)
    - 활동 티어 (`tierRange`): maxClueLevel >= 2이면 공개
    - 발견 기록 시간순 로그 (`clueRecords`)
    - 발견 리전 목록 (`discoveredInRegions`)
  - 조건: maxClueLevel = 1이면 이름만 공개, description/philosophy/tierRange는 숨김.

---

### 2.2 데이터 요구사항

**신규 Hive 박스:**
- `factionStates`: `FactionState` 타입, typeId 9. 키: `factionId` (String)
- `FactionClueRecord`: typeId 10 (FactionState 내 List로 저장, 별도 박스 없음)

**신규 정적 데이터 모델:**
- `FactionData`: freezed + json_serializable. `features/info/domain/faction_data.dart`
  - 필드: `id`, `name`, `description`, `philosophy`, `tierRange(List<int>)`, `color`
  - Supabase `factions` 테이블 연동

**InvestigationResult 확장:**
- `factionClues: List<FactionClueResult>` 필드 추가 (기본값 `const []`)

**Supabase (앱 외부 작업 — 구현 전 선행 필요):**
- `factions` 테이블 생성 (스키마: id TEXT PK, name TEXT, description TEXT, philosophy TEXT, tier_range JSONB, color TEXT)
- `data_versions`에 `factions` 행 추가 (version: 1)
- 세력 마스터 데이터 3행 삽입
- `region_discoveries`에 faction_clue 타입 6행 삽입

---

### 2.3 UI 요구사항

**정보 탭 (`InfoScreen`):**
- 탭 아이콘: `Icons.menu_book` 또는 `Icons.info_outline`, 라벨: `정보`
- 초기 콘텐츠: 세력 도감 항목 카드 1개. 향후 추가 항목을 위한 ListView 구조.
- 세력 도감 진입 카드에 "발견한 세력: N" 카운트 표시. 전체 세력 수는 비공개 원칙에 따라 분모 없이 `"발견한 세력: N"` 형태로만 표시 (예: `"발견한 세력: 2"`).

**세력 도감 (`FactionCodexScreen`):**
- 발견된 세력: `maxClueLevel >= 1`인 항목을 `maxClueLevel` 내림차순 정렬
- 미발견 표시: 발견 안 된 세력이 있으면 `???` 행 1개 (전체 세력 수 노출 금지)
- 세력 카드 구성:
  - 좌측 어센트 바: `FactionData.color` HEX
  - 우측 상단: 별 3개 (채워진 별 `Colors.amber`, 빈 별 `AppTheme.textHint`)
  - 세력 이름: `maxClueLevel >= 1`이면 공개, 아니면 `???`
  - 설명: `maxClueLevel >= 2`이면 `description` 공개, 아니면 `???`
  - 발견 기록: 시간순 `clueRecords` 텍스트 목록

**조사 완료 팝업 수정:**
- `factionClues` 비어있지 않을 때: 기존 발견 섹션 아래 `✨ 새로운 단서 발견!` + 세력명 + clue_text 표시
- `actions`: `factionClues` 존재 시 `[도감에서 확인]` 버튼 추가 (탭 시 정보 탭 이동)

**홈 화면 설정 버튼:**
- 현재 HomeScreen `build()` 반환 Scaffold의 AppBar 우측 상단 또는 Stack 상단 오버레이에 `Icons.settings` 아이콘 버튼 추가
- 탭 시 `_showSettings` 상태 변수로 설정 화면 렌더링 (Navigator.push 미사용)

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `lib/features/investigation/domain/investigation_result.dart` | `factionClues: List<FactionClueResult>` 필드 추가, 기본값 `const []` | FR-4: InvestigationResult 확장 |
| `lib/features/investigation/domain/investigation_notifier.dart` | `_completeInvestigation()` — `newlyTriggered` 루프에 `faction_clue` 분기 추가 | FR-4: faction_clue 처리 |
| `lib/features/investigation/view/investigation_widget.dart` | `InvestigationResultDialog`를 `ConsumerWidget`으로 전환(`build(context, ref)` 시그니처), faction_clue 섹션 + "도감에서 확인" 버튼 추가 | FR-5: 팝업 UI 수정 |
| `lib/app.dart` | `_screens[5]`: `SettingsScreen()` → `InfoScreen()` | FR-1: 네비게이션 |
| `lib/shared/widgets/bottom_nav_bar.dart` | 인덱스 5 탭: `⚙ 설정` → `📋 정보` | FR-1: 네비게이션 |
| `lib/features/home/view/home_screen.dart` | 상단에 ⚙ 아이콘 버튼 추가, 설정 화면 상태 기반 렌더링 | FR-1: 설정 접근 경로 이전 |
| `lib/core/data/sync_service.dart` | `SyncService.allTables` 리스트에 `'factions'` 추가 | FR-2: 동기화 |
| `lib/core/data/hive_initializer.dart` | `FactionStateAdapter`, `FactionClueRecordAdapter` 등록 + `factionStates` 박스 오픈 | FR-3: Hive 초기화 |
| `lib/core/providers/static_data_provider.dart` | `StaticGameData`에 `List<FactionData> factions` 필드 추가 + `dataLoader.loadFromCache('factions', FactionData.fromJson)` 호출 추가 | FR-2: factions 정적 데이터 로드 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/info/domain/faction_data.dart` | FactionData freezed 모델 (Supabase 정적 데이터) |
| `lib/features/info/domain/faction_state_model.dart` | FactionState (typeId 9) + FactionClueRecord (typeId 10) Hive 모델 |
| `lib/features/info/domain/faction_clue_result.dart` | FactionClueResult DTO (InvestigationResult → UI 전달용) |
| `lib/features/info/data/faction_state_repository.dart` | factionStates Hive CRUD (processClue, getState, getAllDiscovered) |
| `lib/features/info/view/info_screen.dart` | 정보 탭 루트 화면 (세력 도감 진입 카드 포함) |
| `lib/features/info/view/faction_codex_screen.dart` | 세력 도감 목록 화면 |
| `lib/features/info/view/faction_detail_screen.dart` | 세력 상세 화면 (발견 기록 로그) |
| `lib/features/info/domain/faction_codex_providers.dart` | `factionCodexScrollTargetProvider` (`StateProvider<String?>`) + `factionListProvider` (`Provider<List<({FactionData data, FactionState? state})>>`) — 세력 정적 데이터와 Hive 상태를 결합한 뷰 리스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `lib/features/info/domain/faction_data.dart` | freezed + json_serializable → `faction_data.freezed.dart`, `faction_data.g.dart` 생성 |
| `lib/features/info/domain/faction_state_model.dart` | hive_generator → `faction_state_model.g.dart` 생성 |

build_runner 재실행 필요.

### 3.4 관련 시스템

- **조사 시스템**: `InvestigationNotifier._completeInvestigation()` 확장. 기존 discovery 파이프라인 구조 유지.
- **정적 데이터 / SyncService**: `factions` 테이블 추가 동기화. 기존 17개 테이블 패턴 동일 적용.
- **Hive 영속성**: typeId 9~10 신규 할당. 기존 마이그레이션 로직(`stat_migration_v2`)에 영향 없음.
- **네비게이션**: `currentTabProvider` 값 5의 의미 변경 (설정 → 정보). 기존 탭 인덱스 0~4 영향 없음.
- **활동 로그**: `ActivityLogType.discoveryFound` 재사용. 스키마 변경 없음.

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `lib/features/investigation/domain/region_discovery_data.dart:8`: `discoveryData: Map<String, dynamic>?` — `faction_clue` JSON 파싱에 그대로 활용. `discoveryData!['faction_id']`, `['clue_level']`, `['clue_text']`로 접근.
- `lib/features/investigation/data/region_state_repository.dart`: RegionStateRepository 패턴 — FactionStateRepository 동일 구조로 구현.
- `lib/core/data/hive_initializer.dart:28`: `Hive.registerAdapter(RegionStateAdapter())` 패턴 — FactionState/FactionClueRecord 어댑터 등록 동일 방식.
- `lib/core/providers/static_data_provider.dart`: `StaticGameData` 및 `DataLoader` — `factions` 필드/로드 추가 시 기존 17개 패턴 그대로 복제.
- `lib/core/data/sync_service.dart`: `'region_discoveries'` 항목 — `'factions'` 추가 시 동일 위치에 동일 형식으로 삽입.
- `lib/features/mercenary/view/mercenary_detail_overlay.dart` (또는 유사 화면): Navigator.push 미사용 상태 기반 화면 전환 패턴 참조 — InfoScreen 내 FactionCodexScreen 전환에 적용.
- `lib/app.dart:171-184`: `investigationCompletedProvider` 리스너 — InvestigationResultDialog 호출 위치. "도감에서 확인" 버튼은 dialog 내부에서 `ref.read(currentTabProvider.notifier).state = 5` 처리.

### 4.2 주의사항

- **InvestigationResultDialog ConsumerWidget 전환**: 현재 `StatelessWidget`. `AlertDialog.actions`에서 `currentTabProvider` 및 `factionCodexScrollTargetProvider` 접근을 위해 `ConsumerWidget`으로 전환 (`build(BuildContext context, WidgetRef ref)` 시그니처). `app.dart`에서 `showDialog(builder: (ctx) => InvestigationResultDialog(...))` 형태이므로 ProviderScope 내부에 있어 ref 접근 가능. 단, 자식 위젯 `_DialogContent`(line 388)는 이미 `ConsumerWidget`이므로 content 영역에서는 ref 접근이 별도 전환 없이 가능하다. `AlertDialog.actions`는 `InvestigationResultDialog.build()` 스코프에서 정의되므로, 부모인 `InvestigationResultDialog` 자체의 `ConsumerWidget` 전환이 반드시 필요하다.
- **`faction_clue` 분기 위치**: `investigation_notifier.dart:105-118`의 `for (final d in newlyTriggered)` 루프 내부에서 `d.discoveryType == 'faction_clue'` 조건 분기 추가. 기존 `repo.addTriggeredDiscovery()` 호출은 그대로 유지 (모든 discovery 타입에 공통 적용).
- **typeId 충돌 방지**: 현재 typeId 0~8 사용 중. `FactionState`에 typeId 9, `FactionClueRecord`에 typeId 10 할당. `ActivityLogType`은 typeId 6으로 별도 파일에 정의됨 — 충돌 없음.
- **`factionClues` 기본값**: `InvestigationResult`에 `factionClues`를 추가할 때 기존 생성자 호출부(`investigation_notifier.dart:120-128`, `154-162`) 모두 수정 필요. 실패 케이스(line 154)는 `factionClues: const []`로 고정.
- **CLAUDE.md 규칙**: Navigator.push 미사용 → InfoScreen 내 화면 전환은 상태 변수 (`_selectedFaction`) 기반.
- **`discoveredInRegions` 타입 불일치**: `FactionState.discoveredInRegions`는 `List<String>` (Hive 저장, 기획서 원안). `FactionClueRecord.regionId`는 `int`. `processClue()` 호출 시 `regionId.toString()`으로 변환하여 `discoveredInRegions`에 저장. `FactionDetailScreen`에서 "발견 지역" 표시 시 `discoveredInRegions`의 String을 `int.parse()`하여 `staticData.regions`에서 지역명을 조회하거나, `FactionClueRecord.regionId`(int)에서 직접 조회한다.

### 4.3 엣지 케이스

- **동일 faction_clue 중복 발견**: 같은 세력의 동일 clue_level을 다른 region에서 재발견 시 — `processClue()`에서 `clueRecords`에 기록 추가는 하되, `maxClueLevel` 갱신은 스킵(`false` 반환). 팝업에는 표시하되 활동 로그는 생략.
- **factions 테이블 비어있을 때 (`factions: []`)**: `StaticGameData.factions`가 빈 리스트면 InvestigationNotifier에서 faction_clue discovery를 처리하려 할 때 세력 이름 조회 실패 → `FactionClueResult.factionName`을 nullable로 두고 null 시 `"(알 수 없는 세력)"` 표시.
- **역방향 단서 레벨**: clue_level 2가 먼저 발견되고 나중에 1이 발견되는 경우 — `processClue()`에서 `maxClueLevel`은 높은 값 유지, `clueRecords`에는 그대로 추가.
- **복수 faction_clue 동시 트리거**: `factionClues` 리스트에 모두 포함. 팝업에서 순서대로 나열.

### 4.4 구현 힌트

- **진입점**: `InvestigationNotifier._completeInvestigation()` (`investigation_notifier.dart:68`) — faction_clue 처리 추가 시작점.
- **데이터 흐름**:
  ```
  [조사 완료] _completeInvestigation()
    → newlyTriggered 순회
      → discoveryType == 'faction_clue'
        → FactionStateRepository.processClue(factionId, clueLevel, regionId, clueText)
          → Hive factionStates 박스 갱신
        → FactionClueResult 생성 (staticData.factions에서 factionName 조회)
    → InvestigationResult(factionClues: [...]) 생성
    → investigationCompletedProvider.state = result
  → app.dart 리스너 → showDialog(InvestigationResultDialog)
    → factionClues 있으면 "도감에서 확인" 버튼
      → currentTabProvider = 5 (정보 탭)
  ```
- **참조 구현**:
  - `investigation_notifier.dart:105-118` — `newlyTriggered` 루프. 이 블록 내에서 분기 추가.
  - `region_state_repository.dart` — FactionStateRepository 구조 동일하게 복제.
  - `sync_service.dart` 내 `'region_discoveries'` 라인 — `'factions'` 추가 위치.
  - `static_data_provider.dart` 내 `regionDiscoveries` 필드/로드 — `factions` 추가 시 동일 패턴.
- **확장 지점**: `HiveInitializer.initialize()` 내 `Hive.registerAdapter(RegionStateAdapter())` 다음 줄에 FactionState/FactionClueRecord 어댑터 등록. `Hive.openBox<RegionState>(regionStateBoxName)` 다음 줄에 `factionStates` 박스 오픈.

---

## 5. 기획 확인 사항

- [Q-1] 정보 탭 목업에서 "발견한 세력: 2 / ???"로 표기했으나, 기획 문서 본문 "세력 총 수 비공개" 규칙에서 분모 표시를 금지한다. → 명세서는 본문 규칙(비공개 원칙)을 따라 "발견한 세력: N" (분모 없음) 형식을 채택한다. 목업의 `/ ???` 표기는 의도적으로 제외.
- [Q-2] 기획서 단서 레벨별 정보 공개 테이블의 `설명(philosophy)` 컬럼이 `description` 필드를 지칭하는 것으로 해석됨. `philosophy`는 상세 화면에서만 부가 표시하며, 도감 카드에는 포함하지 않는다. 기획서 목업(도감 카드/상세 화면)에서 `philosophy` 별도 표시가 없어 이 해석을 채택.
