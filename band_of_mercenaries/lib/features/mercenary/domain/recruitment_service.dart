import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
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

  static Mercenary generateMercenary({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<PersonName> names,
    required Random random,
    int? forceTier,
  }) {
    final tier = forceTier ?? selectTier(random);
    final tierJobs = jobs.where((j) => j.tier == tier).toList();
    final job = tierJobs[random.nextInt(tierJobs.length)];
    final trait = traits[random.nextInt(traits.length)];
    final name = names[random.nextInt(names.length)];

    int atk = job.baseAtk;
    int def = job.baseDef;
    int hp = job.baseHp;

    switch (trait.effectType) {
      case 'hp_bonus':
        hp = (hp * (1 + trait.value)).round();
        break;
      case 'atk_bonus':
        atk = (atk * (1 + trait.value)).round();
        break;
      case 'success_rate':
      case 'survival_rate':
        break;
    }

    return Mercenary(
      id: _uuid.v4(),
      name: name.korean,
      jobId: job.id,
      traitId: trait.id,
      atk: atk, def: def, hp: hp, speed: job.speed,
    );
  }

  static List<Mercenary> generateStartingMercenaries({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<PersonName> names,
    required int count,
    required Random random,
  }) {
    return List.generate(count, (_) => generateMercenary(
      jobs: jobs, traits: traits, names: names, random: random,
      forceTier: random.nextBool() ? 1 : 2,
    ));
  }
}
