import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_service.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_version_provider.dart';

/// 생활권 6 지표 + 통합 완성도 계산.
/// gameTickProvider는 watch하지 않음 (6 지표는 시간 의존 없음).
final livingsphereDashboardProvider = Provider<LivingsphereDashboardSnapshot>((ref) {
  ref.watch(userDataProvider);
  ref.watch(staticDataProvider);
  ref.watch(region3StateVersionProvider); // RegionState 변경 트리거
  ref.watch(factionRefreshProvider); // 가입/탈퇴 트리거
  ref.watch(bandAchievementsProvider); // 위업 변경
  ref.watch(chainQuestProgressProvider); // 체인 진행 변경
  return LivingsphereDashboardService.computeSnapshot(ref);
});
