import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';

class RecruitmentService {
  static bool canFreeRecruit(DateTime lastFreeRecruit, double speedMultiplier) {
    final cooldownSeconds = (GameConstants.freeRecruitCooldown.inSeconds / speedMultiplier).round();
    final nextFreeRecruit = lastFreeRecruit.add(Duration(seconds: cooldownSeconds));
    return DateTime.now().isAfter(nextFreeRecruit);
  }

  static Duration freeRecruitRemaining(DateTime lastFreeRecruit, double speedMultiplier) {
    final cooldownSeconds = (GameConstants.freeRecruitCooldown.inSeconds / speedMultiplier).round();
    final nextFreeRecruit = lastFreeRecruit.add(Duration(seconds: cooldownSeconds));
    final remaining = nextFreeRecruit.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static const _tierProbabilities = <int, double>{1: 0.45, 2: 0.30, 3: 0.15, 4: 0.08, 5: 0.02};
  static const _uuid = Uuid();

  static int selectTier(
    Random random, {
    required NewbieGate gate,
    double recruitBonus = 0.0,
    double extraHighTierBoost = 0.0,
  }) {
    // F 단계: 보너스 무시, T1 고정
    if (gate == NewbieGate.newbieF) return 1;

    // E 단계: 기본 T1 90% / T2 10%, 보너스는 T2 비율로만 흡수 (cap 0.5)
    if (gate == NewbieGate.newbieE) {
      final t2Boost = (recruitBonus + extraHighTierBoost).clamp(0.0, 0.5);
      final t2Prob = 0.10 + t2Boost * 0.5;
      return random.nextDouble() < t2Prob ? 2 : 1;
    }

    // normal 단계: 기존 분포
    final totalBonus = (recruitBonus + extraHighTierBoost).clamp(0.0, 0.5);

    if (totalBonus <= 0.0) {
      final roll = random.nextDouble();
      double cumulative = 0;
      for (final entry in _tierProbabilities.entries) {
        cumulative += entry.value;
        if (roll < cumulative) return entry.key;
      }
      return 1;
    }

    final tier1Prob = 0.45 * (1.0 - totalBonus);
    final reduction = 0.45 - tier1Prob;
    final tier2Prob = _tierProbabilities[2]! + reduction / 4;
    final tier3Prob = _tierProbabilities[3]! + reduction / 4;
    final tier4Prob = _tierProbabilities[4]! + reduction / 4;
    final tier5Prob = _tierProbabilities[5]! + reduction / 4;

    final adjusted = <int, double>{
      1: tier1Prob,
      2: tier2Prob,
      3: tier3Prob,
      4: tier4Prob,
      5: tier5Prob,
    };

    final roll = random.nextDouble();
    double cumulative = 0;
    for (final entry in adjusted.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    return 1;
  }

  static List<String> selectInnateTraits({
    required List<TraitData> traits,
    required List<TraitCategory> categories,
    required Random random,
  }) {
    final innateKeys = categories
        .where((c) => GameConstants.innateCategories.contains(c.key))
        .map((c) => c.key)
        .toList();

    final selected = <String>[];
    for (final catKey in innateKeys) {
      final catTraits = traits.where((t) => t.categoryKey == catKey && t.type == 'innate').toList();
      if (catTraits.isNotEmpty && random.nextDouble() < 0.6) {
        selected.add(catTraits[random.nextInt(catTraits.length)].key);
      }
    }
    if (selected.isEmpty) {
      final allInnate = traits.where((t) => t.type == 'innate').toList();
      if (allInnate.isNotEmpty) {
        selected.add(allInnate[random.nextInt(allInnate.length)].key);
      }
    }
    return selected;
  }

  static Mercenary generateMercenary({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<TraitCategory> categories,
    required List<PersonName> names,
    required Random random,
    required NewbieGate gate,
    int? forceTier,
    double recruitBonus = 0.0,
    double extraHighTierBoost = 0.0,
  }) {
    final tier = forceTier ?? selectTier(
          random,
          gate: gate,
          recruitBonus: recruitBonus,
          extraHighTierBoost: extraHighTierBoost,
        );
    final tierJobs = jobs.where((j) => j.tier == tier).toList();
    final job = tierJobs[random.nextInt(tierJobs.length)];
    final name = names[random.nextInt(names.length)];
    final innateTraitKeys = selectInnateTraits(traits: traits, categories: categories, random: random);

    return Mercenary(
      id: _uuid.v4(),
      name: name.korean,
      jobId: job.id,
      traitId: innateTraitKeys.first,
      str: job.baseStr,
      intelligence: job.baseIntelligence,
      vit: job.baseVit,
      agi: job.baseAgi,
      traitIds: innateTraitKeys,
      recruitedAt: DateTime.now(), // FR-41
      titleIds: const [],
    );
  }

  /// 세력 패시브 적용 후 실효 골드 모집 비용.
  /// [costMultiplier]는 PassiveBonusService.getRecruitmentCostMultiplier()의 반환값.
  static int effectivePaidCost(double costMultiplier) =>
      (GameConstants.paidRecruitCost * costMultiplier).round();

  static List<Mercenary> generateStartingMercenaries({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<TraitCategory> categories,
    required List<PersonName> names,
    required int count,
    required Random random,
  }) {
    return List.generate(count, (_) => generateMercenary(
      jobs: jobs, traits: traits, categories: categories, names: names, random: random,
      forceTier: random.nextBool() ? 1 : 2,
      gate: NewbieGate.normal,
    ));
  }
}
