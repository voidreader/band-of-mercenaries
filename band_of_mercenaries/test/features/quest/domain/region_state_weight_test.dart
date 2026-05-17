import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/region_state_effect.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';

QuestPool _buildPool({
  required String id,
  required String typeId,
  required double difficulty,
  bool isNamed = false,
  RegionStateEffect? effect,
  String? required,
  String? excluded,
}) {
  return QuestPool(
    id: id,
    name: id,
    type: 0,
    difficulty: difficulty,
    minRegionDiff: 1,
    maxRegionDiff: 1,
    typeId: typeId,
    isNamed: isNamed,
    regionStateEffect: effect,
    regionStateRequired: required,
    regionStateExcluded: excluded,
  );
}

RegionState _buildState({
  required int regionId,
  int? dangerLevel,
  List<String>? unlockedFlags,
}) {
  return RegionState(
    regionId: regionId,
    dangerLevel: dangerLevel,
    unlockedFlags: unlockedFlags,
  );
}

void main() {
  group('QuestGenerator.computeFinalWeight', () {
    test('시나리오 1 — region 31 stable + bandits_cleared = 2.25', () {
      final pool = _buildPool(id: 'qp_test', typeId: 'escort', difficulty: 2);
      final state = _buildState(
        regionId: 31,
        dangerLevel: DangerLevel.stable.cacheInt,
        unlockedFlags: ['region_31_bandits_cleared'],
      );
      final weight = QuestGenerator.computeFinalWeight(
        pool: pool,
        regionState: state,
        gate: NewbieGate.normal,
      );
      // NewbieGate.normal(1.0) × stable escort(1.5) × flag escort(1.5) = 2.25
      expect(weight, closeTo(2.25, 0.001));
    });

    test('시나리오 2 — region 38 threat raid = 3.0', () {
      final pool = _buildPool(id: 'qp_test', typeId: 'raid', difficulty: 3);
      final state = _buildState(
        regionId: 38,
        dangerLevel: DangerLevel.threat.cacheInt,
        unlockedFlags: [],
      );
      final weight = QuestGenerator.computeFinalWeight(
        pool: pool,
        regionState: state,
        gate: NewbieGate.normal,
      );
      // NewbieGate.normal(1.0) × threat raid(3.0) = 3.0
      expect(weight, closeTo(3.0, 0.001));
    });

    test('시나리오 3 — region_state_required 불일치 = 0.0', () {
      final pool = _buildPool(
        id: 'qp_test',
        typeId: 'raid',
        difficulty: 2,
        required: 'threat',
      );
      final state = _buildState(
        regionId: 9,
        dangerLevel: DangerLevel.peaceful.cacheInt,
      );
      final weight = QuestGenerator.computeFinalWeight(
        pool: pool,
        regionState: state,
        gate: NewbieGate.normal,
      );
      expect(weight, equals(0.0));
    });

    test('시나리오 4 — cumulative cap 도달 후 0.2× 축소', () {
      final pool = _buildPool(
        id: 'qp_test',
        typeId: 'raid',
        difficulty: 2,
        effect: const CumulativeEffect(
          deltaPerCompletion: -10,
          capPerThreshold: -50,
          thresholdFlag: 'region_31_bandits_cleared',
        ),
      );
      final state = _buildState(
        regionId: 31,
        dangerLevel: DangerLevel.stable.cacheInt,
        unlockedFlags: ['region_31_bandits_cleared'],
      );
      final weight = QuestGenerator.computeFinalWeight(
        pool: pool,
        regionState: state,
        gate: NewbieGate.normal,
      );
      // NewbieGate.normal(1.0) × stable raid(0.3) × flag raid(0.3) × cap(0.2) = 0.018
      expect(weight, closeTo(0.018, 0.001));
    });

    test('시나리오 5 — regionState=null fallback peaceful = 1.0', () {
      final pool = _buildPool(id: 'qp_test', typeId: 'raid', difficulty: 1);
      final weight = QuestGenerator.computeFinalWeight(
        pool: pool,
        regionState: null,
        gate: NewbieGate.normal,
      );
      // NewbieGate.normal(1.0) × peaceful raid(1.0) = 1.0
      expect(weight, closeTo(1.0, 0.001));
    });

    test('시나리오 6 (보너스) — 지명 의뢰 +3.0 가산', () {
      final pool = _buildPool(id: 'qp_test', typeId: 'escort', difficulty: 1, isNamed: true);
      final state = _buildState(
        regionId: 3,
        dangerLevel: DangerLevel.peaceful.cacheInt,
      );
      final weight = QuestGenerator.computeFinalWeight(
        pool: pool,
        regionState: state,
        gate: NewbieGate.normal,
      );
      // NewbieGate.normal(1.0) × peaceful escort(1.2) + named(+3.0) = 4.2
      expect(weight, closeTo(4.2, 0.001));
    });
  });
}
