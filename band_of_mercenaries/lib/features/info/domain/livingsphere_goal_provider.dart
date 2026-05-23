import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/goal_recommendation_service.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_provider.dart';

/// 30분/8시간 목표 추천 — gameTickProvider watch로 1초 재평가 (목표 시간 임박도 변화).
final livingsphereGoalProvider =
    Provider.family<GoalRecommendation, GoalSlot>((ref, slot) {
  ref.watch(gameTickProvider);
  final snapshot = ref.watch(livingsphereDashboardProvider);
  return GoalRecommendationService.recommendGoal(
    slot: slot,
    ref: ref,
    snapshot: snapshot,
  );
});
