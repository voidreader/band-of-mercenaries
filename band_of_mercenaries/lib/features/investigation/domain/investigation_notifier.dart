import 'dart:math';
import 'package:flutter/foundation.dart';
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
import 'package:band_of_mercenaries/features/investigation/domain/region_transformed_provider.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_discovery_data.dart';

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

    final ok = await _ref.read(userDataProvider.notifier).startInvestigation(mercId, endTime, regionId);
    debugPrint('[BOM][Invest] 조사 시작: merc=$mercId, region=$regionId, 종료=$endTime → $ok');
    return ok;
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
    debugPrint('[BOM][Invest] 조사 완료 처리: merc=$mercId, region=$regionId');

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
    debugPrint('[BOM][Invest] 결과: ${success ? "성공" : "실패"} (성공률 ${successRate.toStringAsFixed(1)}%)');

    final repo = _ref.read(regionStateRepositoryProvider);
    InvestigationResult result;

    if (success) {
      final gain = InvestigationService.getKnowledgeGain(tier);
      final updatedState = await repo.updateKnowledge(regionId, gain);

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
          await _applyDiscoveryItems(d, regionId, staticData);
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
          await _applyDiscoveryItems(d, regionId, staticData);
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
          await _applyDiscoveryItems(d, regionId, staticData);
          continue;
        } else if (d.discoveryType == 'transform') {
          final data = d.discoveryData;
          if (data == null) continue;

          final transformType = data['transform_type'] as String?;
          final sectorIndex = (data['sector_index'] as num?)?.toInt();
          final transformedName = data['transformed_name'] as String? ?? '';
          final narrativeTemplate = data['narrative_template'] as String? ?? '';

          if (transformType == null || sectorIndex == null) continue;

          final regionStateRepo = _ref.read(regionStateRepositoryProvider);
          final transformed = await regionStateRepo.applyTransform(
            regionId: regionId,
            sectorIndex: sectorIndex,
            transformType: transformType,
          );
          if (!transformed) continue;

          await _applyDiscoveryItems(d, regionId, staticData);

          // TemplateEngine으로 서사 텍스트 렌더
          String narrativeRendered = narrativeTemplate;
          try {
            final engine = _ref.read(templateEngineProvider);
            final currentUser = _ref.read(userDataProvider);
            final currentStaticData = _ref.read(staticDataProvider).value;
            final allMercs = _ref.read(mercenaryListProvider);
            final investigatingMerc = allMercs.where((m) => m.id == mercId).firstOrNull;
            final currentRegionData =
                currentStaticData?.regions.where((r) => r.region == regionId).firstOrNull;
            final currentRegionState = regionStateRepo.getState(regionId);
            final sectorChangesIntKey = currentRegionState?.sectorChanges.map(
                  (k, v) => MapEntry(int.tryParse(k) ?? 0, v),
                ) ??
                {};

            if (currentUser != null) {
              narrativeRendered = engine.render(
                narrativeTemplate,
                TemplateContext(
                  user: currentUser,
                  merc: investigatingMerc,
                  region: currentRegionData,
                  sectorChanges: sectorChangesIntKey,
                  evaluationScope: EvaluationScope.mercenary,
                ),
              );
            }
          } catch (_) {
            // fail-safe: 렌더 실패 시 원문 그대로 사용
          }

          // 지역 변형 이벤트 publish
          _ref.read(regionTransformedProvider.notifier).state = RegionTransformedEvent(
            regionId: regionId,
            sectorIndex: sectorIndex,
            transformType: transformType,
            transformedName: transformedName,
            narrativeRendered: narrativeRendered,
          );

          // 활동 로그
          final regionName = region?.regionName ?? '리전 $regionId';
          _ref.read(activityLogProvider.notifier).addLog(
            '$regionName의 섹터가 $transformedName(으)로 변형되었다',
            ActivityLogType.regionTransform,
          );
          continue;
        }

        // 4분기 어디에도 해당 안 됨 (normal 등) — items 보상 적용 후 기본 로그
        await _applyDiscoveryItems(d, regionId, staticData);
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

  /// 발견 보상 아이템 지급 — drop_rate 확률 및 999 스택 상한 적용
  Future<void> _applyDiscoveryItems(
    RegionDiscoveryData d,
    int regionId,
    StaticGameData staticData,
  ) async {
    final items = d.discoveryData?['items'];
    if (items is! List) return;
    final inv = _ref.read(inventoryRepositoryProvider);
    final regionRepo = _ref.read(regionStateRepositoryProvider);
    final logger = _ref.read(activityLogProvider.notifier);
    final random = Random();
    for (final entry in items) {
      if (entry is! Map) continue;
      final itemId = entry['item_id'] as String?;
      if (itemId == null) continue;
      final quantity = (entry['quantity'] as num?)?.toInt() ?? 1;
      final dropRate = (entry['drop_rate'] as num?)?.toDouble() ?? 1.0;
      if (random.nextDouble() >= dropRate) continue;
      final itemData = staticData.items.where((i) => i.id == itemId).firstOrNull;
      if (itemData == null) continue; // 데이터 불일치 — silent skip
      if (inv.getQuantityForItemId(itemId) >= 999) {
        await logger.addLog(
          '${itemData.name} 보유량이 가득 찼습니다 (999 도달)',
          ActivityLogType.inventoryStackCapped,
        );
        continue;
      }
      await inv.addItem(itemId: itemId, quantity: quantity, items: staticData.items);
      await regionRepo.addAcquiredMaterial(regionId, itemId);
    }
  }
}
