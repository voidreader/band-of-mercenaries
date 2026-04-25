import 'dart:math';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_effect_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_synergy_matrix.dart';
import 'package:band_of_mercenaries/features/quest/domain/success_rate_breakdown.dart';

enum DamageResult { dead, injured, survived }

class QuestCalculator {
  static const Map<String, double> _questModifiers = {
    'explore': 5.0, 'escort': 3.0, 'raid': 0.0, 'hunt': -5.0,
  };

  static const Map<String, Map<String, double>> _statWeights = {
    'raid':    {'str': 0.70, 'intelligence': 0.10, 'vit': 0.10, 'agi': 0.10},
    'hunt':    {'str': 0.50, 'intelligence': 0.10, 'vit': 0.10, 'agi': 0.30},
    'escort':  {'str': 0.20, 'intelligence': 0.10, 'vit': 0.60, 'agi': 0.10},
    'explore': {'str': 0.10, 'intelligence': 0.45, 'vit': 0.15, 'agi': 0.30},
  };

  static double mercPower(Mercenary merc, String questTypeId) {
    final weights = _statWeights[questTypeId] ?? _statWeights['raid']!;
    return merc.effectiveStr * weights['str']! +
        merc.effectiveIntelligence * weights['intelligence']! +
        merc.effectiveVit * weights['vit']! +
        merc.effectiveAgi * weights['agi']!;
  }

  static int calculatePartyPower(
    List<Mercenary> mercs,
    String questTypeId, {
    Map<String, EquipmentStatBonus>? equipmentBonuses,
  }) {
    if (mercs.isEmpty) return 0;
    final w = _statWeights[questTypeId] ?? _statWeights['raid']!;
    return mercs.fold<int>(0, (sum, m) {
      final str = equipmentBonuses == null
          ? m.effectiveStr
          : m.effectiveStrWith(equipmentBonuses[m.id] ?? EquipmentStatBonus.zero);
      final intel = equipmentBonuses == null
          ? m.effectiveIntelligence
          : m.effectiveIntelligenceWith(equipmentBonuses[m.id] ?? EquipmentStatBonus.zero);
      final vit = equipmentBonuses == null
          ? m.effectiveVit
          : m.effectiveVitWith(equipmentBonuses[m.id] ?? EquipmentStatBonus.zero);
      final agi = equipmentBonuses == null
          ? m.effectiveAgi
          : m.effectiveAgiWith(equipmentBonuses[m.id] ?? EquipmentStatBonus.zero);
      return sum + (str * w['str']! + intel * w['intelligence']! + vit * w['vit']! + agi * w['agi']!).round();
    });
  }

  static double calculateSuccessRate({
    required int partyPower,
    required int enemyPower,
    required List<String> traitBonuses,
    required String questTypeId,
    required int distancePenalty,
    required Random random,
    List<TraitData> allTraits = const [],
    int partySize = 1,
    double factionPassiveBonus = 0.0,
    List<String> partyRoles = const [],
    double legendarySuccessBonus = 0.0,
  }) {
    if (enemyPower <= 0) return 95.0;
    final powerRatio = partyPower / enemyPower;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final rawTraitBonus = TraitEffectService.calculateSuccessRateBonus(
      traitIds: traitBonuses, allTraits: allTraits,
      questTypeId: questTypeId, partySize: partySize,
    );
    final traitBonus = (rawTraitBonus + legendarySuccessBonus).clamp(-10.0, 10.0);
    final roleSynergyBonus = RoleSynergyMatrix.partyAverageBonus(
      partyRoles: partyRoles,
      questTypeId: questTypeId,
    );
    final randomVariance = (random.nextDouble() * 10.0) - 5.0;

    final rate = 50.0 + (powerRatio - 1.0) * 50.0 + traitBonus + questMod
        - distancePenalty.toDouble() + roleSynergyBonus + factionPassiveBonus + randomVariance;
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
    double factionPassiveBonus = 0.0,
    List<String> partyRoles = const [],
    double legendarySuccessBonus = 0.0,
  }) {
    if (enemyPower <= 0) return 95.0;
    final powerRatio = partyPower / enemyPower;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final rawTraitBonus = TraitEffectService.calculateSuccessRateBonus(
      traitIds: traitBonuses, allTraits: allTraits,
      questTypeId: questTypeId, partySize: partySize,
    );
    final traitBonus = (rawTraitBonus + legendarySuccessBonus).clamp(-10.0, 10.0);
    final roleSynergyBonus = RoleSynergyMatrix.partyAverageBonus(
      partyRoles: partyRoles,
      questTypeId: questTypeId,
    );
    final rate = 50.0 + (powerRatio - 1.0) * 50.0 + traitBonus + questMod
        - distancePenalty.toDouble() + roleSynergyBonus + factionPassiveBonus;
    return rate.clamp(5.0, 95.0);
  }

  /// 성공률 레이어별 분해 결과 반환. preview 용도로만 사용 (randomVariance 제외).
  /// factionPassiveBonus는 호출측이 clamp 적용된 값, sharedCapLoss는 초과 손실량(양수).
  static SuccessRateBreakdown calculateSuccessRateBreakdown({
    required int partyPower,
    required int enemyPower,
    required List<String> traitBonuses,
    required String questTypeId,
    required int distancePenalty,
    List<TraitData> allTraits = const [],
    int partySize = 1,
    double factionPassiveBonus = 0.0,
    double passiveSharedCapLoss = 0.0,
    List<String> partyRoles = const [],
    double legendarySuccessBonus = 0.0,
  }) {
    const base = 50.0;
    if (enemyPower <= 0) {
      return const SuccessRateBreakdown(
        base: base,
        powerRatioContribution: 0.0,
        questMod: 0.0,
        roleSynergy: 0.0,
        traitBonus: 0.0,
        factionPassiveBonus: 0.0,
        sharedCapLoss: 0.0,
        distancePenalty: 0.0,
        total: 95.0,
        finalRate: 95.0,
      );
    }
    final powerRatio = partyPower / enemyPower;
    final powerRatioContribution = (powerRatio - 1.0) * 50.0;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final rawTraitBonus = TraitEffectService.calculateSuccessRateBonus(
      traitIds: traitBonuses,
      allTraits: allTraits,
      questTypeId: questTypeId,
      partySize: partySize,
    );
    final traitBonus = (rawTraitBonus + legendarySuccessBonus).clamp(-10.0, 10.0);
    final roleSynergy = RoleSynergyMatrix.partyAverageBonus(
      partyRoles: partyRoles,
      questTypeId: questTypeId,
    );
    final distancePenaltyValue = -distancePenalty.toDouble();
    final total = base
        + powerRatioContribution
        + questMod
        + roleSynergy
        + traitBonus
        + factionPassiveBonus
        + distancePenaltyValue;
    final finalRate = total.clamp(5.0, 95.0);
    return SuccessRateBreakdown(
      base: base,
      powerRatioContribution: powerRatioContribution,
      questMod: questMod,
      roleSynergy: roleSynergy,
      traitBonus: traitBonus,
      factionPassiveBonus: factionPassiveBonus,
      sharedCapLoss: passiveSharedCapLoss,
      distancePenalty: distancePenaltyValue,
      total: total,
      finalRate: finalRate,
    );
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

  static int calculateReward({
    required int baseReward,
    required double rewardMultiplier,
    bool isGreatSuccess = false,
    // 전용 퀘스트 트랙 보너스 (basic: 0.30 / advanced: 0.40), 기본값 0.0으로 하위 호환
    double trackBonus = 0.0,
    // PassiveBonusService 결과에서 변환한 가산값 (랭크 quest_reward_multiplier 포함)
    double passiveRewardBonus = 0.0,
  }) {
    // 가산 보너스 합산, 최대 +0.80 상한 적용
    final stackedBonus = (trackBonus + passiveRewardBonus).clamp(0.0, 0.80);
    final reward = (baseReward * rewardMultiplier * (1 + stackedBonus)).round();
    return isGreatSuccess ? reward * 2 : reward;
  }

  static DamageResult calculateDamage({
    required double roll,
    required double deathRate,
    required double injuryRate,
    required String traitId,
    List<String> traitIds = const [],
    List<TraitData> allTraits = const [],
    List<LegendaryEffect> legendaryEffects = const [],
  }) {
    final ids = traitIds.isNotEmpty ? traitIds : (traitId.isNotEmpty ? [traitId] : <String>[]);
    final deathMod = TraitEffectService.calculateDeathRateModifier(traitIds: ids, allTraits: allTraits);
    final injuryMod = TraitEffectService.calculateInjuryRateModifier(traitIds: ids, allTraits: allTraits);

    // 전설 ③ damage_resistance 합산 (trait 수정치와 동일 가산 스태킹)
    double legendaryDeathMod = 0.0;
    double legendaryInjuryMod = 0.0;
    for (final e in legendaryEffects) {
      if (e is LegendaryDamageResistance) {
        legendaryDeathMod += e.deathMod;
        legendaryInjuryMod += e.injuryMod;
      }
    }

    final effectiveDeathRate = (deathRate + deathMod + legendaryDeathMod).clamp(0.0, 1.0);
    final effectiveInjuryRate = (injuryRate + injuryMod + legendaryInjuryMod).clamp(0.0, 1.0);

    if (roll < effectiveDeathRate) return DamageResult.dead;
    if (roll < effectiveInjuryRate) return DamageResult.injured;
    return DamageResult.survived;
  }

  static Duration calculateDispatchDuration({
    required int baseDuration,
    required int difficulty,
    required double speedMultiplier,
    int partyAverageAgi = 50,
  }) {
    final multiplier = 1.0 + (difficulty - 1) * 0.2;
    final agiMultiplier = partyAverageAgi.clamp(1, 999) / 50.0;
    final seconds = (baseDuration * multiplier / (speedMultiplier * agiMultiplier)).round();
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
