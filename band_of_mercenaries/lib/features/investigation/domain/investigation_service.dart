class InvestigationService {
  /// 조사 성공률 계산
  /// 공식: (85.0 + (effectiveAgi + effectiveVit) / 200.0).clamp(5.0, 95.0)
  static double calculateSuccessRate(int effectiveAgi, int effectiveVit) {
    return (85.0 + (effectiveAgi + effectiveVit) / 200.0).clamp(5.0, 95.0);
  }

  /// 티어별 지식 획득량 (T1=10, T2=8, T3=6, T4=5, T5=4)
  static int getKnowledgeGain(int regionTier) {
    return switch (regionTier) {
      1 => 10,
      2 => 8,
      3 => 6,
      4 => 5,
      5 => 4,
      _ => 5,
    };
  }

  /// 티어별 조사 소요 시간 (T1=5분, T2=8분, T3=10분, T4=15분, T5=20분)
  static Duration getInvestigationDuration(int regionTier, double speedMultiplier) {
    final effectiveSpeed = speedMultiplier <= 0 ? 1.0 : speedMultiplier;
    final minutes = switch (regionTier) {
      1 => 5,
      2 => 8,
      3 => 10,
      4 => 15,
      5 => 20,
      _ => 10,
    };
    return Duration(seconds: (minutes * 60 / effectiveSpeed).round());
  }

  /// 티어별 실패 시 부상 확률 (T1=0%, T2=5%, T3=10%, T4=20%, T5=30%)
  static double getInjuryChance(int regionTier) {
    return switch (regionTier) {
      1 => 0.0,
      2 => 0.05,
      3 => 0.10,
      4 => 0.20,
      5 => 0.30,
      _ => 0.10,
    };
  }
}
