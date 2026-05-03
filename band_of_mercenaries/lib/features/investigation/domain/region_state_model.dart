import 'package:hive/hive.dart';

part 'region_state_model.g.dart';

@HiveType(typeId: 8)
class RegionState extends HiveObject {
  @HiveField(0)
  int regionId;

  @HiveField(1)
  int knowledge; // 0~100

  @HiveField(2)
  List<String> triggeredDiscoveries; // 트리거된 discovery ID 목록

  @HiveField(3)
  Map<String, String> sectorChanges; // 섹터 변환 상태 (key는 0-based('0'~'9'), region_sectors.sector_index는 1-based(1..6) — 변환 시 -1/+1. value: "village"|"ruins"|"hidden")

  RegionState({
    required this.regionId,
    this.knowledge = 0,
    List<String>? triggeredDiscoveries,
    Map<String, String>? sectorChanges,
  })  : triggeredDiscoveries = triggeredDiscoveries ?? [],
        sectorChanges = sectorChanges ?? {};
}
