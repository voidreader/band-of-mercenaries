import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';

final mercenaryRepositoryProvider = Provider((ref) => MercenaryRepository());

final mercenaryListProvider = StateNotifierProvider<MercenaryListNotifier, List<Mercenary>>((ref) {
  return MercenaryListNotifier(ref);
});

class MercenaryListNotifier extends StateNotifier<List<Mercenary>> {
  final Ref ref;
  late final MercenaryRepository _repo;

  MercenaryListNotifier(this.ref) : super([]) {
    _repo = ref.read(mercenaryRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (prev, next) => _checkTimers());
    // 첫 실행 시 initializeNewGame() 완료 후 용병 목록 다시 로드
    ref.listen(userDataProvider, (prev, next) {
      if (prev == null && next != null) _load();
    });
  }

  void _load() {
    state = _repo.getAll();
  }

  void refresh() => _load();

  void _checkTimers() {
    final now = DateTime.now();
    bool changed = false;
    for (final merc in state) {
      if (merc.status == MercenaryStatus.tired && merc.tiredEndTime != null) {
        if (now.isAfter(merc.tiredEndTime!)) {
          merc.status = MercenaryStatus.normal;
          merc.tiredEndTime = null;
          merc.save();
          changed = true;
        }
      }
      if (merc.status == MercenaryStatus.injured && merc.injuryEndTime != null) {
        if (now.isAfter(merc.injuryEndTime!)) {
          merc.status = MercenaryStatus.normal;
          merc.injuryEndTime = null;
          merc.save();
          changed = true;
        }
      }
    }
    if (changed) _load();
  }

  void recalculateTimers(double oldSpeed, double newSpeed) {
    bool changed = false;
    for (final merc in state) {
      if (merc.status == MercenaryStatus.tired && merc.tiredEndTime != null) {
        final newEnd = recalculateEndTime(merc.tiredEndTime, merc.tiredEndTime, oldSpeed, newSpeed);
        if (newEnd != merc.tiredEndTime) {
          merc.tiredEndTime = newEnd;
          merc.save();
          changed = true;
        }
      }
      if (merc.status == MercenaryStatus.injured && merc.injuryEndTime != null) {
        final newEnd = recalculateEndTime(merc.injuryEndTime, merc.injuryEndTime, oldSpeed, newSpeed);
        if (newEnd != merc.injuryEndTime) {
          merc.injuryEndTime = newEnd;
          merc.save();
          changed = true;
        }
      }
    }
    if (changed) _load();
  }

  Future<bool> dismiss(String mercId, int severancePay) async {
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < severancePay) return false;

    final merc = state.firstWhere((m) => m.id == mercId);
    if (merc.isDispatched) return false;

    await ref.read(userDataProvider.notifier).spendGold(severancePay);
    await _repo.dismiss(mercId);
    _load();

    ref.read(activityLogProvider.notifier).addLog(
      '용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G)',
      ActivityLogType.mercenaryDismiss,
    );

    return true;
  }

  Future<Mercenary?> recruit() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return null;

    // Capacity check: enforce barracks max
    final userData = ref.read(userDataProvider);
    final barracksData = staticData.facilities.where((f) => f.id == 'barracks').firstOrNull;
    if (userData != null && barracksData != null) {
      final barracksLevel = userData.facilities['barracks'] ?? 0;
      final maxMercs = FacilityService.getMaxMercenaries(barracksData, barracksLevel);
      final aliveCount = state.where((m) => m.status != MercenaryStatus.dead).length;
      if (aliveCount >= maxMercs) return null;
    }

    final merc = await _repo.recruit(
      jobs: staticData.jobs,
      traits: staticData.traits,
      names: staticData.personNames,
    );
    ref.read(activityLogProvider.notifier).addLog(
      '용병 "${merc.name}" 모집 완료',
      ActivityLogType.mercenaryRecruit,
    );
    _load();
    return merc;
  }
}
