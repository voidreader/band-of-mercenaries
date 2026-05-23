import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 세력 도감 자동 진입 — InfoScreen이 watch 후 _showCodex=true 설정 + 즉시 false 리셋.
final infoScreenAutoShowCodexProvider = StateProvider<bool>((ref) => false);

/// 인벤토리(재료 탭) 자동 진입 — InfoScreen이 watch 후 _showInventory=true + 즉시 false 리셋.
final infoScreenAutoShowInventoryProvider = StateProvider<bool>((ref) => false);

/// 생활권 상세 화면 자동 진입 — InfoScreen이 watch 후 _showLivingsphere=true + 즉시 false 리셋.
final infoScreenAutoShowLivingsphereProvider = StateProvider<bool>((ref) => false);

/// 연대기(위업) 자동 진입 — InfoScreen이 watch 후 _showChronicle=true + 즉시 false 리셋.
final infoScreenAutoShowChronicleProvider = StateProvider<bool>((ref) => false);
