import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 대장간 → 인벤토리 점프 시 스크롤 + slot 자동 선택 타겟.
/// MaterialTabContent가 감지 후 즉시 null로 리셋.
final materialJumpTargetItemIdProvider = StateProvider<String?>((ref) => null);
