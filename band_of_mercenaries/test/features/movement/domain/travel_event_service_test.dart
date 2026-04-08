import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_event_service.dart';

void main() {
  final testEvents = [
    const TravelEvent(id: 'te_gold', name: 'Gold', type: 'discovery', effectType: 'gold', magnitude: 50.0, minTier: 1, maxTier: 5, description: 'Found gold.'),
    const TravelEvent(id: 'te_raid', name: 'Raid', type: 'raid', effectType: 'gold', magnitude: -30.0, minTier: 3, maxTier: 5, description: 'Raided.'),
    const TravelEvent(id: 'te_storm', name: 'Storm', type: 'weather', effectType: 'delay', magnitude: 0.3, minTier: 1, maxTier: 5, description: 'Storm.'),
    const TravelEvent(id: 'te_rep', name: 'Encounter', type: 'encounter', effectType: 'reputation', magnitude: 10.0, minTier: 1, maxTier: 2, description: 'Met a group.'),
  ];

  group('eventProbability', () {
    test('distance 1 = 15%', () => expect(TravelEventService.eventProbability(1), 0.15));
    test('distance 5 = 75%', () => expect(TravelEventService.eventProbability(5), 0.75));
    test('distance 10 capped at 80%', () => expect(TravelEventService.eventProbability(10), 0.80));
    test('distance 0 = 0%', () => expect(TravelEventService.eventProbability(0), 0.0));
  });

  group('filterByTier', () {
    test('tier 1 excludes tier 3+ events', () {
      final filtered = TravelEventService.filterByTier(testEvents, 1);
      expect(filtered.any((e) => e.id == 'te_gold'), true);
      expect(filtered.any((e) => e.id == 'te_raid'), false);
      expect(filtered.any((e) => e.id == 'te_rep'), true);
    });
    test('tier 4 includes matching', () {
      final filtered = TravelEventService.filterByTier(testEvents, 4);
      expect(filtered.any((e) => e.id == 'te_gold'), true);
      expect(filtered.any((e) => e.id == 'te_raid'), true);
      expect(filtered.any((e) => e.id == 'te_rep'), false);
    });
  });

  group('rollEvent', () {
    test('returns null when roll exceeds probability', () {
      final random = _FixedRandom([0.99, 0.0]);
      final result = TravelEventService.rollEvent(distance: 1, regionTier: 1, events: testEvents, random: random);
      expect(result, isNull);
    });
    test('returns event when roll under probability', () {
      final random = _FixedRandom([0.01, 0.0]);
      final result = TravelEventService.rollEvent(distance: 5, regionTier: 1, events: testEvents, random: random);
      expect(result, isNotNull);
    });
  });

  group('delayMultiplier', () {
    test('weather event with 0.3 magnitude returns 1.3', () {
      final event = testEvents.firstWhere((e) => e.effectType == 'delay');
      expect(TravelEventService.delayMultiplier(event), 1.3);
    });
    test('non-delay event returns 1.0', () {
      final event = testEvents.firstWhere((e) => e.effectType == 'gold');
      expect(TravelEventService.delayMultiplier(event), 1.0);
    });
  });
}

class _FixedRandom implements Random {
  final List<double> _values;
  int _index = 0;
  _FixedRandom(this._values);
  @override double nextDouble() => _values[_index++];
  @override int nextInt(int max) => (_values[_index++] * max).floor();
  @override bool nextBool() => _values[_index++] < 0.5;
}
