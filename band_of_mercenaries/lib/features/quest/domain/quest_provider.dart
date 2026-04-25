import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/data/quest_repository.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart' show QuestCompletionService, QuestCompletionResult, TraitEventResult;
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart' show EliteLootResult;
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
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/settings_keys.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_effect_context.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/features/quest/domain/special_flag_processor.dart';

final questRepositoryProvider = Provider((ref) => QuestRepository());

// ─── 세력 전용 퀘스트 쿨다운 헬퍼 ─────────────────────────────────────────

Map<String, DateTime> _loadActiveCooldowns(Box settingsBox) {
  final raw = settingsBox.get(SettingsKeys.factionQuestCooldowns) as String?;
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final now = DateTime.now();
    final result = <String, DateTime>{};
    decoded.forEach((key, value) {
      final ts = DateTime.tryParse(value as String);
      if (ts != null && now.difference(ts) < GameConstants.factionQuestCooldown) {
        result[key] = ts;
      }
    });
    _saveCooldowns(settingsBox, result);
    return result;
  } catch (_) {
    return {};
  }
}

void _saveCooldowns(Box settingsBox, Map<String, DateTime> map) {
  final encoded = jsonEncode(
    map.map((k, v) => MapEntry(k, v.toIso8601String())),
  );
  settingsBox.put(SettingsKeys.factionQuestCooldowns, encoded);
}

// key: questId, value: { mercId: TraitEventResult }
final pendingTraitEventsProvider = StateProvider<Map<String, Map<String, TraitEventResult>>>((ref) => {});

// key: questId, value: EliteLootResult
final pendingEliteLootProvider = StateProvider<Map<String, EliteLootResult>>((ref) => {});

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

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final joinedFactionIds = factionRepo.getJoinedFactionIds();
    final factionReputations = factionRepo.getAllReputations();
    final clueLevelsInRegion = factionRepo.getClueLevelsByRegion(userData.region);
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final cooldownMap = _loadActiveCooldowns(settingsBox);

    await _repo.clearPending();
    final quests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: questCount,
      random: Random(),
      joinedFactionIds: joinedFactionIds,
      factionReputations: factionReputations,
      clueLevelsInRegion: clueLevelsInRegion,
      cooldownExclusiveQuestIds: cooldownMap.keys.toSet(),
      activeSlotCount: questCount,
      eliteMonsters: staticData.eliteMonsters,
      regionEnvironmentTags: _currentRegionEnvironmentTags(userData.region, staticData),
      triggeredDiscoveries: _currentTriggeredDiscoveries(userData.region),
      currentSectorIndex: (userData.sector - 1),
      sectorChanges: ref.read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
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

  Future<void> injectChainStep(ChainQuestData stepData, int userRegion) async {
    final id =
        'chain_${stepData.chainId}_${stepData.step}_${DateTime.now().millisecondsSinceEpoch}';
    final quest = ActiveQuest(
      id: id,
      questPoolId: stepData.id,
      questTypeId: stepData.questTypeId,
      difficulty: stepData.difficulty,
      region: stepData.regionId ?? userRegion,
      questName: stepData.name,
      createdAt: DateTime.now(),
      isChainStep: true,
      chainId: stepData.chainId,
      chainStep: stepData.step,
    );
    await _repo.addQuests([quest]);
    _load();
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

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final joinedFactionIds = factionRepo.getJoinedFactionIds();
    final factionReputations = factionRepo.getAllReputations();
    final clueLevelsInRegion = factionRepo.getClueLevelsByRegion(userData.region);
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final cooldownMap = _loadActiveCooldowns(settingsBox);

    final newQuests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: deficit,
      random: Random(),
      joinedFactionIds: joinedFactionIds,
      factionReputations: factionReputations,
      clueLevelsInRegion: clueLevelsInRegion,
      cooldownExclusiveQuestIds: cooldownMap.keys.toSet(),
      activeSlotCount: maxCount,
      eliteMonsters: staticData.eliteMonsters,
      regionEnvironmentTags: _currentRegionEnvironmentTags(userData.region, staticData),
      triggeredDiscoveries: _currentTriggeredDiscoveries(userData.region),
      currentSectorIndex: (userData.sector - 1),
      sectorChanges: ref.read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
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

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final joinedFactionIds = factionRepo.getJoinedFactionIds();
    final factionReputations = factionRepo.getAllReputations();
    final clueLevelsInRegion = factionRepo.getClueLevelsByRegion(userData.region);
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final cooldownMap = _loadActiveCooldowns(settingsBox);
    final totalSlotCount = getMaxQuestCount();

    final newQuests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: expired.length,
      random: Random(),
      joinedFactionIds: joinedFactionIds,
      factionReputations: factionReputations,
      clueLevelsInRegion: clueLevelsInRegion,
      cooldownExclusiveQuestIds: cooldownMap.keys.toSet(),
      activeSlotCount: totalSlotCount,
      eliteMonsters: staticData.eliteMonsters,
      regionEnvironmentTags: _currentRegionEnvironmentTags(userData.region, staticData),
      triggeredDiscoveries: _currentTriggeredDiscoveries(userData.region),
      currentSectorIndex: (userData.sector - 1),
      sectorChanges: ref.read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
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

    // 파티 장비 스탯 보정 수집 (mercId → EquipmentStatBonus)
    final partyEquipmentBonuses = await EquipmentEffectContext.forParty(
      ref,
      mercs.map((m) => m.id).toList(),
    );

    // 파티 전설 유니크 효과 수집
    final legendaryEffects = <LegendaryEffect>[];
    for (final m in mercs) {
      legendaryEffects.addAll(await EquipmentEffectContext.legendariesFor(ref, m.id));
    }

    // 용병단 장비 패시브 효과 수집
    final guildEquipments = await EquipmentEffectContext.guildEquipmentEffects(ref);

    // 전설 ④ reward_bonus → PassiveEffect로 변환하여 패시브 경로에 편입
    final personalEquipmentLegendaries = <PassiveEffect>[];
    for (final leg in legendaryEffects) {
      if (leg is LegendaryRewardBonus) {
        personalEquipmentLegendaries.add(
          PassiveEffect.questRewardMultiplier(questType: 'all', value: leg.multiplier),
        );
      }
    }

    // 용병별 전설 ⑤ 쿨다운 맵
    final mercCooldowns = <String, DateTime?>{
      for (final m in mercs) m.id: m.legendaryDeathPreventionCooldownUntil,
    };

    // 세력·명성 패시브 + 장비 소스를 합산한 최종 CollectedEffects
    final basePassive = _collectPassiveEffects();
    final passiveEffects = CollectedEffects([
      ...basePassive.effects,
      ...guildEquipments,
      ...personalEquipmentLegendaries,
    ]);

    final result = QuestCompletionService.calculate(
      quest: quest,
      mercs: mercs,
      staticData: staticData,
      playerRegion: userData.region,
      facilities: userData.facilities,
      speedMultiplier: ref.read(speedMultiplierProvider),
      random: Random(),
      passiveEffects: passiveEffects,
      partyEquipmentBonuses: partyEquipmentBonuses,
      legendaryEffects: legendaryEffects,
      mercCooldowns: mercCooldowns,
      eliteLootEntries: staticData.eliteLootEntries,
      isChainStep: quest.isChainQuest,
    );

    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    await _applyCompletionResult(quest, result, mercs, staticData: staticData, deathRate: difficulty.deathRate);
  }

  Future<void> _applyCompletionResult(
    ActiveQuest quest,
    QuestCompletionResult result,
    List<Mercenary> mercs, {
    required StaticGameData staticData,
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

    final eliteLoot = result.eliteLoot;
    if (eliteLoot != null) {
      if (eliteLoot.bonusGold > 0) {
        await ref.read(userDataProvider.notifier).addGold(eliteLoot.bonusGold);
      }
      final inventory = ref.read(inventoryRepositoryProvider);
      final items = staticData.items;
      for (final itemId in eliteLoot.itemDrops) {
        await inventory.addItem(itemId: itemId, items: items);
      }
      final currentLoot = ref.read(pendingEliteLootProvider);
      ref.read(pendingEliteLootProvider.notifier).state = {...currentLoot, quest.id: eliteLoot};
    }

    final mercRepo = ref.read(mercenaryRepositoryProvider);
    for (final damage in result.mercDamages) {
      await mercRepo.setDispatched(damage.mercId, false);
      // 사망 판정 시 정수 소실 로그 기록 (용병 삭제 이전)
      if (damage.newStatus == MercenaryStatus.dead) {
        final deadMerc = mercs.where((m) => m.id == damage.mercId).firstOrNull;
        if (deadMerc != null) {
          final totalPermanent = deadMerc.permanentStr
              + deadMerc.permanentIntelligence
              + deadMerc.permanentVit
              + deadMerc.permanentAgi;
          if (totalPermanent > 0) {
            ref.read(activityLogProvider.notifier).addLog(
              '${deadMerc.name}이(가) 사망했다. 투입 정수 누적 +$totalPermanent 소실',
              ActivityLogType.essenceLostOnDeath,
            );
          }
        }
      }
      if (damage.newStatus != MercenaryStatus.normal) {
        await mercRepo.updateStatus(damage.mercId, damage.newStatus, endTime: damage.recoveryEndTime);
      }
      // 전설 ⑤ 사망 방지 발동 시 쿨다운 기록
      if (damage.legendaryPreventedDeath && damage.newCooldownUntil != null) {
        await mercRepo.setLegendaryCooldown(damage.mercId, damage.newCooldownUntil);
      }
    }

    for (final merc in mercs) {
      final damage = result.mercDamages.firstWhere((d) => d.mercId == merc.id);
      if (damage.newStatus != MercenaryStatus.dead) {
        await mercRepo.addXpAndCheckLevel(merc.id, result.xpGain);
        final traitLearningBoost = merc.traitLearningBoostUntil != null &&
            DateTime.now().isBefore(merc.traitLearningBoostUntil!);
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
          traitLearningBoost: traitLearningBoost,
        );
        final userData = ref.read(userDataProvider);
        final finalStats = MercenaryStatService.updateStatsForFacilityBenefit(
          newStats,
          facilities: userData?.facilities ?? {},
          isFailure: result.resultType == QuestResult.failure ||
              result.resultType == QuestResult.criticalFailure,
          damageStatus: damage.newStatus,
          traitLearningBoost: traitLearningBoost,
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

    // SpecialFlag 처리
    if (quest.specialFlags != null && quest.specialFlags!.isNotEmpty) {
      final flagResult = SpecialFlagProcessor.apply(
        quest: quest,
        resultType: result.resultType,
        partyMercs: mercs,
        staticData: staticData,
        random: Random(),
      );

      if (!flagResult.isEmpty) {
        // 보상 아이템 지급
        if (flagResult.extraItemIds.isNotEmpty) {
          final inventory = ref.read(inventoryRepositoryProvider);
          for (final itemId in flagResult.extraItemIds) {
            await inventory.addItem(itemId: itemId, items: staticData.items);
          }
        }

        // 추가 명성 (음수 포함)
        if (flagResult.extraReputation != 0) {
          await ref.read(userDataProvider.notifier).addReputation(flagResult.extraReputation);
        }

        // trait_learning_boost 갱신
        if (flagResult.boostedMercIds.isNotEmpty) {
          final boostUntil = DateTime.now().add(const Duration(hours: 24));
          for (final mercId in flagResult.boostedMercIds) {
            await mercRepo.setTraitLearningBoost(mercId, boostUntil);
          }
        }
      }
    }

    if (result.repGain > 0) {
      await ref.read(userDataProvider.notifier).addReputation(result.repGain);
    }

    // 세력 평판 지급
    if (result.factionTag != null && result.factionRepGain > 0) {
      ref.read(factionStateRepositoryProvider).addReputation(
        result.factionTag!,
        result.factionRepGain,
      );
    }

    // 전용 퀘스트 완료 시 쿨다운 기록
    if (quest.isFactionExclusive) {
      final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
      final cooldowns = _loadActiveCooldowns(settingsBox);
      cooldowns[quest.id] = DateTime.now();
      _saveCooldowns(settingsBox, cooldowns);
    }

    if (traitEvents.values.any((e) => e.hasEvents)) {
      final current = ref.read(pendingTraitEventsProvider);
      ref.read(pendingTraitEventsProvider.notifier).state = {
        ...current,
        quest.id: traitEvents,
      };
    }

    // 체인 퀘스트 단계 완료 후크
    if (quest.isChainQuest && quest.chainId != null && quest.chainStep != null) {
      final chainStepData = staticData.chainQuests
          .where((c) => c.chainId == quest.chainId && c.step == quest.chainStep)
          .firstOrNull;
      if (chainStepData != null) {
        final chainQuestService = ref.read(chainQuestServiceProvider);
        final questResultType = {
          QuestResult.greatSuccess: 'greatSuccess',
          QuestResult.success: 'success',
          QuestResult.failure: 'failure',
          QuestResult.criticalFailure: 'criticalFailure',
        }[result.resultType] ?? 'failure';

        await chainQuestService.onStepCompleted(
          chainId: quest.chainId!,
          step: quest.chainStep!,
          questResultType: questResultType,
          partyMercs: mercs,
          allMercs: ref.read(mercenaryListProvider),
          questTypeId: quest.questTypeId,
          chainStepData: chainStepData,
          logActivity: (message, type) {
            ref.read(activityLogProvider.notifier).addLog(message, type);
          },
          onChainCompleted: (chainId, finalStep) async {
            final userData = ref.read(userDataProvider);
            if (userData != null &&
                !chainQuestService.canAdvanceToFinal(
                    finalStep: finalStep, user: userData)) {
              ref.read(activityLogProvider.notifier).addLog(
                '연계 최종 단계 진입 불가: 길드 장비 슬롯 부족',
                ActivityLogType.chainProgressed,
              );
              return;
            }
            await chainQuestService.completeChain(
              chainId: chainId,
              finalStep: finalStep,
              logActivity: (message, type) {
                ref.read(activityLogProvider.notifier).addLog(message, type);
              },
              addReputation: (reputation) async {
                await ref
                    .read(userDataProvider.notifier)
                    .addReputation(reputation);
              },
              addCompletedChain: (id) async {
                await ref
                    .read(userDataProvider.notifier)
                    .addCompletedChain(id);
              },
              publishCompleted: (event) {
                ref.read(chainCompletedProvider.notifier).state = event;
              },
            );
          },
        );
      }
    }

    ref.read(mercenaryListProvider.notifier).refresh();
    _load();
  }

  List<String> _currentRegionEnvironmentTags(int regionId, StaticGameData staticData) {
    final region = staticData.regions.where((r) => r.region == regionId).firstOrNull;
    return region?.environmentTags ?? const [];
  }

  Set<String> _currentTriggeredDiscoveries(int regionId) {
    final state = ref.read(regionStateRepositoryProvider).getState(regionId);
    return state?.triggeredDiscoveries.toSet() ?? const {};
  }
}
