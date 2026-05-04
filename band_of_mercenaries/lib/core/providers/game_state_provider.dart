import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/reputation_rank_up_provider.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_completion_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  return UserDataNotifier(ref);
});

class UserDataNotifier extends StateNotifier<UserData?> {
  final Ref ref;
  bool _isCompletingConstruction = false;

  UserDataNotifier(this.ref) : super(null) {
    _load();
  }

  // HiveObject를 in-place 변경 후 state = state 할당 시 identical() 체크로 알림이
  // 발생하지 않는 문제를 방지하기 위해 항상 notify.
  @override
  bool updateShouldNotify(UserData? old, UserData? current) => true;

  void _load() {
    final box = Hive.box<UserData>(HiveInitializer.userBoxName);
    if (box.isNotEmpty) {
      state = box.getAt(0);
      _checkPastConstruction();
      _checkPastInvestigation();
    }
  }

  void _checkPastConstruction() {
    if (state == null || state!.constructionEndTime == null) return;
    if (DateTime.now().isAfter(state!.constructionEndTime!)) {
      completeConstruction();
    }
  }

  void _checkPastInvestigation() {
    // 실제 완료 처리는 InvestigationNotifier.checkCompletion에서 수행
  }

  void refresh() => _load();

  Future<void> initializeNewGame() async {
    debugPrint('[BOM][GameState] initializeNewGame 시작');
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) {
      debugPrint('[BOM][GameState] initializeNewGame 중단: staticData null');
      return;
    }

    final random = Random();
    // 시작 거점 고정: region 3 (더스트플레인) / sector 1
    final startRegion = staticData.regions.firstWhere(
      (r) => r.region == GameConstants.startingRegionId,
      orElse: () => throw StateError(
        'region ${GameConstants.startingRegionId} 누락 — 마이그레이션 미적용',
      ),
    );
    final startSector = GameConstants.startingSector;

    final userData = UserData(
      gold: GameConstants.startingGold,
      region: startRegion.region,
      sector: startSector,
      lastFreeRecruit: DateTime.now().subtract(GameConstants.freeRecruitCooldown),
      createdAt: DateTime.now(),
    );

    final box = Hive.box<UserData>(HiveInitializer.userBoxName);
    await box.clear();
    await box.add(userData);

    // 시작 용병 생성 — state 갱신 전에 완료해야 mercenaryListProvider._load()가 정상 데이터를 읽음
    final mercBox = Hive.box<Mercenary>(HiveInitializer.mercenaryBoxName);
    await mercBox.clear();
    final startingMercs = RecruitmentService.generateStartingMercenaries(
      jobs: staticData.jobs,
      traits: staticData.traits,
      categories: staticData.traitCategories,
      names: staticData.personNames,
      count: 4,
      random: random,
    );
    for (final merc in startingMercs) {
      await mercBox.add(merc);
    }
    debugPrint('[BOM][GameState] 시작 용병 ${startingMercs.length}명 Hive 저장 완료');

    // 초기 퀘스트 생성 — state 갱신 전에 완료해야 questListProvider._load()가 비어있지 않음
    // 시작 풀 6슬롯 분포 (페이즈 4 #3 데이터 의존):
    // - 슬롯 1: 활성 체인 step 1 (region 3 활성화 시 ChainQuestService.tryActivate → injectChainStep)
    //   chain_quests 데이터 미반영 시 일반 풀 난이도 1 1건으로 fallback
    // - 슬롯 2~5: 더스트빌 허드렛일 4건 (난이도 1 / region 3 매칭 풀)
    // - 슬롯 6: 난이도 2 1건 (region 3 매칭 풀)
    // 페이즈 4 #3 미반영 환경에서는 QuestGenerator 기존 알고리즘으로 채움
    final questBox = Hive.box<ActiveQuest>(HiveInitializer.questBoxName);
    await questBox.clear();
    final initialQuests = QuestGenerator.generateQuests(
      regionTier: startRegion.regionTier,
      regionId: startRegion.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: GameConstants.baseQuestCount,
      random: random,
      joinedFactionIds: const [],
      factionReputations: const {},
      clueLevelsInRegion: const {},
      cooldownExclusiveQuestIds: const {},
      activeSlotCount: GameConstants.baseQuestCount,
      eliteMonsters: staticData.eliteMonsters,
      regionEnvironmentTags: startRegion.environmentTags,
      currentSectorIndex: startSector - 1,
    );
    for (final quest in initialQuests) {
      await questBox.add(quest);
    }
    debugPrint('[BOM][GameState] 초기 퀘스트 ${initialQuests.length}개 Hive 저장 완료');

    // M4 MVP 더스트빌 거점 사건 자동 활성화
    final regionRepo = ref.read(regionStateRepositoryProvider);
    if (regionRepo.getState(GameConstants.startingRegionId) == null) {
      await regionRepo.saveState(RegionState(
        regionId: GameConstants.startingRegionId,
        settlementTrust: 0,
        settlementTrustLevel: 1,
      ));
    }
    await ref.read(chainQuestServiceProvider).tryActivateSettlement(
      regionId: GameConstants.startingRegionId,
      eventName: 'pyegwang_reopen',
      user: userData,
    );

    // 모든 Hive 데이터 준비 완료 후 state 갱신 → _PostSyncApp 리빌드 트리거
    debugPrint('[BOM][GameState] initializeNewGame 완료 → state 갱신 (고정 region ${GameConstants.startingRegionId} 더스트플레인, sector: $startSector)');
    state = userData;
  }

  Future<void> addGold(int amount) async {
    if (state == null) return;
    state!.gold += amount;
    await state!.save();
    state = state;
  }

  Future<void> spendGold(int amount) async {
    if (state == null || state!.gold < amount) return;
    state!.gold -= amount;
    await state!.save();
    state = state;
  }

  Future<void> addReputation(int amount) async {
    if (state == null) return;
    if (amount == 0) return;

    final ranks = ref.read(staticDataProvider).valueOrNull?.ranks ?? const <Rank>[];
    final oldLevel = ranks.isEmpty
        ? -1
        : ReputationService.getRankLevel(state!.reputation, ranks);

    state!.reputation = (state!.reputation + amount).clamp(0, 9999999);
    await state!.save();
    state = state;

    if (ranks.isEmpty) return;
    final newLevel = ReputationService.getRankLevel(state!.reputation, ranks);

    if (newLevel > oldLevel && oldLevel >= 0) {
      final sortedRanks = [...ranks]
        ..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
      final oldRank = sortedRanks[oldLevel];
      final newRank = sortedRanks[newLevel];
      final newEffects = PassiveEffect.parseEffects(newRank.bonusJson);
      ref.read(reputationRankUpProvider.notifier).state =
          RankUpEvent(from: oldRank, to: newRank, newEffects: newEffects);
      ref.read(activityLogProvider.notifier).addLog(
        '명성 상승: ${oldRank.grade} → ${newRank.grade} (${newRank.name})',
        ActivityLogType.reputationRankUp,
      );
    } else if (newLevel < oldLevel && oldLevel >= 0) {
      final sortedRanks = [...ranks]
        ..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
      ref.read(activityLogProvider.notifier).addLog(
        '명성 하락: ${sortedRanks[oldLevel].grade} → ${sortedRanks[newLevel].grade}',
        ActivityLogType.reputationRankDown,
      );
    }
  }

  Future<bool> upgradeFacility(String facilityId, int cost) async {
    if (state == null || state!.gold < cost) return false;
    state!.gold -= cost;
    state!.facilities[facilityId] = (state!.facilities[facilityId] ?? 0) + 1;
    await state!.save();
    state = state;
    return true;
  }

  Future<void> recordFreeRecruit() async {
    if (state == null) return;
    state!.lastFreeRecruit = DateTime.now();
    await state!.save();
    state = state;
  }

  Future<bool> startConstruction(String facilityId, int cost, Duration buildDuration) async {
    if (state == null || state!.constructionFacilityId != null) return false;
    if (state!.gold < cost) return false;
    state!.gold -= cost;
    state!.constructionFacilityId = facilityId;
    state!.constructionStartTime = DateTime.now();
    state!.constructionEndTime = DateTime.now().add(buildDuration);
    await state!.save();
    state = state;
    return true;
  }

  Future<void> completeConstruction() async {
    if (state == null || state!.constructionFacilityId == null) return;
    if (_isCompletingConstruction) return;
    _isCompletingConstruction = true;
    try {
      final facilityId = state!.constructionFacilityId!;
      debugPrint('[BOM][GameState] 건설 완료: $facilityId Lv.${(state!.facilities[facilityId] ?? 0) + 1}');
      state!.facilities[facilityId] = (state!.facilities[facilityId] ?? 0) + 1;
      state!.constructionFacilityId = null;
      state!.constructionStartTime = null;
      state!.constructionEndTime = null;
      await state!.save();
      state = state;
      ref.read(constructionCompletedProvider.notifier).state = facilityId;
    } finally {
      _isCompletingConstruction = false;
    }
  }

  Future<void> cancelConstruction(int refundGold) async {
    if (state == null || state!.constructionFacilityId == null) return;
    state!.gold += refundGold;
    state!.constructionFacilityId = null;
    state!.constructionStartTime = null;
    state!.constructionEndTime = null;
    await state!.save();
    state = state;
  }

  void recalculateConstructionTimer(double oldSpeed, double newSpeed) {
    if (state == null || state!.constructionEndTime == null) return;
    final now = DateTime.now();
    final remaining = state!.constructionEndTime!.difference(now);
    if (remaining.isNegative) return;
    final adjustedRemaining = Duration(
      milliseconds: (remaining.inMilliseconds * oldSpeed / newSpeed).round(),
    );
    state!.constructionEndTime = now.add(adjustedRemaining);
    state!.save();
    state = state;
  }

  void checkConstructionCompletion() {
    if (state == null || state!.constructionEndTime == null) return;
    if (_isCompletingConstruction) return;
    if (DateTime.now().isAfter(state!.constructionEndTime!)) {
      completeConstruction();
    }
  }

  Future<bool> startInvestigation(String mercId, DateTime endTime, int regionId) async {
    if (state == null || state!.investigatingMercId != null) return false;
    state!.investigatingMercId = mercId;
    state!.investigationEndTime = endTime;
    state!.investigationRegionId = regionId;
    await state!.save();
    state = state;
    return true;
  }

  Future<void> clearInvestigation() async {
    if (state == null) return;
    state!.investigatingMercId = null;
    state!.investigationEndTime = null;
    state!.investigationRegionId = null;
    await state!.save();
    state = state;
  }

  /// 용병단 깃발 슬롯 장착/해제. null이면 해제.
  Future<void> setGuildBanner(String? itemId) async {
    if (state == null) return;
    state!.bannerItemId = itemId;
    await state!.save();
    state = state;
  }

  /// 용병단 유물 슬롯(0 또는 1) 장착/해제. null이면 해당 슬롯 해제.
  /// 동일 itemId가 다른 슬롯에 이미 장착되어 있으면 해당 슬롯을 null로 비운 뒤 타겟 슬롯에 삽입(중복 방지).
  /// artifactItemIds는 길이 0~2의 리스트로 유지. null 슬롯은 리스트에서 제외(compact).
  Future<void> setGuildArtifact(int slotIndex, String? itemId) async {
    assert(slotIndex == 0 || slotIndex == 1, 'slotIndex must be 0 or 1');
    if (state == null) return;

    // 현재 리스트를 [slot0, slot1] 길이 2 고정 배열로 변환 (부족한 자리는 null)
    final slots = <String?>[null, null];
    for (int i = 0; i < state!.artifactItemIds.length && i < 2; i++) {
      slots[i] = state!.artifactItemIds[i];
    }

    // 동일 itemId가 다른 슬롯에 있으면 제거
    if (itemId != null) {
      for (int i = 0; i < 2; i++) {
        if (i != slotIndex && slots[i] == itemId) {
          slots[i] = null;
        }
      }
    }

    // 타겟 슬롯 치환
    slots[slotIndex] = itemId;

    // compact: null을 제외하고 저장
    state!.artifactItemIds = slots.whereType<String>().toList();
    await state!.save();
    state = state;
  }

  Future<void> addCompletedChain(String chainId) async {
    if (state == null) return;
    if (state!.completedChains.contains(chainId)) return;
    state!.completedChains = [...state!.completedChains, chainId];
    await state!.save();
    state = state;
  }

  void recalculateInvestigationTimer(double oldSpeed, double newSpeed) {
    if (state == null || state!.investigationEndTime == null) return;
    final now = DateTime.now();
    final remaining = state!.investigationEndTime!.difference(now);
    if (remaining.isNegative) return;
    final adjustedRemaining = Duration(
      milliseconds: (remaining.inMilliseconds * oldSpeed / newSpeed).round(),
    );
    state!.investigationEndTime = now.add(adjustedRemaining);
    state!.save();
    state = state;
  }
}
