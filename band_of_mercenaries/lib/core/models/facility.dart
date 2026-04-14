import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility.freezed.dart';
part 'facility.g.dart';

@freezed
class Facility with _$Facility {
  const factory Facility({
    required String id,
    required String name,
    @JsonKey(name: 'effect_type') required String effectType,
    @JsonKey(name: 'max_level') required int maxLevel,
    required List<int> costs,
    required List<double> values,
    String? description,
    String? category,
    @JsonKey(name: 'base_cost') int? baseCost,
    @JsonKey(name: 'cost_multiplier') double? costMultiplier,
    @JsonKey(name: 'lv1_cost') int? lv1Cost,
    @JsonKey(name: 'lv2_cost') int? lv2Cost,
    @JsonKey(name: 'base_time') int? baseTime,
    @JsonKey(name: 'time_multiplier') double? timeMultiplier,
    @JsonKey(name: 'lv1_time') int? lv1Time,
    @JsonKey(name: 'lv2_time') int? lv2Time,
    @JsonKey(name: 'max_effect') double? maxEffect,
    double? alpha,
    List<Map<String, dynamic>>? milestones,
  }) = _Facility;

  factory Facility.fromJson(Map<String, dynamic> json) =>
      _$FacilityFromJson(json);
}