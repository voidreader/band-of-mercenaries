import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_event.freezed.dart';
part 'travel_event.g.dart';

@freezed
class TravelEvent with _$TravelEvent {
  const factory TravelEvent({
    required String id,
    required String name,
    required String type,
    @JsonKey(name: 'effect_type') required String effectType,
    required double magnitude,
    @JsonKey(name: 'min_tier') required int minTier,
    @JsonKey(name: 'max_tier') required int maxTier,
    required String description,
  }) = _TravelEvent;

  factory TravelEvent.fromJson(Map<String, dynamic> json) =>
      _$TravelEventFromJson(json);
}