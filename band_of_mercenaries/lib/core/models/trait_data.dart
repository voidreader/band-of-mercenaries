import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_data.freezed.dart';
part 'trait_data.g.dart';

@freezed
class TraitData with _$TraitData {
  const factory TraitData({
    required String key,
    required String name,
    @JsonKey(name: 'category_key') required String categoryKey,
    required String type,
    @Default('') String description,
    @JsonKey(name: 'effect_text') @Default('') String effectText,
    @JsonKey(name: 'acquisition_condition') Map<String, dynamic>? acquisitionCondition,
    @JsonKey(name: 'effect_json') Map<String, dynamic>? effectJson,
  }) = _TraitData;

  factory TraitData.fromJson(Map<String, dynamic> json) =>
      _$TraitDataFromJson(json);
}
