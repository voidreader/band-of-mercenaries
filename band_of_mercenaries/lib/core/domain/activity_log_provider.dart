import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_repository.dart';

final activityLogRepositoryProvider = Provider((ref) => ActivityLogRepository());

final activityLogProvider = StateNotifierProvider<ActivityLogNotifier, List<ActivityLog>>((ref) {
  return ActivityLogNotifier(ref);
});

class ActivityLogNotifier extends StateNotifier<List<ActivityLog>> {
  final Ref ref;
  late final ActivityLogRepository _repo;

  ActivityLogNotifier(this.ref) : super([]) {
    _repo = ref.read(activityLogRepositoryProvider);
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> addLog(String message, ActivityLogType type) async {
    await _repo.addLog(message, type);
    _load();
  }

  void refresh() => _load();
}
