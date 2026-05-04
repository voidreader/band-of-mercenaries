import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/region_state_repository.dart';

// 특정 regionId의 신뢰도(trust)와 단계(level)를 동기 조회하는 Provider
final settlementTrustProvider = Provider.family<({int trust, int level}), int>((ref, regionId) {
  final repo = ref.watch(regionStateRepositoryProvider);
  return repo.getSettlementTrust(regionId);
});
