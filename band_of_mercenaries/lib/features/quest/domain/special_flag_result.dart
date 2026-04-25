/// 퀘스트 완료 시 특수 플래그 처리 결과 값 객체.
///
/// 세력 패시브, 트레잇 학습 부스트, 평판 패널티 등
/// 완료 후 추가로 적용되는 효과들의 결과를 담는다.
class SpecialFlagResult {
  final List<String> extraItemIds;
  final int extraReputation;
  final List<String> boostedMercIds; // trait_learning_boost 적용된 용병 ID 목록
  final bool reputationPenaltyApplied;

  const SpecialFlagResult({
    required this.extraItemIds,
    required this.extraReputation,
    required this.boostedMercIds,
    required this.reputationPenaltyApplied,
  });

  factory SpecialFlagResult.empty() => const SpecialFlagResult(
    extraItemIds: [],
    extraReputation: 0,
    boostedMercIds: [],
    reputationPenaltyApplied: false,
  );

  bool get isEmpty =>
      extraItemIds.isEmpty &&
      extraReputation == 0 &&
      boostedMercIds.isEmpty &&
      !reputationPenaltyApplied;
}
