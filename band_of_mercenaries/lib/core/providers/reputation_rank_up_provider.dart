import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';

/// 랭크업 이벤트 페이로드.
///
/// [from] 이전 랭크, [to] 신규 도달 랭크.
/// [newEffects]는 신규 랭크의 `bonusJson`을 파싱한 효과 리스트 (누적 X, 신규 효과만).
class RankUpEvent {
  final Rank from;
  final Rank to;
  final List<PassiveEffect> newEffects;

  const RankUpEvent({
    required this.from,
    required this.to,
    required this.newEffects,
  });
}

/// 랭크업 이벤트 전역 발행 채널.
///
/// [UserDataNotifier.addReputation]에서 감지 후 publish.
/// [app.dart]의 `ref.listen`이 감지하여 랭크업 오버레이 표시.
/// 오버레이 닫힐 때 반드시 `state = null`로 리셋.
final reputationRankUpProvider =
    StateProvider<RankUpEvent?>((ref) => null);
