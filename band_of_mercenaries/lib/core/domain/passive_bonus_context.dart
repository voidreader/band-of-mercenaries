import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';

/// 현재 플레이어 상태(가입 세력 + 명성 랭크)를 기반으로
/// [CollectedEffects]를 수집하는 공통 헬퍼.
///
/// 실제 [PassiveBonusService.collect] 시그니처는 `reputation / allRanks / joinedFactions`를
/// 받아 내부에서 rankChain 필터링. 본 헬퍼는 Ref를 통해 3개 입력을 자동 조합한다.
///
/// 사용 예:
///   final effects = PassiveBonusContext.collectFor(ref);
///
/// staticData 또는 userData 미로드 상태에서는 [CollectedEffects.empty] 반환(안전 fallback).
class PassiveBonusContext {
  /// WidgetRef 기반 수집 (UI 위젯에서 사용).
  static CollectedEffects collectFor(WidgetRef ref) {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) return const CollectedEffects.empty();

    final userData = ref.read(userDataProvider);
    if (userData == null) return const CollectedEffects.empty();

    final repo = ref.read(factionStateRepositoryProvider);
    final joinedIds = repo.getJoinedFactionIds();
    final joinedFactions = staticData.factions
        .where((f) => joinedIds.contains(f.id))
        .toList();

    return PassiveBonusService.collect(
      reputation: userData.reputation,
      allRanks: staticData.ranks,
      joinedFactions: joinedFactions,
    );
  }

  /// StateNotifier 등 Ref 타입용 수집.
  static CollectedEffects collectForRead(Ref ref) {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) return const CollectedEffects.empty();

    final userData = ref.read(userDataProvider);
    if (userData == null) return const CollectedEffects.empty();

    final repo = ref.read(factionStateRepositoryProvider);
    final joinedIds = repo.getJoinedFactionIds();
    final joinedFactions = staticData.factions
        .where((f) => joinedIds.contains(f.id))
        .toList();

    return PassiveBonusService.collect(
      reputation: userData.reputation,
      allRanks: staticData.ranks,
      joinedFactions: joinedFactions,
    );
  }
}
