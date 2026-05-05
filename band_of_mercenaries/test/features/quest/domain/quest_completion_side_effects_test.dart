import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_side_effects.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

ActiveQuest _exclusiveQuest() => ActiveQuest(
  id: 'active_runtime_id',
  questPoolId: 'pool_faction_contract',
  questTypeId: 'raid',
  difficulty: 1,
  region: 17,
  questName: '세력 전용 의뢰',
  isAdvancedTrack: false,
);

ActiveQuest _chainQuest() => ActiveQuest(
  id: 'chain_runtime_id',
  questPoolId: 'chain_pool',
  questTypeId: 'raid',
  difficulty: 1,
  region: 42,
  questName: '연계 보상 의뢰',
  isChainStep: true,
  chainId: 'settlement_42_test',
  chainStep: 3,
);

void main() {
  group('QuestCompletionSideEffects', () {
    test('전용 퀘스트 쿨다운 키는 런타임 quest id가 아니라 questPoolId를 사용한다', () {
      final key = QuestCompletionSideEffects.factionCooldownKey(
        _exclusiveQuest(),
      );

      expect(key, 'pool_faction_contract');
      expect(key, isNot('active_runtime_id'));
    });

    test('체인 보상 재료 획득 지역은 시작 지역이 아니라 완료한 퀘스트 지역이다', () {
      final regionId = QuestCompletionSideEffects.materialAcquiredRegion(
        _chainQuest(),
      );

      expect(regionId, 42);
    });
  });
}
