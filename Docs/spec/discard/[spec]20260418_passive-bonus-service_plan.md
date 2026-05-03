# PassiveBonusService 구현 계획서 (산출물)

> Skill used : implement-agent
> 명세서: `Docs/spec/[spec]20260418_passive-bonus-service.md`
> 실행일: 2026-04-18
> 마일스톤: M1 페이즈 4 (1/4)
> 최종 판정: **PASS** (verifier 재검증 통과)

---

## 1. 개요

세력 `passive_bonus_json` + 명성 `bonus_json`을 통합 스태킹하는 신규 서비스 `PassiveBonusService`를 신설하고, 7개 도메인 시스템(퀘스트/세력/명성/용병/시설/이동/방치)에 훅을 주입하여 런타임 보정값을 연결. 16개 효과 타입 카탈로그, 곱셈 하한 0.10 클램프, 공유 상한 +20%p, dispatch_slot +10 상한 등 스태킹 규칙을 구현. 밸런스 리포트의 F→A 랭크 누적 규칙을 준수.

---

## 2. 수립한 구현 계획 요약

| 단계 | 포함 TASK | 목적 |
|:----:|-----------|------|
| STEP 1 | TASK-1, TASK-2 | 신규 모델 (PassiveEffect sealed class + Rank.bonusJson 필드) |
| STEP 2 | TASK-4 | build_runner 재생성 |
| STEP 3 | TASK-5~7, 9, 11, 13a, 14, 16~18, 21, 24 | 서비스 계층 (PassiveBonusService + 시그니처 확장 + 테스트) |
| STEP 4 | TASK-8, 10, 13b, 15a, 19, 20, 22, 23 | 호출측 주입 (UI/Notifier/Provider에 수집 연결) |
| STEP 5 | TASK-12 | QuestListNotifier 연쇄 주입 |
| STEP 6 | TASK-15b | 레거시 정리 (describePassiveBonus 제거) |
| STEP 7 | TASK-26 | 전체 검증 (flutter analyze/test) |

---

## 3. 실제 개발 사항

### 3.1 신규 생성 파일 (5개)

| 파일 경로 | 역할 |
|-----------|------|
| `lib/core/models/passive_effect.dart` | Freezed sealed class 17 variants (16 + unknown fallback), 수동 `fromJson`/`parseEffects` 디스패치 |
| `lib/core/models/passive_effect.freezed.dart` | build_runner 생성 |
| `lib/core/domain/passive_bonus_service.dart` | `CollectedEffects` 래퍼 + 13개 질의 메서드 + `collect()` (F→현재 랭크 누적) |
| `lib/core/domain/rank_helper.dart` | UI 표시용 현재 랭크 조회 공용 헬퍼 |
| `lib/features/info/domain/passive_bonus_formatter.dart` | 한국어 표시 포맷터 (17 variants switch expression) |
| `test/core/domain/passive_bonus_service_test.dart` | 유닛 테스트 18개 (스태킹/상한/누적) |

### 3.2 수정 파일 (23개)

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/core/models/rank.dart` | 필드 추가 | `@JsonKey(name: 'bonus_json') @Default({}) bonusJson` |
| `lib/core/models/rank.freezed.dart`, `rank.g.dart` | 재생성 | build_runner |
| `lib/features/quest/domain/quest_calculator.dart` | 시그니처 확장 | `calculateSuccessRate`/`calculateSuccessRatePreview`에 `factionPassiveBonus = 0.0` |
| `lib/features/quest/domain/quest_completion_service.dart` | 훅 주입 | `passiveEffects` 파라미터 + 성공률/보상 배수/XP/회복시간 4개 지점 |
| `lib/features/quest/domain/quest_provider.dart` | 헬퍼 + 호출 교정 | `_collectPassiveEffects` 신규, `dispatch_slot_bonus`, `passiveRelief` 3개 전달 |
| `lib/features/facility/domain/construction_service.dart` | 시그니처 확장 | 5개 메서드에 `costMultiplier`/`timeMultiplier`/`effectBonus` |
| `lib/features/facility/view/facility_tab_screen.dart` | 주입 | PassiveBonusService 호출 + multipliers 전달 |
| `lib/features/mercenary/domain/recruitment_service.dart` | 시그니처 + 신규 | `selectTier` `extraHighTierBoost`, `effectivePaidCost` static 신규 |
| `lib/features/mercenary/domain/mercenary_provider.dart` | 주입 | `recruit()`에 passive effects 수집 및 tier boost 전달 |
| `lib/features/mercenary/data/mercenary_repository.dart` | 시그니처 확장 | `recruit()` extraHighTierBoost 전달 |
| `lib/features/mercenary/domain/trait_acquisition_service.dart` | 시그니처 + 공식 | `passiveRelief` 파라미터 + 임계값 곱셈 결합 (하한 `threshold * 0.10`) |
| `lib/features/mercenary/domain/trait_evolution_service.dart` | 시그니처 + 공식 | `checkSingleEvolutions` 공식 적용, `checkComboEvolutions` 시그니처만 (Q-5) |
| `lib/features/mercenary/view/recruit_screen.dart` | 주입 | `paidCost` 변수로 3곳 교체 |
| `lib/core/domain/idle_reward_service.dart` | 시그니처 확장 | `rateBonus`/`capBonus` 파라미터 + 공식 재작성 |
| `lib/core/domain/experience_service.dart` | 시그니처 확장 | `passiveXpBonus = 0.0` + 가산 스태킹 |
| `lib/features/movement/domain/travel_event_service.dart` | 신규 메서드 | `applyGoldLossMitigation(int, double)` |
| `lib/features/movement/domain/movement_provider.dart` | 주입 | `_applyEventEffect` 내 passive 수집 + gold_loss/damage 적용 |
| `lib/features/investigation/domain/investigation_notifier.dart` | 주입 | `_completeInvestigation` 내 `investigation_success_rate_bonus` 가산 |
| `lib/features/info/view/faction_detail_screen.dart` | 포맷터 교체 | `PassiveBonusFormatter.describe` 사용 |
| `lib/features/info/domain/faction_join_service.dart` | 레거시 제거 | `describePassiveBonus` 메서드 삭제 (27줄) |
| `lib/main.dart` | 주입 | `_checkIdleReward`에 passive 수집 및 `rateBonus`/`capBonus` 전달 |
| `test/features/info/domain/faction_join_service_test.dart` | 정리 | `describePassiveBonus` 관련 테스트 3개 삭제 (19줄) |

**총 파일 수: 5(신규) + 23(수정) = 28개** + build_runner 생성 3개

---

## 4. verifier 검증 결과 요약

### 반복 횟수

- **1차 검증**: FAIL (4 이슈 — recovery_time 곱셈 미적용, mercenary_xp 미전달, passiveRelief 미전달, describePassiveBonus 잔존)
- **수정 1회 후 재검증**: **PASS** (모든 이슈 해소)

### 수정된 이슈 목록

| # | 심각도 | 위치 | 내용 | 수정 |
|:-:|:-----:|------|------|------|
| 1 | critical | `quest_completion_service.dart:192-196` | `recovery_time_reduction` 곱셈 미적용 | `passiveRecoveryMultiplier` 추가 및 곱셈 결합 |
| 2 | critical | `quest_completion_service.dart:145` | `mercenary_xp_bonus` 미전달 | `passiveXpBonus: PassiveBonusService.getMercenaryXpBonus(passiveEffects)` 추가 |
| 3 | critical | `quest_provider.dart:_applyCompletionResult` | `passiveRelief` 3개 호출에 미전달 | `acquisitionRelief`/`evolutionRelief` 수집 후 3개 호출에 전달 |
| 4 | warning | `faction_join_service.dart:50-76` | `describePassiveBonus` 잔존 (Q-4) | 메서드 + 관련 테스트 19줄 전체 삭제 |

### 사건 기록 — git stash 충돌

구현 도중 일부 coder agent가 `git stash`를 사용하면서 **12개 TASK의 수정이 롤백**되는 사건 발생. 오케스트레이터가 파일 상태를 직접 Read로 검증 후 11개 TASK를 병렬로 **재실행**하여 복구. 이후 `git stash` 사용 금지 규칙 명시.

---

## 5. build_runner 재실행 필요 파일

- `lib/core/models/passive_effect.freezed.dart` (신규)
- `lib/core/models/rank.freezed.dart` (필드 추가 후 재생성)
- `lib/core/models/rank.g.dart` (`bonus_json` 매핑 반영)

실행 명령: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

**완료 상태**: 실행 완료, 165 outputs 생성됨.

---

## 6. CLAUDE.md 금지사항 위반

**없음.**

- Navigator.push 금지: `facility_tab_screen`, `recruit_screen`, `faction_detail_screen`, `investigation_notifier` 모두 상태 기반 렌더링 유지. `showDialog`는 허용 패턴
- 불필요한 주석 지양: 구현 시 대부분의 파일에 WHY 주석만 최소 유지
- 한국어 스타일: 모든 주석, 로그 메시지 한국어 유지 (기술 용어 제외)

---

## 7. 주요 설계 결정

### 7.1 `collect()` F→현재 랭크 누적

architect 초안에서 "currentRank만 수집"으로 제안되었으나, 밸런스 리포트의 누적 수치(A등급 = F+E+D+C+B+A 모든 보너스의 합)와 불일치. 재설계하여 `reputation + allRanks` 시그니처로 변경, 내부에서 `sortedRanks` 생성 후 `requiredReputation <= reputation`인 랭크의 `bonus_json`을 순차 누적.

### 7.2 PassiveEffect 17 variants

16개 공식 타입 + 1개 `unknown` fallback. JSON 파싱 시 알 수 없는 type은 `unknown`으로 수용하고 모든 getter에서 자동 무시 (앱 다운그레이드 호환).

### 7.3 곱셈 하한 0.10 / 공유 상한 +20%p / dispatch_slot +10

`PassiveBonusService` 내부에서 강제. 호출측은 반환값을 그대로 사용하며 추가 clamp 불필요. 5개 type(recovery/facility_time/trait_acq/trait_evo/recruitment_cost)이 곱셈 대상.

### 7.4 `checkComboEvolutions`에 `passiveRelief` 시그니처만 추가

Q-5 결정. 현재 콤보 진화는 조건 기반이 아닌 슬롯 가용성 기반이므로 내부 미사용. `// TODO(M2+): apply passiveRelief when combo evolution gains condition_json` 주석 포함.

### 7.5 `describePassiveBonus` 완전 제거

Q-4 결정. 구 flat-key 포맷 기반 메서드는 DB 스키마와 불일치로 deadcode 상태. `PassiveBonusFormatter.describe`로 완전 대체.

---

## 8. 최종 검증 수치

| 항목 | 값 |
|------|----|
| flutter analyze | No issues found! |
| flutter test | 214/214 PASS |
| PassiveBonusService 유닛 테스트 | 18 PASS |
| FactionJoinService 테스트 (정리 후) | 20 PASS |
| 기타 기존 테스트 | 176 PASS (회귀 없음) |
| 총 수정 파일 | 28개 |
| build_runner outputs | 165 |

---

## 9. 후속 명세 의존성

본 PassiveBonusService는 M1 페이즈 4의 기반 레이어로, 후속 명세 3개가 연결됨:

| 후속 | 대상 명세 | 의존 포인트 |
|-----|----------|-----------|
| P2 | `[spec]20260418_faction-quest-system.md` | `QuestCalculator.calculateReward`에 `trackBonus/passiveRewardBonus/rankRewardBonus` 가산 상한 +0.80 추가 예정 |
| P3 | `[spec]20260418_dispatch-synergy.md` | `QuestCalculator.calculateSuccessRate`에 `roleSynergyBonus` 추가 예정 (독립 상한 +10%p) |
| P4 | `[spec]20260418_rank-bonus-service.md` | `ReputationService.getRankChain`, `UserDataNotifier.addReputation`에 랭크업 감지, 축하 오버레이 UI |

`QuestCalculator` 시그니처는 P1→P2→P3 순차 구현으로 머지 충돌 회피.

---

## 10. 커밋 안내

**finalize-feature 스킬로 커밋 수행 필요.** 이 스킬은 git commit을 수행하지 않음.

변경 파일 요약 (git commit 메시지 참고):
- 신규: passive_effect / passive_bonus_service / passive_bonus_formatter / rank_helper / 유닛 테스트
- 수정: Rank 모델 / 8개 도메인 서비스 / 3개 UI 화면 / 4개 Notifier/Provider / main.dart / FactionJoinService 정리
- 삭제: `FactionJoinService.describePassiveBonus` (Q-4)
