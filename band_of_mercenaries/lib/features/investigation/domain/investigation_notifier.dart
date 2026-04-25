import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
export 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart'
    show regionStateRepositoryProvider;
import 'package:band_of_mercenaries/features/investigation/domain/investigation_service.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_result.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_completion_provider.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_clue_result.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';

final investigationNotifierProvider = StateNotifierProvider<InvestigationNotifier, void>(
  (ref) => InvestigationNotifier(ref),
);

class InvestigationNotifier extends StateNotifier<void> {
  final Ref _ref;
  bool _isCompleting = false;

  InvestigationNotifier(this._ref) : super(null) {
    _checkPastInvestigation();
  }

  void _checkPastInvestigation() {
    final userData = _ref.read(userDataProvider);
    if (userData?.investigatingMercId != null &&
        userData?.investigationEndTime != null &&
        DateTime.now().isAfter(userData!.investigationEndTime!)) {
      checkCompletion();
    }
  }

  Future<bool> startInvestigation(String mercId, int regionId) async {
    final userData = _ref.read(userDataProvider);
    if (userData == null) return false;
    if (userData.isMoving) return false;
    if (userData.investigatingMercId != null) return false;

    final staticData = _ref.read(staticDataProvider).value;
    if (staticData == null) return false;

    final hasDiscoveries = staticData.regionDiscoveries.any((d) => d.regionId == regionId);
    if (!hasDiscoveries) return false;

    final region = staticData.regions.where((r) => r.region == regionId).firstOrNull;
    if (region == null) return false;

    final speedMult = _ref.read(speedMultiplierProvider);
    final duration = InvestigationService.getInvestigationDuration(region.regionTier, speedMult);
    final endTime = DateTime.now().add(duration);

    return await _ref.read(userDataProvider.notifier).startInvestigation(mercId, endTime, regionId);
  }

  void checkCompletion() {
    final userData = _ref.read(userDataProvider);
    if (userData?.investigatingMercId == null || userData?.investigationEndTime == null) return;
    if (_isCompleting) return;
    if (!DateTime.now().isAfter(userData!.investigationEndTime!)) return;

    _isCompleting = true;
    _completeInvestigation().whenComplete(() => _isCompleting = false);
  }

  Future<void> _completeInvestigation() async {
    final userData = _ref.read(userDataProvider);
    if (userData == null) return;

    final mercId = userData.investigatingMercId!;
    final regionId = userData.investigationRegionId!;

    final staticData = _ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final mercs = _ref.read(mercenaryListProvider);
    final merc = mercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) {
      await _ref.read(userDataProvider.notifier).clearInvestigation();
      return;
    }

    final region = staticData.regions.where((r) => r.region == regionId).firstOrNull;
    final tier = region?.regionTier ?? 1;

    double successRate = InvestigationService.calculateSuccessRate(merc.effectiveAgi, merc.effectiveVit);
    final userData2 = _ref.read(userDataProvider);
    final joinedIds = _ref.read(factionStateRepositoryProvider).getJoinedFactionIds();
    final joinedFactions = staticData.factions.where((f) => joinedIds.contains(f.id)).toList();
    final effects = PassiveBonusService.collect(
      reputation: userData2?.reputation ?? 0,
      allRanks: staticData.ranks,
      joinedFactions: joinedFactions,
    );
    final investBonus = PassiveBonusService.getInvestigationSuccessRateBonus(effects);
    successRate = (successRate + investBonus).clamp(5.0, 95.0);
    final success = Random().nextDouble() * 100 < successRate;

    final repo = _ref.read(regionStateRepositoryProvider);
    InvestigationResult result;

    if (success) {
      final gain = InvestigationService.getKnowledgeGain(tier);
      final updatedState = repo.updateKnowledge(regionId, gain);

      final regionDiscoveries = staticData.regionDiscoveries.where((d) => d.regionId == regionId);
      final newlyTriggered = regionDiscoveries
          .where((d) =>
              d.knowledgeThreshold <= updatedState.knowledge &&
              !updatedState.triggeredDiscoveries.contains(d.id))
          .toList();

      for (final d in newlyTriggered) {
        await repo.addTriggeredDiscovery(regionId, d.id);
      }

      _ref.read(activityLogProvider.notifier).addLog(
        '${merc.name} — 조사 완료 (지식 +$gain)',
        ActivityLogType.investigationSuccess,
      );

      final factionClueResults = <FactionClueResult>[];
      final unlockedEliteIds = <String>[];
      final factionRepo = _ref.read(factionStateRepositoryProvider);

      for (final d in newlyTriggered) {
        if (d.discoveryType == 'faction_clue') {
          final factionId = d.discoveryData?['faction_id'] as String?;
          final clueLevel = d.discoveryData?['clue_level'] as int?;
          final clueText = d.discoveryData?['clue_text'] as String?;
          if (factionId == null || clueLevel == null || clueText == null) continue;

          final factionName = staticData.factions
              .where((f) => f.id == factionId)
              .firstOrNull
              ?.name;

          final isNew = await factionRepo.processClue(
            factionId: factionId,
            regionId: regionId,
            discoveryId: d.id,
            foundAt: DateTime.now(),
          );

          factionClueResults.add(FactionClueResult(
            factionId: factionId,
            factionName: factionName,
            clueLevel: clueLevel,
            clueText: clueText,
            regionId: regionId,
            discoveryId: d.id,
          ));

          if (isNew) {
            String logMessage;
            switch (clueLevel) {
              case 1:
                logMessage = '세력 단서 발견: $clueText';
                break;
              case 2:
                logMessage = '세력 발견: ${factionName ?? "(알 수 없는 세력)"}의 정체를 파악했다';
                break;
              case 3:
                logMessage = '거점 발견: ${factionName ?? "(알 수 없는 세력)"}의 전초기지 위치를 파악했다';
                break;
              default:
                logMessage = '세력 단서 발견: $clueText';
            }
            _ref.read(activityLogProvider.notifier).addLog(
              logMessage,
              ActivityLogType.discoveryFound,
            );
          }
          continue;
        } else if (d.discoveryType == 'elite') {
          final eliteId = d.discoveryData?['elite_id'] as String?;
          if (eliteId == null) continue;
          unlockedEliteIds.add(eliteId);
          final revealText = d.discoveryData?['reveal_text'] as String?;
          _ref.read(activityLogProvider.notifier).addLog(
            revealText ?? '엘리트 발견: ${d.description}',
            ActivityLogType.discoveryFound,
          );
          continue;
        } else if (d.discoveryType == 'hidden_quest') {
          final chainId = d.discoveryData?['chain_id'] as String?;
          if (chainId != null) {
            final currentUser = _ref.read(userDataProvider);
            if (currentUser != null) {
              await _ref.read(chainQuestServiceProvider).tryActivate(
                chainId: chainId,
                user: currentUser,
              );
            }
          }
          continue;
        }

        _ref.read(activityLogProvider.notifier).addLog(
          '발견: ${d.description}',
          ActivityLogType.discoveryFound,
        );
      }

      result = InvestigationResult(
        success: true,
        regionId: regionId,
        knowledgeGained: gain,
        currentKnowledge: updatedState.knowledge,
        newDiscoveryIds: newlyTriggered.map((d) => d.id).toList(),
        mercInjured: false,
        mercId: mercId,
        factionClues: factionClueResults,
        unlockedEliteIds: unlockedEliteIds,
      );
    } else {
      final injuryChance = InvestigationService.getInjuryChance(tier);
      final injured = injuryChance > 0 &&
          Random().nextDouble() < injuryChance &&
          merc.status != MercenaryStatus.injured &&
          merc.status != MercenaryStatus.dead;

      if (injured) {
        final speedMult = _ref.read(speedMultiplierProvider);
        final recoverySeconds = (tier * 10 * 60 / speedMult).round();
        final mercRepo = _ref.read(mercenaryRepositoryProvider);
        await mercRepo.updateStatus(
          mercId,
          MercenaryStatus.injured,
          endTime: DateTime.now().add(Duration(seconds: recoverySeconds)),
        );
        _ref.invalidate(mercenaryListProvider);
      }

      _ref.read(activityLogProvider.notifier).addLog(
        '${merc.name} — 조사 실패${injured ? " (부상)" : ""}',
        ActivityLogType.investigationFailed,
      );

      final currentState = repo.getState(regionId);
      result = InvestigationResult(
        success: false,
        regionId: regionId,
        knowledgeGained: 0,
        currentKnowledge: currentState?.knowledge ?? 0,
        newDiscoveryIds: [],
        mercInjured: injured,
        mercId: mercId,
        factionClues: const [],
        unlockedEliteIds: const [],
      );
    }

    await _ref.read(userDataProvider.notifier).clearInvestigation();
    _ref.read(investigationCompletedProvider.notifier).state = result;
  }

  Future<void> cancelInvestigation() async {
    await _ref.read(userDataProvider.notifier).clearInvestigation();
  }
}
