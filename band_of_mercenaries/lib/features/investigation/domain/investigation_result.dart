class InvestigationResult {
  final bool success;
  final int regionId;
  final int knowledgeGained;
  final int currentKnowledge;
  final List<String> newDiscoveryIds;
  final bool mercInjured;
  final String mercId;

  const InvestigationResult({
    required this.success,
    required this.regionId,
    required this.knowledgeGained,
    required this.currentKnowledge,
    required this.newDiscoveryIds,
    required this.mercInjured,
    required this.mercId,
  });
}
