import 'package:freezed_annotation/freezed_annotation.dart';

part 'region_discovery_data.freezed.dart';
part 'region_discovery_data.g.dart';

@freezed
class RegionDiscoveryData with _$RegionDiscoveryData {
  const factory RegionDiscoveryData({
    required String id,
    @JsonKey(name: 'region_id') required int regionId,
    @JsonKey(name: 'knowledge_threshold') required int knowledgeThreshold,
    @JsonKey(name: 'discovery_type') required String discoveryType,
    @JsonKey(name: 'discovery_data') Map<String, dynamic>? discoveryData,
    required String description,
  }) = _RegionDiscoveryData;

  factory RegionDiscoveryData.fromJson(Map<String, dynamic> json) =>
      _$RegionDiscoveryDataFromJson(json);
}
