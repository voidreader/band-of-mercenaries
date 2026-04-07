import 'dart:math';

enum QuestResultType { greatSuccess, success, failure, criticalFailure }

enum DamageResult { dead, injured, survived }

class QuestCalculator {
  static const Map<String, double> _questModifiers = {
    'explore': 5.0, 'escort': 3.0, 'loot': 0.0, 'hunt': -5.0,
  };

  static double calculateSuccessRate({
    required int partyPower,
    required int enemyPower,
    required List<String> traitBonuses,
    required String questTypeId,
    required int distancePenalty,
    required Random random,
  }) {
    final powerRatio = partyPower / enemyPower;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final traitBonus = traitBonuses.contains('veteran') ? 10.0 : 0.0;
    final randomVariance = (random.nextDouble() * 10.0) - 5.0;

    final rate = 50.0 + (powerRatio - 1.0) * 50.0 + traitBonus + questMod - distancePenalty.toDouble() + randomVariance;
    return rate.clamp(5.0, 95.0);
  }

  static QuestResultType determineResult({required double successRate, required double roll}) {
    final greatSuccessThreshold = successRate * 0.3;
    final successThreshold = successRate;
    final failureThreshold = successRate + (100 - successRate) * 0.7;

    if (roll <= greatSuccessThreshold) return QuestResultType.greatSuccess;
    if (roll <= successThreshold) return QuestResultType.success;
    if (roll <= failureThreshold) return QuestResultType.failure;
    return QuestResultType.criticalFailure;
  }

  static int calculateReward({required int baseReward, required double rewardMultiplier, bool isGreatSuccess = false}) {
    final reward = (baseReward * rewardMultiplier).round();
    return isGreatSuccess ? reward * 2 : reward;
  }

  static DamageResult calculateDamage({required double roll, required double deathRate, required double injuryRate, required String traitId}) {
    double effectiveDeathRate = deathRate;
    double effectiveInjuryRate = injuryRate;
    if (traitId == 'coward') effectiveDeathRate *= 0.7;
    if (traitId == 'strong') effectiveInjuryRate *= 0.8;

    if (roll < effectiveDeathRate) return DamageResult.dead;
    if (roll < effectiveInjuryRate) return DamageResult.injured;
    return DamageResult.survived;
  }

  static Duration calculateDispatchDuration({required int baseDuration, required int difficulty, required double speedMultiplier}) {
    final multiplier = 1.0 + (difficulty - 1) * 0.2;
    final seconds = (baseDuration * multiplier / speedMultiplier).round();
    return Duration(seconds: seconds);
  }
}
