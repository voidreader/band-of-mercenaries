import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_choice_result_data.freezed.dart';
part 'travel_choice_result_data.g.dart';

@freezed
class TravelChoiceResultData with _$TravelChoiceResultData {
  const factory TravelChoiceResultData({
    required String id,
    @JsonKey(name: 'option_id') required String optionId,
    @JsonKey(name: 'result_index') required int resultIndex,
    required double probability,
    @JsonKey(name: 'conditional_expr') String? conditionalExpr,
    required String narrative,
    @JsonKey(name: 'effect_type') required String effectType,
    @Default(0.0) @JsonKey(name: 'effect_magnitude') double effectMagnitude,
    @JsonKey(name: 'effect_target') String? effectTarget,
  }) = _TravelChoiceResultData;

  factory TravelChoiceResultData.fromJson(Map<String, dynamic> json) =>
      _$TravelChoiceResultDataFromJson(json);
}
