import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_transition.freezed.dart';
part 'trait_transition.g.dart';

@freezed
class TraitTransition with _$TraitTransition {
  const factory TraitTransition({
    required int id,
    @JsonKey(name: 'from_trait_key') required String fromTraitKey,
    @JsonKey(name: 'to_trait_key') required String toTraitKey,
    @JsonKey(name: 'condition_json') required Map<String, dynamic> conditionJson,
  }) = _TraitTransition;

  factory TraitTransition.fromJson(Map<String, dynamic> json) =>
      _$TraitTransitionFromJson(json);
}
