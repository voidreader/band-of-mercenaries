import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/battle_memory_entry.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';

void main() {
  group('Mercenary', () {
    test('effectiveStr returns 80% when tired', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, status: MercenaryStatus.tired);
      expect(merc.effectiveStr, 8);
      expect(merc.effectiveIntelligence, 8);
      expect(merc.effectiveVit, 80);
    });

    test('effectiveStr returns full value when normal', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50);
      expect(merc.effectiveStr, 10);
    });

    test('isAvailable returns false when dead', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, status: MercenaryStatus.dead);
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns false when dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, isDispatched: true);
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns true when normal and not dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50);
      expect(merc.isAvailable, true);
    });

    test('isAvailable returns true when tired and not dispatched', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 10, intelligence: 10, vit: 100, agi: 50, status: MercenaryStatus.tired);
      expect(merc.isAvailable, true);
    });

    test('hiddenStats initializes to empty map when not provided', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
      );
      expect(merc.hiddenStats, isEmpty);
      expect(merc.hiddenStats, isA<Map<String, int>>());
    });

    test('battleMemories initializes to empty list when not provided', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
      );
      expect(merc.battleMemories, isEmpty);
      expect(merc.battleMemories, isA<List<BattleMemoryEntry>>());
    });

    test('hiddenStats preserves provided values', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
        hiddenStats: {'hidden_stat_1': 2, 'hidden_stat_2': 3},
      );
      expect(merc.hiddenStats, {'hidden_stat_1': 2, 'hidden_stat_2': 3});
    });

    test('battleMemories preserves provided values', () {
      final entry1 = BattleMemoryEntry(
        mercId: 'test',
        entryType: 'emotional_apply',
        sourceEventId: 'quest_1',
        timestamp: DateTime.now(),
      );
      final entry2 = BattleMemoryEntry(
        mercId: 'test',
        entryType: 'hidden_stat_unlock',
        sourceEventId: 'quest_2',
        timestamp: DateTime.now(),
      );
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
        battleMemories: [entry1, entry2],
      );
      expect(merc.battleMemories, hasLength(2));
      expect(merc.battleMemories[0].sourceEventId, 'quest_1');
      expect(merc.battleMemories[1].sourceEventId, 'quest_2');
    });

    test('addBattleMemory maintains FIFO order when adding up to 30 entries', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
      );

      for (int i = 1; i <= 30; i++) {
        final entry = BattleMemoryEntry(
          mercId: 'test',
          entryType: 'emotional_apply',
          sourceEventId: 'quest_$i',
          timestamp: DateTime.now(),
        );
        merc.addBattleMemory(entry);
      }

      expect(merc.battleMemories, hasLength(30));
      expect(merc.battleMemories[0].sourceEventId, 'quest_1');
      expect(merc.battleMemories[29].sourceEventId, 'quest_30');
    });

    test('addBattleMemory removes oldest entry when exceeding 30 entries', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
      );

      // Add 31 entries
      for (int i = 1; i <= 31; i++) {
        final entry = BattleMemoryEntry(
          mercId: 'test',
          entryType: 'emotional_apply',
          sourceEventId: 'quest_$i',
          timestamp: DateTime.now(),
        );
        merc.addBattleMemory(entry);
      }

      // Should have exactly 30 entries
      expect(merc.battleMemories, hasLength(30));

      // First entry should be quest_2 (oldest quest_1 removed)
      expect(merc.battleMemories[0].sourceEventId, 'quest_2');

      // Last entry should be quest_31
      expect(merc.battleMemories[29].sourceEventId, 'quest_31');
    });

    test('addBattleMemory maintains FIFO with multiple cycles', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        str: 10,
        intelligence: 10,
        vit: 100,
        agi: 50,
      );

      // Add 60 entries, ensuring multiple FIFO evictions
      for (int i = 1; i <= 60; i++) {
        final entry = BattleMemoryEntry(
          mercId: 'test',
          entryType: 'emotional_apply',
          sourceEventId: 'quest_$i',
          timestamp: DateTime.now(),
        );
        merc.addBattleMemory(entry);
      }

      // Should have exactly 30 entries
      expect(merc.battleMemories, hasLength(30));

      // Should keep entries from quest_31 to quest_60 (30 most recent)
      expect(merc.battleMemories[0].sourceEventId, 'quest_31');
      expect(merc.battleMemories[29].sourceEventId, 'quest_60');

      // quest_1 through quest_30 should be removed
      final allEventIds = merc.battleMemories.map((e) => e.sourceEventId).toList();
      expect(allEventIds, isNot(contains('quest_1')));
      expect(allEventIds, isNot(contains('quest_30')));
    });
  });

  group('level stat bonuses', () {
    test('level 1 has no bonus (100 str stays 100)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 1);
      expect(merc.effectiveStr, 100);
    });

    test('level 3 gets +20% bonus (100 str becomes 120)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 3);
      expect(merc.effectiveStr, 120);
    });

    test('level 5 gets +40% bonus (100 str becomes 140)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 5);
      expect(merc.effectiveStr, 140);
    });

    test('tired + level 3 stacks multiplicatively (100 * 1.2 * 0.8 = 96)', () {
      final merc = Mercenary(id: 'test', name: 'Test', jobId: 'farmer', traitId: 'strong', str: 100, intelligence: 100, vit: 100, agi: 50, level: 3, status: MercenaryStatus.tired);
      expect(merc.effectiveStr, 96);
    });
  });

  group('CombatSimulationResult', () {
    test('hiddenStatEvents initializes to empty map when not provided', () {
      final result = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: [],
        exitCondition: CombatExitCondition.bEnemyWiped,
        seed: 12345,
      );
      expect(result.hiddenStatEvents, isEmpty);
      expect(result.hiddenStatEvents, isA<Map<String, Map<String, int>>>());
    });

    test('battleMemoryEvents initializes to empty list when not provided', () {
      final result = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: [],
        exitCondition: CombatExitCondition.bEnemyWiped,
        seed: 12345,
      );
      expect(result.battleMemoryEvents, isEmpty);
      expect(result.battleMemoryEvents, isA<List<BattleMemoryEntry>>());
    });

    test('hiddenStatEvents preserves provided values', () {
      final hiddenStatEvents = {
        'merc_1': {'hidden_stat_1': 2, 'hidden_stat_2': 1},
        'merc_2': {'hidden_stat_3': 3},
      };
      final result = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: [],
        exitCondition: CombatExitCondition.bEnemyWiped,
        seed: 12345,
        hiddenStatEvents: hiddenStatEvents,
      );
      expect(result.hiddenStatEvents, hiddenStatEvents);
    });

    test('battleMemoryEvents preserves provided values', () {
      final entry1 = BattleMemoryEntry(
        mercId: 'merc_1',
        entryType: 'hidden_stat_unlock',
        sourceEventId: 'quest_1',
        timestamp: DateTime.now(),
      );
      final entry2 = BattleMemoryEntry(
        mercId: 'merc_2',
        entryType: 'emotional_apply',
        sourceEventId: 'quest_2',
        timestamp: DateTime.now(),
      );
      final events = [entry1, entry2];
      final result = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: [],
        exitCondition: CombatExitCondition.bEnemyWiped,
        seed: 12345,
        battleMemoryEvents: events,
      );
      expect(result.battleMemoryEvents, hasLength(2));
      expect(result.battleMemoryEvents[0].mercId, 'merc_1');
      expect(result.battleMemoryEvents[1].mercId, 'merc_2');
    });

    test('hiddenStatEvents and battleMemoryEvents both initialize empty independently', () {
      final result = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: [],
        exitCondition: CombatExitCondition.bEnemyWiped,
        seed: 12345,
      );
      expect(result.hiddenStatEvents, isEmpty);
      expect(result.battleMemoryEvents, isEmpty);
    });

    test('hiddenStatEvents and battleMemoryEvents both preserve values independently', () {
      final hiddenStatEvents = {
        'merc_1': {'hidden_stat_1': 2},
      };
      final entry = BattleMemoryEntry(
        mercId: 'merc_1',
        entryType: 'hidden_stat_unlock',
        sourceEventId: 'quest_1',
        timestamp: DateTime.now(),
      );
      final result = CombatSimulationResult(
        questResult: QuestResult.success,
        turns: [],
        exitCondition: CombatExitCondition.bEnemyWiped,
        seed: 12345,
        hiddenStatEvents: hiddenStatEvents,
        battleMemoryEvents: [entry],
      );
      expect(result.hiddenStatEvents, isNotEmpty);
      expect(result.battleMemoryEvents, isNotEmpty);
      expect(result.hiddenStatEvents['merc_1']!['hidden_stat_1'], 2);
      expect(result.battleMemoryEvents[0].sourceEventId, 'quest_1');
    });
  });
}
