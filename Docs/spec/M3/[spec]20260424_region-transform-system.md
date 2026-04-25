# 지역 변형 시스템 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260423_region_transform.md`
> 주 밸런스: `Docs/balance-design/[balance]20260424_sector_transform_quests.md` (페이즈 2-2)
> 선행 spec: `Docs/spec/M3/[spec]20260424_template-engine.md` (페이즈 4-1, PASS)
> 작성일: 2026-04-24
> 범위: M3 페이즈 4-3

## 1. 개요

지역 조사가 `knowledge_threshold=98`에 도달하면 한 섹터가 **영구 변형**되어 `village`/`ruins`/`hidden` 3종 중 하나로 고정된다. 변형된 섹터에서는 `quest_pools.sector_type` 필터 기반으로 전용 퀘스트 34개가 생성되며, 일부 퀘스트는 **특수 플래그 6종**(`trait_learning_boost` / `guild_drop_rare` / `guild_drop_ultra_rare` / `essence_drop_bonus` / `equipment_drop_bonus` / `reputation_penalty`)을 가진다. 변형은 **영구적**이며, `RegionState.sectorChanges: Map<int, String>` 필드에 저장된다. 변형 트리거 팝업은 TemplateEngine으로 `narrative_template`을 렌더한다. 본 spec은 데이터/로직 기반은 페이즈 3-2/3-3에서 완성되어 있고, Flutter 런타임 구현을 정의한다.

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] `RegionState.sectorChanges` Hive 필드 추가**
  - 상세: `RegionState` (typeId: 8)에 `@HiveField(3) Map<String, String> sectorChanges` 추가 (기본값 빈 맵)
  - key: 섹터 인덱스 0~9의 **문자열 변환값**(`"0"`~`"9"`) — §4.2 Q-A Hive 직렬화 안정성 이유
  - value: `village`/`ruins`/`hidden` (String)
  - API 레이어는 int 섹터 인덱스를 노출하고 내부 저장 시 `sectorIndex.toString()` 변환
  - 리전당 최대 1섹터 변형 (MVP, §6-2 기획), 런타임 로직에서 enforce

- **[FR-2] 변형 트리거 (조사 완료 시)**
  - 상세: `InvestigationNotifier._completeInvestigation()`에 `transform` discovery_type 분기 추가
  - 트리거 조건:
    - `discovery_type == 'transform'`
    - `knowledge >= knowledge_threshold` (기본 98, 체인 5/6 연관은 88/83 — balance 2-2 §7-A 운영 조정 가능, 현 18행은 98 일괄)
    - `RegionState.sectorChanges[sector_index]`에 이미 값 없음 (중복 변형 방지)
    - 해당 `region_id`의 다른 transform discovery가 이미 트리거되지 않음 (리전당 1섹터 제약)
  - 동작:
    - `discovery_data.transform_type`/`sector_index` 파싱
    - `regionStateRepository.applyTransform(regionId, sectorIndex, transformType)` 호출 → Hive 갱신
    - `regionTransformedProvider` (StateProvider) publish → 변형 팝업 트리거
    - 활동 로그: `ActivityLogType.regionTransform` (HiveField 18) + 메시지 "{region.name}의 섹터가 {transformed_name}(으)로 변형되었다"

- **[FR-3] 변형 팝업 `RegionTransformDialog`**
  - 상세: `regionTransformedProvider` 값 non-null 감지 시 `app.dart`에서 `showDialog` 호출
  - 렌더 요소:
    - 타이틀: "✨ 지역 변형"
    - 본문: `discovery_data.narrative_template`을 TemplateEngine으로 렌더
    - TemplateContext 구성:
      - `merc = investigatingMerc` (조사 수행 용병)
      - `region = currentRegion`
      - `currentSectorIndex = sector_index`
      - `sectorChanges` = 갱신된 맵 포함
      - `evaluationScope: mercenary`
    - 유형 배지: `[유형] {transformed_name}` (village=녹색/ruins=보라/hidden=금색)
    - 버튼 2개: "확인" / "이동 화면으로"
  - dismiss 시 `regionTransformedProvider.state = null` 리셋
  - 팝업 순서: 페이즈 4-6 Global Dialog Queue에서 priority 결정 (본 spec은 provider publish만 정의)

- **[FR-4] `QuestGenerator.generateQuests()` sector_type 분기**
  - 상세: 기존 시그니처에 파라미터 추가:
    - `required int currentSectorIndex`
    - `required RegionState? regionState` (또는 `Map<int, String>? sectorChanges`)
  - 분기 로직:
    ```
    sectorType = regionState?.sectorChanges[currentSectorIndex]
    if (sectorType != null) {
      // 변형된 섹터 → 해당 sector_type 풀만 사용 (village/ruins/hidden 전용 34행 중 일부)
      filtered = questPools.where((p) => p.sectorType == sectorType && p.minRegionDiff <= regionTier && p.maxRegionDiff >= regionTier)
    } else {
      // 변형 안 된 섹터 → sector_type IS NULL 일반 풀만 사용
      filtered = questPools.where((p) => p.sectorType == null && p.minRegionDiff <= regionTier && p.maxRegionDiff >= regionTier)
    }
    ```
  - 기존 is_faction_exclusive / is_elite 분기는 동일하게 유지

- **[FR-5] `quest_pools.sector_type` / `special_flags` 데이터 모델 확장**
  - `QuestPool` Freezed 모델에 다음 필드 추가:
    - `@JsonKey(name: 'sector_type') String? sectorType` (village/ruins/hidden/null)
    - `@JsonKey(name: 'special_flags') @Default({}) Map<String, dynamic> specialFlags`
  - Supabase 동기화: 기존 `quest_pools` 동기화에 두 컬럼 자동 포함 (스키마 JSON 변경)
  - `DataLoader`: 현 로직 유지 (`fromJson`만 업데이트)

- **[FR-6] `ActiveQuest.specialFlags` 런타임 필드**
  - `ActiveQuest` Hive 모델에 `@HiveField(24) Map<String, dynamic>? specialFlags` 추가
  - `QuestGenerator`가 섹터 퀘스트 생성 시 `QuestPool.specialFlags`를 복사하여 채움
  - Hive 직렬화: `dynamic` 타입은 Hive가 지원. JSON 문자열로 저장도 대안이나 Map 직접 저장 선호

- **[FR-7] 특수 플래그 처리 서비스 — `applySpecialFlags`**
  - 신규 파일: `lib/features/quest/domain/special_flag_processor.dart`
  - `QuestCompletionService.calculate()`가 호출 후 `SpecialFlagProcessor.apply(quest, partyMercs, staticData, random)` 실행
  - 반환: `SpecialFlagResult` — `extraItems`, `extraGold`, `extraReputation`, `boostedMercIds` 등
  - 플래그별 처리:
    - **`trait_learning_boost`**: `multiplier: 1.5, duration_hours: 24` — 파티 용병 전원의 `Mercenary.traitLearningBoostUntil = now + 24h`로 갱신. `MercenaryStatService.incrementBehaviorStat()`이 이 타임스탬프를 체크하여 배수 적용
    - **`guild_drop_rare`**: `item_id`, `drop_rate` — `random.nextDouble() < drop_rate` → 아이템 지급 (`guild_banner_standard`/`guild_artifact_honor_horn`/`guild_artifact_guardian_emblem`)
    - **`guild_drop_ultra_rare`**: 동일 패턴. 드랍률만 1% 내외
    - **`essence_drop_bonus`**: `essence_tier`, `drop_rate`, `quantity` — essence_str/int/vit/agi 중 랜덤 1종 × quantity 지급
    - **`equipment_drop_bonus`**: `category: 'personal_equipment'`, `tier_range: [3,4]`, `drop_rate` — 해당 tier 장비 중 랜덤 1개 지급
    - **`reputation_penalty`**: `amount: -5` — `UserDataNotifier.addReputation(amount)` 호출
  - 실행 규칙: **보상 플래그**(`guild_drop_rare`/`guild_drop_ultra_rare`/`essence_drop_bonus`/`equipment_drop_bonus`/`trait_learning_boost`)는 **성공·대성공에만** 적용. **`reputation_penalty`는 결과와 무관하게 항상 적용** (성공 시에도 -5 명성 유지 — "금기된 의식 중단"의 서사적 정합)

- **[FR-8] `Mercenary.traitLearningBoostUntil` Hive 필드**
  - `Mercenary` (typeId: 1)에 `@HiveField(23) DateTime? traitLearningBoostUntil` 추가
  - `MercenaryStatService.incrementBehaviorStat(mercId, stat, amount)`에서:
    - `merc.traitLearningBoostUntil != null && merc.traitLearningBoostUntil!.isAfter(DateTime.now())` → `adjustedAmount = (amount * 1.5).round()`
    - 아니면 `adjustedAmount = amount`
  - 페이즈 4-5 이동 선택지의 `trait_acquired` effect_type도 동일 매커니즘 공유 (본 필드 재사용)

- **[FR-9] 변형 섹터 이동 화면 시각 구분**
  - 상세: `MovementScreen` (또는 섹터 선택 UI)에서 각 섹터 표시 시 `RegionState.sectorChanges[sectorIndex]` 조회
  - 변형된 섹터:
    - 아이콘: 🏘️(village) / 🏛️(ruins) / ✨(hidden)
    - 섹터 이름: `discovery_data.transformed_name` (static_data_provider에서 `regionDiscoveries` 조회)
    - 색상 tint: village 녹색 / ruins 보라 / hidden 금색
  - 일반 섹터: 기존 스타일 유지

- **[FR-10] `RegionStateRepository.applyTransform()` API 추가**
  - 상세:
    ```dart
    RegionState applyTransform(int regionId, int sectorIndex, String transformType) {
      final state = getState(regionId) ?? RegionState(regionId: regionId);
      state.sectorChanges[sectorIndex] = transformType;
      state.save();
      return state;
    }
    ```
  - 중복 호출 방어: 이미 해당 sector_index에 값 있으면 no-op

- **[FR-11] `ActivityLogType.regionTransform` 추가 (HiveField 18)**
  - 페이즈 4-2 spec에서 "선행 충돌 방지용 예약"으로 명시됨. 본 spec에서 정식 배정. **주의**: 기존 `ActivityLogType` HiveField 15~17은 M2a essence 기능이 점유 중이므로 M3 신규는 **18부터 할당**
  - 메시지 포맷: "{region.name}의 섹터가 {transformed_name}(으)로 변형되었다"

- **[FR-12] 대기 퀘스트 보존**
  - 변형 발생 시점 이전에 이미 생성된 `ActiveQuest` (pending 상태)는 유지. 취소·교체 없음
  - 다음 퀘스트 갱신(1시간 주기)부터 변형 섹터의 전용 풀 적용
  - 기획 §6 영속성 규칙 준수

### 2.2 데이터 요구사항

#### 2.2.1 Hive 모델 확장

- **`RegionState`** (typeId: 8)
  - `@HiveField(3) Map<String, String> sectorChanges` 신규 (기본값 `<String, String>{}`) — key는 `sectorIndex.toString()`
  - 어댑터 재생성 필요

- **`Mercenary`** (typeId: 1)
  - `@HiveField(23) DateTime? traitLearningBoostUntil` 신규
  - 어댑터 재생성 필요

- **`ActiveQuest`** (typeId: 4)
  - `@HiveField(24) Map<String, dynamic>? specialFlags` 신규 (페이즈 4-2에서 21~23 점유)
  - 런타임 필드 (Supabase 저장 안 함)

- **`ActivityLogType`** enum (typeId: 6) — **기존 HiveField 0~17 점유**(0~14 + M2a essence 15~17). M3 신규는 **18부터**
  - `@HiveField(18) regionTransform` 추가

#### 2.2.2 Freezed 정적 모델 확장

- **`QuestPool`** (`lib/core/models/quest_pool.dart`)
  - `@JsonKey(name: 'sector_type') String? sectorType` 추가
  - `@JsonKey(name: 'special_flags') @Default({}) Map<String, dynamic> specialFlags` 추가
  - 기존 필드 유지. fromJson/toJson 자동 갱신

#### 2.2.3 StateProvider 신규

- **`regionTransformedProvider`**: `StateProvider<RegionTransformedEvent?>`
  - 값 객체: `regionId`, `sectorIndex`, `transformType`, `transformedName`, `narrativeRendered`
  - publish 후 app.dart가 `ref.listen`으로 감지

- **`SpecialFlagResult`** — 값 객체 (Freezed 필요 없음, 간단 record)
  - `List<String> extraItemIds`
  - `int extraGold`
  - `int extraReputation`  
  - `List<String> boostedMercIds` (trait_learning_boost 적용된 용병)

#### 2.2.4 Supabase 동기화

- `quest_pools` 테이블은 배치 D에서 `sector_type` + `special_flags` 컬럼 이미 존재 (총 398행: 기존 + sector 34 신규). 데이터 버전 증가됨
- `region_discoveries` 테이블은 배치 C에서 `transform` 18행 신규 추가. 기존 동기화 로직으로 자동 반영

### 2.3 UI 요구사항

#### 2.3.1 변형 팝업 (`RegionTransformDialog`)

- **화면 진입 조건**: `regionTransformedProvider`가 non-null 변경
- **위젯 계층**: `AlertDialog > Column > [Title, Badge, Body, Buttons]`
- **상태 변수**:
  - 이벤트 소비: `ref.watch(regionTransformedProvider)`
  - dismiss 시 `ref.read(regionTransformedProvider.notifier).state = null`
- **화면 전환**: `showDialog`(Navigator 기반이나 페이즈 4-6 Global Dialog Queue 경유 예정)
- **연출**: 페이드 인 애니메이션. 변형 유형 아이콘 애니메이션(선택적 MVP 제외)

#### 2.3.2 이동 화면 섹터 구분 (`MovementScreen` 확장)

- **화면 진입 조건**: 기존 이동 화면 렌더 시 매 섹터 렌더 단계에서 `RegionState.sectorChanges` 조회
- **위젯 계층**: 기존 섹터 목록 위젯에 아이콘/이름/색상 조건부 추가
- **상태 변수**: `regionStateProvider` (기존 있음 가정, 없으면 `regionStateRepository.getState(regionId)` 직접 조회)
- **화면 전환**: 변형 섹터 선택 시 기존 이동 플로우 동일 (특별 처리 없음)

### 2.4 활동 로그 통합

- `ActivityLogType.regionTransform`: 본 spec에서 HiveField 15 배정 (페이즈 4-2와 정합)
- 메시지: `"{region_name}의 섹터가 {transformed_name}(으)로 변형되었다"`
- 관련 리전 ID 저장 (기존 `ActivityLog.regionId` 필드가 있다면 재사용, 없으면 메시지에 포함)

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `lib/features/investigation/domain/region_state_model.dart` | `sectorChanges` 필드 추가 (HiveField 3) | FR-1 |
| `lib/features/investigation/data/region_state_repository.dart` | `applyTransform()` 메서드 추가 | FR-10 |
| `lib/features/investigation/domain/investigation_notifier.dart` | `transform` discovery_type 분기 추가 (`_completeInvestigation` 내 `for (final d in newlyTriggered)` 루프에 case 추가) | FR-2 |
| `lib/features/mercenary/domain/mercenary_model.dart` | `traitLearningBoostUntil` 필드 추가 (HiveField 23) | FR-8 |
| `lib/features/mercenary/domain/mercenary_stat_service.dart` | `incrementBehaviorStat()`에 boost 배수 적용 | FR-8 |
| `lib/features/quest/domain/quest_model.dart` | `ActiveQuest.specialFlags` 필드 추가 (HiveField 24) | FR-6 |
| `lib/features/quest/domain/quest_generator.dart` | sector_type 분기 + specialFlags 복사 | FR-4, FR-6 |
| `lib/features/quest/domain/quest_completion_service.dart` | 완료 후 `SpecialFlagProcessor.apply()` 호출 통합 | FR-7 |
| `lib/core/models/quest_pool.dart` | `sectorType`, `specialFlags` 필드 추가 | FR-5 |
| `lib/core/models/activity_log_model.dart` | `ActivityLogType.regionTransform` 추가 (HiveField 18) | FR-11 |
| `lib/features/movement/view/movement_screen.dart` (또는 섹터 목록 위젯) | 변형 섹터 아이콘/이름/색상 구분 | FR-9 |
| `lib/app.dart` | `regionTransformedProvider` `ref.listen` 추가 | FR-3 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `lib/features/investigation/domain/region_transform_service.dart` | 변형 트리거 로직 (InvestigationNotifier에서 호출) + `applyTransform` wrapper |
| `lib/features/investigation/domain/region_transformed_provider.dart` | `StateProvider<RegionTransformedEvent?>` |
| `lib/features/investigation/view/region_transform_dialog.dart` | 변형 팝업 UI |
| `lib/features/quest/domain/special_flag_processor.dart` | 6종 플래그 처리 |
| `lib/features/quest/domain/special_flag_result.dart` | 결과 값 객체 |
| `test/features/investigation/domain/region_transform_trigger_test.dart` | 트리거 조건 단위 테스트 |
| `test/features/quest/domain/special_flag_processor_test.dart` | 6종 플래그별 처리 테스트 |
| `test/features/quest/domain/quest_generator_sector_branch_test.dart` | sector_type 분기 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `lib/features/investigation/domain/region_state_model.g.dart` | `sectorChanges` 필드 추가 |
| `lib/features/mercenary/domain/mercenary_model.g.dart` | `traitLearningBoostUntil` 필드 추가 |
| `lib/features/quest/domain/quest_model.g.dart` | `specialFlags` 필드 추가 |
| `lib/core/models/quest_pool.g.dart` + `.freezed.dart` | `sectorType`, `specialFlags` 추가 |
| `lib/core/models/activity_log_model.g.dart` | enum 값 추가 |

**build_runner 실행**: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

### 3.4 관련 시스템

- **TemplateEngine (페이즈 4-1)**: 변형 팝업의 `narrative_template` 렌더. `mercenary` scope, `context.merc = investigatingMerc`
- **InvestigationService / InvestigationNotifier**: `transform` 분기 통합
- **QuestGenerator**: sector_type 필터링
- **QuestCompletionService**: 완료 후 SpecialFlagProcessor 호출
- **MercenaryStatService**: boost 타임스탬프 기반 배수 처리
- **페이즈 4-2 체인 퀘스트 spec**: `ActivityLogType.regionTransform`(15) / `chainProgressed`(16) / `chainCompleted`(17) 순서 정합 확인됨
- **페이즈 4-5 이동 선택지 spec (예정)**: `trait_acquired` effect_type이 동일 `traitLearningBoostUntil` 재사용
- **페이즈 4-6 공존 정책 spec (예정)**: Global Dialog Queue에서 `RegionTransformDialog` priority 결정

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Hive 모델 확장**: `lib/features/investigation/domain/region_state_model.dart:5-21` — typeId 유지 + append-only HiveField
- **InvestigationNotifier 분기**: `investigation_notifier.dart:133-198` — 기존 `faction_clue`/`elite` 분기 패턴 그대로 확장
- **StateProvider publish**: `lib/features/investigation/domain/investigation_completion_provider.dart` — `InvestigationCompletedProvider` 패턴 재사용
- **Freezed 필드 추가**: `lib/core/models/quest_pool.dart` — `@JsonKey(name: 'snake_case') Type? field` 추가 + `fromJson/toJson` 자동 갱신
- **RegionStateRepository CRUD**: `lib/features/investigation/data/region_state_repository.dart` (existing `updateKnowledge` / `addTriggeredDiscovery` 패턴)

### 4.2 주의사항

- **Hive typeId**: 본 spec은 typeId 신규 할당 **없음** (기존 확장만)
- **HiveField append-only**:
  - RegionState 3 / Mercenary 23 / ActiveQuest 24 / ActivityLogType 18
  - 페이즈 4-2 spec과 정합: UserData 20 / ActiveQuest 21~23 / ActivityLogType 16~17. ActiveQuest 24는 본 spec 전용
- **`Map<int, String>` Hive 직렬화**: Hive는 기본적으로 Map<dynamic, dynamic>만 지원. `Map<int, String>`은 어댑터가 runtime 캐스팅 필요. 대안: `Map<String, String>` 사용 (key를 str로 변환)
  - **결정**: `Map<String, String>` 사용 권장. key는 `sector_index.toString()`로 변환. `sectorChanges['3']` 형식
- **`Map<String, dynamic>` Hive 직렬화**: 기본 지원됨. `specialFlags`는 그대로 사용 가능
- **`discovery_data` JSONB 파싱**: 기존 `InvestigationNotifier`에서 `d.discoveryData?['faction_id'] as String?` 패턴. `transform_type`, `sector_index`, `transformed_name`, `narrative_template` 동일 방식
- **섹터 선택 UI 가정**: 기존 MovementScreen 구조에서 각 섹터를 리스트/그리드로 렌더할 것. 변형 표시 추가는 기존 아이콘 표시 로직 확장
- **체인 5/6 knowledge_threshold 88/83 조정**: balance 2-2 §7-A 권장. 본 MVP는 18행 모두 98 사용 (배치 C 현황). 후속 UPDATE 필요 시 operation-bom에서 처리
- **SpecialFlagProcessor 적용 시점**: `QuestCompletionService.calculate()`가 `QuestCompletionResult`를 반환하는 구조이므로, 호출자(`QuestCompletionNotifier` 또는 유사)가 결과 수령 후 별도로 `SpecialFlagProcessor.apply()` 호출. **또는** `QuestCompletionResult`에 `specialFlagResult` 필드 추가하여 통합 반환 (더 깔끔)
  - **결정**: `QuestCompletionResult`에 `SpecialFlagResult? specialFlagResult` 추가. `QuestCompletionService.calculate()` 내부에서 처리

### 4.3 엣지 케이스

- **변형 중복 시도**: 동일 `region_id`에 이미 transform이 트리거된 상태에서 다른 transform discovery 트리거 시도 → 리전당 1섹터 제약으로 차단. `triggeredDiscoveries`에 이미 있으면 스킵
- **변형 후 재조사**: `knowledge` 상한 100 도달 후 추가 조사 시도 → knowledge gain 0 처리 (기존 로직). transform 재트리거 없음 (triggeredDiscoveries 체크)
- **조사 용병 사망/방출**: 변형 완료 시점의 용병이 이후 사망/방출되어도 변형은 유지. 팝업 표시 중이면 `merc.name`이 "알 수 없는 용병"으로 표시될 수 있음 → TemplateEngine fallback(`[?merc.name]`)으로 안전
- **특수 플래그 미지정**: `specialFlags == {}` 또는 null → `SpecialFlagProcessor.apply()`가 empty result 반환 (no-op)
- **`guild_drop_rare` 중복 획득**: 이미 같은 guild item을 소지한 상태에서 드랍 → `UserData.artifactItemIds`에 중복 추가하지 않음. 대체 보상 없음 (MVP)
- **`trait_learning_boost` 중복 적용**: 이미 `traitLearningBoostUntil`이 미래인 용병에게 또 boost 발생 → **덮어쓰기** (연장 아님, 기획 §4-2 간결성). `now + 24h`로 재설정
- **파티 빈 채로 퀘스트 완료**: `SpecialFlagProcessor.apply()`에서 boostedMercIds 빈 리스트. 다른 플래그는 유저 전체 대상이므로 정상 처리
- **`reputation_penalty` + 성공 결과**: 기획 §5-4 "금기된 의식 중단" 성공 시 -5 명성 (유리한 결과와 함께 penalty). 예외 없이 적용
- **sector_type 값 오기재**: DB에 `village`/`ruins`/`hidden` 외 값이 있으면 `QuestGenerator`는 일반 풀로 폴백 (strict 체크 없이 null처럼 취급)

### 4.4 구현 힌트

- **진입점**:
  - 트리거: `InvestigationNotifier._completeInvestigation()` → `for (final d in newlyTriggered)` 루프에 `else if (d.discoveryType == 'transform')` 분기 추가
  - QuestGen: `QuestGenerator.generateQuests()` 시그니처 확장
  - 완료: `QuestCompletionService.calculate()` 내부에서 SpecialFlagProcessor 호출
- **데이터 흐름**:
  ```
  [조사 완료] → InvestigationNotifier
  → transform discovery 트리거 감지 → applyTransform(regionId, sectorIndex, type) → RegionState 갱신
  → regionTransformedProvider publish (narrative 렌더 완료)
  → app.dart ref.listen → RegionTransformDialog 표시
  → [다음 퀘 갱신] → QuestGenerator.generateQuests(currentSectorIndex, regionState)
  → sector_type 필터링 → specialFlags 복사
  → [파견 완료] → QuestCompletionService.calculate()
  → SpecialFlagProcessor.apply() → extraItems/Gold/Rep + 용병 boost
  ```
- **참조 구현**:
  - Hive 필드 추가: `lib/core/models/user_data.dart` 스타일
  - StateProvider publish + app.dart ref.listen: `lib/core/providers/reputation_rank_up_provider.dart` + `app.dart`
  - 조사 완료 분기 패턴: `investigation_notifier.dart:133-198`
  - Freezed JsonKey snake_case: `lib/core/models/region.dart:6-22`

## 5. 기획 확인 사항

- [Q-A] **`Map<int, String>` vs `Map<String, String>` Hive 직렬화**: Map key가 int면 Hive 캐스팅 런타임 이슈 가능. spec은 **`Map<String, String>` 사용** (key = sector_index.toString()). 접근 시 `sectorChanges['3']` → `sectorChanges[sectorIndex.toString()]` 헬퍼 제공
- [Q-B] **`QuestCompletionResult`에 `SpecialFlagResult` 통합 반환 방식**: 페이즈 4-2 체인 spec에서 `QuestCompletionResult` 필드 추가 이미 언급 없음. 본 spec에서 통합 반환 결정 → `calculate()` 내부에서 호출하여 결과 포함
- [Q-C] **MovementScreen 섹터 UI 구조**: 기존 `MovementScreen`이 섹터를 목록으로 렌더하는지 그리드로 렌더하는지 확인 필요. 둘 다 기존 스타일 유지하며 아이콘/이름/색상만 조건부 교체. → **구현 시 movement_screen.dart 확인 후 결정**
- [Q-D] **`discovery_data.narrative_template`에 `{region.name}` 외 변수 사용 빈도**: 배치 C 18행 모두 `{region.name}` + `{merc.name}` 조합만 사용. 추가 변수 확장 시 호출부 context 구성 재검토 필요. 현 MVP로 충분
- [Q-E] **체인 5/6 연관 리전 knowledge_threshold 조정 시점**: balance 2-2 §7-A Q-E "페이즈 3-2에서 리전 ID 확정 후 반영"이나 배치 C에서 일괄 98로 삽입. 후속 UPDATE로 88/83 조정은 **선택 트랙** (본 spec 범위 밖)
- [Q-F] **`specialFlags` JSONB 파싱 안정성**: JSONB에서 Dart `Map<String, dynamic>`로 변환 시 int vs double 구분(예: `drop_rate: 0.05` vs `amount: -5`). Flutter `json.decode` 기본 동작 확인 → **구현 시 SpecialFlagProcessor가 방어적 캐스팅**
- [Q-G] **팝업 순서 정합**: `RegionTransformDialog`와 `chainCompletedProvider`, `reputationRankUpProvider`의 publish가 동시 발생 시 혼잡. 페이즈 4-6 공존 정책의 Global Dialog Queue에서 priority 결정 → 본 spec은 publish만

## 6. 다음 단계

- **구현**: `/implement-agent @Docs/spec/M3/[spec]20260424_region-transform-system.md`
- **페이즈 4-5 이동 선택지 spec**: `trait_acquired` effect_type이 본 spec FR-8의 `traitLearningBoostUntil`을 재사용. 매커니즘 공유 확정
- **페이즈 4-6 공존 정책 spec**: `RegionTransformDialog` priority + 이동 화면 섹터 시각 구분 규칙 통합
