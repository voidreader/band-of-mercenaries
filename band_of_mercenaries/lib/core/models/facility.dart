import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility.freezed.dart';
part 'facility.g.dart';

@freezed
class Facility with _$Facility {
  const factory Facility({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'EffectType') required String effectType,
    @JsonKey(name: 'MaxLevel') required int maxLevel,
    @JsonKey(name: 'Costs') required List<int> costs,
    @JsonKey(name: 'Values') required List<double> values,
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
