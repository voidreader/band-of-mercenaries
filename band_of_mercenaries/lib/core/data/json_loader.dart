import 'dart:convert';
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

class JsonLoader {
  static List<Difficulty> parseDifficulties(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DifficultyList.fromJson(json).items;
  }

  static List<Job> parseJobs(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return JobList.fromJson(json).items;
  }

  static List<TraitData> parseTraits(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return TraitDataList.fromJson(json).items;
  }

  static List<Region> parseRegions(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return RegionList.fromJson(json).items;
  }

  static List<QuestType> parseQuestTypes(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QuestTypeList.fromJson(json).items;
  }

  static List<QuestPool> parseQuestPools(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QuestPoolList.fromJson(json).items;
  }

  static List<PersonName> parsePersonNames(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PersonNameList.fromJson(json).items;
  }

  static List<TravelEvent> parseTravelEvents(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return TravelEventList.fromJson(json).items;
  }

  static List<Facility> parseFacilities(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return FacilityList.fromJson(json).items;
  }

  static List<Rank> parseRanks(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return RankList.fromJson(json).items;
  }

  static List<MercenaryWage> parseMercenaryWages(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return MercenaryWageList.fromJson(json).items;
  }
}
