import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

/// 신규 유저 보호 게이트 단계.
///
/// - [newbieF]: 명성 등급 F (0~299) — 모집 T1 100%, 파견 d1만
/// - [newbieE]: 명성 등급 E (300~1999) — 모집 T1 90%/T2 10%, 파견 d1+d2(weight 0.25)
/// - [normal]: 명성 등급 D 이상 — 기존 분포 유지
enum NewbieGate { newbieF, newbieE, normal }

class NewbieGateResolver {
  /// 명성과 ranks 데이터로부터 게이트 단계를 판정한다.
  ///
  /// [ranks]가 비어있으면 [StateError]를 던진다 (SyncService 정상 동작 가정).
  static NewbieGate resolve({
    required int reputation,
    required List<Rank> ranks,
  }) {
    if (ranks.isEmpty) {
      throw StateError('ranks 데이터 누락 — SyncService 점검 필요');
    }
    final grade = ReputationService.getCurrentRank(reputation, ranks).grade;
    if (grade == 'F') return NewbieGate.newbieF;
    if (grade == 'E') return NewbieGate.newbieE;
    return NewbieGate.normal;
  }
}
