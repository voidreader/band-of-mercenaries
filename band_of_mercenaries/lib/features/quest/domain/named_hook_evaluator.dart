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

  const NamedHookContext({
    required this.mercenaries,
    required this.bandAchievements,
    required this.flagshipMercId,
  });
}

/// 지명 의뢰 hook 평가 헬퍼.
///
/// 4종 hook_type 단일 조건 분기:
/// - `title`: namedHookValue가 보유 mercenary titleIds에 포함되면 true
/// - `achievement_count`: BandAchievementType.achievement 카운트 >= 임계
/// - `achievement_id`: 동일 templateId 보유 시 true (M6 MVP 데이터 미사용)
/// - `flagship`: flagshipMercId non-null 시 true
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
