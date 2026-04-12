import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

void main() {
  group('calculateXpGain', () {
    test('success on D3 gives 60', () => expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 1.0, facilityBonus: 0.0), 60));
    test('great success doubles', () => expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 2.0, facilityBonus: 0.0), 120));
    test('failure halves', () => expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 0.5, facilityBonus: 0.0), 30));
    test('critical failure = 0', () => expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 0.0, facilityBonus: 0.0), 0));
    test('training bonus 30%', () => expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 1.0, facilityBonus: 0.3), 78));
  });

  group('checkLevelUp', () {
    test('no level up at 50 XP', () => expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 50), 1));
    test('level 2 at 100 XP', () => expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 100), 2));
    test('multi-level jump', () => expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 400), 3));
    test('max level 5 cap', () => expect(ExperienceService.checkLevelUp(currentLevel: 5, currentXp: 9999), 5));
    test('threshold boundaries', () {
      expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 99), 1);
      expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 100), 2);
      expect(ExperienceService.checkLevelUp(currentLevel: 2, currentXp: 349), 2);
      expect(ExperienceService.checkLevelUp(currentLevel: 2, currentXp: 350), 3);
      expect(ExperienceService.checkLevelUp(currentLevel: 3, currentXp: 849), 3);
      expect(ExperienceService.checkLevelUp(currentLevel: 3, currentXp: 850), 4);
      expect(ExperienceService.checkLevelUp(currentLevel: 4, currentXp: 1849), 4);
      expect(ExperienceService.checkLevelUp(currentLevel: 4, currentXp: 1850), 5);
    });
  });

  group('resultMultiplier', () {
    test('maps QuestResult correctly', () {
      expect(ExperienceService.resultMultiplier(QuestResult.greatSuccess), 2.0);
      expect(ExperienceService.resultMultiplier(QuestResult.success), 1.0);
      expect(ExperienceService.resultMultiplier(QuestResult.failure), 0.5);
      expect(ExperienceService.resultMultiplier(QuestResult.criticalFailure), 0.0);
    });
  });
}
