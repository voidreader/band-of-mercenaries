import 'dart:math';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_effect_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

enum DamageResult { dead, injured, survived }

class QuestCalculator {
  static const Map<String, double> _questModifiers = {
    'explore': 5.0, 'escort': 3.0, 'raid': 0.0, 'hunt': -5.0,
  };

  static double calculateSuccessRate({
    required int partyPower,
    required int enemyPower,
    required List<String> traitBonuses,
    required String questTypeId,
    required int distancePenalty,
    required Random random,
    List<TraitData> allTraits = const [],
    int partySize = 1,
  }) {
    if (enemyPower <= 0) return 95.0;
    final powerRatio = partyPower / enemyPower;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final traitBonus = TraitEffectService.calculateSuccessRateBonus(
      traitIds: traitBonuses, allTraits: allTraits,
      questTypeId: questTypeId, partySize: partySize,
    );
    final randomVariance = (random.nextDouble() * 10.0) - 5.0;

    final rate = 50.0 + (powerRatio - 1.0) * 50.0 + traitBonus + questMod - distancePenalty.toDouble() + randomVariance;
    return rate.clamp(5.0, 95.0);
  }

  static double calculateSuccessRatePreview({
    required int partyPower,
    required int enemyPower,
    required List<String> traitBonuses,
    required String questTypeId,
    required int distancePenalty,
    List<TraitData> allTraits = const [],
    int partySize = 1,
  }) {
    if (enemyPower <= 0) return 95.0;
    final powerRatio = partyPower / enemyPower;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final traitBonus = TraitEffectService.calculateSuccessRateBonus(
      traitIds: traitBonuses, allTraits: allTraits,
      questTypeId: questTypeId, partySize: partySize,
    );
    final rate = 50.0 + (powerRatio - 1.0) * 50.0 + traitBonus + questMod - distancePenalty.toDouble();
    return rate.clamp(5.0, 95.0);
  }

  static QuestResult determineResult({required double successRate, required double roll}) {
    final greatSuccessThreshold = successRate * 0.3;
    final successThreshold = successRate;
    final failureThreshold = successRate + (100 - successRate) * 0.7;

    if (roll <= greatSuccessThreshold) return QuestResult.greatSuccess;
    if (roll <= successThreshold) return QuestResult.success;
    if (roll <= failureThreshold) return QuestResult.failure;
    return QuestResult.criticalFailure;
  }

  static int calculateReward({required int baseReward, required double rewardMultiplier, bool isGreatSuccess = false}) {
    final reward = (baseReward * rewardMultiplier).round();
    return isGreatSuccess ? reward * 2 : reward;
  }

  static DamageResult calculateDamage({
    required double roll,
    required double deathRate,
    required double injuryRate,
    required String traitId,
    List<String> traitIds = const [],
    List<TraitData> allTraits = const [],
  }) {
    final ids = traitIds.isNotEmpty ? traitIds : (traitId.isNotEmpty ? [traitId] : <String>[]);
    final deathMod = TraitEffectService.calculateDeathRateModifier(traitIds: ids, allTraits: allTraits);
    final injuryMod = TraitEffectService.calculateInjuryRateModifier(traitIds: ids, allTraits: allTraits);
    final effectiveDeathRate = (deathRate + deathMod).clamp(0.0, 1.0);
    final effectiveInjuryRate = (injuryRate + injuryMod).clamp(0.0, 1.0);

    if (roll < effectiveDeathRate) return DamageResult.dead;
    if (roll < effectiveInjuryRate) return DamageResult.injured;
    return DamageResult.survived;
  }

  static Duration calculateDispatchDuration({required int baseDuration, required int difficulty, required double speedMultiplier}) {
    final multiplier = 1.0 + (difficulty - 1) * 0.2;
    final seconds = (baseDuration * multiplier / speedMultiplier).round();
    return Duration(seconds: seconds);
  }

  static int calculateTotalWage(List<int> mercTiers, List<MercenaryWage> wages) {
    int total = 0;
    for (final tier in mercTiers) {
      final wage = wages.firstWhere((w) => w.tier == tier, orElse: () => const MercenaryWage(tier: 1, wage: 10));
      total += wage.wage;
    }
    return total;
  }

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

  static int calculateNetProfit({required int totalReward, required int totalWage, required int dispatchCost}) {
    return totalReward - totalWage - dispatchCost;
  }
}
