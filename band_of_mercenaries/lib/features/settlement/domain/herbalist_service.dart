class HerbalistService {
  HerbalistService._();

  static const Map<int, double> _costMultipliers = {1: 1.5, 2: 1.0, 3: 0.9, 4: 0.8};
  static const Map<int, int> _cooldownMinutes = {1: 45, 2: 30, 3: 15, 4: 10};
  static const Map<int, double> _gatheringMultipliers = {1: 1.0, 2: 1.0, 3: 1.1, 4: 1.2};

  static int calculateCost(int trustLevel) =>
      (50 * (_costMultipliers[trustLevel] ?? 1.0)).round();

  static int calculateCooldownMinutes(int trustLevel) =>
      _cooldownMinutes[trustLevel] ?? 30;

  static double gatheringMultiplier(int trustLevel) =>
      _gatheringMultipliers[trustLevel] ?? 1.0;
}
