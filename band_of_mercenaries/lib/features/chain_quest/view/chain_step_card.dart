import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/models/chain_quest_data.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';

class ChainStepCard extends ConsumerWidget {
  final ChainQuestProgress progress;

  const ChainStepCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);

    return staticDataAsync.when(
      data: (staticData) {
        final chainStepData = staticData.chainQuests
            .where((c) => c.chainId == progress.chainId && c.step == progress.currentStep)
            .firstOrNull;

        if (chainStepData == null) return const SizedBox.shrink();

        final needsTravel = chainStepData.targetRegionId != null &&
            userData?.region != chainStepData.targetRegionId;

        final availableAt = progress.currentStepAvailableAt;
        final isWaiting =
            availableAt != null && availableAt.isAfter(DateTime.now());

        final isDormant = progress.status == ChainQuestStatus.dormant;

        String? protagonistName;
        if (progress.protagonistMercId != null) {
          final merc = mercs
              .where((m) => m.id == progress.protagonistMercId)
              .firstOrNull;
          protagonistName = merc?.name ?? progress.protagonistMercId;
        }

        String? regionName;
        if (chainStepData.targetRegionId != null) {
          final region = staticData.regions
              .where((r) => r.region == chainStepData.targetRegionId)
              .firstOrNull;
          regionName = region?.regionName ?? '리전 ${chainStepData.targetRegionId}';
        }

        return GestureDetector(
          onTap: () => _onTap(context, ref, isDormant, isWaiting, needsTravel, chainStepData, userData),
          child: Stack(
            children: [
              _ChainStepCardContent(
                chainStepData: chainStepData,
                protagonistName: protagonistName,
                currentStep: progress.currentStep,
              ),
              if (needsTravel || isWaiting || isDormant)
                _ChainStepCardOverlay(
                  needsTravel: needsTravel,
                  isWaiting: isWaiting,
                  isDormant: isDormant,
                  availableAt: availableAt,
                  regionName: regionName,
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    bool isDormant,
    bool isWaiting,
    bool needsTravel,
    ChainQuestData chainStepData,
    UserData? userData,
  ) async {
    if (isDormant) {
      await ref
          .read(chainQuestServiceProvider)
          .reactivateIfDormant(chainId: progress.chainId);
      return;
    }

    if (isWaiting) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아직 다음 단서가 드러나지 않았습니다')),
        );
      }
      return;
    }

    if (needsTravel) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 지역으로 이동 후 수행하세요')),
        );
      }
      return;
    }

    // 최종 단계 진입 전 인벤토리 여유 공간 체크 (FR-6)
    if (chainStepData.finalReward &&
        chainStepData.step == chainStepData.totalSteps) {
      final service = ref.read(chainQuestServiceProvider);
      if (userData != null &&
          !service.canAdvanceToFinal(
              finalStep: chainStepData, user: userData)) {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('최종 보상 수령 불가'),
              content: const Text(
                  '최종 보상을 받으려면 인벤토리에 여유 슬롯이 필요합니다.\n길드 장비 슬롯을 정리한 후 다시 시도하세요.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    // 활성 케이스: 파견 목록에 연계 단계 주입
    await ref.read(questListProvider.notifier).injectChainStep(
      chainStepData,
      userData?.region ?? 1,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${chainStepData.name} 퀘스트가 파견 목록에 추가되었습니다')),
      );
    }
  }
}

class _ChainStepCardContent extends StatelessWidget {
  final ChainQuestData chainStepData;
  final String? protagonistName;
  final int currentStep;

  const _ChainStepCardContent({
    required this.chainStepData,
    required this.protagonistName,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppTheme.tier3,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tier3Bg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppTheme.tier3.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            '🔗 연계',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.tier3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentStep/${chainStepData.totalSteps}단계',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chainStepData.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chainStepData.chainName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    if (protagonistName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '주인공: $protagonistName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.failureBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🛡️ 주인공의 운명',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.failure,
                        ),
                      ),
                    ),
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

class _ChainStepCardOverlay extends StatelessWidget {
  final bool needsTravel;
  final bool isWaiting;
  final bool isDormant;
  final DateTime? availableAt;
  final String? regionName;

  const _ChainStepCardOverlay({
    required this.needsTravel,
    required this.isWaiting,
    required this.isDormant,
    this.availableAt,
    this.regionName,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    if (isDormant) {
      message = '💤 휴면 상태 — 탭하여 재활성화';
    } else if (needsTravel) {
      final name = regionName ?? '해당 지역';
      message = '📍 $name으로 이동 필요';
    } else {
      final remaining = availableAt!.difference(DateTime.now());
      message = '💭 ${_formatDuration(remaining)} 후 다음 단서가 드러납니다';
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0분';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours시간 $minutes분';
    return '$minutes분';
  }
}
