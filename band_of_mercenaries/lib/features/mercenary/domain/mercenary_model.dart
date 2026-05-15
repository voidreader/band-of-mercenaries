import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';

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

  @HiveField(18)
  DateTime? legendaryDeathPreventionCooldownUntil;

  /// 영구 STR 보너스 (아이템·에센스 등 외부 효과로 누적되는 정수 보정값)
  @HiveField(19)
  int permanentStr;

  /// 영구 INTELLIGENCE 보너스
  @HiveField(20)
  int permanentIntelligence;

  /// 영구 VIT 보너스
  @HiveField(21)
  int permanentVit;

  /// 영구 AGI 보너스
  @HiveField(22)
  int permanentAgi;

  /// 트레잇 학습 가속 만료 시각 (이동 선택지 `trait_acquired` 효과로 설정)
  @HiveField(23)
  DateTime? traitLearningBoostUntil;

  /// 위업 시스템 — 획득한 직함 ID 목록
  @HiveField(24)
  List<String> titleIds;

  /// 모집 시각
  @HiveField(25)
  DateTime? recruitedAt;

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
    this.legendaryDeathPreventionCooldownUntil,
    this.permanentStr = 0,
    this.permanentIntelligence = 0,
    this.permanentVit = 0,
    this.permanentAgi = 0,
    this.traitLearningBoostUntil,
    List<String>? titleIds,
    this.recruitedAt,
  })  : stats = stats ?? {},
        traitIds = traitIds ?? [],
        traitHistory = traitHistory ?? [],
        deletedTraitIds = deletedTraitIds ?? [],
        titleIds = List<String>.from(titleIds ?? <String>[]);

  List<String> get allTraitIds {
    if (traitIds.isNotEmpty) return traitIds;
    if (traitId.isNotEmpty) return [traitId];
    return [];
  }

  double get _levelBonus => (level - 1) * GameConstants.levelBonusPerLevel;

  int get effectiveStr {
    final withLevel = ((str + permanentStr) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  int get effectiveIntelligence {
    final withLevel = ((intelligence + permanentIntelligence) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  int get effectiveVit {
    final withLevel = ((vit + permanentVit) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  int get effectiveAgi {
    final withLevel = ((agi + permanentAgi) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired ? (withLevel * GameConstants.tiredDebuffMultiplier).round() : withLevel;
  }

  /// 장비 보정·정수 포함 effective STR. 공식: `(base + permanent + equipment) × (1 + levelBonus) × fatigueMod`.
  int effectiveStrWith(EquipmentStatBonus bonus) {
    final withLevel = ((str + permanentStr + bonus.str) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired
        ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
        : withLevel;
  }

  int effectiveIntelligenceWith(EquipmentStatBonus bonus) {
    final withLevel = ((intelligence + permanentIntelligence + bonus.intelligence) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired
        ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
        : withLevel;
  }

  int effectiveVitWith(EquipmentStatBonus bonus) {
    final withLevel = ((vit + permanentVit + bonus.vit) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired
        ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
        : withLevel;
  }

  int effectiveAgiWith(EquipmentStatBonus bonus) {
    final withLevel = ((agi + permanentAgi + bonus.agi) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired
        ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
        : withLevel;
  }

  bool get isAvailable =>
      status != MercenaryStatus.dead &&
      status != MercenaryStatus.injured &&
      !isDispatched;
}
