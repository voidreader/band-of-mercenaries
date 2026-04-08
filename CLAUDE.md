# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

용병단 운영 텍스트 기반 전략 시뮬레이션 모바일 게임. Flutter로 개발되며, 로컬 JSON + Hive를 사용한 오프라인 MVP 단계. 기획 문서는 `Docs/proto_design.md` 참조.

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
├── main.dart              # 진입점 (Hive 초기화 → ProviderScope)
├── app.dart               # 앱 셸 + 하단 네비게이션
├── core/
│   ├── data/              # HiveInitializer, JsonLoader
│   ├── models/            # 정적 데이터 모델 (freezed + json_serializable)
│   ├── providers/         # 전역 상태 (game_state, static_data, timer)
│   └── theme/             # Material 3 테마, 티어별 색상
├── features/              # 기능별 모듈
│   ├── home/              # 홈(야영지) 화면, ReputationService
│   ├── movement/          # 이동 시스템, TravelEventService
│   ├── quest/             # 퀘스트/파견 시스템, ExperienceService
│   ├── mercenary/         # 용병 모집/관리, FacilityService
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
- `staticDataProvider`: JSON에서 로드된 정적 데이터 (Region, Job, Trait 등)
- `mercenaryListProvider` / `questListProvider`: 용병 및 퀘스트 상태

### 데이터 흐름

```
정적 JSON (assets/json/) → JsonLoader → FutureProvider
사용자 액션 → Repository → Hive 저장 → StateNotifier → UI 갱신
게임 틱 (1초) → 완료 체크 → 자동 결과 계산
```

### 정적 데이터

`Json/` 디렉토리에 원본 JSON 파일, `band_of_mercenaries/assets/json/`에 앱 번들용 복사본.
- Region.json: 199개 리전 (5단계 티어)
- Job.json: 5티어 30+ 직업
- Trait.json: 4종 특성 (강인함, 노련함, 겁쟁이, 광전사)
- Difficulty.json: 5단계 난이도 설정 (파견비용 포함)
- QuestType.json / QuestPool.json: 퀘스트 유형 및 풀
- PersonName.json: 한국어 이름 ~500개
- TravelEvent.json: 이동 중 랜덤 이벤트 (발견, 습격, 날씨, 행운, 조우)
- Facility.json: 시설 종류 및 레벨별 비용/효과 (훈련소, 의무실, 주둔지, 정보망)
- Rank.json: 명성 등급 (F~A) 및 티어 잠금 해제 조건
- MercenaryWage.json: 티어별 용병 인건비

### 영속성

**Hive** (NoSQL key-value): `user`, `mercenaries`, `quests` 3개 박스 사용. Hive 어댑터는 `hive_generator`로 자동 생성.

### 코드 생성

freezed, json_serializable, hive_generator, riverpod_generator 4종을 `build_runner`로 관리. 생성된 파일은 `.g.dart`, `.freezed.dart` 확장자.

## 게임 핵심 시스템 로직

- **이동**: 거리 = |리전 차이| + |섹터 차이|, 소요시간 = 거리 × 30초. 이동 중 TravelEvent 랜덤 발생 (골드, 부상, 지연, 명성 등)
- **성공률**: 50% + (아군전투력/적전투력 - 1) × 50% + 특성보너스 + 퀘스트보정 - 거리패널티 + 랜덤편차, 범위 5%~95%
- **결과**: 대성공(보상 2배) / 성공 / 실패(부상) / 대실패(사망률 증가)
- **경제**: 파견비용(난이도별) + 인건비(용병 티어별) 선차감, 순수익 = 보상 - 인건비 - 파견비용
- **경험치/레벨**: 퀘스트 완료 시 XP 획득 (난이도 × 기본XP × 결과배수 + 시설보너스), 최대 레벨 5
- **명성/랭크**: 퀘스트 완료 시 명성 획득, 등급 F~A, 랭크에 따라 상위 티어 리전 잠금 해제
- **시설**: 훈련소(XP보너스), 의무실(회복감소), 주둔지(용병상한), 정보망(퀘스트수). 골드로 업그레이드
- **용병 상태**: 정상 → 피곤함(능력치 80%, 5분) → 부상(난이도×10분) → 사망(영구 제거). 레벨업 시 능력치 증가
- **모집**: 티어별 확률 가중 (Tier1: 45%, Tier2: 30%, Tier3: 15%, Tier4: 8%, Tier5: 2%). 주둔지 용량 제한

## 분석 설정

`analysis_options.yaml`에서 `invalid_annotation_target: ignore` 설정됨 (freezed/json_serializable 호환용).

## UI

- 한국어 텍스트 (국제화 미적용)
- Material 3 다크 프라이머리 테마
- 티어별 색상: 회색(1) → 초록(2) → 파랑(3) → 보라(4) → 빨강(5)
- 하단 5탭: 이동 / 파견 / 홈 / 모집 / 설정
