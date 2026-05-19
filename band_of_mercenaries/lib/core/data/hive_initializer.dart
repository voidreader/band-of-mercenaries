import 'package:hive_flutter/hive_flutter.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_model.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/core/models/persisted_dialog_entry.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/memorial_cause.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_daily_entry.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart'; // M8b 페이즈 4 #2 추가
import 'package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart'; // M8b 페이즈 4 #2 추가
import 'package:band_of_mercenaries/features/quest/domain/combat_turn.dart'; // M8b 페이즈 4 #2 추가
import 'package:band_of_mercenaries/features/quest/domain/combat_action.dart'; // M8b 페이즈 4 #2 추가
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart'; // M8b 페이즈 4 #2 추가
import 'package:band_of_mercenaries/features/quest/domain/combatant_snapshot.dart'; // M8b 페이즈 4 #2 추가
import 'package:band_of_mercenaries/features/quest/domain/enemy_snapshot.dart'; // M8b 페이즈 4 #2 추가

class HiveInitializer {
  static const String userBoxName = 'user';
  static const String mercenaryBoxName = 'mercenaries';
  static const String questBoxName = 'quests';
  static const String settingsBoxName = 'settings';
  static const String staticDataCacheBoxName = 'staticDataCache';
  static const String regionStateBoxName = 'regionStates';
  static const String factionStateBoxName = 'factionStates';
  static const String inventoryBoxName = 'inventory';
  static const String chainQuestProgressBoxName = 'chainQuestProgress';
  static const String dialogQueueBoxName = 'dialogQueue';
  static const String bandAchievementBoxName = 'bandAchievements';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(MercenaryStatusAdapter());
    Hive.registerAdapter(MercenaryAdapter());
    Hive.registerAdapter(QuestStatusAdapter());
    Hive.registerAdapter(QuestResultAdapter());
    Hive.registerAdapter(CombatReportAdapter()); // M8a 페이즈 4 #2
    // M8b 페이즈 4 #2 — Hive enum (typeId 28~30)
    Hive.registerAdapter(CombatExitConditionAdapter());      // 28
    Hive.registerAdapter(BehaviorPatternAdapter());          // 29
    Hive.registerAdapter(PositionRowAdapter());              // 30
    // M8b 페이즈 4 #2 — 시뮬레이션 영속 (typeId 22~27)
    Hive.registerAdapter(CombatSimulationResultAdapter());   // 22
    Hive.registerAdapter(CombatTurnAdapter());               // 23
    Hive.registerAdapter(CombatActionAdapter());             // 24
    Hive.registerAdapter(StatusEffectEventAdapter());        // 25
    Hive.registerAdapter(CombatantSnapshotAdapter());        // 26
    Hive.registerAdapter(EnemySnapshotAdapter());            // 27
    Hive.registerAdapter(ActiveQuestAdapter());
    Hive.registerAdapter(UserDataAdapter());
    Hive.registerAdapter(ActivityLogTypeAdapter());
    Hive.registerAdapter(ActivityLogAdapter());
    Hive.registerAdapter(RegionStateAdapter());
    Hive.registerAdapter(FactionClueRecordAdapter());
    Hive.registerAdapter(FactionStateAdapter());
    Hive.registerAdapter(FactionShopDailyEntryAdapter()); // M8a 페이즈 4 #1
    Hive.registerAdapter(InventoryItemAdapter());
    Hive.registerAdapter(ChainQuestStatusAdapter());
    Hive.registerAdapter(ChainQuestProgressAdapter());
    Hive.registerAdapter(PersistedDialogEntryAdapter());
    // 위업·연대기 모델 어댑터: enum 먼저, 그 후 클래스
    Hive.registerAdapter(BandAchievementTypeAdapter());
    Hive.registerAdapter(MemorialCauseAdapter());
    Hive.registerAdapter(MercenarySnapshotAdapter());
    Hive.registerAdapter(BandAchievementAdapter());

    await Hive.openBox(settingsBoxName);
    final settingsBox = Hive.box(settingsBoxName);
    if (settingsBox.get('stat_migration_v2') == null) {
      await Hive.deleteBoxFromDisk(mercenaryBoxName);
      await Hive.deleteBoxFromDisk(questBoxName);
      await settingsBox.put('stat_migration_v2', true);
    }

    await Hive.openBox<UserData>(userBoxName);
    await Hive.openBox<Mercenary>(mercenaryBoxName);
    await Hive.openBox<ActiveQuest>(questBoxName);
    await Hive.openBox<ActivityLog>(ActivityLogRepository.boxName);
    await Hive.openBox<String>(staticDataCacheBoxName);
    await Hive.openBox<RegionState>(regionStateBoxName);
    await Hive.openBox<FactionState>(factionStateBoxName);
    await Hive.openBox<InventoryItem>(inventoryBoxName);
    await Hive.openBox<ChainQuestProgress>(chainQuestProgressBoxName);
    await Hive.openBox<PersistedDialogEntry>(dialogQueueBoxName);
    await Hive.openBox<BandAchievement>(bandAchievementBoxName);
  }
}
