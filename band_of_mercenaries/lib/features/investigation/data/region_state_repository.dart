import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';

final regionStateRepositoryProvider = Provider((ref) => RegionStateRepository());

class RegionStateRepository {
  Box<RegionState> get _box => Hive.box<RegionState>(HiveInitializer.regionStateBoxName);

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
  RegionState updateKnowledge(int regionId, int delta) {
    var state = getState(regionId);
    if (state == null) {
      state = RegionState(regionId: regionId);
      _box.add(state);
    }
    state.knowledge = (state.knowledge + delta).clamp(0, 100);
    state.save();
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
}
