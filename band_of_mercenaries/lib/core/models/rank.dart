import 'package:freezed_annotation/freezed_annotation.dart';

part 'rank.freezed.dart';
part 'rank.g.dart';

@freezed
class Rank with _$Rank {
  const factory Rank({
    @JsonKey(name: 'Grade') required String grade,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'RequiredReputation') required int requiredReputation,
    @JsonKey(name: 'UnlockTier') required int unlockTier,
  }) = _Rank;

  factory Rank.fromJson(Map<String, dynamic> json) =>
      _$RankFromJson(json);
}

@freezed
class RankList with _$RankList {
  const factory RankList({
    @JsonKey(name: 'Ranks') required List<Rank> items,
  }) = _RankList;

  factory RankList.fromJson(Map<String, dynamic> json) =>
      _$RankListFromJson(json);
}
