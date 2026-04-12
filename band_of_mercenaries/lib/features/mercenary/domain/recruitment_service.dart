import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';

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

  static int selectTier(Random random) {
    final roll = random.nextDouble();
    double cumulative = 0;
    for (final entry in _tierProbabilities.entries) {
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
    int? forceTier,
  }) {
    final tier = forceTier ?? selectTier(random);
    final tierJobs = jobs.where((j) => j.tier == tier).toList();
    final job = tierJobs[random.nextInt(tierJobs.length)];
    final name = names[random.nextInt(names.length)];
    final innateTraitKeys = selectInnateTraits(traits: traits, categories: categories, random: random);

    final int atk = job.baseAtk;
    final int def = job.baseDef;
    final int hp = job.baseHp;

    return Mercenary(
      id: _uuid.v4(),
      name: name.korean,
      jobId: job.id,
      traitId: innateTraitKeys.first,
      atk: atk, def: def, hp: hp, speed: job.speed,
      traitIds: innateTraitKeys,
    );
  }

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
    ));
  }
}
