import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/movement/data/movement_repository.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_state.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_event_service.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_acquisition_service.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_choice_service.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_choice_recall_provider.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_result_data.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';

final movementRepositoryProvider = Provider((ref) => MovementRepository());

final lastTravelEventProvider = StateProvider<TravelEvent?>((ref) => null);

class TravelEventTraitResult {
  final String mercenaryId;
  final String traitKey;
  const TravelEventTraitResult({required this.mercenaryId, required this.traitKey});
}

final lastTravelEventTraitResultProvider = StateProvider<TravelEventTraitResult?>((ref) => null);

/// Returns true if the given region tier is accessible at the current reputation rank.
final canAccessRegionTierProvider = Provider.family<bool, int>((ref, regionTier) {
  final staticData = ref.watch(staticDataProvider).value;
  final userData = ref.watch(userDataProvider);
  if (staticData == null || userData == null) return false;
  return ReputationService.isRegionAccessible(regionTier, userData.reputation, staticData.ranks);
});

final movementProvider = StateNotifierProvider<MovementNotifier, MovementState?>((ref) {
  return MovementNotifier(ref);
});

class MovementNotifier extends StateNotifier<MovementState?> {
  final Ref ref;
  late final MovementRepository _repo;
  bool _isCompletingMovement = false;

  MovementNotifier(this.ref) : super(null) {
    _repo = ref.read(movementRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (prev, next) => _checkArrival());
  }

  void _load() {
    final user = _repo.userData;
    if (user == null) {
      state = null;
      return;
    }
    state = MovementState(
      isMoving: user.isMoving,
      moveTargetRegion: user.moveTargetRegion,
      moveTargetSector: user.moveTargetSector,
      moveEndTime: user.moveEndTime,
      currentRegion: user.region,
      currentSector: user.sector,
    );
  }

  Future<void> startMovement(int targetRegion, int targetSector) async {
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.isMoving) return;
    if (userData.investigatingMercId != null) return;

    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final targetRegionData = staticData.regions.firstWhere(
      (r) => r.region == targetRegion,
      orElse: () => staticData.regions.first,
    );
    if (!ReputationService.isRegionAccessible(
      targetRegionData.regionTier, userData.reputation, staticData.ranks,
    )) {
      return;
    }

    final distance = UserData.calculateDistance(
      userData.region, userData.sector, targetRegion, targetSector,
    );
    final speedMult = ref.read(speedMultiplierProvider);

    final random = Random();
    final currentRegionData = staticData.regions.firstWhere(
      (r) => r.region == userData.region,
      orElse: () => staticData.regions.first,
    );
    TravelEvent? travelEvent = TravelEventService.rollEvent(
      distance: distance,
      regionTier: currentRegionData.regionTier,
      events: staticData.travelEvents,
      random: random,
    );

    // 선택지 이벤트 롤 (자동 이벤트와 독립)
    final rosterIdle = ref.read(mercenaryListProvider)
        .where((m) => m.isAvailable)
        .toList();
    final choiceEvent = TravelChoiceService.rollChoiceEvent(
      distance: distance,
      regionTier: currentRegionData.regionTier,
      rosterIdle: rosterIdle,
      events: staticData.travelChoiceEvents,
      random: random,
    );
    if (choiceEvent != null) {
      await _repo.setChoiceEventId(choiceEvent.id);
    }

    if (travelEvent != null && travelEvent.effectType == 'trait_innate') {
      final mercs = ref.read(mercenaryListProvider);
      var valid = _isTraitInnateEventValid(travelEvent, mercs, staticData.traits, staticData.traitConflicts);
      if (!valid) {
        final filtered = TravelEventService.filterByTier(staticData.travelEvents, currentRegionData.regionTier)
            .where((e) => e.id != travelEvent!.id).toList();
        travelEvent = null;
        for (var i = 0; i < 3 && filtered.isNotEmpty; i++) {
          final rerolled = filtered[random.nextInt(filtered.length)];
          if (rerolled.effectType == 'trait_innate') {
            if (_isTraitInnateEventValid(rerolled, mercs, staticData.traits, staticData.traitConflicts)) {
              travelEvent = rerolled;
              break;
            } else {
              filtered.remove(rerolled);
            }
          } else {
            travelEvent = rerolled;
            break;
          }
        }
      }
    }

    double durationMultiplier = 1.0;
    if (travelEvent != null) {
      durationMultiplier = TravelEventService.delayMultiplier(travelEvent);
    }

    ref.read(lastTravelEventProvider.notifier).state = travelEvent;

    double travelReduction = 0.0;
    final transportFacility = staticData.facilities.where((f) => f.id == 'transport').firstOrNull;
    if (transportFacility != null) {
      final transportLevel = userData.facilities['transport'] ?? 0;
      travelReduction = ConstructionService.getEffectValue(transportFacility, transportLevel);
    }

    final baseDuration = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);
    final adjustedSeconds = (baseDuration.inSeconds * durationMultiplier * (1.0 - travelReduction)).round();
    final duration = Duration(seconds: adjustedSeconds);
    final endTime = DateTime.now().add(duration);

    await _repo.startMovement(targetRegion, targetSector, endTime);
    _load();
    ref.read(userDataProvider.notifier).refresh();
  }

  void recalculateTimers(double oldSpeed, double newSpeed) {
    final user = _repo.userData;
    if (user == null || !user.isMoving || user.moveEndTime == null) return;
    final newEndTime = recalculateEndTime(user.moveEndTime, user.moveEndTime, oldSpeed, newSpeed);
    if (newEndTime != user.moveEndTime) {
      user.moveEndTime = newEndTime;
      user.save();
      _load();
      ref.read(userDataProvider.notifier).refresh();
    }
  }

  void _checkArrival() {
    final user = _repo.userData;
    if (user == null || !user.isMoving || user.moveEndTime == null) return;
    if (_isCompletingMovement) return;

    if (DateTime.now().isAfter(user.moveEndTime!)) {
      _isCompletingMovement = true;
      _completeMovement().whenComplete(() => _isCompletingMovement = false);
    }
  }

  Future<void> _completeMovement() async {
    final travelEvent = ref.read(lastTravelEventProvider);

    await _repo.completeMovement();
    _load();
    ref.read(userDataProvider.notifier).refresh();

    ref.read(activityLogProvider.notifier).addLog(
      '이동 완료',
      ActivityLogType.movementComplete,
    );

    ref.read(lastTravelEventTraitResultProvider.notifier).state = null;

    if (travelEvent != null && travelEvent.effectType != 'delay') {
      await _applyEventEffect(travelEvent);
    }

    ref.read(lastTravelEventProvider.notifier).state = null;

    await ref.read(questListProvider.notifier).generateQuests();

    await _triggerChoiceRecall();
  }

  Future<void> _triggerChoiceRecall() async {
    final eventId = _repo.choiceEventId;
    if (eventId == null) return;

    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final event = staticData.travelChoiceEvents
        .where((e) => e.id == eventId)
        .firstOrNull;
    if (event == null) {
      await _repo.setChoiceEventId(null);
      return;
    }

    // 중복 방지 — publish 전에 클리어
    await _repo.setChoiceEventId(null);

    final userData = ref.read(userDataProvider);
    if (userData == null) return;

    final rosterIdle = ref.read(mercenaryListProvider)
        .where((m) => m.isAvailable)
        .toList();

    if (rosterIdle.isEmpty) return;

    final protagonist = TravelChoiceService.selectProtagonist(
      rosterIdle: rosterIdle,
      preferredTraitsCsv: event.preferredTraits,
      traits: staticData.traits,
    );

    final engine = ref.read(templateEngineProvider);

    final teamCtx = TemplateContext(
      user: userData,
      merc: protagonist,
      rosterForTeam: rosterIdle,
      evaluationScope: EvaluationScope.team,
    );

    final allOptions = staticData.travelChoiceOptions
        .where((o) => o.eventId == event.id)
        .toList();

    final visibleOptions = TravelChoiceService.filterVisibleOptions(
      options: allOptions,
      engine: engine,
      teamContext: teamCtx,
    );

    if (visibleOptions.isEmpty) return;

    final hiddenOptions = visibleOptions
        .where((o) => o.riskLevel == 'hidden')
        .toList();
    final nonHiddenVisible = visibleOptions
        .where((o) => o.riskLevel != 'hidden')
        .toList();

    final renderedSituation = engine.render(event.situation, teamCtx);

    ref.read(pendingTravelChoiceProvider.notifier).state = TravelChoiceRecallData(
      event: event,
      visibleOptions: nonHiddenVisible,
      hiddenOptions: hiddenOptions,
      protagonist: protagonist,
      renderedSituation: renderedSituation,
    );
  }

  Future<void> _applyEventEffect(TravelEvent event) async {
    final speedMult = ref.read(speedMultiplierProvider);
    final userData = ref.read(userDataProvider);
    final staticData = ref.read(staticDataProvider).value;

    double damageReduction = 0.0;
    if (userData != null && staticData != null) {
      final defenseFacility = staticData.facilities.where((f) => f.id == 'defense').firstOrNull;
      if (defenseFacility != null) {
        final defenseLevel = userData.facilities['defense'] ?? 0;
        damageReduction = ConstructionService.getEffectValue(defenseFacility, defenseLevel);
      }
    }

    // 세력 패시브 effects 수집
    CollectedEffects passiveEffects = const CollectedEffects.empty();
    if (userData != null && staticData != null) {
      final joinedIds = ref.read(factionStateRepositoryProvider).getJoinedFactionIds();
      final joinedFactions = staticData.factions.where((f) => joinedIds.contains(f.id)).toList();
      passiveEffects = PassiveBonusService.collect(
        reputation: userData.reputation,
        allRanks: staticData.ranks,
        joinedFactions: joinedFactions,
      );
    }

    switch (event.effectType) {
      case 'gold':
        if (event.magnitude > 0) {
          await ref.read(userDataProvider.notifier).addGold(event.magnitude.abs().round());
        } else {
          // gold_loss 이벤트: passive mitigation 적용
          final goldLossMitigation = PassiveBonusService.getTravelEventMitigation(passiveEffects, 'gold_loss');
          final reducedMagnitude = TravelEventService.applyGoldLossMitigation(event.magnitude.abs().round(), goldLossMitigation);
          await ref.read(userDataProvider.notifier).spendGold(reducedMagnitude);
        }
      case 'injury':
        final mercs = ref.read(mercenaryListProvider)
            .where((m) => m.isAvailable)
            .toList();
        if (mercs.isNotEmpty) {
          final random = Random();
          // damage 이벤트: 시설 기반 감소 + passive mitigation 가산 (0~0.95 clamp)
          final damageMitigation = PassiveBonusService.getTravelEventMitigation(passiveEffects, 'damage');
          final totalDamageReduction = (damageReduction + damageMitigation).clamp(0.0, 0.95);
          if (random.nextDouble() >= totalDamageReduction) {
            final target = mercs[random.nextInt(mercs.length)];
            final recoverySeconds = (10 * 60 / speedMult).round();
            final recoveryTime = DateTime.now().add(Duration(seconds: recoverySeconds));
            await ref.read(mercenaryRepositoryProvider).updateStatus(
              target.id, MercenaryStatus.injured, endTime: recoveryTime,
            );
            ref.read(mercenaryListProvider.notifier).refresh();
          }
        }
      case 'heal_tired':
        final mercs = ref.read(mercenaryListProvider)
            .where((m) => m.status == MercenaryStatus.tired)
            .toList();
        if (mercs.isNotEmpty) {
          await ref.read(mercenaryRepositoryProvider).updateStatus(
            mercs.first.id, MercenaryStatus.normal,
          );
          ref.read(mercenaryListProvider.notifier).refresh();
        }
      case 'reputation':
        final amount = event.magnitude.abs().round();
        await ref.read(userDataProvider.notifier).addReputation(amount);
      case 'trait_innate':
        final staticData = ref.read(staticDataProvider).value;
        if (staticData == null) return;
        final category = event.targetCategory;
        if (category == null) return;
        final mercs = ref.read(mercenaryListProvider);
        final allTraits = staticData.traits;
        final conflicts = staticData.traitConflicts;
        final candidates = mercs.where((m) {
          if (m.status == MercenaryStatus.dead) return false;
          final hasCategory = m.allTraitIds.any((tid) {
            final t = allTraits.where((t) => t.key == tid).firstOrNull;
            return t != null && t.categoryKey == category && t.type == 'innate';
          });
          return !hasCategory;
        }).toList();
        if (candidates.isEmpty) return;
        final random = Random();
        final targetMerc = candidates[random.nextInt(candidates.length)];
        final innateTraits = allTraits.where((t) =>
          t.type == 'innate' && t.categoryKey == category &&
          !targetMerc.allTraitIds.contains(t.key) &&
          !TraitAcquisitionService.hasConflict(t.key, targetMerc.allTraitIds, conflicts)
        ).toList();
        if (innateTraits.isEmpty) return;
        final selectedTrait = innateTraits[random.nextInt(innateTraits.length)];
        await ref.read(mercenaryRepositoryProvider).addTrait(targetMerc.id, selectedTrait.key);
        ref.read(mercenaryListProvider.notifier).refresh();
        ref.read(activityLogProvider.notifier).addLog(
          '${targetMerc.name}가 여행 중 [${selectedTrait.name}] 선천 트레잇을 획득했다',
          ActivityLogType.traitAcquired,
        );
        ref.read(lastTravelEventTraitResultProvider.notifier).state = TravelEventTraitResult(
          mercenaryId: targetMerc.id,
          traitKey: selectedTrait.key,
        );
    }
  }

  /// view 계층이 data 계층을 직접 접근하지 않도록 선택지 이벤트 효과 적용을 위임받는 메서드.
  Future<void> applyTravelChoiceEffect(
    TravelChoiceResultData result,
    Mercenary protagonist,
  ) async {
    final speedMult = ref.read(speedMultiplierProvider);

    switch (result.effectType) {
      case 'gold':
        if (result.effectMagnitude >= 0) {
          await ref.read(userDataProvider.notifier).addGold(result.effectMagnitude.toInt());
        } else {
          await ref.read(userDataProvider.notifier).spendGold(result.effectMagnitude.abs().toInt());
        }
      case 'reputation':
        await ref.read(userDataProvider.notifier).addReputation(result.effectMagnitude.toInt());
      case 'injury':
        final recoverySeconds = (10 * 60 / speedMult).round();
        final recoveryTime = DateTime.now().add(Duration(seconds: recoverySeconds));
        await ref.read(mercenaryRepositoryProvider).updateStatus(
          protagonist.id, MercenaryStatus.injured, endTime: recoveryTime,
        );
        ref.read(mercenaryListProvider.notifier).refresh();
      case 'heal_tired':
        if (result.effectMagnitude > 0) {
          await ref.read(mercenaryRepositoryProvider).updateStatus(
            protagonist.id, MercenaryStatus.normal,
          );
        } else {
          await ref.read(mercenaryRepositoryProvider).updateStatus(
            protagonist.id, MercenaryStatus.tired,
            endTime: DateTime.now().add(const Duration(minutes: 5)),
          );
        }
        ref.read(mercenaryListProvider.notifier).refresh();
      case 'trait_innate':
        await _applyTravelTraitInnate(protagonist, result.effectTarget);
      case 'trait_acquired':
        final boostUntil = DateTime.now()
            .add(TravelChoiceService.traitLearningBoostDuration);
        await ref.read(mercenaryRepositoryProvider).setTraitLearningBoost(
          protagonist.id, boostUntil,
        );
        ref.read(mercenaryListProvider.notifier).refresh();
      case 'item':
        final itemId = result.effectTarget;
        if (itemId != null) {
          final staticData = ref.read(staticDataProvider).value;
          if (staticData != null) {
            await ref.read(inventoryRepositoryProvider).addItem(
              itemId: itemId,
              quantity: result.effectMagnitude.toInt().clamp(1, 99),
              items: staticData.items,
            );
          }
        }
      case 'nothing':
      default:
        break;
    }
  }

  /// protagonist의 빈 선천 슬롯(innateCount < 3)에만 트레잇을 부여하는 helper.
  /// effectTarget이 null이면 skip.
  Future<void> _applyTravelTraitInnate(
    Mercenary protagonist,
    String? effectTarget,
  ) async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;
    if (effectTarget == null) return;

    final allTraits = staticData.traits;
    final conflicts = staticData.traitConflicts;

    final innateCount = protagonist.allTraitIds.where((id) {
      final t = allTraits.where((t) => t.key == id).firstOrNull;
      return t != null && t.type == 'innate';
    }).length;
    if (innateCount >= 3) return;

    final candidates = allTraits
        .where((t) =>
            t.key == effectTarget &&
            t.type == 'innate' &&
            !protagonist.allTraitIds.contains(t.key) &&
            !TraitAcquisitionService.hasConflict(
                t.key, protagonist.allTraitIds, conflicts))
        .toList();

    if (candidates.isEmpty) return;

    final selected = candidates[Random().nextInt(candidates.length)];
    await ref.read(mercenaryRepositoryProvider).addTrait(
      protagonist.id, selected.key,
    );
    ref.read(mercenaryListProvider.notifier).refresh();
  }

  bool _isTraitInnateEventValid(
    TravelEvent event,
    List<Mercenary> mercs,
    List<TraitData> allTraits,
    List<TraitConflict> conflicts,
  ) {
    final category = event.targetCategory;
    if (category == null) return false;
    final candidates = mercs.where((m) {
      if (m.status == MercenaryStatus.dead) return false;
      final hasCategory = m.allTraitIds.any((tid) {
        final t = allTraits.where((t) => t.key == tid).firstOrNull;
        return t != null && t.categoryKey == category && t.type == 'innate';
      });
      return !hasCategory;
    }).toList();
    if (candidates.isEmpty) return false;
    final innateTraits = allTraits.where((t) => t.type == 'innate' && t.categoryKey == category).toList();
    for (final merc in candidates) {
      final available = innateTraits.where((t) =>
        !merc.allTraitIds.contains(t.key) &&
        !TraitAcquisitionService.hasConflict(t.key, merc.allTraitIds, conflicts)
      );
      if (available.isNotEmpty) return true;
    }
    return false;
  }
}
