import 'dart:math';
import 'package:band_of_mercenaries/core/models/travel_event.dart';

class TravelEventService {
  static double eventProbability(int distance) {
    if (distance <= 0) return 0.0;
    return (distance * 0.15).clamp(0.0, 0.80);
  }

  static List<TravelEvent> filterByTier(List<TravelEvent> events, int tier) {
    return events.where((e) => tier >= e.minTier && tier <= e.maxTier).toList();
  }

  static TravelEvent? rollEvent({
    required int distance,
    required int regionTier,
    required List<TravelEvent> events,
    required Random random,
  }) {
    final probability = eventProbability(distance);
    if (random.nextDouble() >= probability) return null;
    final filtered = filterByTier(events, regionTier);
    if (filtered.isEmpty) return null;
    return filtered[random.nextInt(filtered.length)];
  }

  static double delayMultiplier(TravelEvent event) {
    if (event.effectType == 'delay') return 1.0 + event.magnitude;
    return 1.0;
  }

  static double applyDamageReduction(double magnitude, double damageReduction) {
    return magnitude * (1.0 - damageReduction);
  }
}
