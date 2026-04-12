import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  return UserDataNotifier(ref);
});

class UserDataNotifier extends StateNotifier<UserData?> {
  final Ref ref;

  UserDataNotifier(this.ref) : super(null) {
    _load();
  }

  void _load() {
    final box = Hive.box<UserData>(HiveInitializer.userBoxName);
    if (box.isNotEmpty) {
      state = box.getAt(0);
    }
  }

  void refresh() => _load();

  Future<void> initializeNewGame() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final random = Random();
    final tier1Regions = staticData.regions.where((r) => r.regionTier == 1).toList();
    final startRegion = tier1Regions[random.nextInt(tier1Regions.length)];
    final startSector = random.nextInt(10) + 1;

    final userData = UserData(
      gold: 500,
      region: startRegion.region,
      sector: startSector,
      lastFreeRecruit: DateTime.now().subtract(const Duration(hours: 3)),
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
}
