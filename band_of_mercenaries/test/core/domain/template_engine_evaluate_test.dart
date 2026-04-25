import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

Mercenary _dummyMerc({
  String id = 'merc1',
  int level = 1,
  List<String> traitIds = const [],
}) {
  return Mercenary(
    id: id,
    name: '테스트용병',
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

UserData _dummyUser({int gold = 500}) {
  return UserData(
    gold: gold,
    region: 1,
    sector: 0,
    lastFreeRecruit: DateTime(2026),
    createdAt: DateTime(2026),
  );
}

Region _dummyRegion({int tier = 2}) {
  return Region(
    continent: 1,
    region: 1,
    regionName: '테스트지역',
    regionTier: tier,
    recommendPower: 100,
    description: '',
  );
}

FactionState _dummyFaction({
  String factionId = 'lumen_brotherhood',
  bool joined = true,
}) {
  return FactionState(
    factionId: factionId,
    joined: joined,
  );
}

void main() {
  const engine = TemplateEngine();

  group('TemplateEngine.evaluate', () {
    test('{merc.level} >= 3 — level=3이면 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 3),
      );
      expect(engine.evaluate('{merc.level} >= 3', ctx), isTrue);
    });

    test('{merc.level} >= 3 — level=2이면 false', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 2),
      );
      expect(engine.evaluate('{merc.level} >= 3', ctx), isFalse);
    });

    test('{merc.level} == 1 — quest.difficulty 스타일 동등 비교', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 1),
      );
      expect(engine.evaluate('{merc.level} == 1', ctx), isTrue);
      expect(engine.evaluate('{merc.level} == 5', ctx), isFalse);
    });

    test('{region.tier} < 3 — tier=2이면 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        region: _dummyRegion(tier: 2),
        merc: _dummyMerc(),
      );
      expect(engine.evaluate('{region.tier} < 3', ctx), isTrue);
    });

    test('{region.tier} < 3 — tier=3이면 false', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        region: _dummyRegion(tier: 3),
        merc: _dummyMerc(),
      );
      expect(engine.evaluate('{region.tier} < 3', ctx), isFalse);
    });

    test('{world.gold} > 1000 — gold=1500이면 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(gold: 1500),
        merc: _dummyMerc(),
      );
      expect(engine.evaluate('{world.gold} > 1000', ctx), isTrue);
    });

    test('{world.gold} > 1000 — gold=500이면 false', () {
      final ctx = TemplateContext(
        user: _dummyUser(gold: 500),
        merc: _dummyMerc(),
      );
      expect(engine.evaluate('{world.gold} > 1000', ctx), isFalse);
    });

    test('has_trait:empathic — trait 보유 시 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['empathic']),
      );
      expect(engine.evaluate('has_trait:empathic', ctx), isTrue);
    });

    test('has_trait:empathic — trait 미보유 시 false', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['brave']),
      );
      expect(engine.evaluate('has_trait:empathic', ctx), isFalse);
    });

    test('has_any_trait:a,b,c — 하나라도 보유 시 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['b']),
      );
      expect(engine.evaluate('has_any_trait:a,b,c', ctx), isTrue);
    });

    test('has_any_trait 5개 상한 초과(6개) 입력 — false 반환 (크래시 없음)', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['a']),
      );
      expect(
        engine.evaluate('has_any_trait:a,b,c,d,e,f', ctx),
        isFalse,
      );
    });

    test('has_all_traits:a,b,c — 3개 모두 보유 시 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['a', 'b', 'c']),
      );
      expect(engine.evaluate('has_all_traits:a,b,c', ctx), isTrue);
    });

    test('has_all_traits:a,b,c — 하나라도 없으면 false', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['a', 'b']),
      );
      expect(engine.evaluate('has_all_traits:a,b,c', ctx), isFalse);
    });

    test('joined_faction:lumen_brotherhood — 가입 상태이면 true', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(),
        factionStates: [_dummyFaction(joined: true)],
      );
      expect(engine.evaluate('joined_faction:lumen_brotherhood', ctx), isTrue);
    });

    test('joined_faction:lumen_brotherhood — 미가입 상태이면 false', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(),
        factionStates: [_dummyFaction(joined: false)],
      );
      expect(engine.evaluate('joined_faction:lumen_brotherhood', ctx), isFalse);
    });

    test('AND 결합 — {merc.level} >= 3 and has_trait:brave', () {
      final ctxTrue = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 3, traitIds: ['brave']),
      );
      final ctxFalse = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 3, traitIds: []),
      );
      expect(engine.evaluate('{merc.level} >= 3 and has_trait:brave', ctxTrue), isTrue);
      expect(engine.evaluate('{merc.level} >= 3 and has_trait:brave', ctxFalse), isFalse);
    });

    test('OR 결합 — {merc.level} >= 5 or has_trait:lucky', () {
      final ctxLevel5 = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 5, traitIds: []),
      );
      final ctxHasLucky = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 1, traitIds: ['lucky']),
      );
      final ctxFalse = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 1, traitIds: []),
      );
      expect(engine.evaluate('{merc.level} >= 5 or has_trait:lucky', ctxLevel5), isTrue);
      expect(engine.evaluate('{merc.level} >= 5 or has_trait:lucky', ctxHasLucky), isTrue);
      expect(engine.evaluate('{merc.level} >= 5 or has_trait:lucky', ctxFalse), isFalse);
    });

    test('NOT 결합 — not has_trait:cursed', () {
      final ctxNoCursed = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['brave']),
      );
      final ctxHasCursed = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(traitIds: ['cursed']),
      );
      expect(engine.evaluate('not has_trait:cursed', ctxNoCursed), isTrue);
      expect(engine.evaluate('not has_trait:cursed', ctxHasCursed), isFalse);
    });

    test('그룹핑 — (A or B) and C', () {
      final ctxTrue = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 1, traitIds: ['brave', 'empathic']),
      );
      final ctxFalse = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(level: 1, traitIds: ['brave']),
      );
      expect(
        engine.evaluate(
          '(has_trait:brave or has_trait:lucky) and has_trait:empathic',
          ctxTrue,
        ),
        isTrue,
      );
      expect(
        engine.evaluate(
          '(has_trait:brave or has_trait:lucky) and has_trait:empathic',
          ctxFalse,
        ),
        isFalse,
      );
    });

    test('team scope — 로스터 중 한 명이라도 trait 보유 시 true', () {
      final merc1 = _dummyMerc(id: 'merc1', traitIds: []);
      final merc2 = _dummyMerc(id: 'merc2', traitIds: ['empathic']);
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: merc1,
        rosterForTeam: [merc1, merc2],
        evaluationScope: EvaluationScope.team,
      );
      expect(engine.evaluate('has_trait:empathic', ctx), isTrue);
    });

    test('team scope + 빈 로스터 — false 반환', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        rosterForTeam: [],
        evaluationScope: EvaluationScope.team,
      );
      expect(engine.evaluate('has_trait:empathic', ctx), isFalse);
    });

    test('syntax error 입력 — false 반환, 크래시 없음', () {
      final ctx = TemplateContext(
        user: _dummyUser(),
        merc: _dummyMerc(),
      );
      expect(engine.evaluate('@@invalid##expression!!', ctx), isFalse);
    });
  });
}
