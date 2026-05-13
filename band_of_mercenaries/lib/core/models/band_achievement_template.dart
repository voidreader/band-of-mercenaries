import 'package:freezed_annotation/freezed_annotation.dart';

part 'band_achievement_template.freezed.dart';
part 'band_achievement_template.g.dart';

@freezed
class BandAchievementTemplate with _$BandAchievementTemplate {
  const factory BandAchievementTemplate({
    required String id,
    required String category,
    required String name,
    @JsonKey(name: 'description_template') required String descriptionTemplate,
    @JsonKey(name: 'icon_key') @Default('default') String iconKey,
    @JsonKey(name: 'chronicle_variants') @Default(<String>[]) List<String> chronicleVariants,
    @JsonKey(name: 'default_priority') @Default('high') String defaultPriority,
    @JsonKey(name: 'narrative_hint') String? narrativeHint,
  }) = _BandAchievementTemplate;

  factory BandAchievementTemplate.fromJson(Map<String, dynamic> json) =>
      _$BandAchievementTemplateFromJson(json);
}
