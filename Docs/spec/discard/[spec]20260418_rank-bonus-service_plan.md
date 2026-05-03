# P4-4 rank-bonus-service 구현 계획 및 결과

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260418_rank-bonus-service.md`
> 선행 구현: P4-1 (689705b), P4-2 (0ba94e3), P4-3 (커밋 대기)
> 구현 일자: 2026-04-18
> 마일스톤: M1 페이즈 4 (4/4, 마일스톤 마지막)

## 1. 수립한 구현 계획

### 13개 TASK DAG (4단계)

| 단계 | 태스크 | 설명 |
|:---:|:---|:---|
| 1 (병렬) | TASK-1 | `ReputationService.getRankChain` / `getRankLevel` 신규 |
| 1 (병렬) | TASK-2 | `ActivityLogType`에 @HiveField(13)/(14) + build_runner |
| 1 (병렬) | TASK-3 | `PassiveBonusFormatter` 17 variant 한국어 포맷 신규 |
| 1 (병렬) | TASK-4 | `RankUpEvent` + `reputationRankUpProvider` 신규 |
| 1 (병렬) | TASK-5 | `PassiveBonusContext` 헬퍼 (실제 collect 시그니처 래핑) |
| 2 (병렬) | TASK-6 | `UserDataNotifier.addReputation` 랭크업 감지 로직 추가 |
| 2 (병렬) | TASK-7 | `RankUpOverlay` AlertDialog 신규 |
| 2 (병렬) | TASK-9 | `RankBonusSummarySheet` bottom sheet 신규 |
| 2 (병렬) | TASK-11 | `RankInfoScreen` F~A 타임라인 신규 |
| 3 (병렬) | TASK-8 | `app.dart` `ref.listen<RankUpEvent?>` 등록 |
| 3 (병렬) | TASK-10 | `HomeScreen` 등급 카드 탭 가능화 + `_logIcon` case 추가 |
| 3 (병렬) | TASK-12 | `InfoScreen` `_showRank` 분기 + "명성" ListTile |
| 4 | TASK-13 | `reputation_service_test.dart` + `passive_bonus_formatter_test.dart` |

### 사용자 승인 설계 결정

- **Q-A: PassiveBonusFormatter 신규 작성 (A 채택)** — 실제 17 variant(명세 16 + stub) 모두 한국어 매핑. `UnknownPassiveEffect` fallback 포함.
- **Q-B: FR-11 완전 스킵** — `ReputationService.sumRankSuccessRateBonus` 미추가, `QuestCalculator.calculateSuccessRateBreakdown` 수정 없음. `SuccessRateBreakdown.rankBonus`는 P4-3의 `0.0 stub` 유지. 근거: `PassiveBonusService.collect()`가 이미 랭크 효과를 `CollectedEffects`에 포함하여 `factionPassiveBonus` 레이어로 집계. 별도 계산 시 이중 가산 위험.

## 2. 실제 개발 사항

### 2.1 변경 파일 목록

| 파일 | 변경 유형 | 설명 |
|:---|:---:|:---|
| `band_of_mercenaries/lib/core/domain/reputation_service.dart` | 수정 | `getRankChain` / `getRankLevel` 2개 static 메서드 추가 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | 수정 | `@HiveField(13) reputationRankUp`, `@HiveField(14) reputationRankDown` 추가 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | 수정 | `addReputation`에 랭크업 감지 + clamp + provider/log 발행 |
| `band_of_mercenaries/lib/app.dart` | 수정 | `ref.listen<RankUpEvent?>(reputationRankUpProvider)` 추가 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | 수정 | 등급 카드 `GestureDetector` 래핑 + `_logIcon`에 2 case 추가 |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | 수정 | `_showRank` 분기 + "명성" ListTile 추가 |
| `band_of_mercenaries/lib/core/providers/reputation_rank_up_provider.dart` | 신규 | `RankUpEvent` 모델 + StateProvider |
| `band_of_mercenaries/lib/core/domain/passive_bonus_context.dart` | 신규 | `collectFor` / `collectForRead` 헬퍼 |
| `band_of_mercenaries/lib/core/domain/passive_bonus_formatter.dart` | 신규 | 17 variant exhaustive switch (Dart 3 sealed class) |
| `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart` | 신규 | AlertDialog 기반 축하 오버레이 |
| `band_of_mercenaries/lib/features/home/view/rank_bonus_summary_sheet.dart` | 신규 | 누적 보너스 + 진행도 bottom sheet |
| `band_of_mercenaries/lib/features/info/view/rank_info_screen.dart` | 신규 | F~A 가로 타임라인 + 등급별 보너스 프리뷰 |
| `band_of_mercenaries/test/core/domain/reputation_service_test.dart` | 신규 | 10 tests |
| `band_of_mercenaries/test/core/domain/passive_bonus_formatter_test.dart` | 신규 | 19 tests |

### 2.2 수정하지 않은 파일 (금지사항 준수)

- `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` — **FR-11 스킵** 결정에 따라 수정 없음. P4-3 완료 상태 유지.
- `band_of_mercenaries/lib/features/quest/domain/success_rate_breakdown.dart` — `rankBonus = 0.0 stub` 주석 유지. P4-3 완료 상태 유지.
- `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart` — 기존 `collect` 시그니처 유지. P4-3에서 추가된 `getQuestSuccessRateBonusWithDetail`도 그대로.
- `band_of_mercenaries/lib/features/mercenary/domain/trait_effect_service.dart` — 변경 없음.
- Supabase 신규 마이그레이션 SQL — 생성하지 않음 (P4-1에 이미 포함).

### 2.3 주요 설계 결정

#### UserDataNotifier.addReputation (Hive 가변 필드 트릭 유지)
명세 FR-4 예시의 `state.copyWith(reputation: ...)` 패턴은 현재 `UserData` (Hive 모델)와 불호환. 실제 패턴:
```dart
state!.reputation = (state!.reputation + amount).clamp(0, 9999999);
await state!.save();
state = state;  // Riverpod 알림 트리거
```
중간에 `ReputationService.getRankLevel(state!.reputation, ranks)`로 oldLevel/newLevel 비교 삽입.

#### PassiveBonusContext 실제 시그니처 래핑
명세 FR-3의 `collect({rankChain, currentRank, joinedFactions})`은 잘못된 시그니처. 실제 P4-1 구현은 `collect({reputation, allRanks, joinedFactions})`이며 내부에서 자동 필터링. `PassiveBonusContext`는 실제 시그니처로 래핑.

#### PassiveBonusFormatter 17 variant
실제 `PassiveEffect` sealed class는 명세의 16 variant + `TraitUnlockCategoryEffect` stub = 17개. Dart 3 `switch` 표현식으로 exhaustive 보장. `UnknownPassiveEffect` fallback 포함.

#### app.dart ref.listen 패턴 (Q-7 준수)
```dart
ref.listen<RankUpEvent?>(reputationRankUpProvider, (_, next) {
  if (next == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RankUpOverlay(
        event: next,
        onDismiss: () {
          Navigator.pop(ctx);
          ref.read(reputationRankUpProvider.notifier).state = null;
        },
      ),
    );
  });
});
```
오버레이 내부 `onDismiss` 콜백이 `Navigator.pop` + provider 리셋 책임 (자기책임 원칙).

## 3. 검증 모드 및 결과

### 검증 모드
**풀 검증** (TASK 13개 ≥ 3, verifier 서브에이전트 호출)

### 검증 결과
- **판정: PASS** (1회차 통과)
- FR-1 ~ FR-10 전 항목 충족, FR-11 명시적 스킵 확인
- 금지사항 8개 모두 준수
- `flutter analyze` → `No issues found!`
- `flutter test` → **292/292 PASS** (기존 263 + 신규 29)
  - reputation_service_test: 10 tests
  - passive_bonus_formatter_test: 19 tests

## 4. build_runner 재실행 필요 파일

- `lib/core/domain/activity_log_model.dart` 수정으로 재실행 완료
  - `lib/core/domain/activity_log_model.g.dart` (재생성됨)
- 추가 build_runner 재실행 불필요

## 5. CLAUDE.md 금지사항 위반 사유

위반 없음.

## 6. 주의사항 체크리스트 (12개 준수 확인)

1. ✅ addReputation copyWith 금지, Hive 가변 필드 유지
2. ✅ PassiveBonusService.collect 실제 시그니처({reputation, allRanks, joinedFactions}) 사용
3. ✅ PassiveEffect.parseEffects 재사용, parseBonusJson 신규 작성 없음
4. ✅ PassiveBonusFormatter 17 variant 모두 구현
5. ✅ FR-11 완전 스킵, sumRankSuccessRateBonus 미추가, QuestCalculator 미수정
6. ✅ ActivityLogType HiveField 13, 14 추가, typeId 6 유지
7. ✅ app.dart 기존 ref.listen 패턴(137-184) 정확히 복제
8. ✅ InfoScreen 분기 순서 `_selectedFactionId > _showCodex > _showRank > 기본 목록`
9. ✅ reputation clamp(0, 9999999) 적용
10. ✅ staticDataProvider.valueOrNull + ranks 비어있을 시 감지 스킵
11. ✅ RankUpEvent.newEffects는 newRank.bonusJson만 파싱 (누적 X)
12. ✅ 기존 263/263 테스트 회귀 없음 (최종 292/292 PASS)
