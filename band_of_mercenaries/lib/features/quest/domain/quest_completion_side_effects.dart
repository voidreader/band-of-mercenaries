import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

/// 퀘스트 완료 후 저장되는 부작용 키/대상 결정 규칙.
///
/// QuestListNotifier 내부에 흩어지면 런타임 id와 정적 데이터 id를 혼동하기 쉬워
/// 작은 순수 헬퍼로 분리한다.
class QuestCompletionSideEffects {
  const QuestCompletionSideEffects._();

  /// 세력 전용 퀘스트 쿨다운은 재생성 필터와 같은 questPoolId 기준으로 저장한다.
  static String factionCooldownKey(ActiveQuest quest) => quest.questPoolId;

  /// 체인 보상 재료 발견 기록은 완료한 퀘스트가 속한 실제 지역에 귀속한다.
  static int materialAcquiredRegion(ActiveQuest quest) => quest.region;
}
