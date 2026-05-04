# 명세서: M4 마을 신뢰도 시스템 + 고정 사건 진행 상태 + 페이즈 4 #3 stub 해제

> 작성일: 2026-05-03
> 마일스톤: M4 페이즈 4 #5 (M4 페이즈 4 마지막 산출물)
> 선행 명세:
> - `Docs/spec/M4/[spec]20260503_m4-region-migration.md` (페이즈 4 #1)
> - `Docs/spec/M4/[spec]20260503_m4-region-sectors.md` (페이즈 4 #2)
> - `Docs/spec/M4/[spec]20260503_m4-fixed-quest-system.md` (페이즈 4 #3) — 본 명세가 stub 해제
> 기획 입력:
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` (페이즈 1 #4 — 4단계 컨셉, 저장소 결정 4.1·4.2절, ActivityLog 4.3절, ActiveQuest 영향 4.4절)
> - `Docs/balance-design/[balance]20260503_settlement-trust-tuning.md` (페이즈 2 #1 — 임계값 30/80/200, step 보상 10·15·20·25·30·100, 일반 의뢰 보상 2/3/5점, 단계 진입 일회성 보상)
> - `Docs/spec/M4/[spec]20260503_m4-fixed-quest-system_plan.md` (페이즈 4 #3 후속 권고 8건)
> 후속:
> - 페이즈 4 SQL 4종 일괄 적용 (옵션 B 종결): 페이즈 4 #1·#2·#3 + (본 명세는 SQL 변경 없음, data_versions 갱신만 필요 시 추가)

---

## 1. 개요

페이즈 4 #3에서 stub 상태로 정의된 마을 신뢰도 시스템을 본격 구현하여 거점 사건 라인(`settlement_3_pyegwang_reopen` 6단계)을 활성화한다.

세 영역을 한 번에 다룬다.

1. **저장소 신규 구축**: `RegionState` HiveField 4·5 (`settlementTrust`/`settlementTrustLevel`) 추가, `RegionStateRepository`에 누적·조회·디버그용 메서드 3종 추가, `settlementTrustProvider`/`settlementTrustLevelUpProvider` 신규 채널.
2. **로직 통합**: `ChainQuestService`에 거점 사건 분기 추가 (`tryActivateSettlement` / `checkDormant` skip), `QuestCalculator`·`ExperienceService` is_fixed override 분기, `QuestCompletionService` 호출부에서 settlement_ step 완료 후 신뢰도 누적 + 단계 승급 + 풀 갱신 트리거. `ActivityLogType` 3종 추가, `dialogQueue`에 단계 승급 다이얼로그 통합.
3. **stub 해제**: `QuestListNotifier._getCurrentTrustLevel()`을 `RegionStateRepository.getSettlementTrust(regionId).level`로 교체. 페이즈 4 #3 후속 권고 #1~#3 동시 처리.

본 명세 적용으로 페이즈 4 #3에서 INSERT만 되고 노출되지 않던 16행 quest_pools(`qp_pyegwang_step1~6` + `dustvile_chore_03` 채집 의뢰)가 활성화된다.

---

## 2. 요구사항

### 2.1 기능 요구사항

| ID | 요구사항 | 출처 |
|----|---------|------|
| **저장소** | | |
| REQ-01 | `RegionState`에 `settlementTrust`(HiveField 4, int? null=0) + `settlementTrustLevel`(HiveField 5, int? null=1) 추가 + `currentTrust` / `currentTrustLevel` getter 추가 | 페이즈 1 #4 4.1절 |
| REQ-02 | `RegionStateRepository.addSettlementTrust(int regionId, int amount, String source)` 추가 — 누적 + 단계 승급 검증 + 단계 진입 일회성 보상 지급 + level-up 시 `settlementTrustLevelUpProvider` publish + `QuestListNotifier.refreshAvailableQuests()` 호출 | 페이즈 2 #1 영향표 |
| REQ-03 | `RegionStateRepository.getSettlementTrust(int regionId) → ({int trust, int level})` 추가 (Dart record 반환) | 페이즈 1 #4 4.1절 |
| REQ-04 | `RegionStateRepository.setSettlementTrust(int regionId, int trust, int level)` 추가 (운영·디버그 전용, 일회성 보상 미지급) | 페이즈 1 #4 4.1절 |
| REQ-05 | `settlementTrustProvider(int regionId)` Provider — 현재 신뢰도 단계(int) 동기 제공. `regionStateRepositoryProvider` watch | 페이즈 1 #4 4.1절 |
| REQ-06 | `settlementTrustLevelUpProvider` StateProvider<TrustLevelUpEvent?> 신규 — `RankUpEvent` 패턴 모방 | 페이즈 1 #4 4.1절 |
| **ChainQuestService** | | |
| REQ-07 | `ChainQuestService.tryActivateSettlement(int regionId, String eventName)` 추가 — chainId = `settlement_<regionId>_<eventName>` 생성. 신뢰도 1단계 도달(첫 호출)·재진입 시 자동 호출 | 페이즈 1 #4 4.2절 |
| REQ-08 | `ChainQuestService.checkDormant`에 settlement_ prefix skip 분기 추가 (14일 dormant 정책 미적용) | 페이즈 1 #4 4.2절 |
| REQ-09 | `ChainQuestService.onStepCompleted`은 변경 없음. settlement_ chainId도 동일 흐름. 단, `protagonistMercId`는 거점 사건에서 미사용 (resolveProtagonist 호출 시 null 유지) | 페이즈 1 #4 4.2절 |
| **QuestCalculator·ExperienceService** | | |
| REQ-10 | `QuestCalculator.calculateReward`에 `int? rewardGoldOverride` 파라미터 추가 — non-null이면 `isGreatSuccess` 시 ×2 적용 후 반환, 기존 baseReward·rewardMultiplier 경로 우회 | 페이즈 4 #3 4.5절 + 페이즈 2 #1 표 |
| REQ-11 | `QuestCalculator.calculateDispatchDuration`에 `int? durationOverrideSeconds` 파라미터 추가 — non-null이면 `Duration(seconds: override)` 반환 (speedMultiplier·partyAverageAgi 무시) | 페이즈 4 #3 4.5절 |
| REQ-12 | `QuestCalculator.calculateDispatchCost`에 `bool isFixedWithDurationOverride` 파라미터 추가 — true이면 `minCost`만 반환 (max 미사용) | 페이즈 4 #3 4.5절 |
| REQ-13 | `ExperienceService.calculateXpGain`에 `int? rewardXpBonusOverride` 파라미터 추가 — non-null이면 기본 계산 결과 + override 가산 | 페이즈 4 #3 4.5절 |
| REQ-14 | `QuestCompletionService.calculate` 내부 `calculateReward`/`calculateXpGain` 호출 직전에 `quest.questPoolId`로 `staticData.questPools`에서 pool 조회 후 is_fixed=true이면 override 인자 전달 | 페이즈 4 #3 + 본 명세 통합 |
| REQ-15 | `QuestListNotifier.dispatch`의 `calculateDispatchCost`/`calculateDispatchDuration` 호출 직전에 동일 pool 조회 후 override 인자 전달 | 페이즈 4 #3 4.5절 |
| **QuestCompletionService settlement_ step 완료 처리** | | |
| REQ-16 | `_applyCompletionResult`에서 체인 step 완료 후크 직후, settlement_ prefix chainId 분기 추가 — 성공/대성공 시 `pool.trustRewardOverride` 점수를 `RegionStateRepository.addSettlementTrust(regionId, override, source: 'settlement_step_<step>')` 호출. 실패/대실패는 미지급 | 페이즈 2 #1 조정 2 (결과 보정) |
| REQ-17 | settlement_ step 완료 시 ActivityLog: 성공 → `settlementEventStep`("사건 진행: {questName} 완료 ({step}/6)"), 실패 → `chainProgressed` 기존 사용 | 페이즈 1 #4 4.3절 |
| REQ-18 | settlement_ chainId 6단계(최종) 완료 시 `onChainCompleted` 콜백에서 `settlementEventCompleted` ActivityLog 기록 + chainCompletedProvider publish (기존 흐름 그대로 사용) | 페이즈 1 #4 4.3절 |
| **ActivityLogType enum 확장** | | |
| REQ-19 | `ActivityLogType` enum에 HiveField 22~24 추가: `settlementTrustUp`(22) / `settlementEventStep`(23) / `settlementEventCompleted`(24) | 페이즈 1 #4 4.3절 |
| **단계 승급 시 일회성 보상** | | |
| REQ-20 | `addSettlementTrust` 내부 level-up 발생 시 일회성 보상 지급 (페이즈 2 #1 조정 4): 2단계 +100G+50XP / 3단계 +200G+100XP / 4단계 +500G+200XP+100명성. 골드는 `UserDataNotifier.addGold`, 명성은 `UserDataNotifier.addReputation`, XP는 보유 용병 균등 분배(2.5절 정책) | 페이즈 2 #1 조정 4 |
| REQ-21 | level-up 시 `settlementTrustLevelUpProvider`에 `TrustLevelUpEvent(regionId, fromLevel, toLevel, settlementName)` publish + `settlementTrustUp` ActivityLog 기록 | 페이즈 1 #4 4.3절 |
| REQ-22 | level-up 직후 `QuestListNotifier.refreshAvailableQuests()` 호출 (trust_threshold 조건 변경에 의한 신규 step 노출 트리거) | 페이즈 4 #3 REQ-07 |
| **dialogQueue 통합** | | |
| REQ-23 | `DialogTypeRegistry`에 `settlementTrustUp` 키 상수 추가 + `keys` Set에 포함 | 페이즈 4 #3 plan.md 의존 인터페이스 |
| REQ-24 | `app.dart`에 `ref.listen<TrustLevelUpEvent?>(settlementTrustLevelUpProvider, ...)` 추가 — high priority `dialogQueueProvider.enqueue` (RankUp critical과 ChainCompleted high 사이의 의미 — 사건 라인 클라이맥스 강조) | 페이즈 1 #4 4.1절 + 페이즈 4 #3 plan.md |
| REQ-25 | `SettlementTrustUpDialog` 위젯 신규 (RankUpOverlay 패턴 모방) — 단계 이름·핵심 톤·일회성 보상 요약·"확인" 버튼 | 페이즈 1 #4 1.1절 |
| **거점 사건 활성화 진입점** | | |
| REQ-26 | 게임 시작 시(`UserDataNotifier.initializeNewGame` 직후) region 3에서 `settlementTrust=0, settlementTrustLevel=1` 초기화 + `ChainQuestService.tryActivateSettlement(3, 'pyegwang_reopen')` 호출. RegionState `getState(3)`이 null이면 신규 생성 후 trust=0, level=1로 저장 | 페이즈 4 #3 spec.md 2.5절 |
| REQ-27 | 기존 세이브 사용자(앱 업데이트 후 첫 실행)도 region 3 첫 진입 시 자동 초기화 — `MovementNotifier.completeMove` 또는 `userDataProvider.initialize` 후 region이 3이고 settlementTrust null이면 동일 초기화 | 호환성 (2.5절) |
| **stub 해제 + 페이즈 4 #3 후속 권고 통합** | | |
| REQ-28 | `QuestListNotifier._getCurrentTrustLevel()` 본문 교체: `return ref.read(regionStateRepositoryProvider).getSettlementTrust(userData.region).level;` (userData null 시 0 반환) | 페이즈 4 #3 plan.md 5절 |
| REQ-29 | `ChainTopSection` build()에서 `actives` 필터에 `!p.chainId.startsWith('settlement_')` 조건 추가 (REQ-08 완전 보장) | 페이즈 4 #3 후속 권고 #1 |
| REQ-30 | `QuestListNotifier._injectFixedSettlementQuest` 중복 방어 — `state.any(...)` → `_repo.getAll().any(...)` 또는 메서드 시작부에 `_load()` 호출하여 최신 상태 보장 | 페이즈 4 #3 후속 권고 #2 |
| REQ-31 | `_refreshExpiredQuests`의 `filteredExpired` 이중 필터 제거 — `_checkQuestRefresh`의 `quest.isSettlementStep` continue로 이미 차단됨. `expired`를 그대로 사용 (코드 가독성 개선) | 페이즈 4 #3 후속 권고 #3 |
| **선택 보상 표 (페이즈 2 #1 조정 3, 일반 의뢰)** | | |
| REQ-32 | `QuestCompletionService.calculate` 결과에 `int settlementTrustGain` 필드 추가 (성공/대성공 시 난이도별 2/3/5점, 외부 세력 태그·외부 리전·실패 시 0). region == 3 한정 적용 | 페이즈 2 #1 조정 3 |
| REQ-33 | `_applyCompletionResult`에서 `result.settlementTrustGain > 0`이면 `addSettlementTrust(quest.region, gain, 'quest_d<difficulty>')` 호출 | 페이즈 2 #1 조정 3 |

### 2.2 데이터 요구사항

#### 2.2.1 Hive 박스/모델 변경

| 박스/모델 | 변경 | typeId/HiveField |
|-----------|------|------------------|
| `regionStates` 박스 | `RegionState` 모델 확장 (typeId 8 유지) | 신규 HiveField 4·5 |
| `RegionState.settlementTrust` | int? nullable, null=0 fallback | HiveField(4) |
| `RegionState.settlementTrustLevel` | int? nullable, null=1 fallback. 1~4 단계 캐시 | HiveField(5) |
| `activityLogs` 박스 | `ActivityLogType` enum 확장 (typeId 6 유지) | 신규 HiveField 22·23·24 |
| `ActivityLogType.settlementTrustUp` | 신뢰도 단계 상승 | HiveField(22) |
| `ActivityLogType.settlementEventStep` | 고정 사건 step 완료 | HiveField(23) |
| `ActivityLogType.settlementEventCompleted` | 고정 사건 라인 완주 | HiveField(24) |
| `chainQuestProgress` 박스 | **변경 없음** — chain_id 네이밍 컨벤션으로 거점 사건 구분 | — |
| `dialogQueue` 박스 | `DialogTypeRegistry.settlementTrustUp` 키 추가 (등록 키 집합 8개로 확장) | typeId 15 유지 |

호환성: 기존 세이브의 RegionState는 settlementTrust/Level이 null이므로 `currentTrust ?? 0`/`currentTrustLevel ?? 1` getter 통해 자동 fallback. `ActivityLogType` enum 신규 값 추가는 Hive enum 어댑터에 자동 반영(기존 0~21 매핑 유지).

#### 2.2.2 신규 클래스 / 데이터 구조

| 항목 | 위치 | 정의 |
|------|------|------|
| `TrustLevelUpEvent` | `band_of_mercenaries/lib/features/investigation/domain/trust_level_up_event.dart` 신규 | `final int regionId; final int fromLevel; final int toLevel; final String settlementName; final int? rewardGold; final int? rewardXp; final int? rewardReputation;` |
| `SettlementTrustResult` | 동일 파일 또는 `region_state_repository.dart` 인라인 | `record ({int newTrust, int newLevel, TrustLevelUpEvent? levelUpEvent})` (Dart record) |
| `_TrustReward` 내부 상수 맵 | `region_state_repository.dart` 상수 | `{2: (gold:100, xp:50, rep:0), 3: (gold:200, xp:100, rep:0), 4: (gold:500, xp:200, rep:100)}` (페이즈 2 #1 조정 4) |
| `_TrustThresholds` 내부 상수 맵 | 동일 | `{1: 0, 2: 30, 3: 80, 4: 200}` (페이즈 2 #1 조정 1) |
| `_TrustLevelNames` | 동일 | `{1: '의심', 2: '인지', 3: '친근', 4: '소속'}` (페이즈 1 #4 1.1절) |
| `_QuestTrustReward` 내부 상수 | `quest_completion_service.dart` 상수 또는 GameConstants | `{1: 2, 2: 3, 3: 5, 4: 0, 5: 0}` (페이즈 2 #1 조정 3) — 일반 의뢰 신뢰도 점수 |

#### 2.2.3 SQL 변경 — 없음

본 명세는 코드 영역만 변경한다. 페이즈 4 #3 SQL이 페이즈 4 SQL 일괄 적용 시점에 함께 들어갈 예정이며, 본 명세는 추가 SQL 마이그레이션 파일을 작성하지 않는다.

(option) `data_versions` 갱신은 페이즈 4 #1·#2·#3 SQL 일괄 적용 시 동시 처리. 본 명세는 클라이언트 코드만 변경하므로 별도 increment 불필요.

### 2.3 UI 요구사항

신규 다이얼로그 1종만 추가. 다른 화면 변경 없음.

#### 2.3.1 SettlementTrustUpDialog (단계 승급 축하 다이얼로그)

- **화면 진입 조건**: `addSettlementTrust` 내부에서 새 단계 도달 → `settlementTrustLevelUpProvider` publish → `app.dart` ref.listen → `dialogQueueProvider.enqueue(high priority)` → 큐 표시 listen이 `showDialog(barrierDismissible: false)`로 표시
- **위젯 계층**: `Dialog > Container(maxWidth 380) > Column > Header(단계 배지+이름) + Subtitle(핵심 톤) + Divider + Reward Section(골드/XP/명성 IconText 3종) + Padding + ConfirmButton`
- **상태 변수**: 없음 (static 데이터). dismiss는 부모(app.dart)에서 주입한 콜백으로 위임
- **화면 전환**: `Navigator.push` 미사용 — `showDialog` 단일 표시 (기존 dialog 전부 동일 패턴). dismiss 시 `settlementTrustLevelUpProvider.notifier.state = null` 리셋은 `enqueue` 직후 listen 콜백에서 수행 (RankUp 패턴과 동일 — `app.dart` line 291 참조)
- **연출/애니메이션**: `RankUpOverlay`처럼 단순 Material AlertDialog. 단계별 색상 강조 (페이즈 1 #4 1.3절): 1=`AppTheme.surface` 회색 / 2=`secondary` 베이지 / 3=`tertiary` 따뜻한 brown / 4=`primary` amber. 본 명세는 기존 색상 재사용으로 신규 색상 추가 없이 처리(2.5절 결정)
- **참조 위젯**: `band_of_mercenaries/lib/core/widgets/rank_up_overlay.dart` (또는 동등 위치) — `RankUpEvent` 표시 패턴 그대로 모방

다이얼로그 본문 예시:
```
🌾 마을 신뢰도 2단계 (인지)
"쓸 만한 외지인"

→ 보너스 골드 +100G
→ 용병 경험치 +50 XP
→ 마을 사람들이 일을 맡기기 시작했다.

[확인]
```

4단계 진입 시:
```
🏘️ 마을 신뢰도 4단계 (소속)
"이제 우리 마을 사람"

→ 보너스 골드 +500G
→ 용병 경험치 +200 XP
→ 명성 +100
→ 폐광이 다시 열렸다. 광장에서 잔치가 열린다.

[확인]
```

### 2.4 페이즈 2 #1 정량 수치 직접 입력

| 항목 | 값 | 출처 |
|------|----|----|
| 1→2단계 임계값 | 30점 | 조정 1 |
| 2→3단계 임계값 | 80점 | 조정 1 |
| 3→4단계 임계값 | 200점 | 조정 1 |
| step별 신뢰도 보상 | 10·15·20·25·30·100 (페이즈 4 #3 SQL `trust_reward_override`로 이미 입력됨) | 조정 2 |
| 일반 의뢰 신뢰도 보상 (난이도별) | 2 / 3 / 5 / 0 / 0 | 조정 3 |
| 2단계 진입 일회성 | +100G + 50XP | 조정 4 |
| 3단계 진입 일회성 | +200G + 100XP | 조정 4 |
| 4단계 진입 일회성 | +500G + 200XP + 100 명성 | 조정 4 |
| 결과 보정 | 성공/대성공 ×1.0, 실패/대실패 ×0 | 조정 2 |

### 2.5 결정 사항 (planner Q&A 사전 확정)

본 명세는 사용자 args로 사전 확정된 결정을 따른다.

- **D-1: settlementTrustLevelUpProvider priority** = `high` (RankUp critical과 동급은 아니지만 사건 라인 클라이맥스 차원에서 chainCompleted/regionTransform과 동일한 high 적용)
- **D-2: AppTheme 신규 색상 추가 안 함** — 기존 surface/secondary/tertiary/primary로 4단계 색상 표현. 페이즈 4 #3에서 추가된 `settlementAccent`(0xFFFFA000)는 카드 배지 전용으로 유지하고 다이얼로그 본문에는 단계별 색상 적용
- **D-3: 단계 진입 XP 분배** = 보유 용병(파견 중·정상 모두 포함) 균등 분배. `MercenaryRepository.getAll().where((m) => m.status != MercenaryStatus.dead)` 대상으로 `addXpAndCheckLevel(mercId, xp ÷ aliveCount)` 호출. 정수 나눗셈 (잔여 XP는 0번째 용병에 가산)
- **D-4: ChainQuestService.tryActivateSettlement 호출 시점** = 게임 시작 시 1회 + region 3 진입 시(기존 세이브 호환). 두 경로 모두 멱등성 보장 (`tryActivate` 내부의 `existing != null && status == active` 시 false 반환 패턴 재사용)
- **D-5: 일반 의뢰 신뢰도 점수 적용 범위** = `quest.region == 3` 한정. 외부 리전 / 외부 세력 태그 / 체인 step / 거점 사건 step은 본 표 미적용 (각각 별도 처리)
- **D-6: addSettlementTrust 호출 동기성** = `Future<void>`로 정의하되 호출자(QuestCompletionService)가 await. UI 알림은 비동기 publish (rankUp 패턴 동일)
- **D-7: 결과 보정 변경 안 함** = step별 신뢰도 보상은 ×1.0 유지(페이즈 2 #1 조정 2). 골드/XP는 기존 result_multiplier 적용 (override는 base 값만 대체, 결과 배수는 기존 흐름)

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | REQ |
|---------|----------|-----|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | `settlementTrust`(HiveField 4) + `settlementTrustLevel`(HiveField 5) 필드 추가 + `currentTrust`/`currentTrustLevel` getter | REQ-01 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | `addSettlementTrust` / `getSettlementTrust` / `setSettlementTrust` 메서드 추가. 임계값/보상/단계명 상수 맵 정의. 단계 승급 시 일회성 보상 지급 + provider publish + ActivityLog + refreshAvailableQuests 호출 | REQ-02·03·04·20·21·22 |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | `tryActivateSettlement(int regionId, String eventName)` 메서드 추가. `checkDormant` 내부 settlement_ prefix continue 분기. `onStepCompleted`에서 `protagonistMercId` resolveProtagonist 호출 시 settlement_ prefix면 skip (현재 기본값 처리로 무영향이지만 명시적 분기 추가 권장) | REQ-07·08·09 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | `calculateReward` 시그니처에 `int? rewardGoldOverride`, `calculateDispatchDuration`에 `int? durationOverrideSeconds`, `calculateDispatchCost`에 `bool isFixedWithDurationOverride = false` 추가. 모든 파라미터 기본값 null/false로 하위 호환 | REQ-10·11·12 |
| `band_of_mercenaries/lib/core/domain/experience_service.dart` | `calculateXpGain` 시그니처에 `int? rewardXpBonusOverride` 추가. non-null이면 결과 + override 가산 | REQ-13 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | (1) `calculate` 내부에서 `quest.questPoolId`로 `staticData.questPools` 조회 후 `pool?.isFixed == true`이면 override 인자 전달 (calculateReward·calculateXpGain). (2) `QuestCompletionResult`에 `int settlementTrustGain` 필드 추가 + 계산 로직 (region==3 + 일반 의뢰 + 성공 시 난이도별 2/3/5점, settlement_ step·체인·외부 리전·외부 세력 태그 시 0) | REQ-14·32 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | (1) `_getCurrentTrustLevel()` 본문 교체 → `RegionStateRepository.getSettlementTrust` 호출. (2) `dispatch()` 내부 calculateDispatchCost·Duration 호출 직전 pool 조회 후 override 인자 전달. (3) `_injectFixedSettlementQuest` 중복 체크를 `_repo.getAll()` 또는 `_load()` 선행으로 변경. (4) `_refreshExpiredQuests` filteredExpired 제거하고 expired 그대로 사용. (5) `_applyCompletionResult` 체인 후크 직전·직후 분기: settlement_ step 성공 시 `addSettlementTrust(regionId, pool.trustRewardOverride, 'settlement_step_<step>')` + `settlementEventStep` 활동 로그. (6) 일반 의뢰 region==3 + result.settlementTrustGain>0이면 `addSettlementTrust(regionId, gain, 'quest_d<difficulty>')` 호출 | REQ-15·16·17·28·30·31·33 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType` enum에 settlementTrustUp(22) / settlementEventStep(23) / settlementEventCompleted(24) 추가 | REQ-19 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | `DialogTypeRegistry`에 `settlementTrustUp` 키 상수 추가 + `keys` set에 포함 | REQ-23 |
| `band_of_mercenaries/lib/app.dart` | `ref.listen<TrustLevelUpEvent?>(settlementTrustLevelUpProvider, ...)` 추가 — high priority enqueue + state=null 리셋 (ChainCompleted 패턴 모방, line 295~309 직후) | REQ-24 |
| `band_of_mercenaries/lib/features/quest/view/chain_top_section.dart` | line 23~25 `actives` 필터에 `&& !p.chainId.startsWith('settlement_')` 추가 | REQ-29 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | `initializeNewGame` 끝부분에 region 3 RegionState 초기화 + `chainQuestServiceProvider.tryActivateSettlement(3, 'pyegwang_reopen')` 호출 추가 | REQ-26 |
| `band_of_mercenaries/lib/features/movement/domain/movement_notifier.dart` (또는 진입 트리거 위치) | 이동 완료 시 도착 region이 3이고 settlementTrust null이면 자동 초기화 + tryActivateSettlement 호출 (멱등성 보장) | REQ-27 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---------|------|
| `band_of_mercenaries/lib/features/investigation/domain/trust_level_up_event.dart` | `TrustLevelUpEvent` 클래스 + `settlementTrustLevelUpProvider` StateProvider<TrustLevelUpEvent?> 정의 (rankUpProvider 패턴) |
| `band_of_mercenaries/lib/features/investigation/domain/settlement_trust_provider.dart` | `settlementTrustProvider(int regionId)` `Provider.family<({int trust, int level}), int>` 정의. `regionStateRepositoryProvider` watch 후 `getSettlementTrust(regionId)` 반환 |
| `band_of_mercenaries/lib/core/widgets/settlement_trust_up_dialog.dart` | `SettlementTrustUpDialog` 위젯 (RankUpOverlay 모방). 단계 이름·핵심 톤·일회성 보상 요약·확인 버튼 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | `RegionState` HiveField 4·5 추가 → hive_generator 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | `ActivityLogType` enum HiveField 22·23·24 추가 → hive_generator 재생성 |

`build_runner` 재실행 명령:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

freezed/json_serializable/riverpod_generator 변경 없음 (Provider 신규 추가는 기존 Provider 패턴 따름, family는 `Provider.family<int, int>` 직접 정의로 충분).

### 3.4 관련 시스템

- **마을 신뢰도 (신규)**: 본 명세로 시스템 전반 본격 도입. 거점 단위 진행도. M7+ 다중 거점 확장 시 RegionState→SettlementState 마이그레이션 가능 (페이즈 1 #4 4.1절 미래 가이드)
- **거점 사건 (페이즈 4 #3 stub 해제)**: 본 명세 적용 후 `settlement_3_pyegwang_reopen` 6단계 활성화. 16행 quest_pools 노출
- **체인 퀘스트**: `chainQuestProgress` 박스 재사용. settlement_ prefix 분기로 dormancy/protagonist 정책만 분리
- **퀘스트 보상**: QuestCalculator/ExperienceService 시그니처 확장. is_fixed=false 기존 행은 override null로 무영향
- **명성 시스템**: 4단계 진입 시 +100 명성 호출 → `addReputation` → 기존 `RankUpEvent` 발생 가능 (F→E 진입 가능). dialog 큐는 critical(rankUp) > high(settlement up) 정렬로 자동 직렬 처리
- **활동 로그**: 신규 3종 추가. UI 색상/아이콘 분화는 `ActivityLogScreen` 후속 작업 (본 명세 미포함, 메시지 텍스트로 구분)
- **dialogQueue**: 신규 dialogType 1종 추가 (8종으로 확장)

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

| 패턴 | 참조 파일 | 적용 |
|------|---------|------|
| StateProvider 단계 승급 이벤트 채널 | `band_of_mercenaries/lib/core/providers/reputation_rank_up_provider.dart` (전체) | `settlementTrustLevelUpProvider` 동일 구조 |
| 누적 + 단계 승급 검증 + ActivityLog + Provider publish | `band_of_mercenaries/lib/core/providers/game_state_provider.dart` line 155~191 (`UserDataNotifier.addReputation`) | `addSettlementTrust` 본문 패턴 모방 |
| Hive Repository 메서드 | `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` line 50~70 (`applyTransform`) | `addSettlementTrust` Box 접근 + save 패턴 |
| dialogQueue 통합 listen | `band_of_mercenaries/lib/app.dart` line 295~309 (chainCompletedProvider) | `settlementTrustLevelUpProvider` listen 동일 구조 |
| isChainStep + chainId + chainStep 활용 | `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` line 824~883 (`onStepCompleted` 호출) | settlement_ chainId도 동일 흐름 사용 (분기 추가만) |
| ChainQuestService.tryActivate | `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` line 32~56 | `tryActivateSettlement`은 chainId만 다른 동일 로직 — 내부적으로 `tryActivate(chainId: 'settlement_${regionId}_$eventName')` 위임 가능 |
| Provider.family | 기존 코드 탐색에서 직접 발견 안 됨 (없으면 단순 함수형 정의 사용) | `Provider.family<({int trust, int level}), int>` |
| `_getCurrentTrustLevel` stub | `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` line 137~140 | 본 명세에서 본문 1줄 교체 |

### 4.2 주의사항

- **Hive HiveField 호환**: RegionState HiveField 4·5는 nullable(`int?`)로 추가. 기존 세이브의 RegionState 인스턴스는 read 시 null로 반환되며 `currentTrust ?? 0` / `currentTrustLevel ?? 1`로 fallback. NOT NULL로 추가하면 기존 세이브 deserialize 실패 위험
- **enum HiveField 호환**: ActivityLogType enum에 22·23·24 추가는 새 값이므로 기존 세이브 read 시 unknown enum 경고 없음. 단, 신규 enum 값을 활용하는 ActivityLog 인스턴스를 구버전 앱이 read할 경우 hive_generator의 fallback(첫 번째 enum 값) 동작은 hive 정책상 허용됨
- **Provider.family + watch**: `settlementTrustProvider(regionId)` family는 RegionState 변경을 감지해야 한다. `regionStateRepositoryProvider` watch만으로는 박스 변경을 못 잡으므로, `addSettlementTrust` 내부에서 `state.save()` 후 별도 channel(예: `_trustChangeNotifier` ChangeNotifierProvider 또는 StreamProvider) publish 권장. 또는 `chainQuestProgressProvider`처럼 `box.watch().map`으로 StreamProvider 변환 (4.4절 구현 힌트 참조)
- **dialog 우선순위**: 4단계 진입 시 +100 명성 → F→E 랭크업 발생 가능. settlement up = high, rankUp = critical이므로 자동으로 rankUp이 먼저 표시되고 settlement up이 뒤따른다. 이 직렬화는 큐 정책으로 보장되므로 호출 순서는 비결정적이어도 OK
- **CLAUDE.md 코멘트 정책**: 한국어, 비자명한 사유만. settlement_ prefix 분기 추가 시 "왜 분리하는지"(14일 dormant 부적합, protagonist 미사용) 짧게 명시
- **Navigator.push 금지**: SettlementTrustUpDialog는 showDialog로만 표시. 화면 전환 없음
- **시간 가속 미적용**: 신뢰도 시스템 자체는 시간 의존 로직이 없으므로 `speedMultiplier` 무관

### 4.3 엣지 케이스

| 상황 | 처리 |
|------|------|
| `getState(3)` null | 신규 RegionState 생성 후 trust=0, level=1 저장 (멱등) |
| 기존 세이브 사용자가 region 3 외부에 있을 때 첫 실행 | 본 명세 적용 시 region 3 진입 시점에 자동 초기화 (REQ-27). 즉시 발생 안 함 |
| 동일 frame에 여러 단계 동시 승급 (예: 0점→200점 가산 디버그) | 임계값 표 순회 후 newLevel = 도달 가능 최대 단계로 결정. 일회성 보상은 통과한 모든 단계의 합산 (또는 최종 단계만 — 페이즈 2 #1 조정 4 명시 안 됨 → 합산 채택, 디버그 외 정상 플레이에선 1단씩 발생) |
| `tryActivateSettlement` 후 ChainQuestProgress 이미 active | `tryActivate` 내부 멱등성으로 false 반환 (기존 동작 그대로) |
| `addSettlementTrust(amount=0)` 호출 | early return (아무 변화 없음 — addReputation 패턴 모방) |
| 4단계에서 더 이상 진입 불가, 추가 점수 누적 | 누적은 계속 (디버그용 누적값 추적). level은 4 고정. 단계 승급 발생 안 함 → publish 없음 |
| settlement_ step ActiveQuest 실패/대실패 | `addSettlementTrust` 호출 안 함. `chainProgressed` 활동 로그 (기존 패턴 유지) |
| settlement_ step 6 완료 시 +100 신뢰도 → 4단계 진입 → 일회성 보상(+500G+200XP+100명성) → +100 명성 → F→E 랭크업 가능 | 모든 다이얼로그 큐로 직렬화. critical(rankUp) → high(trustUp) → high(chainCompleted, FIFO) 순서로 자동 표시 |
| pool.questPoolId가 staticData.questPools에 없음 (캐시 불일치) | pool null로 처리 → override 미적용. 기존 calculateReward/calculateXpGain 경로로 fallback. 안전 처리 |
| `_getCurrentTrustLevel()` userData null | 0 반환 (기존 stub과 동일) |
| 기존 세이브의 region == 3 + settlementTrust=null + 이미 chain_quests에 다른 일반 chain progress 존재 | 영향 없음. settlement_ prefix와 chain_ prefix는 chainId가 다르므로 충돌 없음 |

### 4.4 구현 힌트

- **진입점 — 신뢰도 누적**:
  - 일반 의뢰 완료: `_applyCompletionResult` → `result.settlementTrustGain > 0` → `addSettlementTrust(quest.region, gain, 'quest_d<difficulty>')`
  - 사건 step 완료: `_applyCompletionResult` 체인 후크 직전·직후 settlement_ 분기 → `addSettlementTrust(regionId, pool.trustRewardOverride, 'settlement_step_<step>')`
  - 디버그/운영: `setSettlementTrust(regionId, trust, level)` 직접 호출 (UI 미연동)

- **데이터 흐름 — 단계 승급**:
  ```
  QuestCompletionService.calculate
    → settlementTrustGain 계산
  _applyCompletionResult
    → addSettlementTrust(regionId, amount, source)
       → 누적 점수 증가 (RegionState.save)
       → 단계 승급 검증 (newLevel = thresholds 표 순회)
       → newLevel > oldLevel 시:
            * settlementTrustLevel 갱신
            * 일회성 보상 지급 (addGold/addReputation/grantXpEvenly)
            * settlementTrustUp ActivityLog
            * settlementTrustLevelUpProvider publish (TrustLevelUpEvent)
            * QuestListNotifier.refreshAvailableQuests() 호출
       → return SettlementTrustResult(newTrust, newLevel, levelUpEvent?)
  app.dart ref.listen
    → settlementTrustLevelUpProvider 변경 감지
    → dialogQueueProvider.enqueue(high priority, settlementTrustUp)
    → state = null 리셋
  app.dart dialog queue listen
    → SettlementTrustUpDialog showDialog (barrierDismissible: false)
    → dismiss → dequeue
  ```

- **진입점 — 거점 사건 활성화**:
  - 신규 게임: `UserDataNotifier.initializeNewGame` 끝부분에 region 3 RegionState 초기화(`saveState(RegionState(regionId: 3, settlementTrust: 0, settlementTrustLevel: 1))`) + `tryActivateSettlement(3, 'pyegwang_reopen')`
  - 기존 세이브: `MovementNotifier.completeMove` 또는 region 3 도착 hook에서 RegionState null + region==3 시 자동 초기화 (멱등)

- **참조 구현**:
  - `region_state_repository.dart` line 50~70 — `applyTransform` Box 접근 패턴
  - `game_state_provider.dart` line 155~191 — `addReputation`의 oldLevel/newLevel 비교 후 publish + ActivityLog 패턴 그대로
  - `chain_quest_service.dart` line 32~56 — `tryActivate` 멱등성 패턴 그대로
  - `chain_quest_service.dart` line 183~195 — `checkDormant` settlement_ continue 분기
  - `app.dart` line 295~309 — chainCompletedProvider listen 패턴 그대로
  - `quest_provider.dart` line 137~140 — `_getCurrentTrustLevel()` 1줄 교체
  - `quest_provider.dart` line 824~883 — onStepCompleted 호출. settlement_ 분기는 chainStepData 조회 직후

- **확장 지점**:
  - `RegionStateRepository`에 `addSettlementTrust` 추가 — 기존 메서드(applyTransform 등)와 동급
  - `ChainQuestService`에 `tryActivateSettlement` 추가 — 내부적으로 `tryActivate` 재사용 가능
  - `QuestCompletionService` 신규 필드 `settlementTrustGain` — `QuestCompletionResult` 클래스에 추가
  - `_applyCompletionResult` 체인 후크 분기 추가 — 824~883 영역에 settlement_ 분기 삽입
  - `app.dart` listen 추가 — 295~309 사이 또는 직후

- **Provider.family vs Stream**: `settlementTrustProvider(regionId)`는 단순 동기 조회. RegionState 변경 시 자동 갱신을 위해 별도 ChangeNotifier/Stream을 두는 대신, `addSettlementTrust` 내부에서 일회성 이벤트만 publish하는 것이 단순. UI에서 상시 watch가 필요한 곳(예: 마을 진행 바)은 `regionStateRepositoryProvider` watch + 명시적 box.watch StreamProvider 신설 검토 (본 명세 범위 외 — 페이즈 4 #4 마을 방문 UI에서 결정)

### 4.5 사용 예시 (구현 가이드용 스니펫 — 명세 외 참고)

#### `addSettlementTrust` 본문 골격 (구현 시 참고)

```dart
// region_state_repository.dart
static const _trustThresholds = {1: 0, 2: 30, 3: 80, 4: 200};
static const _trustRewards = {
  2: (gold: 100, xp: 50, rep: 0),
  3: (gold: 200, xp: 100, rep: 0),
  4: (gold: 500, xp: 200, rep: 100),
};
static const _trustLevelNames = {1: '의심', 2: '인지', 3: '친근', 4: '소속'};

Future<({int newTrust, int newLevel, TrustLevelUpEvent? levelUpEvent})>
addSettlementTrust({
  required int regionId,
  required int amount,
  required String source,
  required Ref ref, // UI 콜백/명성·골드·XP 지급용
}) async {
  if (amount == 0) {
    final s = getState(regionId);
    return (newTrust: s?.currentTrust ?? 0, newLevel: s?.currentTrustLevel ?? 1, levelUpEvent: null);
  }
  var state = getState(regionId);
  state ??= RegionState(regionId: regionId);
  final oldLevel = state.currentTrustLevel;
  state.settlementTrust = (state.currentTrust + amount).clamp(0, 999999);
  // 임계값 표 순회로 newLevel 결정
  int newLevel = 1;
  for (final entry in _trustThresholds.entries) {
    if (state.settlementTrust! >= entry.value) newLevel = entry.key;
  }
  state.settlementTrustLevel = newLevel;
  await saveState(state);

  TrustLevelUpEvent? event;
  if (newLevel > oldLevel) {
    // 통과한 모든 단계의 보상 합산
    int rewardGold = 0, rewardXp = 0, rewardRep = 0;
    for (int lv = oldLevel + 1; lv <= newLevel; lv++) {
      final r = _trustRewards[lv];
      if (r == null) continue;
      rewardGold += r.gold;
      rewardXp += r.xp;
      rewardRep += r.rep;
    }
    // 일회성 보상 지급 (Repository가 Ref를 통해 호출)
    if (rewardGold > 0) await ref.read(userDataProvider.notifier).addGold(rewardGold);
    if (rewardRep > 0) await ref.read(userDataProvider.notifier).addReputation(rewardRep);
    if (rewardXp > 0) await _grantXpEvenly(ref, rewardXp);
    // ActivityLog
    ref.read(activityLogProvider.notifier).addLog(
      '마을 신뢰도가 $newLevel단계(${_trustLevelNames[newLevel]})에 도달했다',
      ActivityLogType.settlementTrustUp,
    );
    // Provider publish
    event = TrustLevelUpEvent(
      regionId: regionId,
      fromLevel: oldLevel,
      toLevel: newLevel,
      settlementName: '더스트빌', // M4 MVP region 3 한정
      rewardGold: rewardGold,
      rewardXp: rewardXp,
      rewardReputation: rewardRep,
    );
    ref.read(settlementTrustLevelUpProvider.notifier).state = event;
    // 풀 갱신 트리거 (level 변경 → trust_threshold 조건 갱신)
    await ref.read(questListProvider.notifier).refreshAvailableQuests();
  }
  return (newTrust: state.settlementTrust!, newLevel: newLevel, levelUpEvent: event);
}
```

> 주의: Repository에 Ref를 직접 주입하는 방식은 기존 RegionStateRepository(라인 6~7) 패턴과 다소 다르다. 대안은 Repository는 순수 데이터 접근만 담당하고, 보상 지급/log/publish는 별도 SettlementTrustService(domain layer)로 분리. 본 명세는 권장 구조를 명시하지 않고, 구현자가 두 옵션 중 선택하도록 한다 (5절 Q-1 참조).

#### `tryActivateSettlement` 본문 골격

```dart
// chain_quest_service.dart
Future<bool> tryActivateSettlement({
  required int regionId,
  required String eventName,
  required UserData user,
}) async {
  final chainId = 'settlement_${regionId}_$eventName';
  return tryActivate(chainId: chainId, user: user);
}
```

#### `checkDormant` settlement_ skip 분기

```dart
Future<void> checkDormant({required List<ChainQuestProgress> progresses}) async {
  for (final progress in progresses) {
    if (progress.status != ChainQuestStatus.active) continue;
    // 거점 사건은 14일 dormant 정책 미적용 (페이즈 1 #4 4.2절)
    if (progress.chainId.startsWith('settlement_')) continue;
    final availableAt = progress.currentStepAvailableAt;
    if (availableAt == null) continue;
    if (DateTime.now().difference(availableAt) > const Duration(days: 14)) {
      progress.status = ChainQuestStatus.dormant;
      await _repo.save(progress);
    }
  }
}
```

#### `_applyCompletionResult` settlement_ 분기 (체인 후크 옆에 삽입)

```dart
// quest_provider.dart line 824 부근
if (quest.isChainQuest && quest.chainId != null && quest.chainStep != null) {
  // ... 기존 chainStepData 조회 + onStepCompleted 호출
  // 거점 사건 step 완료 처리 (성공/대성공 한정)
  if (quest.isSettlementStep && (result.resultType == QuestResult.greatSuccess
      || result.resultType == QuestResult.success)) {
    final pool = staticData.questPools.where((p) => p.id == quest.questPoolId).firstOrNull;
    final trustReward = pool?.trustRewardOverride ?? 0;
    if (trustReward > 0) {
      await ref.read(regionStateRepositoryProvider).addSettlementTrust(
        regionId: quest.region,
        amount: trustReward,
        source: 'settlement_step_${quest.chainStep}',
        ref: ref,
      );
      ref.read(activityLogProvider.notifier).addLog(
        '사건 진행: ${quest.questName} 완료 (${quest.chainStep}/6)',
        ActivityLogType.settlementEventStep,
      );
    }
  }
}
// 일반 의뢰 신뢰도 점수 (region == 3 + 일반 의뢰 한정)
if (!quest.isChainQuest && quest.region == 3 && result.settlementTrustGain > 0) {
  await ref.read(regionStateRepositoryProvider).addSettlementTrust(
    regionId: quest.region,
    amount: result.settlementTrustGain,
    source: 'quest_d${quest.difficulty}',
    ref: ref,
  );
}
```

---

## 5. 기획 확인 사항

| ID | 사항 | 권장 답변 (사전 확정) |
|----|------|---------------------|
| Q-1 | `RegionStateRepository.addSettlementTrust`이 Ref 주입을 받는 구조(데이터+도메인 혼합)와 별도 `SettlementTrustService`(domain layer)로 분리하는 구조 중 어느 쪽? | **A — Repository 직접 주입 (단순성 우선)**. 사유: 기존 `UserDataNotifier.addReputation`도 Notifier 내부에서 ActivityLog/Provider publish를 직접 처리. 분리하면 신규 파일 1개 추가에 비해 호출 흐름 추적이 어려워짐. M7+ 다중 거점 확장 시 SettlementTrustService로 분리 가능 |
| Q-2 | settlement_ step 완료 시 `protagonistMercId` 정책 — 거점 사건도 `_pickProtagonist` 호출되어 임의로 설정될까? | **권장: 거점 사건은 protagonist 무시**. `onStepCompleted`에 `if (chainId.startsWith('settlement_')) skip protagonist resolution` 분기 추가. 페이즈 1 #4 4.2절의 "거점 사건은 항상 null" 정합. 단, 기존 코드는 분기 추가만 하면 되므로 구현 부담 적음 |
| Q-3 | `currentStepAvailableAt`을 settlement_ step에서도 사용? (chain_quests 테이블의 `next_step_delay_seconds` 미존재) | **권장: 사용 안 함**. quest_pools 행에는 `next_step_delay_seconds` 컬럼이 없고, page 4 #3에 정의된 stepFailureCount/lastActivityAt만 사용. `onStepCompleted` 분기에서 settlement_ prefix면 `currentStepAvailableAt = null` 유지. 페이즈 1 #4 4.2절 정합 |
| Q-4 | 단계 진입 일회성 보상의 XP 분배 — 균등 분배 vs 1명에게 몰빵? | **D-3 결정 적용 — 보유 살아있는 용병 균등 분배** (정수 나눗셈, 잔여는 0번째 인덱스). 이유: 페이즈 2 #1 4단계 진입 +200XP는 큰 값이라 1명만 주면 다른 용병과의 격차 발생. 균등 분배가 자연스러움 |
| Q-5 | settlement_ chainId 6단계 모두 완료 후 신규 사건 라인 활성화 절차? (M4 시점은 1개만) | **M4 시점: 사건 완료 후 미활성**. ChainQuestProgress.status = completed로 영구 보존. M5+ 신규 사건 라인 추가 시 동일 quest_pools 패턴 + tryActivateSettlement 호출 (페이즈 1 #4 2.6절 명시) |
| Q-6 | 디버그용 `setSettlementTrust`는 일회성 보상도 우회? | **권장: 우회**. setter는 운영/디버그 전용이며 정상 게임 플레이에서 호출 안 됨. 일회성 보상 호출 시 무한 루프(setSettlementTrust → addReputation → ...) 가능성. addSettlementTrust만 일회성 보상 트리거 |
| Q-7 | 기존 세이브 사용자 region 3 첫 진입 시 자동 활성화 위치 — `MovementNotifier.completeMove` vs `userDataProvider`(앱 시작 시 region이 3인 경우) 둘 다? | **권장: 양쪽 모두 + 멱등성 보장**. `tryActivate`는 이미 `existing != null && status == active` 시 false 반환. RegionState 초기화도 null 체크 후 진행. 양쪽 모두 호출해도 1회만 효과 발생 |
| Q-8 | M4 region 3 = 더스트빌. settlementName 하드코딩 vs `staticData.regions.firstWhere(r=>r.region==3).name`? | **권장: staticData에서 동적 조회**. 향후 region 이름 변경 시 자동 반영. 단 `TrustLevelUpEvent.settlementName` 인자는 String — 지역 이름이 없으면 '시작 거점' fallback |

---

## 6. 페이즈 4 #3 후속 권고 통합 매트릭스

| # | 페이즈 4 #3 plan.md 권고 | 본 명세 REQ | 적용 시점 |
|---|------------------------|-----------|----------|
| 1 | ChainTopSection settlement_ filter 추가 | REQ-29 | 본 명세 |
| 2 | _injectFixedSettlementQuest 중복 방어 (state vs Hive) | REQ-30 | 본 명세 |
| 3 | _refreshExpiredQuests filteredExpired 이중 필터 정리 | REQ-31 | 본 명세 |
| 4 | _QuestCard IntrinsicHeight 사용 (HIGH) | — | 후속 UI 사이클 (본 명세 범위 외) |
| 5 | _QuestCard speedMultiplierProvider rebuild | — | 후속 UI 사이클 (범위 외) |
| 6 | "📜 마을 사건" 배지 접근성 (Semantics) | — | 후속 접근성 사이클 (범위 외) |
| 7 | _injectFixedSettlementQuest hardcoded chainId 일반화 | — | M5 또는 페이즈 4 #6 (본 명세 미적용 — M4 MVP는 1개 사건만) |
| 8 | settlementAccent 라이트 테마 대비비 | — | 라이트 테마 도입 시 (범위 외) |

---

## 7. 호환성 검토

- **기존 RegionState 박스**: `settlementTrust`/`settlementTrustLevel`이 nullable이라 기존 인스턴스는 read 시 null. `currentTrust ?? 0` getter로 자동 fallback. 즉시 마이그레이션 불필요
- **기존 ActivityLog 박스**: enum 신규 값 22~24 추가는 후방 호환. 구버전 앱이 새 값 인스턴스를 read하면 hive_generator의 fallback(첫 enum) 동작 — 기존 세이브에는 신규 값 없으므로 영향 없음
- **기존 ChainQuestProgress 박스**: 모델 변경 없음. settlement_ prefix는 신규 chainId만 사용하므로 기존 chain_ 항목 무영향
- **기존 quest_pools 캐시**: 페이즈 4 #3에서 이미 9개 컬럼 추가 완료. 본 명세는 컬럼 추가 없음. override 값 활용만 변경
- **기존 dialogQueue 박스 (typeId 15)**: `DialogTypeRegistry.keys` 확장으로 신규 값 등록. 기존 7종은 그대로. 미등록 타입 영속 entry는 `DialogQueuePersistence` 정책에 따라 폐기됨 — 본 명세 신규 타입 추가는 위에서 새 키 등록 → 영속 복원 가능
- **SyncService 변경 불필요**: SQL 마이그레이션 없음. data_versions 갱신은 페이즈 4 SQL 일괄 적용 시 함께 처리
- **테스트 영향**: 기존 testValue PASS 499/499 (페이즈 4 #3 시점). 본 명세 적용 후 신규 단위 테스트 권장:
  - `RegionStateRepository.addSettlementTrust` — 임계값 도달 → newLevel 반환·publish 검증 (Mock Ref)
  - `QuestCompletionService.calculate` — settlement_ step 시 settlementTrustGain=0, region==3 일반 의뢰 시 난이도별 정확값
  - `ChainQuestService.checkDormant` — settlement_ chainId skip 검증
- **운영 도구(operation-bom)**: quest_pools 편집 폼은 페이즈 4 #3에서 이미 9컬럼 반영. 본 명세는 클라이언트 코드만 변경하므로 운영 도구 영향 없음

---

## 8. 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| RegionState HiveField 4·5 (REQ-01) | **높음** | 모든 후속 메서드의 데이터 기반 |
| RegionStateRepository 3개 메서드 (REQ-02·03·04) | **높음** | 신뢰도 누적 핵심 로직 |
| ActivityLogType 3종 (REQ-19) | **높음** | activity log 호출에 의존 |
| TrustLevelUpEvent + settlementTrustLevelUpProvider + settlementTrustProvider (REQ-05·06) | **높음** | UI 통합 채널 |
| ChainQuestService 분기 3개 (REQ-07·08·09) | **높음** | 거점 사건 활성화 진입점 |
| QuestCalculator/ExperienceService override 4개 (REQ-10·11·12·13) | **높음** | 보상 곡선 정합 |
| QuestCompletionService settlement_ 분기 (REQ-14·16·17·18·32·33) | **높음** | 핵심 통합 로직 |
| QuestListNotifier stub 해제 + 후속 권고 #2·#3 (REQ-28·30·31) | **높음** | 페이즈 4 #3 활성화 |
| ChainTopSection settlement_ 필터 (REQ-29) | **높음** | UI 분리 보장 |
| 게임 시작 시 region 3 자동 초기화 (REQ-26) | **높음** | 거점 사건 진입점 |
| 단계 진입 일회성 보상 (REQ-20·21·22) | **높음** | 페이즈 2 #1 정량 입력 |
| dialogQueue 통합 (REQ-23·24·25) | **중간** | UI 알림. 본 흐름 검증 후 추가 가능 |
| MovementNotifier region 3 첫 진입 자동 초기화 (REQ-27) | **중간** | 기존 세이브 호환. initializeNewGame에서 1차 처리 가능 |
| SettlementTrustUpDialog 위젯 (REQ-25) | **중간** | dialog 통합과 함께 |

---

## 9. 후속 작업

본 명세 완료 후:

1. **페이즈 4 SQL 일괄 적용 (옵션 B 종결)** — 페이즈 4 #1·#2·#3 SQL 마이그레이션 4종을 단일 시점에 Supabase에 적용. data_versions 동시 증분으로 클라이언트 sync 트리거. 본 명세는 SQL 변경 없음
2. **페이즈 4 #4 마을 방문 UI** — 본 명세의 `settlementTrustProvider(regionId)` 활용. 약초상/의무실 UI에서 `currentTrustLevel`로 잠금 정책·인사말 변주 처리. 페이즈 4 #3의 `min_trust_level=2` 채집 의뢰 노출도 본 명세 stub 해제로 활성화됨
3. **회귀 테스트** — 첫 2시간 플레이 시뮬레이션 (페이즈 1 #5 + 페이즈 2 #1 표 정합 검증):
   - 0~30분 step 1·2 + 일반 의뢰 → 2단계 진입
   - 30~60분 step 3·4 + 일반 의뢰 → 3단계 진입
   - 60~100분 step 5·6 → 4단계 진입 + +500G+200XP+100명성 보상 확인
4. **ActivityLog UI 색상/아이콘 분화** — settlementTrustUp/EventStep/EventCompleted 3종 색상 차별화 (선택, 후속 사이클)
5. **운영 도구 신뢰도 디버그 패널** — `setSettlementTrust` 호출 진입점 (선택, 후속)
