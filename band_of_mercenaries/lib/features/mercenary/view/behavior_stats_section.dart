import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class BehaviorStatsSection extends StatefulWidget {
  final Map<String, int> stats;

  const BehaviorStatsSection({super.key, required this.stats});

  static const Map<String, String> _labelMap = {
    'total_dispatch_count': '총 파견',
    'success_count': '성공',
    'failure_count': '실패',
    'great_success_count': '대성공',
    'great_failure_count': '대실패',
    'solo_dispatch_count': '솔로 파견',
    'team_dispatch_count': '팀 파견',
    'high_difficulty_count': '고난이도 성공',
    'low_difficulty_count': '저난이도 성공',
    'raid_count': '토벌',
    'hunt_count': '사냥',
    'escort_count': '호위',
    'explore_count': '탐색',
    'near_death_count': '아사 직전',
    'injury_count': '부상',
    'survived_great_failure': '대실패 생존',
    'tier_max_visited': '최고 티어 방문',
    'unique_region_count': '지역 탐험',
    'total_travel_distance': '총 이동거리',
    'total_gold_earned': '총 수입',
    'current_level': '현재 레벨',
    'consecutive_success': '연속 성공',
    'consecutive_failure': '연속 실패',
  };

  static String statLabelKo(String key) {
    return _labelMap[key] ?? key;
  }

  static List<String> summarize(Map<String, int> stats) {
    final totalDispatch = stats['total_dispatch_count'] ?? 0;
    final successCount = stats['success_count'] ?? 0;
    final consecutiveSuccess = stats['consecutive_success'] ?? 0;
    final totalGold = stats['total_gold_earned'] ?? 0;
    return [
      '파견 $totalDispatch회',
      '성공 $successCount회',
      '연속성공 $consecutiveSuccess',
      '금화 ${totalGold}G',
    ];
  }

  @override
  State<BehaviorStatsSection> createState() => _BehaviorStatsSectionState();
}

class _BehaviorStatsSectionState extends State<BehaviorStatsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = BehaviorStatsSection.summarize(widget.stats);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📊 행동 지표',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    _expanded ? '▲ 접기' : '▼ 펼치기',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: summary.map((item) {
                  return Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _buildExpandedGrid(),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedGrid() {
    final entries = BehaviorStatsSection._labelMap.entries.toList();

    return Column(
      children: List.generate(
        (entries.length / 2).ceil(),
        (rowIndex) {
          final leftIndex = rowIndex * 2;
          final rightIndex = leftIndex + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: _buildStatItem(entries[leftIndex])),
                if (rightIndex < entries.length)
                  Expanded(child: _buildStatItem(entries[rightIndex]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(MapEntry<String, String> entry) {
    final value = widget.stats[entry.key] ?? 0;
    return Row(
      children: [
        Text(
          '${entry.value}: ',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textHint,
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
