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

  RegionState({
    required this.regionId,
    this.knowledge = 0,
    List<String>? triggeredDiscoveries,
  }) : triggeredDiscoveries = triggeredDiscoveries ?? [];
}
