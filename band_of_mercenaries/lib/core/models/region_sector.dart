import 'package:freezed_annotation/freezed_annotation.dart';

part 'region_sector.freezed.dart';
part 'region_sector.g.dart';

/// region_sectors 정규화 테이블의 섹터 정보.
/// sectorIndex는 1-based(1..6). 마스터 데이터 가독성 우선.
/// (Hive RegionState.sectorChanges는 0-based 키 사용 — 변환 시 -1/+1.)
@freezed
class RegionSector with _$RegionSector {
  const factory RegionSector({
    required String id,
    @JsonKey(name: 'region_id') required int regionId,
    @JsonKey(name: 'sector_index') required int sectorIndex,
    required String name,
    @JsonKey(name: 'sector_type') required String sectorType,
    @JsonKey(name: 'environment_tags')
    @Default(<String>[])
    List<String> environmentTags,
    String? description,
  }) = _RegionSector;

  factory RegionSector.fromJson(Map<String, dynamic> json) =>
      _$RegionSectorFromJson(json);
}
