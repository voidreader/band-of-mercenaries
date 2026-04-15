import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_data.freezed.dart';
part 'faction_data.g.dart';

@freezed
class FactionData with _$FactionData {
  const factory FactionData({
    required String id,
    required String name,
    required String description,
    required String philosophy,
    @JsonKey(name: 'tier_range') required List<int> tierRange,
    required String color,
  }) = _FactionData;

  factory FactionData.fromJson(Map<String, dynamic> json) =>
      _$FactionDataFromJson(json);
}
