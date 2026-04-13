import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/view/behavior_stats_section.dart';

void main() {
  test('statLabelKo returns Korean label for known keys', () {
    expect(BehaviorStatsSection.statLabelKo('total_dispatch_count'), '총 파견');
    expect(BehaviorStatsSection.statLabelKo('consecutive_success'), '연속 성공');
  });

  test('statLabelKo returns key for unknown keys', () {
    expect(BehaviorStatsSection.statLabelKo('unknown_stat'), 'unknown_stat');
  });

  test('summarize picks 4 key stats', () {
    final stats = {
      'total_dispatch_count': 23,
      'success_count': 15,
      'consecutive_success': 3,
      'total_gold_earned': 5200,
      'failure_count': 8,
    };
    final summary = BehaviorStatsSection.summarize(stats);
    expect(summary.length, 4);
    expect(summary[0], contains('23'));
    expect(summary[1], contains('15'));
  });
}
