import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_completion_provider.dart';

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  return UserDataNotifier(ref);
});

class UserDataNotifier extends StateNotifier<UserData?> {
  final Ref ref;
  bool _isCompletingConstruction = false;

  UserDataNotifier(this.ref) : super(null) {
    _load();
  }

  void _load() {
    final box = Hive.box<UserData>(HiveInitializer.userBoxName);
    if (box.isNotEmpty) {
      state = box.getAt(0);
      _checkPastConstruction();
    }
  }

  void _checkPastConstruction() {
    if (state == null || state!.constructionEndTime == null) return;
    if (DateTime.now().isAfter(state!.constructionEndTime!)) {
      completeConstruction();
    }
  }

  void refresh() => _load();

  Future<void> initializeNewGame() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final random = Random();
    final tier1Regions = staticData.regions.where((r) => r.regionTier == 1).toList();
    final startRegion = tier1Regions[random.nextInt(tier1Regions.length)];
    final startSector = random.nextInt(GameConstants.sectorCount) + 1;

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
    state = userData;

    // Generate starting mercenaries
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
    state!.reputation += amount;
    await state!.save();
    state = state;
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
}
