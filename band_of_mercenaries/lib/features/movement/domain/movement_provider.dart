import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/movement/data/movement_repository.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_event_service.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';

final movementRepositoryProvider = Provider((ref) => MovementRepository());

final lastTravelEventProvider = StateProvider<TravelEvent?>((ref) => null);

/// Returns true if the given region tier is accessible at the current reputation rank.
final canAccessRegionTierProvider = Provider.family<bool, int>((ref, regionTier) {
  final staticData = ref.watch(staticDataProvider).value;
  final userData = ref.watch(userDataProvider);
  if (staticData == null || userData == null) return false;
  return ReputationService.isRegionAccessible(regionTier, userData.reputation, staticData.ranks);
});

final movementProvider = StateNotifierProvider<MovementNotifier, UserData?>((ref) {
  return MovementNotifier(ref);
});

class MovementNotifier extends StateNotifier<UserData?> {
  final Ref ref;
  late final MovementRepository _repo;

  MovementNotifier(this.ref) : super(null) {
    _repo = ref.read(movementRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (prev, next) => _checkArrival());
  }

  void _load() {
    state = _repo.userData;
  }

  Future<void> startMovement(int targetRegion, int targetSector) async {
    final user = state;
    if (user == null || user.isMoving) return;

    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    // Task 14: Region tier lock based on reputation
    final targetRegionData = staticData.regions.firstWhere(
      (r) => r.region == targetRegion,
      orElse: () => staticData.regions.first,
    );
    if (!ReputationService.isRegionAccessible(
      targetRegionData.regionTier, user.reputation, staticData.ranks,
    )) {
      return;
    }

    final distance = UserData.calculateDistance(
      user.region, user.sector, targetRegion, targetSector,
    );
    final speedMult = ref.read(speedMultiplierProvider);

    // Task 7: Roll for travel event
    final random = Random();
    final currentRegionData = staticData.regions.firstWhere(
      (r) => r.region == user.region,
      orElse: () => staticData.regions.first,
    );
    final travelEvent = TravelEventService.rollEvent(
      distance: distance,
      regionTier: currentRegionData.regionTier,
      events: staticData.travelEvents,
      random: random,
    );

    // Apply delay multiplier for weather events
    double durationMultiplier = 1.0;
    if (travelEvent != null) {
      durationMultiplier = TravelEventService.delayMultiplier(travelEvent);
    }

    // Store event in provider
    ref.read(lastTravelEventProvider.notifier).state = travelEvent;

    final baseDuration = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);
    final adjustedSeconds = (baseDuration.inSeconds * durationMultiplier).round();
    final duration = Duration(seconds: adjustedSeconds);
    final endTime = DateTime.now().add(duration);

    await _repo.startMovement(targetRegion, targetSector, endTime);
    _load();
    // Also update the main user data provider
    ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild
  }

  void recalculateTimers(double oldSpeed, double newSpeed) {
    final user = state;
    if (user == null || !user.isMoving || user.moveEndTime == null) return;
    final now = DateTime.now();
    if (now.isAfter(user.moveEndTime!)) return;
    final remainingMs = user.moveEndTime!.difference(now).inMilliseconds;
    final baseRemainingMs = (remainingMs * oldSpeed).round();
    final newRemainingMs = (baseRemainingMs / newSpeed).round();
    user.moveEndTime = now.add(Duration(milliseconds: newRemainingMs));
    user.save();
    _load();
    ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild
  }

  void _checkArrival() {
    final user = _repo.userData;
    if (user == null || !user.isMoving || user.moveEndTime == null) return;

    if (DateTime.now().isAfter(user.moveEndTime!)) {
      _completeMovement();
    }
  }

  Future<void> _completeMovement() async {
    final travelEvent = ref.read(lastTravelEventProvider);

    await _repo.completeMovement();
    _load();
    ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild

    // Apply travel event effect (non-delay events)
    if (travelEvent != null && travelEvent.effectType != 'delay') {
      await _applyEventEffect(travelEvent);
    }

    // Clear the event
    ref.read(lastTravelEventProvider.notifier).state = null;

    // Generate new quests for the new region
    await ref.read(questListProvider.notifier).generateQuests();
  }

  Future<void> _applyEventEffect(TravelEvent event) async {
    final speedMult = ref.read(speedMultiplierProvider);
    switch (event.effectType) {
      case 'gold':
        final amount = event.magnitude.abs().round();
        if (event.magnitude > 0) {
          await ref.read(userDataProvider.notifier).addGold(amount);
        } else {
          await ref.read(userDataProvider.notifier).spendGold(amount);
        }
      case 'injury':
        final mercs = ref.read(mercenaryListProvider)
            .where((m) => m.isAvailable)
            .toList();
        if (mercs.isNotEmpty) {
          final random = Random();
          final target = mercs[random.nextInt(mercs.length)];
          final recoverySeconds = (10 * 60 / speedMult).round();
          final recoveryTime = DateTime.now().add(Duration(seconds: recoverySeconds));
          await ref.read(mercenaryRepositoryProvider).updateStatus(
            target.id, MercenaryStatus.injured, endTime: recoveryTime,
          );
          ref.read(mercenaryListProvider.notifier).refresh();
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
    }
  }
}
