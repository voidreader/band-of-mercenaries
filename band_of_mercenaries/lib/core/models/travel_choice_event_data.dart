import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_choice_event_data.freezed.dart';
part 'travel_choice_event_data.g.dart';

@freezed
class TravelChoiceEventData with _$TravelChoiceEventData {
  const factory TravelChoiceEventData({
    required String id,
    required String name,
    required String category,
    required String situation,
    @JsonKey(name: 'min_tier') required int minTier,
    @JsonKey(name: 'max_tier') required int maxTier,
    @Default(1) int weight,
    @JsonKey(name: 'preferred_traits') String? preferredTraits,
  }) = _TravelChoiceEventData;

  factory TravelChoiceEventData.fromJson(Map<String, dynamic> json) =>
      _$TravelChoiceEventDataFromJson(json);
}
