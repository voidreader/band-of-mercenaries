import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 생활권 점프 시 region ID publish.
/// MovementScreen이 watch 후 _selectedRegion 변경 + 즉시 null 리셋.
final livingsphereMovementTargetProvider = StateProvider<int?>((ref) => null);
