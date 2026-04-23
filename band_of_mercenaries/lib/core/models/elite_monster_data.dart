import 'package:freezed_annotation/freezed_annotation.dart';

part 'elite_monster_data.freezed.dart';
part 'elite_monster_data.g.dart';

@freezed
class EliteMonsterData with _$EliteMonsterData {
  const factory EliteMonsterData({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'is_unique') required bool isUnique,
    @JsonKey(name: 'type_family') required String typeFamily,
    required int tier,
    required int power,
    @JsonKey(name: 'spawn_rate') required double spawnRate,
    @JsonKey(name: 'duration_multiplier') required double durationMultiplier,
    @Default(<String>[])
    @JsonKey(name: 'environment_tags')
    List<String> environmentTags,
    @Default(<String, double>{})
    @JsonKey(name: 'stat_weight', fromJson: _statWeightFromJson)
    Map<String, double> statWeight,
    @JsonKey(name: 'fixed_region_environments')
    List<String>? fixedRegionEnvironments,
    String? lore,
    String? title,
  }) = _EliteMonsterData;

  factory EliteMonsterData.fromJson(Map<String, dynamic> json) =>
      _$EliteMonsterDataFromJson(json);
}

Map<String, double> _statWeightFromJson(dynamic json) =>
    (json as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
