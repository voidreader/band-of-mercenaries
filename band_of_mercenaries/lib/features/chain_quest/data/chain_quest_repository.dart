import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';

class ChainQuestRepository {
  Box<ChainQuestProgress> get _box =>
      Hive.box<ChainQuestProgress>(HiveInitializer.chainQuestProgressBoxName);

  ChainQuestProgress? get(String chainId) => _box.get(chainId);

  List<ChainQuestProgress> getAll() => _box.values.toList();

  List<ChainQuestProgress> getActive() =>
      _box.values.where((p) => p.status == ChainQuestStatus.active).toList();

  Future<void> save(ChainQuestProgress progress) async {
    await _box.put(progress.chainId, progress);
  }

  Future<void> delete(String chainId) async {
    await _box.delete(chainId);
  }

  Stream<List<ChainQuestProgress>> watchAll() =>
      _box.watch().map((_) => getAll());
}

final chainQuestRepositoryProvider = Provider<ChainQuestRepository>(
  (ref) => ChainQuestRepository(),
);
