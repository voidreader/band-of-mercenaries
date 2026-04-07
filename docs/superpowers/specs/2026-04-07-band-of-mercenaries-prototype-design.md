# Band of Mercenaries — 프로토타입 설계 문서

## 1. 프로젝트 개요

- **장르**: 텍스트 기반 전략 시뮬레이션
- **플랫폼**: 모바일 (Flutter)
- **상태 관리**: Riverpod
- **로컬 저장소**: Hive
- **백엔드**: 초기 로컬(Hive), 이후 Supabase 확장
- **UI 언어**: 한국어 전용
- **UI 테마**: 화이트 배경, 색상 최소화, 미니멀 스타일
- **레퍼런스**: OGAME, 아크메이지, Melvor Idle, Kingdom of Loathing

## 2. 아키텍처

### 프로젝트 구조 (Hybrid: 기능별 + 내부 계층)

```
band_of_mercenaries/
├── assets/
│   └── json/                    # Static JSON 데이터
│       ├── Difficulty.json
│       ├── Job.json
│       ├── Trait.json
│       ├── Region.json
│       ├── QuestPool.json
│       ├── QuestType.json
│       └── PersonName.json
├── lib/
│   ├── main.dart                # 앱 진입점, Hive 초기화, ProviderScope
│   ├── app.dart                 # MaterialApp, 라우팅, 테마
│   ├── core/
│   │   ├── data/
│   │   │   ├── json_loader.dart       # assets/json → 모델 파싱
│   │   │   └── hive_initializer.dart  # Hive 박스 등록/초기화
│   │   ├── models/
│   │   │   ├── difficulty.dart
│   │   │   ├── job.dart
│   │   │   ├── trait.dart
│   │   │   ├── region.dart
│   │   │   ├── quest_type.dart
│   │   │   └── person_name.dart
│   │   ├── providers/
│   │   │   ├── game_state_provider.dart   # 전역 게임 상태
│   │   │   ├── timer_provider.dart        # 게임 타이머 + 가속
│   │   │   └── static_data_provider.dart  # JSON 정적 데이터
│   │   └── theme/
│   │       └── app_theme.dart             # 화이트 미니멀 테마
│   ├── features/
│   │   ├── home/
│   │   │   └── view/
│   │   │       ├── home_screen.dart
│   │   │       └── campsite_painter.dart  # CustomPaint 도트풍 야영지
│   │   ├── mercenary/
│   │   │   ├── data/
│   │   │   │   └── mercenary_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── mercenary_model.dart
│   │   │   │   └── mercenary_provider.dart
│   │   │   └── view/
│   │   │       ├── recruit_screen.dart
│   │   │       └── mercenary_card.dart
│   │   ├── quest/
│   │   │   ├── data/
│   │   │   │   └── quest_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── quest_model.dart
│   │   │   │   ├── quest_provider.dart
│   │   │   │   └── quest_calculator.dart  # 성공률/결과 계산
│   │   │   └── view/
│   │   │       ├── dispatch_screen.dart
│   │   │       └── quest_result_dialog.dart
│   │   ├── movement/
│   │   │   ├── data/
│   │   │   │   └── movement_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── movement_model.dart
│   │   │   │   └── movement_provider.dart
│   │   │   └── view/
│   │   │       └── movement_screen.dart
│   │   └── settings/
│   │       └── view/
│   │           └── settings_screen.dart   # 시간 가속 모드
│   └── shared/
│       └── widgets/
│           ├── bottom_nav_bar.dart
│           ├── timer_display.dart
│           └── status_badge.dart
└── pubspec.yaml
```

### 데이터 흐름

1. **Static JSON → Provider**: 앱 시작 시 `JsonLoader`가 assets/json을 파싱하여 `StaticDataProvider`에 로드 (1회)
2. **User Action → Hive**: UI 조작 → Riverpod Provider → Repository → Hive 저장
3. **Timer → UI 갱신**: `TimerProvider`가 매 틱마다 퀘스트/이동 Provider 상태를 업데이트 → UI 자동 반영

### 핵심 의존성

```yaml
flutter_riverpod: ^2.5
hive_flutter: ^1.1
hive: ^2.2
freezed: ^2.5
json_serializable: ^6.8
build_runner: ^2.4
```

## 3. 데이터 모델

### Static 모델 (JSON → 읽기 전용)

기존 `Json/` 디렉토리의 데이터를 `assets/json/`으로 복사하여 사용.

- **Difficulty**: Level(1~5), EnemyPower, RewardMultiplier, InjuryRate, DeathRate
- **Job**: ID, Tier(1~5), Name, BaseAtk, BaseDef, BaseHp, Speed — 67개
- **Trait**: ID, Name, EffectType, Value — 4개 (강인함, 노련함, 겁쟁이, 광전사)
- **Region**: Continent, Region(1~199), RegionName, RegionTier, RecommendPower
- **QuestPool**: ID, Name, Type, Difficulty, MinRegionDiff, MaxRegionDiff
- **QuestType**: ID(loot/explore/hunt/escort), Name, BaseReward, BaseDuration, RiskFactor
- **PersonName**: ID, Korean — 217개

### Runtime 모델 (Hive 저장)

#### User

```
gold: int              # 보유 골드
continent: int         # 현재 대륙 (1 고정)
region: int            # 현재 지역 (1~199)
sector: int            # 현재 섹터 (1~10)
isMoving: bool         # 이동 중 여부
moveTargetRegion: int? # 이동 목표 지역
moveTargetSector: int? # 이동 목표 섹터
moveEndTime: DateTime? # 이동 완료 시각
lastFreeRecruit: DateTime  # 마지막 무료 모집 시각
createdAt: DateTime
```

#### Mercenary

```
id: String (uuid)
name: String           # PersonName에서 랜덤
jobId: String          # Job.json 참조
traitId: String        # Trait.json 참조
atk: int               # baseAtk + trait 보정
def: int               # baseDef + trait 보정
hp: int                # baseHp + trait 보정
speed: double          # 이동 속도 계수
status: MercenaryStatus  # normal | tired | injured | dead
tiredEndTime: DateTime?   # 피곤 회복 시각
injuryEndTime: DateTime?  # 부상 회복 시각
isDispatched: bool     # 파견 중 여부
```

#### ActiveQuest

```
id: String (uuid)
questPoolId: String        # QuestPool.json 참조
questTypeId: String        # QuestType.json 참조
difficulty: int            # 퀘스트 난이도
region: int                # 퀘스트 발생 지역
dispatchedMercIds: List<String>  # 파견된 용병 ID 목록
startTime: DateTime        # 파견 시작 시각
endTime: DateTime          # 파견 완료 예정 시각
status: QuestStatus        # pending | in_progress | completed
result: QuestResult?       # great_success | success | failure | critical_failure
```

## 4. 게임 로직

### 성공률 계산

```
party_power = sum(merc.atk) for dispatched mercs
power_ratio = party_power / quest.enemyPower

success_rate =
  50%
  + (power_ratio - 1) × 50%
  + trait_bonus          # 노련함: +10%
  + quest_modifier       # 탐험: +5%, 호위: +3%, 약탈: 0%, 토벌: -5%
  - distance_penalty     # (퀘스트 지역 - 현재 지역) 차이 × 1%
  + random(-5%, +5%)     # 랜덤 분산

clamp(5%, 95%)  # 최소 5%, 최대 95%
```

### 결과 판정

```
roll = random(0~100)

if roll ≤ success_rate × 0.3:
  → 대성공 (보상 2배)
elif roll ≤ success_rate:
  → 성공 (기본 보상)
elif roll ≤ success_rate + (100-success_rate) × 0.7:
  → 실패 (부상 판정)
else:
  → 대실패 (사망률 증가)
```

### 보상 계산

```
reward = baseReward × difficulty.rewardMultiplier × questType 보정
```

### 피해 판정 (실패/대실패 시)

```
for each dispatched merc:
  roll = random(0~1)

  if roll < difficulty.deathRate:
    → 사망 (영구 제거)
    # 겁쟁이 특성: deathRate × 0.7
  elif roll < difficulty.injuryRate:
    → 부상 (회복 시간: difficulty.level × 10분, 가속 적용)
    # 강인함 특성: injuryRate × 0.8
  else:
    → 생존
```

### 피곤 상태

```
퀘스트 완료(성공/대성공) 후 생존한 용병 → "피곤" 상태
- 피곤 상태에서는 모든 능력치 20% 하락
- 회복 시간: 5분 (가속 적용)
- 피곤 상태에서도 파견 가능하나 능력치 감소 상태로 계산
```

### 이동 시간

```
distance = |current_region - target_region| + |current_sector - target_sector|
move_time = distance × 30초 (base) / avg_party_speed
actual_time = time / speed_multiplier  # 가속 모드 적용 (1x, 10x, 100x)
```

### 파견 소요 시간

```
dispatch_time = questType.baseDuration × (1 + (difficulty - 1) × 0.2) (초 단위)
  # 난이도 1: ×1.0, 난이도 5: ×1.8, 난이도 10: ×2.8
actual_time = dispatch_time / speed_multiplier  # 가속 모드 적용
```

### 용병 모집

```
# 무료 모집: 2시간(가속 적용)마다 1회
# 골드 모집: 100골드 (프로토타입 고정가)

# 티어 확률
Tier 1: 45%    Tier 2: 30%    Tier 3: 15%    Tier 4: 8%    Tier 5: 2%

# 모집 프로세스
1. 티어 확률 → 티어 결정
2. 해당 티어 Job 중 랜덤 선택
3. PersonName 중 랜덤 선택
4. Trait 중 랜덤 선택 (1개)
5. Job의 base 스탯 + Trait 보정 → 최종 능력치
```

### 퀘스트 생성

```
1. 현재 Region의 RegionTier 기준
2. QuestPool에서 MinRegionDiff ≤ RegionTier ≤ MaxRegionDiff인 퀘스트 필터링
3. 필터된 풀에서 랜덤 5개 선택
4. 각 퀘스트에 QuestType 랜덤 배정

갱신 타이밍:
- 새로운 지역에 도착 시 자동 갱신
- 파견 화면 진입 시 퀘스트 없으면 생성
- 기존 퀘스트 전부 파견 완료 시 새로 생성
```

### 초기 게임 상태

```
시작 골드: 500
시작 용병: 4명 (Tier 1~2에서 랜덤 생성)
시작 위치: RegionTier 1인 Region 중 랜덤, Sector 랜덤
무료 모집 타이머: 즉시 1회 가능 상태
```

## 5. UI 설계

### 테마

- **배경**: 흰색 (#ffffff / #fafafa)
- **글자**: 진한 검정 (#1a1a1a) 기본, 보조 텍스트 #444~#555
- **색상 최소화**: 액션 버튼 #1a1a1a, 강조/상태에만 색상 사용

### 하단 네비게이션 (5탭)

| 탭 | 기능 |
|---|---|
| 이동 | 지역/섹터 선택, 이동 시작 |
| 파견 | 퀘스트 목록, 인원 선택, 파견 |
| 홈 (중앙) | 야영지 이미지, 진행 상황 |
| 모집 | 무료/골드 모집, 용병 목록 |
| 설정 | 시간 가속 모드 (x1, x10, x100) |

### 홈 화면

- 상단 바: 골드, 현재 좌표 (대륙:지역:섹터)
- 중앙: CustomPaint 도트풍 야영지 (모닥불 + 용병들)
- 하단: 진행 상황 패널 — 파견 중 퀘스트 남은 시간(파란색), 이동 남은 시간(파란색)

### 이동 화면

- 현재 위치 표시 (지역명, RegionTier, 추천 전투력)
- 지역 선택: ◀ ▶ 좌우 버튼으로 탐색
- 섹터 선택: 1~10 전체 표시, 선택된 섹터 검정 배경
- 이동 소요시간 표시 (시간은 파란색)
- 이동 시작 버튼

### 파견 화면

- 퀘스트 5개 리스트 (이름, 타입, 난이도, 보상, 소요시간)
- 선택된 퀘스트에 대해 파견 인원 선택 (체크 방식, 제한 없음)
- 부상/파견중 용병은 비활성 표시
- 예상 성공률과 전투력 비율 표시
- 파견 출발 버튼
- 이동 중에는 파견 불가 안내

### 모집 화면

- 무료 모집 버튼 (가능/타이머 표시)
- 골드 모집 버튼 (100G)
- 내 용병단 리스트: 이름, 직업(티어 색상), 티어 배지, 상태, 능력치, 특성

### 퀘스트 결과 다이얼로그

- 퀘스트 이름, 타입, 난이도 표시
- 결과 배너: 대성공(파랑), 성공(초록), 실패(주황), 대실패(빨강)
- 보상 획득량
- 각 용병 상태 (무사 귀환 / 부상 / 사망)

### 색상 규칙

#### 티어 & 직업 (동일 색상)

| 티어 | 색상 | 배경 |
|---|---|---|
| T1 | #666666 (회색) | #f0f0f0 |
| T2 | #2e7d32 (초록) | #e8f5e9 |
| T3 | #1565c0 (파랑) | #e3f2fd |
| T4 | #6a1b9a (보라) | #f3e5f5 |
| T5 | #c62828 (빨강) | #ffebee |

#### 특성 (개별 색상)

| 특성 | 색상 |
|---|---|
| 강인함 | #2e7d32 (초록) |
| 노련함 | #1565c0 (파랑) |
| 겁쟁이 | #6a1b9a (보라) |
| 광전사 | #c62828 (빨강) |

#### 퀘스트 결과

| 결과 | 색상 | 배경 |
|---|---|---|
| 대성공 | #1565c0 (파랑) | #e3f2fd |
| 성공 | #2e7d32 (초록) | #e8f5e9 |
| 실패 | #e65100 (주황) | #fff3e0 |
| 대실패 | #c62828 (빨강) | #ffebee |

## 6. 시간 시스템

- 실시간 타이머 기본
- 설정 탭에서 가속 모드 전환 (x1, x10, x100)
- 가속은 이동 시간, 파견 시간, 무료 모집 쿨타임 모두에 적용
- `TimerProvider`가 주기적(1초)으로 틱을 발생시키고, 각 feature의 Provider가 시간 기반 상태를 업데이트

## 7. 핵심 게임 루프

1. **게임 시작** — RegionTier 1 지역 랜덤 배치, 용병 4명 + 500골드
2. **홈 확인** — 야영지에서 진행 상황과 용병 상태 확인
3. **이동 (선택)** — 더 좋은 퀘스트를 위해 다른 지역으로 이동
4. **퀘스트 확인 & 파견** — 5개 퀘스트 중 선택, 용병 배치, 파견
5. **시간 대기** — 파견 소요시간 대기, 그 사이 추가 파견 가능
6. **결과 확인** — 대성공/성공/실패/대실패 판정, 보상/피해 처리
7. **용병 모집 & 반복** — 골드/무료로 신규 용병 모집, 루프 반복

## 8. MVP 범위

### 포함

- 좌표 이동 (Region + Sector)
- 퀘스트 생성 (RegionTier 기반 필터링)
- 파견 + 시간 대기
- 결과 계산 (성공률, 피해 판정)
- 용병 상태 (정상/피곤/부상/사망)
- 용병 모집 (무료/골드)
- 시간 가속 모드 (개발/테스트용)
- CustomPaint 도트풍 홈 화면

### 제외

- PvP (습격)
- 장비 시스템
- 스킬 시스템
- 동맹
- 인카운터 이벤트
- 성장 시스템
- 다국어
