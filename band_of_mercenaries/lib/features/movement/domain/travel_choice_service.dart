import 'dart:math';

import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_event_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_option_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_result_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class TravelChoiceService {
  TravelChoiceService._();

  static const _probCapBase = 0.30;
  static const Map<int, double> _coeffByTier = {
    1: 0.08,
    2: 0.08,
    3: 0.10,
    4: 0.10,
    5: 0.12,
  };
  static const _traitLearningBoostDuration = Duration(hours: 24);

  static final fallbackResult = TravelChoiceResultData(
    id: '__fallback__',
    optionId: '',
    resultIndex: 0,
    probability: 1.0,
    narrative: '{merc.name}은 아무 일 없이 돌아왔다.',
    effectType: 'nothing',
    effectMagnitude: 0.0,
  );

  static TravelChoiceEventData? rollChoiceEvent({
    required int distance,
    required int regionTier,
    required List<Mercenary> rosterIdle,
    required List<TravelChoiceEventData> events,
    required Random random,
  }) {
    if (rosterIdle.isEmpty) return null;

    final coeff = _coeffByTier[regionTier] ?? 0.08;
    final prob = (distance * coeff).clamp(0.0, _probCapBase);
    if (random.nextDouble() >= prob) return null;

    final filtered = events
        .where((e) => regionTier >= e.minTier && regionTier <= e.maxTier)
        .toList();
    if (filtered.isEmpty) return null;

    final totalWeight =
        filtered.fold<double>(0.0, (sum, e) => sum + e.weight);
    double roll = random.nextDouble() * totalWeight;

    for (final event in filtered) {
      roll -= event.weight;
      if (roll <= 0) return event;
    }

    return filtered.last;
  }

  static Mercenary selectProtagonist({
    required List<Mercenary> rosterIdle,
    required String? preferredTraitsCsv,
    required List<TraitData> traits,
  }) {
    final preferredKeys = preferredTraitsCsv != null
        ? preferredTraitsCsv
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
        : <String>{};

    List<Mercenary> candidates = [];
    if (preferredKeys.isNotEmpty) {
      candidates = rosterIdle
          .where((m) => m.allTraitIds.any((id) => preferredKeys.contains(id)))
          .toList();
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final levelCmp = b.level.compareTo(a.level);
        if (levelCmp != 0) return levelCmp;
        return a.id.compareTo(b.id);
      });
      return candidates.first;
    }

    final sorted = [...rosterIdle]
      ..sort((a, b) {
        final levelCmp = b.level.compareTo(a.level);
        if (levelCmp != 0) return levelCmp;
        return a.id.compareTo(b.id);
      });
    return sorted.first;
  }

  static List<TravelChoiceOptionData> filterVisibleOptions({
    required List<TravelChoiceOptionData> options,
    required TemplateEngine engine,
    required TemplateContext teamContext,
  }) {
    return options.where((option) {
      if (option.visibilityExpr == null) return true;
      return engine.evaluate(option.visibilityExpr!, teamContext);
    }).toList();
  }

  static TravelChoiceResultData resolveResult({
    required TravelChoiceOptionData option,
    required List<TravelChoiceResultData> allResults,
    required TemplateEngine engine,
    required TemplateContext mercContext,
    required Random random,
  }) {
    final candidates = allResults
        .where((r) => r.optionId == option.id)
        .where((r) {
          if (r.conditionalExpr == null) return true;
          return engine.evaluate(r.conditionalExpr!, mercContext);
        })
        .toList();

    if (candidates.isEmpty) return fallbackResult;

    final totalProb =
        candidates.fold<double>(0.0, (sum, r) => sum + r.probability);
    if (totalProb <= 0) return fallbackResult;

    double roll = random.nextDouble() * totalProb;
    for (final result in candidates) {
      roll -= result.probability;
      if (roll <= 0) return result;
    }

    return candidates.last;
  }

  static String summarizeEffect(TravelChoiceResultData result) {
    final mag = result.effectMagnitude;
    switch (result.effectType) {
      case 'gold':
        return '골드 ${mag > 0 ? '+' : ''}${mag.toInt()}';
      case 'reputation':
        return '명성 ${mag > 0 ? '+' : ''}${mag.toInt()}';
      case 'injury':
        return '부상';
      case 'heal_tired':
        return mag > 0 ? '피로 회복' : '피로 부여';
      case 'trait_innate':
        return '선천 트레잇 획득';
      case 'trait_acquired':
        return '트레잇 학습 가속 24h';
      case 'item':
        return '아이템 획득';
      case 'nothing':
        return '아무 일 없음';
      default:
        return '효과 없음';
    }
  }

  static Duration get traitLearningBoostDuration => _traitLearningBoostDuration;
}
