# 세력 발견 시스템 — 세계 확장 Phase 6

> 작성일: 2026-04-15
> 유형: 신규 컨텐츠
> 선행 완료: 세계 확장 Phase 1 (지역 조사 시스템)
> 참고: Docs/content-design/roadmap/world_expansion_roadmap.md

---

## 개요

지역 조사 시스템(Phase 1)에서 축적한 지식이 세계의 세력을 발견하는 경로로 연결된다. 플레이어는 조사를 반복하며 단서를 수집하고, 흩어진 조각을 맞추듯 세력의 정체를 점진적으로 파악한다. 이 과정을 기록하고 열람하는 **세력 도감**을 정보 탭에 신설하며, 하단 네비게이션의 설정 탭을 홈 화면으로 이전하여 빈 자리를 확보한다.

**기대 효과:**
- 지역 조사의 보상 경로 확장 -- "단서 발견"이라는 새로운 동기 부여
- 미발견 세력(`???`)이 탐색 호기심을 자극하여 다양한 지역 방문 유도
- 점진적 정보 공개(별 3개 진행도)로 발견의 성취감 극대화
- 향후 세력 가입/기여도/경쟁 시스템의 진입로 확보

**범위 한정:**
- 세력 "발견"까지만 구현 (가입, 기여도, 전용 퀘스트는 2단계 이후)
- 검증용 세력 3개 + faction_clue 데이터 6행으로 파이프라인 검증
- 네비게이션 변경(설정 탭 제거 + 정보 탭 신설) 포함

---

## 레퍼런스 분석

| 게임/작품 | 차용 메커니즘 | 본 시스템 적용 |
|----------|-------------|--------------|
| **용마검전 (김재한)** | 다수 세력의 공존과 경쟁. 플레이어의 선택에 따라 관계가 달라지는 진영 시스템 | 세력 존재 확립 + 점진적 발견. 현 단계에서는 "관찰자" 위치, 향후 가입/경쟁으로 확장 |
| **Crusader Kings 3** | 점진적 정보 공개. 세력의 비밀/음모가 단서 축적에 따라 밝혀지는 구조 | 단서 레벨(1~3)로 세력 이름/설명 순차 공개. `???` 상태에서 시작하여 탐색 동기 부여 |
| **Darkest Dungeon** | 기록장/로그 형식의 서사 표현. 탐험 기록이 쌓이며 세계관이 드러나는 방식 | 발견 기록 텍스트 로그로 서사적 몰입. 별 진행도 + 시간순 기록 혼합 |
| **Melvor Idle** | 마스터리/도감 시스템. 반복 행동의 결과가 시각적 진행도로 축적되는 쾌감 | 별 3개(★☆☆) 진행도 + 도감 UI. 반복 조사가 수집 달성으로 연결 |

---

## 네비게이션 변경 — 정보 탭 신설

### 변경 사항

현재 하단 6탭 구성에서 **설정 탭을 제거**하고, 그 자리에 **정보(情報) 탭을 신설**한다.

| 변경 전 | 변경 후 |
|---------|---------|
| 이동 / 파견 / 홈 / 모집 / 시설 / **설정** | 이동 / 파견 / 홈 / 모집 / 시설 / **정보** |

### 설정 접근 경로 이전

설정 화면은 **홈 화면 상단의 톱니바퀴 아이콘**으로 접근한다.

```
홈 화면 (야영지)
┌─────────────────────────────────┐
│ 🏕 야영지           [⚙]        │  ← 톱니바퀴 버튼
│                                 │
│ ...기존 홈 화면 콘텐츠...        │
└─────────────────────────────────┘
```

### 영향받는 파일

| 파일 | 변경 내용 |
|------|----------|
| `shared/widgets/bottom_nav_bar.dart` | 6번째 탭을 `⚙ 설정` → `📋 정보`로 교체 |
| `core/providers/navigation_provider.dart` | 탭 인덱스 변경 없음 (0~5 유지, 5번의 의미만 변경) |
| `app.dart` (`_MainShellState._screens`) | `SettingsScreen()` → `InfoScreen()`으로 교체 |
| `features/home/view/home_screen.dart` | 상단에 `⚙` 버튼 추가, 탭 시 설정 화면을 상태 기반 렌더링 |
| `features/info/` (신규) | 정보 탭 feature 모듈 생성 |

### 정보 탭 초기 구성

정보 탭은 향후 다양한 정보 컨텐츠의 허브 역할을 한다. 초기 콘텐츠는 세력 도감 하나만 포함한다.

```
정보 탭
┌─────────────────────────────────┐
│ 📋 정보                         │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⚔ 세력 도감                  │ │  ← 현재 유일한 항목
│ │ 발견한 세력: 2 / ???          │ │
│ └─────────────────────────────┘ │
│                                 │
│ (향후 추가 예정)                  │
│ ┌─────────────────────────────┐ │
│ │ 📖 지역 백과 (잠김)           │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🏆 업적 (잠김)               │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## 세력 도감 UI 설계

### 진입 경로

하단 탭 `정보` → 세력 도감 항목 탭 → 세력 도감 화면

### 도감 화면 구성

**별 3개 진행도 + 발견 기록 텍스트 로그 혼합** 방식이다. 단서 레벨에 따라 세력 이름과 설명이 점진적으로 공개된다.

```
정보 탭
└── 세력 도감

은빛 교단                    ★★☆
"고대의 지식을 수호하는 비밀 결사"  ← level 2 도달 시 공개

  📜 발견 기록
  ├ "은빛 문양이 새겨진 석판을 발견했다"       (level 1)
  └ "은빛 교단이라는 세력의 것으로 확인됐다"   (level 2)
─────────────────────────────────────
야만족 연합                  ★☆☆
"???"

  📜 발견 기록
  └ "이 지역에 누군가의 활동 흔적이 있다"      (level 1)
─────────────────────────────────────
??? (미발견)                 ☆☆☆
"아직 발견하지 못한 세력이 있는 것 같다"
```

### 단서 레벨별 정보 공개 규칙

| 단서 레벨 | 별 표시 | 세력 이름 | 설명(philosophy) | 발견 기록 |
|----------|---------|----------|-----------------|----------|
| 0 (미발견) | ☆☆☆ | `???` | "아직 발견하지 못한 세력이 있는 것 같다" | 없음 |
| 1 (흔적) | ★☆☆ | 세력 이름 공개 | `???` | level 1 기록만 |
| 2 (정체) | ★★☆ | 세력 이름 | 설명 공개 | level 1~2 기록 |
| 3 (거점) | ★★★ | 세력 이름 | 설명 공개 + 거점 정보 | 전체 기록 |

### 세력 총 수 비공개

도감에는 "발견한 세력: N" 형태로만 표시하고, 전체 세력 수는 감춘다. 미발견 세력은 `???` 1행으로 통합 표시하여 "아직 더 있을 수 있다"는 느낌을 유지한다. 모든 세력을 발견한 경우에도 `???` 행을 제거하지 않고 "더 이상의 단서가 발견되지 않았다"로 텍스트만 변경하는 방안을 검토할 수 있으나, 초기 구현에서는 단순히 미발견 세력이 있을 때만 `???` 행을 표시한다.

### 도감 상세 진입

세력 카드를 탭하면 상세 화면으로 전환된다 (상태 기반 렌더링, Navigator.push 미사용).

```
← 뒤로                세력 상세

은빛 교단                       ★★☆
"고대의 지식을 수호하는 비밀 결사"

활동 영역: Tier 2~3

📜 발견 기록
──────────────────────────
[은빛 평원]  2026-04-12
"은빛 문양이 새겨진 석판을 발견했다"

[고원 도시]  2026-04-14
"은빛 교단이라는 세력의 것으로 확인됐다"
──────────────────────────

발견 지역: 은빛 평원, 고원 도시
```

### 색상 및 스타일

- 세력 카드 배경: `AppTheme.surfaceLight` 기반, 세력별 `color` 필드로 좌측 어센트 바 표시
- 미발견(`???`) 카드: `AppTheme.border` 계열 어두운 톤
- 별 색상: 채워진 별은 `Colors.amber`, 빈 별은 `AppTheme.textHint`
- 발견 기록: `AppTheme.textSecondary`, 레벨 태그는 세력 어센트 컬러

---

## 단서 발견 흐름

### 전체 파이프라인

```
지역 조사 완료 (InvestigationNotifier._completeInvestigation)
  → 지식 임계값 체크 → region_discoveries 매칭
  → discovery_type == 'faction_clue' 감지
  → discoveryData에서 faction_id, clue_level, clue_text 추출
  → FactionStateRepository 갱신 (FactionState 생성 또는 maxClueLevel 업데이트)
  → InvestigationResult에 faction 단서 정보 포함
  → 조사 완료 팝업에 단서 발견 인라인 표시
  → 활동 로그 기록
```

### 조사 완료 팝업 변경

기존 `InvestigationResultDialog`에 faction_clue 발견 시 추가 섹션을 인라인으로 표시한다. 별도 팝업 체이닝은 하지 않는다.

```
┌─────────────────────────────┐
│       지역 조사 완료         │
│  📍 은빛 평원 (Tier 2)       │
│  지식  ████████░░  +8        │
│        (48 → 56)            │
│                             │
│  ✨ 새로운 단서 발견!         │
│  「은빛 교단」의 흔적을        │
│   이 지역에서 발견했습니다     │
│                             │
│  [도감에서 확인]  [닫기]      │
└─────────────────────────────┘
```

**[도감에서 확인] 버튼 동작:**
1. 팝업 닫기
2. `currentTabProvider`를 5(정보 탭)로 변경
3. 정보 탭 내부에서 세력 도감 화면으로 자동 진입하고, 해당 세력 카드로 스크롤

### InvestigationResult 모델 확장

기존 `InvestigationResult`에 faction 단서 정보를 추가한다.

```dart
class InvestigationResult {
  final bool success;
  final int regionId;
  final int knowledgeGained;
  final int currentKnowledge;
  final List<String> newDiscoveryIds;
  final bool mercInjured;
  final String mercId;
  // --- Phase 6 추가 ---
  final List<FactionClueResult> factionClues;  // 새로 발견된 세력 단서 목록

  // ...
}

class FactionClueResult {
  final String factionId;
  final String clueText;
  final int clueLevel;
  final String? factionName;  // clue_level >= 1이면 factions 테이블에서 조회
}
```

### 활동 로그

단서 발견 시 기존 `ActivityLogType.discoveryFound` 타입을 재사용한다. 메시지 예시:

- level 1: `"세력 단서 발견: 이 지역에 누군가의 활동 흔적이 있다"`
- level 2: `"세력 발견: 은빛 교단의 정체를 파악했다"`
- level 3: `"거점 발견: 은빛 교단의 전초기지 위치를 파악했다"`

### 복수 단서 동시 발견

한 번의 조사 완료로 지식이 급등하여 복수의 faction_clue가 동시에 트리거될 수 있다 (예: knowledge 0→10에서 threshold 5와 10의 두 발견이 동시 트리거). 이 경우:
- `InvestigationResult.factionClues`에 모든 단서를 리스트로 포함
- 팝업에는 모든 단서를 순서대로 나열
- 각각 별도의 활동 로그 기록

---

## 데이터 구조

### Supabase 테이블

#### factions (신규)

세력 마스터 데이터. `data_versions`에 `factions` 행 추가.

| 컬럼 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `id` | `TEXT` (PK) | O | 세력 고유 ID (예: `faction_silver_order`) |
| `name` | `TEXT` | O | 세력 이름 (예: "은빛 교단") |
| `description` | `TEXT` | O | 세력 설명 (clue_level 2 도달 시 공개) |
| `philosophy` | `TEXT` | O | 세력 이념/철학 (도감 상세에서 표시) |
| `tier_range` | `JSONB` | O | 활동 티어 범위 (예: `[2, 3]`) |
| `color` | `TEXT` | O | 대표 색상 HEX (예: `"#C0C0C0"`) |

**검증용 데이터 (3행):**

| id | name | description | philosophy | tier_range | color |
|----|------|-------------|------------|------------|-------|
| `faction_silver_order` | 은빛 교단 | 고대의 지식을 수호하는 비밀 결사 | 지식은 힘이며, 힘은 책임이다 | `[2, 3]` | `#C0C0C0` |
| `faction_savage_alliance` | 야만족 연합 | 강함을 숭배하는 다부족 동맹 | 약한 자는 강한 자를 따를 뿐이다 | `[3, 4]` | `#8B4513` |
| `faction_abyss_guild` | 심연의 상회 | 정보와 돈으로 대륙을 움직이는 상단 | 세상 모든 것에는 가격이 있다 | `[2, 5]` | `#4B0082` |

#### region_discoveries (기존 테이블에 데이터 추가)

`discovery_type = 'faction_clue'` 행을 추가한다. 테이블 스키마는 Phase 1에서 이미 생성되어 있다.

```
region_discoveries 스키마 (기존):
  id            TEXT    PK
  region_id     INTEGER
  knowledge_threshold  INTEGER
  discovery_type       TEXT      -- 'info' | 'elite' | 'hidden_quest' | 'faction_clue' | 'transform'
  discovery_data       JSONB
  description          TEXT
```

**faction_clue용 discovery_data JSON 구조:**

```json
{
  "faction_id": "faction_silver_order",
  "clue_text": "은빛 문양이 새겨진 석판을 발견했다.",
  "clue_level": 1
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `faction_id` | String | factions 테이블의 id 참조 |
| `clue_text` | String | 발견 기록에 표시될 서사 텍스트 |
| `clue_level` | int (1~3) | 단서 수준. 1=흔적, 2=정체, 3=거점 |

**clue_level 의미 상세:**

| clue_level | 명칭 | 도감 반영 | 예시 텍스트 |
|------------|------|----------|------------|
| 1 | 흔적 발견 | 세력 이름 공개, 설명은 `???` | "이 지역에 누군가의 활동 흔적이 있다" |
| 2 | 정체 파악 | 설명(description) 공개 | "은빛 교단이라는 세력의 것으로 확인됐다" |
| 3 | 거점 발견 | 거점 정보 표시, 향후 가입 조건 충족 | "교단의 전초기지 위치를 파악했다" |

**검증용 region_discoveries 데이터 (6행):**

각 세력당 clue_level 1과 2를 서로 다른 리전에 배치한다. clue_level 3은 이번 Phase에서 데이터만 정의하고, 도달 테스트는 세력 가입 단계에서 검증한다.

| id | region_id | knowledge_threshold | discovery_type | discovery_data | description |
|----|-----------|-------------------|----------------|----------------|-------------|
| `disc_fc_silver_1` | 16 | 30 | `faction_clue` | `{"faction_id":"faction_silver_order","clue_text":"은빛 문양이 새겨진 석판을 발견했다.","clue_level":1}` | 은빛 문양이 새겨진 석판을 발견했다 |
| `disc_fc_silver_2` | 28 | 50 | `faction_clue` | `{"faction_id":"faction_silver_order","clue_text":"은빛 교단이라는 세력의 것으로 확인됐다.","clue_level":2}` | 은빛 교단의 정체를 파악했다 |
| `disc_fc_savage_1` | 42 | 40 | `faction_clue` | `{"faction_id":"faction_savage_alliance","clue_text":"야만적인 의식의 흔적이 남아있다.","clue_level":1}` | 야만적인 의식의 흔적을 발견했다 |
| `disc_fc_savage_2` | 55 | 60 | `faction_clue` | `{"faction_id":"faction_savage_alliance","clue_text":"야만족 연합이라 불리는 부족 동맹의 영역이다.","clue_level":2}` | 야만족 연합의 정체를 파악했다 |
| `disc_fc_abyss_1` | 20 | 25 | `faction_clue` | `{"faction_id":"faction_abyss_guild","clue_text":"정체불명의 상인 조직이 남긴 거래 장부를 발견했다.","clue_level":1}` | 정체불명의 거래 장부를 발견했다 |
| `disc_fc_abyss_2` | 70 | 45 | `faction_clue` | `{"faction_id":"faction_abyss_guild","clue_text":"심연의 상회라는 이름이 장부 곳곳에 등장한다.","clue_level":2}` | 심연의 상회의 정체를 파악했다 |

> **region_id 배치 원칙:** 각 세력의 `tier_range`에 해당하는 티어의 리전에 배치. 같은 세력의 서로 다른 단서를 다른 리전에 분산하여, 플레이어가 여러 지역을 탐색하도록 유도.

### Flutter 모델

#### FactionData (정적 데이터 모델, freezed)

Supabase `factions` 테이블과 1:1 매핑. `StaticGameData`에 `List<FactionData> factions` 필드 추가.

```dart
// features/info/domain/faction_data.dart
@freezed
class FactionData with _$FactionData {
  const factory FactionData({
    required String id,
    required String name,
    required String description,
    required String philosophy,
    @JsonKey(name: 'tier_range') required List<int> tierRange,
    required String color,
  }) = _FactionData;

  factory FactionData.fromJson(Map<String, dynamic> json) =>
      _$FactionDataFromJson(json);
}
```

#### FactionState (Hive 유저 상태 모델)

`factionStates` Hive 박스에 `factionId` 키로 저장.

```dart
// features/info/domain/faction_state_model.dart
@HiveType(typeId: 9)  // 기존 typeId: 0~8 사용 중, 9 할당
class FactionState extends HiveObject {
  @HiveField(0)
  String factionId;

  @HiveField(1)
  bool discovered;            // 최소 1개 단서를 발견했는지

  @HiveField(2)
  int maxClueLevel;           // 도달한 최고 단서 레벨 (0~3)

  @HiveField(3)
  List<String> discoveredInRegions;  // 단서를 발견한 리전 ID 목록

  @HiveField(4)
  List<FactionClueRecord> clueRecords;  // 발견 기록 (시간순)

  // 향후 확장 필드 (HiveField 5~)
  // joined: bool
  // contribution: int
  // rank: String

  FactionState({
    required this.factionId,
    this.discovered = false,
    this.maxClueLevel = 0,
    List<String>? discoveredInRegions,
    List<FactionClueRecord>? clueRecords,
  }) : discoveredInRegions = discoveredInRegions ?? [],
       clueRecords = clueRecords ?? [];
}

@HiveType(typeId: 10)
class FactionClueRecord extends HiveObject {
  @HiveField(0)
  String clueText;

  @HiveField(1)
  int clueLevel;

  @HiveField(2)
  int regionId;

  @HiveField(3)
  DateTime discoveredAt;

  FactionClueRecord({
    required this.clueText,
    required this.clueLevel,
    required this.regionId,
    required this.discoveredAt,
  });
}
```

#### FactionClueResult (단서 발견 결과 DTO)

`InvestigationResult`에 포함되어 UI로 전달된다.

```dart
// features/info/domain/faction_clue_result.dart
class FactionClueResult {
  final String factionId;
  final String clueText;
  final int clueLevel;
  final String? factionName;  // staticData에서 조회 (level >= 1이면 항상 존재)

  const FactionClueResult({
    required this.factionId,
    required this.clueText,
    required this.clueLevel,
    this.factionName,
  });
}
```

### Hive 박스

| 박스명 | 모델 | typeId | 키 전략 | 설명 |
|--------|------|--------|---------|------|
| `factionStates` | `FactionState` | 9 | `factionId` (String) | 세력별 유저 상태 |

`HiveInitializer`에 박스 등록 추가 필요:
- `Hive.registerAdapter(FactionStateAdapter())`
- `Hive.registerAdapter(FactionClueRecordAdapter())`
- `await Hive.openBox<FactionState>('factionStates')`

### 동기화

`SyncService`의 `data_versions` 비교 대상에 `factions` 테이블 추가. `DataLoader`에서 `factions` JSON 캐시 로드. `StaticGameData`에 `List<FactionData> factions` 필드 추가.

```
data_versions 추가 행:
  table_name: 'factions'
  version: 1
```

---

## 기존 시스템과의 연관

### InvestigationNotifier 파이프라인 확장

`_completeInvestigation()` 메서드에서 `newlyTriggered` discovery 목록을 순회할 때, `discovery_type == 'faction_clue'` 항목에 대한 처리를 추가한다.

```
기존 흐름:
  newlyTriggered 순회 → addTriggeredDiscovery → 활동 로그

확장 흐름:
  newlyTriggered 순회
    → 일반 discovery → 기존 처리
    → faction_clue → FactionStateRepository.processClue() 호출
                    → FactionClueResult 생성 → InvestigationResult에 추가
                    → 활동 로그 (세력 단서 전용 메시지)
```

**핵심 원칙:** 기존 discovery 트리거 파이프라인의 구조를 변경하지 않고, `faction_clue` 타입에 대한 분기만 추가한다.

### FactionStateRepository

```dart
// features/info/data/faction_state_repository.dart
class FactionStateRepository {
  Box<FactionState> get _box =>
      Hive.box<FactionState>(HiveInitializer.factionStateBoxName);

  FactionState? getState(String factionId) { ... }

  /// 단서 처리: FactionState 생성 또는 업데이트
  /// 반환: maxClueLevel이 실제로 갱신되었는지 여부
  bool processClue(String factionId, int clueLevel, int regionId, String clueText) {
    var state = getState(factionId);
    if (state == null) {
      state = FactionState(factionId: factionId, discovered: true, maxClueLevel: clueLevel);
      state.discoveredInRegions.add(regionId.toString());
      state.clueRecords.add(FactionClueRecord(
        clueText: clueText,
        clueLevel: clueLevel,
        regionId: regionId,
        discoveredAt: DateTime.now(),
      ));
      _box.put(factionId, state);
      return true;
    }

    final updated = clueLevel > state.maxClueLevel;
    if (updated) state.maxClueLevel = clueLevel;
    if (!state.discovered) state.discovered = true;
    if (!state.discoveredInRegions.contains(regionId.toString())) {
      state.discoveredInRegions.add(regionId.toString());
    }
    state.clueRecords.add(FactionClueRecord(
      clueText: clueText,
      clueLevel: clueLevel,
      regionId: regionId,
      discoveredAt: DateTime.now(),
    ));
    state.save();
    return updated;
  }

  List<FactionState> getAllDiscovered() { ... }
}
```

### investigationCompletedProvider 연동

`InvestigationResult`에 `factionClues` 필드가 추가되므로, `app.dart`의 `ref.listen<InvestigationResult?>` 핸들러에서 `InvestigationResultDialog`로 전달하면 자연스럽게 UI에 반영된다.

### 정보망 시설 연동 (향후)

현재 정보망 시설은 퀘스트 수 증가 효과를 가진다. 향후 확장 시:
- 정보망 Lv.5+: 세력 단서 발견 확률 소폭 증가 (이번 Phase 범위 외)
- 정보망 Lv.10+: 조사 슬롯 2개로 확장 (이번 Phase 범위 외)

### 시간 가속 호환

세력 발견은 조사 완료 시 즉시 처리되므로, 별도의 시간 가속 대응이 필요 없다. 조사 자체의 시간 가속은 Phase 1에서 이미 구현되어 있다.

---

## 구현 작업 목록

### Supabase 작업

| # | 작업 | 상세 |
|---|------|------|
| S1 | `factions` 테이블 생성 | 스키마: id(TEXT PK), name(TEXT), description(TEXT), philosophy(TEXT), tier_range(JSONB), color(TEXT) |
| S2 | `data_versions`에 `factions` 행 추가 | `table_name: 'factions', version: 1` |
| S3 | 세력 마스터 데이터 3행 삽입 | 은빛 교단, 야만족 연합, 심연의 상회 |
| S4 | `region_discoveries`에 faction_clue 데이터 6행 삽입 | 세력당 2행 (clue_level 1, 2), 서로 다른 리전에 배치 |

### Flutter 작업

#### 인프라 (네비게이션 + 데이터)

| # | 작업 | 상세 |
|---|------|------|
| F1 | `features/info/` 모듈 생성 | `view/`, `domain/`, `data/` 3계층 디렉토리 |
| F2 | `FactionData` freezed 모델 생성 | `features/info/domain/faction_data.dart` + build_runner |
| F3 | `FactionState` + `FactionClueRecord` Hive 모델 생성 | typeId 9, 10 할당. `features/info/domain/faction_state_model.dart` |
| F4 | `FactionClueResult` DTO 생성 | `features/info/domain/faction_clue_result.dart` |
| F5 | `HiveInitializer`에 `factionStates` 박스 등록 | 어댑터 등록 + 박스 오픈 |
| F6 | `StaticGameData`에 `factions` 필드 추가 | `static_data_provider.dart` 수정 |
| F7 | `SyncService`에 `factions` 동기화 추가 | `data_versions` 비교 대상 + JSON 캐시 로드 |
| F8 | `BottomNavBar` 6번째 탭 변경 | `⚙ 설정` → `📋 정보` |
| F9 | `app.dart` `_screens` 배열 변경 | `SettingsScreen()` → `InfoScreen()` |
| F10 | `HomeScreen` 상단에 설정 버튼 추가 | `⚙` 아이콘 → 설정 화면 상태 기반 렌더링 |

#### 핵심 로직

| # | 작업 | 상세 |
|---|------|------|
| F11 | `FactionStateRepository` 구현 | `features/info/data/faction_state_repository.dart` — processClue, getState, getAllDiscovered |
| F12 | `InvestigationResult` 모델 확장 | `factionClues: List<FactionClueResult>` 필드 추가, 기존 생성자 호환 유지 |
| F13 | `InvestigationNotifier._completeInvestigation` 확장 | faction_clue 타입 분기 → FactionStateRepository.processClue → FactionClueResult 생성 |
| F14 | 활동 로그 기록 | faction_clue 발견 시 `ActivityLogType.discoveryFound`로 세력 전용 메시지 기록 |

#### UI

| # | 작업 | 상세 |
|---|------|------|
| F15 | `InfoScreen` 구현 | 정보 탭 메인 화면 — 세력 도감 진입점 + 향후 확장 슬롯 |
| F16 | `FactionCodexScreen` 구현 | 세력 도감 목록 — 별 진행도, 이름/설명 점진 공개, 미발견 `???` 표시 |
| F17 | `FactionDetailScreen` 구현 | 세력 상세 — 발견 기록 시간순, 발견 지역, 활동 티어 |
| F18 | `InvestigationResultDialog` 확장 | faction_clue 발견 시 인라인 섹션 추가 + [도감에서 확인] 버튼 |
| F19 | [도감에서 확인] 네비게이션 | 팝업 닫기 → currentTabProvider=5 → 세력 도감 자동 진입 |

#### Provider

| # | 작업 | 상세 |
|---|------|------|
| F20 | `factionStateRepositoryProvider` | `Provider((ref) => FactionStateRepository())` |
| F21 | `factionListProvider` | 발견된 세력 목록을 FactionState + FactionData 조합으로 제공 |

### operation-bom (운영 웹앱) 작업

| # | 작업 | 상세 |
|---|------|------|
| O1 | `factions` CRUD UI | 세력 목록/생성/수정/삭제 + 색상 미리보기 |
| O2 | `region_discoveries` 편집 뷰에 `faction_clue` 타입 지원 | discovery_data 입력 시 faction_id 드롭다운 + clue_level 선택 + clue_text 입력 |
| O3 | `data_versions`에 `factions` 버전 발행 기능 추가 | 기존 버전 발행 흐름에 factions 테이블 추가 |

### 작업 의존 순서

```
S1, S2 (Supabase 테이블)
  → S3, S4 (데이터 삽입)

F1~F4 (모델/DTO 생성)
  → F5 (Hive 등록)
  → F6, F7 (StaticGameData + Sync)
  → build_runner build

F8, F9, F10 (네비게이션 변경) -- 독립 작업, 병렬 가능

F11 (FactionStateRepository)
  → F12, F13 (InvestigationResult 확장 + Notifier 확장)
  → F14 (활동 로그)

F15 (InfoScreen)
  → F16 (FactionCodexScreen)
  → F17 (FactionDetailScreen)

F12, F13 완료 후 → F18, F19 (팝업 확장)

F20, F21 (Provider) -- F11과 병렬 가능
```

---

## 향후 확장 로드맵

### 세력 시스템 확장 단계

| 단계 | 내용 | 선행 조건 | 예상 범위 |
|------|------|----------|----------|
| **1단계 (이번 Phase 6)** | 세력 존재 확립 + 단서 발견 + 도감 UI + 네비게이션 변경 | Phase 1 (지역 조사) | Supabase 1테이블 + Flutter 모델/UI/로직 |
| 2단계 | 세력 가입 + 세력 전용 퀘스트 + 기여도 시스템 | Phase 6 + Phase 4 (연계 퀘스트) | clue_level 3 도달 → 가입 선택 → 전용 퀘스트 풀 생성 |
| 3단계 | 세력 상점 (기여도로 전용 장비/정수 교환) | 2단계 + 아이템 시스템 (Phase 2) | 세력별 고유 아이템, 기여도 화폐 |
| 4단계 | 세력 간 영향력 경쟁 (서버 연동) | 3단계 + Supabase 인증/쓰기 | 리전별 세력 영향력, 서버 집계 |

### 정보 탭 확장 방향

정보 탭은 세력 도감을 시작으로 다양한 정보 컨텐츠의 허브가 된다.

| 콘텐츠 | 선행 조건 | 설명 |
|--------|----------|------|
| 세력 도감 | 이번 Phase | 세력 발견 진행도 + 기록 |
| 지역 백과 | Phase 5 (지역 변형) | 방문/조사한 지역 정보, 변형 기록, 발견 이벤트 아카이브 |
| 엘리트 도감 | Phase 3 (엘리트) | 처치한 엘리트 기록, 드랍 테이블 공개 |
| 업적 | 별도 기획 | 달성 조건 기반 업적 시스템 |

### FactionState 향후 필드 확장

```dart
// 2단계 추가 예정
@HiveField(5)
bool joined;              // 세력 가입 여부

@HiveField(6)
int contribution;         // 기여도

@HiveField(7)
String? rank;             // 세력 내 등급

// 3단계 추가 예정
@HiveField(8)
Map<String, int> shopPurchases;  // 상점 구매 기록
```
