import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_notifier.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_result.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_service.dart';

class InvestigationWidget extends ConsumerWidget {
  const InvestigationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    if (userData == null) return const SizedBox.shrink();

    final staticDataAsync = ref.watch(staticDataProvider);
    return staticDataAsync.maybeWhen(
      data: (staticData) {
        final regionId = userData.region;
        final hasDiscoveries =
            staticData.regionDiscoveries.any((d) => d.regionId == regionId);
        if (!hasDiscoveries) return const SizedBox.shrink();

        final repo = ref.read(regionStateRepositoryProvider);
        final regionState = repo.getState(regionId);
        final knowledge = regionState?.knowledge ?? 0;

        // 조사 진행 중
        if (userData.investigatingMercId != null) {
          final mercs = ref.watch(mercenaryListProvider);
          final merc = mercs
              .where((m) => m.id == userData.investigatingMercId)
              .firstOrNull;
          final endTime = userData.investigationEndTime;
          final now = DateTime.now();
          final remaining =
              endTime != null ? endTime.difference(now) : Duration.zero;

          // 진행도: 지식 바 (현재 + 완료 후 예상치)
          final region = staticData.regions
              .where((r) => r.region == regionId)
              .firstOrNull;
          final tier = region?.regionTier ?? 1;
          final gainOnSuccess = InvestigationService.getKnowledgeGain(tier);
          final expectedKnowledge = (knowledge + gainOnSuccess).clamp(0, 100);

          final remainStr = remaining.isNegative
              ? '완료 대기'
              : remaining.inMinutes > 0
                  ? '${remaining.inMinutes}분 ${remaining.inSeconds.remainder(60)}초'
                  : '${remaining.inSeconds}초';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.tier2Bg,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.tier2.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔍 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        '${merc?.name ?? '용병'} — 조사 중',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.tier2,
                        ),
                      ),
                    ),
                    Text(
                      remainStr,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.tier2),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: expectedKnowledge / 100.0,
                              minHeight: 3,
                              backgroundColor: AppTheme.borderLight,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppTheme.tier2),
                            ),
                          ),
                          // 현재 지식 마커
                          if (knowledge > 0)
                            FractionallySizedBox(
                              widthFactor: knowledge / 100.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: 1.0,
                                  minHeight: 3,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          AppTheme.tier2
                                              .withValues(alpha: 0.9)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '지식 $knowledge → $expectedKnowledge/100',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.tier2),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // 조사 완료 (knowledge == 100)
        if (knowledge >= 100) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.tier2Bg,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.tier2.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Text('✅ ', style: TextStyle(fontSize: 12)),
                Text(
                  '이 지역의 모든 발견 완료',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tier2,
                  ),
                ),
              ],
            ),
          );
        }

        // 조사 대기 중 (knowledge < 100)
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.tier2Bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.tier2.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('🔍 ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  '지역 조사 가능 (지식 $knowledge/100)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tier2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showMercenarySelectSheet(context, ref, regionId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tier2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '조사 시작',
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
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

void _showMercenarySelectSheet(
    BuildContext context, WidgetRef ref, int regionId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _MercenarySelectSheet(regionId: regionId),
  );
}

class _MercenarySelectSheet extends ConsumerWidget {
  final int regionId;

  const _MercenarySelectSheet({required this.regionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercs = ref.watch(mercenaryListProvider);
    final userData = ref.watch(userDataProvider);
    final staticDataAsync = ref.watch(staticDataProvider);

    final candidates = mercs.where((m) =>
        m.status != MercenaryStatus.dead &&
        !m.isDispatched &&
        m.id != userData?.investigatingMercId).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '조사할 용병 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: candidates.isEmpty
                ? const Center(
                    child: Text(
                      '파견 가능한 용병이 없습니다',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: candidates.length,
                    itemBuilder: (_, i) {
                      final merc = candidates[i];
                      final successRate =
                          InvestigationService.calculateSuccessRate(
                              merc.effectiveAgi, merc.effectiveVit);
                      final jobName = staticDataAsync.maybeWhen(
                        data: (sd) =>
                            sd.jobs
                                .where((j) => j.id == merc.jobId)
                                .firstOrNull
                                ?.name ??
                            merc.jobId,
                        orElse: () => merc.jobId,
                      );
                      return ListTile(
                        onTap: () {
                          ref
                              .read(investigationNotifierProvider.notifier)
                              .startInvestigation(merc.id, regionId);
                          Navigator.pop(context);
                        },
                        title: Text(
                          merc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          jobName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'AGI ${merc.effectiveAgi} / VIT ${merc.effectiveVit}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                            Text(
                              '성공률 ${successRate.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tier2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class InvestigationResultDialog extends StatelessWidget {
  final InvestigationResult result;
  final String mercName;

  const InvestigationResultDialog({
    super.key,
    required this.result,
    required this.mercName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        result.success ? '조사 완료' : '조사 실패',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: result.success ? AppTheme.tier2 : AppTheme.failure,
        ),
      ),
      content: _DialogContent(result: result, mercName: mercName),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _DialogContent extends ConsumerWidget {
  final InvestigationResult result;
  final String mercName;

  const _DialogContent({required this.result, required this.mercName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!result.success) {
      final msg = result.mercInjured
          ? '$mercName이(가) 부상당했습니다'
          : '지식 미획득';
      return Text(
        '조사 실패 — $msg',
        style: const TextStyle(color: AppTheme.textPrimary),
      );
    }

    // 성공 — 발견 없음
    if (result.newDiscoveryIds.isEmpty) {
      return Text(
        '조사 완료 — 지식 +${result.knowledgeGained} (현재 ${result.currentKnowledge}/100)',
        style: const TextStyle(color: AppTheme.textPrimary),
      );
    }

    // 성공 + 새 발견
    final staticDataAsync = ref.watch(staticDataProvider);
    final descriptions = staticDataAsync.maybeWhen(
      data: (sd) => result.newDiscoveryIds
          .map((id) =>
              sd.regionDiscoveries
                  .where((d) => d.id == id)
                  .firstOrNull
                  ?.description ??
              id)
          .toList(),
      orElse: () => result.newDiscoveryIds,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '조사 완료 — 지식 +${result.knowledgeGained} (현재 ${result.currentKnowledge}/100)',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          '새로운 발견:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.tier2,
          ),
        ),
        const SizedBox(height: 4),
        ...descriptions.map(
          (desc) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(color: AppTheme.tier2)),
                Expanded(
                  child: Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
