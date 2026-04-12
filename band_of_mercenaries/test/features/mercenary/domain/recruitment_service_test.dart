import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_category.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

void main() {
  final jobs = [
    const Job(id: 'farmer', tier: 1, name: '농부', baseAtk: 4, baseDef: 3, baseHp: 24, speed: 0.96),
    const Job(id: 'militia', tier: 2, name: '민병대', baseAtk: 15, baseDef: 15, baseHp: 75, speed: 0.83),
    const Job(id: 'knight', tier: 3, name: '기사', baseAtk: 20, baseDef: 21, baseHp: 97, speed: 0.81),
  ];
  final traits = [
    const TraitData(key: 'strong_build', name: '강인한 체격', categoryKey: 'Physical', type: 'innate'),
    const TraitData(key: 'noble_birth', name: '귀족 출신', categoryKey: 'Background', type: 'innate'),
    const TraitData(key: 'berserker_talent', name: '광전사의 피', categoryKey: 'Talent', type: 'innate'),
    const TraitData(key: 'veteran', name: '베테랑', categoryKey: 'Experience', type: 'acquired'),
  ];
  final categories = [
    const TraitCategory(key: 'Physical', name: '육체적 특성', slotType: 'innate'),
    const TraitCategory(key: 'Background', name: '배경', slotType: 'innate'),
    const TraitCategory(key: 'Talent', name: '재능', slotType: 'innate'),
  ];
  final names = [
    const PersonName(id: 0, korean: '알라릭'),
    const PersonName(id: 1, korean: '세드릭'),
  ];

  group('RecruitmentService', () {
    test('selectTier returns a valid tier between 1-5', () {
      final tier = RecruitmentService.selectTier(Random(42));
      expect(tier, greaterThanOrEqualTo(1));
      expect(tier, lessThanOrEqualTo(5));
    });

    test('tier distribution favors lower tiers', () {
      final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var i = 0; i < 10000; i++) {
        final tier = RecruitmentService.selectTier(Random(i));
        counts[tier] = counts[tier]! + 1;
      }
      expect(counts[1]!, greaterThan(counts[2]!));
      expect(counts[2]!, greaterThan(counts[3]!));
      expect(counts[3]!, greaterThan(counts[4]!));
      expect(counts[4]!, greaterThan(counts[5]!));
    });

    test('generateMercenary creates merc with 1-3 innate traits', () {
      final merc = RecruitmentService.generateMercenary(
        jobs: jobs, traits: traits, categories: categories, names: names, random: Random(42),
      );
      expect(merc.name, isNotEmpty);
      expect(merc.jobId, isNotEmpty);
      expect(merc.traitIds, isNotEmpty);
      expect(merc.traitIds.length, greaterThanOrEqualTo(1));
      expect(merc.traitIds.length, lessThanOrEqualTo(3));
      expect(merc.traitId, merc.traitIds.first);
    });

    test('generateMercenary only assigns innate traits', () {
      for (int seed = 0; seed < 100; seed++) {
        final merc = RecruitmentService.generateMercenary(
          jobs: jobs, traits: traits, categories: categories, names: names, random: Random(seed), forceTier: 1,
        );
        for (final traitKey in merc.traitIds) {
          final trait = traits.firstWhere((t) => t.key == traitKey);
          expect(trait.type, 'innate');
        }
      }
    });

    test('generateMercenary assigns no duplicate categories', () {
      for (int seed = 0; seed < 100; seed++) {
        final merc = RecruitmentService.generateMercenary(
          jobs: jobs, traits: traits, categories: categories, names: names, random: Random(seed), forceTier: 1,
        );
        final cats = merc.traitIds.map((key) => traits.firstWhere((t) => t.key == key).categoryKey).toSet();
        expect(cats.length, merc.traitIds.length);
      }
    });

    test('generateStartingMercenaries creates 4 mercs from tier 1-2', () {
      final mercs = RecruitmentService.generateStartingMercenaries(
        jobs: jobs, traits: traits, categories: categories, names: names, count: 4, random: Random(42),
      );
      expect(mercs.length, 4);
      for (final merc in mercs) {
        final job = jobs.firstWhere((j) => j.id == merc.jobId);
        expect(job.tier, lessThanOrEqualTo(2));
        expect(merc.traitIds, isNotEmpty);
      }
    });
  });
}
