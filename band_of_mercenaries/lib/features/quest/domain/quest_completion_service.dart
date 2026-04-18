import 'dart:math';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';

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
  final String? factionTag;
  final int factionRepGain;

  const QuestCompletionResult({
    required this.resultType,
    required this.rewardGold,
    required this.totalWage,
    required this.netReward,
    required this.xpGain,
    required this.repGain,
    required this.mercDamages,
    this.factionTag,
    this.factionRepGain = 0,
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
    CollectedEffects passiveEffects = const CollectedEffects.empty(),
  }) {
    final partyPower = QuestCalculator.calculatePartyPower(mercs, quest.questTypeId);
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final distancePenalty = (quest.region - playerRegion).abs();

    // 성공률 판정 (트레잇 + 패시브 보너스 적용)
    final allTraitIds = mercs.expand((m) => m.allTraitIds).toSet().toList();
    final passiveSuccessBonus = PassiveBonusService.getQuestSuccessRateBonus(
      passiveEffects,
      questType: quest.questTypeId,
      partySize: mercs.length,
    );
    final baseSuccessRate = QuestCalculator.calculateSuccessRate(
      partyPower: partyPower,
      enemyPower: difficulty.enemyPower,
      traitBonuses: allTraitIds,
      questTypeId: quest.questTypeId,
      distancePenalty: distancePenalty,
      random: random,
      allTraits: staticData.traits,
      partySize: mercs.length,
      partyRoles: RoleUtils.extractRoles(mercs, staticData.jobs),
    );
    final successRate = (baseSuccessRate + passiveSuccessBonus).clamp(5.0, 95.0);

    final roll = random.nextDouble() * 100;
    final resultType = QuestCalculator.determineResult(successRate: successRate, roll: roll);

    // 보상 계산 (가산 방식으로 통합)
    final passiveRewardBonus = PassiveBonusService.getQuestRewardMultiplier(
      passiveEffects,
      quest.questTypeId,
    ) - 1.0;
    final trackBonus = quest.isFactionExclusive
        ? (quest.isAdvancedTrack == true
            ? GameConstants.trackRewardAdvanced
            : GameConstants.trackRewardBasic)
        : 0.0;
    int rewardGold = 0;
    int totalWage = 0;
    if (resultType == QuestResult.greatSuccess || resultType == QuestResult.success) {
      rewardGold = QuestCalculator.calculateReward(
        baseReward: questType.baseReward,
        rewardMultiplier: difficulty.rewardMultiplier,
        isGreatSuccess: resultType == QuestResult.greatSuccess,
        trackBonus: trackBonus,
        passiveRewardBonus: passiveRewardBonus,
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
      passiveXpBonus: PassiveBonusService.getMercenaryXpBonus(passiveEffects),
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
          final passiveRecoveryMultiplier = PassiveBonusService.getRecoveryTimeMultiplier(
            passiveEffects,
            'injured',
          );
          final adjustedRecoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction) * passiveRecoveryMultiplier).round();
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

    // 세력 평판 보상 (성공/대성공 시에만 지급)
    final factionRepGain = (quest.factionTag != null &&
            (resultType == QuestResult.greatSuccess ||
                resultType == QuestResult.success))
        ? (quest.reputationReward ?? 0)
        : 0;

    return QuestCompletionResult(
      resultType: resultType,
      rewardGold: rewardGold,
      totalWage: totalWage,
      netReward: netReward,
      xpGain: xpGain,
      repGain: repGain,
      mercDamages: mercDamages,
      factionTag: quest.factionTag,
      factionRepGain: factionRepGain,
    );
  }
}
