import 'package:freezed_annotation/freezed_annotation.dart';

part 'elite_loot_entry.freezed.dart';
part 'elite_loot_entry.g.dart';

@freezed
class EliteLootEntry with _$EliteLootEntry {
  const factory EliteLootEntry({
    required String id,
    @JsonKey(name: 'elite_id') required String eliteId,
    @JsonKey(name: 'drop_type') required String dropType,
    @JsonKey(name: 'item_id') String? itemId,
    @JsonKey(name: 'gold_min') int? goldMin,
    @JsonKey(name: 'gold_max') int? goldMax,
    @JsonKey(name: 'drop_rate') required double dropRate,
    @JsonKey(name: 'rarity_grade') required String rarityGrade,
    @Default(1) int quantity,
  }) = _EliteLootEntry;

  factory EliteLootEntry.fromJson(Map<String, dynamic> json) =>
      _$EliteLootEntryFromJson(json);
}
