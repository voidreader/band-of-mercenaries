import 'dart:math';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

class TraitEventResult {
  final String? acquiredTraitKey;
  final List<SingleEvolutionCandidate> singleEvoCandidates;
  final List<ComboEvolutionCandidate> comboEvoCandidates;

  const TraitEventResult({
    this.acquiredTraitKey,
    this.singleEvoCandidates = const [],
    this.comboEvoCandidates = const [],
  });

  bool get hasEvents =>
      acquiredTraitKey != null ||
      singleEvoCandidates.isNotEmpty ||
      comboEvoCandidates.isNotEmpty;
}

class MercDamageResult {
  final String mercId;
  final MercenaryStatus newStatus;
  final DateTime? recoveryEndTime;
  final double damageRoll;

  const MercDamageResult({
    required this.mercId,
    required this.newStatus,
    this.recoveryEndTime,
    this.damageRoll = 0.0,
  });
}

class QuestCompletionResult {
  final QuestResult resultType;
  final int rewardGold;
  final int totalWage;
  final int netReward;
  final int xpGain;
  final int repGain;
  final List<MercDamageResult> mercDamages;

  const QuestCompletionResult({
    required this.resultType,
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
    final allTraitIds = mercs.expand((m) => m.allTraitIds).toSet().toList();
    final successRate = QuestCalculator.calculateSuccessRate(
      partyPower: partyPower,
      enemyPower: difficulty.enemyPower,
      traitBonuses: allTraitIds,
      questTypeId: quest.questTypeId,
      distancePenalty: distancePenalty,
      random: random,
      allTraits: staticData.traits,
      partySize: mercs.length,
    );

    final roll = random.nextDouble() * 100;
    final resultType = QuestCalculator.determineResult(successRate: successRate, roll: roll);

    // 보상 계산
    int rewardGold = 0;
    int totalWage = 0;
    if (resultType == QuestResult.greatSuccess || resultType == QuestResult.success) {
      rewardGold = QuestCalculator.calculateReward(
        baseReward: questType.baseReward,
        rewardMultiplier: difficulty.rewardMultiplier,
        isGreatSuccess: resultType == QuestResult.greatSuccess,
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
      trainingBonus = ConstructionService.getEffectValue(trainingFacility, trainingLevel);
    }
    final xpGain = ExperienceService.calculateXpGain(
      difficulty: quest.difficulty.clamp(1, 5),
      resultMultiplier: xpMultiplier,
      facilityBonus: trainingBonus,
    );

    // 명성 계산
    int repGain = 0;
    if (resultType == QuestResult.greatSuccess || resultType == QuestResult.success) {
      repGain = ReputationService.calculateQuestReputation(
        difficulty: quest.difficulty.clamp(1, 5),
        isGreatSuccess: resultType == QuestResult.greatSuccess,
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
      recoveryReduction = ConstructionService.getEffectValue(infirmaryFacility, infirmaryLevel);
    }

    double injuryReduction = 0.0;
    final fieldHospitalFacility = staticData.facilities.where((f) => f.id == 'field_hospital').firstOrNull;
    if (fieldHospitalFacility != null) {
      final fieldHospitalLevel = facilities['field_hospital'] ?? 0;
      injuryReduction = ConstructionService.getEffectValue(fieldHospitalFacility, fieldHospitalLevel);
    }

    final now = DateTime.now();
    final mercDamages = <MercDamageResult>[];
    for (final merc in mercs) {
      if (resultType == QuestResult.failure || resultType == QuestResult.criticalFailure) {
        final damageRoll = random.nextDouble();
        final damageResult = QuestCalculator.calculateDamage(
          roll: damageRoll,
          deathRate: difficulty.deathRate,
          injuryRate: difficulty.injuryRate * (1.0 - injuryReduction),
          traitId: merc.traitId,
          traitIds: merc.allTraitIds,
          allTraits: staticData.traits,
        );
        if (damageResult == DamageResult.dead) {
          mercDamages.add(MercDamageResult(mercId: merc.id, newStatus: MercenaryStatus.dead, damageRoll: damageRoll));
        } else if (damageResult == DamageResult.injured) {
          final baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMultiplier).round();
          final adjustedRecoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction)).round();
          mercDamages.add(MercDamageResult(
            mercId: merc.id,
            newStatus: MercenaryStatus.injured,
            recoveryEndTime: now.add(Duration(seconds: adjustedRecoverySeconds)),
            damageRoll: damageRoll,
          ));
        } else {
          mercDamages.add(MercDamageResult(mercId: merc.id, newStatus: MercenaryStatus.normal, damageRoll: damageRoll));
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
      rewardGold: rewardGold,
      totalWage: totalWage,
      netReward: netReward,
      xpGain: xpGain,
      repGain: repGain,
      mercDamages: mercDamages,
    );
  }
}
