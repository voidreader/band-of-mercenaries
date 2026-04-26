import 'dart:math';

import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/models/quest_narrative_data.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

class QuestNarrativeService {
  QuestNarrativeService._();

  static QuestNarrativeData? pickTemplate({
    required String questType,
    required QuestResult resultType,
    required bool isElite,
    required List<QuestNarrativeData> allNarratives,
    required Random random,
  }) {
    final candidates = allNarratives
        .where((n) =>
            n.questType == questType &&
            n.resultType == resultType.name &&
            n.isElite == isElite)
        .toList();

    if (candidates.isEmpty) return null;

    final totalWeight = candidates.fold<double>(0.0, (sum, n) => sum + n.weight);
    double roll = random.nextDouble() * totalWeight;

    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll <= 0) return candidate;
    }

    return candidates.last;
  }

  static Mercenary? pickProtagonist(
    List<Mercenary> partyMercs,
    String questTypeId,
  ) {
    if (partyMercs.isEmpty) return null;

    final weights = QuestCalculator.statWeightsFor(questTypeId);

    Mercenary? best;
    double bestScore = double.negativeInfinity;

    for (final merc in partyMercs) {
      final score = merc.effectiveStr * weights['str']! +
          merc.effectiveIntelligence * weights['intelligence']! +
          merc.effectiveVit * weights['vit']! +
          merc.effectiveAgi * weights['agi']!;
      if (score > bestScore) {
        bestScore = score;
        best = merc;
      }
    }

    return best;
  }

  static String? renderNarrative({
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    required TemplateEngine templateEngine,
    Map<String, String>? sectorChanges,
    int? seed,
  }) {
    if (quest.isChainQuest) return null;

    final questResult = quest.result;
    if (questResult == null) return null;

    final narrative = pickTemplate(
      questType: quest.questTypeId,
      resultType: questResult,
      isElite: quest.isElite,
      allNarratives: staticData.questNarratives,
      random: Random(seed),
    );

    if (narrative == null) return null;

    final merc = pickProtagonist(partyMercs, quest.questTypeId);

    String? enemyName;
    if (quest.isElite) {
      enemyName = staticData.eliteMonsters
          .where((e) => e.id == quest.eliteId)
          .map((e) => e.name)
          .firstOrNull;
    } else {
      enemyName = staticData.questPools
          .where((p) => p.id == quest.questPoolId)
          .map((p) => p.enemyName)
          .firstOrNull;
    }

    final region = staticData.regions
        .where((r) => r.region == quest.region)
        .firstOrNull;

    final convertedSectorChanges = sectorChanges?.map(
      (k, v) => MapEntry(int.tryParse(k) ?? -1, v),
    );

    final context = TemplateContext(
      user: userData,
      merc: merc,
      region: region,
      factionStates: factionStates,
      sectorChanges: convertedSectorChanges,
      currentSectorIndex: userData.sector,
      enemyName: enemyName,
      eliteId: quest.eliteId,
      seed: seed,
      evaluationScope: EvaluationScope.mercenary,
    );

    return templateEngine.render(narrative.template, context);
  }
}
