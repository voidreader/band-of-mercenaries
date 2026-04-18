# 세력 태그 + 전용 퀘스트 시스템 구현 계획 및 결과

Skill used : implement-agent

> 원본 명세서: `Docs/spec/[spec]20260418_faction-quest-system.md`
> 구현일: 2026-04-18
> 마일스톤: M1 페이즈 4 (2/4)
> 검증 모드: 풀 검증 (verifier 서브에이전트)
> 최종 판정: **PASS**

## 1. 구현 계획 요약

### 요구사항 분해

원본 명세의 FR-1~FR-11을 REQ-1~REQ-16으로 재정리했다. 사용자가 전달한 주의사항 1~8을 반영하여 다음 3가지 명세 오류를 교정했다:

- **주의사항 2:** 명세의 `PassiveBonusService.sumRewardMultiplier`는 존재하지 않는 API. 실제는 `getQuestRewardMultiplier`(반환 multiplier). `- 1.0` 변환으로 가산값을 얻는다.
- **주의사항 3:** `rankRewardBonus` 파라미터는 추가하지 않는다. `PassiveBonusService`가 이미 F→현재 랭크 효과를 `CollectedEffects`에 누적하므로 별도 파라미터 추가 시 중복 가산된다.
- **주의사항 1:** P4-1이 `quest_completion_service.dart:117`에서 `(baseRewardGold * passiveRewardMultiplier).round()` 곱셈 레이어를 적용한 상태. FR-7의 가산 상한 +0.80 clamp와 충돌하므로 곱셈 레이어를 제거하고 `calculateReward` 내부 가산으로 단일화한다.

### 사용자 확인 결과 (계획 승인 시 확정)

- Q-1: 기존 마이그레이션 파일(`20260418_m1_phase4_complete.sql`) 이미 실행됨 → TASK-1은 DB 상태 검증만 수행
- Q-2: `QuestCompletionService.calculate()`는 순수 함수 유지, `addReputation` 호출은 `quest_provider._applyCompletionResult`에서 수행
- Q-3: 탈퇴 세력도 `addReputation` 호출 허용 (기존 클램프 로직에 의존)
- Q-4: 쿨다운 맵 갱신을 `_applyCompletionResult` 내부에서 수행

### 태스크 분해

15개 태스크, 8단계 실행 순서:

- **그룹 A (병렬 6개):** TASK-1 DB 검증, TASK-2 상수 추가, TASK-3 ActiveQuest, TASK-4 QuestPool, TASK-6 Repository, TASK-7 calculateReward
- **그룹 B (순차):** TASK-5 build_runner 재생성
- **그룹 C:** TASK-8 FactionTagResolver
- **그룹 D:** TASK-9 QuestGenerator
- **그룹 E (병렬 3개):** TASK-10 QuestCompletionService, TASK-12 DispatchScreen, TASK-13 DispatchDetailPage
- **그룹 F:** TASK-11 quest_provider
- **그룹 G:** TASK-14 유닛 테스트
- **그룹 H:** TASK-15 전체 테스트 회귀

## 2. 변경 파일 목록

### 신규 생성 (4개)
| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/faction_tag_resolver.dart` | 태그 선정 정적 유틸 클래스 |
| `band_of_mercenaries/test/features/quest/domain/faction_tag_resolver_test.dart` | FactionTagResolver 10 케이스 |
| `band_of_mercenaries/test/features/quest/domain/quest_generator_exclusive_test.dart` | QuestGenerator 전용 필터 7 케이스 |
| `Docs/spec/[spec]20260418_faction-quest-system_plan.md` | 본 문서 |

### 수정 (10개)
| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/data/settings_keys.dart` | 상수 추가 | `factionQuestCooldowns` |
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | 상수 추가 | 세력 태그/쿨다운 파라미터 8개 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | 필드 추가 | `ActiveQuest` HiveField 17~19 + `isFactionExclusive` getter |
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | 필드 추가 | Freezed 필드 5개, 기존 `type` deprecated |
| `band_of_mercenaries/lib/features/info/data/faction_state_repository.dart` | 메서드 추가 | `getClueLevelsByRegion`, `getAllReputations` |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | 시그니처 확장 | `calculateReward`에 `trackBonus`/`passiveRewardBonus` + 가산 상한 +0.80 clamp |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | 시그니처 + 로직 확장 | 신규 파라미터 5+2개, 전용/일반 분리, `pool.typeId` 기반 QuestType, FactionTagResolver 호출 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 리팩토링 | 곱셈 레이어 제거 → 가산 통합, `QuestCompletionResult` 2필드 확장, 세력 평판 계산 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 호출부 + 로직 추가 | 쿨다운 헬퍼 2개, 3곳 호출부 신규 파라미터 주입, `_applyCompletionResult` 세력 평판/쿨다운 기록 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | UI 확장 | `_buildQuestCard` 세력 배지 + 전용 강조 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | UI 확장 | 상단 세력/트랙 표시 |
| `band_of_mercenaries/test/features/quest/domain/quest_generator_test.dart` | 호환 수정 | 기존 4곳 호출부에 신규 필수 파라미터 빈 값 전달 |

### 자동 재생성 (3개, build_runner)
- `band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart`
- `band_of_mercenaries/lib/core/models/quest_pool.g.dart`
- `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart`

### DB 마이그레이션 (기존 파일, 사전 적용 확인)
- `band_of_mercenaries/supabase/migrations/20260418_m1_phase4_complete.sql` — §2.1 스키마 확장 + §2.2 98행 INSERT + `data_versions` 갱신 이미 적용 확인

## 3. 핵심 설계 결정

### 3.1 보상 공식 가산 통일
`calculateReward` 시그니처에 `trackBonus = 0.0`, `passiveRewardBonus = 0.0` 파라미터를 추가하고 내부에서 `(trackBonus + passiveRewardBonus).clamp(0.0, 0.80)`를 계산한다. `QuestCompletionService`는 `passiveRewardBonus = getQuestRewardMultiplier(...) - 1.0` 변환으로 가산값을 공급하고, 기존 곱셈 레이어(`(baseRewardGold * passiveRewardMultiplier).round()`)를 완전히 제거했다. `rankRewardBonus` 파라미터는 도입하지 않았다(랭크 효과는 이미 `passiveEffects`에 포함).

### 3.2 Side Effect 분리
`QuestCompletionService.calculate()`는 순수 계산 함수를 유지한다. `FactionStateRepository.addReputation` 호출은 `quest_provider._applyCompletionResult`에서 `result.factionRepGain > 0` 조건으로 수행한다. 쿨다운 맵 기록도 동일 지점에서 `quest.isFactionExclusive` 조건으로 수행한다.

### 3.3 쿨다운 맵 저장 방식
`settings` 박스에 단일 JSON 키(`factionQuestCooldowns`)로 `{questId: ISO8601}` 맵을 저장한다. `_loadActiveCooldowns`가 호출될 때마다 `GameConstants.factionQuestCooldown = Duration(hours: 6)` 기준 lazy cleanup을 수행하고 정리된 맵을 즉시 저장한다.

### 3.4 proximityTier M1 고정
거점 시스템이 M3 이후 도입될 예정이므로 M1 범위에서는 모든 리전에 `proximityTier = 3`(10%) 기본값을 적용한다. `QuestGenerator.generateQuests`의 선택 파라미터로 노출하여 M3 이후 동적 계산 대체가 가능하다.

### 3.5 QuestType 결정 방식
기존 `questTypes[random.nextInt(questTypes.length)]` 랜덤 선택을 폐기하고 `pool.typeId` 기반 고정 조회(`firstWhere`)로 전환했다. `typeId`가 없는 기존 200행은 `@Default('raid')`로 처리된다.

## 4. 검증 결과 요약

### 자동 검증
- `flutter analyze`: **No issues found**
- `flutter test`: **231/231 PASS** (기존 214 + 신규 17)
  - `faction_tag_resolver_test.dart`: 10/10
  - `quest_generator_exclusive_test.dart`: 7/7
  - 기존 회귀 테스트 214/214 유지

### verifier 판정
- FR-1 ~ FR-11 전체 PASS
- 주의사항 1~8 전체 준수 확인
- 시그니처 일관성, Side Effect 위치, 쿨다운 관리 정합성 확인
- **최종 판정: PASS (이슈 없음)**

### DB 상태 검증 (Supabase MCP)
- `quest_pools` 5개 신규 컬럼 존재 확인
- 전용 퀘스트 98행 INSERT 확인 (총 298 = 200 + 98)
- `data_versions[quest_pools] = 2` 갱신 확인

## 5. build_runner 재실행 내역

`dart run build_runner build --delete-conflicting-outputs` 1회 실행 (974 outputs, 11s)

재생성 대상:
- `quest_model.g.dart` (Hive TypeAdapter, HiveField 17~19 대응)
- `quest_pool.g.dart` / `quest_pool.freezed.dart` (Freezed 필드 5개 대응)

## 6. CLAUDE.md 준수 여부

**위반 없음.** 모든 태스크에서 주석 최소화(한국어 단일 라인), Material 3 다크 테마, `Navigator.push` 미사용(상태 기반 렌더링), Riverpod `ref.read`/`ref.watch` 패턴, Freezed snake_case `@JsonKey` 규약을 준수했다.

## 7. 후속 작업 권장

- P4-3 (`[spec]20260418_dispatch-synergy.md`): `QuestCalculator.calculateSuccessRate`에 `partyRoles`/`roleSynergyBonus` 파라미터 추가 예정. 본 구현은 `calculateReward`만 수정했으므로 머지 충돌 없음.
- P4-4 (`[spec]20260418_rank-bonus-service.md`): `ReputationService` 랭크 보너스 로직 추가. 본 구현의 세력 평판과 독립.
- M3 거점 시스템 도입 시 `FactionTagResolver.proximityTier` 계산을 정적 3에서 동적 거리 기반으로 교체.
