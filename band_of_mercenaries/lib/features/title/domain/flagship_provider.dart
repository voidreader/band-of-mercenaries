import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/flagship_mercenary_service.dart';

/// FlagshipMercenaryService 콜백 DI Provider.
/// staticData / getReputation / getJoinedFactions 콜백은 현재 5단계 정렬에서
/// 미사용이므로 제거. 페이즈 5+ reputation/faction 가중치 도입 시 재추가 예정.
final flagshipMercenaryServiceProvider =
    Provider<FlagshipMercenaryService>((ref) {
  return FlagshipMercenaryService(
    getMercenaries: () => ref.read(mercenaryListProvider),
    getBandAchievements: () => ref.read(bandAchievementsProvider),
  );
});

/// 현재 간판 mercenary (자동/수동 통합).
/// userData.flagshipMercId watch + mercenaryList watch + bandAchievements watch로
/// 의존 Provider 변경 시 자동 재계산. dead mercenary 시 자동 알고리즘 fallback.
final flagshipMercenaryProvider = Provider<Mercenary?>((ref) {
  final userData = ref.watch(userDataProvider);
  final mercList = ref.watch(mercenaryListProvider);
  // 정렬 2순위(위업 주인공 횟수) 의존성 추적용 — 값은 service 콜백에서 read
  ref.watch(bandAchievementsProvider);

  // 수동 간판이 설정된 경우
  final manualId = userData?.flagshipMercId;
  if (manualId != null) {
    final manual = mercList.firstWhereOrNull((m) => m.id == manualId);
    if (manual != null && manual.status != MercenaryStatus.dead) {
      return manual;
    }
    // 수동 ID가 dead거나 사라진 경우 자동 알고리즘 fallback
  }

  // 자동 알고리즘
  final service = ref.watch(flagshipMercenaryServiceProvider);
  return service.selectAuto();
});
