import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_service.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/chain_region_state_mapping.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

final chainQuestServiceProvider = Provider<ChainQuestService>((ref) {
  return ChainQuestService(
    ref.watch(chainQuestRepositoryProvider),
    grantAchievement: (templateId, snapshot, regionId, payload) async {
      await ref.read(achievementServiceProvider).grant(
        templateId,
        mercSnapshot: snapshot,
        regionId: regionId,
        payload: payload,
      );
    },
    buildSnapshot: (mercId) {
      if (mercId == null) return null;
      final mercs = ref.read(mercenaryListProvider);
      final merc = mercs.where((m) => m.id == mercId).firstOrNull;
      if (merc == null) return null;
      final staticData = ref.read(staticDataProvider).valueOrNull;
      if (staticData == null) return null;
      final job = staticData.jobs.where((j) => j.id == merc.jobId).firstOrNull;
      if (job == null) return null;
      return MercenarySnapshot.fromMercenary(merc, jobName: job.name, tier: job.tier);
    },
    // M7 페이즈 4 #1 FR-4b — 체인 완주 시 region dangerScore + flag toggle
    applyRegionStateFromChain: (chainId) async {
      final entry = chainRegionStateMapping[chainId];
      if (entry == null) return;
      final repo = ref.read(regionStateRepositoryProvider);
      final toggled = await repo.toggleFlag(
        regionId: entry.regionId,
        flag: entry.flag,
        ref: ref,
      );
      if (toggled) {
        await repo.addDangerScore(
          regionId: entry.regionId,
          delta: entry.delta,
          source: 'chain_$chainId',
          ref: ref,
        );
      }
    },
  );
});

final chainQuestProgressProvider = StreamProvider<List<ChainQuestProgress>>((ref) {
  return ref.watch(chainQuestRepositoryProvider).watchAll();
});

final activeChainProvider = Provider<ChainQuestProgress?>((ref) {
  final progresses = ref.watch(chainQuestProgressProvider).valueOrNull ?? [];
  final active = progresses.where((p) => p.status == ChainQuestStatus.active).toList();
  if (active.isEmpty) return null;
  final sorted = [...active]
    ..sort((a, b) {
      final aTime = a.currentStepAvailableAt;
      final bTime = b.currentStepAvailableAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime);
    });
  return sorted.first;
});

final chainCompletedProvider = StateProvider<ChainCompletedEvent?>((ref) => null);
