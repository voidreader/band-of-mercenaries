import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

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

  Future<Mercenary?> recruit() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return null;
    final merc = await _repo.recruit(
      jobs: staticData.jobs,
      traits: staticData.traits,
      names: staticData.personNames,
    );
    _load();
    return merc;
  }
}
