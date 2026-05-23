import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';

/// 펼침 가능 지표 카드 — LivingsphereDetailScreen에서 6 지표 표시.
/// 펼침 상태는 부모(StatefulWidget의 _expandedMap)가 관리 (세션 상태, 영속 불가).
class MetricExpansionCard extends StatelessWidget {
  final MetricKey metricKey;
  final MetricValue value;
  final bool expanded;
  final VoidCallback onToggle;

  /// 펼침 본문 점프 버튼 목록 (0~3개).
  final List<MetricJumpAction> jumpActions;

  const MetricExpansionCard({
    super.key,
    required this.metricKey,
    required this.value,
    required this.expanded,
    required this.onToggle,
    required this.jumpActions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _metricLabel(metricKey),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _resolveDisplayText(value),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (value.percent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _metricColor(metricKey, value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: expanded
                ? _buildExpandedBody(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((value.expandedSummary ?? '').isNotEmpty)
            Text(
              value.expandedSummary ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          if (jumpActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: jumpActions.map((action) {
                return TextButton(
                  onPressed: action.onTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 32),
                    backgroundColor: AppTheme.background,
                  ),
                  child: Text(
                    '→ ${action.label}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static String _metricLabel(MetricKey key) {
    switch (key) {
      case MetricKey.stability:
        return '안정도';
      case MetricKey.infrastructure:
        return '거점 발전';
      case MetricKey.eventCompletion:
        return '사건 완료';
      case MetricKey.resourceCraft:
        return '자원·제작';
      case MetricKey.influence:
        return '영향력';
      case MetricKey.achievement:
        return '위업';
    }
  }

  static String _resolveDisplayText(MetricValue value) {
    switch (value.displayMode) {
      case MetricDisplayMode.percent:
        return '${value.percent.toStringAsFixed(0)}%';
      case MetricDisplayMode.tierLevel:
        if (value.label != null) return value.label!;
        final cv = value.currentValue;
        return cv != null ? 'Tier ${cv.toInt()}' : 'Tier —';
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

  /// 지표 키별 진행 바 색상.
  /// stability는 percent 기반 4단계(dangerLevel 색상 재사용),
  /// 나머지는 지표 의미에 맞는 고정 색상.
  static Color _metricColor(MetricKey key, MetricValue value) {
    switch (key) {
      case MetricKey.stability:
        if (value.percent >= 90) return AppTheme.dangerLevelColor(1);
        if (value.percent >= 70) return AppTheme.dangerLevelColor(2);
        if (value.percent >= 30) return AppTheme.dangerLevelColor(3);
        return AppTheme.dangerLevelColor(4);
      case MetricKey.infrastructure:
        return AppTheme.settlementAccent;
      case MetricKey.eventCompletion:
        return AppTheme.chainGold;
      case MetricKey.resourceCraft:
        // material 전용 갈색 — AppTheme 미정의 fallback
        return const Color(0xFF8D6E63);
      case MetricKey.influence:
        return AppTheme.namedAccent;
      case MetricKey.achievement:
        return AppTheme.eliteUniqueBorder;
    }
  }
}

/// 지표 카드 펼침 본문의 점프 버튼 데이터.
class MetricJumpAction {
  final String label;
  final VoidCallback onTap;

  const MetricJumpAction({required this.label, required this.onTap});
}
