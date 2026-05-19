// M8b 페이즈 4 #2 — 파견 시작 시점 용병 스냅샷 (typeId 26)
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';

part 'combatant_snapshot.g.dart';

@HiveType(typeId: 26)
class CombatantSnapshot extends HiveObject {
  @HiveField(0)
  String mercId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String jobId;

  @HiveField(3)
  int tier;

  @HiveField(4)
  int level;

  /// EquipmentStatBonus 반영된 동결값
  @HiveField(5)
  int effectiveStr;

  @HiveField(6)
  int effectiveInt;

  @HiveField(7)
  int effectiveVit;

  @HiveField(8)
  int effectiveAgi;

  @HiveField(9)
  List<String> titleIds;

  /// 선천 + 후천 합산
  @HiveField(10)
  List<String> traitIds;

  @HiveField(11)
  List<String> equippedItemIds;

  /// jobs.role
  @HiveField(12)
  String role;

  /// 진형 배치
  @HiveField(13)
  PositionRow positionRow;

  /// 동일 row 내 순서
  @HiveField(14)
  int positionIndex;

  CombatantSnapshot({
    required this.mercId,
    required this.name,
    required this.jobId,
    required this.tier,
    required this.level,
    required this.effectiveStr,
    required this.effectiveInt,
    required this.effectiveVit,
    required this.effectiveAgi,
    this.titleIds = const [],
    this.traitIds = const [],
    this.equippedItemIds = const [],
    required this.role,
    required this.positionRow,
    required this.positionIndex,
  });
}
