import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/quest/data/quest_repository.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart' show QuestCompletionService, QuestCompletionResult, TraitEventResult;
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_stat_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_acquisition_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';

final questRepositoryProvider = Provider((ref) => QuestRepository());

// key: questId, value: { mercId: TraitEventResult }
final pendingTraitEventsProvider = StateProvider<Map<String, Map<String, TraitEventResult>>>((ref) => {});

final questListProvider = StateNotifierProvider<QuestListNotifier, List<ActiveQuest>>((ref) {
  return QuestListNotifier(ref);
});

class QuestListNotifier extends StateNotifier<List<ActiveQuest>> {
  final Ref ref;
  late final QuestRepository _repo;
  final Set<String> _completingQuestIds = {};

  QuestListNotifier(this.ref) : super([]) {
    _repo = ref.read(questRepositoryProvider);
    _load();
    if (state.isEmpty) {
      generateQuests();
    }
    ref.listen(gameTickProvider, (prev, next) {
      _checkCompletions();
      _checkQuestRefresh();
    });
  }

  void _load() {
    state = _repo.getAll();
  }

  void refresh() => _load();

  /// 현재 플레이어의 세력 패시브 + 명성 랭크 보너스를 수집하여 반환.
  /// staticData 또는 userData가 없으면 빈 effects를 반환하여 중립값으로 동작.
  CollectedEffects _collectPassiveEffects() {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return const CollectedEffects.empty();

    final joinedIds = ref.read(factionStateRepositoryProvider).getJoinedFactionIds();
    final joinedFactions = staticData.factions
        .where((f) => joinedIds.contains(f.id))
        .toList();
    return PassiveBonusService.collect(
      reputation: userData.reputation,
      allRanks: staticData.ranks,
      joinedFactions: joinedFactions,
    );
  }

  Future<void> clearCompleted(String questId) async {
    await _repo.removeQuest(questId);
    _load();
  }

  Future<void> generateQuests() async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final region = staticData.regions.firstWhere((r) => r.region == userData.region);

    // 정보망 시설 + 패시브 슬롯 보너스를 통합 계산
    final questCount = getMaxQuestCount();

    await _repo.clearPending();
    final quests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: questCount,
      random: Random(),
    );
    await _repo.addQuests(quests);
    _load();
  }

  int getMaxQuestCount() {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return GameConstants.baseQuestCount;

    int count = GameConstants.baseQuestCount;

    // 정보망 시설 보너스
    final intelligenceLevel = userData.facilities['intelligence'] ?? 0;
    if (intelligenceLevel > 0) {
      final intelligenceFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'intelligence',
        orElse: () => staticData.facilities.first,
      );
      count += FacilityService.getExtraQuestCount(intelligenceFacility, intelligenceLevel);
    }

    // 세력 패시브 + 명성 랭크 dispatch_slot_bonus 가산 (상한 +10은 PassiveBonusService 내부 클램프)
    final passiveSlots = PassiveBonusService.getDispatchSlotBonus(_collectPassiveEffects());
    count += passiveSlots;

    return count;
  }

  Future<void> fillQuests() async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final maxCount = getMaxQuestCount();
    final activeCount = state.where(
      (q) => q.status == QuestStatus.pending || q.status == QuestStatus.inProgress,
    ).length;
    final deficit = maxCount - activeCount;
    if (deficit <= 0) return;

    final region = staticData.regions.firstWhere((r) => r.region == userData.region);

    final newQuests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: deficit,
      random: Random(),
    );
    await _repo.addQuests(newQuests);
    _load();
  }

  Future<bool> dispatch(String questId, List<String> mercIds) async {
    final staticData = ref.read(staticDataProvider).value;
    final speedMult = ref.read(speedMultiplierProvider);
    if (staticData == null) return false;

    final quest = state.firstWhere((q) => q.id == questId);
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);

    // Check dispatch cost
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final dispatchCost = QuestCalculator.calculateDispatchCost(
      baseDuration: questType.baseDuration,
      difficulty: quest.difficulty,
      minCost: difficulty.minDispatchCost,
      maxCost: difficulty.maxDispatchCost,
    );
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < dispatchCost) {
      return false;
    }

    // Deduct dispatch cost
    await ref.read(userDataProvider.notifier).spendGold(dispatchCost);

    final dispatchedMercs = ref.read(mercenaryListProvider)
        .where((m) => mercIds.contains(m.id))
        .toList();
    final avgAgi = dispatchedMercs.isEmpty
        ? 50
        : (dispatchedMercs.fold<int>(0, (s, m) => s + m.effectiveAgi) / dispatchedMercs.length).round();
    final duration = QuestCalculator.calculateDispatchDuration(
      baseDuration: questType.baseDuration,
      difficulty: quest.difficulty,
      speedMultiplier: speedMult,
      partyAverageAgi: avgAgi,
    );

    final endTime = DateTime.now().add(duration);
    await _repo.startQuest(questId, mercIds, endTime, dispatchCost: dispatchCost);

    final mercNotifier = ref.read(mercenaryListProvider.notifier);
    for (final mercId in mercIds) {
      await ref.read(mercenaryRepositoryProvider).setDispatched(mercId, true);
    }
    mercNotifier.refresh();
    _load();
    return true;
  }

  void recalculateTimers(double oldSpeed, double newSpeed) {
    bool changed = false;
    for (final quest in state) {
      if (quest.status == QuestStatus.inProgress && quest.endTime != null && quest.startTime != null) {
        final newEndTime = recalculateEndTime(quest.endTime, quest.startTime, oldSpeed, newSpeed);
        if (newEndTime != quest.endTime) {
          quest.endTime = newEndTime;
          quest.save();
          changed = true;
        }
      }
    }
    if (changed) _load();
  }

  static const _questRefreshDuration = Duration(hours: 1);

  void _checkQuestRefresh() {
    final now = DateTime.now();
    final speedMult = ref.read(speedMultiplierProvider);

    final expiredQuests = <ActiveQuest>[];
    for (final quest in state) {
      if (quest.status == QuestStatus.pending && quest.createdAt != null) {
        final realElapsed = now.difference(quest.createdAt!);
        final gameElapsedMs = (realElapsed.inMilliseconds * speedMult).round();
        final gameElapsed = Duration(milliseconds: gameElapsedMs);
        if (gameElapsed >= _questRefreshDuration) {
          expiredQuests.add(quest);
        }
      }
    }

    if (expiredQuests.isNotEmpty) {
      _refreshExpiredQuests(expiredQuests);
    }
  }

  Future<void> _refreshExpiredQuests(List<ActiveQuest> expired) async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final region = staticData.regions.firstWhere((r) => r.region == userData.region);

    for (final quest in expired) {
      await _repo.removeQuest(quest.id);
    }

    final newQuests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: expired.length,
      random: Random(),
    );
    await _repo.addQuests(newQuests);
    _load();
  }

  void _checkCompletions() {
    final now = DateTime.now();
    for (final quest in state) {
      if (quest.status == QuestStatus.inProgress && quest.endTime != null) {
        if (now.isAfter(quest.endTime!) && !_completingQuestIds.contains(quest.id)) {
          _completingQuestIds.add(quest.id);
          _completeQuest(quest).whenComplete(() => _completingQuestIds.remove(quest.id));
        }
      }
    }
  }

  Future<void> _completeQuest(ActiveQuest quest) async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final mercs = ref.read(mercenaryListProvider)
        .where((m) => quest.dispatchedMercIds.contains(m.id))
        .toList();

    final passiveEffects = _collectPassiveEffects();
    final result = QuestCompletionService.calculate(
      quest: quest,
      mercs: mercs,
      staticData: staticData,
      playerRegion: userData.region,
      facilities: userData.facilities,
      speedMultiplier: ref.read(speedMultiplierProvider),
      random: Random(),
      passiveEffects: passiveEffects,
    );

    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    await _applyCompletionResult(quest, result, mercs, deathRate: difficulty.deathRate);
  }

  Future<void> _applyCompletionResult(
    ActiveQuest quest,
    QuestCompletionResult result,
    List<Mercenary> mercs, {
    double deathRate = 0.05,
  }) async {
    final traitEvents = <String, TraitEventResult>{};
    await _repo.completeQuest(
      quest.id,
      result.resultType,
      rewardGold: result.rewardGold,
      totalWage: result.totalWage,
      earnedXp: result.xpGain,
      earnedReputation: result.repGain,
    );

    final resultText = {
      QuestResult.greatSuccess: '대성공',
      QuestResult.success: '성공',
      QuestResult.failure: '실패',
      QuestResult.criticalFailure: '대실패',
    }[result.resultType] ?? '완료';
    ref.read(activityLogProvider.notifier).addLog(
      '퀘스트 "${quest.questName}" $resultText!',
      ActivityLogType.questResult,
    );

    if (result.netReward > 0) {
      await ref.read(userDataProvider.notifier).addGold(result.netReward);
    }

    final mercRepo = ref.read(mercenaryRepositoryProvider);
    for (final damage in result.mercDamages) {
      await mercRepo.setDispatched(damage.mercId, false);
      if (damage.newStatus != MercenaryStatus.normal) {
        await mercRepo.updateStatus(damage.mercId, damage.newStatus, endTime: damage.recoveryEndTime);
      }
    }

    for (final merc in mercs) {
      final damage = result.mercDamages.firstWhere((d) => d.mercId == merc.id);
      if (damage.newStatus != MercenaryStatus.dead) {
        await mercRepo.addXpAndCheckLevel(merc.id, result.xpGain);
        final newStats = MercenaryStatService.updateStatsAfterQuest(
          merc.stats,
          resultType: result.resultType,
          questTypeId: quest.questTypeId,
          difficulty: quest.difficulty,
          partySize: mercs.length,
          damageStatus: damage.newStatus,
          damageRoll: damage.damageRoll,
          deathRate: deathRate,
          rewardGold: result.rewardGold,
          mercLevel: merc.level,
        );
        final userData = ref.read(userDataProvider);
        final finalStats = MercenaryStatService.updateStatsForFacilityBenefit(
          newStats,
          facilities: userData?.facilities ?? {},
          isFailure: result.resultType == QuestResult.failure ||
              result.resultType == QuestResult.criticalFailure,
          damageStatus: damage.newStatus,
        );
        await mercRepo.updateStats(merc.id, finalStats);

        final staticData = ref.read(staticDataProvider).value;
        if (staticData != null) {
          final passiveEffects = _collectPassiveEffects();
          final acquisitionRelief = PassiveBonusService.getTraitAcquisitionRelief(passiveEffects);
          final evolutionRelief = PassiveBonusService.getTraitEvolutionRelief(passiveEffects);

          final candidates = TraitAcquisitionService.checkAcquisitionCandidates(
            stats: finalStats,
            currentTraitIds: merc.allTraitIds,
            traitHistory: merc.traitHistory,
            allTraits: staticData.traits,
            categories: staticData.traitCategories,
            conflicts: staticData.traitConflicts,
            synergies: staticData.traitSynergies,
            passiveRelief: acquisitionRelief,
          );
          if (candidates.isNotEmpty) {
            await mercRepo.addTrait(merc.id, candidates.first);
            final traitData = staticData.traits.where((t) => t.key == candidates.first).firstOrNull;
            if (traitData != null) {
              ref.read(activityLogProvider.notifier).addLog(
                '${merc.name}이(가) "${traitData.name}" 트레잇을 획득!',
                ActivityLogType.traitAcquired,
              );
            }
          }

          // Refresh traitIds after potential acquisition
          final updatedMerc = mercRepo.getAll().firstWhere((m) => m.id == merc.id);
          final currentTraitIds = updatedMerc.allTraitIds;

          // Single evolution: collect candidates only (no auto-apply)
          final singleCandidates = TraitEvolutionService.checkSingleEvolutions(
            stats: newStats,
            currentTraitIds: currentTraitIds,
            transitions: staticData.traitTransitions,
            allTraits: staticData.traits,
            passiveRelief: evolutionRelief,
          );

          // Combo evolution: collect candidates only if no single evolution
          List<ComboEvolutionCandidate> comboCandidates = [];
          if (singleCandidates.isEmpty) {
            comboCandidates = TraitEvolutionService.checkComboEvolutions(
              currentTraitIds: currentTraitIds,
              comboEvolutions: staticData.traitComboEvolutions,
              allTraits: staticData.traits,
              passiveRelief: evolutionRelief,
            );
          }

          // Store trait event results
          final acquiredKey = candidates.isNotEmpty ? candidates.first : null;
          traitEvents[merc.id] = TraitEventResult(
            acquiredTraitKey: acquiredKey,
            singleEvoCandidates: singleCandidates,
            comboEvoCandidates: comboCandidates,
          );
        }
      }
    }

    if (result.repGain > 0) {
      await ref.read(userDataProvider.notifier).addReputation(result.repGain);
    }

    if (traitEvents.values.any((e) => e.hasEvents)) {
      final current = ref.read(pendingTraitEventsProvider);
      ref.read(pendingTraitEventsProvider.notifier).state = {
        ...current,
        quest.id: traitEvents,
      };
    }

    ref.read(mercenaryListProvider.notifier).refresh();
    _load();
  }
}
