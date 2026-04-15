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
│   ├── investigation/     # 지역 조사 시스템 (InvestigationNotifier, RegionStateRepository, InvestigationWidget)
│   ├── info/              # 정보 탭 (InfoScreen, FactionCodexScreen, FactionDetailScreen, FactionStateRepository)
│   └── settings/          # 설정 (시간 가속)
└── shared/widgets/        # 공유 위젯 (BottomNavBar, TimerDisplay, StatusBadge)
```

### feature 모듈 구조

각 feature는 `view/`, `domain/`, `data/` 3계층으로 분리:
- **view**: 화면 위젯
- **domain**: 비즈니스 로직 (Notifier, Calculator, Service)
- **data**: Repository (Hive 박스 접근)

### 상태 관리

**Flutter Riverpod** 사용. 주요 Provider:
- `gameTickProvider`: 1초 간격 Stream으로 게임 루프 구동 (퀘스트 완료, 이동 도착, 건설 완료 체크)
- `userDataProvider`: 전역 게임 상태 (골드, 위치, 이동 상태)
- `staticDataProvider`: 로컬 JSON 캐시에서 로드된 정적 데이터 (Region, Job, Trait 등). 앱 시작/포그라운드 복귀 시 Supabase와 버전 비교 후 갱신
- `mercenaryListProvider` / `questListProvider`: 용병 및 퀘스트 상태
- `activityLogProvider`: 활동 로그 (Hive `activityLogs` 박스, 최대 100개)
- `currentTabProvider`: 하단 네비게이션 탭 인덱스 (`core/providers/navigation_provider.dart`)
- `constructionCompletedProvider`: 건설 완료 알림 (`features/facility/domain/construction_completion_provider.dart`)
- `investigationNotifierProvider`: 지역 조사 시작/완료 로직 (`features/investigation/domain/investigation_notifier.dart`)
- `investigationCompletedProvider`: 조사 완료 알림 StateProvider<InvestigationResult?> (`features/investigation/domain/investigation_completion_provider.dart`)
- `factionStateRepositoryProvider`: FactionStateRepository 인스턴스 (`features/info/data/faction_state_repository.dart`)
- `factionListProvider`: staticDataProvider의 factions를 동기 제공하는 Provider<List<FactionData>> (`features/info/domain/faction_codex_providers.dart`)
- `factionCodexScrollTargetProvider`: 조사 완료 팝업 → 세력 도감 자동 스크롤용 StateProvider<String?> (`features/info/domain/faction_codex_providers.dart`)

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
- 첫 실행: 서버 연결 필수, 전체 18개 테이블 다운로드
- 이후 실행: `data_versions` 테이블로 버전 비교, 변경된 테이블만 다운로드
- 서버 연결 실패 시: 로컬 캐시로 오프라인 플레이 가능 (캐시 있는 경우)
- 싱크 타이밍: 앱 시작 + 포그라운드 복귀

**정적 데이터 테이블 (18개):**
- regions: 199개 리전 (5단계 티어)
- jobs: 5티어 30+ 직업
- trait_categories: 8개 트레잇 카테고리 (Physical, Background, Talent, CombatStyle, Survival, Behavior, Mental, Experience)
- traits: 106개 트레잇 (선천 35 + 후천 acquired 40 + 후천 evolved 31). key/name/categoryKey/type/description/effectText/acquisitionCondition/effectJson
- trait_conflicts: 충돌 관계 (16쌍, 양방향 32행)
- trait_transitions: 단일 진화 경로 (16개, condition_json으로 복합 조건)
- trait_combo_evolutions: 조합 진화 레시피 (15개)
- trait_synergies: 선천-후천 시너지 (39개, 획득 조건 완화 비율)
- difficulties: 5단계 난이도 설정 (min_dispatch_cost/max_dispatch_cost로 시간 비례 비용)
- quest_types / quest_pools: 퀘스트 유형 및 풀
- person_names: 한국어 이름 ~500개
- travel_events: 이동 중 랜덤 이벤트 (발견, 습격, 날씨, 행운, 조우)
- facilities: 시설 종류 및 레벨별 비용/효과 (훈련소, 의무실, 주둔지, 정보망)
- ranks: 명성 등급 (F~A) 및 티어 잠금 해제 조건
- mercenary_wages: 티어별 용병 인건비
- region_discoveries: 리전별 발견 데이터 (id TEXT PK, region_id INTEGER, knowledge_threshold INTEGER, discovery_type TEXT, discovery_data JSONB, description TEXT)
- factions: 세력 마스터 데이터 (id TEXT PK, name TEXT, description TEXT, philosophy TEXT, tier_range JSONB, color TEXT)

**모델 JSON 키 규칙:** 모든 정적 데이터 모델은 snake_case @JsonKey를 사용 (Supabase 컬럼명과 일치). Dart 필드명과 동일한 경우 @JsonKey 생략.

### Supabase 연결

- `supabase_flutter` 패키지 사용
- `.env` 파일에 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 설정 (gitignored)
- `.env.example`에 템플릿 존재
- 현재 인증 없이 anon key로 읽기 전용 접근 (향후 로그인 추가 예정)

### 영속성

**Hive** (NoSQL key-value): `user`, `mercenaries`, `quests`, `activityLogs`, `settings`, `regionStates` 6개 박스 사용. Hive 어댑터는 `hive_generator`로 자동 생성.
- `mercenaries` 박스: Mercenary 모델 — HiveField(4) `str` (int), HiveField(5) `intelligence` (int), HiveField(6) `vit` (int), HiveField(7) `agi` (int, 기존 double speed에서 변환). HiveField(14) `stats` (Map<String, int>, 23개 행동 지표), HiveField(15) `traitIds` (List<String>, 복수 트레잇), HiveField(16) `traitHistory` (List<String>, 소멸/삭제 트레잇 기록 → 재획득 방지), HiveField(17) `deletedTraitIds` (List<String>, 삭제된 트레잇 기록 → 히스토리 UI에서 (삭제) 구분 표시). `allTraitIds` getter로 구 traitId 호환. 앱 첫 실행 시 `stat_migration_v2` 플래그(settings 박스)로 일회성 데이터 초기화 수행
- `user` 박스 건설 큐: HiveField(12) `constructionFacilityId` (String?, 건설 중 시설 ID), HiveField(13) `constructionStartTime` (DateTime?), HiveField(14) `constructionEndTime` (DateTime?)
- `user` 박스 지역 조사: HiveField(15) `investigatingMercId` (String?, 조사 중 용병 ID), HiveField(16) `investigationEndTime` (DateTime?), HiveField(17) `investigationRegionId` (int?)
- `regionStates` 박스: RegionState 모델 (typeId:8) — regionId(int), knowledge(int 0~100), triggeredDiscoveries(List<String>). regionId 키로 저장
- `factionStates` 박스: FactionState 모델 (typeId:9) — factionId(String), clueRecords(List<FactionClueRecord>). `discoveredInRegions` getter로 고유 리전 ID 계산. FactionClueRecord(typeId:10) — factionId, regionId, discoveryId, foundAt. `FactionStateRepository`로 CRUD
- `settings` 박스: 일반 key-value. 키는 `SettingsKeys` 상수 클래스(`core/data/settings_keys.dart`)에서 중앙 관리

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
- **명성/랭크**: 퀘스트 완료 시 명성 획득, 등급 F~A, 랭크에 따라 상위 티어 리전 잠금 해제
- **시설**: 12종, 최대 Lv25, 건설 큐 1개(한 번에 하나만 건설). 골드 비용 + 건설 시간(Lv1: 5분, Lv2: 10분, Lv3+: `25×1.45^(Lv-3)` 분). 효과 로그 스케일(`maxEffect × ln(1+level×α) / ln(1+25×α)`). 비용 4티어: Core(300G)/Standard(500G)/Premium(700G)/Expensive(1,000G), 배율 1.5. `ConstructionService`로 공식 계산, `FacilityService`는 wrapper. 건설 완료는 gameTickProvider에서 체크. 시간 가속 적용. 기능 해금 이정표는 milestones JSONB로 정의(현재 stub). 시설 목록: 훈련소(XP)/의무실(회복+트레잇삭제)/주둔지(용병상한)/정보망(퀘스트수)/대장간(장비stub)/주점(모집확률)/연구소(조사stub)/방어시설(피해감소)/금고(방치보상)/게시판(품질stub)/이동수단(이동시간)/야전병원(부상감소)
- **용병 상태**: 정상 → 피곤함(능력치 80%, 5분) → 부상(난이도×10분) → 사망(영구 제거). 레벨업 시 능력치 증가
- **모집**: 티어별 확률 가중 (Tier1: 45%, Tier2: 30%, Tier3: 15%, Tier4: 8%, Tier5: 2%). 선천 트레잇 1~3개 랜덤 부여 (Physical/Background/Talent 각 60% 확률, 최소 1개). 주둔지 용량 제한
- **트레잇 시스템**: 선천(최대 3, 영구) + 후천(최대 4, 획득/진화/삭제). `MercenaryStatService`로 23개 행동 지표 추적 → 퀘스트 완료 시 `TraitAcquisitionService`가 조건 체크 → 자동 획득. `TraitEffectService`로 effect_json 기반 성공률/데미지 보정. 충돌 관계 검증 포함(`hasConflict` public static). `TraitEvolutionService`로 단일 진화(acquired → evolved, conditionJson 충족 시 교체) + 조합 진화(2개 acquired → evolved, 원본 소멸 + 슬롯 해방). `TraitDeletionService`로 후천 트레잇 삭제(acquired 200G/evolved 500G, 의무실 레벨 해금). 소멸/삭제 트레잇은 `traitHistory`에 기록되어 재획득 방지. 퀘스트 완료 시 획득은 자동 적용 후 알림 팝업, 진화는 `pendingTraitEventsProvider`를 통해 UI에서 카드 비교형 선택 팝업으로 플레이어가 경로 결정 (보류 가능). 여행 이벤트로 빈 선천 슬롯에 트레잇 부여 가능 (`lastTravelEventTraitResultProvider`로 결과 전달)
- **방출**: 파견 중이 아닌 용병을 퇴직금(인건비×레벨) 지급 후 영구 방출. 재모집 불가
- **퀘스트 갱신**: 대기 중 퀘스트는 1시간(게임 시간)마다 자동 교체. 5개 미만이면 채우기 가능
- **방치형 보상**: 앱 미접속 시간 기준 분당 1G, 최대 480G(8시간) + 금고 시설 보너스. 실제 시간 기준
- **지역 조사**: 용병 1명을 현재 리전에 배치하여 지식 포인트(knowledge 0~100) 누적. 성공률 = `(85 + (AGI+VIT)/200).clamp(5,95)%`. 소요시간 리전 티어별(T1=5분~T5=20분). 지식 임계값 도달 시 `region_discoveries` 발견 자동 트리거. 파견·이동과 독립된 별도 슬롯. `InvestigationNotifier`(StateNotifier<void>)가 완료 처리, 결과는 `investigationCompletedProvider`(StateProvider<InvestigationResult?>)로 전달
- **시간 가속**: 속도 변경 시 모든 활성 타이머(퀘스트, 이동, 건설, 조사)의 endTime을 비례 재계산 (개발/테스트용)
- **이동 제한**: 파견 중인 용병이 있거나 조사 진행 중이면 이동 불가. 조사 중에도 이동 불가 (양방향 상호 배제)
- **세력 발견**: 지역 조사 완료 시 `region_discoveries`의 `discovery_type == 'faction_clue'` 항목이 트리거되면 세력 단서를 발견. `discovery_data` JSON에서 `faction_id`, `clue_level`(1~3), `clue_text` 추출 → `FactionStateRepository.processClue()`로 Hive 저장. 동일 discoveryId 중복 발견 시 기록만 추가(maxClueLevel 유지). clue_level별 활동 로그: level1 "세력 단서 발견", level2 "세력 발견: {name}의 정체를 파악했다", level3 "거점 발견: {name}의 전초기지 위치를 파악했다". 조사 완료 팝업에 인라인 표시 + "도감에서 확인" 버튼으로 정보 탭 → 세력 도감 자동 이동

## 분석 설정

`analysis_options.yaml`에서 `invalid_annotation_target: ignore` 설정됨 (freezed/json_serializable 호환용). `avoid_print: true` 린트 룰 활성화.

## UI

- 한국어 텍스트 (국제화 미적용)
- Material 3 다크 프라이머리 테마
- 티어별 색상: 회색(1) → 초록(2) → 파랑(3) → 보라(4) → 빨강(5)
- 하단 6탭: 이동 / 파견 / 홈 / 모집 / 시설 / 정보
- 웹: `_MobileFrame`에서 `ConstrainedBox(maxWidth: 430)`으로 모바일 해상도 제한. 새 화면 전환 시 `Navigator.push` 대신 상태 기반 렌더링 사용 (Navigator가 ConstrainedBox 바깥으로 빠져나가는 문제 방지)
- 파견 화면: 퀘스트 선택 시 전체화면 `DispatchDetailPage`를 상태 기반으로 렌더링 (3단 구조: 상단 퀘스트 정보/중앙 용병 목록/하단 버튼)
- 퀘스트 완료 팝업: 보상 상세 내역 (골드, 파견비, 인건비, 순수익, XP, 명성) 표시. `ActiveQuest` 모델에 HiveField 12-16으로 보상 데이터 저장. 이후 트레잇 획득 알림 → 진화 선택 팝업 순서로 체이닝
- 용병 상세 오버레이: `selectedMercenaryIdProvider`로 앱 레벨 전체화면 오버레이. 용병 카드 탭 → 프로필/트레잇 슬롯(TraitSlotGrid)/행동 지표(BehaviorStatsSection)/히스토리(TraitHistorySection) 단일 스크롤. 트레잇 탭 → TraitDetailDialog (효과, 진화 경로 진행도, 시너지, 충돌)
- 설정 화면: 홈 탭 상단 우측 `Icons.settings` 아이콘 버튼 탭 → `_showSettings` 상태 변수로 상태 기반 렌더링 (탭 6번째 자리 → 정보 탭으로 대체됨)
- 정보 탭 (`InfoScreen`): 세력 도감(`FactionCodexScreen`) 진입 허브. `_showCodex`/`_selectedFactionId` 상태 변수로 화면 전환. `factionCodexScrollTargetProvider` non-null 감지 시 자동으로 도감 화면으로 전환
