import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 간판 용병 자동 선정 도메인 (5단계 정렬) + 사망/방출 시 자동 복귀 helper.
/// 콜백 DI 패턴 — Riverpod 의존 없음.
///
/// 현재 5단계 정렬(titleIds→위업 횟수→level→partyPower→recruitedAt)은
/// mercenary 객체 effective getter만 사용하므로 콜백 2개(getMercenaries/getBandAchievements)로 충분.
/// 페이즈 5+ reputation/faction 가중치 도입 시 콜백 재추가 예정.
class FlagshipMercenaryService {
  final List<Mercenary> Function() getMercenaries;
  final List<BandAchievement> Function() getBandAchievements;

  FlagshipMercenaryService({
    required this.getMercenaries,
    required this.getBandAchievements,
  });

  /// 5단계 정렬로 자동 간판 mercenary 1명 선정. dead 제외.
  /// 순서: titleIds.length DESC → 위업 주인공 횟수 DESC → level DESC → partyPower DESC → recruitedAt ASC.
  Mercenary? selectAuto() {
    final candidates = getMercenaries()
        .where((m) => m.status != MercenaryStatus.dead)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort(_compareFlagship);
    return candidates.first;
  }

  /// 5단계 비교자 (a, b) — `compareTo` 음수 = a 우선.
  int _compareFlagship(Mercenary a, Mercenary b) {
    // 1순위: titleIds.length DESC
    final cmpTitles = b.titleIds.length.compareTo(a.titleIds.length);
    if (cmpTitles != 0) return cmpTitles;

    // 2순위: 위업 주인공 횟수 DESC
    final aAch = _countAchievements(a.id);
    final bAch = _countAchievements(b.id);
    final cmpAch = bAch.compareTo(aAch);
    if (cmpAch != 0) return cmpAch;

    // 3순위: level DESC
    if (a.level != b.level) return b.level.compareTo(a.level);

    // 4순위: partyPower DESC (단순 가중 평균)
    final aPower = _calculatePartyPower(a);
    final bPower = _calculatePartyPower(b);
    final cmpPower = bPower.compareTo(aPower);
    if (cmpPower != 0) return cmpPower;

    // 5순위: recruitedAt ASC (이른 가입 우선; null = DateTime(2000) fallback)
    final aRecruited = a.recruitedAt ?? DateTime(2000);
    final bRecruited = b.recruitedAt ?? DateTime(2000);
    return aRecruited.compareTo(bRecruited);
  }

  /// 위업 주인공 횟수 카운트 (achievement type만, memorial 제외).
  int _countAchievements(String mercId) {
    return getBandAchievements()
        .where((a) =>
            a.type == BandAchievementType.achievement &&
            a.mercSnapshot?.id == mercId)
        .length;
  }

  /// partyPower 단순 가중 평균 — STR·INT 0.3, VIT·AGI 0.2.
  /// effectiveXxx getter는 Mercenary 모델의 레벨 + 피로 디버프 반영 값.
  double _calculatePartyPower(Mercenary m) {
    return m.effectiveStr * 0.3 +
        m.effectiveIntelligence * 0.3 +
        m.effectiveVit * 0.2 +
        m.effectiveAgi * 0.2;
  }

  /// 사망/방출 처리 시 호출. 수동 간판이 사라진 경우 null 반환(자동 복귀 시그널).
  /// 호출처에서 반환값이 null이면 userData.flagshipMercId = null 처리.
  String? handleMercDeathOrRelease(
    String deadMercId, {
    required String? currentFlagshipMercId,
  }) {
    if (currentFlagshipMercId == deadMercId) return null;
    return currentFlagshipMercId;
  }
}
