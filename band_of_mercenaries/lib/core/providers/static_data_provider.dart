import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';

class StaticGameData {
  final List<Difficulty> difficulties;
  final List<Job> jobs;
  final List<TraitData> traits;
  final List<Region> regions;
  final List<QuestType> questTypes;
  final List<QuestPool> questPools;
  final List<PersonName> personNames;
  final List<TravelEvent> travelEvents;
  final List<Facility> facilities;
  final List<Rank> ranks;
  final List<MercenaryWage> mercenaryWages;

  const StaticGameData({
    required this.difficulties,
    required this.jobs,
    required this.traits,
    required this.regions,
    required this.questTypes,
    required this.questPools,
    required this.personNames,
    required this.travelEvents,
    required this.facilities,
    required this.ranks,
    required this.mercenaryWages,
  });
}

final staticDataProvider = FutureProvider<StaticGameData>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final cacheDir = Directory('${appDir.path}/cache');
  final dataLoader = DataLoader(cacheDir: cacheDir);

  return StaticGameData(
    difficulties: dataLoader.loadFromCache('difficulties', Difficulty.fromJson),
    jobs: dataLoader.loadFromCache('jobs', Job.fromJson),
    traits: dataLoader.loadFromCache('traits', TraitData.fromJson),
    regions: dataLoader.loadFromCache('regions', Region.fromJson),
    questTypes: dataLoader.loadFromCache('quest_types', QuestType.fromJson),
    questPools: dataLoader.loadFromCache('quest_pools', QuestPool.fromJson),
    personNames: dataLoader.loadFromCache('person_names', PersonName.fromJson),
    travelEvents: dataLoader.loadFromCache('travel_events', TravelEvent.fromJson),
    facilities: dataLoader.loadFromCache('facilities', Facility.fromJson),
    ranks: dataLoader.loadFromCache('ranks', Rank.fromJson),
    mercenaryWages: dataLoader.loadFromCache('mercenary_wages', MercenaryWage.fromJson),
  );
});
