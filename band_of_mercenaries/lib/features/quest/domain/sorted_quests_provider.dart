import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart'
    show factionRefreshProvider, factionStateRepositoryProvider;
import 'package:band_of_mercenaries/features/investigation/domain/investigation_notifier.dart'
    show regionStateRepositoryProvider;
import 'package:band_of_mercenaries/features/investigation/domain/region_transformed_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_sort_service.dart';

/// 파견 화면 정렬 결과를 메모이제이션하는 derived Provider.
///
/// gameTickProvider(1초 주기)와 무관하게 입력 Provider 변경 시에만 재계산된다.
/// 무효화 트리거: questListProvider / chainQuestProgressProvider / userDataProvider /
/// staticDataProvider / currentRegionSectorChangesProvider(지역 변형) / factionRefreshProvider(가입/탈퇴).
final sortedPendingQuestsProvider = Provider<QuestSortResult>((ref) {
  final quests = ref.watch(questListProvider);
  final chainProgressAsync = ref.watch(chainQuestProgressProvider);
  final userData = ref.watch(userDataProvider);
  final staticDataAsync = ref.watch(staticDataProvider);

  // 무효화 트리거 (값은 사용 안 함, watch만)
  ref.watch(currentRegionSectorChangesProvider);
  ref.watch(factionRefreshProvider);

  final staticData = staticDataAsync.valueOrNull;
  if (userData == null || staticData == null) {
    return const QuestSortResult(chainTier0: [], sortedRest: []);
  }

  final pending = quests.where((q) => q.status == QuestStatus.pending).toList();
  final chainProgress = chainProgressAsync.valueOrNull ?? const <ChainQuestProgress>[];
  // Repository는 Provider<Repository> (불변 싱글턴) — 재구독 없이 read해도 항상 최신 인스턴스.
  // 무효화 트리거는 위의 currentRegionSectorChangesProvider/factionRefreshProvider watch가 담당.
  final regionState = ref.read(regionStateRepositoryProvider).getState(userData.region);
  final joinedFactionIds =
      ref.read(factionStateRepositoryProvider).getJoinedFactionIds().toSet();

  return QuestSortService.sort(
    quests: pending,
    chainProgress: chainProgress,
    currentRegion: userData.region,
    currentSector: userData.sector,
    regionState: regionState,
    questPools: staticData.questPools,
    questTypes: staticData.questTypes,
    joinedFactionIds: joinedFactionIds,
    eliteMonsters: staticData.eliteMonsters,
  );
});
