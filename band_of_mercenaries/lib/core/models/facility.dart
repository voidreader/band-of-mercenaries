import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility.freezed.dart';
part 'facility.g.dart';

@freezed
class Facility with _$Facility {
  const factory Facility({
    required String id,
    required String name,
    @JsonKey(name: 'effect_type') required String effectType,
    @JsonKey(name: 'max_level') required int maxLevel,
    required List<int> costs,
    required List<double> values,
  }) = _Facility;

  factory Facility.fromJson(Map<String, dynamic> json) =>
      _$FacilityFromJson(json);
}

@freezed
class FacilityList with _$FacilityList {
  const factory FacilityList({
    @JsonKey(name: 'Facilities') required List<Facility> items,
  }) = _FacilityList;

  factory FacilityList.fromJson(Map<String, dynamic> json) =>
      _$FacilityListFromJson(json);
}
