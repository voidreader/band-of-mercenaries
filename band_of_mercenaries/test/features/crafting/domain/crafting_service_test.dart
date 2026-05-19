import 'package:flutter_test/flutter_test.dart';

import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/models/crafting_recipe_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';

class _FakeInventoryRepository implements InventoryRepository {
  @override
  int getQuantityForItemId(String itemId) => 999;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFactionStateRepository implements FactionStateRepository {
  @override
  FactionState? getState(String factionId) => FactionState(
    factionId: factionId,
    reputation: factionId == 'faction_adventurers_guild' ? 31 : 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRegionStateRepository implements RegionStateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChainQuestRepository implements ChainQuestRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserDataNotifier implements UserDataNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeActivityLogNotifier implements ActivityLogNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAchievementService implements AchievementService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

StaticGameData _emptyStaticData() {
  return StaticGameData(
    difficulties: const [],
    jobs: const [],
    traits: const [],
    traitCategories: const [],
    traitConflicts: const [],
    traitTransitions: const [],
    traitComboEvolutions: const [],
    traitSynergies: const [],
    regions: const [],
    questTypes: const [],
    questPools: const [],
    personNames: const [],
    travelEvents: const [],
    facilities: const [],
    ranks: const [],
    mercenaryWages: const [],
    regionDiscoveries: const [],
    factions: const [],
    items: const [],
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionAdjacencies: const [],
    regionSectors: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: const [],
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
  );
}

void main() {
  group('CraftingService.evaluateState', () {
    test('CSV 형식의 factionReputation 조건을 세력 평판 해금으로 평가한다', () {
      final service = CraftingService(
        staticData: _emptyStaticData(),
        inventoryRepository: _FakeInventoryRepository(),
        regionStateRepository: _FakeRegionStateRepository(),
        chainQuestRepository: _FakeChainQuestRepository(),
        userDataNotifier: _FakeUserDataNotifier(),
        activityLogNotifier: _FakeActivityLogNotifier(),
        achievementService: _FakeAchievementService(),
        factionStateRepository: _FakeFactionStateRepository(),
        isFactionContactActive: (_) => false,
      );
      final recipe = CraftingRecipeData(
        id: 'recipe_m8a_record_compass',
        name: '기록원의 나침반',
        resultItemId: 'guild_artifact_record_compass',
        inputs: const [],
        unlockCondition: RecipeUnlockCondition.fromJson(const {
          'type': 'factionReputation',
          'factionId': 'faction_adventurers_guild',
          'minReputation': 31,
        }),
      );

      expect(service.evaluateState(recipe), RecipeState.ready);
    });
  });
}
