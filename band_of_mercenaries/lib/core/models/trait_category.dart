import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_category.freezed.dart';
part 'trait_category.g.dart';

@freezed
class TraitCategory with _$TraitCategory {
  const factory TraitCategory({
    required String key,
    required String name,
    @JsonKey(name: 'slot_type') required String slotType,
  }) = _TraitCategory;

  factory TraitCategory.fromJson(Map<String, dynamic> json) =>
      _$TraitCategoryFromJson(json);
}
