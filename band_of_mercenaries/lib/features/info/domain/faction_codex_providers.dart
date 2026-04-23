import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
export 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart'
    show factionStateRepositoryProvider, FactionStateRepository;

// 세력 도감 자동 스크롤 타깃 Provider
// InvestigationResultDialog에서 "도감에서 확인" 클릭 시 factionId 설정
// FactionCodexScreen에서 소비 후 null로 초기화
final factionCodexScrollTargetProvider = StateProvider<String?>((ref) => null);

// 세력 목록 Provider
// staticDataProvider(FutureProvider)의 factions를 동기적으로 제공
// 로딩 중 또는 factions 없을 때 빈 리스트 반환
final factionListProvider = Provider<List<FactionData>>((ref) {
  return ref.watch(staticDataProvider).value?.factions ?? const [];
});

/// UI 갱신 트리거 Provider — join/leave/평판 변경 후 increment
final factionRefreshProvider = StateProvider<int>((ref) => 0);
