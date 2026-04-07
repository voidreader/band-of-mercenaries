import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_data.freezed.dart';
part 'trait_data.g.dart';

@freezed
class TraitData with _$TraitData {
  const factory TraitData({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'EffectType') required String effectType,
    @JsonKey(name: 'Value') required double value,
  }) = _TraitData;

  factory TraitData.fromJson(Map<String, dynamic> json) =>
      _$TraitDataFromJson(json);
}

@freezed
class TraitDataList with _$TraitDataList {
  const factory TraitDataList({
    @JsonKey(name: 'Traits') required List<TraitData> items,
  }) = _TraitDataList;

  factory TraitDataList.fromJson(Map<String, dynamic> json) =>
      _$TraitDataListFromJson(json);
}
