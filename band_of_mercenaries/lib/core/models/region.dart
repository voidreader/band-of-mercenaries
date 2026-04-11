import 'package:freezed_annotation/freezed_annotation.dart';

part 'region.freezed.dart';
part 'region.g.dart';

@freezed
class Region with _$Region {
  const factory Region({
    required int continent,
    required int region,
    @JsonKey(name: 'region_name') required String regionName,
    @JsonKey(name: 'region_tier') required int regionTier,
    @JsonKey(name: 'recommend_power') required int recommendPower,
    required String description,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) =>
      _$RegionFromJson(json);
}

@freezed
class RegionList with _$RegionList {
  const factory RegionList({
    @JsonKey(name: 'Regions') required List<Region> items,
  }) = _RegionList;

  factory RegionList.fromJson(Map<String, dynamic> json) =>
      _$RegionListFromJson(json);
}
