import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/domain/info_screen_auto_show_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_goal_provider.dart';
import 'package:band_of_mercenaries/features/info/view/widgets/goal_card.dart';
import 'package:band_of_mercenaries/features/info/view/widgets/metric_expansion_card.dart';
import 'package:band_of_mercenaries/features/movement/domain/livingsphere_movement_target_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_facility_target_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

/// 생활권 대시보드 상세 화면 — 6 펼침 지표 카드 + 2 목표 카드.
/// InfoScreen에서 상태 기반 렌더링으로 진입 (Navigator.push 미사용).
class LivingsphereDetailScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const LivingsphereDetailScreen({super.key, required this.onBack});

  @override
  ConsumerState<LivingsphereDetailScreen> createState() =>
      _LivingsphereDetailScreenState();
}

class _LivingsphereDetailScreenState
    extends ConsumerState<LivingsphereDetailScreen> {
  /// 6 지표 펼침 상태 — SessionState (영속 X, 화면 dispose 시 초기화).
  final Map<MetricKey, bool> _expandedMap = {
    for (final key in MetricKey.values) key: false,
  };

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(livingsphereDashboardProvider);
    final shortGoal = ref.watch(livingsphereGoalProvider(GoalSlot.short30Min));
    final longGoal = ref.watch(livingsphereGoalProvider(GoalSlot.long8Hour));
    final userData = ref.watch(userDataProvider);

    // FR-11: invalidatedPinId post-frame cleanup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shortGoal.invalidatedPinId != null) {
        ref.read(userDataProvider.notifier).setShortGoalPin(null);
      }
      if (longGoal.invalidatedPinId != null) {
        ref.read(userDataProvider.notifier).setLongGoalPin(null);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderBar(
          totalCompletionPct: snapshot.totalCompletionPct,
          onBack: widget.onBack,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // 6 펼침 카드
              for (final key in MetricKey.values)
                MetricExpansionCard(
                  metricKey: key,
                  value: snapshot.metrics[key]!,
                  expanded: _expandedMap[key] ?? false,
                  onToggle: () => setState(() {
                    _expandedMap[key] = !(_expandedMap[key] ?? false);
                  }),
                  jumpActions: _buildJumpActions(key, userData),
                ),
              const SizedBox(height: 8),
              // 30분 목표 카드
              GoalCard(
                recommendation: shortGoal,
                onPinToggle: () =>
                    _togglePin(GoalSlot.short30Min, shortGoal),
              ),
              // 8시간 목표 카드
              GoalCard(
                recommendation: longGoal,
                onPinToggle: () => _togglePin(GoalSlot.long8Hour, longGoal),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 점프 액션 빌더 — MetricKey별 jumpActions 결정 (FR-17 §4.4 매핑)
  // ===========================================================================
  List<MetricJumpAction> _buildJumpActions(MetricKey key, UserData? userData) {
    switch (key) {
      case MetricKey.stability:
        return [
          MetricJumpAction(
            label: '이동 화면',
            onTap: () {
              ref.read(livingsphereMovementTargetProvider.notifier).state = 3;
              ref.read(currentTabProvider.notifier).state = 0;
            },
          ),
        ];
      case MetricKey.infrastructure:
        return [
          MetricJumpAction(
            label: '촌장 집',
            onTap: () {
              ref.read(livingsphereMovementTargetProvider.notifier).state = 3;
              ref.read(settlementFacilityTargetProvider.notifier).state =
                  VillageFacility.chiefHouse;
              ref.read(currentTabProvider.notifier).state = 0;
            },
          ),
        ];
      case MetricKey.eventCompletion:
        return [
          MetricJumpAction(
            label: '파견 화면',
            onTap: () {
              ref.read(currentTabProvider.notifier).state = 1;
            },
          ),
        ];
      case MetricKey.resourceCraft:
        return [
          MetricJumpAction(
            label: '인벤토리 재료',
            onTap: () {
              ref.read(infoScreenAutoShowInventoryProvider.notifier).state =
                  true;
              ref.read(currentTabProvider.notifier).state = 5;
            },
          ),
          MetricJumpAction(
            label: '대장간',
            onTap: () {
              ref.read(livingsphereMovementTargetProvider.notifier).state = 3;
              ref.read(settlementFacilityTargetProvider.notifier).state =
                  VillageFacility.oldSmithy;
              ref.read(currentTabProvider.notifier).state = 0;
            },
          ),
        ];
      case MetricKey.influence:
        return [
          MetricJumpAction(
            label: '세력 도감',
            onTap: () {
              ref.read(infoScreenAutoShowCodexProvider.notifier).state = true;
              ref.read(currentTabProvider.notifier).state = 5;
            },
          ),
        ];
      case MetricKey.achievement:
        return [
          MetricJumpAction(
            label: '연대기',
            onTap: () {
              ref.read(infoScreenAutoShowChronicleProvider.notifier).state =
                  true;
              ref.read(currentTabProvider.notifier).state = 5;
            },
          ),
        ];
    }
  }

  // ===========================================================================
  // 핀 토글 — primary candidate ID 기준으로 고정/해제
  // ===========================================================================
  void _togglePin(GoalSlot slot, GoalRecommendation recommendation) {
    final userData = ref.read(userDataProvider);
    if (userData == null) return;

    final currentPinId = slot == GoalSlot.short30Min
        ? userData.shortGoalPinId
        : userData.longGoalPinId;
    final primaryId = recommendation.primary?.id;

    if (primaryId == null) return;

    final notifier = ref.read(userDataProvider.notifier);
    if (currentPinId == primaryId) {
      // 핀 해제
      if (slot == GoalSlot.short30Min) {
        notifier.setShortGoalPin(null);
      } else {
        notifier.setLongGoalPin(null);
      }
    } else {
      // 핀 고정
      if (slot == GoalSlot.short30Min) {
        notifier.setShortGoalPin(primaryId);
      } else {
        notifier.setLongGoalPin(primaryId);
      }
    }
  }
}

/// 헤더 바 — 뒤로가기 버튼 + 지역명 + 통합 완성도 %.
class _HeaderBar extends StatelessWidget {
  final double totalCompletionPct;
  final VoidCallback onBack;

  const _HeaderBar({required this.totalCompletionPct, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: onBack,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: '뒤로가기',
          ),
          const SizedBox(width: 4),
          const Text(
            '🏘️ 더스트플레인 생활권',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            '완성도 ${totalCompletionPct.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
