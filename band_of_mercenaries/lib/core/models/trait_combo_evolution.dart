import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_combo_evolution.freezed.dart';
part 'trait_combo_evolution.g.dart';

@freezed
class TraitComboEvolution with _$TraitComboEvolution {
  const factory TraitComboEvolution({
    required int id,
    @JsonKey(name: 'required_trait_1') required String requiredTrait1,
    @JsonKey(name: 'required_trait_2') required String requiredTrait2,
    @JsonKey(name: 'result_trait_key') required String resultTraitKey,
  }) = _TraitComboEvolution;

  factory TraitComboEvolution.fromJson(Map<String, dynamic> json) =>
      _$TraitComboEvolutionFromJson(json);
}
