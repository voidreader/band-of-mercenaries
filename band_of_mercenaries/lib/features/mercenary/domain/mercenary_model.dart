import 'package:hive/hive.dart';

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
  int atk;

  @HiveField(5)
  int def;

  @HiveField(6)
  int hp;

  @HiveField(7)
  double speed;

  @HiveField(8)
  MercenaryStatus status;

  @HiveField(9)
  DateTime? tiredEndTime;

  @HiveField(10)
  DateTime? injuryEndTime;

  @HiveField(11)
  bool isDispatched;

  Mercenary({
    required this.id,
    required this.name,
    required this.jobId,
    required this.traitId,
    required this.atk,
    required this.def,
    required this.hp,
    required this.speed,
    this.status = MercenaryStatus.normal,
    this.tiredEndTime,
    this.injuryEndTime,
    this.isDispatched = false,
  });

  int get effectiveAtk =>
      status == MercenaryStatus.tired ? (atk * 0.8).round() : atk;

  int get effectiveDef =>
      status == MercenaryStatus.tired ? (def * 0.8).round() : def;

  int get effectiveHp =>
      status == MercenaryStatus.tired ? (hp * 0.8).round() : hp;

  bool get isAvailable =>
      status != MercenaryStatus.dead &&
      status != MercenaryStatus.injured &&
      !isDispatched;
}
