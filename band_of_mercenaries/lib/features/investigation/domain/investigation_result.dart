import 'package:band_of_mercenaries/features/info/domain/faction_clue_result.dart';

class InvestigationResult {
  final bool success;
  final int regionId;
  final int knowledgeGained;
  final int currentKnowledge;
  final List<String> newDiscoveryIds;
  final bool mercInjured;
  final String mercId;
  final List<FactionClueResult> factionClues;
  final List<String> unlockedEliteIds;

  const InvestigationResult({
    required this.success,
    required this.regionId,
    required this.knowledgeGained,
    required this.currentKnowledge,
    required this.newDiscoveryIds,
    required this.mercInjured,
    required this.mercId,
    this.factionClues = const [],
    this.unlockedEliteIds = const [],
  });
}
