# UI 개선: 파견 화면, 퀘스트 완료 팝업, 최근활동 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 파견 화면을 전체화면 페이지로 전환하고, 퀘스트 완료 팝업에 보상 상세 내역을 추가하고, 홈 화면 최근활동에 스크롤을 지원한다.

**Architecture:** 3개 독립 영역 수정. (1) 파견 화면: 바텀시트를 제거하고 `Navigator.push`로 전체화면 `DispatchDetailPage`를 추가. (2) 퀘스트 팝업: `ActiveQuest` 모델에 보상 필드 5개를 추가하고 `QuestResultDialog`에서 표시. (3) 최근활동: `Column` → `ListView.builder` 전환 + `maxLogs` 100.

**Tech Stack:** Flutter, Riverpod, Hive, build_runner

**Spec:** `Docs/superpowers/specs/2026-04-11-ui-fixes-dispatch-popup-activity-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/features/quest/domain/quest_model.dart` | ActiveQuest에 보상 필드 5개 추가 |
| Regenerate | `lib/features/quest/domain/quest_model.g.dart` | Hive adapter 재생성 |
| Modify | `lib/features/quest/data/quest_repository.dart` | completeQuest/startQuest에 보상 필드 저장 |
| Modify | `lib/features/quest/domain/quest_provider.dart` | dispatch/completeQuest에서 보상 값 계산 후 저장 |
| Modify | `lib/features/quest/view/quest_result_dialog.dart` | 보상 내역 섹션 + 버튼 텍스트 변경 |
| Create | `lib/features/quest/view/dispatch_detail_page.dart` | 전체화면 파견 페이지 |
| Modify | `lib/features/quest/view/dispatch_screen.dart` | 바텀시트 제거, Navigator.push로 전환 |
| Modify | `lib/features/home/data/activity_log_repository.dart` | maxLogs 50 → 100 |
| Modify | `lib/features/home/view/home_screen.dart` | Column → ListView.builder |

All paths relative to `band_of_mercenaries/`.

---

### Task 1: ActiveQuest 모델에 보상 필드 추가

**Files:**
- Modify: `lib/features/quest/domain/quest_model.dart:28-79`

- [ ] **Step 1: ActiveQuest에 5개 nullable 필드 추가**

`quest_model.dart`의 `ActiveQuest` 클래스에 HiveField 12~16 추가:

```dart
  @HiveField(11)
  DateTime? createdAt;

  @HiveField(12)
  int? rewardGold;

  @HiveField(13)
  int? totalWage;

  @HiveField(14)
  int? dispatchCost;

  @HiveField(15)
  int? earnedXp;

  @HiveField(16)
  int? earnedReputation;

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
    this.rewardGold,
    this.totalWage,
    this.dispatchCost,
    this.earnedXp,
    this.earnedReputation,
  });
```

- [ ] **Step 2: build_runner 실행하여 Hive adapter 재생성**

Run: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: `quest_model.g.dart` regenerated with new fields (HiveField 12~16 in read/write methods)

- [ ] **Step 3: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/domain/quest_model.dart lib/features/quest/domain/quest_model.g.dart
git commit -m "feat: add reward fields to ActiveQuest model (HiveField 12-16)"
```

---

### Task 2: Repository에서 보상 필드 저장 지원

**Files:**
- Modify: `lib/features/quest/data/quest_repository.dart:22-36`

- [ ] **Step 1: startQuest에 dispatchCost 파라미터 추가**

`quest_repository.dart`의 `startQuest` 메서드를 수정:

```dart
  Future<void> startQuest(String questId, List<String> mercIds, DateTime endTime, {int? dispatchCost}) async {
    final quest = _box.values.firstWhere((q) => q.id == questId);
    quest.dispatchedMercIds = mercIds;
    quest.startTime = DateTime.now();
    quest.endTime = endTime;
    quest.status = QuestStatus.inProgress;
    quest.dispatchCost = dispatchCost;
    await quest.save();
  }
```

- [ ] **Step 2: completeQuest에 보상 필드 파라미터 추가**

`quest_repository.dart`의 `completeQuest` 메서드를 수정:

```dart
  Future<void> completeQuest(
    String questId,
    QuestResult result, {
    int? rewardGold,
    int? totalWage,
    int? earnedXp,
    int? earnedReputation,
  }) async {
    final quest = _box.values.firstWhere((q) => q.id == questId);
    quest.status = QuestStatus.completed;
    quest.result = result;
    quest.rewardGold = rewardGold;
    quest.totalWage = totalWage;
    quest.earnedXp = earnedXp;
    quest.earnedReputation = earnedReputation;
    await quest.save();
  }
```

- [ ] **Step 3: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/data/quest_repository.dart
git commit -m "feat: add reward field params to quest repository methods"
```

---

### Task 3: Provider에서 보상 값 계산 후 저장

**Files:**
- Modify: `lib/features/quest/domain/quest_provider.dart:125-168` (dispatch)
- Modify: `lib/features/quest/domain/quest_provider.dart:242-406` (_completeQuest)

- [ ] **Step 1: dispatch()에서 dispatchCost를 repository에 전달**

`quest_provider.dart`의 `dispatch` 메서드에서 `_repo.startQuest` 호출을 수정 (line 159):

기존:
```dart
    await _repo.startQuest(questId, mercIds, endTime);
```

변경:
```dart
    await _repo.startQuest(questId, mercIds, endTime, dispatchCost: dispatchCost);
```

- [ ] **Step 2: _completeQuest()에서 보상 값을 계산하여 repository에 전달**

`quest_provider.dart`의 `_completeQuest` 메서드를 수정. 보상 계산 결과를 변수에 저장하고, `_repo.completeQuest` 호출 시 전달한다.

먼저, 보상 계산을 `_repo.completeQuest` 호출보다 앞으로 이동해야 한다. 현재 코드에서 `_repo.completeQuest(quest.id, questResult)`가 line 280에서 먼저 호출되고, 보상 계산이 line 293 이후에 실행된다. 순서를 변경한다.

`_completeQuest` 메서드를 다음과 같이 수정 (line 242~406 전체):

```dart
  Future<void> _completeQuest(ActiveQuest quest) async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final random = Random();
    final mercs = ref.read(mercenaryListProvider)
        .where((m) => quest.dispatchedMercIds.contains(m.id))
        .toList();

    final partyPower = mercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final userData = ref.read(userDataProvider);

    final distancePenalty = userData != null ? (quest.region - userData.region).abs() : 0;

    final successRate = QuestCalculator.calculateSuccessRate(
      partyPower: partyPower,
      enemyPower: difficulty.enemyPower,
      traitBonuses: mercs.map((m) => m.traitId).toList(),
      questTypeId: quest.questTypeId,
      distancePenalty: distancePenalty,
      random: random,
    );

    final roll = random.nextDouble() * 100;
    final resultType = QuestCalculator.determineResult(successRate: successRate, roll: roll);

    final questResult = switch (resultType) {
      QuestResultType.greatSuccess => QuestResult.greatSuccess,
      QuestResultType.success => QuestResult.success,
      QuestResultType.failure => QuestResult.failure,
      QuestResultType.criticalFailure => QuestResult.criticalFailure,
    };

    // Calculate reward values before saving
    int rewardGold = 0;
    int totalWage = 0;

    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      rewardGold = QuestCalculator.calculateReward(
        baseReward: questType.baseReward,
        rewardMultiplier: difficulty.rewardMultiplier,
        isGreatSuccess: resultType == QuestResultType.greatSuccess,
      );

      final mercTiers = mercs.map((merc) {
        final job = staticData.jobs.firstWhere(
          (j) => j.id == merc.jobId,
          orElse: () => staticData.jobs.first,
        );
        return job.tier;
      }).toList();

      totalWage = QuestCalculator.calculateTotalWage(mercTiers, staticData.mercenaryWages);
    }

    // Calculate XP
    final resultName = switch (resultType) {
      QuestResultType.greatSuccess => 'greatSuccess',
      QuestResultType.success => 'success',
      QuestResultType.failure => 'failure',
      QuestResultType.criticalFailure => 'criticalFailure',
    };
    final xpMultiplier = ExperienceService.resultMultiplier(resultName);

    double trainingBonus = 0.0;
    if (userData != null) {
      final trainingLevel = userData.facilities['training'] ?? 0;
      if (trainingLevel > 0) {
        final trainingFacility = staticData.facilities.firstWhere(
          (f) => f.id == 'training',
          orElse: () => staticData.facilities.first,
        );
        trainingBonus = FacilityService.getEffectValue(trainingFacility, trainingLevel);
      }
    }

    final xpGain = ExperienceService.calculateXpGain(
      difficulty: quest.difficulty.clamp(1, 5),
      resultMultiplier: xpMultiplier,
      facilityBonus: trainingBonus,
    );

    // Calculate reputation
    int repGain = 0;
    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      repGain = ReputationService.calculateQuestReputation(
        difficulty: quest.difficulty.clamp(1, 5),
        isGreatSuccess: resultType == QuestResultType.greatSuccess,
      );
    }

    // Save quest result with reward data
    await _repo.completeQuest(
      quest.id,
      questResult,
      rewardGold: rewardGold,
      totalWage: totalWage,
      earnedXp: xpGain,
      earnedReputation: repGain,
    );

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

    // Process rewards with wage deduction
    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      final netReward = rewardGold - totalWage;
      if (netReward > 0) {
        await ref.read(userDataProvider.notifier).addGold(netReward);
      }
    }

    // Process damage
    final mercRepo = ref.read(mercenaryRepositoryProvider);
    final speedMult = ref.read(speedMultiplierProvider);

    // Get infirmary bonus for recovery time reduction
    double recoveryReduction = 0.0;
    if (userData != null) {
      final infirmaryLevel = userData.facilities['infirmary'] ?? 0;
      if (infirmaryLevel > 0) {
        final infirmaryFacility = staticData.facilities.firstWhere(
          (f) => f.id == 'infirmary',
          orElse: () => staticData.facilities.first,
        );
        recoveryReduction = FacilityService.getEffectValue(infirmaryFacility, infirmaryLevel);
      }
    }

    for (final merc in mercs) {
      await mercRepo.setDispatched(merc.id, false);

      if (resultType == QuestResultType.failure || resultType == QuestResultType.criticalFailure) {
        final damageRoll = random.nextDouble();
        final damageResult = QuestCalculator.calculateDamage(
          roll: damageRoll,
          deathRate: difficulty.deathRate,
          injuryRate: difficulty.injuryRate,
          traitId: merc.traitId,
        );

        if (damageResult == DamageResult.dead) {
          await mercRepo.updateStatus(merc.id, MercenaryStatus.dead);
        } else if (damageResult == DamageResult.injured) {
          final baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMult).round();
          final adjustedRecoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction)).round();
          final recoveryTime = DateTime.now().add(Duration(seconds: adjustedRecoverySeconds));
          await mercRepo.updateStatus(merc.id, MercenaryStatus.injured, endTime: recoveryTime);
        }
      } else {
        // Success: set tired
        final tiredSeconds = (5 * 60 / speedMult).round();
        final tiredEnd = DateTime.now().add(Duration(seconds: tiredSeconds));
        await mercRepo.updateStatus(merc.id, MercenaryStatus.tired, endTime: tiredEnd);
      }
    }

    // XP distribution
    for (final merc in mercs) {
      if (merc.status != MercenaryStatus.dead) {
        await mercRepo.addXpAndCheckLevel(merc.id, xpGain);
      }
    }

    // Reputation gain on success/great success
    if (repGain > 0) {
      await ref.read(userDataProvider.notifier).addReputation(repGain);
    }

    ref.read(mercenaryListProvider.notifier).refresh();
    _load();
  }
```

- [ ] **Step 3: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/domain/quest_provider.dart
git commit -m "feat: save reward data to ActiveQuest on dispatch and completion"
```

---

### Task 4: 퀘스트 완료 팝업에 보상 상세 내역 추가

**Files:**
- Modify: `lib/features/quest/view/quest_result_dialog.dart`

- [ ] **Step 1: 보상 내역 섹션 + 버튼 텍스트 변경**

`quest_result_dialog.dart` 전체를 다음으로 교체:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

class QuestResultDialog extends ConsumerWidget {
  final ActiveQuest quest;

  const QuestResultDialog({super.key, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);
    final mercs = ref.watch(mercenaryListProvider);

    return staticData.when(
      data: (data) {
        final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
        final (label, color, bgColor) = switch (quest.result) {
          QuestResult.greatSuccess => ('대성공!', AppTheme.greatSuccess, AppTheme.greatSuccessBg),
          QuestResult.success => ('성공!', AppTheme.success, AppTheme.successBg),
          QuestResult.failure => ('실패...', AppTheme.failure, AppTheme.failureBg),
          QuestResult.criticalFailure => ('대실패...', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
          null => ('완료', AppTheme.textSecondary, AppTheme.tier1Bg),
        };

        final isSuccess = quest.result == QuestResult.greatSuccess || quest.result == QuestResult.success;
        final rewardGold = quest.rewardGold ?? 0;
        final totalWage = quest.totalWage ?? 0;
        final dispatchCost = quest.dispatchCost ?? 0;
        final netProfit = rewardGold - totalWage - dispatchCost;
        final earnedXp = quest.earnedXp ?? 0;
        final earnedReputation = quest.earnedReputation ?? 0;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('퀘스트 완료', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(quest.questName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text('${questType.name} · 난이도 ${quest.difficulty}',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                const SizedBox(height: 16),

                // Result banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
                const SizedBox(height: 16),

                // Mercenary status
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('용병 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                for (final mercId in quest.dispatchedMercIds)
                  _buildMercStatus(mercId, mercs, data),

                const SizedBox(height: 16),

                // Reward details section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('보상 내역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildRewardRow('기본 보상', '${rewardGold}G', AppTheme.textSecondary),
                      const SizedBox(height: 4),
                      _buildRewardRow('파견 비용', '-${dispatchCost}G', AppTheme.textTertiary),
                      const SizedBox(height: 4),
                      _buildRewardRow('인건비', '-${totalWage}G', AppTheme.textTertiary),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, color: AppTheme.borderLight),
                      ),
                      _buildRewardRow(
                        '순수익',
                        '${netProfit >= 0 ? '+' : ''}${netProfit}G',
                        netProfit >= 0 ? Colors.green : Colors.red,
                        isBold: true,
                      ),
                      const SizedBox(height: 4),
                      _buildRewardRow('획득 경험치', '+$earnedXp XP', AppTheme.timerBlue),
                      const SizedBox(height: 4),
                      _buildRewardRow('획득 명성', '+$earnedReputation', AppTheme.tier4),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isSuccess ? '🪙 ${netProfit}G 보상 수령' : '확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildRewardRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMercStatus(String mercId, List<Mercenary> mercs, StaticGameData data) {
    final Mercenary? merc = mercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('알 수 없는 용병', style: TextStyle(fontSize: 14)),
            Text('사망', style: TextStyle(fontSize: 14, color: AppTheme.criticalFailure, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
    final statusText = switch (merc.status) {
      MercenaryStatus.normal || MercenaryStatus.tired => '무사 귀환',
      MercenaryStatus.injured => '부상',
      MercenaryStatus.dead => '사망',
    };
    final statusColor = switch (merc.status) {
      MercenaryStatus.normal || MercenaryStatus.tired => AppTheme.textSecondary,
      MercenaryStatus.injured => AppTheme.failure,
      MercenaryStatus.dead => AppTheme.criticalFailure,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${merc.name} (${job.name})', style: const TextStyle(fontSize: 14)),
          Text(statusText, style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/view/quest_result_dialog.dart
git commit -m "feat: add reward details section to quest result dialog"
```

---

### Task 5: 전체화면 파견 페이지 생성

**Files:**
- Create: `lib/features/quest/view/dispatch_detail_page.dart`

- [ ] **Step 1: DispatchDetailPage 위젯 생성**

`dispatch_detail_page.dart` 파일을 생성:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

class DispatchDetailPage extends ConsumerStatefulWidget {
  final String questId;

  const DispatchDetailPage({super.key, required this.questId});

  @override
  ConsumerState<DispatchDetailPage> createState() => _DispatchDetailPageState();
}

class _DispatchDetailPageState extends ConsumerState<DispatchDetailPage> {
  final Set<String> _selectedMercIds = {};

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questListProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);
    final userData = ref.watch(userDataProvider);

    final quest = quests.where((q) => q.id == widget.questId).firstOrNull;
    if (quest == null || userData == null) {
      return const Scaffold(body: Center(child: Text('퀘스트를 찾을 수 없습니다')));
    }

    return staticData.when(
      data: (data) {
        final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
        final difficulty = data.difficulties.firstWhere(
          (d) => d.level == quest.difficulty.clamp(1, 5),
          orElse: () => data.difficulties.first,
        );

        // Filter mercenaries: exclude dead and dispatched
        final availableMercs = mercs.where((m) =>
          m.status != MercenaryStatus.dead && !m.isDispatched
        ).toList();

        final selectedMercs = mercs.where((m) => _selectedMercIds.contains(m.id)).toList();
        final partyPower = selectedMercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);

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
        final hasEnoughGold = userData.gold >= dispatchCost;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Top fixed: Quest info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_back, size: 22),
                            ),
                          ),
                          Expanded(
                            child: Text(quest.questName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${questType.name} · 난이도 ${quest.difficulty} · 보상 ${grossReward}G · 소요 ${questType.baseDuration}초',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),

                // Middle scroll: Mercenary list
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Text('파견 가능한 용병 (${availableMercs.length}명)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: availableMercs.length,
                          itemBuilder: (_, index) {
                            final merc = availableMercs[index];
                            final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
                            final isSelected = _selectedMercIds.contains(merc.id);
                            final canSelect = merc.status != MercenaryStatus.injured;

                            return Opacity(
                              opacity: canSelect ? 1.0 : 0.5,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                                  ),
                                ),
                                child: ListTile(
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
                                          }
                                        : null,
                                  ),
                                  title: Text(
                                    '${merc.name} (${job.name})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '전투력: ${merc.effectiveAtk}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                                  ),
                                  trailing: merc.status == MercenaryStatus.injured
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.failureBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('부상',
                                            style: TextStyle(fontSize: 11, color: AppTheme.failure, fontWeight: FontWeight.w600)),
                                        )
                                      : Text(
                                          merc.status == MercenaryStatus.tired ? '피곤함' : '정상',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom fixed: Cost summary + dispatch button
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '성공률: ${_selectedMercIds.isEmpty ? "-" : "${(partyPower / difficulty.enemyPower * 50 + 50).clamp(5, 95).round()}%"}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          Text(
                            '순수익: ${_selectedMercIds.isEmpty ? "-" : "${netProfit}G"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedMercIds.isEmpty
                                  ? AppTheme.textSecondary
                                  : (netProfit >= 0 ? Colors.green : Colors.red),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (!hasEnoughGold && _selectedMercIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('골드가 부족합니다 (파견비용: ${dispatchCost}G)',
                            style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedMercIds.isEmpty || !hasEnoughGold)
                              ? null
                              : () async {
                                  final success = await ref.read(questListProvider.notifier)
                                      .dispatch(widget.questId, _selectedMercIds.toList());
                                  if (success && mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          child: const Text('파견 출발'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
```

- [ ] **Step 2: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/view/dispatch_detail_page.dart
git commit -m "feat: create full-screen dispatch detail page"
```

---

### Task 6: DispatchScreen에서 바텀시트를 Navigator.push로 교체

**Files:**
- Modify: `lib/features/quest/view/dispatch_screen.dart`

- [ ] **Step 1: import 추가 + 바텀시트 관련 코드 제거 + Navigator.push 적용**

`dispatch_screen.dart`를 수정한다.

import 섹션에 추가:
```dart
import 'package:band_of_mercenaries/features/quest/view/dispatch_detail_page.dart';
```

`_DispatchScreenState` 클래스에서 다음을 변경:

1. `_selectedMercIds` 필드 삭제 (line 24: `final Set<String> _selectedMercIds = {};`)

2. `_buildQuestCard` 메서드의 `onTap` (line 162~168)을 수정:

기존:
```dart
      onTap: () {
        setState(() {
          _selectedQuestId = quest.id;
          _selectedMercIds.clear();
        });
        _showDispatchBottomSheet(context, mercs, data);
      },
```

변경:
```dart
      onTap: () {
        setState(() {
          _selectedQuestId = quest.id;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DispatchDetailPage(questId: quest.id),
          ),
        );
      },
```

3. 다음 메서드들을 전체 삭제:
   - `_showDispatchBottomSheet` (line 215~370)
   - `_getMercStatusText` (line 372~379)
   - `_buildCostBreakdown` (line 381~415)
   - `_buildBreakdownRow` (line 417~432)

4. 삭제한 메서드에서만 사용하던 import 정리:
   - `quest_calculator.dart` import는 dispatch_screen에서 더 이상 불필요하므로 삭제

- [ ] **Step 2: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/view/dispatch_screen.dart
git commit -m "feat: replace bottom sheet with Navigator.push to DispatchDetailPage"
```

---

### Task 7: 홈 화면 최근활동 스크롤 지원

**Files:**
- Modify: `lib/features/home/data/activity_log_repository.dart:6`
- Modify: `lib/features/home/view/home_screen.dart:306-352`

- [ ] **Step 1: maxLogs를 50에서 100으로 변경**

`activity_log_repository.dart` line 6:

기존:
```dart
  static const int maxLogs = 50;
```

변경:
```dart
  static const int maxLogs = 100;
```

- [ ] **Step 2: _buildActivityLog를 Column에서 ListView.builder로 변경**

`home_screen.dart`의 `_buildActivityLog()` 메서드를 수정:

기존 (line 316~352):
```dart
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
```

변경:
```dart
    final displayLogs = logs.take(100).toList();

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
          SizedBox(
            height: 240,
            child: ListView.builder(
              itemCount: displayLogs.length,
              itemBuilder: (_, index) {
                final log = displayLogs[index];
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
              },
            ),
          ),
        ],
      ),
    );
```

- [ ] **Step 3: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/home/data/activity_log_repository.dart lib/features/home/view/home_screen.dart
git commit -m "feat: add scrollable activity log with 100-item limit"
```

---

### Task 8: 최종 검증

- [ ] **Step 1: 전체 정적 분석**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No issues found

- [ ] **Step 2: 전체 테스트**

Run: `cd band_of_mercenaries && flutter test`
Expected: All tests pass

- [ ] **Step 3: 수동 검증 항목 확인**

앱 실행 후 다음을 확인:
1. 파견 탭 → 퀘스트 카드 탭 → 전체화면 파견 페이지로 전환되는지
2. 파견 페이지에서 사망/파견중 용병이 표시되지 않는지
3. 부상 용병에 빨간 "부상" 태그가 보이는지
4. 하단 버튼이 Android/iOS 하단에 가려지지 않는지 (SafeArea)
5. 퀘스트 완료 시 팝업에 보상 상세 내역이 표시되는지
6. 성공 시 버튼이 "🪙 NNG 보상 수령"으로 표시되는지
7. 실패 시 버튼이 "확인"으로 표시되는지
8. 홈 화면 최근활동이 스크롤 가능한지
