import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/settlement/domain/infrastructure_upgrade_event.dart';

/// M7 페이즈 4 #4 — 인프라 단계 승급 이벤트 발행 (StateProvider)
/// 이벤트 채널 패턴: 발행 → enqueue → null 리셋
final settlementInfrastructureUpgradedProvider =
    StateProvider<InfrastructureUpgradeEvent?>((ref) => null);
