import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

final factionStateRepositoryProvider = Provider((ref) => FactionStateRepository());

class FactionStateRepository {
  Box<FactionState> get _box => Hive.box<FactionState>(HiveInitializer.factionStateBoxName);

  FactionState? getState(String factionId) {
    try {
      return _box.values.firstWhere((s) => s.factionId == factionId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> processClue({
    required String factionId,
    required int regionId,
    required String discoveryId,
    required DateTime foundAt,
  }) async {
    var state = getState(factionId);
    if (state == null) {
      state = FactionState(factionId: factionId);
      await _box.add(state);
    }

    final alreadyFound = state.clueRecords.any((r) => r.discoveryId == discoveryId);

    final record = FactionClueRecord(
      factionId: factionId,
      regionId: regionId,
      discoveryId: discoveryId,
      foundAt: foundAt,
    );
    state.clueRecords.add(record);
    await state.save();

    return !alreadyFound;
  }

  List<FactionState> getAll() {
    return _box.values.toList();
  }
}
