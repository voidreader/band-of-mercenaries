import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_conflict.freezed.dart';
part 'trait_conflict.g.dart';

@freezed
class TraitConflict with _$TraitConflict {
  const factory TraitConflict({
    @JsonKey(name: 'trait_key') required String traitKey,
    @JsonKey(name: 'conflict_trait_key') required String conflictTraitKey,
  }) = _TraitConflict;

  factory TraitConflict.fromJson(Map<String, dynamic> json) =>
      _$TraitConflictFromJson(json);
}
