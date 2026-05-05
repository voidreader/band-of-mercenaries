import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';

void main() {
  // d1 30개 / d2 30개 / d3 30개, 모두 region_diff 1 매칭
  final pools = <QuestPool>[
    for (var i = 0; i < 30; i++)
      QuestPool(
        id: 'd1_$i',
        name: 'd1 의뢰 $i',
        type: 0,
        difficulty: 1,
        minRegionDiff: 1,
        maxRegionDiff: 1,
      ),
    for (var i = 0; i < 30; i++)
      QuestPool(
        id: 'd2_$i',
        name: 'd2 의뢰 $i',
        type: 0,
        difficulty: 2,
        minRegionDiff: 1,
        maxRegionDiff: 1,
      ),
    for (var i = 0; i < 30; i++)
      QuestPool(
        id: 'd3_$i',
        name: 'd3 의뢰 $i',
        type: 0,
        difficulty: 3,
        minRegionDiff: 1,
        maxRegionDiff: 1,
      ),
  ];

  final questTypes = [
    const QuestType(
        id: 'raid', name: '약탈', baseReward: 100, baseDuration: 60, riskFactor: 0.3),
  ];

  Map<int, int> runAndCount({
    required NewbieGate gate,
    required int trials,
    required int seed,
  }) {
    final random = Random(seed);
    final counts = <int, int>{1: 0, 2: 0, 3: 0};
    for (var i = 0; i < trials; i++) {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 3,
        questPools: pools,
        questTypes: questTypes,
        count: 6,
        random: random,
        joinedFactionIds: const [],
        factionReputations: const {},
        clueLevelsInRegion: const {},
        cooldownExclusiveQuestIds: const {},
        activeSlotCount: 6,
        gate: gate,
      );
      for (final q in quests) {
        counts[q.difficulty] = (counts[q.difficulty] ?? 0) + 1;
      }
    }
    return counts;
  }

  group('QuestGenerator newbie gate', () {
    test('newbieF: 모든 슬롯 d1만 등장', () {
      final counts = runAndCount(gate: NewbieGate.newbieF, trials: 100, seed: 1);
      expect(counts[2], 0, reason: 'F 단계는 d2 등장 X');
      expect(counts[3], 0, reason: 'F 단계는 d3 등장 X');
      expect(counts[1], greaterThan(0));
    });

    test('newbieE: d2 등장하지만 d3는 0', () {
      const trials = 200;
      final counts =
          runAndCount(gate: NewbieGate.newbieE, trials: trials, seed: 5);
      // d1 weight 30 × 1.0 = 30, d2 weight 30 × 0.25 = 7.5
      // 비복원 weighted sampling — 6슬롯 d2 평균 약 1.0 (풀 30개라 약간 더 많음)
      // 핵심: d3는 0, d2는 등장
      expect(counts[3], 0, reason: 'E 단계는 d3 등장 X');
      expect(counts[2], greaterThan(0), reason: 'E 단계는 d2 가끔 등장');
      // E 단계 d2 평균 비율 — 모집단이 30/30이므로 weight 30/(30+7.5) = 80% d1, 20% d2
      // 실험적으로 6슬롯 평균 d2는 약 1~1.5개
      final d2Ratio = (counts[2] ?? 0) / (trials * 6);
      expect(d2Ratio, inInclusiveRange(0.10, 0.30),
          reason: 'd2 슬롯 비율 10~30% 범위 (가중치 0.25 기반)');
    });

    test('normal: d1/d2/d3 모두 등장', () {
      final counts =
          runAndCount(gate: NewbieGate.normal, trials: 100, seed: 9);
      expect(counts[1], greaterThan(0));
      expect(counts[2], greaterThan(0));
      expect(counts[3], greaterThan(0));
    });

    test('normal weight 1/1/1은 균등 분포에 수렴 (각 difficulty ≈ 33%)', () {
      const trials = 300;
      final counts =
          runAndCount(gate: NewbieGate.normal, trials: trials, seed: 11);
      final total = counts.values.fold(0, (s, v) => s + v);
      final r1 = (counts[1] ?? 0) / total;
      final r2 = (counts[2] ?? 0) / total;
      final r3 = (counts[3] ?? 0) / total;
      // 3종 균등 — 각 약 33% (±5%p)
      expect(r1, inInclusiveRange(0.28, 0.38));
      expect(r2, inInclusiveRange(0.28, 0.38));
      expect(r3, inInclusiveRange(0.28, 0.38));
    });
  });
}
