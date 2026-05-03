import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/settings_keys.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';

class RegionMigrationService {
  static const String _flagKey = SettingsKeys.regionMigrationV1;
  static const String _sectorCountFlagKey = SettingsKeys.regionSectorCountV1;

  /// 살아남는 40개 region_id 셋을 staticData.regions에서 추출하여
  /// regionStates / user / factionStates 박스를 정리.
  /// 각 단계는 별도 멱등성 플래그로 보호되어 독립적으로 1회만 실행된다.
  static Future<void> migrate(StaticGameData staticData) async {
    final settings = Hive.box(HiveInitializer.settingsBoxName);
    final regionBox = Hive.box<RegionState>(HiveInitializer.regionStateBoxName);

    // §1. 페이즈 4 #1 region 매핑 정리 (region_migration_v1)
    if (settings.get(_flagKey) != true) {
      debugPrint('[BOM][RegionMigration] migrate 시작');

      final survivingIds = staticData.regions.map((r) => r.region).toSet();
      int deletedRegionStates = 0;
      int deletedClueRecords = 0;
      bool userReset = false;

      // 1. regionStates 박스 정리
      final keysToDelete = <dynamic>[];
      for (final key in regionBox.keys) {
        final state = regionBox.get(key);
        if (state != null && !survivingIds.contains(state.regionId)) {
          keysToDelete.add(key);
        }
      }
      await regionBox.deleteAll(keysToDelete);
      deletedRegionStates = keysToDelete.length;

      // 2. user 박스 정리
      final userBox = Hive.box<UserData>(HiveInitializer.userBoxName);
      if (userBox.isNotEmpty) {
        final userData = userBox.getAt(0);
        if (userData != null && !survivingIds.contains(userData.region)) {
          userData.region = GameConstants.startingRegionId;
          userData.sector = GameConstants.startingSector;
          userData.isMoving = false;
          userData.moveTargetRegion = null;
          userData.moveTargetSector = null;
          userData.moveEndTime = null;
          userData.investigatingMercId = null;
          userData.investigationEndTime = null;
          userData.investigationRegionId = null;
          await userData.save();
          userReset = true;
        }
      }

      // 3. factionStates 박스 정리
      final factionBox = Hive.box<FactionState>(HiveInitializer.factionStateBoxName);
      for (final key in factionBox.keys) {
        final state = factionBox.get(key);
        if (state == null) continue;
        final originalLength = state.clueRecords.length;
        state.clueRecords.removeWhere((r) => !survivingIds.contains(r.regionId));
        if (state.clueRecords.length != originalLength) {
          deletedClueRecords += originalLength - state.clueRecords.length;
          await state.save();
        }
      }

      // 4. 플래그 저장
      await settings.put(_flagKey, true);

      debugPrint(
        '[BOM][RegionMigration] migrate 완료: '
        'regionStates -$deletedRegionStates / '
        'factions clue -$deletedClueRecords / '
        'user reset: $userReset',
      );
    }

    // §2. 페이즈 4 #2 region.sectorCount 기반 sectorChanges 키 정리 (region_sector_count_v1)
    // §1 플래그 완료 여부와 무관하게 별도 실행 — 페이즈 4 #1 적용 사용자도 이 단계는 새로 실행됨.
    if (settings.get(_sectorCountFlagKey) != true) {
      final sectorCountMap = {
        for (final r in staticData.regions) r.region: r.sectorCount,
      };
      int cleanedSectorChangeKeys = 0;
      for (final key in regionBox.keys) {
        final state = regionBox.get(key);
        if (state == null) continue;
        // 0-based 키 한도: sectorCount - 1 (예: sectorCount=4 → 0..3 허용)
        final allowedMaxKey = (sectorCountMap[state.regionId] ?? 4) - 1;
        final invalidKeys = state.sectorChanges.keys
            .where((k) => (int.tryParse(k) ?? -1) > allowedMaxKey)
            .toList();
        if (invalidKeys.isNotEmpty) {
          for (final k in invalidKeys) {
            state.sectorChanges.remove(k);
          }
          cleanedSectorChangeKeys += invalidKeys.length;
          await state.save();
        }
      }
      await settings.put(_sectorCountFlagKey, true);
      debugPrint(
        '[BOM][RegionMigration] sector_count 정리 완료: '
        'sectorChanges 키 -$cleanedSectorChangeKeys',
      );
    }
  }
}
