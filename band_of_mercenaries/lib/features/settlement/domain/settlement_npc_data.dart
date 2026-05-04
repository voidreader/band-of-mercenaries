import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

/// 더스트빌 NPC 및 광장 풍문 정적 자료.
///
/// 기획 문서 [content]20260503_starting-settlement.md 3·4절 데이터를 그대로 인라인.
class SettlementNpc {
  final String id;
  final String name;
  final String emoji;
  final Map<int, String> greetingByLevel;

  const SettlementNpc({
    required this.id,
    required this.name,
    required this.emoji,
    required this.greetingByLevel,
  });
}

class SettlementNpcData {
  SettlementNpcData._();

  static const SettlementNpc parson = SettlementNpc(
    id: 'npc_chief_parson',
    name: '파슨',
    emoji: '🧓',
    greetingByLevel: {
      1: '용병이라고? 쓸 만한지부터 보자고.',
      2: '...허드렛일 정도는 맡길 수 있겠어. 제대로 해주게.',
      3: '마을 사람들이 자네 이야기를 하더군. 나쁘진 않아.',
      4: '이제 자네는 우리 마을의 한 사람일세. 큰 일을 부탁하지.',
    },
  );

  static const SettlementNpc hagen = SettlementNpc(
    id: 'npc_smith_hagen',
    name: '하겐',
    emoji: '⚒️',
    greetingByLevel: {
      1: '(고개를 한 번 끄덕이고 다시 모루를 두드린다)',
      2: '...당분간 자네에게 줄 일은 없네. 하지만 손이 빈 거 같으면 다시 와봐.',
      3: '이거 좀 손봐줄 수 있겠나? 보수는 쳐주지.',
      4: '솜씨 좋은 친구가 도와주니 든든해. 아주 좋아.',
    },
  );

  static const SettlementNpc neris = SettlementNpc(
    id: 'npc_herbalist_neris',
    name: '네리스',
    emoji: '🌿',
    greetingByLevel: {
      1: '다친 사람 있으면 데려와요. 단, 값은 받아요.',
      2: '처음보다는 익숙하군요. 정상 가격에 봐드릴게요.',
      3: '이제 좀 자주 보는 얼굴이네요. 요즘 어때요?',
      4: '마을 사람들이 당신을 좋게 말해요. 약초 더 챙겨드릴게요.',
    },
  );

  static const SettlementNpc dora = SettlementNpc(
    id: 'npc_square_old_dora',
    name: '도라 할멈',
    emoji: '👵',
    greetingByLevel: {
      1: '어이 거기, 우리 마을은 험한 곳이라우.',
      2: '용병단이 뭘 좀 해주긴 하는 모양이더라.',
      3: '용병 양반, 요새 자주 보네. 폐광은 잘 봐줘.',
      4: '이제 우리 마을의 일원이지. 자랑스럽게 말할 수 있어.',
    },
  );

  static const SettlementNpc remi = SettlementNpc(
    id: 'npc_square_kid_remi',
    name: '레미',
    emoji: '👦',
    greetingByLevel: {
      1: '(낯선 용병을 멀리서 흘끔거린다)',
      2: '용병이라고 했어요? 폐광 가본 적 있어요?',
      3: '용병 형아! 폐광 갔다 왔어요? 뭐 봤어요?',
      4: '형아 또 의뢰 가요? 다음엔 나도 데려가 줘요!',
    },
  );

  static const Map<int, String> squareGossip = {
    1: '어이 거기, 우리 마을은 험한 곳이라우.',
    2: '용병단이 뭘 좀 해주긴 하는 모양이더라.',
    3: '용병 형아! 폐광 갔다 왔어요? 뭐 봤어요?',
    4: '이제 우리 마을의 일원입니다. 자랑스럽게 말할 수 있어요.',
  };

  static const String eventCompletedMessage =
      '마을이 며칠간 시끄럽게 떠들썩했다. 광장에서 작은 잔치가 열렸고, 사람들은 당신에게 고개를 숙였다.';

  static SettlementNpc npcFor(VillageFacility facility) {
    switch (facility) {
      case VillageFacility.chiefHouse:
        return parson;
      case VillageFacility.oldSmithy:
        return hagen;
      case VillageFacility.herbalist:
        return neris;
    }
  }

  static String greetingFor(VillageFacility facility, int trustLevel) {
    final npc = npcFor(facility);
    return npc.greetingByLevel[trustLevel] ?? npc.greetingByLevel[1] ?? '';
  }
}
