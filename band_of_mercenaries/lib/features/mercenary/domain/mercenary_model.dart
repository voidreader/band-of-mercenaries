import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';

part 'mercenary_model.g.dart';

@HiveType(typeId: 0)
enum MercenaryStatus {
  @HiveField(0)
  normal,
  @HiveField(1)
  tired,
  @HiveField(2)
  injured,
  @HiveField(3)
  dead,
}

@HiveType(typeId: 1)
class Mercenary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String jobId;

  @HiveField(3)
  final String traitId;

  @HiveField(4)
  int str;

  @HiveField(5)
  int intelligence;

  @HiveField(6)
  int vit;

  @HiveField(7)
  int agi;

  @HiveField(8)
  MercenaryStatus status;

  @HiveField(9)
  DateTime? tiredEndTime;

  @HiveField(10)
  DateTime? injuryEndTime;

  @HiveField(11)
  bool isDispatched;

  @HiveField(12)
  int xp;

  @HiveField(13)
  int level;

  @HiveField(14)
  Map<String, int> stats;

  @HiveField(15)
  List<String> traitIds;

  @HiveField(16)
  List<String> traitHistory;

  @HiveField(17)
  List<String> deletedTraitIds;

  Mercenary({
    required this.id,
    required this.name,
    required this.jobId,
    required this.traitId,
    required this.str,
    required this.intelligence,
    required this.vit,
    required this.agi,
    this.status = MercenaryStatus.normal,
    this.tiredEndTime,
    this.injuryEndTime,
    this.isDispatched = false,
    this.xp = 0,
    this.level = 1,
    Map<String, int>? stats,
    List<String>? traitIds,
    List<String>? traitHistory,
    List<String>? deletedTraitIds,
  })  : stats = stats ?? {},
        traitIds = traitIds ?? [],
        traitHistory = traitHistory ?? [],
        deletedTraitIds = deletedTraitIds ?? [];

  List<String> get allTraitIds {
    if (traitIds.isNotEmpty) return traitIds;
    if (traitId.isNotEmpty) return [traitId];
    return [];
  }

  double get _levelBonus => (level - 1) * GameConstants.levelBonusPerLevel;

  int get effectiveStr {
    final withLevel = (str * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  int get effectiveIntelligence {
    final withLevel = (intelligence * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  int get effectiveVit {
    final withLevel = (vit * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  int get effectiveAgi {
    final withLevel = (agi * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  bool get isAvailable =>
      status != MercenaryStatus.dead &&
      status != MercenaryStatus.injured &&
      !isDispatched;
}
