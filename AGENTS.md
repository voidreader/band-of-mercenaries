# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

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
│   ├── achievement/       # 위업·연대기·AchievementService·ChronicleScreen·AchievementUnlockedDialog·MercenarySnapshot 영속 보존
│   ├── title/             # 칭호·간판 용병·TitleService·FlagshipMercenaryService·TitleUnlockedDialog·FlagshipHomeCard·TitlesSection
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
- `sortedPendingQuestsProvider`: QuestSortResult — `gameTickProvider` 독립 메모이제이션, 6계층 정렬(체인 0/고정/거점/지명/세력/엘리트/변형/일반) (`features/quest/domain/sorted_quests_provider.dart`)
- `dialogQueueProvider`: DialogPriority(critical/high/medium/low) desc + FIFO + id dedup, Hive 영속화. `app.dart` 단일 `ref.listen` + `_isShowingDialog` 플래그로 팝업 표시 (`core/providers/dialog_queue_provider.dart`)

**이벤트 채널 패턴** — 새 팝업 추가 시 이 패턴을 따를 것:
`StateProvider<Event?>` publish 직후 `dialogQueueProvider.enqueue()` 호출 + `state = null` 즉시 리셋. dismiss는 큐의 책임이므로 builder/onDismiss 콜백에서 state 리셋 금지.
- `reputationRankUpProvider` (critical) · `chainCompletedProvider` (high) · `regionTransformedProvider` (high) · `settlementTrustLevelUpProvider` (high) · `investigationCompletedProvider` (medium) · `constructionCompletedProvider` (medium) · `pendingTravelChoiceProvider` (medium) · `dangerLevelChangedProvider` (medium, M7 페이즈 4 #1 — isBigTransition=true일 때만 enqueue) · `settlementInfrastructureUpgradedProvider` (medium, M7 페이즈 4 #4)

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
- `achievementServiceProvider`: AchievementService 콜백 DI (`features/achievement/domain/achievement_service_provider.dart` — 순환 참조 회피로 분리. `achievement_provider.dart`에서 re-export). `bandAchievementsProvider`(StateNotifier, box.watch 구독 — sorted desc) · `renderedAchievementProvider`(family<String, achievementId> — TemplateEngine 렌더 캐싱, user는 read 1회) (`features/achievement/domain/achievement_provider.dart`)
- `titleServiceProvider`: TitleService 콜백 DI 9개(titles/getMercenary/updateMercenaryTitles/addLog/enqueueDialog/hasAchievement/bandAchievements/staticData/buildTitleDialog) — 순환 참조 회피로 `title_service_provider.dart` 분리. hasAchievement·bandAchievements 콜백은 `Hive.box<BandAchievement>` 직접 조회 (achievement_service_provider 의존 회피). `titlesProvider`(Provider<List<TitleData>> — staticData fallback) · `mercenaryTitlesProvider`(family<String, mercId> — titleIds → TitleData 변환, 미발견 silent skip) (`features/title/domain/`)
- `flagshipMercenaryProvider`: Provider<Mercenary?> — userData.flagshipMercId/mercList/bandAchievements watch 후 수동/자동 통합 + dead fallback. `flagshipMercenaryServiceProvider`(FlagshipMercenaryService 콜백 DI 2개: getMercenaries/getBandAchievements — selectAuto 5단계 정렬 / handleMercDeathOrRelease) (`features/title/domain/flagship_provider.dart`)
- `settlementInfrastructureTierProvider`: `Provider.family<int, regionId>` — region 인프라 단계(1~4) 동기 조회 (M7 페이즈 4 #4, `features/settlement/domain/settlement_infrastructure_provider.dart`). null fallback 1.
- `regionDangerDecayProvider`: `Provider<void>` — 60틱 카운터로 M7 핵심 7리전 중 dangerScore<0인 region에 12시간 경과 시 +1 decay 적용 (M7 페이즈 4 #1 FR-4d, `core/providers/timer_provider.dart`). app.dart에서 `ref.watch`로 활성화.

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

**테이블 (32개):** regions(40개·5티어·sector_count 동적·M7 6리전 region_name 갱신) · jobs(85개·5티어·role 컬럼) · trait_categories(8개) · traits(106개·선천35/acquired40/evolved31) · trait_conflicts(16쌍) · trait_transitions(16개) · trait_combo_evolutions(15개) · trait_synergies(39개) · difficulties(5단계) · quest_types · quest_pools(341행·is_fixed/is_named/M7 페이즈 4 #2 `region_state_effect` JSONB/`region_state_required`/`region_state_excluded` 3 컬럼 + 36행 M7 INSERT) · person_names(~500개) · travel_events · facilities · ranks · mercenary_wages · region_discoveries(50행·discovery_type 6종·M7 15행 추가) · region_sectors(1-based sector_index) · factions(14개) · elite_monsters(40종) · elite_loot_tables(210행) · chain_quests(8체인 26단계·M7 페이즈 4 #4 chain_m7_mist_clearing 2단계 추가) · quest_narratives(88행) · travel_choice_events(12행) · travel_choice_options(30행) · travel_choice_results(72행) · crafting_recipes(16행·M7 신규 6 레시피·unlock_condition_json type 확장: regionFlag/infrastructureTier/all/any) · quest_pool_material_drops · band_achievement_templates(34행·9카테고리·M7 페이즈 4 #1 region_pacified 7행 + #4 infrastructure_growth 1행 추가·CHECK 확장) · titles(11행) · **region_adjacency(M7 페이즈 4 #3 신설 22행, from_region/to_region/distance_units, 양방향 11쌍, region_3 도달 보장)**

**items 확장 (M7):** category 4종 유지 · slot 17종(M5 16 + M7 페이즈 3 #5 `consumable` slot 추가 + CHECK 확장) · 신규 6 아이템(`equip_weapon_beast_tool`·`cons_wildflower_oil`·`equip_armor_nomad`·`cons_seaweed_tonic`·`guild_artifact_swamp_seal`·`guild_artifact_burnt_seal`)

**items 테이블 (M5 → M7 갱신):** category 4종(personal_equipment/guild_equipment/consumable/material) · slot 17종(기존 11 + material_ore/material_hide/material_herb/material_relic_fragment/material_monster_part + consumable) · region_exclusive INTEGER NULL REFERENCES regions(id)

### Supabase 연결

`.env`에 `SUPABASE_URL`, `SUPABASE_ANON_KEY` (gitignored). `.env.example` 참조. anon key 읽기 전용.

### 영속성 (Hive)

11개 박스: `settings` · `user` · `mercenaries` · `quests` · `activityLogs` · `staticDataCache` · `regionStates` · `factionStates` · `chainQuestProgress` · `dialogQueue` · `bandAchievements`

**typeId 점유 및 다음 HiveField 번호** — 새 모델/필드 추가 시 반드시 확인:

| 모델 | typeId | 다음 HiveField |
|------|--------|---------------|
| UserData | — | 28 |
| Mercenary | — | 26 |
| ActiveQuest | — | 27 |
| ActivityLogType (enum) | 6 | 35 |
| RegionState | 8 | 14 |
| FactionState | 9 | 6 |
| FactionClueRecord | 10 | — |
| InventoryItem | 11 | — |
| ChainQuestProgress | 13 | — |
| ChainQuestStatus | 14 | — |
| PersistedDialogEntry | 15 | — |
| BandAchievement | 16 | 7 |
| BandAchievementType (enum) | 17 | 2 |
| MercenarySnapshot | 18 | 6 |
| MemorialCause (enum) | 19 | 3 |

사용 중 typeId: 6·8·9·10·11·13·14·15·16·17·18·19. 신규 모델은 **20+** 사용. typeId 12는 여전히 미사용 (보존).
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
- **다이얼로그 큐**: 5계층 컨텐츠 공존 보장. priority: critical(rankUp) > high(chain/transform/trustUp/achievementUnlocked/titleUnlocked) > medium(construction/investigation/travelChoice/regionStateChanged/settlementInfrastructureUpgraded). critical은 `barrierDismissible: false`. DialogTypeRegistry 13종 (M7 페이즈 4 #1·#4 신규 2종 추가).
- **위업·연대기 시스템**: `AchievementService` 콜백 DI — `grant(templateId, mercSnapshot?, regionId?, payload?)` 멱등 보장(hasAchievement 사전 체크) + 4단계 사이드이펙트(bandAchievementsBox.add → activityLog `★ 위업: {name}` → 카테고리 `reputation_rank` 제외 시 dialogQueue.enqueue → return BandAchievement). 페이즈 4 #2에서 (2.5) 단계 추가 — `evaluateAchievementHook` 콜백(nullable)으로 칭호 hook 평가 후 grantedTitles를 dialog payload + builder 3-arg에 첨부 (fail-soft try/catch). `recordMemorial(MemorialCause, MercenarySnapshot, payload?)`는 `(mercId, cause)` 중복 검사 후 box.add만(dialog/activityLog 미실행). `hasAchievement(templateId)` 동기 bool, `getAll()` achievedAt desc. 6 hook 통합 fail-soft trailing side effect: 체인(`ChainQuestService.completeChain` chainId prefix 분기 `chain_/settlement_` → `chain_completed:` / `settlement_event_completed:`) · 거점 신뢰도 4단계(`RegionStateRepository.addSettlementTrust` → `settlement_trust_belonging:region_$regionId`) · 명성 진입(`UserDataNotifier.addReputation` toGrade∈{E,D,C,B,A} → `reputation_rank:$grade`, RankUpDialog 본체 1줄 인라인이 dialog 대체) · 엘리트 유니크 첫 처치(`quest_provider` `_applyCompletionResult` 엘리트 분기 isUnique → `elite_unique_first_kill:$eliteId`) · T3+ 첫 제작(`CraftingService.craft` addItem 직후 tier>=3 → `craft_first_rare:$recipeId`) · 사망/방출 memorial(`quest_provider` dead 분기 + `MercenaryRepository.dismiss` 직전 snapshot 구성). `MercenarySnapshot` 6필드(id/name/jobId/jobName/tier/titleIds — 페이즈 4 #2에서 titleIds 추가)는 발급 시점 영속 보존(본체 삭제 후 참조). `bandAchievementsProvider`(StateNotifier·box.watch 구독) + `renderedAchievementProvider`(family·TemplateEngine 렌더 캐싱). `achievementServiceProvider`는 `achievement_service_provider.dart`에 분리하여 순환 참조 회피, `achievement_provider.dart`에서 re-export. ChronicleScreen은 상태 기반 렌더링(`_showChronicle` + `onBack`) — HomeScreen/InfoScreen 양쪽 진입점. AchievementUnlockedDialog는 high priority + `barrierDismissible: false` (확인 버튼만 dismiss) + grantedTitles 1줄 인라인 표시(0/1-2/3+ 분기). `band_achievement_templates` 26행 시드(chain 7·settlement_event 1·settlement_trust 1·reputation_rank 5·elite_unique 8·craft_first_rare 1·memorial 3, placeholder 7개는 elite_monsters.is_unique=true 후속 UPDATE 위임). 카테고리 7종 `_categoryOf(templateId)` `:` 앞 부분 추출. `MemorialCause` 3종(diedQuest/diedEvent/released, diedEvent는 travel_event_service 사망 분기 부재로 미적용 대기)
- **칭호·간판 용병 시스템**: `TitleService` 콜백 DI — 3 hook 평가 메서드(`evaluateAchievementHook` Future<List<TitleData>> / `evaluateActionStatHook` / `evaluateStatusHook` 모두 async) + `_grantTitle`(mercenary.titleIds append → updateMercenaryTitles 영속 → activityLog `titleUnlocked` HiveField 30 미러). hook 3종: (a) 위업 hook은 AchievementService.grant 본체 (2.5)에 통합되어 AchievementUnlockedDialog grantedTitles 1줄 인라인 / (b) 행동지표 hook은 QuestCompletionService 파견 결과 직후 각 mercenary 평가 / (c) 상태 hook은 부상 진입 시 평가. 모두 fail-soft try/catch + 신규 `TitleUnlockedDialog`(high) enqueue. `hook_target` 5종: require_protagonist / first_only / last_dispatch_protagonist(UserData.lastDispatchProtagonistMercId HiveField 25 캐시) / most_dispatched_to_region_3(Mercenary.stats `region_{N}_dispatch_count` 카운터) / top_contributor_24h(누적 success+great_success 1위 단순화 fallback — 페이즈 5+ 정교화 위임). `FlagshipMercenaryService.selectAuto()` 5단계 정렬(titleIds.length DESC → 위업 주인공 횟수 DESC → level DESC → partyPower DESC(effective stat 가중평균) → recruitedAt ASC, null=DateTime(2000) fallback) + `handleMercDeathOrRelease`로 수동 간판 자동 복귀. `flagshipMercenaryProvider`(userData/mercList/bandAchievements 3종 watch) — 수동(UserData.flagshipMercId HiveField 24) 우선, 미설정·dead·미발견 시 자동 알고리즘 fallback. `Mercenary.titleIds` HiveField 24·`recruitedAt` HiveField 25(`RecruitmentService.generateMercenary`에서 `DateTime.now()` 설정). `MercenarySnapshot.titleIds` HiveField 5는 `fromMercenary` 시점 자동 사본 동결(페이즈 4 #1 호환). `PassiveBonusService.collect`에 `titleEffects: List<PassiveEffect>` 인자 + `MercenaryTitleEffects.collectFor(merc, titles)` helper(quest_completion_service에서 파티 첫 번째 mercenary 단독 적용 — Q-10). `getQuestRewardMultiplier`·`getMercenaryXpBonus` 가산 상한 +0.30 명시. `titleServiceProvider`는 `title_service_provider.dart` 분리(순환 참조 회피, hasAchievement/bandAchievements는 Hive box 직접 조회). 11종 칭호(`titles` 31번째 테이블): 마을의 은인·폐광의 생존자·첫 깃발을 든 자·도적길 추적자·백전노장·정찰의 눈·호위의 노련함·더스트빌의 친우·괴물 사냥꾼·이름을 알린 자·혼을 끊은 자. 행동 지표 임계 페이즈 2 #1 결정(raid 20·dispatch 80·explore 15·escort 12).
- **지명 의뢰 시스템 (M6 페이즈 4 #3)**: `NamedHookEvaluator` 순수 정적 헬퍼 — `evaluateNamedHook(QuestPool, NamedHookContext)` + `isCooldownPassed(DateTime?, DateTime)`. 4종 hook_type: `title`(`mercenaries.any titleIds.contains`) / `achievement_count`(BandAchievementType.achievement 카운트 >= 임계) / `achievement_id`(M6 MVP 데이터 미사용) / `flagship`(flagshipMercId non-null). silent false for null/unknown. `QuestGenerator.generateQuests()` 시그니처에 4 옵션 인자 추가(mercenaries/bandAchievements/flagshipMercId/namedQuestCooldowns) + generalPools `.where()` named hook + 쿨다운 평가 + `_weightedSample` `if (p.isNamed) w += 3.0` 가중치 α=3(페이즈 2 #2 정량 검증 — 매 갱신 ~64% 등장 / 시간당 ~0.9회) + flagship 의뢰 발급 시 `namedTargetMercId` 동결. `QuestSortService` 6→7 슬롯(fixed → settlement → named → tier1/2/3/4) `QuestSortResult.namedTier` 신규 필드. `QuestCompletionService` named 배수 적용 — `pool.specialFlags['named_reward_multiplier']` × `named_reputation_multiplier`(1.30~1.50) 결과 배수 직후·칭호 효과 직전. 발급 직후 `_updateNamedCooldownsForQuests` 헬퍼(Map merge + 단일 save) → `UserData.namedQuestCooldowns` HiveField 26 영속. `UserDataNotifier.updateNamedQuestCooldowns` 메서드. 사망/방출 시 `terminateNamedQuestsForMerc(mercId)` — `namedTargetMercId == mercId` 진행 의뢰 자동 제거 + ActivityLog `namedQuestTerminated` HiveField 31 발급 (dialog 미발생, fail-soft trailing). `ActiveQuest.namedTargetMercId` HiveField 26 동결(flagship 한정). 의뢰 카드 UI 차별화 — `QuestLayerInfo.isNamed`/`namedSublabel` 필드 추가, `LayerSidebarResolver`/QuestCardBadges/_nameColor/_borderColor 모두 `AppTheme.namedAccent`(0xFFE91E63) 적용. ✩ 지명 배지 + hook별 sublabel(`'칭호 — {name}'` / `'위업 {N}개 이상'` / `'간판 용병 지명'`). 잠금 UI(`_isNamedQuestLocked` + `_resolveLockedMercName`) — title hook 전원 파견 중·flagship hook 동결 용병 파견 중일 때 `Opacity(0.4)` + `AbsorbPointer` + 우상단 "지명 용병 복귀 대기" 배지 + `Positioned.fill GestureDetector`로 토스트(`'지명 용병 {name}이(가) 복귀해야 수행할 수 있습니다'`). `quest_pools` 4 컬럼(`is_named` BOOL DEFAULT false / `named_hook_type` TEXT / `named_hook_value` TEXT / `named_cooldown_hours` INT DEFAULT 24) + CHECK 2종(`named_hook_type_check`/`named_consistency`) + 부분 INDEX `idx_quest_pools_is_named` + 7행 시드(qp_named_village_savior/road_hunter/monster_hunter/renowned_3/renowned_10/flagship_letter/flagship_legend). 24h 쿨다운 회전. 단일 hook 정책(복합 조건 M9+ 위임).
- **지역 상태 변화 시스템 (M7 페이즈 4 #1)**: `RegionState` HiveField 8·9·10 추가 — `dangerScore`(int? -100~+100 clamp) / `dangerLevel`(int? 1~4 캐시) / `unlockedFlags`(List<String>). `DangerLevel` enum 4종(stable/peaceful/tension/threat) + `DangerLevelResolver`(resolveLevel/fromCacheInt/fromLowercaseString) + 한국어 라벨 헬퍼(`features/investigation/domain/danger_level.dart`). `RegionStateRepository` 메서드 4종 — `getOrCreateRegionState`(동기) · `addDangerScore({regionId,delta,source,ref})`(clamp + 단계 재계산 + isBigTransition 판정 + ActivityLog `regionDangerLevelChanged` HiveField 32 + 첫 peaceful 진입 시 `region_pacified:region_$id` 위업 fail-soft grant + refreshAvailableQuests) · `toggleFlag({regionId,flag,ref})`(멱등 List 추가 + ActivityLog `regionUnlockedFlagToggled` HiveField 33 + 인프라 전이 trailing) · `hasFlag`(동기). 트리거 5종 fail-soft trailing: 의뢰 완료(페이즈 4 #2 `applyDangerScoreFromQuest`) · 체인 완주(`ChainQuestService.applyRegionStateFromChain` 콜백 DI · `chainRegionStateMapping` 5쌍) · 엘리트 유니크 첫 처치(`quest_provider._applyCompletionResult` · `eliteRegionStateMapping`) · decay(`regionDangerDecayProvider` 60틱 카운터 · `_lastDecayCheckedAt` 정적 Map · 12시간 간격 +1) · flag toggle(인프라 전이 평가). `dangerLevelChangedProvider` StateProvider(medium) + `RegionStateChangedDialog`(isBigTransition=true만 enqueue, XOR로 stable/threat 진입·이탈은 인접 단계라도 큰 전이). `band_achievement_templates` 8행 추가(region_pacified 7 + infrastructure_tier 1·CHECK 확장). M7 핵심 7리전: 3·31·127·9·10·146·38 — `M7Constants.livingsphereRegions` 단일 정의.
- **QuestGenerator 가중치 분기 (M7 페이즈 4 #2)**: `QuestPool` 3 필드 확장(`regionStateEffect`/`regionStateRequired`/`regionStateExcluded`) + `RegionStateEffect` freezed sealed union(`CumulativeEffect`·`OneshotEffect` 2 case, `@FreezedUnionValue` discriminator `type`). `RegionStateWeightConfig` 정적 상수 — dangerLevel 4단계 × quest_type 4종 매트릭스(threat raid 3.0× / stable raid 0.3× 등) + 8 flag × 1~2 quest_type 14쌍 + cumulativeCapReachedMultiplier 0.2. `QuestGenerator.computeFinalWeight({pool,regionState,gate})` 7단계 가중치 계산(NewbieGate base → required/excluded weight=0 → dangerLevel × → flag × → cumulative cap × → named α=3 가산). `_weightedSample` 시그니처에 `RegionState?` 추가 + `generateQuests` 시그니처 확장(`regionState`) + `quest_provider` 3 호출점(generateQuests/fillQuests/_refreshExpiredQuests). `RegionState.questPoolCompletionCounts` HiveField 11(Map<String,int> region별 누적 카운터). `RegionStateRepository.applyDangerScoreFromQuest` 본체 — Cumulative(카운터 +1 → delta 적용 → cap 도달 시 flag toggle + 단발 -10 보너스) / Oneshot(flag 미보유 시 delta+toggle). `_applyCompletionResult` trailing(성공/대성공 한정 + fail-soft). `quest_pools` ALTER 3 컬럼 + 36행 M7 INSERT(r3:2 / r31:6 / r127:5 / r9:6 / r10:5 / r146:6 / r38:6 · cumulative 7 / oneshot 6 / 상태조건 11 / 일반 12).
- **이동 화면 + 거점 상세 UI (M7 페이즈 4 #3)**: `region_adjacency` 32번째 Supabase 테이블(22행 양방향 11쌍 · CHECK distance_units>0 · UNIQUE(from,to) · 양방향 정합 검증). `RegionAdjacency` freezed 모델 + `StaticGameData.regionAdjacencies` + `regionAdjacencyMap`(Map<int,Map<int,int>> derived getter). `SyncService.allTables` 32번째 등록. `MovementDistanceCalculator.calculate`(동일 region |sector 차| → 인접 distance_units + |sector 차| → UserData.calculateDistance fallback). `MovementScreen` 변경 — 거리 계산 위임 + 광장 이정표 -10% 곱셈 합산(`infraTier >= 2 && region 3 출발/도착` → `1.0 - ((1.0 - transport) * 0.9)`) + 환경 아이콘(🏔️/🌊/🌳/🌫️/🏛️/🌾) + `RegionStatusBadgeRow`(dangerLevel 점·한국어 라벨 + unlockedFlags 최대 2개 + overflow) + `LivingsphereJumpBar`(7리전 가로 스크롤 칩, M7 7리전 진입 시만 노출) + 잠금 텍스트 강화(`🔒 ${requiredRank.grade} 랭크 필요`). `AppTheme.dangerLevelColor`(파랑/초록/주황/빨강) + `dangerLevelLabel`(안정/평온/긴장/위협) 헬퍼. `RegionStateChangedDialog`와 색상 공유. `VillageVisitSection` Tier 3+ 외래 좌판 카드 + Tier 2+ 인프라 배지(`_infrastructureLabel`). `ChiefHouseScreen` Tier 2+ "생활권 정보" 버튼 + dialog(7리전 dangerLevel 매트릭스 + flagCount).
- **마을 인프라 성장 시스템 (M7 페이즈 4 #4)**: `RegionState.infrastructureTier` HiveField 12(1~4, region 3 한정). `SettlementInfrastructureConfig` 정적 상수 — `infraTierThresholds`{1:0,2:2,3:4,4:6} + `infraTierRewards`{2:100G/100XP/50명성, 3:200/200/100, 4:500/500/300} + `infraTierNames`{고립/연결/거점화/변방의 중심} + `infrastructureRelevantFlags`(M7 8 flag) + `foreignStallBasePrices`(8종 60~300G) + `foreignStallTier4Discount` 0.80 + `signpostDistanceMultiplier` 0.90 + `signpostMinTier` 2 + `resolveTier(flagCount)`. `settlementInfrastructureTierProvider` Provider.family<int,regionId>(stub 1 fallback). `RegionStateRepository._evaluateInfrastructureTransition` 본체(M7 7리전 flag 합산 → resolveTier → 통과 단계 보상 합산 → Tier 4 진입 시 `infrastructure_tier:tier_4` 위업 "변방의 영주" grant) — `toggleFlag` trailing 활성화. `InfrastructureUpgradeEvent` + `settlementInfrastructureUpgradedProvider`(medium) + `SettlementInfrastructureUpgradedDialog`. `VillageFacility.foreignStall` enum 4번째 case + `ForeignStallScreen`(initState에서 `incrementForeignStallVisit` 호출 → `UserData.foreignStallVisitCount` HiveField 27 영속) + 외래 상인 케일 NPC + 3 ActionButton(재료 거래 Tier 3 3종 / Tier 4 6종+-20% / 외래 소식 / 방문 횟수). `HerbalistService` infra multiplier 3종(cost/cooldown/gathering 곱셈 합산 — Tier 4 도달 시 비용 -57% / 쿨다운 -84% / 채집 +44%) + named optional `infraTier` 인자 default 1. `CraftingService._isUnlockedM7` switch 4 type(`regionFlag`/`infrastructureTier`/`all`/`any` 재귀) + `RecipeUnlockCondition` freezed 4 nullable 필드(type/flag/value/conditions). M5 기존 trustLevel/chainStep/firstAcquiredItem 분기 보존(condition.type==null 분기). 페이즈 3 #5 SQL — items 6 + crafting_recipes 6(M7 신규 레시피 unlock_condition_json 4 type) + `chain_m7_mist_clearing` 2단계(region 146 안개 해소 -50 특수 단발, 페이즈 4 #1 FR-4b 매핑 활성). `ActivityLogType.settlementInfrastructureUpgraded` HiveField 34. `items_slot_check` CHECK 확장(`consumable` 추가) + `band_achievement_templates_category_check` 확장(`region_pacified`/`infrastructure_growth` 추가).

## 테스트 구조

24개 테스트 파일, `test/` 아래 `lib/` 구조와 동일. 도메인 서비스 유닛 테스트 위주.

```bash
cd band_of_mercenaries && flutter test test/features/quest/
cd band_of_mercenaries && flutter test test/features/mercenary/
```

## 문서 구조

`Docs/` — `proto_design.md`(기획 레퍼런스) · `content_status.md`(M3 기준 보관본) · `game_overview.md`(AI 컨텍스트용) · `spec/`(진행 중 명세서) · `Archive/`(완료 산출물) · `changelog-fragments/`(릴리스 노트 단편)

## 분석 설정

`analysis_options.yaml`: `invalid_annotation_target: ignore` (freezed 호환). `avoid_print: true` 활성화.

## UI

- 한국어, Material 3 다크 테마, 티어별 색상(회색→초록→파랑→보라→빨강)
- 하단 6탭: 이동 / 파견 / 홈 / 모집 / 시설 / 정보
- 화면 전환은 `Navigator.push` 대신 상태 기반 렌더링 (파견 상세, 설정, 마을 방문, 정보 탭 내부 등)
- 파견 화면: `sortedPendingQuestsProvider` 6계층 정렬(체인 0/고정/거점/지명/세력/엘리트/변형/일반). 카드에 `LayerSidebar` + `QuestCardBadges`(체인/지명/엘리트/섹터/세력 배지). `ChainTopSection`(최대 3장) 별도 렌더, 거점 사건(`isSettlementStep`)은 일반 목록 최상단 `settlementTier`로 노출. M6 페이즈 4 #3 지명 의뢰 카드는 hook 매칭 mercenary 전원 파견 중(title) 또는 namedTargetMercId 동결 mercenary 파견 중(flagship)일 때 `Opacity(0.4)` + `AbsorbPointer` 잠금 + 토스트 안내
- 용병 상세: `selectedMercenaryIdProvider` 앱 레벨 오버레이. 성공률 분해: `SuccessRateBreakdownSheet`. M6 페이즈 4 #2 `TitlesSection`(MercenarySynergySection 다음, BehaviorStatsSection 직전) — chainGold border + N개 TitleCard + 빈 상태 + `FlagshipToggleButton` 4상태 분기(자동/수동 × 이 용병/다른 용병)
- 홈 야영지: `FlagshipHomeCard`(야영지 이미지 다음, ChronicleHomeCard 직전, gameTickProvider watch — 1초 재평가) — chainGold border + TierBadge + 이름·티어·직업·레벨·합류 일수·칭호 미니칩(최대 3+overflow)·파견 중 배지. 탭 → `selectedMercenaryIdProvider.state` 상태 기반 오버레이.
- AppTheme 주요 색상: `chainGold`(0xFFD4AF37) · `settlementAccent`(0xFFFFA000) · `namedAccent`(0xFFE91E63, M6 페이즈 4 #3 지명 의뢰 분홍 마젠타 — 5계층 색상 분리) · `eliteAccent`(#e65100) · `uniqueAccent`(#7b1fa2) · `dangerRed`(0xFFC62828, RecipeCard insufficient 부족 재료 텍스트) · `memorialGray`(0xFF6E6E6E, 추모 카드 카테고리 칩·아이콘·텍스트 강조)
- 인벤토리 화면: 5탭(전체 / 개인 장비 / 길드 장비 / 소비 / 재료). MaterialTab은 slot 6칩 sub-filter + tier desc → 보유량 desc → id asc 정렬, 빈 상태에서 출처 가이드 토글
- 낡은 대장간: M5 페이즈 4 #2부터 정식 제작 화면. `RecipeListSection` 4계층 정렬 + 그룹 헤더(banner 양자택일·artifact 동시 장착) + RecipeCard 4상태(locked/insufficient/ready) + [제작] 토스트(1.5초)
