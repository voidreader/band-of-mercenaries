# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

용병단 운영 텍스트 기반 전략 시뮬레이션 모바일 게임. Flutter로 개발되며, Supabase 서버에서 정적 데이터를 동기화하고 Hive로 유저 데이터를 로컬 저장한다. 운영 웹앱은 `operation-bom` 프로젝트 참조. 기획 문서는 `Docs/proto_design.md` 참조.

핵심 게임 루프: 용병 모집 → 위치 이동 → 퀘스트 생성 → 파견 → 시간 대기 → 결과 획득 → 반복

## 개발 명령어

Flutter 프로젝트 디렉토리는 `band_of_mercenaries/`이며, 모든 Flutter/Dart 명령어는 해당 디렉토리에서 실행해야 한다.

```bash
# 의존성 설치
cd band_of_mercenaries && flutter pub get

# 코드 생성 (freezed, json_serializable, hive_generator, riverpod_generator)
cd band_of_mercenaries && dart run build_runner build

# 코드 생성 (watch 모드)
cd band_of_mercenaries && dart run build_runner watch

# 앱 실행
cd band_of_mercenaries && flutter run

# 전체 테스트
cd band_of_mercenaries && flutter test

# 단일 테스트 파일 실행
cd band_of_mercenaries && flutter test test/features/quest/domain/quest_calculator_test.dart

# 정적 분석
cd band_of_mercenaries && flutter analyze
```

모델이나 Provider를 수정한 후에는 반드시 `dart run build_runner build`를 실행하여 `.g.dart`, `.freezed.dart` 파일을 재생성해야 한다.

## 아키텍처

### 디렉토리 구조

```
band_of_mercenaries/lib/
├── main.dart              # 진입점 (Hive/Supabase 초기화 → SyncService → ProviderScope → 방치형 보상)
├── app.dart               # 앱 셸 + 하단 네비게이션 + WidgetsBindingObserver(lastActiveTime 저장, 포그라운드 싱크)
├── core/
│   ├── constants/         # GameConstants (게임 밸런스 상수)
│   ├── data/              # HiveInitializer, SupabaseInitializer, DataLoader, SyncService, SettingsKeys
│   ├── domain/            # 전역 도메인 서비스 (ActivityLog, ExperienceService, ReputationService, IdleRewardService)
│   ├── models/            # 정적 데이터 모델 (freezed + json_serializable) + UserData (Hive)
│   ├── providers/         # 전역 상태 (game_state, static_data, timer, navigation)
│   └── theme/             # Material 3 테마, 티어별 색상
├── features/              # 기능별 모듈
│   ├── home/              # 홈(야영지) 화면
│   ├── movement/          # 이동 시스템, TravelEventService, MovementState
│   ├── quest/             # 퀘스트/파견 시스템, QuestCompletionService
│   ├── facility/          # 시설 시스템 (건설 큐, ConstructionService, 시설 탭 UI)
│   ├── mercenary/         # 용병 모집/관리, FacilityService, RecruitmentService
│   │   └── view/          # MercenaryDetailOverlay, MercenaryCard, TraitDetailDialog, TraitEvolutionDialog
│   │                      # TraitSlotGrid, TraitHistorySection, BehaviorStatsSection, EquipmentSlotGrid
│   │                      # MercenaryProfileHeader(StatChip/XpBar), MercenaryRoleSynergySection
│   │                      # TraitEvolutionSection, TraitSynergyConflictSection, RecruitScreen
│   ├── investigation/     # 지역 조사 시스템 (InvestigationNotifier, RegionStateRepository, InvestigationWidget)
│   ├── chain_quest/       # 연계 퀘스트 시스템 (ChainQuestService, ChainQuestRepository, ChainStepCard, ChainCompletedDialog)
│   ├── info/              # 정보 탭 (InfoScreen, FactionCodexScreen, FactionDetailScreen, FactionStateRepository, FactionJoinService)
│   │   └── view/          # FactionDetailScreen, FactionCodexScreen, RankInfoScreen, GuildEquipmentScreen
│   │                      # FactionTopBar, FactionJoinSection(ReputationBar/JoinConditions/ConditionRow/VisibilityBadge)
│   └── settings/          # 설정 (시간 가속)
└── shared/widgets/        # 공유 위젯 (BottomNavBar, TimerDisplay, StatusBadge, TierBadge, CardContainer, EmptyStateWidget)
```

### feature 모듈 구조

각 feature는 `view/`, `domain/`, `data/` 3계층으로 분리:
- **view**: 화면 위젯. Screen 파일 + 분리된 하위 위젯 파일들 (모두 `view/` 폴더 내 배치)
- **domain**: 비즈니스 로직 (Notifier, Calculator, Service)
- **data**: Repository (Hive 박스 접근)

UI 리팩토링 정책은 `Docs/flutter-ui-refactor.md` 참조. 주요 규칙:
- Provider를 읽으면 ConsumerWidget, 로컬 상태만 필요하면 StatefulWidget
- 공통 위젯은 `shared/widgets/`에 배치 (동일 패턴 3개 파일 이상 반복 시)
- 화면 전환은 Navigator.push 대신 상태 기반 렌더링 사용
- 스타일(TextStyle/Color)은 `core/theme/` 중앙 관리, `shared/styles/` 생성 금지

### 상태 관리

**Flutter Riverpod** 사용. 주요 Provider:
- `gameTickProvider`: 1초 간격 Stream으로 게임 루프 구동 (퀘스트 완료, 이동 도착, 건설 완료 체크)
- `userDataProvider`: 전역 게임 상태 (골드, 위치, 이동 상태)
- `staticDataProvider`: 로컬 JSON 캐시에서 로드된 정적 데이터 (Region, Job, Trait 등). 앱 시작/포그라운드 복귀 시 Supabase와 버전 비교 후 갱신
- `mercenaryListProvider` / `questListProvider`: 용병 및 퀘스트 상태
- `activityLogProvider`: 활동 로그 (Hive `activityLogs` 박스, 최대 100개)
- `currentTabProvider`: 하단 네비게이션 탭 인덱스 (`core/providers/navigation_provider.dart`)
- `constructionCompletedProvider`: 건설 완료 알림 (`features/facility/domain/construction_completion_provider.dart`)
- `reputationRankUpProvider`: 명성 랭크 상승 이벤트 채널 StateProvider<RankUpEvent?> (`core/providers/reputation_rank_up_provider.dart`). `UserDataNotifier.addReputation`이 publish, `app.dart`가 `ref.listen`으로 감지하여 `RankUpOverlay`를 `showDialog`로 표시 (닫기 시 오버레이가 `state = null` 리셋)
- `investigationNotifierProvider`: 지역 조사 시작/완료 로직 (`features/investigation/domain/investigation_notifier.dart`)
- `investigationCompletedProvider`: 조사 완료 알림 StateProvider<InvestigationResult?> (`features/investigation/domain/investigation_completion_provider.dart`)
- `factionStateRepositoryProvider`: FactionStateRepository 인스턴스 (`features/info/data/faction_state_repository.dart`)
- `factionListProvider`: staticDataProvider의 factions를 동기 제공하는 Provider<List<FactionData>> (`features/info/domain/faction_codex_providers.dart`)
- `factionCodexScrollTargetProvider`: 조사 완료 팝업 → 세력 도감 자동 스크롤용 StateProvider<String?> (`features/info/domain/faction_codex_providers.dart`)
- `factionRefreshProvider`: 세력 가입/탈퇴·평판 변경 후 FactionCodexScreen·FactionDetailScreen 강제 갱신용 StateProvider<int> 카운터 (`features/info/domain/faction_codex_providers.dart`)
- `pendingEliteLootProvider`: 엘리트 드랍 결과를 도메인→뷰 계층으로 전달하는 StateProvider<Map<String, EliteLootResult>> (`features/quest/domain/quest_provider.dart`). `pendingTraitEventsProvider`와 동일 패턴. 퀘스트 완료 시 저장, `_showResult`에서 읽고 `QuestResultDialog`에 전달 후 제거
- `chainQuestServiceProvider`: Provider<ChainQuestService> — 연계 퀘스트 순수 서비스 (`features/chain_quest/domain/chain_quest_provider.dart`)
- `chainQuestProgressProvider`: StreamProvider<List<ChainQuestProgress>> — Hive `chainQuestProgress` 박스 watch 스트림
- `activeChainProvider`: Provider<ChainQuestProgress?> — 현재 활성 연계 퀘스트 단계 (currentStepAvailableAt 기준 정렬, 1개만 노출)
- `chainCompletedProvider`: StateProvider<ChainCompletedEvent?> — 체인 완주 이벤트 채널. `ChainQuestService.completeChain`이 publish, `app.dart`가 `ref.listen`으로 감지하여 `ChainCompletedDialog`를 `showDialog(barrierDismissible: false)`로 표시 (onDismiss 콜백에서 `state = null` 리셋)
- `regionTransformedProvider`: StateProvider<RegionTransformedEvent?> — 지역 변형 이벤트 채널 (`features/investigation/domain/region_transformed_provider.dart`). `InvestigationNotifier`가 `transform` discovery_type 완료 시 publish, `app.dart`가 `ref.listen`으로 감지하여 `RegionTransformDialog`를 `showDialog(barrierDismissible: false)`로 표시
- `currentRegionSectorChangesProvider`: Provider<Map<String, String>> — 현재 리전의 sectorChanges 반응적 제공 (`features/investigation/domain/region_transformed_provider.dart`). `userDataProvider`(리전 변경) + `regionTransformedProvider`(변형 이벤트)를 watch하여 자동 갱신. MovementScreen이 data 레이어 직접 접근 없이 변형 섹터 정보를 조회
- `templateEngineProvider`: Provider<TemplateEngine> — 스테이트리스 템플릿 엔진 (`core/providers/template_engine_provider.dart`). 변수 치환 `{namespace.field}`, 조건 분기 `[if]...[/if]`, 랜덤 변주 `[pick A|B]` 지원. `TemplateContext`(user, merc, region, factionStates 등)로 렌더
- `pendingTravelChoiceProvider`: StateProvider<TravelChoiceRecallData?> — 이동 선택지 이벤트 채널 (`features/movement/domain/travel_choice_recall_provider.dart`). `MovementNotifier._triggerChoiceRecall()`이 이동 완료 시 publish, `home_screen.dart`가 `ref.listen`으로 감지하여 `dialogQueueProvider.enqueue()`로 medium priority 등록 (큐 통합 후 직접 showDialog 미수행)
- `dialogQueueProvider`: StateNotifierProvider<DialogQueueNotifier, List<DialogRequest>> — 전역 다이얼로그 우선순위 큐 (`core/providers/dialog_queue_provider.dart`). `DialogPriority`(critical/high/medium/low) desc + FIFO + id dedup. `enqueue(DialogRequest)` 시 인메모리 정렬 삽입 + Hive `dialogQueue` 박스(`PersistedDialogEntry` typeId:15) 영속화. `dequeue()`는 head pop. 앱 시작 시 `DialogQueuePersistence.loadValid()`로 24h 이내 + 등록된 dialogType만 복원, 만료/실패 항목은 ActivityLog "알림 일부 유실됨" 기록. `app.dart`가 단일 `ref.listen`으로 큐 head를 `_isShowingDialog` 플래그 + `mounted` 가드 + `addPostFrameCallback`으로 `showDialog` 표시. `DialogTypeRegistry`는 dialogType String → builder 매핑 키 상수(`constructionComplete`/`investigationResult`/`rankUp`/`autoTravelEvent`/`travelChoiceRecall`/`chainCompleted`/`regionTransform` 7종). 5개 도메인 채널(construction=medium / investigation=medium / rankUp=critical / chainCompleted=high / regionTransform=high) 모두 큐 어댑터로 통합. **dismiss 일관성**: 모든 채널이 `enqueue(...)` 직후 즉시 `xxxProvider.notifier.state = null` 호출, builder/onDismiss 콜백은 `dismiss` 단순 참조만 (state 리셋 책임 listen 콜백으로 일원화)
- `sortedPendingQuestsProvider`: Provider<QuestSortResult> — 파견 화면 정렬 메모이제이션 derived Provider (`features/quest/domain/sorted_quests_provider.dart`). `gameTickProvider`(1초 주기) 변경과 무관하게 입력(`questListProvider`/`chainQuestProgressProvider`/`userDataProvider`/`staticDataProvider` + 무효화 트리거 `currentRegionSectorChangesProvider`/`factionRefreshProvider`) 변경 시에만 `QuestSortService.sort()` 재실행. dispatch_screen이 단일 watch로 5계층 정렬 결과 사용

### 데이터 흐름

```
앱 시작 → SyncService (Supabase data_versions 비교) → 변경 테이블 다운로드 → 로컬 JSON 캐시 저장
로컬 JSON 캐시 → DataLoader → StaticGameData → FutureProvider
사용자 액션 → Repository → Hive 저장 → StateNotifier → UI 갱신
게임 틱 (1초) → 완료 체크 → 자동 결과 계산
포그라운드 복귀 → SyncService → 변경 시 staticDataProvider 무효화
```

### 정적 데이터 (Supabase 동기화)

정적 데이터는 Supabase 서버에서 관리되며, operation-bom 웹앱에서 편집/버전 발행한다. Flutter 앱은 로컬 JSON 캐시(`앱 문서 디렉토리/cache/*.json`)에 저장하여 오프라인에서도 동작한다.

**동기화 방식:**
- 첫 실행: 서버 연결 필수, 전체 20개 테이블 다운로드
- 이후 실행: `data_versions` 테이블로 버전 비교, 변경된 테이블만 다운로드
- 서버 연결 실패 시: 로컬 캐시로 오프라인 플레이 가능 (캐시 있는 경우)
- 싱크 타이밍: 앱 시작 + 포그라운드 복귀

**정적 데이터 테이블 (25개):**
- regions: 40개 리전 (M4 페이즈 4 #1에서 199→40 축소, 5단계 티어). `environment_tags` JSONB 컬럼 (엘리트 몬스터 스폰 환경 필터 — 예: `["forest","dungeon"]`). `sector_count` INT NOT NULL DEFAULT 4 CHECK 1..6 컬럼(M4 페이즈 4 #2): 동적 섹터 개수, 4개 region(1·23·127·146) = 5, 나머지 36 = 4. `Region.sectorCount` 필드(@JsonKey 'sector_count', @Default 4)로 매핑. MovementScreen이 `List.generate(targetRegion.sectorCount, ...)`로 동적 그리드 렌더링.
- jobs: 5티어 85개 직업. `role` 컬럼(text NOT NULL DEFAULT 'specialist')으로 파견 상성 매트릭스 조회 키 보유 — warrior 26 / specialist 16 / mage 16 / support 10 / ranger 9 / rogue 8
- trait_categories: 8개 트레잇 카테고리 (Physical, Background, Talent, CombatStyle, Survival, Behavior, Mental, Experience)
- traits: 106개 트레잇 (선천 35 + 후천 acquired 40 + 후천 evolved 31). key/name/categoryKey/type/description/effectText/acquisitionCondition/effectJson
- trait_conflicts: 충돌 관계 (16쌍, 양방향 32행)
- trait_transitions: 단일 진화 경로 (16개, condition_json으로 복합 조건)
- trait_combo_evolutions: 조합 진화 레시피 (15개)
- trait_synergies: 선천-후천 시너지 (39개, 획득 조건 완화 비율)
- difficulties: 5단계 난이도 설정 (min_dispatch_cost/max_dispatch_cost로 시간 비례 비용)
- quest_types / quest_pools: 퀘스트 유형 및 풀. `quest_pools` 세력 태그 확장 컬럼: `type_id`(text NOT NULL DEFAULT 'raid', 신규 유형 참조용), `faction_tag`(text nullable FK → factions.id, 전용 퀘스트 고정 세력), `is_faction_exclusive`(bool NOT NULL DEFAULT false), `min_reputation`(int NOT NULL DEFAULT 0, 전용 퀘스트 해금 임계 기본 11 / 고급 61), `sector_type`(text nullable, M3 대비 필드), `enemy_name`(text nullable, 퀘스트 서사 `{quest.enemy}` 치환용). 기존 `type` real 필드는 deprecated 유지. 세력 전용 퀘스트 98행(14세력 × 7개) 포함, 총 298행
- person_names: 한국어 이름 ~500개
- travel_events: 이동 중 랜덤 이벤트 (발견, 습격, 날씨, 행운, 조우)
- facilities: 시설 종류 및 레벨별 비용/효과 (훈련소, 의무실, 주둔지, 정보망)
- ranks: 명성 등급 (F~A) 및 티어 잠금 해제 조건
- mercenary_wages: 티어별 용병 인건비
- region_discoveries: 리전별 발견 데이터 (id TEXT PK, region_id INTEGER, knowledge_threshold INTEGER, discovery_type TEXT, discovery_data JSONB, description TEXT). M4 페이즈 4 #2에서 region 18·23·146 transform 행 sector_index 재매핑(0-based 한도 외 행 보존용 — region 18: ≥4 → 1 / region 23·146: ≥4 → 4)
- region_sectors: 섹터 정규화 테이블 (id TEXT PK 명명규칙 `r{region_id}_s{sector_index}`, region_id INT FK→regions(region) ON DELETE CASCADE, sector_index INT CHECK 1..6 — **1-based**, name TEXT, sector_type TEXT CHECK IN ('village','ruins','hidden','dungeon','field'), environment_tags JSONB DEFAULT '[]', description TEXT, UNIQUE(region_id, sector_index)). M4 페이즈 4 #2 시점 0행 — 시드 ~164행은 후속 페이즈 위임. 더스트플레인(region 3) 4섹터는 `RegionSectorFallback.dustplainSectors` 코드 상수로 인라인. `RegionSectorFallback.lookupSector(regionId, sectorIndex, regionSectors)`가 staticData → fallback(region 3 한정) → null 우선순위 조회. MovementScreen `_SectorTile`이 sectorChanges(M3 변형 0-based) → lookupSector(데이터/fallback)?.sectorType 우선순위로 sector_type 결정. dungeon/field는 MovementScreen 그리드 한정 시각(LayerSidebar/QuestCardBadges 미반영) — `AppTheme.sectorDungeon`(0xFFB71C1C) ⛏️ / `AppTheme.sectorField`(0xFF558B2F) 🌾
- factions: 세력 마스터 데이터 (id TEXT PK, name TEXT, description TEXT, philosophy TEXT, tier_range JSONB, color TEXT, visibility_type TEXT DEFAULT 'public', join_rank_min TEXT nullable, join_needs_clue BOOLEAN DEFAULT false, passive_bonus_json JSONB DEFAULT '{}', conflict_faction_ids JSONB DEFAULT '[]'). 14개: 공개 6 / 비밀 4 / 지역 4
- elite_monsters: 엘리트 몬스터 마스터 데이터 (id TEXT PK, name TEXT, description TEXT, tier INT, environment_tags JSONB, combat_power INT, is_unique BOOL, title TEXT nullable, lore TEXT nullable, min_region_tier INT, max_region_tier INT). 보통 31종 + 유니크 8종 = 39종
- elite_loot_tables: 엘리트 드랍 테이블 (id TEXT PK, elite_id TEXT FK, item_id TEXT nullable, bonus_gold INT, drop_weight INT, min_difficulty INT). 209행
- chain_quests: 연계 퀘스트 단계 데이터 (id TEXT PK, chain_id TEXT, chain_name TEXT, step INT, total_steps INT, region_id INT nullable, target_region_id INT nullable, target_sector_id INT nullable, name TEXT, description TEXT, quest_type_id TEXT, difficulty INT, combat_power INT, reward_gold INT, reward_xp INT, reward_items JSONB, final_reward BOOL, final_reputation_bonus INT nullable, duration_seconds INT, next_step_delay_seconds INT, faction_tag_id TEXT nullable). 7체인 24단계. `target_sector_id`는 1-based(1..10) sector 인덱스 — null이면 region 전체 하이라이트 fallback. MovementScreen이 `Map<int, Set<int?>>` 자료구조로 region+sector 매칭(`null in set` → 전체, `sector in set` → 직접)
- quest_narratives: 퀘스트 서사 템플릿 (id TEXT PK, quest_type TEXT, result_type TEXT — greatSuccess/success/failure/criticalFailure, is_elite BOOL DEFAULT false, template TEXT, weight INT DEFAULT 1, description TEXT nullable). 88행 (raid/hunt/escort/explore × 4결과 × 4변형 + labor/survey 각 8 + 엘리트 raid/hunt 각 4). `QuestNarrativeService.pickTemplate()`이 quest_type × result_type × is_elite 3중 필터 + weight 가중 랜덤 선택 → TemplateEngine 렌더 → `ActiveQuest.renderedNarrative` 저장
- travel_choice_events: 이동 선택지 이벤트 (id TEXT PK, name TEXT, category TEXT, situation TEXT, min_tier INT, max_tier INT, weight INT DEFAULT 1, preferred_traits TEXT nullable). 12행
- travel_choice_options: 선택지 옵션 (id TEXT PK, event_id TEXT FK, choice_index INT, label TEXT, visibility_expr TEXT nullable, description TEXT, risk_level TEXT — safe/risky/hidden). 30행
- travel_choice_results: 선택지 결과 (id TEXT PK, option_id TEXT FK, result_index INT, probability REAL, conditional_expr TEXT nullable, narrative TEXT, effect_type TEXT, effect_magnitude REAL DEFAULT 0.0, effect_target TEXT nullable). 72행. `TravelChoiceService.resolveResult()`가 probability + conditional_expr 평가 후 결과 선택

**모델 JSON 키 규칙:** 모든 정적 데이터 모델은 snake_case @JsonKey를 사용 (Supabase 컬럼명과 일치). Dart 필드명과 동일한 경우 @JsonKey 생략.

### Supabase 연결

- `supabase_flutter` 패키지 사용
- `.env` 파일에 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 설정 (gitignored)
- `.env.example`에 템플릿 존재
- 현재 인증 없이 anon key로 읽기 전용 접근 (향후 로그인 추가 예정)

### 영속성

**Hive** (NoSQL key-value): 10개 박스. Hive 어댑터는 `hive_generator`로 자동 생성.
- `settings`: 일반 key-value (SettingsKeys 참조)
- `user`: UserData (골드, 위치, 이동/건설/조사 상태)
- `mercenaries`: Mercenary 모델
- `quests`: ActiveQuest 모델
- `activityLogs`: ActivityLog 모델 (최대 100개). `ActivityLogType` enum 확장(@HiveField(13) `reputationRankUp` / @HiveField(14) `reputationRankDown`, typeId 6 유지)
- `staticDataCache`: String 타입, 정적 데이터 JSON 로컬 캐시 (오프라인 플레이용, SyncService가 관리)
- `regionStates`: RegionState 모델 (typeId:8)
- `factionStates`: FactionState 모델 (typeId:9)
- `chainQuestProgress`: ChainQuestProgress 모델 (typeId:13)
- `dialogQueue`: PersistedDialogEntry 모델 (typeId:15) — 다이얼로그 큐 영속화 (24h 만료, builder 클로저 미저장, dialogType + payloadJson만 저장)

상세 필드 구조:
- `mercenaries` 박스: Mercenary 모델 — HiveField(4) `str` (int), HiveField(5) `intelligence` (int), HiveField(6) `vit` (int), HiveField(7) `agi` (int, 기존 double speed에서 변환). HiveField(14) `stats` (Map<String, int>, 23개 행동 지표), HiveField(15) `traitIds` (List<String>, 복수 트레잇), HiveField(16) `traitHistory` (List<String>, 소멸/삭제 트레잇 기록 → 재획득 방지), HiveField(17) `deletedTraitIds` (List<String>, 삭제된 트레잇 기록 → 히스토리 UI에서 (삭제) 구분 표시). HiveField(23) `traitLearningBoostUntil` (DateTime?, 트레잇 학습 부스트 만료 시각 — null이면 부스트 비활성). `allTraitIds` getter로 구 traitId 호환. 앱 첫 실행 시 `stat_migration_v2` 플래그(settings 박스)로 일회성 데이터 초기화 수행
- `user` 박스 건설 큐: HiveField(12) `constructionFacilityId` (String?, 건설 중 시설 ID), HiveField(13) `constructionStartTime` (DateTime?), HiveField(14) `constructionEndTime` (DateTime?)
- `user` 박스 지역 조사: HiveField(15) `investigatingMercId` (String?, 조사 중 용병 ID), HiveField(16) `investigationEndTime` (DateTime?), HiveField(17) `investigationRegionId` (int?)
- `regionStates` 박스: RegionState 모델 (typeId:8) — regionId(int), knowledge(int 0~100), triggeredDiscoveries(List<String>), HiveField(3) `sectorChanges` (Map<String, String>, 변형된 섹터 맵 key=섹터인덱스 문자열 "0"~"9" / value="village"|"ruins"|"hidden", 기본값 {}). 리전당 최대 1섹터 변형 (MVP 제약). regionId 키로 저장
- `factionStates` 박스: FactionState 모델 (typeId:9) — factionId(String), clueRecords(List<FactionClueRecord>), HiveField(2) reputation(int?, null-safe 하위호환), HiveField(3) joined(bool?), HiveField(4) joinedAt(DateTime?), HiveField(5) facilityLevels(Map<String,int>?). `isJoined` getter(joined ?? false), `currentReputation` getter(reputation ?? 0), `maxClueLevel` getter(고유 discoveryId 수, 0~3). `discoveredInRegions` getter로 고유 리전 ID 계산. FactionClueRecord(typeId:10) — factionId, regionId, discoveryId, foundAt. `FactionStateRepository`로 CRUD (join/leave/addReputation/setReputation/applyConflictPenalty/getJoinedFactionIds). 순수 정적 서비스 `FactionJoinService`(`features/info/domain/faction_join_service.dart`)로 가입 조건 판정·평판 클램프·패시브 설명 처리
- `settings` 박스: 일반 key-value. 키는 `SettingsKeys` 상수 클래스(`core/data/settings_keys.dart`)에서 중앙 관리. `factionQuestCooldowns` 키는 전용 퀘스트 6시간 쿨다운 맵(`{questId: ISO8601}` JSON 문자열). 접근 시마다 lazy cleanup 수행
- `quests` 박스 세력 태그 확장: HiveField(17) `factionTag` (String?, 런타임 부여된 세력 태그 또는 전용 퀘스트 고정 세력), HiveField(18) `reputationReward` (int?, 완료 시 지급될 세력 평판 값, 생성 시점에 미리 계산), HiveField(19) `isAdvancedTrack` (bool?, 전용 퀘스트 트랙 구분: null=일반, false=기본, true=고급). `isFactionExclusive` getter(`isAdvancedTrack != null`)로 전용 퀘스트 판별
- `quests` 박스 체인 퀘스트 확장: HiveField(20) `eliteId` (String?, 엘리트 몬스터 ID), HiveField(21) `isChainStep` (bool?), HiveField(22) `chainId` (String?), HiveField(23) `chainStep` (int?). `isChainQuest` getter(`isChainStep ?? false`), `isElite` getter(`eliteId != null`). 체인 단계는 `QuestListNotifier.injectChainStep(ChainQuestData, userRegion)`으로 대기열에 삽입
- `quests` 박스 지역 변형 확장: HiveField(24) `specialFlags` (Map<String, dynamic>?, 퀘스트 풀의 특수 플래그 런타임 복사. null=일반 퀘스트). `SpecialFlagProcessor.apply()`가 완료 시 처리 — 6종: `trait_learning_boost`(용병 트레잇 학습 지표 2배, n분간) / `guild_drop_rare`·`guild_drop_ultra_rare`(길드 장비 드랍, 희귀/초희귀) / `essence_drop_bonus`(정수 드랍) / `equipment_drop_bonus`(personal_equipment tier 3~4 드랍) / `reputation_penalty`(퀘스트 결과 무관 평판 차감). 보상 5종은 success/greatSuccess 시만 적용, penalty는 항상 적용
- `quests` 박스 서사 확장: HiveField(25) `renderedNarrative` (String?, 완료 시점 1회 렌더된 서사 문자열. `QuestNarrativeService.renderNarrative()`가 seed 고정 후 생성, 이후 재렌더 금지). 체인 퀘스트는 null 유지 (`chain_quests.description` 사용)
- `user` 박스 체인 퀘스트: HiveField(20) `completedChains` (List<String>, 완료된 체인 ID 목록). `completedChainSet` getter로 Set 변환
- `user` 박스 이동 선택지: HiveField(21) `choiceEventId` (String?, 이동 완료 시 롤된 선택지 이벤트 ID. 앱 재시작 시 recall 복원용. 팝업 표시 후 null 초기화)
- `chainQuestProgress` 박스: ChainQuestProgress 모델 (typeId:13) — chainId(String), currentStep(int), status(ChainQuestStatus typeId:14: active/completed/dormant), startedAt, completedAt?, protagonistMercId?, currentStepAvailableAt?, stepFailureCount, lastActivityAt?. `ChainQuestRepository`로 CRUD + watchAll Stream. 14일 미활동 시 dormant 전환, 탭으로 재활성화
- `activityLogs` 박스 체인 퀘스트 확장: `ActivityLogType` enum HiveField(18) `regionTransform` / HiveField(19) `chainProgressed` / HiveField(20) `chainCompleted`
- `activityLogs` 박스 이동 선택지 확장: `ActivityLogType` enum HiveField(21) `travelChoiceCompleted`
- `dialogQueue` 박스: PersistedDialogEntry 모델 (typeId:15) — id(String, 중복 방지), priority(int, DialogPriority.index), dialogType(String, DialogTypeRegistry 키), payloadJson(String, jsonEncode 직렬화), enqueuedAt(DateTime, 24h 만료 기준). builder 클로저는 직렬화 불가하여 메모리 전용. `DialogQueuePersistence`로 CRUD + 24h 만료/미등록 dialogType 필터/복원 실패 시 박스 비움 + ActivityLog 기록. typeId 15는 11(InventoryItem)/13(ChainQuestProgress)/14(ChainQuestStatus) 점유로 12 또는 15 중 충돌 회피로 선택

### 코드 생성

freezed, json_serializable, hive_generator, riverpod_generator 4종을 `build_runner`로 관리. 생성된 파일은 `.g.dart`, `.freezed.dart` 확장자.

## 게임 핵심 시스템 로직

- **이동**: 거리 = |리전 차이| + |섹터 차이|, 소요시간 = 거리 × 30초. 이동 중 TravelEvent 랜덤 발생 (골드, 부상, 지연, 명성, 선천 트레잇 부여 등). `trait_innate` 이벤트는 빈 선천 슬롯 보유 용병에게 선천 트레잇 부여 (조건 미충족 시 최대 3회 재롤링)
- **용병 스탯**: STR(기본 공격력) / INTELLIGENCE(스킬 공격력, 추후 스킬 시스템 연동) / VIT(체력+방어력 통합) / AGI(이동속도+회피, 기존 speed 대체). `effectiveStr/Intelligence/Vit/Agi` getter로 레벨 보너스 + 피로 디버프 반영
- **partyPower**: `Σ(str×w_str + intelligence×w_int + vit×w_vit + agi×w_agi)`. 퀘스트 유형별 가중치 (`QuestCalculator._statWeights`): raid(STR 0.70), hunt(STR 0.50/AGI 0.30), escort(VIT 0.60), explore(INT 0.45/AGI 0.30). 파견 시간은 파티 평균 AGI 기반 보정(`partyAverageAgi / 50.0`)
- **성공률**: 50% + (partyPower/enemyPower - 1) × 50% + 특성보너스 + 퀘스트보정 - 거리패널티 + 랜덤편차, 범위 5%~95%
- **결과**: 대성공(보상 2배) / 성공 / 실패(부상) / 대실패(사망률 증가)
- **경제**: 파견비용(난이도별 min~max, 소요시간 비례 보간) + 인건비(용병 티어별) 선차감, 순수익 = 보상 - 인건비 - 파견비용
- **경험치/레벨**: 퀘스트 완료 시 XP 획득 (난이도 × 기본XP × 결과배수 + 시설보너스), 최대 레벨 5
- **명성/랭크**: 퀘스트 완료 시 명성 획득, 등급 F~A, 랭크에 따라 상위 티어 리전 잠금 해제. `ReputationService.getRankChain(reputation, ranks)`로 F~현재 랭크까지 누적 리스트 조회, `getRankLevel(reputation, ranks)`이 인덱스 반환(빈 체인 시 -1). `UserDataNotifier.addReputation`이 oldLevel/newLevel 비교 후 상승 시 `reputationRankUpProvider`에 `RankUpEvent(from, to, newEffects=PassiveEffect.parseEffects(newRank.bonusJson))` publish + `ActivityLogType.reputationRankUp` 로그 기록. 하향(M2a 대비 stub)은 `reputationRankDown` 로그만 기록하고 UI 알림 미발생. 누적 보너스는 `PassiveBonusService.collect`가 내부에서 rankChain 필터링하여 자동 처리(`PassiveBonusContext` 헬퍼로 `Ref/WidgetRef`에서 일괄 수집). `PassiveBonusFormatter.format(PassiveEffect)`이 17개 효과 타입을 한국어 표시 문자열로 변환
- **시설**: 12종, 최대 Lv25, 건설 큐 1개(한 번에 하나만 건설). 골드 비용 + 건설 시간(Lv1: 5분, Lv2: 10분, Lv3+: `25×1.45^(Lv-3)` 분). 효과 로그 스케일(`maxEffect × ln(1+level×α) / ln(1+25×α)`). 비용 4티어: Core(300G)/Standard(500G)/Premium(700G)/Expensive(1,000G), 배율 1.5. `ConstructionService`로 공식 계산, `FacilityService`는 wrapper. 건설 완료는 gameTickProvider에서 체크. 시간 가속 적용. 기능 해금 이정표는 milestones JSONB로 정의(현재 stub). 시설 목록: 훈련소(XP)/의무실(회복+트레잇삭제)/주둔지(용병상한)/정보망(퀘스트수)/대장간(장비stub)/주점(모집확률)/연구소(조사stub)/방어시설(피해감소)/금고(방치보상)/게시판(품질stub)/이동수단(이동시간)/야전병원(부상감소)
- **용병 상태**: 정상 → 피곤함(능력치 80%, 5분) → 부상(난이도×10분) → 사망(영구 제거). 레벨업 시 능력치 증가
- **모집**: 티어별 확률 가중 (Tier1: 45%, Tier2: 30%, Tier3: 15%, Tier4: 8%, Tier5: 2%). 선천 트레잇 1~3개 랜덤 부여 (Physical/Background/Talent 각 60% 확률, 최소 1개). 주둔지 용량 제한
- **트레잇 시스템**: 선천(최대 3, 영구) + 후천(최대 4, 획득/진화/삭제). `MercenaryStatService`로 23개 행동 지표 추적 → 퀘스트 완료 시 `TraitAcquisitionService`가 조건 체크 → 자동 획득. `TraitEffectService`로 effect_json 기반 성공률/데미지 보정. 충돌 관계 검증 포함(`hasConflict` public static). `TraitEvolutionService`로 단일 진화(acquired → evolved, conditionJson 충족 시 교체) + 조합 진화(2개 acquired → evolved, 원본 소멸 + 슬롯 해방). `TraitDeletionService`로 후천 트레잇 삭제(acquired 200G/evolved 500G, 의무실 레벨 해금). 소멸/삭제 트레잇은 `traitHistory`에 기록되어 재획득 방지. 퀘스트 완료 시 획득은 자동 적용 후 알림 팝업, 진화는 `pendingTraitEventsProvider`를 통해 UI에서 카드 비교형 선택 팝업으로 플레이어가 경로 결정 (보류 가능). 여행 이벤트로 빈 선천 슬롯에 트레잇 부여 가능 (`lastTravelEventTraitResultProvider`로 결과 전달). 진화 적용 자체는 `MercenaryListNotifier.applyEvolution(mercId, EvolutionChoice)`이 domain 레이어에서 처리 (Repository 호출 + 트레잇 이름 lookup + ActivityLog 기록 + state refresh) — view는 위임만 수행. `EvolutionChoice`는 `features/mercenary/domain/evolution_choice.dart`의 단순 데이터 클래스 (single/combo 분기)
- **방출**: 파견 중이 아닌 용병을 퇴직금(인건비×레벨) 지급 후 영구 방출. 재모집 불가
- **퀘스트 갱신**: 대기 중 퀘스트는 1시간(게임 시간)마다 자동 교체. 5개 미만이면 채우기 가능
- **세력 태그 + 전용 퀘스트**: `FactionTagResolver.resolve()`가 일반 퀘스트 생성 시 런타임으로 세력 태그 부여. 가입 세력 단서 보유 → 100%, 비가입 세력은 거점 근접도 기반 확률(tier 1: 30% / 2: 20% / 3(M1 기본): 10% / 4: 5%). 적대 세력(평판 -100) 제외. 태그 퀘스트 완료 시 평판 +1 or +2(근접도). `quest_pools.is_faction_exclusive = true`인 전용 퀘스트는 가입 세력 + `min_reputation` 충족 + 6h 쿨다운 미포함 조건으로만 노출. 노출 상한 `min(joinedCount×2, activeSlotCount×0.5)`. 전용 퀘스트는 기본 트랙(평판 11, 보상 +0.30) / 고급 트랙(평판 61, 보상 +0.40) 구분, 완료 시 평판 5~7 / 8~10 지급. 보상 공식은 `QuestCalculator.calculateReward`에 `trackBonus + passiveRewardBonus` 가산 상한 +0.80 clamp로 통합(`rankRewardBonus`는 `passiveEffects`에 포함되어 중복 방지). 전용 퀘스트 완료 시 `settings` 박스의 `factionQuestCooldowns` 맵에 `questId + now()` 기록, 6시간 경과 후 자동 재노출
- **파견 상성**: `RoleSynergyMatrix` 6개 role × 4개 quest_type 정적 상수(−2 ~ +8). `QuestCalculator.calculateSuccessRate`에 `partyRoles` 파라미터 + `RoleUtils.extractRoles(mercs, jobs)`로 파티 평균 보정값 계산, ±10%p 독립 상한 클램프. 트레잇 시너지도 `traitBonus.clamp(-10.0, 10.0)` 별도 독립 상한. `calculateSuccessRateBreakdown()` static 메서드가 `SuccessRateBreakdown` 값 객체를 반환하여 레이어별(기본값/파티력/유형/상성/트레잇/세력 패시브/공유 상한 손실/거리 패널티) 분해 제공. `PassiveBonusService.getQuestSuccessRateBonusWithDetail()`이 `(rawSum, applied, lossAmount)` 레코드로 공유 상한 +20%p 초과 손실량 노출. `rankBonus` 필드는 `PassiveBonusService`가 이미 랭크 효과를 포함하므로 `0.0 stub`으로 유지(중복 가산 방지)
- **방치형 보상**: 앱 미접속 시간 기준 분당 1G, 최대 480G(8시간) + 금고 시설 보너스. 실제 시간 기준
- **지역 조사**: 용병 1명을 현재 리전에 배치하여 지식 포인트(knowledge 0~100) 누적. 성공률 = `(85 + (AGI+VIT)/200).clamp(5,95)%`. 소요시간 리전 티어별(T1=5분~T5=20분). 지식 임계값 도달 시 `region_discoveries` 발견 자동 트리거. 파견·이동과 독립된 별도 슬롯. `InvestigationNotifier`(StateNotifier<void>)가 완료 처리, 결과는 `investigationCompletedProvider`(StateProvider<InvestigationResult?>)로 전달
- **시간 가속**: 속도 변경 시 모든 활성 타이머(퀘스트, 이동, 건설, 조사)의 endTime을 비례 재계산 (개발/테스트용)
- **이동 제한**: 파견 중인 용병이 있거나 조사 진행 중이면 이동 불가. 조사 중에도 이동 불가 (양방향 상호 배제)
- **세력 발견**: 지역 조사 완료 시 `region_discoveries`의 `discovery_type == 'faction_clue'` 항목이 트리거되면 세력 단서를 발견. `discovery_data` JSON에서 `faction_id`, `clue_level`(1~3), `clue_text` 추출 → `FactionStateRepository.processClue()`로 Hive 저장. 동일 discoveryId 중복 발견 시 기록만 추가(maxClueLevel 유지). clue_level별 활동 로그: level1 "세력 단서 발견", level2 "세력 발견: {name}의 정체를 파악했다", level3 "거점 발견: {name}의 전초기지 위치를 파악했다". 조사 완료 팝업에 인라인 표시 + "도감에서 확인" 버튼으로 정보 탭 → 세력 도감 자동 이동
- **엘리트 몬스터**: 퀘스트 생성 시 `EliteSpawnService.trySpawn()`이 확률적으로 엘리트를 배정. 보통 엘리트(🔥) / 유니크 엘리트(★) 2계층. 스폰 조건: 리전 티어 범위 + `environment_tags` 교집합 + 최소 난이도. 성공 시 `ActiveQuest`에 `eliteId` 저장. 완료 시 `EliteLootService.roll()`이 드랍 테이블에서 보너스 골드/아이템을 확률 추출하여 `EliteLootResult` 반환. 결과는 `pendingEliteLootProvider`를 통해 `QuestResultDialog`에 전달. `EliteMonsterData` / `EliteLootTableData` freezed 모델 — `core/models/elite_monster_data.dart` / `core/models/elite_loot_table_data.dart`
- **연계 퀘스트(체인 퀘스트)**: 지역 조사 완료 시 `discovery_type == 'hidden_quest'`인 `region_discoveries` 항목이 체인을 활성화(`ChainQuestService.tryActivate`). 체인 7종 × 최대 24단계. 파견 화면 최상단 `ChainStepCard`에 현재 단계 고정 노출 (이동 필요/대기/휴면 오버레이). 주인공 용병 선정(1단계 첫 성공 시 partyPower 기여도 최고 용병, step>1 사망 시 폴백 재지정). 체인 단계 ActiveQuest의 주인공 사망률 50% 감소. 체인 완주 시 평판 보너스 + `completedChains` 기록 + `ChainCompletedDialog` 팝업(TemplateEngine 렌더). 14일 비활동 시 `dormant` 전환. 최종 단계 진입 전 길드 장비 슬롯 여유 체크(`canAdvanceToFinal`). `ChainQuestService`는 Ref 직접 의존 없는 순수 서비스(콜백 파라미터로 의존성 역전)
- **퀘스트 서사**: 퀘스트 완료 시 `quest_narratives` 88행에서 `quest_type × result_type × is_elite` 3중 필터 후 weight 가중 랜덤 선택 → TemplateEngine 렌더 → `ActiveQuest.renderedNarrative`(HiveField 25) 저장(이후 재렌더 금지). `QuestNarrativeService.pickTemplate()` / `.pickProtagonist()` / `.renderNarrative()` 3개 정적 메서드 (순수 서비스 클래스). 대표 용병은 파티 내 partyPower 개별 기여 최대 용병(`QuestCalculator.statWeightsFor()` 사용). `{quest.enemy}` 변수는 `TemplateContext.enemyName`으로 사전 해결(일반: `QuestPool.enemyName`, 엘리트: `EliteMonster.name`, null: `"적"` fallback). `QuestResultDialog`에 이탤릭 서사 Container 표시, 활동 로그 메시지 포맷 `'퀘스트 "이름" 결과! — 서사'`. 체인 퀘스트는 본 서비스 미사용(chain_quests.description 직접 사용)
- **템플릿 엔진**: `TemplateEngine`(const 스테이트리스 클래스) — 변수 치환 `{namespace.field}`, 조건 분기 `[if condition]...[/if]`, 랜덤 변주 `[pick A|B|C]`. `TemplateContext`(freezed, user 필수)로 컨텍스트 제공. `render()` fail-safe(예외 시 원문 반환). `TravelEventService.renderDescription()`으로 이동 이벤트 설명 치환, `ChainCompletedDialog`에서 체인 완주 설명 치환
- **지역 변형**: 지역 조사 완료 시 `discovery_type == 'transform'`인 `region_discoveries` 항목이 섹터를 영구 변형. `discovery_data`에서 `transform_type`(village/ruins/hidden), `sector_index`(0~9), `transformed_name`, `narrative_template` 추출 → `RegionStateRepository.applyTransform()`으로 Hive 저장 → TemplateEngine 렌더 → `regionTransformedProvider` publish → `app.dart` ref.listen → `RegionTransformDialog` 팝업. 변형된 섹터에는 `quest_pools.sector_type` 일치 퀘스트 34개 생성 (`QuestGenerator.sectorType` 분기). 일부 퀘스트는 `specialFlags`를 가지며 `SpecialFlagProcessor`로 완료 시 특수 보상 처리. MovementScreen에서 변형 섹터를 아이콘(🏘️/🏛️/✨) + 색상 테두리로 시각 구분 (`currentRegionSectorChangesProvider` watch). 리전당 1섹터 제약(MVP)
- **이동 선택지(회상 팝업)**: 이동 완료 시 `TravelChoiceService.rollChoiceEvent()`가 `P = min(base + coeff × distance, 0.30)` 공식으로 이벤트 확률 계산 (tier별 coeff: 1-2: 0.08, 3-4: 0.10, 5: 0.12). 이벤트 발생 시 `UserData.choiceEventId` HiveField(21)에 저장하고 `_triggerChoiceRecall()`이 `pendingTravelChoiceProvider`에 `TravelChoiceRecallData` publish. `home_screen.dart` ref.listen → `TravelChoiceRecallDialog` 팝업(barrierDismissible: false). 다이얼로그 1단계: 상황 서사 + 일반 선택지(Row) + 숨겨진 선택지(Column, ✦ prefix). 2단계: 결과 서사 + 효과 요약. 효과 8종: `gold_gain`/`gold_loss`/`xp_gain`/`reputation_gain`/`reputation_loss`/`trait_learning_boost`/`item_drop`/`trait_innate`/`nothing`. `applyTravelChoiceEffect`는 `MovementNotifier`에 위임(레이어 경계 준수). `TravelChoiceService`는 Ref 직접 의존 없는 순수 서비스 (5개 static 메서드: rollChoiceEvent / selectProtagonist / filterVisibleOptions / resolveResult / summarizeEffect)
- **공존 정책 / 다이얼로그 큐**: M3 이후 5계층 컨텐츠(체인·세력 전용·엘리트·변형 섹터·일반)가 파견 화면에 공존, 한 번의 이동 도착 시 다중 팝업이 발생. `dialogQueueProvider` 단일 큐로 5개 도메인 채널(건설=medium / 조사=medium / 랭크업=critical / 체인 완주=high / 지역 변형=high) + 이동 자동 이벤트=medium / 선택지 회상=medium 통합. `app.dart`가 `_isShowingDialog` 플래그 + `mounted` 가드로 중복 표시 방지 + `addPostFrameCallback`으로 head 표시. critical은 `barrierDismissible: false`. 파견 화면 정렬은 `QuestSortService.sort()` 5계층 fold (Tier 0 체인 active → Tier 1 세력 전용 → Tier 2 엘리트(유니크 우선) → Tier 3 변형 섹터 → Tier 4 일반). 같은 tier는 `questType.baseReward × difficulty` 내림 → difficulty 오름 → id 사전순(pending 시 ActiveQuest.rewardGold가 null이라 추정값 사용). Tier 0는 `ChainTopSection`(최대 3장, 활성/비활성/0 케이스, 비활성은 opacity 0.6 + "이동 화면으로" 버튼으로 `currentTabProvider = 0`)으로 별도 렌더, 일반 목록에서 제거. 카드 시각 통합은 `LayerSidebar`(8단계 우선순위 fold) + `QuestCardBadges`(체인/엘리트/섹터/세력 4종 배지, 세력명 6자 초과 시 3자+"…"). MovementScreen은 `chainTargetSectors`(`Map<int, Set<int?>>`)로 region+sector 매칭하여 체인 대상 섹터 타일에 금색 2px 테두리 + "체인" 마이크로 배지 표시(`null` 포함 시 region 전체 fallback). AppTheme에 `chainGold`(0xFFD4AF37) 신규 + `transformVillage/Ruins/Hidden`, `eliteAccent/UniqueAccent` 명세 색상으로 갱신
- **세력 가입/관리**: `FactionJoinService.canJoin()`으로 가입 조건 판정. 가입 조건: 평판 > 0 / `joinNeedsClue`이면 clueLevel 3 필요 / `joinRankMin`이면 현재 랭크 충족 필요 / 충돌 세력 제외 후 실효 가입 수 < 3. 평판은 `clampReputation()`으로 미가입 시 최대 10 / 가입 시 최대 100 / 최소 -100. 가입 시 충돌 세력(`conflict_faction_ids`)은 자동 탈퇴 + 평판 -20 패널티(`applyConflictPenalty`). 세력별 `passive_bonus_json`으로 패시브 혜택 기술(현재 표시만, 실제 효과 stub). `visibilityType` = 'public' 세력은 이름 항상 노출(clueLevel 1 보장), 'secret'/'regional' 세력은 발견 전 '???' 표시. 세력 도감(`FactionCodexScreen`): 공개 → 발견 비밀/지역(clueLevel 내림차순) → 미발견 순 정렬. 세력 상세(`FactionDetailScreen`): 평판 바, 가입 조건, 패시브, 가입/탈퇴 버튼

## 테스트 구조

24개 테스트 파일, `test/` 디렉토리 아래 `lib/` 구조와 동일하게 배치. 도메인 서비스 유닛 테스트 위주 (QuestCalculator, TraitEvolutionService, FactionJoinService 등), 뷰 위젯 테스트 일부 포함 (BehaviorStatsSection, TraitSlotGrid).

```bash
# 기능별 테스트
cd band_of_mercenaries && flutter test test/features/quest/
cd band_of_mercenaries && flutter test test/features/mercenary/
```

## 문서 구조

`Docs/` — 기획/개발 문서
- `proto_design.md`: 원본 기획 문서 (게임 시스템 레퍼런스)
- `content_status.md`: 콘텐츠 구현 현황 추적
- `game_overview.md`: 게임 개요 (AI 컨텍스트용)
- `spec/`: 구현 명세서 (spec-pipeline 산출물)
- `changelog-fragments/`: 릴리스 노트 fragment 파일 (merge-changelog 스킬로 CHANGELOG.md에 병합)

## 분석 설정

`analysis_options.yaml`에서 `invalid_annotation_target: ignore` 설정됨 (freezed/json_serializable 호환용). `avoid_print: true` 린트 룰 활성화.

## UI

- 한국어 텍스트 (국제화 미적용)
- Material 3 다크 프라이머리 테마
- 티어별 색상: 회색(1) → 초록(2) → 파랑(3) → 보라(4) → 빨강(5)
- 하단 6탭: 이동 / 파견 / 홈 / 모집 / 시설 / 정보
- 새 화면 전환 시 `Navigator.push` 대신 상태 기반 렌더링 사용
- 파견 화면: 퀘스트 선택 시 전체화면 `DispatchDetailPage`를 상태 기반으로 렌더링 (3단 구조: 상단 퀘스트 정보/중앙 용병 목록/하단 버튼). 퀘스트 카드에 세력 태그 배지(세력명 + `FactionData.color`) 표시, 전용 퀘스트는 좌측 3px 세로 막대 + 테두리 강조 + "전용" 레이블. `DispatchDetailPage` 상단에 전용 → "세력명 · 고급/기본 트랙" 텍스트, 태그 → 원형 세력 컬러 + 세력명 조건부 렌더링. 퀘스트 카드에 추천 role Chip×2(`RoleSynergyMatrix.topRolesForQuest`) 추가, 용병 카드는 `singleBonus >= 5.0`일 때 `primary.withValues(alpha: 0.10)` tint + `+X.X` 배지. 성공률 옆 `?` IconButton → `showModalBottomSheet` → `SuccessRateBreakdownSheet`로 레이어별 분해 표시
- 퀘스트 완료 팝업: 보상 상세 내역 (골드, 파견비, 인건비, 순수익, XP, 명성) 표시. `ActiveQuest` 모델에 HiveField 12-16으로 보상 데이터 저장. 이후 트레잇 획득 알림 → 진화 선택 팝업 순서로 체이닝. 엘리트 퀘스트 완료 시 `QuestResultDialog`에 `EliteLootResult?` 전달 → 보통 `🔥 엘리트 드랍` / 유니크 `★ 유니크 드랍` 섹션 조건부 표시
- 파견 화면 엘리트 UI: 엘리트 퀘스트 카드에 좌측 사이드바 색상 강조(보통: `#e65100` / 유니크: `#7b1fa2`) + 상단 배지(🔥 엘리트 / ★ 유니크) + 이름 색상 강조. 퀘스트 상세 페이지(`DispatchDetailPage`)에 엘리트 서사 카드(이름·설명/로어, 그라디언트 배경) 삽입
- 용병 상세 오버레이: `selectedMercenaryIdProvider`로 앱 레벨 전체화면 오버레이. 용병 카드 탭 → 프로필/트레잇 슬롯(TraitSlotGrid)/퀘스트 유형별 상성(role 한글명 + 4종 quest_type 보정값 + 트레잇 시너지 리스트)/행동 지표(BehaviorStatsSection)/히스토리(TraitHistorySection) 단일 스크롤. 트레잇 탭 → TraitDetailDialog (효과, 진화 경로 진행도, 시너지, 충돌)
- 설정 화면: 홈 탭 상단 우측 `Icons.settings` 아이콘 버튼 탭 → `_showSettings` 상태 변수로 상태 기반 렌더링 (탭 6번째 자리 → 정보 탭으로 대체됨)
- 정보 탭 (`InfoScreen`): 세력 도감(`FactionCodexScreen`) + 명성(`RankInfoScreen`) 진입 허브. `_showCodex` / `_selectedFactionId` / `_showRank` 상태 변수로 화면 전환 (분기 순서: `_selectedFactionId` > `_showCodex` > `_showRank` > 기본 ListTile). `factionCodexScrollTargetProvider` non-null 감지 시 자동으로 도감 화면으로 전환
- 홈 등급 카드: `GestureDetector`로 탭 가능. 탭 시 `showModalBottomSheet(RankBonusSummarySheet)` → rankChain 전체 활성 보너스(등급 태그 포함) + 다음 등급 진행도(최고 랭크 A는 "최고 등급 도달" 안내)
- 랭크업 축하 오버레이(`RankUpOverlay`): `showDialog(barrierDismissible: false)` 기반 AlertDialog. `app.dart`의 `ref.listen<RankUpEvent?>`가 감지 → `WidgetsBinding.addPostFrameCallback` 내 표시. 오버레이 확인 버튼 onDismiss에서 `Navigator.pop` + `reputationRankUpProvider.state = null` 리셋 (자기책임 원칙)
- 명성 화면(`RankInfoScreen`): 상단 현재 랭크 배지 + 진행도, 중단 F~A 가로 타임라인(탭 가능), 하단 선택 등급 보너스 프리뷰(활성/잠금 표시). `_selectedRankGrade` 상태로 타임라인 선택
