import 'package:flutter/foundation.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';

class ChainCompletedEvent {
  final String chainId;
  final String chainName;
  final Map<String, int> rewardItems;
  final int reputationBonus;
  final String finalDescription;
  final String? protagonistMercId;

  const ChainCompletedEvent({
    required this.chainId,
    required this.chainName,
    required this.rewardItems,
    required this.reputationBonus,
    required this.finalDescription,
    this.protagonistMercId,
  });
}

class ChainQuestService {
  final ChainQuestRepository _repo;

  /// 위업 발급 콜백 (선택). 주입 시 체인 완주 후 위업 grant 호출.
  /// 미주입 시 hook skip (fail-soft).
  final Future<void> Function(
    String templateId,
    MercenarySnapshot? snapshot,
    int? regionId,
    Map<String, dynamic> payload,
  )? grantAchievement;

  /// mercId → MercenarySnapshot 변환 콜백 (선택).
  /// null이거나 mercId를 찾지 못하면 null 반환.
  final MercenarySnapshot? Function(String? mercId)? buildSnapshot;

  ChainQuestService(
    this._repo, {
    this.grantAchievement,
    this.buildSnapshot,
  });

  Future<bool> tryActivate({
    required String chainId,
    required UserData user,
  }) async {
    if (user.completedChains.contains(chainId)) return false;

    final existing = _repo.get(chainId);

    if (existing != null && existing.status == ChainQuestStatus.active) {
      return false;
    }

    if (existing != null && existing.status == ChainQuestStatus.dormant) {
      existing.status = ChainQuestStatus.active;
      await _repo.save(existing);
      return true;
    }

    final progress = ChainQuestProgress(
      chainId: chainId,
      startedAt: DateTime.now(),
    );
    await _repo.save(progress);
    return true;
  }

  Future<void> onStepCompleted({
    required String chainId,
    required int step,
    required String questResultType,
    required List<Mercenary> partyMercs,
    required List<Mercenary> allMercs,
    required String questTypeId,
    required ChainQuestData chainStepData,
    required void Function(String message, ActivityLogType type) logActivity,
    required Future<void> Function(String chainId, ChainQuestData finalStep)
        onChainCompleted,
    /// step 완료 시 지급할 아이템 처리 콜백
    required Future<void> Function(String itemId, int quantity) addRewardItems,
  }) async {
    final progress = _repo.get(chainId);
    if (progress == null) return;

    final isSuccess =
        questResultType == 'success' || questResultType == 'greatSuccess';

    if (isSuccess) {
      // 거점 사건은 protagonist 무시 (페이즈 1 #4 4.2절)
      if (!chainId.startsWith('settlement_')) {
        final resolvedProtagonist =
            resolveProtagonist(progress: progress, allMercs: allMercs);
        if (resolvedProtagonist == null) {
          final hadProtagonist = progress.protagonistMercId != null;
          if (partyMercs.isNotEmpty) {
            progress.protagonistMercId =
                _pickProtagonist(partyMercs, questTypeId);
          } else {
            final living = allMercs
                .where((m) => m.status != MercenaryStatus.dead)
                .toList();
            progress.protagonistMercId = _pickProtagonist(living, questTypeId);
          }
          if (hadProtagonist && progress.protagonistMercId != null) {
            logActivity(
              '이야기의 주인공이 새로운 용병으로 이어졌다',
              ActivityLogType.chainProgressed,
            );
          }
        }
      }

      for (final entry in chainStepData.rewardItems.entries) {
        await addRewardItems(entry.key, entry.value);
      }

      if (step == chainStepData.totalSteps) {
        await onChainCompleted(chainId, chainStepData);
      } else {
        progress.currentStep += 1;
        progress.currentStepAvailableAt = DateTime.now()
            .add(Duration(seconds: chainStepData.nextStepDelaySeconds));
      }

      logActivity(
        '체인 단계 완료: ${chainStepData.chainName} $step/${chainStepData.totalSteps}단계',
        ActivityLogType.chainProgressed,
      );
    } else {
      progress.stepFailureCount += 1;
    }

    await _repo.save(progress);
  }

  Future<void> completeChain({
    required String chainId,
    required ChainQuestData finalStep,
    required void Function(String message, ActivityLogType type) logActivity,
    required Future<void> Function(int reputation) addReputation,
    required Future<void> Function(String chainId) addCompletedChain,
    required void Function(ChainCompletedEvent event) publishCompleted,
  }) async {
    final progress = _repo.get(chainId);
    if (progress == null) return;

    await addReputation(finalStep.finalReputationBonus ?? 0);
    await addCompletedChain(chainId);

    progress.status = ChainQuestStatus.completed;
    progress.completedAt = DateTime.now();
    await _repo.save(progress);

    logActivity(
      '연계 퀘스트 완주: ${finalStep.chainName}',
      ActivityLogType.chainCompleted,
    );

    publishCompleted(
      ChainCompletedEvent(
        chainId: chainId,
        chainName: finalStep.chainName,
        rewardItems: finalStep.rewardItems,
        reputationBonus: finalStep.finalReputationBonus ?? 0,
        finalDescription: finalStep.description,
        protagonistMercId: progress.protagonistMercId,
      ),
    );

    // 체인 완주 위업 hook — grantAchievement 미주입 시 skip (fail-soft)
    try {
      if (grantAchievement != null) {
        final String templateId;
        MercenarySnapshot? snapshot;

        if (chainId.startsWith('chain_')) {
          // 일반 체인 7종 — protagonistMercId 기반 snapshot
          templateId = 'chain_completed:$chainId';
          snapshot = buildSnapshot?.call(progress.protagonistMercId);
        } else if (chainId.startsWith('settlement_')) {
          // 거점 사건 — protagonistMercId 기반 snapshot (null fallback 허용)
          templateId = 'settlement_event_completed:$chainId';
          snapshot = buildSnapshot?.call(progress.protagonistMercId);
        } else {
          // 알 수 없는 prefix — hook skip
          return;
        }

        await grantAchievement!(
          templateId,
          snapshot,
          finalStep.regionId,
          {'chainId': chainId},
        );
      }
    } on Exception catch (e) {
      debugPrint('[BOM][Achievement] chain hook 실패 ($chainId): $e');
    }
  }

  bool canAdvanceToFinal({
    required ChainQuestData finalStep,
    required UserData user,
  }) {
    final hasGuildEquipment = finalStep.rewardItems.keys.any(
      (itemId) => itemId.startsWith('guild_equipment'),
    );

    if (hasGuildEquipment) {
      final artifactSlotAvailable = user.artifactItemIds.length < 2;
      final bannerSlotAvailable = user.bannerItemId == null;
      return artifactSlotAvailable || bannerSlotAvailable;
    }

    return true;
  }

  Mercenary? resolveProtagonist({
    required ChainQuestProgress progress,
    required List<Mercenary> allMercs,
  }) {
    final mercId = progress.protagonistMercId;
    if (mercId == null) return null;

    final merc = allMercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) return null;
    if (merc.status == MercenaryStatus.dead) return null;

    return merc;
  }

  Future<void> checkDormant({
    required List<ChainQuestProgress> progresses,
  }) async {
    for (final progress in progresses) {
      // 거점 사건은 14일 dormant 정책 미적용 (페이즈 1 #4 4.2절)
      if (progress.chainId.startsWith('settlement_')) continue;
      if (progress.status != ChainQuestStatus.active) continue;
      final availableAt = progress.currentStepAvailableAt;
      if (availableAt == null) continue;
      if (DateTime.now().difference(availableAt) > const Duration(days: 14)) {
        progress.status = ChainQuestStatus.dormant;
        await _repo.save(progress);
      }
    }
  }

  Future<bool> tryActivateSettlement({
    required int regionId,
    required String eventName,
    required UserData user,
  }) async {
    final chainId = 'settlement_${regionId}_$eventName';
    return tryActivate(chainId: chainId, user: user);
  }

  Future<void> reactivateIfDormant({required String chainId}) async {
    final progress = _repo.get(chainId);
    if (progress == null) return;
    if (progress.status != ChainQuestStatus.dormant) return;

    progress.status = ChainQuestStatus.active;
    await _repo.save(progress);
  }

  String? _pickProtagonist(List<Mercenary> mercs, String questTypeId) {
    if (mercs.isEmpty) return null;

    Mercenary? best;
    double bestPower = -1;
    for (final merc in mercs) {
      final power = QuestCalculator.mercPower(merc, questTypeId);
      if (power > bestPower) {
        bestPower = power;
        best = merc;
      }
    }
    return best?.id;
  }
}
