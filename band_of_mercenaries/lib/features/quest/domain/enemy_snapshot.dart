// M8b 페이즈 4 #2 — 전투 적 스냅샷 영속 모델 (typeId 27)
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';

part 'enemy_snapshot.g.dart';

@HiveType(typeId: 27)
class EnemySnapshot extends HiveObject {
  /// EnemyArchetype.id
  @HiveField(0)
  String archetypeId;

  /// 'archetypeId#instanceIndex' 형식
  @HiveField(1)
  String instanceId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String role;

  @HiveField(4)
  int tier;

  @HiveField(5)
  int str;

  /// Dart 'int' 키워드 충돌 회피
  @HiveField(6)
  int int_;

  @HiveField(7)
  int vit;

  @HiveField(8)
  int agi;

  /// 시뮬레이션 종료 시점 HP (영속용 final 값)
  @HiveField(9)
  int hp;

  @HiveField(10)
  int attack;

  @HiveField(11)
  int defense;

  @HiveField(12)
  List<String> skillIds;

  @HiveField(13)
  BehaviorPattern behaviorPattern;

  @HiveField(14)
  String? factionTag;

  @HiveField(15)
  PositionRow positionRow;

  @HiveField(16)
  int positionIndex;

  @HiveField(17)
  String formationGroupId;

  @HiveField(18)
  String? enemyKeywordKey;

  /// 페이즈 4 #1 [FR-15] §3 1회성 플래그
  @HiveField(19)
  bool flagBattleFuryUsed;

  @HiveField(20)
  bool flagSummonUsed;

  EnemySnapshot({
    required this.archetypeId,
    required this.instanceId,
    required this.name,
    required this.role,
    required this.tier,
    required this.str,
    required this.int_,
    required this.vit,
    required this.agi,
    required this.hp,
    required this.attack,
    required this.defense,
    this.skillIds = const [],
    required this.behaviorPattern,
    this.factionTag,
    required this.positionRow,
    required this.positionIndex,
    required this.formationGroupId,
    this.enemyKeywordKey,
    this.flagBattleFuryUsed = false,
    this.flagSummonUsed = false,
  });
}
