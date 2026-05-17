import 'package:freezed_annotation/freezed_annotation.dart';

part 'region_adjacency.freezed.dart';
part 'region_adjacency.g.dart';

@freezed
class RegionAdjacency with _$RegionAdjacency {
  const factory RegionAdjacency({
    required int id,
    @JsonKey(name: 'from_region') required int fromRegion,
    @JsonKey(name: 'to_region') required int toRegion,
    @JsonKey(name: 'distance_units') required int distanceUnits,
  }) = _RegionAdjacency;

  factory RegionAdjacency.fromJson(Map<String, dynamic> json) =>
      _$RegionAdjacencyFromJson(json);
}
