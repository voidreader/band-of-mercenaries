class FactionClueResult {
  final String factionId;
  final String? factionName; // nullable: factions 테이블 비어있을 때 null
  final int clueLevel; // 1, 2, 3
  final String clueText; // 단서 텍스트
  final int regionId; // 발견한 리전 ID
  final String discoveryId; // region_discoveries 항목 ID

  const FactionClueResult({
    required this.factionId,
    this.factionName,
    required this.clueLevel,
    required this.clueText,
    required this.regionId,
    required this.discoveryId,
  });
}
