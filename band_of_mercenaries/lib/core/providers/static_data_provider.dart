import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_discovery_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/elite_loot_entry.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/core/models/quest_narrative_data.dart';

class StaticGameData {
  final List<Difficulty> difficulties;
  final List<Job> jobs;
  final List<TraitData> traits;
  final List<TraitCategory> traitCategories;
  final List<TraitConflict> traitConflicts;
  final List<TraitTransition> traitTransitions;
  final List<TraitComboEvolution> traitComboEvolutions;
  final List<TraitSynergy> traitSynergies;
  final List<Region> regions;
  final List<QuestType> questTypes;
  final List<QuestPool> questPools;
  final List<PersonName> personNames;
  final List<TravelEvent> travelEvents;
  final List<Facility> facilities;
  final List<Rank> ranks;
  final List<MercenaryWage> mercenaryWages;
  final List<RegionDiscoveryData> regionDiscoveries;
  final List<FactionData> factions;
  final List<ItemData> items;
  final List<EliteMonsterData> eliteMonsters;
  final List<EliteLootEntry> eliteLootEntries;
  final List<ChainQuestData> chainQuests;
  final List<QuestNarrativeData> questNarratives;

  const StaticGameData({
    required this.difficulties,
    required this.jobs,
    required this.traits,
    required this.traitCategories,
    required this.traitConflicts,
    required this.traitTransitions,
    required this.traitComboEvolutions,
    required this.traitSynergies,
    required this.regions,
    required this.questTypes,
    required this.questPools,
    required this.personNames,
    required this.travelEvents,
    required this.facilities,
    required this.ranks,
    required this.mercenaryWages,
    required this.regionDiscoveries,
    required this.factions,
    required this.items,
    required this.eliteMonsters,
    required this.eliteLootEntries,
    required this.chainQuests,
    required this.questNarratives,
  });
}

final staticDataProvider = FutureProvider<StaticGameData>((ref) async {
  final cacheBox = Hive.box<String>(HiveInitializer.staticDataCacheBoxName);
  final dataLoader = DataLoader(cacheBox: cacheBox);

  return StaticGameData(
    difficulties: dataLoader.loadFromCache('difficulties', Difficulty.fromJson),
    jobs: dataLoader.loadFromCache('jobs', Job.fromJson),
    traits: dataLoader.loadFromCache('traits', TraitData.fromJson),
    traitCategories: dataLoader.loadFromCache('trait_categories', TraitCategory.fromJson),
    traitConflicts: dataLoader.loadFromCache('trait_conflicts', TraitConflict.fromJson),
    traitTransitions: dataLoader.loadFromCache('trait_transitions', TraitTransition.fromJson),
    traitComboEvolutions: dataLoader.loadFromCache('trait_combo_evolutions', TraitComboEvolution.fromJson),
    traitSynergies: dataLoader.loadFromCache('trait_synergies', TraitSynergy.fromJson),
    regions: dataLoader.loadFromCache('regions', Region.fromJson),
    questTypes: dataLoader.loadFromCache('quest_types', QuestType.fromJson),
    questPools: dataLoader.loadFromCache('quest_pools', QuestPool.fromJson),
    personNames: dataLoader.loadFromCache('person_names', PersonName.fromJson),
    travelEvents: dataLoader.loadFromCache('travel_events', TravelEvent.fromJson),
    facilities: dataLoader.loadFromCache('facilities', Facility.fromJson),
    ranks: dataLoader.loadFromCache('ranks', Rank.fromJson),
    mercenaryWages: dataLoader.loadFromCache('mercenary_wages', MercenaryWage.fromJson),
    regionDiscoveries: dataLoader.loadFromCache('region_discoveries', RegionDiscoveryData.fromJson),
    factions: dataLoader.loadFromCache('factions', FactionData.fromJson),
    items: dataLoader.loadFromCache('items', ItemData.fromJson),
    eliteMonsters: dataLoader.loadFromCache('elite_monsters', EliteMonsterData.fromJson),
    eliteLootEntries: dataLoader.loadFromCache('elite_loot_tables', EliteLootEntry.fromJson),
    chainQuests: dataLoader.loadFromCache('chain_quests', ChainQuestData.fromJson),
    questNarratives: dataLoader.loadFromCache('quest_narratives', QuestNarrativeData.fromJson),
  );
});
