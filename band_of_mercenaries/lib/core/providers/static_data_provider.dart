import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/data/json_loader.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

class StaticGameData {
  final List<Difficulty> difficulties;
  final List<Job> jobs;
  final List<TraitData> traits;
  final List<Region> regions;
  final List<QuestType> questTypes;
  final List<QuestPool> questPools;
  final List<PersonName> personNames;

  const StaticGameData({
    required this.difficulties,
    required this.jobs,
    required this.traits,
    required this.regions,
    required this.questTypes,
    required this.questPools,
    required this.personNames,
  });
}

final staticDataProvider = FutureProvider<StaticGameData>((ref) async {
  final results = await Future.wait([
    rootBundle.loadString('assets/json/Difficulty.json'),
    rootBundle.loadString('assets/json/Job.json'),
    rootBundle.loadString('assets/json/Trait.json'),
    rootBundle.loadString('assets/json/Region.json'),
    rootBundle.loadString('assets/json/QuestType.json'),
    rootBundle.loadString('assets/json/QuestPool.json'),
    rootBundle.loadString('assets/json/PersonName.json'),
  ]);

  return StaticGameData(
    difficulties: JsonLoader.parseDifficulties(results[0]),
    jobs: JsonLoader.parseJobs(results[1]),
    traits: JsonLoader.parseTraits(results[2]),
    regions: JsonLoader.parseRegions(results[3]),
    questTypes: JsonLoader.parseQuestTypes(results[4]),
    questPools: JsonLoader.parseQuestPools(results[5]),
    personNames: JsonLoader.parsePersonNames(results[6]),
  );
});
