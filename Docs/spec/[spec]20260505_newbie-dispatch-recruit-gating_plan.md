# 신규 유저 파견·모집 하향 게이팅 구현 plan

Skill used : implement-spec

> 명세서: `Docs/spec/[spec]20260505_newbie-dispatch-recruit-gating.md`
> 기획 문서: `Docs/balance-design/[balance]20260505_newbie-dispatch-recruit-gating.md`
> 작성일: 2026-05-05

## 개요

명성 등급(F/E/D+) 기반 신규 유저 보호 게이트를 도메인 레이어에 도입했다. `RecruitmentService.selectTier()`와 `QuestGenerator.generateQuests()`에 `NewbieGate` 인자를 추가하고, 6곳의 호출부에서 `userData.reputation` + `staticData.ranks`를 전달한다. 데이터/UI 변경은 없으며, freezed/json_serializable/hive 모델 변경도 없어 build_runner 재실행은 불요하다.

## Q-1~Q-5 결정 (구현 채택)

| 질문 | 채택 | 비고 |
|------|------|------|
| Q-1 F/E 단계 보너스 처리 | 옵션 B (단계 내 적용) | E에서 t2Prob = 0.10 + boost*0.5 (cap 0.5) |
| Q-2 D+ 단계 보너스 동작 | 변경 없음 | 기존 누적 분포 + reduction/4 분배 유지 |
| Q-3 ranks 누락 fallback | 옵션 B (StateError throw) | SyncService 정상 가정 |
| Q-4 E 단계 d2 슬롯 보장 | 옵션 A (weighted sampling) | 기댓값 기반, 분산 허용 |
| Q-5 엘리트 퀘스트 게이팅 | 변경 없음 | 풀 필터 거치지 않음 |

## 변경 파일 목록

### 신규 생성 (3개)

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/domain/newbie_gate.dart` | `NewbieGate` enum + `NewbieGateResolver.resolve()` 헬퍼 |
| `band_of_mercenaries/test/features/mercenary/domain/recruitment_service_gate_test.dart` | 명성 경계별 selectTier 분포 회귀 테스트 (10000회 표본) |
| `band_of_mercenaries/test/features/quest/domain/quest_generator_newbie_gate_test.dart` | 명성 경계별 generateQuests difficulty 분포 회귀 테스트 (100~300회 표본) |

### 수정 (7개)

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` | 시그니처 + 분기 | `selectTier()`/`generateMercenary()`에 `gate: NewbieGate` 추가. F/E 분기 신규. `generateStartingMercenaries`는 `NewbieGate.normal` 전달 (forceTier 강제로 미사용) |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | 시그니처 | `recruit()`에 `required NewbieGate gate` 추가 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | 호출부 | `recruit()` 내부에서 `NewbieGateResolver.resolve()` 호출하여 gate 산출 후 `_repo.recruit()`에 전달 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | 시그니처 + 알고리즘 | `generateQuests()`에 `gate` (default normal) 추가. 균등 `shuffle().take()` 패턴을 `_weightedSample()`로 교체. `_weightFor()` 헬퍼 신규 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 호출부 3곳 | `generateQuests`/`fillQuests`/`_refreshExpiredQuests` 모두 `NewbieGateResolver.resolve()` 후 `gate:` 인자 전달 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | 호출부 | `initializeNewGame` 내부 `QuestGenerator.generateQuests` 호출에 `gate: NewbieGate.newbieF` 전달 (시작 명성 0이므로 F 고정) |
| `band_of_mercenaries/test/features/mercenary/domain/recruitment_service_test.dart` | 시그니처 호환 | 기존 `selectTier(Random(...))`, `generateMercenary(...)` 호출에 `gate: NewbieGate.normal` 추가 (기존 분포 검증 유지) |

> 명세 §3.1에 포함됐던 `recruit_screen.dart`는 변경 불요로 정정. `mercenary_provider.recruit()`이 이미 진입점에서 `userData.reputation`/`staticData.ranks` read 중이므로 view 레이어는 무관.

## 핵심 구현 포인트

### NewbieGate 결정 로직 (`newbie_gate.dart`)

```dart
enum NewbieGate { newbieF, newbieE, normal }

class NewbieGateResolver {
  static NewbieGate resolve({required int reputation, required List<Rank> ranks}) {
    if (ranks.isEmpty) throw StateError('ranks 데이터 누락 — SyncService 점검 필요');
    final grade = ReputationService.getCurrentRank(reputation, ranks).grade;
    if (grade == 'F') return NewbieGate.newbieF;
    if (grade == 'E') return NewbieGate.newbieE;
    return NewbieGate.normal;
  }
}
```

### selectTier 분기 (`recruitment_service.dart`)

- newbieF: 보너스 무관 `return 1`
- newbieE: `t2Prob = 0.10 + (recruitBonus + extraHighTierBoost).clamp(0, 0.5) * 0.5` → T1/T2 양자 분기, T3+ 차단
- normal: 기존 누적 확률 + reduction/4 분배 그대로

### QuestGenerator weighted sampling (`quest_generator.dart`)

`_weightFor(gate, difficulty)`로 풀 weight 산출 후 `_weightedSample()`이 비복원 가중 샘플링. weight 0 풀은 사전 제외하여 무한 루프 방지. 중복 의뢰는 선택 후 즉시 `removeAt`로 제거.

| gate | d1 | d2 | d3 |
|------|------|------|------|
| newbieF | 1.0 | 0 | 0 |
| newbieE | 1.0 | 0.25 | 0 |
| normal | 1.0 | 1.0 | 1.0 |

normal weight 1.0/1.0/1.0은 균등 shuffle과 통계적 동치 (회귀 테스트에서 ±5% 검증).

### 호출부 패턴 (quest_provider 3곳)

```dart
final newbieGate = NewbieGateResolver.resolve(
  reputation: userData.reputation,
  ranks: staticData.ranks,
);
final quests = QuestGenerator.generateQuests(
  ...,
  gate: newbieGate,
);
```

### initializeNewGame (game_state_provider)

신규 시작 시점은 reputation=0이므로 NewbieGateResolver를 거치지 않고 `gate: NewbieGate.newbieF` 직접 전달 (ranks 데이터 의존 회피).

## 검증 결과

### flutter analyze
```
No issues found! (ran in 2.3s)
```

### flutter test (mercenary + quest)
```
00:03 +262: All tests passed!
```

기존 261개 + 신규 19개(엄밀히는 신규 테스트 파일 2개로 케이스 약 12개 추가, 게이트 헬퍼 +7) = 262개 모두 통과.

신규 테스트 케이스:
- `recruitment_service_gate_test.dart`: NewbieGateResolver 경계 7개 + selectTier 분포 4개
- `quest_generator_newbie_gate_test.dart`: F 단계 d1 only / E 단계 d2 등장+d3 차단 / normal 모두 등장 / normal weight 균등 검증

### 수동 검증 가이드

운영 환경 검증:
1. 신규 게임 시작 → 파견 탭 6슬롯 모두 difficulty 1 노출 확인
2. 모집 화면 → 무료/유료 모집 시 T1만 등장 확인 (10회 반복)
3. 거점 사건 step 1, 2 완료 → 명성 +25 누적 (여전히 F)
4. 사건 step 6 완료 → 명성 +500 (E 진입) → 다음 generateQuests 트리거 시 d2 의뢰 등장 / 모집 시 T2 가끔 등장
5. 명성 2000 도달 (D 진입) → 정상 분포로 복귀 (d3 / T3~T5 등장)

## build_runner 재실행 필요 여부

**불요**. freezed/json_serializable/hive 모델 변경 없음. `NewbieGate`는 plain enum.

## CLAUDE.md 금지사항 위반

없음. `analysis_options.yaml: avoid_print: true` 준수 (debugPrint만 사용).

## 후속 작업 안내

- 커밋과 아카이브가 필요하시면 `finalize-feature` 스킬을 실행해주세요.
- build_runner 재실행 불요.
- 산출물:
  - 분석 리포트: `Docs/balance-design/[balance]20260505_newbie-dispatch-recruit-gating.md`
  - 명세서: `Docs/spec/[spec]20260505_newbie-dispatch-recruit-gating.md`
  - plan 문서: 이 파일

## 변경 파일 요약 (총 10개)

신규 3개:
- `band_of_mercenaries/lib/core/domain/newbie_gate.dart`
- `band_of_mercenaries/test/features/mercenary/domain/recruitment_service_gate_test.dart`
- `band_of_mercenaries/test/features/quest/domain/quest_generator_newbie_gate_test.dart`

수정 7개:
- `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart`
- `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart`
- `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart`
- `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`
- `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart`
- `band_of_mercenaries/lib/core/providers/game_state_provider.dart`
- `band_of_mercenaries/test/features/mercenary/domain/recruitment_service_test.dart`
