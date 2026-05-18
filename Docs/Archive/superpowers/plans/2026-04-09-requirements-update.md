# 2026-04-09 요구사항 업데이트 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 8개 영역(버그 수정, 밸런스, 퀘스트 개선, 홈 화면, 이동 제한, 용병 방출, 방치형 보상)에 대한 기능 구현 및 버그 수정

**Architecture:** 기존 Riverpod + Hive 아키텍처를 유지하며, 시간 가속은 endTime 재계산 방식으로 수정. 활동 로그는 새 Hive 박스로 관리. 방치형 보상은 WidgetsBindingObserver를 통한 앱 라이프사이클 감지.

**Tech Stack:** Flutter, Riverpod, Hive, freezed, json_serializable, build_runner

**Spec:** `docs/superpowers/specs/2026-04-09-requirements-update-design.md`

---

## File Structure

### 수정 대상 파일
- `lib/core/providers/timer_provider.dart` — recalculateAllTimers 함수 추가
- `lib/core/models/difficulty.dart` — MinDispatchCost/MaxDispatchCost 필드
- `lib/core/data/hive_initializer.dart` — ActivityLog 어댑터 등록, 새 박스 오픈
- `lib/main.dart` — 방치형 보상 계산, 퀘스트 자동 생성
- `lib/app.dart` — WidgetsBindingObserver 추가
- `lib/features/quest/domain/quest_model.dart` — createdAt 필드
- `lib/features/quest/domain/quest_calculator.dart` — calculateDispatchCost 메서드
- `lib/features/quest/domain/quest_provider.dart` — 갱신 로직, recalculateTimers
- `lib/features/quest/domain/quest_generator.dart` — createdAt 설정
- `lib/features/quest/view/dispatch_screen.dart` — 다이얼로그 버그 수정, 바텀시트, 갱신 타이머, 채우기 버튼
- `lib/features/quest/view/quest_result_dialog.dart` — (변경 없음, 재사용)
- `lib/features/home/view/home_screen.dart` — 대시보드, 로그, 완료 알림
- `lib/features/movement/view/movement_screen.dart` — 파견 중 이동 제한
- `lib/features/movement/domain/movement_provider.dart` — recalculateTimers
- `lib/features/mercenary/domain/mercenary_model.dart` — (변경 없음)
- `lib/features/mercenary/domain/mercenary_provider.dart` — recalculateTimers, dismiss 메서드
- `lib/features/mercenary/data/mercenary_repository.dart` — dismiss, dismissedIds 저장
- `lib/features/mercenary/view/recruit_screen.dart` — 방출 버튼
- `lib/features/settings/view/settings_screen.dart` — 속도 변경 시 recalculate 호출
- `assets/json/Difficulty.json` — 비용 구조 변경

### 신규 파일
- `lib/features/home/domain/activity_log_model.dart` — ActivityLog Hive 모델
- `lib/features/home/data/activity_log_repository.dart` — ActivityLog 레포지토리
- `lib/features/home/domain/activity_log_provider.dart` — ActivityLog 프로바이더
- `test/features/quest/domain/quest_calculator_dispatch_cost_test.dart` — 비용 계산 테스트
- `test/features/quest/domain/quest_refresh_test.dart` — 퀘스트 갱신 테스트

---

## Task 1: 시간 가속 모드 수정

시간 가속 변경 시 모든 활성 타이머의 endTime을 재계산하여 즉시 반영되도록 수정.

**Files:**
- Modify: `lib/core/providers/timer_provider.dart`
- Modify: `lib/features/quest/domain/quest_provider.dart:107-116`
- Modify: `lib/features/movement/domain/movement_provider.dart:100-107`
- Modify: `lib/features/mercenary/domain/mercenary_provider.dart:35-57`
- Modify: `lib/features/settings/view/settings_screen.dart`

- [ ] **Step 1: timer_provider.dart에 recalculateAllTimers 헬퍼 추가**

```dart
// lib/core/providers/timer_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speedMultiplierProvider = StateProvider<double>((ref) => 1.0);

final gameTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

/// 속도 변경 시 활성 타이머의 endTime을 재계산하는 유틸리티.
/// oldSpeed에서 설정된 endTime을 newSpeed 기준으로 변환한다.
DateTime? recalculateEndTime(DateTime? endTime, DateTime? startTime, double oldSpeed, double newSpeed) {
  if (endTime == null || startTime == null) return endTime;
  final now = DateTime.now();
  if (now.isAfter(endTime)) return endTime; // 이미 완료됨

  // 남은 실제 시간을 원래 게임 시간으로 복원 후 새 속도로 재계산
  final remainingReal = endTime.difference(now);
  final remainingBase = remainingReal * oldSpeed; // 원래 게임 시간
  final newRemaining = remainingBase * (1.0 / newSpeed); // 새 속도 적용
  return now.add(newRemaining);
}
```

- [ ] **Step 2: quest_provider.dart에 recalculateTimers 메서드 추가**

`QuestListNotifier` 클래스에 추가:

```dart
// lib/features/quest/domain/quest_provider.dart — QuestListNotifier 내부에 추가
void recalculateTimers(double oldSpeed, double newSpeed) {
  bool changed = false;
  for (final quest in state) {
    if (quest.status == QuestStatus.inProgress && quest.endTime != null && quest.startTime != null) {
      final newEndTime = recalculateEndTime(quest.endTime, quest.startTime, oldSpeed, newSpeed);
      if (newEndTime != quest.endTime) {
        quest.endTime = newEndTime;
        quest.save();
        changed = true;
      }
    }
  }
  if (changed) _load();
}
```

`timer_provider.dart`의 import도 필요:
```dart
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
```
(이미 import되어 있음)

- [ ] **Step 3: movement_provider.dart에 recalculateTimers 메서드 추가**

`MovementNotifier` 클래스에 추가:

```dart
// lib/features/movement/domain/movement_provider.dart — MovementNotifier 내부에 추가
void recalculateTimers(double oldSpeed, double newSpeed) {
  final user = state;
  if (user == null || !user.isMoving || user.moveEndTime == null) return;

  final now = DateTime.now();
  if (now.isAfter(user.moveEndTime!)) return; // 이미 완료

  final remaining = user.moveEndTime!.difference(now);
  final baseRemaining = remaining * oldSpeed;
  final newRemaining = baseRemaining * (1.0 / newSpeed);
  user.moveEndTime = now.add(newRemaining);
  user.save();
  _load();
  ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild
}
```

`timer_provider.dart` import 추가 (이미 있으면 skip):
```dart
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
```

- [ ] **Step 4: mercenary_provider.dart에 recalculateTimers 메서드 추가**

`MercenaryListNotifier` 클래스에 추가:

```dart
// lib/features/mercenary/domain/mercenary_provider.dart — MercenaryListNotifier 내부에 추가
void recalculateTimers(double oldSpeed, double newSpeed) {
  bool changed = false;
  for (final merc in state) {
    if (merc.status == MercenaryStatus.tired && merc.tiredEndTime != null) {
      final newEnd = recalculateEndTime(merc.tiredEndTime, merc.tiredEndTime!.subtract(const Duration(minutes: 5)), oldSpeed, newSpeed);
      if (newEnd != merc.tiredEndTime) {
        merc.tiredEndTime = newEnd;
        merc.save();
        changed = true;
      }
    }
    if (merc.status == MercenaryStatus.injured && merc.injuryEndTime != null) {
      // startTime 정보가 없으므로 현재 시간을 기준으로 남은 시간만 재계산
      final now = DateTime.now();
      if (now.isBefore(merc.injuryEndTime!)) {
        final remaining = merc.injuryEndTime!.difference(now);
        final baseRemaining = remaining * oldSpeed;
        final newRemaining = baseRemaining * (1.0 / newSpeed);
        merc.injuryEndTime = now.add(newRemaining);
        merc.save();
        changed = true;
      }
    }
  }
  if (changed) _load();
}
```

- [ ] **Step 5: settings_screen.dart에서 속도 변경 시 recalculate 호출**

설정 화면의 속도 변경 버튼에서 oldSpeed를 캡처하고 모든 notifier에 recalculate를 호출:

```dart
// lib/features/settings/view/settings_screen.dart — 속도 변경 버튼 onPressed 수정
// 기존:
// onPressed: () => ref.read(speedMultiplierProvider.notifier).state = speed,
// 변경:
onPressed: () {
  final oldSpeed = ref.read(speedMultiplierProvider);
  ref.read(speedMultiplierProvider.notifier).state = speed;
  ref.read(questListProvider.notifier).recalculateTimers(oldSpeed, speed);
  ref.read(movementProvider.notifier).recalculateTimers(oldSpeed, speed);
  ref.read(mercenaryListProvider.notifier).recalculateTimers(oldSpeed, speed);
},
```

추가 import 필요:
```dart
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
```

- [ ] **Step 6: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: No errors.

- [ ] **Step 7: 커밋**

```bash
cd band_of_mercenaries && git add lib/core/providers/timer_provider.dart lib/features/quest/domain/quest_provider.dart lib/features/movement/domain/movement_provider.dart lib/features/mercenary/domain/mercenary_provider.dart lib/features/settings/view/settings_screen.dart && git commit -m "fix: time acceleration recalculates all active timers on speed change"
```

---

## Task 2: 퀘스트 완료 다이얼로그 깜빡임 + 확인 버튼 먹통 수정

`build()` 내 매 렌더마다 다이얼로그를 띄우는 로직을 `ref.listen()`으로 이동하고, 중복 표시를 방지.

**Files:**
- Modify: `lib/features/quest/view/dispatch_screen.dart:22-48`

- [ ] **Step 1: _DispatchScreenState에 다이얼로그 상태 추적 필드 추가**

```dart
// lib/features/quest/view/dispatch_screen.dart
// 기존 (line 22-24):
// class _DispatchScreenState extends ConsumerState<DispatchScreen> {
//   String? _selectedQuestId;
//   final Set<String> _selectedMercIds = {};

// 변경:
class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  String? _selectedQuestId;
  final Set<String> _selectedMercIds = {};
  bool _isShowingResult = false;
  final Set<String> _shownResultIds = {};
```

- [ ] **Step 2: build() 내 completion 감지 로직을 initState의 ref.listenManual로 이동**

먼저 build() 내의 기존 감지 코드를 제거 (line 42-48):
```dart
// 삭제할 코드:
//    // Check for completed quests to show results
//    final completed = quests.where((q) => q.status == QuestStatus.completed).toList();
//    if (completed.isNotEmpty) {
//      WidgetsBinding.instance.addPostFrameCallback((_) {
//        _showResult(context, completed.first, ref);
//      });
//    }
```

`_DispatchScreenState`에 `initState` 오버라이드 추가:

```dart
@override
void initState() {
  super.initState();
  // ref.listenManual은 ConsumerState에서 사용 가능
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
}
```

실제로 ConsumerStatefulWidget에서는 `build` 내에서 `ref.listen`을 사용할 수 있으므로, build 메서드 상단에 배치:

```dart
@override
Widget build(BuildContext context) {
  // 퀘스트 완료 감지 — ref.listen은 상태 변경 시에만 콜백 실행
  ref.listen<List<ActiveQuest>>(questListProvider, (previous, next) {
    if (_isShowingResult) return;
    final completed = next.where(
      (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
    ).toList();
    if (completed.isNotEmpty) {
      _isShowingResult = true;
      _shownResultIds.add(completed.first.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showResult(context, completed.first, ref);
        }
      });
    }
  });

  final userData = ref.watch(userDataProvider);
  final quests = ref.watch(questListProvider);
  // ... 나머지 기존 코드 유지
```

- [ ] **Step 3: _showResult 메서드에서 다이얼로그 닫힘 시 플래그 리셋**

기존 `_showResult` 메서드 수정 (dispatch_screen.dart 하단):

```dart
// 기존 _showResult를 다음으로 교체:
void _showResult(BuildContext context, ActiveQuest quest, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => QuestResultDialog(quest: quest),
  );
  // 다이얼로그 닫힘 후 퀘스트 정리
  ref.read(questListProvider.notifier).clearCompleted(quest.id);
  _isShowingResult = false;
  // 다음 완료된 퀘스트가 있으면 표시
  if (mounted) {
    final quests = ref.read(questListProvider);
    final nextCompleted = quests.where(
      (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
    ).toList();
    if (nextCompleted.isNotEmpty) {
      _isShowingResult = true;
      _shownResultIds.add(nextCompleted.first.id);
      _showResult(context, nextCompleted.first, ref);
    }
  }
}
```

Note: `clearCompleted(questId)` 메서드가 quest_provider에 없으면 추가 필요. 기존에 완료 퀘스트를 정리하는 로직을 확인하고, 없으면 추가:

```dart
// quest_provider.dart에 추가
Future<void> clearCompleted(String questId) async {
  await _repo.removeQuest(questId);
  _load();
}
```

- [ ] **Step 4: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 5: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/quest/view/dispatch_screen.dart lib/features/quest/domain/quest_provider.dart && git commit -m "fix: prevent quest result dialog flickering and button unresponsiveness"
```

---

## Task 3: 파견 비용 구조 변경

난이도별 고정 비용을 최소~최대 범위로 변경하고, 소요시간에 따라 선형 보간.

**Files:**
- Modify: `assets/json/Difficulty.json`
- Modify: `lib/core/models/difficulty.dart`
- Modify: `lib/features/quest/domain/quest_calculator.dart`
- Modify: `lib/features/quest/domain/quest_provider.dart:77-88`
- Modify: `lib/features/quest/view/dispatch_screen.dart:194`
- Test: `test/features/quest/domain/quest_calculator_dispatch_cost_test.dart`

- [ ] **Step 1: 비용 계산 테스트 작성**

```dart
// test/features/quest/domain/quest_calculator_dispatch_cost_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';

void main() {
  group('calculateDispatchCost', () {
    test('난이도1 최단 퀘스트는 최소 비용에 가까워야 함', () {
      // baseDuration=60, difficulty=1 → duration=60*1.0=60s
      // ratio = 60/144 ≈ 0.417
      // cost = 5 + (30-5)*0.417 ≈ 15
      final cost = QuestCalculator.calculateDispatchCost(
        baseDuration: 60, difficulty: 1, minCost: 5, maxCost: 30,
      );
      expect(cost, greaterThanOrEqualTo(5));
      expect(cost, lessThanOrEqualTo(30));
    });

    test('난이도5 최장 퀘스트는 최대 비용에 가까워야 함', () {
      // baseDuration=80, difficulty=5 → duration=80*1.8=144s
      // ratio = 144/144 = 1.0
      // cost = 50 + (200-50)*1.0 = 200
      final cost = QuestCalculator.calculateDispatchCost(
        baseDuration: 80, difficulty: 5, minCost: 50, maxCost: 200,
      );
      expect(cost, equals(200));
    });

    test('비용은 항상 minCost 이상 maxCost 이하', () {
      for (int diff = 1; diff <= 5; diff++) {
        for (int base in [60, 70, 75, 80]) {
          final cost = QuestCalculator.calculateDispatchCost(
            baseDuration: base, difficulty: diff, minCost: 5, maxCost: 200,
          );
          expect(cost, greaterThanOrEqualTo(5));
          expect(cost, lessThanOrEqualTo(200));
        }
      }
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/quest_calculator_dispatch_cost_test.dart
```

Expected: FAIL — `calculateDispatchCost` static method does not exist with those parameters.

- [ ] **Step 3: Difficulty.json 수정**

```json
{
  "Difficultys": [
    {"Level": 1, "EnemyPower": 10, "RewardMultiplier": 1.0, "SuccessPenalty": 0.0, "InjuryRate": 0.1, "DeathRate": 0.05, "MinDispatchCost": 5, "MaxDispatchCost": 30},
    {"Level": 2, "EnemyPower": 20, "RewardMultiplier": 1.5, "SuccessPenalty": 0.1, "InjuryRate": 0.2, "DeathRate": 0.1, "MinDispatchCost": 10, "MaxDispatchCost": 60},
    {"Level": 3, "EnemyPower": 35, "RewardMultiplier": 2.2, "SuccessPenalty": 0.2, "InjuryRate": 0.3, "DeathRate": 0.15, "MinDispatchCost": 20, "MaxDispatchCost": 100},
    {"Level": 4, "EnemyPower": 55, "RewardMultiplier": 3.2, "SuccessPenalty": 0.3, "InjuryRate": 0.45, "DeathRate": 0.22, "MinDispatchCost": 35, "MaxDispatchCost": 150},
    {"Level": 5, "EnemyPower": 80, "RewardMultiplier": 4.5, "SuccessPenalty": 0.4, "InjuryRate": 0.6, "DeathRate": 0.3, "MinDispatchCost": 50, "MaxDispatchCost": 200}
  ]
}
```

`Json/` 디렉토리에 원본이 있으면 동일하게 수정.

- [ ] **Step 4: difficulty.dart 모델 수정**

```dart
// lib/core/models/difficulty.dart
@freezed
class Difficulty with _$Difficulty {
  const factory Difficulty({
    @JsonKey(name: 'Level') required int level,
    @JsonKey(name: 'EnemyPower') required int enemyPower,
    @JsonKey(name: 'RewardMultiplier') required double rewardMultiplier,
    @JsonKey(name: 'SuccessPenalty') required double successPenalty,
    @JsonKey(name: 'InjuryRate') required double injuryRate,
    @JsonKey(name: 'DeathRate') required double deathRate,
    @JsonKey(name: 'MinDispatchCost') required int minDispatchCost,
    @JsonKey(name: 'MaxDispatchCost') required int maxDispatchCost,
  }) = _Difficulty;

  factory Difficulty.fromJson(Map<String, dynamic> json) =>
      _$DifficultyFromJson(json);
}
```

- [ ] **Step 5: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: quest_calculator.dart에 calculateDispatchCost 추가**

```dart
// lib/features/quest/domain/quest_calculator.dart — QuestCalculator 클래스 내부에 추가
static const double _maxDuration = 144.0; // 80(최대baseDuration) * 1.8(난이도5보정)

static int calculateDispatchCost({
  required int baseDuration,
  required int difficulty,
  required int minCost,
  required int maxCost,
}) {
  final multiplier = 1.0 + (difficulty - 1) * 0.2;
  final duration = baseDuration * multiplier;
  final ratio = (duration / _maxDuration).clamp(0.0, 1.0);
  return (minCost + (maxCost - minCost) * ratio).round();
}
```

- [ ] **Step 7: quest_provider.dart에서 새 비용 계산 사용**

기존 dispatch() 메서드의 비용 관련 코드 수정 (line 77-88):

```dart
// 기존:
// if (userData == null || userData.gold < difficulty.dispatchCost) {
// await ref.read(userDataProvider.notifier).spendGold(difficulty.dispatchCost);

// 변경:
final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
final dispatchCost = QuestCalculator.calculateDispatchCost(
  baseDuration: questType.baseDuration,
  difficulty: quest.difficulty,
  minCost: difficulty.minDispatchCost,
  maxCost: difficulty.maxDispatchCost,
);
if (userData == null || userData.gold < dispatchCost) {
  return false;
}
await ref.read(userDataProvider.notifier).spendGold(dispatchCost);
```

Note: `questType`이 이미 위에서 선언되어 있으므로 변수 선언 위치를 조정해야 할 수 있음. 기존 코드에서 questType은 line 75에 선언됨 — 비용 계산을 그 이후에 배치.

- [ ] **Step 8: dispatch_screen.dart의 비용 표시 수정**

```dart
// lib/features/quest/view/dispatch_screen.dart — _buildDispatchPanel 내 (기존 line 194):
// 기존:
// final dispatchCost = difficulty.dispatchCost;

// 변경:
final dispatchCost = QuestCalculator.calculateDispatchCost(
  baseDuration: questType.baseDuration,
  difficulty: quest.difficulty,
  minCost: difficulty.minDispatchCost,
  maxCost: difficulty.maxDispatchCost,
);
```

- [ ] **Step 9: 기존 dispatchCost 참조 제거 확인**

프로젝트 전체에서 `.dispatchCost`를 검색하여 누락된 참조가 없는지 확인:

```bash
cd band_of_mercenaries && grep -rn "\.dispatchCost" lib/
```

모든 참조를 새 `calculateDispatchCost` 방식으로 교체.

- [ ] **Step 10: 테스트 통과 확인**

```bash
cd band_of_mercenaries && flutter test test/features/quest/domain/quest_calculator_dispatch_cost_test.dart
```

Expected: PASS

- [ ] **Step 11: 전체 분석 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 12: 커밋**

```bash
cd band_of_mercenaries && git add assets/json/Difficulty.json Json/Difficulty.json lib/core/models/difficulty.dart lib/core/models/difficulty.freezed.dart lib/core/models/difficulty.g.dart lib/features/quest/domain/quest_calculator.dart lib/features/quest/domain/quest_provider.dart lib/features/quest/view/dispatch_screen.dart test/features/quest/domain/quest_calculator_dispatch_cost_test.dart && git commit -m "feat: scale dispatch cost by duration within difficulty min/max range"
```

---

## Task 4: 퀘스트 자동 생성 + createdAt 필드

첫 실행 시 자동 생성하고, 퀘스트별 생성 시간을 추적.

**Files:**
- Modify: `lib/features/quest/domain/quest_model.dart`
- Modify: `lib/features/quest/domain/quest_generator.dart`
- Modify: `lib/features/quest/domain/quest_provider.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: quest_model.dart에 createdAt 필드 추가**

```dart
// lib/features/quest/domain/quest_model.dart — ActiveQuest 클래스에 추가
// 기존 HiveField(10) questName 다음에:

@HiveField(11)
DateTime? createdAt;

// 생성자에도 추가:
ActiveQuest({
  required this.id,
  required this.questPoolId,
  required this.questTypeId,
  required this.difficulty,
  required this.region,
  required this.questName,
  this.dispatchedMercIds = const [],
  this.startTime,
  this.endTime,
  this.status = QuestStatus.pending,
  this.result,
  this.createdAt,
});
```

- [ ] **Step 2: build_runner로 Hive 어댑터 재생성**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: quest_generator.dart에서 createdAt 설정**

```dart
// lib/features/quest/domain/quest_generator.dart — generateQuests() 내 ActiveQuest 생성 부분
// 기존 ActiveQuest 생성에 createdAt 추가:
ActiveQuest(
  id: const Uuid().v4(),
  questPoolId: pool.id,
  questTypeId: questType.id,
  difficulty: pool.difficulty.clamp(1, 5),
  region: regionId,
  questName: pool.name,
  createdAt: DateTime.now(),  // 추가
)
```

- [ ] **Step 4: quest_provider.dart 초기화 시 자동 생성**

`QuestListNotifier` 생성자에서 로드 후 퀘스트가 없으면 자동 생성:

```dart
// lib/features/quest/domain/quest_provider.dart — QuestListNotifier 생성자 수정
QuestListNotifier(this.ref) : super([]) {
  _repo = ref.read(questRepositoryProvider);
  _load();
  // 퀘스트가 없으면 자동 생성
  if (state.isEmpty) {
    generateQuests();
  }
  ref.listen(gameTickProvider, (prev, next) {
    _checkCompletions();
  });
}
```

Note: `generateQuests()`가 async이므로 생성자에서 호출 시 await 불가. `then`이나 fire-and-forget으로 처리. 현재 패턴이 `Future<void>`를 반환하므로:

```dart
if (state.isEmpty) {
  generateQuests(); // fire-and-forget, _load()가 내부에서 호출됨
}
```

- [ ] **Step 5: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 6: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/quest/domain/quest_model.dart lib/features/quest/domain/quest_model.g.dart lib/features/quest/domain/quest_generator.dart lib/features/quest/domain/quest_provider.dart && git commit -m "feat: auto-generate quests on first launch and add createdAt field"
```

---

## Task 5: 퀘스트 1시간 갱신 + 카운트다운 UI

대기 중(pending) 퀘스트를 1시간 후 새 퀘스트로 교체하고, 남은 시간을 표시.

**Files:**
- Modify: `lib/features/quest/domain/quest_provider.dart`
- Modify: `lib/features/quest/view/dispatch_screen.dart`

- [ ] **Step 1: 생성자에서 _checkQuestRefresh 호출 추가**

기존 `ref.listen` 콜백에 `_checkQuestRefresh()` 호출 추가:

```dart
// lib/features/quest/domain/quest_provider.dart — QuestListNotifier 생성자의 ref.listen 수정
ref.listen(gameTickProvider, (prev, next) {
  _checkCompletions();
  _checkQuestRefresh();
});
```

- [ ] **Step 2: _checkQuestRefresh 및 _refreshExpiredQuests 메서드 구현**

```dart
// lib/features/quest/domain/quest_provider.dart — QuestListNotifier 내부에 추가
static const _questRefreshDuration = Duration(hours: 1);

void _checkQuestRefresh() {
  final now = DateTime.now();
  final speedMult = ref.read(speedMultiplierProvider);
  bool changed = false;

  final expiredQuests = <ActiveQuest>[];
  for (final quest in state) {
    if (quest.status == QuestStatus.pending && quest.createdAt != null) {
      // 속도 배율 적용: 실제 경과 시간 × 속도 = 게임 경과 시간
      final realElapsed = now.difference(quest.createdAt!);
      final gameElapsed = realElapsed * speedMult;
      if (gameElapsed >= _questRefreshDuration) {
        expiredQuests.add(quest);
      }
    }
  }

  if (expiredQuests.isNotEmpty) {
    _refreshExpiredQuests(expiredQuests);
  }
}

Future<void> _refreshExpiredQuests(List<ActiveQuest> expired) async {
  final staticData = ref.read(staticDataProvider).value;
  final userData = ref.read(userDataProvider);
  if (staticData == null || userData == null) return;

  final region = staticData.regions.firstWhere((r) => r.region == userData.region);

  for (final quest in expired) {
    await _repo.removeQuest(quest.id);
  }

  final newQuests = QuestGenerator.generateQuests(
    regionTier: region.regionTier,
    regionId: userData.region,
    questPools: staticData.questPools,
    questTypes: staticData.questTypes,
    count: expired.length,
    random: Random(),
  );
  await _repo.addQuests(newQuests);
  _load();
}
```

Note: `_repo.removeQuest(questId)` 메서드가 없으면 `QuestRepository`에 추가:

```dart
// lib/features/quest/data/quest_repository.dart — 추가
Future<void> removeQuest(String questId) async {
  final index = _box.values.toList().indexWhere((q) => q.id == questId);
  if (index >= 0) {
    await _box.deleteAt(index);
  }
}
```

- [ ] **Step 3: dispatch_screen.dart에서 갱신 카운트다운 표시**

퀘스트 카드에 남은 갱신 시간 표시. `_buildQuestCard` 메서드 내에서:

```dart
// 퀘스트 카드 내부에 갱신 타이머 추가
// quest.createdAt이 있고 pending 상태일 때:
if (quest.status == QuestStatus.pending && quest.createdAt != null) {
  final speedMult = ref.read(speedMultiplierProvider);
  final realElapsed = DateTime.now().difference(quest.createdAt!);
  final gameElapsed = realElapsed * speedMult;
  final remaining = const Duration(hours: 1) - gameElapsed;
  if (remaining.isNegative) {
    // 곧 갱신됨
  } else {
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    // 카드 하단에 표시:
    Text(
      '갱신까지 ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
    );
  }
}
```

구체적인 위치는 기존 `_buildQuestCard` 메서드의 Column children 끝에 추가.

- [ ] **Step 4: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 5: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/quest/domain/quest_provider.dart lib/features/quest/data/quest_repository.dart lib/features/quest/view/dispatch_screen.dart && git commit -m "feat: auto-refresh pending quests every hour with countdown timer"
```

---

## Task 6: 퀘스트 채우기 버튼

활성 퀘스트가 최대 수 미만일 때 채우기 버튼 표시.

**Files:**
- Modify: `lib/features/quest/domain/quest_provider.dart`
- Modify: `lib/features/quest/view/dispatch_screen.dart`

- [ ] **Step 1: quest_provider.dart에 fillQuests 메서드 추가**

```dart
// lib/features/quest/domain/quest_provider.dart — QuestListNotifier 내부에 추가
int getMaxQuestCount() {
  final staticData = ref.read(staticDataProvider).value;
  final userData = ref.read(userDataProvider);
  if (staticData == null || userData == null) return 5;

  int count = 5;
  final intelligenceLevel = userData.facilities['intelligence'] ?? 0;
  if (intelligenceLevel > 0) {
    final intelligenceFacility = staticData.facilities.firstWhere(
      (f) => f.id == 'intelligence',
      orElse: () => staticData.facilities.first,
    );
    count += FacilityService.getExtraQuestCount(intelligenceFacility, intelligenceLevel);
  }
  return count;
}

Future<void> fillQuests() async {
  final staticData = ref.read(staticDataProvider).value;
  final userData = ref.read(userDataProvider);
  if (staticData == null || userData == null) return;

  final maxCount = getMaxQuestCount();
  final activeCount = state.where(
    (q) => q.status == QuestStatus.pending || q.status == QuestStatus.inProgress,
  ).length;
  final deficit = maxCount - activeCount;
  if (deficit <= 0) return;

  final region = staticData.regions.firstWhere((r) => r.region == userData.region);

  final newQuests = QuestGenerator.generateQuests(
    regionTier: region.regionTier,
    regionId: userData.region,
    questPools: staticData.questPools,
    questTypes: staticData.questTypes,
    count: deficit,
    random: Random(),
  );
  await _repo.addQuests(newQuests);
  _load();
}
```

- [ ] **Step 2: dispatch_screen.dart에 채우기 버튼 추가**

퀘스트 목록 상단 또는 하단에 조건부 버튼:

```dart
// pendingQuests 목록 아래에 추가 (build 메서드 내):
Builder(builder: (context) {
  final maxCount = ref.read(questListProvider.notifier).getMaxQuestCount();
  final activeCount = quests.where(
    (q) => q.status == QuestStatus.pending || q.status == QuestStatus.inProgress,
  ).length;
  if (activeCount >= maxCount) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => ref.read(questListProvider.notifier).fillQuests(),
        child: Text('퀘스트 채우기 ($activeCount/$maxCount)'),
      ),
    ),
  );
}),
```

- [ ] **Step 3: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 4: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/quest/domain/quest_provider.dart lib/features/quest/view/dispatch_screen.dart && git commit -m "feat: add quest fill button when active quests below max count"
```

---

## Task 7: 파견 인원 선택 바텀시트

인라인 용병 리스트를 DraggableScrollableSheet 바텀시트로 교체.

**Files:**
- Modify: `lib/features/quest/view/dispatch_screen.dart:170-294`

- [ ] **Step 1: 퀘스트 선택 시 바텀시트를 표시하도록 변경**

기존 `_buildDispatchPanel`을 바텀시트로 호출하는 방식으로 변경.

퀘스트 카드 탭 시 바텀시트를 표시:

```dart
// _buildQuestCard 내 onTap 수정:
// 기존: 퀘스트 선택 시 setState로 _selectedQuestId 설정
// 변경: 퀘스트 선택 시 바텀시트 표시
onTap: () {
  setState(() {
    _selectedQuestId = quest.id;
    _selectedMercIds.clear();
  });
  _showDispatchBottomSheet(context, mercs, data);
},
```

- [ ] **Step 2: _showDispatchBottomSheet 메서드 구현**

```dart
// lib/features/quest/view/dispatch_screen.dart — 새 메서드 추가
void _showDispatchBottomSheet(BuildContext context, List<Mercenary> mercs, StaticGameData data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final quest = ref.read(questListProvider).firstWhere((q) => q.id == _selectedQuestId);
          final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
          final difficulty = data.difficulties.firstWhere(
            (d) => d.level == quest.difficulty.clamp(1, 5),
            orElse: () => data.difficulties.first,
          );
          final selectedMercs = mercs.where((m) => _selectedMercIds.contains(m.id)).toList();
          final partyPower = selectedMercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);
          final userData = ref.read(userDataProvider);

          final grossReward = QuestCalculator.calculateReward(
            baseReward: questType.baseReward,
            rewardMultiplier: difficulty.rewardMultiplier,
          );
          final mercTiers = selectedMercs.map((merc) {
            final job = data.jobs.firstWhere((j) => j.id == merc.jobId, orElse: () => data.jobs.first);
            return job.tier;
          }).toList();
          final totalWage = QuestCalculator.calculateTotalWage(mercTiers, data.mercenaryWages);
          final dispatchCost = QuestCalculator.calculateDispatchCost(
            baseDuration: questType.baseDuration,
            difficulty: quest.difficulty,
            minCost: difficulty.minDispatchCost,
            maxCost: difficulty.maxDispatchCost,
          );
          final netProfit = QuestCalculator.calculateNetProfit(
            totalReward: grossReward, totalWage: totalWage, dispatchCost: dispatchCost,
          );
          final hasEnoughGold = userData != null && userData.gold >= dispatchCost;

          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 핸들 바
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('파견 인원 선택 (${_selectedMercIds.length}명)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // 용병 리스트 (스크롤 가능)
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: mercs.length,
                        itemBuilder: (_, index) {
                          final merc = mercs[index];
                          final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
                          final isSelected = _selectedMercIds.contains(merc.id);
                          final canSelect = merc.isAvailable;

                          return ListTile(
                            dense: true,
                            enabled: canSelect,
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: canSelect
                                  ? (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedMercIds.add(merc.id);
                                        } else {
                                          _selectedMercIds.remove(merc.id);
                                        }
                                      });
                                      setSheetState(() {});
                                    }
                                  : null,
                            ),
                            title: Text(
                              '${merc.name} (${job.name})',
                              style: TextStyle(
                                fontSize: 13,
                                color: canSelect ? AppTheme.textSecondary : const Color(0xFF999999),
                                decoration: canSelect ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text(
                              '전투력: ${merc.effectiveAtk} · ${_getMercStatusText(merc)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                            ),
                          );
                        },
                      ),
                    ),
                    // 비용/수익 요약
                    if (_selectedMercIds.isNotEmpty) ...[
                      const Divider(),
                      _buildCostBreakdown(
                        grossReward: grossReward,
                        totalWage: totalWage,
                        dispatchCost: dispatchCost,
                        netProfit: netProfit,
                      ),
                    ],
                    Text(
                      '예상 성공률: ${_selectedMercIds.isEmpty ? "-" : "${(partyPower / difficulty.enemyPower * 50 + 50).clamp(5, 95).round()}%"} · 전투력: $partyPower/${difficulty.enemyPower}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    if (!hasEnoughGold)
                      Text('골드가 부족합니다 (파견비용: ${dispatchCost}G)',
                        style: const TextStyle(fontSize: 13, color: Colors.red)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedMercIds.isEmpty || !hasEnoughGold)
                            ? null
                            : () {
                                ref.read(questListProvider.notifier)
                                    .dispatch(_selectedQuestId!, _selectedMercIds.toList());
                                setState(() {
                                  _selectedQuestId = null;
                                  _selectedMercIds.clear();
                                });
                                Navigator.pop(context);
                              },
                        child: const Text('파견 출발'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

String _getMercStatusText(Mercenary merc) {
  switch (merc.status) {
    case MercenaryStatus.normal: return '정상';
    case MercenaryStatus.tired: return '피곤함';
    case MercenaryStatus.injured: return '부상';
    case MercenaryStatus.dead: return '사망';
  }
}
```

- [ ] **Step 3: 기존 인라인 dispatch panel 제거**

build() 내에서 `_selectedQuestId != null`일 때 `_buildDispatchPanel`을 렌더하던 코드를 제거. 바텀시트가 대체함.

- [ ] **Step 4: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 5: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/quest/view/dispatch_screen.dart && git commit -m "feat: replace inline party selection with draggable bottom sheet"
```

---

## Task 8: ActivityLog 시스템 (모델 + 저장소 + 프로바이더)

활동 로그 인프라 구축.

**Files:**
- Create: `lib/features/home/domain/activity_log_model.dart`
- Create: `lib/features/home/data/activity_log_repository.dart`
- Create: `lib/features/home/domain/activity_log_provider.dart`
- Modify: `lib/core/data/hive_initializer.dart`

- [ ] **Step 1: activity_log_model.dart 생성**

```dart
// lib/features/home/domain/activity_log_model.dart
import 'package:hive/hive.dart';

part 'activity_log_model.g.dart';

@HiveType(typeId: 6)
enum ActivityLogType {
  @HiveField(0)
  questResult,
  @HiveField(1)
  mercenaryStatus,
  @HiveField(2)
  movementComplete,
  @HiveField(3)
  mercenaryRecruit,
  @HiveField(4)
  mercenaryDismiss,
  @HiveField(5)
  levelUp,
}

@HiveType(typeId: 7)
class ActivityLog extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final ActivityLogType type;

  ActivityLog({
    required this.timestamp,
    required this.message,
    required this.type,
  });
}
```

- [ ] **Step 2: activity_log_repository.dart 생성**

```dart
// lib/features/home/data/activity_log_repository.dart
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';

class ActivityLogRepository {
  static const String boxName = 'activityLogs';
  static const int maxLogs = 50;

  Box<ActivityLog> get _box => Hive.box<ActivityLog>(boxName);

  List<ActivityLog> getAll() {
    final logs = _box.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 최신순
    return logs;
  }

  Future<void> addLog(String message, ActivityLogType type) async {
    final log = ActivityLog(
      timestamp: DateTime.now(),
      message: message,
      type: type,
    );
    await _box.add(log);

    // 최대 개수 초과 시 오래된 것 삭제
    if (_box.length > maxLogs) {
      final sorted = _box.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = sorted.take(_box.length - maxLogs);
      for (final log in toDelete) {
        await log.delete();
      }
    }
  }
}
```

- [ ] **Step 3: activity_log_provider.dart 생성**

```dart
// lib/features/home/domain/activity_log_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/home/data/activity_log_repository.dart';

final activityLogRepositoryProvider = Provider((ref) => ActivityLogRepository());

final activityLogProvider = StateNotifierProvider<ActivityLogNotifier, List<ActivityLog>>((ref) {
  return ActivityLogNotifier(ref);
});

class ActivityLogNotifier extends StateNotifier<List<ActivityLog>> {
  final Ref ref;
  late final ActivityLogRepository _repo;

  ActivityLogNotifier(this.ref) : super([]) {
    _repo = ref.read(activityLogRepositoryProvider);
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> addLog(String message, ActivityLogType type) async {
    await _repo.addLog(message, type);
    _load();
  }

  void refresh() => _load();
}
```

- [ ] **Step 4: hive_initializer.dart에 어댑터 등록 및 박스 오픈**

```dart
// lib/core/data/hive_initializer.dart — import 추가:
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';

// initialize() 내부 — 어댑터 등록 추가:
Hive.registerAdapter(ActivityLogTypeAdapter());
Hive.registerAdapter(ActivityLogAdapter());

// 박스 오픈 추가:
await Hive.openBox<ActivityLog>(ActivityLogRepository.boxName);
```

- [ ] **Step 5: build_runner로 Hive 어댑터 생성**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 7: 주요 이벤트 발생 지점에 로그 추가**

각 이벤트 발생 지점에 로그 기록을 추가:

**quest_provider.dart — _completeQuest 내부** (결과 계산 후):
```dart
// 퀘스트 완료 로그
final resultText = {
  QuestResultType.greatSuccess: '대성공',
  QuestResultType.success: '성공',
  QuestResultType.failure: '실패',
  QuestResultType.criticalFailure: '대실패',
}[resultType] ?? '완료';
ref.read(activityLogProvider.notifier).addLog(
  '퀘스트 "${quest.questName}" $resultText!',
  ActivityLogType.questResult,
);
```

import 추가:
```dart
import 'package:band_of_mercenaries/features/home/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';
```

**movement_provider.dart — _completeMovement 내부:**
```dart
ref.read(activityLogProvider.notifier).addLog(
  '${targetRegionData.regionName}에 도착했습니다.',
  ActivityLogType.movementComplete,
);
```

**mercenary_provider.dart — recruit 메서드 내부** (모집 성공 후):
```dart
ref.read(activityLogProvider.notifier).addLog(
  '용병 "${merc.name}" 모집 완료',
  ActivityLogType.mercenaryRecruit,
);
```

- [ ] **Step 8: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/home/domain/activity_log_model.dart lib/features/home/domain/activity_log_model.g.dart lib/features/home/data/activity_log_repository.dart lib/features/home/domain/activity_log_provider.dart lib/core/data/hive_initializer.dart lib/features/quest/domain/quest_provider.dart lib/features/movement/domain/movement_provider.dart lib/features/mercenary/domain/mercenary_provider.dart && git commit -m "feat: add activity log system with Hive persistence"
```

---

## Task 9: 홈 화면 개선 (대시보드 + 활동 로그 + 완료 알림)

홈 화면에 용병단 요약 대시보드, 활동 로그, 퀘스트 완료 알림을 추가.

**Files:**
- Modify: `lib/features/home/view/home_screen.dart`

- [ ] **Step 1: 필요한 import 추가**

```dart
// lib/features/home/view/home_screen.dart — import 추가
import 'package:band_of_mercenaries/features/home/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
```

- [ ] **Step 2: 완료 알림 감지 로직 추가**

`_HomeScreenState`에 상태 추가 및 `build` 내에 ref.listen:

```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _wasMoving = false;
  bool _isShowingQuestResult = false;  // 추가
  final Set<String> _shownQuestResultIds = {};  // 추가

  @override
  Widget build(BuildContext context) {
    // 퀘스트 완료 감지
    ref.listen<List<ActiveQuest>>(questListProvider, (prev, next) {
      if (_isShowingQuestResult) return;
      final completed = next.where(
        (q) => q.status == QuestStatus.completed && !_shownQuestResultIds.contains(q.id),
      ).toList();
      if (completed.isNotEmpty) {
        _isShowingQuestResult = true;
        _shownQuestResultIds.add(completed.first.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showQuestResult(completed.first);
        });
      }
    });

    // ... 기존 코드 계속
```

```dart
void _showQuestResult(ActiveQuest quest) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => QuestResultDialog(quest: quest),
  );
  ref.read(questListProvider.notifier).clearCompleted(quest.id);
  _isShowingQuestResult = false;
  // 다음 완료된 퀘스트 체크
  final quests = ref.read(questListProvider);
  final nextCompleted = quests.where(
    (q) => q.status == QuestStatus.completed && !_shownQuestResultIds.contains(q.id),
  ).toList();
  if (nextCompleted.isNotEmpty && mounted) {
    _isShowingQuestResult = true;
    _shownQuestResultIds.add(nextCompleted.first.id);
    _showQuestResult(nextCompleted.first);
  }
}
```

- [ ] **Step 3: 용병단 대시보드 위젯 추가**

build 메서드 내 랭크 섹션과 야영지 사이에 추가:

```dart
Widget _buildDashboard(List<Mercenary> mercs, StaticGameData data, UserData userData) {
  final normalCount = mercs.where((m) => m.status == MercenaryStatus.normal && !m.isDispatched).length;
  final dispatchedCount = mercs.where((m) => m.isDispatched).length;
  final injuredCount = mercs.where((m) => m.status == MercenaryStatus.injured).length;
  final deadCount = mercs.where((m) => m.status == MercenaryStatus.dead).length;
  final totalPower = mercs.where((m) => m.isAvailable).fold<int>(0, (sum, m) => sum + m.effectiveAtk);

  final barracksData = data.facilities.where((f) => f.id == 'barracks').firstOrNull;
  final barracksLevel = userData.facilities['barracks'] ?? 0;
  final maxMercs = barracksData != null
      ? FacilityService.getMaxMercenaries(barracksData, barracksLevel)
      : 10;
  final aliveCount = mercs.where((m) => m.status != MercenaryStatus.dead).length;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('용병단 현황', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            _dashItem('보유', '$aliveCount/$maxMercs', AppTheme.textSecondary),
            _dashItem('파견 중', '$dispatchedCount', AppTheme.primary),
            _dashItem('부상', '$injuredCount', Colors.orange),
            _dashItem('사망', '$deadCount', Colors.red),
          ],
        ),
        const SizedBox(height: 4),
        Text('총 전투력: $totalPower', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
      ],
    ),
  );
}

Widget _dashItem(String label, String value, Color color) {
  return Expanded(
    child: Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
      ],
    ),
  );
}
```

- [ ] **Step 4: 활동 로그 위젯 추가**

```dart
Widget _buildActivityLog() {
  final logs = ref.watch(activityLogProvider);

  if (logs.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Text('아직 활동 기록이 없습니다.', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
    );
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('최근 활동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...logs.take(10).map((log) {
          final icon = _logIcon(log.type);
          final timeAgo = _formatTimeAgo(log.timestamp);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(log.message,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(timeAgo, style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

String _logIcon(ActivityLogType type) {
  switch (type) {
    case ActivityLogType.questResult: return '⚔';
    case ActivityLogType.mercenaryStatus: return '💊';
    case ActivityLogType.movementComplete: return '🏕';
    case ActivityLogType.mercenaryRecruit: return '🛡';
    case ActivityLogType.mercenaryDismiss: return '👋';
    case ActivityLogType.levelUp: return '⬆';
  }
}

String _formatTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}
```

- [ ] **Step 5: 홈 화면 레이아웃에 대시보드, 로그 배치**

build 메서드의 Column 내 야영지(Campsite) 위에 대시보드를, 야영지 아래에 활동 로그를 삽입:

```dart
// build() 내 기존 위젯 순서:
// Gold + location → Rank/Reputation → [대시보드 삽입] → Campsite → [활동 로그 삽입] → Progress panel

// staticData.when(data:) 내부에서:
_buildDashboard(mercs, data, userData),
const SizedBox(height: 6),
// ... campsite ...
const SizedBox(height: 6),
_buildActivityLog(),
```

- [ ] **Step 6: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 7: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/home/view/home_screen.dart && git commit -m "feat: add mercenary dashboard, activity log, and quest completion alerts to home screen"
```

---

## Task 10: 파견 중 이동 제한

파견 중인 용병이 있으면 이동 버튼을 비활성화.

**Files:**
- Modify: `lib/features/movement/view/movement_screen.dart:276-287`

- [ ] **Step 1: 파견 중 퀘스트 감지 및 버튼 비활성화**

`movement_screen.dart`의 `build` 메서드 내에서 questListProvider를 watch하고, 이동 버튼 조건에 반영:

```dart
// build() 상단에 추가:
final quests = ref.watch(questListProvider);
final hasDispatchedQuests = quests.any((q) => q.status == QuestStatus.inProgress);
```

import 추가:
```dart
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
```

이동 버튼 수정 (line 278-286):

```dart
// 기존:
// onPressed: userData.isMoving || distance == 0 || !isTargetAccessible
//     ? null
//     : () { ... },
// child: Text(userData.isMoving ? '이동 중...' : '이동 시작'),

// 변경:
onPressed: (userData.isMoving || distance == 0 || !isTargetAccessible || hasDispatchedQuests)
    ? null
    : () {
        ref.read(movementProvider.notifier)
            .startMovement(_selectedRegion, _selectedSector);
      },
child: Text(
  userData.isMoving
      ? '이동 중...'
      : hasDispatchedQuests
          ? '파견된 용병이 있습니다'
          : '이동 시작',
),
```

- [ ] **Step 2: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 3: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/movement/view/movement_screen.dart && git commit -m "feat: disable movement when mercenaries are dispatched"
```

---

## Task 11: 용병 방출 기능

방출 버튼, 퇴직금 차감, 영구 제거.

**Files:**
- Modify: `lib/features/mercenary/domain/mercenary_provider.dart`
- Modify: `lib/features/mercenary/data/mercenary_repository.dart`
- Modify: `lib/features/mercenary/view/recruit_screen.dart`

- [ ] **Step 1: mercenary_repository.dart에 dismiss 관련 메서드 추가**

```dart
// lib/features/mercenary/data/mercenary_repository.dart — 추가

// dismissedIds를 user box에 저장 (간단한 key-value)
static const String _dismissedIdsKey = 'dismissed_merc_ids';

Set<String> getDismissedIds() {
  final userBox = Hive.box<UserData>(HiveInitializer.userBoxName);
  final userData = userBox.getAt(0);
  if (userData == null) return {};
  // UserData에 dismissedIds 필드가 없으므로 별도 일반 박스 사용
  return {};
}

Future<void> dismiss(String mercId) async {
  final index = _box.values.toList().indexWhere((m) => m.id == mercId);
  if (index >= 0) {
    await _box.deleteAt(index);
  }
}
```

실제로는 dismissedIds를 별도 Hive 박스나 user box에 저장하는 것이 좋음. 간단하게 UserData에 리스트를 추가하거나, 별도 일반 Box를 사용. 여기서는 일반 Box를 사용:

```dart
// hive_initializer.dart에 추가:
static const String settingsBoxName = 'settings';
// initialize()에 추가:
await Hive.openBox(settingsBoxName);
```

```dart
// mercenary_repository.dart — 최종 버전
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';

Future<void> dismiss(String mercId) async {
  final index = _box.values.toList().indexWhere((m) => m.id == mercId);
  if (index >= 0) {
    await _box.deleteAt(index);
  }
  // 방출 ID 저장
  final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
  final dismissed = List<String>.from(settingsBox.get('dismissedMercIds', defaultValue: <String>[]));
  dismissed.add(mercId);
  await settingsBox.put('dismissedMercIds', dismissed);
}

List<String> getDismissedIds() {
  final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
  return List<String>.from(settingsBox.get('dismissedMercIds', defaultValue: <String>[]));
}
```

- [ ] **Step 2: mercenary_provider.dart에 dismiss 메서드 추가**

```dart
// lib/features/mercenary/domain/mercenary_provider.dart — MercenaryListNotifier 내부에 추가
Future<bool> dismiss(String mercId, int severancePay) async {
  final userData = ref.read(userDataProvider);
  if (userData == null || userData.gold < severancePay) return false;

  final merc = state.firstWhere((m) => m.id == mercId);
  if (merc.isDispatched) return false; // 파견 중 방출 불가

  await ref.read(userDataProvider.notifier).spendGold(severancePay);
  await _repo.dismiss(mercId);
  _load();

  // 활동 로그
  ref.read(activityLogProvider.notifier).addLog(
    '용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G)',
    ActivityLogType.mercenaryDismiss,
  );

  return true;
}
```

import 추가:
```dart
import 'package:band_of_mercenaries/features/home/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';
```

- [ ] **Step 3: recruit_screen.dart에 방출 버튼 추가**

용병 목록의 각 카드에 방출 버튼을 추가. 기존 용병 리스트 렌더링 부분에:

```dart
// 각 용병 카드에 방출 버튼 추가
// 조건: 파견 중이 아닌 용병
if (!merc.isDispatched) ...[
  TextButton(
    onPressed: () {
      final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
      final wage = data.mercenaryWages.firstWhere(
        (w) => w.tier == job.tier,
        orElse: () => data.mercenaryWages.first,
      );
      final severancePay = wage.wage * merc.level;

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('용병 방출'),
          content: Text(
            '용병 "${merc.name}"을 방출합니다.\n'
            '퇴직금 ${severancePay}G가 차감됩니다.\n\n'
            '방출된 용병은 다시 모집할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(mercenaryListProvider.notifier)
                    .dismiss(merc.id, severancePay);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('방출'),
            ),
          ],
        ),
      );
    },
    style: TextButton.styleFrom(foregroundColor: Colors.red),
    child: const Text('방출', style: TextStyle(fontSize: 12)),
  ),
],
```

- [ ] **Step 4: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 5: 커밋**

```bash
cd band_of_mercenaries && git add lib/core/data/hive_initializer.dart lib/features/mercenary/data/mercenary_repository.dart lib/features/mercenary/domain/mercenary_provider.dart lib/features/mercenary/view/recruit_screen.dart && git commit -m "feat: add mercenary discharge with severance pay"
```

---

## Task 12: 방치형 오프라인 골드 보상

앱 비활성 시간에 비례한 골드 보상.

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/core/data/hive_initializer.dart` (settings 박스 이미 Task 11에서 추가)
- Modify: `lib/main.dart`

- [ ] **Step 1: app.dart에 WidgetsBindingObserver 추가**

`MainShell`을 StatefulWidget으로 변경하거나, 별도 위젯으로 래핑:

```dart
// lib/app.dart — MainShell을 ConsumerStatefulWidget으로 변경
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  static const _screens = [
    MovementScreen(),
    DispatchScreen(),
    HomeScreen(),
    RecruitScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveLastActiveTime();
    }
  }

  void _saveLastActiveTime() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    settingsBox.put('lastActiveTime', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: SafeArea(child: _screens[currentTab]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      ),
    );
  }
}
```

import 추가:
```dart
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
```

- [ ] **Step 2: main.dart에서 앱 시작 시 방치 보상 계산 + 팝업**

AppBootstrap의 userData 로드 완료 후, 방치 보상을 계산:

```dart
// lib/main.dart — AppBootstrap의 build 수정
// userData != null인 경우 (기존 BandOfMercenariesApp 반환 부분):
return _IdleRewardWrapper(child: const BandOfMercenariesApp());
```

별도 위젯으로 분리:

```dart
// lib/main.dart에 추가
class _IdleRewardWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _IdleRewardWrapper({required this.child});

  @override
  ConsumerState<_IdleRewardWrapper> createState() => _IdleRewardWrapperState();
}

class _IdleRewardWrapperState extends ConsumerState<_IdleRewardWrapper> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIdleReward());
    }
    return widget.child;
  }

  void _checkIdleReward() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final lastActiveMs = settingsBox.get('lastActiveTime') as int?;
    if (lastActiveMs == null) return;

    final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
    final now = DateTime.now();
    final absentMinutes = now.difference(lastActive).inMinutes;

    if (absentMinutes < 1) return;

    // 분당 1G, 최대 480분(8시간)
    final rewardMinutes = absentMinutes.clamp(0, 480);
    final reward = rewardMinutes; // 1G per minute

    if (reward <= 0) return;

    ref.read(userDataProvider.notifier).addGold(reward);

    // 팝업 표시
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('부재 보상'),
          content: Text(
            '${absentMinutes > 480 ? "8시간 이상" : "${absentMinutes}분"} 동안 부재하셨습니다.\n'
            '${reward}G를 획득했습니다!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }

    // lastActiveTime 갱신
    settingsBox.put('lastActiveTime', now.millisecondsSinceEpoch);
  }
}
```

import 추가:
```dart
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
```

- [ ] **Step 3: 빌드 확인**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 4: 커밋**

```bash
cd band_of_mercenaries && git add lib/app.dart lib/main.dart && git commit -m "feat: add idle offline gold reward (1G/min, max 480G)"
```

---

## Task 13: 최종 검증

전체 빌드 및 테스트.

**Files:** 전체

- [ ] **Step 1: 전체 테스트 실행**

```bash
cd band_of_mercenaries && flutter test
```

- [ ] **Step 2: 정적 분석**

```bash
cd band_of_mercenaries && flutter analyze
```

- [ ] **Step 3: 빌드 확인**

```bash
cd band_of_mercenaries && flutter build web
```

- [ ] **Step 4: 이슈 수정**

테스트 실패나 분석 에러가 있으면 수정.

- [ ] **Step 5: 최종 커밋**

모든 수정 사항 커밋.
