import 'package:flutter/foundation.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/constants/m7_constants.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/models/crafting_recipe_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
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
    required this.achievementService,
    // FR-F1: 세력 평판·접촉점 기반 해금 조건 평가 DI
    required this.factionStateRepository,
    required this.isFactionContactActive,
  });

  final StaticGameData staticData;
  final InventoryRepository inventoryRepository;
  final RegionStateRepository regionStateRepository;
  final ChainQuestRepository chainQuestRepository;
  final UserDataNotifier userDataNotifier;
  final ActivityLogNotifier activityLogNotifier;
  final AchievementService achievementService;
  // FR-F1
  final FactionStateRepository factionStateRepository;
  final bool Function(String contactId) isFactionContactActive;

  /// 레시피의 해금 조건과 재료 보유량을 평가하여 RecipeState를 반환한다.
  RecipeState evaluateState(CraftingRecipeData recipe) {
    final condition = recipe.unlockCondition;

    if (condition != null) {
      // M7 페이즈 4 #4 신규 type 분기
      if (condition.type != null) {
        if (!_isUnlockedM7(condition)) return RecipeState.locked;
      } else {
        // M5 기존 분기 (trustLevel/chainStep/firstAcquiredItem)
        if (condition.trustLevel != null) {
          final trust = regionStateRepository.getSettlementTrust(
            GameConstants.startingRegionId,
          );
          if (trust.level < condition.trustLevel!) return RecipeState.locked;
        }

        if (condition.chainStep != null) {
          final chainStep = condition.chainStep!;
          final progress = chainQuestRepository.get(chainStep.chainId);
          final unlocked =
              progress != null &&
              progress.status == ChainQuestStatus.completed &&
              progress.currentStep > chainStep.step;
          if (!unlocked) return RecipeState.locked;
        }

        if (condition.firstAcquiredItem != null) {
          final regionState = regionStateRepository.getState(
            GameConstants.startingRegionId,
          );
          final acquired =
              regionState?.firstAcquiredMaterialIds.contains(
                condition.firstAcquiredItem!,
              ) ??
              false;
          if (!acquired) return RecipeState.locked;
        }
      }
    }

    // 재료 보유량 평가
    for (final input in recipe.inputs) {
      final qty = inventoryRepository.getQuantityForItemId(input.itemId);
      if (qty < input.quantity) return RecipeState.insufficient;
    }

    return RecipeState.ready;
  }

  /// M7 페이즈 4 #4 신규 type 분기 해금 조건 평가.
  bool _isUnlockedM7(RecipeUnlockCondition condition) {
    switch (condition.type) {
      case 'regionFlag':
        final flag = condition.flag;
        if (flag == null) return false;
        for (final regionId in M7Constants.livingsphereRegions) {
          final state = regionStateRepository.getState(regionId);
          if (state?.unlockedFlags.contains(flag) == true) return true;
        }
        return false;
      case 'infrastructureTier':
        final value = condition.value;
        if (value == null) return false;
        final r3 = regionStateRepository.getState(
          GameConstants.startingRegionId,
        );
        final tier = r3?.currentInfrastructureTier ?? 1;
        return tier >= value;
      case 'all':
        final conds = condition.conditions;
        if (conds == null || conds.isEmpty) return false;
        return conds.every(_isUnlockedM7);
      case 'any':
        final conds = condition.conditions;
        if (conds == null || conds.isEmpty) return false;
        return conds.any(_isUnlockedM7);
      // FR-F1: 세력 평판 임계 해금 조건 (factionReputation >= value)
      case 'factionReputation':
        final factionId = condition.flag ?? condition.factionId;
        final minRep = condition.value ?? condition.minReputation;
        if (factionId == null || minRep == null) return false;
        final state = factionStateRepository.getState(factionId);
        final rep = state?.currentReputation ?? 0;
        return rep >= minRep;
      // FR-F1: 세력 접촉점 활성 여부 해금 조건
      case 'factionContact':
        final contactId = condition.flag;
        if (contactId == null) return false;
        return isFactionContactActive(contactId);
      default:
        return false;
    }
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
      orElse: () =>
          throw ArgumentError('알 수 없는 resultItemId: ${recipe.resultItemId}'),
    );

    await activityLogNotifier.addLog(
      '${resultItemData.name} 제작 완료',
      ActivityLogType.craftCompleted,
    );

    // 희귀 등급(tier >= 3) 아이템 최초 제작 위업 hook
    try {
      if (resultItemData.tier >= 3 &&
          !achievementService.hasAchievement('craft_first_rare:$recipeId')) {
        await achievementService.grant(
          'craft_first_rare:$recipeId',
          payload: {
            'recipeId': recipeId,
            'itemId': recipe.resultItemId,
            'tier': resultItemData.tier,
          },
        );
      }
    } on Exception catch (e) {
      debugPrint('[BOM][Achievement] craft_first_rare 실패: $e');
    }

    return CraftingSuccess(newItem);
  }
}
