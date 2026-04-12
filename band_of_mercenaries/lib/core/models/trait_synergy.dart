import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_synergy.freezed.dart';
part 'trait_synergy.g.dart';

@freezed
class TraitSynergy with _$TraitSynergy {
  const factory TraitSynergy({
    required int id,
    @JsonKey(name: 'innate_trait_key') required String innateTraitKey,
    @JsonKey(name: 'target_trait_key') required String targetTraitKey,
    @JsonKey(name: 'reduction_percent') required double reductionPercent,
  }) = _TraitSynergy;

  factory TraitSynergy.fromJson(Map<String, dynamic> json) =>
      _$TraitSynergyFromJson(json);
}
