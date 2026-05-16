import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/named_hook_evaluator.dart';

QuestPool _namedPool({
  required String hookType,
  required String? hookValue,
}) {
  return QuestPool(
    id: 'qp_test',
    name: 'test',
    type: 1,
    difficulty: 2,
    minRegionDiff: 1,
    maxRegionDiff: 5,
    isNamed: true,
    namedHookType: hookType,
    namedHookValue: hookValue,
  );
}

Mercenary _mercWithTitles(List<String> titleIds) {
  return Mercenary(
    id: 'm1',
    name: 'tester',
    jobId: 'j1',
    traitId: 'trait_none',
    str: 10,
    intelligence: 10,
    vit: 10,
    agi: 10,
    titleIds: titleIds,
  );
}

BandAchievement _achievement(String templateId) {
  return BandAchievement(
    id: 'ba_$templateId',
    templateId: templateId,
    type: BandAchievementType.achievement,
    achievedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('NamedHookEvaluator.evaluateNamedHook', () {
    test('title hook: 칭호 보유 mercenary 1명 이상 시 true', () {
      final pool = _namedPool(hookType: 'title', hookValue: 'title_road_hunter');
      final ctx = NamedHookContext(
        mercenaries: [_mercWithTitles(['title_road_hunter'])],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('title hook: 칭호 보유 mercenary 0명 시 false', () {
      final pool = _namedPool(hookType: 'title', hookValue: 'title_road_hunter');
      final ctx = NamedHookContext(
        mercenaries: [_mercWithTitles(['title_village_savior'])],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('achievement_count hook: count == threshold 시 true', () {
      final pool = _namedPool(hookType: 'achievement_count', hookValue: '3');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('a'), _achievement('b'), _achievement('c')],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('achievement_count hook: count < threshold 시 false', () {
      final pool = _namedPool(hookType: 'achievement_count', hookValue: '3');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('a'), _achievement('b')],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('achievement_count hook: memorial 제외 — type=memorial 카운트 안 함', () {
      final pool = _namedPool(hookType: 'achievement_count', hookValue: '2');
      final memorial = BandAchievement(
        id: 'm',
        templateId: 'memorial:diedQuest',
        type: BandAchievementType.memorial,
        achievedAt: DateTime(2026, 1, 1),
      );
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('a'), memorial],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('flagship hook: flagshipMercId non-null 시 true', () {
      final pool = _namedPool(hookType: 'flagship', hookValue: '');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: 'm_flagship',
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('flagship hook: flagshipMercId null 시 false', () {
      final pool = _namedPool(hookType: 'flagship', hookValue: '');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('achievement_id hook: 매칭되는 templateId 보유 시 true', () {
      final pool = _namedPool(
          hookType: 'achievement_id',
          hookValue: 'chain_completed:chain_test');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: [_achievement('chain_completed:chain_test')],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isTrue);
    });

    test('unknown hook_type 시 silent false', () {
      final pool = _namedPool(hookType: 'unknown_type', hookValue: 'x');
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: 'm_flagship',
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });

    test('hook_type null 시 silent false', () {
      const pool = QuestPool(
        id: 'qp_test',
        name: 'test',
        type: 1,
        difficulty: 2,
        minRegionDiff: 1,
        maxRegionDiff: 5,
        isNamed: true,
        namedHookType: null,
      );
      final ctx = NamedHookContext(
        mercenaries: const [],
        bandAchievements: const [],
        flagshipMercId: null,
      );
      expect(NamedHookEvaluator.evaluateNamedHook(pool, ctx), isFalse);
    });
  });

  group('NamedHookEvaluator.isCooldownPassed', () {
    test('null 시 통과', () {
      expect(NamedHookEvaluator.isCooldownPassed(null, DateTime.now()), isTrue);
    });

    test('과거 시각 시 통과', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      expect(NamedHookEvaluator.isCooldownPassed(past, DateTime.now()), isTrue);
    });

    test('미래 시각 시 차단', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(NamedHookEvaluator.isCooldownPassed(future, DateTime.now()), isFalse);
    });
  });
}
