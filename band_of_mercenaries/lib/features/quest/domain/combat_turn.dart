// M8b 페이즈 4 #2 — 전투 라운드 영속 모델 (typeId 23)
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_action.dart';

part 'combat_turn.g.dart';

@HiveType(typeId: 23)
class CombatTurn extends HiveObject {
  /// 0=선제 라운드, 1+=일반 라운드
  @HiveField(0)
  int roundIndex;

  /// 'initiative'/'general'
  @HiveField(1)
  String phase;

  @HiveField(2)
  List<CombatAction> actions;

  /// 라운드 종료 시 트리거된 enum names
  @HiveField(3)
  List<String> exitConditionsTriggered;

  /// 라운드 종료 시점 HP 스냅샷 (디버그용)
  @HiveField(4)
  Map<String, int>? hpRemainingByCombatant;

  CombatTurn({
    required this.roundIndex,
    required this.phase,
    required this.actions,
    this.exitConditionsTriggered = const [],
    this.hpRemainingByCombatant,
  });
}
