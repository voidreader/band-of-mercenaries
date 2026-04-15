import 'package:hive/hive.dart';

part 'faction_state_model.g.dart';

@HiveType(typeId: 10)
class FactionClueRecord extends HiveObject {
  @HiveField(0)
  late String factionId;

  @HiveField(1)
  late int regionId;

  @HiveField(2)
  late String discoveryId;

  @HiveField(3)
  late DateTime foundAt;

  FactionClueRecord({
    required this.factionId,
    required this.regionId,
    required this.discoveryId,
    required this.foundAt,
  });
}

@HiveType(typeId: 9)
class FactionState extends HiveObject {
  @HiveField(0)
  late String factionId;

  @HiveField(1)
  late List<FactionClueRecord> clueRecords;

  FactionState({
    required this.factionId,
    List<FactionClueRecord>? clueRecords,
  }) : clueRecords = clueRecords ?? [];

  List<int> get discoveredInRegions =>
      clueRecords.map((r) => r.regionId).toSet().toList();
}
