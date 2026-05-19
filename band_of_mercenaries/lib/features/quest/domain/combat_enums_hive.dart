// M8b 페이즈 4 #2 — 시뮬레이션 영속 Hive enum 3종 (typeId 28~30)
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'combat_enums_hive.g.dart';

@HiveType(typeId: 28)
enum CombatExitCondition {
  @HiveField(0)
  @JsonValue('a_party_wiped')
  aPartyWiped,

  @HiveField(1)
  @JsonValue('b_enemy_wiped')
  bEnemyWiped,

  @HiveField(2)
  @JsonValue('c_objective_achieved')
  cObjectiveAchieved,

  @HiveField(3)
  @JsonValue('d_round_limit')
  dRoundLimit,

  @HiveField(4)
  @JsonValue('e_flee')
  eFlee,

  @HiveField(5)
  @JsonValue('f_escort_dead')
  fEscortDead,
}

@HiveType(typeId: 29)
enum BehaviorPattern {
  @HiveField(0)
  @JsonValue('aggressive')
  aggressive,

  @HiveField(1)
  @JsonValue('opportunist')
  opportunist,

  @HiveField(2)
  @JsonValue('caster')
  caster,

  @HiveField(3)
  @JsonValue('supporter')
  supporter,

  @HiveField(4)
  @JsonValue('defender')
  defender,

  @HiveField(5)
  @JsonValue('berserker')
  berserker,
}

@HiveType(typeId: 30)
enum PositionRow {
  @HiveField(0)
  @JsonValue('front')
  front,

  @HiveField(1)
  @JsonValue('middle')
  middle,

  @HiveField(2)
  @JsonValue('back')
  back,
}
