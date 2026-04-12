import 'package:freezed_annotation/freezed_annotation.dart';

part 'difficulty.freezed.dart';
part 'difficulty.g.dart';

@freezed
class Difficulty with _$Difficulty {
  const factory Difficulty({
    required int level,
    @JsonKey(name: 'enemy_power') required int enemyPower,
    @JsonKey(name: 'reward_multiplier') required double rewardMultiplier,
    @JsonKey(name: 'success_penalty') required double successPenalty,
    @JsonKey(name: 'injury_rate') required double injuryRate,
    @JsonKey(name: 'death_rate') required double deathRate,
    @JsonKey(name: 'min_dispatch_cost') required int minDispatchCost,
    @JsonKey(name: 'max_dispatch_cost') required int maxDispatchCost,
  }) = _Difficulty;

  factory Difficulty.fromJson(Map<String, dynamic> json) =>
      _$DifficultyFromJson(json);
}