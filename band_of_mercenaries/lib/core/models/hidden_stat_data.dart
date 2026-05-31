// M8.5 페이즈 4 #3 — HiddenStatData 정적 카탈로그 모델
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hidden_stat_data.freezed.dart';
part 'hidden_stat_data.g.dart';

@freezed
class HiddenStatData with _$HiddenStatData {
  const factory HiddenStatData({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'counter_key') required String counterKey,
    @JsonKey(name: 'level_thresholds') required List<int> levelThresholds,
    @JsonKey(name: 'combat_effects_json') required Map<String, dynamic> combatEffectsJson,
    @JsonKey(name: 'passive_effects_json') Map<String, dynamic>? passiveEffectsJson,
    @JsonKey(name: 'post_reward_effects_json') Map<String, dynamic>? postRewardEffectsJson,
    @JsonKey(name: 'icon_key') @Default('default') String iconKey,
    @JsonKey(name: 'narrative_hint') String? narrativeHint,
  }) = _HiddenStatData;

  factory HiddenStatData.fromJson(Map<String, dynamic> json) =>
      _$HiddenStatDataFromJson(json);
}
