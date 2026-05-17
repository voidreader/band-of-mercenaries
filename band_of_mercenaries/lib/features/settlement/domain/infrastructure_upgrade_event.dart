/// M7 페이즈 4 #4 — 인프라 단계 승급 이벤트
class InfrastructureUpgradeEvent {
  final int fromTier;
  final int toTier;
  final int? rewardGold;
  final int? rewardXp;
  final int? rewardReputation;
  final List<String> grantedAchievements;

  const InfrastructureUpgradeEvent({
    required this.fromTier,
    required this.toTier,
    this.rewardGold,
    this.rewardXp,
    this.rewardReputation,
    this.grantedAchievements = const [],
  });
}
