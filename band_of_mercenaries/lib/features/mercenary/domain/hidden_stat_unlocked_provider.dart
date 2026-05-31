import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 은닉 스탯 해금 이벤트 페이로드.
///
/// 용병이 특정 조건(행동지표/칭호/위업 등)을 만족하여 은닉 스탯이 해금될 때
/// [hiddenStatUnlockedProvider]에 publish된다.
class HiddenStatUnlockEvent {
  /// 용병 ID
  final String mercId;

  /// 용병 이름
  final String mercName;

  /// 해금된 은닉 스탯 ID
  final String statId;

  /// 해금된 은닉 스탯 이름
  final String statName;

  /// 해금 이유 설명 (예: "칭호 '위대한 전사' 획득으로 해금")
  final String description;

  /// 효과 항목 리스트 (각 줄을 별도로 표시)
  /// 예: ["+10 STR", "방어력 +15%"]
  final List<String> effects;

  const HiddenStatUnlockEvent({
    required this.mercId,
    required this.mercName,
    required this.statId,
    required this.statName,
    required this.description,
    required this.effects,
  });
}

/// 은닉 스탯 해금 이벤트 채널.
///
/// [UserDataNotifier] 또는 관련 도메인 서비스에서 감지 후 publish.
/// [app.dart]의 `ref.listen`이 감지하여 은닉 스탯 해금 다이얼로그를 표시.
/// 다이얼로그 닫힐 때 반드시 `state = null`로 리셋.
final hiddenStatUnlockedProvider =
    StateProvider<HiddenStatUnlockEvent?>((ref) => null);
