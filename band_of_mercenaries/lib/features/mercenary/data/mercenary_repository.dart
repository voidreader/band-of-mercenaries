import 'dart:math';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/settings_keys.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

class MercenaryRepository {
  Box<Mercenary> get _box => Hive.box<Mercenary>(HiveInitializer.mercenaryBoxName);

  List<Mercenary> getAll() => _box.values.toList();

  List<Mercenary> getAlive() =>
      _box.values.where((m) => m.status != MercenaryStatus.dead).toList();

  List<Mercenary> getAvailable() =>
      _box.values.where((m) => m.isAvailable).toList();

  Future<Mercenary> recruit({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<TraitCategory> categories,
    required List<PersonName> names,
  }) async {
    final merc = RecruitmentService.generateMercenary(
      jobs: jobs,
      traits: traits,
      categories: categories,
      names: names,
      random: Random(),
    );
    await _box.add(merc);
    return merc;
  }

  Future<void> updateStatus(String mercId, MercenaryStatus status, {DateTime? endTime}) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.status = status;
    if (status == MercenaryStatus.injured) {
      merc.injuryEndTime = endTime;
    } else if (status == MercenaryStatus.tired) {
      merc.tiredEndTime = endTime;
    }
    await merc.save();
  }

  Future<void> setDispatched(String mercId, bool dispatched) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.isDispatched = dispatched;
    await merc.save();
  }

  Future<void> removeDead(String mercId) async {
    final index = _box.values.toList().indexWhere((m) => m.id == mercId);
    if (index >= 0) await _box.deleteAt(index);
  }

  Future<void> dismiss(String mercId) async {
    final index = _box.values.toList().indexWhere((m) => m.id == mercId);
    if (index >= 0) {
      await _box.deleteAt(index);
    }
    // Save dismissed ID
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final dismissed = List<String>.from(settingsBox.get(SettingsKeys.dismissedMercIds, defaultValue: <String>[]));
    dismissed.add(mercId);
    await settingsBox.put(SettingsKeys.dismissedMercIds, dismissed);
  }

  List<String> getDismissedIds() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    return List<String>.from(settingsBox.get(SettingsKeys.dismissedMercIds, defaultValue: <String>[]));
  }

  Future<void> updateStats(String mercId, Map<String, int> newStats) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.stats = newStats;
    await merc.save();
  }

  Future<void> addTrait(String mercId, String traitKey) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    if (!merc.traitIds.contains(traitKey)) {
      merc.traitIds = [...merc.traitIds, traitKey];
      await merc.save();
    }
  }

  Future<void> evolveTrait(String mercId, String fromKey, String toKey) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.traitIds = merc.traitIds.map((k) => k == fromKey ? toKey : k).toList();
    merc.traitHistory = [...merc.traitHistory, fromKey];
    await merc.save();
  }

  Future<void> comboEvolveTrait(String mercId, String key1, String key2, String resultKey) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.traitIds = merc.traitIds.where((k) => k != key1 && k != key2).toList()..add(resultKey);
    merc.traitHistory = [...merc.traitHistory, key1, key2];
    await merc.save();
  }

  Future<void> addXpAndCheckLevel(String mercId, int xpGain) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.xp += xpGain;
    final newLevel = ExperienceService.checkLevelUp(currentLevel: merc.level, currentXp: merc.xp);
    merc.level = newLevel;
    await merc.save();
  }
}
