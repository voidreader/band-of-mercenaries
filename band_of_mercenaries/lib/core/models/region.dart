import 'package:freezed_annotation/freezed_annotation.dart';

part 'region.freezed.dart';
part 'region.g.dart';

@freezed
class Region with _$Region {
  const factory Region({
    @JsonKey(name: 'Continent') required int continent,
    @JsonKey(name: 'Region') required int region,
    @JsonKey(name: 'RegionName') required String regionName,
    @JsonKey(name: 'RegionTier') required int regionTier,
    @JsonKey(name: 'RecommendPower') required int recommendPower,
    @JsonKey(name: 'Desc') required String desc,
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
