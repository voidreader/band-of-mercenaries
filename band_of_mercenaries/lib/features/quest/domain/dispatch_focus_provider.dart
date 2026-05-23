import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 사건 완료 점프 시 quest_pool_id publish.
/// DispatchScreen이 watch 후 해당 카드 포커스 + 즉시 null 리셋.
/// MVP: 카드 인덱스 매칭 없으면 silent skip.
final dispatchFocusQuestPoolIdProvider = StateProvider<String?>((ref) => null);
