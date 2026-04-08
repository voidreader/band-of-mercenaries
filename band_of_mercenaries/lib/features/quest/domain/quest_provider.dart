import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/quest/data/quest_repository.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

final questRepositoryProvider = Provider((ref) => QuestRepository());

final questListProvider = StateNotifierProvider<QuestListNotifier, List<ActiveQuest>>((ref) {
  return QuestListNotifier(ref);
});

class QuestListNotifier extends StateNotifier<List<ActiveQuest>> {
  final Ref ref;
  late final QuestRepository _repo;

  QuestListNotifier(this.ref) : super([]) {
    _repo = ref.read(questRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (prev, next) => _checkCompletions());
  }

  void _load() {
    state = _repo.getAll();
  }

  void refresh() => _load();

  Future<void> generateQuests() async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final region = staticData.regions.firstWhere((r) => r.region == userData.region);

    // Use intelligence facility bonus for quest count
    int questCount = 5;
    final intelligenceLevel = userData.facilities['intelligence'] ?? 0;
    if (intelligenceLevel > 0) {
      final intelligenceFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'intelligence',
        orElse: () => staticData.facilities.first,
      );
      questCount += FacilityService.getExtraQuestCount(intelligenceFacility, intelligenceLevel);
    }

    await _repo.clearPending();
    final quests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: questCount,
      random: Random(),
    );
    await _repo.addQuests(quests);
    _load();
  }

  Future<bool> dispatch(String questId, List<String> mercIds) async {
    final staticData = ref.read(staticDataProvider).value;
    final speedMult = ref.read(speedMultiplierProvider);
    if (staticData == null) return false;

    final quest = state.firstWhere((q) => q.id == questId);
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);

    // Check dispatch cost
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < difficulty.dispatchCost) {
      return false;
    }

    // Deduct dispatch cost
    await ref.read(userDataProvider.notifier).spendGold(difficulty.dispatchCost);

    final duration = QuestCalculator.calculateDispatchDuration(
      baseDuration: questType.baseDuration,
      difficulty: quest.difficulty,
      speedMultiplier: speedMult,
    );

    final endTime = DateTime.now().add(duration);
    await _repo.startQuest(questId, mercIds, endTime);

    final mercNotifier = ref.read(mercenaryListProvider.notifier);
    for (final mercId in mercIds) {
      await ref.read(mercenaryRepositoryProvider).setDispatched(mercId, true);
    }
    mercNotifier.refresh();
    _load();
    return true;
  }

  void _checkCompletions() {
    final now = DateTime.now();
    for (final quest in state) {
      if (quest.status == QuestStatus.inProgress && quest.endTime != null) {
        if (now.isAfter(quest.endTime!)) {
          _completeQuest(quest);
        }
      }
    }
  }

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

    await _repo.completeQuest(quest.id, questResult);

    // Process rewards with wage deduction
    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      final grossReward = QuestCalculator.calculateReward(
        baseReward: questType.baseReward,
        rewardMultiplier: difficulty.rewardMultiplier,
        isGreatSuccess: resultType == QuestResultType.greatSuccess,
      );

      // Get merc tiers for wage calculation
      final mercTiers = mercs.map((merc) {
        final job = staticData.jobs.firstWhere(
          (j) => j.id == merc.jobId,
          orElse: () => staticData.jobs.first,
        );
        return job.tier;
      }).toList();

      final totalWage = QuestCalculator.calculateTotalWage(mercTiers, staticData.mercenaryWages);
      final netReward = (grossReward - totalWage).clamp(0, grossReward);
      await ref.read(userDataProvider.notifier).addGold(netReward);
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

    // Task 13: XP distribution
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

    for (final merc in mercs) {
      if (merc.status != MercenaryStatus.dead) {
        await mercRepo.addXpAndCheckLevel(merc.id, xpGain);
      }
    }

    // Task 13: Reputation gain on success/great success
    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      final repGain = ReputationService.calculateQuestReputation(
        difficulty: quest.difficulty.clamp(1, 5),
        isGreatSuccess: resultType == QuestResultType.greatSuccess,
      );
      await ref.read(userDataProvider.notifier).addReputation(repGain);
    }

    ref.read(mercenaryListProvider.notifier).refresh();
    _load();
  }
}
