import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'faction_contact_data.dart';

/// M8a 세력 접촉점 활성 평가 헬퍼 (FR-A3)
///
/// triggerType 3종(infrastructureTier / region_flag / achievement) 지원.
/// 영속 캐시 미사용 — 매 호출 시 RegionStateRepository / AchievementService를 다시 읽는다.
class FactionContactService {
  const FactionContactService._();

  /// contactId가 현재 활성 상태인지 동기 평가 (WidgetRef 버전 — UI 계층에서 사용).
  ///
  /// staticData.factionContacts에서 contactId를 찾고, triggerType 분기:
  /// - infrastructureTier: 값 형식 `region_{N}>={tier}` — RegionState.infrastructureTier 비교
  /// - region_flag: 값 형식 플래그명 — 모든 RegionState.unlockedFlags 매칭
  /// - achievement: 값 형식 `templateId` 또는 `prefix:*` 와일드카드
  /// 미지원 type 또는 contactId 미존재 시 false.
  static bool isActive(String contactId, WidgetRef ref) {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return false;
    final repo = ref.read(regionStateRepositoryProvider);
    final achievements = ref.read(achievementServiceProvider).getAll();
    return _isActiveCore(
      contactId,
      staticData: staticData,
      regionRepo: repo,
      achievements: achievements,
    );
  }

  /// contactId가 현재 활성 상태인지 동기 평가 (Provider Ref 버전 — Provider 계층에서 사용).
  ///
  /// FR-F1: CraftingService isFactionContactActive 콜백 DI에서 사용한다.
  static bool isActiveFromProviderRef(String contactId, Ref<Object?> ref) {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return false;
    final repo = ref.read(regionStateRepositoryProvider);
    final achievements = ref.read(achievementServiceProvider).getAll();
    return _isActiveCore(
      contactId,
      staticData: staticData,
      regionRepo: repo,
      achievements: achievements,
    );
  }

  /// 내부 공용 로직 — WidgetRef / ProviderRef 양쪽에서 위임한다.
  static bool _isActiveCore(
    String contactId, {
    required StaticGameData staticData,
    required RegionStateRepository regionRepo,
    required List<BandAchievement> achievements,
  }) {
    FactionContact? contact;
    for (final c in staticData.factionContacts) {
      if (c.id == contactId) {
        contact = c;
        break;
      }
    }
    if (contact == null) return false;

    switch (contact.triggerType) {
      case 'infrastructureTier':
        final parsed = _parseRegionTierTrigger(contact.triggerValue);
        if (parsed == null) return false;
        final tier =
            regionRepo.getOrCreateRegionState(parsed.regionId).infrastructureTier ??
            1;
        return tier >= parsed.threshold;

      case 'region_flag':
        for (final r in staticData.regions) {
          final state = regionRepo.getState(r.region);
          if (state == null) continue;
          if (state.unlockedFlags.contains(contact.triggerValue)) return true;
        }
        return false;

      case 'achievement':
        final value = contact.triggerValue;
        if (value.endsWith(':*')) {
          final prefix = value.substring(0, value.length - 1);
          return achievements.any((a) => a.templateId.startsWith(prefix));
        }
        return achievements.any((a) => a.templateId == value);

      default:
        return false;
    }
  }

  static _RegionTierTrigger? _parseRegionTierTrigger(String value) {
    final regex = RegExp(r'^region_(\d+)>=(\d+)$');
    final m = regex.firstMatch(value);
    if (m == null) return null;
    final regionId = int.tryParse(m.group(1)!);
    final threshold = int.tryParse(m.group(2)!);
    if (regionId == null || threshold == null) return null;
    return _RegionTierTrigger(regionId, threshold);
  }
}

class _RegionTierTrigger {
  final int regionId;
  final int threshold;
  const _RegionTierTrigger(this.regionId, this.threshold);
}
