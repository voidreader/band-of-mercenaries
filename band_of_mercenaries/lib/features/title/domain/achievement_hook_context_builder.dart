import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/title_service.dart';
import 'package:band_of_mercenaries/features/title/domain/top_contributor_helper.dart';

/// AchievementService.grant 시점에 호출.
/// hook_target 5종 분기에 필요한 보조 컨텍스트를 구성한다.
AchievementHookContext buildAchievementHookContext(
  Ref ref,
  BandAchievement achievement,
) {
  final mercList = ref.read(mercenaryListProvider);
  final userData = ref.read(userDataProvider);

  // alive 용병만 hook 후보 (사망 제외)
  final aliveMercs =
      mercList.where((m) => m.status != MercenaryStatus.dead).toList();
  final aliveIds = aliveMercs.map((m) => m.id).toList();

  // regionId: achievement.regionId 우선, 없으면 region 3 default
  // (most_dispatched_to_region_3 hook 보조 — 더스트빌이 페이즈 4 #2 주력 거점)
  final regionId = achievement.regionId ?? 3;
  final regionDispatchCounts = <String, int>{};
  final statKey = 'region_${regionId}_dispatch_count';
  for (final m in aliveMercs) {
    final count = m.stats[statKey];
    if (count != null && count > 0) {
      regionDispatchCounts[m.id] = count;
    }
  }

  return AchievementHookContext(
    achievement: achievement,
    protagonist: achievement.mercSnapshot,
    aliveDispatchableMercIds: aliveIds,
    regionDispatchCounts: regionDispatchCounts,
    lastDispatchTopMercId: userData?.lastDispatchProtagonistMercId,
    top24hContributorMercId: compute24hTopContributor(ref),
  );
}
