// M8b 페이즈 4 #2 — CombatStatusEffect 정적 카탈로그 모델
import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_enums.dart';

part 'combat_status_effect.freezed.dart';
part 'combat_status_effect.g.dart';

@freezed
class CombatStatusEffect with _$CombatStatusEffect {
  const factory CombatStatusEffect({
    required String id,
    required String kind,
    @JsonKey(name: 'display_label') required String displayLabel,
    @JsonKey(name: 'default_duration_turns') required int defaultDurationTurns,
    @JsonKey(name: 'default_intensity') required double defaultIntensity,
    @JsonKey(name: 'stack_policy') required StackPolicy stackPolicy,
    @JsonKey(name: 'hook_target') required List<String> hookTarget,
    @JsonKey(name: 'apply_method') required ApplyMethod applyMethod,
    required String description,
  }) = _CombatStatusEffect;

  factory CombatStatusEffect.fromJson(Map<String, dynamic> json) =>
      _$CombatStatusEffectFromJson(json);
}
