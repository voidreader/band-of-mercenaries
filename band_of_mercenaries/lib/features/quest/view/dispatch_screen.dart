import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart' show TraitEventResult;
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart' show EliteLootResult;
import 'package:band_of_mercenaries/features/quest/domain/role_synergy_matrix.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';
import 'package:band_of_mercenaries/features/quest/domain/sorted_quests_provider.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_detail_page.dart';
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/features/quest/view/chain_top_section.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_acquisition_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_evolution_dialog.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_notifier.dart' show regionStateRepositoryProvider;
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
        // 정렬은 sortedPendingQuestsProvider가 메모이제이션 처리 (1초 tick 영향 회피)
        final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
        final chainProgresses = ref.watch(chainQuestProgressProvider).valueOrNull ?? const <ChainQuestProgress>[];
        final regionState = ref.watch(regionStateRepositoryProvider).getState(userData.region);
        final sortResult = ref.watch(sortedPendingQuestsProvider);

        // Tier 0(체인 단계)는 ChainTopSection이 별도 처리, sortedRest만 목록에 사용
        final pendingQuests = sortResult.sortedRest;
        debugPrint('[BOM][Dispatch] build: quests=${quests.length}, '
            'pending=${quests.where((q) => q.status == QuestStatus.pending).length}, '
            'sortedRest=${pendingQuests.length}, '
            'questTypeIds=${quests.map((q) => q.questTypeId).toSet()}, '
            'staticTypeIds=${data.questTypes.map((t) => t.id).toSet()}');

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
                  Text(() {
                    final r = data.regions.where((r) => r.region == userData.region).firstOrNull;
                    return r != null ? '${r.regionName} (지역 ${userData.region})' : '지역 ${userData.region}';
                  }(), style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
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

    for (final entry in events.entries) {
      final mercId = entry.key;
      final event = entry.value;
      final mercs = ref.read(mercenaryListProvider);
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
        // 진화 다이얼로그 표시 직전에 최신 trait 목록 fetch (방금 적용된 acquisition 반영)
        final updatedMerc = ref.read(mercenaryListProvider).where((m) => m.id == mercId).firstOrNull;
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

        if (choice != null && context.mounted) {
          await ref.read(mercenaryListProvider.notifier).applyEvolution(mercId, choice);
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

    // 지명 의뢰 정보 (M6 페이즈 4 #3)
    final isNamed = pool?.isNamed ?? false;
    String? namedSublabel;
    if (isNamed && pool != null) {
      namedSublabel = _resolveNamedHookLabel(pool, data);
    }

    return QuestLayerInfo(
      chain: chain,
      isElite: quest.isElite,
      isUnique: isUnique,
      sectorType: sectorType,
      faction: faction,
      isFactionExclusive: quest.isFactionExclusive,
      isNamed: isNamed,
      namedSublabel: namedSublabel,
    );
  }

  /// 지명 hook 타입을 서브라벨 문자열로 변환한다 (M6 페이즈 4 #3).
  static String? _resolveNamedHookLabel(QuestPool pool, StaticGameData data) {
    final hookType = pool.namedHookType;
    final hookValue = pool.namedHookValue;
    switch (hookType) {
      case 'title':
        if (hookValue != null) {
          final title = data.titles.where((t) => t.id == hookValue).firstOrNull;
          return title != null ? '칭호 — ${title.name}' : '칭호 보유 용병 지명';
        }
        return '칭호 보유 용병 지명';
      case 'achievement_count':
        return hookValue != null ? '위업 $hookValue개 이상' : '위업';
      case 'flagship':
        return '간판 용병 지명';
      default:
        return null; // fallback: '지명'만 표시
    }
  }

  /// M6 페이즈 4 #3 — 지명 의뢰 카드 잠금 여부.
  /// hook=title: 칭호 보유 alive mercenary 전원 파견 중일 때 true
  /// hook=flagship: namedTargetMercId 동결 mercenary가 파견 중일 때 true
  /// hook=achievement_count: 잠금 무관 (false)
  static bool _isNamedQuestLocked(
    ActiveQuest quest,
    QuestPool pool,
    List<Mercenary> mercs,
  ) {
    if (!pool.isNamed) return false;
    switch (pool.namedHookType) {
      case 'title':
        final candidates = mercs
            .where((m) =>
                m.titleIds.contains(pool.namedHookValue) &&
                m.status != MercenaryStatus.dead)
            .toList();
        if (candidates.isEmpty) return false;
        return candidates.every((m) => m.isDispatched);
      case 'flagship':
        final targetId = quest.namedTargetMercId;
        if (targetId == null) return false;
        final target = mercs.where((m) => m.id == targetId).firstOrNull;
        if (target == null || target.status == MercenaryStatus.dead) return false;
        return target.isDispatched;
      default:
        return false;
    }
  }

  /// M6 페이즈 4 #3 — 잠금 토스트에 표시할 지명 용병 이름.
  /// hook=title: 첫 번째 alive title 보유 용병 이름
  /// hook=flagship: namedTargetMercId 동결 용병 이름
  /// 알 수 없으면 "지명 용병" fallback
  static String _resolveLockedMercName(
    ActiveQuest quest,
    QuestPool pool,
    List<Mercenary> mercs,
  ) {
    switch (pool.namedHookType) {
      case 'title':
        final candidate = mercs.where((m) =>
            m.titleIds.contains(pool.namedHookValue) &&
            m.status != MercenaryStatus.dead).firstOrNull;
        return candidate?.name ?? '지명 용병';
      case 'flagship':
        final targetId = quest.namedTargetMercId;
        if (targetId == null) return '지명 용병';
        return mercs.where((m) => m.id == targetId).firstOrNull?.name ?? '지명 용병';
      default:
        return '지명 용병';
    }
  }

  /// 이름 색상을 계층 우선순위에 따라 결정한다.
  Color? _nameColor(QuestLayerInfo layerInfo) {
    if (layerInfo.chain != null) return AppTheme.primary;
    if (layerInfo.isNamed) return AppTheme.namedAccent;
    if (layerInfo.isElite && layerInfo.isUnique) return AppTheme.eliteUniqueAccent;
    if (layerInfo.isElite) return AppTheme.eliteAccent;
    return null; // 기본 onSurface
  }

  /// 테두리 색상을 계층 우선순위에 따라 결정한다.
  Color _borderColor(QuestLayerInfo layerInfo, bool isSelected, {bool isFixed = false}) {
    if (isSelected) return AppTheme.primary;
    // 고정 임무 → 청록색
    if (isFixed) return const Color(0xFF00ACC1);
    // 체인 → 금색 우선 (세력 전용과 중첩 시도 금색)
    if (layerInfo.chain != null) return AppTheme.chainGold;
    // 지명 의뢰 → namedAccent
    if (layerInfo.isNamed) return AppTheme.namedAccent;
    // 세력 전용 → 세력 컬러
    if (layerInfo.isFactionExclusive && layerInfo.faction != null) {
      return FactionData.parseColor(layerInfo.faction!.color);
    }
    return AppTheme.borderLight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questType = data.questTypes.where((t) => t.id == quest.questTypeId).firstOrNull;
    if (questType == null) {
      debugPrint('[BOM][Dispatch] questTypeId 누락: ${quest.questTypeId} — 카드 skip');
      return const SizedBox.shrink();
    }
    final pool = data.questPools.where((p) => p.id == quest.questPoolId).firstOrNull;
    final isFixed = pool?.isFixed ?? false;
    final layerInfo = _buildLayerInfo();
    final nameColor = _nameColor(layerInfo);
    final borderColor = _borderColor(layerInfo, isSelected, isFixed: isFixed);

    // M6 페이즈 4 #3 — 지명 의뢰 잠금 상태 계산
    final mercList = ref.watch(mercenaryListProvider);
    final locked = pool != null ? _isNamedQuestLocked(quest, pool, mercList) : false;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
      ),
      child: IntrinsicHeight(
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
                    // 고정 임무 / 거점 사건 배지 (같은 줄)
                    if (isFixed || quest.isSettlementStep)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (isFixed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00ACC1).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF00ACC1), width: 1),
                                ),
                                child: const Text(
                                  '📌 고정 임무',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00ACC1),
                                  ),
                                ),
                              ),
                            if (quest.isSettlementStep)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.settlementAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.settlementAccent, width: 1),
                                ),
                                child: const Text(
                                  '📜 마을 사건',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.settlementAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
                    // 자동 갱신까지 남은 시간 표시 (고정 임무는 갱신되지 않으므로 제외)
                    if (!isFixed && quest.status == QuestStatus.pending && quest.createdAt != null)
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // 잠금 상태일 때 카드 전체를 dimming + 탭 차단
          Opacity(
            opacity: locked ? 0.4 : 1.0,
            child: AbsorbPointer(
              absorbing: locked,
              child: GestureDetector(
                onTap: onTap,
                child: cardContent,
              ),
            ),
          ),
          // M6 페이즈 4 #3 — 잠금 오버레이: 투명 탭 감지
          if (locked)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // locked == true 일 때 pool != null 이 Dart flow analysis에 의해 보장됨
                  final mercName = _resolveLockedMercName(quest, pool, mercList);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('지명 용병 $mercName이(가) 복귀해야 수행할 수 있습니다'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          // 잠금 배지
          if (locked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '지명 용병 복귀 대기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
