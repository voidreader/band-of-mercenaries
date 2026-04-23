import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/elite_monster_data.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/faction_tag_resolver.dart';

class QuestGenerator {
  static const _uuid = Uuid();

  static List<ActiveQuest> generateQuests({
    required int regionTier,
    required int regionId,
    required List<QuestPool> questPools,
    required List<QuestType> questTypes,
    required int count,
    required Random random,
    required List<String> joinedFactionIds,
    required Map<String, int> factionReputations,
    required Map<String, int> clueLevelsInRegion,
    required Set<String> cooldownExclusiveQuestIds,
    required int activeSlotCount,
    int proximityTier = 3,
    List<String> hostileFactionIds = const [],
    List<EliteMonsterData> eliteMonsters = const [],
    List<String> regionEnvironmentTags = const [],
    Set<String> triggeredDiscoveries = const {},
  }) {
    // 1. 기본 티어 필터
    final filtered = questPools
        .where((p) => p.minRegionDiff <= regionTier && p.maxRegionDiff >= regionTier)
        .toList();
    if (filtered.isEmpty) return [];

    // 2. 전용/일반 분리
    final exclusivePools = filtered.where((p) => p.isFactionExclusive).toList();
    final generalPools = filtered.where((p) => !p.isFactionExclusive).toList();

    // 3. 전용 퀘스트 후보 필터링
    final eligibleExclusive = exclusivePools.where((p) =>
        p.factionTag != null &&
        joinedFactionIds.contains(p.factionTag) &&
        !hostileFactionIds.contains(p.factionTag) &&
        (factionReputations[p.factionTag] ?? 0) >= p.minReputation &&
        !cooldownExclusiveQuestIds.contains(p.id)).toList();
    eligibleExclusive.shuffle(random);

    // 4. 전용 노출 상한 계산
    int exclusiveCap = min(joinedFactionIds.length * 2, (activeSlotCount * 0.5).floor());
    exclusiveCap = min(exclusiveCap, count);
    final selectedExclusivePools = eligibleExclusive.take(exclusiveCap).toList();

    // 5. 일반 퀘스트 채우기
    final remainingCount = count - selectedExclusivePools.length;
    generalPools.shuffle(random);
    final selectedGeneralPools = generalPools.take(remainingCount).toList();

    // 6. ActiveQuest 생성
    final results = <ActiveQuest>[];

    // 전용 퀘스트
    for (final pool in selectedExclusivePools) {
      final isAdvanced = pool.minReputation >= 61;
      final repReward = isAdvanced ? (8 + random.nextInt(3)) : (5 + random.nextInt(3));
      final questType = questTypes.firstWhere(
        (t) => t.id == pool.typeId,
        orElse: () => questTypes.first,
      );
      results.add(ActiveQuest(
        id: _uuid.v4(),
        questPoolId: pool.id,
        questTypeId: questType.id,
        difficulty: pool.difficulty.round(),
        region: regionId,
        questName: pool.name,
        createdAt: DateTime.now(),
        factionTag: pool.factionTag,
        reputationReward: repReward,
        isAdvancedTrack: isAdvanced,
      ));
    }

    // 일반 퀘스트
    for (final pool in selectedGeneralPools) {
      final tag = FactionTagResolver.resolve(
        regionId: regionId,
        joinedFactionIds: joinedFactionIds,
        clueLevelsInRegion: clueLevelsInRegion,
        hostileFactionIds: hostileFactionIds,
        proximityTier: proximityTier,
        random: random,
      );
      final repReward = tag != null ? FactionTagResolver.tagReputationGain(proximityTier) : null;
      final questType = questTypes.firstWhere(
        (t) => t.id == pool.typeId,
        orElse: () => questTypes.first,
      );
      results.add(ActiveQuest(
        id: _uuid.v4(),
        questPoolId: pool.id,
        questTypeId: questType.id,
        difficulty: pool.difficulty.round(),
        region: regionId,
        questName: pool.name,
        createdAt: DateTime.now(),
        factionTag: tag,
        reputationReward: repReward,
        isAdvancedTrack: null,
      ));
    }

    // 7. 엘리트 퀘스트 생성
    const maxEliteCount = 2;
    final normalCandidates = eliteMonsters
        .where((m) => !m.isUnique && m.environmentTags.any(regionEnvironmentTags.contains))
        .toList();
    final uniqueCandidates = eliteMonsters
        .where((m) => m.isUnique && triggeredDiscoveries.any((d) => d.endsWith('_${m.id}')))
        .toList();
    final eliteCandidates = [...normalCandidates, ...uniqueCandidates];
    int eliteGenerated = 0;
    for (final monster in eliteCandidates) {
      if (eliteGenerated >= maxEliteCount) break;
      if (random.nextDouble() < monster.spawnRate) {
        final questName = monster.isUnique
            ? '[유니크] ${monster.name}'
            : '[엘리트] ${monster.name}';
        results.add(ActiveQuest(
          id: _uuid.v4(),
          questPoolId: 'elite_${monster.id}',
          questTypeId: 'raid',
          difficulty: monster.tier,
          region: regionId,
          questName: questName,
          createdAt: DateTime.now(),
          eliteId: monster.id,
          status: QuestStatus.pending,
        ));
        eliteGenerated++;
      }
    }

    return results;
  }
}
