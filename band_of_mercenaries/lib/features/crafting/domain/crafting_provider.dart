import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/models/crafting_recipe_data.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart';

/// 정적 데이터 준비 후 CraftingService 인스턴스를 제공한다 (콜백 DI 의존성 주입).
final craftingServiceProvider = Provider<CraftingService>((ref) {
  final staticData = ref.watch(staticDataProvider).requireValue;
  return CraftingService(
    staticData: staticData,
    inventoryRepository: ref.watch(inventoryRepositoryProvider),
    regionStateRepository: ref.watch(regionStateRepositoryProvider),
    chainQuestRepository: ref.watch(chainQuestRepositoryProvider),
    userDataNotifier: ref.read(userDataProvider.notifier),
    activityLogNotifier: ref.read(activityLogProvider.notifier),
    achievementService: ref.read(achievementServiceProvider),
  );
});

/// staticData에서 craftingRecipes 추출 (로딩 중 빈 리스트 fallback).
final craftingRecipesProvider = Provider<List<CraftingRecipeData>>((ref) {
  return ref.watch(staticDataProvider).maybeWhen(
    data: (d) => d.craftingRecipes,
    orElse: () => const [],
  );
});

/// 1초 tick마다 재평가 — chain step / trust level / 재료 보유량 변화 감지.
final recipeStateProvider =
    Provider.family<RecipeState, String>((ref, recipeId) {
  ref.watch(gameTickProvider);
  final service = ref.watch(craftingServiceProvider);
  final recipes = ref.watch(craftingRecipesProvider);
  final recipe = recipes.firstWhere(
    (r) => r.id == recipeId,
    orElse: () => throw ArgumentError('레시피 $recipeId 없음'),
  );
  return service.evaluateState(recipe);
});

/// 재료 itemId가 들어가는 레시피 수 (정적 데이터 — Provider 캐시).
final materialUsageCountProvider =
    Provider.family<int, String>((ref, materialItemId) {
  final recipes = ref.watch(craftingRecipesProvider);
  return recipes
      .where((r) => r.inputs.any((i) => i.itemId == materialItemId))
      .length;
});
