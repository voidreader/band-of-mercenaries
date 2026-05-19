import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 지명 의뢰 hook 평가 컨텍스트. (M6 페이즈 4 #3)
///
/// `QuestGenerator`가 발급 후보 풀 평가 시 외부에서 주입한다.
/// 직접 Provider 의존을 회피하여 순수 함수 단위 테스트 가능.
class NamedHookContext {
  final List<Mercenary> mercenaries;
  final List<BandAchievement> bandAchievements;
  final String? flagshipMercId;

  /// region_flag hook용. key=regionId, value=해당 region의 unlockedFlags Set.
  /// (M8a 페이즈 4 #1, FR-B1)
  final Map<int, Set<String>> unlockedRegionFlags;

  /// faction_contact hook용. FactionContactService.isActive가 true인 contactId 집합.
  /// (M8a 페이즈 4 #1, FR-B1)
  final Set<String> activeContactIds;

  /// faction_reputation hook용. key=factionId, value=currentReputation.
  /// (M8a 페이즈 4 #1, FR-B1)
  final Map<String, int> factionReputations;

  const NamedHookContext({
    required this.mercenaries,
    required this.bandAchievements,
    required this.flagshipMercId,
    this.unlockedRegionFlags = const {},
    this.activeContactIds = const {},
    this.factionReputations = const {},
  });
}

/// 지명 의뢰 hook 평가 헬퍼.
///
/// 7종 hook_type 단일 조건 분기:
/// - `title`: namedHookValue가 보유 mercenary titleIds에 포함되면 true
/// - `achievement_count`: BandAchievementType.achievement 카운트 >= 임계
/// - `achievement_id`: 동일 templateId 보유 시 true (M6 MVP 데이터 미사용)
/// - `flagship`: flagshipMercId non-null 시 true
/// - `region_flag`: unlockedRegionFlags에 포함 또는 위업 templateId fallback (M8a FR-B1)
/// - `faction_contact`: activeContactIds에 포함 시 true (M8a FR-B1)
/// - `faction_reputation`: `'faction_<id>>=<int>'` 형식 파싱, 임계 이상 시 true (M8a FR-B1)
///
/// 미지원/null hook_type은 silent false. (M6 MVP — 복합 조건 M9+ 위임)
class NamedHookEvaluator {
  const NamedHookEvaluator._();

  static bool evaluateNamedHook(QuestPool pool, NamedHookContext ctx) {
    final hookType = pool.namedHookType;
    if (hookType == null) return false;
    final value = pool.namedHookValue ?? '';

    switch (hookType) {
      case 'title':
        if (value.isEmpty) return false;
        return ctx.mercenaries.any((m) => m.titleIds.contains(value));
      case 'achievement_count':
        final threshold = int.tryParse(value) ?? 0;
        if (threshold <= 0) return false;
        final count = ctx.bandAchievements
            .where((a) => a.type == BandAchievementType.achievement)
            .length;
        return count >= threshold;
      case 'achievement_id':
        if (value.isEmpty) return false;
        return ctx.bandAchievements.any((a) => a.templateId == value);
      case 'flagship':
        return ctx.flagshipMercId != null;
      // FR-B1: region_flag hook — 모든 region의 unlockedFlags 검색 + 위업 templateId fallback
      case 'region_flag':
        if (value.isEmpty) return false;
        for (final set in ctx.unlockedRegionFlags.values) {
          if (set.contains(value)) return true;
        }
        if (value.contains(':')) {
          return ctx.bandAchievements.any((a) => a.templateId == value);
        }
        return false;
      // FR-B1: faction_contact hook — activeContactIds 포함 여부
      case 'faction_contact':
        if (value.isEmpty) return false;
        return ctx.activeContactIds.contains(value);
      // FR-B1: faction_reputation hook — 'faction_<id>>=<int>' 형식 파싱
      case 'faction_reputation':
        final regex = RegExp(r'^(faction_[a-z_]+)>=(\-?\d+)$');
        final m = regex.firstMatch(value);
        if (m == null) return false;
        final factionId = m.group(1);
        final group2 = m.group(2);
        if (factionId == null || group2 == null) return false;
        final threshold = int.tryParse(group2);
        if (threshold == null) return false;
        final currentRep = ctx.factionReputations[factionId] ?? 0;
        return currentRep >= threshold;
      default:
        return false;
    }
  }

  /// 쿨다운 통과 여부. null 또는 과거 시각이면 통과.
  static bool isCooldownPassed(DateTime? nextAvailableAt, DateTime now) {
    if (nextAvailableAt == null) return true;
    return nextAvailableAt.isBefore(now);
  }
}
