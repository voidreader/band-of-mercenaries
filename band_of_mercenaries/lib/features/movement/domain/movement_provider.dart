import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/movement/data/movement_repository.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';

final movementRepositoryProvider = Provider((ref) => MovementRepository());

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

    final distance = UserData.calculateDistance(
      user.region, user.sector, targetRegion, targetSector,
    );
    final speedMult = ref.read(speedMultiplierProvider);
    final duration = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);
    final endTime = DateTime.now().add(duration);

    await _repo.startMovement(targetRegion, targetSector, endTime);
    _load();
    // Also update the main user data provider
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
    await _repo.completeMovement();
    _load();
    ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild
    // Generate new quests for the new region
    await ref.read(questListProvider.notifier).generateQuests();
  }
}
