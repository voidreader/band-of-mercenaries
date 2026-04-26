import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_event_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_option_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_result_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_choice_service.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';

// 테스트용 Mercenary 생성 헬퍼
Mercenary _makeMerc({
  required String id,
  int level = 1,
  List<String> traitIds = const [],
}) {
  return Mercenary(
    id: id,
    name: '용병_$id',
    jobId: 'warrior',
    traitId: '',
    str: 10,
    intelligence: 10,
    vit: 10,
    agi: 10,
    level: level,
    traitIds: traitIds,
  );
}

// 테스트용 TravelChoiceEventData 생성 헬퍼
TravelChoiceEventData _makeEvent({
  required String id,
  int minTier = 1,
  int maxTier = 5,
  int weight = 1,
  String? preferredTraits,
}) {
  return TravelChoiceEventData(
    id: id,
    name: '이벤트_$id',
    category: 'test',
    situation: '테스트 상황',
    minTier: minTier,
    maxTier: maxTier,
    weight: weight,
    preferredTraits: preferredTraits,
  );
}

// 테스트용 TravelChoiceOptionData 생성 헬퍼
TravelChoiceOptionData _makeOption({
  required String id,
  String? visibilityExpr,
}) {
  return TravelChoiceOptionData(
    id: id,
    eventId: 'event_test',
    choiceIndex: 0,
    label: '선택지_$id',
    visibilityExpr: visibilityExpr,
    description: '테스트 설명',
    riskLevel: 'low',
  );
}

// 테스트용 TravelChoiceResultData 생성 헬퍼
TravelChoiceResultData _makeResult({
  required String id,
  required String optionId,
  String effectType = 'nothing',
  double effectMagnitude = 0.0,
  double probability = 1.0,
  String? conditionalExpr,
}) {
  return TravelChoiceResultData(
    id: id,
    optionId: optionId,
    resultIndex: 0,
    probability: probability,
    conditionalExpr: conditionalExpr,
    narrative: '테스트 서사',
    effectType: effectType,
    effectMagnitude: effectMagnitude,
  );
}

// 테스트용 최소 UserData 생성 헬퍼
UserData _makeUserData() {
  return UserData(
    gold: 100,
    region: 1,
    sector: 0,
    lastFreeRecruit: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('TravelChoiceService.rollChoiceEvent', () {
    test('rosterIdle이 비어있으면 null을 반환한다', () {
      final events = [_makeEvent(id: 'e1')];

      final result = TravelChoiceService.rollChoiceEvent(
        distance: 5,
        regionTier: 3,
        rosterIdle: [],
        events: events,
        random: Random(0),
      );

      expect(result, isNull);
    });

    test('distance=0이면 확률=0이므로 null을 반환한다', () {
      final merc = _makeMerc(id: 'a');
      final events = [_makeEvent(id: 'e1')];

      // distance=0 → prob=0.0 → random.nextDouble()는 항상 >= 0.0
      final result = TravelChoiceService.rollChoiceEvent(
        distance: 0,
        regionTier: 3,
        rosterIdle: [merc],
        events: events,
        random: Random(0),
      );

      expect(result, isNull);
    });

    test('regionTier=3, distance=3: 확률=0.30, random=0.0이면 이벤트를 반환한다', () {
      final merc = _makeMerc(id: 'a');
      final event = _makeEvent(id: 'e1', minTier: 1, maxTier: 5);

      // regionTier=3 → coeff=0.10, distance=3 → prob=0.30 (probCapBase)
      // nextDouble()=0.0 < 0.30 → 이벤트 발동
      final result = TravelChoiceService.rollChoiceEvent(
        distance: 3,
        regionTier: 3,
        rosterIdle: [merc],
        events: [event],
        random: _FixedRandom(0.0),
      );

      expect(result, isNotNull);
      expect(result!.id, 'e1');
    });

    test('regionTier=1, distance=1: 확률=0.08, random=0.09이면 null을 반환한다', () {
      final merc = _makeMerc(id: 'a');
      final events = [_makeEvent(id: 'e1')];

      // regionTier=1 → coeff=0.08, distance=1 → prob=0.08
      // nextDouble()=0.09 >= 0.08 → 발동 안 함
      final result = TravelChoiceService.rollChoiceEvent(
        distance: 1,
        regionTier: 1,
        rosterIdle: [merc],
        events: events,
        random: _FixedRandom(0.09),
      );

      expect(result, isNull);
    });

    test('minTier=3인 이벤트는 regionTier=2에서 필터링되어 제외된다', () {
      final merc = _makeMerc(id: 'a');
      // minTier=3인 이벤트만 존재 → regionTier=2에서 filtered 비어있음 → null
      final events = [_makeEvent(id: 'e1', minTier: 3, maxTier: 5)];

      final result = TravelChoiceService.rollChoiceEvent(
        distance: 5,
        regionTier: 2,
        rosterIdle: [merc],
        events: events,
        random: _FixedRandom(0.0),
      );

      expect(result, isNull);
    });
  });

  group('TravelChoiceService.selectProtagonist', () {
    test('preferredTraits 보유 용병이 우선 선택된다', () {
      final mercWithTrait = _makeMerc(id: 'b', level: 1, traitIds: ['brave']);
      final mercWithoutTrait = _makeMerc(id: 'a', level: 3);

      final result = TravelChoiceService.selectProtagonist(
        rosterIdle: [mercWithoutTrait, mercWithTrait],
        preferredTraitsCsv: 'brave',
        traits: [],
      );

      expect(result.id, 'b');
    });

    test('preferredTraits 보유자 없으면 최고 레벨 용병을 fallback으로 선택한다', () {
      final lowLevel = _makeMerc(id: 'a', level: 1);
      final highLevel = _makeMerc(id: 'b', level: 3);

      final result = TravelChoiceService.selectProtagonist(
        rosterIdle: [lowLevel, highLevel],
        preferredTraitsCsv: 'nonexistent_trait',
        traits: [],
      );

      expect(result.id, 'b');
    });

    test('레벨 동점 시 id lexical 오름차순 정렬에서 첫 번째 용병을 선택한다', () {
      final mercC = _makeMerc(id: 'c', level: 2);
      final mercA = _makeMerc(id: 'a', level: 2);
      final mercB = _makeMerc(id: 'b', level: 2);

      final result = TravelChoiceService.selectProtagonist(
        rosterIdle: [mercC, mercA, mercB],
        preferredTraitsCsv: null,
        traits: [],
      );

      expect(result.id, 'a');
    });
  });

  group('TravelChoiceService.resolveResult', () {
    test('conditionalExpr 실패 시 fallback nothing 결과를 반환한다', () {
      final engine = const TemplateEngine();
      final userData = _makeUserData();
      // team.gold >= 9999 조건은 기본 gold=100으로 실패
      final context = TemplateContext(user: userData);
      final option = _makeOption(id: 'opt1');
      final result = _makeResult(
        id: 'r1',
        optionId: 'opt1',
        conditionalExpr: 'user.gold >= 9999',
      );

      final resolved = TravelChoiceService.resolveResult(
        option: option,
        allResults: [result],
        engine: engine,
        mercContext: context,
        random: Random(0),
      );

      expect(resolved.id, '__fallback__');
      expect(resolved.effectType, 'nothing');
    });

    test('random=0.0이면 첫 번째 후보를 선택한다', () {
      final engine = const TemplateEngine();
      final userData = _makeUserData();
      final context = TemplateContext(user: userData);
      final option = _makeOption(id: 'opt1');

      final result1 = _makeResult(id: 'r1', optionId: 'opt1', probability: 0.5);
      final result2 = _makeResult(id: 'r2', optionId: 'opt1', probability: 0.5);

      // random=0.0 → roll=0.0, roll -= 0.5 → roll=-0.5 <= 0 → 첫 번째 선택
      final resolved = TravelChoiceService.resolveResult(
        option: option,
        allResults: [result1, result2],
        engine: engine,
        mercContext: context,
        random: _FixedRandom(0.0),
      );

      expect(resolved.id, 'r1');
    });
  });

  group('TravelChoiceService.filterVisibleOptions', () {
    test('TC-1: visibilityExpr == null인 옵션은 항상 포함된다', () {
      final engine = const TemplateEngine();
      final userData = _makeUserData(); // gold=100
      final context = TemplateContext(user: userData);

      final option = _makeOption(id: 'opt1', visibilityExpr: null);

      final result = TravelChoiceService.filterVisibleOptions(
        options: [option],
        engine: engine,
        teamContext: context,
      );

      expect(result.length, 1);
      expect(result.first.id, 'opt1');
    });

    test('TC-2: visibilityExpr 평가 true인 옵션은 포함된다', () {
      final engine = const TemplateEngine();
      final userData = _makeUserData(); // gold=100
      final context = TemplateContext(user: userData);

      // {world.gold}=100 >= 0 → true
      final option = _makeOption(id: 'opt2', visibilityExpr: '{world.gold} >= 0');

      final result = TravelChoiceService.filterVisibleOptions(
        options: [option],
        engine: engine,
        teamContext: context,
      );

      expect(result.length, 1);
      expect(result.first.id, 'opt2');
    });

    test('TC-3: visibilityExpr 평가 false인 옵션은 제외된다', () {
      final engine = const TemplateEngine();
      final userData = _makeUserData(); // gold=100
      final context = TemplateContext(user: userData);

      // {world.gold}=100 >= 9999 → false
      final option = _makeOption(id: 'opt3', visibilityExpr: '{world.gold} >= 9999');

      final result = TravelChoiceService.filterVisibleOptions(
        options: [option],
        engine: engine,
        teamContext: context,
      );

      expect(result.isEmpty, isTrue);
    });

    test('TC-4: hidden riskLevel 옵션도 visibilityExpr false이면 제외된다', () {
      final engine = const TemplateEngine();
      final userData = _makeUserData(); // gold=100
      final context = TemplateContext(user: userData);

      final hiddenOption = TravelChoiceOptionData(
        id: 'opt_hidden',
        eventId: 'event_test',
        choiceIndex: 1,
        label: '숨겨진 선택지',
        visibilityExpr: '{world.gold} >= 9999',
        description: '테스트 설명',
        riskLevel: 'hidden',
      );

      final result = TravelChoiceService.filterVisibleOptions(
        options: [hiddenOption],
        engine: engine,
        teamContext: context,
      );

      expect(result.isEmpty, isTrue);
    });
  });

  group('TravelChoiceService.summarizeEffect', () {
    test('effectType=gold, 양수 magnitude → "골드 +N" 형식을 반환한다', () {
      final result = _makeResult(
        id: 'r1',
        optionId: 'opt1',
        effectType: 'gold',
        effectMagnitude: 50.0,
      );

      expect(TravelChoiceService.summarizeEffect(result), '골드 +50');
    });

    test('effectType=gold, 음수 magnitude → "골드 -N" 형식을 반환한다', () {
      final result = _makeResult(
        id: 'r1',
        optionId: 'opt1',
        effectType: 'gold',
        effectMagnitude: -30.0,
      );

      expect(TravelChoiceService.summarizeEffect(result), '골드 -30');
    });

    test('effectType=reputation → "명성 +N" 형식을 반환한다', () {
      final result = _makeResult(
        id: 'r1',
        optionId: 'opt1',
        effectType: 'reputation',
        effectMagnitude: 5.0,
      );

      expect(TravelChoiceService.summarizeEffect(result), '명성 +5');
    });

    test('effectType=injury → "부상"을 반환한다', () {
      final result = _makeResult(
        id: 'r1',
        optionId: 'opt1',
        effectType: 'injury',
        effectMagnitude: 0.0,
      );

      expect(TravelChoiceService.summarizeEffect(result), '부상');
    });

    test('effectType=nothing → "아무 일 없음"을 반환한다', () {
      final result = _makeResult(
        id: 'r1',
        optionId: 'opt1',
        effectType: 'nothing',
        effectMagnitude: 0.0,
      );

      expect(TravelChoiceService.summarizeEffect(result), '아무 일 없음');
    });
  });
}

/// 테스트용 고정값 Random — nextDouble()이 항상 [value]를 반환한다.
class _FixedRandom implements Random {
  final double value;
  _FixedRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}
