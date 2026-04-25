# 이동 선택지 시스템 개발 명세서

> 기획 문서: Docs/content-design/[content]20260424_travel_choices.md
> 밸런스 문서: Docs/balance-design/[balance]20260424_travel_choice_ev.md
> 작성일: 2026-04-25
> 선행 spec: [spec]20260424_template-engine.md (Phase 4-1), [spec]20260424_region-transform-system.md (Phase 4-3)

## 1. 개요

이동 완료 시점에 "오는 길에 이런 일이 있었소" 형식의 회상 팝업을 표시하고, 플레이어가 2~3개 선택지 중 하나를 고르면 결과 서사와 효과가 적용된다. 기존 자동 이벤트(`travel_events` 12종)와 독립된 별도 롤로 동작하며, 선택지 조건(visibility_expr)·결과 분기(conditional_expr)를 TemplateEngine으로 평가한다. 선택지 이벤트 ID는 UserData HiveField(21)에 저장하여 앱 재시작 시에도 보존된다.

## 2. 요구사항

### 2.1 기능 요구사항

- [FR-1] **rollChoiceEvent** — 이동 시작 시 자동 이벤트 롤과 독립적으로 선택지 이벤트를 롤한다.
  - 발동 확률: `(distance × 계수).clamp(0.0, 0.30)` (계수: T1~2=0.08 / T3~4=0.10 / T5=0.12)
  - `rosterIdle.isEmpty` → `null` 반환, 선택지 이벤트 미발동
  - tier 범위 필터(`min_tier ≤ regionTier ≤ max_tier`) 후 weight 기반 가중 랜덤 선택
  - 선택된 이벤트 ID를 `UserData.choiceEventId`(HiveField 21)에 저장

- [FR-2] **selectProtagonist** — 회상 팝업의 `{merc.*}` 바인딩 대상 용병을 결정한다.
  - `event.preferredTraits` 쉼표 분리 → `rosterIdle` 중 보유자 우선 (최고 레벨, 동률 시 id lexical)
  - 매칭 없으면 `rosterIdle` 중 최고 레벨 fallback

- [FR-3] **선택지 visibility_expr 평가 (team scope)** — 팝업 1단계에서 각 선택지의 `visibilityExpr`을 평가한다.
  - `evaluationScope: EvaluationScope.team` 으로 TemplateEngine.evaluate() 호출
  - `rosterForTeam` 파라미터에 전체 idle 로스터 전달
  - 조건 미충족 선택지는 목록에서 제외 (회색 표시 없음 — 완전 숨김)
  - `visibilityExpr == null` → 항상 표시

- [FR-4] **resolveResult** — 선택지 클릭 시 결과를 결정한다.
  - `conditional_expr` 있는 결과: `evaluationScope: EvaluationScope.mercenary` + protagonist 컨텍스트로 평가 → 탈락하면 후보에서 제외
  - 남은 후보의 `probability` 합으로 재정규화
  - 재정규화된 확률로 가중 랜덤 선택
  - 탈락 후 후보 0개 → fallback `{narrative: "{merc.name}은 아무 일 없이 돌아왔다.", effectType: "nothing"}` 코드 상수 반환

- [FR-5] **applyEffect** — 결과의 effect_type에 따라 8종 효과를 적용한다.
  - `gold`: `UserDataNotifier.addGold(effectMagnitude.toInt())`
  - `reputation`: `UserDataNotifier.addReputation(effectMagnitude.toInt())`
  - `injury`: protagonist에게 부상 적용 (`MercenaryRepository.setInjured(protagonist.id)`)
  - `heal_tired`: magnitude > 0 → protagonist 피로 회복 / magnitude < 0 → protagonist 피로 부여
  - `trait_innate`: 기존 `_applyEventEffect`의 `trait_innate` 경로 재사용 (protagonist 대상)
  - `trait_acquired`: `protagonist.traitLearningBoostUntil = DateTime.now().add(24h)` 저장 (Phase 4-3 공유 필드)
  - `item`: `ItemService.addItem(effectTarget, quantity: effectMagnitude.toInt())` (M2a 인프라)
  - `nothing`: no-op

- [FR-6] **TravelChoiceRecallDialog** — 2단계 팝업 UI
  - 1단계: situation 렌더 결과 + 선택지 버튼 목록 (2개면 가로 배치, 3개면 세로 — hidden은 하단 `✦` 아이콘)
  - 2단계: result narrative 렌더 결과 + 효과 요약 (gold/rep/etc) + "확인" 버튼
  - 확인 클릭 → `pendingTravelChoiceProvider.state = null` 리셋

- [FR-7] **이동 완료 연동** — `_completeMovement()`에서 `choiceEventId != null` 이면 팝업을 트리거한다.
  - StaticGameData에서 이벤트·선택지·결과 조회
  - protagonist 결정
  - `pendingTravelChoiceProvider` 에 `TravelChoiceRecallData` 설정
  - `UserData.choiceEventId = null` 저장 (팝업 중복 방지)

- [FR-8] **활동 로그** — 선택지 완료 시 단일 1줄 요약 엔트리를 기록한다.
  - 형식: `"길에서 {event.name} — [{option.label}] → {effect_summary}"`
  - effect_summary: "명성 +10" / "유물 획득" / "부상" / "아무 일 없음" 등 간결한 한국어
  - `ActivityLogType.travelChoiceCompleted` (HiveField 21)

### 2.2 데이터 요구사항

#### Supabase 정적 데이터 (3테이블, 114행 — Phase 3에서 이미 삽입 완료)

- **`travel_choice_events`** (12행): id, name, category, situation, min_tier, max_tier, weight, preferred_traits
- **`travel_choice_options`** (30행): id, event_id, choice_index, label, visibility_expr, description, risk_level
- **`travel_choice_results`** (72행): id, option_id, result_index, probability, conditional_expr, narrative, effect_type, effect_magnitude, effect_target

#### StaticGameData 신규 필드 (3개)

```dart
final List<TravelChoiceEventData> travelChoiceEvents;
final List<TravelChoiceOptionData> travelChoiceOptions;
final List<TravelChoiceResultData> travelChoiceResults;
```

#### SyncService 신규 테이블 (3개)

```dart
'travel_choice_events',
'travel_choice_options',
'travel_choice_results',
```

#### UserData Hive 필드 추가

```dart
@HiveField(20)
List<String> completedChains;  // Phase 4-2 점유 — 수정 금지

@HiveField(21)
String? choiceEventId;          // Phase 4-5 신규 — 이동 중 선택지 이벤트 ID 보존
```

#### Mercenary Hive 필드 추가 (Phase 4-3과 공유)

```dart
@HiveField(23)
DateTime? traitLearningBoostUntil;  // trait_acquired 효과 만료 시각
```

#### ActivityLogType 신규 열거값

```dart
@HiveField(18)
regionTransform,        // Phase 4-3 점유

@HiveField(19)
chainProgressed,        // Phase 4-2 점유

@HiveField(20)
chainCompleted,         // Phase 4-2 점유

@HiveField(21)
travelChoiceCompleted,  // Phase 4-5 신규
```

#### 밸런스 수치 (코드 상수)

```dart
// TravelChoiceService 내 상수
static const _probCapBase = 0.30;
static const _coeffByTier = {1: 0.08, 2: 0.08, 3: 0.10, 4: 0.10, 5: 0.12};
static const _traitLearningBoostDuration = Duration(hours: 24);
static const _traitLearningBoostMultiplier = 1.5;
```

### 2.3 UI 요구사항

- **화면 진입 조건**: `pendingTravelChoiceProvider` non-null 감지 시 `home_screen.dart`의 `ref.listen`이 `TravelChoiceRecallDialog`를 `showDialog(barrierDismissible: false)`로 표시
- **위젯 계층**:
  ```
  TravelChoiceRecallDialog (StatefulWidget)
  └─ AlertDialog
     ├─ 1단계: Column
     │   ├─ Text(renderedSituation)   // TemplateEngine.render 결과
     │   ├─ SizedBox(height: 16)
     │   └─ _buildOptionButtons()
     │       ├─ safe/risky: Row(2개 ElevatedButton)
     │       └─ hidden(있으면): 세로 배치 OutlinedButton with ✦ prefix icon
     └─ 2단계: Column
         ├─ Text(renderedNarrative)
         ├─ _EffectSummaryRow(result)  // gold/rep/etc 아이콘+수치
         └─ ElevatedButton("확인", onPressed: onDismiss)
  ```
- **상태 변수**: `_stage = 0 (선택중) | 1 (결과)`, `_selectedOption`, `_resolvedResult`
- **화면 전환**: `showDialog` 사용 (CLAUDE.md: ConstrainedBox 바깥으로 나가지 않도록 `barrierDismissible: false` + `Dialog(child: ...)` 감싸기 불필요, 기존 AlertDialog 패턴 준수)
- **연출**: 선택지 클릭 → 즉시 stage 1로 전환 (애니메이션 없음 — 기존 퀘스트 결과 팝업과 동일)

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/static_game_data.dart` | `travelChoiceEvents`, `travelChoiceOptions`, `travelChoiceResults` 필드 3개 추가 | 정적 데이터 신규 3테이블 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 3테이블명 추가 | Supabase 동기화 대상 등록 |
| `band_of_mercenaries/lib/core/data/data_loader.dart` | 3테이블 JSON 로드 로직 추가 | StaticGameData 구성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `travelChoiceCompleted` @HiveField(21) 추가 | 활동 로그 타입 확장 |
| `band_of_mercenaries/lib/core/models/user_data.dart` | `choiceEventId: String?` @HiveField(21) 추가 | 이벤트 ID 이동 중 보존 |
| `band_of_mercenaries/lib/core/models/mercenary.dart` | `traitLearningBoostUntil: DateTime?` @HiveField(23) 추가 | Phase 4-3 공유 필드 (미구현 시에만) |
| `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart` | `startMovement`에 rollChoiceEvent 호출, `_completeMovement`에 팝업 트리거 추가 | 핵심 연동 |
| `band_of_mercenaries/lib/features/movement/data/movement_repository.dart` | `choiceEventId` Hive 저장/조회 메서드 추가 | 영속성 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | `ref.listen(pendingTravelChoiceProvider)` 추가 → `TravelChoiceRecallDialog` 표시 | UI 트리거 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/travel_choice_event_data.dart` | Freezed + json_serializable — 마스터 이벤트 모델 |
| `band_of_mercenaries/lib/core/models/travel_choice_option_data.dart` | Freezed + json_serializable — 선택지 모델 |
| `band_of_mercenaries/lib/core/models/travel_choice_result_data.dart` | Freezed + json_serializable — 결과 분기 모델 |
| `band_of_mercenaries/lib/features/movement/domain/travel_choice_service.dart` | 순수 정적 서비스 — rollChoiceEvent / selectProtagonist / resolveResult / applyEffect |
| `band_of_mercenaries/lib/features/movement/domain/travel_choice_recall_provider.dart` | `pendingTravelChoiceProvider` StateProvider + `TravelChoiceRecallData` 클래스 |
| `band_of_mercenaries/lib/features/movement/view/travel_choice_recall_dialog.dart` | 2단계 팝업 UI Widget |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `lib/core/models/travel_choice_event_data.dart` | Freezed + json_serializable |
| `lib/core/models/travel_choice_option_data.dart` | Freezed + json_serializable |
| `lib/core/models/travel_choice_result_data.dart` | Freezed + json_serializable |
| `lib/core/models/user_data.dart` | HiveField(21) 추가 — hive_generator |
| `lib/core/models/mercenary.dart` | HiveField(23) 추가 — hive_generator (Phase 4-3 미구현 시) |
| `lib/core/domain/activity_log_model.dart` | 열거값 추가 — hive_generator |

### 3.4 관련 시스템

- **TemplateEngine (Phase 4-1)**: `evaluationScope: EvaluationScope.team|mercenary` 파라미터, `rosterForTeam` 필드 — 본 spec의 FR-3, FR-4가 실사용 첫 투입
- **TravelEventService (기존)**: `rollEvent()` + `_applyEventEffect()` 패턴 참조. 기존 12종 자동 이벤트 수정 없음
- **MovementProvider (기존)**: `startMovement()`, `_completeMovement()` 확장
- **MercenaryStatService (기존)**: `traitLearningBoostUntil` 읽기 (`TraitAcquisitionService`가 이미 이 필드를 참조한다는 가정 — Phase 4-3 연동)
- **ActivityLog (core)**: `ActivityLogType.travelChoiceCompleted` 추가
- **SyncService (core)**: 3테이블 추가 — 기존 21개 → 24개

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `lib/features/movement/domain/travel_event_service.dart` : 순수 정적 서비스 패턴 → `TravelChoiceService` 동일 구조
- `lib/features/movement/domain/movement_provider.dart` `_applyEventEffect()` : switch-case 효과 적용 패턴, trait_innate 처리 경로 재사용
- `lib/features/quest/domain/quest_provider.dart` `pendingEliteLootProvider` : StateProvider 기반 팝업 큐 패턴 → `pendingTravelChoiceProvider` 동일 패턴
- `lib/features/home/view/home_screen.dart` `ref.listen(movementProvider)` : 도착 팝업 트리거 위치 → `ref.listen(pendingTravelChoiceProvider)` 동일 위치에 추가
- `lib/features/quest/view/quest_result_dialog.dart` : 2단계 팝업 StatefulWidget 구조 참조
- `lib/core/models/elite_monster_data.dart` : Freezed + json_serializable 패턴 참조

### 4.2 주의사항

- **HiveField append-only**: `UserData` HiveField 0-19는 변경 금지. 신규 필드는 20(Phase 4-2), 21(본 spec) 순서 유지. `Mercenary` HiveField 22까지 기존, 23=`traitLearningBoostUntil`.
- **ActivityLogType HiveField 충돌 방지**: 기존 essenceApplied(15)/essenceLostOnDeath(16)/essenceLostOnRelease(17) + M3 신규 regionTransform(18)/chainProgressed(19)/chainCompleted(20)/travelChoiceCompleted(21). 다른 값 사용 금지.
- **`evaluationScope` 분리**: `visibility_expr` → `EvaluationScope.team` (rosterForTeam 전달), `conditional_expr` → `EvaluationScope.mercenary` (protagonist만). 혼용 금지.
- **정규화 분모 = 0 방지**: 탈락 후 후보가 0개이면 fallback 상수 반환. 정규화 전 `filtered.isEmpty` 체크 필수.
- **TemplateEngine null 안전**: `TemplateContext.merc`가 null인 경우(로스터 0명 극단 상황)는 이벤트 자체 미발동(FR-1 rosterIdle.isEmpty 가드)으로 예방. Dialog 진입 시 protagonist 항상 non-null 보장.
- **heal_tired 음수**: 기존 `_applyEventEffect`는 양수(회복)만 처리. `applyEffect`에서 `effectMagnitude < 0`이면 피로 부여(protagonist.status = MercenaryStatus.tired, tiredEndTime = now + 5min). 기존 자동 이벤트 코드 변경 없이 TravelChoiceService 내에서 독립 처리.
- **item 효과**: M2a `ItemService.addItem(itemId, quantity)` 의존. M2a 인프라 미구현 구간이면 gold 환산(하급=40G, 중급=150G) fallback 처리. 구현 시 주석으로 명시.
- **팝업 타이밍**: `pendingTravelChoiceProvider`는 `_completeMovement()` 내에서 설정. `home_screen.dart`의 `ref.listen`은 `addPostFrameCallback`으로 지연 호출 (기존 이동 완료 팝업 동일 패턴). 퀘스트 완료 팝업 이후 순서 확보는 Phase 4-6 공존 정책에서 확정.
- **Navigator 스코프**: CLAUDE.md 제약 — 새 화면 전환은 상태 기반 렌더링. 단 `showDialog`는 허용 (기존 모든 팝업이 showDialog 사용). `TravelChoiceRecallDialog`는 Dialog 내 StatefulWidget.

### 4.3 엣지 케이스

- **전원 파견 시**: `rosterIdle.isEmpty` → `rollChoiceEvent()` null 반환 → `choiceEventId` 저장 없음 → 팝업 미발동
- **로스터 0명 극단 상황**: 이론상 발생 불가. 발생 시 이벤트 미발동
- **앱 재시작 후 이동 완료**: `_load()`에서 `userData.choiceEventId != null`이면 `_completeMovement()`가 다음 틱에서 팝업 트리거 (MovementProvider 재초기화 후 틱 체크로 자연 처리)
- **조건 결과 0개 탈락**: fallback constant `TravelChoiceResultData(id: '_fallback', ..., effectType: 'nothing')` 코드 상수로 정의
- **probability 합 1.0 이상**: 데이터 검증 실패 방어 — 정규화는 `sum > 0.0`이면 항상 수행

### 4.4 구현 힌트

- **진입점**: `MovementNotifier.startMovement()` → `TravelChoiceService.rollChoiceEvent()` 호출, `MovementRepository.saveChoiceEventId()` 저장
- **데이터 흐름**:
  ```
  startMovement()
    → TravelChoiceService.rollChoiceEvent(distance, tier, rosterIdle, events, random)
    → MovementRepository.saveChoiceEventId(event.id)  [Hive 저장]
  
  _completeMovement()  [gameTickProvider 호출]
    → userData.choiceEventId != null
    → staticData에서 event/options/results 조회
    → TravelChoiceService.selectProtagonist(rosterIdle, preferredTraits, traitMap)
    → pendingTravelChoiceProvider.state = TravelChoiceRecallData(...)
    → MovementRepository.clearChoiceEventId()
  
  home_screen.dart ref.listen(pendingTravelChoiceProvider)
    → showDialog(TravelChoiceRecallDialog(data))
  
  TravelChoiceRecallDialog
    → TemplateEngine.render(situation, ctx[evaluationScope=team])  [1단계 표시]
    → TemplateEngine.evaluate(visibilityExpr, ctx[scope=team]) per option  [버튼 필터]
    → [선택] TravelChoiceService.resolveResult(option, results, ctx[scope=merc], random)
    → TravelChoiceService.applyEffect(result, protagonist, ...)
    → ActivityLog 기록  [2단계 결과 표시]
    → [확인] pendingTravelChoiceProvider.state = null
  ```
- **참조 구현**:
  - `features/movement/domain/travel_event_service.dart` : TravelChoiceService 구조 모델
  - `features/movement/domain/movement_provider.dart` `_applyEventEffect()` : trait_innate 경로 재사용
  - `features/quest/domain/quest_provider.dart` `pendingEliteLootProvider` : StateProvider 팝업 패턴
  - `features/home/view/home_screen.dart` (L80-165) : ref.listen 트리거 패턴
- **확장 지점**:
  - `MovementNotifier.startMovement()` 내 `rollEvent()` 호출 직후 → `rollChoiceEvent()` 호출 추가
  - `MovementNotifier._completeMovement()` 내 활동 로그 기록 이후 → `pendingTravelChoiceProvider` 설정 추가

## 5. 기획 확인 사항

- [Q-1] hidden 선택지 수 — 밸런스 리포트 §8-2에서 12종 all-hidden(기획)을 6종으로 축소 권장. 페이즈 3-5에서 data-generator가 실제 데이터 생성 시 결정 완료 (본 spec은 데이터 기반으로 동작하므로 코드 변경 없음). → **코드 수준에서는 영향 없음**
- [Q-2] 선택지 이벤트 발생 확률 cap — 기획 §1-1 `0.40~0.60` 대신 밸런스 리포트 `0.30` 채택. → **FR-1 수치 확정 적용**
- [Q-3] Q-9 전원 파견 미발동 — 밸런스 §4-6 확정. → **FR-1에 반영**
- [Q-4] 활동 로그 1줄 요약 — 밸런스 §4-7 확정. → **FR-8에 반영**
- [Q-5] `delay` 효과 제외 — 기획 §5 확정. `applyEffect`에 delay case 없음.
- [Q-6] Phase 1-6 팝업 순서 — 도착 팝업 순서(퀘스트→자동이벤트→**선택지**→기타)는 Phase 4-6 spec에서 확정. 본 spec은 `pendingTravelChoiceProvider` 패턴으로 독립 운영, 충돌 시 Phase 4-6에서 조정.
- [Q-7] item 효과 대상 — `items.tier ≤ 3`(M2a) 한정. 밸런스 §4-4 확정. → **코드 주석으로 명시**
