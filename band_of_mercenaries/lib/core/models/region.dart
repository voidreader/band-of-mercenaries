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
    @JsonKey(name: 'environment_tags')
    @Default(<String>[])
    List<String> environmentTags,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) =>
      _$RegionFromJson(json);
}