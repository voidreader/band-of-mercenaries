import 'package:freezed_annotation/freezed_annotation.dart';

part 'rank.freezed.dart';
part 'rank.g.dart';

@freezed
class Rank with _$Rank {
  const factory Rank({
    required String grade,
    required String name,
    @JsonKey(name: 'required_reputation') required int requiredReputation,
    @JsonKey(name: 'unlock_tier') required int unlockTier,
    @JsonKey(name: 'bonus_json')
    @Default(<String, dynamic>{})
    Map<String, dynamic> bonusJson,
  }) = _Rank;

  factory Rank.fromJson(Map<String, dynamic> json) =>
      _$RankFromJson(json);
}