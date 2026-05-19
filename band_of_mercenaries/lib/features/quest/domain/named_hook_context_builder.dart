import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/game_state_provider.dart'
    show userDataProvider;
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart'
    show achievementServiceProvider;
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_contact_service.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart'
    show mercenaryListProvider;

import 'named_hook_evaluator.dart';

/// M8a 세력 지명 의뢰 hook 평가 컨텍스트 빌더 (FR-B2)
///
/// quest_provider.dart의 generateQuests 호출점들이 사용. read 기반(race condition 회피).
class NamedHookContextBuilder {
  const NamedHookContextBuilder._();

  static NamedHookContext build(WidgetRef ref) {
    final staticData = ref.read(staticDataProvider).value;

    // 기존 3 필드
    final mercenaries = ref.read(mercenaryListProvider);
    final bandAchievements = ref.read(achievementServiceProvider).getAll();
    final flagshipMercId = ref.read(userDataProvider)?.flagshipMercId;

    // 신규 3 필드
    final unlockedRegionFlags = <int, Set<String>>{};
    final regionRepo = ref.read(regionStateRepositoryProvider);
    if (staticData != null) {
      for (final region in staticData.regions) {
        final regionState = regionRepo.getState(region.region);
        final flags = regionState?.unlockedFlags ?? const <String>[];
        if (flags.isNotEmpty) {
          unlockedRegionFlags[region.region] = flags.toSet();
        }
      }
    }

    final activeContactIds = <String>{};
    if (staticData != null) {
      for (final contact in staticData.factionContacts) {
        if (FactionContactService.isActive(contact.id, ref)) {
          activeContactIds.add(contact.id);
        }
      }
    }

    final factionStates = ref.read(factionStateRepositoryProvider).getAllReputations();
    final factionReputations = Map<String, int>.from(factionStates);

    return NamedHookContext(
      mercenaries: mercenaries,
      bandAchievements: bandAchievements,
      flagshipMercId: flagshipMercId,
      unlockedRegionFlags: unlockedRegionFlags,
      activeContactIds: activeContactIds,
      factionReputations: factionReputations,
    );
  }
}
