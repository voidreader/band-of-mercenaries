import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

part 'template_context.freezed.dart';

enum EvaluationScope { mercenary, team }

@freezed
class TemplateContext with _$TemplateContext {
  const factory TemplateContext({
    Mercenary? merc,
    ActiveQuest? quest,
    Region? region,
    required UserData user,
    @Default(<FactionState>[]) List<FactionState> factionStates,
    Map<int, String>? sectorChanges,
    int? currentSectorIndex,
    @Default(<Mercenary>[]) List<Mercenary> rosterForTeam,
    String? eliteId,
    String? allyName,
    String? enemyName,
    int? seed,
    @Default(EvaluationScope.mercenary) EvaluationScope evaluationScope,
  }) = _TemplateContext;
}
