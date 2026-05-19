// M8b 페이즈 4 #2 — 시뮬레이션 영속 결과 (typeId 22)
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/combatant_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/enemy_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';

part 'combat_simulation_result.g.dart';

@HiveType(typeId: 22)
class CombatSimulationResult extends HiveObject {
  @HiveField(0)
  QuestResult questResult;

  @HiveField(1)
  List<CombatTurn> turns;

  @HiveField(2)
  String? protagonistMercId;

  @HiveField(3)
  List<String> featuredMercIds;

  @HiveField(4)
  List<String> injuredMercIds;

  @HiveField(5)
  List<String> deceasedMercIds;

  @HiveField(6)
  double objectiveProgress;

  @HiveField(7)
  CombatExitCondition exitCondition;

  @HiveField(8)
  List<StatusEffectEvent> statusEffectHistory;

  @HiveField(9)
  int seed;

  @HiveField(10)
  List<String> toneTags;

  @HiveField(11)
  List<CombatantSnapshot> combatantSnapshots;

  @HiveField(12)
  List<EnemySnapshot> enemySnapshots;

  CombatSimulationResult({
    required this.questResult,
    required this.turns,
    this.protagonistMercId,
    this.featuredMercIds = const [],
    this.injuredMercIds = const [],
    this.deceasedMercIds = const [],
    this.objectiveProgress = 0.0,
    required this.exitCondition,
    this.statusEffectHistory = const [],
    required this.seed,
    this.toneTags = const [],
    this.combatantSnapshots = const [],
    this.enemySnapshots = const [],
  });
}
