import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';

/// M7 페이즈 4 #4 — region별 현재 인프라 단계 (family Provider)
final settlementInfrastructureTierProvider =
    Provider.family<int, int>((ref, regionId) {
  final repo = ref.watch(regionStateRepositoryProvider);
  final state = repo.getState(regionId);
  return state?.currentInfrastructureTier ?? 1;
});
