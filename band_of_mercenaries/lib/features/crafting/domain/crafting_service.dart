import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/models/crafting_recipe_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';

/// 레시피 해금·재료 충족 상태를 나타낸다.
enum RecipeState { locked, insufficient, ready }

/// 제작 시도 결과 — 성공과 실패 두 가지 분기를 sealed로 표현한다.
sealed class CraftingResult {
  const CraftingResult();
}

/// 제작 성공 — 인벤토리에 추가된 InventoryItem을 포함한다.
class CraftingSuccess extends CraftingResult {
  final InventoryItem item;
  const CraftingSuccess(this.item);
}

/// 제작 실패 — reason 값: 'lockMissing' | 'materialShortage' | 'unknown'.
class CraftingFailure extends CraftingResult {
  final String reason;
  const CraftingFailure(this.reason);
}

/// 레시피 해금 평가·제작 실행을 담당하는 순수 서비스 (ref 미보유, 테스트 가능).
class CraftingService {
  const CraftingService({
    required this.staticData,
    required this.inventoryRepository,
    required this.regionStateRepository,
    required this.chainQuestRepository,
    required this.userDataNotifier,
    required this.activityLogNotifier,
  });

  final StaticGameData staticData;
  final InventoryRepository inventoryRepository;
  final RegionStateRepository regionStateRepository;
  final ChainQuestRepository chainQuestRepository;
  final UserDataNotifier userDataNotifier;
  final ActivityLogNotifier activityLogNotifier;

  /// 레시피의 해금 조건과 재료 보유량을 평가하여 RecipeState를 반환한다.
  RecipeState evaluateState(CraftingRecipeData recipe) {
    final condition = recipe.unlockCondition;

    if (condition != null) {
      // 신뢰도 조건 평가
      if (condition.trustLevel != null) {
        final trust = regionStateRepository
            .getSettlementTrust(GameConstants.startingRegionId);
        if (trust.level < condition.trustLevel!) return RecipeState.locked;
      }

      // 체인 단계 완료 조건 평가
      if (condition.chainStep != null) {
        final chainStep = condition.chainStep!;
        final progress = chainQuestRepository.get(chainStep.chainId);
        final unlocked = progress != null &&
            progress.status == ChainQuestStatus.completed &&
            progress.currentStep > chainStep.step;
        if (!unlocked) return RecipeState.locked;
      }

      // 특정 아이템 최초 입수 조건 영속 평가
      if (condition.firstAcquiredItem != null) {
        final regionState =
            regionStateRepository.getState(GameConstants.startingRegionId);
        final acquired = regionState?.firstAcquiredMaterialIds
                .contains(condition.firstAcquiredItem!) ??
            false;
        if (!acquired) return RecipeState.locked;
      }
    }

    // 재료 보유량 평가
    for (final input in recipe.inputs) {
      final qty = inventoryRepository.getQuantityForItemId(input.itemId);
      if (qty < input.quantity) return RecipeState.insufficient;
    }

    return RecipeState.ready;
  }

  /// 레시피를 실행하여 재료를 소비하고 결과물을 인벤토리에 추가한다.
  Future<CraftingResult> craft(String recipeId) async {
    final recipe = staticData.craftingRecipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => throw ArgumentError('알 수 없는 recipeId: $recipeId'),
    );

    final state = evaluateState(recipe);
    if (state == RecipeState.locked) {
      return const CraftingFailure('lockMissing');
    }
    if (state == RecipeState.insufficient) {
      return const CraftingFailure('materialShortage');
    }

    for (final input in recipe.inputs) {
      await inventoryRepository.consumeMaterial(input.itemId, input.quantity);
    }

    final newItem = await inventoryRepository.addItem(
      itemId: recipe.resultItemId,
      quantity: recipe.resultQuantity,
      items: staticData.items,
    );

    final resultItemData = staticData.items.firstWhere(
      (i) => i.id == recipe.resultItemId,
      orElse: () => throw ArgumentError('알 수 없는 resultItemId: ${recipe.resultItemId}'),
    );

    await activityLogNotifier.addLog(
      '${resultItemData.name} 제작 완료',
      ActivityLogType.craftCompleted,
    );

    return CraftingSuccess(newItem);
  }
}
