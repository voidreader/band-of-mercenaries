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

  /// 이동 이벤트 골드 손실 완화.
  /// magnitude: 기본 손실 골드량.
  /// mitigation: 완화 비율 (0.0~0.95, PassiveBonusService가 이미 클램프).
  /// 반환: 완화 후 손실 골드량 (정수).
  static int applyGoldLossMitigation(int magnitude, double mitigation) {
    final clamped = mitigation.clamp(0.0, 0.95);
    final reduced = (magnitude * (1.0 - clamped)).round();
    return reduced < 0 ? 0 : reduced;
  }
}
