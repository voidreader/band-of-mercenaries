import 'package:freezed_annotation/freezed_annotation.dart';

part 'region_state_effect.freezed.dart';
part 'region_state_effect.g.dart';

@freezed
sealed class RegionStateEffect with _$RegionStateEffect {
  @FreezedUnionValue('cumulative')
  const factory RegionStateEffect.cumulative({
    @JsonKey(name: 'delta_per_completion') required int deltaPerCompletion,
    @JsonKey(name: 'cap_per_threshold') required int capPerThreshold,
    @JsonKey(name: 'threshold_flag') required String thresholdFlag,
  }) = CumulativeEffect;

  @FreezedUnionValue('oneshot')
  const factory RegionStateEffect.oneshot({
    required int delta,
    required String flag,
  }) = OneshotEffect;

  factory RegionStateEffect.fromJson(Map<String, dynamic> json) =>
      _$RegionStateEffectFromJson(json);
}
