import 'package:flutter_riverpod/flutter_riverpod.dart';

/// region 3 RegionState 변경 트리거.
/// RegionStateRepository의 mutation 메서드(addDangerScore/toggleFlag/addSettlementTrust 등)에서
/// `ref.read(region3StateVersionProvider.notifier).state++`로 증가시켜 livingsphereDashboardProvider 재계산을 유도한다.
final region3StateVersionProvider = StateProvider<int>((ref) => 0);
