// band_of_mercenaries/test/features/info/domain/faction_join_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';

void main() {
  group('FactionJoinService.canJoin', () {
    const baseArgs = (
      factionId: 'faction_a',
      reputation: 1,
      joinNeedsClue: false,
      maxClueLevel: 0,
      joinRankMin: null,
      currentRank: 'F',
      conflictFactionIds: <String>[],
      currentlyJoinedFactionIds: <String>[],
    );

    test('평판 0이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 0,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('평판 -1이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: -1,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('clue 필요한데 maxClueLevel 2이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: true,
          maxClueLevel: 2,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('clue 필요하고 maxClueLevel 3이면 clue 조건 통과', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: true,
          maxClueLevel: 3,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isTrue,
      );
    });

    test('joinRankMin D인데 현재 랭크 E이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: 'D',
          currentRank: 'E',
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('joinRankMin D인데 현재 랭크 D이면 가입 가능', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: 'D',
          currentRank: 'D',
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isTrue,
      );
    });

    test('이해충돌 세력이 이미 가입되어 있으면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: 'faction_a',
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: const ['faction_b'],
          currentlyJoinedFactionIds: const ['faction_b'],
        ),
        isFalse,
      );
    });

    test('이미 3개 가입 중이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: const ['x', 'y', 'z'],
        ),
        isFalse,
      );
    });

    test('모든 조건 충족 시 가입 가능', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isTrue,
      );
    });
  });

  group('FactionJoinService.clampReputation', () {
    test('미가입 상태에서 +11 시도 → 10으로 클램핑', () {
      expect(FactionJoinService.clampReputation(11, joined: false), 10);
    });

    test('미가입 상태에서 10은 그대로', () {
      expect(FactionJoinService.clampReputation(10, joined: false), 10);
    });

    test('가입 후에는 100까지 허용', () {
      expect(FactionJoinService.clampReputation(80, joined: true), 80);
    });

    test('최소값 -100 이하는 클램핑', () {
      expect(FactionJoinService.clampReputation(-200, joined: true), -100);
    });

    test('최대값 100 이상은 클램핑', () {
      expect(FactionJoinService.clampReputation(150, joined: true), 100);
    });
  });

  group('FactionJoinService.isRankSufficient', () {
    test('F는 F 이상 통과', () => expect(FactionJoinService.isRankSufficient('F', 'F'), isTrue));
    test('E는 F 이상 통과', () => expect(FactionJoinService.isRankSufficient('E', 'F'), isTrue));
    test('E는 D 이상 미통과', () => expect(FactionJoinService.isRankSufficient('E', 'D'), isFalse));
    test('B는 C 이상 통과', () => expect(FactionJoinService.isRankSufficient('B', 'C'), isTrue));
    test('A는 모든 랭크 통과', () => expect(FactionJoinService.isRankSufficient('A', 'B'), isTrue));
  });

  group('FactionJoinService.describePassiveBonus', () {
    test('탐험 보상 +15%', () {
      final result = FactionJoinService.describePassiveBonus({'explore_reward_pct': 15});
      expect(result, contains('탐험 퀘스트 보상 +15%'));
    });

    test('복수 보너스', () {
      final result = FactionJoinService.describePassiveBonus({
        'escort_reward_pct': 15,
        'idle_reward_pct': 10,
      });
      expect(result, contains('호위 퀘스트 보상 +15%'));
      expect(result, contains('방치 보상 +10%'));
    });

    test('빈 맵 → 빈 문자열', () {
      expect(FactionJoinService.describePassiveBonus({}), isEmpty);
    });
  });
}
