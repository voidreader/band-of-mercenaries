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
│   ├── providers/         # 전역 상태 (game_state, static_data, timer)
│   └── theme/             # Material 3 테마, 티어별 색상
├── features/              # 기능별 모듈
│   ├── home/              # 홈(야영지) 화면
│   ├── movement/          # 이동 시스템, TravelEventService, MovementState
│   ├── quest/             # 퀘스트/파견 시스템, QuestCompletionService
│   ├── mercenary/         # 용병 모집/관리, FacilityService, RecruitmentService
│   └── settings/          # 설정, 시설 관리 (FacilityScreen)
└── shared/widgets/        # 공유 위젯 (BottomNavBar, TimerDisplay, StatusBadge)
```

### feature 모듈 구조

각 feature는 `view/`, `domain/`, `data/` 3계층으로 분리:
- **view**: 화면 위젯
- **domain**: 비즈니스 로직 (Notifier, Calculator, Service)
- **data**: Repository (Hive 박스 접근)

### 상태 관리

**Flutter Riverpod** 사용. 주요 Provider:
- `gameTickProvider`: 1초 간격 Stream으로 게임 루프 구동 (퀘스트 완료, 이동 도착 체크)
- `userDataProvider`: 전역 게임 상태 (골드, 위치, 이동 상태)
- `staticDataProvider`: 로컬 JSON 캐시에서 로드된 정적 데이터 (Region, Job, Trait 등). 앱 시작/포그라운드 복귀 시 Supabase와 버전 비교 후 갱신
- `mercenaryListProvider` / `questListProvider`: 용병 및 퀘스트 상태
- `activityLogProvider`: 활동 로그 (Hive `activityLogs` 박스, 최대 100개)

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
- 첫 실행: 서버 연결 필수, 전체 16개 테이블 다운로드
- 이후 실행: `data_versions` 테이블로 버전 비교, 변경된 테이블만 다운로드
- 서버 연결 실패 시: 로컬 캐시로 오프라인 플레이 가능 (캐시 있는 경우)
- 싱크 타이밍: 앱 시작 + 포그라운드 복귀

**정적 데이터 테이블 (16개):**
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

**모델 JSON 키 규칙:** 모든 정적 데이터 모델은 snake_case @JsonKey를 사용 (Supabase 컬럼명과 일치). Dart 필드명과 동일한 경우 @JsonKey 생략.

### Supabase 연결

- `supabase_flutter` 패키지 사용
- `.env` 파일에 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 설정 (gitignored)
- `.env.example`에 템플릿 존재
- 현재 인증 없이 anon key로 읽기 전용 접근 (향후 로그인 추가 예정)

### 영속성

**Hive** (NoSQL key-value): `user`, `mercenaries`, `quests`, `activityLogs`, `settings` 5개 박스 사용. Hive 어댑터는 `hive_generator`로 자동 생성.
- `mercenaries` 박스: Mercenary 모델 — HiveField(14) `stats` (Map<String, int>, 23개 행동 지표), HiveField(15) `traitIds` (List<String>, 복수 트레잇). `allTraitIds` getter로 구 traitId 호환
- `settings` 박스: 일반 key-value. 키는 `SettingsKeys` 상수 클래스(`core/data/settings_keys.dart`)에서 중앙 관리

### 코드 생성

freezed, json_serializable, hive_generator, riverpod_generator 4종을 `build_runner`로 관리. 생성된 파일은 `.g.dart`, `.freezed.dart` 확장자.

## 게임 핵심 시스템 로직

- **이동**: 거리 = |리전 차이| + |섹터 차이|, 소요시간 = 거리 × 30초. 이동 중 TravelEvent 랜덤 발생 (골드, 부상, 지연, 명성 등)
- **성공률**: 50% + (아군전투력/적전투력 - 1) × 50% + 특성보너스 + 퀘스트보정 - 거리패널티 + 랜덤편차, 범위 5%~95%
- **결과**: 대성공(보상 2배) / 성공 / 실패(부상) / 대실패(사망률 증가)
- **경제**: 파견비용(난이도별 min~max, 소요시간 비례 보간) + 인건비(용병 티어별) 선차감, 순수익 = 보상 - 인건비 - 파견비용
- **경험치/레벨**: 퀘스트 완료 시 XP 획득 (난이도 × 기본XP × 결과배수 + 시설보너스), 최대 레벨 5
- **명성/랭크**: 퀘스트 완료 시 명성 획득, 등급 F~A, 랭크에 따라 상위 티어 리전 잠금 해제
- **시설**: 훈련소(XP보너스), 의무실(회복감소), 주둔지(용병상한), 정보망(퀘스트수). 골드로 업그레이드
- **용병 상태**: 정상 → 피곤함(능력치 80%, 5분) → 부상(난이도×10분) → 사망(영구 제거). 레벨업 시 능력치 증가
- **모집**: 티어별 확률 가중 (Tier1: 45%, Tier2: 30%, Tier3: 15%, Tier4: 8%, Tier5: 2%). 선천 트레잇 1~3개 랜덤 부여 (Physical/Background/Talent 각 60% 확률, 최소 1개). 주둔지 용량 제한
- **트레잇 시스템**: 선천(최대 3, 영구) + 후천(최대 4, 획득/진화). `MercenaryStatService`로 23개 행동 지표 추적 → 퀘스트 완료 시 `TraitAcquisitionService`가 조건 체크 → 자동 획득. `TraitEffectService`로 effect_json 기반 성공률/데미지 보정. 충돌 관계 검증 포함
- **방출**: 파견 중이 아닌 용병을 퇴직금(인건비×레벨) 지급 후 영구 방출. 재모집 불가
- **퀘스트 갱신**: 대기 중 퀘스트는 1시간(게임 시간)마다 자동 교체. 5개 미만이면 채우기 가능
- **방치형 보상**: 앱 미접속 시간 기준 분당 1G, 최대 480G(8시간). 실제 시간 기준
- **시간 가속**: 속도 변경 시 모든 활성 타이머의 endTime을 비례 재계산 (개발/테스트용)
- **이동 제한**: 파견 중인 용병이 있으면 이동 불가

## 분석 설정

`analysis_options.yaml`에서 `invalid_annotation_target: ignore` 설정됨 (freezed/json_serializable 호환용). `avoid_print: true` 린트 룰 활성화.

## UI

- 한국어 텍스트 (국제화 미적용)
- Material 3 다크 프라이머리 테마
- 티어별 색상: 회색(1) → 초록(2) → 파랑(3) → 보라(4) → 빨강(5)
- 하단 5탭: 이동 / 파견 / 홈 / 모집 / 설정
- 웹: `_MobileFrame`에서 `ConstrainedBox(maxWidth: 430)`으로 모바일 해상도 제한. 새 화면 전환 시 `Navigator.push` 대신 상태 기반 렌더링 사용 (Navigator가 ConstrainedBox 바깥으로 빠져나가는 문제 방지)
- 파견 화면: 퀘스트 선택 시 전체화면 `DispatchDetailPage`를 상태 기반으로 렌더링 (3단 구조: 상단 퀘스트 정보/중앙 용병 목록/하단 버튼)
- 퀘스트 완료 팝업: 보상 상세 내역 (골드, 파견비, 인건비, 순수익, XP, 명성) 표시. `ActiveQuest` 모델에 HiveField 12-16으로 보상 데이터 저장
