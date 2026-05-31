# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

용병단 운영 텍스트 기반 전략 시뮬레이션 모바일 게임. Flutter로 개발되며, Supabase 서버에서 정적 데이터를 동기화하고 Hive로 유저 데이터를 로컬 저장한다. 운영 웹앱은 `operation-bom` 프로젝트 참조. 기획 레퍼런스는 `Docs/game_overview.md`, 마일스톤 계획은 `Docs/roadmap/master_roadmap.md` 참조.

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

**테이블 (40개):** regions(40개·5티어·sector_count 동적·M7 6리전 region_name 갱신) · jobs(85개·5티어·role 컬럼) · trait_categories(8개) · traits(106개·선천35/acquired40/evolved31) · trait_conflicts(16쌍) · trait_transitions(16개) · trait_combo_evolutions(15개) · trait_synergies(39개) · difficulties(5단계) · quest_types · quest_pools(353행·is_fixed/is_named/M7 페이즈 4 #2 `region_state_effect` JSONB/`region_state_required`/`region_state_excluded` 3 컬럼 + 36행 M7 INSERT + **M8a +12 세력 지명 의뢰** + **M8.5 페이즈 4 #2 `party_size_min` INT NOT NULL DEFAULT 1 / `party_size_max` INT NULL 2 컬럼 + CHECK `quest_pools_party_size_check` + 5행 솔로/소수정예 의뢰**) · person_names(~500개) · travel_events · facilities · ranks · mercenary_wages · region_discoveries(50행·discovery_type 6종·M7 15행 추가) · region_sectors(1-based sector_index) · factions(14개) · elite_monsters(40종) · elite_loot_tables(210행) · chain_quests(8체인 26단계·M7 페이즈 4 #4 chain_m7_mist_clearing 2단계 추가) · quest_narratives(88행) · travel_choice_events(12행) · travel_choice_options(30행) · travel_choice_results(72행) · crafting_recipes(18행·M7 신규 6 레시피·M8a +2 세력 레시피·unlock_condition_json type 확장: regionFlag/infrastructureTier/all/any/**factionReputation/factionContact**) · quest_pool_material_drops · band_achievement_templates(34행·9카테고리·M7 페이즈 4 #1 region_pacified 7행 + #4 infrastructure_growth 1행 추가·CHECK 확장) · titles(13행·M8a +2 세력 칭호·`hook_type` CHECK 확장 `faction_reputation` 추가) · region_adjacency(M7 페이즈 4 #3 신설 22행, from_region/to_region/distance_units, 양방향 11쌍, region_3 도달 보장) · **faction_contacts(M8a 페이즈 4 #1 신설 3행, optional, region 3 + 38 NPC 접촉점)** · **faction_reactions(M8a 페이즈 4 #1 신설 33행, optional, relation_stage 7종 + weight 가중 랜덤)** · **faction_shop_items(M8a 페이즈 4 #1 신설 18행, optional, stock_policy once/daily + 평판 1/11/31/61 해금)** · **combat_report_templates(M8a 페이즈 4 #2 신설 96행 + M8b 페이즈 4 #2 +85행 = 181행, optional, scope 8종(`combat_skill` 신규 추가) + scene 보충풀 + line_type summary/detail)** · **combat_report_keywords(M8a 페이즈 4 #2 신설 40행, optional, category battlefield/enemy/decisive)** · **combat_skills(M8b 페이즈 4 #2 신설 16행, optional, role 6종·trigger_kind 5종·action_cost 3종·targeting_kind 6종·dispel_kind 4종, party 10 + 적 전용 6)** · **combat_status_effects(M8b 페이즈 4 #2 신설 10행, optional, kind buff/debuff/mez/dot·stack_policy refresh/stack/ignore·apply_method multiplicative/additive/proportional/absolute/none)** · **enemies(M8b 페이즈 4 #2 신설 26행, optional, enemy_kind normal/elite/unique·role 6종·behavior_pattern 6종, 일반 17 + 일반 엘리트 5 + 유니크 4)**

**items 확장 (M8a):** category 4종 유지 · slot 17종 유지 · `items` 신규 17행(M8a 페이즈 4 #1 — 신규 4 아이템 `guild_artifact_record_compass`/`guild_artifact_trade_seal`/`guild_artifact_merchant_warrant`/`equip_accessory_red_spear_wristwrap` + 상점 placeholder 13종 — 효과 수치는 후속 마일스톤에서 확정)

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
| ActiveQuest | — | 28 |
| ActivityLogType (enum) | 6 | 41 |
| RegionState | 8 | 14 |
| FactionState | 9 | 10 |
| FactionClueRecord | 10 | — |
| InventoryItem | 11 | — |
| ChainQuestProgress | 13 | — |
| ChainQuestStatus | 14 | — |
| PersistedDialogEntry | 15 | — |
| BandAchievement | 16 | 7 |
| BandAchievementType (enum) | 17 | 2 |
| MercenarySnapshot | 18 | 6 |
| MemorialCause (enum) | 19 | 3 |
| FactionShopDailyEntry | 20 | 2 |
| CombatReport | 21 | 15 |
| CombatSimulationResult | 22 | 13 |
| CombatTurn | 23 | 5 |
| CombatAction | 24 | 17 |
| StatusEffectEvent | 25 | 10 |
| CombatantSnapshot | 26 | 15 |
| EnemySnapshot | 27 | 21 |
| CombatExitCondition (enum) | 28 | 6 |
| BehaviorPattern (enum) | 29 | 6 |
| PositionRow (enum) | 30 | 3 |

사용 중 typeId: 6·8·9·10·11·13·14·15·16·17·18·19·20·21·22·23·24·25·26·27·28·29·30. 신규 모델은 **31+** 사용. typeId 12는 여전히 미사용 (보존).
주요 마이그레이션 플래그: `stat_migration_v2` (settings 박스, 일회성 초기화).

### 코드 생성

freezed · json_serializable · hive_generator · riverpod_generator — `build_runner`로 관리. 생성 파일: `.g.dart`, `.freezed.dart`.

## 게임 핵심 시스템 로직

> 각 시스템의 메서드 시그니처·HiveField 번호·단계별 trailing 로직 등 세부 구현은 `Docs/architecture-notes.md` 참조.

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
- **제작 시스템**: `CraftingService`(콜백 DI) — `evaluateState`(4상태: 잠김/부족/충족) + `craft`(consumeMaterial × N → addItem → ActivityLog). `unlock_condition_json` 해금 6 type(trustLevel/chainStep/firstAcquiredItem/regionFlag/infrastructureTier/factionReputation/factionContact). 재료·소비재는 `InventoryRepository` stack 누적(999 클램프). 5종 드랍 출처 hook(의뢰·조사·엘리트·이동선택지·체인) → `RegionStateRepository.addAcquiredMaterial` 멱등 영속 추적. 낡은 대장간 = region 3 신뢰도 2단계+. 인벤토리 5탭째 MaterialTab + 양방향 점프(🔨 ↔ 인벤토리)
- **퀘스트 서사**: `QuestNarrativeService` — quest_type×result_type×is_elite 3중 필터 + weight 가중 랜덤 → `TemplateEngine` 렌더 → `renderedNarrative` 1회 저장 (재렌더 금지)
- **방치형 보상**: 분당 1G, 최대 480G + 금고 보너스
- **다이얼로그 큐**: 5계층 컨텐츠 공존 보장. priority: critical(rankUp) > high(chain/transform/trustUp/achievementUnlocked/titleUnlocked) > medium(construction/investigation/travelChoice/regionStateChanged/settlementInfrastructureUpgraded). critical은 `barrierDismissible: false`. DialogTypeRegistry 13종 (M7 페이즈 4 #1·#4 신규 2종 추가).
- **위업·연대기**: `AchievementService.grant(templateId, ...)` 멱등(hasAchievement 사전 체크) + 사이드이펙트(box.add → activityLog → dialog enqueue, `reputation_rank` 카테고리만 dialog 생략 — RankUpDialog 인라인 대체). 6 trailing hook(체인 완주·거점 신뢰도 4단계·명성 등급 진입·엘리트 유니크 첫 처치·T3+ 첫 제작·사망/방출 memorial) 모두 fail-soft. `MercenarySnapshot`은 발급 시점 동결(본체 삭제 후 참조). `recordMemorial`은 box.add만(dialog 없음). `bandAchievementsProvider`(box.watch) + ChronicleScreen(상태 기반). 카테고리 7종은 templateId `:` 앞부분
- **칭호·간판 용병**: `TitleService` 3 hook(위업/행동지표/상태) fail-soft → `TitleUnlockedDialog`. `hook_target` 5종(require_protagonist/first_only/last_dispatch_protagonist/most_dispatched_to_region_3/top_contributor_24h). `FlagshipMercenaryService.selectAuto` 5단계 정렬 — 수동(`UserData.flagshipMercId`) 우선, dead/미설정 시 자동 fallback(`flagshipMercenaryProvider`). 칭호 효과는 `PassiveBonusService.collect(titleEffects:)` 파티 첫 mercenary 단독 적용(가산 상한 +0.30). `titleServiceProvider`는 순환 참조 회피로 분리. `titles` 테이블(M8.5 시점 칭호 다수, hook_type=action_stat/faction_reputation 등)
- **지명 의뢰**: `NamedHookEvaluator.evaluateNamedHook(pool, ctx)` 4 hook_type(title/achievement_count/achievement_id/flagship, 미상은 silent false). 발급 가중치 α=3, `QuestSortService` named 슬롯, 보상 배수(`named_reward_multiplier` × 명성 1.30~1.50). `UserData.namedQuestCooldowns` 24h 회전. flagship 의뢰는 `namedTargetMercId` 동결 — 사망/방출 시 `terminateNamedQuestsForMerc`로 자동 제거. 카드 `AppTheme.namedAccent`(분홍) + hook 용병 전원 파견 중일 때 `Opacity+AbsorbPointer` 잠금. 단일 hook 정책(복합 조건 M9+ 위임)
- **지역 상태 변화**: `RegionState`에 dangerScore(-100~100)/dangerLevel(1~4)/unlockedFlags. `DangerLevel` enum 4종(stable/peaceful/tension/threat) + `DangerLevelResolver`. `RegionStateRepository.addDangerScore`/`toggleFlag`/`hasFlag`. 트리거 5종 fail-soft trailing(의뢰 완료·체인 완주·엘리트 유니크 첫 처치·decay 12시간 +1·flag toggle). `dangerLevelChangedProvider`(isBigTransition=true만 enqueue → `RegionStateChangedDialog`). M7 핵심 7리전 = `M7Constants.livingsphereRegions`(3·31·127·9·10·146·38)
- **QuestGenerator 가중치 분기**: `QuestPool`에 regionStateEffect(`RegionStateEffect` sealed: Cumulative/Oneshot)/regionStateRequired/Excluded. `QuestGenerator.computeFinalWeight({pool,regionState,gate})` 7단계(NewbieGate base → required/excluded weight=0 → dangerLevel × → flag × → cumulative cap × → named 가산). 매트릭스는 `RegionStateWeightConfig` 정적 상수. 완료 시 `RegionStateRepository.applyDangerScoreFromQuest`(성공/대성공 한정 fail-soft)
- **이동 화면 + 거점 상세 UI**: `region_adjacency` 테이블 → `MovementDistanceCalculator.calculate`(인접 distance_units + sector 차, `UserData.calculateDistance` fallback). 광장 이정표 infraTier≥2 시 거리 -10%. `AppTheme.dangerLevelColor`/`dangerLevelLabel`(안정/평온/긴장/위협) + `RegionStatusBadgeRow` + `LivingsphereJumpBar`(7리전 진입 시). `VillageVisitSection`/`ChiefHouseScreen` Tier별 카드·버튼
- **마을 인프라 성장**: `RegionState.infrastructureTier`(1~4, region 3 한정). `SettlementInfrastructureConfig` 정적 상수(임계 {2:2,3:4,4:6} + 단계 보상/이름/외래상점 가격). `RegionStateRepository._evaluateInfrastructureTransition`(7리전 flag 합산 → resolveTier → 통과 단계 보상, `toggleFlag` trailing). `settlementInfrastructureTierProvider`(family). `VillageFacility.foreignStall` + `ForeignStallScreen`(Tier별 재료 거래). `HerbalistService` infra multiplier(cost/cooldown/gathering). 인프라 상승 시 `settlementInfrastructureUpgradedProvider`(medium)
- **세력 수직 절편**: 대표 3 세력(모험가/상인/전사)에 "접촉점 → 후원 → 가입 → 신뢰" 절편. `FactionContactService.isActive`(infrastructureTier/region_flag/achievement 3 trigger). `FactionRelationStage` enum 7종 + `resolve`. `FactionShopService`(stock_policy once/daily, 24h restock, sealed `FactionShopUnlockResult`). `NamedHookEvaluator` 3 hook 확장(region_flag/faction_contact/faction_reputation) + `NamedHookContextBuilder.build(ref)` 단일 진입점. `QuestCompletionService`는 `faction_named` 평판 분기(음수 가능). `FactionDetailScreen` 3 섹션 + `FactionCodexScreen` 분홍 dot
- **턴 전투 시뮬레이터**: `CombatSimulator.simulate(...) → CombatSimulationResult?` 정적 결정적 4 페이즈(사전→선제→일반 1~8R→마무리). 시드 = `stableSeed32('${startTime.microsecondsSinceEpoch}|${quest.id}')`(Dart `hashCode` 금지). 종료 6종(파티/적 전멸·목표·라운드 한계·도주·호위 사망). 확률 clamp(명중 [.50,.95]/회피 [0,.75]/치명 [.05,.60]/사망저항 [.20,.80]+체인 주인공 .90). 7 PRNG 도메인 키별 매 액션 새 인스턴스. 정적 카탈로그 3종(CombatSkill/StatusEffect/EnemyArchetype) + 영속 6종(typeId 22~27) + enum 3종(28~30). `QuestCompletionService.calculate(regionState:)`가 `combatSimulationEligible`(엘리트/체인 핵심·최종/지명/고급 세력) 평가 후 simulate → resultType override. fail-soft fallback 5종(일반 의뢰/userData null/simulate null·throw/startTime null). `deathResistanceCaps`(M8.5 솔로/소수정예)
- **전투 보고서**: `CombatReport`(typeId 21) → `ActiveQuest.combatReport` 임베드(별도 박스 미사용). `CombatReportService.generate(...)` scope 7종 + scene 보충풀(`_resolveScopeChain` 좁은→넓은 fallback). `_resultTypeKey`로 CSV snake_case ↔ Dart camelCase 매핑(직접 `.name` 비교 금지). 주인공(`pickProtagonist`) null이면 미생성. `combat_report_templates`/`_keywords` optional 테이블 — 빈 캐시 = 미생성 fail-soft. `_applyCompletionResult`가 `combatReportEligible && combatReport==null` 가드 + try/catch trailing. `QuestResultDialog`는 `ConsumerStatefulWidget` + `_showDetail` + `AnimatedSwitcher` 인라인(Navigator.push 금지)
- **솔로/소수정예 의뢰**: 지명 의뢰 확장. `QuestPool.partySizeMin`/`partySizeMax`(일반 의뢰=`null`로 기존 동작 보존). `FlagshipSoloQuestConfig` 정적 상수(사망저항 cap 솔로 0.95/소수 0.90, 쿨다운 48h/36h, weight α 2.0) + 4 매트릭스(party_size/guaranteed_drop/probabilistic_drop/epilogue). `computeFinalWeight`는 `named_weight_alpha`(fallback 3.0). `QuestSortService.namedTier` 3 그룹(솔로 max=1 / 소수 2~3 / 일반 null). `CombatSimulator.simulate(deathResistanceCaps:)` 5계층 패스스루(`effectiveMax = max(perMercCap, baseCap)`, 기존 호출은 `const {}` default 호환). `_applyCompletionResult` 5 trailing fail-soft(카운터+칭호 hook / 실패 로그 / 보장·확률 드랍 / epilogue). `DispatchDetailPage` 정확 인원 강제 + `partySizeLabel`(⭐/⭐⭐/⭐⭐⭐)

## 테스트 구조

72개 테스트 파일, `test/` 아래 `lib/` 구조와 동일. 도메인 서비스 유닛 테스트 위주. 전체 테스트 669 PASS(M8b 페이즈 4 #5 검증·밸런스 명세 구현 시점).

```bash
cd band_of_mercenaries && flutter test test/features/quest/
cd band_of_mercenaries && flutter test test/features/mercenary/
```

## 문서 구조

`Docs/` — `game_overview.md`(기획 레퍼런스·구현 현황) · `roadmap/master_roadmap.md`(마일스톤 계획) · `content_status.md`(M3 기준 보관본) · `project_snapshot_for_ai.md`(AI 컨텍스트용) · `spec/`(진행 중 명세서) · `milestone-runs/`(마일스톤 진행 상태) · `content-design/`·`balance-design/`·`content-data/`(컨텐츠 산출물) · `Archive/`(완료 산출물) · `changelog-fragments/`(릴리스 노트 단편)

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
