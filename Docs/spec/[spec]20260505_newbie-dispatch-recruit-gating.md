# 신규 유저 파견·모집 하향 게이팅 개발 명세서

> 기획 문서: Docs/balance-design/[balance]20260505_newbie-dispatch-recruit-gating.md
> 작성일: 2026-05-05

## 1. 개요

명성 등급(F/E/D+)을 기반으로 신규 유저의 파견 임무 풀과 모집 티어 분포에 단계별 게이트를 적용한다. 데이터 모델 변경 없이 `RecruitmentService.selectTier()` / `QuestGenerator.generateQuests()` 두 도메인 함수의 시그니처를 확장하고, 호출부에서 `userData.reputation`과 `staticData.ranks`를 전달한다. 게이트 판정은 기존 `ReputationService.getCurrentRank().grade`로 단일화한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 모집 티어 분포 명성 게이트** — `RecruitmentService.selectTier()`
  - F 등급 (명성 0~299): T1 100% (T2~T5 차단)
  - E 등급 (명성 300~1999): T1 90% / T2 10% (T3~T5 차단)
  - D 등급 이상 (명성 2000+): 현재 분포 유지 (T1 45% / T2 30% / T3 15% / T4 8% / T5 2%)
  - 단계 판정: `ReputationService.getCurrentRank(reputation, ranks).grade`로 'F'/'E'/그 외 분기

- **[FR-2] 파견 풀 difficulty weight 게이트** — `QuestGenerator.generateQuests()`
  - F 등급: difficulty 1만 추출 (d2/d3 weight 0)
  - E 등급: d1 weight 1.0, d2 weight 0.25, d3 weight 0
  - D+ 등급: d1/d2/d3 weight 1.0/1.0/1.0 (현재 균등 분포와 동치)
  - 균등 `shuffle().take()` 패턴을 weighted sampling으로 교체

- **[FR-3] 모집 보너스 cap 강제**
  - F 단계: `recruitBonus` / `extraHighTierBoost`가 적용되어도 T2~T5로 확률이 이전되지 않음 → T1 100% 유지
  - E 단계: 보너스 효과는 T1↔T2 사이에서만 발현, T3~T5로 이전 차단
  - D+ 단계: 현재 보너스 로직 유지 (변경 없음)
  - **Q-1 결정에 따라 옵션 A(보너스 완전 무시) 또는 옵션 B(단계 내 적용) 채택**

- **[FR-4] 게이트 판정 헬퍼 — `NewbieGate` enum 도입 (권장)**
  - `core/domain/newbie_gate.dart` 신규: `enum NewbieGate { newbieF, newbieE, normal }` + `NewbieGateResolver.resolve(reputation, ranks)`
  - selectTier/generateQuests 양쪽에서 동일한 enum을 받아 분기 일관성 보장

- **[FR-5] 호출부 갱신**
  - `quest_provider.dart`의 `generateQuests` / `fillQuests` / `_refreshExpiredQuests` 3개 메서드 — `userData.reputation` + `staticData.ranks` 전달
  - `game_state_provider.dart`의 `initializeNewGame` 내부 `QuestGenerator.generateQuests` 호출 — reputation=0(F 명시) + ranks 전달
  - `mercenary_repository.dart`의 `recruit()` 메서드 — reputation/ranks 인자 추가
  - `recruit_screen.dart`의 모집 호출부 — `userData.reputation` 및 `staticData.ranks` 전달

- **[FR-6] 시작 용병 생성 영향 없음**
  - `RecruitmentService.generateStartingMercenaries`는 기존 `forceTier: random.nextBool() ? 1 : 2` 로직 유지
  - 신규 시작 시점 T1~T2 4인 파티 보장 (selectTier 경유하지 않으므로 게이트 무관)

- **[FR-7] 단위 테스트 추가**
  - 명성 0 / 299 / 300 / 1999 / 2000 경계에서 selectTier 분포 (대량 표본 통계)
  - 동일 경계에서 generateQuests의 difficulty 분포 (대량 표본 통계)
  - F/E 단계에서 보너스가 잠긴 티어로 이전되지 않음 검증

### 2.2 데이터 요구사항

- 신규/수정 Hive 박스: 없음
- 신규/수정 정적 데이터 모델: 없음 (`ranks.unlock_tier` 컬럼은 본 게이트에서 활용 안 함, 단 향후 통합 가능)
- 신규 enum: `NewbieGate { newbieF, newbieE, normal }` (FR-4)
- 밸런스 수치: 기획 문서 §6.1, §6.2 표 그대로 (가중치 0.25, 명성 임계 300/2000)

### 2.3 UI 요구사항

UI 변경 없음. 모집 화면(`recruit_screen.dart`) / 파견 화면(`dispatch_screen.dart`)은 게이트 결과만 노출되므로 별도 처리 불필요. Visual Companion 단계 생략.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` | `selectTier()` 시그니처에 `currentReputation: int` + `ranks: List<Rank>` (또는 `gate: NewbieGate`) 추가, F/E/D+ 분기 분포 적용. 보너스 cap 처리. | FR-1, FR-3 |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | `recruit()` 메서드에 reputation/ranks 인자 추가하여 selectTier로 전달 | FR-5 |
| `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart` | `mercenaryRepositoryProvider.recruit()` 호출부에 `userData.reputation`, `staticData.ranks` 전달 | FR-5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `generateQuests()` 시그니처에 `currentReputation` + `ranks` 추가. line 36~74의 풀 필터링 → 균등 take를 weighted sampling으로 교체 | FR-2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `generateQuests` (line 214 호출) / `fillQuests` (line 415 호출) / `_refreshExpiredQuests` (line 599 호출) 3곳에 reputation/ranks 전달 | FR-5 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | `initializeNewGame` 내부 `QuestGenerator.generateQuests` 호출 (line 118)에 reputation=0, ranks 전달 | FR-5 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/domain/newbie_gate.dart` | `NewbieGate` enum + `NewbieGateResolver.resolve(reputation, ranks)` 헬퍼 (FR-4) |
| `band_of_mercenaries/test/features/mercenary/domain/recruitment_service_gate_test.dart` | 명성 경계별 selectTier 분포 회귀 테스트 (FR-7) |
| `band_of_mercenaries/test/features/quest/domain/quest_generator_newbie_gate_test.dart` | 명성 경계별 generateQuests difficulty 분포 회귀 테스트 (FR-7) |

### 3.3 코드 생성 필요 파일

없음. freezed/json_serializable 모델 변경이 없고 신규 enum은 코드 생성을 요구하지 않음.

### 3.4 관련 시스템

- **모집 시스템**: 핵심 변경 대상. `RecruitmentService` 시그니처가 외부 API이므로 호출부 동시 갱신 필수.
- **파견 시스템**: `QuestGenerator` 시그니처 변경. weighted sampling은 기존 `shuffle().take()` 와 통계적으로 동치(D+ 단계)이지만 분포 회귀 테스트로 보장.
- **명성 시스템**: `ReputationService` 변경 없음. 게이트 판정에만 활용.
- **고정 의뢰 / 엘리트 퀘스트**: 게이트 무관 (4.2 주의사항 참조).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `ReputationService.getCurrentRank()` (`core/domain/reputation_service.dart:4`): 명성→grade 조회. 게이트 판정에 직접 활용.
- `ReputationService.getMaxUnlockedTier()` (`core/domain/reputation_service.dart:12`): unlock_tier 조회. 본 명세는 grade 기반 분기를 채택했지만 향후 단계 정의 변경 시 통합 후보.
- `QuestGenerator.generateQuests()` (`features/quest/domain/quest_generator.dart:35`): 풀 필터링 → 분리 → shuffle take 패턴. weight 도입 위치는 line 71 `selectedGeneralPools` 추출 직전.
- `RecruitmentService.selectTier()` (`features/mercenary/domain/recruitment_service.dart:27`): 누적 확률 비교 패턴 유지하되 단계별 확률 테이블만 분기.

### 4.2 주의사항

- **호출부 누락 금지**: `QuestGenerator.generateQuests()` 호출은 4곳, `RecruitmentService.recruit()` 진입 1곳, `generateStartingMercenaries` 1곳. 시그니처 확장 시 인자를 `required`로 추가하여 컴파일 에러로 누락 자동 검출.
- **시작 용병은 게이트 미적용**: `generateStartingMercenaries`는 `forceTier`로 강제하므로 selectTier를 거치지 않음. 본 게이트와 무관 (FR-6).
- **고정 의뢰는 게이트 미적용**: `_injectFixedSettlementQuest` 경로(`quest_provider.dart:305`)는 `QuestGenerator`를 거치지 않고 직접 `staticData.questPools`에서 inject. 사건 진행은 명성과 별개로 동작 (의도된 동작).
- **엘리트 퀘스트는 게이트 미적용**: `QuestGenerator.generateQuests` 8단계의 엘리트 spawn은 difficulty가 monster.tier로 결정되며 풀 필터링과 무관. F/E 단계라도 환경 조건 충족 시 등장 가능. 거대 박쥐 강제 spawn은 사건 step 3 시점(이미 E 진입 가능)이므로 충돌 없음.
- **D+ 단계 weight 1.0/1.0/1.0**: 균등 shuffle과 통계적으로 동치. 회귀 테스트에서 카이제곱/비율 검증으로 보장 (Q-4 옵션 A 채택 시).
- **CLAUDE.md `analysis_options.yaml: avoid_print: true`** 준수 — 로그는 `debugPrint` 사용.

### 4.3 엣지 케이스

- **명성 점프 (사건 step 6 완료 +500)**: F 등급에서 명성 0 → 500으로 점프 시 F → E 한 번에 진입. 다음 `generateQuests()` / `recruit()` 호출 시 즉시 E 단계 분포 적용. 별도 refresh 트리거 불필요 (1시간 자동 갱신 또는 위치 이동 시 재생성으로 충분).
- **명성 음수 보정**: `addReputation()` 내부 `clamp(0, 9999999)`로 음수 차단. 추가 보정 불요.
- **ranks 데이터 누락**: `staticData.ranks`가 비어있으면 `getCurrentRank()`가 `ranks.first` 호출에서 예외. SyncService 정상 동작 시 발생 불가하지만 fallback 정책 결정 필요 → **Q-3**.
- **E 단계 d2 슬롯 분산**: 가중 샘플링은 확률적이므로 6슬롯 d2가 0개로 나오는 경우도 정상 결과. 체감 일관성 vs 단순성 트레이드오프 → **Q-4**.
- **정보망 시설로 슬롯 증가**: weight 기반이므로 자동 충족. 8슬롯이면 E 단계 d2 기댓값 8 × 14.7% ≈ 1.18로 자연 증가.

### 4.4 구현 힌트

**진입점:**
- 모집: `recruit_screen.dart` → `mercenaryRepositoryProvider.recruit()` (`mercenary_repository.dart:24`) → `RecruitmentService.generateMercenary()` → `selectTier()`
- 파견: `quest_provider.dart` 3개 메서드 → `QuestGenerator.generateQuests()` / `game_state_provider.dart:118` 1곳

**데이터 흐름:**
```
userData.reputation (Hive) + staticData.ranks (Supabase 캐시)
  → ReputationService.getCurrentRank().grade
  → NewbieGateResolver.resolve()
  → NewbieGate (newbieF/newbieE/normal)
  → selectTier / generateQuests 분포 분기
```

**참조 구현:**
- `ReputationService.getCurrentRank()` (`core/domain/reputation_service.dart:4`) — 명성→grade 조회
- `RecruitmentService.selectTier()` (`features/mercenary/domain/recruitment_service.dart:27-63`) — 누적 확률 패턴
- `QuestGenerator.generateQuests()` filtered → generalPools 분리 → take (`features/quest/domain/quest_generator.dart:36-74`) — weighted sampling 도입 위치
- `quest_provider.dart:202-235` (`generateQuests`) / `quest_provider.dart:402-437` (`fillQuests`) / `quest_provider.dart:586-621` (`_refreshExpiredQuests`) — 호출부 패턴 (chain progress 인자 패턴 참조)

**확장 지점 — `NewbieGate` enum 도입:**
```dart
// core/domain/newbie_gate.dart (신규)
enum NewbieGate { newbieF, newbieE, normal }

class NewbieGateResolver {
  static NewbieGate resolve(int reputation, List<Rank> ranks) {
    if (ranks.isEmpty) return NewbieGate.normal; // Q-3 결정 시 변경
    final grade = ReputationService.getCurrentRank(reputation, ranks).grade;
    if (grade == 'F') return NewbieGate.newbieF;
    if (grade == 'E') return NewbieGate.newbieE;
    return NewbieGate.normal;
  }
}
```

**weighted sampling 의사 코드 (E 단계 기준, Q-4 옵션 A):**
```
remaining = generalPools.where((p) {
  if (gate == newbieF) return p.difficulty == 1;
  if (gate == newbieE) return p.difficulty == 1 || p.difficulty == 2;
  return true;
}).map((p) => (pool: p, weight: weightFor(gate, p.difficulty))).toList();

final selected = <QuestPool>[];
for (var i = 0; i < remainingCount; i++) {
  final total = remaining.fold(0.0, (s, e) => s + e.weight);
  if (total <= 0) break;
  var roll = random.nextDouble() * total;
  for (var j = 0; j < remaining.length; j++) {
    roll -= remaining[j].weight;
    if (roll <= 0) {
      selected.add(remaining[j].pool);
      remaining.removeAt(j); // 중복 의뢰 방지
      break;
    }
  }
}
```

**모집 분포 분기 의사 코드 (Q-1 옵션 B 채택 가정):**
```
switch (gate) {
  case newbieF:
    return 1; // 보너스 무시, T1 100%
  case newbieE:
    // 기본 T1 90% / T2 10% — 보너스는 T1↔T2 사이에서만 효과
    final t2Boost = (recruitBonus + extraHighTierBoost).clamp(0.0, 0.5);
    final t2Prob = 0.10 + t2Boost * 0.5; // 보너스 0.5 시 T2 35%
    return random.nextDouble() < t2Prob ? 2 : 1;
  case normal:
    // 기존 로직 그대로
}
```

---

## 5. 기획 확인 사항

- **[Q-1] F/E 단계 보너스 처리**
  - 옵션 A: 보너스 효과 완전 무시 (F는 T1 100% 고정, E는 90/10 고정)
  - 옵션 B: 보너스를 단계 내에서만 적용 (E 단계는 T1↔T2 사이 비율 변동, T3+ 이전 차단)
  - 분석 리포트 §6.1: "잠긴 티어가 풀리지 않도록 cap" 표현 → **옵션 B 시사**
  - **권장: 옵션 B** (보너스 시설 의미 보존)
  - → 결정 후 명세 갱신

- **[Q-2] D+ 단계 보너스 동작**
  - 현재대로 모든 보너스 적용 (변경 없음) → 권장
  - → 확인만 필요

- **[Q-3] ranks 데이터 누락 시 fallback**
  - 옵션 A: D+ (정상 분포)로 fallback (관대)
  - 옵션 B: 예외 throw (엄격, 데이터 무결성 검증)
  - **권장: 옵션 B** (SyncService 정상 동작 가정, 실패는 즉시 가시화)

- **[Q-4] E 단계 d2 슬롯 보장 vs 확률 변동**
  - 옵션 A: weighted sampling 그대로 (d2 6슬롯 평균 0.88, 0개 슬롯도 가능) → 단순
  - 옵션 B: d2 1슬롯 확정 + 나머지 5슬롯 d1 (체감 일관성)
  - 분석 리포트 §6.2는 "기댓값 0.88"로 명시 → **옵션 A 권장**
  - → 결정 후 의사 코드 채택

- **[Q-5] 엘리트 퀘스트 게이팅**
  - F/E 단계에서도 환경 조건/유니크 조건 충족 시 등장 허용 → 권장 (현재 동작 유지)
  - 거대 박쥐 강제 spawn은 사건 step 3(이미 E 진입 가능 시점) → 충돌 없음
  - → 확인만 필요
