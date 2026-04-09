import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

class QuestRepository {
  Box<ActiveQuest> get _box => Hive.box<ActiveQuest>(HiveInitializer.questBoxName);

  List<ActiveQuest> getAll() => _box.values.toList();

  List<ActiveQuest> getPending() =>
      _box.values.where((q) => q.status == QuestStatus.pending).toList();

  List<ActiveQuest> getInProgress() =>
      _box.values.where((q) => q.status == QuestStatus.inProgress).toList();

  Future<void> addQuests(List<ActiveQuest> quests) async {
    for (final quest in quests) {
      await _box.add(quest);
    }
  }

  Future<void> startQuest(String questId, List<String> mercIds, DateTime endTime) async {
    final quest = _box.values.firstWhere((q) => q.id == questId);
    quest.dispatchedMercIds = mercIds;
    quest.startTime = DateTime.now();
    quest.endTime = endTime;
    quest.status = QuestStatus.inProgress;
    await quest.save();
  }

  Future<void> completeQuest(String questId, QuestResult result) async {
    final quest = _box.values.firstWhere((q) => q.id == questId);
    quest.status = QuestStatus.completed;
    quest.result = result;
    await quest.save();
  }

  Future<void> clearPending() async {
    final pending = _box.values.where((q) => q.status == QuestStatus.pending).toList();
    for (final quest in pending) {
      await quest.delete();
    }
  }

  Future<void> clearCompleted() async {
    final completed = _box.values.where((q) => q.status == QuestStatus.completed).toList();
    for (final quest in completed) {
      await quest.delete();
    }
  }

  Future<void> removeQuest(String questId) async {
    final index = _box.values.toList().indexWhere((q) => q.id == questId);
    if (index >= 0) {
      await _box.deleteAt(index);
    }
  }
}
