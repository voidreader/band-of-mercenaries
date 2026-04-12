import 'dart:math';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';

class MercDamageResult {
  final String mercId;
  final MercenaryStatus newStatus;
  final DateTime? recoveryEndTime;

  const MercDamageResult({
    required this.mercId,
    required this.newStatus,
    this.recoveryEndTime,
  });
}

class QuestCompletionResult {
  final QuestResultType resultType;
  final QuestResult questResult;
  final int rewardGold;
  final int totalWage;
  final int netReward;
  final int xpGain;
  final int repGain;
  final List<MercDamageResult> mercDamages;

  const QuestCompletionResult({
    required this.resultType,
    required this.questResult,
    required this.rewardGold,
    required this.totalWage,
    required this.netReward,
    required this.xpGain,
    required this.repGain,
    required this.mercDamages,
  });
}

class QuestCompletionService {
  static QuestCompletionResult calculate({
    required ActiveQuest quest,
    required List<Mercenary> mercs,
    required StaticGameData staticData,
    required int playerRegion,
    required Map<String, int> facilities,
    required double speedMultiplier,
    required Random random,
  }) {
    final partyPower = mercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final distancePenalty = (quest.region - playerRegion).abs();

    // 성공률 판정
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

    // 보상 계산
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

    final netReward = rewardGold > 0 ? rewardGold - totalWage : 0;

    // XP 계산
    final xpMultiplier = ExperienceService.resultMultiplier(resultType);
    double trainingBonus = 0.0;
    final trainingLevel = facilities['training'] ?? 0;
    if (trainingLevel > 0) {
      final trainingFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'training',
        orElse: () => staticData.facilities.first,
      );
      trainingBonus = FacilityService.getEffectValue(trainingFacility, trainingLevel);
    }
    final xpGain = ExperienceService.calculateXpGain(
      difficulty: quest.difficulty.clamp(1, 5),
      resultMultiplier: xpMultiplier,
      facilityBonus: trainingBonus,
    );

    // 명성 계산
    int repGain = 0;
    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      repGain = ReputationService.calculateQuestReputation(
        difficulty: quest.difficulty.clamp(1, 5),
        isGreatSuccess: resultType == QuestResultType.greatSuccess,
      );
    }

    // 데미지 계산
    double recoveryReduction = 0.0;
    final infirmaryLevel = facilities['infirmary'] ?? 0;
    if (infirmaryLevel > 0) {
      final infirmaryFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'infirmary',
        orElse: () => staticData.facilities.first,
      );
      recoveryReduction = FacilityService.getEffectValue(infirmaryFacility, infirmaryLevel);
    }

    final now = DateTime.now();
    final mercDamages = <MercDamageResult>[];
    for (final merc in mercs) {
      if (resultType == QuestResultType.failure || resultType == QuestResultType.criticalFailure) {
        final damageRoll = random.nextDouble();
        final damageResult = QuestCalculator.calculateDamage(
          roll: damageRoll,
          deathRate: difficulty.deathRate,
          injuryRate: difficulty.injuryRate,
          traitId: merc.traitId,
        );
        if (damageResult == DamageResult.dead) {
          mercDamages.add(MercDamageResult(mercId: merc.id, newStatus: MercenaryStatus.dead));
        } else if (damageResult == DamageResult.injured) {
          final baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMultiplier).round();
          final adjustedRecoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction)).round();
          mercDamages.add(MercDamageResult(
            mercId: merc.id,
            newStatus: MercenaryStatus.injured,
            recoveryEndTime: now.add(Duration(seconds: adjustedRecoverySeconds)),
          ));
        } else {
          mercDamages.add(MercDamageResult(mercId: merc.id, newStatus: MercenaryStatus.normal));
        }
      } else {
        final tiredSeconds = (5 * 60 / speedMultiplier).round();
        mercDamages.add(MercDamageResult(
          mercId: merc.id,
          newStatus: MercenaryStatus.tired,
          recoveryEndTime: now.add(Duration(seconds: tiredSeconds)),
        ));
      }
    }

    return QuestCompletionResult(
      resultType: resultType,
      questResult: questResult,
      rewardGold: rewardGold,
      totalWage: totalWage,
      netReward: netReward,
      xpGain: xpGain,
      repGain: repGain,
      mercDamages: mercDamages,
    );
  }
}
