import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'danger_level_changed_event.dart';

/// 지역 위험도 단계 변화 이벤트 전역 발행 채널.
///
/// [InvestigationService]에서 위험도 단계 변화 감지 시 publish.
/// [app.dart]의 `ref.listen`이 감지하여 지역 상태 변화 다이얼로그 표시.
/// 다이얼로그 닫힐 때 반드시 `state = null`로 리셋.
final dangerLevelChangedProvider =
    StateProvider<DangerLevelChangedEvent?>((ref) => null);
