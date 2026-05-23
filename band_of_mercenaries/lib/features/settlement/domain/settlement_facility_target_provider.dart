import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

/// 거점 발전/대장간 점프 시 시설 enum publish.
/// MovementScreen이 watch 후 현재 위치가 region 3 village 섹터이면 _selectedFacility 변경 + 즉시 null 리셋.
/// region 3 village 섹터가 아니면 region 3 sector 1 포커스만 + 즉시 null 리셋.
final settlementFacilityTargetProvider = StateProvider<VillageFacility?>((ref) => null);
