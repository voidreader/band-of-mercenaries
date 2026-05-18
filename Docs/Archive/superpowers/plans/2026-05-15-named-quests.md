# 지명 의뢰 시스템 구현 계획 (M6 페이즈 4 #3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 칭호·위업·간판 용병 정체성 기반의 지명 의뢰 시스템을 구현하여 M6 마일스톤을 완료한다.

**Architecture:** `quest_pools` 테이블 4 컬럼 확장(M4 `is_fixed` 패턴 재사용) + `QuestGenerator` named hook 평가 + 가중치 +α=3 분기 + `QuestSortService` NamedTier 7슬롯 + 24h 쿨다운 추적 + flagship 의뢰 동결/자동 종료 + UI 차별화. 신규 테이블 0, 새 Hive 박스 0, HiveField 3개 추가 (UserData 26 / ActiveQuest 26 / ActivityLogType 31).

**Tech Stack:** Flutter · Riverpod · Hive · Supabase · freezed · json_serializable · build_runner · flutter_test

**Spec:** `Docs/Archive/20260515_M6_phase4_3_named-quests/spec.md`

**구현 컨벤션:** 본 프로젝트는 페이즈별 일괄 커밋(`finalize-feature`)을 채택하므로 각 TASK 끝에 commit하지 않고 TASK 16 통합 검증 후 단일 커밋. 단, 각 TASK 종료 시 build/test 통과를 verify한다.

---

## File Structure

### 수정 대상 (15)

| 파일 | 책임 |
|------|------|
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `namedAccent` 신규 색상 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `namedQuestTerminated` enum 추가 |
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | 4 필드 추가 (freezed) |
| `band_of_mercenaries/lib/core/models/user_data.dart` | `namedQuestCooldowns` HiveField 26 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `namedTargetMercId` HiveField 26 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | named hook 평가 + 가중치 +α 분기 + 시그니처 확장 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | NamedTier 분기 + 7슬롯 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | named 보상 배수 적용 |
| `band_of_mercenaries/lib/features/quest/data/quest_repository.dart` | 발급 시 cooldown 갱신 + namedTargetMercId 동결 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 사망 분기 + flagship 의뢰 자동 종료 + QuestGenerator 호출처 인자 주입 |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | dismiss 분기 + flagship 의뢰 자동 종료 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | named 카드 차별화 + LockOverlay |
| `band_of_mercenaries/lib/shared/widgets/quest_card_badges.dart` (탐색 시 확정) | ✩ 지명 배지 |
| `band_of_mercenaries/lib/shared/widgets/layer_sidebar.dart` (탐색 시 확정) | namedAccent 색띠 |
| `Docs/milestone-runs/M6/state.md` | 페이즈 4 #3 완료 표기 |

### 신규 생성 (5)

| 파일 | 책임 |
|------|------|
| `band_of_mercenaries/lib/features/quest/domain/named_hook_evaluator.dart` | `NamedHookContext` + `evaluateNamedHook` 정적 함수 |
| `band_of_mercenaries/supabase/migrations/20260515130000_create_named_quests.sql` | 4 컬럼 ALTER + CHECK + INDEX + 7행 INSERT + data_versions |
| `band_of_mercenaries/test/features/quest/domain/named_hook_evaluator_test.dart` | hook 평가 단위 테스트 (8 케이스) |
| `band_of_mercenaries/test/features/quest/domain/quest_sort_service_named_test.dart` | NamedTier 정렬 (3 케이스) |
| `Docs/changelog-fragments/20260515_M6_phase4_3_named-quests.md` | 릴리스 노트 단편 (finalize 시) |

### 코드 생성 필요 (5)

build_runner 1회 실행 (`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`):

- `quest_pool.freezed.dart` / `quest_pool.g.dart`
- `user_data.g.dart`
- `quest_model.g.dart`
- `activity_log_model.g.dart`

---

## Task 1: AppTheme `namedAccent` 색상 추가

**Files:**
- Modify: `band_of_mercenaries/lib/core/theme/app_theme.dart`

- [ ] **Step 1: 색상 상수 추가**

`app_theme.dart`의 chainGold 정의 아래(`chainGold` line ~59 다음)에 추가:

```dart
  // Chain quest colors
  static const Color chainGold = Color(0xFFD4AF37);           // 연계 퀘스트 금색

  // Named quest accent (M6 페이즈 4 #3 — 지명 의뢰 5계층 색상 분리)
  // chain=금 / settlement=주황 / named=분홍 / faction=세력별 / elite=주황
  static const Color namedAccent = Color(0xFFE91E63);          // 지명 의뢰 분홍 마젠타
```

- [ ] **Step 2: flutter analyze 검증**

```bash
cd band_of_mercenaries && flutter analyze lib/core/theme/app_theme.dart
```

Expected: `No issues found!`

---

## Task 2: ActivityLogType `namedQuestTerminated` enum 추가

**Files:**
- Modify: `band_of_mercenaries/lib/core/domain/activity_log_model.dart`
- Generate: `activity_log_model.g.dart`

- [ ] **Step 1: enum value 추가**

`activity_log_model.dart` line 68 (`titleUnlocked` 다음)에 추가:

```dart
  @HiveField(30)
  titleUnlocked,
  @HiveField(31)
  namedQuestTerminated,
}
```

- [ ] **Step 2: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded after Xs with N outputs`

- [ ] **Step 3: 생성 결과 verify**

`activity_log_model.g.dart`에 `31` HiveField가 enum case로 등장하는지 grep:

```bash
grep -n "31" band_of_mercenaries/lib/core/domain/activity_log_model.g.dart
```

Expected: `case 31: return ActivityLogType.namedQuestTerminated;` (또는 동등)

---

## Task 3: QuestPool freezed 모델 4 필드 추가

**Files:**
- Modify: `band_of_mercenaries/lib/core/models/quest_pool.dart`
- Generate: `quest_pool.freezed.dart` / `quest_pool.g.dart`

- [ ] **Step 1: 4 필드 추가**

`quest_pool.dart`의 마지막 필드 `minTrustLevel` (line 37) 다음에 추가:

```dart
    // 단계별 노출 제어 컬럼 (페이즈 2 #3)
    @Default(0) @JsonKey(name: 'min_trust_level') int minTrustLevel,

    // 지명 의뢰 컬럼 (M6 페이즈 4 #3)
    @Default(false) @JsonKey(name: 'is_named') bool isNamed,
    @JsonKey(name: 'named_hook_type') String? namedHookType,
    @JsonKey(name: 'named_hook_value') String? namedHookValue,
    @Default(24) @JsonKey(name: 'named_cooldown_hours') int namedCooldownHours,
  }) = _QuestPool;
```

- [ ] **Step 2: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded`

- [ ] **Step 3: 생성 파일 verify**

```bash
grep -n "isNamed" band_of_mercenaries/lib/core/models/quest_pool.freezed.dart | head -5
grep -n "is_named" band_of_mercenaries/lib/core/models/quest_pool.g.dart | head -3
```

Expected: `isNamed`가 4종 필드 모두 freezed/g.dart에 등장

- [ ] **Step 4: flutter analyze**

```bash
cd band_of_mercenaries && flutter analyze lib/core/models/quest_pool.dart
```

Expected: `No issues found!`

---

## Task 4: UserData `namedQuestCooldowns` HiveField 26 추가

**Files:**
- Modify: `band_of_mercenaries/lib/core/models/user_data.dart`
- Generate: `user_data.g.dart`

- [ ] **Step 1: 필드 추가**

`user_data.dart` line 89 (`lastDispatchProtagonistMercId` 다음)에 추가:

```dart
  /// 마지막 파견 주인공 용병 ID (nullable)
  @HiveField(25)
  String? lastDispatchProtagonistMercId;

  /// 지명 의뢰 쿨다운 추적 (M6 페이즈 4 #3)
  /// key: quest_pool_id, value: 다음 발급 가능 시각
  /// ⚠️ 기획서 HiveField 25 → 페이즈 4 #2 충돌로 26 시프트
  @HiveField(26)
  Map<String, DateTime> namedQuestCooldowns;
```

- [ ] **Step 2: 생성자에 필드 추가**

`user_data.dart`의 `UserData(...)` 생성자 매개변수 마지막에 추가:

```dart
    this.flagshipMercId,
    this.lastDispatchProtagonistMercId,
    Map<String, DateTime>? namedQuestCooldowns,
  })  : facilities = facilities ?? {},
        artifactItemIds = artifactItemIds ?? <String>[],
        completedChains = completedChains ?? <String>[],
        namedQuestCooldowns = namedQuestCooldowns ?? <String, DateTime>{};
```

- [ ] **Step 3: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded`

- [ ] **Step 4: 생성 파일 verify**

```bash
grep -n "namedQuestCooldowns" band_of_mercenaries/lib/core/models/user_data.g.dart
```

Expected: `26: namedQuestCooldowns` 라인 등장 (read + write 양쪽)

- [ ] **Step 5: 신규 유저 마이그레이션 호환 확인**

`hive_initializer.dart` 또는 UserDataNotifier 초기화 경로에서 `namedQuestCooldowns: <String, DateTime>{}` 또는 default 인자 그대로 자동 호환되는지 코드 확인. 누락 시 보강.

```bash
grep -rn "UserData(" band_of_mercenaries/lib/core/data/ band_of_mercenaries/lib/core/providers/ | grep -v "\.g\.dart"
```

기존 호출처 모두 named 인자이므로 자동 호환. 누락이면 빈 Map 명시 주입.

---

## Task 5: ActiveQuest `namedTargetMercId` HiveField 26 추가

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_model.dart`
- Generate: `quest_model.g.dart`

- [ ] **Step 1: 필드 추가**

`quest_model.dart` line 113 (`renderedNarrative` 다음, ActiveQuest 마지막 필드 위치)에 추가:

```dart
  @HiveField(25)
  String? renderedNarrative;

  /// 지명 의뢰 발급 시 발급 시점의 flagshipMercId 동결 (M6 페이즈 4 #3)
  /// flagship hook 전용 — title/achievement_count hook 의뢰는 null 유지
  @HiveField(26)
  String? namedTargetMercId;
```

- [ ] **Step 2: 생성자에 필드 추가**

`ActiveQuest({...})` 생성자 마지막 매개변수에 추가:

```dart
    this.renderedNarrative,
    this.namedTargetMercId,
  });
```

- [ ] **Step 3: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded`

- [ ] **Step 4: 생성 파일 verify**

```bash
grep -n "namedTargetMercId" band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart
```

Expected: `26: namedTargetMercId` 라인 (read + write)

---

## Task 6: NamedHookEvaluator + 단위 테스트 (TDD)

**Files:**
- Create: `band_of_mercenaries/lib/features/quest/domain/named_hook_evaluator.dart`
- Test: `band_of_mercenaries/test/features/quest/domain/named_hook_evaluator_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

`test/features/quest/domain/named_hook_evaluator_test.dart` 생성:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/named_hook_evaluator.dart';

QuestPool _namedPool({
  required String hookType,
  required String? hookValue,
}) {
  return QuestPool(
    id: 'qp_test',
    name: 'test',
    type: 1,
    difficulty: 2,
    minRegionDiff: 1,
    maxRegionDiff: 5,
    isNamed: true,
    namedHookType: hookType,
    namedHookValue: hookValue,
  );
}

Mercenary _mercWithTitles(List<String> titleIds) {
  return Mercenary(
    id: 'm1', name: 'tester', jobId: 'j1',
    str: 10, intelligence: 10, vit: 10, agi: 10,
    titleIds: titleIds,
  );
}

BandAchievement _achievement(String templateId) {
  return BandAchievement(
    id: 'ba_$templateId',
    templateId: templateId,
    type: BandAchievementType.achievement,
    achievedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('NamedHookEvaluator.evaluateNamedHook', () {
    test('title hook: 칭호 보유 mercenary 1명 이상 시 true', () {
      final pool = _namedPool(hookType: 'title', hookValue: 'title_road_hunter');
      final ctx = NamedHookContext(
        mercenaries: [_mercWithTitles(['title_road_hunter'])],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('title hook: 칭호 보유 mercenary 0명 시 false', () {
      final pool = _namedPool(hookType: 'title', hookValue: 'title_road_hunter');
      final ctx = NamedHookContext(
        mercenaries: [_mercWithTitles(['title_village_savior'])],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('achievement_count hook: count == threshold 시 true', () {
      final pool = _namedPool(hookType: 'achievement_count', hookValue: '3');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('a'), _achievement('b'), _achievement('c')],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('achievement_count hook: count < threshold 시 false', () {
      final pool = _namedPool(hookType: 'achievement_count', hookValue: '3');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('a'), _achievement('b')],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('achievement_count hook: memorial 제외 — type=memorial 카운트 안 함', () {
      final pool = _namedPool(hookType: 'achievement_count', hookValue: '2');
      final memorial = BandAchievement(
        id: 'm', templateId: 'memorial:diedQuest',
        type: BandAchievementType.memorial,
        achievedAt: DateTime(2026, 1, 1),
      );
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('a'), memorial],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('flagship hook: flagshipMercId non-null 시 true', () {
      final pool = _namedPool(hookType: 'flagship', hookValue: '');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: 'm_flagship',
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('flagship hook: flagshipMercId null 시 false', () {
      final pool = _namedPool(hookType: 'flagship', hookValue: '');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('achievement_id hook: 매칭되는 templateId 보유 시 true', () {
      final pool = _namedPool(
          hookType: 'achievement_id',
          hookValue: 'chain_completed:chain_test');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('chain_completed:chain_test')],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('unknown hook_type 시 silent false', () {
      final pool = _namedPool(hookType: 'unknown_type', hookValue: 'x');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: 'm_flagship',
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('hook_type null 시 silent false', () {
      final pool = QuestPool(
        id: 'qp_test', name: 'test', type: 1, difficulty: 2,
        minRegionDiff: 1, maxRegionDiff: 5,
        isNamed: true, namedHookType: null,
      );
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });
  });

  group('NamedHookEvaluator.isCooldownPassed', () {
    test('null 시 통과', () {
      expect(NamedHookEvaluator.isCooldownPassed(null, DateTime.now()), isTrue);
    });

    test('과거 시각 시 통과', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      expect(NamedHookEvaluator.isCooldownPassed(past, DateTime.now()), isTrue);
    });

    test('미래 시각 시 차단', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(NamedHookEvaluator.isCooldownPassed(future, DateTime.now()), isFalse);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/named_hook_evaluator_test.dart
```

Expected: 컴파일 실패 (named_hook_evaluator.dart 미존재)

- [ ] **Step 3: NamedHookEvaluator 구현**

`band_of_mercenaries/lib/features/quest/domain/named_hook_evaluator.dart` 생성:

```dart
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 지명 의뢰 hook 평가 컨텍스트. (M6 페이즈 4 #3)
///
/// `QuestGenerator`가 발급 후보 풀 평가 시 외부에서 주입한다.
/// 직접 Provider 의존을 회피하여 순수 함수 단위 테스트 가능.
class NamedHookContext {
  final List<Mercenary> mercenaries;
  final List<BandAchievement> bandAchievements;
  final String? flagshipMercId;

  const NamedHookContext({
    required this.mercenaries,
    required this.bandAchievements,
    required this.flagshipMercId,
  });
}

/// 지명 의뢰 hook 평가 헬퍼.
///
/// 4종 hook_type 단일 조건 분기:
/// - `title`: namedHookValue가 보유 mercenary titleIds에 포함되면 true
/// - `achievement_count`: BandAchievementType.achievement 카운트 >= 임계
/// - `achievement_id`: 동일 templateId 보유 시 true (M6 MVP 데이터 미사용)
/// - `flagship`: flagshipMercId non-null 시 true
///
/// 미지원/null hook_type은 silent false. (M6 MVP — 복합 조건 M9+ 위임)
class NamedHookEvaluator {
  const NamedHookEvaluator._();

  static bool evaluateNamedHook(QuestPool pool, NamedHookContext ctx) {
    final hookType = pool.namedHookType;
    if (hookType == null) return false;
    final value = pool.namedHookValue ?? '';

    switch (hookType) {
      case 'title':
        if (value.isEmpty) return false;
        return ctx.mercenaries.any((m) => m.titleIds.contains(value));
      case 'achievement_count':
        final threshold = int.tryParse(value) ?? 0;
        if (threshold <= 0) return false;
        final count = ctx.bandAchievements
            .where((a) => a.type == BandAchievementType.achievement)
            .length;
        return count >= threshold;
      case 'achievement_id':
        if (value.isEmpty) return false;
        return ctx.bandAchievements.any((a) => a.templateId == value);
      case 'flagship':
        return ctx.flagshipMercId != null;
      default:
        return false;
    }
  }

  /// 쿨다운 통과 여부. null 또는 과거 시각이면 통과.
  static bool isCooldownPassed(DateTime? nextAvailableAt, DateTime now) {
    if (nextAvailableAt == null) return true;
    return nextAvailableAt.isBefore(now);
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/named_hook_evaluator_test.dart
```

Expected: `All tests passed!` (12 케이스 — 8 hook + 3 cooldown + extra 1)

---

## Task 7: QuestGenerator named 평가 + 가중치 +α=3 분기

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`

- [ ] **Step 1: 시그니처 확장**

`generateQuests()` 인자 마지막에 추가 (line 35 `NewbieGate gate` 다음):

```dart
    NewbieGate gate = NewbieGate.normal,
    // M6 페이즈 4 #3 — 지명 의뢰 hook 평가 컨텍스트
    List<Mercenary> mercenaries = const [],
    List<BandAchievement> bandAchievements = const [],
    String? flagshipMercId,
    Map<String, DateTime> namedQuestCooldowns = const {},
  }) {
```

- [ ] **Step 2: import 추가**

`quest_generator.dart` 상단에 추가:

```dart
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/named_hook_evaluator.dart';
```

- [ ] **Step 3: generalPools 필터에 named 분기 추가**

기존 `generalPools` 필터 체인(line 50-57)에 named hook 평가 + 쿨다운 필터 추가:

```dart
    // 3. 전용/일반 분리
    final exclusivePools = filtered.where((p) => p.isFactionExclusive).toList();
    final now = DateTime.now();
    final hookContext = NamedHookContext(
      mercenaries: mercenaries,
      bandAchievements: bandAchievements,
      flagshipMercId: flagshipMercId,
    );
    final generalPools = filtered
        .where((p) => !p.isFactionExclusive)
        .where((p) => !p.isFixed)                           // REQ-03: 고정 의뢰 제외
        .where((p) => p.minTrustLevel <= currentTrustLevel) // REQ-04: 신뢰도 단계 필터
        .where((p) => sectorType != null
            ? p.sectorType == sectorType
            : p.sectorType == null)
        .where((p) {
          // M6 페이즈 4 #3 — 지명 의뢰 hook + 쿨다운 평가
          if (!p.isNamed) return true;
          if (!NamedHookEvaluator.evaluateNamedHook(p, hookContext)) return false;
          return NamedHookEvaluator.isCooldownPassed(
            namedQuestCooldowns[p.id], now);
        })
        .toList();
```

- [ ] **Step 4: `_weightedSample` 가중치 +α=3 분기 추가**

`_weightFor` 메서드는 NewbieGate 분기만 담당 — 지명 가중치는 `_weightedSample`에서 +α=3 후처리. 새로운 helper 도입 또는 `_weightedSample` 시그니처 확장. 가장 깔끔한 방법은 `_weightedSample`에 `Set<String> namedEligiblePoolIds` 인자 추가:

```dart
  static List<QuestPool> _weightedSample(
    List<QuestPool> pools,
    int count,
    NewbieGate gate,
    Random random, {
    Set<String> namedEligiblePoolIds = const {},
  }) {
    if (count <= 0) return const [];
    final weighted = <({QuestPool pool, double weight})>[];
    for (final p in pools) {
      var w = _weightFor(gate, p.difficulty);
      if (w > 0 && p.isNamed && namedEligiblePoolIds.contains(p.id)) {
        w += 3.0; // M6 페이즈 4 #3 — α=3 가중치 (페이즈 2 #2 검증)
      }
      if (w > 0) weighted.add((pool: p, weight: w));
    }
    // ... 기존 sampling 로직 그대로 ...
```

호출처(`generateQuests` 내):

```dart
    // 6. 일반 퀘스트 채우기
    final remainingCount = count - selectedExclusivePools.length;
    final namedEligibleIds = generalPools
        .where((p) => p.isNamed)
        .map((p) => p.id)
        .toSet();
    final selectedGeneralPools = _weightedSample(
      generalPools,
      remainingCount,
      gate,
      random,
      namedEligiblePoolIds: namedEligibleIds,
    );
```

(generalPools 필터에서 이미 hook+cooldown 통과한 named만 살아있으므로 별도 ID set 불필요. 단순화: `_weightedSample` 내부에서 `p.isNamed`만 검사하고 +α=3 부여. 위 코드 단순화)

**단순화된 _weightedSample**:

```dart
  static List<QuestPool> _weightedSample(
    List<QuestPool> pools, int count, NewbieGate gate, Random random,
  ) {
    if (count <= 0) return const [];
    final weighted = <({QuestPool pool, double weight})>[];
    for (final p in pools) {
      var w = _weightFor(gate, p.difficulty);
      if (w <= 0) continue;
      if (p.isNamed) w += 3.0; // M6 페이즈 4 #3 — α=3 가중치
      weighted.add((pool: p, weight: w));
    }
    // 이후 기존 비복원 가중 샘플링 그대로
    final selected = <QuestPool>[];
    for (var i = 0; i < count; i++) {
      var total = 0.0;
      for (final e in weighted) total += e.weight;
      if (total <= 0) break;
      var roll = random.nextDouble() * total;
      for (var j = 0; j < weighted.length; j++) {
        roll -= weighted[j].weight;
        if (roll <= 0) {
          selected.add(weighted[j].pool);
          weighted.removeAt(j);
          break;
        }
      }
    }
    return selected;
  }
```

- [ ] **Step 5: namedTargetMercId 동결 (flagship 의뢰 한정)**

`generateQuests` step 7 (line 109-) `for (final pool in selectedGeneralPools)` 루프 내 ActiveQuest 생성 시 namedTargetMercId 분기 추가:

```dart
    // 일반 퀘스트
    for (final pool in selectedGeneralPools) {
      // ... 기존 tag/repReward/questType 계산 ...

      // M6 페이즈 4 #3 — flagship 의뢰 namedTargetMercId 동결
      final namedTargetMercId =
          (pool.isNamed && pool.namedHookType == 'flagship')
              ? flagshipMercId
              : null;

      results.add(ActiveQuest(
        id: _uuid.v4(),
        // ... 기존 필드 ...
        specialFlags: pool.specialFlags.isEmpty
            ? null
            : Map<String, dynamic>.from(pool.specialFlags),
        namedTargetMercId: namedTargetMercId,
      ));
    }
```

- [ ] **Step 6: flutter analyze**

```bash
cd band_of_mercenaries && flutter analyze lib/features/quest/domain/quest_generator.dart
```

Expected: `No issues found!`

---

## Task 8: QuestGenerator 호출처 인자 주입

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` (또는 호출처)

- [ ] **Step 1: 호출처 식별**

```bash
grep -rn "QuestGenerator.generateQuests" band_of_mercenaries/lib/
```

Expected: `quest_provider.dart` 또는 `game_state_provider.dart` 또는 `quest_repository.dart`에서 호출

- [ ] **Step 2: 4 인자 주입 (호출처별로)**

각 호출처에서 다음 인자 추가:

```dart
QuestGenerator.generateQuests(
  // ... 기존 인자 ...
  gate: gate,
  mercenaries: ref.read(mercenaryListProvider),
  bandAchievements: ref.read(bandAchievementsProvider),
  flagshipMercId: userData.flagshipMercId,
  namedQuestCooldowns: userData.namedQuestCooldowns,
);
```

⚠️ 호출처가 순수 함수 영역(Provider 외부)이면, 호출 직전 Provider에서 값을 read하여 인자로 주입.

- [ ] **Step 3: flutter analyze 전체**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!` (named_hook_evaluator + quest_generator + 호출처 모두 통과)

---

## Task 9: QuestSortService NamedTier 분기 + 단위 테스트 (TDD)

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart`
- Test: `band_of_mercenaries/test/features/quest/domain/quest_sort_service_named_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_sort_service.dart';

QuestPool _pool({
  required String id,
  bool isNamed = false,
  bool isFactionExclusive = false,
  String? factionTag,
}) {
  return QuestPool(
    id: id, name: id, type: 1, difficulty: 2,
    minRegionDiff: 1, maxRegionDiff: 5,
    isNamed: isNamed,
    isFactionExclusive: isFactionExclusive,
    factionTag: factionTag,
  );
}

ActiveQuest _quest({required String poolId, String? factionTag, bool? isAdv}) {
  return ActiveQuest(
    id: poolId, questPoolId: poolId, questTypeId: 'raid',
    difficulty: 2, region: 1, questName: poolId,
    factionTag: factionTag, isAdvancedTrack: isAdv,
  );
}

void main() {
  final questTypes = [
    QuestType(id: 'raid', name: 'raid', baseReward: 100, durationSeconds: 600),
  ];

  test('named 1 + 일반 3 → namedTier sortedRest 최상단(settlement 다음)', () {
    final pools = [_pool(id: 'qp_named_x', isNamed: true), _pool(id: 'a'), _pool(id: 'b'), _pool(id: 'c')];
    final quests = [_quest(poolId: 'qp_named_x'), _quest(poolId: 'a'), _quest(poolId: 'b'), _quest(poolId: 'c')];
    final result = QuestSortService.sort(
      quests: quests, chainProgress: const [],
      currentRegion: 1, currentSector: 1, regionState: null,
      questPools: pools, questTypes: questTypes,
      joinedFactionIds: const {},
    );
    expect(result.sortedRest.first.questPoolId, 'qp_named_x');
  });

  test('named + faction(tier1) 혼재 → named가 faction보다 위', () {
    final pools = [
      _pool(id: 'qp_named_x', isNamed: true),
      _pool(id: 'qp_faction_x', isFactionExclusive: true, factionTag: 'f1'),
    ];
    final quests = [
      _quest(poolId: 'qp_faction_x', factionTag: 'f1', isAdv: false),
      _quest(poolId: 'qp_named_x'),
    ];
    final result = QuestSortService.sort(
      quests: quests, chainProgress: const [],
      currentRegion: 1, currentSector: 1, regionState: null,
      questPools: pools, questTypes: questTypes,
      joinedFactionIds: {'f1'},
    );
    final namedIdx = result.sortedRest.indexWhere((q) => q.questPoolId == 'qp_named_x');
    final factionIdx = result.sortedRest.indexWhere((q) => q.questPoolId == 'qp_faction_x');
    expect(namedIdx, lessThan(factionIdx));
  });

  test('named 0개 → 기존 동작 영향 없음', () {
    final pools = [_pool(id: 'a'), _pool(id: 'b')];
    final quests = [_quest(poolId: 'a'), _quest(poolId: 'b')];
    final result = QuestSortService.sort(
      quests: quests, chainProgress: const [],
      currentRegion: 1, currentSector: 1, regionState: null,
      questPools: pools, questTypes: questTypes,
      joinedFactionIds: const {},
    );
    expect(result.sortedRest.length, 2);
    expect(result.namedTier, isEmpty);
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/quest_sort_service_named_test.dart
```

Expected: `namedTier` 필드 미존재로 컴파일 실패

- [ ] **Step 3: QuestSortResult.namedTier 필드 추가**

`quest_sort_service.dart` line 9-19:

```dart
class QuestSortResult {
  final List<ActiveQuest> chainTier0;
  final List<ActiveQuest> settlementTier;
  final List<ActiveQuest> namedTier;  // M6 페이즈 4 #3
  final List<ActiveQuest> sortedRest;

  const QuestSortResult({
    required this.chainTier0,
    required this.settlementTier,
    required this.namedTier,
    required this.sortedRest,
  });
}
```

- [ ] **Step 4: sort() 분기 추가**

line 57-63에 namedTier 추가, for-loop에 isNamed 분기 추가, sortedRest 7슬롯 갱신:

```dart
    final chainTier0 = <ActiveQuest>[];
    final fixedTier = <ActiveQuest>[];
    final settlementTier = <ActiveQuest>[];
    final namedTier = <ActiveQuest>[];  // M6 페이즈 4 #3
    final tier1 = <ActiveQuest>[];
    final tier2 = <ActiveQuest>[];
    final tier3 = <ActiveQuest>[];
    final tier4 = <ActiveQuest>[];

    for (final q in quests) {
      if (poolMap[q.questPoolId]?.isFixed == true) {
        fixedTier.add(q);
        continue;
      }
      // M6 페이즈 4 #3 — 지명 의뢰는 fixed/settlement 다음, faction/elite 위
      if (poolMap[q.questPoolId]?.isNamed == true) {
        namedTier.add(q);
        continue;
      }
      if (q.isChainQuest && q.chainId != null && activeChainIds.contains(q.chainId)) {
        // ... 기존 ...
```

sort 호출 + return:

```dart
    _sortByEstimatedReward(fixedTier, poolMap, typeMap);
    _sortByEstimatedReward(settlementTier, poolMap, typeMap);
    _sortByEstimatedReward(namedTier, poolMap, typeMap);  // M6 페이즈 4 #3
    // ... 기존 ...

    return QuestSortResult(
      chainTier0: chainTier0,
      settlementTier: settlementTier,
      namedTier: namedTier,
      sortedRest: [...fixedTier, ...settlementTier, ...namedTier, ...tier1, ...tier2, ...tier3, ...tier4],
    );
```

- [ ] **Step 5: 기존 호출처 호환 확인**

`QuestSortResult`의 named 매개변수 추가로 기존 호출처 컴파일 실패 가능. 모두 grep:

```bash
grep -rn "QuestSortResult(" band_of_mercenaries/lib/ band_of_mercenaries/test/
```

각 호출처에 `namedTier: const []` 추가 (없는 경우)

- [ ] **Step 6: 테스트 실행 → 통과 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/quest_sort_service_named_test.dart
```

Expected: `All tests passed!` (3 케이스)

- [ ] **Step 7: 기존 QuestSortService 테스트 회귀 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/
```

Expected: 모든 quest domain 테스트 PASS

---

## Task 10: QuestCompletionService named 보상 배수 적용

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` 또는 `quest_calculator.dart`

- [ ] **Step 1: 보상 계산 함수 위치 식별**

```bash
grep -n "rewardGold\|baseReward" band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart | head -20
```

가장 적절한 위치(예: `QuestCompletionService.calculateReward()` 또는 `quest_provider.dart::_applyCompletionResult()`) 식별.

- [ ] **Step 2: named 배수 적용 코드 추가**

해당 위치에 적용:

```dart
// 기존: 기본 보상 × 결과 배수
int rewardGold = (baseReward * resultMultiplier).round();
int reputationGain = (baseReputation * resultMultiplier).round();

// M6 페이즈 4 #3 — 지명 의뢰 보상 배수 (칭호 효과 적용 전, 결과 배수 직후)
final pool = staticData.questPools.firstWhere(
  (p) => p.id == quest.questPoolId,
  orElse: () => questPools.first,
);
if (pool.isNamed) {
  final flags = pool.specialFlags;
  final rewardMulti = (flags['named_reward_multiplier'] as num?)?.toDouble() ?? 1.0;
  final repMulti = (flags['named_reputation_multiplier'] as num?)?.toDouble() ?? 1.0;
  rewardGold = (rewardGold * rewardMulti).round();
  reputationGain = (reputationGain * repMulti).round();
}

// 이후 칭호 효과 / 세력 효과 / 랭크 효과 적용 (기존 그대로)
```

⚠️ 적용 순서는 spec FR-11 §6.1: 기본 → 결과 배수 → **named 배수** → 칭호 → 세력 → 랭크 → 최종.

- [ ] **Step 3: flutter analyze**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!`

---

## Task 11: QuestRepository 발급 시 cooldown 갱신

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/data/quest_repository.dart` 또는 의뢰 발급 직후 호출처

- [ ] **Step 1: 발급 직후 hook 식별**

`addQuests()` 또는 `generateQuests` 호출 직후 위치 식별. 가장 자연스러운 위치는 `quest_provider.dart`의 quest 생성/저장 후.

```bash
grep -rn "addQuests\|generateQuests" band_of_mercenaries/lib/features/quest/
```

- [ ] **Step 2: cooldown 갱신 helper**

`quest_provider.dart` 또는 호출처 Notifier에서 발급 직후:

```dart
// M6 페이즈 4 #3 — 지명 의뢰 발급 시 쿨다운 갱신
final namedQuests = newQuests.where((q) {
  final pool = poolMap[q.questPoolId];
  return pool?.isNamed == true;
});
if (namedQuests.isNotEmpty) {
  final cooldowns = Map<String, DateTime>.from(userData.namedQuestCooldowns);
  for (final q in namedQuests) {
    final pool = poolMap[q.questPoolId]!;
    cooldowns[pool.id] = DateTime.now().add(Duration(hours: pool.namedCooldownHours));
  }
  await userDataNotifier.updateNamedQuestCooldowns(cooldowns);
}
```

`UserDataNotifier`에 `updateNamedQuestCooldowns(Map<String, DateTime>)` 메서드 추가:

```dart
Future<void> updateNamedQuestCooldowns(Map<String, DateTime> cooldowns) async {
  final user = state;
  if (user == null) return;
  user.namedQuestCooldowns = cooldowns;
  await user.save();
  state = user;
}
```

- [ ] **Step 3: flutter analyze**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!`

---

## Task 12: 사망/방출 시 flagship 의뢰 자동 종료

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` (사망 분기)
- Modify: `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` 또는 `mercenary_provider.dart` (dismiss 분기)

- [ ] **Step 1: 자동 종료 헬퍼 작성**

`quest_provider.dart`에 정적 또는 Notifier 메서드로 추가:

```dart
/// M6 페이즈 4 #3 — flagship 의뢰 자동 종료 헬퍼.
///
/// 진행 중/대기 중인 ActiveQuest 중 `namedTargetMercId == mercId`인 의뢰를
/// 자동 제거하고 ActivityLog 1줄 발급. dialog enqueue 없음 (조용한 종료).
Future<void> terminateNamedQuestsForMerc(String mercId) async {
  final allQuests = _questRepository.getAll();
  final terminated = allQuests
      .where((q) => q.namedTargetMercId == mercId &&
          q.status != QuestStatus.completed)
      .toList();
  for (final quest in terminated) {
    await _questRepository.removeQuest(quest.id);
    _activityLogNotifier.add(
      ActivityLog(
        timestamp: DateTime.now(),
        message: "지명 의뢰 '${quest.questName}'가 지명 용병의 부재로 종료되었다",
        type: ActivityLogType.namedQuestTerminated,
      ),
    );
  }
}
```

- [ ] **Step 2: 사망 분기에서 호출**

`quest_provider.dart` 사망 분기(`_applyCompletionResult` dead case)에 추가:

```dart
if (damageResult == DamageResult.dead) {
  // 기존: snapshot + memorial 발급 + flagship 해제
  // ...
  // M6 페이즈 4 #3 — flagship 의뢰 자동 종료
  await terminateNamedQuestsForMerc(merc.id);
}
```

- [ ] **Step 3: dismiss 분기에서 호출**

`mercenary_repository.dart::dismiss()` 또는 `mercenary_provider.dart::dismissMercenary()` snapshot 발급 직후:

```dart
Future<void> dismissMercenary(String mercId) async {
  // 기존: snapshot + memorial recordMemorial(released) + flagship 해제
  // ...
  // M6 페이즈 4 #3 — flagship 의뢰 자동 종료
  ref.read(questProviderNotifier).terminateNamedQuestsForMerc(mercId);
}
```

⚠️ 호출 위치는 코드 탐색 후 가장 자연스러운 hook에 부착. 페이즈 4 #1·#2 패턴 참조.

- [ ] **Step 4: flutter analyze**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!`

---

## Task 13: LayerSidebar / QuestCardBadges named 분기

**Files:**
- Modify: `band_of_mercenaries/lib/shared/widgets/layer_sidebar.dart` (또는 quest_card 위치)
- Modify: `band_of_mercenaries/lib/shared/widgets/quest_card_badges.dart` (또는 동등 위치)

- [ ] **Step 1: 위젯 파일 탐색**

```bash
grep -rn "class LayerSidebar\|class QuestCardBadges" band_of_mercenaries/lib/
```

- [ ] **Step 2: LayerSidebar named 색상 분기**

기존 chainGold / settlementAccent / eliteAccent 분기 직후 isNamed 분기 추가:

```dart
Color _resolveColor(QuestPool? pool, ActiveQuest quest) {
  if (quest.isChainQuest) return AppTheme.chainGold;
  if (quest.isSettlementStep) return AppTheme.settlementAccent;
  if (pool?.isNamed == true) return AppTheme.namedAccent;  // M6 페이즈 4 #3
  if (quest.isElite) return AppTheme.eliteAccent;
  // ... 기존 ...
}
```

- [ ] **Step 3: QuestCardBadges ✩ 지명 배지 추가**

기존 배지 (chain/elite/sector/faction) 컬렉션에 named 배지 추가:

```dart
if (pool?.isNamed == true) {
  final hookLabel = _resolveNamedHookLabel(pool!, ref);
  badges.add(
    _Badge(
      icon: '✩',
      label: '지명',
      sublabel: hookLabel,
      color: AppTheme.namedAccent,
    ),
  );
}

String _resolveNamedHookLabel(QuestPool pool, WidgetRef ref) {
  switch (pool.namedHookType) {
    case 'title':
      final titles = ref.read(titlesProvider);
      final title = titles.firstWhereOrNull((t) => t.id == pool.namedHookValue);
      return title != null ? '칭호 — ${title.name}' : '칭호 보유 용병 지명';
    case 'achievement_count':
      return '위업 ${pool.namedHookValue}개 이상';
    case 'flagship':
      return '간판 용병 지명';
    default:
      return '지명';
  }
}
```

- [ ] **Step 4: flutter analyze**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!`

---

## Task 14: dispatch_screen 카드 차별화 + LockOverlay

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart`

- [ ] **Step 1: 잠금 판정 헬퍼**

`dispatch_screen.dart` 또는 신규 helper에 추가:

```dart
/// M6 페이즈 4 #3 — 지명 의뢰 카드 잠금 여부.
/// hook=title: 칭호 보유 mercenary 전원 파견 중일 때 true
/// hook=flagship: namedTargetMercId 동결 mercenary가 파견 중일 때 true
/// hook=achievement_count: 잠금 무관 (false)
bool _isNamedQuestLocked(ActiveQuest quest, QuestPool pool, List<Mercenary> mercs) {
  if (!pool.isNamed) return false;
  switch (pool.namedHookType) {
    case 'title':
      final candidates = mercs
          .where((m) =>
              m.titleIds.contains(pool.namedHookValue) &&
              m.status != MercenaryStatus.dead)
          .toList();
      if (candidates.isEmpty) return false; // 매칭 없으면 풀에서 제외됨
      return candidates.every((m) => m.isDispatched);
    case 'flagship':
      final targetId = quest.namedTargetMercId;
      if (targetId == null) return false;
      final target = mercs.firstWhereOrNull((m) => m.id == targetId);
      if (target == null || target.status == MercenaryStatus.dead) return false;
      return target.isDispatched;
    default:
      return false;
  }
}
```

- [ ] **Step 2: 카드 위젯에 LockOverlay 적용**

```dart
final locked = _isNamedQuestLocked(quest, pool, mercList);
// ...
return Opacity(
  opacity: locked ? 0.4 : 1.0,
  child: AbsorbPointer(
    absorbing: locked,
    child: Card(
      // ... 기존 카드 ...
    ),
  ),
);
// 잠금 시 상단에 배지 + 탭 시 토스트 (locked: false 시 GestureDetector 무력화)
```

탭 토스트 (잠금 상태 카드 위에 별도 GestureDetector 또는 Stack):

```dart
if (locked)
  Positioned.fill(
    child: GestureDetector(
      onTap: () {
        final mercName = _resolveLockedMercName(quest, pool, mercList);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('지명 용병 $mercName이(가) 복귀해야 수행할 수 있습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    ),
  ),
```

- [ ] **Step 3: flutter analyze + 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!`

---

## Task 15: SQL Migration (4 컬럼 ALTER + CHECK + INDEX + 7행 INSERT + data_versions)

**Files:**
- Create: `band_of_mercenaries/supabase/migrations/20260515130000_create_named_quests.sql`

- [ ] **Step 1: SQL 작성**

```sql
-- M6 페이즈 4 #3 — 지명 의뢰 시스템
-- quest_pools 4 컬럼 확장 + CHECK 2 + INDEX 1 + 7행 INSERT
-- 명세서: Docs/Archive/20260515_M6_phase4_3_named-quests/spec.md §FR-1·FR-13
-- 작성일: 2026-05-15

BEGIN;

-- ============================================================
-- §FR-1 — quest_pools 4 컬럼 확장
-- ============================================================

ALTER TABLE public.quest_pools
  ADD COLUMN IF NOT EXISTS is_named BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS named_hook_type TEXT NULL,
  ADD COLUMN IF NOT EXISTS named_hook_value TEXT NULL,
  ADD COLUMN IF NOT EXISTS named_cooldown_hours INTEGER NULL DEFAULT 24;

-- CHECK 제약: hook_type 4종 enum (NULL 허용)
ALTER TABLE public.quest_pools
  DROP CONSTRAINT IF EXISTS named_hook_type_check;
ALTER TABLE public.quest_pools
  ADD CONSTRAINT named_hook_type_check
  CHECK (named_hook_type IS NULL OR
         named_hook_type IN ('title', 'achievement_count', 'achievement_id', 'flagship'));

-- CHECK 제약: is_named ↔ hook_type 일관성
ALTER TABLE public.quest_pools
  DROP CONSTRAINT IF EXISTS named_consistency;
ALTER TABLE public.quest_pools
  ADD CONSTRAINT named_consistency
  CHECK ((is_named = false AND named_hook_type IS NULL) OR
         (is_named = true AND named_hook_type IS NOT NULL));

-- 부분 인덱스 (named 행만)
CREATE INDEX IF NOT EXISTS idx_quest_pools_is_named
  ON public.quest_pools (is_named) WHERE is_named = true;

-- ============================================================
-- §FR-13 — 7행 지명 의뢰 INSERT
-- ============================================================

-- 1. 마을의 은인을 찾는다 (title hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_village_savior', '마을의 은인을 찾는다',
  3, 2, 1, 5, 'escort',
  true, 'title', 'title_village_savior', 24,
  '{"named_reward_multiplier": 1.30, "named_reputation_multiplier": 1.30, "named_description": "그 일을 해낸 사람이라면 부탁드릴 것이 있습니다..."}'::jsonb,
  '인근 마을 노인'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 2. 도적길 추적자에게 (title hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_road_hunter', '도적길 추적자에게',
  1, 3, 2, 4, 'raid',
  true, 'title', 'title_road_hunter', 24,
  '{"named_reward_multiplier": 1.40, "named_reputation_multiplier": 1.30, "named_description": "도적길에 익숙한 자가 필요하다"}'::jsonb,
  '도적단 척후병'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 3. 괴물의 흔적을 따른다 (title hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_monster_hunter', '괴물의 흔적을 따른다',
  1, 4, 2, 4, 'raid',
  true, 'title', 'title_monster_hunter', 24,
  '{"named_reward_multiplier": 1.40, "named_reputation_multiplier": 1.30, "named_description": "그 짐승의 흔적을 본 적 있는가"}'::jsonb,
  '거대 짐승'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 4. 이름 있는 용병단을 찾는다 (achievement_count hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_renowned_3', '이름 있는 용병단을 찾는다',
  2, 2, 1, 5, 'explore',
  true, 'achievement_count', '3', 24,
  '{"named_reward_multiplier": 1.30, "named_reputation_multiplier": 1.30, "named_description": "이름 있는 용병단이라 들었다"}'::jsonb,
  '미지의 영역'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 5. 전설을 들은 의뢰인 (achievement_count hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_renowned_10', '전설을 들은 의뢰인',
  1, 5, 4, 5, 'raid',
  true, 'achievement_count', '10', 24,
  '{"named_reward_multiplier": 1.50, "named_reputation_multiplier": 1.50, "named_description": "당신들의 전설을 들었다. 진위를 확인하고 싶다"}'::jsonb,
  '강력한 적'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 6. 깃대를 보고 온 편지 (flagship hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_flagship_letter', '깃대를 보고 온 편지',
  3, 2, 1, 5, 'escort',
  true, 'flagship', '', 24,
  '{"named_reward_multiplier": 1.30, "named_reputation_multiplier": 1.30, "named_description": "용병단의 깃대를 보고 왔습니다. 당신께만 부탁드릴 것이 있습니다."}'::jsonb,
  '깃대를 본 의뢰인'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- 7. 깃대의 전설을 찾는 자 (flagship hook)
INSERT INTO public.quest_pools (
  id, name, type, difficulty, min_region_diff, max_region_diff, type_id,
  is_named, named_hook_type, named_hook_value, named_cooldown_hours,
  special_flags, enemy_name
) VALUES (
  'qp_named_flagship_legend', '깃대의 전설을 찾는 자',
  1, 4, 2, 4, 'raid',
  true, 'flagship', '', 24,
  '{"named_reward_multiplier": 1.50, "named_reputation_multiplier": 1.40, "named_description": "당신의 깃대 아래에서 임무를 수행하고 싶다는 자가 찾아왔습니다."}'::jsonb,
  '깃대의 전설을 따르는 자'
) ON CONFLICT (id) DO UPDATE SET
  is_named = EXCLUDED.is_named,
  named_hook_type = EXCLUDED.named_hook_type,
  named_hook_value = EXCLUDED.named_hook_value,
  named_cooldown_hours = EXCLUDED.named_cooldown_hours,
  special_flags = EXCLUDED.special_flags;

-- ============================================================
-- data_versions 갱신 (quest_pools version + 1)
-- ============================================================

INSERT INTO public.data_versions (table_name, version, updated_at)
VALUES ('quest_pools', (SELECT COALESCE(MAX(version), 0) + 1 FROM public.data_versions WHERE table_name = 'quest_pools'), NOW())
ON CONFLICT (table_name) DO UPDATE SET
  version = public.data_versions.version + 1,
  updated_at = NOW();

COMMIT;
```

- [ ] **Step 2: SQL 검증 (로컬 syntax만)**

```bash
ls band_of_mercenaries/supabase/migrations/20260515130000_create_named_quests.sql
```

Expected: 파일 존재 + SQL 문법 일관성 확인

⚠️ **Supabase 적용은 사용자가 별도로 MCP `apply_migration` 호출** — 본 TASK는 SQL 작성만 담당.

---

## Task 16: 통합 검증 + 최종 빌드

**Files:**
- Verify all

- [ ] **Step 1: 전체 빌드**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded` (모든 .g.dart / .freezed.dart 재생성)

- [ ] **Step 2: flutter analyze 전체**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: 전체 테스트 실행**

```bash
cd band_of_mercenaries && flutter test
```

Expected: `All tests passed!` — 특히 다음 신규 테스트 통과:
- `test/features/quest/domain/named_hook_evaluator_test.dart` (12 케이스)
- `test/features/quest/domain/quest_sort_service_named_test.dart` (3 케이스)

- [ ] **Step 4: state.md 페이즈 4 #3 완료 표기**

`Docs/milestone-runs/M6/state.md` 편집:
- 페이즈 4 #3 항목 `[ ]` → `[x]` 전환
- 산출물 경로 + 완료 timestamp + 핵심 결정 1줄 요약 기재
- 페이즈 4 상태 `in_progress` → `completed`
- 마일스톤 상태 `in_progress` → `completed` (M6 전체 완료)
- 실행 이력에 완료 라인 추가

- [ ] **Step 5: finalize-feature 준비**

`/finalize-feature` 호출로 다음 처리:
- CHANGELOG fragment 생성 (`Docs/changelog-fragments/20260515_M6_phase4_3_named-quests.md`)
- CLAUDE.md 갱신 (HiveField 표 + 게임 시스템 로직 섹션에 지명 의뢰 추가)
- 명세서·plan 아카이브 (`Docs/Archive/20260515_M6_phase4_3_named-quests/`)
- 단일 커밋 (개별 스테이징, .env 제외)

**Supabase migration 적용은 사용자가 별도로 MCP 호출** — `mcp__plugin_supabase_supabase__apply_migration`.

---

## Self-Review

### Spec Coverage Check

- ✅ FR-1 → TASK 15 (SQL ALTER + CHECK + INDEX)
- ✅ FR-2 → TASK 3 (QuestPool 4 필드)
- ✅ FR-3 → TASK 4 (UserData HiveField 26)
- ✅ FR-4 → TASK 5 (ActiveQuest HiveField 26)
- ✅ FR-5 → TASK 7 (QuestGenerator 분기)
- ✅ FR-6 → TASK 6 (NamedHookEvaluator + 8 케이스)
- ✅ FR-7 → TASK 11 (cooldown 갱신)
- ✅ FR-8 → TASK 9 (NamedTier + 3 케이스)
- ✅ FR-9 → TASK 1 (namedAccent) + TASK 13 (LayerSidebar/Badges)
- ✅ FR-10 → TASK 14 (LockOverlay)
- ✅ FR-11 → TASK 10 (보상 배수)
- ✅ FR-12 → TASK 12 (사망/방출 자동 종료) + TASK 2 (ActivityLogType)
- ✅ FR-13 → TASK 15 (7행 INSERT)

### Type Consistency Check

- `NamedHookContext`: TASK 6에서 정의, TASK 7에서 동일 시그니처 사용 ✓
- `evaluateNamedHook(QuestPool, NamedHookContext) → bool`: TASK 6과 TASK 7 일치 ✓
- `namedQuestCooldowns`: `Map<String, DateTime>` 일관 (TASK 4 / TASK 7 / TASK 11) ✓
- `namedTargetMercId`: `String?` 일관 (TASK 5 / TASK 7 / TASK 12 / TASK 14) ✓
- HiveField 번호: UserData 26 / ActiveQuest 26 / ActivityLogType 31 (TASK 2·4·5) ✓
- AppTheme.namedAccent: `Color(0xFFE91E63)` (TASK 1 / TASK 13) ✓

### Placeholder Scan

- TBD/TODO 없음 ✓
- "appropriate error handling" 없음 ✓
- "handle edge cases" 없음 ✓
- 모든 step에 실제 코드 또는 명확한 명령 ✓

---

## Execution Handoff

**Plan complete and saved to `Docs/superpowers/plans/2026-05-15-named-quests.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - 신규 subagent를 TASK별로 dispatch + 2단계 review (페이즈 4 #1·#2와 동일 패턴)

**2. Inline Execution** - 현재 세션에서 batch checkpoint로 실행

페이즈 4 #1·#2는 `implement-agent` 16~15 TASK 순차 격리 모드로 진행했고, 본 페이즈도 16 TASK로 동일 규모. 동일 패턴 권장.

**Which approach?**
