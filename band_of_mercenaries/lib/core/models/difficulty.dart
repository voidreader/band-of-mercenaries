import 'package:freezed_annotation/freezed_annotation.dart';

part 'difficulty.freezed.dart';
part 'difficulty.g.dart';

@freezed
class Difficulty with _$Difficulty {
  const factory Difficulty({
    @JsonKey(name: 'Level') required int level,
    @JsonKey(name: 'EnemyPower') required int enemyPower,
    @JsonKey(name: 'RewardMultiplier') required double rewardMultiplier,
    @JsonKey(name: 'SuccessPenalty') required double successPenalty,
    @JsonKey(name: 'InjuryRate') required double injuryRate,
    @JsonKey(name: 'DeathRate') required double deathRate,
  }) = _Difficulty;

  factory Difficulty.fromJson(Map<String, dynamic> json) =>
      _$DifficultyFromJson(json);
}

@freezed
class DifficultyList with _$DifficultyList {
  const factory DifficultyList({
    @JsonKey(name: 'Difficultys') required List<Difficulty> items,
  }) = _DifficultyList;

  factory DifficultyList.fromJson(Map<String, dynamic> json) =>
      _$DifficultyListFromJson(json);
}
