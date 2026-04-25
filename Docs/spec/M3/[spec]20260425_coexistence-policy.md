# 공존 정책 — 파견 화면 정렬 + 도착 팝업 큐 개발 명세서

> 기획 문서: Docs/content-design/[content]20260424_coexistence_policy.md
> 작성일: 2026-04-25
> 선행 spec: [spec]20260424_chain-quest-system.md (Phase 4-2), [spec]20260424_region-transform-system.md (Phase 4-3), [spec]20260425_travel-choice-system.md (Phase 4-5)

## 1. 개요

M3 이후 파견 화면에 5계층 컨텐츠(체인·세력 전용·엘리트·변형 섹터·일반)가 공존하고, 한 번의 이동 도착 시 최대 8단계 팝업이 순차 발생한다. 본 spec은 ① `DialogQueueNotifier` 기반 전역 팝업 큐, ② 파견 화면 5계층 정렬 + 체인 상단 고정 섹션, ③ 카드 시각 통합 규칙(LayerSidebar/QuestCardBadges 공유 위젯), ④ 이동 화면 체인 하이라이트를 정의한다. 기존 3개 독립 팝업 채널(건설/조사/랭크업)을 큐로 통합하고, Phase 4-2~4-5가 각자 정의한 팝업을 동일 큐 계약으로 연결한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### 전역 팝업 큐 (FR-1 ~ FR-5)

- [FR-1] **DialogQueueNotifier** — 우선순위 큐 상태를 관리한다.
  - `enqueue(DialogRequest)`: priority 내림차순 삽입, 동일 priority는 FIFO, 중복 id 무시
  - `dequeue()`: 현재 표시 완료 후 큐에서 pop → 다음 항목 자동 표시
  - `state: List<DialogRequest>` — 큐 전체 노출 (app.dart가 첫 번째 항목만 렌더링)

- [FR-2] **DialogPriority 분류** — 4단계:
  - `critical`: 용병 사망·랭크업 → 즉시 인터럽트, barrierDismissible: false
  - `high`: 퀘스트 완료·변형 발동·체인 완주 → 도착 팝업 순서 내 우선
  - `medium`: 자동 이벤트·이동 선택지·건설 완료·조사 완료·체인 진행
  - `low`: (향후 확장) 현재는 사용하지 않음, 코드 상수만 정의

- [FR-3] **큐 persistence** — 앱 종료 후 복원을 위해 `PersistedDialogEntry`를 Hive `dialogQueue` 박스에 저장한다.
  - 앱 재실행 시 `enqueuedAt` 기준 24시간 이내 항목만 복원 (만료 항목은 삭제 + ActivityLog "알림 일부 유실됨" 기록)
  - 복원 실패(deserialize 오류) 시 큐 비움 + 동일 ActivityLog 기록
  - `PersistedDialogEntry` → typeId:13, HiveField 0-4 (id/priority/dialogType/payloadJson/enqueuedAt)
  - `dialogType: String` 값 → builder 팩터리 매핑 테이블(코드 상수) `DialogTypeRegistry`로 복원

- [FR-4] **app.dart 큐 렌더링** — `ref.listen(dialogQueueProvider)` 단일 채널로 통합한다.
  - `state.isNotEmpty` → `addPostFrameCallback`으로 `state.first` 팝업 표시
  - 팝업 확인(dismiss) 시 `dequeue()` 호출
  - 현재 팝업이 표시 중이면 새 항목이 들어와도 재표시 안 함 (`_isShowingDialog` 플래그)

- [FR-5] **기존 채널 마이그레이션** — 3개 독립 채널을 큐로 전환한다.
  - `constructionCompletedProvider` → medium priority enqueue (`ConstructionCompleteDialog`)
  - `investigationCompletedProvider` → medium priority enqueue (`InvestigationResultDialog`)
  - `reputationRankUpProvider` → **critical** priority enqueue (`RankUpOverlay`)
  - 기존 `app.dart`의 3개 `ref.listen` 블록 제거 → `dialogQueueProvider` 단일 listen으로 대체
  - 각 Provider의 `state → enqueue, state = null` 호출 위치: 해당 Notifier 내부(Provider 그대로 유지, app.dart listen만 변경)

- [FR-6] **이동 완료 팝업 큐 통합** — `home_screen.dart`의 이동 이벤트 팝업을 큐로 통합한다.
  - `lastTravelEventProvider` non-null → medium enqueue (`AutoTravelEventDialog`) → 확인 시 dequeue + `state = null`
  - `pendingTravelChoiceProvider`(Phase 4-5) non-null → medium enqueue (`TravelChoiceRecallDialog`) → 확인 시 dequeue + `state = null`
  - 팝업 순서 보장: `_completeMovement()` 내 enqueue 순서 = 자동 이벤트(먼저) → 선택지 회상(나중)

#### 파견 화면 5계층 정렬 (FR-7 ~ FR-8)

- [FR-7] **5계층 정렬 함수** — `QuestSortService.sort(quests, chainProgress, currentRegion, currentSector, regionState, questPools, joinedFactions)` 순수 정적 메서드.
  - Tier 0 (체인 다음 단계): 체인 상단 고정 섹션에 분리, 일반 목록에서 제거
  - Tier 1 (세력 전용): `quest.isFactionExclusive && joinedFactionIds.contains(quest.factionTag)`
  - Tier 2 (엘리트): `quest.isElite` → 유니크 먼저(isUnique), 보통 다음
  - Tier 3 (변형 섹터 전용): 해당 퀘스트의 QuestPool.sectorType != null && sectorType == currentSectorTransformType
  - Tier 4 (일반): 나머지
  - **같은 Tier 내**: `rewardGold` 내림차순 → `difficulty` 오름차순 → `id` 사전순

- [FR-8] **체인 상단 고정 섹션** — Tier 0 체인 카드를 `ChainTopSection` 위젯으로 별도 렌더링한다.
  - 최대 3장. 현재 리전 수행 가능 → 활성 카드 우선, 타 리전 필요 → 비활성 카드 후순위
  - 활성 카드: `Chain N/M` 배지 + 파견 시작 버튼 + 금색 2px 테두리 + 금색 사이드바
  - 비활성 카드: 반투명(opacity 0.6) + "📍 이동 필요" 안내 + "이동 화면으로" 버튼(currentTabProvider → 이동 탭) + 금색 사이드바
  - 0장이면 섹션 자체 생략 (SizedBox.shrink())
  - 섹션 하단 구분선(`Divider`) + "진행 중인 체인" 회색 라벨
  - 데이터 의존: `chainQuestProgressListProvider`(Phase 4-2), `staticData.chainQuests`(Phase 4-2)

#### 카드 시각 통합 규칙 (FR-9 ~ FR-11)

- [FR-9] **LayerSidebar 위젯** — 퀘스트 계층에 따른 좌측 3px 사이드바 색상을 결정한다.
  - 우선순위 fold (상위 계층이 우선):
    1. 체인 다음 단계 → `#d4af37` (금색)
    2. 엘리트 유니크 → `#7b1fa2` (진보라)
    3. 엘리트 보통 → `#e65100` (주황)
    4. 변형 섹터 hidden → `#b8860b` (어두운 금)
    5. 변형 섹터 ruins → `#6a1b9a` (보라)
    6. 변형 섹터 village → `#2e7d32` (녹색)
    7. 세력 전용 → `FactionData.parseColor(faction.color)`
    8. 일반 → `null` (사이드바 생략)
  - `Color? resolveColor(QuestLayerInfo info)` 메서드 반환

- [FR-10] **QuestCardBadges 위젯** — 4종 배지를 왼→오른쪽 순서로 렌더링한다.
  1. **체인 배지**: `[체인명 · N/M]` — `chainProgress != null`일 때
  2. **엘리트 배지**: 🔥(보통) / ★(유니크) — 기존 코드를 위젯으로 이동
  3. **변형 섹터 배지**: 🏘️(village) / 🏛️(ruins) / ✦(hidden) — `sectorType != null`일 때
  4. **세력 배지**: 세력 컬러 원형 + 세력명 — `factionTag != null`일 때 (세력명 6자 초과 시 앞 3자 + "…")
  - `QuestLayerInfo` 데이터 클래스 (runtime only, no Hive): 체인/엘리트/섹터/세력 정보 집약

- [FR-11] **_QuestCard 시각 통합** — 기존 `_QuestCard` 내 분산된 시각 코드를 `LayerSidebar` + `QuestCardBadges`로 교체한다.
  - 이름 색상: 체인 다음 단계 → `AppTheme.primary`, 엘리트 유니크 → `#c084fc`, 엘리트 보통 → `#fb923c`, 나머지 → 기본 `onSurface`
  - 테두리: 체인 → 2px `#d4af37`, 세력 전용 → 1.5px 세력 컬러, 중첩(체인+세력) → double border 허용, 기타 → `AppTheme.borderLight`
  - **QuestLayerInfo 생성**: `_QuestCard.build()`에서 staticData + chainProgress 조합하여 구성

- [FR-12] **이동 화면 체인 하이라이트** — `MovementScreen` 섹터 타일에 체인 다음 단계 리전/섹터를 금색으로 강조한다.
  - 체인의 `target_region_id`/`target_sector_id`(Phase 4-2 스키마)가 현재 선택 가능 리전과 일치하면 해당 타일 테두리 `#d4af37` 2px + "체인" 마이크로 배지
  - 변형 섹터 × 체인 중첩 시: 체인 금색 우선, 변형 아이콘은 타일 내 별도 표시

#### ActivityLogType 아이콘 (FR-13)

- [FR-13] **ActivityLog UI 아이콘 매핑** — M3 신규 4개 ActivityLogType에 아이콘/색상을 정의한다.
  - `regionTransform` (HiveField 18): 🗺️, 색상 `#b8860b`
  - `chainProgressed` (HiveField 19): ⛓️, 색상 `AppTheme.primary`
  - `chainCompleted` (HiveField 20): ⛓️ (굵게 + 금색), 색상 `#d4af37`
  - `travelChoiceCompleted` (HiveField 21): 🛤️, 색상 `AppTheme.textSecondary`
  - 적용 위치: ActivityLog 목록을 렌더링하는 위젯의 `_iconForType()` 분기 확장

### 2.2 데이터 요구사항

#### 신규 Hive 모델

```dart
@HiveType(typeId: 13)
class PersistedDialogEntry extends HiveObject {
  @HiveField(0) String id;              // 중복 방지용 고유 id
  @HiveField(1) int priority;           // DialogPriority.index
  @HiveField(2) String dialogType;      // DialogTypeRegistry 키
  @HiveField(3) String payloadJson;     // payload를 JSON 직렬화
  @HiveField(4) DateTime enqueuedAt;    // 24h 만료 기준
}
```

#### 신규 Hive 박스

- `dialogQueue` 박스 (9번째): `PersistedDialogEntry` 목록 저장. `HiveInitializer`에 등록.

#### 런타임 전용 클래스 (Hive 불필요)

```dart
enum DialogPriority { critical, high, medium, low }

class DialogRequest {
  final String id;
  final DialogPriority priority;
  final Widget Function(BuildContext context, VoidCallback onDismiss) builder;
  final String dialogType;     // persistence 복원용
  final dynamic payload;       // json 직렬화 가능한 payload
}

class QuestLayerInfo {
  final ChainQuestInfo? chain;      // chainName, currentStep, totalSteps, isActive
  final bool isElite;
  final bool isUnique;
  final String? sectorType;         // village/ruins/hidden/null
  final FactionData? faction;
  final bool isFactionExclusive;
}
```

#### DialogTypeRegistry (코드 상수)

```dart
static const Map<String, Widget Function(BuildContext, VoidCallback, dynamic)> _registry = {
  'constructionComplete': _buildConstructionDialog,
  'investigationResult': _buildInvestigationDialog,
  'rankUp': _buildRankUpDialog,
  'autoTravelEvent': _buildAutoEventDialog,
  'travelChoiceRecall': _buildChoiceRecallDialog,
  'chainProgress': _buildChainProgressDialog,
  'regionTransform': _buildTransformDialog,
};
```

#### HiveType 할당 요약 (Phase 4-6 확인)

| typeId | 모델 | Phase |
|--------|------|-------|
| 11 | ChainQuestProgress | 4-2 |
| 12 | ChainQuestStatus | 4-2 |
| **13** | **PersistedDialogEntry** | **4-6 신규** |

### 2.3 UI 요구사항

- **ChainTopSection 위젯 진입 조건**: `chainQuestProgressListProvider` 비어 있지 않을 때 파견 화면 상단에 삽입
- **위젯 계층**:
  ```
  DispatchScreen
  ├── ChainTopSection (0~3 ChainQuestCard)
  │   ├── 구분선 + "진행 중인 체인" 라벨
  │   └── Column: 체인 카드 (금색 테두리, LayerSidebar, 활성/비활성)
  └── ListView: pending 퀘스트 (QuestSortService.sort 결과)
      └── _QuestCard (LayerSidebar + QuestCardBadges 통합)
  ```
- **상태 변수**: `DispatchScreen._selectedQuestId: String?` (기존 `isSelected` 로직 유지)
- **화면 전환**: 기존 `DispatchDetailPage` 상태 기반 렌더링 유지

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/app.dart` | 3개 독립 ref.listen 제거 → dialogQueueProvider 단일 listen + `_isShowingDialog` 플래그 | FR-4, FR-5 |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | `PersistedDialogEntry` 어댑터 등록 + `dialogQueue` 박스 open | FR-3 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `QuestSortService` 적용, `ChainTopSection` 삽입, `_QuestCard` 시각 `LayerSidebar`+`QuestCardBadges` 교체 | FR-7~FR-11 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | 섹터 타일 `_buildSectorTile()` 추출 + 체인 하이라이트 조건부 금색 테두리 | FR-12 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | `lastTravelEventProvider` / `pendingTravelChoiceProvider` listen → dialogQueueProvider.enqueue() 변경 | FR-6 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | ActivityLog 렌더링 위젯의 `_iconForType()` 분기에 4종 추가 (또는 ActivityLog 뷰 파일) | FR-13 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | `DialogQueueNotifier` StateNotifier + `dialogQueueProvider` + `DialogTypeRegistry` |
| `band_of_mercenaries/lib/core/models/dialog_request.dart` | `DialogRequest` 클래스 + `DialogPriority` enum + `QuestLayerInfo` 클래스 |
| `band_of_mercenaries/lib/core/models/persisted_dialog_entry.dart` | `PersistedDialogEntry` Hive 모델 |
| `band_of_mercenaries/lib/core/data/dialog_queue_persistence.dart` | `DialogQueuePersistence` — Hive `dialogQueue` 박스 저장/복원/만료 처리 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | `QuestSortService.sort()` 순수 정적 함수 |
| `band_of_mercenaries/lib/features/quest/view/chain_top_section.dart` | `ChainTopSection` + `ChainQuestCard` 위젯 |
| `band_of_mercenaries/lib/shared/widgets/layer_sidebar.dart` | `LayerSidebar` 위젯 + `LayerSidebarResolver.resolveColor()` |
| `band_of_mercenaries/lib/shared/widgets/quest_card_badges.dart` | `QuestCardBadges` 위젯 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `lib/core/models/persisted_dialog_entry.dart` | HiveType(typeId: 13) → hive_generator |

### 3.4 관련 시스템

- **Phase 4-2 (체인 퀘스트)**: `chainQuestProgressListProvider`, `staticData.chainQuests` — Tier 0 정렬 + ChainTopSection 데이터 의존. Phase 4-2 미구현 시 `chainQuestProgressListProvider = []` stub으로 ChainTopSection 생략
- **Phase 4-3 (지역 변형)**: `RegionState.sectorChanges` — Tier 3 정렬 조건. 미구현 시 빈 Map으로 Tier 3 = 없음
- **Phase 4-5 (이동 선택지)**: `pendingTravelChoiceProvider` — FR-6 큐 통합 의존
- **기존 팝업 Provider**: `constructionCompletedProvider`, `investigationCompletedProvider`, `reputationRankUpProvider` — Provider 자체는 유지, app.dart listen만 변경
- **FactionStateRepository**: `getJoinedFactionIds()` — Tier 1 정렬 조건

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `lib/features/quest/view/dispatch_screen.dart` `_QuestCard` (L325-540): 기존 사이드바/배지/테두리 코드 → `LayerSidebar`/`QuestCardBadges`로 추출·대체
- `lib/core/providers/reputation_rank_up_provider.dart`: StateProvider 기반 이벤트 채널 — DialogQueueNotifier enqueue 흐름의 모델
- `lib/features/quest/domain/quest_provider.dart` `pendingEliteLootProvider`: Map 기반 pending 패턴 참조

### 4.2 주의사항

- **Builder 클로저 불직렬화**: `DialogRequest.builder`는 Hive 저장 불가. `PersistedDialogEntry`는 `dialogType` + `payloadJson`만 저장, `DialogTypeRegistry`가 재구성. payload는 `jsonEncode`/`jsonDecode` 가능한 타입만(Map<String, dynamic>).
- **`_isShowingDialog` 플래그**: 큐에 항목이 있어도 현재 팝업 중이면 새 listen 콜백이 중복 `showDialog` 하지 않도록 `app.dart`에 bool 플래그 유지. 팝업 dismiss 콜백에서 `dequeue()` + `_isShowingDialog = false`.
- **ActivityLogType 수정 금지 규칙**: HiveField 15~17은 M2a essenceApplied/Lost 점유. M3 신규 HiveField는 18(regionTransform)/19(chainProgressed)/20(chainCompleted)/21(travelChoiceCompleted). 기획서 §10의 HiveField 15~18은 **오류** — spec에서 수정값 18~21로 구현.
- **QuestPool.sectorType**: `ActiveQuest.questPoolId`로 StaticGameData.questPools에서 lookup. 매 정렬마다 O(n)이므로 `Map<String, QuestPool>` 인덱스를 정렬 전 1회 구성.
- **변형 섹터 Tier 3 판별**: `RegionState.sectorChanges[currentSector.toString()]` 값이 non-null이고, 해당 quest의 pool.sectorType == 그 값이면 Tier 3.
- **체인 카드 3장 상한**: `chainQuestProgressListProvider` 목록에서 현재 리전 활성 우선 정렬 후 최대 3개. 4개 이상이면 나머지는 표시 안 함.
- **CLAUDE.md UI 제약**: 새 화면은 상태 기반 렌더링. `ChainTopSection`은 `DispatchScreen` 내부 Column에 조건부 삽입 (Navigator 사용 안 함).
- **세력명 overflow**: 6자 초과 시 `faction.name.substring(0, 3) + '…'` (Q-2 확정 규칙).

### 4.3 엣지 케이스

- **큐 비어 있을 때 dequeue()**: 무시 (List empty guard)
- **동일 id 중복 enqueue**: 기존 항목 유지, 신규 무시 (dedup by id)
- **persistence 복원 중 dialogType 미등록**: 해당 항목 skip + ActivityLog "알림 유실"
- **ChainTopSection: 활성 0장 + 비활성 1장**: 비활성 카드 1장 표시 (0장이 아님)
- **변형 섹터 × 체인 중첩**: Tier 0 우선 → ChainTopSection에 표시, 일반 목록 미포함
- **빌드 시 Phase 4-2 미구현**: `chainQuestProgressListProvider` 존재하지 않으면 empty list 반환하는 stub provider를 `quest_sort_service.dart`에 정의 (추후 Phase 4-2 구현 시 교체)
- **priority = critical 팝업 복원**: 24h 만료 전이라도 critical은 앱 재시작 시 반드시 표시. 랭크업은 이미 지나간 상태이므로 복원 시 RankUpOverlay 재표시는 OK.

### 4.4 구현 힌트

- **진입점**: `app.dart` `ref.listen(dialogQueueProvider)` — 큐 변화마다 호출, `state.isNotEmpty && !_isShowingDialog`일 때 `state.first.builder(context, () { dequeue(); _isShowingDialog = false; })` 호출
- **데이터 흐름**:
  ```
  Notifier.completeX() 또는 _completeMovement()
    → dialogQueueProvider.notifier.enqueue(DialogRequest(...))
    → DialogQueuePersistence.save(PersistedDialogEntry(...))
  
  app.dart ref.listen
    → queue.first.builder(ctx, onDismiss) → showDialog
    → 확인 클릭 → onDismiss → dequeue() → DialogQueuePersistence.remove(id) → _isShowingDialog = false
    → 다음 항목 자동 처리
  
  앱 재실행
    → DialogQueuePersistence.loadAndClean(24h)
    → DialogQueueNotifier 초기화 시 복원된 항목 enqueue
  ```
- **QuestSortService 데이터 흐름**:
  ```
  DispatchScreen.build()
    → ref.watch(questListProvider) + ref.watch(chainProgressProvider)
      + ref.watch(userDataProvider) + ref.watch(regionStateProvider)
    → QuestSortService.sort(...)
    → chainQuests(Tier 0) → ChainTopSection
    → rest(Tier 1~4) → ListView
  ```
- **참조 구현**:
  - `dispatch_screen.dart` L93-94: 기존 상태 필터 → sort 함수로 교체
  - `dispatch_screen.dart` L325-540 `_QuestCard`: LayerSidebar + QuestCardBadges 추출 참조
  - `app.dart` L139-204: 3개 독립 listen 블록 → 1개로 통합

## 5. 기획 확인 사항

- [Q-1] 체인 상단 고정 최대 3장 — 기획 §4-3 확정. → **FR-8 적용**
- [Q-2] 세력명 축약 규칙 — 6자 초과 시 3자+"…". → **FR-10 적용**
- [Q-4] 큐 persistence 만료 24시간 — 기획 §Q-4 권장안 채택. → **FR-3 적용**
- [Q-6] 변형 ruins vs 엘리트 유니크 보라 유사 — 기획 §Q-6 권장 `#5e35b1` 재조정 미확정 → **MVP는 기획 §2-1 원안 `#6a1b9a` 유지**, 운영 피드백 후 조정
- [Q-10] persistence 복원 실패 처리 — 큐 비움 + ActivityLog 기록 → **FR-3 적용**
- [C-1] 기획서 §10 ActivityLogType HiveField 15~18 → **실제 코드상 M2a가 15~17 점유. 본 spec에서 18~21로 수정 적용** (기획 오류 수정)
- [C-2] 기획서 §5-1 "8단계 순서"에서 Phase 4-5는 `TravelChoiceRecallDialog`(매체 priority enqueue). 순서는 enqueue 타이밍으로 보장 — `_completeMovement()`에서 ①자동 이벤트 ②선택지 회상 순으로 enqueue → FIFO로 자동 순서 유지.
