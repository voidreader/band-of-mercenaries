import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

void main() {
  late Directory tempDir;
  late DataLoader dataLoader;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('data_loader_test_');
    dataLoader = DataLoader(cacheDir: tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('DataLoader', () {
    test('hasCache returns false when no cache files exist', () {
      expect(dataLoader.hasCache(), false);
    });

    test('saveToCache writes JSON file', () async {
      final data = [
        {'id': 'farmer', 'tier': 1, 'name': '농부', 'base_atk': 4, 'base_def': 3, 'base_hp': 24, 'speed': 0.96},
      ];

      await dataLoader.saveToCache('jobs', data);

      final file = File('${tempDir.path}/jobs.json');
      expect(file.existsSync(), true);

      final content = jsonDecode(file.readAsStringSync()) as List;
      expect(content.length, 1);
      expect(content[0]['id'], 'farmer');
    });

    test('hasCache returns true after saving', () async {
      await dataLoader.saveToCache('jobs', [{'id': 'test'}]);
      expect(dataLoader.hasCache(), true);
    });

    test('loadFromCache parses saved data correctly', () async {
      final data = [
        {'id': 'farmer', 'tier': 1, 'name': '농부', 'base_atk': 4, 'base_def': 3, 'base_hp': 24, 'speed': 0.96},
      ];

      await dataLoader.saveToCache('jobs', data);
      final jobs = dataLoader.loadFromCache('jobs', Job.fromJson);

      expect(jobs.length, 1);
      expect(jobs[0].id, 'farmer');
      expect(jobs[0].tier, 1);
      expect(jobs[0].baseAtk, 4);
    });

    test('loadFromCache returns empty list when no cache', () {
      final result = dataLoader.loadFromCache('jobs', Job.fromJson);
      expect(result, isEmpty);
    });

    test('parseList converts list of maps to models', () {
      final response = [
        {'grade': 'F', 'name': '무명', 'required_reputation': 0, 'unlock_tier': 1},
        {'grade': 'E', 'name': '신입', 'required_reputation': 100, 'unlock_tier': 2},
      ];

      final ranks = DataLoader.parseList(response, Rank.fromJson);
      expect(ranks.length, 2);
      expect(ranks[0].grade, 'F');
      expect(ranks[1].requiredReputation, 100);
    });
  });
}
