# M7 페이즈 4 #1: RegionState 모델 확장 + 지역 상태 시스템 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260516_m7_region_state_rules.md`
> 밸런스 문서: `Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md`
> 데이터 산출물: `Docs/content-data/[region-discovery]20260517_m7-discoveries.csv` (Supabase 적용 완료), `Docs/content-data/m7_phase3_5_recipes_chain.sql` (페이즈 4 #4 적용 위임)
> 작성일: 2026-05-17

## 1. 개요

M7 페이즈 1 #1에서 정의한 7개 생활권 리전(3·31·127·9·10·146·38)에 **가역적 위험도 상태 시스템**을 도입한다. `RegionState`에 3축(`dangerScore` int -100~+100 / `dangerLevel` int 1~4 캐시 / `unlockedFlags` List<String> 영속)을 추가하고, 사건 완료·체인 완주·엘리트 처치·시간 경과 4종 트리거로 상태가 변동한다. dangerLevel 큰 전이 시 RegionStateChangedDialog(medium priority) 발동 + M6 hook 7번째 `region_state_transition`으로 위업 발급. 본 spec은 데이터 모델·서비스·이벤트 채널·M6 hook 통합·decay 메커니즘만 다루며, QuestGenerator 가중치 분기(페이즈 4 #2)와 인프라 단계 시스템(페이즈 4 #4)은 별도 spec에 위임한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `RegionState`에 dangerScore·dangerLevel·unlockedFlags 3축 추가

- HiveField 8: `int? dangerScore` (nullable, fallback 0). 범위 -100 ~ +100 (clamp 적용).
- HiveField 9: `int? dangerLevel` (nullable, fallback 2=peaceful). 1=stable, 2=peaceful, 3=tension, 4=threat.
- HiveField 10: `List<String> unlockedFlags` (non-null, default `[]`). 멱등 추가 (M5 firstAcquiredMaterialIds 패턴).
- getter: `currentDangerScore`, `currentDangerLevel`, `hasFlag(String)`.
- HiveType id 8 유지(기존), build_runner 재실행 필요(`region_state_model.g.dart` 재생성).
- 기존 사용자 세이브 호환 — nullable + List default로 자동 fallback.

#### FR-2: `DangerLevel` enum + `resolveLevel(int)` 함수

- enum 4종: stable / peaceful / tension / threat.
- 임계값 (페이즈 2 #2 확정): stable -100~-50, peaceful -49~-1, tension 0~+49, threat +50~+100.
- `resolveLevel(int score)` 정적 함수 — score → DangerLevel 매핑.
- `DangerLevel.toCacheInt()` / `DangerLevel.fromCacheInt(int?)` — int 캐시 변환 헬퍼.
- enum.toString 한국어 라벨 매핑 (`'안정'` / `'평온'` / `'긴장'` / `'위협'`).
- `region_state_required`/`excluded` 컬럼 값(text 'stable'/'peaceful'/'tension'/'threat')과 일치하는 string 매핑 `toLowercaseString()` 헬퍼.

#### FR-3: `RegionStateRepository` 신규 메서드 4종

- `addDangerScore(regionId, delta, source)`:
  - clamp(-100, +100)로 점수 갱신
  - dangerLevel 재계산 (resolveLevel) — int 캐시 갱신
  - dangerLevel 전이 발생 시 `dangerLevelChangedProvider` publish (DangerLevelChangedEvent 페이로드)
  - ActivityLog `regionDangerLevelChanged` 추가
  - dangerLevel 전이 직후 fail-soft trailing — M6 hook 7번째 평가 (FR-7 참조)
  - 반환: `({int newScore, int newLevel, DangerLevelChangedEvent? event})`
- `toggleFlag(regionId, flag)`:
  - unlockedFlags에 멱등 추가 (이미 있으면 false 반환 + skip)
  - ActivityLog `regionUnlockedFlagToggled` 추가
  - fail-soft trailing — M6 hook 7번째 평가 (region_state_transition와 별개로 flag 자체 위업 발급 가능성, 페이즈 4 #4의 인프라 단계 전이 trailing은 별도 spec)
  - 반환: `bool` (신규 토글 여부)
- `hasFlag(regionId, flag)`: 동기 bool 조회. RegionState 미존재 시 false.
- `getOrCreateRegionState(regionId)`: RegionState가 없으면 신규 생성+box에 추가, 있으면 기존 반환. 기본값 보장.

#### FR-4: 트리거 통합 (fail-soft trailing 5종)

- **FR-4a**: `QuestCompletionService` — quest 완료 직후 `pool.regionStateEffect`가 있으면 `applyDangerScoreFromQuest(regionId, pool)` 호출. cumulative(현재 누적 횟수가 cap에 미달이면 delta 적용, cap 도달 시 단발 -10 보너스 + flag toggle) / oneshot(flag 미보유 시에만 delta 적용 + flag toggle) 분기. **단, quest_pools 신규 3 컬럼은 페이즈 4 #2 spec에서 ALTER. 본 spec은 호출 지점 추가만 명세하고 실제 region_state_effect 사용은 페이즈 4 #2 마이그레이션 후 활성화**.
- **FR-4b**: `ChainQuestService.completeChain()` — 체인 완주 trailing. settlement_* prefix 제외 일반 chain 완주 시 매핑된 region에 oneshot delta 적용 + flag toggle. 매핑 테이블 (페이즈 1 #2 1.3절 8 flag 중 4개):
  - chain_roadside_shrine → region 31, -20, flag `region_31_shrine_quest_completed`
  - chain_windrunner_trail → region 10, -30, flag `region_10_windrunner_chain_completed`
  - chain_ironbound_pact → region 38, -40, flag `region_38_ironbound_pact_completed`
  - chain_m7_mist_clearing → region 146, **-50 특수 단발**, flag `region_146_mist_cleared`
  - settlement_3_pyegwang_reopen → region 3, -30, flag `region_3_pyegwang_reopen_completed` (settlement_ prefix 예외 — 본 spec에서 명시적 처리)
- **FR-4c**: `EliteLootService` 또는 `_applyCompletionResult` 엘리트 분기 — 유니크 엘리트 첫 처치 시 매핑된 region에 flag toggle + oneshot delta:
  - elite_giant_beast 또는 region 9 forest 환경 엘리트 → region 9, -40, flag `region_9_giant_beast_killed`
  - (추후 신규 elite 추가 시 매핑 확장 — 페이즈 4 별도 spec)
- **FR-4d**: `gameTickProvider` decay 분기 — 매 틱(1초) 현재 시각 비교, M7 7리전 중 `dangerScore < 0`인 region에 대해 `(now - lastDecayCheck).inHours >= 12` 시 `addDangerScore(regionId, +1, 'decay')` 호출. lastDecayCheck는 RegionStateRepository 내부 정적 Map<int, DateTime> 또는 RegionState 신규 필드 추가 검토 (M7 MVP는 정적 Map, 앱 재시작 시 리셋되어도 무방).
- **FR-4e**: `RegionStateRepository.toggleFlag()` 내부 trailing — 페이즈 4 #4 spec의 인프라 단계 전이 평가 hook (`_evaluateInfrastructureTransition`)을 fail-soft try/catch로 호출. 본 spec은 hook 호출 지점만 명세, 실제 인프라 전이 로직은 페이즈 4 #4 spec.

#### FR-5: `dangerLevelChangedProvider` + `RegionStateChangedDialog` + DialogTypeRegistry 확장

- `dangerLevelChangedProvider`: `StateProvider<DangerLevelChangedEvent?>` (initial null). 페이로드:
  ```dart
  class DangerLevelChangedEvent {
    final int regionId;
    final String regionName;
    final DangerLevel from;
    final DangerLevel to;
    final List<String> grantedAchievements;  // M6 hook 7번째 결과
    final bool isBigTransition;              // 가벼운/큰 전이 구분
  }
  ```
- 큰 전이 vs 가벼운 전이 (페이즈 1 #2 6.2절):
  - **큰 전이** (dialog 발동): stable ↔ tension, stable ↔ threat, peaceful ↔ threat (한 단계 이상 건너뛰기 또는 stable/threat 진입·이탈)
  - **가벼운 전이** (ActivityLog만): peaceful ↔ tension, tension ↔ threat (인접 단계)
- DialogTypeRegistry 신규 키 추가 (12 → 13종): `static const String regionStateChanged = 'regionStateChanged';`
- `RegionStateChangedDialog`: medium priority, `barrierDismissible: true`. 확인 버튼 1개. UI:
  - 타이틀: "{regionName} 상태 변화"
  - 본문: "{regionName}이(가) {from 한국어} → {to 한국어}로 변화했다." + 위업 발급 시 "🏆 위업 {N}개를 획득했다." 추가
  - `dangerLevelChangedProvider`에 isBigTransition=true일 때만 dialogQueue enqueue
- 우선순위 정렬 (페이즈 1 #2 6.2절): critical(rankUp) > high(chain/transform/trustUp/achievement/title) > **medium(construction/investigation/travelChoice/regionStateChanged/idleReward)** > low

#### FR-6: ActivityLogType 신규 2종 + flag_description 매핑

- HiveField 32: `regionDangerLevelChanged` — 메시지: `"{regionName} 상태가 {from} → {to}로 변화했다"`.
- HiveField 33: `regionUnlockedFlagToggled` — 메시지: `"{regionName}에서 변화가 일어났다: {flag_description}"`.
- flag_description 매핑 표 (8 flag — 페이즈 1 #2 1.3절 + 페이즈 3 #5 메타):
  - `region_3_pyegwang_reopen_completed` → "폐광이 재개되었다"
  - `region_31_bandits_cleared` → "도적이 소탕되었다"
  - `region_31_shrine_quest_completed` → "폐사당 체인이 완료되었다"
  - `region_127_nomad_friendly` → "유목민과 친교를 맺었다"
  - `region_9_giant_beast_killed` → "거대 야수가 처치되었다"
  - `region_10_windrunner_chain_completed` → "풍신의 자취를 따라갔다"
  - `region_146_mist_cleared` → "회색 늪지의 안개가 걷혔다"
  - `region_38_ironbound_pact_completed` → "부서진 요새의 서약이 매듭지어졌다"
- ActivityLogType enum 재생성 필요 (build_runner — `activity_log_model.g.dart`).

#### FR-7: M6 hook 7번째 (region_state_transition) + AchievementService 통합 + band_achievement_templates 7행

- **AchievementService 변경 없음** — `grant(templateId, ...)` 메서드는 기존 그대로 활용. 새 callback DI 추가하지 않음. 대신 `RegionStateRepository.addDangerScore()` 내부에서 dangerLevel 전이 감지 시 직접 호출.
- 전이 hook 평가 로직 (RegionStateRepository.addDangerScore 내부 fail-soft trailing):
  ```dart
  // 첫 peaceful 진입 (음수 진입) 시 위업 발급
  if (newScore < 0 && oldScore >= 0) {
    try {
      await ref.read(achievementServiceProvider).grant(
        'region_pacified:region_$regionId',
        regionId: regionId,
        payload: {'oldScore': oldScore, 'newScore': newScore, 'oldLevel': oldLevel, 'newLevel': newLevel},
      );
    } catch (e) { debugPrint('[M7][Achievement] region_pacified grant 실패: $e'); }
  }
  ```
- `band_achievement_templates` 신규 7행 INSERT (Supabase 마이그레이션 — 본 spec 적용 시 함께):

| template_id | category | name | description | hook_type | hook_value |
|------------|---------|------|------------|-----------|-----------|
| region_pacified:region_3 | region_pacified | 더스트플레인의 안식 | 폐광의 그늘이 걷혔다. | region_state_transition | region_3_first_peaceful |
| region_pacified:region_31 | region_pacified | 도적길 평정자 | 도적의 흔적이 사라졌다. | region_state_transition | region_31_first_peaceful |
| region_pacified:region_127 | region_pacified | 변방 해안의 친우 | 유목민의 인사를 받았다. | region_state_transition | region_127_first_peaceful |
| region_pacified:region_9 | region_pacified | 외곽 숲의 사냥꾼 | 야수의 울음이 잦아들었다. | region_state_transition | region_9_first_peaceful |
| region_pacified:region_10 | region_pacified | 풍신 숲의 매듭 | 바람의 자취를 따라잡았다. | region_state_transition | region_10_first_peaceful |
| region_pacified:region_146 | region_pacified | 회색 늪지의 빛 | 안개가 걷힌 자리에 빛이 들었다. | region_state_transition | region_146_first_peaceful |
| region_pacified:region_38 | region_pacified | 부서진 요새의 영웅 | 옛 서약이 매듭지어졌다. | region_state_transition | region_38_first_peaceful |

- hook_type=`region_state_transition`은 M6 페이즈 4 #1 6 hook에 7번째로 의미 부여. **AchievementService 코드에서는 hook_type별 분기 로직 없음** — template_id 매칭만으로 grant 수행 (M6 grant() 기존 동작 유지). hook_type은 운영 도구 표시·디버그 용도.
- `payload` 필드는 grant() 메서드 4번째 인자로 전달 (M6 settlement_trust_belonging:region_X 호출 시점 패턴 그대로).
- `AchievementUnlockedDialog` (M6 페이즈 4 #1) — high priority 자동 발동 (변경 없음).

#### FR-8: decay 메커니즘 (gameTickProvider 분기)

- `gameTickProvider` (1초 stream) 내부에서 매 틱마다 다음 분기 추가:
  - 정적 Map<int, DateTime> `_lastDecayCheckedAt` (RegionStateRepository 내부 필드)에서 lastDecayCheck 시각 조회. 초기값 또는 미접근 시 `DateTime.now()` 기록.
  - 매 60초마다(매 틱 부담 회피, 60틱 카운터) M7 7리전 [3, 31, 127, 9, 10, 146, 38]에 대해 RegionState 조회.
  - dangerScore < 0 이고 `(now - lastDecayCheck).inHours >= 12` 인 region에 대해 `addDangerScore(regionId, +1, 'decay')` 호출. lastDecayCheck 갱신.
- decay 적용 시점에 dangerLevel 전이가 발생할 수 있음 — 정상 처리 (addDangerScore 내부에서 자동 처리).
- 시간 가속 적용 — gameTickProvider는 이미 시간 가속 기반이므로 자연스럽게 가속 적용됨.
- **M7 MVP에서 decay 활성** (페이즈 2 #2 확정 N=12시간). M8+ 영역 외에도 일반 세션(4~6시간)에서는 영향 0이라 학습 부담 없음.

### 2.2 데이터 요구사항

#### Hive 박스 / 모델

- **`RegionState`** (typeId 8): HiveField 8·9·10 신규 추가
  - `int? dangerScore` (HiveField 8)
  - `int? dangerLevel` (HiveField 9)
  - `List<String> unlockedFlags` (HiveField 10)
- **`ActivityLogType`** enum (typeId 6): HiveField 32·33 추가
  - `regionDangerLevelChanged` (HiveField 32)
  - `regionUnlockedFlagToggled` (HiveField 33)
- build_runner 재실행: `region_state_model.g.dart`, `activity_log_model.g.dart`
- CLAUDE.md typeId·HiveField 표 갱신: RegionState 다음 HiveField 7→11, ActivityLogType 32→34

#### Supabase 정적 데이터

- `band_achievement_templates` 테이블 INSERT 7행 (FR-7 표).
- region_discoveries 변경 없음 (페이즈 3 #3에서 이미 적용).
- quest_pools 신규 3 컬럼 (`region_state_effect`/`region_state_required`/`region_state_excluded`)은 본 spec **범위 외** — 페이즈 4 #2 spec에서 ALTER + 36행 INSERT 마이그레이션 (`Docs/content-data/m7_quest_pools_state.sql`).

#### 신규 enum / 클래스

- `DangerLevel` enum (코드 전용, Hive 직렬화 안 함): `core/constants/danger_level.dart` 또는 `features/investigation/domain/danger_level.dart`.
- `DangerLevelChangedEvent` 클래스: `features/investigation/domain/danger_level_changed_event.dart` (TrustLevelUpEvent 패턴 답습).
- `RegionStateChangedDialog` 위젯: `core/widgets/region_state_changed_dialog.dart` (SettlementTrustUpDialog 패턴 답습).

#### 밸런스 수치 (페이즈 2 #2 확정)

- 4단계 임계값: stable -100~-50, peaceful -49~-1, tension 0~+49, threat +50~+100
- 트리거 점수 변동: oneshot 등급 4종 (-10~-15/-20~-25/-30~-40/-50)
- cumulative: 회당 -10, cap -50, cap 도달 시 단발 -10 보너스 (총 -60)
- decay 시간 N=12시간

### 2.3 UI 요구사항

#### RegionStateChangedDialog

- **화면 진입 조건**: `dangerLevelChangedProvider`에 `event != null && event.isBigTransition` 발생 시 `app.dart` ref.listen → `dialogQueue.enqueue(regionStateChanged, payload)` → 큐 head 도달 시 자동 표시.
- **위젯 계층**: `AlertDialog` (Material 3 기본) > `Column(mainAxisSize: min)` > [Text(타이틀) + SizedBox + Text(본문) + 위업 발급 시 추가 Text] + `actions: [TextButton('확인')]`.
- **상태 변수**: 없음 (read-only payload만 표시).
- **화면 전환**: `Navigator.push` 대신 dialogQueue 큐 패턴. dismiss 시 큐가 자동 head 갱신.
- **CLAUDE.md 제약**: `dismiss는 큐의 책임이므로 builder/onDismiss 콜백에서 state 리셋 금지`. `enqueue(...)` 직후 즉시 `dangerLevelChangedProvider.notifier.state = null` 리셋 (이벤트 채널 패턴).
- **연출**: 기본 fade-in (Material AlertDialog 기본). 별도 애니메이션 없음.

#### MovementScreen (페이즈 4 #3 spec 영역 — 본 spec 범위 외)

- 본 spec은 RegionState 데이터 모델·서비스만 다룸. region 카드 dangerLevel 색상 표시 등 UI는 페이즈 4 #3 spec.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | HiveField 8·9·10 추가 + getter | FR-1 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | addDangerScore/toggleFlag/hasFlag/getOrCreateRegionState 메서드 4종 추가 + lastDecayCheck Map | FR-3, FR-4d |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | ActivityLogType enum HiveField 32·33 추가 | FR-6 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.regionStateChanged 신규 키 추가 + builder 분기 | FR-5 |
| `band_of_mercenaries/lib/app.dart` | dangerLevelChangedProvider ref.listen + dialogQueue enqueue | FR-5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | quest 완료 trailing 호출 추가 (페이즈 4 #2 데이터 준비 후 활성) | FR-4a |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | completeChain() trailing — chain_id → region dangerScore 변동 + flag toggle | FR-4b |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `_applyCompletionResult` 엘리트 분기 — flag toggle + delta 적용 | FR-4c |
| `band_of_mercenaries/lib/core/providers/timer_provider.dart` (또는 gameTickProvider 위치) | decay 분기 — 60틱 카운터 + 7리전 체크 | FR-4d |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/danger_level.dart` | `DangerLevel` enum + `resolveLevel(int)` 함수 + 변환 헬퍼 (FR-2) |
| `band_of_mercenaries/lib/features/investigation/domain/danger_level_changed_event.dart` | `DangerLevelChangedEvent` 페이로드 클래스 (FR-5) |
| `band_of_mercenaries/lib/features/investigation/domain/danger_level_changed_provider.dart` | `dangerLevelChangedProvider` StateProvider (FR-5) |
| `band_of_mercenaries/lib/core/widgets/region_state_changed_dialog.dart` | `RegionStateChangedDialog` 위젯 (FR-5) |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_flag_descriptions.dart` | flag_description 매핑 8쌍 + 헬퍼 함수 (FR-6) |
| `band_of_mercenaries/lib/features/investigation/domain/chain_region_state_mapping.dart` | chain_id → (regionId, delta, flag) 매핑 5쌍 (FR-4b) |
| `band_of_mercenaries/lib/features/investigation/domain/elite_region_state_mapping.dart` | elite_id → (regionId, delta, flag) 매핑 1쌍 (FR-4c, 추후 확장) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | HiveField 8·9·10 추가 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType HiveField 32·33 추가 |

`dart run build_runner build` (또는 watch) 1회 실행 필요.

### 3.4 관련 시스템

- **M3 region-transform**: 영향 없음. `sectorChanges` (HiveField 3)와 신규 필드(8·9·10) 분리 저장. 페이즈 1 #2 5.1절 권장된 transform → dangerScore -10 약한 영향은 **M7 MVP에서 미적용** (over-engineering 회피).
- **M4 settlement-trust**: region 3에 공존, 독립 작동. addSettlementTrust와 addDangerScore가 같은 RegionState를 수정하므로 save() 순서 주의 (서로 다른 필드라 충돌 없음).
- **M5 firstAcquiredMaterialIds**: HiveField 7과 unlockedFlags(HiveField 10) 분리. addAcquiredMaterial과 toggleFlag는 독립 메서드.
- **M6 위업·칭호 시스템**: AchievementService.grant 기존 메서드 재사용. band_achievement_templates 7행 INSERT만 추가.
- **QuestGenerator**: 본 spec 범위 외 (페이즈 4 #2). 단, FR-4a의 trailing 호출은 페이즈 4 #2 quest_pools ALTER 후 활성.
- **인프라 단계 시스템**: 본 spec 범위 외 (페이즈 4 #4). FR-4e의 toggleFlag 내부 trailing hook 호출 지점만 명세.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `RegionStateRepository.addSettlementTrust()` (region_state_repository.dart:145~280) — clamp + 단계 재계산 + 통과 단계 보상 합산 + ActivityLog + Provider publish + ref.read AchievementService.grant fail-soft 패턴. **addDangerScore는 본 메서드를 답습** (보상 합산 부분 제외, 점수 변동·level 전이·publish·ActivityLog·hook 동일).
- `TrustLevelUpEvent` (features/investigation/domain/trust_level_up_event.dart) — payload 클래스 구조. **DangerLevelChangedEvent는 동일 패턴 답습**.
- `settlementTrustLevelUpProvider` — StateProvider 채널. **dangerLevelChangedProvider는 동일 패턴 답습**.
- `SettlementTrustUpDialog` (core/widgets/settlement_trust_up_dialog.dart) — AlertDialog + 확인 버튼 1개 + ref.listen 자동 dismiss. **RegionStateChangedDialog 동일 패턴 답습**.
- `DialogTypeRegistry.settlementTrustUp` (dialog_queue_provider.dart:24) — String 키 상수 + builder switch case. **regionStateChanged 동일 패턴 답습**.
- `AchievementService.grant()` 호출 패턴 (region_state_repository.dart:264~273) — try-catch fail-soft + payload Map. **본 spec FR-7 동일 패턴 답습**.
- `RegionStateRepository.addAcquiredMaterial()` (region_state_repository.dart:78~89) — 멱등 List<String> 추가 패턴. **toggleFlag 동일 패턴 답습**.

### 4.2 주의사항

- **CLAUDE.md 다이얼로그 큐 패턴**: `enqueue(...)` 직후 즉시 `xxxProvider.notifier.state = null` 리셋. dismiss는 큐의 책임이므로 builder/onDismiss에서 state 리셋 금지. dialog_queue_provider.dart `_setupListeners()` 내 패턴 답습.
- **gameTickProvider 비용**: 매 틱(1초) 7리전 RegionState 조회는 과부담. **60틱 카운터 또는 5초 간격 throttle** 권장 — addDangerScore는 동기 메서드 아닌 async이므로 큐잉 회피.
- **dangerLevel 전이 알림 빈도**: 페이즈 2 #2 시뮬레이션 결과 8시간 동안 큰 전이 1회만 발생. 페이즈 1 #2 6.2절 "큰 전이만 dialog" 기준 명확히 지킬 것.
- **AchievementService.grant() 멱등성**: 이미 보유한 위업 재발급 시 자동 skip (M6 페이즈 4 #1 hasAchievement 사전 체크). region_pacified:region_X는 첫 peaceful 진입 시점에만 한 번 발급되도록 보장.
- **build_runner 실행 시점**: HiveField 추가 후 반드시 `dart run build_runner build --delete-conflicting-outputs` 실행. 누락 시 Hive 직렬화 오류.
- **CLAUDE.md typeId·HiveField 표 갱신**: 본 spec 적용 후 RegionState 다음 HiveField 11, ActivityLogType 다음 HiveField 34 명시.
- **트랜잭션 순서**: RegionStateRepository.addDangerScore() 내부에서 save() → publish → ActivityLog → hook 순서 (TrustLevelUpEvent 패턴 답습).

### 4.3 엣지 케이스

- **dangerScore clamp 경계**: -100 또는 +100에서 추가 delta 적용 시 변경 없음. 단, 이전과 동일한 값이라도 publish는 안 함 (dangerLevel 변화 없으면).
- **RegionState 미존재 시 addDangerScore**: `getOrCreateRegionState()` 통해 신규 RegionState 생성 후 진행. dangerScore=0, dangerLevel=2 (peaceful)부터 시작.
- **toggleFlag 멱등**: 이미 unlockedFlags에 있으면 false 반환 + ActivityLog 미발급 + hook 미평가.
- **decay 충돌**: addDangerScore가 동시에 호출되면 (사용자 사건 + decay 자동) Hive box 직렬화에서 race 가능. dart는 단일 스레드이므로 실질 충돌 없음. 단 lastDecayCheck Map 갱신은 동기 보장.
- **dangerLevel 큰 전이 판정 정확성**:
  - stable(1) → tension(3) = 2단계 = 큰 전이 ✅
  - peaceful(2) → threat(4) = 2단계 = 큰 전이 ✅
  - stable(1) → peaceful(2) = 1단계 = 가벼운 전이 (단, stable 이탈이므로 큰 전이로 분류? — 페이즈 1 #2 6.2절 권장: "stable ↔ tension, stable ↔ threat, peaceful ↔ threat" 명시. stable ↔ peaceful은 가벼운 전이로 분류)
  - 본 spec 채택: `(from == stable || to == stable) && abs(from - to) >= 2 || (from == threat || to == threat) && abs(from - to) >= 2` 또는 단순화 `(from.index - to.index).abs() >= 2`
- **chain_m7_mist_clearing 트리거 시점**: 페이즈 3 #5 SQL이 페이즈 4 #4 적용 전까지 chain 데이터 미존재. 본 spec FR-4b의 chain trailing 호출 시 `chain_id == 'chain_m7_mist_clearing'` 분기는 chain 데이터 적용 후 활성. 미존재 상태에서 호출되어도 fail-soft (try-catch).
- **settlement_3_pyegwang_reopen 이중 보상**: region 3에 settlement_trust(+100, level 4) + dangerScore(-30) 동시 적용. 두 시스템 모두 region 3 RegionState 수정 → 한 save() 호출에서 두 필드 동시 갱신 권장 (트랜잭션 일관성).
- **App 재시작 시 lastDecayCheck Map 리셋**: 정적 Map은 앱 재시작 시 리셋되어 모든 region의 decay 카운터가 reset. M7 MVP에서는 무방 (실시간 12시간 미접속 후 첫 재방문 시 즉시 +1 decay). M8+ 필요 시 RegionState에 lastDangerScoreDecayAt HiveField 추가 검토.

### 4.4 구현 힌트

- **진입점**: 
  - 사건 트리거: `QuestCompletionService.completeQuest()` / `ChainQuestService.completeChain()` / `_applyCompletionResult` 엘리트 분기 / gameTickProvider 60틱 분기
  - 이벤트 채널: `dangerLevelChangedProvider` (StateProvider, app.dart ref.listen)
  - 다이얼로그: dialogQueueProvider (큐 패턴)
- **데이터 흐름**:
  1. 사건 발생 → `RegionStateRepository.addDangerScore(regionId, delta, source)` 호출
  2. clamp + level 재계산 + save()
  3. level 전이 발생 시 isBigTransition 판정
  4. ActivityLog `regionDangerLevelChanged` 추가
  5. 첫 peaceful 진입(`oldScore >= 0 && newScore < 0`) 시 AchievementService.grant('region_pacified:region_X') fail-soft trailing
  6. isBigTransition=true이면 dangerLevelChangedProvider.notifier.state = event
  7. app.dart ref.listen → dialogQueueProvider.enqueue('regionStateChanged', payload) → state=null 리셋
  8. dialogQueue head 도달 → RegionStateChangedDialog 표시
- **참조 구현**:
  - region_state_repository.dart:145~280 — addSettlementTrust 메서드 (단계 재계산·publish·ActivityLog·hook 통합 패턴)
  - features/investigation/domain/trust_level_up_event.dart — TrustLevelUpEvent 페이로드 클래스
  - core/widgets/settlement_trust_up_dialog.dart — AlertDialog 패턴
  - dialog_queue_provider.dart:15~30, 156~186 — DialogTypeRegistry 키 + builder switch case
  - app.dart:48 + ref.listen — settlementTrustUpProvider 패턴
- **확장 지점**:
  - chain_id → region 매핑: `chain_region_state_mapping.dart` Map<String, ({int regionId, int delta, String flag})>
  - elite_id → region 매핑: `elite_region_state_mapping.dart` 동일 형식
  - flag → description 매핑: `region_state_flag_descriptions.dart` Map<String, String>

## 5. 기획 확인 사항

- **[Q-1] M3 region-transform 발생 시 dangerScore -10 약한 영향 적용 여부** → 페이즈 1 #2 5.1절 권장이었으나 본 spec **미적용** (over-engineering 회피). 페이즈 4 #2 또는 M8+ 재검토.
- **[Q-2] gameTickProvider decay 카운터 위치** → RegionStateRepository 내부 정적 `Map<int, DateTime> _lastDecayCheckedAt`. RegionState HiveField 추가는 M8+ 영역.
- **[Q-3] hook_type 'region_state_transition' 운영 도구 표시 여부** → band_achievement_templates 테이블에 hook_type 컬럼이 이미 있는 경우 그대로 활용. 없으면 본 spec 7행 INSERT 시 hook_type 컬럼 추가 검토 — 페이즈 4 #1 spec 적용 시점에 결정.
- **[Q-4] AchievementService callback DI 7번째 추가 여부** → 본 spec 권장: **추가하지 않음**. `RegionStateRepository.addDangerScore()` 내부에서 직접 호출 (region_state_repository.dart:264 settlement_trust_belonging 패턴 동일). M6 페이즈 4 #1 AchievementService 코드 변경 회피.
- **[Q-5] flag → region 매핑의 코드 vs DB 위치** → 본 spec 채택: **코드 (Dart Map 상수)**. 8 flag는 페이즈 1 #2에서 영속 정의된 enum 수준. 운영 도구 편집 불필요. M9+ 확장 시 DB 이동 검토.
- **[Q-6] chain 완주 trailing fail-soft 대상에 settlement_3_pyegwang_reopen 포함 여부** → 본 spec 포함: chain_id prefix `settlement_` 분기에서 region 3, -30, flag `region_3_pyegwang_reopen_completed` 매핑 적용. M4 settlement_trust 시스템과 별개로 dangerScore 변동 (페이즈 1 #2 5.2절 의도된 이중 작동).
- **[Q-7] decay N=12시간 활성/비활성** → 페이즈 2 #2 4절 권장 N=12 활성. 일반 4~6시간 세션에서 영향 0이라 학습 부담 없음. M7 MVP 활성 채택.
- **[Q-8] isBigTransition 판정 식** → 본 spec 채택: `(from.index - to.index).abs() >= 2 || (from == DangerLevel.stable) ^ (to == DangerLevel.stable) || (from == DangerLevel.threat) ^ (to == DangerLevel.threat)` (XOR — stable/threat 진입·이탈은 인접 단계라도 큰 전이). 페이즈 2 #2 시뮬레이션 정합 (8시간 1회).
