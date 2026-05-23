// M8.5 페이즈 4 #1 — 생활권 완성도 요약 카드 (홈 화면 노출)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/domain/info_screen_auto_show_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_goal_provider.dart';

/// 생활권 완성도 요약 카드 위젯 (홈 야영지 화면 배치)
class LivingsphereSummarySection extends ConsumerWidget {
  const LivingsphereSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    if (userData == null) return const SizedBox.shrink();

    final snapshot = ref.watch(livingsphereDashboardProvider);
    final shortGoal = ref.watch(livingsphereGoalProvider(GoalSlot.short30Min));
    final longGoal = ref.watch(livingsphereGoalProvider(GoalSlot.long8Hour));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Text(
                  '🏘️ 더스트플레인 생활권',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '완성도 ${snapshot.totalCompletionPct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 6 지표 미니 행
            ...MetricKey.values.map((key) {
              final value = snapshot.metrics[key];
              return _MetricMiniRow(
                label: _metricLabel(key),
                value: value,
                color: _metricColor(key, value),
              );
            }),

            const Divider(height: 16),

            // 30분 목표 행
            _GoalRow(prefix: '30분', goal: shortGoal),
            const SizedBox(height: 2),
            // 8시간 목표 행
            _GoalRow(prefix: '8시간', goal: longGoal),
            const SizedBox(height: 4),

            // 자세히 보기 버튼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ref
                      .read(infoScreenAutoShowLivingsphereProvider.notifier)
                      .state = true;
                  ref.read(currentTabProvider.notifier).state = 5;
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                ),
                child: const Text(
                  '자세히 보기 →',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MetricKey별 한국어 라벨 반환
  static String _metricLabel(MetricKey key) => switch (key) {
        MetricKey.stability => '안정도',
        MetricKey.infrastructure => '거점 발전',
        MetricKey.eventCompletion => '사건 완료',
        MetricKey.resourceCraft => '자원·제작',
        MetricKey.influence => '영향력',
        MetricKey.achievement => '위업',
      };

  /// MetricKey와 MetricValue를 기반으로 진행 바 색상 반환
  static Color _metricColor(MetricKey key, MetricValue? value) {
    switch (key) {
      case MetricKey.stability:
        // percent 기반 dangerLevel 역산하여 색상 매핑
        // stability_pct = clamp(((100 - dangerScore) / 200) * 100, 0, 100)
        // percent 90이상 → stable(1), 70이상 → peaceful(2), 30이상 → tension(3), else → threat(4)
        final pct = value?.percent ?? 0.0;
        if (pct >= 90) return AppTheme.dangerLevelColor(1);
        if (pct >= 70) return AppTheme.dangerLevelColor(2);
        if (pct >= 30) return AppTheme.dangerLevelColor(3);
        return AppTheme.dangerLevelColor(4);
      case MetricKey.infrastructure:
        return AppTheme.settlementAccent;
      case MetricKey.eventCompletion:
        return AppTheme.chainGold;
      case MetricKey.resourceCraft:
        // AppTheme에 materialAccent 미정의 → 갈색 계열 직접 사용
        return const Color(0xFF8D6E63);
      case MetricKey.influence:
        return AppTheme.namedAccent;
      case MetricKey.achievement:
        // AppTheme.uniqueAccent 미정의 → eliteUniqueBorder(0xFF7b1fa2) 사용
        return AppTheme.eliteUniqueBorder;
    }
  }
}

// =========================================================================
// 지표 미니 행 위젯 (private)
// =========================================================================

class _MetricMiniRow extends StatelessWidget {
  final String label;
  final MetricValue? value;
  final Color color;

  const _MetricMiniRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = value?.percent ?? 0.0;
    final displayText = _resolveDisplayText(value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: pct / 100.0,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveDisplayText(MetricValue? value) {
    if (value == null) return '—';
    switch (value.displayMode) {
      case MetricDisplayMode.percent:
        return '${value.percent.toStringAsFixed(0)}%';
      case MetricDisplayMode.tierLevel:
        final cv = value.currentValue;
        return cv != null ? 'Tier ${cv.toInt()}' : '—';
      case MetricDisplayMode.countOverTotal:
        final cv = value.currentValue;
        final tv = value.totalValue;
        if (cv != null && tv != null) {
          return '${cv.toInt()}/${tv.toInt()}';
        }
        return '—';
      case MetricDisplayMode.averageStage:
        return '${value.percent.toStringAsFixed(0)}%';
    }
  }
}

// =========================================================================
// 목표 행 위젯 (private)
// =========================================================================

class _GoalRow extends StatelessWidget {
  final String prefix;
  final GoalRecommendation goal;

  const _GoalRow({required this.prefix, required this.goal});

  @override
  Widget build(BuildContext context) {
    final label = goal.isFallback
        ? (goal.slot == GoalSlot.short30Min
            ? '다음 의뢰를 시작하세요'
            : '위업 컬렉션을 채워보세요')
        : (goal.primary?.label ?? '—');

    return Row(
      children: [
        const Text('🎯 ', style: TextStyle(fontSize: 12)),
        Text(
          '$prefix: ',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
