import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart' show TraitEventResult;
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart' show EliteLootResult;
import 'package:band_of_mercenaries/features/quest/domain/role_synergy_matrix.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_sort_service.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_detail_page.dart';
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/features/quest/view/chain_top_section.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_acquisition_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_evolution_dialog.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_notifier.dart' show regionStateRepositoryProvider;
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart' show factionStateRepositoryProvider;
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';
import 'package:band_of_mercenaries/shared/widgets/layer_sidebar.dart';
import 'package:band_of_mercenaries/shared/widgets/quest_card_badges.dart';

const Map<String, IconData> _roleIcons = {
  'warrior': Icons.shield,
  'ranger': Icons.gps_fixed,
  'mage': Icons.auto_awesome,
  'rogue': Icons.dark_mode,
  'support': Icons.favorite,
  'specialist': Icons.build,
};

class DispatchScreen extends ConsumerStatefulWidget {
  const DispatchScreen({super.key});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  String? _selectedQuestId;
  String? _dispatchQuestId;
  bool _isShowingResult = false;
  final Set<String> _shownResultIds = {};

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final quests = ref.watch(questListProvider);
    final staticData = ref.watch(staticDataProvider);
    ref.watch(gameTickProvider);

    ref.listen<List<ActiveQuest>>(questListProvider, (previous, next) {
      if (_isShowingResult) return;
      final completed = next.where(
        (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
      ).toList();
      if (completed.isNotEmpty) {
        _isShowingResult = true;
        _shownResultIds.add(completed.first.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showResult(context, completed.first, ref);
          }
        });
      }
    });

    if (userData == null) return const Center(child: CircularProgressIndicator());

    if (_dispatchQuestId != null) {
      // 대상 퀘스트가 pending 상태인지 확인 — 탭 전환 후 복귀 시 stale ID 방지
      final targetQuest = quests.where((q) => q.id == _dispatchQuestId).firstOrNull;
      if (targetQuest == null || targetQuest.status != QuestStatus.pending) {
        // 다음 프레임에서 리셋 (build 중 setState 방지)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _dispatchQuestId = null);
        });
      } else {
        return DispatchDetailPage(
          questId: _dispatchQuestId!,
          onBack: () => setState(() => _dispatchQuestId = null),
        );
      }
    }

    if (userData.isMoving) {
      return const Center(
        child: Text('이동 중에는 파견할 수 없습니다', style: TextStyle(fontSize: 16, color: AppTheme.textHint)),
      );
    }

    return staticData.when(
      data: (data) {
        // 정렬에 필요한 데이터 수집
        final pendingRaw = quests.where((q) => q.status == QuestStatus.pending).toList();
        final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
        final chainProgresses = ref.watch(chainQuestProgressProvider).valueOrNull ?? const <ChainQuestProgress>[];
        final regionState = ref.watch(regionStateRepositoryProvider).getState(userData.region);
        final joinedFactionIds = ref.watch(factionStateRepositoryProvider).getJoinedFactionIds().toSet();

        final sortResult = QuestSortService.sort(
          quests: pendingRaw,
          chainProgress: chainProgresses,
          currentRegion: userData.region,
          currentSector: userData.sector,
          regionState: regionState,
          questPools: data.questPools,
          questTypes: data.questTypes,
          joinedFactionIds: joinedFactionIds,
          eliteMonsters: data.eliteMonsters,
        );

        // Tier 0(체인 단계)는 ChainTopSection이 별도 처리, sortedRest만 목록에 사용
        final pendingQuests = sortResult.sortedRest;

        return Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${data.regions.firstWhere((r) => r.region == userData.region).regionName} (지역 ${userData.region})',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // In-progress quests
                    for (final quest in inProgressQuests)
                      if (quest.endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.tier3Bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TimerDisplay(
                              label: '⚔ ${quest.questName}',
                              remaining: quest.endTime!.difference(DateTime.now()),
                            ),
                          ),
                        ),

                    // Quest list header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('가능한 퀘스트 (${pendingQuests.length}개)',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
                        if (pendingQuests.isEmpty)
                          TextButton(
                            onPressed: () => ref.read(questListProvider.notifier).generateQuests(),
                            child: const Text('퀘스트 생성'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 연계 퀘스트 최상단 섹션 (ChainTopSection이 내부에서 0~3 카드 렌더링)
                    const ChainTopSection(),

                    // 정렬된 일반 퀘스트 목록 (Tier 1~4)
                    for (final quest in pendingQuests)
                      _QuestCard(
                        quest: quest,
                        data: data,
                        isSelected: _selectedQuestId == quest.id,
                        chainProgresses: chainProgresses,
                        regionState: regionState,
                        currentSector: userData.sector,
                        onTap: () => setState(() {
                          _selectedQuestId = quest.id;
                          _dispatchQuestId = quest.id;
                        }),
                      ),

                    // Fill quests button
                    Builder(builder: (context) {
                      final maxCount = ref.read(questListProvider.notifier).getMaxQuestCount();
                      final activeCount = quests.where(
                        (q) => q.status == QuestStatus.pending || q.status == QuestStatus.inProgress,
                      ).length;
                      if (activeCount >= maxCount) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => ref.read(questListProvider.notifier).fillQuests(),
                            child: Text('퀘스트 채우기 ($activeCount/$maxCount)'),
                          ),
                        ),
                      );
                    }),

                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다')),
    );
  }

  Future<void> _showResult(BuildContext context, ActiveQuest quest, WidgetRef ref) async {
    final EliteLootResult? eliteLoot = ref.read(pendingEliteLootProvider)[quest.id];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestResultDialog(quest: quest, eliteLoot: eliteLoot),
    );

    // Trait event popups
    if (context.mounted) {
      final events = ref.read(pendingTraitEventsProvider)[quest.id];
      if (events != null) {
        await _showTraitEvents(context, ref, events);
        // Remove processed events
        final current = ref.read(pendingTraitEventsProvider);
        ref.read(pendingTraitEventsProvider.notifier).state = Map.from(current)..remove(quest.id);
      }
    }

    // 엘리트 loot 정리
    final currentLoot = ref.read(pendingEliteLootProvider);
    if (currentLoot.containsKey(quest.id)) {
      ref.read(pendingEliteLootProvider.notifier).state = Map.from(currentLoot)..remove(quest.id);
    }

    // 다이얼로그 닫힘 후 퀘스트 정리
    ref.read(questListProvider.notifier).clearCompleted(quest.id);
    _isShowingResult = false;
    // 다음 완료된 퀘스트가 있으면 표시
    if (context.mounted) {
      final quests = ref.read(questListProvider);
      final nextCompleted = quests.where(
        (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
      ).toList();
      if (nextCompleted.isNotEmpty) {
        _isShowingResult = true;
        _shownResultIds.add(nextCompleted.first.id);
        _showResult(context, nextCompleted.first, ref);
      }
    }
  }

  Future<void> _showTraitEvents(
    BuildContext context,
    WidgetRef ref,
    Map<String, TraitEventResult> events,
  ) async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;
    final mercs = ref.read(mercenaryListProvider);
    final mercRepo = ref.read(mercenaryRepositoryProvider);

    for (final entry in events.entries) {
      final mercId = entry.key;
      final event = entry.value;
      final merc = mercs.where((m) => m.id == mercId).firstOrNull;
      if (merc == null || !context.mounted) continue;

      // 1. Acquisition notification
      if (event.acquiredTraitKey != null) {
        final traitData = staticData.traits.where((t) => t.key == event.acquiredTraitKey).firstOrNull;
        if (traitData != null && context.mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => TraitAcquisitionDialog(trait: traitData, mercenaryName: merc.name),
          );
        }
      }

      // 2. Evolution selection
      if (event.singleEvoCandidates.isNotEmpty || event.comboEvoCandidates.isNotEmpty) {
        if (!context.mounted) break;
        // Get current acquired traits for the card comparison view
        final updatedMerc = mercRepo.getAll().where((m) => m.id == mercId).firstOrNull;
        if (updatedMerc == null) continue;
        final currentTraits = updatedMerc.allTraitIds
            .map((key) => staticData.traits.where((t) => t.key == key).firstOrNull)
            .whereType<TraitData>()
            .where((t) => t.type != 'innate')
            .toList();

        final choice = await showDialog<EvolutionChoice?>(
          context: context,
          barrierDismissible: false,
          builder: (_) => TraitEvolutionDialog(
            mercenaryName: updatedMerc.name,
            currentTraits: currentTraits,
            singleCandidates: event.singleEvoCandidates,
            comboCandidates: event.comboEvoCandidates,
            allTraits: staticData.traits,
          ),
        );

        // Apply evolution if chosen
        if (choice != null) {
          if (choice.isSingle && choice.single != null) {
            final s = choice.single!;
            await mercRepo.evolveTrait(mercId, s.fromKey, s.toKey);
            final fromTrait = staticData.traits.where((t) => t.key == s.fromKey).firstOrNull;
            final toTrait = staticData.traits.where((t) => t.key == s.toKey).firstOrNull;
            if (fromTrait != null && toTrait != null) {
              ref.read(activityLogProvider.notifier).addLog(
                '${updatedMerc.name}의 "${fromTrait.name}"이(가) "${toTrait.name}"(으)로 진화!',
                ActivityLogType.traitEvolved,
              );
            }
          } else if (!choice.isSingle && choice.combo != null) {
            final c = choice.combo!;
            await mercRepo.comboEvolveTrait(mercId, c.trait1Key, c.trait2Key, c.resultKey);
            final t1 = staticData.traits.where((t) => t.key == c.trait1Key).firstOrNull;
            final t2 = staticData.traits.where((t) => t.key == c.trait2Key).firstOrNull;
            final result = staticData.traits.where((t) => t.key == c.resultKey).firstOrNull;
            if (t1 != null && t2 != null && result != null) {
              ref.read(activityLogProvider.notifier).addLog(
                '${updatedMerc.name}의 "${t1.name}" + "${t2.name}" → "${result.name}"(으)로 조합 진화!',
                ActivityLogType.traitEvolved,
              );
            }
          }
          ref.read(mercenaryListProvider.notifier).refresh();
        }
      }
    }
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({
    required this.quest,
    required this.data,
    required this.isSelected,
    required this.chainProgresses,
    required this.regionState,
    required this.currentSector,
    required this.onTap,
  });

  final ActiveQuest quest;
  final StaticGameData data;
  final bool isSelected;
  final List<ChainQuestProgress> chainProgresses;
  final RegionState? regionState;
  final int currentSector;
  final VoidCallback onTap;

  /// QuestLayerInfo를 구성한다. LayerSidebar와 QuestCardBadges 양쪽이 공유.
  QuestLayerInfo _buildLayerInfo() {
    // 체인 정보
    ChainQuestInfo? chain;
    if (quest.isChainQuest && quest.chainId != null) {
      final step = data.chainQuests.where(
        (s) => s.chainId == quest.chainId && s.step == quest.chainStep,
      ).firstOrNull;
      // 해당 chainId의 progress가 존재하고 step 데이터도 있는 경우에만 체인 정보 생성
      if (step != null && chainProgresses.any((p) => p.chainId == quest.chainId)) {
        chain = ChainQuestInfo(
          chainName: step.chainName,
          currentStep: step.step,
          totalSteps: step.totalSteps,
        );
      }
    }

    // 엘리트 정보
    final eliteData = quest.isElite
        ? data.eliteMonsters.where((m) => m.id == quest.eliteId).firstOrNull
        : null;
    final isUnique = eliteData?.isUnique ?? false;

    // 변형 섹터 타입 (현재 섹터의 변형이 퀘스트 풀과 일치하는 경우만)
    String? sectorType;
    final pool = data.questPools.where((p) => p.id == quest.questPoolId).firstOrNull;
    if (pool?.sectorType != null &&
        regionState?.sectorChanges[currentSector.toString()] == pool!.sectorType) {
      sectorType = pool.sectorType;
    }

    // 세력 정보
    final FactionData? faction = quest.factionTag == null
        ? null
        : data.factions.where((f) => f.id == quest.factionTag).firstOrNull;

    return QuestLayerInfo(
      chain: chain,
      isElite: quest.isElite,
      isUnique: isUnique,
      sectorType: sectorType,
      faction: faction,
      isFactionExclusive: quest.isFactionExclusive,
    );
  }

  /// 이름 색상을 계층 우선순위에 따라 결정한다.
  Color? _nameColor(QuestLayerInfo layerInfo) {
    if (layerInfo.chain != null) return AppTheme.primary;
    if (layerInfo.isElite && layerInfo.isUnique) return AppTheme.eliteUniqueAccent;
    if (layerInfo.isElite) return AppTheme.eliteAccent;
    return null; // 기본 onSurface
  }

  /// 테두리 색상을 계층 우선순위에 따라 결정한다.
  Color _borderColor(QuestLayerInfo layerInfo, bool isSelected) {
    if (isSelected) return AppTheme.primary;
    // 체인 → 금색 우선 (세력 전용과 중첩 시도 금색)
    if (layerInfo.chain != null) return AppTheme.chainGold;
    // 세력 전용 → 세력 컬러
    if (layerInfo.isFactionExclusive && layerInfo.faction != null) {
      return FactionData.parseColor(layerInfo.faction!.color);
    }
    return AppTheme.borderLight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final layerInfo = _buildLayerInfo();
    final nameColor = _nameColor(layerInfo);
    final borderColor = _borderColor(layerInfo, isSelected);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측 사이드바 (계층 색상)
            LayerSidebar(
              info: layerInfo,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                bottomLeft: Radius.circular(7),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 퀘스트 이름 + 퀘스트 유형
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quest.questName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: nameColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(questType.name,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 계층 배지 (체인/엘리트/변형섹터/세력)
                    QuestCardBadges(info: layerInfo),
                    const SizedBox(height: 4),
                    Text(
                        '난이도 ${quest.difficulty} · 보상 ${questType.baseReward}G · 소요 ${questType.baseDuration}초',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
                    // 추천 role Chip 표시
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Builder(builder: (context) {
                        final topRoles = RoleSynergyMatrix.topRolesForQuest(
                          quest.questTypeId,
                          n: 2,
                        );
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final entry in topRoles)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                avatar: Icon(
                                  _roleIcons[entry.key] ?? Icons.build,
                                  size: 14,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  RoleUtils.koreanName(entry.key),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                    // 자동 갱신까지 남은 시간 표시
                    if (quest.status == QuestStatus.pending && quest.createdAt != null)
                      Builder(builder: (_) {
                        final speedMult = ref.watch(speedMultiplierProvider);
                        final realElapsed = DateTime.now().difference(quest.createdAt!);
                        final gameElapsedMs = (realElapsed.inMilliseconds * speedMult).round();
                        final gameElapsed = Duration(milliseconds: gameElapsedMs);
                        final remaining = const Duration(hours: 1) - gameElapsed;
                        if (remaining.isNegative) return const SizedBox.shrink();
                        final mins = remaining.inMinutes;
                        final secs = remaining.inSeconds % 60;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '갱신까지 ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
