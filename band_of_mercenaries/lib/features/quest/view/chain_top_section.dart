import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';


/// 파견 화면 상단에 진행 중인 체인 퀘스트를 최대 3장 표시하는 섹션 위젯.
/// 활성(현재 리전) 체인 우선 노출, 비활성 시 이동 탭 이동 버튼 제공.
class ChainTopSection extends ConsumerWidget {
  const ChainTopSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(chainQuestProgressProvider);
    final progresses = progressAsync.valueOrNull ?? const <ChainQuestProgress>[];

    // settlement_ prefix 체인은 settlementTier로 일반 목록에 표시되므로 여기서 제외
    final actives = progresses
        .where((p) =>
            p.status == ChainQuestStatus.active &&
            !p.chainId.startsWith('settlement_'))
        .toList();
    if (actives.isEmpty) return const SizedBox.shrink();

    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final userData = ref.watch(userDataProvider);
    if (staticData == null) return const SizedBox.shrink();

    final currentRegionId = userData?.region;

    final cards = <_ChainCardData>[];
    for (final p in actives) {
      final step = staticData.chainQuests
          .where((q) => q.chainId == p.chainId && q.step == p.currentStep)
          .firstOrNull;
      if (step == null) continue;

      final targetRegion = step.targetRegionId ?? step.regionId;
      final isActiveHere =
          targetRegion == null || targetRegion == currentRegionId;

      // 대기 중(currentStepAvailableAt 미래) 여부 판정
      final availableAt = p.currentStepAvailableAt;
      final isWaiting =
          availableAt != null && availableAt.isAfter(DateTime.now());

      cards.add(_ChainCardData(
        progress: p,
        step: step,
        isActiveHere: isActiveHere && !isWaiting,
        isWaiting: isWaiting,
      ));
    }

    // 활성(현재 리전, 대기 아님) 우선, 비활성 후순위. 최대 3장.
    cards.sort((a, b) {
      if (a.isActiveHere == b.isActiveHere) return 0;
      return a.isActiveHere ? -1 : 1;
    });
    final visible = cards.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '진행 중인 체인',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final c in visible)
          _ChainQuestCard(data: c),
        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ChainQuestCard extends ConsumerWidget {
  final _ChainCardData data;
  const _ChainQuestCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isActiveHere) {
      return _ActiveChainCard(data: data);
    }
    return _InactiveChainCard(data: data);
  }
}

/// 현재 리전에서 바로 파견 가능한 활성 체인 카드.
class _ActiveChainCard extends ConsumerWidget {
  final _ChainCardData data;

  const _ActiveChainCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: AppTheme.chainGold, width: 4),
          top: BorderSide(color: AppTheme.chainGold, width: 2),
          right: BorderSide(color: AppTheme.chainGold, width: 2),
          bottom: BorderSide(color: AppTheme.chainGold, width: 2),
        ),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.chainGold.withValues(alpha: 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.chainGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🔗 ${data.step.step}/${data.step.totalSteps}단계',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.chainGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.step.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              data.step.description,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final userData = ref.read(userDataProvider);
                  await ref
                      .read(questListProvider.notifier)
                      .injectChainStep(
                        data.step,
                        userData?.region ?? 1,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${data.step.name} 퀘스트가 파견 목록에 추가되었습니다'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.chainGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '파견 시작',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이동이 필요하거나 대기 중인 비활성 체인 카드.
class _InactiveChainCard extends ConsumerWidget {
  final _ChainCardData data;
  const _InactiveChainCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayMessage = data.isWaiting
        ? _buildWaitingMessage()
        : '📍 이동 필요';

    return Opacity(
      opacity: 0.6,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: AppTheme.chainGold.withValues(alpha: 0.5), width: 4),
            top: BorderSide(
                color: AppTheme.chainGold.withValues(alpha: 0.5), width: 1),
            right: BorderSide(
                color: AppTheme.chainGold.withValues(alpha: 0.5), width: 1),
            bottom: BorderSide(
                color: AppTheme.chainGold.withValues(alpha: 0.5), width: 1),
          ),
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data.step.chainName}  ${data.step.step}/${data.step.totalSteps}단계',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                overlayMessage,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (!data.isWaiting) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // 이동 탭 인덱스: 0 (이동/파견/홈/모집/시설/정보)
                      ref.read(currentTabProvider.notifier).state = 0;
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.chainGold,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '이동 화면으로',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildWaitingMessage() {
    final availableAt = data.progress.currentStepAvailableAt;
    if (availableAt == null) return '💭 대기 중';
    final remaining = availableAt.difference(DateTime.now());
    if (remaining.isNegative) return '💭 단서 공개 중';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) return '💭 $hours시간 $minutes분 후 다음 단서 공개';
    return '💭 $minutes분 후 다음 단서 공개';
  }
}

class _ChainCardData {
  final ChainQuestProgress progress;
  final ChainQuestData step;
  final bool isActiveHere;
  final bool isWaiting;

  const _ChainCardData({
    required this.progress,
    required this.step,
    required this.isActiveHere,
    required this.isWaiting,
  });
}
