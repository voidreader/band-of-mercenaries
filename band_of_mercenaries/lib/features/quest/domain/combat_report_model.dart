import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combatant_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart';
import 'package:band_of_mercenaries/features/quest/domain/enemy_snapshot.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';

part 'combat_report_model.g.dart';

@HiveType(typeId: 21)
class CombatReport extends HiveObject {
  @HiveField(0)
  String summary;

  @HiveField(1)
  List<String> details;

  @HiveField(2)
  int seed;

  @HiveField(3)
  String? protagonistMercId;

  @HiveField(4)
  List<String> featuredMercIds;

  @HiveField(5)
  List<String> toneTags;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  List<String> templateIds;

  // M8b 페이즈 4 #2 추가
  @HiveField(8)
  int? schemaVersion;

  @HiveField(9)
  List<CombatantSnapshot>? combatantSnapshots;

  @HiveField(10)
  List<CombatTurn>? turns;

  @HiveField(11)
  CombatExitCondition? exitCondition;

  @HiveField(12)
  double? objectiveProgress;

  @HiveField(13)
  List<EnemySnapshot>? enemySnapshots;

  @HiveField(14)
  List<StatusEffectEvent>? statusEffectHistory;

  CombatReport({
    required this.summary,
    required this.details,
    required this.seed,
    this.protagonistMercId,
    required this.featuredMercIds,
    required this.toneTags,
    required this.createdAt,
    required this.templateIds,
    // M8b 페이즈 4 #2 추가
    this.schemaVersion,
    this.combatantSnapshots,
    this.turns,
    this.exitCondition,
    this.objectiveProgress,
    this.enemySnapshots,
    this.statusEffectHistory,
  });
}
