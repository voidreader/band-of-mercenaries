class HerbalistService {
  HerbalistService._();

  static const Map<int, double> _costMultipliers = {1: 1.5, 2: 1.0, 3: 0.9, 4: 0.8};
  static const Map<int, int> _cooldownMinutes = {1: 45, 2: 30, 3: 15, 4: 10};
  static const Map<int, double> _gatheringMultipliers = {1: 1.0, 2: 1.0, 3: 1.1, 4: 1.2};

  // M7 페이즈 4 #4 인프라 배수
  static const Map<int, double> _infraCostMultipliers = {1: 1.0, 2: 1.0, 3: 0.9, 4: 0.8};
  static const Map<int, double> _infraGatheringMultipliers = {1: 1.0, 2: 1.05, 3: 1.10, 4: 1.20};
  static const Map<int, double> _infraCooldownMultipliers = {1: 1.0, 2: 1.0, 3: 0.85, 4: 0.70};

  static int calculateCost(int trustLevel, {int infraTier = 1}) {
    final base = 50;
    final trust = _costMultipliers[trustLevel] ?? 1.0;
    final infra = _infraCostMultipliers[infraTier] ?? 1.0;
    return (base * trust * infra).round();
  }

  static int calculateCooldownMinutes(int trustLevel, {int infraTier = 1}) {
    final baseMin = _cooldownMinutes[trustLevel] ?? 45;
    final infra = _infraCooldownMultipliers[infraTier] ?? 1.0;
    return (baseMin * infra).round();
  }

  static double gatheringMultiplier(int trustLevel, {int infraTier = 1}) {
    final trust = _gatheringMultipliers[trustLevel] ?? 1.0;
    final infra = _infraGatheringMultipliers[infraTier] ?? 1.0;
    return trust * infra;
  }
}
