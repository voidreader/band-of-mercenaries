import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_data.freezed.dart';
part 'trait_data.g.dart';

@freezed
class TraitData with _$TraitData {
  const factory TraitData({
    required String id,
    required String name,
    @JsonKey(name: 'effect_type') required String effectType,
    required double value,
  }) = _TraitData;

  factory TraitData.fromJson(Map<String, dynamic> json) =>
      _$TraitDataFromJson(json);
}