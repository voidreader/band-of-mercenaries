import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_event.freezed.dart';
part 'travel_event.g.dart';

@freezed
class TravelEvent with _$TravelEvent {
  const factory TravelEvent({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') required String type,
    @JsonKey(name: 'EffectType') required String effectType,
    @JsonKey(name: 'Magnitude') required double magnitude,
    @JsonKey(name: 'MinTier') required int minTier,
    @JsonKey(name: 'MaxTier') required int maxTier,
    @JsonKey(name: 'Description') required String description,
  }) = _TravelEvent;

  factory TravelEvent.fromJson(Map<String, dynamic> json) =>
      _$TravelEventFromJson(json);
}

@freezed
class TravelEventList with _$TravelEventList {
  const factory TravelEventList({
    @JsonKey(name: 'TravelEvents') required List<TravelEvent> items,
  }) = _TravelEventList;

  factory TravelEventList.fromJson(Map<String, dynamic> json) =>
      _$TravelEventListFromJson(json);
}
