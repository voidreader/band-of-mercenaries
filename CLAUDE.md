# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

용병단 운영 텍스트 기반 전략 시뮬레이션 모바일 게임. Flutter로 개발되며, Supabase 서버에서 정적 데이터를 동기화하고 Hive로 유저 데이터를 로컬 저장한다. 운영 웹앱은 `operation-bom` 프로젝트 참조. 기획 문서는 `Docs/proto_design.md` 참조.

핵심 게임 루프: 용병 모집 → 위치 이동 → 퀘스트 생성 → 파견 → 시간 대기 → 결과 획득 → 반복

## 개발 명령어

Flutter 프로젝트 디렉토리는 `band_of_mercenaries/`이며, 모든 Flutter/Dart 명령어는 해당 디렉토리에서 실행해야 한다.

```bash
cd band_of_mercenaries && flutter pub get
cd band_of_mercenaries && dart run build_runner build   # 코드 생성
cd band_of_mercenaries && dart run build_runner watch   # watch 모드
cd band_of_mercenaries && flutter run
cd band_of_mercenaries && flutter test
cd band_of_mercenaries && flutter test test/features/quest/domain/quest_calculator_test.dart
cd band_of_mercenaries && flutter analyze
```

모델·Provider 수정 후 반드시 `build_runner build` 실행 (`.g.dart`, `.freezed.dart` 재생성).

## 아키텍처

### 디렉토리 구조

```
band_of_mercenaries/lib/
├── main.dart              # Hive/Supabase 초기화 → SyncService → ProviderScope → 방치형 보상
├── app.dart               # 앱 셸 + 하단 네비게이션 + WidgetsBindingObserver(포그라운드 싱크)
├── core/
│   ├── constants/         # GameConstants
│   ├── data/              # HiveInitializer, SupabaseInitializer, DataLoader, SyncService, SettingsKeys
│   ├── domain/            # ActivityLog, ExperienceService, ReputationService, IdleRewardService
│   ├── models/            # 정적 데이터 모델 (freezed+json) + UserData (Hive)
│   ├── providers/         # 전역 Provider (game_state, static_data, timer, navigation, dialog_queue)
│   └── theme/             # Material 3 테마, 티어별 색상
├── features/
│   ├── home/              # 홈(야영지) 화면
│   ├── movement/          # 이동·TravelEventService·MovementState
│   ├── quest/             # 파견·QuestCompletionService·QuestNarrativeService
│   ├── facility/          # 시설·건설 큐·ConstructionService
│   ├── mercenary/         # 용병 모집/관리·TraitEvolutionService·RecruitmentService
│   ├── inventory/         # 인벤토리·EssenceService·ItemEffectService·InventoryScreen
│   ├── investigation/     # 지역 조사·InvestigationNotifier·RegionStateRepository
│   ├── chain_quest/       # 연계 퀘스트·ChainQuestService·ChainQuestRepository
│   ├── info/              # 정보 탭·FactionCodexScreen·FactionDetailScreen·FactionJoinService
│   ├── settlement/        # 마을 방문·HerbalistService·거점 화면 3종·NPC 데이터
│   ├── crafting/          # 제작 시스템·CraftingService·MaterialTab·RecipeListSection·낡은 대장간 화면
│   └── settings/          # 설정 (시간 가속)
└── shared/widgets/        # 공용 위젯 (BottomNavBar, TimerDisplay, StatusBadge, TierBadge 등)
```

### feature 모듈 구조

각 feature는 `view/`, `domain/`, `data/` 3계층으로 분리. `Docs/flutter-ui-refactor.md` 참조.
- Provider를 읽으면 ConsumerWidget, 로컬 상태만 필요하면 StatefulWidget
- 화면 전환은 `Navigator.push` 대신 상태 기반 렌더링 사용
- 공통 위젯은 `shared/widgets/` (동일 패턴 3개 파일 이상 반복 시)
- 스타일(TextStyle/Color)은 `core/theme/` 중앙 관리, `shared/styles/` 생성 금지

### 상태 관리

**Flutter Riverpod** 사용.

**핵심 Provider:**
- `gameTickProvider`: 1초 Stream, 게임 루프 구동 (퀘스트·이동·건설 완료 체크)
- `userDataProvider`: UserDataNotifier — 골드·위치·이동/건설/조사 상태
- `staticDataProvider`: FutureProvider — 로컬 JSON 캐시 → StaticGameData. 앱 시작·포그라운드 복귀 시 Supabase 버전 비교 후 갱신
- `mercenaryListProvider` / `questListProvider`: 용병·퀘스트 목록
- `sortedPendingQuestsProvider`: QuestSortResult — `gameTickProvider` 독립 메모이제이션, 5계층 정렬 (`features/quest/domain/sorted_quests_provider.dart`)
- `dialogQueueProvider`: DialogPriority(critical/high/medium/low) desc + FIFO + id dedup, Hive 영속화. `app.dart` 단일 `ref.listen` + `_isShowingDialog` 플래그로 팝업 표시 (`core/providers/dialog_queue_provider.dart`)

**이벤트 채널 패턴** — 새 팝업 추가 시 이 패턴을 따를 것:
`StateProvider<Event?>` publish 직후 `dialogQueueProvider.enqueue()` 호출 + `state = null` 즉시 리셋. dismiss는 큐의 책임이므로 builder/onDismiss 콜백에서 state 리셋 금지.
- `reputationRankUpProvider` (critical) · `chainCompletedProvider` (high) · `regionTransformedProvider` (high) · `settlementTrustLevelUpProvider` (high) · `investigationCompletedProvider` (medium) · `constructionCompletedProvider` (medium) · `pendingTravelChoiceProvider` (medium)

**기타 Provider:**
- `activityLogProvider`: Hive `activityLogs`, 최대 100개
- `currentTabProvider`: 하단 탭 인덱스 (`core/providers/navigation_provider.dart`)
- `factionStateRepositoryProvider` · `factionListProvider` · `factionCodexScrollTargetProvider` · `factionRefreshProvider` (`features/info/domain/faction_codex_providers.dart`)
- `pendingEliteLootProvider` · `pendingTraitEventsProvider`: 도메인→뷰 결과 전달 (`features/quest/domain/quest_provider.dart`)
- `chainQuestProgressProvider` (StreamProvider) · `activeChainProvider` · `chainQuestServiceProvider` (`features/chain_quest/domain/`)
- `settlementTrustProvider`: `family<({trust, level}), int>` — region 신뢰도 동기 조회 (`features/investigation/domain/`)
- `currentRegionSectorChangesProvider`: 현재 리전 변형 섹터 반응형 제공 (`features/investigation/domain/region_transformed_provider.dart`)
- `templateEngineProvider`: TemplateEngine — `{ns.field}` / `[if]` / `[pick A|B]` (`core/providers/template_engine_provider.dart`)
- `craftingServiceProvider` · `craftingRecipesProvider` · `recipeStateProvider`(family, gameTickProvider watch — 1초 재평가) · `materialUsageCountProvider`(family) (`features/crafting/domain/crafting_provider.dart`)
- `recipeFilterMaterialIdProvider` · `materialJumpTargetItemIdProvider`: StateProvider<String?> 일회성 컨텍스트, 양방향 점프 (인벤토리↔대장간) — 큐 미사용, 단순 publish/consume 패턴 (`features/crafting/domain/recipe_filter_provider.dart` / `material_jump_provider.dart`)

### 데이터 흐름

```
앱 시작 → SyncService (data_versions 비교) → 변경 테이블 다운로드 → 로컬 JSON 캐시
로컬 JSON → DataLoader → StaticGameData → FutureProvider
사용자 액션 → Repository → Hive → StateNotifier → UI
게임 틱 (1초) → 완료 체크 → 자동 결과 계산
포그라운드 복귀 → SyncService → 변경 시 staticDataProvider 무효화
```

### 정적 데이터 (Supabase 동기화)

앱 문서 디렉토리 `cache/*.json`에 로컬 캐시. `data_versions` 테이블로 변경분만 갱신. 모든 모델은 snake_case `@JsonKey` (Dart 필드명과 동일하면 생략).

**테이블 (27개):** regions(40개·5티어·sector_count 동적) · jobs(85개·5티어·role 컬럼) · trait_categories(8개) · traits(106개·선천35/acquired40/evolved31) · trait_conflicts(16쌍) · trait_transitions(16개) · trait_combo_evolutions(15개) · trait_synergies(39개) · difficulties(5단계) · quest_types · quest_pools(298행·is_fixed 고정의뢰 포함) · person_names(~500개) · travel_events · facilities · ranks · mercenary_wages · region_discoveries(discovery_type 6종 — info/elite/hidden_quest/faction_clue/transform/normal) · region_sectors(1-based sector_index) · factions(14개·공개6/비밀4/지역4) · elite_monsters(40종·거대 박쥐 포함) · elite_loot_tables(210행·material drop_type 포함) · chain_quests(7체인 24단계·settlement_3_pyegwang_reopen reward_items 5단계) · quest_narratives(88행) · travel_choice_events(12행) · travel_choice_options(30행) · travel_choice_results(72행) · crafting_recipes(10행·단일 트랜잭션 적용·old_smithy 한정) · quest_pool_material_drops(스키마 only·INSERT는 페이즈 4 #3)

**items 테이블 확장 (M5):** category 4종(personal_equipment/guild_equipment/consumable/material) · slot 16종(기존 11 + material_ore/material_hide/material_herb/material_relic_fragment/material_monster_part) · region_exclusive INTEGER NULL REFERENCES regions(id)

### Supabase 연결

`.env`에 `SUPABASE_URL`, `SUPABASE_ANON_KEY` (gitignored). `.env.example` 참조. anon key 읽기 전용.

### 영속성 (Hive)

10개 박스: `settings` · `user` · `mercenaries` · `quests` · `activityLogs` · `staticDataCache` · `regionStates` · `factionStates` · `chainQuestProgress` · `dialogQueue`

**typeId 점유 및 다음 HiveField 번호** — 새 모델/필드 추가 시 반드시 확인:

| 모델 | typeId | 다음 HiveField |
|------|--------|---------------|
| UserData | — | 24 |
| Mercenary | — | 24 |
| ActiveQuest | — | 26 |
| ActivityLogType (enum) | 6 | 29 |
| RegionState | 8 | 8 |
| FactionState | 9 | 6 |
| FactionClueRecord | 10 | — |
| InventoryItem | 11 | — |
| ChainQuestProgress | 13 | — |
| ChainQuestStatus | 14 | — |
| PersistedDialogEntry | 15 | — |

사용 중 typeId: 6·8·9·10·11·13·14·15. 신규 모델은 **16+** 사용.
주요 마이그레이션 플래그: `stat_migration_v2` (settings 박스, 일회성 초기화).

### 코드 생성

freezed · json_serializable · hive_generator · riverpod_generator — `build_runner`로 관리. 생성 파일: `.g.dart`, `.freezed.dart`.

## 게임 핵심 시스템 로직

- **이동**: 거리 = |리전 차이| + |섹터 차이|, 30초/칸. 이동 중 TravelEvent 랜덤 발생. 파견 중·조사 중 이동 불가 (양방향 상호 배제)
- **용병 스탯**: STR/INT/VIT/AGI. `effectiveXxx` getter로 레벨 보너스 + 피로 디버프 반영
- **파견 계산**: `partyPower` = 스탯 가중합 (유형별 가중치 — `QuestCalculator._statWeights`). 성공률 5~95%, 결과 4종(대성공/성공/실패/대실패). `calculateSuccessRateBreakdown()`으로 레이어별 분해 가능
- **경제**: 파견비 + 인건비 선차감, 순수익 = 보상 - 비용. 전용 퀘스트 기본/고급 트랙 보상 보정
- **용병 상태**: 정상 → 피곤(5분·80%) → 부상(난이도×10분) → 사망(영구). 최대 레벨 5
- **모집**: 티어별 가중 확률(T1 45%~T5 2%), 선천 트레잇 1~3개, 주둔지 용량 제한
- **트레잇**: 선천 3 + 후천 4. 23개 행동 지표 추적 → 자동 획득. 단일/조합 진화, `TraitDeletionService`로 삭제. `traitHistory`로 재획득 방지
- **시설**: 12종 Lv25, 건설 큐 1개. `ConstructionService`로 비용/시간 계산. 건설 완료는 gameTickProvider에서 체크
- **명성/랭크**: F~A 등급. 랭크업 시 `reputationRankUpProvider` publish. `PassiveBonusService.collect`로 누적 패시브 적용. 신규 유저 보호 게이트 `NewbieGate` (F/E/normal) — `RecruitmentService.selectTier` 모집 cap (F=T1 only, E=T1·T2) + `QuestGenerator.generateQuests` 파견 weight (F=d1 only, E=d1+d2 0.25). 판정은 `NewbieGateResolver.resolve(reputation, ranks)` (`core/domain/newbie_gate.dart`)
- **파견 상성**: `RoleSynergyMatrix` 6role × 4type, ±10%p 독립 상한. 트레잇 보너스도 별도 ±10%p 독립 상한
- **세력**: `FactionTagResolver`로 일반 퀘스트에 태그 부여. `FactionJoinService.canJoin()` 가입 조건 판정. 충돌 세력 가입 시 자동 탈퇴 + 평판 -20
- **지역 조사**: knowledge 0~100, 임계값 도달 시 `region_discoveries` 발견 트리거 → faction_clue/hidden_quest/transform 3종 분기
- **연계 퀘스트(체인)**: `hidden_quest` discovery_type으로 활성화. 7체인 24단계. `ChainQuestService` 순수 서비스 (콜백 DI). 거점 사건은 `settlement_<regionId>_<eventName>` chainId 컨벤션으로 분리 (settlement_ prefix는 dormant 체크·protagonist 지정 skip)
- **엘리트 몬스터**: `EliteSpawnService.trySpawn()` 확률 배정, 보통/유니크 2계층. 완료 시 `EliteLootService.roll()`
- **마을 신뢰도**: region 3 기준, 4단계(의심1·인지2·친근3·소속4), 임계값 {1:0·2:30·3:80·4:200}. 단계 승급 시 일회성 보상 지급 + `settlementTrustLevelUpProvider` publish
- **마을 방문**: region 3 sector 1(village) 진입 시 `VillageVisitSection` 인라인 노출. 약초상(즉시 회복·쿨다운)·촌장 집·낡은 대장간. 게임 시간 미소모
- **제작 시스템**: `CraftingService` 콜백 DI — `evaluateState(recipe)` 4상태 평가(잠김/부족/충족, M5 MVP는 crafted 미적용) + `craft(recipeId)` 실행(consumeMaterial × N → addItem → ActivityLog `craftCompleted`). `unlock_condition_json`은 trustLevel/chainStep/firstAcquiredItem 3종 분기 (firstAcquiredItem은 `RegionState.firstAcquiredMaterialIds` HiveField 7 영속 추적 — 첫 입수 후 모두 소비해도 해금 유지). `InventoryRepository`는 `stackMaxByCategory > 1` 일반화 분기로 material/consumable stack 누적 + 999 클램프 + `consumeMaterial`/`getQuantityForItemId` 메서드 제공. 5종 드랍 출처 hook 모두 활성 — 의뢰(`quest_pool_material_drops`)·조사(`region_discoveries.discovery_data.items`)·엘리트(`elite_loot_tables` drop_type='material')·이동선택지(`travel_choice_results.effect_type='material_drop'`)·체인(`chain_quests.reward_items` JSONB). `RegionStateRepository.addAcquiredMaterial(regionId, itemId)` 멱등 메서드로 hook마다 영속 추적. 신뢰도 2/3단계 진입 시 일회성 재료 보너스(#6 ×1 / #1 ×3) 자동 지급. `QuestGenerator`는 `currentChainId/currentChainStep` 인자로 거대 박쥐 step 3 강제 spawn(M6+ 데이터 모델 마이그레이션 위임 TODO). 999 도달 시 `ActivityLogType.inventoryStackCapped` HiveField 28 활동 로그. 낡은 대장간(region 3 신뢰도 2단계+) RecipeListSection 4계층 정렬(상태→slot→tier→id) + banner/artifact 양자택일 그룹 헤더. 인벤토리 4탭째 MaterialTab(slot 6칩 + region_exclusive 시각 차별화) + 양방향 점프(🔨 ×N → 자동 필터 / 부족 재료 → 인벤토리 자동 진입)
- **퀘스트 서사**: `QuestNarrativeService` — quest_type×result_type×is_elite 3중 필터 + weight 가중 랜덤 → `TemplateEngine` 렌더 → `renderedNarrative` 1회 저장 (재렌더 금지)
- **방치형 보상**: 분당 1G, 최대 480G + 금고 보너스
- **다이얼로그 큐**: 5계층 컨텐츠 공존 보장. priority: critical(rankUp) > high(chain/transform/trustUp) > medium(construction/investigation/travelChoice). critical은 `barrierDismissible: false`

## 테스트 구조

24개 테스트 파일, `test/` 아래 `lib/` 구조와 동일. 도메인 서비스 유닛 테스트 위주.

```bash
cd band_of_mercenaries && flutter test test/features/quest/
cd band_of_mercenaries && flutter test test/features/mercenary/
```

## 문서 구조

`Docs/` — `proto_design.md`(기획 레퍼런스) · `content_status.md`(구현 현황) · `game_overview.md`(AI 컨텍스트용) · `spec/`(명세서) · `changelog-fragments/`(릴리스 노트 단편)

## 분석 설정

`analysis_options.yaml`: `invalid_annotation_target: ignore` (freezed 호환). `avoid_print: true` 활성화.

## UI

- 한국어, Material 3 다크 테마, 티어별 색상(회색→초록→파랑→보라→빨강)
- 하단 6탭: 이동 / 파견 / 홈 / 모집 / 시설 / 정보
- 화면 전환은 `Navigator.push` 대신 상태 기반 렌더링 (파견 상세, 설정, 마을 방문, 정보 탭 내부 등)
- 파견 화면: `sortedPendingQuestsProvider` 5계층 정렬. 카드에 `LayerSidebar` + `QuestCardBadges`(체인/엘리트/섹터/세력 배지). `ChainTopSection`(최대 3장) 별도 렌더, 거점 사건(`isSettlementStep`)은 일반 목록 최상단 `settlementTier`로 노출
- 용병 상세: `selectedMercenaryIdProvider` 앱 레벨 오버레이. 성공률 분해: `SuccessRateBreakdownSheet`
- AppTheme 주요 색상: `chainGold`(0xFFD4AF37) · `settlementAccent`(0xFFFFA000) · `eliteAccent`(#e65100) · `uniqueAccent`(#7b1fa2) · `dangerRed`(0xFFC62828, RecipeCard insufficient 부족 재료 텍스트)
- 인벤토리 화면: 5탭(전체 / 개인 장비 / 길드 장비 / 소비 / 재료). MaterialTab은 slot 6칩 sub-filter + tier desc → 보유량 desc → id asc 정렬, 빈 상태에서 출처 가이드 토글
- 낡은 대장간: M5 페이즈 4 #2부터 정식 제작 화면. `RecipeListSection` 4계층 정렬 + 그룹 헤더(banner 양자택일·artifact 동시 장착) + RecipeCard 4상태(locked/insufficient/ready) + [제작] 토스트(1.5초)
