import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

void main() {
  late Directory tempDir;
  late Box<String> cacheBox;
  late DataLoader dataLoader;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('data_loader_test_');
    Hive.init(tempDir.path);
    cacheBox = await Hive.openBox<String>('testCache');
    dataLoader = DataLoader(cacheBox: cacheBox);
  });

  tearDown(() async {
    await cacheBox.close();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  group('DataLoader', () {
    test('hasCache returns false when no cache exists', () {
      expect(dataLoader.hasCache(), false);
    });

    test('saveToCache stores data', () async {
      final data = [
        {
          'id': 'farmer',
          'tier': 1,
          'name': '농부',
          'base_str': 4,
          'base_intelligence': 3,
          'base_vit': 24,
          'base_agi': 96,
        },
      ];

      await dataLoader.saveToCache('jobs', data);
      expect(cacheBox.containsKey('jobs'), true);
    });

    test('hasCache returns true after saving', () async {
      await dataLoader.saveToCache('jobs', [
        {'id': 'test'},
      ]);
      expect(dataLoader.hasCache(), true);
    });

    test('loadFromCache parses saved data correctly', () async {
      final data = [
        {
          'id': 'farmer',
          'tier': 1,
          'name': '농부',
          'base_str': 4,
          'base_intelligence': 3,
          'base_vit': 24,
          'base_agi': 96,
        },
      ];

      await dataLoader.saveToCache('jobs', data);
      final jobs = dataLoader.loadFromCache('jobs', Job.fromJson);

      expect(jobs.length, 1);
      expect(jobs[0].id, 'farmer');
      expect(jobs[0].tier, 1);
      expect(jobs[0].baseStr, 4);
    });

    test('loadFromCache returns empty list when no cache', () {
      final result = dataLoader.loadFromCache('jobs', Job.fromJson);
      expect(result, isEmpty);
    });

    test(
      'validateRequiredCaches throws when required table cache is missing',
      () async {
        await dataLoader.saveToCache('jobs', [
          {'id': 'test'},
        ]);

        expect(
          () => dataLoader.validateRequiredCaches(['jobs', 'regions']),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('regions'),
            ),
          ),
        );
      },
    );

    test(
      'validateRequiredCaches treats empty cached table as missing',
      () async {
        await dataLoader.saveToCache('jobs', const []);

        expect(
          () => dataLoader.validateRequiredCaches(['jobs']),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'validateRequiredCaches passes when every required table has data',
      () async {
        await dataLoader.saveToCache('jobs', [
          {'id': 'test'},
        ]);
        await dataLoader.saveToCache('regions', [
          {'region': 3},
        ]);

        expect(
          () => dataLoader.validateRequiredCaches(['jobs', 'regions']),
          returnsNormally,
        );
      },
    );

    test('parseList converts list of maps to models', () {
      final response = [
        {
          'grade': 'F',
          'name': '무명',
          'required_reputation': 0,
          'unlock_tier': 1,
        },
        {
          'grade': 'E',
          'name': '신입',
          'required_reputation': 100,
          'unlock_tier': 2,
        },
      ];

      final ranks = DataLoader.parseList(response, Rank.fromJson);
      expect(ranks.length, 2);
      expect(ranks[0].grade, 'F');
      expect(ranks[1].requiredReputation, 100);
    });
  });
}
