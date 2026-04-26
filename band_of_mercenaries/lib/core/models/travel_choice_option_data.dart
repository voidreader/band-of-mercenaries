import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_choice_option_data.freezed.dart';
part 'travel_choice_option_data.g.dart';

@freezed
class TravelChoiceOptionData with _$TravelChoiceOptionData {
  const factory TravelChoiceOptionData({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'choice_index') required int choiceIndex,
    required String label,
    @JsonKey(name: 'visibility_expr') String? visibilityExpr,
    required String description,
    @JsonKey(name: 'risk_level') required String riskLevel,
  }) = _TravelChoiceOptionData;

  factory TravelChoiceOptionData.fromJson(Map<String, dynamic> json) =>
      _$TravelChoiceOptionDataFromJson(json);
}
