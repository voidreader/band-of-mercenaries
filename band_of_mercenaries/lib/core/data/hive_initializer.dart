import 'package:hive_flutter/hive_flutter.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/home/data/activity_log_repository.dart';

class HiveInitializer {
  static const String userBoxName = 'user';
  static const String mercenaryBoxName = 'mercenaries';
  static const String questBoxName = 'quests';
  static const String settingsBoxName = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(MercenaryStatusAdapter());
    Hive.registerAdapter(MercenaryAdapter());
    Hive.registerAdapter(QuestStatusAdapter());
    Hive.registerAdapter(QuestResultAdapter());
    Hive.registerAdapter(ActiveQuestAdapter());
    Hive.registerAdapter(UserDataAdapter());
    Hive.registerAdapter(ActivityLogTypeAdapter());
    Hive.registerAdapter(ActivityLogAdapter());

    await Hive.openBox<UserData>(userBoxName);
    await Hive.openBox<Mercenary>(mercenaryBoxName);
    await Hive.openBox<ActiveQuest>(questBoxName);
    await Hive.openBox<ActivityLog>(ActivityLogRepository.boxName);
    await Hive.openBox(settingsBoxName);
  }
}
