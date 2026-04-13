import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class TraitDeletionResult {
  final bool canDelete;
  final String? reason;
  final int cost;

  const TraitDeletionResult({
    required this.canDelete,
    this.reason,
    required this.cost,
  });
}

class TraitDeletionService {
  static int deletionCost(TraitData trait) {
    if (trait.type == 'acquired') return GameConstants.traitDeletionCostAcquired;
    if (trait.type == 'evolved') return GameConstants.traitDeletionCostEvolved;
    return 0;
  }

  static TraitDeletionResult canDelete({
    required TraitData trait,
    required Mercenary mercenary,
    required int infirmaryLevel,
    required int currentGold,
  }) {
    if (trait.type == 'innate') {
      return const TraitDeletionResult(canDelete: false, reason: '선천 트레잇은 삭제할 수 없습니다', cost: 0);
    }

    final cost = deletionCost(trait);

    if (mercenary.isDispatched) {
      return TraitDeletionResult(canDelete: false, reason: '파견 중에는 삭제할 수 없습니다', cost: cost);
    }

    if (trait.type == 'acquired' && infirmaryLevel < GameConstants.traitDeletionMinInfirmaryLevelAcquired) {
      return TraitDeletionResult(
        canDelete: false,
        reason: '의무실 레벨 ${GameConstants.traitDeletionMinInfirmaryLevelAcquired} 필요',
        cost: cost,
      );
    }

    if (trait.type == 'evolved' && infirmaryLevel < GameConstants.traitDeletionMinInfirmaryLevelEvolved) {
      return TraitDeletionResult(
        canDelete: false,
        reason: '의무실 레벨 ${GameConstants.traitDeletionMinInfirmaryLevelEvolved} 필요',
        cost: cost,
      );
    }

    if (currentGold < cost) {
      return TraitDeletionResult(
        canDelete: false,
        reason: '골드가 부족합니다 ($currentGold G / $cost G)',
        cost: cost,
      );
    }

    return TraitDeletionResult(canDelete: true, cost: cost);
  }
}
