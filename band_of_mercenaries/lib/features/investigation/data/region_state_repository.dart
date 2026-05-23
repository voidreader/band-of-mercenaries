import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/constants/m7_constants.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/region_state_effect.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level_changed_event.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level_changed_provider.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_flag_descriptions.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_version_provider.dart';
import 'package:band_of_mercenaries/features/investigation/domain/trust_level_up_event.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_infrastructure_config.dart';
import 'package:band_of_mercenaries/features/settlement/domain/infrastructure_upgrade_event.dart';
import 'package:band_of_mercenaries/features/settlement/domain/infrastructure_upgrade_provider.dart';

final regionStateRepositoryProvider = Provider(
  (ref) => RegionStateRepository(),
);

class RegionStateRepository {
  Box<RegionState> get _box =>
      Hive.box<RegionState>(HiveInitializer.regionStateBoxName);

  // ─── 신뢰도 단계 임계값 (단계 → 최소 누적 점수) ─────────────────────────
  static const Map<int, int> _trustThresholds = {1: 0, 2: 30, 3: 80, 4: 200};

  // 단계 진입 일회성 보상 (단계 → 보상). 1단계는 초기값이라 보상 없음.
  // 여러 단계를 한 번에 통과할 때 합산하는 이유: amount가 크면 1단계를 건너뛸 수 있으므로
  // 중간 단계 보상을 빠짐없이 지급해야 공정하다.
  static const Map<int, ({int gold, int xp, int rep})> _trustRewards = {
    2: (gold: 100, xp: 50, rep: 0),
    3: (gold: 200, xp: 100, rep: 0),
    4: (gold: 500, xp: 200, rep: 100),
  };

  // 단계별 한국어 명칭
  static const Map<int, String> _trustLevelNames = {
    1: '의심',
    2: '인지',
    3: '친근',
    4: '소속',
  };

  DateTime getLastDecayCheckedAt(int regionId) =>
      getState(regionId)?.lastDangerDecayCheckedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> updateLastDecayCheckedAt(
    int regionId,
    DateTime now, {
    Ref? ref,
  }) async {
    var state = getState(regionId) ?? RegionState(regionId: regionId);
    state.lastDangerDecayCheckedAt = now;
    await saveState(state);
    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger
    if (ref != null && regionId == GameConstants.startingRegionId) {
      ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);
    }
  }

  RegionState? getState(int regionId) {
    try {
      return _box.values.firstWhere((s) => s.regionId == regionId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveState(RegionState state) async {
    final existing = getState(state.regionId);
    if (existing == null) {
      await _box.add(state);
    } else {
      await existing.save();
    }
  }

  // knowledge를 delta만큼 증가시키고 clamp(0, 100), 업데이트된 RegionState 반환
  Future<RegionState> updateKnowledge(
    int regionId,
    int delta, {
    Ref? ref,
  }) async {
    var state = getState(regionId);
    if (state == null) {
      state = RegionState(regionId: regionId);
      await _box.add(state);
    }
    state.knowledge = (state.knowledge + delta).clamp(0, 100);
    await state.save();
    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger
    if (ref != null && regionId == GameConstants.startingRegionId) {
      ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);
    }
    return state;
  }

  Future<void> addTriggeredDiscovery(int regionId, String discoveryId) async {
    final state = getState(regionId);
    if (state == null) return;
    if (!state.triggeredDiscoveries.contains(discoveryId)) {
      state.triggeredDiscoveries.add(discoveryId);
      await state.save();
    }
  }

  /// region별 재료 첫 입수 영속 추적 (M5 페이즈 4 #3 — CraftingService.firstAcquiredItem 영속 평가용)
  Future<void> addAcquiredMaterial(
    int regionId,
    String itemId, {
    Ref? ref,
  }) async {
    var state = getState(regionId);
    if (state == null) {
      state = RegionState(regionId: regionId);
      await _box.add(state);
    }
    if (state.firstAcquiredMaterialIds.contains(itemId)) {
      return; // 멱등 — 이미 추적됨
    }
    state.firstAcquiredMaterialIds.add(itemId);
    await state.save();
    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger
    if (ref != null && regionId == GameConstants.startingRegionId) {
      ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);
    }
  }

  // 섹터 변환을 적용한다. MVP: 리전당 최대 1섹터 변형 제약. 성공 시 true 반환
  Future<bool> applyTransform({
    required int regionId,
    required int sectorIndex,
    required String transformType,
  }) async {
    var state = getState(regionId);
    if (state == null) {
      state = RegionState(regionId: regionId);
      await _box.add(state);
    }

    // MVP: 리전당 최대 1섹터 변형 제약
    if (state.sectorChanges.isNotEmpty) return false;

    final key = sectorIndex.toString();
    if (state.sectorChanges.containsKey(key)) return false;

    state.sectorChanges[key] = transformType;
    await state.save();
    return true;
  }

  // ─── 마을 신뢰도 조회 ──────────────────────────────────────────────────────

  /// 현재 신뢰도 점수와 단계를 반환한다. RegionState가 없으면 초기값 (trust:0, level:1)
  ({int trust, int level}) getSettlementTrust(int regionId) {
    final state = getState(regionId);
    if (state == null) return (trust: 0, level: 1);
    return (trust: state.currentTrust, level: state.currentTrustLevel);
  }

  // ─── 마을 신뢰도 디버그 설정 ───────────────────────────────────────────────

  /// 운영·디버그 전용 직접 설정. 일회성 보상 우회, publish/ActivityLog/XP 부여 없음.
  Future<void> setSettlementTrust(int regionId, int trust, int level) async {
    var state = getState(regionId) ?? RegionState(regionId: regionId);
    state.settlementTrust = trust;
    state.settlementTrustLevel = level;
    await saveState(state);
  }

  Future<void> setEventCompleted(int regionId) async {
    var state = getState(regionId) ?? RegionState(regionId: regionId);
    state.lastEventCompletedAt = DateTime.now();
    await saveState(state);
  }

  // ─── 마을 신뢰도 증가 (핵심 메서드) ──────────────────────────────────────

  /// 신뢰도 점수를 [amount]만큼 증가시킨다.
  ///
  /// 단계 승급 발생 시 통과한 모든 단계의 보상을 합산 지급하고
  /// [settlementTrustLevelUpProvider]에 이벤트를 publish한다.
  Future<({int newTrust, int newLevel, TrustLevelUpEvent? levelUpEvent})>
  addSettlementTrust({
    required int regionId,
    required int amount,
    required String source,
    required Ref ref,
  }) async {
    // amount가 0이면 변경 없음 — addReputation 패턴 모방
    if (amount == 0) {
      final current = getSettlementTrust(regionId);
      return (
        newTrust: current.trust,
        newLevel: current.level,
        levelUpEvent: null,
      );
    }

    var state = getState(regionId) ?? RegionState(regionId: regionId);
    final oldLevel = state.currentTrustLevel;

    state.settlementTrust = (state.currentTrust + amount).clamp(0, 999999);

    // 임계값 표를 순회하여 새 단계 계산 (오름차순 순회로 최고 충족 단계 확정)
    int newLevel = 1;
    for (final entry in _trustThresholds.entries) {
      if (state.settlementTrust! >= entry.value) newLevel = entry.key;
    }
    state.settlementTrustLevel = newLevel;

    await saveState(state);

    TrustLevelUpEvent? event;

    if (newLevel > oldLevel) {
      // 중간 단계를 한 번에 건너뛴 경우를 포함해 통과한 모든 단계 보상 합산
      int rewardGold = 0, rewardXp = 0, rewardRep = 0;
      for (int lv = oldLevel + 1; lv <= newLevel; lv++) {
        final r = _trustRewards[lv];
        if (r == null) continue;
        rewardGold += r.gold;
        rewardXp += r.xp;
        rewardRep += r.rep;
      }

      // 보상 지급
      if (rewardGold > 0) {
        await ref.read(userDataProvider.notifier).addGold(rewardGold);
      }
      if (rewardRep > 0) {
        await ref.read(userDataProvider.notifier).addReputation(rewardRep);
      }
      if (rewardXp > 0) {
        await _grantXpEvenly(ref, rewardXp);
      }

      /// M5 페이즈 4 #3 — 신뢰도 단계 진입 일회성 재료 보너스
      if (regionId == GameConstants.startingRegionId) {
        final staticData = ref.read(staticDataProvider).valueOrNull;
        if (staticData != null) {
          final inv = ref.read(inventoryRepositoryProvider);
          final logger = ref.read(activityLogProvider.notifier);
          // 2단계 진입: 빛바랜 천 조각 ×1
          if (newLevel >= 2 && oldLevel < 2) {
            const itemId = 'mat_hide_faded_cloth';
            if (inv.getQuantityForItemId(itemId) >= 999) {
              final itemData = staticData.items.firstWhereOrNull(
                (i) => i.id == itemId,
              );
              if (itemData != null) {
                await logger.addLog(
                  '${itemData.name} 보유량이 가득 찼습니다 (999 도달)',
                  ActivityLogType.inventoryStackCapped,
                );
              }
            } else {
              await inv.addItem(
                itemId: itemId,
                quantity: 1,
                items: staticData.items,
              );
              await addAcquiredMaterial(regionId, itemId);
            }
          }
          // 3단계 진입: 녹슨 쇳조각 ×3
          if (newLevel >= 3 && oldLevel < 3) {
            const itemId = 'mat_ore_rusty_scrap';
            if (inv.getQuantityForItemId(itemId) >= 999) {
              final itemData = staticData.items.firstWhereOrNull(
                (i) => i.id == itemId,
              );
              if (itemData != null) {
                await logger.addLog(
                  '${itemData.name} 보유량이 가득 찼습니다 (999 도달)',
                  ActivityLogType.inventoryStackCapped,
                );
              }
            } else {
              await inv.addItem(
                itemId: itemId,
                quantity: 3,
                items: staticData.items,
              );
              await addAcquiredMaterial(regionId, itemId);
            }
          }
        }
      }

      // 거점명 동적 조회 — 미발견 시 '시작 거점' fallback
      final regionStaticData = ref.read(staticDataProvider).valueOrNull;
      final settlementName =
          regionStaticData?.regions
              .where((r) => r.region == regionId)
              .map((r) => r.regionName)
              .firstOrNull ??
          '시작 거점';

      ref
          .read(activityLogProvider.notifier)
          .addLog(
            '마을 신뢰도가 $newLevel단계(${_trustLevelNames[newLevel]})에 도달했다',
            ActivityLogType.settlementTrustUp,
          );

      event = TrustLevelUpEvent(
        regionId: regionId,
        fromLevel: oldLevel,
        toLevel: newLevel,
        settlementName: settlementName,
        rewardGold: rewardGold > 0 ? rewardGold : null,
        rewardXp: rewardXp > 0 ? rewardXp : null,
        rewardReputation: rewardRep > 0 ? rewardRep : null,
      );

      // 신뢰도 단계 승급 이벤트 발행
      ref.read(settlementTrustLevelUpProvider.notifier).state = event;

      // [FR-6] 거점 신뢰도 4단계(소속) 진입 시 위업 발급
      if (newLevel == 4) {
        try {
          await ref
              .read(achievementServiceProvider)
              .grant(
                'settlement_trust_belonging:region_$regionId',
                regionId: regionId,
                payload: {'oldLevel': oldLevel, 'newLevel': newLevel},
              );
        } on Exception catch (e) {
          debugPrint(
            '[BOM][Achievement] settlement_trust_belonging grant 실패: $e',
          );
        }
      }

      // 단계 승급 후 퀘스트 풀 갱신 (min_trust_level 조건 재평가)
      await ref.read(questListProvider.notifier).refreshAvailableQuests();
    }

    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger
    if (regionId == GameConstants.startingRegionId) {
      ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);
    }

    return (
      newTrust: state.settlementTrust!,
      newLevel: newLevel,
      levelUpEvent: event,
    );
  }

  // ─── M7 페이즈 4 #1 — 위험도·플래그 ────────────────────────────────────────

  /// RegionState가 없으면 신규 생성 후 box.add. 있으면 기존 반환.
  ///
  /// 호출자가 mutation 후 [saveState] 또는 `state.save()` 호출 책임을 가진다.
  /// (addSettlementTrust 라인 157 패턴 답습)
  RegionState getOrCreateRegionState(int regionId) {
    return getState(regionId) ?? RegionState(regionId: regionId);
  }

  /// 위험도 점수를 [delta]만큼 증감시킨다. clamp(-100, +100).
  ///
  /// 단계 전이 발생 시:
  /// - ActivityLog `regionDangerLevelChanged` 기록
  /// - 첫 peaceful 진입(음수 진입) 시 `region_pacified:region_$regionId` 위업 발급 (fail-soft)
  /// - isBigTransition인 경우 [dangerLevelChangedProvider] publish
  /// - 퀘스트 풀 갱신 ([refreshAvailableQuests])
  Future<({int newScore, int newLevel, DangerLevelChangedEvent? event})>
  addDangerScore({
    required int regionId,
    required int delta,
    required String source,
    required Ref ref,
  }) async {
    if (delta == 0) {
      final s = getState(regionId);
      final score = s?.currentDangerScore ?? 0;
      final level = s?.currentDangerLevel ?? 2;
      return (newScore: score, newLevel: level, event: null);
    }

    var state = getState(regionId) ?? RegionState(regionId: regionId);
    final oldScore = state.currentDangerScore;
    final oldLevelInt = state.currentDangerLevel;
    final oldLevel =
        DangerLevelResolver.fromCacheInt(oldLevelInt) ?? DangerLevel.peaceful;

    final newScore = (oldScore + delta).clamp(-100, 100);
    state.dangerScore = newScore;
    final newLevel = DangerLevelResolver.resolveLevel(newScore);
    state.dangerLevel = newLevel.cacheInt;
    await saveState(state);

    DangerLevelChangedEvent? event;

    if (newLevel != oldLevel) {
      final staticData = ref.read(staticDataProvider).valueOrNull;
      final regionName =
          staticData?.regions
              .where((r) => r.region == regionId)
              .map((r) => r.regionName)
              .firstOrNull ??
          '지역 $regionId';

      final isBig = DangerLevelChangedEvent.computeIsBigTransition(
        oldLevel,
        newLevel,
      );

      await ref
          .read(activityLogProvider.notifier)
          .addLog(
            '$regionName 상태가 ${oldLevel.koreanLabel} → ${newLevel.koreanLabel}(으)로 변화했다',
            ActivityLogType.regionDangerLevelChanged,
          );

      // [FR] 첫 peaceful 진입 (음수 진입) 시 위업 발급 — fail-soft
      List<String> grantedAchievements = [];
      if (newScore < 0 && oldScore >= 0) {
        try {
          await ref
              .read(achievementServiceProvider)
              .grant(
                'region_pacified:region_$regionId',
                regionId: regionId,
                payload: {'oldScore': oldScore, 'newScore': newScore},
              );
          grantedAchievements = ['region_pacified:region_$regionId'];
        } on Exception catch (e) {
          debugPrint('[M7][Achievement] region_pacified grant 실패: $e');
        }
      }

      event = DangerLevelChangedEvent(
        regionId: regionId,
        regionName: regionName,
        from: oldLevel,
        to: newLevel,
        grantedAchievements: grantedAchievements,
        isBigTransition: isBig,
      );

      if (isBig) {
        ref.read(dangerLevelChangedProvider.notifier).state = event;
      }

      // region_state_required·excluded 재평가
      await ref.read(questListProvider.notifier).refreshAvailableQuests();
    }

    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger
    if (regionId == GameConstants.startingRegionId) {
      ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);
    }

    return (newScore: newScore, newLevel: newLevel.cacheInt, event: event);
  }

  /// 영속 플래그를 멱등 추가한다. 신규 토글이면 true, 이미 있으면 false 반환.
  ///
  /// ActivityLog `regionUnlockedFlagToggled` 기록.
  /// fail-soft trailing: 페이즈 4 #4 인프라 단계 전이 평가 (TASK-13에서 본체 활성화).
  Future<bool> toggleFlag({
    required int regionId,
    required String flag,
    required Ref ref,
  }) async {
    var state = getState(regionId) ?? RegionState(regionId: regionId);
    if (state.unlockedFlags.contains(flag)) return false;

    state.unlockedFlags.add(flag);
    await saveState(state);

    final staticData = ref.read(staticDataProvider).valueOrNull;
    final regionName =
        staticData?.regions
            .where((r) => r.region == regionId)
            .map((r) => r.regionName)
            .firstOrNull ??
        '지역 $regionId';
    final flagDesc = regionStateFlagDescriptions[flag] ?? flag;

    await ref
        .read(activityLogProvider.notifier)
        .addLog(
          '$regionName에서 변화가 일어났다: $flagDesc',
          ActivityLogType.regionUnlockedFlagToggled,
        );

    // M7 페이즈 4 #4 인프라 전이 평가 trailing (fail-soft)
    try {
      final event = await _evaluateInfrastructureTransition(ref: ref);
      if (event != null) {
        ref.read(settlementInfrastructureUpgradedProvider.notifier).state =
            event;
      }
    } on Exception catch (e) {
      debugPrint('[M7][Infrastructure] transition 평가 실패: $e');
    }

    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger
    if (regionId == GameConstants.startingRegionId) {
      ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);
    }

    return true;
  }

  /// 영속 플래그 보유 여부 (동기 조회).
  bool hasFlag(int regionId, String flag) {
    final state = getState(regionId);
    return state?.unlockedFlags.contains(flag) ?? false;
  }

  /// M7 페이즈 4 #2 — quest 완료 시 region_state_effect 적용.
  ///
  /// [CumulativeEffect]: 의뢰 완료 횟수를 [questPoolCompletionCounts]에 누적하며
  /// [deltaPerCompletion]만큼 위험도를 누적한다. 누적량이 [capPerThreshold]
  /// (음수 = 위험도 감소 폭)에 도달하면 [thresholdFlag]를 토글하고 -10 bonus 적용.
  /// 이후 카운터는 계속 누적되지만 추가 위험도 감소는 없다.
  ///
  /// [OneshotEffect]: 플래그 보유 여부 확인 후, 신규 토글이면 [delta]만큼 위험도 변화.
  Future<void> applyDangerScoreFromQuest({
    required int regionId,
    required QuestPool pool,
    required Ref ref,
  }) async {
    final effect = pool.regionStateEffect;
    if (effect == null) return;

    switch (effect) {
      case CumulativeEffect():
        var state = getState(regionId) ?? RegionState(regionId: regionId);
        // 이미 cap 도달 — 카운터 증가만 (saveState로 persist)
        if (state.unlockedFlags.contains(effect.thresholdFlag)) {
          state.questPoolCompletionCounts[pool.id] =
              (state.questPoolCompletionCounts[pool.id] ?? 0) + 1;
          await saveState(state);
          return;
        }
        // 카운터 +1
        final newCount = (state.questPoolCompletionCounts[pool.id] ?? 0) + 1;
        state.questPoolCompletionCounts[pool.id] = newCount;
        await saveState(state);

        // delta 적용 (위험도 갱신은 addDangerScore가 자체 saveState 수행)
        await addDangerScore(
          regionId: regionId,
          delta: effect.deltaPerCompletion,
          source: 'cumulative_${pool.id}',
          ref: ref,
        );

        // cap 도달 검증 — capPerThreshold는 음수 (위험도 감소 폭)
        final cumulativeDelta = newCount * effect.deltaPerCompletion;
        if (cumulativeDelta <= effect.capPerThreshold) {
          final toggled = await toggleFlag(
            regionId: regionId,
            flag: effect.thresholdFlag,
            ref: ref,
          );
          if (toggled) {
            await addDangerScore(
              regionId: regionId,
              delta: -10,
              source: 'cumulative_cap_bonus',
              ref: ref,
            );
          }
        }
        break;
      case OneshotEffect():
        if (hasFlag(regionId, effect.flag)) return;
        await toggleFlag(regionId: regionId, flag: effect.flag, ref: ref);
        await addDangerScore(
          regionId: regionId,
          delta: effect.delta,
          source: 'oneshot_${pool.id}',
          ref: ref,
        );
        break;
    }
  }

  /// M7 페이즈 4 #4 — toggleFlag trailing에서 호출. **region 3(GameConstants.startingRegionId) 한정** 인프라 단계 전이 평가.
  /// 7리전 어디서 flag가 토글되더라도 본 메서드는 region 3 인프라 단계만 재평가하며, 결과 단계 변경 시 InfrastructureUpgradeEvent를 반환한다.
  /// fail-soft. event 반환 (이벤트 publish는 호출자 책임).
  Future<InfrastructureUpgradeEvent?> _evaluateInfrastructureTransition({
    required Ref ref,
  }) async {
    final r3State =
        getState(GameConstants.startingRegionId) ??
        RegionState(regionId: GameConstants.startingRegionId);
    final currentTier = r3State.currentInfrastructureTier;

    // 7리전 unlockedFlags 합산 (8 flag 한정)
    int flagCount = 0;
    for (final regionId in M7Constants.livingsphereRegions) {
      final state = getState(regionId);
      if (state == null) continue;
      for (final flag in state.unlockedFlags) {
        if (SettlementInfrastructureConfig.infrastructureRelevantFlags.contains(
          flag,
        )) {
          flagCount++;
        }
      }
    }

    final nextTier = SettlementInfrastructureConfig.resolveTier(flagCount);
    if (nextTier <= currentTier) return null;

    // 단계 갱신
    r3State.infrastructureTier = nextTier;
    await saveState(r3State);

    // 통과한 모든 Tier 보상 합산
    int rewardGold = 0, rewardXp = 0, rewardRep = 0;
    for (int tier = currentTier + 1; tier <= nextTier; tier++) {
      final r = SettlementInfrastructureConfig.infraTierRewards[tier];
      if (r == null) continue;
      rewardGold += r.gold;
      rewardXp += r.xp;
      rewardRep += r.rep;
    }
    if (rewardGold > 0) {
      await ref.read(userDataProvider.notifier).addGold(rewardGold);
    }
    if (rewardRep > 0) {
      await ref.read(userDataProvider.notifier).addReputation(rewardRep);
    }
    if (rewardXp > 0) {
      await _grantXpEvenly(ref, rewardXp);
    }

    // ActivityLog
    final tierName =
        SettlementInfrastructureConfig.infraTierNames[nextTier] ?? '';
    ref
        .read(activityLogProvider.notifier)
        .addLog(
          '더스트빌이 [$nextTier단계: $tierName] 단계로 발전했다',
          ActivityLogType.settlementInfrastructureUpgraded,
        );

    // 위업 hook — Tier 4 진입 시 '변방의 영주'
    List<String> grantedAchievements = const [];
    if (nextTier == 4) {
      try {
        await ref
            .read(achievementServiceProvider)
            .grant(
              'infrastructure_tier:tier_4',
              regionId: GameConstants.startingRegionId,
              payload: {
                'fromTier': currentTier,
                'toTier': nextTier,
                'flagCount': flagCount,
              },
            );
        grantedAchievements = ['infrastructure_tier:tier_4'];
      } on Exception catch (e) {
        debugPrint('[M7][Achievement] infrastructure_tier grant 실패: $e');
      }
    }

    // 퀘스트 풀 갱신
    await ref.read(questListProvider.notifier).refreshAvailableQuests();

    // M8.5 페이즈 4 #1 — 대시보드 invalidation trigger (region 3 인프라 변경)
    ref.read(region3StateVersionProvider.notifier).update((s) => s + 1);

    return InfrastructureUpgradeEvent(
      fromTier: currentTier,
      toTier: nextTier,
      rewardGold: rewardGold > 0 ? rewardGold : null,
      rewardXp: rewardXp > 0 ? rewardXp : null,
      rewardReputation: rewardRep > 0 ? rewardRep : null,
      grantedAchievements: grantedAchievements,
    );
  }

  // ─── 내부 헬퍼 ────────────────────────────────────────────────────────────

  /// 살아있는 용병 전원에게 XP를 균등 분배한다.
  /// 정수 나눗셈 잔여분은 0번째 용병에게 가산.
  Future<void> _grantXpEvenly(Ref ref, int totalXp) async {
    final mercRepo = ref.read(mercenaryRepositoryProvider);
    final aliveList = mercRepo
        .getAll()
        .where((m) => m.status != MercenaryStatus.dead)
        .toList();
    if (aliveList.isEmpty) return;
    final per = totalXp ~/ aliveList.length;
    final remainder = totalXp - (per * aliveList.length);
    for (int i = 0; i < aliveList.length; i++) {
      final xp = per + (i == 0 ? remainder : 0);
      if (xp > 0) {
        await mercRepo.addXpAndCheckLevel(aliveList[i].id, xp);
      }
    }
  }
}
