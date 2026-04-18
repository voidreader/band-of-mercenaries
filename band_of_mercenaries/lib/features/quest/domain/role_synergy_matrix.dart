/// role × quest_type 상성 매트릭스 (%p 단위).
///
/// 값 범위: -2 ~ +8. 파티 평균 적용 후 ±10%p 독립 상한 클램프.
/// 밸런스 검증: Docs/balance-design/20260417_dispatch_synergy_values.md 분석 1.
///
/// **M2b 이후 T5 ranger 직업 1개 추가 예정** — 현재 M1은 0 허용.
class RoleSynergyMatrix {
  static const Map<String, Map<String, double>> _matrix = {
    'warrior':    {'raid': 8.0,  'hunt': 5.0, 'escort': 3.0, 'explore': -2.0},
    'ranger':     {'raid': 3.0,  'hunt': 8.0, 'escort': 2.0, 'explore': 3.0},
    'mage':       {'raid': -2.0, 'hunt': 2.0, 'escort': 3.0, 'explore': 8.0},
    'rogue':      {'raid': 5.0,  'hunt': 3.0, 'escort': 0.0, 'explore': 5.0},
    'support':    {'raid': 0.0,  'hunt': 2.0, 'escort': 8.0, 'explore': 2.0},
    'specialist': {'raid': 2.0,  'hunt': 2.0, 'escort': 2.0, 'explore': 2.0},
  };

  /// 단일 용병(role)의 특정 퀘스트 유형에 대한 보정값을 반환한다.
  /// 알 수 없는 role → specialist로 fallback. 알 수 없는 quest_type → 0.
  static double singleBonus(String role, String questTypeId) {
    final row = _matrix[role] ?? _matrix['specialist']!;
    return row[questTypeId] ?? 0.0;
  }

  /// 파티 평균 기반 보정값 계산.
  /// - 빈 파티: 0.0
  /// - 파티 멤버별 role 리스트 평균
  /// - 결과를 [-10, +10] %p 독립 상한으로 클램프
  static double partyAverageBonus({
    required List<String> partyRoles,
    required String questTypeId,
  }) {
    if (partyRoles.isEmpty) return 0.0;
    final sum = partyRoles.fold<double>(
      0.0,
      (acc, r) => acc + singleBonus(r, questTypeId),
    );
    final avg = sum / partyRoles.length;
    return avg.clamp(-10.0, 10.0);
  }

  /// 해당 quest_type에서 상위 N개 role을 반환 (퀘스트 카드 추천 배지용).
  /// 공동 +8끼리 동률이면 매트릭스 선언 순서 보장.
  static List<MapEntry<String, double>> topRolesForQuest(
    String questTypeId, {
    int n = 2,
  }) {
    final entries = _matrix.entries
        .map((e) => MapEntry(e.key, e.value[questTypeId] ?? 0.0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }
}
