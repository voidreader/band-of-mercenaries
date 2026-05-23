# 간판 용병 솔로/소수정예 의뢰 QuestGenerator 확장 구현 계획서

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260523_m8.5_flagship_solo_quests.md`
> 작성일: 2026-05-23
> 마일스톤: M8.5 페이즈 4 #2
> 실행 모드: 순차 격리 모드 (TASK ≥ 5, 11 TASK)
> 검증 모드: 각 TASK 미니 사이클(verifier+flutter-reviewer) + PHASE 3-C final integration sanity check

---

## 1. 구현 결과 요약

21개 명세 요구사항(FR-1~21)을 11 TASK로 분할하여 순차 격리 모드로 실행. 모든 TASK PASS, 통합 빌드 게이트 통과, 전체 회귀 테스트 **698/698 PASS**.

### 핵심 산출물

| 분류 | 산출물 |
|------|--------|
| **도메인 서비스** | `CombatSimulator.simulate(deathResistanceCaps)` 5계층 패스스루 + effectiveMax 단일 clamp / `QuestGenerator.computeFinalWeight()` named_weight_alpha 분기 |
| **모델/상수** | `QuestPool` freezed 2 필드(`partySizeMin`/`partySizeMax`) / `FlagshipSoloQuestConfig` 정적 상수 클래스(6 상수 + 4 매트릭스) |
| **Trailing** | `quest_provider._applyCompletionResult` 5 trailing fail-soft(카운터·실패로그·보장드랍·확률드랍·epilogue) |
| **UI** | `DispatchDetailPage` 파티 선택 강제 + 보상 미리보기 보정 / 의뢰 카드 ⭐/⭐⭐/⭐⭐⭐ 배지 |
| **enum** | `ActivityLogType.soloQuestInjuredReturn` HiveField 40 |
| **단위 테스트** | 신규 281+ 회귀 PASS, 전체 698 PASS |

---

## 2. 실행 모드 및 검증 모드

### 실행 모드: 순차 격리 (continuous execution)

- TASK 수 11개 ≥ 5 → 순차 격리 모드 적용
- 각 TASK 직후 verifier(spec) → flutter-reviewer(quality) 미니 사이클 수행
- task 사이 사용자 체크인 없음 (BLOCKED 시점만 보고 — 본 구현에서는 BLOCKED 0건)
- main이 task별 응답 전문 폐기하고 5필드 요약만 보관 → 컨텍스트 누적 방지

### 검증 모드: 3-C (final integration sanity check)

- 각 TASK는 미니 사이클에서 verifier + flutter-reviewer 두 번 검증
- 최종 통합 단계에서 flutter-reviewer 1회 추가 호출 (task 간 wiring·일관성·교차 의존만 검증)

### 검증 결과 요약

| TASK | 모델 | verifier | flutter-reviewer | 재작업 |
|------|------|----------|-----------------|--------|
| TASK-1 (QuestPool freezed) | haiku | PASS | APPROVE | 0 |
| TASK-2 (FlagshipSoloQuestConfig) | haiku | PASS | APPROVE | 0 |
| TASK-3 (ActivityLogType HiveField 40) | haiku | PASS | APPROVE | 0 |
| TASK-4 (computeFinalWeight α) | haiku | PASS | APPROVE | 0 |
| TASK-5 (QuestSortService) | sonnet | PASS | APPROVE | 0 |
| TASK-6 (CombatSimulator deathResistanceCaps) | opus | PASS | APPROVE | 0 |
| TASK-7 (QuestCompletionService cap 구성) | sonnet | PASS | APPROVE | 0 |
| TASK-9 (dispatch validation) | haiku | PASS | APPROVE | 0 |
| TASK-8 (5 trailing 통합) | opus | PASS | APPROVE | 0 |
| TASK-10 (DispatchDetailPage UI) | sonnet | PASS | APPROVE | 0 |
| TASK-11 (배지 3파일) | sonnet | PASS | APPROVE | 0 |
| **빌드 게이트 (PHASE 2.5)** | — | — | — | dart-build-resolver 1건 (home_screen.dart switch case 추가) |
| **FINAL INTEGRATION (PHASE 3-C)** | — | — | APPROVE | 0 |

- 총 재작업 횟수: 0
- 총 PHASE: 5 (PHASE 1 → 2 → 2.5 → 3 → 5단계 산출물)
- 검증자 호출 수: 22회 (TASK별 verifier×11 + flutter-reviewer×11) + final integration 1회 = 23회

---

## 3. 변경 파일 목록

### 3.1 신규 생성 (1개)

| 파일 경로 | 역할 | TASK |
|----------|------|------|
| `band_of_mercenaries/lib/features/quest/domain/flagship_solo_quest_config.dart` | `FlagshipSoloQuestConfig` 정적 상수 클래스 (6 상수 + 4 매트릭스) | TASK-2 |

### 3.2 수정 (12개)

| 파일 경로 | 변경 내용 | TASK |
|----------|----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | `partySizeMin` (@Default(1)) / `partySizeMax` (int?) freezed 필드 2개 추가 | TASK-1 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType.soloQuestInjuredReturn` (HiveField 40) 추가 | TASK-3 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `computeFinalWeight()` line 305 — `specialFlags['named_weight_alpha']` 우선 + 3.0 fallback | TASK-4 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | `_sortNamedTier`/`_partySizeGroup` 신규, sort() namedTier 정렬 교체 (솔로→소수정예→일반) | TASK-5 |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` | `simulate(deathResistanceCaps)` 시그니처 + `_runPhase1`/`_Phase1State`/`_resolveDeath`/`_evaluateDeathResist` 5계층 전파, effectiveMax 단일 clamp 통합 | TASK-6 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | `CombatSimulator.simulate()` 호출 직전 `deathResistanceCaps` 맵 구성 (DB > Config fallback) | TASK-7 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `dispatch()` `partySizeValidation` 가드 (TASK-9) + `_applyCompletionResult` 5 trailing 통합 (TASK-8: FR-10/12/19/20/21) | TASK-8, TASK-9 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | `_partySizeValid` 헬퍼, 솔로 radio + 페어/삼인행 강제 + 일반 의뢰 보존, 보상 미리보기 `named_reward_multiplier` 적용 | TASK-10 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `_resolvePartySizeLabel(QuestPool?)` 정적 헬퍼 + `_buildLayerInfo` 적용 (`partySizeLabel:` 인자 전달) | TASK-11 |
| `band_of_mercenaries/lib/core/models/dialog_request.dart` | `QuestLayerInfo.partySizeLabel: String?` 필드 + 생성자 named optional | TASK-11 |
| `band_of_mercenaries/lib/shared/widgets/quest_card_badges.dart` | `_namedBadge` 시그니처 변경 (sublabel, partySizeLabel), `_composeNamedLabel` 4분기 헬퍼 추가 | TASK-11 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | `ActivityLogType.soloQuestInjuredReturn` switch case 추가 (mercenaryStatus 모방) | dart-build-resolver |

### 3.3 코드 생성 재실행 (3개)

| 파일 경로 | 재생성 이유 |
|----------|------------|
| `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart` | `QuestPool` freezed 2 필드 추가 |
| `band_of_mercenaries/lib/core/models/quest_pool.g.dart` | `QuestPool` json_serializable 매핑 (`party_size_min` default 1, `party_size_max` nullable) |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | `ActivityLogType` HiveField 40 typeAdapter 매핑 |

---

## 4. 핵심 설계 결정

### 4.1 `deathResistanceCaps` 5계층 패스스루 (TASK-6)

`CombatSimulator`의 순수 도메인 서비스 원칙을 유지하기 위해 `simulate()` 시그니처에 `Map<String, double> deathResistanceCaps = const {}` named optional 인자를 추가하고, 5계층으로 패스스루:

```
simulate(deathResistanceCaps) → _runPhase1(required) → _Phase1State.deathResistanceCaps (final 필드)
  → _resolveDeath(state.deathResistanceCaps) → _evaluateDeathResist(c, isChainProtagonist, caps)
```

`_evaluateDeathResist`에서 `effectiveMax = math.max(perMercCap ?? baseCap, baseCap)` 단일 계산으로 chain protagonist cap(0.90)과 per-merc cap(0.95) 충돌을 해결. **솔로 체인 주인공의 effectiveMax = max(0.95, 0.90) = 0.95**로 솔로 cap 우선 보장. 기존 호출 측은 인자 미전달 → `const {}` default로 100% 호환.

### 4.2 `_applyCompletionResult` 5 trailing 통합 (TASK-8)

기존 region 카운터 trailing(line 1308~1327) 직후에 5개 독립 fail-soft 블록 삽입. **5 블록 모두 단일 `soloPool` lookup 공유** (변수 명 충돌 회피로 `pool` → `soloPool` 조정). 각 블록 독립 `try/catch + debugPrint('[FR-N] ...: $e')` 로 격리.

순서:
1. **FR-10 카운터+hook** (솔로 1인: `solo_completion_count`+1 / 대성공 시 `solo_great_success_count`+1, 페어: `pair_completion_count`, 삼인행: `small_party_count`). 매 카운터 분기마다 `mercRepo.getAll().firstOrNull`로 최신 stats 재조회 + `Map<String, int>.from` 신규 Map 병합 → race condition 방지. 칭호 hook 평가는 nested try/catch로 mercenary별 격리.
2. **FR-12 실패 메시지** (`ActivityLogType.soloQuestInjuredReturn` 발급)
3. **FR-19 보장 드랍** (`inventoryRepo.addItem`) + 중복 시 `(100 * difficulty).round()` 골드 변환
4. **FR-20 확률 드랍** (`stableSeed32('${quest.startTime?...}|${quest.id}|drop')` 결정적 시드)
5. **FR-21 epilogue** (`activityLogProvider.notifier.addLog`)

### 4.3 `QuestSortService` 3그룹 정렬 (TASK-5)

`namedTier` 풀 내부에 4 키 비교기:
1. `_partySizeGroup(partySizeMax)`: 1→0(솔로) / 2·3→1(소수정예) / null·그외→2(일반 named) 오름차순
2. `_estimatedReward` 내림차순
3. `difficulty` 오름차순
4. `id` 오름차순 (tie-breaker)

기존 `_sortByEstimatedReward`는 다른 tier(fixedTier/settlementTier/tier1/tier3/tier4)에서 계속 사용되므로 **삭제하지 않고 유지**.

### 4.4 솔로 의뢰 UI 강제 (TASK-10)

`DispatchDetailPage`에서 4 분기 동작:
- **솔로**(`partySizeMax == 1`): radio 동작 — 새 용병 선택 시 기존 자동 해제 + 토스트 `'솔로 의뢰는 1명만 파견할 수 있습니다'`
- **페어**(`partySizeMin == 2 && partySizeMax == 2`): `'정확히 2명을 선택하세요 (현재 N명)'` 안내 + 버튼 비활성
- **삼인행**(`partySizeMin == 3 && partySizeMax == 3`): 동일 패턴 3명
- **일반 의뢰**(`partySizeMax == null`): 기존 동작 유지

`_partySizeValid(QuestPool?)` 헬퍼로 [파견 출발] 버튼 활성 조건에 통합. 보상 미리보기에 `named_reward_multiplier` 곱 적용으로 실제 보상과 화면 정합.

### 4.5 배지 통합 3파일 (TASK-11)

3파일 동시 수정으로 데이터 흐름 추가:
- `QuestLayerInfo.partySizeLabel: String?` 신규 필드
- `_resolvePartySizeLabel(QuestPool?)` 정적 헬퍼 (⭐/⭐⭐/⭐⭐⭐ 결정)
- `_namedBadge(sublabel, partySizeLabel)` 시그니처 변경 + `_composeNamedLabel` 4분기 헬퍼

색상은 `AppTheme.namedAccent`(분홍 마젠타) 공유. M6 기존 named 의뢰는 `partySizeMax == null`이므로 `'✩ 지명'` 배지 그대로 유지(회귀 없음).

### 4.6 FR-17 잠금 정책 (검증만, 코드 변경 없음)

`_isNamedQuestLocked()` switch가 `title`/`flagship` hookType만 처리하고 `achievement_count`는 `default: return false`로 자동 잠금 없음. 페어/삼인행 의뢰는 `hookType == achievement_count`이므로 기존 분기로 자연 처리. 코드 변경 없이 명세 §FR-17 정합 확보.

---

## 5. PHASE 별 진행 요약

### PHASE 1: 계획 수립

- planner 1회 호출 → 11 TASK 분해 (haiku 4 / sonnet 5 / opus 2) + 의존성 그래프 + 검증 가이드 생성
- 사용자 확인 필요 Q-1(`quest_pools_party_size_check` 이름 충돌) + Q-2(마이그레이션 시점)
  - Q-1: main이 Supabase MCP `execute_sql`로 직접 검증 → 충돌 없음 ✓
  - Q-2: 코드 먼저 → 이후 마이그레이션 (사용자 동의)
- 사용자 승인 후 PHASE 2 진입

### PHASE 2: 구현 (순차 격리 모드)

- 11 TASK 단일 경로 순차 실행
  - Step 1·2·3: TASK-1·2·3 (선행 3종, 모두 haiku)
  - Step 4·5: TASK-4·5
  - Step 6: TASK-6 (opus, deathResistanceCaps 5계층 핵심)
  - Step 7: TASK-7
  - Step 8: TASK-9 (dispatch validation, TASK-8보다 먼저 — 같은 파일)
  - Step 9: TASK-8 (opus, 5 trailing 통합)
  - Step 10·11: TASK-10·11
- 각 TASK 직후 verifier+flutter-reviewer 미니 사이클
- 재작업 0건

### PHASE 2.5: 빌드 게이트

- `flutter analyze` 전체: ERROR 1건 발견 (`home_screen.dart:554` exhaustive switch에 `soloQuestInjuredReturn` 누락)
- `dart run build_runner build --delete-conflicting-outputs`: PASS (0 outputs — 모든 생성 코드가 이미 최신)
- dart-build-resolver 호출 → `home_screen.dart`에 `mercenaryStatus` 모방 case 추가 → SUCCESS
- 재검증: `flutter analyze` ERROR 0건 (INFO 1건은 본 명세 범위 외 — `combat_report_service.dart:162` 기존 코드 관련)

### PHASE 3: 검증 (3-C 통합 sanity check)

- main 직접 통합 점검: 12개 신규 시그니처의 wiring 정합 검증 → 모두 PASS
- flutter-reviewer FINAL INTEGRATION 1회 호출 → APPROVE
- 검증 영역: 3 수직 데이터 흐름(파티 크기·사망 저항 cap·배지 UI) + 5 trailing 격리 + enum cross-file 일관성 + CombatSimulator 시그니처 호환 + 회귀 위험 영역 + fail-soft 격리
- 회귀 테스트 최종 확인: **698/698 PASS**

---

## 6. 자가 점검 결과

| 점검 항목 | 결과 |
|----------|------|
| `flutter analyze` (전체) | ERROR 0건 (INFO 1건 — 본 명세 범위 외) |
| `dart run build_runner build --delete-conflicting-outputs` | SUCCESS (모든 생성 코드 최신) |
| `flutter test test/features/quest/` (도메인 회귀) | 281/281 PASS |
| `flutter test` (전체 회귀) | **698/698 PASS** |

---

## 7. CLAUDE.md 준수 사항

- **상태 기반 렌더링**: 모든 UI 변경(TASK-10·11)이 `setState` + 상태 변수 패턴, Navigator.push 없음
- **Riverpod 관용구**: `ref.read(...notifier)` / `ref.read(...repositoryProvider)` 직접 호출 패턴 일관
- **fail-soft trailing**: TASK-8 5 블록 모두 `try { ... } catch (e) { debugPrint('[FR-N] ...: $e'); }` 격리
- **시드 결정성**: TASK-8 FR-20 확률 드랍에서 `stableSeed32(...)` 사용 (Dart `hashCode` 금지 준수)
- **`avoid_print`**: `print` 사용 0건, `debugPrint`만 사용
- **freezed/json_serializable**: TASK-1·3 모두 build_runner 재생성 후 커밋 대상에 포함
- **Hive typeId 보존**: 기존 0~39 보존, 신규 40만 추가 (`ActivityLogType.soloQuestInjuredReturn`)
- **순수 도메인 서비스**: `CombatSimulator`·`QuestCompletionService`는 Hive/Provider 직접 접근 없음, 호출 측에서 데이터 주입

CLAUDE.md 금지사항 위반 없음.

---

## 8. 후속 작업 안내

### Supabase 마이그레이션 (별도 단계)

본 코드 구현은 기존 JSON 캐시(`partySizeMin=1`, `partySizeMax=null`)와 100% 호환되어 마이그레이션 이전에도 회귀 없이 빌드·테스트 가능. 마이그레이션 시점:
- `quest_pools` ALTER 2 컬럼 + CHECK `quest_pools_party_size_check` (충돌 없음 확인) + 5행 INSERT
- `titles` 4행 INSERT (`title_lone_wolf` / `title_silver_pair` / `title_three_kings` / `title_unyielding_solo`)
- `items` 2행 INSERT (`guild_artifact_lone_wolf_compass` / `guild_artifact_three_kings_seal`, `effect_json={}`)

SQL은 명세서 §부록 참고. Supabase MCP `apply_migration` 또는 SQL 에디터로 실행.

### 페이즈 4 #5 위임 검증 항목

명세 §10에 따라 페이즈 4 #5에서 실제 로그 기반 재검증:
- 솔로 #3 성공 기준 순익 550~650G
- 솔로 #3 실제 사망률 1.2~2.0%
- 솔로/소수정예 주간 순익 2,300~3,000G
- 솔로/소수정예 주간 명성 350~450
- 5~10시간 내 #2 또는 #3 첫 노출
- NamedTier 잠식(기존 M6/M8a 지명 의뢰 완전 밀림 없음)

### 커밋·아카이브

본 implement-agent 스킬은 git commit과 문서 아카이브를 수행하지 않는다. `finalize-feature` 스킬에서 일괄 처리.
