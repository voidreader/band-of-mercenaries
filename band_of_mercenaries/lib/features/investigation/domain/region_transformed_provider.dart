import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';

/// 현재 리전의 섹터 변형 맵을 반응적으로 제공하는 Provider.
/// [userDataProvider]의 region이 바뀌거나, [regionTransformedProvider]에
/// 새 이벤트가 publish될 때 자동 갱신된다.
final currentRegionSectorChangesProvider = Provider<Map<String, String>>((ref) {
  final userData = ref.watch(userDataProvider);
  if (userData == null) return const {};
  // 변형 이벤트 발생 시 이 Provider를 재계산하기 위해 watch
  ref.watch(regionTransformedProvider);
  final repo = ref.watch(regionStateRepositoryProvider);
  return repo.getState(userData.region)?.sectorChanges ?? const {};
});

/// 지역 변형 이벤트 값 객체.
/// 지역 조사 완료 후 변형이 트리거될 때 [regionTransformedProvider]에 publish된다.
class RegionTransformedEvent {
  final int regionId;
  final int sectorIndex;

  /// 변형 유형: "village" | "ruins" | "hidden"
  final String transformType;

  /// 한글 변형 이름 (예: "개척 마을")
  final String transformedName;

  /// TemplateEngine 렌더 완료된 서사 텍스트
  final String narrativeRendered;

  const RegionTransformedEvent({
    required this.regionId,
    required this.sectorIndex,
    required this.transformType,
    required this.transformedName,
    required this.narrativeRendered,
  });
}

/// 지역 변형 이벤트 채널.
/// 도메인 계층에서 publish하고, 뷰 계층(app.dart 등)이 ref.listen으로 감지하여 팝업을 표시한다.
/// 팝업 닫기 시 state = null 로 리셋한다.
final regionTransformedProvider = StateProvider<RegionTransformedEvent?>((ref) => null);
