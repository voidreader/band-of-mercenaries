import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'faction_contact_service.dart';

/// M8a 세력 관계 단계 (FR-A4)
///
/// 우선순위: hostile > core > trusted > joined > patronage > noticed > untouched
enum FactionRelationStage {
  untouched,
  noticed,
  patronage,
  joined,
  trusted,
  core,
  hostile;

  /// factionId의 현재 관계 단계를 계산한다.
  ///
  /// Hive 신규 필드 추가 없이 reputation / isJoined + 접촉점 활성 여부만 사용.
  static FactionRelationStage resolve(String factionId, WidgetRef ref) {
    return _resolveCore(
      factionId,
      ref: ref,
      isActiveContact: (contactId) => FactionContactService.isActive(contactId, ref),
    );
  }

  /// factionId의 현재 관계 단계를 계산한다 (Provider 계층 버전).
  ///
  /// `Ref<Object?>` 타입을 받으므로 Provider 계층에서 호출 가능.
  /// M8.5 페이즈 4 #1 LivingsphereDashboardService.computeSnapshot에서 사용.
  static FactionRelationStage resolveFromProviderRef(
    String factionId,
    Ref<Object?> ref,
  ) {
    return _resolveCore(
      factionId,
      ref: ref,
      isActiveContact: (contactId) =>
          FactionContactService.isActiveFromProviderRef(contactId, ref),
    );
  }

  /// 내부 공용 로직 — resolve / resolveFromProviderRef에서 위임.
  static FactionRelationStage _resolveCore(
    String factionId, {
    required dynamic ref,
    required bool Function(String contactId) isActiveContact,
  }) {
    final state =
        ref.read(factionStateRepositoryProvider).getState(factionId);
    final reputation = state?.currentReputation ?? 0;
    final joined = state?.isJoined ?? false;

    if (reputation < 0) return FactionRelationStage.hostile;
    if (joined && reputation >= 61) return FactionRelationStage.core;
    if (joined && reputation >= 31) return FactionRelationStage.trusted;
    if (joined) return FactionRelationStage.joined;

    final hasActiveContact = _hasActiveContact(factionId, ref, isActiveContact);
    if (hasActiveContact && reputation >= 1 && reputation <= 10) {
      return FactionRelationStage.patronage;
    }
    if (hasActiveContact && reputation == 0) {
      return FactionRelationStage.noticed;
    }
    return FactionRelationStage.untouched;
  }

  static bool _hasActiveContact(
    String factionId,
    dynamic ref,
    bool Function(String contactId) isActiveContact,
  ) {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return false;
    for (final contact in staticData.factionContacts) {
      if (contact.factionId != factionId) continue;
      if (isActiveContact(contact.id)) return true;
    }
    return false;
  }
}
