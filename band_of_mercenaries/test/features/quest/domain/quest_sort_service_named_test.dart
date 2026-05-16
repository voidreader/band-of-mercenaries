import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_sort_service.dart';

QuestPool _pool({
  required String id,
  bool isNamed = false,
  bool isFactionExclusive = false,
  String? factionTag,
}) {
  return QuestPool(
    id: id,
    name: id,
    type: 1,
    difficulty: 2,
    minRegionDiff: 1,
    maxRegionDiff: 5,
    isNamed: isNamed,
    isFactionExclusive: isFactionExclusive,
    factionTag: factionTag,
  );
}

ActiveQuest _quest({required String poolId, String? factionTag, bool? isAdv}) {
  return ActiveQuest(
    id: poolId,
    questPoolId: poolId,
    questTypeId: 'raid',
    difficulty: 2,
    region: 1,
    questName: poolId,
    factionTag: factionTag,
    isAdvancedTrack: isAdv,
  );
}

void main() {
  final questTypes = [
    QuestType(
      id: 'raid',
      name: 'raid',
      baseReward: 100,
      baseDuration: 600,
      riskFactor: 1.0,
    ),
  ];

  test('named 1 + 일반 3 → namedTier sortedRest 최상단(settlement 다음)', () {
    final pools = [
      _pool(id: 'qp_named_x', isNamed: true),
      _pool(id: 'a'),
      _pool(id: 'b'),
      _pool(id: 'c'),
    ];
    final quests = [
      _quest(poolId: 'qp_named_x'),
      _quest(poolId: 'a'),
      _quest(poolId: 'b'),
      _quest(poolId: 'c'),
    ];
    final result = QuestSortService.sort(
      quests: quests,
      chainProgress: const [],
      currentRegion: 1,
      currentSector: 1,
      regionState: null,
      questPools: pools,
      questTypes: questTypes,
      joinedFactionIds: const {},
    );
    expect(result.sortedRest.first.questPoolId, 'qp_named_x');
    expect(result.namedTier.length, 1);
    expect(result.namedTier.first.questPoolId, 'qp_named_x');
  });

  test('named + faction(tier1) 혼재 → named가 faction보다 위', () {
    final pools = [
      _pool(id: 'qp_named_x', isNamed: true),
      _pool(id: 'qp_faction_x', isFactionExclusive: true, factionTag: 'f1'),
    ];
    final quests = [
      _quest(poolId: 'qp_faction_x', factionTag: 'f1', isAdv: false),
      _quest(poolId: 'qp_named_x'),
    ];
    final result = QuestSortService.sort(
      quests: quests,
      chainProgress: const [],
      currentRegion: 1,
      currentSector: 1,
      regionState: null,
      questPools: pools,
      questTypes: questTypes,
      joinedFactionIds: {'f1'},
    );
    final namedIdx = result.sortedRest.indexWhere(
      (q) => q.questPoolId == 'qp_named_x',
    );
    final factionIdx = result.sortedRest.indexWhere(
      (q) => q.questPoolId == 'qp_faction_x',
    );
    expect(namedIdx, lessThan(factionIdx));
  });

  test('named 0개 → 기존 동작 영향 없음', () {
    final pools = [_pool(id: 'a'), _pool(id: 'b')];
    final quests = [_quest(poolId: 'a'), _quest(poolId: 'b')];
    final result = QuestSortService.sort(
      quests: quests,
      chainProgress: const [],
      currentRegion: 1,
      currentSector: 1,
      regionState: null,
      questPools: pools,
      questTypes: questTypes,
      joinedFactionIds: const {},
    );
    expect(result.sortedRest.length, 2);
    expect(result.namedTier, isEmpty);
  });
}
