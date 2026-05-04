import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 마을 신뢰도 단계 승급 이벤트 페이로드.
///
/// [regionId] 승급 발생 리전 ID.
/// [fromLevel] 이전 신뢰도 단계, [toLevel] 신규 도달 단계.
/// [settlementName] 거점 명칭 (팝업 표시용).
/// [rewardGold]/[rewardXp]/[rewardReputation] 단계 진입 일회성 보상 (null이면 미지급).
class TrustLevelUpEvent {
  final int regionId;
  final int fromLevel;
  final int toLevel;
  final String settlementName;
  final int? rewardGold;
  final int? rewardXp;
  final int? rewardReputation;

  const TrustLevelUpEvent({
    required this.regionId,
    required this.fromLevel,
    required this.toLevel,
    required this.settlementName,
    this.rewardGold,
    this.rewardXp,
    this.rewardReputation,
  });
}

/// 마을 신뢰도 단계 승급 이벤트 전역 발행 채널.
///
/// [RegionStateRepository.addSettlementTrust]에서 단계 승급 감지 시 publish.
/// [app.dart]의 `ref.listen`이 감지하여 신뢰도 승급 다이얼로그 표시.
/// 다이얼로그 닫힐 때 반드시 `state = null`로 리셋.
final settlementTrustLevelUpProvider =
    StateProvider<TrustLevelUpEvent?>((ref) => null);
