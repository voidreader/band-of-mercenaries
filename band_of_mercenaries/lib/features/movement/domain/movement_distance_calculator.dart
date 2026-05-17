import 'package:band_of_mercenaries/core/models/user_data.dart';

class MovementDistanceCalculator {
  MovementDistanceCalculator._();

  /// M7 페이즈 4 #3 — region_adjacency 그래프 기반 거리 계산.
  ///
  /// - 동일 region: |fromSector - toSector|
  /// - 인접 그래프 매칭: distance_units + |fromSector - toSector|
  /// - fallback: UserData.calculateDistance (|region 차이| + |sector 차이|)
  static int calculate({
    required int fromRegion,
    required int fromSector,
    required int toRegion,
    required int toSector,
    required Map<int, Map<int, int>> adjacencyMap,
  }) {
    if (fromRegion == toRegion) {
      return (toSector - fromSector).abs();
    }
    final adjacencyDistance = adjacencyMap[fromRegion]?[toRegion];
    if (adjacencyDistance != null) {
      return adjacencyDistance + (toSector - fromSector).abs();
    }
    return UserData.calculateDistance(fromRegion, fromSector, toRegion, toSector);
  }
}
