# 연계 퀘스트 시스템 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260423_chain_quests.md`
> 주 밸런스: `Docs/balance-design/[balance]20260424_chain_quest_rewards.md` (페이즈 2-1)
> 선행 spec: `Docs/spec/M3/[spec]20260424_template-engine.md` (페이즈 4-1, PASS)
> 작성일: 2026-04-24
> 범위: M3 페이즈 4-2

## 1. 개요

M3의 7체인 24단계 연계 퀘스트 시스템을 Flutter 앱에 구현한다. 지역 조사(`region_discoveries.hidden_quest`) 트리거로 체인이 발동하고, 단계별 퀘스트를 순차 수행하며, 단계 간에는 **실제 시간 기반 delay**가 있다. 최종 단계 완료 시 **확정 장비 아이템**과 **완주 명성 보너스**를 지급한다. 체인 주인공은 단계 1 파티 최고 기여 용병으로 고정되고, 사망·방출 시 폴백된다. balance 2-1의 런타임 로직 4건(death×0.5 / 휴면 14일 / 인벤 차단 / 완주 명성)을 반영한다.

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 체인 발동 트리거**
  - 상세: 지역 조사 완료 시 `RegionState.knowledge`가 `region_discoveries.knowledge_threshold`에 도달하고 `discovery_type='hidden_quest'`이며 `discovery_data.chain_id`가 존재하면 체인 발동
  - 조건:
    - 이미 완주된 체인(`UserData.completedChains` 포함) → 발동 안 함
    - 이미 진행 중 체인(`chainQuestProgress` 박스에 `status=active` 있음) → 발동 안 함
    - 휴면 체인(`status=dormant`) → 자동 재개(5-4 참조)
  - 동작: `ChainQuestProgress` Hive 객체 생성 + `InvestigationCompletionService`에서 발동 알림 팝업 띄움

- **[FR-2] 주인공 용병 선정 고정**
  - 상세: 체인 발동 시점이 아닌 **단계 1 완료 시** `ChainQuestProgress.protagonistMercId`에 파티 내 최고 기여 용병 고정
  - 기여 계산: `QuestCalculator.calculatePartyPower` 로직 재사용 (quest_type별 stat weight 반영)
  - 단계 1 재도전 시: 주인공 선정은 **첫 성공 시에만** 수행 (대성공·성공 모두 첫 완료로 인정). 실패 재도전 시에는 선정 안 함

- **[FR-3] 체인 단계 퀘스트 주입**
  - 상세: 활성 체인의 현재 단계의 `region_id`와 `target_region_id`에 맞춰 파견 화면에 **체인 단계 카드** 주입
  - `region_id`는 체인 시작 리전. `target_region_id`는 단계 수행 리전. 동일하면 "현재 리전" 단계, 다르면 "이동 필요" 단계
  - 유저가 `UserData.region == target_region_id`가 아닐 때: 카드 비활성 + "📍 {region_name}으로 이동하여 수행" 오버레이
  - `currentStepAvailableAt > now`일 때: 카드 잠금 + "💭 {남은 시간} 후 다음 단서가 드러납니다"
  - 파견 화면 **최상단 슬롯 고정** (페이즈 1-6 공존 정책 5계층 정렬 최상위)

- **[FR-4] 체인 단계 완료 처리**
  - 상세: `ChainQuestService.onStepCompleted(chainId, step, resultType)` 호출 시
    - `resultType`이 `success` 또는 `greatSuccess`면 단계 진행
      - 단계 1 첫 성공 → 주인공 선정 (FR-2)
      - 마지막 단계 아님 → `currentStep += 1`, `currentStepAvailableAt = now + next_step_delay_seconds`
      - 마지막 단계 → `onChainCompleted` 호출 (FR-7)
    - 실패·대실패 → `stepFailureCount += 1`, 단계 재도전 허용 (delay 초기화 없음)
  - 활동 로그: 성공 시 `ActivityLogType.chainProgressed` 기록 (HiveField 19)

- **[FR-5] 체인 단계 death_rate × 0.5 감산**
  - 상세: `ActiveQuest.isChainStep == true`인 퀘스트의 완료 데미지 계산 시 `difficulty.deathRate × 0.5` 적용 (injuryRate는 그대로)
  - 구현: `QuestCompletionService.calculate()`에 `isChainStep: bool` 파라미터 추가. `true`면 내부에서 `effectiveDeathRate = difficulty.deathRate × 0.5`
  - balance 2-1 §5-3 적용
  - UI: 체인 단계 카드에 "🛡️ 주인공의 운명이 파티를 보호합니다" 배지 표시 (페이즈 1-6 공존 정책 Q-B 반영)

- **[FR-6] 인벤토리 사전 차단 (최종 단계 진입)**
  - 상세: `ChainQuestService.canAdvanceToFinal(chainId) → bool` — 최종 단계로 진입하기 **전**에 호출
    - 최종 단계의 `reward_items` JSONB 파싱 → 아이템 ID 1개
    - 용병단 장비(`guild_equipment`)면 `UserData.artifactItemIds` 여유 체크 (`.length < 2` + `bannerItemId == null` 둘 중 하나)
    - 개인 장비(`personal_equipment`)면 용병 전체의 장비 슬롯 중 여유 1칸 확인 (**FR-6-a 참조**)
  - 호출 시점: 체인 단계 N-1 완료 후 N(최종) 단계 노출 **직전**
  - 차단 시 UI: `showDialog` 모달 "최종 보상을 받으려면 인벤토리에 여유가 필요합니다" + 확인 버튼. 최종 단계 노출 보류
  - 해결 시 자동 재검증 (유저가 인벤 정리 후 파견 화면 진입 시 재호출)
  - balance 2-1 §5-4 적용

- **[FR-6-a] 개인 장비 인벤 여유 판정**
  - 각 용병의 장비 슬롯(weapon/armor/helmet/boots/accessory)이 기존 인프라 기반일 때, 해당 슬롯이 비어있는 용병이 1명 이상 존재하면 여유 있음
  - 기존 M2a 인벤 시스템(`features/inventory`)의 API 확인 필요 (Q-A 오픈)
  - 대안: 최종 보상 아이템의 category가 `personal_equipment`면 "소지 가능" 판정을 생략하고 무조건 통과 (**MVP 권장**) — 이유: 개인 장비 슬롯 관리는 용병별 상이해서 차단 UX가 복잡. 용병단 장비만 차단

- **[FR-7] 체인 완주 보너스 지급**
  - 상세: `ChainQuestService.onChainCompleted(chainId)` 호출 시
    - 최종 단계의 `chain_quests.final_reputation_bonus` 값(DB 저장됨)을 `UserData.reputation`에 가산
    - `UserData.completedChains` Set에 `chainId` 추가
    - `ChainQuestProgress.status = completed`, `completedAt = now`
    - 활동 로그: `ActivityLogType.chainCompleted` 기록 (HiveField 20)
  - 랭크 상승 감지: `UserDataNotifier.addReputation()` 경유 시 기존 `reputationRankUpProvider` 자동 트리거 (추가 구현 불필요)

- **[FR-8] 주인공 폴백**
  - 상세: `ChainQuestService.getProtagonist(chainId)` 호출 시
    - `protagonistMercId` 용병이 존재(`Hive mercenaries` 박스)하고 `status != dead/released`면 그대로 반환
    - 아니면 "다음 단계 파티 최고 기여자"로 자동 갱신 + 활동 로그에 "이야기의 주인공이 바뀌었다" 기록
    - 파티가 아직 구성 안 된 경우: 로스터에서 최고 레벨 용병 fallback
  - TemplateEngine 호출 시 `context.merc = this.getProtagonist()` 결과 사용

- **[FR-9] 휴면 전환 / 자동 재개**
  - 상세: `ChainQuestService.checkDormant()` — `gameTickProvider`에서 1시간 주기로 호출 (60 tick × 60 = 3600 tick)
    - `currentStepAvailableAt` 이후 **14일** 경과 + `status == active` → `status = dormant`
    - 활동 로그 기록 없음 (조용한 전환)
  - 자동 재개: 파견 화면에서 체인 단계 카드 탭 시 `status = dormant`이면 자동 `status = active`로 복원
  - balance 2-1 §5-5 적용

- **[FR-10] `ActiveQuest.isChainStep` 플래그 추가**
  - 상세: `ActiveQuest` Hive 모델에 `HiveField(21) bool? isChainStep`, `HiveField(22) String? chainId`, `HiveField(23) int? chainStep` 추가
  - `isChainStep ?? false` getter 제공 (null-safe)
  - `QuestGenerator`는 체인 단계 주입 시 이 필드들 채움

- **[FR-11] 체인 단계 서사 렌더 (TemplateEngine)**
  - 상세: 파견 화면 체인 단계 카드·완료 팝업에서 `chain_quests.description` 렌더
  - `TemplateContext`:
    - `merc = getProtagonist(chainId)` (FR-8)
    - `quest = null` (아직 활성화 안 된 체인 단계는 quest 없음) 또는 `quest = currentActiveQuest` (활성화된 경우)
    - `region = currentRegion`
    - `evaluationScope: mercenary`
  - `[if joined_faction:<id>]` 조건 분기 → `FactionStateRepository.isJoined(id)` 기반 평가

- **[FR-12] 체인 완주 후 재발동 방지**
  - 상세: 동일 `chain_id`가 복수 리전에 배치되어 있어도 `UserData.completedChains`에 있으면 재발동 안 함
  - `InvestigationCompletionService`에서 `chain_id` 체크 로직 추가

### 2.2 데이터 요구사항

#### 2.2.1 신규 Hive 모델

- **`ChainQuestProgress`** (typeId: **11**)
  ```dart
  @HiveType(typeId: 11)
  class ChainQuestProgress extends HiveObject {
    @HiveField(0) String chainId;
    @HiveField(1) int currentStep;
    @HiveField(2) ChainQuestStatus status;  // active/completed/dormant
    @HiveField(3) DateTime startedAt;
    @HiveField(4) DateTime? completedAt;
    @HiveField(5) String? protagonistMercId;  // 단계 1 완료 후 고정
    @HiveField(6) DateTime? currentStepAvailableAt;  // 단계 간 delay 종료 시각
    @HiveField(7) int stepFailureCount;  // UI 힌트용 (재도전 횟수)
    @HiveField(8) DateTime? lastActivityAt;  // 휴면 판정용 (currentStepAvailableAt 경과 후 수행 시각)
  }
  ```

- **`ChainQuestStatus`** enum (typeId: **12**)
  ```dart
  @HiveType(typeId: 12)
  enum ChainQuestStatus {
    @HiveField(0) active,
    @HiveField(1) completed,
    @HiveField(2) dormant,
  }
  ```

#### 2.2.2 신규 Hive 박스

- **`chainQuestProgress`** — key: `chainId` (String), value: `ChainQuestProgress`
- `HiveInitializer`에 등록 + `Hive.registerAdapter(ChainQuestProgressAdapter())` + `Hive.registerAdapter(ChainQuestStatusAdapter())`
- 앱 초기화 시 `Hive.openBox<ChainQuestProgress>('chainQuestProgress')`

#### 2.2.3 기존 Hive 모델 확장

- **`UserData`** (typeId: 5)
  - `@HiveField(20) Set<String> completedChains` 추가 (기본값 `<String>{}`)
  - 기존 HiveField 0~19 유지. Hive 필드 번호는 append-only이므로 안전

- **`ActiveQuest`** (typeId: 4)
  - `@HiveField(21) bool? isChainStep` 추가
  - `@HiveField(22) String? chainId` 추가
  - `@HiveField(23) int? chainStep` 추가
  - getter: `bool get isChainQuest => isChainStep ?? false;`

- **`ActivityLogType`** enum (typeId: 6) — **기존 HiveField 0~17 점유**(0~14 + M2a essence 15~17). M3 신규는 **18부터**
  - `@HiveField(18) regionTransform` — 페이즈 4-3에서 추가 (선행 충돌 방지용 예약)
  - `@HiveField(19) chainProgressed` 추가
  - `@HiveField(20) chainCompleted` 추가

#### 2.2.4 신규 Freezed 정적 모델

- **`ChainQuestData`** (`lib/core/models/chain_quest_data.dart`)
  ```dart
  @freezed
  class ChainQuestData with _$ChainQuestData {
    const factory ChainQuestData({
      required String id,
      @JsonKey(name: 'chain_id') required String chainId,
      @JsonKey(name: 'chain_name') required String chainName,
      required int step,
      @JsonKey(name: 'total_steps') required int totalSteps,
      @JsonKey(name: 'region_id') int? regionId,
      @JsonKey(name: 'target_region_id') int? targetRegionId,
      required String name,
      required String description,
      @JsonKey(name: 'quest_type_id') required String questTypeId,
      required int difficulty,
      @JsonKey(name: 'combat_power') required int combatPower,
      @JsonKey(name: 'reward_gold') required int rewardGold,
      @Default(0) @JsonKey(name: 'reward_xp') int rewardXp,
      @Default({}) @JsonKey(name: 'reward_items') Map<String, int> rewardItems,
      @Default(false) @JsonKey(name: 'final_reward') bool finalReward,
      @JsonKey(name: 'final_reputation_bonus') int? finalReputationBonus,
      @JsonKey(name: 'duration_seconds') required int durationSeconds,
      @Default(0) @JsonKey(name: 'next_step_delay_seconds') int nextStepDelaySeconds,
      @JsonKey(name: 'faction_tag_id') String? factionTagId,
    }) = _ChainQuestData;
    factory ChainQuestData.fromJson(Map<String, dynamic> json) => _$ChainQuestDataFromJson(json);
  }
  ```

#### 2.2.5 Supabase 동기화

- `SyncService`에 `chain_quests` 테이블 다운로드 추가
- `data_versions` 테이블 엔트리 이미 존재 (배치 B에서 추가)
- `StaticGameData`에 `List<ChainQuestData> chainQuests` 필드 추가
- `DataLoader`가 로컬 JSON 캐시에서 `ChainQuestData` 리스트 로드

### 2.3 UI 요구사항

#### 2.3.1 파견 화면 체인 단계 카드

- **화면 진입 조건**: `DispatchDetailPage` 렌더 시 `chainQuestProgress` 박스에서 활성 체인 조회 → 체인 단계 카드 위젯 주입
- **위젯 계층**: `ListView > ChainStepCard (최상단) > QuestList (나머지 퀘스트 카드)`
- **상태 변수**:
  - `chainQuestProgressProvider`: `StreamProvider<List<ChainQuestProgress>>` — Hive 박스 변경 감지
  - `activeChainProvider`: `Provider<ChainQuestProgress?>` — 현재 표시할 체인 1개 (다중 체인 동시 진행 시 가장 긴급한 것 1개)
- **화면 전환**: Navigator.push 금지 — 카드 탭 시 기존 `DispatchDetailPage` 상태로 퀘스트 선택 동일 흐름
- **카드 시각 (페이즈 1-6 공존 정책 반영)**:
  - 좌측 사이드바: 체인 티어별 보라/금 그라데이션 (T2: 녹색 / T3: 파랑 / T4: 보라 / T5: 금색)
  - 상단 배지: "🔗 연계 {N}/{M}"
  - 체인 이름 서브텍스트: "{chain_name} · {N}/{M}단계"
  - death×0.5 배지: "🛡️ 주인공의 운명" (FR-5 Q-B)
  - 이름 아래 주인공 이름: "주인공: {protagonist.name}"
- **상태별 오버레이**:
  - 이동 필요 (`user.region != target_region_id`): "📍 {region.name}으로 이동 필요" 반투명 오버레이
  - 대기 중 (`currentStepAvailableAt > now`): "💭 {남은 시간 포맷} 후 다음 단서가 드러납니다"
  - 인벤 부족 (최종 단계, FR-6): "📦 인벤토리 여유 필요" 경고 배지

#### 2.3.2 체인 완주 팝업

- **진입 조건**: `onChainCompleted` 완료 시 `chainCompletedProvider` StateProvider publish → `app.dart`에서 `ref.listen`으로 감지
- **위젯**: `showDialog` + `ChainCompletedDialog` (신규)
- **표시 내용**:
  - 최종 단계 서사 (`chain_quests.description` 렌더)
  - 획득 아이템 (reward_items JSONB 파싱 → 아이템 이미지/이름)
  - 획득 명성 `+{final_reputation_bonus}`
  - 확인 버튼 → dialog dismiss + `chainCompletedProvider.state = null` 리셋
- **랭크업 감지**: 명성 지급 시 기존 `reputationRankUpProvider` 자동 트리거되므로 별도 처리 불필요 (단, 페이즈 1-6 Global Dialog Queue 경유 시 순서 조정 필요 — 페이즈 4-6 spec 대상)

#### 2.3.3 주인공 변경 활동 로그

- 주인공 폴백 발생 시 `ActivityLog` 추가 — `type = chainProgressed`, 메시지 "{old_name}의 이야기가 {new_name}에게 이어졌다"

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `band_of_mercenaries/lib/core/models/user_data.dart` | `completedChains: Set<String>` 필드 추가 (HiveField 20) | FR-12 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `isChainStep`/`chainId`/`chainStep` 필드 추가 (HiveField 21~23) + `isChainQuest` getter | FR-10 |
| `band_of_mercenaries/lib/core/models/activity_log_model.dart` | `ActivityLogType.chainProgressed` / `chainCompleted` 값 추가 (HiveField 19/20) | FR-4, FR-7 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | `calculate()` 시그니처에 `isChainStep: bool = false` 추가. `deathRate = difficulty.deathRate × (isChainStep ? 0.5 : 1.0)` 적용 | FR-5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | 체인 단계 퀘스트 생성 분기 추가 (활성 체인의 현재 단계 → ActiveQuest 생성 시 `isChainStep/chainId/chainStep` 채움) | FR-3, FR-10 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `chain_quests` 테이블 동기화 추가 | §2.2.5 |
| `band_of_mercenaries/lib/core/data/data_loader.dart` | `chainQuests` 로드 함수 추가 | §2.2.5 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `StaticGameData.chainQuests` 필드 추가 | §2.2.5 |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | `ChainQuestProgress`/`ChainQuestStatus` 어댑터 등록 + `chainQuestProgress` 박스 open | §2.2.2 |
| `band_of_mercenaries/lib/core/providers/timer_provider.dart` (gameTickProvider) | `ChainQuestService.checkDormant()` 1시간 주기 호출 + 단계 간 delay 도달 체크 | FR-9, FR-3 |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart` | 조사 완료 시 `discovery_type='hidden_quest' + chain_id` 체크 → `ChainQuestService.startChain()` 호출 | FR-1 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 체인 단계 카드 위젯 최상단 렌더 + 이동/대기/인벤 오버레이 | §2.3.1 |
| `band_of_mercenaries/lib/app.dart` | `chainCompletedProvider` `ref.listen` 추가 → `ChainCompletedDialog` 표시 | §2.3.2 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/lib/core/models/chain_quest_data.dart` | Freezed 정적 모델 (Supabase fromJson) |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_progress.dart` | Hive 모델 `ChainQuestProgress` + `ChainQuestStatus` enum |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | `startChain` / `onStepCompleted` / `onChainCompleted` / `getProtagonist` / `checkDormant` / `canAdvanceToFinal` |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_provider.dart` | `chainQuestProgressProvider` / `activeChainProvider` / `chainCompletedProvider` |
| `band_of_mercenaries/lib/features/chain_quest/data/chain_quest_repository.dart` | Hive `chainQuestProgress` 박스 CRUD |
| `band_of_mercenaries/lib/features/chain_quest/view/chain_step_card.dart` | 파견 화면 상단 고정 카드 위젯 |
| `band_of_mercenaries/lib/features/chain_quest/view/chain_completed_dialog.dart` | 완주 팝업 |
| `test/features/chain_quest/domain/chain_quest_service_test.dart` | 서비스 단위 테스트 (주인공 선정/폴백/휴면/인벤 차단 시나리오) |
| `test/features/chain_quest/domain/chain_quest_completion_death_rate_test.dart` | FR-5 death×0.5 검증 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `lib/core/models/chain_quest_data.freezed.dart` + `.g.dart` | 신규 Freezed 모델 |
| `lib/core/models/user_data.g.dart` | `completedChains` 필드 추가 |
| `lib/features/quest/domain/quest_model.g.dart` | `isChainStep`/`chainId`/`chainStep` 추가 |
| `lib/core/models/activity_log_model.g.dart` | enum 값 추가 |
| `lib/features/chain_quest/domain/chain_quest_progress.g.dart` | `ChainQuestProgress`/`ChainQuestStatus` Hive 어댑터 |

**build_runner 실행**: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

### 3.4 관련 시스템

- **TemplateEngine (페이즈 4-1)**: `ChainQuestService`가 `templateEngineProvider.render()` 호출하여 `chain_quests.description` 렌더 (주인공 기준 mercenary scope)
- **InvestigationService / InvestigationNotifier**: 조사 완료 시 체인 발동 분기 추가
- **QuestGenerator**: 파견 화면 퀘스트 목록에 체인 단계 카드 **주입은 하지 않음** (별도 고정 슬롯). 체인 단계를 직접 ActiveQuest로 만드는 것은 **카드 탭 시** 수행
- **QuestCompletionService**: death_rate 감산 (FR-5)
- **FactionJoinService / FactionStateRepository**: TemplateEngine 조건식 `joined_faction` 평가 시 조회
- **ReputationService / UserDataNotifier**: 완주 명성 보너스 지급
- **Supabase `chain_quests`**: 배치 B 24행 삽입 완료. SyncService가 로컬 캐시 동기화
- **페이즈 4-6 spec (예정)**: 파견 화면 공존 정렬(5계층) 통합 구현. 본 spec은 체인 단계 카드의 **최상단 고정 위치 계약**만 정의

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Hive 모델 + 박스**: `lib/core/models/user_data.dart:5-102` — `@HiveType(typeId: N) class X extends HiveObject`
- **Freezed 정적 모델 + Supabase fromJson**: `lib/core/models/quest_pool.dart`, `lib/core/models/elite_monster_data.dart` — `@freezed` + `@JsonKey(name: 'snake_case')`
- **StateProvider publish 패턴**: `lib/core/providers/reputation_rank_up_provider.dart` (`RankUpEvent` publish → `app.dart` ref.listen)
- **gameTickProvider Stream 기반 체크**: 기존 `lib/core/providers/timer_provider.dart` (퀘스트 완료·이동 도착·건설 완료 체크 패턴 확장)
- **DispatchDetailPage 상태 기반 렌더링**: 기존 `lib/features/quest/view/dispatch_detail_page.dart` (CLAUDE.md 제약 준수 — Navigator.push 금지)

### 4.2 주의사항

- **Hive typeId 충돌 방지**: 현재 사용 중 0~10(quest/mercenary/user/activity/region/faction/clue). **11, 12 신규 할당**
- **HiveField 번호 append-only**: 기존 필드 번호 재사용 금지. `UserData` 20, `ActiveQuest` 21~23, `ActivityLogType` 16~17 엄수
- **build_runner `--delete-conflicting-outputs`**: `.g.dart` 충돌 시 필수
- **`completedChains`는 Set<String>** — Hive는 Set 직렬화 지원. `List<String>`으로도 가능하나 Set이 중복 방지 명시적
- **`ActiveQuest.isChainStep` 런타임 필드**: QuestGenerator가 채움. Supabase 저장 필드 아님 (런타임 전용)
- **주인공 선정 시점**: 체인 발동 시가 아니라 **단계 1 완료 시**. 이유: 파티 구성 전 주인공 선정 불가 (기획 §7)
- **TemplateEngine `context.quest`**: 체인 단계 카드 렌더 시 `null` 허용. `{quest.*}` 참조 시 `[?quest.*]` 출력. 완료 팝업 시에는 `currentActiveQuest` 주입
- **gameTickProvider 성능**: 1시간 주기 `checkDormant` 호출은 1초 tick 중 3600번째마다 실행 (modulo). 전 체인 순회 — 체인 수 7개이므로 부담 없음
- **CLAUDE.md 제약**: Navigator.push 대신 상태 기반 렌더링. 웹 `_MobileFrame` ConstrainedBox(maxWidth: 430) 준수

### 4.3 엣지 케이스

- **주인공 용병 파견 중**: 주인공 용병이 다른 퀘스트로 파견 중일 때 체인 단계 수행 불가능. 파티 선택 화면에서 제외 또는 체인 카드 비활성 — MVP 단순화로 **파견 중이어도 카드 표시**, 유저가 다른 용병으로 파티 구성 허용. TemplateEngine 렌더는 `getProtagonist()` 결과로 계속 표시 (파견 중 용병 이름 그대로 나옴)
- **다중 체인 동시 발동**: 여러 체인이 동시에 `active`일 수 있음. `activeChainProvider`는 가장 긴급한 1개만 카드로 노출 (우선순위: `currentStepAvailableAt`가 가장 빠른 것). 나머지는 페이즈 1-6 공존 정책에서 "일반 목록 하단 노출" 검토 (본 spec MVP는 1개 표시)
- **인벤 차단 중 체인 포기**: 기획상 포기 불가. 유저가 인벤 정리하지 않으면 영원히 대기 상태. 휴면 전환(14일 미수행) 규칙이 자연 안전장치
- **완주 후 동일 리전 재조사**: `completedChains` 체크로 재발동 안 함 (FR-12)
- **체인 7 엔드게임 15시간 delay 중 앱 종료**: `currentStepAvailableAt`은 실제 시간 기준이므로 앱 재시작 시 정상 도달 판정
- **`final_reputation_bonus` 값 null**: DB 저장 체인 24행 모두 최종 단계에 값 존재 확인됨. 방어적으로 `?? 0`
- **랭크업 팝업과 체인 완주 팝업 동시**: 페이즈 4-6 공존 정책(Global Dialog Queue)에서 순서 조정. 본 spec은 둘 다 기존 channel을 통해 publish

### 4.4 구현 힌트

- **진입점**:
  - 발동: `InvestigationNotifier.onCompleted()` → `ChainQuestService.tryStartChain(discoveryId, chainId)`
  - 단계 완료: `QuestCompletionService.onCompleted()` → quest.isChainQuest이면 `ChainQuestService.onStepCompleted(quest.chainId, quest.chainStep, resultType)`
  - 휴면 체크: `gameTickProvider` 1시간 주기
- **데이터 흐름**:
  ```
  [조사 완료] → InvestigationNotifier → ChainQuestService.tryStartChain()
  → ChainQuestProgress 생성 → DispatchDetailPage (chain_step_card 노출)
  → 유저 파견 → ActiveQuest(isChainStep=true) → QuestCompletionService (death×0.5)
  → ChainQuestService.onStepCompleted() → 다음 단계 대기 or 완주
  → 완주 시: onChainCompleted() → 명성+보너스 + completedChains 추가 + chainCompletedProvider publish
  → app.dart ref.listen → ChainCompletedDialog 표시
  ```
- **참조 구현**:
  - `ChainQuestProgress` Hive 모델: `lib/core/models/user_data.dart` 스타일
  - `ChainQuestService` 패턴: `lib/features/facility/domain/construction_service.dart` (서비스 + 상태 관리)
  - StateProvider publish: `lib/core/providers/reputation_rank_up_provider.dart:8-15`
  - 카드 위젯: `lib/features/quest/view/quest_card.dart` (있다면) 또는 `dispatch_detail_page.dart` 내부
- **확장 지점**: `ChainQuestService`는 향후 세력 체인·엔드게임 체인 추가 시 확장 가능. `activeChainProvider` 복수 노출은 M4+ 기획 반영

## 5. 기획 확인 사항

- [Q-A] **FR-6-a 개인 장비 인벤 슬롯 판정**: M2a `features/inventory` 모듈의 개인 장비 슬롯 관리 API가 존재하는지 확인 필요. 미존재 시 MVP는 **용병단 장비만 차단, 개인 장비 무조건 통과**로 진행 → **구현 단계에서 inventory 모듈 확인 후 결정**
- [Q-B] **`death×0.5` UI 배지 문구**: 기획서에는 없으나 balance 2-1 Q-B에서 제안. "🛡️ 주인공의 운명이 파티를 보호합니다" 사용. → 확정
- [Q-C] **다중 체인 동시 노출 UI**: MVP 1개 표시. M4+에서 복수 표시 검토 → 확정
- [Q-D] **주인공이 파견 중인 용병일 때 체인 단계 수행 허용 여부**: MVP 허용(다른 용병으로 파티 구성 가능) → 확정
- [Q-E] **체인 단계 퀘스트가 `quest_pools`와 섞여 보이는가**: 아니다. 체인 단계 카드는 `dispatch_detail_page`의 **독립 슬롯**으로 최상단 고정. `QuestGenerator`가 `quest_pools`에서 뽑는 퀘스트 5개는 그대로 아래 나열 → 확정
- [Q-F] **완주 명성 `final_reputation_bonus` DB 저장값 vs 런타임 계산**: balance 2-1 공식이 DB에 이미 저장됨(배치 B). 런타임 재계산 불필요. DB 값 그대로 사용 → 확정
- [Q-G] **체인 단계 `ActiveQuest`의 `questPoolId` 필드**: chain_quests 테이블이므로 `'chain_{chain_id}_step{N}'` 형태로 생성(실제 chain_quests.id 값 사용). QuestGenerator에서 처리. `questPoolId`가 실제 `quest_pools.id`가 아닌 예외 케이스 → **`questPoolId`는 체인 퀘스트 시 `chain_quests.id`로 대체 사용**. `isChainStep` 플래그로 구분

## 6. 다음 단계

- **구현**: 페이즈 4 전체 spec 작성 완료 후 `/implement-agent @Docs/spec/M3/[spec]20260424_chain-quest-system.md`
- **페이즈 4-3 선행 의존**: `ActivityLogType.regionTransform` (HiveField 15) 배정은 페이즈 4-3 spec에서 확정 → 본 spec은 16/17만 점유
- **페이즈 4-6 공존 정책 spec**: 체인 단계 카드 5계층 정렬 최상위 + Global Dialog Queue에서 ChainCompletedDialog 우선순위 결정
