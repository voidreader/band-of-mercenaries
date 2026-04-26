# 퀘스트 서사 통합 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260424_quest_narratives.md` (페이즈 1-4)
> 선행 spec: `Docs/spec/M3/[spec]20260424_template-engine.md` (페이즈 4-1, PASS)
> 데이터 선행: 배치 E(`quest_narratives` 88행 + `quest_pools.enemy_name` ALTER) + 배치 G(200행 재분류 + enemy_name 채움 77행)
> 작성일: 2026-04-24
> 범위: M3 페이즈 4-4

## 1. 개요

퀘스트 완료 시 `quest_narratives` 88행에서 `quest_type × result_type × is_elite` 매트릭스로 후보를 필터링하여 weight 기반 random 선택 후 TemplateEngine으로 렌더한다. 렌더된 문자열은 `ActiveQuest.renderedNarrative` Hive 필드에 저장되어 **pick 시드 재현** 문제(페이즈 4-1 Q-3)를 해결한다. 완료 팝업(`QuestResultDialog`)과 활동 로그에서 동일 문자열을 표시한다. 체인 단계 퀘스트는 `chain_quests.description`을 사용하므로 본 spec 범위 밖(페이즈 4-2에서 처리됨).

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] `QuestNarrativeData` Freezed 정적 모델**
  - 상세: `quest_narratives` 테이블 매핑
  - 필드:
    - `id` (String, PK)
    - `questType` (String) — @JsonKey(name: 'quest_type')
    - `resultType` (String) — @JsonKey(name: 'result_type'), 값 `greatSuccess`/`success`/`failure`/`criticalFailure`
    - `isElite` (bool) — @JsonKey(name: 'is_elite'), default false
    - `template` (String)
    - `weight` (int, default 1)
    - `description` (String?)
  - Supabase fromJson/toJson 자동 생성

- **[FR-2] `QuestNarrativeService.pickTemplate()`**
  - 상세: quest 완료 시 서사 템플릿 선택
  - 시그니처:
    ```dart
    QuestNarrativeData? pickTemplate({
      required String questType,
      required QuestResult resultType,
      required bool isElite,
      required List<QuestNarrativeData> allNarratives,
      required Random random,
    });
    ```
  - 필터링:
    1. `quest_type == questType` 일치
    2. `result_type == resultType.name` 일치 (enum → string 변환)
    3. `is_elite == isElite` 일치
  - 후보 중 `weight` 기반 가중치 랜덤 선택
  - 후보 0개: `null` 반환 → 호출부는 fallback 문자열 사용

- **[FR-3] `QuestNarrativeService.renderNarrative()`**
  - 상세: 선택된 템플릿 + TemplateEngine으로 최종 문자열 생성
  - 시그니처:
    ```dart
    String renderNarrative({
      required ActiveQuest quest,
      required List<Mercenary> partyMercs,
      required StaticGameData staticData,
      required UserData userData,
      required List<FactionState> factionStates,
      required Map<String, String>? sectorChanges,
      int? seed,
    });
    ```
  - 절차:
    1. `pickTemplate` 호출 → 템플릿 획득 (없으면 `null` 반환 — 호출부 처리)
    2. 대표 용병 선정: `partyMercs` 중 `QuestCalculator.calculatePartyPower`의 개별 기여도가 가장 높은 용병 (페이즈 4-1 Q-2 결정)
    3. `TemplateContext` 구성:
       - `merc = 대표 용병`
       - `quest = quest`
       - `region = staticData.regions.firstWhere((r) => r.region == quest.region)`
       - `user = userData`
       - `factionStates = factionStates`
       - `sectorChanges = sectorChanges`
       - `currentSectorIndex = userData.sector`
       - `rosterForTeam = []` (본 렌더는 mercenary scope 전용)
       - `seed = seed` (pick 재현용)
       - `evaluationScope: mercenary`
    4. `templateEngine.render(template, context)` 호출
    5. 결과 반환

- **[FR-4] `ActiveQuest.renderedNarrative` Hive 필드 추가**
  - `@HiveField(25) String? renderedNarrative` 추가
  - QuestCompletionService가 완료 직후 `QuestNarrativeService.renderNarrative()` 호출 → 결과 저장
  - 저장 시점: `QuestCompletionService.calculate()`가 `QuestCompletionResult`를 반환한 후, 호출부(`QuestCompletionNotifier` 또는 유사)가 `ActiveQuest`에 기록
  - **pick 시드 고정**: 저장된 `renderedNarrative`가 있으면 `QuestResultDialog`/`ActivityLog`는 이 값을 그대로 표시 (재렌더 금지)

- **[FR-5] `{quest.enemy}` 변수 TemplateEngine 해결**
  - TemplateEngine 카탈로그(페이즈 4-1)에 이미 `quest.enemy`가 등록됨
  - 런타임 값 해결: `quest.questPoolId`로 `staticData.questPools` 조회 → 해당 pool의 `enemyName` 필드 반환
  - `enemyName`이 `null`이면 fallback `"적"` (TemplateEngine fallback 구문 `{quest.enemy|적}`)
  - 체인 퀘스트: `quest_pools`에 없는 `chain_xxx_stepN` ID는 `null` → fallback
  - **QuestPool Freezed 모델에 `enemyName` 필드 추가** (페이즈 4-3 spec과는 별개 필드)

- **[FR-6] `QuestResultDialog` 서사 영역 추가**
  - 기존 `QuestResultDialog` (`lib/features/quest/view/quest_result_dialog.dart:10-`) 수정
  - Result banner (현 line 55~65) **아래**에 서사 영역 삽입
  - `quest.renderedNarrative != null && quest.renderedNarrative!.isNotEmpty` 일 때만 표시
  - 위젯 구조:
    ```
    Container (padding: 14, background: AppTheme.tier1Bg opacity 0.5, borderRadius: 8)
      └ Text(quest.renderedNarrative, style: fontStyle.italic, fontSize: 14, textAlign: center)
    ```
  - 서사 없으면(`null` 또는 빈 문자열) 영역 생략. 기존 레이아웃 유지

- **[FR-7] 활동 로그 메시지에 서사 반영**
  - `QuestCompletionService` 완료 후 `activityLogProvider.notifier.addLog()` 호출
  - 메시지 포맷 (현행 확인 후 통합): `"[{quest.name}] {renderedNarrative}"` 또는 서사만
  - 기존 `ActivityLogType.questResult` 재사용 (신규 타입 불필요)
  - 서사가 `null`이면 기존 포맷 사용 (대성공/성공/실패/대실패 결과만 표기)

- **[FR-8] Supabase 동기화 — `quest_narratives` 테이블**
  - `SyncService`에 `quest_narratives` 다운로드 추가
  - `data_versions` 엔트리 이미 존재 (배치 E)
  - `StaticGameData.questNarratives: List<QuestNarrativeData>` 필드 추가
  - `DataLoader`가 로컬 JSON 캐시 → `QuestNarrativeData` 리스트 로드

- **[FR-9] 대표 용병 선정 로직**
  - 상세: 페이즈 4-1 Q-2 결정대로 `(b) 파티 기여도 최대 용병` 사용
  - 구현: 각 용병의 개별 partyPower 기여 계산
    ```dart
    static Mercenary pickProtagonist(List<Mercenary> mercs, String questTypeId, Map<String, EquipmentStatBonus> equipmentBonuses) {
      final weights = QuestCalculator._statWeights[questTypeId] ?? QuestCalculator._statWeights['raid']!;
      return mercs.map((m) {
        final contribution = m.effectiveStr × weights['str'] + ...; // 각 용병의 기여 점수
        return (m, contribution);
      }).reduce((a, b) => a.$2 > b.$2 ? a : b).$1;
    }
    ```
  - **주의**: `QuestCalculator._statWeights`가 private — 본 spec에서 `public static` 전환 필요하거나 `QuestCalculator`에 `pickProtagonist` 메서드 직접 추가
  - **결정**: `QuestCalculator.statWeightsFor(questTypeId)` public 메서드 신설 + `QuestNarrativeService.pickProtagonist()`에서 사용

- **[FR-10] 체인 퀘스트는 본 서비스 미사용**
  - `ActiveQuest.isChainQuest == true` (페이즈 4-2)이면 `QuestNarrativeService.renderNarrative()` 호출 **생략**
  - 대신 호출부가 `chain_quests.description`을 직접 렌더 (페이즈 4-2 spec FR-11)
  - 본 서비스는 일반 퀘스트 + 엘리트 퀘스트만 처리

- **[FR-11] 엘리트 퀘스트 서사 분기**
  - `quest.isElite == true` → `pickTemplate(isElite: true, ...)`
  - 엘리트 8행(quest_type × result_type × 1 변형)에서 선택
  - `{quest.enemy}` 변수는 엘리트 이름으로 해결:
    - `quest.questPoolId`가 `elite_xxx` 형태 → `staticData.eliteMonsters.firstWhere((e) => e.id == quest.eliteId).name`
    - 일반 quest_pool fromJson enemyName은 null이므로 엘리트 전용 로직으로 `{quest.enemy}` 해결
  - **TemplateContext 확장 필요**: `TemplateContext.eliteId: String?` 또는 `eliteName: String?` 필드 추가 → TemplateEngine에서 `{quest.enemy}` 해결 시 `isElite`면 `eliteName` 우선 사용
  - **결정**: `TemplateContext`에 `quest`를 포함하지 말고, 해결된 enemy 문자열을 직접 계산하여 context에 주입. 본 spec은 호출부에서 책임짐

- **[FR-12] Pick 시드 결정 규칙**
  - 상세: `QuestCompletionService` 완료 시점에 `seed = DateTime.now().millisecondsSinceEpoch + quest.id.hashCode` 생성
  - `renderNarrative(seed: ...)` 호출 → TemplateEngine이 pick 블록에서 이 시드 사용
  - `ActiveQuest.renderedNarrative`에 결과 저장 → 이후 재렌더 없음 (FR-4)
  - 활동 로그는 renderedNarrative 문자열을 그대로 참조

### 2.2 데이터 요구사항

#### 2.2.1 신규 Freezed 모델

- **`QuestNarrativeData`** (`lib/core/models/quest_narrative_data.dart`)
  ```dart
  @freezed
  class QuestNarrativeData with _$QuestNarrativeData {
    const factory QuestNarrativeData({
      required String id,
      @JsonKey(name: 'quest_type') required String questType,
      @JsonKey(name: 'result_type') required String resultType,
      @Default(false) @JsonKey(name: 'is_elite') bool isElite,
      required String template,
      @Default(1) int weight,
      String? description,
    }) = _QuestNarrativeData;
    factory QuestNarrativeData.fromJson(Map<String, dynamic> json) => _$QuestNarrativeDataFromJson(json);
  }
  ```

#### 2.2.2 기존 모델 확장

- **`QuestPool`** Freezed 모델 (`lib/core/models/quest_pool.dart`)
  - `@JsonKey(name: 'enemy_name') String? enemyName` 추가 (기존 필드 외)
  - 페이즈 4-3 spec의 `sectorType`/`specialFlags` 확장과 병행

- **`ActiveQuest`** Hive 모델 (typeId: 4)
  - `@HiveField(25) String? renderedNarrative` 추가
  - 페이즈 4-2(21~23)/4-3(24) 이후 25 순차 배정

- **`StaticGameData`** (`lib/core/providers/static_data_provider.dart`)
  - `List<QuestNarrativeData> questNarratives` 필드 추가

#### 2.2.3 TemplateEngine 연계

- `TemplateEngine.render()` 호출 시 `{quest.enemy}` 변수는 `TemplateContext`가 `quest`를 포함하는 기존 구조 활용
- **TemplateContext 해결 흐름**:
  - 일반 퀘: `staticData.questPools.firstWhere((p) => p.id == quest.questPoolId).enemyName`
  - 엘리트: `staticData.eliteMonsters.firstWhere((e) => e.id == quest.eliteId).name`
  - 둘 다 null: fallback `"적"` (`{quest.enemy|적}` 기획 권장)
- **페이즈 4-1 TemplateEngine spec의 `TemplateContext.quest` 필드**는 `ActiveQuest`를 그대로 수용. `{quest.enemy}` 해결은 TemplateEngine 내부 로직이 처리 (page 4-1 FR-1/FR-10에서 카탈로그만 등록되어 있음 → **TemplateEngine 구현 시 `quest.enemy` 해결 로직 명시 필요**, 본 spec이 추가 요구사항)
- **결정**: 본 spec이 TemplateEngine spec의 FR-1 구현 시점에 "`{quest.enemy}` 해결 로직: QuestPool.enemyName 우선, EliteMonster.name fallback, null이면 `"적"`" 규칙을 추가 반영하도록 명시

### 2.3 UI 요구사항

#### 2.3.1 QuestResultDialog 서사 영역

- **화면 진입 조건**: `QuestResultDialog` 렌더 시 `quest.renderedNarrative != null && quest.renderedNarrative!.isNotEmpty`
- **위젯 계층**: `Column > ... > Result banner > **Container (서사)** > SizedBox > Merc status > ...`
- **상태 변수**: 없음 (ActiveQuest가 이미 `renderedNarrative` 저장)
- **화면 전환**: `QuestResultDialog`는 `showDialog`. 기존 구조 유지
- **연출**:
  - 서사 Container padding 14, margin-top 12, background `AppTheme.tier1Bg.withValues(alpha: 0.3)`, borderRadius 8
  - 텍스트 `fontStyle.italic`, textAlign center, color `AppTheme.textSecondary`
  - 서사 없으면 영역 자체 생략 (기존 레이아웃 영향 최소화)

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `lib/core/models/quest_pool.dart` | `enemyName` 필드 추가 (페이즈 4-3에서 `sectorType`/`specialFlags` 추가와 병행) | FR-5 |
| `lib/features/quest/domain/quest_model.dart` | `ActiveQuest.renderedNarrative` 필드 추가 (HiveField 25) | FR-4 |
| `lib/features/quest/domain/quest_completion_service.dart` | 완료 시 `QuestNarrativeService.renderNarrative()` 호출 + `ActiveQuest` 저장 경로 통합 | FR-4, FR-12 |
| `lib/features/quest/domain/quest_calculator.dart` | `statWeightsFor(questTypeId)` public 메서드 추가 | FR-9 |
| `lib/features/quest/view/quest_result_dialog.dart` | 서사 영역 Container 삽입 (Result banner 아래) | FR-6 |
| `lib/core/data/sync_service.dart` | `quest_narratives` 테이블 동기화 추가 | FR-8 |
| `lib/core/data/data_loader.dart` | `QuestNarrativeData` 로드 | FR-8 |
| `lib/core/providers/static_data_provider.dart` | `StaticGameData.questNarratives` 필드 추가 | FR-8 |
| `lib/core/domain/template_engine.dart` (페이즈 4-1 예정 구현) | `{quest.enemy}` 해결 로직 추가: QuestPool.enemyName → EliteMonster.name → "적" fallback | §2.2.3 |
| `lib/core/domain/activity_log_provider.dart` 또는 호출부 | 서사 메시지 포맷 통합 | FR-7 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `lib/core/models/quest_narrative_data.dart` | Freezed 정적 모델 |
| `lib/features/quest/domain/quest_narrative_service.dart` | `pickTemplate` + `renderNarrative` + `pickProtagonist` |
| `test/features/quest/domain/quest_narrative_service_test.dart` | 필터·가중치·렌더 테스트 (~15개) |
| `test/features/quest/domain/quest_narrative_render_test.dart` | TemplateEngine 통합 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `lib/core/models/quest_narrative_data.freezed.dart` + `.g.dart` | 신규 Freezed |
| `lib/core/models/quest_pool.freezed.dart` + `.g.dart` | `enemyName` 추가 (페이즈 4-3과 동시 생성) |
| `lib/features/quest/domain/quest_model.g.dart` | `renderedNarrative` 추가 |

**build_runner 실행**: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

### 3.4 관련 시스템

- **TemplateEngine (페이즈 4-1)**: 본 spec이 `{quest.enemy}` 해결 로직 추가 요구사항 전달. 페이즈 4-1 구현 시 반영 필요
- **QuestCompletionService (페이즈 4-2/4-3)**: 완료 후 `renderNarrative()` 호출 + `ActiveQuest.renderedNarrative` 저장 통합
- **QuestResultDialog (기존)**: 서사 영역 UI 추가
- **ActivityLogProvider (기존)**: 서사 메시지 반영
- **SyncService (기존)**: `quest_narratives` 다운로드
- **페이즈 4-2 체인 퀘스트 spec**: 본 서비스 미사용(FR-10), 체인은 `chain_quests.description` 직접 렌더
- **페이즈 4-6 공존 정책 spec (예정)**: `QuestResultDialog` 팝업 순서 조정

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Freezed 정적 모델**: `lib/core/models/elite_monster_data.dart`, `lib/core/models/quest_pool.dart` — `@freezed` + `@JsonKey(name: 'snake_case')`
- **서비스 클래스**: `lib/features/quest/domain/elite_loot_service.dart` — static 메서드 모음
- **QuestResultDialog 구조**: `lib/features/quest/view/quest_result_dialog.dart:40-166` — `Dialog > Padding > Column` 구조에 영역 삽입
- **ActiveQuest HiveField 확장**: 페이즈 4-2 spec이 21~23 점유, 페이즈 4-3이 24, 본 spec 25

### 4.2 주의사항

- **HiveField append-only**:
  - `ActiveQuest` 25 (페이즈 4-2: 21~23, 4-3: 24 이후)
  - `ActivityLogType`: 본 spec은 추가 없음 (기존 `questResult` 재사용)
  - `QuestPool`은 Freezed 모델이므로 HiveField 불필요
- **Weight 가중치 랜덤 선택 알고리즘**:
  ```dart
  final totalWeight = candidates.map((c) => c.weight).sum;
  double roll = random.nextDouble() * totalWeight;
  for (final c in candidates) {
    roll -= c.weight;
    if (roll <= 0) return c;
  }
  return candidates.last; // edge case
  ```
- **renderedNarrative 저장 시점**: `QuestCompletionService`가 `QuestCompletionResult`를 반환한 후, 호출부가 `activeQuest.renderedNarrative = result.renderedNarrative` 직접 갱신. Hive `save()` 명시적 호출 필요
- **TemplateContext.sectorChanges 공급**: 페이즈 4-3 spec의 `RegionState.sectorChanges` 조회. `sectorChanges: regionState?.sectorChanges` 주입
- **QuestPool.enemyName 채움 완료 데이터**: 배치 G에서 77/200행 채움. 나머지 123행(탐험/호위/중립)은 NULL 유지. TemplateEngine fallback으로 안전
- **엘리트 퀘 `{quest.enemy}` 해결**: `EliteMonsterData.name` (예: "고블린 습격자")
- **체인 퀘스트 렌더 우회**: `ActiveQuest.isChainStep == true` 조건으로 호출부에서 분기. `renderedNarrative`는 null 유지 (체인은 `chain_quests.description` 사용하므로 `QuestResultDialog`에서 별도 처리 or 체인 전용 팝업)
- **pick 시드 결정성**: seed를 확실히 전달해야 재렌더 없음 보장. QuestCompletionService에서 seed 생성 후 QuestNarrativeService에 전달

### 4.3 엣지 케이스

- **템플릿 0개 매칭**: 필터 결과 빈 리스트 → `pickTemplate()` null 반환 → 호출부는 renderedNarrative를 저장하지 않음 (null). UI 영역 생략
- **TemplateEngine 오류**: render 중 문법 오류 → TemplateEngine fail-safe(원본 출력) 반환. renderedNarrative에 원본 템플릿 저장됨 — 경고 로그만
- **대표 용병 선정 시 빈 파티**: `partyMercs.isEmpty` → pickProtagonist null 반환 → TemplateContext merc=null → `{merc.name}` → `[?merc.name]`. 이례적(완료된 퀘에 파티 없을 수 없음)
- **`quest.enemy` 값이 fallback 리터럴 포함**: enemyName DB 값 중 `|` 포함 가능성 → TemplateEngine fallback 구문과 충돌 가능. 배치 G 생성 값(`오크`/`괴물`/`늑대 무리` 등) 특수문자 없음 확인됨. 향후 `|` 포함 추가 시 주의
- **엘리트 퀘 but eliteId null**: 예외 상황. `{quest.enemy}` fallback `"적"`으로 안전 처리
- **weight 총합 0**: 모든 후보 weight 0 → 예외 상황. 현 88행 모두 weight=1로 정상. 방어적 처리 불필요
- **동일 quest 재완료**: ActiveQuest는 완료 후 삭제/아카이브되므로 재렌더 경로 없음. renderedNarrative 저장 후 영구 유지

### 4.4 구현 힌트

- **진입점**:
  - `QuestCompletionNotifier.onQuestCompleted(quest, result)` → `QuestNarrativeService.renderNarrative()` 호출 → `ActiveQuest.renderedNarrative` 저장 → `QuestResultDialog` 표시
- **데이터 흐름**:
  ```
  [퀘스트 완료] → QuestCompletionService.calculate()
  → QuestNarrativeService.pickTemplate(quest_type, result_type, is_elite)
  → weight-based random 선택 → QuestNarrativeData
  → QuestNarrativeService.renderNarrative(quest, partyMercs, ...)
  → pickProtagonist → TemplateContext 구성 → TemplateEngine.render()
  → String 결과 반환 → ActiveQuest.renderedNarrative 저장 (Hive)
  → QuestResultDialog 표시 → 서사 영역에 renderedNarrative 출력
  → ActivityLog에 renderedNarrative 기록
  ```
- **참조 구현**:
  - Freezed 모델: `lib/core/models/elite_monster_data.dart`
  - 서비스 패턴: `lib/features/quest/domain/elite_loot_service.dart`
  - TemplateEngine 호출: 페이즈 4-1 spec FR-8
  - ActivityLog 메시지 포맷: `lib/core/domain/activity_log_provider.dart`
  - QuestResultDialog 레이아웃: 기존 파일 line 40-166

## 5. 기획 확인 사항

- [Q-A] **`{quest.enemy}` 해결 로직 TemplateEngine spec 반영 여부**: 페이즈 4-1 spec은 카탈로그만 등록. 실제 값 해결 로직이 TemplateEngine 구현에 포함되어야 하는데, 본 spec이 그 요구사항을 추가 명시 (§2.2.3). 페이즈 4-1 구현자가 확인 필요 — **구현 단계 교차 참조 필수**
- [Q-B] **엘리트 퀘 서사의 `{quest.enemy}` 해결**: `eliteId` → `eliteMonsters` 조회. TemplateEngine이 `TemplateContext`에 `eliteMonsters` 리스트를 별도로 받는지 혹은 `StaticGameData` 전체를 받는지 구현 결정 필요 — **권장: TemplateContext에 이미 `quest` 필드가 있으므로 TemplateEngine이 staticData 주입 받아 eliteId → name 해결**. 페이즈 4-1 구현 시 `TemplateContext.staticData: StaticGameData?` 추가 or helper
- [Q-C] **서사 저장 후 재렌더 여부**: renderedNarrative가 null 이외 값이면 재렌더 절대 금지 (시드 재현 불가). 활동 로그·팝업 모두 저장된 값 사용 — 확정
- [Q-D] **체인 퀘 서사는 chain_quests.description 사용**: 페이즈 4-2 spec FR-11과 정합. QuestResultDialog 구분 표시 여부 → 체인은 별도 팝업(`ChainCompletedDialog`)이므로 QuestResultDialog는 일반+엘리트만 처리. 확정
- [Q-E] **활동 로그 서사 포맷**: 기존 `questResult` 타입 재사용하되 메시지 본문을 renderedNarrative로 대체. 기존 "[퀘스트명] 결과" 포맷 대신 "[퀘스트명] {서사}" → 읽기 흐름 통일. 현재 activity_log_provider 포맷 확인 후 통일
- [Q-F] **대표 용병 개별 기여 계산**: 현 `calculatePartyPower`는 파티 합산. 개별 기여는 각 용병의 (str×w_str + int×w_int + vit×w_vit + agi×w_agi) 직접 계산. 같은 공식 재사용 가능 → 확정
- [Q-G] **서사 템플릿 0 매칭 시 fallback 문자열**: 기획은 "언급 없음". MVP는 서사 영역 자체 생략 (null 처리). 향후 기획 보강 가능

## 6. 다음 단계

- **구현**: 페이즈 4 전체 spec 완료 후 `/implement-agent @Docs/spec/M3/[spec]20260424_quest-narrative-integration.md`
- **페이즈 4-1 구현 교차 반영**: `{quest.enemy}` 해결 로직 + `TemplateContext` staticData/eliteMonsters 주입 (§2.2.3 Q-A/Q-B)
- **페이즈 4-5/4-6 의존**: 본 spec은 travel_choice narrative 렌더와 유사 패턴이나 travel_choice는 별도 모델. 페이즈 4-5가 유사 서비스를 재구성
