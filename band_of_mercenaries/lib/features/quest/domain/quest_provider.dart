import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/data/quest_repository.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart'
    show QuestCompletionService, QuestCompletionResult, TraitEventResult;
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart'
    show EliteLootResult;
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
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/features/quest/domain/special_flag_processor.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_side_effects.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';

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
      if (ts != null &&
          now.difference(ts) < GameConstants.factionQuestCooldown) {
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
final pendingTraitEventsProvider =
    StateProvider<Map<String, Map<String, TraitEventResult>>>((ref) => {});

// key: questId, value: EliteLootResult
final pendingEliteLootProvider = StateProvider<Map<String, EliteLootResult>>(
  (ref) => {},
);

final questListProvider =
    StateNotifierProvider<QuestListNotifier, List<ActiveQuest>>((ref) {
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
    } else {
      // _PostSyncApp이 userData != null이 된 후에야 BandOfMercenariesApp을 빌드하므로,
      // questListProvider 첫 생성 시점에는 아래 ref.listen의 prev null→non-null 트랜지션이
      // 이미 종료되어 발화하지 않는다. initializeNewGame이 일반 퀘스트를 Hive에 미리
      // 저장한 신규 유저 플로우에서 고정 사건 의뢰가 누락되는 문제를 보강.
      Future.microtask(_injectFixedSettlementQuest);
    }
    // 핫 리스타트·중간 재진입 등 prev=null인 경로 보조 안전망
    ref.listen(userDataProvider, (prev, next) {
      if (prev == null && next != null) {
        debugPrint(
          '[BOM][Quest] userDataProvider null→non-null 감지 → _load 재실행',
        );
        _load();
        if (state.isEmpty) {
          generateQuests();
        } else {
          // initializeNewGame이 퀘스트를 Hive에 미리 저장한 경우:
          // generateQuests()가 호출되지 않으므로 고정 사건 의뢰를 별도 주입.
          // tryActivateSettlement()는 state=userData 설정 전에 await 완료되므로
          // 이 시점에 chain progress가 이미 존재한다.
          _injectFixedSettlementQuest();
        }
      }
    });
    ref.listen(gameTickProvider, (prev, next) {
      _checkCompletions();
      _checkQuestRefresh();
    });
  }

  void _load() {
    state = _repo.getAll();
    final pending = state.where((q) => q.status == QuestStatus.pending).length;
    final inProgress = state
        .where((q) => q.status == QuestStatus.inProgress)
        .length;
    debugPrint(
      '[BOM][Quest] _load: 총 ${state.length}개 (대기 $pending / 진행 $inProgress)',
    );
  }

  void refresh() => _load();

  /// 현재 플레이어의 세력 패시브 + 명성 랭크 보너스를 수집하여 반환.
  /// staticData 또는 userData가 없으면 빈 effects를 반환하여 중립값으로 동작.
  CollectedEffects _collectPassiveEffects() {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) {
      return const CollectedEffects.empty();
    }

    final joinedIds = ref
        .read(factionStateRepositoryProvider)
        .getJoinedFactionIds();
    final joinedFactions = staticData.factions
        .where((f) => joinedIds.contains(f.id))
        .toList();
    return PassiveBonusService.collect(
      reputation: userData.reputation,
      allRanks: staticData.ranks,
      joinedFactions: joinedFactions,
    );
  }

  /// 현재 거점 신뢰도 단계 조회.
  int _getCurrentTrustLevel() {
    final userData = ref.read(userDataProvider);
    if (userData == null) return 0;
    return ref
        .read(regionStateRepositoryProvider)
        .getSettlementTrust(userData.region)
        .level;
  }

  Future<void> clearCompleted(String questId) async {
    await _repo.removeQuest(questId);
    _load();
  }

  Future<void> generateQuests() async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) {
      debugPrint(
        '[BOM][Quest] generateQuests 중단: staticData=${staticData != null}, userData=${userData != null}',
      );
      return;
    }
    debugPrint('[BOM][Quest] generateQuests 시작 (region: ${userData.region})');

    final region = staticData.regions.firstWhere(
      (r) => r.region == userData.region,
    );

    // 정보망 시설 + 패시브 슬롯 보너스를 통합 계산
    final questCount = getMaxQuestCount();

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final joinedFactionIds = factionRepo.getJoinedFactionIds();
    final factionReputations = factionRepo.getAllReputations();
    final clueLevelsInRegion = factionRepo.getClueLevelsByRegion(
      userData.region,
    );
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final cooldownMap = _loadActiveCooldowns(settingsBox);

    await _repo.clearPending();
    final pyegwangProgress = ref
        .read(chainQuestRepositoryProvider)
        .get('settlement_3_pyegwang_reopen');
    final chainIdForSpawn = pyegwangProgress?.status == ChainQuestStatus.active
        ? 'settlement_3_pyegwang_reopen'
        : null;
    final newbieGate = NewbieGateResolver.resolve(
      reputation: userData.reputation,
      ranks: staticData.ranks,
    );
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
      regionEnvironmentTags: _currentRegionEnvironmentTags(
        userData.region,
        staticData,
      ),
      triggeredDiscoveries: _currentTriggeredDiscoveries(userData.region),
      // user.sector(1-based 1..sectorCount) → quest_generator/sectorChanges key(0-based) 변환 위해 -1.
      currentSectorIndex: (userData.sector - 1),
      sectorChanges: ref
          .read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
      currentTrustLevel: _getCurrentTrustLevel(),
      currentChainId: chainIdForSpawn,
      currentChainStep: pyegwangProgress?.currentStep,
      gate: newbieGate,
    );
    await _repo.addQuests(quests);
    debugPrint('[BOM][Quest] generateQuests 완료: ${quests.length}개 생성');
    await _injectFixedSettlementQuest();
    _load();
  }

  int getMaxQuestCount() {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) {
      return GameConstants.baseQuestCount;
    }

    int count = GameConstants.baseQuestCount;

    // 정보망 시설 보너스
    final intelligenceLevel = userData.facilities['intelligence'] ?? 0;
    if (intelligenceLevel > 0) {
      final intelligenceFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'intelligence',
        orElse: () => staticData.facilities.first,
      );
      count += FacilityService.getExtraQuestCount(
        intelligenceFacility,
        intelligenceLevel,
      );
    }

    // 세력 패시브 + 명성 랭크 dispatch_slot_bonus 가산 (상한 +10은 PassiveBonusService 내부 클램프)
    final passiveSlots = PassiveBonusService.getDispatchSlotBonus(
      _collectPassiveEffects(),
    );
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

  /// 고정 사건 의뢰를 현재 진행 상태에 따라 ActiveQuest로 생성한다.
  ///
  /// 호출 시점:
  /// - generateQuests() 완료 직후
  /// - refreshAvailableQuests() 호출 시 (단계 완료·신뢰도 단계 진입 후)
  ///
  /// 의사 코드:
  /// 1. chainQuestRepositoryProvider에서 settlement_3_pyegwang_reopen 진행 조회
  /// 2. progress null 또는 status==completed면 return
  /// 3. quest_pools에서 is_fixed=true AND fixed_chain_id='settlement_3_pyegwang_reopen'
  ///    AND fixed_step=currentStep AND trust_threshold <= currentTrustLevel 검색
  /// 4. 이미 ActiveQuest(pending/inProgress)로 존재하는 경우 skip
  /// 5. 조건 만족 시 ActiveQuest 생성 (isChainStep=true, chainId=..., chainStep=currentStep)
  Future<void> _injectFixedSettlementQuest() async {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    const chainId = 'settlement_3_pyegwang_reopen';
    final progress = ref.read(chainQuestRepositoryProvider).get(chainId);
    if (progress == null || progress.status == ChainQuestStatus.completed) {
      return;
    }

    final currentStep = progress.currentStep;
    final currentTrustLevel = _getCurrentTrustLevel();

    final fixedPool = staticData.questPools
        .where(
          (p) =>
              p.isFixed &&
              p.fixedChainId == chainId &&
              p.fixedStep == currentStep &&
              (p.trustThreshold ?? 1) <= currentTrustLevel,
        )
        .firstOrNull;

    if (fixedPool == null) return;

    // state 최신화 후 중복 체크 (비동기 흐름에서 state가 stale할 수 있으므로)
    _load();
    // 이미 pending/inProgress인 고정 의뢰가 존재하면 skip (중복 방지)
    final alreadyActive = state.any(
      (q) =>
          q.isChainQuest &&
          q.chainId == chainId &&
          q.chainStep == currentStep &&
          (q.status == QuestStatus.pending ||
              q.status == QuestStatus.inProgress),
    );
    if (alreadyActive) return;

    final quest = ActiveQuest(
      id: 'fixed_${chainId}_step${currentStep}_${DateTime.now().millisecondsSinceEpoch}',
      questPoolId: fixedPool.id,
      questTypeId: fixedPool.typeId,
      difficulty: fixedPool.difficulty.round(),
      region: userData.region,
      questName: fixedPool.name,
      createdAt: DateTime.now(),
      isChainStep: true,
      chainId: chainId,
      chainStep: currentStep,
    );
    await _repo.addQuests([quest]);
    _load();
  }

  /// 단계 진입 또는 사건 step 완료 후 고정 의뢰 재노출을 트리거한다.
  ///
  /// 페이즈 4 #5 호출 시점:
  /// - RegionStateRepository.addSettlementTrust() 내에서 levelUp 발생 시
  /// - QuestCompletionService 내 settlement_ 사건 step 완료 후
  ///
  /// 본 명세(페이즈 4 #3)에서는 메서드 시그니처와 내부 로직 정의만 수행.
  /// 실제 호출은 페이즈 4 #5에서 연결.
  Future<void> refreshAvailableQuests() async {
    await _injectFixedSettlementQuest();
    await fillQuests();
  }

  Future<void> fillQuests() async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final maxCount = getMaxQuestCount();
    final activeCount = state
        .where(
          (q) =>
              q.status == QuestStatus.pending ||
              q.status == QuestStatus.inProgress,
        )
        .length;
    final deficit = maxCount - activeCount;
    if (deficit <= 0) return;

    final region = staticData.regions.firstWhere(
      (r) => r.region == userData.region,
    );

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final joinedFactionIds = factionRepo.getJoinedFactionIds();
    final factionReputations = factionRepo.getAllReputations();
    final clueLevelsInRegion = factionRepo.getClueLevelsByRegion(
      userData.region,
    );
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final cooldownMap = _loadActiveCooldowns(settingsBox);

    final fillPyegwangProgress = ref
        .read(chainQuestRepositoryProvider)
        .get('settlement_3_pyegwang_reopen');
    final fillChainIdForSpawn =
        fillPyegwangProgress?.status == ChainQuestStatus.active
        ? 'settlement_3_pyegwang_reopen'
        : null;
    final newbieGate = NewbieGateResolver.resolve(
      reputation: userData.reputation,
      ranks: staticData.ranks,
    );
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
      regionEnvironmentTags: _currentRegionEnvironmentTags(
        userData.region,
        staticData,
      ),
      triggeredDiscoveries: _currentTriggeredDiscoveries(userData.region),
      // user.sector → 0-based 변환 (위 generateQuests 호출 정책 참조).
      currentSectorIndex: (userData.sector - 1),
      sectorChanges: ref
          .read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
      currentTrustLevel: _getCurrentTrustLevel(),
      currentChainId: fillChainIdForSpawn,
      currentChainStep: fillPyegwangProgress?.currentStep,
      gate: newbieGate,
    );
    await _repo.addQuests(newQuests);
    _load();
  }

  Future<bool> dispatch(String questId, List<String> mercIds) async {
    final staticData = ref.read(staticDataProvider).value;
    final speedMult = ref.read(speedMultiplierProvider);
    if (staticData == null) return false;

    final quest = state.firstWhere((q) => q.id == questId);
    final questType = staticData.questTypes.firstWhere(
      (t) => t.id == quest.questTypeId,
    );

    // 고정 의뢰 override 적용을 위해 pool 조회
    final pool = staticData.questPools
        .where((p) => p.id == quest.questPoolId)
        .firstOrNull;

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
      isFixedWithDurationOverride:
          pool?.isFixed == true && pool?.durationOverrideSeconds != null,
    );
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < dispatchCost) {
      return false;
    }

    // Deduct dispatch cost
    await ref.read(userDataProvider.notifier).spendGold(dispatchCost);

    final dispatchedMercs = ref
        .read(mercenaryListProvider)
        .where((m) => mercIds.contains(m.id))
        .toList();
    final avgAgi = dispatchedMercs.isEmpty
        ? 50
        : (dispatchedMercs.fold<int>(0, (s, m) => s + m.effectiveAgi) /
                  dispatchedMercs.length)
              .round();
    final duration = QuestCalculator.calculateDispatchDuration(
      baseDuration: questType.baseDuration,
      difficulty: quest.difficulty,
      speedMultiplier: speedMult,
      partyAverageAgi: avgAgi,
      durationOverrideSeconds: pool?.isFixed == true
          ? pool?.durationOverrideSeconds
          : null,
    );

    final endTime = DateTime.now().add(duration);
    await _repo.startQuest(
      questId,
      mercIds,
      endTime,
      dispatchCost: dispatchCost,
    );

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
      if (quest.status == QuestStatus.inProgress &&
          quest.endTime != null &&
          quest.startTime != null) {
        final newEndTime = recalculateEndTime(
          quest.endTime,
          quest.startTime,
          oldSpeed,
          newSpeed,
        );
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
      // 거점 사건(settlement_ prefix) 의뢰는 자동 갱신 주기에서 제외 (REQ-06)
      if (quest.isSettlementStep) continue;
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

    final region = staticData.regions.firstWhere(
      (r) => r.region == userData.region,
    );

    // _checkQuestRefresh의 isSettlementStep continue로 이미 차단되므로 별도 필터 불필요
    for (final quest in expired) {
      await _repo.removeQuest(quest.id);
    }

    if (expired.isEmpty) return;

    final factionRepo = ref.read(factionStateRepositoryProvider);
    final joinedFactionIds = factionRepo.getJoinedFactionIds();
    final factionReputations = factionRepo.getAllReputations();
    final clueLevelsInRegion = factionRepo.getClueLevelsByRegion(
      userData.region,
    );
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final cooldownMap = _loadActiveCooldowns(settingsBox);
    final totalSlotCount = getMaxQuestCount();

    final refreshPyegwangProgress = ref
        .read(chainQuestRepositoryProvider)
        .get('settlement_3_pyegwang_reopen');
    final refreshChainIdForSpawn =
        refreshPyegwangProgress?.status == ChainQuestStatus.active
        ? 'settlement_3_pyegwang_reopen'
        : null;
    final newbieGate = NewbieGateResolver.resolve(
      reputation: userData.reputation,
      ranks: staticData.ranks,
    );
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
      regionEnvironmentTags: _currentRegionEnvironmentTags(
        userData.region,
        staticData,
      ),
      triggeredDiscoveries: _currentTriggeredDiscoveries(userData.region),
      // user.sector → 0-based 변환 (위 generateQuests 호출 정책 참조).
      currentSectorIndex: (userData.sector - 1),
      sectorChanges: ref
          .read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
      currentTrustLevel: _getCurrentTrustLevel(),
      currentChainId: refreshChainIdForSpawn,
      currentChainStep: refreshPyegwangProgress?.currentStep,
      gate: newbieGate,
    );
    await _repo.addQuests(newQuests);
    _load();
  }

  void _checkCompletions() {
    final now = DateTime.now();
    for (final quest in state) {
      if (quest.status == QuestStatus.inProgress && quest.endTime != null) {
        if (now.isAfter(quest.endTime!) &&
            !_completingQuestIds.contains(quest.id)) {
          _completingQuestIds.add(quest.id);
          _completeQuest(
            quest,
          ).whenComplete(() => _completingQuestIds.remove(quest.id));
        }
      }
    }
  }

  Future<void> _completeQuest(ActiveQuest quest) async {
    debugPrint(
      '[BOM][Quest] 퀘스트 완료 처리: "${quest.questName}" (난이도 ${quest.difficulty})',
    );
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final mercs = ref
        .read(mercenaryListProvider)
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
      legendaryEffects.addAll(
        await EquipmentEffectContext.legendariesFor(ref, m.id),
      );
    }

    // 용병단 장비 패시브 효과 수집
    final guildEquipments = await EquipmentEffectContext.guildEquipmentEffects(
      ref,
    );

    // 전설 ④ reward_bonus → PassiveEffect로 변환하여 패시브 경로에 편입
    final personalEquipmentLegendaries = <PassiveEffect>[];
    for (final leg in legendaryEffects) {
      if (leg is LegendaryRewardBonus) {
        personalEquipmentLegendaries.add(
          PassiveEffect.questRewardMultiplier(
            questType: 'all',
            value: leg.multiplier,
          ),
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
      templateEngine: ref.read(templateEngineProvider),
      userData: userData,
      factionStates: ref.read(factionStateRepositoryProvider).getAll(),
      sectorChanges: ref
          .read(regionStateRepositoryProvider)
          .getState(userData.region)
          ?.sectorChanges,
      currentTrustLevel: ref
          .read(regionStateRepositoryProvider)
          .getSettlementTrust(quest.region)
          .level,
    );

    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    await _applyCompletionResult(
      quest,
      result,
      mercs,
      staticData: staticData,
      deathRate: difficulty.deathRate,
    );
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

    if (result.renderedNarrative != null) {
      quest.renderedNarrative = result.renderedNarrative;
      await quest.save();
    }

    final resultText =
        {
          QuestResult.greatSuccess: '대성공',
          QuestResult.success: '성공',
          QuestResult.failure: '실패',
          QuestResult.criticalFailure: '대실패',
        }[result.resultType] ??
        '완료';
    debugPrint(
      '[BOM][Quest] 결과: "$resultText" 순수익 ${result.netReward}G, XP ${result.xpGain}, 명성 ${result.repGain}',
    );
    ref
        .read(activityLogProvider.notifier)
        .addLog(
          '퀘스트 "${quest.questName}" $resultText!${result.renderedNarrative != null ? " — ${result.renderedNarrative}" : ""}',
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
      ref.read(pendingEliteLootProvider.notifier).state = {
        ...currentLoot,
        quest.id: eliteLoot,
      };
    }

    // M5 페이즈 4 #3 — quest_pool_material_drops: 퀘스트 풀에 연결된 재료를 확률 드롭
    final materialDrops = staticData.questPoolMaterialDrops
        .where((d) => d.poolId == quest.questPoolId)
        .toList();
    if (materialDrops.isNotEmpty) {
      final inventory = ref.read(inventoryRepositoryProvider);
      final regionRepo = ref.read(regionStateRepositoryProvider);
      final logger = ref.read(activityLogProvider.notifier);
      final random = Random();
      for (final drop in materialDrops) {
        if (random.nextDouble() >= drop.dropRate) continue;
        final qty = drop.qtyMax > drop.qtyMin
            ? drop.qtyMin + random.nextInt(drop.qtyMax - drop.qtyMin + 1)
            : drop.qtyMin;
        if (inventory.getQuantityForItemId(drop.itemId) >= 999) {
          final itemData = staticData.items
              .where((i) => i.id == drop.itemId)
              .firstOrNull;
          if (itemData == null) continue; // 데이터 불일치 silent skip
          await logger.addLog(
            '${itemData.name} 보유량이 가득 찼습니다 (999 도달)',
            ActivityLogType.inventoryStackCapped,
          );
          continue;
        }
        await inventory.addItem(
          itemId: drop.itemId,
          quantity: qty,
          items: staticData.items,
        );
        await regionRepo.addAcquiredMaterial(quest.region, drop.itemId);
      }
    }

    final mercRepo = ref.read(mercenaryRepositoryProvider);
    for (final damage in result.mercDamages) {
      await mercRepo.setDispatched(damage.mercId, false);
      // 사망 판정 시 정수 소실 로그 기록 (용병 삭제 이전)
      if (damage.newStatus == MercenaryStatus.dead) {
        final deadMerc = mercs.where((m) => m.id == damage.mercId).firstOrNull;
        if (deadMerc != null) {
          final totalPermanent =
              deadMerc.permanentStr +
              deadMerc.permanentIntelligence +
              deadMerc.permanentVit +
              deadMerc.permanentAgi;
          if (totalPermanent > 0) {
            ref
                .read(activityLogProvider.notifier)
                .addLog(
                  '${deadMerc.name}이(가) 사망했다. 투입 정수 누적 +$totalPermanent 소실',
                  ActivityLogType.essenceLostOnDeath,
                );
          }
        }
      }
      if (damage.newStatus != MercenaryStatus.normal) {
        await mercRepo.updateStatus(
          damage.mercId,
          damage.newStatus,
          endTime: damage.recoveryEndTime,
        );
      }
      // 전설 ⑤ 사망 방지 발동 시 쿨다운 기록
      if (damage.legendaryPreventedDeath && damage.newCooldownUntil != null) {
        await mercRepo.setLegendaryCooldown(
          damage.mercId,
          damage.newCooldownUntil,
        );
      }
    }

    for (final merc in mercs) {
      final damage = result.mercDamages.firstWhere((d) => d.mercId == merc.id);
      if (damage.newStatus != MercenaryStatus.dead) {
        await mercRepo.addXpAndCheckLevel(merc.id, result.xpGain);
        final traitLearningBoost =
            merc.traitLearningBoostUntil != null &&
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
          isFailure:
              result.resultType == QuestResult.failure ||
              result.resultType == QuestResult.criticalFailure,
          damageStatus: damage.newStatus,
          traitLearningBoost: traitLearningBoost,
        );
        await mercRepo.updateStats(merc.id, finalStats);

        final staticData = ref.read(staticDataProvider).value;
        if (staticData != null) {
          final passiveEffects = _collectPassiveEffects();
          final acquisitionRelief =
              PassiveBonusService.getTraitAcquisitionRelief(passiveEffects);
          final evolutionRelief = PassiveBonusService.getTraitEvolutionRelief(
            passiveEffects,
          );

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
            final traitData = staticData.traits
                .where((t) => t.key == candidates.first)
                .firstOrNull;
            if (traitData != null) {
              ref
                  .read(activityLogProvider.notifier)
                  .addLog(
                    '${merc.name}이(가) "${traitData.name}" 트레잇을 획득!',
                    ActivityLogType.traitAcquired,
                  );
            }
          }

          // Refresh traitIds after potential acquisition
          final updatedMerc = mercRepo.getAll().firstWhere(
            (m) => m.id == merc.id,
          );
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
          await ref
              .read(userDataProvider.notifier)
              .addReputation(flagResult.extraReputation);
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
      ref
          .read(factionStateRepositoryProvider)
          .addReputation(result.factionTag!, result.factionRepGain);
    }

    // 전용 퀘스트 완료 시 쿨다운 기록
    if (quest.isFactionExclusive) {
      final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
      final cooldowns = _loadActiveCooldowns(settingsBox);
      cooldowns[QuestCompletionSideEffects.factionCooldownKey(quest)] =
          DateTime.now();
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
    if (quest.isChainQuest &&
        quest.chainId != null &&
        quest.chainStep != null) {
      final chainStepData = staticData.chainQuests
          .where((c) => c.chainId == quest.chainId && c.step == quest.chainStep)
          .firstOrNull;
      if (chainStepData != null) {
        final chainQuestService = ref.read(chainQuestServiceProvider);
        final questResultType =
            {
              QuestResult.greatSuccess: 'greatSuccess',
              QuestResult.success: 'success',
              QuestResult.failure: 'failure',
              QuestResult.criticalFailure: 'criticalFailure',
            }[result.resultType] ??
            'failure';

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
          addRewardItems: (itemId, quantity) async {
            final staticData = ref.read(staticDataProvider).valueOrNull;
            if (staticData == null) return;
            final inv = ref.read(inventoryRepositoryProvider);
            final logger = ref.read(activityLogProvider.notifier);
            if (inv.getQuantityForItemId(itemId) >= 999) {
              final itemData = staticData.items
                  .where((i) => i.id == itemId)
                  .firstOrNull;
              if (itemData == null) return; // 데이터 불일치 silent skip
              await logger.addLog(
                '${itemData.name} 보유량이 가득 찼습니다 (999 도달)',
                ActivityLogType.inventoryStackCapped,
              );
              return;
            }
            await inv.addItem(
              itemId: itemId,
              quantity: quantity,
              items: staticData.items,
            );
            await ref
                .read(regionStateRepositoryProvider)
                .addAcquiredMaterial(
                  QuestCompletionSideEffects.materialAcquiredRegion(quest),
                  itemId,
                );
          },
          onChainCompleted: (chainId, finalStep) async {
            final userData = ref.read(userDataProvider);
            if (userData != null &&
                !chainQuestService.canAdvanceToFinal(
                  finalStep: finalStep,
                  user: userData,
                )) {
              ref
                  .read(activityLogProvider.notifier)
                  .addLog(
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
                await ref.read(userDataProvider.notifier).addCompletedChain(id);
              },
              publishCompleted: (event) {
                ref.read(chainCompletedProvider.notifier).state = event;
              },
            );
          },
        );
      }
    }

    // 거점 사건 step 완료 처리 (성공/대성공 한정)
    if (quest.isSettlementStep &&
        (result.resultType == QuestResult.greatSuccess ||
            result.resultType == QuestResult.success)) {
      final pool = staticData.questPools
          .where((p) => p.id == quest.questPoolId)
          .firstOrNull;
      final trustReward = pool?.trustRewardOverride ?? 0;
      if (trustReward > 0) {
        await ref
            .read(regionStateRepositoryProvider)
            .addSettlementTrust(
              regionId: quest.region,
              amount: trustReward,
              source: 'settlement_step_${quest.chainStep}',
              ref: ref,
            );
        ref
            .read(activityLogProvider.notifier)
            .addLog(
              '사건 진행: ${quest.questName} 완료 (${quest.chainStep}/6)',
              ActivityLogType.settlementEventStep,
            );
      }
      // 6단계 완료 시 거점 사건 완료 로그 (M4 MVP 1개 사건 6단계 고정)
      if (quest.chainStep == 6) {
        await ref
            .read(regionStateRepositoryProvider)
            .setEventCompleted(quest.region);
        ref
            .read(activityLogProvider.notifier)
            .addLog(
              '거점 사건 완료: ${quest.questName}',
              ActivityLogType.settlementEventCompleted,
            );
      }
    }

    // 일반 의뢰 신뢰도 점수 (region == 3 + 일반 의뢰 한정)
    if (!quest.isChainQuest &&
        quest.region == 3 &&
        result.settlementTrustGain > 0) {
      await ref
          .read(regionStateRepositoryProvider)
          .addSettlementTrust(
            regionId: quest.region,
            amount: result.settlementTrustGain,
            source: 'quest_d${quest.difficulty}',
            ref: ref,
          );
    }

    ref.read(mercenaryListProvider.notifier).refresh();
    _load();
  }

  List<String> _currentRegionEnvironmentTags(
    int regionId,
    StaticGameData staticData,
  ) {
    final region = staticData.regions
        .where((r) => r.region == regionId)
        .firstOrNull;
    return region?.environmentTags ?? const [];
  }

  Set<String> _currentTriggeredDiscoveries(int regionId) {
    final state = ref.read(regionStateRepositoryProvider).getState(regionId);
    return state?.triggeredDiscoveries.toSet() ?? const {};
  }
}
