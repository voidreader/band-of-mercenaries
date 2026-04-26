import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/quest_narrative_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_narrative_service.dart';

Mercenary _makeMerc({
  required String id,
  int str = 10,
  int intelligence = 10,
  int vit = 10,
  int agi = 10,
}) {
  return Mercenary(
    id: id,
    name: 'Test',
    jobId: 'warrior',
    traitId: '',
    str: str,
    intelligence: intelligence,
    vit: vit,
    agi: agi,
  );
}

QuestNarrativeData _makeNarrative({
  required String id,
  required String questType,
  required String resultType,
  bool isElite = false,
  int weight = 1,
}) {
  return QuestNarrativeData(
    id: id,
    questType: questType,
    resultType: resultType,
    isElite: isElite,
    template: 'template_$id',
    weight: weight,
  );
}

void main() {
  group('QuestNarrativeService.pickTemplate', () {
    test('questType/resultType/isElite 모두 일치하는 행을 반환한다', () {
      final narratives = [
        _makeNarrative(id: 'n1', questType: 'raid', resultType: 'success', isElite: false),
        _makeNarrative(id: 'n2', questType: 'hunt', resultType: 'success', isElite: false),
        _makeNarrative(id: 'n3', questType: 'raid', resultType: 'failure', isElite: false),
      ];

      final result = QuestNarrativeService.pickTemplate(
        questType: 'raid',
        resultType: QuestResult.success,
        isElite: false,
        allNarratives: narratives,
        random: Random(0),
      );

      expect(result, isNotNull);
      expect(result!.id, 'n1');
    });

    test('매칭 후보가 0개이면 null을 반환한다', () {
      final narratives = [
        _makeNarrative(id: 'n1', questType: 'raid', resultType: 'success', isElite: false),
      ];

      final result = QuestNarrativeService.pickTemplate(
        questType: 'escort',
        resultType: QuestResult.success,
        isElite: false,
        allNarratives: narratives,
        random: Random(0),
      );

      expect(result, isNull);
    });

    test('weight 차등 — 고중량이 낮은 weight보다 70% 이상 선택된다 (100회 반복)', () {
      final narratives = [
        _makeNarrative(id: 'low', questType: 'raid', resultType: 'success', isElite: false, weight: 1),
        _makeNarrative(id: 'high', questType: 'raid', resultType: 'success', isElite: false, weight: 5),
      ];

      int highCount = 0;
      for (int i = 0; i < 100; i++) {
        final result = QuestNarrativeService.pickTemplate(
          questType: 'raid',
          resultType: QuestResult.success,
          isElite: false,
          allNarratives: narratives,
          random: Random(i),
        );
        if (result?.id == 'high') highCount++;
      }

      expect(highCount, greaterThan(70));
    });

    test('isElite true인 행만 필터링된다', () {
      final narratives = [
        _makeNarrative(id: 'normal', questType: 'raid', resultType: 'success', isElite: false),
        _makeNarrative(id: 'elite', questType: 'raid', resultType: 'success', isElite: true),
      ];

      final result = QuestNarrativeService.pickTemplate(
        questType: 'raid',
        resultType: QuestResult.success,
        isElite: true,
        allNarratives: narratives,
        random: Random(0),
      );

      expect(result, isNotNull);
      expect(result!.id, 'elite');
    });

    test('isElite false인 행만 필터링된다', () {
      final narratives = [
        _makeNarrative(id: 'normal', questType: 'raid', resultType: 'success', isElite: false),
        _makeNarrative(id: 'elite', questType: 'raid', resultType: 'success', isElite: true),
      ];

      final result = QuestNarrativeService.pickTemplate(
        questType: 'raid',
        resultType: QuestResult.success,
        isElite: false,
        allNarratives: narratives,
        random: Random(0),
      );

      expect(result, isNotNull);
      expect(result!.id, 'normal');
    });

    test('resultType 불일치 시 null을 반환한다', () {
      final narratives = [
        _makeNarrative(id: 'n1', questType: 'raid', resultType: 'success', isElite: false),
      ];

      final result = QuestNarrativeService.pickTemplate(
        questType: 'raid',
        resultType: QuestResult.failure,
        isElite: false,
        allNarratives: narratives,
        random: Random(0),
      );

      expect(result, isNull);
    });
  });

  group('QuestNarrativeService.pickProtagonist', () {
    test('빈 리스트이면 null을 반환한다', () {
      final result = QuestNarrativeService.pickProtagonist([], 'raid');
      expect(result, isNull);
    });

    test('raid 퀘스트에서 STR이 가장 높은 용병을 반환한다', () {
      final mercs = [
        _makeMerc(id: 'a', str: 20, intelligence: 10, vit: 10, agi: 10),
        _makeMerc(id: 'b', str: 50, intelligence: 10, vit: 10, agi: 10),
        _makeMerc(id: 'c', str: 30, intelligence: 10, vit: 10, agi: 10),
      ];

      final result = QuestNarrativeService.pickProtagonist(mercs, 'raid');

      expect(result, isNotNull);
      expect(result!.id, 'b');
    });

    test('단일 용병이면 해당 용병을 반환한다', () {
      final mercs = [
        _makeMerc(id: 'solo', str: 15, intelligence: 12, vit: 8, agi: 9),
      ];

      final result = QuestNarrativeService.pickProtagonist(mercs, 'raid');

      expect(result, isNotNull);
      expect(result!.id, 'solo');
    });

    test('escort 퀘스트에서 VIT이 가장 높은 용병을 반환한다', () {
      final mercs = [
        _makeMerc(id: 'x', str: 10, intelligence: 10, vit: 10, agi: 10),
        _makeMerc(id: 'y', str: 10, intelligence: 10, vit: 50, agi: 10),
        _makeMerc(id: 'z', str: 10, intelligence: 10, vit: 30, agi: 10),
      ];

      final result = QuestNarrativeService.pickProtagonist(mercs, 'escort');

      expect(result, isNotNull);
      expect(result!.id, 'y');
    });

    test('explore 퀘스트에서 INTELLIGENCE가 가장 높은 용병을 반환한다', () {
      final mercs = [
        _makeMerc(id: 'p', str: 10, intelligence: 10, vit: 10, agi: 10),
        _makeMerc(id: 'q', str: 10, intelligence: 60, vit: 10, agi: 10),
      ];

      final result = QuestNarrativeService.pickProtagonist(mercs, 'explore');

      expect(result, isNotNull);
      expect(result!.id, 'q');
    });
  });
}
