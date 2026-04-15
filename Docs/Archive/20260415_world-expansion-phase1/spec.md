# 세계 확장 Phase 1 — 지역 조사 시스템 개발 명세서

> 기획 문서: Docs/content-design/20260413_world_expansion_system.md (§1 지역 상태 시스템, §2 지역 조사 메커니즘)
> 작성일: 2026-04-15

---

## 1. 개요

199개 리전에 유저별 `RegionState`(지역 상태)를 부여하고, 용병 1명을 파견과 독립된 "지역 조사" 행동에 배치하여 지식 포인트를 누적하는 시스템을 구현한다. 지식이 임계값에 도달하면 Supabase의 `region_discoveries` 테이블에 기획자가 사전 배치한 발견 이벤트가 트리거되어 팝업으로 전달되고 활동 로그에 기록된다. Phase 2~6의 모든 세계 확장 기능이 이 Phase 1의 RegionState와 region_discoveries 파이프라인 위에서 동작한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 지역 조사 시작**
  - 조건: 파견 중 용병 없음(이동 제한 없음), 현재 위치 리전에 `region_discoveries` 데이터 1건 이상 존재, 조사 슬롯 비어있음
  - 동작: 용병 1명 선택(정상/피곤함 상태, 파견 중·조사 중 아님) → `UserData.investigatingMercId`, `investigationEndTime`, `investigationRegionId` 저장
  - 조사 시간(티어별): T1=5분, T2=8분, T3=10분, T4=15분, T5=20분
  - UI: 홈 화면 조사 위젯 내 "조사 시작" 버튼 → 용병 선택 모달

- **[FR-2] 조사 완료 처리 (gameTickProvider 기반 자동)**
  - 성공률: `85% + (merc.effectiveAgi + merc.effectiveVit) / 200`
  - **성공 시**: `RegionState.knowledge += 티어별 획득량` (T1:+10, T2:+8, T3:+6, T4:+5, T5:+4, 상한 100)
    - 지식 임계값 도달 체크 → `region_discoveries` 조회 → 미트리거 발견 이벤트 일괄 트리거
    - `RegionState.triggeredDiscoveries`에 트리거된 ID 추가
  - **실패 시**: 지식 획득 없음. 티어별 확률로 용병 부상(T1:0%, T2:5%, T3:10%, T4:20%, T5:30%)
  - 완료 후 UserData 조사 필드 3종 초기화, `investigationCompletedProvider`에 결과 설정
  - 활동 로그 기록 (성공/실패/발견 이벤트)

- **[FR-3] 발견 이벤트 처리 (Phase 1 범위)**
  - 트리거된 발견 이벤트: 모든 타입(`info`/`elite`/`hidden_quest`/`faction_clue`/`transform`)에 대해 `description` 텍스트를 팝업으로 표시
  - 실제 게임 효과(엘리트 출현, 숨겨진 퀘스트 생성 등)는 Phase 3/4에서 구현 — Phase 1에서는 발견 사실 기록만 수행
  - `RegionState.triggeredDiscoveries`에 기록 → 동일 발견이 재트리거되지 않음

- **[FR-4] 이동 시 조사 중단**
  - `MovementNotifier.startMovement()` 진입 시 조사 중이면 자동 중단
  - `UserData` 조사 필드 3종 초기화 (지식은 `RegionState`에 보존)
  - 별도 팝업 없이 조용히 중단, 활동 로그 미기록

- **[FR-5] 파견/조사 상호 배타**
  - 조사 중인 용병은 퀘스트 파견 불가 → `dispatch_detail_page.dart`의 `availableMercs` 필터에 `investigatingMercId` 제외 조건 추가
  - 파견 중인 용병은 조사 배치 불가 → 조사 시작 모달의 용병 목록에서 `isDispatched == true` 제외

- **[FR-6] RegionState 영속성**
  - Hive `regionStates` 박스 신설 (`Box<RegionState>`)
  - 키: `regionId` (int)
  - 유저가 조사를 처음 시작하는 리전에만 엔트리 생성 (방문만으로는 생성 안 함)

- **[FR-7] region_discoveries 정적 데이터 동기화**
  - Supabase `region_discoveries` 테이블 추가 (별도 Supabase 작업 필요)
  - `SyncService.allTables`에 추가 → 기존 버전 비교 + 변경 시 다운로드 파이프라인에 자동 편입
  - `StaticGameData.regionDiscoveries: List<RegionDiscoveryData>` 추가

- **[FR-8] 홈 화면 조사 위젯**
  - 현재 위치 리전에 `region_discoveries` 데이터 없으면 위젯 숨김 (섹션 자체 미표시)
  - 조사 중: 용병명, 잔여 시간, 지식 진행도 바(현재 knowledge + 완료 후 예상치)
  - 조사 미중 + knowledge < 100: "지역 조사 시작" 버튼 + 현재 지식 레벨 표시
  - 조사 미중 + knowledge == 100: "이 지역의 모든 발견 완료" 상태 표시
  - 위치: HomeScreen의 Construction mini widget(line 257-329) 바로 아래, Dashboard(line 331) 위

### 2.2 데이터 요구사항

**신규 Hive 모델 (RegionState)**
```
박스명: regionStates
타입: Box<RegionState>
키: regionId (int)

RegionState {
  @HiveField(0) int regionId
  @HiveField(1) int knowledge         // 0~100
  @HiveField(2) List<String> triggeredDiscoveries  // 트리거된 discovery ID 목록
}
```

**UserData 신규 HiveField**
```
@HiveField(15) String? investigatingMercId
@HiveField(16) DateTime? investigationEndTime
@HiveField(17) int? investigationRegionId
```

**신규 정적 데이터 모델 (RegionDiscoveryData)**
```
Supabase 테이블: region_discoveries
Dart 모델: RegionDiscoveryData (freezed + json_serializable)

{
  id: String
  regionId: int            @JsonKey(name: 'region_id')
  knowledgeThreshold: int  @JsonKey(name: 'knowledge_threshold')
  discoveryType: String    @JsonKey(name: 'discovery_type')  // info|elite|hidden_quest|faction_clue|transform
  discoveryData: Map<String, dynamic>?  @JsonKey(name: 'discovery_data')
  description: String
}
```

**완료 결과 모델 (DTO, Hive 미사용)**
```
InvestigationResult {
  bool success
  int regionId
  int knowledgeGained
  int currentKnowledge
  List<String> newDiscoveryIds  // 이번 완료에서 새로 트리거된 ID
  bool mercInjured
  String mercId
}
```

**밸런스 수치**
```
지식 획득량: T1=+10, T2=+8, T3=+6, T4=+5, T5=+4
조사 시간: T1=5분, T2=8분, T3=10분, T4=15분, T5=20분
기본 성공률: 85% + (agi + vit) / 200
실패 시 부상 확률: T1=0%, T2=5%, T3=10%, T4=20%, T5=30%
```

### 2.3 UI 요구사항

- **InvestigationWidget** (홈 화면 삽입 위젯)
  - Construction mini widget과 동일한 시각적 스타일 (Container, border, progress bar)
  - 색상 테마: `AppTheme.tier2` (초록 — 탐색/정보의 뉘앙스)
  - 조사 시작 버튼 탭 → 용병 선택 모달(BottomSheet) 표시

- **용병 선택 모달**
  - 선택 가능 용병 목록: `status != dead`, `!isDispatched`, `merc.id != investigatingMercId`
  - 각 용병 카드: 이름, 직업, AGI/VIT 수치, 예상 성공률(%)
  - 용병 탭 → 즉시 조사 시작 (별도 확인 버튼 없음)

- **InvestigationResultDialog**
  - 성공 + 발견 없음: "조사 완료 — 지식 +N (현재 M/100)"
  - 성공 + 발견 있음: 발견 이벤트 description 텍스트 (한 화면에 복수 표시 가능)
  - 실패 + 부상: "조사 실패 — [용병명]이(가) 부상당했습니다"
  - 실패 + 부상 없음: "조사 실패 — 지식 미획득"

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField(15-17) 추가 (investigatingMercId, investigationEndTime, investigationRegionId) | 조사 상태를 UserData에 저장 (건설 큐 패턴 동일) |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | RegionStateAdapter 등록 + regionStates 박스 오픈 | 새 Hive 박스 추가 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 `'region_discoveries'` 추가 | Supabase 동기화 대상 추가 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `StaticGameData`에 `regionDiscoveries` 필드 추가, `loadFromCache` 호출 추가 | 정적 데이터 모델 통합 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | InvestigationWidget 삽입 (line 329 이후) | 홈 화면 조사 섹션 |
| `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart` | `startMovement()` 내 조사 중단 로직 추가 | 이동 시 조사 자동 중단 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | `availableMercs` 필터에 `investigatingMercId` 제외 조건 추가 (line 45-47) | 조사 중 용병 파견 불가 |
| `band_of_mercenaries/lib/app.dart` | gameTickProvider listener에 `investigationNotifier.checkCompletion()` 추가, `investigationCompletedProvider` listener 추가 (line 127-129 패턴) | 완료 자동 체크 + 결과 팝업 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | RegionState Hive 모델 (typeId: 8) |
| `band_of_mercenaries/lib/features/investigation/domain/region_discovery_data.dart` | RegionDiscoveryData 정적 데이터 모델 (freezed + json_serializable) |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_result.dart` | InvestigationResult DTO (순수 Dart, Hive 미사용) |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_service.dart` | 성공률 계산, 지식 획득량, 부상 판정 등 순수 static 메서드 모음 |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart` | InvestigationNotifier (StateNotifier) — 조사 시작/완료/중단 비즈니스 로직, gameTickProvider listen |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_completion_provider.dart` | `investigationCompletedProvider: StateProvider<InvestigationResult?>` — 완료 알림용 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | RegionStateRepository — regionStates Hive 박스 CRUD |
| `band_of_mercenaries/lib/features/investigation/view/investigation_widget.dart` | InvestigationWidget (홈 삽입 위젯) + InvestigationResultDialog + 용병 선택 모달 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `features/investigation/domain/region_state_model.dart` | hive_generator (`@HiveType`, `@HiveField`) |
| `features/investigation/domain/region_discovery_data.dart` | freezed + json_serializable |
| `core/models/user_data.dart` | hive_generator (새 필드 3개 추가) |

### 3.4 관련 시스템

- **UserDataNotifier**: 조사 필드 3종 관리 (start/cancel은 InvestigationNotifier가 직접 UserData를 write)
- **MercenaryNotifier**: 부상 적용 시 `mercenaryProvider.notifier`를 통해 상태 갱신
- **QuestProvider**: 간접 영향 없음. dispatch_detail_page.dart에서 UI 필터만 수정
- **MovementNotifier**: `startMovement()` 내에서 investigationNotifierProvider를 읽어 cancel 호출
- **ActivityLogProvider**: 조사 완료/발견 이벤트 로그 기록
- **staticDataProvider**: regionDiscoveries 리스트 추가 (자동으로 `ref.invalidate` 대상에 포함)

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `core/providers/game_state_provider.dart:116-175` — UserData에 3개 필드로 진행 중 작업 추적 + 완료 처리 패턴. `startConstruction → completeConstruction → cancelConstruction` 구조를 그대로 차용
- `app.dart:127-129` — gameTickProvider listen → notifier 메서드 직접 호출 패턴
- `app.dart:131-158` — `constructionCompletedProvider` listen → 팝업 표시 + 활동 로그 패턴 (investigationCompletedProvider에 동일 패턴 적용)
- `features/home/view/home_screen.dart:257-329` — Construction mini widget UI 구조 (InvestigationWidget 디자인 기준)
- `features/quest/view/dispatch_detail_page.dart:44-47` — `availableMercs` 필터 위치

### 4.2 주의사항

- **UserData HiveField 번호**: 현재 최고 번호 14 (`constructionEndTime`). 신규 필드는 반드시 15, 16, 17 순서로 추가. 번호 충돌 시 기존 유저 데이터 파괴
- **RegionState typeId**: 현재 사용 중인 typeId 0~7. RegionState는 반드시 typeId **8** 사용
- **중복 완료 방지**: InvestigationNotifier 내에 `_isCompleting: bool` 플래그 필수 (construction과 동일)
- **이동 후 조사 중단**: `MovementNotifier.startMovement()`에서 `ref.read(investigationNotifierProvider.notifier).cancelInvestigation()` 호출. 이 시점에 지식은 이미 RegionState에 저장된 값이므로 별도 보존 로직 불필요 — 단, 진행 중 획득 예정이었던 지식은 소멸(설계 의도)
- **발견 이벤트 타입별 Phase 1 처리**: `elite`, `hidden_quest`, `faction_clue`, `transform` 타입이 트리거되어도 Phase 1에서는 description 팝업만 표시. `RegionState.triggeredDiscoveries`에 ID를 기록함으로써 Phase 3/4/6에서 효과를 사후 연동 가능하도록 설계
- **regionDiscoveries가 없는 리전**: `staticData.regionDiscoveries.where((d) => d.regionId == currentRegionId).isEmpty`이면 InvestigationWidget 자체를 숨김 (SizedBox.shrink 반환)

### 4.3 엣지 케이스

- **앱 재시작 시 진행 중 조사 복구**: InvestigationNotifier 생성 시 `UserData.investigatingMercId != null && investigationEndTime != null`이면 이미 완료됐는지 체크 → 완료 시 즉시 `checkCompletion()` 호출 (건설의 `_checkPastConstruction()` 패턴 동일)
- **용병 부상/사망 중 조사**: 조사 완료 처리 시 용병이 외부 요인(여행 이벤트 등)으로 이미 부상/사망 상태이면 추가 부상 적용 스킵
- **knowledge = 100 도달 후 반복 조사**: 기획서에 "반복 배치 가능"이라고 명시되어 있지 않음. knowledge 100 도달 시 조사 위젯에 "모든 발견 완료" 표시 후 조사 시작 버튼 비활성화 처리
- **region_discoveries 미배포 상태**: `staticData.regionDiscoveries`가 비어있어도 InvestigationWidget 자체를 숨기므로 오류 없음
- **조사 성공률이 100%를 초과하는 경우**: `(85.0 + (agi + vit) / 200.0).clamp(5.0, 95.0)`으로 상한 처리 (기존 성공률 계산 패턴과 동일)

### 4.4 구현 힌트

- **진입점**: `HomeScreen` → `InvestigationWidget` → `investigationNotifierProvider.notifier.startInvestigation()`
- **데이터 흐름 (완료 시)**: `gameTickProvider (app.dart) → investigationNotifier.checkCompletion() → InvestigationService.calculateResult() → RegionStateRepository.updateKnowledge() → mercenaryProvider.notifier.applyInjury() → userDataProvider.notifier.clearInvestigation() → investigationCompletedProvider.state = result → app.dart listener → InvestigationResultDialog`
- **참조 구현**: `game_state_provider.dart:116-175` — startConstruction/completeConstruction 전체 패턴 (3개 필드 start → clear 흐름)
- **참조 구현**: `app.dart:127-158` — gameTickProvider listen + completedProvider listen + showDialog 패턴
- **확장 지점**: `InvestigationService.calculateResult()`의 반환값에 `newDiscoveryIds`를 포함시켜 Phase 3/4/6에서 타입별 분기 처리를 붙일 수 있음

---

## 5. Supabase 작업 (Flutter 구현과 병행)

- `region_discoveries` 테이블 생성 (컬럼: id, region_id, knowledge_threshold, discovery_type, discovery_data JSONB, description)
- `data_versions` 테이블에 `region_discoveries` 행 추가 (version: 1)
- 테스트용 발견 데이터 최소 1개 삽입 (검증용)

---

## 6. 기획 확인 사항

- [Q-1] 조사 실패 시 부상 확률 → **확인 완료**: 보수적 안 적용 (T1:0%, T2:5%, T3:10%, T4:20%, T5:30%)
- [Q-2] 성공률 스탯 보정 공식 → **확인 완료**: `85% + (agi + vit) / 200` 적용, `.clamp(5.0, 95.0)` 처리
- [Q-3] knowledge 100 도달 후 재조사 가능 여부 → **미확인**: 기획서에 명시 없음. Phase 1에서는 100 도달 시 조사 종료(버튼 비활성화)로 처리. 재조사가 필요한 경우(Phase 이후 콘텐츠 갱신 목적) 별도 기획 요청
